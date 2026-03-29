#!/usr/bin/env node
// Tests for super-research-tracker.js hook
// Run: node tests/test-research-tracker.js

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const HOOK = path.join(__dirname, '..', 'hooks', 'super-research-tracker.js');
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  PASS  ${name}`);
    passed++;
  } catch (e) {
    console.log(`  FAIL  ${name} — ${e.message}`);
    failed++;
  }
}

function runHook(input) {
  // Write input to a temp file to avoid shell escaping issues
  const inputFile = path.join(os.tmpdir(), `super-hook-input-${Date.now()}.json`);
  fs.writeFileSync(inputFile, JSON.stringify(input));
  try {
    return execSync(`cat "${inputFile}" | node "${HOOK}"`, {
      encoding: 'utf8',
      timeout: 5000,
    });
  } catch (e) {
    return e.stdout || '';
  } finally {
    fs.unlinkSync(inputFile);
  }
}

function assert(condition, msg) {
  if (!condition) throw new Error(msg);
}

function makeTmpWithSuper() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));
  fs.mkdirSync(path.join(tmp, '.super'));
  return tmp;
}

function makeTmpGitWithSuper() {
  const tmp = makeTmpWithSuper();
  execSync('git init --quiet && git commit --allow-empty -m init --quiet', { cwd: tmp });
  return tmp;
}

console.log('\nResearch Tracker Tests');
console.log('======================\n');

// Test 1: Writing research.md creates state.json with RESEARCH capability
test('research.md write creates state.json', () => {
  const tmp = makeTmpWithSuper();

  runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, '.super', 'research.md'),
      content: '## Research\n[HIGH] stuff\n[MEDIUM] things\n[LOW] maybe',
    },
    cwd: tmp,
  });

  const statePath = path.join(tmp, '.super', 'state.json');
  assert(fs.existsSync(statePath), 'state.json not created');
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert(state.capabilities_activated.includes('RESEARCH'), 'RESEARCH not in capabilities');
  assert(state.artifacts['research.md'], 'research.md not in artifacts');

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 2: Writing plan.md adds PLAN capability
test('plan.md write adds PLAN capability', () => {
  const tmp = makeTmpWithSuper();

  runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, '.super', 'plan.md'),
      content: '## Plan\nVerify: tests pass\nDependencies: none',
    },
    cwd: tmp,
  });

  const state = JSON.parse(fs.readFileSync(path.join(tmp, '.super', 'state.json'), 'utf8'));
  assert(state.capabilities_activated.includes('PLAN'), 'PLAN not in capabilities');

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 3: Writing map-tech.md adds MAP capability and tracks git SHA
test('map-tech.md write adds MAP + git SHA metadata', () => {
  const tmp = makeTmpGitWithSuper();

  runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, '.super', 'map-tech.md'),
      content: '## Tech Stack\nNode.js 20',
    },
    cwd: tmp,
  });

  const state = JSON.parse(fs.readFileSync(path.join(tmp, '.super', 'state.json'), 'utf8'));
  assert(state.capabilities_activated.includes('MAP'), 'MAP not in capabilities');
  assert(state.map_metadata, 'map_metadata missing');
  assert(state.map_metadata.git_sha, 'git_sha missing');
  assert(state.map_metadata.agents_run.includes('tech'), 'tech not in agents_run');

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 4: Writing experiments.md adds EXPERIMENT + experiment_metadata
test('experiments.md write tracks experiment count', () => {
  const tmp = makeTmpGitWithSuper();

  runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, '.super', 'experiments.md'),
      content: '## Log\n### Baseline\nResult: 3s\n### Experiment #1 — cache\nHypothesis: caching\n### Experiment #2 — index\nHypothesis: indexing\n### Current Best\nResult: 2s',
    },
    cwd: tmp,
  });

  const state = JSON.parse(fs.readFileSync(path.join(tmp, '.super', 'state.json'), 'utf8'));
  assert(state.capabilities_activated.includes('EXPERIMENT'), 'EXPERIMENT not in capabilities');
  assert(state.experiment_metadata, 'experiment_metadata missing');
  assert(state.experiment_metadata.experiment_count === 2, `expected 2, got ${state.experiment_metadata.experiment_count}`);

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 5: Quality warning for research.md missing confidence tags
test('research.md missing tags triggers quality warning', () => {
  const tmp = makeTmpWithSuper();

  const output = runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, '.super', 'research.md'),
      content: '## Research\nSome findings without any tags at all',
    },
    cwd: tmp,
  });

  assert(output.includes('ARTIFACT QUALITY'), `expected quality warning, got: "${output}"`);

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 6: Non-.super/ writes are ignored
test('Non-.super/ write is ignored', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));

  runHook({
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(tmp, 'src', 'app.js'),
      content: 'console.log("hello")',
    },
    cwd: tmp,
  });

  assert(!fs.existsSync(path.join(tmp, '.super', 'state.json')), 'state.json should not exist');

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 7: Non-Write tools are ignored
test('Read tool is ignored', () => {
  const tmp = makeTmpWithSuper();

  runHook({
    tool_name: 'Read',
    tool_input: { file_path: path.join(tmp, '.super', 'research.md') },
    cwd: tmp,
  });

  assert(!fs.existsSync(path.join(tmp, '.super', 'state.json')), 'state.json should not exist for Read');

  fs.rmSync(tmp, { recursive: true, force: true });
});

// Test 8: Multiple map writes accumulate agents_run
test('Multiple map writes accumulate agents', () => {
  const tmp = makeTmpGitWithSuper();

  runHook({
    tool_name: 'Write',
    tool_input: { file_path: path.join(tmp, '.super', 'map-tech.md'), content: 'tech' },
    cwd: tmp,
  });
  runHook({
    tool_name: 'Write',
    tool_input: { file_path: path.join(tmp, '.super', 'map-architecture.md'), content: 'arch' },
    cwd: tmp,
  });

  const state = JSON.parse(fs.readFileSync(path.join(tmp, '.super', 'state.json'), 'utf8'));
  assert(state.map_metadata.agents_run.includes('tech'), 'tech missing');
  assert(state.map_metadata.agents_run.includes('architecture'), 'architecture missing');
  assert(state.map_metadata.agents_run.length === 2, `expected 2 agents, got ${state.map_metadata.agents_run.length}`);

  fs.rmSync(tmp, { recursive: true, force: true });
});

console.log(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
