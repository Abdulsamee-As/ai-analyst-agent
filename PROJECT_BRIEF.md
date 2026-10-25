# AI Analyst Agent: Project Brief

> This file describes the project for the portfolio website. Use it as the single source of truth when writing the project page. All numbers below are real results from the project.

## One-line summary

An automated n8n workflow that pulls sales data from PostgreSQL, calculates KPIs with SQL, detects unusual numbers with Python z-scores, and sends an AI agent to investigate them by writing its own SQL queries. It then emails a formatted report and logs every finding to the database.

## The problem

Dashboards show **what** happened, but someone still has to dig into **why**. When a number looks wrong, an analyst has to slice the data by region, category and product to find the cause. That takes time every week.

## The solution

A workflow that does the first round of investigation automatically:

1. Calculates the monthly KPIs with SQL
2. Uses statistics (z-scores) to flag numbers that are unusual compared to their own history
3. Sends only the unusual ones to an AI agent
4. The agent writes its own SQL queries to drill down and find the likely cause
5. A formatted email report goes out, and every finding is saved to a history table

**Core rule of the design: code does the math, AI explains the story.** The LLM never calculates numbers itself. Every number comes from SQL or Python.

## Tech stack

- **n8n** (workflow automation, n8n Cloud)
- **PostgreSQL** hosted on **Supabase**
- **SQL** (CTEs, window functions, FILTER, json_build_object, json_agg)
- **Python** (Code node, z-score anomaly detection written from scratch with no libraries)
- **JavaScript** (Code nodes that build the HTML email)
- **Google Gemini** (gemini-3.8-flash) as the agent's language model
- **Gmail** for report delivery
- **Dataset:** Kaggle Sample Superstore (9,994 order lines, 2014-01-03 to 2017-12-30)

## Workflow architecture

```
Schedule Trigger (Mondays 9 AM, Asia/Karachi)
  -> get KPI (Postgres: one SQL query returns all KPIs as one JSON item)
  -> Get History (Postgres: monthly sales and profit per region and sub-category, 974 rows)
  -> Detect Anomalies (Python: z-score per region and sub-category)
  -> Anomalies Found? (IF node)
       TRUE  -> Investigate Anomalies (AI Agent)
                  sub-nodes: Gemini Chat Model + Query Sales Database (read-only Postgres tool)
                -> Build Email (JavaScript: HTML report)
                     -> Send Report (Gmail)
                     -> Split Out -> Save to Insights Log (Postgres insert)
       FALSE -> Build Normal Email (JavaScript: KPI-only report) -> Send Report (Gmail)

Separate workflow: AI Analyst Error Alert (Error Trigger -> Gmail) fires if any automatic run fails.
```

## How it works, step by step

### 1. Data layer (raw to clean pattern)
- The Kaggle CSV was loaded as-is into a `raw_superstore` table.
- A clean `sales` table was built with SQL: snake_case column names, text dates converted to real DATE type with TO_DATE, postal codes restored as 5-character text with LPAD (leading zeros were lost when stored as numbers), and money stored as exact NUMERIC instead of double precision.
- Sanity checks confirmed 9,994 rows, no missing postal codes, no ship dates before order dates, no zero or negative sales. Totals matched published analyses of the dataset: sales 2,297,200.86 and profit 286,397.02.
- Lesson learned on the way: the first import failed because Order ID was set as the primary key, but one order has many product lines. The grain of the table is one product line per row, so Row ID became the key.

### 2. KPIs in one SQL query
- The query finds the latest month by itself with MAX(order_date), so the report moves forward automatically when new data arrives.
- It compares the current month with the previous month: sales, profit, margin, orders and growth, broken down by region and sub-category, plus the 10 worst loss-making products.
- Everything is packed into a single JSON item with json_build_object and json_agg. This matters because an n8n node runs once per incoming item, so one item keeps the whole workflow running exactly once.

### 3. Anomaly detection in Python
- For each region and sub-category, the latest month is compared with its own past months.
- z = (this month - historical average) / standard deviation. Flagged if z is above 2 or below -2.
- Mean and sample standard deviation are calculated by hand, because the n8n Cloud Python node cannot import libraries.

### 4. The AI agent
- Runs only when anomalies are found (IF node), which saves cost.
- Receives the overall KPIs and the top 5 anomalies.
- Has one tool: a Postgres query tool. It writes its own SELECT queries to drill down by region, category, sub-category and product, checks discounts, and compares with the same month in previous years to account for seasonality.
- Strict rules in the system prompt: never do math in its head, never invent numbers, maximum 3 queries, small results only.
- Returns its findings as JSON (title, what happened, likely cause, recommendation, severity), which the JavaScript node parses.

