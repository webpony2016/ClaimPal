# ClaimPal 手机 App 端 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 PRD 的手机端功能做成一个完整可演示的 Flutter Web 应用 —— 工程骨架 + Stitch 的 13 个核心界面,mock 数据驱动,后续可平滑替换为 Supabase。

**Architecture:** Feature-first 目录结构。Riverpod 注入"可替换 Repository"(现在是 mock 实现),UI 只依赖抽象接口。go_router + `StatefulShellRoute` 管理导航与 4 个底部 Tab 栈;Paywall/注册为半屏 `showModalBottomSheet`。一个 `accountProvider` 作为订阅档/额度/游客态的单一数据源,`accessGuard` 在"申请"动作前做拦截。

**Tech Stack:** Flutter 3.41.5 / Dart 3.11.3、flutter_riverpod、go_router、google_fonts、intl;测试用 flutter_test。

**设计参考:** `docs/plans/2026-05-30-claimpal-mobile-app-design.md`(完整设计)、`stitch_class_action_settlement_tracker/<screen>/{code.html,screen.png}`(逐屏像素参照)、`stitch_class_action_settlement_tracker/legal_ledger/DESIGN.md`(设计令牌)。

**通用约定:**
- 所有命令用 `rtk` 前缀(如 `rtk flutter test`)。
- 颜色/字号一律走 `core/theme`,禁止页面里硬编码十六进制色值(现有 `claimpal_claim_tracker_screen.dart` 里的私有色板将被迁移为公共 `AppColors`)。
- 每个 Task 结束都 commit。提交信息用 `feat:`/`test:`/`chore:` 前缀,结尾带 `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`。
- 裂变奖励文案统一为 **"Give 1 Month, Get 1 Month" Plus**(覆盖 Stitch 稿里的 "2 Months / Pro")。

---

## Phase 0 — 工程骨架

### Task 0.1: 用 flutter create 生成工程(保留现有文件)

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `web/`, `analysis_options.yaml` 等(flutter 生成)
- 注意: 现有 `lib/claimpal_claim_tracker_screen.dart` 不能被覆盖

**Step 1:** 先把现有文件挪开,避免被覆盖:
```bash
rtk git mv lib/claimpal_claim_tracker_screen.dart claimpal_claim_tracker_screen.dart.bak
```

**Step 2:** 在项目根生成 Flutter 工程(`.` 表示当前目录,org 自定):
```bash
rtk flutter create --org com.claimpal --platforms=web --project-name claimpal .
```
Expected: 生成 `pubspec.yaml`、`lib/main.dart`、`web/`、`test/`。

**Step 3:** 把备份文件放回未来归属目录:
```bash
mkdir -p lib/features/home/widgets
rtk git mv claimpal_claim_tracker_screen.dart.bak lib/features/home/widgets/claim_tracker_screen.dart
```
(后续 Task 会重构它接 provider;现在先保留以免丢失。)

**Step 4:** 确认能编译:
```bash
rtk flutter analyze
```
Expected: 0 errors(可能有关于未使用文件的 info,忽略)。

**Step 5: Commit**
```bash
rtk git add -A && rtk git commit -m "chore: scaffold Flutter web project, relocate existing tracker screen"
```

---

### Task 0.2: 添加依赖

**Files:**
- Modify: `pubspec.yaml`

**Step 1:** 加依赖:
```bash
rtk flutter pub add flutter_riverpod go_router google_fonts intl
rtk flutter pub add dev:mocktail
```

**Step 2:** 拉取:
```bash
rtk flutter pub get
```
Expected: 成功,无版本冲突。

**Step 3: Commit**
```bash
rtk git add pubspec.yaml pubspec.lock && rtk git commit -m "chore: add riverpod, go_router, google_fonts, intl deps"
```

---

### Task 0.3: 建立目录骨架占位

