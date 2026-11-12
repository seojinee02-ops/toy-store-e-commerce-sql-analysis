# Analysis Notes - Toy Store E-commerce SQL Portfolio

 ## 1. Revenue & Sales Performance
 
 **Business question:** How did sales and profitability evolve over time?
 
 **Method:** Aggregated 'orders' by 'DATE_TRUNC('month', created_at)' to calculate order count, revenue, units purchased, average order value (AOV), gross profit and gross margin.

 **Observation:** December 2014 had the highest monthly revenue and gross profit in the examined period.

 **Interpretation / limitation:** The dataset covers March 2012 to March 2015; the first and last months are incomplete. Month-to-month comparisons involving those months should be interpreted cautiously. Gross profit is calculated before refund adjustments.

 ##2. Marketing & Conversion

 **Business questions:** Which sources and devices generate purchases most effectively?

 **Observations:**
- Overall session-to-order conversion: desktop **8.50%**; mobile **3.09%**.
- bsearch has a higher aggregate conversion rate(**7.19%**) than gsearch (**6.75%**).
- Within each device, gsearch has a higher rate: desktop **8.43%** vs. bsearch **7.85%**; mobile **3.17%** vs bsearch **3.01%**.
- The share of mobile traffic differs between sources(approximately **31.9%** for gsearch and **13.6%** for bsearch), consistent with a Simpson's paradox aggregation reversal.

**Business implication:** Compare marketing channels within device segments before drawing conclusions from aggregate conversion rates. Do not interpret this observational analysis as proof that a channel or device causes higher conversions.

**Data-quality note:** Some missing UTM/referrer values were imported as the literal string `'NULL'`, rather than SQL 'NULL'. 'NULLIF(utm_source, 'NULL')' is useful when standardizing these values. An unattributed source is not necessarily direct traffic.

## 3. Customer Journey & Purchase Funnel

**Business question:** At which stages do sessions drop off, and how does performance differ by device(desktop/mobile)?

**Method:** For each 'website_session_id', used conditional 'MIN(created_at)' to identify the first recorded visits to product listing, cart, shipping, billing('/billing' or '/billing-2') and thank-you pages. Classified progression using timestamp comparisons. 

**Overall results:**

| Stage | Sessions | Conversion from previous stage | 
| ---|---:|---:|
| Product listing | 261,231 | Starting cohort | 
| Cart | 94,953 | 36.35% |
| Shipping | 64,484 | 67.91% |
| Billing | 52,058 | 80.73% | 
| Thank-you page | 32,313 | 62.07% |

**Device-level observations:**
- Product-to-purchase progression: desktop **14.46%**, mobile **6.54%** (among sessions reaching '/products').
- Product-to-cart conversion: desktop **39.08%**, mobile **28.73%**.
- The largest desktop-mobile percentage-point gap between adjacent funnel stages was **Shipping -> Billing**: desktop **82.98%**, mobile **70.69%** (difference **12.29 percentage points**).

**Business implication:** Prioritize investigating the product-to-cart experience (the largest overall drop-off stage) and the mobile shipping-to-billing journey (the largest desktop stage gap). Suggested explanations such as form friction are hypotheses, not measured causes.

**Limitations / validation still needed:**
- This is a **first-visit timestamp funnel**. Repeated or out of order page visits may be misclassified, and the strict sequence is not guaranteed to capture every valid journey.
- The final funnel stage uses the **thank-you page** as a purpose proxy; validate session-level agreement with the 'orders' table.
- This funnel begins at '/products', so its **12.37%** overall product-to-purchase rate is not the same as site-wide session-to-order conversion.

## 4. Product Performance & Refunds 

**Business question:** Which product contribute the most revenue and profit, and which have the highest refund rates? 

**Method:** Joined 'order_items' with 'products' on 'product_id'; joined refunds on 'order_item_id'. Aggregated product-level units, sales, pre-refund gross profit, gross margin, refunded items and refunded amount. 

**Observations:**
- **The Original Mr. Fuzzy** generated about **$1,211,058** in revenue (approximately **62.47%** of product revenue) and about **$738,893** in gross profit, reflecting a concentration of sales in one proudct.
- **The Birthday Sugar Panda** had the highest gross margin (**68.49%** ) and highest item refund rate (**6.04%**).
- **The Original Mr. Fuzzy** had the highest total refunded amount (approximately **$61,838**), despite a lower refund rate (**5.11%**) than Sugar Panda.
- **The Hudson River Mini Bear** had the lowest item refund rate (**1.28%**).

**Business implication:** Examine both scale and efficiency when evaluating products. A high-margin product can also have a high refund incidence; a high-volume product can contribute the largest absolute refund cost. 

**Limitations:**
- 'units_sold' counts order-item rows, assuming one sold unit per row in this dataset.
- The refund rate represents **distinct refunded order items / distinct sold order items**, not the share of revenue refunded.
- Gross profit here is **pre-refund** and excludes other operating/marketing costs; avoid calling it net profit.
- Product launch timing may vary; lifetime sales are not normalized for selling period.

## Portfolio recommendations / next checks
- Re-run the finalized SQL files in pgAdmin and compare outputs with the figures above.
- Validate thank-you-page sessions against actual 'orders' records by 'website_session_id'.
- Add a source and any reuse/licensing restrictions for the dataset before making the repository public.
- Present the main findings as observations, clearly seaprating hypotheses and limitations. 