### 5. Safety
- The agent connects with a separate **read-only database role** (`ai_reader`) that can only SELECT from the sales table. It cannot see other tables and cannot change or delete anything.
- Row Level Security is enabled, with a policy that lets only this role read the rows.
- A 10-second statement timeout stops runaway queries.
- Writes to the insights log use a different credential, so the AI never has write access.

### 6. Outputs and reliability
- HTML email with KPI cards, a manager summary and colour-coded findings (red for high, orange for medium).
- Every finding is saved to an `insights_log` table with an auto ID and timestamp, building a history over time.
- Retry on fail for the AI node, plus a separate error workflow that emails an alert with the failed node and error message.
- Both branches of the IF node were tested before going live.

## Real results (December 2017 run)

**KPIs:** Sales $83,829.32, sales growth -29.23% vs November, profit $8,483.35, margin 10.12%.

**Finding 1 (medium): Storage profit spike.** Storage profit reached $1,394.12 against a normal monthly average of $423.08 (z-score 2.71). The agent traced it to strong West region volume with an average discount of only about 2%.

**Finding 2 (high): Appliances sales up, but discounts caused losses.** Appliances sales reached $6,516.83 against a normal average of $2,149.26 (z-score 2.54). The agent found that the Central region lost $427.00 on Appliances with an average discount of 40%.

### Verification (the AI's claim checked manually with SQL)

| Region  | Appliances sales | Profit  | Avg discount |
|---------|------------------|---------|--------------|
| Central | 2,591.53         | -427.00 | 40.0%        |
| West    | 423.42           | 130.94  | 4.0%         |
| South   | 640.00           | 172.91  | 10.0%        |
| East    | 2,861.88         | 813.59  | 2.9%         |

**Key insight:** Central and East sold almost the same amount of Appliances, but Central gave 40% discounts and lost $427, while East gave 2.9% and earned $814. Same sales, opposite result, purely because of discounting. The agent found this on its own, and the numbers matched exactly when checked by hand.

## Challenges and lessons learned

- **Free-tier AI limits are built for chatting, not agents.** One agent run sends several requests (one per thinking step and query), and each step re-sends the whole conversation, so token use grows fast. Free tiers ran out quickly during testing. Fixes: smaller prompts, a tool description that forces small query results (no SELECT *, max 20 rows, filter with WHERE), a query cap and an iteration cap.
- **Structured output parser loop.** With n8n's Structured Output Parser, the Gemini agent kept failing at the final "submit answer" step and hit the iteration limit. Switching to plain JSON output defined in the system prompt, parsed in JavaScript, fixed it.
- **Unusual is not the same as bad.** The z-score flags what is unusual for each sub-category's own history. Binders lost the most money but were not flagged, because losses are normal for Binders. A future version should also send the worst loss-makers to the agent.
- **Seasonality.** A simple z-score compares December with all months. The agent is instructed to compare with the same month in earlier years before calling a change unusual.
- **Mock data during development.** The AI node was pinned with sample output while building the email and logging steps, so no API quota was wasted.

## Possible next steps

- Send loss-making products to the agent as well as statistical anomalies
- Seasonal baseline (same month last year) inside the Python step
- A Power BI dashboard on top of the insights_log table to track recurring problems
- Slack or Teams alerts for high-severity findings

## Skills demonstrated

SQL (advanced queries, data cleaning, data modelling, roles and permissions), Python (statistics from scratch), JavaScript, workflow automation, AI agent design and prompt engineering, tool design for LLMs, data validation, security thinking (least privilege, RLS), error handling, and verifying AI output against source data.

## Images (in the images folder)

| File | Caption |
|------|---------|
| canvas.png | The full n8n workflow, from schedule trigger to email and database log |
| agent-sql.png | A SQL query written by the AI agent itself, with the real rows it got back |
| email-report.png | The automated email report with KPI cards and AI findings |
| verification.png | Manual SQL check confirming the agent's Central vs East discount finding |
| insights-log.png | Findings saved automatically to the insights_log table |

## Notes for the page

- Tone: clear and practical, aimed at recruiters and hiring managers for Data Analyst, BI Analyst and Analytics Engineer roles.
- Lead with the problem and the result (the Central vs East insight), then show how it works.
- Highlight the design rule "code does the math, AI explains the story" and the read-only safety design.
- Never publish passwords, API keys, Supabase host names, project IDs or email addresses.
