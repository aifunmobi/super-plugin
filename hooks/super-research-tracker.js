#!/usr/bin/env node
// super-hook-version: 1.0.0
// /super Research & Artifact Tracker — PostToolUse hook
//
// Monitors .super/ artifact writes and tracks workflow state.
// When artifacts are written (research.md, plan.md, experiments.md, map.md),
// updates .super/state.json with timestamps and completion status.
//
// This gives the agent persistent memory of what's been done in the current
// /super session — surviving context resets and enabling resume.
//
// Also validates artifact quality:
// - Research must have confidence tags
// - Plans must have verification criteria
// - Experiment logs must have baseline measurements

const fs = require('fs');
const path = require('path');

const ARTIFACTS = {
  'research.md': { required: ['[HIGH]', '[MEDIUM]', '[LOW]'], label: 'confidence tags' },
  'plan.md': { required: ['Verify:', 'Dependencies:'], label: 'verification criteria and dependencies' },
  'experiments.md': { required: ['Baseline', 'Hypothesis'], label: 'baseline and hypothesis' },
  'map.md': { required: [], label: null },
  'map-tech.md': { required: [], label: null },
  'map-architecture.md': { required: [], label: null },
  'map-quality.md': { required: [], label: null },
  'map-concerns.md': { required: [], label: null },
};

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 5000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const toolName = data.tool_name;

    // Only track Write operations
    if (toolName !== 'Write') {
      process.exit(0);
    }

    const filePath = data.tool_input?.file_path || '';
    const cwd = data.cwd || process.cwd();
    const superDir = path.join(cwd, '.super');

    // Only track .super/ writes
    if (!filePath.includes('.super/') && !filePath.includes('.super\\')) {
      process.exit(0);
    }

    const fileName = path.basename(filePath);

    // Check if this is a tracked artifact
    const artifact = ARTIFACTS[fileName];
    if (!artifact) {
      process.exit(0);
    }

    // Update state.json
    const statePath = path.join(superDir, 'state.json');
    let state = {
      session_start: new Date().toISOString(),
      artifacts: {},
      capabilities_activated: [],
      last_updated: null,
    };

    if (fs.existsSync(statePath)) {
      try {
        state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
      } catch {
        // Corrupted, use default
      }
    }

    state.artifacts[fileName] = {
      written: new Date().toISOString(),
      size_bytes: Buffer.byteLength(data.tool_input?.content || '', 'utf8'),
    };
    state.last_updated = new Date().toISOString();

    // Infer capabilities from artifacts
    const caps = new Set(state.capabilities_activated || []);
    if (fileName === 'research.md') caps.add('RESEARCH');
    if (fileName === 'plan.md') caps.add('PLAN');
    if (fileName === 'experiments.md') caps.add('EXPERIMENT');
    if (fileName.startsWith('map')) caps.add('MAP');
    state.capabilities_activated = [...caps];

    fs.writeFileSync(statePath, JSON.stringify(state, null, 2));

    // Validate artifact quality
    const content = data.tool_input?.content || '';
    if (artifact.required.length > 0) {
      const missing = artifact.required.filter(tag => !content.includes(tag));
      if (missing.length > 0) {
        const output = {
          hookSpecificOutput: {
            hookEventName: 'PostToolUse',
            additionalContext:
              `ARTIFACT QUALITY: ${fileName} was written but is missing ${artifact.label}. ` +
              `Expected markers not found: ${missing.join(', ')}. ` +
              `Consider updating the artifact to include these for downstream consumers.`
          }
        };
        process.stdout.write(JSON.stringify(output));
        return;
      }
    }
  } catch {
    process.exit(0);
  }
});
