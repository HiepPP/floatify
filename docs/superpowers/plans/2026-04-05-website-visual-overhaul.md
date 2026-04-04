# Website Visual Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the Floatify landing page from Catppuccin terminal aesthetic to premium neutral dark (Linear-inspired) while adding two new sections.

**Architecture:** In-place refactor of the single `index.astro` file with updated Tailwind color tokens. Two new sections (animated demo + screenshot) are inserted after hero. No structural decomposition - all changes happen in 5 files.

**Tech Stack:** Astro 4, Tailwind CSS 3, vanilla JS/CSS animations

---

### Task 1: Update Tailwind Color Tokens

**Files:**
- Modify: `website/tailwind.config.mjs`

- [ ] **Step 1: Replace terminal color tokens**

Replace the `colors.terminal` block in `tailwind.config.mjs` with neutral tokens:

```js
colors: {
  terminal: {
    bg: '#0a0a0a',
    card: '#111',
    surface: '#1a1a1a',
    border: '#1a1a1a',
    'border-hover': '#262626',
    text: '#e5e5e5',
    'text-secondary': '#737373',
    'text-tertiary': '#525252',
    'text-muted': '#404040',
    'text-faint': '#333',
    dot: '#404040',
  },
},
```

- [ ] **Step 2: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 3: Commit**

```bash
git add website/tailwind.config.mjs
git commit -m "refactor(website): replace Catppuccin tokens with neutral dark palette"
```

---

### Task 2: Update Layout and Global Styles

**Files:**
- Modify: `website/src/layouts/Layout.astro`
- Modify: `website/src/styles/global.css`

- [ ] **Step 1: Update Layout.astro body class**

Change the body class from:
```
class="bg-terminal-bg text-terminal-text font-mono antialiased"
```
to:
```
class="bg-terminal-bg text-terminal-text font-mono antialiased selection:bg-white/10"
```

The `selection:bg-white/10` adds a subtle white highlight on text selection for premium feel.

- [ ] **Step 2: Update global.css**

Replace the entire `global.css` with:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

html {
  scroll-behavior: smooth;
}

body {
  @apply bg-terminal-bg text-terminal-text font-mono antialiased;
}
```

This removes the unused `terminal-dot-red`, `terminal-dot-yellow`, `terminal-dot-green` classes that were Catppuccin-specific.

- [ ] **Step 3: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 4: Commit**

```bash
git add website/src/layouts/Layout.astro website/src/styles/global.css
git commit -m "refactor(website): update layout and global styles for neutral dark theme"
```

---

### Task 3: Overhaul Navigation and Hero

**Files:**
- Modify: `website/src/pages/index.astro:7-62`

- [ ] **Step 1: Replace the Navigation section (lines 7-22)**

Replace the entire `<nav>` block with:

```astro
  <!-- Navigation -->
  <nav id="navbar" class="fixed top-0 left-0 right-0 z-50 transition-all duration-300">
    <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
      <div class="text-xl font-bold text-terminal-text">Floatify</div>
      <a
        href="https://github.com/hieppp/floatify"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-2 px-4 py-2 rounded-lg bg-terminal-surface border border-terminal-border hover:bg-terminal-border-hover transition-colors"
      >
        <svg class="w-5 h-5 text-terminal-text" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/>
        </svg>
        <span class="text-sm text-terminal-text">Star</span>
      </a>
    </div>
  </nav>
