# ClaimPal 手机 App 端 — 设计文档

**日期**: 2026-05-30
**状态**: 已确认,待出实现计划
**来源**: `PRD_cn.md` + `stitch_class_action_settlement_tracker/` (Google Stitch 导出的 UI 设计)

## 1. 目标与范围

把 PRD 描述的手机 App 端做成一个**完整可演示的 Flutter 应用**:搭建工程骨架(导航、主题、状态管理),并将 Stitch 的 13 个界面全部实现为可点击跑通的页面。

- **数据**: mock 数据驱动,暂不接后端(Supabase schema 已在 `supabase/` 就绪,后续替换)。
- **状态管理**: Riverpod。
- **验证平台**: Flutter Web (Chrome)。
- **工具链**: Flutter 3.41.5 / Dart 3.11.3 (stable),已就绪。

## 2. 已锁定的决策

| 决策 | 选择 |
|---|---|
| 实现范围 | 完整 App 骨架 + 全部核心界面(mock 数据) |
| 状态管理 | Riverpod |
| 验证平台 | Flutter Web |
| 工程架构 | 方案 A:Feature-first + 可替换 Repository 层 |
| 路由 | go_router + `StatefulShellRoute` |
| 详情页 | 无专门 mockup,按设计系统 + PRD 自建 |
| 多变体界面 | 合并成单页多状态(代填 step1 ×2、成功页 ×2、裂变 ×3) |
| 裂变奖励 | **双方各得 1 个月 Plus**(覆盖设计稿"2 个月 Pro"文案) |

## 3. 架构(方案 A:Feature-first + 可替换 Repository)

```
lib/
  main.dart, app.dart            # ProviderScope + MaterialApp.router
  core/
    theme/        # legal_ledger 设计令牌 → ThemeData + AppColors/AppText
    router/       # go_router 路由表 + accessGuard 拦截
    widgets/      # 跨页复用组件
  data/
    models/       # 不可变模型 + copyWith
    repositories/ # 抽象接口
    mock/         # Mock 实现(现在注入)
  features/
    home/         # 游客 FOMO 首页 + Tracker 首页
    detail/       # 诉讼详情 + Paywall 弹窗
    auth/         # 注册拦截弹窗
    filing/       # AI 代填三步 + 成功追踪
    pricing/      # 订阅套餐
    referral/     # 裂变 + 钱包/Rewards
    profile/      # My Claims / Profile 占位
```

**核心原则**: Riverpod provider 注入 repository,UI 只依赖接口。接 Supabase = 新增 `SupabaseXxxRepository` + override 一个 provider,UI 零改动。

### 依赖包

- `flutter_riverpod` — 状态管理
- `go_router` — 路由 + 拦截守卫
- `google_fonts` — Inter 字体(设计系统指定)
- `intl` — 金额/日期格式化
- dev: `flutter_lints`、`flutter_test`(后续 `mocktail`)
- 暂不引入 `freezed`/`supabase_flutter`(模型手写,保持轻量)

### 路由表

| 路径 | 页面 | 备注 |
|---|---|---|
| `/` | 游客 FOMO 首页 | 启动默认 |
| `/tracker` | Tracker 首页(已有 widget) | 登录后主页 |
| `/lawsuit/:id` | 诉讼详情 | 游客可浏览 |
| `/filing/:id` | AI 代填三步 | 页内步骤状态 |
| `/pricing` | 订阅套餐 | |
| `/referral` | 裂变推荐 | |
| `/wallet` | 钱包/Rewards | |
| 底部 Tab | Tracker / Explore / My Claims / Profile | `StatefulShellRoute.indexedStack` 保留各栈 |

Paywall、注册为 `showModalBottomSheet` 半屏覆盖,不入路由历史。

## 4. 数据模型与 Repository 层

### 模型 (`data/models/`)