**Files:**
- Create: `lib/core/theme/.gitkeep`, `lib/core/router/.gitkeep`, `lib/core/widgets/.gitkeep`, `lib/data/models/.gitkeep`, `lib/data/repositories/.gitkeep`, `lib/data/mock/.gitkeep`, `lib/features/{home,detail,auth,filing,pricing,referral,profile}/.gitkeep`

**Step 1:** 创建空目录占位(保证结构可见)。

**Step 2: Commit**
```bash
rtk git add -A && rtk git commit -m "chore: create feature-first directory skeleton"
```

---

## Phase 1 — 设计系统(主题)

### Task 1.1: AppColors

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Test: `test/core/theme/app_colors_test.dart`

**Step 1: Write the failing test**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/core/theme/app_colors.dart';

void main() {
  test('AppColors exposes the Legal Ledger palette', () {
    expect(AppColors.primary, const Color(0xFF1A365D));
    expect(AppColors.success, const Color(0xFF10B981));
    expect(AppColors.background, const Color(0xFFF7FAFC));
    expect(AppColors.expired, const Color(0xFF718096));
  });
}
```

**Step 2: Run, expect FAIL** — `rtk flutter test test/core/theme/app_colors_test.dart`(找不到 AppColors)。

**Step 3: Implement** `app_colors.dart`,把 `DESIGN.md` 与现有私有 `_ClaimPalColors` 的色值合并为公共常量类 `AppColors`(primary、primaryContainer、success、successDark、expired/neutral、background、surface、surfaceContainerLow、outline、outlineVariant、onSurface、mutedText、error 等)。

**Step 4: Run, expect PASS。**

**Step 5: Commit** `feat: add AppColors design tokens`。

---

### Task 1.2: AppTextStyles + ThemeData

**Files:**
- Create: `lib/core/theme/app_text.dart`(基于 google_fonts Inter,实现 DESIGN.md 的字阶:headlineLg/Md/Sm、bodyLg/Md/Sm、labelLg/Sm)
- Create: `lib/core/theme/app_theme.dart`(`ThemeData buildTheme()`:colorScheme 用 AppColors,字体 Inter,输入框 OutlineInputBorder 焦点 2px primary,卡片 8px 圆角 1px 描边,按钮 4px)
- Test: `test/core/theme/app_theme_test.dart`

**Step 1: Write failing test** —— 验证 `buildTheme().colorScheme.primary == AppColors.primary` 且 `useMaterial3 == true`。

**Step 2:** Run, expect FAIL。

**Step 3: Implement** `app_text.dart` + `app_theme.dart`。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add Inter typography scale and app theme`。

---

## Phase 2 — 数据模型

> 模型为不可变类,带 `const` 构造、`copyWith`、`==`/`hashCode`(可用 `Object.hash`)。每个模型一个测试文件,至少测 `copyWith` 与相等性。

### Task 2.1: SubscriptionTier + UserAccount

**Files:**
- Create: `lib/data/models/user_account.dart`
- Test: `test/data/models/user_account_test.dart`

**Step 1: Write failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/user_account.dart';

void main() {
  test('starter has limit 2; pro is unlimited (null limit)', () {
    const starter = UserAccount(isGuest: false, tier: SubscriptionTier.starter,
        autofillUsed: 0, autofillLimit: 2);
    expect(starter.hasAutofillCredit, isTrue);
    const used = UserAccount(isGuest: false, tier: SubscriptionTier.starter,
        autofillUsed: 2, autofillLimit: 2);
    expect(used.hasAutofillCredit, isFalse);
    const pro = UserAccount(isGuest: false, tier: SubscriptionTier.pro,
        autofillUsed: 99, autofillLimit: null);
    expect(pro.hasAutofillCredit, isTrue); // null = unlimited
  });

  test('guest never has filing access via credit', () {
    const guest = UserAccount.guest();
    expect(guest.isGuest, isTrue);
  });
}
```

**Step 2:** Run, expect FAIL。

**Step 3: Implement** `user_account.dart`:`enum SubscriptionTier { starter, plus, pro }`;`UserAccount` 含 `isGuest`、`tier`、`autofillUsed`、`autofillLimit`(`int?`,null=无限);getter `bool get hasAutofillCredit => autofillLimit == null || autofillUsed < autofillLimit!;`;`const UserAccount.guest()` 工厂(isGuest=true, tier=starter, used=0, limit=2);`copyWith`。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add UserAccount model with autofill credit logic`。