```

Key changes:
- Logo: `text-white` -> `text-terminal-text`
- GitHub button: hard-coded Catppuccin bg/border -> Tailwind token classes
- SVG: added `text-terminal-text` for neutral fill

- [ ] **Step 2: Replace the Hero section (lines 24-62)**

Replace the entire Hero section (from `<!-- Hero Section -->` through the closing `</section>` tag on line 62) with:

```astro
  <!-- Hero Section -->
  <section class="min-h-screen flex flex-col items-center justify-center px-6 pt-20">
    <div class="text-center max-w-3xl mx-auto mb-12">
      <h1 class="text-5xl md:text-6xl font-bold text-terminal-text mb-6 leading-tight">
        Floating Notifications<br/>for Developers
      </h1>
      <p class="text-xl text-terminal-text-secondary mb-8">
        Sub-millisecond notifications that never steal your focus
      </p>
    </div>

    <!-- Terminal Window -->
    <div
      id="terminal"
      class="w-full max-w-2xl rounded-xl overflow-hidden cursor-pointer transition-all duration-200 hover:border-terminal-border-hover"
      style="background: #1a1a1a; border: 1px solid #1a1a1a;"
    >
      <!-- Terminal Header -->
      <div class="flex items-center gap-2 px-4 py-3" style="background: #0a0a0a;">
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <span class="ml-4 text-sm text-terminal-text-muted">zsh</span>
      </div>
      <!-- Terminal Body -->
      <div class="px-6 py-8 font-mono text-sm">
        <div class="flex items-center">
          <span class="text-terminal-text">$</span>
          <span id="typed-command" class="ml-2 text-terminal-text"></span>
          <span id="cursor" class="ml-1 w-2.5 h-5 bg-terminal-text" style="display: inline-block;"></span>
        </div>
        <div id="copied-feedback" class="mt-4 text-terminal-text-secondary text-sm opacity-0 transition-opacity duration-300">
          Copied!
        </div>
      </div>
    </div>

    <!-- CTA Buttons -->
    <div class="mt-10 flex items-center justify-center gap-4">
      <a
        href="#installation"
        class="px-6 py-3 rounded-lg bg-white text-black font-mono text-sm font-medium transition-colors hover:bg-neutral-200"
      >
        Get Started
      </a>
      <a
        href="https://github.com/hieppp/floatify"
        target="_blank"
        rel="noopener noreferrer"
        class="px-6 py-3 rounded-lg border border-terminal-border text-terminal-text-secondary font-mono text-sm transition-colors hover:border-terminal-border-hover hover:text-terminal-text"
      >
        View on GitHub
      </a>
    </div>
  </section>
