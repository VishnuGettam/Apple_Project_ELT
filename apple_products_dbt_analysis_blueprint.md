# Apple Products — dbt Analytics Blueprint

> A reference document for building a dbt project on Apple product data ingested into Snowflake via Snowpipe from S3.

---

## 1. Dataset Overview

**Source**: Apple products CSV (Flipkart catalog data) ingested into Snowflake via Snowpipe from S3.

**Row count**: 62 product variants

**Columns available**:

| Column | Type | Notes |
|--------|------|-------|
| `Product Name` | string | Contains model, color, storage — needs parsing |
| `Product URL` | string | Flipkart product link |
| `Brand` | string | Always "Apple" — drop or use as filter |
| `Sale Price` | numeric | Current selling price (INR) |
| `MRP` | numeric | Maximum retail price (INR) |
| `Discount Percentage` | numeric | Precomputed discount |
| `Number Of Ratings` | numeric | Total rating count |
| `Number Of Reviews` | numeric | Total review count |
| `UPC` | string | Unique product code |
| `Star Rating` | numeric | Average star rating (1–5) |
| `RAM` | string | e.g. "2 GB", "4 GB" — needs casting |

**Models present**: iPhone 8, iPhone 8 Plus, iPhone XR, iPhone XS Max, iPhone 11 / 11 Pro / 11 Pro Max, iPhone 12 / 12 Mini / 12 Pro / 12 Pro Max, iPhone SE.

---

## 2. Suggested dbt Project Structure

A layered approach following dbt best practices:

```
models/
├── staging/
│   └── stg_apple_products.sql        -- rename cols, cast types, basic cleanup
├── intermediate/
│   ├── int_products_parsed.sql       -- extract model, color, storage_gb from name
│   └── int_product_metrics.sql       -- derive price_per_gb, engagement score, etc.
└── marts/
    ├── dim_products.sql              -- clean product dimension
    ├── fct_product_summary.sql       -- one row per product with all metrics
    ├── agg_model_pricing.sql         -- aggregated by model
    ├── agg_storage_economics.sql     -- aggregated by storage tier
    └── agg_color_variants.sql        -- aggregated by color
```

**Materialization recommendation**:
- `staging/` → views
- `intermediate/` → views
- `marts/` → tables

---

## 3. Key Transformations (Intermediate Layer)

The heaviest lifting is parsing `Product Name`. Here's what to derive:

| Derived field | Source / Logic | Example |
|---------------|---------------|---------|
| `model_name` | Extract from name | `iPhone 11 Pro Max` |
| `model_family` | Strip Pro/Plus/Max suffix | `iPhone 11` |
| `color` | Inside parentheses | `Gold`, `Space Grey` |
| `storage_gb` | Inside parentheses (GB) | `64`, `128`, `256` |
| `ram_gb` | Cast "2 GB" → 2 | `2`, `4` |
| `is_premium` | Pro/Pro Max flag | boolean |
| `price_per_gb` | sale_price / storage_gb | numeric |
| `discount_amount` | mrp - sale_price | numeric |
| `engagement_score` | ratings + reviews | numeric |

---

## 4. Analyses to Build (Marts Layer)

### 4.1 Pricing & Discount Analysis
- Average sale price and MRP by model
- Discount % distribution — which models are discounted vs sold at MRP?
- Discount strategy: do older models have higher discounts? (lifecycle hypothesis)
- Premium positioning: Pro/Pro Max discount behavior vs standard models

### 4.2 Storage Economics
- Price-per-GB across storage tiers (64 / 128 / 256)
- Which storage tier offers best value-for-money?
- Premium charged for jumping 64 → 128 → 256 GB
- Compare same model across storage variants (e.g., iPhone 11 64GB vs 256GB)

### 4.3 Customer Engagement & Satisfaction
- Top products by total ratings and reviews
- Review-to-rating ratio (how engaged are reviewers?)
- Star rating spread across models
- Correlation: does price relate to satisfaction?
- Engagement leaders vs sales leaders (proxy)

