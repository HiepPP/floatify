## Overview

Redesign the Floatify website as a Mario-style game world. The page itself is the game - dark sky background with parallax clouds, pixel art ground tiles, floating question-mark blocks. Each section is a "level" the visitor scrolls through. Mix of Switch UI shell structure, game-world decorations, and playful Nintendo-style interactions.

Stack: Astro + Tailwind (existing). No heavy JS libraries. Pure CSS animations + vanilla JS + Intersection Observer.

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| sky-dark | #1a1a2e | Background gradient start |
| sky-mid | #16213e | Background gradient end |
| mario-red | #E52521 | Primary CTA, accents |
| coin-gold | #F5C518 | Highlights, badges, coin animations |
| pipe-green | #049C2F | Success states, complete status, pipes |
| sky-blue | #6185F8 | Links, secondary actions |
| cloud-white | #F0F0F0 | Primary text |
| brick-brown | #C84C09 | Cards, block borders |
| ground-brown | #8B5E34 | Section dividers, ground tiles |
| block-tan | #D4A55A | Question-mark blocks |

## Typography

- Headers: "Press Start 2P" (Google Fonts) - pixel game font
- Body: "Inter" (Google Fonts) - clean readable contrast
- Code: system monospace with game-console styling (dark screen, subtle scanline overlay)

## Page Background - Game World

Full-page layered parallax background using CSS transforms on scroll:

- Layer 1 (far): star field - small white dots, very slow parallax
- Layer 2 (mid): pixel-art clouds drifting horizontally via CSS animation, medium parallax
- Layer 3 (near): ground tile strip at section transitions

All layers are CSS-only (radial gradients for stars, inline SVG or CSS shapes for clouds). No external image files needed.

## Section 1: Hero - "Game Start Screen"

Layout:
- Full viewport height, centered content
- Parallax star field + drifting clouds behind

Elements:
- "FLOATIFY" in Press Start 2P, large (clamp 3rem - 5rem), white with 3px dark drop shadow
- Subtitle "Session HUDs for Developers" in Inter, cloud-white, smaller
- Tagline line below: "A macOS menu bar app for Claude Code and Codex" in muted text
- Animated coin counter in top-right corner (decorative spinning coin CSS sprite + number)

Entrance animation (on page load, ~800ms staggered):
- Title drops in from above with bounce easing
- Subtitle fades up 200ms after
- Buttons scale-in 400ms after

Buttons:
- "START" in mario-red, chunky rounded, gentle bounce animation (translateY 2px loop). Links to #installation
- "GitHub" secondary button, outlined sky-blue

Terminal block (existing typing animation):
- Restyled as a "message block" with brick-brown border, pixel corner accents
- On click: coin-pop particle burst (5-8 small gold circles fly out via CSS animation) as copy feedback instead of plain "Copied!" text

## Section 2: Demo - "World 1-1"

Section header: "WORLD 1-1" in Press Start 2P, small caps tracking, coin-gold color

The existing demo video wrapped in a pixel-art frame:
- 4px solid brick-brown border with pixel corner pieces (small square overlaps at corners)
- "PRESS PLAY" overlay centered on the video thumbnail, retro play triangle icon
- Overlay fades out when video plays

A decorative row of small brick tiles above the section as ground/divider.

## Section 3: Features - "Power-Ups"

Section header: "POWER-UPS" in Press Start 2P, coin-gold

Feature cards (8 features, same content as current site):
- Grid: 1 col mobile, 2 col md, 3 col lg
- Each card styled as a question-mark block:
  - block-tan background with subtle inner shadow
  - "?" watermark behind content (large, low opacity)
  - Brick-brown 2px border
  - Pixel-art icon above title (inline SVG, 32x32)

Scroll animation (Intersection Observer):
- When a card enters viewport, it plays a "block hit" animation: translateY -8px fast, then settle back with bounce
- Staggered: each card triggers 100ms after the previous

Feature list (same content, new titles where noted):
1. Per-Session Floaters
2. Zero Focus Stealing
3. Project-Aware Labels
4. Drag, Close, Arrange
5. Color-First Status
6. Claude and Codex
7. Render Modes (Super Slay / Slay / Lame)
8. File Changes and Activity

## Section 4: Interactive Floater Playground - "Mini-Game"

This is the centerpiece wow moment. A live interactive mockup.

Layout:
- Centered container, max-w-lg
- Pixel border frame (double border: outer brick-brown, inner block-tan, 4px gap)
- Header bar: "FLOATER DEMO" in Press Start 2P, small

Mockup content:
- A div styled to look like an actual Floatify floater panel:
  - Dark rounded rectangle (similar to real app)
  - Project label "floatify"
  - Colored status dot (changes color based on selected state)
  - Small sprite character (CSS pixel art, 16x16, simple character)
  - File count "3 files" and activity "Just now"
- Sprite character has idle animation (2-frame pixel shift loop)

