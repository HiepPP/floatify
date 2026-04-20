# Website Nintendo Redesign Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Goal: Redesign the Floatify website as a Mario-style game world with parallax background, pixel art decorations, interactive floater playground, scroll animations, and a scroll-following character.

Architecture: Single-page Astro site. Four files total - tailwind config for color tokens, global CSS for animations/pixel art/parallax utilities, Layout.astro for fonts/meta, index.astro for all sections and inline JS. Pure CSS animations + vanilla JS + Intersection Observer. No external libraries.

Tech Stack: Astro 4, Tailwind CSS 3, Google Fonts (Press Start 2P + Inter), vanilla JS

Spec: `docs/superpowers/specs/2026-04-21-website-nintendo-redesign-design.md`

---

### Task 1: Tailwind Config - New Color Tokens and Typography

Files:
- Modify: `website/tailwind.config.mjs`

- [ ] Step 1: Replace the tailwind config with new game-world tokens

Replace the entire `website/tailwind.config.mjs` contents with:

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
  ],
  theme: {
    extend: {
      colors: {
        game: {
          'sky-dark': '#1a1a2e',
          'sky-mid': '#16213e',
          'mario-red': '#E52521',
          'coin-gold': '#F5C518',
          'pipe-green': '#049C2F',
          'sky-blue': '#6185F8',
          'cloud-white': '#F0F0F0',
          'brick-brown': '#C84C09',
          'ground-brown': '#8B5E34',
          'block-tan': '#D4A55A',
          'console-dark': '#0f0f1a',
        },
      },
      fontFamily: {
        pixel: ['"Press Start 2P"', 'monospace'],
        body: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['SF Mono', 'Fira Code', 'monospace'],
      },
    },
  },
  plugins: [],
};
```

Note: flowbite plugin removed - not used in the redesign.

- [ ] Step 2: Verify Tailwind picks up the new config

Run: `cd /Users/hiep/Projects/floatify/website && npx tailwind --help`
Expected: No config errors. (Full verification comes after global.css is updated.)

- [ ] Step 3: Commit

```bash
git add website/tailwind.config.mjs
git commit -m "feat(website): replace terminal tokens with game-world color palette"
```

---

### Task 2: Global CSS - Animations, Pixel Art Utilities, Parallax

Files:
- Modify: `website/src/styles/global.css`

- [ ] Step 1: Replace global.css with game-world base styles and all CSS animations

Write the full contents of `website/src/styles/global.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

html {
  scroll-behavior: smooth;
}

body {
  font-family: 'Inter', system-ui, sans-serif;
  background: linear-gradient(180deg, #1a1a2e 0%, #16213e 50%, #1a1a2e 100%);
  background-attachment: fixed;
  color: #F0F0F0;
  -webkit-font-smoothing: antialiased;
  overflow-x: hidden;
}

/* --- Star field background --- */
.star-field {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  background:
    radial-gradient(1px 1px at 10% 20%, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 25% 45%, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 40% 15%, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 55% 70%, rgba(255,255,255,0.5), transparent),
    radial-gradient(1px 1px at 70% 35%, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 85% 60%, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 15% 80%, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 50% 50%, rgba(255,255,255,0.5), transparent),
    radial-gradient(1px 1px at 90% 10%, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 35% 90%, rgba(255,255,255,0.6), transparent),
    radial-gradient(1.5px 1.5px at 5% 55%, rgba(255,255,255,0.9), transparent),
    radial-gradient(1.5px 1.5px at 60% 25%, rgba(255,255,255,0.7), transparent),
    radial-gradient(1.5px 1.5px at 80% 80%, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 45% 5%, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 95% 45%, rgba(255,255,255,0.5), transparent),
    radial-gradient(1px 1px at 20% 65%, rgba(255,255,255,0.7), transparent),
    radial-gradient(1.5px 1.5px at 75% 50%, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 30% 30%, rgba(255,255,255,0.8), transparent);
}

/* --- Drifting clouds --- */
.cloud {
  position: absolute;
  width: 80px;
  height: 30px;
  background: rgba(240, 240, 240, 0.08);
  border-radius: 15px;
  filter: blur(1px);
}

.cloud::before {
  content: '';
  position: absolute;
  width: 40px;
  height: 20px;
  background: rgba(240, 240, 240, 0.08);
  border-radius: 10px;
  top: -10px;
  left: 15px;
}

.cloud-layer {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}

.cloud-drift-1 { animation: drift 60s linear infinite; }
.cloud-drift-2 { animation: drift 45s linear infinite reverse; }
.cloud-drift-3 { animation: drift 75s linear infinite; }

@keyframes drift {
  from { transform: translateX(-120px); }
  to { transform: translateX(calc(100vw + 120px)); }
}

/* --- Ground tile divider --- */
.ground-divider {
  height: 16px;
  background:
    repeating-linear-gradient(
      90deg,
      #8B5E34 0px,
      #8B5E34 15px,
      #6B4423 15px,
      #6B4423 16px
    );
  background-size: 16px 16px;
  image-rendering: pixelated;
}

/* --- Scanline overlay for code blocks --- */
.scanlines {
  position: relative;
}

.scanlines::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent 0px,
    transparent 2px,
    rgba(0, 0, 0, 0.08) 2px,
    rgba(0, 0, 0, 0.08) 3px
  );
  pointer-events: none;
  border-radius: inherit;
}

/* --- Pixel border utility --- */
.pixel-border {
  border: 4px solid #C84C09;
  box-shadow:
    4px 0 0 0 #C84C09,
    -4px 0 0 0 #C84C09,
    0 4px 0 0 #C84C09,
    0 -4px 0 0 #C84C09;
}

.pixel-border-double {
  border: 4px solid #C84C09;
  outline: 4px solid #D4A55A;
  outline-offset: 4px;
}

/* --- Hero entrance animations --- */
.hero-title {
  animation: dropBounce 0.8s cubic-bezier(0.34, 1.56, 0.64, 1) both;
}

.hero-subtitle {
  animation: fadeUp 0.6s ease-out 0.2s both;
}

.hero-buttons {
  animation: scaleIn 0.5s ease-out 0.4s both;
}

@keyframes dropBounce {
  0% { transform: translateY(-60px); opacity: 0; }
  60% { transform: translateY(8px); opacity: 1; }
  80% { transform: translateY(-4px); }
  100% { transform: translateY(0); }
}

