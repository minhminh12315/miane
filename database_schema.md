# Cấu Trúc Database MIANE (PostgreSQL)

Hệ thống microservices MIANE sử dụng 4 database riêng biệt chạy trên PostgreSQL để đảm bảo tính độc lập giữa các service, kết hợp mẫu thiết kế **Transactional Outbox** để giao tiếp hướng sự kiện (Event-Driven) bất đồng bộ.

---

## 1. Database: `Miane_identity`
Chịu trách nhiệm quản lý người dùng, tài khoản và phân quyền (ASP.NET Core Identity).

### Bảng: `Users`
Kế thừa từ `IdentityUser<Guid>` và bổ sung các trường nghiệp vụ của MIANE.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID duy nhất của người dùng |
| `FullName` | `text` | Not Null | Họ và tên |
| `AvatarUrl` | `text` | Nullable | Link ảnh đại diện |
| `IsEmployee` | `boolean` | Not Null, Default `false` | Phân biệt nhân viên và khách hàng |
| `EmployeeId` | `text` | Nullable, Unique | Mã số nhân viên (nếu có) |
| `CreateAt` | `timestamp` | Not Null, Default `UTC` | Thời gian tạo tài khoản |
| `IsActive` | `boolean` | Not Null, Default `true` | Trạng thái hoạt động |
| `UserTier` | `integer` | Not Null, Default `0` | Hạng tài khoản: `0` = Basic, `1` = Pro |
| `TripPassTripIds` | `text` | Nullable (JSON Array) | Danh sách Trip ID có vé kích hoạt vượt hạn mức thành viên |
| `Email` | `text` | Unique, Not Null | Email người dùng |
| `NormalizedEmail` | `text` | Nullable | Email đã chuẩn hóa |
| `PasswordHash` | `text` | Nullable | Mật khẩu băm |
| `SecurityStamp` | `text` | Nullable | Token bảo mật của Identity |
| `ConcurrencyStamp` | `text` | Nullable | Token tránh xung đột ghi đồng thời |
| `PhoneNumber` | `text` | Nullable | Số điện thoại |
| `TwoFactorEnabled` | `boolean` | Not Null | Xác thực 2 lớp |
| `LockoutEnd` | `timestamp` | Nullable | Thời gian khóa tài khoản |
| `LockoutEnabled` | `boolean` | Not Null | Bật chế độ khóa tài khoản khi nhập sai |
| `AccessFailedCount` | `integer` | Not Null | Số lần nhập mật khẩu sai liên tiếp |

### Các Bảng ASP.NET Core Identity Khác (Đã đổi tên)
* **`Roles`**: Quản lý các nhóm quyền (Role).
* **`UserRoles`**: Liên kết N-N giữa `Users` và `Roles`.
* **`UserClaims`**: Lưu các Claim chi tiết của người dùng.
* **`UserLogins`**: Lưu thông tin đăng nhập bên thứ 3 (Google, Apple...).
* **`RoleClaims`**: Lưu các Claim gắn với Role.
* **`UserTokens`**: Lưu các Token xác thực (ví dụ OTP, Reset Token).

---

## 2. Database: `Miane_trip`
Chịu trách nhiệm quản lý các chuyến đi (Trips) và thành viên tham gia chuyến đi.

### Bảng: `Trips`
Quản lý thông tin tổng quan hành trình chuyến đi.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID chuyến đi |
| `Name` | `text` | Not Null | Tên chuyến đi |
| `Description` | `text` | Nullable | Mô tả chi tiết chuyến đi |
| `InviteCode` | `text` | Not Null, Unique (8 ký tự) | Mã mời tham gia chuyến đi |
| `BaseCurrency` | `text` | Not Null, Default `"VND"` | Đơn vị tiền tệ cơ sở của chuyến đi |
| `CreatedByUserId` | `uuid` | Not Null | ID người dùng tạo chuyến đi |
| `Status` | `integer` | Not Null, Default `0` | Trạng thái: `0` = Active (Đang đi), `1` = Completed (Đã kết thúc) |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo bản ghi |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật bản ghi |

### Bảng: `TripMembers`
Quản lý danh sách thành viên tham gia chuyến đi và vai trò của họ.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID bản ghi thành viên |
| `TripId` | `uuid` | FK -> `Trips.Id` | ID chuyến đi |
| `UserId` | `uuid` | Not Null | ID người dùng tham gia |
| `Role` | `integer` | Not Null, Default `1` | Vai trò: `0` = Owner (Trưởng nhóm), `1` = Member |
| `JoinedAt` | `timestamp` | Not Null, Default `UTC` | Thời điểm tham gia |
| `NickName` | `text` | Nullable | Biệt danh trong chuyến đi |
| `UserTier` | `integer` | Not Null, Default `0` | Hạng thành viên lúc tham gia |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo bản ghi |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật bản ghi |

---

## 3. Database: `Miane_expense`
Trọng tâm xử lý tài chính, chia hóa đơn, quỹ nhóm (Trip Pool) và đơn giản hóa công nợ.

### Bảng: `Expenses`
Lưu thông tin chi tiết các khoản chi tiêu.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID khoản chi tiêu |
| `TripId` | `uuid` | Index | ID chuyến đi tương ứng |
| `Description` | `varchar(500)` | Not Null | Mô tả khoản chi |
| `Amount` | `numeric(18,4)` | Not Null | Số tiền chi tiêu gốc |
| `Currency` | `varchar(3)` | Not Null | Mã tiền tệ gốc (ví dụ: VND, USD, THB...) |
| `ConvertedAmount`| `numeric(18,4)` | Not Null | Số tiền sau khi quy đổi ra tiền tệ cơ sở |
| `ExchangeRate` | `numeric(18,8)` | Not Null, Default `1.0` | Tỷ giá quy đổi tại thời điểm chi tiêu |
| `PaidByUserId` | `uuid` | Not Null | ID người trả tiền |
| `SplitType` | `integer` | Not Null | Công thức chia: `0` = Equal (Chia đều), `1` = Custom (Chia tùy chọn), `2` = TripPool (Chi từ quỹ nhóm) |
| `IsPaidFromPool` | `boolean` | Not Null | Đánh dấu nếu chi trực tiếp từ quỹ nhóm |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo bản ghi |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật bản ghi |

