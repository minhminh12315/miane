# MIANE — Feature Backlog (Monetization & Attractiveness)

> **Mục đích file:** Tài liệu nguồn sự thật cho agent/dev khi mở rộng sản phẩm theo hướng **hấp dẫn người dùng VN** và **kiếm tiền thực tiễn**.  
> Đọc file này trước khi implement feature mới liên quan monetization, travel booking, hoặc bản đồ chuyến đi.  
> **Ngày cập nhật:** 2026-07-27  
> **Phạm vi:** Product backlog + spec kỹ thuật định hướng (chưa phải SRS chính thức). Khi implement chi tiết, agent phải đối chiếu code hiện tại và cập nhật lại mục “Trạng thái” của từng feature.

---

## 0. Cách dùng file này (cho agent) 

1. Đọc mục **1–3** để nắm positioning & model tiền.
2. Chọn feature theo **Priority** (P0 → P1 → P2 → P3). Không nhảy P3 khi P0 chưa xong trừ khi user yêu cầu rõ.
3. Mỗi feature có: `ID`, mục tiêu, user story, acceptance criteria, touchpoints code, gating VIP/Trip Pass, phụ thuộc, ghi chú kỹ thuật.
4. Phần **CUSTOMIZE** (mục 6–7) là đặc tả sâu cho **chuyến bay / khách sạn / Google Maps** — khi làm phải đọc hết mục đó.
5. Sau khi ship: cập nhật cột **Trạng thái** (`todo` | `in_progress` | `done` | `blocked`) và link PR/commit nếu có.
6. Không commit secrets (API key Booking/Traveloka/Google) vào repo; dùng env / secret store.

### Liên quan trong repo

| Tài liệu / code | Đường dẫn |
|---|---|
| Vision Free vs Pro | `Bản mô tả dự án MIANE - Quản lý chi tiêu và lên kế hoạch du lịch.md` |
| SRS | `SRS.md`, `SRS_vi.md` |
| Expense / wallet / payment SDS | `SDS_EXPENSE_WALLET_PAYMENT.md` (và bản `_vi`) |
| Agent rules | `.agents/rules/miane.md` |
| Trip entities đã có sẵn | `src/Services/Trip/Trip.API/Domain/Entities/` — đặc biệt `TripBooking`, `TripLocation`, `TripLeg`, `TripActivity` |
| Trip workspace UI | `src/Clients/mobile/lib/features/home/presentation/screens/trip_workspace_screen.dart` |
| IAP / VIP | `src/Clients/mobile/lib/features/subscription/` |
| Identity tier | `Users.UserTier`, `Users.TripPassTripIds` |

---

## 1. Positioning sản phẩm (để không làm sai hướng)

### 1.1 Không phải

- “Một Splitwise khác” thuần chia tiền (thị trường khó monetize: Tricount gần như free; Splitwise Pro bị phản cảm).

### 1.2 Phải là

**OS chuyến đi nhóm cho người Việt:** lịch trình + quỹ/chi tiêu + quyết toán VietQR + (mới) **đặt vé/khách sạn + bản đồ hành trình**.

Thông điệp: *Một app cho cả chuyến — không cần Excel / Zalo / 5 tab trình duyệt.*

### 1.3 Đối tượng trả tiền chính

| Persona | Nhu cầu | Sẵn sàng trả |
|---|---|---|
| Organizer (trưởng nhóm) | Nhóm đông, chốt sổ, đỡ loạn | **Trip Pass / VIP** |
| Người đi thường xuyên | Nhiều trip/năm, AI, export | **VIP tháng/năm** |
| Thành viên occasional | Chỉ xem nợ, quét QR trả | Free / guest |

---

## 2. Model monetization mục tiêu

| Gói | Giá gợi ý (VND) | Quyền lợi cốt lõi |
|---|---|---|
| **Basic** | 0 | ≤2 trip active, ≤7 thành viên/trip, split cơ bản, VietQR, lịch trình thủ công, map xem cơ bản |
| **Trip Pass** | 29.000–49.000 / chuyến | Mở khóa giới hạn thành viên **cho 1 trip**; có thể kèm 1–2 quyền AI tạm thời |
| **VIP (MIANE VIP)** | ~99.000 / tháng hoặc ~699.000 / năm | Unlimited trips/members, AI OCR/planner, export PDF/Excel, map nâng cao, affiliate/search flight-hotel không giới hạn |
| **Affiliate** (song song) | Hoa hồng Booking/Traveloka | Deep link / search → book ngoài hoặc in-app; không thay subscription |

### Nguyên tắc gating (quan trọng)

