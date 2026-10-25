// n8n Code node (JavaScript, Run Once for All Items)
// Turns the agent's JSON answer plus the KPIs into an HTML email.

const raw = $input.first().json.output;
const clean = typeof raw === 'string' ? raw.replace(/```json|```/g, '').trim() : raw;
const agent = typeof clean === 'string' ? JSON.parse(clean) : clean;

const kpi = $('get KPI').first().json.overall;

const colors = { high: '#d93025', medium: '#f29900', low: '#188038' };

const fmt = (n) => Number(n).toLocaleString('en-US', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

const card = (label, value) => `
  <td style="padding:12px;background:#f1f3f4;text-align:center;">
    <div style="font-size:12px;color:#5f6368;">${label}</div>
    <div style="font-size:18px;font-weight:bold;">${value}</div>
  </td>`;

const findingsHtml = agent.findings.map((f, i) => `
  <div style="border-left:4px solid ${colors[f.severity] || '#666'};padding:12px 16px;margin:16px 0;background:#f8f9fa;">
    <div style="font-size:12px;font-weight:bold;color:${colors[f.severity] || '#666'};text-transform:uppercase;">${f.severity} priority</div>
    <h3 style="margin:4px 0 8px;">${i + 1}. ${f.title}</h3>
    <p><b>What happened:</b> ${f.what_happened}</p>
    <p><b>Likely cause:</b> ${f.likely_cause}</p>
    <p><b>Recommendation:</b> ${f.recommendation}</p>
  </div>`).join('');

const html = `
<div style="font-family:Arial,sans-serif;max-width:640px;margin:auto;color:#202124;">
  <h2>AI Analyst Report: ${agent.report_month}</h2>
  <table width="100%" cellspacing="8"><tr>
    ${card('Sales', '$' + fmt(kpi.sales_cur))}
    ${card('Sales growth', kpi.sales_growth_pct + '%')}
    ${card('Profit', '$' + fmt(kpi.profit_cur))}
    ${card('Margin', kpi.margin_cur_pct + '%')}
  </tr></table>
  <h3>Summary</h3>
  <p>${agent.summary}</p>
  <h3>Findings</h3>
  ${findingsHtml}
  <p style="font-size:12px;color:#5f6368;margin-top:24px;">
    Generated automatically by the AI Analyst Agent (n8n + PostgreSQL + Python + Gemini).
    All numbers are calculated with SQL. The AI explains them.
  </p>
</div>`;

return [{
  json: {
    subject: `AI Analyst Report: ${agent.report_month} (${agent.findings.length} findings)`,
    html: html,
    report_month: agent.report_month,
    findings: agent.findings
  }
}];
