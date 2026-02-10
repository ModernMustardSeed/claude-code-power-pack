---
name: leads
description: Lead generation with parallel discovery, qualification scoring, and memory graph storage
---

# Lead Generation Skill

## Purpose

Discover, qualify, and organize potential leads by combining web search, LinkedIn intelligence, GitHub activity, and memory graph context. Outputs a scored lead table and stores qualified leads as entities in the knowledge graph.

## Trigger

User asks to find leads, prospect, identify potential customers/partners, or research companies/people in a target market.

## Execution Strategy

### Phase 0: Define Criteria (Sequential)

1. **Read memory graph** for existing lead criteria, ICP (Ideal Customer Profile), and past leads:
   ```
   Use mcp__memory__search_nodes with "lead criteria" and "ICP"
   ```
2. **Establish or confirm qualification criteria** with the user:
   - **Industry/Vertical:** What sectors?
   - **Company Size:** Revenue range, employee count, funding stage
   - **Role/Title:** Who is the decision maker?
   - **Pain Point:** What problem does your product solve for them?
   - **Geography:** Any location constraints?
   - **Budget Signals:** Hiring for relevant roles, recent funding, tech stack indicators
   - **Disqualifiers:** What automatically rules someone out?

3. **Define scoring rubric** (or use defaults):

| Signal | Points | Example |
|--------|--------|---------|
| Matches target industry | +20 | SaaS, e-commerce, creator economy |
| Right company size | +15 | 10-200 employees |
| Decision-maker role | +15 | CTO, VP Engineering, Founder |
| Active pain point signal | +20 | Job posting for role your tool replaces |
| Recent funding/growth | +10 | Series A-C in last 12 months |
| Existing tech stack fit | +10 | Uses complementary tools |
| Engaged with similar content | +10 | Follows competitors, active in relevant communities |
| **Disqualifier** | **-100** | Already has competing solution, wrong geography |

**Score interpretation:** 70+ = Hot, 40-69 = Warm, below 40 = Cold

### Phase 1: Discovery (Parallel)

Run all simultaneously:

- **Web Search A** — "[industry] companies [pain point] [year]"
- **Web Search B** — "[target role] hiring [relevant skill] [year]" (hiring = active need)
- **Web Search C** — "[competitor] alternatives" or "[competitor] switching from"
- **Memory Check** — Search existing graph for:
  - Previously identified leads not yet contacted
  - Companies mentioned in past research
  - Connections through existing relationships
- **LinkedIn Search** (via web search proxy):
  - "[target role] at [industry] companies"
  - People engaging with relevant topics
- **GitHub Search** (if relevant for developer-facing products):
  ```
  Use mcp__github__search_users or mcp__github__search_repositories
  ```
  - Active contributors in relevant ecosystems
  - Companies with public repos using complementary tech

### Phase 2: Enrichment (Parallel per lead)

For each promising lead identified in Phase 1:

- **Company website** — WebFetch their about/pricing/team page
- **LinkedIn profile** — Web search for "[name] [company] LinkedIn"
- **GitHub presence** — Check for repos, activity, tech stack signals
- **News/funding** — Web search for "[company] funding" or "[company] news [year]"
- **Tech stack signals** — Check job postings, GitHub repos, or tools like BuiltWith (via web search)

### Phase 3: Qualification (Sequential)

For each lead:

1. Apply the scoring rubric from Phase 0
2. Calculate fit score (0-100)
3. Identify the strongest signal (why this lead specifically)
4. Note the best approach angle (what to lead with in outreach)
5. Flag any concerns or unknowns

### Phase 4: Output

Present the qualified leads table plus individual profiles.

### Phase 5: Memory Storage

Store all qualified leads (score 40+) in the knowledge graph:

```
For each qualified lead, use mcp__memory__create_entities:
  - name: "[Person Name] @ [Company]"
  - entityType: "Lead"
  - observations:
    - "Fit score: [N]/100"
    - "Industry: [industry]"
    - "Role: [title]"
    - "Company size: [size]"
    - "Key signal: [strongest qualification signal]"
    - "Approach angle: [suggested approach]"
    - "Status: New"
    - "Found: [date]"

Use mcp__memory__create_relations:
  - Lead -> related Project (the product/service being sold)
  - Lead -> related Research (if research skill was used)
  - Lead -> Lead (if leads are at the same company)
```

## Output Format

```markdown
# Lead Report: [Target Description]
**Date:** [Current Date]
**Criteria:** [1-line summary of ICP]
**Leads Found:** [Total] ([Hot]/[Warm]/[Cold])

## Hot Leads (Score 70+)

| # | Name | Company | Role | Score | Key Signal | Approach |
|---|------|---------|------|-------|------------|----------|
| 1 | [Name] | [Company] | [Title] | [Score] | [Signal] | [Angle] |
| 2 | [Name] | [Company] | [Title] | [Score] | [Signal] | [Angle] |

## Warm Leads (Score 40-69)

| # | Name | Company | Role | Score | Key Signal | Approach |
|---|------|---------|------|-------|------------|----------|
| 1 | [Name] | [Company] | [Title] | [Score] | [Signal] | [Angle] |

## Lead Profiles

### [Lead Name] @ [Company] — Score: [N]/100
- **Why they fit:** [2-3 sentences on qualification]
- **Company context:** [Size, funding, recent news]
- **Tech stack:** [Known tools/technologies]
- **Approach suggestion:** [Specific outreach angle]
- **Links:** [Website] | [LinkedIn] | [GitHub]

## Suggested Next Steps
1. [Prioritized action for hottest lead]
2. [Outreach sequence suggestion]
3. [Follow-up research needed]

## Sources
- [Source URLs used during discovery]
```

## Cross-Skill Chaining

- **From research:** Industry or competitor research surfaces potential leads
- **From briefing:** Inbound emails flagged as potential leads trigger qualification
- **To social:** Lead insights inform content strategy (write about their pain points)
- **To gtm:** Qualified lead list feeds into go-to-market channel strategy
- **To research:** Unfamiliar industries or companies trigger deeper research

## Lead Lifecycle

Leads stored in memory can be updated over time:

```
Use mcp__memory__add_observations to update lead status:
  - "Status: Contacted [date]"
  - "Status: Responded [date]"
  - "Status: Meeting scheduled [date]"
  - "Status: Closed Won/Lost [date]"
  - "Note: [any relevant context from interactions]"
```

## Quality Checklist

- [ ] ICP criteria confirmed before searching
- [ ] At least 3 discovery channels used in parallel
- [ ] Each lead has a specific approach angle (not generic)
- [ ] Scoring is consistent and defensible
- [ ] Hot leads have enriched profiles with links
- [ ] All qualified leads stored in memory graph
- [ ] Sources listed for verification