- **Không khóa ngược** quỹ nhóm / VietQR / split cơ bản đã có trên free (gây churn).
- Khóa theo: **số lượng** (trip, member), **AI usage**, **export**, **search booking quota**, **map layers nâng cao**, **offline không giới hạn**.
- Prefer **organizer trả tiền** hơn “mỗi thành viên 1 VIP”.

### Trạng thái monetization hiện tại (2026-07)

| Hạng mục | Trạng thái |
|---|---|
| Enforce 2 trips / 7 members | Đã có (server) |
| IAP Flutter + `upgrade-pro` | Demo; receipt verify **stub**; SKU `com.example.*` |
| Trip Pass commerce | Schema field có; **chưa bán / chưa enforce cross-service** |
| Ads | Không có |
| Affiliate booking | Không có |

---

## 3. Ma trận ưu tiên tổng quan

| Priority | Theme | Vì sao |
|---|---|---|
| **P0** | Thu tiền + giữ chân tối thiểu | Không có thì không make money / không retention |
| **P1** | Core loop “không thể thiếu khi đi nhóm” | Viral + daily open trong chuyến |
| **P2** | Customize travel: flight/hotel + Google Maps | Differentiator + affiliate revenue + wow |
| **P3** | Nice-to-have / chi phí cao | Chỉ sau khi P0–P2 ổn định |

---

## 4. Backlog chi tiết theo feature

### Legend trạng thái

`todo` | `in_progress` | `done` | `blocked`

---

### P0 — Monetization plumbing & retention tối thiểu

#### FEAT-P0-01 — Production IAP + verify receipt

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Bán VIP thật trên App Store / Play |
| **User story** | Là organizer, tôi nâng cấp VIP và quyền lợi kích hoạt ngay sau thanh toán thành công |
| **Acceptance criteria** | (1) Product ID production (không còn `com.example.*`). (2) Backend verify App Store Server API / Google Play Developer API. (3) Set `UserTier=1`, re-issue JWT. (4) Restore purchases. (5) Xử lý expired / refund → downgrade. |
| **Touchpoints** | `iap_service.dart`, `pro_upgrade_controller.dart`, `AuthController.UpgradeToPro`, `AuthService.UpgradeToProAsync` |
| **Gating** | N/A (nền tảng) |
| **Deps** | Apple/Google developer accounts, shared secret / service account |
| **Ghi chú** | Dev mode có thể skip verify; production **bắt buộc** verify. Không tin client. |

#### FEAT-P0-02 — Trip Pass (one-shot unlock theo chuyến)

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Convert nhóm đông 1 lần mà không cần VIP tháng |
| **User story** | Trip của tôi chạm 7 người; tôi mua Trip Pass ~39k để mời thêm bạn **chỉ cho chuyến này** |
| **Acceptance criteria** | (1) IAP consumable/non-sub product `trip_pass`. (2) Ghi `TripPassTripIds` (hoặc bảng `TripPasses`). (3) `JoinTripHandler` tôn trọng pass của **owner**. (4) Paywall khi join fail vì cap. (5) UI Settings/Trip hiển thị “Đã mở khóa Trip Pass”. |
| **Touchpoints** | `JoinTripHandler.cs`, `User.TripPassTripIds`, subscription UI, notification limit upsell |
| **Gating** | Basic → Pass |
| **Deps** | FEAT-P0-01 (hoặc thanh toán VN tạm: SePay/PayOS nếu web) |
| **Estimate** | M |

#### FEAT-P0-03 — Push notifications (FCM / APNs)

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Reminder nợ + lịch → mở app lại |
| **User story** | Tôi nhận push “Bạn nợ An 150.000đ — quét VietQR” và “Ngày mai 08:00 check-in KS” |
| **Acceptance criteria** | (1) Đăng ký device token. (2) Push: expense mới, nhắc nợ, fund request, sắp tới activity/booking. (3) Deep link vào đúng màn hình. (4) User tắt/bật theo loại. |
| **Touchpoints** | Notification.API (hiện in-app), mobile notification settings |
| **Gating** | Free cơ bản; VIP có thể có reminder thông minh hơn |
| **Deps** | Firebase/APNs setup |
| **Estimate** | L |

#### FEAT-P0-04 — Guest / soft join (giảm ma sát viral)

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Thành viên xem nợ + trả QR không bắt buộc full account ngay |
| **User story** | Tôi mở link mời, xem “tôi nợ bao nhiêu”, quét VietQR, không phải đăng ký dài |
| **Acceptance criteria** | (1) Magic link / OTP nhẹ. (2) Guest read-only balances + VietQR. (3) Thêm expense / sửa lịch cần account. (4) Rate-limit & abuse protection. |
| **Touchpoints** | `TripShareLink`, `TripInvitation`, auth gate |
| **Gating** | Free (growth) |
| **Estimate** | L |

