#!/usr/bin/env node
// Tests for super-plan-guard.js hook
// Run: node tests/test-plan-guard.js

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const HOOK = path.join(__dirname, '..', 'hooks', 'super-plan-guard.js');
let passed = 0;
let failed = 0;

function test(name, input, expectWarning) {
  try {
    const result = execSync(`echo '${JSON.stringify(input)}' | node "${HOOK}"`, {
      encoding: 'utf8',
      timeout: 5000,
      cwd: input.cwd || os.tmpdir(),
    });

    const hasWarning = result.includes('PLAN GUARD');

    if (hasWarning === expectWarning) {
      console.log(`  PASS  ${name}`);
      passed++;
    } else {
      console.log(`  FAIL  ${name} — expected warning=${expectWarning}, got warning=${hasWarning}`);
      failed++;
    }
  } catch (e) {
    // Exit code 0 with no output = no warning (pass-through)
    if (!expectWarning && (e.status === 0 || e.stdout === '')) {
      console.log(`  PASS  ${name}`);
      passed++;
    } else {
      console.log(`  FAIL  ${name} — unexpected error: ${e.message}`);
      failed++;
    }
  }
}

// Setup temp dirs
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));
const superDir = path.join(tmpDir, '.super');
fs.mkdirSync(superDir);

const tmpDirWithPlan = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));
const superDirWithPlan = path.join(tmpDirWithPlan, '.super');
fs.mkdirSync(superDirWithPlan);
fs.writeFileSync(path.join(superDirWithPlan, 'plan.md'), '# Plan\nVerify: yes\nDependencies: none');

const tmpDirSimple = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));
const superDirSimple = path.join(tmpDirSimple, '.super');
fs.mkdirSync(superDirSimple);
fs.writeFileSync(path.join(superDirSimple, 'state.json'), JSON.stringify({ simple_mode: true }));

const tmpDirNone = fs.mkdtempSync(path.join(os.tmpdir(), 'super-test-'));

console.log('\nPlan Guard Tests');
console.log('================\n');

// 1. No .super/ directory — should pass silently
test('No .super dir — pass through', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDirNone, 'src/app.js') },
  cwd: tmpDirNone,
}, false);

// 2. .super/ exists, no plan, editing source — should warn
test('.super/ exists, no plan, editing source — warn', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDir, 'src/app.js') },
  cwd: tmpDir,
}, true);

// 3. .super/ exists, plan exists — should pass
test('.super/ exists, plan exists — pass', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDirWithPlan, 'src/app.js') },
  cwd: tmpDirWithPlan,
}, false);

// 4. .super/ exists, no plan, editing .super/ artifact — should pass (bypass)
test('Editing .super/ artifact — bypass', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDir, '.super/research.md') },
  cwd: tmpDir,
}, false);

// 5. .super/ exists, no plan, editing .md file — should pass (bypass)
test('Editing .md file — bypass', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDir, 'README.md') },
  cwd: tmpDir,
}, false);

// 6. .super/ exists, no plan, editing package.json — should pass (bypass)
test('Editing package.json — bypass', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDir, 'package.json') },
  cwd: tmpDir,
}, false);

// 7. Non-Write/Edit tool — should pass
test('Bash tool — pass through', {
  tool_name: 'Bash',
  tool_input: { command: 'echo hello' },
  cwd: tmpDir,
}, false);

// 8. SIMPLE mode — should pass even without plan
test('SIMPLE mode — pass (guard suppressed)', {
  tool_name: 'Write',
  tool_input: { file_path: path.join(tmpDirSimple, 'src/app.js') },
  cwd: tmpDirSimple,
}, false);

// Cleanup
fs.rmSync(tmpDir, { recursive: true, force: true });
fs.rmSync(tmpDirWithPlan, { recursive: true, force: true });
fs.rmSync(tmpDirSimple, { recursive: true, force: true });
fs.rmSync(tmpDirNone, { recursive: true, force: true });

console.log(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
