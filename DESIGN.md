# TeleCars design system: "Ring & Route"

An evolution of TeleTech blue for an Operate-mode Android app. Two motifs come straight from the product. **Ring** is the concentric ellipse from the TeleTech mark, read as a signal: presence, being live, being checked in. **Route** is the origin → destination line every trip is made of. Everything else stays quiet, precise and Material-native.

## Colour (`lib/core/theme/app_colors.dart`)

| Token | Hex | Use |
|---|---|---|
| `deepBlue` | `#0B4DA2` | TeleTech blue: primary actions, selection |
| `signal` | `#2F7BEA` | Live and active states, focus, the ring pulse |
| `navy` | `#0B1F45` | Text (ink) and the dark hero surface |
| `navyDeep` | `#071533` | Deepest end of the hero surface |
| `inkMuted` | `#5B6B86` | Secondary text (5.3:1 on white) |
| `scaffold` | `#F4F6FA` | App background |
| `line` | `#E3E8F1` | Hairline borders, dividers |
| `paleBlue` | `#EAF0FA` | Tinted fills (inputs, empty-state ground) |
| success / warning / error | `#1F9D6B` / `#E0A030` / `#D64545` | Status; text on their tints uses the darkened `ink` variant from `AppColors.inkOn()` |

Restrained: blue appears only on actions, selection and live state. Each screen gets one dark navy hero surface at most.

## Type

Readex Pro (Latin and Arabic in one family; falls back to Cairo). Numbers use tabular figures (`AppTypography.tabular`). Material type roles only; weights 400 / 500 / 600 / 700.

## Shape and depth

- Radius: cards 16, controls 14, chips and segmented controls are pills.
- Depth is declared once: content cards use a 1 px `line` border and no shadow. Floating chrome (the bottom bar, the hero surface) uses one soft offset shadow (`0 8 24`, 10–18 % navy).
- No side status bars on cards. Status is a chip with a dot.

## Motion (`lib/core/theme/app_motion.dart`)

| Token | Value | Use |
|---|---|---|
| `easeOut` | cubic(0.23, 1, 0.32, 1) | Entrances and feedback |
| `easeInOut` | cubic(0.77, 0, 0.175, 1) | On-screen movement (nav indicator, segmented thumb) |
| `press` | 120 ms | Press scale 0.97 |
| `quick` | 180 ms | State swaps, chips |
| `standard` | 260 ms | Indicators, list entrances |
| `emphasized` | 420 ms | Page transitions, the check-in moment |

- Exits are faster than entrances. Never scale from 0 (start at 0.92 or above together with an opacity fade).
- Lists stagger with non-uniform delays (0, 50, 90, 120, 145, 165 ms, then capped). Stagger runs only on first load.
- **Focal moment:** a successful check-in plays a ring burst from the status mark with a medium haptic, and the ring keeps a slow pulse while the driver is checked in.
- Navigation: a sliding pill indicator in the bottom bar, a sliding thumb in period controls, and shared-axis page transitions that follow text direction.
- Reduced motion: no movement; only fades and colour changes remain.