---

### Task 2.2: Lawsuit + LawsuitStatus

**Files:**
- Create: `lib/data/models/lawsuit.dart`
- Test: `test/data/models/lawsuit_test.dart`

**Step 1: Write failing test** —— 构造一个 active 与一个 expired `Lawsuit`,断言 `status`、`payoutValue`、`requiredProof` 列表、`copyWith(status:)` 生效。

**Step 2:** Run, expect FAIL。

**Step 3: Implement** `lawsuit.dart`:`enum LawsuitStatus { active, expired }`;字段 `id, title, brand, category(LawsuitCategory enum 决定图标), status, payoutLabel, payoutValue, deadline(DateTime?), expiredDaysAgo(int?), eligibility(String), requiredProof(List<String>)`;`copyWith`、相等性。`LawsuitCategory` enum(privacy, finance, health, security, other)用于映射图标(图标映射放 UI 层,不放模型)。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add Lawsuit model`。

---

### Task 2.3: FomoSummary / FilingDraft / ClaimProgress / RewardsSummary / SubscriptionPlan

> 拆成 5 个小 Task(2.3a–2.3e),每个:写 copyWith/相等性测试 → FAIL → 实现 → PASS → commit。要点:
- **2.3a FomoSummary**: `missedAmount, upcomingAmount, timeframe(enum {threeMonths, sixMonths})`。
- **2.3b FilingDraft**: `lawsuitId, fullName, address, actionRequiredFields(Map<String,String?> 如 {purchaseYear: null}), uploadedFileName(String?), signatureData(String?)`;getter `bool get isStep1Complete`(所有 actionRequiredFields 非空且有上传文件)、`bool get isStep2Complete`(signatureData 非空)。**测试覆盖这两个 getter 的真/假分支。**
- **2.3c ClaimProgress**: `enum ClaimStage { aiSubmitted, courtReview, settlementApproved, payoutSent }`;`ClaimProgress { ClaimStage currentStage }`;getter `int get stageIndex`、`ClaimProgress advanced()`(推进到下一阶段,封顶 payoutSent)。**测试 advance 推进与封顶。**
- **2.3d RewardsSummary**: `totalEarned(double), pending(double), referralLink(String), invites(List<ReferralInvite>)`;`ReferralInvite { String maskedId; RewardStatus status }`(`enum RewardStatus { pending, credited }`)。
- **2.3e SubscriptionPlan**: `tier, monthlyPrice(double), yearlyPrice(double), features(List<String>), monthlyAutofills(int?)`(null=无限)。

每个 Task 独立 commit。

---

## Phase 3 — Repository 接口 + Mock + Providers

> 模式:先定义抽象接口(纯 Dart,无 Flutter 依赖)→ mock 实现 → Riverpod provider。逻辑性强的(额度扣减、进度推进)用 TDD 测 mock 行为。

### Task 3.1: LawsuitRepository 接口 + Mock + provider

**Files:**
- Create: `lib/data/repositories/lawsuit_repository.dart`(抽象类)
- Create: `lib/data/mock/mock_lawsuit_repository.dart`
- Create: `lib/data/mock/mock_data.dart`(集中放假数据:Facebook 隐私和解 Up to $350、Capital One Data Breach $25 expired 12d、Fitbit Up to $150、Equifax Up to $125 expired 45d,等)
- Create: `lib/data/providers.dart`(集中放 repository providers)
- Test: `test/data/mock/mock_lawsuit_repository_test.dart`

**Step 1: Write failing test**
```dart
// watchActive() 只返回 active;getById 命中返回对应项,未命中返回 null;
// search('fitbit') 大小写不敏感命中 Fitbit;getFomoSummary() 返回非零金额。
```

**Step 2:** Run, expect FAIL。

**Step 3: Implement** 接口(方法见设计文档 §4)+ mock(内存 List + `Future.delayed(Duration(milliseconds:300))` 模拟网络;`watch*` 返回 `Stream`,可用 `Stream.value(...)` 或 `async*`)。`mock_data.dart` 提供 ≥6 条 active + ≥3 条 expired。在 `providers.dart` 定义 `final lawsuitRepositoryProvider = Provider<LawsuitRepository>((ref) => MockLawsuitRepository());`。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add LawsuitRepository interface, mock, and seed data`。