@keyframes fadeUp {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes scaleIn {
  from { transform: scale(0.8); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

/* --- START button bounce --- */
.btn-bounce {
  animation: gentleBounce 2s ease-in-out infinite;
}

@keyframes gentleBounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-3px); }
}

/* --- Coin spin --- */
.coin-spin {
  display: inline-block;
  animation: coinSpin 1.5s linear infinite;
}

@keyframes coinSpin {
  0%, 100% { transform: scaleX(1); }
  25% { transform: scaleX(0.3); }
  50% { transform: scaleX(1); }
  75% { transform: scaleX(0.3); }
}

/* --- Coin pop particles --- */
.coin-particle {
  position: absolute;
  width: 8px;
  height: 8px;
  background: #F5C518;
  border-radius: 50%;
  pointer-events: none;
  animation: coinPop 0.8s ease-out forwards;
}

@keyframes coinPop {
  0% { transform: translate(0, 0) scale(1); opacity: 1; }
  100% { transform: translate(var(--tx), var(--ty)) scale(0.3); opacity: 0; }
}

/* --- Block hit animation --- */
.block-hit {
  animation: blockHit 0.4s ease-out;
}

@keyframes blockHit {
  0% { transform: translateY(0); }
  30% { transform: translateY(-8px); }
  60% { transform: translateY(2px); }
  100% { transform: translateY(0); }
}

/* --- Question mark block card --- */
.q-block {
  position: relative;
  overflow: hidden;
}

.q-block::before {
  content: '?';
  position: absolute;
  right: -5px;
  bottom: -15px;
  font-family: 'Press Start 2P', monospace;
  font-size: 5rem;
  color: rgba(255, 255, 255, 0.04);
  pointer-events: none;
  line-height: 1;
}

/* --- Confetti burst --- */
.confetti-piece {
  position: absolute;
  width: 6px;
  height: 6px;
  pointer-events: none;
  animation: confettiFall 1s ease-out forwards;
}

@keyframes confettiFall {
  0% { transform: translate(0, 0) rotate(0deg) scale(1); opacity: 1; }
  100% { transform: translate(var(--cx), var(--cy)) rotate(var(--cr)) scale(0.2); opacity: 0; }
}

/* --- Warp pipe --- */
.warp-pipe {
  position: relative;
  width: 60px;
  height: 80px;
  background: #049C2F;
  border-radius: 0;
}

.warp-pipe::before {
  content: '';
  position: absolute;
  top: 0;
  left: -6px;
  width: 72px;
  height: 20px;
  background: #05B636;
  border-radius: 4px 4px 0 0;
  border: 2px solid #037A22;
}

.warp-pipe::after {
  content: '';
  position: absolute;
  top: 20px;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(90deg, #037A22 0%, #049C2F 30%, #05B636 50%, #049C2F 70%, #037A22 100%);
}

/* --- Data packet animation --- */
.data-packet {
  width: 8px;
  height: 8px;
  background: #F5C518;
  position: absolute;
  opacity: 0;
}

.data-packet.animate {
  animation: packetTravel 2.5s ease-in-out forwards;
}

@keyframes packetTravel {
  0% { left: 0%; top: 50%; opacity: 1; }
  20% { left: 25%; top: 30%; opacity: 1; }
  35% { left: 25%; top: 80%; opacity: 0.5; }
  40% { left: 30%; top: 50%; opacity: 1; }
  60% { left: 60%; top: 30%; opacity: 1; }
  75% { left: 60%; top: 80%; opacity: 0.5; }
  80% { left: 65%; top: 50%; opacity: 1; }
  100% { left: 95%; top: 50%; opacity: 1; transform: scale(1.5); }
}

/* --- Sprite pixel character (idle) --- */
.pixel-sprite {
  width: 16px;
  height: 16px;
  image-rendering: pixelated;
  animation: spriteIdle 1s step-end infinite;
}

@keyframes spriteIdle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-1px); }
}

/* --- Scroll character --- */
.scroll-character {
  position: fixed;
  left: 16px;
  z-index: 50;
  width: 16px;
  height: 16px;
  pointer-events: none;
  transition: bottom 0.1s linear;
}

.scroll-character.walking {
  animation: spriteWalk 0.4s step-end infinite;
}

@keyframes spriteWalk {
  0%, 100% { transform: translateY(0) scaleX(1); }
  25% { transform: translateY(-2px) scaleX(1); }
  50% { transform: translateY(0) scaleX(-1); }
  75% { transform: translateY(-2px) scaleX(-1); }
}

/* --- Glow effects for floater playground --- */
.glow-red { box-shadow: 0 0 12px 2px rgba(229, 37, 33, 0.5); }
.glow-yellow { box-shadow: 0 0 12px 2px rgba(245, 197, 24, 0.5); }
.glow-green { box-shadow: 0 0 12px 2px rgba(4, 156, 47, 0.5); }

.glow-red-pulse {
  animation: pulseRed 1.5s ease-in-out infinite;
}

@keyframes pulseRed {
  0%, 100% { box-shadow: 0 0 12px 2px rgba(229, 37, 33, 0.3); }
  50% { box-shadow: 0 0 20px 4px rgba(229, 37, 33, 0.6); }
}

