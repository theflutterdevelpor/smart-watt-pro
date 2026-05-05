---
name: Lumina Energy
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c3c5d9'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8d90a2'
  outline-variant: '#434656'
  surface-tint: '#b7c4ff'
  primary: '#b7c4ff'
  on-primary: '#002682'
  primary-container: '#1d5aff'
  on-primary-container: '#ebecff'
  inverse-primary: '#004cec'
  secondary: '#a3d73e'
  on-secondary: '#243600'
  secondary-container: '#77a700'
  on-secondary-container: '#243600'
  tertiary: '#c6c6c7'
  on-tertiary: '#2f3131'
  tertiary-container: '#6a6c6c'
  on-tertiary-container: '#eeeeee'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001552'
  on-primary-fixed-variant: '#0038b6'
  secondary-fixed: '#bef458'
  secondary-fixed-dim: '#a3d73e'
  on-secondary-fixed: '#131f00'
  on-secondary-fixed-variant: '#364e00'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 24px
  margin: 32px
---

## Brand & Style

The design system is built upon the concept of "Illuminated Clarity." It targets a high-end, tech-forward audience that values both aesthetic sophistication and functional precision. The brand personality is optimistic, energetic, and transparent. 

By utilizing an enhanced Glassmorphism style, the UI evokes a sense of depth and lightness. The interface should feel like a series of physical glass panes suspended in a vibrant, pressurized environment. The emotional response is one of "premium efficiency"—where complex data feels breathable and high-performance tools feel approachable.

## Colors

The palette is anchored by a deep, midnight neutral that serves as the canvas for the glass effects. The primary Electric Blue (#1D5AFF) is used for high-priority actions and primary data streams, while the Lime Green (#99CC33) provides a vibrant counterpoint for success states and secondary metrics.

Backgrounds should rarely be solid. Instead, use a dark base with subtle mesh gradients in the background to allow the backdrop-blur of the cards to catch hints of color. Text must maintain high contrast, primarily using pure white or very light silver to ensure legibility over semi-transparent layers.

## Typography

The design system utilizes Plus Jakarta Sans across all levels to maintain a cohesive, welcoming, and modern tone. Headlines use tighter letter-spacing and heavier weights to command attention against the soft background effects. 

Body text remains spacious to ensure readability through transparent layers. Labels and utility text are occasionally set in uppercase with slight tracking to provide a technical, "instrument-panel" feel that complements the energy-focused theme.

## Layout & Spacing

This design system employs a fluid 12-column grid designed for expansive dashboards. The rhythm is dictated by a base-8 scale, ensuring consistent alignment of glass modules. 

Large internal padding (typically 32px) within cards is required to prevent content from feeling crowded against the generous border radii. Negative space is treated as a functional element, allowing the background blurs and gradients to create a sense of atmospheric depth between UI components.

## Elevation & Depth

Depth is the defining characteristic of this design system. It is achieved through a three-layer stack:

1.  **Backdrop:** A 20px Gaussian blur applied to the surface (`backdrop-filter: blur(20px)`).
2.  **Inner Edge:** A 1px semi-transparent white stroke (12-15% opacity) that acts as a "specular highlight" on the top and left edges of cards, simulating the thickness of physical glass.
3.  **Shadow:** A multi-layered, soft drop shadow. Use a tight, darker shadow for contact and a wide, low-opacity blue-tinted shadow for ambient lift.

Elevated states (like hovered cards) should increase the blur intensity and the spread of the ambient shadow rather than just becoming lighter.

## Shapes

The shape language is defined by extreme roundedness. Standard cards use a 24px radius, while large container modules or hero sections move to 32px. This softness offsets the "coldness" of the glass and the technical nature of the colors, making the software feel more organic and accessible. 

Interactive elements like buttons and input fields should utilize pill-shaped (fully rounded) geometries to clearly distinguish them from the structural glass containers.

## Components

### Buttons
Primary buttons are solid Electric Blue with a subtle inner glow. Secondary buttons use the glass style with a more prominent white inner border and high-contrast white text.

### Cards
The primary container. Must have `backdrop-filter: blur(20px)`, a 24px-32px border radius, and the 1px subtle white inner border. The background fill should be a dark neutral at roughly 65% opacity.

### Inputs & Fields
Inputs are semi-transparent with a darker fill than the cards to create an "etched" look. On focus, the border transitions to a glowing Electric Blue.

### Data Visualization
Charts should use glowing lines and frosted area fills. Use the Lime Green for positive trends and the Electric Blue for primary data streams. Avoid solid fills; use gradients that transition from the accent color to transparent.

### Chips & Tags
Pill-shaped with a low-opacity version of the accent colors (e.g., 20% Electric Blue background with 100% Blue text). They should retain a slight blur to stay consistent with the design system's glass-heavy aesthetic.