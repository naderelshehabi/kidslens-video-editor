// Block edits to generated Dart files (revamp Phase 0.4).
//
// Replaces the Claude-Code `.claude/settings.json` PreToolUse hook that
// never fired under opencode (opencode reads opencode.json + .opencode/plugins/
// instead of Claude-Code conventions).
//
// Fires on every tool call BEFORE it runs and throws when:
//   - tool === "edit" or "write"  -> output.args.filePath matches \.(g|freezed)\.dart$
//   - tool === "apply_patch"      -> output.args.patchText contains a marker
//                                    line referencing such a file
//
// Throwing from `tool.execute.before` aborts the tool call (see OpenCode docs
// for the `.env protection` example). The error message reaches the agent as
// the tool-result, so the message must be actionable.
//
// Mirrors the hard invariant in CLAUDE.md / docs/implement/revamp-checklist.md
// (Phase 0.4): never hand-edit `*.g.dart` / `*.freezed.dart`; regenerate via
// `dart run build_runner build --delete-conflicting-outputs` and commit output.

/* eslint-disable */
// @ts-nocheck
// Deno/Bun-style JSDoc for editor TS check — ignored at runtime by opencode.

/**
 * @param {object} ctx - Plugin context (project, directory, worktree, client, $).
 * @returns {Promise<object>} hook map.
 */
export const BlockGeneratedFilesPlugin = async ({ directory }) => {
  const generatedSuffix = /\.(g|freezed)\.dart$/;
  const actionableHint =
    " is generated. Edit the annotated source instead, then run: " +
    "dart run build_runner build --delete-conflicting-outputs";

  /**
   * Extract Dart file paths from apply_patch patchText marker lines.
   *
   * Markers observed in the wild (per opencode docs/tools):
   *   *** Add File: <relpath>
   *   *** Update File: <relpath>
   *   *** Move to: <relpath>
   *   *** Delete File: <relpath>
   *
   * Lines are relative to the project root; we just need to test the suffix.
   *
   * @param {string} patchText
   * @returns {string[]} list of paths referenced by the patch (may be empty).
   */
  const extractedPathsFromPatch = (patchText) => {
    if (!patchText || typeof patchText !== "string") return [];
    const matches = [];
    for (const line of patchText.split(/\r?\n/)) {
      // Anchored on leading "*** " to avoid false matches inside patch body.
      const m = /^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$/.exec(
        line,
      );
      if (m && m[1]) matches.push(m[1].trim());
    }
    return matches;
  };

  return {
    "tool.execute.before": async (input, output) => {
      const tool = input.tool;
      if (tool !== "edit" && tool !== "write" && tool !== "apply_patch") {
        return;
      }

      // edit / write carry a single filePath in output.args.filePath.
      if (tool === "edit" || tool === "write") {
        const filePath = output.args?.filePath;
        if (typeof filePath === "string" && generatedSuffix.test(filePath)) {
          throw new Error(`Blocked: ${filePath}${actionableHint}`);
        }
        return;
      }

      // apply_patch carries `patchText` with embedded path markers.
      const patchText = output.args?.patchText;
      for (const path of extractedPathsFromPatch(patchText)) {
        if (generatedSuffix.test(path)) {
          throw new Error(
            `Blocked: apply_patch targets ${path}${actionableHint}`,
          );
        }
      }
    },
  };
};
