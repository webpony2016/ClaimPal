# ClaimPal 数据库使用指南

本目录是 ClaimPal 的 Supabase 数据库工程,包含建表迁移、回滚脚本与 pgTAP 测试。

---

## 1. 目录结构

```
supabase/
├── migrations/
│   └── 20260530172624_init_claimpal_schema.sql   # 前向迁移(建表 + RLS + 触发器)
├── rollback/
│   └── 20260530172624_init_claimpal_schema_down.sql  # 手动回滚脚本(不归 CLI 管)
├── tests/
│   └── reward_engine_test.sql                    # pgTAP 测试:奖励引擎 + 列守卫
└── README.md                                     # 本文件
```

> ⚠️ `rollback/` 故意放在 `migrations/` 之外。Supabase CLI 把 `migrations/` 下每个
> `.sql` 都当成按时间戳排序的「前向」迁移,若把 down 脚本放进去,会被正向执行或与
> up 迁移版本号冲突。回滚必须手动跑(见第 6 节)。

---

## 2. 前置条件

| 工具 | 说明 |
|---|---|
| Docker Desktop | 本地 Supabase 实例运行所需 |
| Supabase CLI | `npm i -g supabase` 或 `npx supabase` |
| psql | 手动跑回滚脚本时需要(随 PostgreSQL 客户端安装) |

首次在仓库里启用 Supabase(如果还没有 `config.toml`):

```bash
rtk npx supabase init
```

---

## 3. 本地启动与应用迁移

```bash
# 启动本地 Supabase(Postgres + Auth + Studio 等)
rtk npx supabase start

# 把 migrations/ 里的迁移应用到本地数据库
rtk npx supabase migration up
```

`supabase start` 结束后会打印本地连接信息(API URL、Studio URL、`service_role` key、
数据库连接串)。Studio 默认在 http://localhost:54323,可视化查看刚建出来的 4 张表。

---

## 4. 推送到云端项目

```bash
# 一次性:把本地仓库链接到你的云端 Supabase 项目
rtk npx supabase link --project-ref <your-project-ref>

# 把尚未应用的迁移推到云端
rtk npx supabase db push
```

`db push` 只会执行 `migrations/` 里「云端迁移历史中还没记录」的版本,可安全重复运行。

---

## 5. 运行 pgTAP 测试

```bash
rtk npx supabase test db
```

测试套件会在一个事务里建临时用户与推荐数据、断言、然后回滚 —— **不会污染**你的数据。
11 个断言覆盖:

| 场景 | 验证点 |
|---|---|
| NULL 基准 (A→B) | `premium_until` 为空时 → `now() + 30 天`,`starter` 升 `plus` |
| 双方都拿奖 | 推荐人同样 `+30 天` 升 `plus`(PRD「送一个月,得一个月」) |
| 未来日期叠加 (C→D) | `2099-01-01 + 30 天 = 2099-01-31`,已有 `plus`/`pro` 不降级 |
| 过期日期重置 (E→F) | 过去时间视为失效 → 重置为 `now() + 30 天` |
| 幂等 | 重复写入 `first_claim_filed` 不二次发奖 |
| data_version 同步 | `global_meta.data_version == MAX(settlements.version_id)` |
| 列守卫 ×2 | 非 `service_role` 客户端无法自升 `pro` / 无法直接改 `referrals.status` |

> 测试利用「`now()` 在单个事务内恒定」的特性,所有「+30 天」断言都是**精确相等**,
> 无需容差。前提是 `supabase test db` 跑在带 `auth` schema 和 `pgtap` 扩展的官方镜像里。

---

## 6. 回滚(撤销本次迁移)

回滚脚本不归 CLI 管,用 `psql` 直连数据库手动执行。先拿到连接串:

```bash
# 本地实例连接串(supabase start 输出里有,通常如下)
$env:DATABASE_URL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"

rtk psql $env:DATABASE_URL -f supabase/rollback/20260530172624_init_claimpal_schema_down.sql
```

脚本按依赖逆序 drop:`auth.users` 触发器 → 列守卫 → 奖励引擎 → 版本同步触发器 →
四张表(policy/index/外键随表消失) → 序列 → 枚举类型。全程 `if exists`,可重复执行。

> 云端回滚请谨慎:`db push` 后云端会记录迁移版本号。手动跑 down 脚本删表后,如需重建,
> 可能要先用 `supabase migration repair` 清理迁移历史,再重新 `db push`。

---

## 7. 业务模型速查

### 4 张表

| 表 | 作用 | 关键点 |
|---|---|---|
| `profiles` | 用户档案(1:1 关联 `auth.users`) | `premium_tier` / `premium_until` 为**服务端独占字段** |
| `settlements` | 集体诉讼和解信息(目录数据) | `version_id` 为增量同步游标(序列自增) |
| `referrals` | 推荐台账 | 匿名:无任何金额/案件字段 |
| `global_meta` | 动态键值遥测 | 存全局 `data_version` |

### 增量同步(PRD §2.3)

客户端存本地缓存版本号,请求 `WHERE version_id > <本地版本>` 即可只拉增量行;
`global_meta.data_version` 由触发器自动等于 `MAX(version_id)`,所以版本检查是一次 O(1) 查找。

### 推荐奖励引擎(PRD §1.2)

推荐状态从 `registered` 变为 `first_claim_filed` 时,自动给**推荐人和被推荐人各 +30 天**:

- 基准 = `max(now(), 当前 premium_until)`;若为 NULL 或已过期 → 基准 = `now()`。
- 奖励可**无限叠加**(每条推荐独立触发)。
- `starter` 升 `plus`,但**绝不降级**已有的 `pro`。
- 仅在状态**转换**时触发(幂等,重复写入不重复发奖)。

### 安全模型(为什么有「列守卫」)

只靠 RLS,已认证用户仍能执行
`update profiles set premium_tier='pro' where id=auth.uid()`(能通过 `using`/`with check`)。
因此 `guard_privileged_columns()` 这个 `BEFORE` 触发器拦截客户端对
`premium_tier`/`premium_until`/`referrals.status` 等服务端字段的写入;只有 `service_role`
(你的 IAP 回调)和 `SECURITY DEFINER` 奖励引擎可绕过。

---

## 8. 常见操作

**模拟「后台批准并发布」一条和解信息(会自动 bump data_version):**

```sql
insert into public.settlements (brand_name, max_payout, deadline, eligibility_text, proof_required)
values ('Acme 数据泄露和解', 125.00, now() + interval '90 days', '2020-2023 年间的注册用户', false);
```

**模拟「被推荐人完成首次申报」触发奖励(需 service_role / 后端身份):**

```sql
update public.referrals
   set status = 'first_claim_filed'
 where id = '<referral-uuid>';
-- 触发后,referrer_id 与 referee_id 双方 premium_until 各 +30 天
```

**查当前全局数据版本:**

```sql
select (value)::bigint as data_version from public.global_meta where key = 'data_version';
```