---

### Task 3.2: SubscriptionRepository + accountProvider(额度扣减核心)

**Files:**
- Create: `lib/data/repositories/subscription_repository.dart`
- Create: `lib/data/mock/mock_subscription_repository.dart`
- Create: `lib/features/account/account_provider.dart`(`NotifierProvider<AccountNotifier, UserAccount>`)
- Test: `test/features/account/account_provider_test.dart`

**Step 1: Write failing test** —— 用 `ProviderContainer` 测 `AccountNotifier`:
```dart
// 初始为 guest;register() 后 isGuest=false 且 tier=starter limit=2;
// useAutofillCredit() 使 autofillUsed +1;
// 连用 2 次后 hasAutofillCredit==false;
// upgradeTo(SubscriptionTier.pro) 后 limit==null 且 hasAutofillCredit==true;
// pro 下 useAutofillCredit() 不报错且 used 不影响访问。
```

**Step 2:** Run, expect FAIL。

**Step 3: Implement** `AccountNotifier`(`build()` 返回 `UserAccount.guest()`;`register()`、`continueAsGuest()`、`useAutofillCredit()`、`upgradeTo(tier)`,通过 `state = state.copyWith(...)`)。SubscriptionRepository 提供 `getPlans()`(返回 3 档 mock plan:starter 免费 2 次、plus $2.99/$19.99 5 次/月、pro $5.99/$39.99 无限)。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add account provider with credit/upgrade logic and subscription plans`。

---

### Task 3.3: FilingRepository(草稿预填 + 进度推进)

**Files:**
- Create: `lib/data/repositories/filing_repository.dart`
- Create: `lib/data/mock/mock_filing_repository.dart`
- Add provider 到 `lib/data/providers.dart`
- Test: `test/data/mock/mock_filing_repository_test.dart`

**Step 1: Write failing test** —— `getDraft(lawsuitId)` 返回带 fullName/address 已填、actionRequiredFields 含 null 项的草稿;`submit(draft)` 后 `watchProgress(id)` 起始为 `aiSubmitted`。

**Step 2:** Run, expect FAIL。

**Step 3: Implement。**

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add FilingRepository mock`。

---

### Task 3.4: ReferralRepository(奖励 = 1 个月 Plus)

**Files:**
- Create: `lib/data/repositories/referral_repository.dart`
- Create: `lib/data/mock/mock_referral_repository.dart`
- Add provider
- Test: `test/data/mock/mock_referral_repository_test.dart`

**Step 1: Write failing test** —— `getRewards()` 返回 `totalEarned==120.0, pending==30.0`,`referralLink` 含 `claimpal`;邀请记录里 maskedId 不含真实信息(隐私)。

**Step 2:** Run, expect FAIL。**Step 3:** Implement。**Step 4:** PASS。**Step 5: Commit** `feat: add ReferralRepository mock (1-month Plus reward)`。

---

## Phase 4 — Core:路由、拦截守卫、共享组件

### Task 4.1: accessGuard(拦截逻辑,纯函数)

**Files:**
- Create: `lib/core/guard/access_guard.dart`
- Test: `test/core/guard/access_guard_test.dart`