/* --- Typing cursor --- */
.typing-cursor {
  display: inline-block;
  width: 10px;
  height: 20px;
  background: #F0F0F0;
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

/* --- Intersection observer fade-in utility --- */
.observe-hidden {
  opacity: 0;
  transform: translateY(20px);
}

.observe-visible {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.5s ease-out, transform 0.5s ease-out;
}

/* --- Selection color --- */
::selection {
  background: rgba(245, 197, 24, 0.3);
}
```

- [ ] Step 2: Verify the dev server reloads without errors

Check: `http://localhost:4322/` - page should load (will look broken until index.astro is updated, that's expected). No CSS build errors in terminal.

- [ ] Step 3: Commit

```bash
git add website/src/styles/global.css
git commit -m "feat(website): add game-world CSS animations, pixel art utilities, parallax layers"
```

---

### Task 3: Layout.astro - Fonts and Meta Updates

Files:
- Modify: `website/src/layouts/Layout.astro`

- [ ] Step 1: Update Layout.astro with new fonts and updated meta

Replace the full contents of `website/src/layouts/Layout.astro`:

```astro
---
interface Props {
  title: string;
  description?: string;
  image?: string;
}

const {
  title,
  description = "Floatify - A macOS menu bar app with persistent session floaters for Claude Code and Codex. Per-session HUDs with project labels, status colors, sprite avatars, and render modes.",
  image = "/floatify-og-image.png"
} = Astro.props;

const siteUrl = "https://floatify.app";
const twitterHandle = "@hieppp";
const githubUrl = "https://github.com/hieppp/floatify";
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <!-- Primary Meta Tags -->
    <title>{title}</title>
    <meta name="title" content={title} />
    <meta name="description" content={description} />
    <meta name="author" content="hieppp" />
    <meta name="robots" content="index, follow" />
    <link rel="canonical" href={siteUrl} />

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website" />
    <meta property="og:url" content={siteUrl} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={`${siteUrl}${image}`} />
    <meta property="og:site_name" content="Floatify" />

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:url" content={siteUrl} />
    <meta name="twitter:title" content={title} />
    <meta name="twitter:description" content={description} />
    <meta name="twitter:image" content={`${siteUrl}${image}`} />
    <meta name="twitter:creator" content={twitterHandle} />

    <!-- GitHub -->
    <meta name="github:url" content={githubUrl} />

    <!-- Favicon -->
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />

    <!-- Google Fonts: Press Start 2P + Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Press+Start+2P&display=swap" rel="stylesheet" />

    <!-- JSON-LD Structured Data -->
    <script type="application/ld+json">
      {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": "Floatify",
        "description": "A macOS menu bar app with one persistent floater per Claude Code or Codex session, temporary CLI notifications, and render modes from Super Slay to Lame.",
        "url": "https://floatify.app",
        "applicationCategory": "DeveloperTool",
        "operatingSystem": "macOS",
        "programmingLanguage": "Swift",
        "license": "https://opensource.org/licenses/MIT",
        "author": {
          "@type": "Person",
          "name": "hieppp",
          "url": "https://github.com/hieppp"
        },
        "repository": {
          "@type": "SoftwareSourceCode",
          "url": "https://github.com/hieppp/floatify"
        },
        "keywords": ["macOS", "notification", "menu bar", "session floater", "developer tools", "Claude Code", "Codex", "IPC", "FIFO", "render mode"],
        "offers": {
          "@type": "Offer",
          "price": "0",
          "priceCurrency": "USD"
        },
        "screenshot": "https://floatify.app/floatify-screenshot.png",
        "softwareVersion": "1.0.0"
      }
    </script>

    <!-- Theme -->
    <meta name="theme-color" content="#1a1a2e" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
  </head>
  <body>
    <slot />
  </body>
</html>
```

Key changes: added Google Fonts link (Press Start 2P + Inter), updated theme-color to sky-dark, removed `class="dark"` from html (not needed), removed inline body classes (handled by global.css).

- [ ] Step 2: Verify dev server reloads, fonts load

Check: `http://localhost:4322/` - open Network tab, verify `fonts.googleapis.com` requests succeed.

- [ ] Step 3: Commit

```bash
git add website/src/layouts/Layout.astro
git commit -m "feat(website): add game fonts and update meta for nintendo theme"
```

---

### Task 4: Index.astro - Hero Section (Section 1)

Files:
- Modify: `website/src/pages/index.astro`

This task starts the full rewrite of index.astro. Begin with the frontmatter, background layers, nav, and hero section. Subsequent tasks append remaining sections.

- [ ] Step 1: Write the initial index.astro with background layers, nav, and hero

Replace the full contents of `website/src/pages/index.astro`:

```astro
---
import Layout from '../layouts/Layout.astro';
---

<Layout title="Floatify - Session Floaters for Claude Code and Codex">

  <!-- Background layers -->
  <div class="star-field" aria-hidden="true"></div>
  <div class="cloud-layer" aria-hidden="true">
    <div class="cloud cloud-drift-1" style="top: 15%; left: -80px;"></div>
    <div class="cloud cloud-drift-2" style="top: 35%; left: -80px; width: 100px; height: 35px;"></div>
    <div class="cloud cloud-drift-3" style="top: 60%; left: -80px; width: 60px; height: 25px;"></div>
    <div class="cloud cloud-drift-1" style="top: 80%; left: -80px; width: 90px; height: 30px; animation-delay: -20s;"></div>
    <div class="cloud cloud-drift-2" style="top: 45%; left: -80px; width: 70px; height: 28px; animation-delay: -15s;"></div>
  </div>

  <!-- Skip to main content -->
  <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-game-coin-gold focus:text-game-sky-dark focus:rounded-lg">
    Skip to main content
  </a>

  <!-- Navigation -->
  <header>
    <nav id="navbar" aria-label="Main navigation" class="fixed top-0 left-0 right-0 z-40 transition-all duration-300">
      <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
        <a href="/" class="font-pixel text-sm text-game-cloud-white" aria-label="Floatify home">
          FLOATIFY
        </a>
        <a
          href="https://github.com/hieppp/floatify"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center gap-2 px-4 py-2 rounded-lg border-2 border-game-sky-blue text-game-sky-blue hover:bg-game-sky-blue hover:text-game-sky-dark transition-colors text-sm font-body"
        >
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/>
          </svg>
          Star
        </a>
      </div>
    </nav>
  </header>

  <!-- Main Content -->
  <main id="main-content" class="relative z-10">

  <!-- Section 1: Hero - Game Start Screen -->
  <section aria-labelledby="hero-heading" class="min-h-screen flex flex-col items-center justify-center px-6 pt-20">
    <div class="text-center max-w-3xl mx-auto mb-12">
      <h1 id="hero-heading" class="hero-title font-pixel text-game-cloud-white mb-6 leading-relaxed" style="font-size: clamp(1.8rem, 5vw, 3.2rem); text-shadow: 3px 3px 0 rgba(0,0,0,0.5);">
        FLOATIFY
      </h1>
      <p class="hero-subtitle font-body text-xl text-game-cloud-white mb-4">
        Session HUDs for Developers
      </p>
      <p class="hero-subtitle font-body text-base text-game-cloud-white/60">
        A macOS menu bar app for Claude Code and Codex. Each live session gets a persistent floater with project label, color status, sprite avatar, git file count, and activity time.
      </p>
    </div>

    <!-- Terminal / Message Block -->
    <div
      id="terminal"
      class="w-full max-w-2xl rounded-lg overflow-hidden cursor-pointer relative"
      style="background: #0f0f1a; border: 4px solid #C84C09;"
    >
      <div class="flex items-center gap-2 px-4 py-3" style="background: #161625; border-bottom: 2px solid #C84C09;">
        <div class="w-3 h-3 rounded-full bg-game-mario-red"></div>
        <div class="w-3 h-3 rounded-full bg-game-coin-gold"></div>
        <div class="w-3 h-3 rounded-full bg-game-pipe-green"></div>
        <span class="ml-4 text-sm font-mono text-game-cloud-white/40">zsh</span>
      </div>
      <div class="px-6 py-8 font-mono text-sm scanlines">
        <div class="flex items-center">
          <span class="text-game-coin-gold">$</span>
          <span id="typed-command" class="ml-2 text-game-cloud-white"></span>
          <span class="typing-cursor ml-1"></span>
        </div>
      </div>
    </div>

    <!-- CTA Buttons -->
    <div class="hero-buttons mt-10 flex items-center justify-center gap-4">
      <a
        href="#installation"
        class="btn-bounce px-8 py-3 rounded-lg bg-game-mario-red text-game-cloud-white font-pixel text-xs transition-colors hover:bg-red-700"
      >
        START
      </a>
      <a
        href="https://github.com/hieppp/floatify"
        target="_blank"
        rel="noopener noreferrer"
        class="px-6 py-3 rounded-lg border-2 border-game-sky-blue text-game-sky-blue font-body text-sm transition-colors hover:bg-game-sky-blue hover:text-game-sky-dark"
      >
        GitHub
      </a>
    </div>

    <!-- Decorative coin counter -->
    <div class="absolute top-24 right-8 flex items-center gap-2 font-pixel text-xs text-game-coin-gold" aria-hidden="true">
      <span class="coin-spin">&#9679;</span>
      <span>x 42</span>
    </div>
  </section>

  <!-- Remaining sections will be added in subsequent tasks -->

  </main>

</Layout>

<script>
  // --- Terminal typing animation ---
  const command = "git clone https://github.com/hieppp/floatify.git";
  const typedEl = document.getElementById("typed-command");
  let charIdx = 0;

  function typeChar() {
    if (!typedEl) return;
    if (charIdx < command.length) {
      typedEl.textContent += command[charIdx];
      charIdx++;
      setTimeout(typeChar, 40 + Math.random() * 60);
    }
  }
  setTimeout(typeChar, 500);

  // --- Coin pop on terminal click ---
  const terminal = document.getElementById("terminal");
  terminal?.addEventListener("click", () => {
    navigator.clipboard.writeText("git clone https://github.com/hieppp/floatify.git");
    for (let i = 0; i < 7; i++) {
      const p = document.createElement("div");
      p.className = "coin-particle";
      const angle = (Math.PI * 2 * i) / 7;
      const dist = 30 + Math.random() * 20;
      p.style.setProperty("--tx", `${Math.cos(angle) * dist}px`);
      p.style.setProperty("--ty", `${Math.sin(angle) * dist - 20}px`);
      p.style.left = "50%";
      p.style.top = "50%";
      terminal.appendChild(p);
      setTimeout(() => p.remove(), 800);
    }
  });

  // --- Navbar scroll background ---
  const navbar = document.getElementById("navbar");
  window.addEventListener("scroll", () => {
    if (!navbar) return;
    if (window.scrollY > 50) {
      navbar.style.background = "rgba(26, 26, 46, 0.95)";
      navbar.style.backdropFilter = "blur(10px)";
      navbar.style.borderBottom = "2px solid #C84C09";
    } else {
      navbar.style.background = "transparent";
      navbar.style.backdropFilter = "none";
      navbar.style.borderBottom = "none";
    }
  });
</script>
```

- [ ] Step 2: Verify hero renders in browser

Check: `http://localhost:4322/` - star field, clouds, bouncing title, typing terminal, START button, coin counter visible. Click terminal to see coin particles.

- [ ] Step 3: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add hero section with game start screen, star field, coin particles"
```

---

### Task 5: Index.astro - Demo Section (Section 2)

Files:
- Modify: `website/src/pages/index.astro`

- [ ] Step 1: Add demo section after the hero section closing tag

Insert before the `<!-- Remaining sections will be added in subsequent tasks -->` comment:

```html
  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 2: Demo - World 1-1 -->
  <section aria-labelledby="demo-heading" class="py-20 px-6">
    <div class="max-w-4xl mx-auto">
      <h2 id="demo-heading" class="font-pixel text-sm text-game-coin-gold text-center mb-10 tracking-wider">
        WORLD 1-1
      </h2>
      <div class="relative pixel-border rounded-lg overflow-hidden">
        <!-- Video overlay -->
        <div id="video-overlay" class="absolute inset-0 z-10 flex items-center justify-center bg-black/50 cursor-pointer transition-opacity duration-300">
          <div class="flex flex-col items-center gap-3">
            <div class="w-16 h-16 rounded-full border-4 border-game-mario-red flex items-center justify-center">
              <svg class="w-6 h-6 text-game-mario-red ml-1" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z"/>
              </svg>
            </div>
            <span class="font-pixel text-xs text-game-mario-red">PRESS PLAY</span>
          </div>
        </div>
        <video
          id="demo-video"
          src="/demo.mp4"
          class="w-full block"
          muted
          loop
          playsinline
          preload="metadata"
          aria-label="Floatify demo video showing session floaters in action"
        >
          Your browser does not support the demo video.
        </video>
      </div>
    </div>
  </section>
```

- [ ] Step 2: Add the video overlay JS to the existing script block

Append inside the `<script>` tag:

```js
  // --- Video overlay play ---
  const overlay = document.getElementById("video-overlay");
  const video = document.getElementById("demo-video") as HTMLVideoElement | null;
  overlay?.addEventListener("click", () => {
    video?.play();
    overlay.style.opacity = "0";
    overlay.style.pointerEvents = "none";
  });
```

- [ ] Step 3: Verify demo section renders

Check: `http://localhost:4322/` - scroll down, see "WORLD 1-1" header, pixel-bordered video with "PRESS PLAY" overlay. Click overlay to play video.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add demo section with pixel frame and play overlay"
```

---

### Task 6: Index.astro - Features Section (Section 3)

Files:
- Modify: `website/src/pages/index.astro`

- [ ] Step 1: Add features section after the demo section

Insert after the demo section closing `</section>`:

```html
  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 3: Features - Power-Ups -->
  <section aria-labelledby="features-heading" class="py-20 px-6 max-w-6xl mx-auto">
    <h2 id="features-heading" class="font-pixel text-sm text-game-coin-gold text-center mb-12 tracking-wider">
      POWER-UPS
    </h2>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

      <!-- Feature 1: Per-Session Floaters -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Per-Session Floaters</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Each Claude Code or Codex session gets its own floater instead of one global status box.</p>
      </div>

      <!-- Feature 2: Zero Focus Stealing -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Zero Focus Stealing</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Non-activating NSPanel windows stay above apps without interrupting typing or mouse focus.</p>
      </div>

      <!-- Feature 3: Project-Aware Labels -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Project-Aware Labels</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Each floater shows the current folder name, so multiple sessions stay easy to scan.</p>
      </div>

      <!-- Feature 4: Drag, Close, Arrange -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Drag, Close, Arrange</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Move floaters anywhere, close the ones you do not need, restack them from the menu bar, or click a floater to open its project in VS Code.</p>
      </div>

      <!-- Feature 5: Color-First Status -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Color-First Status</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Red means running. Green means complete. Status stays readable without extra words.</p>
      </div>

      <!-- Feature 6: Claude and Codex -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Claude and Codex</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Both tools get live session discovery. Codex can infer task state from session logs. Claude still works best with hooks.</p>
      </div>

      <!-- Feature 7: Render Modes -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
          <path stroke-linecap="square" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">Render Modes</h3>
        <p class="text-sm font-body text-game-cloud-white/70">Super Slay turns effects up, Slay keeps the standard animated look, and Lame strips heavy repeat effects for the lowest CPU.</p>
      </div>

      <!-- Feature 8: File Changes & Activity -->
      <div class="q-block bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-6 observe-hidden" data-observe>
        <svg class="w-8 h-8 text-game-coin-gold mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style="image-rendering: pixelated;">
          <path stroke-linecap="square" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
        <h3 class="font-pixel text-xs text-game-cloud-white mb-3 leading-relaxed">File Changes & Activity</h3>
        <p class="text-sm font-body text-game-cloud-white/70">See git modified files count and time since last activity. Stay informed about what is happening in each session at a glance.</p>
      </div>

    </div>
  </section>
```

- [ ] Step 2: Add Intersection Observer JS for block-hit animations

Append to the `<script>` tag:

```js
  // --- Intersection Observer for scroll animations ---
  const observeEls = document.querySelectorAll("[data-observe]");
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        const el = entry.target as HTMLElement;
        const siblings = Array.from(el.parentElement?.querySelectorAll("[data-observe]") || []);
        const idx = siblings.indexOf(el);
        setTimeout(() => {
          el.classList.remove("observe-hidden");
          el.classList.add("observe-visible", "block-hit");
          el.addEventListener("animationend", () => el.classList.remove("block-hit"), { once: true });
        }, idx * 100);
        observer.unobserve(el);
      }
    });
  }, { threshold: 0.2 });

  observeEls.forEach((el) => observer.observe(el));
