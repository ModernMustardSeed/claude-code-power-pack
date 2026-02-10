---
name: gtm
description: Go-to-market strategy generation with competitor analysis, channel ranking, launch checklist, and week-by-week execution plan
---

# Go-To-Market Strategy Skill

## Purpose

Generate a comprehensive go-to-market strategy for a product or feature launch. Combines project context, competitor intelligence, market research, and channel analysis into an actionable week-by-week plan.

## Trigger

User asks for a launch plan, go-to-market strategy, GTM plan, marketing strategy for a product, or how to bring something to market.

## Execution Strategy

### Phase 0: Context Load (Sequential)

1. **Read project CLAUDE.md** for product details, tech stack, and stated goals:
   ```
   Read the CLAUDE.md file in the project root
   ```
2. **Read memory graph** for existing market research, leads, brand context:
   ```
   Use mcp__memory__read_graph to load full context
   Use mcp__memory__search_nodes for the specific product/project
   ```
3. **Clarify with user** (if not already clear):
   - What is being launched? (product, feature, update, pivot)
   - Who is the target user? (be specific: role, company size, pain)
   - What is the pricing model? (free, freemium, paid, enterprise)
   - What is the timeline? (launch date or "ASAP")
   - What is the budget? (zero/bootstrap, small, significant)
   - What existing audience/channels exist?

### Phase 1: Market Intelligence (Parallel)

Run all simultaneously:

- **Competitor Search A** — "[product category] tools [year]"
- **Competitor Search B** — "[specific competitor] pricing features review"
- **Competitor Search C** — "[product category] market size [year]"
- **Community Search** — "[target audience] [pain point] reddit/forum/community"
- **Product Hunt / Launch Platforms** — "site:producthunt.com [product category]"
- **GitHub Check** — Search for open-source alternatives:
  ```
  Use mcp__github__search_repositories with relevant keywords
  ```
- **Memory Check** — Pull any previous research, leads, or competitive data from the knowledge graph

### Phase 2: Deep Competitor Analysis (Parallel per competitor)

For top 3-5 competitors identified:

- **WebFetch** their pricing page, features page, and about page
- **Check their social presence** — Web search "[competitor] twitter/linkedin followers"
- **Check reviews** — Web search "[competitor] reviews [year]" on G2, Capterra, TrustPilot
- **Identify gaps** — What are users complaining about?

### Phase 3: Strategy Synthesis (Sequential)

Use sequential-thinking if the market is complex or positioning is unclear.

Build each section of the output:

1. **Product Positioning** — How does this product uniquely serve the target user?
2. **Competitive Landscape** — Where does this fit in the market map?
3. **Channel Strategy** — Which channels will drive the most efficient growth?
4. **Launch Sequence** — What happens in what order?
5. **Growth Loops** — What mechanisms create compounding growth?

### Phase 4: Output

Compile the full GTM strategy document.

### Phase 5: Memory Storage

```
Use mcp__memory__create_entities:
  - name: "GTM Strategy: [Product] ([Date])"
  - entityType: "Strategy"
  - observations: [key positioning decisions, channel priorities, launch date]

Use mcp__memory__create_relations:
  - Strategy -> Project
  - Strategy -> related Research entities
  - Strategy -> Lead entities (target customers)
```

## Output Format

