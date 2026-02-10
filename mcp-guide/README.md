# MCP Server Setup Guide

Model Context Protocol (MCP) servers extend Claude Code with persistent capabilities. This guide covers which servers to install, why, and how.

## Priority Tiers

### Essential (Install These First)

#### Memory Server
Persistent knowledge graph that survives across sessions. This is the backbone of the 4-layer memory system.

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

**What it gives you:** Entities, relations, and observations that persist forever. Store project info, decisions, contacts, research findings.

**Key tools:** `read_graph`, `create_entities`, `add_observations`, `delete_observations`, `search_nodes`

---

#### GitHub Server
Full GitHub API access for repo operations, PRs, issues, and code search.

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

**Create a token at:** https://github.com/settings/tokens
**Scopes needed:** `repo`, `read:org`, `read:user`

**Key tools:** `create_pull_request`, `list_issues`, `search_code`, `get_file_contents`

---

#### Filesystem Server
Direct file system access beyond the working directory.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/home"]
    }
  }
}
```

**Key tools:** `read_file`, `write_file`, `list_directory`, `search_files`

---

### Recommended (High Value)

#### Sequential Thinking
Extended reasoning for complex architecture decisions, debugging, and multi-step analysis. Pairs extremely well with Opus 4.6.

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**When to use:** Complex debugging, architecture trade-off analysis, multi-step planning, conflicting research synthesis.

---

#### Context7
Look up documentation for any library by name. Eliminates hallucinated API calls.

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**Key tools:** `resolve-library-id`, `query-docs`

**Example:** Ask Claude to check the docs for `@supabase/ssr` and it will fetch the real API instead of guessing.

---

### Optional (Use Case Dependent)

#### Google Workspace
Calendar, Gmail, Docs, Sheets, Drive. Useful for the `/briefing` skill.

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "npx",
      "args": ["-y", "@anthropic/google-workspace-mcp"],
      "env": {
        "GOOGLE_CLIENT_ID": "your_client_id",
        "GOOGLE_CLIENT_SECRET": "your_client_secret"
      }
    }
  }
}
```

**Note:** Requires Google Cloud Console OAuth setup. High context cost (~40 tools loaded).

---

#### Puppeteer
Browser automation for testing and scraping.

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

**Key tools:** `puppeteer_navigate`, `puppeteer_screenshot`, `puppeteer_click`, `puppeteer_fill`

---

## Where to Configure

### Claude Code CLI
Add MCP servers to `~/.claude.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "memory": { ... },
    "github": { ... }
  }
}
```

### Per-Project
Add to `.claude.json` in your project root for project-specific servers.

## Performance Considerations

| Server | Tools Loaded | Context Impact | Recommendation |
|--------|-------------|----------------|----------------|
| memory | ~10 | Low | Always on |
| github | ~20 | Medium | Always on |
| filesystem | ~15 | Medium | Always on |
| sequential-thinking | 1 | Very Low | Always on |
| context7 | 2 | Very Low | Always on |
| google-workspace | ~40 | High | Only if you use /briefing |
| puppeteer | ~7 | Low | Only if you need browser automation |

**Total with essential + recommended:** ~48 tools, moderate context usage.
**Total with all servers:** ~95 tools, high context usage.

## Troubleshooting

### "Cannot connect to MCP server"
- Ensure `npx` is in your PATH
- Try running the command manually: `npx -y @modelcontextprotocol/server-memory`
- Check if the package exists: `npm info @modelcontextprotocol/server-memory`

### "OAuth port in use" (Google Workspace)
- The Google Workspace server uses port 8000 for OAuth callbacks
- Kill whatever is using port 8000: `lsof -i :8000` (Mac/Linux) or `netstat -ano | findstr :8000` (Windows)

### Memory server not persisting
- The memory server stores data in `~/.claude/memory/` by default
- Ensure this directory exists and is writable
- Check that the server isn't being restarted between sessions
