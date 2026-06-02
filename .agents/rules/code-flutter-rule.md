---
trigger: always_on
---

# MIANE Flutter Mobile Frontend Rules
## Riverpod + Firebase Architecture

---

# 1. Design System & Anti-Slop Requirements

## Critical Design Reference

**MANDATORY**

For any UI generation, widget creation, screen implementation, component modification, animation design, or layout structure:

- ALWAYS read and strictly follow definitions from `DESIGN.md` located in the project root.
- NEVER invent:
  - Colors
  - Typography scales
  - Border radius values
  - Component patterns
  - Spacing systems
  - Motion behavior
- NEVER introduce visual styles that contradict `DESIGN.md`.

If a design decision is not explicitly defined, derive it from existing patterns in `DESIGN.md`.

---

## Taste Skill Configuration

### DESIGN_VARIANCE = 8/10

Target style:

- Premium
- Tech-minimalist
- Elegant
- High-end fintech/travel application

Preferred:

- Asymmetric layouts
- Visual hierarchy
- Premium spacing
- Dynamic compositions

Avoid:

- Generic dashboard layouts
- Bootstrap-style grids
- Repetitive card stacks

---

### MOTION_INTENSITY = 7/10

Motion is a first-class design element.

Prefer:

- Spring animations
- Elastic transitions
- 450ms theme morphing
- Smooth state changes
- Natural momentum

Avoid:

- Linear animations
- Abrupt transitions
- Instant state changes

---

### VISUAL_DENSITY = 5/10

Balance spaciousness and information.

Rules:

- Itinerary screens → spacious and breathable
- Ledger/finance screens → denser information display
- Never overcrowd the UI

---

## Anti-Slop Output Requirements

Every generated code response must be:

- Complete
- Production-ready
- Compilation-ready

Never output:

```dart
// TODO
```

```dart
// Implement later
```

```dart
// Placeholder
```

Partial implementations are prohibited.

---

# 2. Core Design Tokens

## Colors

```yaml
colors:
  primary: "#0D2C54"        # Heritage Navy
  secondary: "#4A90E2"      # Luminous Azure
  accentGold: "#F4BD64"     # Sand Gold
  surfaceLight: "#F8F9FA"   # White Smoke
  surfaceDark: "#05101E"    # Deep Abyss
```

### Usage

| Token | Purpose |
|---------|---------|
| Primary | Core structure, navigation, dark surfaces |
| Secondary | Active states, progress, interactions |
| Accent Gold | Premium features, logo, AI highlights only |
| Surface Light | Light mode backgrounds |
| Surface Dark | Dark mode backgrounds |

---

## Typography

```yaml
displayLg:
  fontFamily: Playfair Display
  fontSize: 32
  fontWeight: 700

bodyMd:
  fontFamily: Be Vietnam Pro
  fontSize: 16
  fontWeight: 400

labelSm:
  fontFamily: Be Vietnam Pro
  fontSize: 12
  fontWeight: 500
```

---

## Border Radius

```yaml
rounded:
  lg: 32
```

### Rule

Global corner radius:

```text
32px
```

Avoid:

- Sharp corners
- Small-radius cards
- Mixed-radius designs

---

## Spacing System

```yaml
spacing:
  sm: 8
  md: 16
  lg: 24
  xl: 32
```

Use spacing tokens consistently.

Never hardcode random spacing values.

---

# 3. Architecture & Technology Stack

## State Management

### Riverpod

Preferred:

```dart
@riverpod
class ExampleController extends _$ExampleController
```

Use:

- riverpod_generator
- AsyncNotifier
- Notifier

Avoid:

- Provider package
- Bloc
- GetX
- setState-heavy architecture

---

## Backend Infrastructure

### Firebase

Mandatory integrations:

- Firebase Authentication
- Google OAuth2
- Firebase Cloud Messaging (FCM)
- Firestore Realtime Sync

---

# 4. Feature-First Folder Structure

Every feature inside:

```text
lib/features/{feature_name}/
```

must follow:

```text
lib/features/
└── feature_name/
    ├── data/
    │   ├── datasources/
    │   └── repositories/
    │
    ├── domain/
    │   ├── models/
    │   └── repositories/
    │
    └── presentation/
        ├── controllers/
        ├── screens/
        └── widgets/
```

---

## Data Layer

```text
data/
```

Contains:

### datasources/

- Firebase Remote Sources
- Local Cache Sources

### repositories/

Repository implementations

Example:

```dart
class LedgerRepositoryImpl
    implements LedgerRepository
```

---

## Domain Layer

```text
domain/
```

Contains:

### models/

Use:

- Freezed
- Immutable entities

Example:

```dart
@freezed
class Trip with _$Trip
```

### repositories/

Repository contracts/interfaces only.

---

## Presentation Layer

```text
presentation/
```

Contains:

### controllers/

Riverpod state management

Examples:

```dart
AsyncNotifier
Notifier
StateNotifier
```

### screens/

Full pages:

- Splash
- Onboarding
- Ledger
- Itinerary
- Settings

### widgets/

Feature-scoped reusable widgets.

---

# 5. Shared Infrastructure

Global reusable code belongs in:

```text
lib/core/
```

Examples:

```text
lib/core/theme/
lib/core/network/
lib/core/firebase/
lib/core/widgets/
lib/core/utils/
```

Includes:

- Theme system
- Network clients
- Firebase setup
- VietQR deep-link handlers
- Shared widgets

---

# 6. File System Permissions

## File Creation

ALLOWED

Agent may:

- Create files
- Create folders
- Create models
- Create widgets
- Create repositories

No confirmation required.

---

## File Modification

ALLOWED

Agent may directly modify:

- Existing code
- Themes
- Components
- Features

No confirmation required.

---

## File Deletion

STRICTLY PROHIBITED

Before deleting:

- Any file
- Any folder
- Any asset

Agent MUST request explicit user approval.

Example:

```text
This feature requires deleting:

- old_widget.dart
- legacy_repository.dart

Please confirm before deletion.
```

---

# 7. Automated Validation Pipeline

## Mandatory Post-Modification Validation

After ANY code generation or modification:

Run validation automatically.

User should never need to request validation manually.

---

## Step 1

### Generate Riverpod / Freezed Files

Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Required whenever:

- Freezed models change
- Riverpod generators change
- JSON serialization changes

---

## Step 2

### Static Analysis

Run:

```bash
flutter analyze
```

or

```bash
dart analyze
```

Fix:

- Errors
- Warnings
- Lint issues

before proceeding.

---

## Step 3

### Test Suite

Run:

```bash
flutter test
```

Requirements:

- All tests pass
- No regressions introduced
- No failing widget tests
- No failing unit tests

---

## Failure Handling

If any validation step fails:

1. Read terminal output.
2. Identify root cause.
3. Patch code immediately.
4. Re-run failed command.
5. Repeat until all checks pass.

Never declare completion while:

- build_runner fails
- analyze fails
- tests fail

---

# 8. Completion Criteria

A task is considered complete only when:

- Feature implementation is finished.
- Code is production-ready.
- Riverpod architecture is respected.
- Firebase integration is correct.
- Design system is respected.
- No placeholder code exists.
- Validation pipeline passes.
- Application compiles successfully.

Only then may the task be marked as completed.