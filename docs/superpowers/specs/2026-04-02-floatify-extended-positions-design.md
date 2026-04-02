# Floatify Extended Positions & Effects Design Specification

## Overview

Extend Floatify's notification positioning system from 2 corners (bottomLeft, bottomRight) to 7 position types with horizontal stacking, per-position animations, visual effects, and sound effects.

## Position Types

### Enum: `Corner` (Extended)

```swift
enum Corner {
    // Bottom edges (existing)
    case bottomLeft
    case bottomRight

    // Top edges (new)
    case topLeft
    case topRight

    // Center (new)
    case center

    // Menubar (new)
    case menubar

    // Horizontal stacking mode (new, works with any anchor)
    case horizontal
}
```

### Position Definitions

| Position    | Anchor        | Stack Direction | Animation Entry      |
|-------------|---------------|-----------------|---------------------|
| bottomLeft  | screen bottom-left corner | vertical up | slide from left |
| bottomRight | screen bottom-right corner | vertical up | slide from right |
| topLeft     | screen top-left corner | vertical down | drop from top |
| topRight    | screen top-right corner | vertical down | drop from top |
| center      | screen center | scale/bounce | bounce in |
| menubar     | top center (below menu bar) | horizontal or vertical | gentle drop |
| horizontal  | screen bottom-left corner | horizontal right | cascade slide |

## Horizontal Stacking

When `horizontal` mode is active:

- Notifications stack left-to-right from the anchor corner
- Each notification offset by `notificationWidth + gap` (default: 280px + 8px)
- Cascade animation: each notification delays 100ms after the previous
- Max visible: 4 horizontal notifications before oldest dismisses
- Uses existing `maxPanels = 3` cap; oldest horizontal dismissed first

```swift
struct HorizontalStackManager {
    static let horizontalGap: CGFloat = 8
    static let horizontalMaxVisible = 4
    static let cascadeDelay: TimeInterval = 0.1
}
```

## Per-Position Animations

### Entry Animation Mapping

| Position    | Entry Animation | Duration | Easing |
|-------------|-----------------|----------|--------|
| bottomLeft  | slide from left | 400ms | easeOut |
| bottomRight | slide from right | 400ms | easeOut |
| topLeft     | drop from top | 450ms | spring(0.7) |
| topRight    | drop from top | 450ms | spring(0.7) |
| center      | bounce + scale | 500ms | spring(0.5, 0.8) |
| menubar     | gentle drop | 400ms | easeInOut |
| horizontal  | cascade slide | 350ms each | easeOut |

### Exit Animation

- All positions: fade out + slight scale down (0.95) over 200ms
- Horizontal: rightmost exits first, others slide left to fill gap

## Visual Effects

### Particle Sparkles (Top Corners)

- On appear: 5-8 small circles burst outward from notification
- Colors: white/silver with 60% opacity
- Duration: 600ms
- Physics: radial burst with gravity falloff

### Glow Pulse (Center)

- Soft radial gradient glow behind notification
- Color: position-themed (blue for center, purple for menubar)
- Animation: pulse 3 times on entry, 80% -> 100% -> 80% opacity
- Duration: 900ms total

### Sound Wave Ripple (Bottom Corners)

- Concentric circles expand outward on entry
- Color: cyan-blue gradient, 40% opacity
- 3 rings, 150ms apart
- Duration: 500ms total

### Shimmer Effect (Menubar)

- Diagonal light streak sweeps across notification
- White gradient, 30% opacity
- Duration: 400ms

### Cascade Effect (Horizontal)

- Each notification in sequence slightly offset in entry timing
- Entry y-position staggers: each 4px lower than previous
- Final positions align after all entries complete

## Sound Effects

### Sound Mapping

| Position    | Sound Type | File | Duration |
|-------------|------------|------|----------|
| bottomLeft  | soft slide | slide_left.wav | 200ms |
| bottomRight | soft slide | slide_right.wav | 200ms |
| topLeft     | soft chime | chime_top.wav | 300ms |
| topRight    | soft chime | chime_top.wav | 300ms |
| center      | alert tone | alert_center.wav | 400ms |
| menubar     | whisper | whisper.wav | 250ms |
| horizontal  | cascade chime | cascade.wav | 500ms |

### Implementation

- Sounds played via `NSSound` or `AVAudioPlayer`
- Volume: 0.3 (subtle, non-intrusive)
- Respects system silent mode (check `AVAudioSession.sharedInstance().isOtherAudioPlaying`)
- Sound files stored in app bundle under `Sounds/`

## Position Configuration

### JSON Payload (CLI)

```json
{
  "message": "Task complete!",
  "corner": "bottomRight",
  "duration": 6,
  "effect": "sparkle",
  "sound": true
}
```

New `effect` field optional:
- `"sparkle"` - particle burst
- `"glow"` - pulse effect
- `"ripple"` - sound wave
- `"shimmer"` - light sweep
- `"cascade"` - sequential entry
- `null` - position default effect

### Default Effects by Position

| Position    | Default Effect |
|-------------|---------------|
| bottomLeft  | ripple |
| bottomRight | ripple |
| topLeft     | sparkle |
| topRight    | sparkle |
| center      | glow |
| menubar     | shimmer |
| horizontal  | cascade |

## Architecture Changes

### Files Modified

- `Corner.swift` - extend enum with new cases
- `FloatNotificationManager.swift` - add position-specific logic, effects manager
- `FloatNotificationView.swift` - add effect overlays, shimmer, particles
- `AppDelegate.swift` - load sound files, manage audio
- `cli/main.swift` - parse new corner values, effect options

### New Files

- `FloatEffects.swift` - particle system, glow renderer, ripple animator
- `SoundManager.swift` - audio playback with volume/silent mode
- `HorizontalStackManager.swift` - horizontal layout logic
- `Sounds/` directory - audio files

## Testing Checklist

- [ ] All 7 positions render correctly on single monitor
- [ ] Horizontal stacking: 3 notifications appear side-by-side
- [ ] Horizontal stacking: oldest dismissed when 4th arrives
- [ ] Particle sparkles appear on top corner notifications
- [ ] Glow pulses on center notifications
- [ ] Ripple effect on bottom corner notifications
- [ ] Shimmer sweeps across menubar notifications
- [ ] Cascade entry animates 3 horizontal notifications sequentially
- [ ] Sound plays on notification appear (when not silent)
- [ ] Sound silent when system in silent/do not disturb
- [ ] Multi-monitor: notifications appear on correct screen
- [ ] Existing bottomLeft/bottomRight behavior unchanged (backwards compatible)
