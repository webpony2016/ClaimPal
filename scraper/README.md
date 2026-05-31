# ClaimPal Scraper

`scraper/` 是 ClaimPal 的独立抓取子项目，用于从外部 class action settlement 来源发现候选案件、提取原始内容，并在后续阶段把结构化结果推送到 `admin_panel` 的待审核队列。

当前已完成一版可运行的基础实现，已包含：

- 环境变量配置
- Python 依赖清单
- `pydantic-settings` 设置模型
- 共享数据模型与 Admin payload 校验
- SQLite 状态存储与去重
- HTML 提取、日期/金额/国家/证明要求规则提取
- `admin_panel` 发布客户端与发布重试
- `CourtListener` 首个参考来源适配器
- 端到端 ingestion pipeline
- CLI 运行入口与结构化测试/客户端测试/管道测试

---

## 运行前提

需要：

- Python 3.11+
- 一个可访问的 `admin_panel` 服务地址（后续 publish 阶段使用）

> 建议从 `scraper/` 目录执行命令，因为 `app/settings.py` 默认从当前工作目录读取 `.env`。

---

## 环境变量

仓库里提供了一个示例配置文件 `scraper/.env.example`：

```env
ADMIN_API_BASE_URL=http://127.0.0.1:8008
ADMIN_BEARER_TOKEN=replace-with-admin-token
LLM_API_KEY=replace-with-llm-key
SCRAPER_STATE_DB_URL=sqlite:///scraper_state.db
REQUEST_TIMEOUT_SECONDS=20
MAX_RETRIES=3
USER_AGENT=ClaimPalScraper/0.1
```

建议先复制为本地 `.env`：

```text
Copy-Item .env.example .env
```

说明：

- `ADMIN_API_BASE_URL`：Admin API 基础地址
- `ADMIN_BEARER_TOKEN`：写入 `/api/admin/scraped-pool` 时使用的 Bearer Token
- `LLM_API_KEY`：后续 LLM 结构化阶段使用；Phase 1 仅占位
- `SCRAPER_STATE_DB_URL`：本地状态存储地址，第一阶段默认 SQLite
- `REQUEST_TIMEOUT_SECONDS`：HTTP 超时秒数
- `MAX_RETRIES`：后续发布与抓取重试次数
- `USER_AGENT`：抓取器请求头标识

---

## 安装依赖

在 `scraper/` 下执行：

```text
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

---

## 当前可用命令

打印当前设置（敏感值会打码）：

```text
python -m app.main --show-settings
```

用占位的 dry-run 模式验证 CLI 能正常读取配置：

```text
python -m app.main --dry-run
```

运行单个来源的 dry-run（会提取并构建 payload，但不会调用 Admin API）：

```text
python -m app.main --source courtlistener --dry-run --max-items 5
```

运行全部来源：

```text
python -m app.main --all-sources --dry-run --max-items 5
```

---

## 运行测试

在 `scraper/` 下执行：

```text
python -m pytest -q
```

当前测试覆盖：

- 设置模型加载
- payload 校验
- SQLite 状态存储与去重
- Admin API 客户端错误分类
- 提取与结构化逻辑
- 来源适配器与端到端 pipeline

---

## 本地冒烟验证

推荐本地联调顺序：

1. 在 `admin_panel/` 启动后台服务
2. 在 `scraper/` 执行 `python -m app.main --source courtlistener --dry-run --max-items 1`
3. 检查输出的 summary 是否包含 payload 构建结果
4. 配置真实 `ADMIN_BEARER_TOKEN`
5. 执行 `python -m app.main --source courtlistener --max-items 1`
6. 打开后台审核页，确认 `pending_settlements` 中出现新记录

## 后续待办

下一阶段建议继续推进：

1. 增强 HTML 来源解析
2. 增加更多真实来源适配器
3. 增强近似重复检测
4. 接入可选 LLM 供应商实现
5. 补充调度与告警
