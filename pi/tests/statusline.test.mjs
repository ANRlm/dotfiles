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
// Isolate the legacy preset file and verify that it is ignored.
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
  usedPercent: 46,
  cacheRead: 680000, cacheWrite: 1000, cacheHitPercent: 85,
};
const activity = { phase: 'tool', toolName: 'very-long-tool-name', toolCount: 2, frame: '⠋' };

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
            for (const metric of ['cache 85.0%', 'high']) assert.ok(output.includes(metric), metric);
            if (active) assert.match(output, /tool very-long-tool-name ×2/);
          }
        }
      }
    }
    assert.deepEqual(mod.renderFooter(base, theme, 0), []);
  });
}

test('ctx shows remaining tokens, drains with usage and adapts to available columns', () => {
  const render = (state, width = 100) => plain(mod.renderContext({ ...base, ...state }, themes[0], width));
  assert.match(render({}), /^ctx 108k\/200k ━━━━━━━╸────── 54% left$/);
  assert.match(render({ usedPercent: 0 }), /^ctx 200k\/200k ━{14} 100% left/);
  assert.match(render({ usedPercent: 100 }), /^ctx 0\/200k ─{14} ! 0% left/);
  assert.match(render({}, 33), /^ctx 108k\/200k ━━━━━───── 54% left$/);
  assert.match(render({}, 32), /^ctx 108k\/200k ━━━─── 54% left$/);
  assert.match(render({}, 25), /^ctx 108k\/200k 54% left$/);
  assert.equal(render({}, 20), 'ctx 54% left');
  assert.match(render({}, 5), /108k\/200k/); // Full values returned for wrapping.
});

test('ctx handles unknown usage and clamps out-of-range percentages', () => {
  const render = state => plain(mod.renderContext({ ...base, ...state }, themes[0], 100));
  for (const usedPercent of [undefined, null, NaN, Infinity]) {
    const result = render({ usedPercent });
    assert.equal(result, 'ctx —/200k · usage pending');
    assert.doesNotMatch(result, /━|─|%/);
  }
  assert.equal(render({ window: undefined }), 'ctx —/— · usage pending');
  assert.match(render({ usedPercent: -10 }), /200k\/200k .*100% left/);
  assert.match(render({ usedPercent: 120 }), /0\/200k .*0% left/);
});

test('ctx color follows remaining share', () => {
  const theme = { fg: (color, text) => `<${color}>${text}</${color}>` };
  const render = state => mod.renderContext({ ...base, ...state }, theme, 1000);
  assert.match(render({ usedPercent: 50 }), /<text>━━━━━━━/);
  assert.match(render({ usedPercent: 75 }), /<warning>━━━╸/);
  assert.match(render({ usedPercent: 91 }), /<error>━<\/error>/);
  // Below 10% a marker carries the warning without relying on color.
  assert.match(render({ usedPercent: 95 }), /<error>! 5% left<\/error>/);
  assert.match(render({ usedPercent: 91 }), /<error>! 9% left<\/error>/);
  assert.doesNotMatch(render({ usedPercent: 80 }), /! \d+% left/);
});

test('ctx shrinks against actual right-hand content before moving to overflow', () => {
  const lines = mod.renderFooter({ ...base, model: 'gpt-6-astra', activity }, themes[0], 100).map(plain);
  assert.match(lines[1], /^ctx .*tool very-long-tool-name ×2.*gpt-6-astra · high$/);
  const long = mod.renderFooter(base, themes[0], 80).map(plain);
  assert.match(long[1], /^ctx 108k\/200k 54% left/);
  assert.ok(long[1].endsWith(`${base.model} · high`));
});

test('single layout shows every metric; model and effort stay on row two when idle or active', () => {
  for (const active of [undefined, activity]) {
    const lines = mod.renderFooter({ ...base, activity: active }, themes[0], 240).map(plain);
    assert.equal(lines.length, 2);
    assert.match(lines[0], /cache 85\.0%$/);
    assert.ok(!lines[0].includes(base.model));
    assert.ok(lines[1].startsWith('ctx '));
    assert.ok(lines[1].endsWith(`${base.model} · high`));
    if (active) assert.match(lines[1], /tool very-long-tool-name ×2/);
  }
  const lines = mod.renderFooter({ ...base, model: 'gpt-6-astra' }, themes[0], 80).map(plain);
  assert.match(lines[1], /gpt-6-astra · high$/);
});

