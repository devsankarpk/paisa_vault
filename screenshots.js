// Regenerates screenshots/*.png from the prototype. Usage: node screenshots.js (needs playwright)
const { chromium } = require('playwright');
const path = require('path');
const screens = ['lock','home','dashboard','activity','search','ask','cards','card/hdfc','addcard','profile','hidden','selftransfers','household','reports','budgets','alerts','backup','security'];
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const url = 'file://' + path.join(__dirname, 'app', 'index.html');
  for (const s of screens) {
    await p.goto(url + '#/' + s);
    if (s === 'card/hdfc') await p.click('[data-reveal]');
    await p.waitForTimeout(300);
    await p.screenshot({ path: path.join(__dirname, 'screenshots', s.replace('/', '-') + '.png') });
  }
  await b.close();
})();