#### FEAT-P0-05 — Paywall UX nhất quán + entitlement middleware

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Mọi Pro claim đều enforce server-side |
| **Acceptance criteria** | (1) Middleware/handler check `X-User-Tier` + Trip Pass. (2) UI badge VIP thống nhất. (3) Analytics/OCR/AI không lách bằng client. (4) Error code ổn định: `TIER_LIMIT_EXCEEDED`, `VIP_REQUIRED`, `TRIP_PASS_REQUIRED`. |
| **Touchpoints** | Gateway headers, Trip/Expense handlers, `ios_ui.dart` paywall sheet |
| **Estimate** | M |

---

### P1 — Core loop nhóm trong chuyến

#### FEAT-P1-01 — Deep link thanh toán + confirm đã nhận

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Trả nợ 1–2 chạm; chốt sổ không tranh cãi |
| **Acceptance criteria** | (1) Mở app NH/MoMo với STK/số tiền/memo sẵn. (2) Người nhận bấm “Đã nhận”. (3) Memo unique `MIANE_xxxxx`. (4) Sau này mới webhook auto-reconcile. |
| **Touchpoints** | `VietQrController`, PaymentMethods, Debts settle flow, SDS payment |
| **Gating** | Free; VIP: lịch sử + nhắc tự động |
| **Estimate** | L |

#### FEAT-P1-02 — Auto-reconcile (phase 2 của P1-01)

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Khớp giao dịch theo memo → auto “Đã thanh toán” |
| **Acceptance criteria** | Webhook/provider adapter; idempotent; audit log; không double-settle |
| **Deps** | FEAT-P1-01, partner banking/Open API nếu có |
| **Estimate** | XL — có thể `blocked` theo pháp lý/partner |

#### FEAT-P1-03 — OCR hóa đơn VN (iOS + Android) + item split

| | |
|---|---|
| **Trạng thái** | `todo` (iOS on-device partial) |
| **Mục tiêu** | Quán ăn đông người — nhập chi nhanh, đáng tiền VIP |
| **Acceptance criteria** | (1) Scan → amount, merchant, date, line items gợi ý. (2) Review trước khi save. (3) Quota Basic (vd 3/tháng), VIP unlimited. (4) Server OCR hoặc hybrid (không chỉ Vision iOS). |
| **Touchpoints** | `scan_bill_screen.dart`, `vn_receipt_parser.dart`, `services/ai-image/` (mở rộng OCR) |
| **Gating** | VIP / quota |
| **Estimate** | L |

#### FEAT-P1-04 — Trip Checklist chung

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Engagement trước chuyến; rẻ để làm |
| **Acceptance criteria** | Checklist items, assign member, check-off realtime/sync, template “Đi biển / Đà Lạt” |
| **Gating** | Free |
| **Estimate** | S–M |

#### FEAT-P1-05 — Poll / vote trong trip

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Giảm spam Zalo; quyết định nhóm trong app |
| **Acceptance criteria** | Tạo poll (chỗ ăn, giờ đi), vote 1 lần/user, đóng poll, pin kết quả vào itinerary |
| **Gating** | Free; VIP: poll không giới hạn / gắn booking |
| **Estimate** | M |

#### FEAT-P1-06 — Export Excel / PDF báo cáo chi tiêu

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Organizer “chốt sổ” — lý do VIP rõ |
| **Acceptance criteria** | Export theo trip: expenses, balances, settlements; PDF đẹp + CSV/XLSX |
| **Gating** | **VIP** |
| **Estimate** | M |

#### FEAT-P1-07 — AI Trip Planner MVP

| | |
|---|---|
| **Trạng thái** | `todo` (spec có, API planner chưa) |
| **Mục tiêu** | Differentiator Pro; input điểm đến/ngày/ngân sách/gu → lịch + ước chi |
| **Acceptance criteria** | (1) Endpoint FastAPI `/api/planner/suggest`. (2) Ghi vào `TripPlan` / `TripActivity`. (3) User edit được. (4) Cost control + VIP gate. |
| **Touchpoints** | `services/ai-image/` → tách/đổi tên service AI; Trip.API plans |
| **Gating** | VIP (Basic: 1 lần thử / watermark) |
| **Estimate** | XL |

#### FEAT-P1-08 — Budget alert

| | |
|---|---|
| **Trạng thái** | `todo` |
| **Mục tiêu** | Cảnh báo khi nhóm vượt % ngân sách |
| **Acceptance criteria** | Set budget trip; threshold 80%/100%; in-app + push; gợi ý cắt chi (optional AI) |
| **Gating** | Free alert đơn giản; VIP gợi ý thông minh |
| **Deps** | FEAT-P0-03 |
| **Estimate** | M |