```markdown
# Go-To-Market Strategy: [Product Name]
**Date:** [Current Date]
**Launch Target:** [Date or Phase]
**Budget Level:** [Bootstrap / Small / Significant]

## Product Positioning

### One-Liner
[Complete this: "[Product] helps [target user] [achieve outcome] by [unique mechanism]"]

### Positioning Statement
For [target audience] who [situation/pain point],
[Product] is a [category] that [key benefit].
Unlike [primary competitor], we [key differentiator].

### Value Propositions (ranked by resonance)
1. **[Primary value prop]** — [Why this matters most to the target user]
2. **[Secondary value prop]** — [Supporting benefit]
3. **[Tertiary value prop]** — [Nice-to-have that tips decisions]

## Competitive Landscape

| Feature | [Your Product] | [Competitor A] | [Competitor B] | [Competitor C] |
|---------|---------------|----------------|----------------|----------------|
| [Feature 1] | ... | ... | ... | ... |
| [Feature 2] | ... | ... | ... | ... |
| Pricing | ... | ... | ... | ... |
| **Key Weakness** | ... | ... | ... | ... |

### Your Unfair Advantages
1. [Advantage with evidence]
2. [Advantage with evidence]

### Gaps to Address Before Launch
1. [Gap — severity — mitigation plan]

## Launch Channels (Ranked by Expected ROI)

| Rank | Channel | Cost | Effort | Expected Impact | Timeline |
|------|---------|------|--------|-----------------|----------|
| 1 | [Channel] | [$ or Free] | [Low/Med/High] | [Projected result] | [When] |
| 2 | [Channel] | [$ or Free] | [Low/Med/High] | [Projected result] | [When] |
| 3 | [Channel] | [$ or Free] | [Low/Med/High] | [Projected result] | [When] |

### Channel Details

#### [Top Channel]
- **Why:** [Specific reasoning with evidence]
- **How:** [Tactical steps]
- **Measure:** [KPI and target]

#### [Second Channel]
- **Why:** [Specific reasoning with evidence]
- **How:** [Tactical steps]
- **Measure:** [KPI and target]

## Growth Loops

### Loop 1: [Name] (e.g., Content -> SEO -> Signup -> Content)
```
[User action] -> [Creates value/content] -> [Attracts new users] -> [Repeat]
```
- **Kick-start:** [How to get the loop spinning initially]
- **Amplifier:** [What makes each cycle bigger than the last]

### Loop 2: [Name] (e.g., Referral -> Usage -> Referral)
```
[User action] -> [Shares/invites] -> [New user joins] -> [Repeat]
```
- **Kick-start:** [Initial activation strategy]
- **Amplifier:** [Incentive or natural sharing mechanism]

## Launch Checklist

### Pre-Launch (2+ weeks before)
- [ ] Landing page live with email capture
- [ ] Product demo video/screenshots ready
- [ ] Social accounts created and warmed up
- [ ] Email list segmented and sequences drafted
- [ ] Press/blogger outreach list compiled
- [ ] Beta testers lined up for day-one reviews
- [ ] Analytics and tracking configured
- [ ] Pricing page finalized

### Launch Day
- [ ] Product Hunt submission (if applicable)
- [ ] Social media posts across all platforms
- [ ] Email blast to list
- [ ] Personal outreach to warm leads
- [ ] Community posts (relevant subreddits, forums, Discord/Slack groups)
- [ ] Monitor and respond to all feedback within 2 hours

### Post-Launch (Week 1-2)
- [ ] Follow up with every sign-up personally
- [ ] Collect and publish testimonials
- [ ] Write "building in public" retrospective post
- [ ] Analyze channel performance and double down on winners
- [ ] Fix critical feedback items immediately

## Week-by-Week Execution Plan

### Week -2: Foundation
| Day | Task | Owner | Channel |
|-----|------|-------|---------|
| Mon | [Task] | [Role] | [Channel] |
| Tue | [Task] | [Role] | [Channel] |
| ... | ... | ... | ... |

### Week -1: Pre-Launch Buzz
| Day | Task | Owner | Channel |
|-----|------|-------|---------|
| Mon | [Task] | [Role] | [Channel] |
| ... | ... | ... | ... |

### Week 0: Launch
| Day | Task | Owner | Channel |
|-----|------|-------|---------|
| Mon | [Task] | [Role] | [Channel] |
| ... | ... | ... | ... |

### Week 1-2: Post-Launch
| Day | Task | Owner | Channel |
|-----|------|-------|---------|
| Mon | [Task] | [Role] | [Channel] |
| ... | ... | ... | ... |

### Week 3-4: Optimize
| Focus | Action | KPI Target |
|-------|--------|------------|
| [Channel] | [Optimization action] | [Metric] |
| ... | ... | ... |

## Success Metrics

| Metric | Week 1 Target | Month 1 Target | Month 3 Target |
|--------|---------------|----------------|----------------|
| Sign-ups | [N] | [N] | [N] |
| Active users | [N] | [N] | [N] |
| Revenue | [$] | [$] | [$] |
| [Custom KPI] | [N] | [N] | [N] |

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [Plan] |
| [Risk] | [H/M/L] | [H/M/L] | [Plan] |
```

## Cross-Skill Chaining

- **From research:** Competitive and market research feeds positioning and channel decisions
- **From leads:** Existing qualified leads inform launch outreach list
- **To social:** GTM strategy triggers content drafting for launch posts
- **To leads:** Post-launch, GTM shifts to ongoing lead generation
- **To briefing:** Launch milestones tracked in daily briefings

## Quality Checklist

- [ ] Positioning is specific and differentiated (not generic)
- [ ] At least 3 competitors analyzed with real data
- [ ] Channels ranked with reasoning, not just listed
- [ ] Growth loops are realistic and specific to this product
- [ ] Week-by-week plan has concrete tasks, not vague goals
- [ ] Success metrics are measurable with specific targets
- [ ] Risks identified with mitigation plans
- [ ] Strategy stored in memory graph
