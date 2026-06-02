---
name: MIANE Travel Core
colors:
  primary: "#0D2C54" 
  secondary: "#4A90E2" 
  accent-gold: "#F4BD64" 
  surface-light: "#F8F9FA"
  surface-dark: "#05101E" 
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: 700
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: 400
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: 500
rounded:
  lg: 32px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
---

# Design System: MIANE Travel Core

## Overview
A premium, cultural tech-minimalism interface for MIANE — a smart travel itinerary planner and group expense-splitting application. It balances clean modern digital interfaces with rich, tactile travel environments by utilizing Modern Minimalism and light Glass Morphism effects. The design is explicitly crafted to feel liberating and energetic, avoiding the dryness of standard financial management applications.

## Colors
The color palette has been strictly calibrated to match the official `miane-logo.png`, utilizing a sophisticated dual-tone approach of Deep Blue and Sand Gold, entirely stripping away orange and green hues.
*   **Primary (#0D2C54):** Heritage Navy. Drawn directly from the deep blue background of the logo. Represents technology, transparency, and absolute reliability. Used for core structural headers, background canvases in dark mode, and formal visualizer elements.
*   **Secondary (#4A90E2):** Luminous Azure. A brighter, energetic blue replacing the previous coral/orange. Used for active interactive nodes, budget-splitting matrices, and progress indicators to maintain visual harmony with the primary navy.
*   **Accent Gold (#F4BD64):** Sand Gold (Vàng Cát). Directly representing the stylized Lac Bird vector layer in the logo. Strictly reserved for the logo, premium Pro tier indicators, AI scanning frames, and critical alert highlights.
*   **Surfaces:** 
    *   *Light Mode:* White Smoke (#F8F9FA) with translucent frosted glass overlays.
    *   *Dark Mode:* Deep Abyss (#05101E) - a pure, extremely dark navy with zero green tint, equipped with subtle luminous borders to optimize nighttime viewing and reduce eye strain when checking schedules outdoors.

## Typography
*   **Headlines & Luxury Accents:** Playfair Display, bold, serif. Used for screen titles, onboarding steps, and premium travel headings.
*   **Body & Operations:** Be Vietnam Pro, regular/medium, sans-serif. Highly readable for financial ledgers, numbers, and settings.
*   **Labels & Meta-Logs:** Be Vietnam Pro, 12px, uppercase for active indicators and structural tags.

## Components

### 1. Cards & Sheets
*   Strict global execution of 32dp corner radius.
*   Utilizes light drop-shadows to emphasize layering over the background canvases.
*   Must incorporate clear data visualization, such as dynamic pie and bar charts, to represent expense structures instantly.

### 2. Floating Header
A translucent glass floating panel positioned at the top of the interface, adhering to the 32dp curvature rule. It includes:
*   **Logo Area (Left):** Displays the stylized Lac Bird from the logo rendered in Accent Gold (#F4BD64).
*   **Theme Switcher (Center-Right):** A capsule indicator toggle supporting a Theme Morphing effect (450ms color-shifting) for rapid transition between Light and Dark modes.
*   **Profile Area (Right):** A rounded user avatar that opens an expanded Profile Settings screen, allowing users to configure their Language, Region, and Receiving Wallet (Bank/MoMo).

### 3. Floating Bottom Navigator
A completely detached pill-shaped chassis floating 16dp above screen bounds. Features 32dp rounded corners with high-transparency frosted glass. It houses quick-access nodes mapped to the application's core flows:
*   **Home (Trip Dashboard):** The central hub displaying the three most critical metrics: the next schedule in the day, the group's total spent budget, and the user's personal financial status (who they owe or who owes them).
*   **Itinerary:** Access to the interactive travel route map and the AI Trip Planner.
*   **Ledger:** Management of the Smart Split-wise system, manual expense entries, and the AI OCR receipt scanner.
*   **Settlement:** Displays the cash-flow optimization algorithm (shortest path of money), dynamic VietQR/MoMo codes for 1-touch App-to-App payments, and real-time Auto-Reconciliation tracking.
*   **Radial FAB (Center):** The main interactive menu that pops out sub-buttons via an elastic-out spring physics curve. Provides quick access to value-added features like the Shared Cloud Album and Trip Checklist.

## Animations, Transitions & Interactions
*   **Jet Launch Intro:** On application boot, a vector airplane accelerates from the bottom center, expanding and scaling exponentially until it eclipses the frame to transition into the dashboard.
*   **Theme Morphing:** 450ms color-shifting pixel interpolation when toggling between Light and Dark environments.
*   **Radial FAB Expansion:** Main interactive menu pops out sub-buttons using an elastic-out spring physics curve.
*   **The 3-Touch Rule:** Critical operational flows, such as inputting a new expense or checking a schedule, must be achievable within a maximum of three screen touches.

## Do's and Don'ts
*   **Do** keep the bottom navigator strictly unattached to the screen boundaries.
*   **Do** restrict the Accent Gold color strictly to the logo elements and Premium Pro tier indicators.
*   **Do** seamlessly integrate Premium indicators (like icons) into the UI to encourage upgrades without breaking the user experience.
*   **Don't** use sharp edges anywhere; every surface must maintain a unified 32dp curvature.