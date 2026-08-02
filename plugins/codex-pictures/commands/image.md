---
description: Generate an image on the Codex subscription (free). Usage: /image a hero of a Montana barn at dusk --out ~/hero.jpg --size 1600x900
argument-hint: <what to make> [--out path] [--size WxH] [--png] [--allow-text]
allowed-tools: Bash, Read, Write
---

Generate an image for Sarah on the flat Codex subscription. Never fal: fal is
video only now.

**Request:** $ARGUMENTS

Do this:

1. **Read the request for a subject, an output path, and a size.** Anything not
   given, choose sensibly and say what you chose:
   - No path: write to the scratchpad and give her the full path at the end.
   - No size: infer from the words. "hero" 1600x900, "social" or "post"
     1080x1080, "story" or "reel" 1080x1920, "og image" 1200x630, "thumbnail"
     1280x720, "print" or "apparel" 2048x2048 png. Otherwise 1600x900.
   - `--png` means PNG, and so does anything needing transparency or line art.

2. **Expand her words into a real art-direction brief** before rendering. Carry
   the subject and moment, the light named exactly, the lens and distance, the
   frame and where the negative space sits, and the film character. A bare
   subject line comes back looking like stock. If the request names a brand
   (CXC, MMS, a client), load that brand's rules first and honor the locked
   tokens.

3. **Render:**
   ```bash
   node C:/Users/moder/.claude/tools/codex-image.mjs --prompt "<the expanded brief>" --out "<path>" --width W --height H --json
   ```
   It takes 60 to 120 seconds. Do not kill it early. Add `--allow-text` only if
   the image is supposed to carry words.

4. **Look at the result with the Read tool.** This step is not optional. Judge
   it at full size: stock feel, rendered-3D feel, mangled hands, warped text,
   wrong crop. If it fails, correct the brief and render once more rather than
   handing her something she has to reject.

5. **Report** the path, the dimensions, the file size, and one line on the art
   direction you chose. If it failed twice, give her Codex's own error text
   rather than a summary, since that is where a quota or refusal message lives.
