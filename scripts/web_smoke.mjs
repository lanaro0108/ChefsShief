import assert from 'node:assert/strict';
import { mkdir } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { chromium } from 'playwright-core';

// Tests the compiled Flutter UI against the REAL local Firebase emulators and
// the REAL TheMealDB API. Translation alone is stubbed to avoid public-service quotas.
// No production credentials or pre-seeded accounts are used.
const baseUrl = process.env.CHEFS_WEB_URL ?? 'http://127.0.0.1:7357';
assert.equal(new URL(baseUrl).hostname, '127.0.0.1', 'Smoke tests only target the local development app.');
const output = process.env.CHEFS_SCREENSHOT_DIR ?? '/tmp/chefs-shelf-screenshots';
await mkdir(output, { recursive: true });
const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_EXECUTABLE ?? '/usr/bin/chromium',
  headless: true,
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
  proxy: process.env.HTTPS_PROXY ? {
    server: process.env.HTTPS_PROXY, bypass: '127.0.0.1,localhost',
  } : undefined,
});
const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
const page = await context.newPage();
page.setDefaultTimeout(25000);
// In managed environments Chromium may lack the proxy CA in its own store.
// Fetch the real SDK through curl's configured CA trust; TLS stays verified.
// Public CI and normal browsers use their ordinary HTTPS transport.
if (process.env.CHEFS_PROXY_CA_FETCH === '1') {
  const resources = new Map();
  const run = promisify(execFile);
  await page.route('https://www.gstatic.com/firebasejs/**', async route => {
    const url = route.request().url();
    if (!resources.has(url)) {
      resources.set(url, run('curl', ['--fail', '--silent', '--show-error', '--max-time', '30', url], {encoding: 'buffer', maxBuffer: 20 * 1024 * 1024}).then(result => result.stdout));
    }
    await route.fulfill({body: await resources.get(url), contentType: 'application/javascript', headers: {'access-control-allow-origin': '*'}});
  });
}
await page.route('https://api.mymemory.translated.net/**', async route => {
  const source = new URL(route.request().url()).searchParams.get('q') ?? '';
  // Preserve all quantities while exercising the translated-view workflow.
  const amounts = source.match(/[0-9]+(?:[.,][0-9]+)?/g) ?? [];
  await route.fulfill({
    contentType: 'application/json',
    headers: {'access-control-allow-origin': '*'},
    body: JSON.stringify({responseStatus: 200, responseData: {translatedText: 'Preparo em português. ' + amounts.join(' ')}}),
  });
});
const errors = [];
page.on('pageerror', error => errors.push(error.message));
const email = `chef-web-${Date.now()}@example.com`;
const password = 'TesteLocal123!';

async function openApp(target) {
  await target.goto(baseUrl);
  await target.locator('flt-semantics-placeholder').waitFor({state:'attached'});
  await target.locator('flt-semantics-placeholder').evaluate(element => element.click());
  await target.getByRole('button', {name:'Entrar no meu caderno', exact:true}).waitFor();
}
async function fill(target, label, value) {
  await fillField(target, target.getByRole('textbox', { name: label }), value);
}
async function nextFrame(target) {
  await target.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
}
async function fillField(target, field, value) {
  await field.scrollIntoViewIfNeeded();
  await nextFrame(target);
  await field.focus();
  await nextFrame(target);
  // Use native editing gestures: semantic textareas may expose a selection
  // different from the canvas editor, so setting DOM value alone is insufficient.
  await target.keyboard.press('ControlOrMeta+A');
  await target.keyboard.press('Backspace');
  await target.keyboard.insertText(value);
  await nextFrame(target);
  assert.ok(await field.inputValue() === value, 'The focused Flutter editor must reflect the intended field value.');
  await field.press('Tab');
}
async function register(target, address) {
  await target.getByRole('button', { name: 'Primeira vez aqui? Crie sua conta', exact: true }).click();
  await fill(target, /^Seu nome/, 'Chef de Teste');
  await fill(target, /^E-mail/, address);
  await fillField(target, target.getByLabel(/^Senha/), password);
  await target.getByRole('button', { name: 'Criar minha conta', exact: true }).click();
  await target.getByText('O que vamos cozinhar hoje?', { exact: true }).waitFor();
  await target.getByText('Ambiente local · Contas e receitas de teste', { exact: true }).waitFor();
}

