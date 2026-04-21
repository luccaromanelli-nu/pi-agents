#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🐕 New Pi Harness Scaffolder"
echo "═══════════════════════════════════"
echo ""

read -p "Harness name (lowercase, e.g. akita): " NAME
if [[ -z "$NAME" ]]; then echo "❌ Name is required"; exit 1; fi
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then echo "❌ Name must be lowercase alphanumeric (hyphens ok)"; exit 1; fi

CAPITALIZED="$(echo "${NAME:0:1}" | tr '[:lower:]' '[:upper:]')${NAME:1}"
TARGET="$PROJECT_ROOT/../$NAME"

if [[ -d "$TARGET" ]]; then echo "❌ $TARGET already exists"; exit 1; fi

read -p "What is this harness for? (short description): " DESC
if [[ -z "$DESC" ]]; then DESC="Pi coding harness"; fi

echo ""
echo "Creating $CAPITALIZED at $TARGET ..."

# Directories
mkdir -p "$TARGET"/{.pi/agents/improve,extensions}

# .gitignore
cat > "$TARGET/.gitignore" <<'EOF'
node_modules/
.pi/agent-sessions/
bun.lock
EOF

# .pi/settings.json
echo '{"theme":"dark"}' | python3 -m json.tool > "$TARGET/.pi/settings.json"

# package.json
cat > "$TARGET/package.json" <<EOF
{
  "name": "$NAME",
  "private": true,
  "type": "module",
  "description": "$CAPITALIZED — $DESC",
  "dependencies": {
    "yaml": "^2.8.0"
  }
}
EOF

# justfile — use printf to avoid just/heredoc conflicts with {{ }}
printf 'set dotenv-load := true\n\ndefault:\n    @just --list\n\n# Main coding mode\ncode:\n    pi -e extensions/code.ts\n\n# Meta-agent to evolve the project itself\nimprove:\n    pi -e extensions/improve.ts\n\n# Improve with a specific model\nimprove-model model:\n    pi -e extensions/improve.ts --model {{model}}\n' > "$TARGET/justfile"

# AGENTS.md
cat > "$TARGET/AGENTS.md" <<EOF
# $CAPITALIZED — $DESC