```

Key changes:
- Headline: `text-white` -> `text-terminal-text`
- Tagline: `text-gray-400` -> `text-terminal-text-secondary`
- Terminal: Catppuccin inline styles -> neutral token classes + inline styles
- Dots: Catppuccin hex -> `bg-terminal-dot`
- Prompt: `text-[#a6e3a1]` -> `text-terminal-text`
- Cursor: `bg-white animate-pulse` -> `bg-terminal-text` (blink animation kept in `<style>` block)
- "Copied!": `text-[#a6e3a1]` -> `text-terminal-text-secondary`
- Hover: removed `shadow-purple-500/20`, replaced with `hover:border-terminal-border-hover`
- Removed "Click terminal to copy command" helper text
- Added two CTA buttons below terminal

- [ ] **Step 3: Update navbar scroll JS**

In the `<script>` block at the bottom of the file, find the navbar scroll handler and replace the scrolled-state values:

Replace:
```js
navbar.style.background = "rgba(17, 17, 27, 0.95)";
```
with:
```js
navbar.style.background = "rgba(10, 10, 10, 0.95)";
navbar.style.borderBottom = "1px solid #1a1a1a";
```

And in the else branch, add:
```js
navbar.style.borderBottom = "none";
```

- [ ] **Step 4: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 5: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "refactor(website): overhaul nav and hero to neutral dark palette"
```

---

### Task 4: Add Animated Demo Section

**Files:**
- Modify: `website/src/pages/index.astro` (insert after Hero, before Features)

- [ ] **Step 1: Insert the animated demo section**

Insert the following block immediately after the Hero `</section>` (after the CTA buttons section) and before the Features `<!-- Features Section -->` comment:

```astro
  <!-- Animated Demo Section -->
  <section class="py-16 px-6">
    <div class="max-w-2xl mx-auto">
      <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase text-center mb-10">See It In Action</p>
      <div class="relative rounded-xl overflow-hidden border border-terminal-border" style="background: #111;">
        <!-- macOS top bar -->
        <div class="flex items-center gap-2 px-4 py-3 border-b border-terminal-border" style="background: #0a0a0a;">
          <div class="w-2.5 h-2.5 rounded-full bg-terminal-dot"></div>
          <div class="w-2.5 h-2.5 rounded-full bg-terminal-dot"></div>
          <div class="w-2.5 h-2.5 rounded-full bg-terminal-dot"></div>
          <div class="flex-1 text-center">
            <span class="text-[10px] text-terminal-text-muted font-mono">Finder</span>
          </div>
        </div>
        <!-- Desktop area -->
        <div class="relative" style="height: 220px; background: #0a0a0a;">
          <!-- Fake desktop content -->
          <div class="absolute top-4 left-4 w-12 h-12 rounded-lg bg-terminal-surface border border-terminal-border"></div>
          <div class="absolute top-4 left-20 w-12 h-12 rounded-lg bg-terminal-surface border border-terminal-border"></div>
          <!-- Notification panel (animated) -->
          <div id="demo-notification" class="absolute bottom-4 right-4 rounded-lg border border-terminal-border p-3 flex items-center gap-3 opacity-0 translate-y-2" style="background: #1a1a1a; width: 200px; transition: opacity 0.4s ease, transform 0.4s ease;">
            <div class="w-8 h-8 rounded bg-terminal-surface flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-terminal-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
              </svg>
            </div>
            <div class="min-w-0">
              <p class="text-xs text-terminal-text font-mono truncate">Build complete</p>
              <p class="text-[10px] text-terminal-text-muted font-mono truncate">bottomRight</p>
            </div>
          </div>
          <!-- Dock -->
          <div class="absolute bottom-0 left-1/2 -translate-x-1/2 flex gap-1.5 pb-2 px-3 py-1 rounded-lg" style="background: rgba(255,255,255,0.05);">
            <div class="w-4 h-4 rounded bg-terminal-surface border border-terminal-border"></div>
            <div class="w-4 h-4 rounded bg-terminal-surface border border-terminal-border"></div>
            <div class="w-4 h-4 rounded bg-terminal-surface border border-terminal-border"></div>
          </div>
        </div>
      </div>
    </div>
  </section>
```

- [ ] **Step 2: Add IntersectionObserver script for demo animation**

Add this script block right after the demo section HTML (or append to the existing `<script>` block at the bottom of the file):

```js
    // Demo notification animation
    const demoNotification = document.getElementById("demo-notification");
    if (demoNotification) {
      let demoObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            function showNotification() {
              demoNotification.style.opacity = "1";
              demoNotification.style.transform = "translateY(0)";
              setTimeout(() => {
                demoNotification.style.opacity = "0";
                demoNotification.style.transform = "translateY(8px)";
              }, 2500);
            }
            showNotification();
            const interval = setInterval(() => {
              if (!demoNotification) {
                clearInterval(interval);
                return;
              }
              showNotification();
            }, 5500);
            demoObserver.unobserve(entry.target);
          }
        });
      }, { threshold: 0.5 });
      demoObserver.observe(demoNotification.closest("section"));
    }
```

- [ ] **Step 3: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 4: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "feat(website): add animated notification demo section"
```

---

### Task 5: Add Screenshot Placeholder Section

**Files:**
- Modify: `website/src/pages/index.astro` (insert after demo, before Features)

- [ ] **Step 1: Create placeholder screenshot**

Create an empty placeholder image in `website/public/`:

Run: `cd website && touch public/floatify-screenshot.png`

This creates a 0-byte placeholder. Replace it later with a real macOS screenshot.

- [ ] **Step 2: Insert the screenshot section**

Insert the following block immediately after the demo `</section>` and before the Features `<!-- Features Section -->` comment:

```astro
  <!-- Screenshot Section -->
  <section class="py-16 px-6">
    <div class="max-w-4xl mx-auto">
      <img
        src="/floatify-screenshot.png"
        alt="Floatify showing a notification in the bottom-right corner of a macOS desktop"
        class="w-full rounded-xl border border-terminal-border"
        loading="lazy"
      />
    </div>
  </section>
```

- [ ] **Step 3: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 4: Commit**

```bash
git add website/src/pages/index.astro website/public/floatify-screenshot.png
git commit -m "feat(website): add macOS screenshot placeholder section"
```