```

- [ ] Step 3: Verify features render with scroll animation

Check: `http://localhost:4322/` - scroll to features, see "POWER-UPS" header, question-mark block cards bounce in with stagger.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add power-ups features section with block-hit scroll animations"
```

---

### Task 7: Index.astro - Interactive Floater Playground (Section 4)

Files:
- Modify: `website/src/pages/index.astro`

- [ ] Step 1: Add the playground section after features

Insert after the features section closing `</section>`:

```html
  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 4: Interactive Floater Playground - Mini-Game -->
  <section aria-labelledby="playground-heading" class="py-20 px-6">
    <div class="max-w-lg mx-auto">
      <h2 id="playground-heading" class="font-pixel text-sm text-game-coin-gold text-center mb-10 tracking-wider">
        MINI-GAME
      </h2>

      <!-- Pixel border frame -->
      <div class="pixel-border-double rounded-lg p-1">
        <div class="bg-game-sky-dark rounded-lg overflow-hidden">
          <!-- Header bar -->
          <div class="px-4 py-2 border-b-2 border-game-brick-brown bg-game-brick-brown/20">
            <span class="font-pixel text-[10px] text-game-coin-gold">FLOATER DEMO</span>
          </div>

          <!-- Floater mockup -->
          <div class="p-6">
            <div
              id="floater-mockup"
              class="relative mx-auto rounded-xl p-4 transition-all duration-300 glow-red-pulse"
              style="background: rgba(30, 30, 50, 0.9); max-width: 280px; border: 1px solid rgba(255,255,255,0.1);"
            >
              <div class="flex items-center gap-3">
                <!-- Status dot -->
                <div id="status-dot" class="w-3 h-3 rounded-full bg-game-mario-red transition-colors duration-300"></div>
                <!-- Project label -->
                <span class="font-mono text-sm text-game-cloud-white">floatify</span>
                <!-- Sprite character -->
                <div class="ml-auto pixel-sprite" style="width: 16px; height: 16px; background: #F5C518; border-radius: 2px;" aria-hidden="true"></div>
              </div>
              <div class="flex items-center gap-4 mt-2 text-xs font-mono text-game-cloud-white/50">
                <span>3 files</span>
                <span>Just now</span>
              </div>
            </div>
          </div>

          <!-- Control buttons -->
          <div class="flex items-center justify-center gap-4 p-4 border-t-2 border-game-brick-brown/30">
            <button
              data-status="running"
              class="status-btn px-4 py-2 rounded-full bg-game-mario-red text-white font-pixel text-[10px] active:scale-95 transition-transform border-2 border-red-800"
            >
              Running
            </button>
            <button
              data-status="idle"
              class="status-btn px-4 py-2 rounded-full bg-game-coin-gold text-game-sky-dark font-pixel text-[10px] active:scale-95 transition-transform border-2 border-yellow-700"
            >
              Idle
            </button>
            <button
              data-status="complete"
              class="status-btn px-4 py-2 rounded-full bg-game-pipe-green text-white font-pixel text-[10px] active:scale-95 transition-transform border-2 border-green-800"
            >
              Complete
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>
```

- [ ] Step 2: Add playground JS to the script block

Append to the `<script>` tag:

```js
  // --- Floater Playground ---
  const mockup = document.getElementById("floater-mockup");
  const dot = document.getElementById("status-dot");
  const statusBtns = document.querySelectorAll(".status-btn");

  statusBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const status = (btn as HTMLElement).dataset.status;
      if (!mockup || !dot) return;

      // Remove all glow classes
      mockup.classList.remove("glow-red", "glow-yellow", "glow-green", "glow-red-pulse");

      if (status === "running") {
        dot.style.background = "#E52521";
        mockup.classList.add("glow-red-pulse");
      } else if (status === "idle") {
        dot.style.background = "#F5C518";
        mockup.classList.add("glow-yellow");
      } else if (status === "complete") {
        dot.style.background = "#049C2F";
        mockup.classList.add("glow-green");
        // Confetti burst
        for (let i = 0; i < 18; i++) {
          const c = document.createElement("div");
          c.className = "confetti-piece";
          const colors = ["#E52521", "#F5C518", "#049C2F", "#6185F8", "#F0F0F0"];
          c.style.background = colors[Math.floor(Math.random() * colors.length)];
          const angle = (Math.PI * 2 * i) / 18;
          const dist = 40 + Math.random() * 60;
          c.style.setProperty("--cx", `${Math.cos(angle) * dist}px`);
          c.style.setProperty("--cy", `${Math.sin(angle) * dist - 30}px`);
          c.style.setProperty("--cr", `${Math.random() * 720 - 360}deg`);
          c.style.left = "50%";
          c.style.top = "50%";
          mockup.appendChild(c);
          setTimeout(() => c.remove(), 1000);
        }
      }
    });
  });