**Step 1: Write failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/core/guard/access_guard.dart';
import 'package:claimpal/data/models/user_account.dart';

void main() {
  test('guest filing -> requireRegistration', () {
    expect(resolveFilingAccess(const UserAccount.guest()),
        FilingAccess.requireRegistration);
  });
  test('free user with credit -> allow', () {
    expect(resolveFilingAccess(const UserAccount(isGuest: false,
        tier: SubscriptionTier.starter, autofillUsed: 1, autofillLimit: 2)),
        FilingAccess.allow);
  });
  test('free user out of credit -> requirePaywall', () {
    expect(resolveFilingAccess(const UserAccount(isGuest: false,
        tier: SubscriptionTier.starter, autofillUsed: 2, autofillLimit: 2)),
        FilingAccess.requirePaywall);
  });
  test('pro -> allow', () {
    expect(resolveFilingAccess(const UserAccount(isGuest: false,
        tier: SubscriptionTier.pro, autofillUsed: 99, autofillLimit: null)),
        FilingAccess.allow);
  });
}
```

**Step 2:** Run, expect FAIL。

**Step 3: Implement** `enum FilingAccess { allow, requireRegistration, requirePaywall }` 与 `FilingAccess resolveFilingAccess(UserAccount a)`:guest→requireRegistration;else hasAutofillCredit?allow:requirePaywall。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: add filing access guard`。

---

### Task 4.2: 共享组件 — StatusBadge, LawsuitCard

**Files:**
- Create: `lib/core/widgets/status_badge.dart`(从现有 `_StatusBadge` 提取为公共)
- Create: `lib/core/widgets/lawsuit_card.dart`(从现有 `_ClaimCard` 重构,接收 `Lawsuit` 模型 + `onTap`;active/expired 两态:expired 时 0.72 透明、CTA 灰禁用)
- Create: `lib/core/theme/category_icons.dart`(`IconData iconFor(LawsuitCategory)`)
- Test: `test/core/widgets/lawsuit_card_test.dart`

**Step 1: Write failing widget test** —— pump 一个 active `Lawsuit` 的 `LawsuitCard`,`expect(find.text(...title), findsOneWidget)` 且 CTA 可点;pump expired 的,断言 CTA `onPressed == null`(禁用)。

**Step 2:** Run, expect FAIL。

**Step 3: Implement**,复用现有 `claim_tracker_screen.dart` 里的卡片视觉(迁移到接收 `Lawsuit` 模型)。

**Step 4:** Run, expect PASS。

**Step 5: Commit** `feat: extract StatusBadge and LawsuitCard shared widgets`。

---

### Task 4.3: 共享组件 — ClaimStepper, PrivacyBadge, AppBottomSheet, FomoBanner

**Files:**
- Create: `lib/core/widgets/claim_stepper.dart`(水平 4 阶段步进器,接收 `ClaimProgress`,完成步 success 绿、未完成 neutral 灰)
- Create: `lib/core/widgets/privacy_badge.dart`("100% Privacy Protected" + 锁图标)
- Create: `lib/core/widgets/app_bottom_sheet.dart`(半屏 sheet 骨架:圆角顶、抓手、内容 slot)
- Create: `lib/core/widgets/fomo_banner.dart`(渐变看板,接收 `FomoSummary`)
- Test: `test/core/widgets/claim_stepper_test.dart`

**Step 1:** 给 `ClaimStepper` 写 widget 测:`courtReview` 时第 1、2 步为完成态(找到对应数量的对勾/高亮)。

**Step 2:** FAIL → **Step 3:** Implement 四个组件 → **Step 4:** PASS → **Step 5: Commit** `feat: add stepper, privacy badge, bottom sheet, fomo banner widgets`。

---

### Task 4.4: 路由表 + 占位页 + main.dart 接线