---

### Task 6: Overhaul Features Section

**Files:**
- Modify: `website/src/pages/index.astro:64-111`

- [ ] **Step 1: Replace the Features section heading and grid**

Replace the entire Features `<!-- Features Section -->` block with:

```astro
  <!-- Features Section -->
  <section class="py-20 px-6 max-w-6xl mx-auto">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase text-center mb-12">Features</p>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Feature 1: Sub-millisecond IPC -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13 10V3L4 14h7v7l9-11h-7z"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Sub-millisecond IPC</h3>
        <p class="text-sm text-terminal-text-secondary">FIFO pipe for instant communication between CLI and app with minimal latency.</p>
      </div>
      <!-- Feature 2: Zero Focus Stealing -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Zero Focus Stealing</h3>
        <p class="text-sm text-terminal-text-secondary">Non-activating NSPanel design keeps your workflow uninterrupted.</p>
      </div>
      <!-- Feature 3: Dead Zone Positioning -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Dead Zone Positioning</h3>
        <p class="text-sm text-terminal-text-secondary">Screen corner placement uses otherwise wasted screen space.</p>
      </div>
      <!-- Feature 4: Stackable Panels -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Stackable Panels</h3>
        <p class="text-sm text-terminal-text-secondary">Up to 3 notifications stack elegantly with 4px vertical offset.</p>
      </div>
      <!-- Feature 5: FIFO Pipe IPC -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">FIFO Pipe IPC</h3>
        <p class="text-sm text-terminal-text-secondary">Simple and reliable named pipe communication, no network needed.</p>
      </div>
      <!-- Feature 6: Developer-First -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Developer-First</h3>
        <p class="text-sm text-terminal-text-secondary">Hooks integrate seamlessly with your Claude Code workflow.</p>
      </div>
      <!-- Feature 7: Configurable -->
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-6 hover:-translate-y-1 hover:border-terminal-border-hover transition-all duration-200">
        <svg class="w-6 h-6 text-terminal-text-secondary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
        </svg>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Configurable Layout</h3>
        <p class="text-sm text-terminal-text-secondary">Customize panel size, margin, and stacking offset via positions.json.</p>
      </div>
    </div>
  </section>
```

Key changes:
- Section heading: `text-3xl font-bold` -> `text-xs tracking-wider uppercase`
- Card bg: `bg-terminal-bg` -> `bg-terminal-card`
- Border: `border-terminal-border` (same token name, new color value)
- Hover: removed `shadow-purple-500/20`, replaced with `hover:border-terminal-border-hover`
- Icons: emoji -> inline SVG stroke icons in `text-terminal-text-secondary`
- Description: `text-terminal-text/70` -> `text-terminal-text-secondary`

- [ ] **Step 2: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 3: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "refactor(website): overhaul features section with SVG icons and neutral palette"
```

---

### Task 7: Overhaul How It Works Section

**Files:**
- Modify: `website/src/pages/index.astro:157-184`

- [ ] **Step 1: Replace the How It Works section**

Replace the entire `<!-- How It Works Section -->` block with:

```astro
  <!-- How It Works Section -->
  <section class="py-20 px-6 max-w-6xl mx-auto">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase text-center mb-12">How It Works</p>
    <div class="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-8 md:gap-4">
      <!-- Step 1 -->
      <div class="flex-1 flex flex-col items-center text-center relative">
        <div class="w-12 h-12 rounded-full bg-terminal-surface text-terminal-text flex items-center justify-center text-xl font-bold mb-4 z-10">1</div>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Hook Trigger</h3>
        <p class="text-sm text-terminal-text-secondary">Claude Code hook fires on your command completion.</p>
        <div class="hidden md:block absolute top-6 right-0 translate-x-1/2 w-8 h-0.5 bg-terminal-border"></div>
      </div>
      <!-- Step 2 -->
      <div class="flex-1 flex flex-col items-center text-center relative">
        <div class="w-12 h-12 rounded-full bg-terminal-surface text-terminal-text flex items-center justify-center text-xl font-bold mb-4 z-10">2</div>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">CLI Command</h3>
        <p class="text-sm text-terminal-text-secondary">floatify sends message via FIFO pipe to the app.</p>
        <div class="hidden md:block absolute top-6 right-0 translate-x-1/2 w-8 h-0.5 bg-terminal-border"></div>
      </div>
      <!-- Step 3 -->
      <div class="flex-1 flex flex-col items-center text-center">
        <div class="w-12 h-12 rounded-full bg-terminal-surface text-terminal-text flex items-center justify-center text-xl font-bold mb-4 z-10">3</div>
        <h3 class="text-lg font-semibold text-terminal-text mb-2">Notification</h3>
        <p class="text-sm text-terminal-text-secondary">Panel appears in screen dead zone instantly.</p>
      </div>
    </div>
  </section>