---

### P2 — CUSTOMIZE: Booking + Maps (chi tiết ở mục 6–7)

| ID | Tên ngắn | Trạng thái |
|---|---|---|
| **FEAT-P2-01** | Trip Map (Google Maps) — layers điểm/đường bay/KS | `todo` |
| **FEAT-P2-02** | Manual booking objects (flight/hotel) gắn map + chi tiêu | `todo` |
| **FEAT-P2-03** | Affiliate deep-link Booking.com | `todo` |
| **FEAT-P2-04** | Affiliate / Partners Traveloka | `todo` |
| **FEAT-P2-05** | In-app search hotel/flight (Demand API / TPN) — phase sau | `todo` |
| **FEAT-P2-06** | Sync booking → expense + calendar reminders | `todo` |

Xem **mục 6 và 7** cho spec đầy đủ.

---

### P3 — Nice-to-have / chi phí cao

| ID | Feature | Ghi chú | Trạng thái |
|---|---|---|---|
| FEAT-P3-01 | Shared cloud album không giới hạn | Storage đắt; convert yếu hơn OCR | `todo` |
| FEAT-P3-02 | Offline sync không giới hạn | VIP perk; conflict resolution phức tạp | `todo` |
| FEAT-P3-03 | Live multi-currency FX | Ít nhu cầu nội địa; làm khi có user quốc tế | `todo` |
| FEAT-P3-04 | Ads trên Basic | Chỉ khi DAU lớn; rủi ro brand | `todo` |
| FEAT-P3-05 | Google/Apple Calendar sync | Pro perk trong vision | `todo` |
| FEAT-P3-06 | VIP Organizer (1 người trả, cả trip hưởng AI) | Packaging nâng cao | `todo` |
| FEAT-P3-07 | Car rental / activities via Booking Demand API | Sau khi hotel/flight ổn | `todo` |

---

## 5. Roadmap 90 ngày (gợi ý thực thi)

### Tháng 1 — Chốt sổ & thu tiền
1. FEAT-P0-01 IAP production  
2. FEAT-P0-02 Trip Pass  
3. FEAT-P0-05 Entitlement middleware  
4. FEAT-P0-03 Push (MVP: nợ + join)  
5. FEAT-P2-02 Manual flight/hotel booking (không cần partner API trước)

### Tháng 2 — Trong chuyến không thể thiếu
6. FEAT-P1-01 Deep link + confirm nhận  
7. FEAT-P1-03 OCR 2 platform + quota  
8. FEAT-P1-04 Checklist  
9. FEAT-P2-01 Google Maps trip layers (đọc từ booking/location/leg)  
10. FEAT-P0-04 Guest join (nếu bandwidth)

### Tháng 3 — Wow + doanh thu phụ
11. FEAT-P2-03 / P2-04 Affiliate links Booking + Traveloka  
12. FEAT-P1-07 AI Planner MVP  
13. FEAT-P1-06 Export PDF/Excel  
14. FEAT-P2-06 Booking → expense auto  
15. Chuẩn bị hồ sơ partner Demand API / TPN (FEAT-P2-05)

---

## 6. CUSTOMIZE — Chuyến bay & Khách sạn (Traveloka / Booking)

### 6.1 Mục tiêu sản phẩm

Trong tab **Lịch trình** (hoặc section mới **Đặt chỗ** của trip workspace), user có thể:

1. **Thêm thủ công** vé máy bay / khách sạn (confirmation, giờ, địa điểm).  
2. **Tìm & mở** kết quả trên Traveloka hoặc Booking (affiliate).  
3. (Phase sau) **Search in-app** qua API partner, rồi redirect hoặc book.  
4. Mọi booking gắn **bản đồ** + optional **khoản chi** trong Expense.

### 6.2 Hiện trạng code (tận dụng, đừng tạo trùng)

Entity đã có:

```text
TripBooking
  TripId, Type ("Hotel" mặc định), Title, ConfirmationNumber,
  StartsAt, EndsAt, LocationName, Status, AttachmentUrl, Notes
```

**Thiếu so với nhu cầu map + flight/hotel đầy đủ** (đề xuất mở rộng — migration mới):