- **`Lawsuit`** — id、title、品牌名/logo、`category`、`LawsuitStatus{active,expired}`、`payoutLabel`、`payoutValue`、`deadline`、`expiredDaysAgo`、`eligibility`、`requiredProof[]`。(并入现有 `ClaimPalClaim`)
- **`FomoSummary`** — `missedAmount`、`upcomingAmount`、`timeframe`。
- **`UserAccount`** — `SubscriptionTier{starter,plus,pro}`、`autofillUsed`、`autofillLimit`(starter=2,pro=null 表无限)、`isGuest`。**拦截逻辑单一数据源。**
- **`FilingDraft`** — `lawsuitId`、自动填好的 `fullName`/`address`、`actionRequiredFields`、`uploadedFileName`、`signatureData`。
- **`ClaimProgress`** — 4 阶段 `{aiSubmitted, courtReview, settlementApproved, payoutSent}` + 当前索引。
- **`RewardsSummary`** — `totalEarned`、`pending`、`referralLink`、匿名邀请记录。
- **`SubscriptionPlan`** — tier、`monthlyPrice`、`yearlyPrice`、`features[]`、`monthlyAutofills`。

### Repository 接口 + Mock

| 接口 | 关键方法 | Mock 行为 |
|---|---|---|
| `LawsuitRepository` | `watchActive()`, `watchExpired()`, `getById(id)`, `getFomoSummary()`, `search(q)` | 内存假数据 + `Future.delayed` |
| `FilingRepository` | `getDraft(lawsuitId)`, `submit(draft)`, `watchProgress(id)` | 返回预填草稿;submit 推进 4 阶段 |
| `SubscriptionRepository` | `getPlans()`, `watchAccount()`, `useAutofillCredit()` | starter 默认 2 次,用完触发 Paywall |
| `ReferralRepository` | `getRewards()`, `generateLink()` | 假钱包数据;奖励 = 1 个月 Plus |
| `AuthRepository` | `currentUser`, `register()`, `continueAsGuest()` | 切换 guest/registered |

Mock 数据复用 Stitch 真实文案(Facebook 隐私和解 Up to $350、Capital One、Fitbit、Equifax 等)。

## 5. 界面清单与组件映射

| Feature 页面 | 对应 Stitch 设计 | 关键组件 |
|---|---|---|
| 游客 FOMO 首页 | `guest_home_fomo_driven` | 渐变 FOMO 看板、控制面板(显示过期 Toggle + 时间范围)、混合信息流(鲜艳 Active / 50% 置灰 Expired) |
| Tracker 首页 | `lawsuit_tracker_home` ✅已有 | 复用 `claimpal_claim_tracker_screen.dart`,接 provider |
| 诉讼详情 | ⚠️ 无 mockup,自建 | 品牌 Logo、预计金额、申请资格、所需证明、CTA |
| Paywall 拦截 | `claimradar_paywall_pop_up` | 半屏 sheet:额度用尽文案、月/年切换、$2.99/$5.99 两档、Apple/Google Pay 按钮、底部"邀请好友免费解锁 1 个月 Plus" |
| 注册拦截 | `registration_pop_up` | 半屏 sheet:注册/社交登录 |
| AI 代填 第 1 步 | `ai_1_click_smart_filing_step_1_1` + `_1_2` | 半屏抽屉、"AI Autofill Ready"微光标签、已填姓名/地址+绿勾、Action Required 区(购买年份 + 虚线上传框)。两变体合并为"已填/待填"双态 |
| AI 代填 第 2 步 | `ai_1_click_smart_filing_step_2` | 免责声明容器、手写签名板、盾牌图标"Authorize & Submit via AI" |
| AI 代填 成功 | `ai_1_click_smart_filing_success_1` + `_2` | 满屏绿色勾选动画 + 4 阶段时间轴步进器。两变体合并 |
| 订阅套餐 | `claimradar_pricing_plans` | 月/年切换、Starter/Plus/Pro 三档卡片 |
| 裂变 + 钱包 | `claimpal_referral_dashboard` + `referral_rewards_dashboard` + `referral_earnings_dashboard` | Total Earned $120(翠绿)/ Pending $30(灰)、提现按钮、"Give 1 Month, Get 1 Month" 推荐卡、100% Privacy 徽章、复制链接 + 社交分享。三变体合并 |
| My Claims / Profile | 底部 Tab 占位 | 简单列表 + 占位 Profile |

**共享 widget** (`core/widgets/`): `StatusBadge`、`ClaimStepper`、`AppBottomSheet`、隐私锁徽章、FOMO 渐变看板、`LawsuitCard`(active/expired 两态)。

### 设计系统(来自 `legal_ledger/DESIGN.md`)

