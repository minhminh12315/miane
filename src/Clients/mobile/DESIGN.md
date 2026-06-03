---
name: MIANE Apple Core Design System
colors:
  primary: "#0D2C54"       # Heritage Navy
  secondary: "#4A90E2"     # Luminous Azure
  accent-gold: "#F4BD64"   # Sand Gold
  surface-light: "#F8F9FA" # White Smoke
  surface-dark: "#0D2C54"  # Heritage Navy
  canvas-light: "#F8F9FA"  # White Smoke
  canvas-dark: "#05101E"   # Deep Abyss
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: 700
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 15px
    fontWeight: 400
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: 500
rounded:
  lg: 32px
  md: 16px
  pill: 99px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
---

# Apple-Style Design System: MIANE Travel

## Overview
A clean, friendly, modern, and premium travel expense planner matching Apple's design language (Human Interface Guidelines). The layout relies on structural flat layers, neutral color scales, large clean navigation headers, fine system divider lines, and high-quality frosted glass blur effects.

## Colors
The color palette matches the MIANE Core Design System tokens:
*   **Luminous Azure (#4A90E2):** System primary brand color, used for links, active nodes, buttons, selection states.
*   **Heritage Navy (#0D2C54):** Primary dark surface for cards and containers.
*   **Sand Gold (#F4BD64):** Premium accents and AI highlights.
*   **Canvas & Surface Light:** 
    *   Canvas Background: `#F8F9FA` (White Smoke).
    *   Surfaces/Cards: `#FFFFFF` (White).
*   **Canvas & Surface Dark:** 
    *   Canvas Background: `#05101E` (Deep Abyss).
    *   Surfaces/Cards: `#0D2C54` (Heritage Navy) / `#1A3D6C` (Secondary Dark Surface).

## Typography
*   **Font Family:** `SF Pro` on iOS (defaults automatically when no font family is specified) and `Inter` / `Be Vietnam Pro` (Google Fonts) on other platforms.
*   **Layout Hierarchy:** Uses large, bold navigation headers left-aligned, standard SF-styled weight mappings (Regular, Medium, SemiBold, Bold).

## Rounded Corners (Bo góc)
*   **Card / Large Sheets (lg):** `32px` for standard layout container cards.
*   **Button / Input Fields (md):** `16px` for cohesive iOS style.
*   **Capsule / Status Pills (pill):** `99px` for chips and indicators.

## Components & Visuals
*   **Glassmorphic blurs (`BackdropFilter`):** Used on headers, tab bars, and modals.
*   **Dividers:** Outlines and separators must be thin: `0.5px` to `1px`, colored `#38383A` (Dark Mode) or `#D1D1D6` (Light Mode).