```

Key changes:
- Heading: uppercase label style
- Step badge: `bg-purple-600 text-white` -> `bg-terminal-surface text-terminal-text`
- Description: `text-terminal-text/70` -> `text-terminal-text-secondary`
- Connecting lines: `bg-terminal-border` (same token, new neutral value)

- [ ] **Step 2: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 3: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "refactor(website): overhaul how it works section with neutral palette"
```

---

### Task 8: Overhaul Code Sections (Config, CLI, Integration)

**Files:**
- Modify: `website/src/pages/index.astro:113-252`

- [ ] **Step 1: Replace the Configuration section**

Replace the entire `<!-- Configuration Section -->` block with:

```astro
  <!-- Configuration Section -->
  <section id="configuration" class="py-20 px-6 max-w-4xl mx-auto">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase font-mono mb-8">Configuration</p>
    <p class="text-terminal-text-secondary mb-6">Floatify uses <code class="px-2 py-1 bg-terminal-surface rounded text-sm text-terminal-text">positions.json</code> for per-position notification settings. Place your custom config at <code class="px-2 py-1 bg-terminal-surface rounded text-sm text-terminal-text">~/.floatify/positions.json</code>.</p>
    <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
      <div class="flex items-center justify-between px-4 py-2 border-b border-terminal-border bg-[#0a0a0a]">
        <span class="text-xs text-terminal-text-muted font-mono">positions.json</span>
        <button onclick="copyCode(this)" class="text-xs text-terminal-text-muted hover:text-terminal-text-secondary px-2 py-1 rounded bg-terminal-surface hover:bg-terminal-border-hover transition-colors">Copy</button>
      </div>
      <pre class="p-4 text-sm font-mono text-terminal-text overflow-x-auto"><code>{`{
  "bottomRight": {
    "margin": 20,
    "width": 320,
    "height": 80,
    "stackOffset": 6
  },
  "center": {
    "margin": 0,
    "width": 280,
    "height": 68,
    "stackOffset": 4
  }
}`}</code></pre>
    </div>
    <div class="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-4">
        <p class="text-xs text-terminal-text-muted font-mono mb-1">margin</p>
        <p class="text-sm text-terminal-text">Screen edge distance (px)</p>
      </div>
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-4">
        <p class="text-xs text-terminal-text-muted font-mono mb-1">width</p>
        <p class="text-sm text-terminal-text">Panel width (px)</p>
      </div>
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-4">
        <p class="text-xs text-terminal-text-muted font-mono mb-1">height</p>
        <p class="text-sm text-terminal-text">Panel height (px)</p>
      </div>
      <div class="bg-terminal-card border border-terminal-border rounded-lg p-4">
        <p class="text-xs text-terminal-text-muted font-mono mb-1">stackOffset</p>
        <p class="text-sm text-terminal-text">Stack spacing (px)</p>
      </div>
    </div>
  </section>
```

- [ ] **Step 2: Replace the CLI Reference section**

Replace the entire `<!-- CLI Reference -->` block with:

```astro
  <!-- CLI Reference -->
  <section id="cli-reference" class="py-20 px-6 max-w-4xl mx-auto">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase font-mono mb-8">CLI Reference</p>
    <div class="space-y-6">
      <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
        <div class="flex items-center justify-between px-4 py-2 border-b border-terminal-border bg-[#0a0a0a]">
          <div class="flex gap-1.5">
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
          </div>
          <button onclick="copyCode(this)" class="text-xs text-terminal-text-muted hover:text-terminal-text-secondary px-2 py-1 rounded bg-terminal-surface hover:bg-terminal-border-hover transition-colors">Copy</button>
        </div>
        <pre class="p-4 text-sm font-mono text-terminal-text overflow-x-auto"><code>floatify --message "Task complete!"</code></pre>
      </div>
      <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
        <div class="flex items-center justify-between px-4 py-2 border-b border-terminal-border bg-[#0a0a0a]">
          <div class="flex gap-1.5">
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
          </div>
          <button onclick="copyCode(this)" class="text-xs text-terminal-text-muted hover:text-terminal-text-secondary px-2 py-1 rounded bg-terminal-surface hover:bg-terminal-border-hover transition-colors">Copy</button>
        </div>
        <pre class="p-4 text-sm font-mono text-terminal-text overflow-x-auto"><code>floatify --message "Deploy done!" --position bottomRight</code></pre>
      </div>
      <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
        <div class="flex items-center justify-between px-4 py-2 border-b border-terminal-border bg-[#0a0a0a]">
          <div class="flex gap-1.5">
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
            <span class="w-3 h-3 rounded-full bg-terminal-dot"></span>
          </div>
          <button onclick="copyCode(this)" class="text-xs text-terminal-text-muted hover:text-terminal-text-secondary px-2 py-1 rounded bg-terminal-surface hover:bg-terminal-border-hover transition-colors">Copy</button>
        </div>
        <pre class="p-4 text-sm font-mono text-terminal-text overflow-x-auto"><code>floatify --message "Build failed" --position bottomLeft --duration 10</code></pre>
      </div>
    </div>
  </section>
```

- [ ] **Step 3: Replace the Claude Code Integration section**

Replace the entire `<!-- Claude Code Integration -->` block with:

```astro
  <!-- Claude Code Integration -->
  <section id="claude-code-integration" class="py-20 px-6 max-w-4xl mx-auto">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase font-mono mb-8">Claude Code Integration</p>
    <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
      <div class="flex items-center justify-between px-4 py-2 border-b border-terminal-border bg-[#0a0a0a]">
        <span class="text-xs text-terminal-text-muted font-mono">settings.json</span>
        <button onclick="copyCode(this)" class="text-xs text-terminal-text-muted hover:text-terminal-text-secondary px-2 py-1 rounded bg-terminal-surface hover:bg-terminal-border-hover transition-colors">Copy</button>
      </div>
      <pre class="p-4 text-sm font-mono text-terminal-text overflow-x-auto"><code>{`{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "floatify --message 'Floatify is waiting' --position bottomRight --duration 10"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "floatify --message 'Bash task done' --position bottomLeft --duration 5"
      }]
    }]
  }
}`}</code></pre>
    </div>
  </section>
```