| Field đề xuất | Kiểu | Mục đích |
|---|---|---|
| `Provider` | string | `manual` \| `booking` \| `traveloka` \| `other` |
| `ExternalId` | string? | ID inventory/order phía partner |
| `AffiliateUrl` | string? | Deep link attribution |
| `IataFrom` / `IataTo` | string? | Flight |
| `AirlineCode` / `FlightNumber` | string? | Flight |
| `Lat` / `Lng` | decimal? | Pin map (KS / sân bay) |
| `LatTo` / `LngTo` | decimal? | Đích bay / checkout |
| `Address` | string? | KS |
| `PriceAmount` / `Currency` | decimal?/string | Hiển thị + seed expense |
| `ExpenseId` | guid? | Link Expense.API (cross-service id lưu bên Trip hoặc outbox) |
| `RawPayloadJson` | jsonb? | Cache response partner (redact PII) |
| `LegId` | guid? | Gắn `TripLeg` |

`Type` enum chuẩn hóa: `Hotel` | `Flight` | `Transport` | `Activity` | `Other`.

Controllers/UI: hiện cần xác nhận có CRUD `TripBooking` exposed chưa — agent implement phải grep `TripBooking` / `BookingsController` trước khi code.

### 6.3 Chiến lược tích hợp 3 tầng (bắt buộc làm theo thứ tự)

```text
Tầng A — Manual booking          → ship ngay (không phụ thuộc partner)
Tầng B — Affiliate deep link      → doanh thu sớm, legal nhẹ hơn
Tầng C — Full API search/book     → cần hợp đồng Managed Affiliate / TPN
```

**Không** bắt đầu bằng Tầng C nếu chưa có credentials partner.

---

### 6.4 Tầng A — Manual Flight / Hotel (FEAT-P2-02)

#### User stories

- Là planner, tôi thêm chuyến bay `VN123 HAN→DAD 07:00–08:20`, confirmation `ABC123`, để cả nhóm thấy trên lịch + map.  
- Là planner, tôi thêm khách sạn “Muong Thanh Đà Nẵng”, check-in/out, địa chỉ; map hiện pin KS.  
- Tôi bấm “Tạo khoản chi từ booking” → expense gợi ý số tiền + split.

#### Acceptance criteria

1. CRUD booking trong trip (role Planner/Owner/Admin).  
2. Form Flight vs Hotel khác field.  
3. Upload/đính kèm ảnh vé / PDF confirmation (`AttachmentUrl`).  
4. Hiển thị trên timeline lịch trình theo `StartsAt`.  
5. Có tọa độ (geocode từ địa chỉ hoặc chọn trên map) → FEAT-P2-01.  
6. Optional tạo expense draft.  
7. Status: `Planned` | `Confirmed` | `Cancelled` | `Completed`.

#### API đề xuất (Trip.API)

```http
GET    /trips/{tripId}/bookings
POST   /trips/{tripId}/bookings
GET    /trips/{tripId}/bookings/{bookingId}
PUT    /trips/{tripId}/bookings/{bookingId}
DELETE /trips/{tripId}/bookings/{bookingId}
POST   /trips/{tripId}/bookings/{bookingId}/create-expense  # gọi/emit sang Expense
```

#### Flutter UI

- Entry: Trip workspace → tab Lịch trình → FAB “Thêm đặt chỗ” hoặc section **Bay & Ở**.  
- Bottom sheet: chọn loại → form.  
- Card booking: icon máy bay/KS, giờ, status, “Xem trên map”.

#### Gating

- Basic: ≤5 bookings / trip.  
- VIP / Trip Pass: unlimited.

---

### 6.5 Tầng B — Affiliate deep link (FEAT-P2-03, FEAT-P2-04)

#### Ý tưởng UX

Trong trip đã có `DestinationCity` / leg:

1. User chọn **Tìm khách sạn** hoặc **Tìm vé máy bay**.  
2. App prefill: city, check-in/out từ leg dates, số khách = số member (hoặc input).  
3. Mở **Custom Tabs / Safari View / external browser** tới URL affiliate có `aid` / partner param.  
4. Sau khi book xong (ngoài app), user **import thủ công** confirmation (Tầng A) hoặc “Tôi đã đặt” + dán mã.

#### Booking.com

| | |
|---|---|
| **Partner program** | Booking.com Affiliate / Demand (deep link trước) |
| **Docs** | https://developers.booking.com/demand — full API cần Managed Affiliate |
| **Tầng B** | Deep link search hotels theo dest + dates; gắn `aid` / label tracking |
| **Tầng C** | Demand API: `/accommodations/search`, orders preview/create — **cần duyệt partner** |
| **Doanh thu** | Commission theo booking hoàn thành |
| **Ghi chú VN** | Inventory mạnh quốc tế + VN; UI tiếng Việt vẫn deep link được |

**URL builder (ví dụ — agent phải dùng format affiliate chính thức khi có aid):**

- Prefill destination, `checkin`, `checkout`, `group_adults`, `label=miane_trip_{tripId}`.

#### Traveloka

