---
name: research
description: Deep multi-source research with parallel web searches, GitHub checks, docs review, and structured output
---

# Deep Research Skill

## Purpose

Conduct thorough, multi-source research on any topic and produce a structured report with executive summary, key findings, comparison tables, recommendations, and sources.

## Trigger

User asks to research a topic, compare technologies, evaluate tools, or investigate a question that requires gathering information from multiple sources.

## Execution Strategy

### Phase 0: Context Load (Sequential)

1. **Read memory graph** for any existing knowledge on the topic:
   ```
   Use mcp__memory__search_nodes with the research topic as query
   ```
2. **Parse the request** to identify:
   - Primary research question
   - Specific comparison targets (if any)
   - Constraints or preferences mentioned
   - Desired depth (quick overview vs. deep dive)

### Phase 1: Broad Discovery (Parallel)

Run all of these simultaneously:

- **Web Search A** — Primary topic search with current year for recency
- **Web Search B** — Alternative framing of the same question (different keywords)
- **Web Search C** — "[topic] vs alternatives comparison [year]"
- **GitHub Search** — Search repositories related to the topic for popularity signals (stars, recent activity)
- **Documentation Check** — Use context7 (resolve-library-id then query-docs) if the topic involves specific libraries or frameworks

### Phase 2: Deep Dive (Parallel per source)

For each promising result from Phase 1:

- **WebFetch** on the top 3-5 most relevant URLs
- **GitHub repo inspection** for any key repositories (README, recent issues, release frequency)
- **Documentation deep-read** for technical topics

### Phase 3: Conflict Resolution (Sequential)

When sources disagree:

1. Use **sequential-thinking** to work through conflicting claims
2. Note the disagreement explicitly in findings
3. Evaluate source credibility (official docs > blog posts > forum answers)
4. Flag unresolved conflicts for user awareness

### Phase 4: Synthesis and Output

Compile findings into the standard output format below.

### Phase 5: Memory Storage

Store research results in the memory graph:
```
Use mcp__memory__create_entities to create a Research entity with:
  - name: "Research: [Topic] ([Date])"
  - entityType: "Research"
  - observations: [key findings as individual observations]

Use mcp__memory__create_relations to link:
  - Research entity -> related project entities (if applicable)
  - Research entity -> related technology entities
```

## Output Format

```markdown
# Research Report: [Topic]
**Date:** [Current Date]
**Depth:** [Quick / Standard / Deep]

## Executive Summary
[2-3 sentences capturing the most important takeaway]

## Key Findings

### Finding 1: [Title]
[Details with supporting evidence and source attribution]

### Finding 2: [Title]
[Details with supporting evidence and source attribution]

### Finding 3: [Title]
[Details with supporting evidence and source attribution]

## Comparison Table

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| [Criterion 1] | ... | ... | ... |
| [Criterion 2] | ... | ... | ... |
| [Criterion 3] | ... | ... | ... |
| **Verdict** | ... | ... | ... |

## Recommendations

1. **Best overall:** [Option] — [Why]
2. **Best for [specific use case]:** [Option] — [Why]
3. **Avoid if:** [Conditions where recommendation changes]

## Open Questions
- [Anything unresolved or needing further investigation]

## Sources
- [Source 1](URL) — [Brief note on what it contributed]
- [Source 2](URL) — [Brief note on what it contributed]
- [Source 3](URL) — [Brief note on what it contributed]
```

## Cross-Skill Chaining

- **From briefing:** Briefing skill may trigger research when it detects a topic needing investigation
- **To gtm:** Research findings feed directly into go-to-market strategy (competitor landscape, market sizing)
- **To leads:** Research on industries or companies flows into lead qualification criteria
- **To social:** Research findings can be repurposed as thought leadership content

## Quality Checklist

- [ ] At least 3 independent sources consulted
- [ ] All claims have source attribution
- [ ] Comparison table included when evaluating options
- [ ] Recency of sources verified (prefer current year)
- [ ] Conflicts between sources explicitly noted
- [ ] Recommendations are actionable and specific
- [ ] Results stored in memory graph for future reference