- [ ] **Step 4: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 5: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "refactor(website): overhaul code sections with neutral dark palette"
```

---

### Task 9: Overhaul Installation and Footer

**Files:**
- Modify: `website/src/pages/index.astro:254-382`

- [ ] **Step 1: Replace the Installation section**

Replace the entire `<!-- Installation Section -->` block with:

```astro
  <!-- Installation Section -->
  <section id="installation" class="py-20 px-6 max-w-4xl mx-auto border-t border-terminal-border">
    <p class="text-xs text-terminal-text-tertiary tracking-wider uppercase font-mono mb-8">Installation</p>
    <div class="relative rounded-lg overflow-hidden border border-terminal-border bg-terminal-card">
      <div class="flex items-center gap-2 px-4 py-3 border-b border-terminal-border bg-[#0a0a0a]">
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <div class="w-3 h-3 rounded-full bg-terminal-dot"></div>
        <span class="ml-4 text-xs text-terminal-text-muted font-mono">terminal</span>
      </div>

      <ol class="divide-y divide-terminal-border">
        <!-- Step 1: Clone -->
        <li class="flex items-start gap-4 p-4">
          <span class="flex-shrink-0 w-8 h-8 bg-terminal-surface text-terminal-text-muted rounded-full flex items-center justify-center text-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <div class="flex-1 min-w-0">
            <p class="text-terminal-text font-mono mb-2">Clone the repository</p>
            <div class="p-3 bg-[#0a0a0a] border border-terminal-border rounded font-mono text-sm">
              <span class="text-terminal-text-muted">$</span> <span class="text-terminal-text-secondary">git clone https://github.com/hieppp/floatify.git</span>
            </div>
          </div>
        </li>

        <!-- Step 2: Generate Xcode project -->
        <li class="flex items-start gap-4 p-4">
          <span class="flex-shrink-0 w-8 h-8 bg-terminal-surface text-terminal-text-muted rounded-full flex items-center justify-center text-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <div class="flex-1 min-w-0">
            <p class="text-terminal-text font-mono mb-2">Generate Xcode project</p>
            <div class="p-3 bg-[#0a0a0a] border border-terminal-border rounded font-mono text-sm">
              <span class="text-terminal-text-muted">$</span> <span class="text-terminal-text-secondary">cd Floatify && xcodegen generate</span>
            </div>
          </div>
        </li>

        <!-- Step 3: Build the app -->
        <li class="flex items-start gap-4 p-4">
          <span class="flex-shrink-0 w-8 h-8 bg-terminal-surface text-terminal-text-muted rounded-full flex items-center justify-center text-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <div class="flex-1 min-w-0">
            <p class="text-terminal-text font-mono mb-2">Build the app</p>
            <div class="p-3 bg-[#0a0a0a] border border-terminal-border rounded font-mono text-sm overflow-x-auto">
              <span class="text-terminal-text-muted">$</span> <span class="text-terminal-text-secondary">xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO</span>
            </div>
          </div>
        </li>

        <!-- Step 4: Build the CLI -->
        <li class="flex items-start gap-4 p-4">
          <span class="flex-shrink-0 w-8 h-8 bg-terminal-surface text-terminal-text-muted rounded-full flex items-center justify-center text-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <div class="flex-1 min-w-0">
            <p class="text-terminal-text font-mono mb-2">Build the CLI</p>
            <div class="p-3 bg-[#0a0a0a] border border-terminal-border rounded font-mono text-sm overflow-x-auto">
              <span class="text-terminal-text-muted">$</span> <span class="text-terminal-text-secondary">xcodebuild -project Floatify.xcodeproj -scheme floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO</span>
            </div>
          </div>
        </li>

        <!-- Step 5: Install symlinks -->
        <li class="flex items-start gap-4 p-4">
          <span class="flex-shrink-0 w-8 h-8 bg-terminal-surface text-terminal-text-muted rounded-full flex items-center justify-center text-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <div class="flex-1 min-w-0">
            <p class="text-terminal-text font-mono mb-2">Install symlinks</p>
            <div class="p-3 bg-[#0a0a0a] border border-terminal-border rounded font-mono text-sm">
              <p class="text-terminal-text-muted">The app creates symlinks automatically on first launch.</p>
              <p class="text-terminal-text-muted mt-2">Run <span class="text-terminal-text-secondary">open /Applications/Floatify.app</span> to start.</p>
            </div>
          </div>
        </li>
      </ol>
    </div>

    <div class="mt-8 text-center">
      <a href="https://github.com/hieppp/floatify" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-2 px-6 py-3 border border-terminal-border text-terminal-text-secondary rounded-lg font-mono text-sm transition-colors hover:border-terminal-border-hover hover:text-terminal-text">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
          <path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 3.848-2.805 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A12.019 12.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd"/>
        </svg>
        View on GitHub
      </a>
    </div>
  </section>
```

Key changes:
- Border-top: `#313244/30` -> `border-terminal-border`
- Code block bg: `#1e1e2e` -> `bg-terminal-card`
- Header bg: `#181825` -> `#0a0a0a`
- Dots: Catppuccin hex -> `bg-terminal-dot`
- Prompt `$`: `text-[#a6e3a1]` -> `text-terminal-text-muted`
- Checkmark: `bg-[#a6e3a1]/20 text-[#a6e3a1]` -> `bg-terminal-surface text-terminal-text-muted`
- Inline command bg: `#181825` -> `#0a0a0a`
- "View on GitHub": `bg-[#313244]` -> `border border-terminal-border`

