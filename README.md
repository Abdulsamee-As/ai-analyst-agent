# AI Analyst Agent (n8n + PostgreSQL + SQL + Python + Gemini)

An automated workflow that calculates monthly sales KPIs in SQL, flags unusual
numbers with Python z-scores, then sends an AI agent to write its own SQL queries
and work out *why*. It emails a formatted report and logs every finding to the
database.

**Design rule: code does the math, AI explains the story.** The language model
never calculates a number. Every figure comes from SQL or Python.

📄 **Full case study:** https://abdulsamee-portfolio.netlify.app/projects/ai-analyst-agent

## The problem

Dashboards show *what* happened. Someone still has to dig into *why* — slicing by
region, category, sub-category and product, then checking whether discounting
explains it. That's the same hour of work every week, and it's the part dashboards
never automate.

## How it works

```
Schedule Trigger (Mondays 9 AM)
  → get KPI          (Postgres: all KPIs returned as one JSON item)
  → Get History      (Postgres: monthly sales/profit per region & sub-category, 974 rows)
  → Detect Anomalies (Python: z-score per group, no libraries)
  → Anomalies Found? (IF)
       TRUE  → Investigate Anomalies (AI Agent + read-only Postgres tool)
               → Build Email (JS) → Send Report (Gmail)
                                  → Save to Insights Log (Postgres)
       FALSE → Build Normal Email (JS) → Send Report (Gmail)
```

A separate error workflow emails an alert if any automatic run fails.

## What it found (December 2017 run)

Sales $83,829.32 (−29.23% MoM), profit $8,483.35, margin 10.12%. Two anomalies
cleared the z-score threshold:

- **Storage profit spike** (medium) — $1,394.12 against a normal average of
  $423.08, z = 2.71. Traced to strong West volume at ~2% average discount.
- **Appliances growing while losing money** (high) — sales $6,516.83 against a
  normal average of $2,149.26, z = 2.54. The Central region lost $427.00 on
  Appliances at a 40% average discount.

**The insight:** Central and East sold almost identical volumes of Appliances.
Central discounted at 40% and lost $427. East discounted at 2.9% and made $814.
Same sales, opposite result, purely because of discounting — and the agent reached
it on its own in three queries. Verified by hand in SQL; the numbers matched exactly.

| Region  | Appliances sales | Profit  | Avg discount |
|---------|------------------|---------|--------------|
| Central | 2,591.53         | −427.00 | 40.0%        |
| West    | 423.42           | 130.94  | 4.0%         |
| South   | 640.00           | 172.91  | 10.0%        |
| East    | 2,861.88         | 813.59  | 2.9%         |

## Safety

The agent connects through a dedicated read-only role (`ai_reader`) that can only
`SELECT` from the sales table. Row Level Security is enabled, a 10-second statement
timeout kills runaway queries, and writes to the insights log use a different
credential — so the agent never holds write access at any point.

## Repository

| Path | What it is |
|---|---|
| `sql/` | Data cleaning, sanity checks, the KPI query, the read-only role, verification |
| `prompts/` | Agent system message, Postgres tool description, user prompt |
| `code/detect_anomalies.py` | Z-score anomaly detection, written without libraries |
| `code/build_email.js` | Builds the HTML report from the agent's JSON |
| `results/` | The December 2017 report |
| `workflow/` | n8n workflow exports |
| `PROJECT_BRIEF.md` | Full write-up: architecture, lessons learned, next steps |

## Stack

n8n · PostgreSQL (Supabase) · SQL (CTEs, window functions, `FILTER`,
`json_build_object`, `json_agg`) · Python · JavaScript · Google Gemini · Gmail

**Dataset:** Kaggle Sample Superstore, 9,994 order lines, 2014-01-03 to 2017-12-30.

## Honest limits

A plain z-score compares December against all months, so the agent is instructed to
check the same month in previous years before calling a change unusual. It also
flags what is *unusual*, not what is *bad* — Binders lost the most money and were
never flagged, because losing money is normal for Binders. Sending the worst
loss-makers to the agent is the next change.
