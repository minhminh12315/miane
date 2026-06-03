---
description: Create base UI/UX for my app
---

# 📋 MIANE MOBILE APP — UI DEVELOPMENT WORKFLOW (MOCK DATA + RIVERPOD)

## Objective

Triển khai toàn bộ giao diện ứng dụng MIANE bằng dữ liệu giả lập (Hardcoded Mock Data) kết hợp Riverpod State Management nhằm:

* Hoàn thiện 100% UI/UX trước khi Backend hoàn thành.
* Hoàn thiện Navigation Flow đầy đủ.
* Tách biệt UI và Business Logic.
* Đảm bảo khi có API thực tế chỉ cần thay đổi Repository/Provider mà không sửa UI.

---

# Architecture Strategy

## Current Phase

### UI-First Development

Sử dụng:

* Riverpod Notifier / AsyncNotifier
* Hardcoded Mock Data
* Fake Authentication Flow
* Local State Navigation

Backend chưa được kết nối ở giai đoạn này.

---

## Future Phase

### API Integration

Khi Backend hoàn thiện:

1. Thay thế Mock Repository bằng API Repository.
2. Kết nối Firebase Authentication.
3. Kết nối Firestore.
4. Kết nối REST API.
5. Không thay đổi bất kỳ Widget UI nào.

---

# Screen Inventory

Các màn hình phải được xây dựng theo đúng thứ tự dưới đây.

---

## 1. WelcomeFlowScreen

### File

```text
lib/features/auth/presentation/screens/welcome_flow_screen.dart
```

### Purpose

Giới thiệu ứng dụng.

### Mock Components

* Animated timeline
* Animated chart
* Feature highlights
* CTA button

### Required Fix

Opacity animation crash phải được xử lý.

---

## 2. AuthGateScreen

### File

```text
lib/features/auth/presentation/screens/auth_gate_screen.dart
```

### Purpose

Cổng lựa chọn đăng nhập hoặc đăng ký.

### Mock Components

* Google Login Button
* Apple Login Button
* Email Login Button
* Register Button

---

## 3. LoginScreen

### File

```text
lib/features/auth/presentation/screens/login_screen.dart
```

### Purpose

Đăng nhập tài khoản.

### Mock Components

* Email field
* Password field
* Forgot password button
* Login button

---

## 4. RegisterScreen

### File

```text
lib/features/auth/presentation/screens/register_screen.dart
```

### Purpose

Đăng ký tài khoản mới.

### Mock Components

* Full Name
* Email
* Password
* Confirm Password
* Register Button

---

## 5. InitialSetupScreen

### File

```text
lib/features/user_profile/presentation/screens/initial_setup_screen.dart
```

### Purpose

Thiết lập ban đầu sau khi đăng ký.

### Mock Components

#### Currency Selection

* VND
* USD

#### Initial Balance

* Input Amount

#### Continue Button

* Save Setup

---

## 6. MainLayoutScreen

### File

```text
lib/features/home/presentation/screens/main_layout_screen.dart
```

### Purpose

Khung chính của ứng dụng.

### Components

Bottom Navigation Bar:

* Home
* Analytics
* Settings

---

## 7. HomeScreen

### File

```text
lib/features/home/presentation/screens/home_screen.dart
```

### Purpose

Dashboard tài chính.

### Mock Components

#### Account Summary

* Total Balance
* Monthly Income
* Monthly Expense

#### Transaction Timeline

* Recent Transactions
* Mock Ledger Data

---

## 8. AnalyticsScreen

### File

```text
lib/features/analytics/presentation/screens/analytics_screen.dart
```

### Purpose

Báo cáo tài chính.

### Mock Components

#### Expense Pie Chart

* Food
* Shopping
* Travel
* Bills

#### Income Chart

* Monthly Revenue
* Savings Rate

---

# Navigation Workflow

Ứng dụng được điều khiển hoàn toàn bằng Riverpod Auth State.

```text
                   [ APP START ]
                           │
                           ▼
                 AppAuthStatus State
                           │
      ┌────────────────────┼────────────────────┐
      ▼                    ▼                    ▼

 [WELCOME]          [NEEDS SETUP]      [AUTHENTICATED]

      │                    │                    │
      ▼                    ▼                    ▼

WelcomeFlowScreen   InitialSetupScreen   MainLayoutScreen

      │                                      │
      ▼                                      ▼

 AuthGateScreen                        Bottom Navigation

      │                            ┌────────┴────────┐
      ▼                            ▼                 ▼

 LoginScreen                 HomeScreen      AnalyticsScreen

      │
      ▼

 RegisterScreen
```

---

# Step 1 — Fix WelcomeFlowScreen Crash

## Issue

Animation sử dụng:

```dart
Curves.easeOutBack
```

có thể tạo giá trị:

```dart
opacity > 1
```

hoặc

