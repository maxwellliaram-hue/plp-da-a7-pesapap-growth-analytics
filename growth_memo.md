# Memo: Roll out the simplified onboarding screen

**To:** Head of Growth, PesaPap  **From:** Growth Analytics  **Date:** 10 November 2026

## Result
Group B (simplified sign-up screen) converted **13.8%** of users versus **10.5%** for group A (control): **+3.3 percentage points, a 32% relative lift**. The chi-square test gives p = 0.005, so the gap is very unlikely to be chance. The 95% confidence interval for the difference is **+1.0 to +5.7 points**: the screen almost certainly helps, but the size of the gain is uncertain.

## Impact
At the current pace of about 760 sign-ups a month, rollout adds roughly **25 converted users a month (about 305 a year; range 90 to 520)**. At about KES 4,000 of transaction value per converted user, that is about **KES 1.2M of extra annual transaction value (range KES 0.4M to 2.1M)**, or about **KES 18,000 of annual revenue** at an assumed 1.5% take rate. The absolute shilling gain is small at today's volume, but it scales directly with sign-ups and the change costs little to ship.

## Recommendation
1. **Roll out variant B to all new users**, keeping a 5% holdout on the old screen for two months to confirm the lift persists.
2. **Run a win-back campaign on the "At Risk" RFM segment first**: 503 users who transacted about 3.8 times each (avg KES 5,000, 23% of all value) but have been silent for about 50 days.
3. Ask data engineering to fix signup-date capture (see caveats) before the next growth review.

## Caveats
- **Group sizes are slightly uneven** (1,443 A vs 1,557 B; sample-ratio test p = 0.04). Covariates (county, channel, signup month) are balanced, but assignment should be confirmed as random.
- **31% of transactions (KES 5.0M) are dated before the user's signup**, which is impossible. I kept them in headline totals and excluded them from RFM and cohort analysis; all money figures are sensitive to this.
- **Partial months:** January starts on 15 Jan and June ends on 13 Jun, so month-over-month changes involving them are not real growth or decline. Full-month value growth is +6.9%, +2.0%, +3.1% (Mar to May).
- **"Converted" is not defined in the data**; I assumed it means an activated, transacting user. The take rate (1.5%) and value per converted user are assumptions, and marginal converters may be less valuable than average.
- The confidence interval is wide, the test ran for one window only, and novelty effects were not tested.