**Files:**
- Create: `lib/core/router/app_router.dart`(go_router:`/`, `/tracker`, `/lawsuit/:id`, `/filing/:id`, `/pricing`, `/referral`, `/wallet`;`StatefulShellRoute.indexedStack` 包 Tracker/Explore/MyClaims/Profile 四个 branch)
- Create: 各 feature 下的 `XxxScreen` **占位**(只放标题 Scaffold,后续 Phase 5 填充)
- Modify: `lib/main.dart`(`ProviderScope` + `MaterialApp.router(theme: buildTheme(), routerConfig: ...)`)
- Modify: `lib/app.dart`(可选,封装 MaterialApp)
- Test: `test/core/router/app_router_test.dart`(pump app,`/` 显示游客首页占位;`go('/pricing')` 显示 Pricing 占位)

**Step 1:** Write failing test(路由跳转可达)。

**Step 2:** FAIL → **Step 3:** Implement 路由 + 占位 + main 接线 → **Step 4:** PASS。

**Step 5:** `rtk flutter run -d chrome` 手动确认能启动到游客首页占位(冒烟)。

**Step 6: Commit** `feat: wire go_router with shell route and placeholder screens`。

---

## Phase 5 — 界面实现(逐屏,对照 Stitch)

> 每屏一个 Task。实现前**先 Read 对应 `code.html` 与查看 `screen.png`** 还原布局/文案/间距,颜色走 `AppColors`。数据通过 Riverpod provider 注入,异步用 `.when(data/loading/error)`。每屏至少 1 个 widget smoke test(渲染关键文案不崩)。

### Task 5.1: Tracker 首页(接 provider)
- 参照 `lawsuit_tracker_home`。把现有 `lib/features/home/widgets/claim_tracker_screen.dart` 重构为消费 `activeLawsuitsProvider`/`expiredLawsuitsProvider` 与 `homeFilterProvider`(显示过期 Toggle、时间范围),卡片改用共享 `LawsuitCard`,点击 CTA 走 `accessGuard`。测试:有数据时渲染卡片;Toggle 关时不显示 expired。Commit。

### Task 5.2: 游客 FOMO 首页
- 参照 `guest_home_fomo_driven`。顶部 `FomoBanner`(接 `fomoSummaryProvider`)、控制面板(Toggle+时间范围过滤)、混合信息流。游客点卡片→进详情;点 "File Claim"→走 `accessGuard`(guest→注册 sheet)。Commit。

### Task 5.3: 诉讼详情页(自建)
- 参照设计系统 + PRD §三.2。`/lawsuit/:id` 读 `lawsuitRepositoryProvider.getById`;id 不存在显示占位。展示品牌 Logo、预计金额、申请资格、所需证明列表、底部 "File Claim" CTA(走 `accessGuard`)。Commit。

### Task 5.4: 注册拦截 sheet
- 参照 `registration_pop_up`。`showAppBottomSheet` 半屏;表单(邮箱/社交登录 mock);提交调 `AccountNotifier.register()`;成功后关闭并继续原"申请"动作。测试:出现关键文案。Commit。

### Task 5.5: Paywall sheet
- 参照 `claimradar_paywall_pop_up`。额度用尽时弹;文案带当前诉讼金额;月/年切换;$2.99/$5.99 两档;Apple/Google Pay 按钮(mock);底部 "邀请好友免费解锁 1 个月 Plus" → 跳 `/referral`。点套餐→`AccountNotifier.upgradeTo`(mock 升级)。Commit。

### Task 5.6: AI 代填 第 1 步
- 参照 `ai_1_click_smart_filing_step_1_1` + `_1_2`。读 `filingControllerProvider(id)` 的草稿;"AI Autofill Ready" 微光标签;已填姓名/地址 + 绿勾;Action Required 区(购买年份输入框 + 虚线上传框,上传用 mock 文件名)。`isStep1Complete` 为真才启用"下一步"。Commit。