```

- [ ] Step 3: Verify playground works

Check: `http://localhost:4322/` - scroll to MINI-GAME, see floater mockup with red pulsing glow. Click "Idle" for yellow glow, "Complete" for green glow + confetti burst.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add interactive floater playground with status toggling and confetti"
```

---

### Task 8: Index.astro - Warp Pipe Flow (Section 5)

Files:
- Modify: `website/src/pages/index.astro`

- [ ] Step 1: Add the warp pipe section after the playground

Insert after the playground section closing `</section>`:

```html
  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 5: How It Works - Warp Zone -->
  <section aria-labelledby="warp-heading" class="py-20 px-6 max-w-4xl mx-auto">
    <h2 id="warp-heading" class="font-pixel text-sm text-game-pipe-green text-center mb-12 tracking-wider">
      WARP ZONE
    </h2>

    <div id="warp-flow" class="relative flex flex-col md:flex-row items-center justify-between gap-8 md:gap-4">
      <!-- Step 1 -->
      <div class="flex-1 flex flex-col items-center text-center">
        <div class="warp-pipe mb-4" aria-hidden="true"></div>
        <h3 class="font-pixel text-[10px] text-game-cloud-white mb-2 leading-relaxed">Hook Trigger</h3>
        <p class="text-sm font-body text-game-cloud-white/60">Live process scan discovers sessions</p>
      </div>

      <!-- Arrow -->
      <div class="hidden md:block text-game-coin-gold font-pixel text-lg" aria-hidden="true">&#9654;</div>

      <!-- Step 2 -->
      <div class="flex-1 flex flex-col items-center text-center">
        <div class="warp-pipe mb-4" aria-hidden="true"></div>
        <h3 class="font-pixel text-[10px] text-game-cloud-white mb-2 leading-relaxed">CLI Command</h3>
        <p class="text-sm font-body text-game-cloud-white/60">CLI sends status via FIFO pipe</p>
      </div>

      <!-- Arrow -->
      <div class="hidden md:block text-game-coin-gold font-pixel text-lg" aria-hidden="true">&#9654;</div>

      <!-- Step 3 -->
      <div class="flex-1 flex flex-col items-center text-center">
        <div class="warp-pipe mb-4" aria-hidden="true"></div>
        <h3 class="font-pixel text-[10px] text-game-cloud-white mb-2 leading-relaxed">Floater Appears</h3>
        <p class="text-sm font-body text-game-cloud-white/60">Persistent floater appears per session</p>
      </div>

      <!-- Data packet (animated) -->
      <div id="data-packet" class="data-packet hidden md:block" aria-hidden="true"></div>
    </div>
  </section>