### Bảng: `ExpenseSplits`
Chi tiết khoản tiền từng người cần chịu cho mỗi hóa đơn.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID bản ghi |
| `ExpenseId` | `uuid` | FK -> `Expenses.Id` (Cascade) | ID khoản chi tiêu |
| `UserId` | `uuid` | Index (cùng `ExpenseId`) | ID người chịu chi phí |
| `Amount` | `numeric(18,4)` | Not Null | Số tiền phải chịu (theo tiền tệ cơ sở) |
| `IsPaid` | `boolean` | Not Null, Default `false` | Trạng thái thanh toán |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

### Bảng: `TripPools`
Quỹ nhóm của chuyến đi dùng để đóng góp và chi tiêu chung.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID quỹ |
| `TripId` | `uuid` | Unique Index | ID chuyến đi |
| `Balance` | `numeric(18,4)` | Not Null, Default `0.0` | Số dư hiện tại của quỹ |
| `Currency` | `varchar(3)` | Not Null, Default `"VND"` | Tiền tệ của quỹ |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

### Bảng: `PoolContributions`
Nhật ký đóng góp tiền vào quỹ nhóm.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID đóng góp |
| `TripPoolId` | `uuid` | FK -> `TripPools.Id` (Cascade) | ID quỹ |
| `UserId` | `uuid` | Not Null | ID người đóng góp |
| `Amount` | `numeric(18,4)` | Not Null | Số tiền đóng góp |
| `ContributedAt` | `timestamp` | Not Null, Default `UTC` | Thời điểm đóng góp |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo bản ghi |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

### Bảng: `DebtRecords`
Bảng lưu các giao dịch nợ đã được tối ưu hóa (Debt Simplification).

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID khoản nợ |
| `TripId` | `uuid` | Index (cùng `IsSettled`) | ID chuyến đi |
| `FromUserId` | `uuid` | Not Null | ID người nợ (con nợ) |
| `ToUserId` | `uuid` | Not Null | ID người nhận thanh toán (chủ nợ) |
| `Amount` | `numeric(18,4)` | Not Null | Số tiền nợ |
| `Currency` | `varchar(3)` | Not Null, Default `"VND"` | Tiền tệ khoản nợ |
| `IsSettled` | `boolean` | Not Null, Default `false` | Đã thanh toán hay chưa |
| `SettledAt` | `timestamp` | Nullable | Thời điểm thanh toán nợ |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

---

## 4. Database: `Miane_notification`
Quản lý đăng ký thiết bị nhận thông báo đẩy FCM (Firebase Cloud Messaging) và lịch sử thông báo.

### Bảng: `DeviceRegistrations`
Đăng ký token thiết bị để gửi thông báo đẩy.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID đăng ký |
| `UserId` | `uuid` | Index | ID người dùng |
| `FcmToken` | `varchar(500)` | Unique, Not Null | Token thiết bị cấp bởi Firebase FCM |
| `DevicePlatform` | `varchar(20)` | Not Null (ios/android/web) | Nền tảng thiết bị |
| `RegisteredAt` | `timestamp` | Not Null, Default `UTC` | Thời điểm đăng ký |
| `IsActive` | `boolean` | Not Null, Default `true` | Trạng thái hoạt động của token |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

### Bảng: `NotificationLogs`
Lịch sử thông báo đã gửi cho người dùng.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID thông báo |
| `UserId` | `uuid` | Index (cùng `IsRead`) | ID người dùng nhận thông báo |
| `Title` | `varchar(200)` | Not Null | Tiêu đề thông báo |
| `Body` | `varchar(1000)`| Not Null | Nội dung thông báo |
| `EventType` | `varchar(100)` | Not Null | Loại sự kiện (ví dụ: `ExpenseCreated`, `DebtSettled`) |
| `SentAt` | `timestamp` | Not Null, Default `UTC` | Thời gian gửi |
| `IsRead` | `boolean` | Not Null, Default `false` | Đã đọc hay chưa |
| `Data` | `text` | Nullable (JSON String) | Dữ liệu đính kèm (Deep link, TripId...) |
| `CreatedAt` | `timestamp` | Not Null | Thời gian tạo |
| `UpdatedAt` | `timestamp` | Nullable | Thời gian cập nhật |

---

## 5. Bảng Dùng Chung Cho Mẫu Thiết Kế Outbox: `OutboxMessages`
Được tự động tích hợp ở lớp cơ sở `BaseDbContext` cho tất cả các database trừ `Miane_identity` để thực hiện gửi Event giao tiếp giữa các service một cách đáng tin cậy.

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `Id` | `uuid` | PK | ID tin nhắn outbox |
| `Type` | `varchar(500)` | Not Null | Tên class Event đầy đủ |
| `Content` | `text` | Not Null | Payload của event dưới dạng JSON |
| `OccurredOn` | `timestamp` | Not Null, Default `UTC` | Thời điểm phát sinh sự kiện |
| `ProcessedOn` | `timestamp` | Nullable, Index (unprocessed filter)| Thời điểm xử lý/gửi event đi thành công |
| `Error` | `text` | Nullable | Chi tiết lỗi nếu gửi thất bại |
| `RetryCount` | `integer` | Not Null, Default `0` | Số lần thử lại |
