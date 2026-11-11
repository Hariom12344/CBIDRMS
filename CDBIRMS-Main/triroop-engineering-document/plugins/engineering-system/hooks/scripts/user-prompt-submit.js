#!/usr/bin/env node
// UserPromptSubmit hook for the engineering-system plugin.
// Injects a short pointer to the ES request-workflow process as additionalContext
// on every prompt. Reads the hook event from stdin (unused beyond exit safety),
// writes the hookSpecificOutput JSON to stdout, and always exits 0 so a hook
// failure never blocks the user's prompt.

const CONTEXT = `ES (Engineering System) plugin active. Before acting on this request:
- If it will change code/files: run the request-workflow skill's 9-step process (triage -> match ES skill -> confirm you understand current state (graph/read) -> plan -> size blast radius -> confirm with the user -> execute). Load the "engineering-system" skill for the sub-skill index (feature-contract, frontend-architecture, backend-architecture, api-design, proxy-infrastructure, auth-infrastructure, validation, database-orm, testing-strategy, vertical-slice-philosophy).
- If it's a pure question or read-only lookup, just answer directly - do not force the full workflow onto it.
- If unsure which ES skill applies, or the request is ambiguous in a way that would cause real rework if guessed wrong, ask the user before proceeding.`;

async function main() {
  try {
    const chunks = [];
    for await (const chunk of process.stdin) chunks.push(chunk);
    void Buffer.concat(chunks).toString("utf8");
  } catch {
    // stdin read is best-effort; the hook still injects context on failure.
  }

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: CONTEXT,
      },
    })
  );
  process.exit(0);
}

main();
