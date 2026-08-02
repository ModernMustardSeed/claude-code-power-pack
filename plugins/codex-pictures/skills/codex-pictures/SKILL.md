---
name: codex-pictures
description: The standard for generating ANY still image, anywhere. Auto-invoke whenever a task needs a picture made: a hero photo, a section image, a product or apparel visual, an ad creative, a social card, a moodboard frame, an OG image, an avatar, a thumbnail, a texture, a coloring page, an illustration, or a placeholder. Also invoke when a script or route that generates images is being written, reviewed, or migrated, and whenever the words fal, Flux, Seedream, Ideogram, nano-banana, or "generate an image" appear. Images run on the flat Codex subscription, never the metered fal wallet. fal keeps video only.
---

# Pictures come off the Codex subscription

**The law, set by Sarah 2026-08-01:** *"use codex for all image gen everywhere from now on. fal can still do full on video."*

Every still image, every project, every surface. fal is not the default anymore
and is not a coin-flip alternative: it is a paid fallback that has to be opted
into. Video stays on fal (and KIE via `/video`), because Codex has no video tool.

Why this is not just thrift: the fal wallet has run dry mid-build repeatedly and
taken real prospects' heroes down with it. The wallet went dry again 2026-08-01
("User is locked"). A flat subscription cannot do that.

## Generate an image

```bash
node C:/Users/moder/.claude/tools/codex-image.mjs \
  --prompt "<full art direction, see the brief standard below>" \
  --out hero.jpg --width 1600 --height 900 --json
```

Prints `{"ok":true,"path":...,"bytes":...,"seconds":...}` and exits 0, or
`{"ok":false,"error":...}` and exits non-zero. **A zero exit means you really
have an image**: the tool decodes the pixels before reporting success, because
`codex exec` is an agent and can narrate a success it did not achieve.

| Flag | Default | Notes |
|---|---|---|
| `--width` / `--height` | 1600x900 | Exact. It cover-fits, so ask for the size the slot actually needs. |
| `--format` | from `--out` | `jpeg` or `png`. PNG for anything needing transparency or line art. |
| `--quality` | 82 | JPEG only. |
| `--tries` | 2 | Retries the whole render. |
| `--allow-text` | off | Only when the image is SUPPOSED to carry words (ad creative, a sign). Off by default because generated lettering is usually mangled. |
| `--fallback-fal` | off | Opt in to the paid path. Use only when an image genuinely cannot be missing and Codex just failed. |
| `--json` | off | Machine-readable. Use this from scripts. |

**Timing: 60 to 120 seconds per image. That is normal. Do not kill it early.**
Renders are serialized machine-wide by a lock file, so launching several at once
queues them rather than racing. Codex quota is flat-rate but finite, and a
parallel batch is the fastest way to burn a day of it.

From Node, import it instead of shelling out:

```js
import { generateImage } from 'C:/Users/moder/modern-mustard-seed/scripts/codex-image.mjs';
const r = await generateImage({ prompt, out, width: 1600, height: 900, log: console.error });
if (!r.ok) throw new Error(r.error);
```

## Write the brief like an art director, not like a search box

A one-line subject returns stock. Carry all five or expect to regenerate:

1. **Subject and the moment.** Mid-action, human, specific. Never a product
   floating on seamless.
2. **Light, named exactly.** "Raking late-afternoon sun through a west window",
   "overcast north light", "warm tungsten pooled against blue dusk".
3. **Lens and distance.** 35mm environmental, 85mm compression, shallow depth
   with the background falling off.
4. **Frame.** What is in the foreground, where the negative space sits so type
   has somewhere to live, what bleeds off the edge.
5. **Film character.** The grade you will match, gentle halation, fine grain.

Then **judge what came back at full size.** If it reads as stock, as a rendered
3D scene, as a collage, or it has mangled hands or a sixth finger, regenerate
with a corrected prompt. Two attempts is normal. A third is cheaper than a bad
masthead.

## Sizes worth memorizing

| Slot | Size |
|---|---|
| Web hero (16:9) | 1600x900 |
| Full-bleed hero (retina) | 2400x1350 |
| Section / card | 1200x800 |
| Square social, IG feed | 1080x1080 |
| IG / FB portrait | 1080x1350 |
| Story, Reel, 9:16 | 1080x1920 |
| OG / Twitter card | 1200x630 |
| YouTube thumbnail | 1280x720 |
| Apparel print art | 2048x2048 (PNG) |

## Brand rules that still apply

- **CXC:** elite fashion register, never craft-fair. No text baked into the
  image; the logo goes on as a post-process overlay. Read
  `~/.claude/skills/design/brands/cxc.md` and `cxc-voice.md` first.
- **MMS:** the mascot is a fixed character description, not a name to prompt
  with. Reuse the `CHARACTER` string in `lib/pictures.ts` verbatim.
- **Client and demo sites:** the hero must be a photograph that clears the
  photograph gate. Never inline SVG scene art as a substitute.

## Server-side and serverless

A Vercel function cannot run the Codex CLI. Those routes call the **relay**, a
local service that wraps this same renderer:

```bash
node C:/Users/moder/modern-mustard-seed/scripts/codex-image-relay.mjs
```

Client helper: `lib/codex-relay.ts` (`renderViaRelay`). It health-checks first
and returns a typed miss so the caller can decide, rather than hanging a user
request on a 90-second render. See `codex-image-generation.md` in memory for the
token and tunnel setup.

## When it fails

The error carries **Codex's own words**, which is where a quota message, a
content refusal, or a missing login actually shows up. Read it before retrying.

- *"produced no image"* plus a quota complaint: the subscription is tapped for
  the window. Stop generating and tell Sarah. Do not silently fall back to a
  wallet that is also empty.
- *"would not decode"*: transient. Retry once.
- *"sharp not found"*: run from a repo that has it, or `npm i sharp` there.
- Never ship a placeholder or an SVG scene in a hero's place and call the build
  done. A missing hero is a failed build, and it gets reported as one.
