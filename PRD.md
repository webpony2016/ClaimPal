PRODUCT REQUIREMENTS DOCUMENT (PRD)
Project Name: ClaimPal (by LawPal)
Target Market: United States & Canada (US/CA)
Platform: iOS & Android (Cross-platform Mobile App)
Core Mission: A bank-grade legal-tech application that scans, tracks, and facilitates 1-click filing for Class Action Lawsuit settlements using a frictionless Freemium Subscription model.


1. System Architecture & Business Logic
1.1 Commercialization (3-Tier In-App Subscription)
All subscriptions utilize Apple App Store and Google Play In-App Purchases (IAP).
• Starter Plan (Free): Includes exactly 2 lifelong AI Smart-Filing credits. Basic push notification alerts.
• Plus Plan ($2.99/mo or $19.99/yr): Up to 5 AI Smart-Filings per month. Priority deadline alerts. Access to the past 6-month expired dashboard.
• Pro Plan ($5.99/mo or $39.99/yr): Unlimited AI Smart-Filings. Instant real-time alerts. Prioritized dedicated audit support.
1.2 Viral Growth Mechanics ("Give 1 Month, Get 1 Month")
• Trigger: A non-paying/paying user shares a custom referral link (://claimpal.com).
• Condition: When the referred friend registers via email AND successfully executes their first AI Smart-Filing.
• Reward: Both the referrer and the friend automatically receive 30 Days (1 Month) of Plus Premium membership for free. This can stack infinitely.
• Privacy Guard (Crucial for US/CA): The ledger must remain 100% anonymized. No user can see what lawsuits their friends filed or the compensation amounts.
1.3 Compliance & Fund Flow
• No Escrow/Trusting: ClaimPal never handles, touches, or routes the settlement funds (to avoid North American MSB and Anti-Money Laundering regulatory audits).
• Direct Payouts: 100% of settlement funds are routed directly from Court-appointed Administrators (Epiq, JND, KCC) to the user's personal PayPal, bank account, or mailing address.


2. Backend Scraper & Sync Logic
2.1 Scraping Flow
• Sources: Automated scraping targeting Top Class Actions, ClassAction.org, CanLII, and CourtListener RSS feeds.
• LLM Sanitization: Markdown scraped code is passed via backend API to an LLM to generate structured JSON formats (Fields: Brand, Max_Payout, Deadline, Eligibility_Criteria, Proof_Required).
2.2 Human-In-The-Loop Approval (Admin Dashboard)
• Scraped items go into a pending pool. A Web-based Admin Dashboard lets the admin click "Approve & Publish".
• Upon approval, the database increments a global telemetry key: data_version (e.g., from v102 to v103).
2.3 Incremental Sync Data Flow
• The mobile client stores a local cache version ID (e.g., v102).
• On app startup, or via twice-daily background polling, the client makes a lightweight GET /api/check-version request.
• If the remote version is higher (v103), the client requests only the delta/new rows created between v102 and v103 and merges them locally into SQLite/Realm.
• Active States: Lawsuits where deadline > current_date.
• Recently Expired States: Lawsuits where deadline < current_date AND current_date - deadline <= 180 days (6 months). Show as grayed-out/muted card by default, with a native setting allowing the user to hide expired items completely.