Controls below the mockup:
- Three buttons: "Running" (red), "Idle" (yellow), "Complete" (green)
- Styled as game controller buttons (rounded, with pressed state)
- Clicking a button:
  - Changes status dot color
  - Running: red pulsing glow on the floater border
  - Idle: yellow steady glow
  - Complete: green glow + CSS confetti burst (15-20 small colored squares fly out from center, fade and fall via CSS animation, removed after 1s)
- Sprite character changes animation frame on status change

All vanilla JS. No libraries.

## Section 5: How It Works - "Warp Pipe Flow"

Section header: "WARP ZONE" in Press Start 2P, pipe-green

Three green pipes in a horizontal row (flexbox, responsive to stack on mobile):
- Each pipe is CSS-drawn: vertical green rectangle with wider top rim
- Label above each pipe in Inter

Flow:
```
[Hook Trigger] -> Pipe 1 -> [CLI Command] -> Pipe 2 -> [Floater Appears]
```

Scroll animation:
- When section enters viewport, a small "data packet" (gold square, 8x8) animates from left to right, entering pipe 1, exiting, traveling to pipe 2, exiting, then a mini floater pops up at the end
- CSS keyframe animation, ~2s duration, plays once

Labels below each pipe in Inter:
1. "Live process scan discovers sessions"
2. "CLI sends status via FIFO pipe"
3. "Persistent floater appears per session"

## Section 6: Installation - "Player Select"

Section header: "START GAME" in Press Start 2P, mario-red

Styled as a game setup / character select screen:
- Dark container with pixel border
- Steps as a vertical list with game-console screen styling

Each step:
- Left: step number in a coin-gold circle badge
- Right: description + code block
- Code blocks: dark background (#0f0f1a), subtle horizontal scanline overlay (CSS repeating-linear-gradient, 1px lines at 3px interval, very low opacity), monospace text in cloud-white

Steps (merged from current CLI Reference + Hook Setup + Installation):
1. Clone: `git clone https://github.com/hieppp/floatify.git`
2. Build: `cd floatify && ./build.sh`
3. What build.sh does (text explanation, no code)
4. Hook setup for Claude Code: settings.json snippet
5. Hook setup for Codex: hooks.json snippet
6. Test it: `floatify --status running` / `floatify --status complete`

"INSERT COIN" copy button on each code block. On click: coin sprite pops out (same as hero terminal block feedback).

Below the steps: GitHub link button styled as an arcade "CONTINUE?" prompt.

## Section 7: Game Options (compact)

Replaces the old Settings/Gaps section. Single row of 4 small cards (2x2 on mobile):

| Render mode | Theme | Display style | Idle timeout |
Styled as game option toggles (small block-tan cards with pixel border).

One-liner note below: "Codex infers task state from logs. Claude needs hooks for precise status."

## Footer

Dark ground-tile strip background.
- Left: "2026 Floatify" in pixel font, small
- Center: "MIT License" badge (coin-gold border)
- Right: GitHub link
- No back-to-top (the scroll character serves as progress indicator)

## Scroll-Following Character

A small pixel-art character (16x16 CSS pixel art) fixed to the left edge of the viewport:
- Position: fixed, left 16px, bottom calculated from scroll progress
- Moves vertically as user scrolls (translateY mapped to scroll percentage)
- Simple 2-frame walk animation while scrolling, idle frame when stopped
- Hidden on mobile (below md breakpoint) to save space
- CSS-only pixel art using box-shadow technique (single-element pixel drawing)

## Dropped Sections

- FAQ: essential info redistributed into Features and Installation
- Separate CLI Reference: merged into Installation step 6
- Separate Hook Setup: merged into Installation steps 4-5
- Settings/Gaps: compressed into "Game Options" compact card row

## Kept As-Is

- Layout.astro meta tags, SEO, structured data (update descriptions to match new theme)
- Demo video (demo.mp4) - just reframed with pixel art border
- Favicon
- Astro + Tailwind + static output config

## Performance Constraints

- No external JS libraries. Vanilla JS only.
- All pixel art via CSS (box-shadow technique or inline SVG). No image sprites.
- CSS animations use transform/opacity only (GPU composited, no layout thrash).
- Intersection Observer with threshold 0.2 for scroll triggers. Observe once, then unobserve.
- Parallax via CSS perspective transform on a wrapper, not JS scroll listeners.
- Confetti particles: max 20 elements, removed from DOM after animation ends (1s).
- Total added JS: estimated under 3KB minified.
- Google Fonts: Press Start 2P (~8KB) + Inter (~15KB variable). Both with display=swap.

## File Changes

| File | Action |
|------|--------|
| website/src/pages/index.astro | Rewrite - all new sections and markup |
| website/src/styles/global.css | Rewrite - new palette, pixel art utilities, animations |
| website/src/layouts/Layout.astro | Update - new fonts, updated meta description |
| website/tailwind.config.mjs | Update - new color tokens, remove old terminal tokens |

No new files needed. Everything fits in the existing 4-file structure.
