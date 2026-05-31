# ClaimPal Admin Panel

`admin_panel/` 是 ClaimPal 的独立后台审核服务，用于人工审核抓取到的 class action settlement 数据，并决定是否发布到线上 `settlements` 目录。

它基于以下技术栈：

- FastAPI
- Jinja2
- Tailwind CSS（CDN）
- vanilla JavaScript
- psycopg

后台提供两部分能力：

1. Web 审核界面：在浏览器中查看原始抓取内容、修正字段、保存草稿、批准发布或拒绝垃圾数据。
2. Bearer Token 保护的 Admin API：供抓取器写入待审核记录，供前端读取/保存/批准/拒绝。

---

## 目录结构

```text
admin_panel/
├── .env
├── app/
│   ├── auth.py
│   ├── db.py
│   ├── main.py
│   ├── routes/
│   │   └── admin.py
│   ├── schemas.py
│   ├── services/
│   │   └── settlements.py
│   └── settings.py
├── static/
│   └── admin.js
├── templates/
│   └── review.html
├── tests/
│   ├── conftest.py
│   ├── test_admin_auth.py
│   ├── test_approve_reject.py
│   └── test_pending_pool.py
└── requirements.txt
```

---

## 运行前提

需要以下本地依赖：

- Python 3
- 一个可访问的 PostgreSQL / Supabase 数据库
- （推荐）本地 Supabase 环境，用于联调 `pending_settlements` 和 `settlements`

如果你要跑本地 Supabase，请先参考：

- `../supabase/README.md`

> 注意：`app/settings.py` 通过 `.env` 读取配置，且路径相对**当前工作目录**。因此启动后台时请从 `admin_panel/` 目录执行命令。

---

## 环境变量

后台依赖两个环境变量：

- `ADMIN_BEARER_TOKEN`：Admin API 的 Bearer Token
- `DATABASE_URL`：Postgres / Supabase 连接串

仓库里提供了一个示例配置文件 `admin_panel/.env.example`：

```env
ADMIN_BEARER_TOKEN=replace-with-admin-token
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

建议先复制为本地 `.env` 后再修改：

```text
Copy-Item .env.example .env
```

随后再按本地环境修改该 `.env`，或者在 shell 里手动设置环境变量。

---

## 安装依赖

在 `admin_panel/` 下执行：

```text
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

如果你使用的是非 PowerShell 环境，只需要改成对应的虚拟环境激活命令即可。

---

## 本地数据库准备

### 方案 A：使用本地 Supabase（推荐）

在仓库根目录执行：

```text
npx supabase start
npx supabase migration up
```

如果你已经有本地数据库连接串，就把 `admin_panel/.env` 中的 `DATABASE_URL` 改成对应地址。

### 方案 B：使用现成 Postgres / Supabase 项目

只要下面这些对象已经存在即可：

- `public.pending_settlements`
- `public.settlements`
- `public.global_meta`

并且已应用这些迁移：

- `supabase/migrations/20260530172624_init_claimpal_schema.sql`
- `supabase/migrations/20260530190000_admin_pending_settlements.sql`

---

## 启动后台

在 `admin_panel/` 下执行：

```text
uvicorn app.main:app --reload --port 8008
```

启动成功后，浏览器打开：

```text
http://127.0.0.1:8008
```

首次进入页面时，前端会提示输入 Admin Token。输入的值必须和 `ADMIN_BEARER_TOKEN` 一致。

---

## 页面交互说明

Web 审核页包含以下能力：

- 左侧：显示原始抓取内容（`raw_content`）
- 左侧：显示原始链接（`source_url`）并支持 `Open original source`
- 右侧：编辑审核字段
  - `brand_name`
  - `max_payout`
  - `country`
  - `proof_required`
  - `deadline`
  - `eligibility_text`
- `Approve & Publish`
  - 调用 `POST /api/admin/approve/{id}`
  - 向 `settlements` 写入正式数据
  - 更新全局 `data_version`
  - 删除对应 pending 记录
