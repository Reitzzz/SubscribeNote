// Run: node scripts/check-prototype.cjs (no dependencies).
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, '../Android-5.6_Sol.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
new vm.Script(script);
const fixtures = script.split('    // DOM:')[0];
vm.runInNewContext(fixtures + `
  assert.equal(Object.keys(subscriptions).length, 8);
  assert.equal(subscriptions.wps.manual, true);
  assert.equal(subscriptions.chatgpt.price, '¥1430 JPY');
  assert.ok(library.length > 180);
  assert.equal(new Set(library.map(item => item.name)).size, library.length);
  assert.equal(summarize(2026).reduce((sum,row) => sum+row.amount,0), 96908);
  assert.equal(rowsFor(2026).reduce((sum,row) => sum+row.paid,0), 45169);
  assert.equal(summarize(2026,'AI').reduce((sum,row) => sum+row.amount,0), 37808);
  assert.equal(summarize(2026,'全部',9).reduce((sum,row) => sum+row.amount,0), 7935);
  assert.equal(summarize(2025).reduce((sum,row) => sum+row.amount,0), 20000);
  assert.equal(summarize(2025,'全部',9).length, 0);
  assert.equal(addMonths('2026-01-31',1), '2026-02-28');
  assert.equal(addMonths('2024-01-31',1), '2024-02-29');
  assert.equal(monthEnd('2026-09'), '2026-09-30');
  assert.equal(cycleDate('2026-02','2026-01-31'), '2026-02-28');
  assert.equal(validDate('2026-02-30'), false);
  assert.equal(validDate('2024-02-29'), true);
  for (const value of ['', '-1', 'Infinity', 'NaN', '100000000']) assert.equal(amountInput(value), false);
  assert.equal(amountInput('0'), true);
  assert.equal(escapeHtml('<img src=x onerror="bad()">'), '&lt;img src=x onerror=&quot;bad()&quot;&gt;');
`, { assert });
const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]);
// Static markup only; template strings in the script contain dynamically created IDs.
const staticIds = [...html.split('<script>')[0].matchAll(/\bid="([^"]+)"/g)].map(match => match[1]);
assert.equal(new Set(staticIds).size, staticIds.length, 'Duplicate static DOM IDs');
for (const match of html.matchAll(/data-jump="([^"]+)"/g)) assert.ok(ids.includes(match[1]), 'Missing navigation target: ' + match[1]);
const assetNames = ['wps','xsus','bilibili','apple','anti','tencent','chatgpt','avatar','flowus','docs','yuque','baidu','surfshark','nordvpn','nexitally','migu','mango','iqiyi','youku','soundcloud','tidal','deezer','spotify','telegram'];
assetNames.push('kimi','qwen','doubao','zhipu','spark','hailuo','tiangong','yuanbao','deepseek','trae','360','baichuan','codegeex','stepfun','kling','jimeng','vidu');
for (const name of assetNames) {
  assert.ok(fs.statSync(path.join(__dirname, '../assets/recording', name + '.png')).size > 100);
}
console.log('PASS: syntax, fixtures, statistics, dates, validation, escaping, navigation and ' + assetNames.length + ' recording assets.');
