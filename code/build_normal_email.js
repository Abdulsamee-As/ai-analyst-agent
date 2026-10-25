// n8n Code node (JavaScript): KPI-only email for the "no anomalies" branch

const kpi = $('get KPI').first().json;
const o = kpi.overall;

const fmt = (n) => Number(n).toLocaleString('en-US', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

const card = (label, value) => `
  <td style="padding:12px;background:#f1f3f4;text-align:center;">
    <div style="font-size:12px;color:#5f6368;">${label}</div>
    <div style="font-size:18px;font-weight:bold;">${value}</div>
  </td>`;

const regionRows = kpi.by_region.map(r => `
  <tr>
    <td style="padding:8px;border-bottom:1px solid #e0e0e0;">${r.region}</td>
    <td style="padding:8px;border-bottom:1px solid #e0e0e0;">$${fmt(r.sales_cur)}</td>
    <td style="padding:8px;border-bottom:1px solid #e0e0e0;">${r.sales_growth_pct}%</td>
    <td style="padding:8px;border-bottom:1px solid #e0e0e0;">${r.margin_cur_pct}%</td>
  </tr>`).join('');

const html = `
<div style="font-family:Arial,sans-serif;max-width:640px;margin:auto;color:#202124;">
  <h2>KPI Report: ${kpi.report_month}</h2>
  <table width="100%" cellspacing="8"><tr>
    ${card('Sales', '$' + fmt(o.sales_cur))}
    ${card('Sales growth', o.sales_growth_pct + '%')}
    ${card('Profit', '$' + fmt(o.profit_cur))}
    ${card('Margin', o.margin_cur_pct + '%')}
  </tr></table>
  <p style="padding:12px;background:#e6f4ea;color:#188038;">
    No unusual changes were found this month. All regions and sub-categories are within their normal range.
  </p>
  <h3>Sales by region</h3>
  <table width="100%" style="border-collapse:collapse;">
    <tr style="background:#f1f3f4;">
      <th style="padding:8px;text-align:left;">Region</th>
      <th style="padding:8px;text-align:left;">Sales</th>
      <th style="padding:8px;text-align:left;">Growth</th>
      <th style="padding:8px;text-align:left;">Margin</th>
    </tr>
    ${regionRows}
  </table>
</div>`;

return [{
  json: {
    subject: `KPI Report: ${kpi.report_month} (no anomalies)`,
    html: html
  }
}];