test('activity labels are English names for every live phase', () => {
  for (const phase of ['waiting', 'thinking', 'streaming', 'tool', 'compacting', 'finishing']) {
    const output = plain(mod.renderFooter({ ...base, activity: { ...activity, phase } }, themes[0], 240).join('\n'));
    assert.ok(output.includes(phase === 'tool' ? 'tool very-long-tool-name ×2' : phase));
    assert.doesNotMatch(output, /等待|思考|生成|工具|压缩|收尾/);
  }
});

test('labels sanitize control characters', () => {
  const lines = mod.renderFooter({ ...base, branch: '\x1b[31mbranch\nINJECT' }, themes[0], 120);
  assert.equal(plain(lines.join('')).includes('\n'), false);
});

function harness(settings = {}) {
  const handlers = new Map();
  let component;
  let command;
  let unsubscribes = 0;
  const notices = [];
  const pi = {
    on(name, fn) { const list = handlers.get(name) ?? []; list.push(fn); handlers.set(name, list); },
    getSettings: () => settings, getThinkingLevel: () => 'high',
    registerCommand(_name, definition) { command = definition.handler; },
  };
  const ctx = {
    mode: 'tui', model: { provider: 'test', id: 'model', contextWindow: 200000 }, thinkingLevel: 'high',
    sessionManager: { getSessionId: () => 'main', getLeafId: () => 'leaf', getEntries: () => [
      { type: 'message', message: { role: 'assistant', usage: { input: 10, output: 2, cacheRead: 90, cacheWrite: 0 } } },
    ], getCwd: () => '/tmp/project' },
    getContextUsage: () => ({ percent: 46, contextWindow: 200000 }),
    ui: {
      setFooter(factory) {
        component?.dispose();
        component = factory?.({ requestRender() {} }, themes[0], { getGitBranch: () => 'main', onBranchChange: () => () => { unsubscribes++; } });
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
    assert.match(h.render(), /tool child ×2/);
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
    assert.doesNotMatch(h.render(), /waiting|finishing|compacting|tool /);
    await h.emit('session_before_compact');
    await h.emit('session_compact_failed');
    assert.doesNotMatch(h.render(), /compacting|waiting/);
  } finally { await h.emit('session_shutdown'); }
});

test('legacy presets are ignored; commands only toggle the footer; resume resets live state', async () => {
  const h = harness();
  try {
    await h.emit('session_start');
    assert.match(h.render(), /cache 90\.0%/); // Old minimal config cannot suppress statistics.
    for (const command of ['balanced', 'full', 'minimal', 'details']) {
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

test('usage keeps session totals and weights cache hit over the last 20 prompts', () => {
  const usage = { input: 10, output: 2, cacheRead: 90, cacheWrite: 0 };
  const entries = [
    { type: 'message', message: { role: 'assistant', usage } },
    { type: 'usage', usage }, { type: 'compaction', usage }, { type: 'branch_summary', usage },
    { type: 'message', message: { role: 'toolResult', usage } },
  ];
  const totals = mod.readSessionUsage(entries);
  assert.equal(totals.input, 50);
  assert.equal(totals.cacheHitPercent, 90);
  entries.push({ type: 'message', message: { role: 'assistant', usage: { ...usage, input: 0, cacheRead: 0 } } });
  assert.equal(mod.readSessionUsage(entries).cacheHitPercent, 90);
  assert.equal(mod.readSessionUsage([]).cacheHitPercent, undefined);
  const mixed = mod.readSessionUsage([
    { type: 'message', message: { role: 'assistant', usage: { input: 10, output: 0, cacheRead: 90, cacheWrite: 0 } } },
    { type: 'message', message: { role: 'assistant', usage: { input: 90, output: 0, cacheRead: 10, cacheWrite: 0 } } },
  ]);
  assert.equal(mixed.cacheHitPercent, 50);
  // A cold streak earlier in a long session must not be averaged away.
  const cold = { type: 'message', message: { role: 'assistant', usage: { input: 100, output: 0, cacheRead: 0, cacheWrite: 0 } } };
  const warm = { type: 'message', message: { role: 'assistant', usage: { input: 0, output: 0, cacheRead: 90, cacheWrite: 0 } } };
  const rolling = mod.readSessionUsage([...Array(5).fill(cold), ...Array(20).fill(warm)]);
  assert.equal(rolling.cacheHitPercent, 100);
  assert.equal(rolling.input, 500);
});
