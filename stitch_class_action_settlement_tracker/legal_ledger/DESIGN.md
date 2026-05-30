---
name: Legal Ledger
colors:
  surface: '#f7fafc'
  surface-dim: '#d7dadc'
  surface-bright: '#f7fafc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f6'
  surface-container: '#ebeef0'
  surface-container-high: '#e5e9eb'
  surface-container-highest: '#e0e3e5'
  on-surface: '#181c1e'
  on-surface-variant: '#43474e'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eef1f3'
  outline: '#74777f'
  outline-variant: '#c4c6cf'
  surface-tint: '#455f88'
  primary: '#002045'
  on-primary: '#ffffff'
  primary-container: '#1a365d'
  on-primary-container: '#86a0cd'
  inverse-primary: '#adc7f7'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#122234'
  on-tertiary: '#ffffff'
  tertiary-container: '#28374a'
  on-tertiary-container: '#91a0b7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#adc7f7'
  on-primary-fixed: '#001b3c'
  on-primary-fixed-variant: '#2d476f'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#d4e4fc'
  tertiary-fixed-dim: '#b8c8e0'
  on-tertiary-fixed: '#0d1c2e'
  on-tertiary-fixed-variant: '#39485c'
  background: '#f7fafc'
  on-background: '#181c1e'
  surface-variant: '#e0e3e5'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 16px
  gutter-mobile: 12px
---

## Brand & Style
The design system is engineered to project **institutional authority, precision, and financial transparency.** It serves a dual purpose: providing users with the confidence that their legal claims are handled with professional rigor, while maintaining the accessibility required for navigating complex legal data.

The aesthetic follows a **Corporate Modern** approach with a lean toward **Minimalism.** By utilizing heavy white space and a structured hierarchy, the interface reduces the cognitive load associated with legal jargon. The visual language is intentional and "un-fussy," prioritizing legibility and status-tracking over decorative elements. Every visual choice is designed to evoke a sense of security and fiduciary responsibility.

## Colors
The palette is rooted in traditional legal and financial colors to establish immediate trust.

- **Primary (#1A365D):** A deep, authoritative blue used for headers, primary actions, and brand-critical elements. It signifies stability and power.
- **Success/Active (#10B981):** A vibrant emerald green reserved for "Active" claim statuses, payout confirmations, and positive progress. It provides a high-contrast signal for user success.
- **Neutral/Expired (#718096):** A soft slate used for secondary information, archived settlements, and disabled states. It allows the active data to remain the focal point.
- **Background (#F7FAFC):** A cool, nearly-white gray that provides a clean canvas, preventing the clinical feel of pure white while maintaining high readability.

## Typography
This design system utilizes **Inter** for all roles to leverage its exceptional legibility and systematic feel. The type scale is optimized for information density, ensuring that multi-line legal descriptions remain readable.

Headlines use tighter letter-spacing and heavier weights to anchor sections, while body text maintains a generous line-height to facilitate skimming through settlement details. Labels are occasionally transformed to uppercase with slight tracking to differentiate metadata from actionable content.

## Layout & Spacing
The system uses a **4px base unit** and a **12-column fluid grid** for desktop, reflowing to a **4-column grid** on mobile devices. 

In this design system, spacing is used to group related legal information. Cards and input groups are separated by `lg` (24px) units to create distinct "envelopes" of data. Content within cards uses `sm` (12px) or `md` (16px) units to maintain a compact, professional information density. 

Mobile layouts must adhere to a strict `16px` side margin to ensure content remains clear of device edges while maximizing the horizontal space for data tables or claim progress bars.

## Elevation & Depth
Depth is handled through **Tonal Layers** supplemented by **Low-Contrast Outlines.** Because the app manages sensitive legal data, we avoid heavy, dramatic shadows which can feel too "app-like" or casual.

1.  **Level 0 (Background):** The base `#F7FAFC` surface.
2.  **Level 1 (Cards/Containers):** White surfaces with a 1px border in a lightened version of the Neutral color (#E2E8F0). No shadow.
3.  **Level 2 (Active/Floating):** Used for bottom sheets or modals. Features a very soft, diffused shadow (0px 4px 12px, 5% opacity Primary Blue) to indicate interaction priority without breaking the flat, clean aesthetic.

## Shapes
The shape language is **Soft (0.25rem/4px).** This subtle rounding strikes the perfect balance between the rigid "sharpness" of traditional law firms and the approachability of modern FinTech. 

Buttons and input fields use the base `rounded` (4px) setting. Larger containers like cards use `rounded-lg` (8px) to provide a slightly more modern, contained feel. Status badges and chips use a "pill" style (full rounding) to clearly distinguish them from interactive buttons.

## Components

- **Buttons:** Primary buttons are solid `#1A365D` with white text. High contrast is mandatory. Disabled states use 40% opacity of the primary color rather than graying them out, maintaining brand presence while indicating inactivity.
- **Status Badges:** Use a "Vivid Badge" pattern. For "Active" settlements, use a subtle 10% opacity Emerald Green background with solid `#10B981` text. 
- **Cards:** The primary container for lawsuits. Must include a 1px border (#E2E8F0) and 16px internal padding. Card headers should use `headline-sm` for the case title.
- **Input Fields:** Outlined style with a 1px border. On focus, the border transitions to Primary Blue with a 2px stroke. Label text sits consistently above the field.
- **Progress Trackers:** For claim tracking, use a horizontal stepper. Completed steps use the Success Green; pending steps use the Neutral Gray.
- **Lists:** Use "Divided Lists" with a 1px separator. Each list item should have a chevron icon if it leads to a drill-down legal summary.