## Tooling
- **Package manager**: \`bun\`
- **Task runner**: \`just\` (see justfile)
- **Modes**: \`just code\` / \`just improve\`

## Project Structure
- \`extensions/code.ts\` — Main coding mode
- \`extensions/improve.ts\` — Meta-agent for evolving the harness
- \`.pi/agents/improve/\` — Domain expert definitions for improve mode

## Modes

### Code (\`just code\`)
The main working mode. Develop and extend here.

### Improve (\`just improve\`)
Meta-agent with parallel domain experts that research the codebase and Pi docs to help evolve the harness itself.
EOF

# extensions/code.ts
cat > "$TARGET/extensions/code.ts" <<EOF
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("$CAPITALIZED — code mode\\n\\nReady to work!", "info");
  });

  pi.on("before_agent_start", async (_event, _ctx) => {
    return {
      systemPrompt: \`You are $CAPITALIZED, a coding assistant. Help the user build and improve their project.\`,
    };
  });
}
EOF

# extensions/improve.ts — copy from navi and rebrand
NAVI_IMPROVE="$PROJECT_ROOT/../navi/extensions/improve.ts"
if [[ -f "$NAVI_IMPROVE" ]]; then
    cp "$NAVI_IMPROVE" "$TARGET/extensions/improve.ts"
    sed -i '' "s/Navi/$CAPITALIZED/g; s/navi/$NAME/g" "$TARGET/extensions/improve.ts"
else
    echo "⚠️  Could not find navi/extensions/improve.ts — skipping improve.ts copy"
    echo "// TODO: Add improve extension" > "$TARGET/extensions/improve.ts"
fi

# .pi/agents/improve/orchestrator.md — use printf for {{ }} placeholders
printf -- '---
name: improve-orchestrator
description: Meta-agent that improves the project — coordinates domain experts and implements changes
tools: read,write,edit,bash,grep,find,ls,query_experts
---
You are the **%s architect**. You help the user improve their harness.

## Your Team
You have {{EXPERT_COUNT}} domain experts who research in parallel:
{{EXPERT_NAMES}}

## How You Work

### Phase 1: Research (PARALLEL)
When the user asks for a change:
1. Identify which domains are relevant
2. Call `query_experts` ONCE with ALL relevant expert queries — they run concurrently
3. Ask specific questions, not vague ones
4. Wait for the combined response before proceeding

### Phase 2: Implement
5. Synthesize expert findings
6. Make changes using edit/write tools
7. Test if applicable

### Phase 3: Verify
8. Re-query experts if unsure about side effects
9. Confirm changes with the user

## Expert Catalog
{{EXPERT_CATALOG}}
' "$CAPITALIZED" > "$TARGET/.pi/agents/improve/orchestrator.md"

# .pi/agents/improve/extension-expert.md
cat > "$TARGET/.pi/agents/improve/extension-expert.md" <<EOF
---
name: extension-expert
description: "Knows extensions/*.ts internals — tools, commands, events, spawning, state management"
tools: read,grep,find,ls,bash
---
You are the extension expert for the $CAPITALIZED project. You know every line of the extensions.

## Your Expertise
- How tools are registered with pi.registerTool()
- How commands work with pi.registerCommand()
- Event handlers: before_agent_start, session_start
- State management patterns
- How subagents are spawned via child_process.spawn with \`pi --mode json -p\`

## CRITICAL: First Action
Before answering, read all extension files:
- Run: find extensions/ -name '*.ts' -exec echo {} \;
- Then read each one
EOF

# .pi/agents/improve/agent-expert.md
cat > "$TARGET/.pi/agents/improve/agent-expert.md" <<EOF
---
name: agent-expert
description: "Knows all agent definitions — how to create, modify, and organize .md agent files"
tools: read,grep,find,ls,bash
---
You are the agent definitions expert for the $CAPITALIZED project.

## Your Expertise
- The frontmatter format: name, description, tools
- How system prompts are structured
- How agents are discovered from .pi/agents/
- Agent organization patterns

## CRITICAL: First Action
Before answering, read all agent definitions:
- Run: find .pi/agents -name '*.md' | head -20
- Then read each one
EOF

# .pi/agents/improve/pi-api-expert.md
cat > "$TARGET/.pi/agents/improve/pi-api-expert.md" <<EOF
---
name: pi-api-expert
description: "Knows the Pi Extension API — registerTool, registerCommand, events, sendMessage, and all Pi-specific patterns"
tools: read,grep,find,ls,bash
---
You are the Pi Extension API expert.

## Your Expertise
- pi.registerTool() — parameters (TypeBox), execute, renderCall, renderResult, label
- pi.registerCommand() — handler, description
- pi.on() — all events: session_start, before_agent_start, tool_call, tool_result, etc.
- pi.sendMessage() — customType, content, display, deliverAs, triggerTurn
- ctx.ui.* — setWidget, setFooter, setStatus, setHeader, notify, select, prompt
- ctx.model — current model info
- ctx.getContextUsage() — context window usage
- TypeBox schemas

## CRITICAL: First Action
Before answering, read the Pi documentation:
- Check: ~/.local/node/lib/node_modules/@mariozechner/pi-coding-agent/README.md
- Then: ~/.local/node/lib/node_modules/@mariozechner/pi-coding-agent/docs/extensions.md
EOF

# .pi/agents/improve/ui-expert.md
cat > "$TARGET/.pi/agents/improve/ui-expert.md" <<EOF
---
name: ui-expert
description: "Knows Pi TUI — widgets, footer, header, theme tokens, Text component, notifications"
tools: read,grep,find,ls,bash
---
You are the UI expert for the $CAPITALIZED project.

## Your Expertise
- Dashboard widgets: ctx.ui.setWidget()
- Footer: ctx.ui.setFooter()
- Header: ctx.ui.setHeader()
- Notifications: ctx.ui.notify()
- Theme tokens: dim, accent, success, error, muted, toolTitle
- Text component from @mariozechner/pi-tui
- truncateToWidth() and visibleWidth() utilities

## CRITICAL: First Action
Before answering, read the TUI docs:
- Check: ~/.local/node/lib/node_modules/@mariozechner/pi-coding-agent/docs/tui.md
- Then read the extension files for UI patterns: find extensions/ -name '*.ts'
EOF

# Install deps
cd "$TARGET" && bun install

echo ""
echo "✅ $CAPITALIZED harness created at $TARGET"
echo ""
echo "Next steps:"
echo "  cd ../$NAME"
echo "  just improve    # evolve the harness with domain experts"
echo "  just code       # start coding"