| | |
|---|---|
| **Partner** | Traveloka Partners Network (TPN) — https://www.travelokapartnersnetwork.com/ |
| **Liên hệ** | partnersnetwork@traveloka.com (theo site TPN) |
| **Models** | Direct API / Webview redirect / Agent web — **redirect/webview phù hợp MVP** |
| **Điểm mạnh** | Inventory Đông Nam Á, bay nội địa VN, UX quen user VN |
| **Tầng B** | Deep link hoặc WebView search flight/hotel với attribution |
| **Tầng C** | API sau NDA + credentials từ Traveloka |

**Khuyến nghị sản phẩm:**  
- User VN nội địa → ưu tiên CTA **Traveloka** cho bay.  
- KS quốc tế / đa quốc gia → CTA **Booking.com**.  
- UI: “Tìm trên Traveloka” / “Tìm trên Booking” cạnh nhau, không lock 1 provider.

#### Acceptance criteria Tầng B

1. Từ trip/leg → mở search prefilled.  
2. Attribution param chứa `tripId` (và `userId` hashed nếu policy cho phép).  
3. Sau khi quay lại app: prompt “Thêm booking thủ công?”.  
4. Settings: bật/tắt gợi ý affiliate.  
5. Không scrape HTML Traveloka/Booking — **chỉ** official partner link/API.  
6. Logging affiliate click (analytics) để đo conversion.

#### Gating & money

- Free: N click/tháng (vd 10).  
- VIP: unlimited search CTA.  
- Doanh thu chính: **commission**, không phải phí user.

#### Legal / compliance (agent phải tuân thủ)

- Không giả mạo là OTA.  
- Disclose “Liên kết đối tác — MIANE có thể nhận hoa hồng”.  
- Không lưu thẻ tín dụng user trên MIANE ở Tầng B.  
- Privacy policy cập nhật share data với partner khi vào Tầng C.

---

### 6.6 Tầng C — In-app Search API (FEAT-P2-05) — phase sau

#### Kiến trúc đề xuất

```text
Flutter
  → Web.Gateway
    → Trip.API (orchestration, auth, quota)
      → connectors/
          BookingDemandConnector
          TravelokaTpnConnector
      → normalize → DTO chung HotelOffer / FlightOffer
  → User chọn offer
      → redirect checkout partner  HOẶC  orders/create (nếu được phép)
  → lưu TripBooking + RawPayloadJson (redacted)
```

**Không** gọi partner API trực tiếp từ mobile (lộ token). Luôn qua backend.

#### DTO chung (normalize)

```csharp
// Pseudo — implement trong Trip.API Application layer
public sealed record HotelOfferDto(
    string Provider,          // booking | traveloka
    string ExternalId,
    string Name,
    decimal? Lat,
    decimal? Lng,
    string? Address,
    decimal Price,
    string Currency,
    double? StarRating,
    string DeepLinkOrToken,
    DateOnly CheckIn,
    DateOnly CheckOut);

public sealed record FlightOfferDto(
    string Provider,
    string ExternalId,
    string AirlineCode,
    string FlightNumber,
    string IataFrom,
    string IataTo,
    DateTime DepartureUtc,
    DateTime ArrivalUtc,
    decimal Price,
    string Currency,
    string DeepLinkOrToken);
```

#### Quota & caching

- Cache search key `(dest, dates, pax, provider)` Redis TTL ngắn (5–15 phút).  
- Rate limit per user/tier.  
- Circuit breaker khi partner down → fallback deep link Tầng B.

#### Acceptance criteria Tầng C

1. Search hotel/flight in-app, list + filter giá.  
2. Tap → chi tiết → “Đặt trên {Provider}” (redirect) hoặc book in-flow nếu contract cho phép.  
3. Sau book thành công (webhook/order details): tạo `TripBooking` Confirmed + pin map.  
4. VIP unlimited; Basic giới hạn search/ngày.  
5. Không có credentials → feature flag OFF, UI chỉ hiện Tầng B.

#### Blockers thực tế

| Blocker | Hành động |
|---|---|
| Chưa là Managed Affiliate Booking | Đăng ký affiliate; dùng deep link trước |
| Chưa NDA Traveloka TPN | Email partner; WebView redirect trước |
| PCI / payment in-app | Tránh nhận card trên MIANE; để partner checkout |

---

### 6.7 Đồng bộ booking → chi tiêu & nhắc (FEAT-P2-06)

1. Khi `PriceAmount` có → “Tạo expense” prefill category `Flight`/`Hotel`, paidBy = creator, split Equal mặc định.  
2. Push trước `StartsAt` (24h / 3h) — deps FEAT-P0-03.  
3. Nếu hủy booking → gợi ý hủy/sửa expense liên quan (không auto xóa tiền đã settle).

