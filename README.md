# ClaimPal

ClaimPal 是一个围绕 class action settlement（集体诉讼和解）构建的产品仓库，当前包含：

- Flutter 客户端
- 独立的 Scraper 抓取服务
- 独立的 Web Admin 审核后台
- Supabase 数据库迁移、回滚脚本与测试

---

## 仓库主要模块

### Flutter 客户端

主应用代码位于：

- `lib/`
- `test/`

如果你是在做 Flutter 开发，可以按常规流程运行：

```text
flutter pub get
flutter run
```

如果你希望 Flutter 客户端直接读取 Supabase 真实数据：

```text
flutter run --dart-define=SUPABASE_URL=https://<your-project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

说明：

- 未传入 `SUPABASE_URL` / `SUPABASE_ANON_KEY` 时，App 会自动回退到本地 mock 数据。
- 当前实现会在启动时自动执行匿名登录，因此你的 Supabase 项目需要启用 Anonymous Sign-Ins。
- 在开启 Supabase 后，诉讼列表、账户档位（`profiles`）和邀请奖励（`referrals`）都会读取真实数据。
- 客户端只能使用 `anon key`，不要把 `service_role` 或数据库直连串塞进 App —— 安全不是装饰品。

### Web Admin 后台

后台审核服务位于：

- `admin_panel/`

它是一个独立的 FastAPI 项目，用于：

- 接收抓取器写入的待审核 settlement 数据
- 在浏览器中审核原始内容与 AI 清洗结果
- Save Draft / Approve / Reject
- 将审核通过的数据发布到 `settlements`

详细启动说明见：

- `admin_panel/README.md`

### Scraper 抓取服务

抓取服务位于：

- `scraper/`

它是一个独立的 Python 子项目，当前已具备基础可运行实现，用于：

- 管理抓取器配置、CLI 运行入口与结构化日志
- 维护本地 SQLite 状态存储与重复检测
- 提取原始 HTML / 文本内容并生成待审核 payload
- 通过 `admin_panel` 的 `POST /api/admin/scraped-pool` 推送待审核记录
- 提供首个 `CourtListener` 参考来源适配器与测试基线

详细说明见：

- `scraper/README.md`

### Supabase 数据库工程

数据库相关内容位于：

- `supabase/migrations/`
- `supabase/rollback/`
- `supabase/tests/`

详细数据库说明见：

- `supabase/README.md`

---

## 快速入口

### 想启动后台审核服务

直接看：

- `admin_panel/README.md`

其中包含：

- 环境变量说明
- 依赖安装
- 本地 Supabase / Postgres 准备
- `uvicorn` 启动命令
- API 示例
- 测试命令

### 想准备本地数据库

直接看：

- `supabase/README.md`

其中包含：

- `supabase start`
- `supabase migration up`
- pgTAP 测试
- 手动回滚

### 想查看抓取器骨架

直接看：

- `scraper/README.md`

其中包含：

- 环境变量说明
- 依赖安装
- CLI stub 用法
- Phase 1 测试命令

---

## 相关设计文档

- `docs/superpowers/specs/2026-05-30-web-admin-panel-design.md`
- `docs/superpowers/specs/2026-05-30-scraper-service-design.md`
- `docs/superpowers/plans/2026-05-30-web-admin-panel-implementation.md`
- `docs/superpowers/plans/2026-05-30-scraper-service-implementation.md`

---

## 备注

`admin_panel` 是独立子项目，建议从 `admin_panel/` 目录启动，因为其配置通过本地 `.env` 文件读取：

- `ADMIN_BEARER_TOKEN`
- `DATABASE_URL`

这能避免“服务能起但读不到配置”的经典小坑。配置问题从不迟到，只会挑最忙的时候出现。
