# WildDeck Branding Guidelines

## Product Identity

**Name:** WildDeck  
**Tagline:** "Play Wild. Win Fast."  
**Version:** 1.0

## Visual Identity

### Color Palette

| Name | Hex | Usage |
|---|---|---|
| Navy Deep | `#0B0E1A` | Primary background |
| Navy Mid | `#141829` | Surface background |
| Navy Surface | `#1C2235` | Card/panel background |
| Ember Red | `#E53935` | Primary accent, action |
| Amber | `#F9A825` | Warning, Last Card indicator |
| Deep Blue | `#1565C0` | Blue card color |
| Forest Green | `#2E7D32` | Green card color |

### Card Colors

WildDeck uses four original card colors:

- **Red** — Ember red (`#E53935`)
- **Blue** — Deep blue (`#1565C0`)
- **Green** — Forest green (`#2E7D32`)
- **Yellow** — Amber (`#F9A825`)
- **Wild** — Multi-color gradient (all four colors)

### Typography

- **Primary font family:** GameFont (custom, included in assets)
- **Fallback:** System sans-serif

## Game Terminology

WildDeck uses its own terminology. The table below shows the canonical WildDeck terms:

| Concept | WildDeck Term |
|---|---|
| Declaring you have one card left | "Last Card!" |
| The declaration button | "LAST CARD!" button |
| Wild color change card | "Wild" |
| Wild plus draw penalty card | "Wild Draw Four" |
| Draw penalty on missed declaration | Last Card penalty (+2 cards) |
| Challenge a Wild Draw Four | "Challenge" |

## Asset Originality Requirements

All WildDeck visual assets MUST be original works:

- Card back design — original geometric pattern on navy background
- Card face layout — original layout using WildDeck card colors and value glyphs
- Application icon — original WD lettermark
- Loading screens — original animations
- Sound effects — original or royalty-free sounds with no resemblance to competing products

## Prohibited References

The following must NEVER appear in any WildDeck codebase, assets, documentation, or user-facing content:

- The word "UNO" in any capitalization
- The word "Mattel" in any context
- Phrases such as "UNO-style", "UNO-inspired", "UNO clone", "similar to UNO"
- Any trademarked card game logo, typography, or artwork
- Any card layout or visual design copied from a commercial card game product

## Internal Migration Notes

For historical reference only (never user-facing): WildDeck was developed as an original multiplayer card game. Earlier development documentation may reference common card game mechanics by generic names; all user-facing and code-level identifiers use WildDeck-specific terminology.

## Compliance Verification

To verify compliance, run:

```bash
grep -ri "uno\|mattel" . \
  --include="*.dart" --include="*.go" --include="*.yaml" --include="*.yml" \
  --include="*.tf" --include="*.sh" --include="*.js" --include="*.md" \
  | grep -v ".git/"
```

This command must return zero results for all production source files.