---

## 7. CUSTOMIZE — Google Maps trong chuyến đi (FEAT-P2-01)

### 7.1 Mục tiêu UX

Trong trip workspace, thêm bề mặt **Bản đồ** (tab mới hoặc toggle trên Lịch trình) hiển thị:

| Layer | Nguồn dữ liệu | Hiển thị |
|---|---|---|
| **Chặng / thành phố** | `TripLeg` (lat/lng) | Marker city + label thứ tự |
| **Đường bay** | `TripBooking` Type=Flight | **Polyline geodesic** sân bay đi → đến (hoặc tọa độ IATA) |
| **Khách sạn** | `TripBooking` Type=Hotel | Marker icon KS |
| **Điểm tham quan / activity** | `TripLocation`, `TripActivity` | Marker theo category |
| **Route ngày** | Activities trong 1 ngày sort theo giờ | Polyline đường bộ (Directions API — optional phase 2) |
| **Member check-in** (P3) | realtime location opt-in | Không làm ở MVP map |

### 7.2 Hiện trạng

- Flutter: **chưa** có `google_maps_flutter` trong `pubspec.yaml` (đã kiểm tra 2026-07).  
- Backend: `TripLocation`, `TripLeg`, `TripActivity` **đã có lat/lng**.  
- `TripBooking` **chưa có** lat/lng — cần migration (mục 6.2).

### 7.3 Phụ thuộc Google Cloud

| API | Dùng cho | Ghi chú |
|---|---|---|
| **Maps SDK for Android/iOS** | Render map | Restrict API key by bundle / SHA |
| **Maps JavaScript** | Chỉ nếu có web client | Optional |
| **Geocoding API** | Địa chỉ KS → lat/lng | Gọi từ **backend** để giữ key |
| **Places API** (optional) | Autocomplete điểm đến | VIP quota |
| **Directions API** (optional phase 2) | Đường đi trong ngày | Cost cao — gate VIP |
| **Aerial / static** | Không cần MVP | — |

**Bắt buộc:** API key restriction; không embed unrestricted key trong client repo public. Dùng key mobile riêng + backend proxy cho Geocoding/Places.

### 7.4 Flutter packages đề xuất

```yaml
google_maps_flutter: # map
# optional:
# google_maps_flutter_ios / android config per platform docs
```

Platform setup:

- iOS: AppDelegate / Info.plist `GMSServices` API key.  
- Android: `AndroidManifest.xml` `com.google.android.geo.API_KEY`.  
- Document trong `GOOGLE_MAPS_SETUP.md` (tạo khi implement).

### 7.5 API backend phục vụ map

```http
GET /trips/{tripId}/map
```

Response đề xuất:

```json
{
  "tripId": "...",
  "bounds": { "sw": { "lat": 0, "lng": 0 }, "ne": { "lat": 0, "lng": 0 } },
  "legs": [
    { "id": "...", "order": 0, "name": "Đà Nẵng", "lat": 16.05, "lng": 108.2 }
  ],
  "markers": [
    {
      "id": "...",
      "kind": "hotel",
      "title": "Muong Thanh",
      "lat": 16.06,
      "lng": 108.22,
      "bookingId": "...",
      "startsAt": "..."
    },
    {
      "id": "...",
      "kind": "activity",
      "title": "Bà Nà",
      "lat": 15.99,
      "lng": 107.99,
      "activityId": "..."
    }
  ],
  "flightPaths": [
    {
      "bookingId": "...",
      "title": "VN123 HAN→DAD",
      "from": { "lat": 21.22, "lng": 105.8, "iata": "HAN" },
      "to": { "lat": 16.04, "lng": 108.2, "iata": "DAD" }
    }
  ]
}
```

**Airport coordinates:** bảng tĩnh IATA phổ biến VN/Asia trong Trip.API (`AirportCoords`) hoặc geocode 1 lần cache Redis; không hardcode chỉ 2 sân bay.

### 7.6 UI / UX chi tiết

#### MVP (ship trước)

1. Full-bleed map trong trip (không card nhỏ vô nghĩa).  
2. Fit bounds tất cả markers + flight endpoints.  
3. Toggle layers: Bay | Khách sạn | Lịch trình | Chặng.  
4. Tap marker → bottom sheet: tên, giờ, “Mở chi tiết” / “Chỉ đường” (mở Google Maps app bên ngoài).  
5. Empty state: “Thêm chân chuyến hoặc khách sạn để xem bản đồ”.  
6. Dark/light theo theme app (map style JSON nhẹ — tránh purple glow).

#### Phase 2