- [ ] **Step 2: Replace the Footer section**

Replace the entire `<!-- Footer -->` block with:

```astro
  <!-- Footer -->
  <footer class="py-8 px-6 border-t border-terminal-border bg-terminal-card">
    <div class="max-w-6xl mx-auto">
      <div class="flex flex-col md:flex-row items-center justify-between gap-4">
        <p class="text-terminal-text-faint text-sm font-mono">2026 Floatify</p>
        <span class="px-3 py-1 bg-terminal-surface rounded text-xs font-mono text-terminal-text-tertiary border border-terminal-border">
          MIT License
        </span>
        <a href="https://github.com/hieppp/floatify" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-2 text-terminal-text-faint hover:text-terminal-text-muted text-sm font-mono transition-colors">
          GitHub
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
          </svg>
        </a>
      </div>
      <div class="mt-6 text-center">
        <a href="#" class="text-terminal-text-faint hover:text-terminal-text-muted text-xs font-mono transition-colors">
          Back to top
        </a>
      </div>
    </div>
  </footer>
```

Key changes:
- Bg: `#181825` -> `bg-terminal-card`
- Border: `#313244` -> `border-terminal-border`
- Copyright: `text-terminal-text/60` -> `text-terminal-text-faint`
- MIT badge: `bg-[#313244]/50 text-terminal-text/80 border-[#313244]` -> `bg-terminal-surface text-terminal-text-tertiary border-terminal-border`
- GitHub link: `text-terminal-text/60 hover:text-terminal-text` -> `text-terminal-text-faint hover:text-terminal-text-muted`
- Back to top: `text-terminal-text/40 hover:text-terminal-text/80` -> `text-terminal-text-faint hover:text-terminal-text-muted`

- [ ] **Step 3: Remove the duplicate cursor style block**

There are two `<style>` blocks at the bottom of the file (lines 384-393 and 453-463). The second one is a duplicate. Remove the second `<style>` block entirely (lines 453-463):

```html
<style>
  #cursor {
    display: inline-block;
    animation: blink 1s step-end infinite;
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
  }
</style>
```

Keep only the first `<style>` block (lines 384-393).

- [ ] **Step 4: Verify build succeeds**

Run: `cd website && npm run build`
Expected: Build completes with no errors

- [ ] **Step 5: Commit**

```bash
git add website/src/pages/index.astro
git commit -m "refactor(website): overhaul installation and footer with neutral dark palette"
```

---

### Task 10: Final Build and Visual Verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run production build**

Run: `cd website && npm run build`
Expected: Build completes with 0 errors

- [ ] **Step 2: Start preview server**

Run: `cd website && npm run preview`
Expected: Server starts at `http://localhost:4321`

- [ ] **Step 3: Visual verification checklist**

Open `http://localhost:4321` and verify:
- Page background is near-black (`#0a0a0a`), not Catppuccin purple
- Navigation has neutral GitHub button, no colored elements
- Hero terminal has muted gray dots, no colored dots
- Two CTA buttons appear below terminal (Get Started + View on GitHub)
- Animated demo section appears after hero with notification animation
- Screenshot placeholder appears after demo
- Feature cards have monochrome SVG icons, no emoji
- Feature card hover shows border brighten, no purple glow
- How It Works step badges are neutral gray, not purple
- All code blocks have gray dots, neutral borders
- Installation checkmarks are gray, not green
- Footer text is very faint (`#333` range)
- No Catppuccin colors remain anywhere on the page
- Terminal typing animation still works
- Copy-to-clipboard buttons still work
- Navbar scroll effect still works (transparent -> dark bg on scroll)

- [ ] **Step 4: Stop preview server and commit any fixes**

If any issues were found during verification, fix them and commit:

```bash
git add website/
git commit -m "fix(website): address visual verification issues"
```