- `Reject / Spam`
  - 调用 `POST /api/admin/reject/{id}`
  - 删除 pending 记录
  - 不写入 `settlements`

---

## Admin API 速查

所有 `/api/admin/*` 路由都要求：

```http
Authorization: Bearer <ADMIN_BEARER_TOKEN>
```

### 1. 推送待审核抓取结果

`POST /api/admin/scraped-pool`

最小示例请求体：

```json
{
  "raw_content": "Apple settlement details",
  "brand_name": "Apple",
  "country": "US"
}
```

更完整的示例（PowerShell 可用 `curl.exe`）：

```text
curl.exe -X POST http://127.0.0.1:8008/api/admin/scraped-pool ^
  -H "Authorization: Bearer replace-with-admin-token" ^
  -H "Content-Type: application/json" ^
  -d "{\"source_url\":\"https://example.com/apple\",\"raw_content\":\"Apple raw settlement text\",\"raw_content_type\":\"text\",\"brand_name\":\"Apple\",\"max_payout\":\"35.00\",\"country\":\"US\",\"proof_required\":false,\"deadline\":\"2026-08-14\",\"eligibility_text\":\"US customers with qualifying purchases.\",\"ai_payload\":{\"confidence\":0.92},\"scraper_payload\":{\"source\":\"manual-smoke-test\"}}"
```

### 2. 读取下一个待审核项

`GET /api/admin/pending`

### 3. 读取指定待审核项

`GET /api/admin/pending/{id}`

### 4. 保存草稿

`PATCH /api/admin/pending/{id}`

### 5. 批准并发布

`POST /api/admin/approve/{id}`

### 6. 拒绝

`POST /api/admin/reject/{id}`

---

## 运行测试

在 `admin_panel/` 下执行：

```text
python -m pytest -q tests
```

当前测试覆盖的重点包括：

- Bearer Token 鉴权
- `scraped-pool` 创建待审核记录
- pending 列表 / 读取 / 更新
- approve / reject 路由行为
- 事务发布逻辑
- `data_version` 同步逻辑
- rollback / 缺失记录处理

---

## 推荐联调流程

如果你希望验证整条链路，推荐按下面顺序操作：

1. 启动本地 Supabase
2. 应用数据库迁移
3. 在 `admin_panel/` 下安装依赖
4. 配置 `admin_panel/.env`
5. 启动 `uvicorn app.main:app --reload --port 8008`
6. 用 `POST /api/admin/scraped-pool` 写入一条 pending 数据
7. 打开 `http://127.0.0.1:8008`
8. 输入 Bearer Token
9. 执行 `Approve & Publish` / `Reject / Spam`
10. 到数据库里检查：
    - `pending_settlements`
    - `settlements`
    - `global_meta`

---

## 常见问题

### 页面打开后一直报鉴权失败

检查：

- 浏览器输入的 token 是否和 `ADMIN_BEARER_TOKEN` 一致
- 页面是否还保存着旧 token；清除 `claimpal_admin_token` 的 localStorage 值后重新输入

### 启动时报数据库连接失败

通常是 `DATABASE_URL` 不可达，优先检查：

- Postgres / Supabase 是否真的已启动
- 端口是否正确（本地 Supabase 常见是 `54322`）
- 当前目录是否是 `admin_panel/`，以便 `.env` 被正确读取

### 页面能打开，但没有数据

说明服务启动正常，但 `pending_settlements` 队列为空。可以先调用：

- `POST /api/admin/scraped-pool`

手动塞一条待审核记录。

---

## 相关文档

- 仓库总览：`../README.md`
- 数据库说明：`../supabase/README.md`
- 设计规格：`../docs/superpowers/specs/2026-05-30-web-admin-panel-design.md`
- 实施计划：`../docs/superpowers/plans/2026-05-30-web-admin-panel-implementation.md`
