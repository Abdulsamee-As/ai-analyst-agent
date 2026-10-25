# Agent user prompt (n8n expression)

```
Report month: {{ $('Detect Anomalies').first().json.report_month }}

Overall KPIs, this month vs last month:
{{ JSON.stringify($('get KPI').first().json.overall) }}

Top anomalies found by the statistical check (z-score above 2 or below -2):
{{ JSON.stringify($('Detect Anomalies').first().json.anomalies.slice(0, 5)) }}

Investigate the 2 most important anomalies using the database tool, find the likely causes, and give recommendations. When you are done, reply with ONLY the JSON described in your instructions.
```