```

- [ ] Step 2: Add warp zone scroll-triggered animation JS

Append to the `<script>` tag:

```js
  // --- Warp zone data packet animation ---
  const warpFlow = document.getElementById("warp-flow");
  const packet = document.getElementById("data-packet");
  if (warpFlow && packet) {
    const warpObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          packet.classList.add("animate");
          warpObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.3 });
    warpObserver.observe(warpFlow);
  }
```

- [ ] Step 3: Verify warp zone renders

Check: `http://localhost:4322/` - scroll to WARP ZONE, see three green pipes with labels and arrows. Data packet animates across on scroll.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add warp pipe flow section with data packet animation"
```

---

### Task 9: Index.astro - Installation, Game Options, Footer (Sections 6-7 + Footer)

Files:
- Modify: `website/src/pages/index.astro`

- [ ] Step 1: Add installation, game options, and footer sections

Insert after the warp zone section closing `</section>`, replacing the `<!-- Remaining sections will be added in subsequent tasks -->` comment:

```html
  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 6: Installation - Start Game -->
  <section id="installation" aria-labelledby="install-heading" class="py-20 px-6 max-w-4xl mx-auto">
    <h2 id="install-heading" class="font-pixel text-sm text-game-mario-red text-center mb-10 tracking-wider">
      START GAME
    </h2>

    <div class="pixel-border rounded-lg overflow-hidden" style="background: #0f0f1a;">
      <ol class="divide-y divide-game-brick-brown/30">

        <!-- Step 1: Clone -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">1</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">Clone the repository</p>
            <div class="relative scanlines rounded" style="background: #161625;">
              <pre class="p-3 font-mono text-sm text-game-cloud-white overflow-x-auto"><code><span class="text-game-coin-gold">$</span> git clone https://github.com/hieppp/floatify.git</code></pre>
              <button onclick="copyAndCoin(this, 'git clone https://github.com/hieppp/floatify.git')" class="absolute top-2 right-2 px-2 py-1 font-pixel text-[8px] text-game-coin-gold border border-game-coin-gold rounded hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors">INSERT COIN</button>
            </div>
          </div>
        </li>

        <!-- Step 2: Build -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">2</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">Build and install</p>
            <div class="relative scanlines rounded" style="background: #161625;">
              <pre class="p-3 font-mono text-sm text-game-cloud-white overflow-x-auto"><code><span class="text-game-coin-gold">$</span> cd floatify && ./build.sh</code></pre>
              <button onclick="copyAndCoin(this, 'cd floatify && ./build.sh')" class="absolute top-2 right-2 px-2 py-1 font-pixel text-[8px] text-game-coin-gold border border-game-coin-gold rounded hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors">INSERT COIN</button>
            </div>
          </div>
        </li>

        <!-- Step 3: What it does -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">3</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">What build.sh does</p>
            <p class="text-sm font-body text-game-cloud-white/60">Builds the app and CLI, installs Floatify.app to /Applications, updates /usr/local/bin/floatify, and relaunches the app.</p>
          </div>
        </li>

        <!-- Step 4: Claude hooks -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">4</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">Claude Code hooks <span class="text-xs text-game-cloud-white/40 font-mono">~/.claude/settings.json</span></p>
            <div class="relative scanlines rounded" style="background: #161625;">
              <pre class="p-3 font-mono text-xs text-game-cloud-white overflow-x-auto"><code>{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "floatify --status complete"
      }]
    }],
    "SessionEnd": [{
      "hooks": [{
        "type": "command",
        "command": "floatify --status complete"
      }]
    }]
  }
}</code></pre>
              <button onclick="copyAndCoin(this, `{&quot;hooks&quot;:{&quot;Stop&quot;:[{&quot;hooks&quot;:[{&quot;type&quot;:&quot;command&quot;,&quot;command&quot;:&quot;floatify --status complete&quot;}]}],&quot;SessionEnd&quot;:[{&quot;hooks&quot;:[{&quot;type&quot;:&quot;command&quot;,&quot;command&quot;:&quot;floatify --status complete&quot;}]}]}}`)" class="absolute top-2 right-2 px-2 py-1 font-pixel text-[8px] text-game-coin-gold border border-game-coin-gold rounded hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors">INSERT COIN</button>
            </div>
          </div>
        </li>

        <!-- Step 5: Codex hooks -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">5</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">Codex hooks <span class="text-xs text-game-cloud-white/40 font-mono">~/.codex/hooks.json</span></p>
            <div class="relative scanlines rounded" style="background: #161625;">
              <pre class="p-3 font-mono text-xs text-game-cloud-white overflow-x-auto"><code>{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "floatify --status running"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "floatify --status complete"
      }]
    }]
  }
}</code></pre>
              <button onclick="copyAndCoin(this, `{&quot;hooks&quot;:{&quot;UserPromptSubmit&quot;:[{&quot;hooks&quot;:[{&quot;type&quot;:&quot;command&quot;,&quot;command&quot;:&quot;floatify --status running&quot;}]}],&quot;Stop&quot;:[{&quot;hooks&quot;:[{&quot;type&quot;:&quot;command&quot;,&quot;command&quot;:&quot;floatify --status complete&quot;}]}]}}`)" class="absolute top-2 right-2 px-2 py-1 font-pixel text-[8px] text-game-coin-gold border border-game-coin-gold rounded hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors">INSERT COIN</button>
            </div>
          </div>
        </li>

        <!-- Step 6: Test -->
        <li class="flex items-start gap-4 p-5">
          <span class="flex-shrink-0 w-8 h-8 bg-game-coin-gold text-game-sky-dark rounded-full flex items-center justify-center font-pixel text-xs">6</span>
          <div class="flex-1 min-w-0">
            <p class="font-body text-game-cloud-white mb-2">Test it</p>
            <div class="relative scanlines rounded" style="background: #161625;">
              <pre class="p-3 font-mono text-sm text-game-cloud-white overflow-x-auto"><code><span class="text-game-coin-gold">$</span> floatify --status running