1. Directions polyline theo thứ tự activity trong **một ngày**.  
2. Timeline scrubber: kéo ngày → highlight markers ngày đó.  
3. “Thêm điểm từ map” long-press → tạo `TripLocation` / activity.  
4. Cluster markers khi zoom out.

### 7.7 Acceptance criteria FEAT-P2-01

1. Map hiển thị được trên iOS + Android với key cấu hình qua env.  
2. Hotel booking có lat/lng hiện marker.  
3. Flight booking hiện đường bay geodesic từ–đến.  
4. Legs / activities / locations hiện đúng.  
5. Layer toggles hoạt động.  
6. Không crash khi thiếu tọa độ (skip + warning nhẹ).  
7. Basic: map + layers cơ bản.  
8. VIP: Places autocomplete thêm điểm; Directions theo ngày (khi bật phase 2).  
9. Chi phí Google Maps có monitoring (quota alert).

### 7.8 Gating map

| | Basic | VIP |
|---|---|---|
| Xem map + flight path + hotel pins | ✅ | ✅ |
| Thêm điểm bằng long-press / Places | Giới hạn N điểm | Unlimited |
| Directions tối ưu trong ngày | ❌ hoặc 1 lần/trip | ✅ |
| Live traffic | ❌ | Optional sau |

### 7.9 Bảo mật & chi phí

- Restrict key; rotate nếu leak.  
- Geocoding server-side + cache theo địa chỉ normalized.  
- Không gửi PII lên Google ngoài địa chỉ cần thiết.  
- Ngân sách: set billing cap Google Cloud.

### 7.10 Thứ tự implement Maps (cho agent)

1. Migration `TripBooking` thêm geo + flight fields.  
2. Endpoint `GET /trips/{id}/map`.  
3. Flutter integrate SDK + màn `trip_map_screen`.  
4. Wire markers từ API.  
5. Flight polylines.  
6. Layer toggles + marker sheets.  
7. Geocode helper khi user nhập địa chỉ KS.  
8. (Sau) Directions + Places.

---

## 8. Gợi ý cấu trúc code khi implement CUSTOMIZE

```text
src/Services/Trip/Trip.API/
  Domain/Entities/TripBooking.cs          # mở rộng fields
  Domain/Entities/AirportReference.cs     # optional
  Application/Bookings/...
  Application/Maps/GetTripMapQuery.cs
  Infrastructure/Integrations/
    Booking/
      IBookingAffiliateLinkBuilder.cs
      BookingDemandClient.cs              # feature flag
    Traveloka/
      ITravelokaLinkBuilder.cs
      TravelokaTpnClient.cs               # feature flag
    Google/
      IGeocodingClient.cs

src/Clients/mobile/lib/features/trips/
  bookings/                               # forms + list
  map/                                    # trip_map_screen, layers
  affiliate/                              # launch URLs
```

Feature flags (`appsettings` + remote config):

```json
{
  "Features": {
    "TripMap": true,
    "ManualBookings": true,
    "AffiliateBookingCom": true,
    "AffiliateTraveloka": true,
    "DemandApiBooking": false,
    "TravelokaTpnApi": false
  }
}
```

---

## 9. Definition of Done (áp dụng mọi feature trong file)

- [ ] AC trong bảng feature đã pass.  
- [ ] Server enforce entitlement nếu là VIP/Pass.  
- [ ] Không lộ secret.  
- [ ] Có empty/error/loading states trên Flutter.  
- [ ] Cập nhật **Trạng thái** trong file này.  
- [ ] Nếu đổi model tiền / Free vs Pro → cập nhật luôn vision doc hoặc ghi chú lệch tạm thời.  
- [ ] Không thêm scope P3 “tiện tay” trong PR P0/P1.

---

## 10. Open questions (cần product owner quyết)

1. Ưu tiên affiliate **Traveloka trước** hay **Booking.com trước** cho thị trường VN? (Gợi ý: Traveloka flight nội địa + Booking hotel quốc tế.)  
2. Trip Pass giá chốt: 29k / 39k / 49k?  
3. Guest join có cho xem **toàn bộ** expense nhóm hay chỉ balance của mình?  
4. Có làm WebView in-app cho Traveloka hay luôn mở external browser?  
5. Ngân sách trần Google Maps / tháng?

---

## 11. Changelog tài liệu

| Ngày | Thay đổi |
|---|---|
| 2026-07-27 | Tạo file: backlog monetization P0–P3 + CUSTOMIZE flight/hotel (Traveloka/Booking) + Google Maps trip layers |

---

**Kết thúc file.** Agent implement: bắt đầu từ P0 hoặc đúng ID user chỉ định; với customize map/booking bắt đầu **Tầng A + FEAT-P2-01 MVP**, không nhảy Tầng C khi chưa có partner credentials.
