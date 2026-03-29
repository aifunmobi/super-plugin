#!/usr/bin/env node
// Lints SKILL.md and README.md for consistency
// Catches stale syntax, orphaned options, missing sections
// Run: node tests/test-skill-lint.js

const fs = require('fs');
const path = require('path');

const SKILL = fs.readFileSync(path.join(__dirname, '..', 'skills', 'super', 'SKILL.md'), 'utf8');
const README = fs.readFileSync(path.join(__dirname, '..', 'README.md'), 'utf8');
const README_BEFORE_CHANGELOG = README.split('## Changelog')[0] || README;

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

function assert(condition, msg) {
  if (!condition) throw new Error(msg);
}

console.log('\nSKILL.md Lint');
console.log('=============\n');

test('No old --loops syntax', () => {
  assert(!SKILL.includes('--loops'), 'Found --loops (should be loops=)');
});

test('No old --dry-run syntax', () => {
  assert(!SKILL.includes('--dry-run'), 'Found --dry-run (should be dry)');
});

test('No old +capability syntax', () => {
  const hits = SKILL.match(/`\+(?:research|map|build|experiment|simple|plan|orchestrate)`/g);
  assert(!hits, `Found old +syntax: ${hits}`);
});

test('Uses loops= syntax', () => {
  assert(SKILL.includes('loops='), 'loops= not found');
});

test('All option keywords present', () => {
  const required = ['simple', 'no-simple', 'research', 'no-research', 'map', 'no-map',
    'experiment', 'no-experiment', 'illustrate', 'dry', 'clean', 'update', 'loops='];
  const missing = required.filter(k => !SKILL.includes(k));
  assert(missing.length === 0, `Missing: ${missing.join(', ')}`);
});

test('Two-phase research pattern documented', () => {
  assert(SKILL.includes('Two-Phase Research Pattern'), 'Missing two-phase section header');
  assert(SKILL.includes('Phase 1'), 'Missing Phase 1');
  assert(SKILL.includes('Phase 2'), 'Missing Phase 2');
  assert(SKILL.includes('research-raw.md'), 'Missing research-raw.md artifact');
  assert(SKILL.includes('Sub-agents do NOT have web search access'), 'Missing platform constraint note');
});

test('No old single-phase research pattern', () => {
  assert(!SKILL.includes('Dispatch 4 parallel researchers'), 'Found old single-phase research pattern');
});

test('Two-phase MAP pattern documented', () => {
  assert(SKILL.includes('Two-Phase Codebase Mapping'), 'Missing two-phase MAP section header');
  assert(SKILL.includes('map-raw.md'), 'Missing map-raw.md artifact');
  assert(SKILL.includes('Tech analyst') || SKILL.includes('Tech analyst'), 'Missing Tech analyst in MAP Phase 2');
});

test('No old single-phase MAP pattern', () => {
  // The old pattern just said "Dispatch up to 4 parallel agents" without a Phase 1/2 split
  const mapSection = SKILL.split('## MAP')[1]?.split('## BUILD')[0] || '';
  assert(mapSection.includes('Phase 1') && mapSection.includes('Phase 2'), 'MAP section missing Phase 1/2 structure');
});

test('ILLUSTRATE capability documented', () => {
  assert(SKILL.includes('## ILLUSTRATE'), 'Missing ILLUSTRATE section');
  assert(SKILL.includes('matplotlib'), 'Missing matplotlib reference');
  assert(SKILL.includes('Agg'), 'Missing Agg backend reference');
  assert(SKILL.includes('chart-specs.json'), 'Missing chart-specs.json artifact');
  assert(SKILL.includes('.super/charts/'), 'Missing charts directory reference');
});

test('illustrate option in option table', () => {
  assert(SKILL.includes('`illustrate`'), 'illustrate not in option table');
  assert(SKILL.includes('`no-illustrate`') || SKILL.includes('no-illustrate'), 'no-illustrate not mentioned');
});

test('Update meta-command documented', () => {
  assert(SKILL.includes('/super update'), 'Missing /super update section');
  assert(SKILL.includes('Update to v'), 'Missing update output example');
});

test('Execution plan section exists', () => {
  assert(SKILL.includes('Proceed? [Y/n]'), 'Missing confirmation prompt');
});

test('SIMPLE skips confirmation', () => {
  assert(SKILL.includes('SIMPLE') && SKILL.includes('skip'), 'SIMPLE confirmation skip not documented');
});

test('Diminishing returns rule', () => {
  assert(SKILL.includes('10%'), 'Diminishing returns threshold missing');
});

test('Safety cap at 100', () => {
  assert(SKILL.includes('100') && SKILL.toLowerCase().includes('safety cap'), 'Safety cap not documented');
});

test('Default loop values documented', () => {
  assert(SKILL.includes('Research re-research | 2'), 'Research default not documented');
  assert(SKILL.includes('Plan verification | 2'), 'Plan default not documented');
  assert(SKILL.includes('Experiment hypotheses | 3'), 'Experiment default not documented');
});

console.log('\nREADME.md Lint');
console.log('==============\n');

test('No old --loops in README (before changelog)', () => {
  assert(!README_BEFORE_CHANGELOG.includes('--loops'), 'Found --loops');
});

test('No old --dry-run in README (before changelog)', () => {
  assert(!README_BEFORE_CHANGELOG.includes('--dry-run'), 'Found --dry-run');
});

test('No old +/- flags in README (before changelog)', () => {
  const hits = README_BEFORE_CHANGELOG.match(/`[+-](?:research|map|build|experiment|simple)`/g);
  assert(!hits, `Found old syntax: ${hits}`);
});

test('Install URL uses main branch', () => {
  assert(README.includes('aifunmobi/super-plugin/main/install.sh'), 'Not using main branch');
});

test('All 8 capabilities mentioned', () => {
  const caps = ['SIMPLE', 'PLAN', 'RESEARCH', 'MAP', 'BUILD', 'EXPERIMENT', 'GENERATE-CLI', 'ORCHESTRATE'];
  const missing = caps.filter(c => !README.includes(c));
  assert(missing.length === 0, `Missing: ${missing.join(', ')}`);
});

test('Option reference section exists', () => {
  assert(README.includes('option reference'), 'No option reference section');
});

test('loops= syntax used in README', () => {
  assert(README_BEFORE_CHANGELOG.includes('loops='), 'loops= not found');
});

test('Two-phase research mentioned in README', () => {
  assert(README.includes('two-phase') || README.includes('Two-phase'), 'Two-phase research not in README');
  assert(README.includes('Phase 1') && README.includes('Phase 2'), 'Phase 1/2 not described in README');
});

console.log(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
