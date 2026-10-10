// Run: node --test pi/tests/statusline.test.mjs
// Override package discovery with PI_PACKAGE_DIR=/path/to/@earendil-works/pi-coding-agent.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, mkdirSync, rmSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { createRequire } from 'node:module';
import { stripVTControlCharacters as plain } from 'node:util';
import { after, test } from 'node:test';

function packageDirectory() {
  if (process.env.PI_PACKAGE_DIR) return process.env.PI_PACKAGE_DIR;
  const require = createRequire(import.meta.url);
  try { return resolve(require.resolve('@earendil-works/pi-coding-agent'), '../..'); } catch {}
  for (const [command, args, suffix] of [
    ['npm', ['root', '-g'], '@earendil-works/pi-coding-agent'],
    ['brew', ['--prefix', 'pi-coding-agent'], 'libexec/lib/node_modules/@earendil-works/pi-coding-agent'],
  ]) {
    try {
      const path = join(execFileSync(command, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(), suffix);
      if (existsSync(join(path, 'package.json'))) return path;
    } catch {}
  }
  throw new Error('Pi package not found; set PI_PACKAGE_DIR.');
}
const root = packageDirectory();
const requirePi = createRequire(join(root, 'package.json'));
const { createJiti } = requirePi('jiti');
// Isolate calibration writes and verify that old preset configuration is ignored.
const home = mkdtempSync(join(tmpdir(), 'pi-statusline-'));
const oldHome = process.env.HOME;
process.env.HOME = home;
mkdirSync(join(home, '.pi/agent'), { recursive: true });
const presetFile = join(home, '.pi/agent/statusline.json');
const oldPreset = '{"preset":"minimal"}\n';
writeFileSync(presetFile, oldPreset);
after(() => { process.env.HOME = oldHome; rmSync(home, { recursive: true, force: true }); });
const jiti = createJiti(import.meta.url, { alias: { '@earendil-works/pi-tui': requirePi.resolve('@earendil-works/pi-tui') } });
const mod = await jiti.import('../extensions/minimal-statusline.ts');
const { visibleWidth } = await jiti.import(requirePi.resolve('@earendil-works/pi-tui'));
const { getThemeByName } = await jiti.import(join(root, 'dist/modes/interactive/theme/theme.js'));
const themes = ['dark', 'light'].map(name => getThemeByName(name));
const base = {
  cwd: '/home/me/projects/company/很长的项目目录', home: '/home/me', branch: 'feature/中文分支-very-long-name',
  model: 'provider/model-with-a-very-long-name-20261001', effort: 'high', window: 200000,
  usedPercent: 46, autoCompactReserve: 16384, input: 120000, output: 8000, cost: 0.123,
  cacheRead: 680000, cacheWrite: 1000, cacheHitPercent: 85,
};
const activity = { phase: 'tool', toolName: 'very-long-tool-name', toolCount: 2, elapsedMs: 18000, frame: '⠋' };

for (const theme of themes) {
  test(`all-information layout matrix (${theme.name})`, () => {
    for (const width of [1, 4, 20, 40, 60, 80, 120, 200]) {
      for (const usedPercent of [undefined, null, 0, 46, 70, 90, 99, 100]) {
        for (const active of [undefined, activity]) {
          const lines = mod.renderFooter({ ...base, usedPercent, activity: active }, theme, width);
          assert.ok(lines.length >= 2);
          for (const line of lines) assert.ok(visibleWidth(line) <= width, `${width}: ${plain(line)}`);
          if (width >= 40) {
            const output = plain(lines.join('\n')).replace(/\s+/g, ' ');
            for (const metric of ['↑120k', '↓8k', '≈$0.123', 'cache 85.0%', 'r 680k', 'w 1k', 'high']) assert.ok(output.includes(metric), metric);
            if (active) assert.match(output, /tools×2/);
          }
        }
      }
    }
    assert.deepEqual(mod.renderFooter(base, theme, 0), []);
  });
}

test('ctx shows remaining tokens, drains with usage and adapts to available columns', () => {
  const render = (state, width = 100) => plain(mod.renderContext({ ...base, ...state }, themes[0], width));
  assert.match(render({}), /^ctx 108k\/200k ━━━━━━━╸────── 54% left · auto in ≈91.6k$/);
  assert.match(render({ usedPercent: 0 }), /^ctx 200k\/200k ━{14} 100% left/);
  assert.match(render({ usedPercent: 100 }), /^ctx 0\/200k ─{14} 0% left · auto due/);
  assert.match(render({}, 46), /^ctx 108k\/200k ━━━─── 54% left · auto in ≈91.6k$/);
  assert.match(render({}, 40), /^ctx 108k\/200k 54% left · auto in ≈91.6k$/);
  assert.equal(render({}, 30), 'ctx 54% left · auto ≈91.6k');
  assert.match(render({}, 5), /108k\/200k/); // Full values returned for wrapping.
});

test('ctx distinguishes disabled, zero reserve, due and unknown usage', () => {
  const render = state => plain(mod.renderContext({ ...base, ...state }, themes[0], 100));
  assert.match(render({ autoCompactReserve: undefined }), /auto off$/);
  assert.match(render({ autoCompactReserve: 0 }), /auto in ≈108k$/);
  assert.match(render({ usedPercent: 90, autoCompactReserve: 20000 }), /auto due$/);
  assert.match(render({ usedPercent: 95, autoCompactReserve: 20000 }), /auto due$/);
  assert.match(render({ autoCompactReserve: 300000 }), /auto due$/);
  for (const usedPercent of [undefined, null, NaN, Infinity]) {
    const result = render({ usedPercent });
    assert.equal(result, 'ctx —/200k · usage pending');
    assert.doesNotMatch(result, /━|─|%|auto due/);
  }
  assert.equal(render({ window: undefined }), 'ctx —/— · usage pending');
  assert.match(render({ usedPercent: undefined, autoCompactReserve: undefined }), /usage pending · auto off$/);
  assert.match(render({ usedPercent: -10 }), /200k\/200k .*100% left/);
  assert.match(render({ usedPercent: 120 }), /0\/200k .*0% left · auto due$/);
});

test('ctx color reflects effective capacity, with or without auto-compaction', () => {
  const theme = { fg: (color, text) => `<${color}>${text}</${color}>` };
  const render = state => mod.renderContext({ ...base, ...state }, theme, 1000);
  // Same 60% used: 40% physical room vs only 20/140 = 14.3% effective room.
  assert.match(render({ usedPercent: 60, autoCompactReserve: 60000 }), /<warning>≈20k<\/warning>/);
  assert.match(render({ usedPercent: 60, autoCompactReserve: 0 }), /<text>≈80k<\/text>/);
  assert.match(render({ usedPercent: 66, autoCompactReserve: 60000 }), /<error>≈8k<\/error>/);
  assert.match(render({ usedPercent: 90, autoCompactReserve: 20000 }), /<error>auto due<\/error>/);
  assert.match(render({ usedPercent: 95, autoCompactReserve: undefined }), /<error>5% left<\/error>/);
  assert.match(render({ usedPercent: 75, autoCompactReserve: undefined }), /<warning>25% left<\/warning>/);
});

test('ctx shrinks against actual right-hand content before moving to overflow', () => {
  const lines = mod.renderFooter({ ...base, model: 'gpt-6-astra', activity }, themes[0], 100).map(plain);
  assert.match(lines[1], /^ctx .*tools×2.*gpt-6-astra · high$/);
  const long = mod.renderFooter(base, themes[0], 80).map(plain);
  assert.match(long[1], /^ctx 54% left · auto ≈91.6k/);
  assert.ok(long[1].endsWith(`${base.model} · high`));
});

test('single layout shows every metric; model and effort stay on row two when idle or active', () => {
  for (const active of [undefined, activity]) {
    const lines = mod.renderFooter({ ...base, activity: active }, themes[0], 240).map(plain);
    assert.equal(lines.length, 2);
    assert.match(lines[0], /↑120k.*↓8k.*≈\$0.123.*cache 85.0%.*r 680k.*w 1k/);
    assert.ok(!lines[0].includes(base.model));
    assert.ok(lines[1].startsWith('ctx '));
    assert.ok(lines[1].endsWith(`${base.model} · high`));
    if (active) assert.match(lines[1], /tools×2/);
  }
  const lines = mod.renderFooter({ ...base, model: 'gpt-6-astra' }, themes[0], 80).map(plain);
  assert.match(lines[1], /gpt-6-astra · high$/);
});

test('activity labels are English and rates appear only during generation/thinking', () => {
  for (const phase of ['waiting', 'thinking', 'streaming', 'tool', 'compacting', 'finishing']) {
    const output = plain(mod.renderFooter({ ...base, activity: { ...activity, phase }, rate: { tokensPerSecond: 45, estimated: true } }, themes[0], 240).join('\n'));
    assert.equal(output.includes('~45 tok/s'), ['thinking', 'streaming'].includes(phase));
    assert.ok(output.includes(phase === 'tool' ? 'tools×2' : phase));
    assert.doesNotMatch(output, /等待|思考|生成|工具|压缩|收尾/);
  }
});

test('labels preserve both ends and sanitize control characters', () => {
  for (let width = 0; width < 30; width++) assert.ok(visibleWidth(mod.shortLabel('中文模型-very-long-name-20261001', width)) <= width);
  assert.match(mod.shortLabel('model-very-long-name-20261001', 18), /^model.*….*1001$/);
  const lines = mod.renderFooter({ ...base, branch: '\x1b[31mbranch\nINJECT' }, themes[0], 120);
  assert.equal(plain(lines.join('')).includes('\n'), false);
});

test('extension statuses show all content and prioritize important markers without a details view', () => {
  const statuses = new Map([
    ['normal', 'working '.repeat(100)], ['warning', '⚠ quota'], ['error', 'Error: connection'],
    ['third', '失败: request'], ['fourth', 'all fine'],
  ]);
  for (const width of [20, 40, 80, 120]) {
    const lines = mod.renderExtensionStatuses(statuses, themes[0], width);
    lines.forEach(line => assert.ok(visibleWidth(line) <= width));
    const text = plain(lines.join('\n'));
    assert.match(text, /^│ warning:/);
    assert.equal((text.match(/working/g) ?? []).length, 100);
    for (const value of ['quota', 'connection', 'request', 'all fine']) assert.ok(text.includes(value));
    assert.doesNotMatch(text, /statusline details/);
  }
});

function harness() {
  const handlers = new Map();
  let component;
  let command;
  let unsubscribes = 0;
  const notices = [];
  const statuses = new Map([['test-extension', 'long status '.repeat(50)]]);
  const pi = {
    on(name, fn) { const list = handlers.get(name) ?? []; list.push(fn); handlers.set(name, list); },
    getSettings: () => ({}), getThinkingLevel: () => 'high',
    registerCommand(_name, definition) { command = definition.handler; },
  };
  const ctx = {
    mode: 'tui', model: { provider: 'test', id: 'model', contextWindow: 200000 }, thinkingLevel: 'high',
    sessionManager: { getSessionId: () => 'main', getLeafId: () => 'leaf', getEntries: () => [
      { type: 'message', message: { role: 'assistant', usage: { input: 10, output: 2, cacheRead: 90, cacheWrite: 0, cost: { total: 0.1 } } } },
    ], getCwd: () => '/tmp/project' },
    getContextUsage: () => ({ percent: 46, contextWindow: 200000 }),
    ui: {
      setFooter(factory) {
        component?.dispose();
        component = factory?.({ requestRender() {} }, themes[0], { getGitBranch: () => 'main', getExtensionStatuses: () => statuses, onBranchChange: () => () => { unsubscribes++; } });
      },
      notify(text) { notices.push(text); },
    },
  };
  mod.default(pi);
  return {
    ctx, notices,
    async emit(name, event = {}, context = ctx) { for (const fn of handlers.get(name) ?? []) await fn(event, context); },
    render: () => plain(component.render(120).join('\n')),
    command: args => command(args, ctx),
    get unsubscribes() { return unsubscribes; },
  };
}

test('runtime handles parallel/nested tools, recovery, settlement and foreign sessions', async () => {
  const h = harness();
  try {
    await h.emit('session_start');
    await h.emit('agent_start');
    assert.match(h.render(), /waiting/);
    await h.emit('message_start', { message: { role: 'assistant' } });
    await h.emit('message_update', { message: { role: 'assistant' }, assistantMessageEvent: { type: 'thinking_delta', delta: '思考' } });
    assert.match(h.render(), /thinking/);
    await h.emit('message_update', { message: { role: 'assistant' }, assistantMessageEvent: { type: 'text_delta', delta: 'answer' } });
    assert.match(h.render(), /streaming/);
    await h.emit('tool_execution_start', { toolCallId: 'a', toolName: 'parent' });
    await h.emit('tool_execution_start', { toolCallId: 'a/1', parentToolCallId: 'a', toolName: 'child' });
    assert.match(h.render(), /tools×2/);
    await h.emit('tool_execution_end', { toolCallId: 'a/1' });
    assert.match(h.render(), /tool parent/);
    const foreign = { ...h.ctx, sessionManager: { ...h.ctx.sessionManager, getSessionId: () => 'foreign' } };
    await h.emit('tool_execution_end', { toolCallId: 'a' }, foreign);
    await h.emit('session_shutdown', {}, foreign);
    assert.match(h.render(), /tool parent/);
    await h.emit('tool_execution_end', { toolCallId: 'a' });
    assert.match(h.render(), /waiting/);
    await h.emit('agent_end');
    assert.match(h.render(), /finishing/);
    await h.emit('session_before_compact');
    assert.match(h.render(), /compacting/);
    await h.emit('session_compact', { willRetry: true });
    await h.emit('agent_start');
    assert.match(h.render(), /waiting/);
    await h.emit('agent_settled');
    assert.doesNotMatch(h.render(), /waiting|finishing|compacting|tools×/);
    await h.emit('session_before_compact');
    await h.emit('session_compact_failed');
    assert.doesNotMatch(h.render(), /compacting|waiting/);
  } finally { await h.emit('session_shutdown'); }
});

test('legacy presets are ignored; commands only toggle the footer; resume resets live state', async () => {
  const h = harness();
  try {
    await h.emit('session_start');
    assert.match(h.render(), /↑10.*↓2.*≈\$0.100/); // Old minimal config cannot suppress statistics.
    assert.equal((h.render().replace(/\s+/g, ' ').match(/long status/g) ?? []).length, 50);
    for (const command of ['balanced', 'full', 'minimal', 'cost', 'details']) {
      await h.command(command);
      assert.equal(h.notices.at(-1), 'Usage: /statusline [custom | default]');
    }
    assert.equal(readFileSync(presetFile, 'utf8'), oldPreset);
    await h.command('default');
    await h.command('custom');
    await h.command('');
    await h.command('');
    assert.ok(h.unsubscribes >= 2);
    await h.emit('agent_start');
    await h.emit('tool_execution_start', { toolCallId: 'a', toolName: 'old-tool' });
    await h.emit('session_start', { reason: 'resume' });
    assert.doesNotMatch(h.render(), /old-tool/);
    h.ctx.model = { ...h.ctx.model, id: 'new-model' };
    await h.emit('model_select');
    assert.match(h.render().split('\n')[1], /new-model/);
  } finally { await h.emit('session_shutdown'); }
});

test('run timer stays continuous across tools and recovery; inactive rates are hidden', async () => {
  const h = harness();
  const realNow = Date.now;
  let now = 100000;
  Date.now = () => now;
  try {
    await h.emit('session_start');
    await h.emit('agent_start');
    now += 1000;
    await h.emit('message_start', { message: { role: 'assistant' } });
    await h.emit('message_update', { message: { role: 'assistant' }, assistantMessageEvent: { type: 'text_delta', delta: 'a' } });
    now += 1000;
    assert.match(h.render(), /~0.4 tok\/s/);
    await h.emit('message_end', { message: { role: 'assistant', usage: { output: 1 } } });
    assert.doesNotMatch(h.render(), /tok\/s/);
    now += 3000;
    await h.emit('tool_execution_start', { toolCallId: 'a', toolName: 'bash' });
    assert.match(h.render(), /5.0s/);
    await h.emit('tool_execution_end', { toolCallId: 'a' });
    await h.emit('agent_end');
    now += 2000;
    await h.emit('agent_start');
    assert.match(h.render(), /7.0s/);
    await h.emit('agent_settled');
    assert.doesNotMatch(h.render(), /tok\/s|waiting/);
  } finally {
    Date.now = realNow;
    await h.emit('session_shutdown');
  }
});

test('usage keeps session totals but cache hit comes from the latest assistant', () => {
  const usage = { input: 10, output: 2, cacheRead: 90, cacheWrite: 0, cost: { total: 0.1 } };
  const entries = [
    { type: 'message', message: { role: 'assistant', usage } },
    { type: 'usage', usage }, { type: 'compaction', usage }, { type: 'branch_summary', usage },
    { type: 'message', message: { role: 'toolResult', usage } },
  ];
  const totals = mod.readSessionUsage(entries);
  assert.equal(totals.input, 50);
  assert.equal(totals.cacheHitPercent, 90);
  assert.equal(totals.cost, 0.5);
  entries.push({ type: 'message', message: { role: 'assistant', usage: { ...usage, input: 0, cacheRead: 0 } } });
  assert.equal(mod.readSessionUsage(entries).cacheHitPercent, undefined);
});
