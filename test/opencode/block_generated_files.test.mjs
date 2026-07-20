// Node-side smoke test for .opencode/plugins/block_generated_files.js
// Phase 0.4 verification: exercises the plugin's `tool.execute.before` hook
// against synthetic tool inputs and asserts it throws on generated-file paths
// and is silent otherwise.
//
// Run: node test/opencode/block_generated_files.test.mjs

import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(new URL('.', import.meta.url));
const pluginPath = pathToFileURL(
  here + '../../.opencode/plugins/block_generated_files.js',
).href;

const mod = await import(pluginPath);
const pluginName = Object.keys(mod).find(
  (k) => k.toLowerCase().includes('blockgeneratedfiles') ||
         k.includes('BlockGeneratedFiles'),
);

const pluginFn = mod[pluginName];
assert.match(pluginName, /BlockGeneratedFiles/i, 'plugin export name');

const ctxStub = { directory: process.cwd() };
const hooks = await pluginFn(ctxStub);
const preExec = hooks['tool.execute.before'];
assert.equal(typeof preExec, 'function', 'tool.execute.before is a function');

let failures = 0;
function expectBlocked(label, toolName, args) {
  const input = { tool: toolName };
  const output = { args };
  assert.rejects(
    async () => preExec(input, output),
    /Blocked: .*\.(g|freezed)\.dart is generated/,
    label,
  ).then(
    () => console.log('OK   blocked    ' + label),
    (err) => {
      console.error('FAIL blocking  ' + label + '\n   ' + err);
      failures++;
    },
  );
}
function expectAllowed(label, toolName, args) {
  const input = { tool: toolName };
  const output = { args };
  try {
    const r = preExec(input, output);
    if (r && typeof r.then === 'function') {
      r.then(
        () => console.log('OK   allowed    ' + label),
        (err) => {
          console.error(
            'FAIL unexpected throw: ' + label + '\n   ' + err,
          );
          failures++;
        },
      );
    } else {
      console.log('OK   allowed    ' + label);
    }
  } catch (err) {
    console.error('FAIL unexpected throw: ' + label + '\n   ' + err);
    failures++;
  }
}

// Test cases
await expectBlocked('edit a .g.dart', 'edit', {
  filePath: 'lib/state/providers/foo.g.dart',
});
await expectBlocked('edit a .freezed.dart', 'edit', {
  filePath: 'lib/data/models/evidence_record.freezed.dart',
});
await expectBlocked('write to a .g.dart', 'write', {
  filePath: 'test/some_test.freezed.dart',
});

expectAllowed('edit a regular .dart', 'edit', {
  filePath: 'lib/services/foo.dart',
});
expectAllowed('write a non-dart file', 'write', {
  filePath: 'README.md',
});
expectAllowed('edit a .pyg.dart-like-but-not match (negative)', 'edit', {
  filePath: 'lib/foo.reg.dart',
});

// apply_patch: marker line test
await expectBlocked('apply_patch touches .g.dart', 'apply_patch', {
  patchText: '*** Update File: lib/state/providers/foo.g.dart\n@@\n-old\n+new\n',
});
await expectBlocked('apply_patch Add File to .freezed.dart', 'apply_patch', {
  patchText: '*** Add File: lib/data/models/foo.freezed.dart\n+content\n',
});
expectAllowed('apply_patch touches regular .dart', 'apply_patch', {
  patchText: '*** Update File: lib/services/foo.dart\n-old\n+new\n',
});
expectAllowed('apply_patch touches README.md', 'apply_patch', {
  patchText: '*** Update File: README.md\n-old\n+new\n',
});
expectAllowed('bash tool call passes through', 'bash', { command: 'ls' });
expectAllowed('grep tool call passes through', 'grep', { pattern: 'foo' });
expectAllowed('read .g.dart (we let reads through; rule only blocks writes)', 'read', {
  filePath: 'lib/state/providers/foo.g.dart',
});

await new Promise((r) => setTimeout(r, 100));
if (failures > 0) {
  console.error(`\n${failures} FAILURES`);
  process.exit(1);
}
console.log('\nAll block_generated_files.js plugin assertions passed.');