```dart
opacity < 0
```

gây crash.

---

## Required Fix

Thay thế toàn bộ opacity animation bằng:

```dart
opacity: animatedValue.clamp(0.0, 1.0)
```

Ví dụ:

```dart
Opacity(
  opacity: animation.value.clamp(0.0, 1.0),
  child: child,
)
```

---

# Step 2 — Create App Authentication Provider

## File

```text
lib/features/auth/presentation/controllers/app_auth_provider.dart
```

---

## State Definition

```dart
enum AppAuthStatus {
  welcome,
  unauthenticated,
  needsSetup,
  authenticated,
}
```

---

## Riverpod Notifier

```dart
@riverpod
class AppAuth extends _$AppAuth {
  @override
  AppAuthStatus build() {
    return AppAuthStatus.welcome;
  }

  void completeWelcome() {
    state = AppAuthStatus.unauthenticated;
  }

  void loginFake() {
    state = AppAuthStatus.authenticated;
  }

  void registerFake() {
    state = AppAuthStatus.needsSetup;
  }

  void completeSetup() {
    state = AppAuthStatus.authenticated;
  }

  void logout() {
    state = AppAuthStatus.unauthenticated;
  }
}
```

---

# Step 3 — Configure Root Navigation

## File

```text
lib/main.dart
```

---

## Responsibilities

Root application phải lắng nghe:

```dart
appAuthProvider
```

và quyết định màn hình hiển thị.

---

## State Mapping

| Auth State      | Screen             |
| --------------- | ------------------ |
| welcome         | WelcomeFlowScreen  |
| unauthenticated | AuthGateScreen     |
| needsSetup      | InitialSetupScreen |
| authenticated   | MainLayoutScreen   |

---

## Navigation Logic

```dart
switch (status) {
  case AppAuthStatus.welcome:
    return const WelcomeFlowScreen();

  case AppAuthStatus.unauthenticated:
    return const AuthGateScreen();

  case AppAuthStatus.needsSetup:
    return const InitialSetupScreen();

  case AppAuthStatus.authenticated:
    return const MainLayoutScreen();
}
```

---

# Step 4 — Wire Mock Actions

## Welcome Screen

```dart
ref
    .read(appAuthProvider.notifier)
    .completeWelcome();
```

---

## Login Screen

```dart
ref
    .read(appAuthProvider.notifier)
    .loginFake();
```

---

## Register Screen

```dart
ref
    .read(appAuthProvider.notifier)
    .registerFake();
```

---

## Setup Screen

```dart
ref
    .read(appAuthProvider.notifier)
    .completeSetup();
```

---

## Logout Button

```dart
ref
    .read(appAuthProvider.notifier)
    .logout();
```

---

# Mock Data Strategy

## Rule

Không gọi API.

Không kết nối Firebase.

Không kết nối Firestore.

---

## Data Source

Tạo dữ liệu cứng bên trong:

```text
lib/features/*/data/mock/
```

Ví dụ:

```text
mock_transactions.dart
mock_analytics.dart
mock_user.dart
```

---

## Example Transaction

```dart
const transactions = [
  Transaction(
    title: 'Coffee',
    amount: -45000,
  ),
  Transaction(
    title: 'Salary',
    amount: 15000000,
  ),
];
```

---

# Future API Integration Plan

Sau khi Backend hoàn thành.

---

## Phase 1 — Model Layer

Tạo:

```dart
@freezed
class UserModel
```

và

```dart
@freezed
class TransactionModel
```

sử dụng:

* Freezed
* JsonSerializable

---

## Phase 2 — Repository Layer

Triển khai:

```text
AuthRepository
UserRepository
TransactionRepository
AnalyticsRepository
```

Sử dụng:

```text
Firebase Auth
Firestore
REST API
```

---

## Phase 3 — State Layer Migration

Chuyển từ:

```dart
Notifier<AppAuthStatus>
```

sang:

```dart
AsyncNotifier<AppAuthState>
```

hoặc:

```dart
FutureProvider
```

---

## Phase 4 — Production Authentication Flow

```text
Firebase Login
        │
        ▼

Check User Profile

        │
        ▼

Needs Setup ?
   │
 ┌─┴─┐

YES  NO
 │    │

 ▼    ▼

Setup  Dashboard
```

---

# Success Criteria

Implementation được xem là hoàn thành khi:

* WelcomeFlowScreen không còn crash opacity.
* AppAuth Provider hoạt động.
* Main.dart điều hướng bằng Riverpod State.
* Toàn bộ 8 màn hình tồn tại.
* Navigation Flow hoàn chỉnh.
* Tất cả dữ liệu hiển thị bằng Mock Data.
* Không có TODO hoặc Placeholder.
* UI sẵn sàng cho việc tích hợp Backend sau này.
* Không cần thay đổi UI khi chuyển sang API thực tế.
