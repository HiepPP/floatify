# Floatify Landing Page Design

**Date:** 2026-04-03
**Status:** Approved

## 1. Concept & Vision

A developer-focused marketing landing page built in the **Technical & Precise** style (dark terminal aesthetic). The page communicates speed, simplicity, and power through terminal visuals, monospace typography, and code-first presentation. It feels like a natural extension of the tool itself.

**Personality:** Precise, fast, no-nonsense. The kind of page a developer respects.

---

## 2. Page Structure

**Route:** `/` (homepage)

**Sections (top to bottom):**

1. **Hero** — Terminal-style intro with animated install command, headline, tagline
2. **Features** — Grid of 4-6 key features with icons
3. **How It Works** — 3-step visual flow (hook → CLI → notification)
4. **CLI Reference** — Interactive code examples showing key commands
5. **Claude Code Integration** — Code block showing hook configuration
6. **Installation** — Build-from-source instructions + symlink setup
7. **Footer** — GitHub link, MIT license, back to top

**Responsive strategy:**
- Desktop: Full terminal aesthetic with wide code blocks
- Mobile: Stacked sections, scrollable code blocks, terminal bar simplified

---

## 3. Component Inventory

**Navigation**
- Minimal top bar: Logo + GitHub star button
- Sticky on scroll
- States: default (transparent), scrolled (dark bg)

**Hero Terminal Block**
- macOS-style terminal window with traffic light dots
- Animated `$ brew install` command that types out
- Copy-to-clipboard on click
- States: loading (typing animation), idle

**Feature Cards**
- Icon + title + description
- Dark card background with subtle border
- Hover: slight lift + border glow
- 2x3 grid on desktop, stacked on mobile

**How It Works Stepper**
- 3 horizontal steps with connecting lines
- Each step: number badge + title + description
- Mobile: vertical stack

**Code Blocks**
- Syntax highlighted (Astro Shiki)
- Dark theme (Catppuccin)
- Copy button top-right
- Line numbers for longer blocks

**Installation Card**
- Step-by-step numbered instructions
- Terminal blocks for commands
- Checkmark indicators when complete

**Footer**
- Single row: copyright + GitHub link + license badge
- Minimal, no newsletter or extra links

---

## 4. Technical Approach

**Stack:**
- Astro 4.x (static site generator)
- Tailwind CSS 3.x
- Flowbite (Tailwind component library)
- Shiki (syntax highlighting, built into Astro)
- Deployment: Vercel (static export)

**Project structure:**
```
floatify/
└── website/
    ├── src/
    │   ├── layouts/
    │   ├── pages/
    │   ├── components/
    │   └── styles/
    ├── public/
    ├── astro.config.mjs
    ├── tailwind.config.mjs
    └── package.json
```

**Key implementation notes:**
- `output: 'static'` for Vercel static deployment
- Flowbite dark theme components + custom terminal styling
- No client-side JS beyond copy buttons and scroll behavior
- Build command: `npm run build`

---

## 5. Design Decisions

| Decision | Choice | Rationale |
|----------|--------|------------|
| Visual style | Dark terminal aesthetic | Matches tool personality, appeals to developers |
| Component library | Flowbite | Tailwind-based, dark theme ready, no React dependency |
| Syntax highlighting | Shiki (Astro built-in) | Built-in, Catppuccin theme matching terminal colors |
| Deployment | Vercel static | User requested, zero-config deployment |
| Repo structure | Monorepo (website/ folder) | Shares repo, simpler CI, unified git history |
| Animations | Minimal | Terminal typing effect only, respects performance |