<span class="text-game-coin-gold">$</span> floatify --status complete</code></pre>
              <button onclick="copyAndCoin(this, 'floatify --status running')" class="absolute top-2 right-2 px-2 py-1 font-pixel text-[8px] text-game-coin-gold border border-game-coin-gold rounded hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors">INSERT COIN</button>
            </div>
          </div>
        </li>

      </ol>
    </div>

    <!-- Continue button -->
    <div class="mt-10 text-center">
      <a
        href="https://github.com/hieppp/floatify"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-2 px-6 py-3 border-2 border-game-coin-gold text-game-coin-gold font-pixel text-xs rounded-lg hover:bg-game-coin-gold hover:text-game-sky-dark transition-colors"
      >
        CONTINUE?
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/>
        </svg>
      </a>
    </div>
  </section>

  <!-- Ground divider -->
  <div class="ground-divider" aria-hidden="true"></div>

  <!-- Section 7: Game Options (compact) -->
  <section aria-labelledby="options-heading" class="py-12 px-6 max-w-4xl mx-auto">
    <h2 id="options-heading" class="font-pixel text-[10px] text-game-coin-gold text-center mb-8 tracking-wider">
      GAME OPTIONS
    </h2>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-4">
        <p class="font-pixel text-[8px] text-game-coin-gold mb-1">Render</p>
        <p class="text-xs font-body text-game-cloud-white/70">Super Slay, Slay, or Lame</p>
      </div>
      <div class="bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-4">
        <p class="font-pixel text-[8px] text-game-coin-gold mb-1">Theme</p>
        <p class="text-xs font-body text-game-cloud-white/70">Dark or light palette</p>
      </div>
      <div class="bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-4">
        <p class="font-pixel text-[8px] text-game-coin-gold mb-1">Display</p>
        <p class="text-xs font-body text-game-cloud-white/70">Compact, regular, or large</p>
      </div>
      <div class="bg-game-block-tan/10 border-2 border-game-brick-brown rounded-lg p-4">
        <p class="font-pixel text-[8px] text-game-coin-gold mb-1">Timeout</p>
        <p class="text-xs font-body text-game-cloud-white/70">Seconds before idle and complete</p>
      </div>
    </div>
    <p class="mt-4 text-xs font-body text-game-cloud-white/40 text-center">Codex infers task state from logs. Claude needs hooks for precise status.</p>
  </section>

  </main>

  <!-- Footer -->
  <footer class="ground-divider-thick py-8 px-6" style="background: linear-gradient(180deg, #3d2510 0%, #1a1a2e 100%);">
    <div class="max-w-6xl mx-auto">
      <div class="flex flex-col md:flex-row items-center justify-between gap-4">
        <p class="font-pixel text-[8px] text-game-cloud-white/40">2026 FLOATIFY</p>
        <span class="px-3 py-1 rounded border border-game-coin-gold/30 font-pixel text-[8px] text-game-coin-gold/60">
          MIT LICENSE
        </span>
        <a href="https://github.com/hieppp/floatify" target="_blank" rel="noopener noreferrer" class="font-pixel text-[8px] text-game-cloud-white/40 hover:text-game-cloud-white transition-colors">
          GITHUB &#9654;
        </a>
      </div>
    </div>
  </footer>