### 4.4 Product Variant Analysis
- Number of color variants per model
- Number of storage variants per model
- Does color affect pricing? (usually shouldn't, but verify)
- Most "complete" SKU lineup — which model has the most variants?

### 4.5 Model Generation Comparison
- Compare iPhone 8 → XR → 11 → 12 evolution in:
  - Price trajectory
  - Discount behavior
  - Customer engagement
- Standard vs Pro vs Pro Max tier analysis within the same generation

### 4.6 Top Performers Dashboard
- Top 10 products by engagement
- Top 10 products by discount
- Best-value products: high star rating + lower price-per-GB

---

## 5. Business Insights You Can Project

Once the models above are built, you'll likely surface these story-level insights:

1. **"Pro/Pro Max models hold their pricing"** — flagship models sell at MRP with 0% discount, while standard models (XR, 11) get meaningful discounts (16–29%). Apple's premium tier is discount-resistant.

2. **"iPhone XR is the engagement king"** — dramatically more ratings/reviews (~79k+ ratings) than any other model, suggesting it was the volume seller of its generation. Popular models drive engagement.

3. **"Storage premium is non-linear"** — going from 64GB → 256GB doesn't quadruple the price even though storage does. There's a sweet spot for value (usually 128GB).

4. **"Customer satisfaction is uniformly high"** — star ratings cluster between 4.5–4.7 across all models. Star rating alone isn't a differentiator; reviews/ratings volume is the real popularity signal.

5. **"Color doesn't drive price"** — same model across colors has identical pricing, so color is purely a preference dimension, not a pricing lever.

6. **"Older generations get cleared out"** — iPhone XR (older) has the biggest discounts; iPhone 12 Pro Max (newer flagship) has zero. Classic lifecycle pricing.

7. **"RAM scales with generation, not tier"** — newer models have more RAM regardless of Pro/standard, useful for spec-evolution storytelling.

---

## 6. dbt Best Practices to Apply

### Sources
Declare the Snowpipe-loaded raw table as a dbt source:

```yaml
# models/staging/_sources.yml
sources:
  - name: raw_apple
    database: <your_raw_db>
    schema: <your_raw_schema>
    tables:
      - name: apple_products
        loaded_at_field: _loaded_at
        freshness:
          warn_after: {count: 24, period: hour}
```

### Tests
Add tests at the staging layer:

```yaml
# models/staging/_models.yml
models:
  - name: stg_apple_products
    columns:
      - name: upc
        tests:
          - unique
          - not_null
      - name: sale_price
        tests:
          - not_null
      - name: storage_gb
        tests:
          - accepted_values:
              values: [64, 128, 256]
```

### Documentation
- Add `description:` to every model and column
- Run `dbt docs generate && dbt docs serve` to view the DAG
- Useful for spotting structural issues early

### Optional Enhancement — Release Year Seed
The dataset has no time/date dimension. Add a seed file mapping each model to its release year:

```csv
# seeds/model_release_years.csv
model_family,release_year
iPhone 8,2017
iPhone XR,2018
iPhone XS,2018
iPhone 11,2019
iPhone SE,2020
iPhone 12,2020
```

This unlocks:
- Age-vs-discount analysis
- Generation-over-generation pricing evolution
- "Years on market" as a discount predictor

A single seed file turns this from a snapshot into a lifecycle analysis.

---

## 7. Suggested Build Order

1. **Set up sources** — declare raw table in `_sources.yml`
2. **Build staging** (`stg_apple_products.sql`) — clean column names, type casts
3. **Add basic tests** — unique, not_null on UPC and key fields
4. **Build intermediate** — parse product name into model/color/storage
5. **Build marts** — start with `dim_products` and `fct_product_summary`
6. **Build aggregations** — one mart per analysis area (pricing, storage, engagement)
7. **Add the release year seed** — enrich with lifecycle data
8. **Generate docs** — `dbt docs generate && dbt docs serve`

---

## 8. Quick Reference: Useful dbt Commands

```bash
dbt deps                       # install packages
dbt seed                       # load CSV seeds
dbt run                        # build all models
dbt run --select staging       # build only staging
dbt run --select +fct_product_summary  # build model and its dependencies
dbt test                       # run all tests
dbt docs generate              # generate documentation
dbt docs serve                 # serve docs on localhost:8080
```

---

*Good luck with the project! 🛠️*