- 字体: Inter 全局。
- 主色 Primary: `#1A365D`(深蓝,权威)。
- Success/Active: `#10B981`(翠绿)。
- Neutral/Expired: `#718096`(石板灰)。
- 背景: `#F7FAFC`。
- 形状: 4px 软圆角;卡片 8px;徽章/chip pill 全圆。
- 深度: 平面 + 1px 描边(`#E2E8F0`),弹窗用极淡阴影。

## 6. 状态流转与关键业务逻辑

### Provider 分层

- **Repository providers**(可 override 成 Supabase)。
- **State/Notifier providers**:
  - `accountProvider`(`NotifierProvider<UserAccount>`)— 全局:游客态、订阅档、额度。拦截逻辑单一数据源。
  - `activeLawsuitsProvider` / `expiredLawsuitsProvider`(`StreamProvider`)。
  - `fomoSummaryProvider`(`FutureProvider`)。
  - `homeFilterProvider`(显示过期 Toggle + 时间范围,本地 UI 状态)。
  - `filingControllerProvider(lawsuitId)`(`family`:三步表单草稿、当前步、签名)。
  - `claimProgressProvider(lawsuitId)`、`rewardsProvider`、`subscriptionPlansProvider`。

### 核心拦截流

**`accessGuard(account, action='file')`** —— 注册墙只挡"申请"动作:

1. **游客**浏览首页/详情 → 放行;点 "File Claim" → 弹注册 sheet。
2. **免费用户额度未用尽**点申请 → 放行进代填。
3. **免费用户额度用尽**(第 3 次)点申请 → 弹 Paywall sheet,文案带当前金额。
4. **Pro** → 无限放行。

判断放在跳转/按钮回调里读 `accountProvider`,不污染 UI 组件。

**额度消耗**: 进代填第 1 步**不**扣;第 2 步"Authorize & Submit"成功后调 `useAutofillCredit()` 扣 1 次,推进 `ClaimProgress` 到 `aiSubmitted`,跳成功页。Pro 跳过扣减。

**裂变奖励**: 每成功邀请一位好友注册并完成首笔申请,**双方各得 1 个月 Plus**。`rewardsProvider` 展示假 totalEarned/pending;复制链接用 `Clipboard.setData`;社交分享/提现 mock(SnackBar)。

**导航**: `StatefulShellRoute.indexedStack` 保留 4 Tab 各自栈;弹窗为 modal 覆盖,不入历史。

## 7. 错误处理与边界

- 异步三态: `.when(data/loading/error)` — loading 骨架,error 重试按钮。Mock 提供"模拟失败"开关。
- 详情页 id 不存在 → "诉讼不存在"占位页。
- 过期诉讼: 50% 置灰、CTA 禁用;`accessGuard` 拒绝申请。
- 额度边界: Pro 用 `null` 哨兵表无限;扣减前再校验防重复扣。
- 表单校验: 第 1 步必填项未填禁用"下一步";第 2 步签名为空禁用提交。
- 空态: 搜索无结果、My Claims 为空 → 空态文案。
- Inter 字体加载失败 → `google_fonts` 回退系统字体。

## 8. 测试与验证

### 测试

- **单元/逻辑**: `accessGuard` 四分支、`useAutofillCredit()` 扣减与 Pro 跳过/边界、`ClaimProgress` 推进、Mock 数据形状。
- **Widget**: `LawsuitCard` active/expired 两态、`ClaimStepper` 当前步高亮、Paywall 在额度用尽时出现。

### 验证标准(Flutter Web)

1. `flutter analyze` 零 error。
2. `flutter test` 全绿。
3. `flutter run -d chrome` 走通主闭环: 游客首页 → 详情 → 点申请弹注册 → 注册后进代填三步 → 成功页时间轴 → 底部 Tab 切换 → 裂变/钱包/订阅可达。
4. 手机视口截图比对 Stitch `screen.png` 确认还原度。

## 9. 暂不做(YAGNI)

- 不接 Supabase / 真实网络(留接口)。
- 不接 Stripe / Apple/Google Pay 真实支付(按钮 mock)。
- 不做真实签名上传 / 文件存储。
- 不做增量更新 / 本地 SQLite 缓存(PRD 后端逻辑,非本期 UI 范围)。
- 不做 Admin Dashboard(后台审核流,非手机端)。