```

- [ ] Step 2: Add the copyAndCoin function to the script block

Add this function near the top of the `<script>` tag (before the other JS):

```js
  // --- Copy with coin pop ---
  function copyAndCoin(btn: HTMLButtonElement, text: string) {
    navigator.clipboard.writeText(text);
    const rect = btn.getBoundingClientRect();
    for (let i = 0; i < 5; i++) {
      const p = document.createElement("div");
      p.className = "coin-particle";
      p.style.position = "fixed";
      const angle = (Math.PI * 2 * i) / 5 - Math.PI / 2;
      const dist = 20 + Math.random() * 15;
      p.style.setProperty("--tx", `${Math.cos(angle) * dist}px`);
      p.style.setProperty("--ty", `${Math.sin(angle) * dist}px`);
      p.style.left = `${rect.left + rect.width / 2}px`;
      p.style.top = `${rect.top + rect.height / 2}px`;
      document.body.appendChild(p);
      setTimeout(() => p.remove(), 800);
    }
    const orig = btn.textContent;
    btn.textContent = "GOT IT!";
    setTimeout(() => { btn.textContent = orig; }, 1500);
  }

  // Make copyAndCoin available globally for onclick handlers
  (window as any).copyAndCoin = copyAndCoin;
```

- [ ] Step 3: Verify installation, game options, and footer render

Check: `http://localhost:4322/` - scroll to START GAME, see numbered steps with scanline code blocks, INSERT COIN buttons produce coin pops. GAME OPTIONS shows 4 compact cards. Footer has pixel font text.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add installation, game options, and footer sections"
```

---

### Task 10: Index.astro - Scroll-Following Character

Files:
- Modify: `website/src/pages/index.astro`
- Modify: `website/src/styles/global.css`

- [ ] Step 1: Add the scroll character element to index.astro

Insert right after the opening `<main>` tag:

```html
    <!-- Scroll-following character -->
    <div id="scroll-char" class="scroll-character hidden md:block" aria-hidden="true"
      style="bottom: 20px; background: #F5C518; border-radius: 2px; box-shadow: 2px 0 0 #C84C09, -2px 0 0 #C84C09, 0 2px 0 #C84C09, 0 -2px 0 #C84C09, 0 -4px 0 #E52521, 2px -4px 0 #E52521, -2px -4px 0 #E52521, 0 -6px 0 #E52521;"
    ></div>
```

- [ ] Step 2: Add scroll character JS to the script block

Append to the `<script>` tag:

```js
  // --- Scroll-following character ---
  const scrollChar = document.getElementById("scroll-char");
  let scrollTimeout: ReturnType<typeof setTimeout>;

  window.addEventListener("scroll", () => {
    if (!scrollChar) return;
    const scrollPct = window.scrollY / (document.documentElement.scrollHeight - window.innerHeight);
    const viewH = window.innerHeight;
    const charBottom = 20 + scrollPct * (viewH - 60);
    scrollChar.style.bottom = `${charBottom}px`;
    scrollChar.classList.add("walking");
    clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(() => {
      scrollChar.classList.remove("walking");
    }, 150);
  });
```

- [ ] Step 3: Verify scroll character moves with scroll

Check: `http://localhost:4322/` on a wide viewport (> 768px). Small gold pixel character on the left edge moves up as you scroll. Walking animation plays during scroll, stops when idle. Hidden on mobile.

- [ ] Step 4: Commit

```bash
git add website/src/pages/index.astro website/src/styles/global.css
git commit -m "feat(website): add scroll-following pixel character"
```

---

### Task 11: Final Polish and Verification

Files:
- Modify: `website/src/pages/index.astro` (if needed)
- Modify: `website/src/styles/global.css` (if needed)

- [ ] Step 1: Remove the placeholder comment from index.astro

Search for and remove `<!-- Remaining sections will be added in subsequent tasks -->` if it still exists.

- [ ] Step 2: Full page walkthrough in browser

Open `http://localhost:4322/` and verify each section:
1. Hero: title bounces in, clouds drift, stars visible, typing animation, coin counter, START button bounces, terminal coin-pop on click
2. Demo: pixel border, PRESS PLAY overlay, video plays on click
3. Features: POWER-UPS header, 8 question-mark block cards, block-hit animation on scroll
4. Playground: MINI-GAME, floater mockup, three status buttons work, confetti on complete
5. Warp Zone: three green pipes, data packet animates on scroll
6. Installation: START GAME, 6 numbered steps, INSERT COIN copy buttons with coin pop
7. Game Options: 4 compact cards
8. Footer: pixel font, MIT badge, GitHub link
9. Scroll character: moves with scroll on desktop, hidden on mobile
10. Navbar: transparent at top, solid with blur on scroll

- [ ] Step 3: Check mobile responsiveness

Resize browser to 375px width:
- Hero stacks vertically
- Features grid collapses to 1 column
- Warp pipes stack vertically
- Installation steps remain readable
- Game options grid is 2x2
- Scroll character is hidden
- No horizontal overflow

- [ ] Step 4: Fix any issues found

Address any visual or functional issues discovered in steps 2-3.

- [ ] Step 5: Build production check

Run: `cd /Users/hiep/Projects/floatify/website && npm run build`
Expected: No errors. Static output generated in `dist/`.

- [ ] Step 6: Commit

```bash
git add website/
git commit -m "feat(website): complete nintendo game world redesign - final polish"
```