try {
  await openApp(page);
  await page.screenshot({path:`${output}/01-login-desktop.png`});
  await register(page, email);
  console.log('PASS: UI registration and real Firebase Auth session.');
  const search = page.getByRole('textbox', {name:'Buscar receitas', exact:true});
  await fillField(page, search, 'Arrabiata');
  await page.getByRole('button', {name:'Buscar agora', exact:true}).click();
  await page.getByRole('button', {name:'Abrir receita Penne ao molho arrabbiata', exact:true}).waitFor();
  await page.screenshot({path:`${output}/02-descoberta-desktop.png`});
  await page.getByRole('button', {name:'Abrir receita Penne ao molho arrabbiata', exact:true}).click();
  await page.getByText('Na bancada', {exact:true}).waitFor();
  await page.getByText('Mãos à massa', {exact:true}).waitFor();
  await page.getByText('RECEITA EM PORTUGUÊS', {exact:true}).waitFor();
  await page.getByRole('checkbox', {name:'1/4 xícara de azeite', exact:true}).waitFor();
  await page.getByRole('button', {name:'Ver original', exact:true}).click();
  await page.getByText('Spicy Arrabiata Penne', {exact:true}).waitFor();
  await page.getByRole('button', {name:'Voltar à receita', exact:true}).click();
  await page.getByRole('button', {name:'Salvar no caderno', exact:true}).click();
  await page.getByRole('button', {name:'Dar meu toque', exact:true}).waitFor();
  console.log('PASS: Real TheMealDB search, complete details and Firestore creation.');

  await page.getByRole('button', {name:'Dar meu toque', exact:true}).click();
  await fill(page, /^Nome da receita/, 'Penne com meu toque');
  await fill(page, /^Ingrediente 1(?:\b)/, '300 g de penne');
  await fill(page, /^Passo 1(?:\b)/, 'Prepare os ingredientes com carinho.');
  await fill(page, /^Minhas observações/, 'Adicionar manjericão fresco ao servir.');
  await page.getByRole('button', {name:'Salvar minhas alterações', exact:true}).click();
  await page.getByText('Penne com meu toque', {exact:true}).waitFor();
  await page.getByRole('checkbox', {name:'300 g de penne', exact:true}).waitFor();
  await page.getByText('Prepare os ingredientes com carinho.', {exact:true}).waitFor();
  console.log('PASS: Flutter editor persists title, ingredient array, steps and personal notes.');
  await page.screenshot({path:`${output}/03-receita-desktop.png`});

  await page.getByRole('button', {name:'Voltar', exact:true}).click();
  await page.getByText(/^Meu caderno/).first().click();
  await page.getByRole('button', {name:'Abrir receita Penne com meu toque', exact:true}).waitFor();
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(4500); // Let the success snackbar leave the screenshot.
  await page.mouse.wheel(0,200);
  await nextFrame(page);
  await page.screenshot({path:`${output}/04-caderno-mobile.png`});
  await page.getByRole('button', {name:'Abrir receita Penne com meu toque', exact:true}).click();
  await page.getByRole('button', {name:'Remover', exact:true}).click();
  await page.getByRole('button', {name:'Manter receita', exact:true}).click();
  await page.getByText('Penne com meu toque', {exact:true}).waitFor();
  await page.getByRole('button', {name:'Remover', exact:true}).click();
  await page.getByRole('button', {name:'Remover receita', exact:true}).click();
  await page.getByText('Seu caderno começa com uma receita', {exact:true}).waitFor();
  console.log('PASS: Mobile notebook, cancellation and confirmed deletion.');

  await page.getByRole('button', {name:/^Minha conta/}).click();
  await page.getByRole('menuitem', {name:'Sair da conta', exact:true}).click();
  await page.getByRole('button', {name:'Entrar no meu caderno', exact:true}).waitFor();
  await fill(page, /^E-mail/, email);
  await fillField(page, page.getByLabel(/^Senha/), password);
  await page.getByRole('button', {name:'Entrar no meu caderno', exact:true}).click();
  await page.getByText('O que vamos cozinhar hoje?', {exact:true}).waitFor();
  console.log('PASS: Logout and login retain the account.');
  assert.deepEqual(errors, [], 'The browser must not produce uncaught application errors.');
  console.log(`PASS: Web smoke completed. Screenshots: ${output}`);
} catch (error) {
  await page.screenshot({path:`${output}/failure.png`}).catch(()=>{});
  console.error((await page.locator('body').innerText()).slice(0,2500));
  throw error;
} finally { await browser.close(); }
