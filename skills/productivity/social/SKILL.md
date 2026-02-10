---
name: social
description: Multi-platform social media content drafting with brand voice customization and approval workflow
---

# Social Media Drafting Skill

## Purpose

Draft platform-optimized social media content for X (Twitter), LinkedIn, Facebook, Instagram, and TikTok. Adapts tone and format per platform. Never posts without explicit approval.

## Trigger

User asks to draft a post, create social content, announce something, or promote content across social platforms.

## CRITICAL RULE

**NEVER post, publish, or send content without explicit user approval.** Always present drafts and wait for confirmation before any public-facing action.

## Execution Strategy

### Phase 0: Context Load (Sequential)

1. **Read memory graph** for brand voice notes, past content themes, audience context:
   ```
   Use mcp__memory__search_nodes with "brand voice" and "social content"
   ```
2. **Parse the request** to identify:
   - Core message or announcement
   - Target platforms (all or specific)
   - Tone override (if specified)
   - Any links, images, or media to include
   - Call to action (if any)

### Phase 1: Platform Drafts (Parallel)

Draft all requested platforms simultaneously, applying platform-specific rules:

#### X (Twitter)
- **Character limit:** 280 (leave room for engagement — aim for 240-260)
- **Format:** Hook in first line, core message, CTA or question
- **Hashtags:** 1-2 max, only if genuinely relevant
- **Thread format:** If content exceeds one tweet, structure as numbered thread (1/N)
- **Tone:** Conversational, punchy, opinionated
- **Best practices:**
  - Front-load the hook — first 50 chars decide scroll-stop
  - Questions drive replies
  - Avoid links in first tweet of thread (kills reach)
  - Use line breaks for readability

#### LinkedIn
- **Character limit:** 3,000 (first 210 chars visible before "see more")
- **Format:** Hook line, story/insight (short paragraphs), takeaway, CTA
- **Hashtags:** 3-5 at the bottom
- **Tone:** Professional but human, insight-driven, story-first
- **Best practices:**
  - First line MUST compel the click on "see more"
  - One idea per short paragraph (1-2 sentences)
  - Use line breaks liberally — walls of text kill engagement
  - End with a question to drive comments
  - Carousels and documents get more reach than text-only

#### Facebook
- **Character limit:** 63,206 (but keep it under 500 for engagement)
- **Format:** Relatable hook, context, value, CTA
- **Hashtags:** 0-2 (less is more on Facebook)
- **Tone:** Community-focused, warm, relatable
- **Best practices:**
  - Native video/photos dramatically outperform links
  - Questions and polls drive engagement
  - Tag relevant pages when appropriate
  - Shorter posts (under 80 chars) get more engagement

#### Instagram
- **Character limit:** 2,200 (caption)
- **Format:** Hook, value/story, CTA, hashtag block
- **Hashtags:** 5-15 relevant hashtags (mix of broad and niche)
- **Tone:** Visual-first, aspirational, authentic
- **Best practices:**
  - Caption starts with a hook (first 125 chars visible)
  - Include clear CTA ("Save this", "Share with someone who...")
  - Hashtags: mix 3-5 broad, 5-7 mid-range, 3-5 niche
  - Separate hashtags from caption with line breaks or put in first comment
  - Reels > Carousels > Single image for reach

#### TikTok
- **Character limit:** 4,000 (caption/description)
- **Format:** Hook (first 3 seconds concept), script outline, caption with hashtags
- **Hashtags:** 3-5 trending + niche mix
- **Tone:** Raw, authentic, educational or entertaining
- **Best practices:**
  - Describe the video concept and hook, not just caption
  - First 3 seconds determine retention — lead with the payoff
  - Trending sounds boost discoverability
  - Text overlays reinforce spoken content
  - Suggest a pattern interrupt at the midpoint

### Phase 2: Brand Voice Alignment (Sequential)

Check all drafts against brand voice guidelines (loaded from memory or CLAUDE.md):

- **Vocabulary:** Use/avoid specific words per brand guidelines
- **Values:** Ensure content reflects stated brand values
- **Consistency:** Cross-check that the same message feels cohesive across platforms
- **Differentiation:** Each platform version should feel native, not copy-pasted

### Phase 3: Present for Approval (Sequential)

Present all drafts in a clear format:

```markdown
## Social Media Drafts: [Topic]

### X (Twitter)
> [Draft text]

Character count: [N]/280
Suggested posting time: [Time + timezone]

### LinkedIn
> [Draft text]

Character count: [N]/3,000
Suggested posting time: [Time + timezone]

[...repeat for each platform...]

### Notes
- [Any platform-specific suggestions: images needed, video concept, etc.]
- [Alternative hooks if main hook feels weak]

**Ready to post? Tell me which platforms to proceed with, or request edits.**
```

### Phase 4: Memory Storage (After Approval)

Once approved and/or posted:
```
Use mcp__memory__create_entities to create:
  - name: "Social Post: [Topic] ([Date])"
  - entityType: "SocialContent"
  - observations: [platforms, engagement notes, content theme]

Use mcp__memory__create_relations to link:
  - SocialContent -> related Project (if promoting a project)
  - SocialContent -> Brand entity
```

## Cross-Skill Chaining

- **From research:** Research findings become thought leadership posts
- **From briefing:** Content deadlines surfaced in briefing trigger drafting
- **From gtm:** Launch announcements drafted as part of go-to-market execution
- **From leads:** Case studies and social proof content for lead nurturing
- **To research:** If user wants to post about a trending topic, chain to research first

## Brand Voice Configuration

Users can define brand voice in their project CLAUDE.md:

```markdown
## Brand Voice
- tone: [professional, casual, bold, empathetic, etc.]
- personality: [describe in 2-3 sentences]
- always_use: [words or phrases that define the brand]
- never_use: [words or phrases to avoid]
- emoji_style: [none, minimal, expressive]
- audience: [describe target audience]
```

## Content Calendar Support

If the user maintains a content calendar:
- Check memory for planned content themes
- Suggest content that fills gaps in the calendar
- Track what's been posted to avoid repetition

## Quality Checklist

- [ ] Each platform draft respects character limits
- [ ] Hook is strong and tested against "would I stop scrolling?" criterion
- [ ] CTA is clear on every platform
- [ ] Hashtags are relevant and current (not banned or oversaturated)
- [ ] Tone matches brand voice guidelines
- [ ] No content posted without explicit approval
- [ ] Drafts stored in memory after approval