### Task 5.7: AI 代填 第 2 步(签名)
- 参照 `ai_1_click_smart_filing_step_2`。免责声明容器;手写签名板用 `GestureDetector`+`CustomPainter` 自绘(把笔迹序列化成字符串存 `signatureData`,空则禁用提交);盾牌图标 "Authorize & Submit via AI" 按钮。点提交:`FilingRepository.submit` + `AccountNotifier.useAutofillCredit()`(Pro 跳过)→ 跳成功页。Commit。

### Task 5.8: AI 代填 成功页 + 进度
- 参照 `ai_1_click_smart_filing_success_1` + `_2`。满屏绿色勾选动画(`AnimatedScale`/`TweenAnimationBuilder`);下方 `ClaimStepper`(接 `claimProgressProvider`,起始 aiSubmitted)。Commit。

### Task 5.9: 订阅套餐页
- 参照 `claimradar_pricing_plans`。月/年切换;Starter/Plus/Pro 三档卡片(接 `subscriptionPlansProvider`);选档 mock 升级。Commit。

### Task 5.10: 裂变 + 钱包页
- 参照 `claimpal_referral_dashboard` + `referral_rewards_dashboard` + `referral_earnings_dashboard`(合并)。接 `rewardsProvider`:Total Earned $120(翠绿)/ Pending $30(灰)、提现按钮(mock SnackBar);"Give 1 Month, Get 1 Month" 推荐卡;`PrivacyBadge`;复制链接(`Clipboard.setData` + SnackBar 确认);社交分享图标(mock)。Commit。

### Task 5.11: My Claims / Profile 占位页
- 底部 Tab 的另两个分支。My Claims:用 `FilingRepository` 已提交项做简单 `ClaimStepper` 列表(没有则空态)。Profile:占位(头像、订阅档 chip、升级入口跳 `/pricing`)。Commit。

---

## Phase 6 — 整合与导航打磨

### Task 6.1: 底部导航接线 + 首页→Tracker 登录跳转
- 确认 `StatefulShellRoute` 四 Tab 切换保留各自栈;游客在 `/`,注册后默认落 `/tracker`。冒烟测试 Tab 切换。Commit。

### Task 6.2: 全局错误/加载态收口
- 抽一个 `AsyncValueView`(或统一 `.when` helper):loading→骨架,error→重试按钮文案。各页接入。Mock 加"模拟失败"开关(`mock_data.dart` 顶部 const)。Commit。

---

## Phase 7 — 验证

### Task 7.1: 静态分析 + 全量测试
```bash
rtk flutter analyze        # Expected: No issues found
rtk flutter test           # Expected: All tests passed
```
不过不准进入 7.2。修到全绿,Commit 修复。

### Task 7.2: Web 跑通主闭环(手动 + 截图)
```bash
rtk flutter run -d chrome
```
走通:游客首页 → 点 File Claim 弹注册 → 注册 → 进详情/代填三步(预填→上传→签名→授权)→ 成功页时间轴 → 底部 Tab 切换 → 裂变/钱包/订阅页可达 → 用尽免费额度后再申请弹 Paywall。

用 Playwright/Chrome 在手机视口(如 390×844)截关键页,与 `stitch_class_action_settlement_tracker/<screen>/screen.png` 比对还原度,记录差异。

> **REQUIRED SUB-SKILL:** 验证阶段用 superpowers:verification-before-completion —— 先有证据(命令输出/截图)再宣称完成。

### Task 7.3: 完结分支
- 全绿且闭环可演示后,用 superpowers:finishing-a-development-branch 决定合并/PR。

---

## 附:执行顺序与依赖

Phase 0 → 1 → 2 → 3 → 4 必须顺序完成(后者依赖前者)。Phase 5 各屏在 Phase 4 完成后**可并行**(彼此独立,只依赖共享组件与 provider),但建议先做 5.1/5.2(首页)再做拦截链 5.4/5.5,再做代填链 5.6→5.7→5.8。Phase 6、7 最后。
