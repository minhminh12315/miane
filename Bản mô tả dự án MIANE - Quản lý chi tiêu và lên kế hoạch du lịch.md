# DỰ ÁN QUẢN LÝ CHI TIÊU VÀ LÊN KẾ HOẠCH DU LỊCH - MIANE

**Tên ứng dụng:** MIANE - Quản lý chi tiêu và lên kế hoạch du lịch

**Slogan gợi ý:** Đồng bộ lịch trình, đơn giản chi tiêu.

## 1\. Tổng Quan Dự Án & Mục Tiêu

MIANE là ứng dụng di động thông minh được thiết kế nhằm giải quyết toàn diện hai bài toán lớn nhất của việc đi du lịch nhóm: **lên kế hoạch lịch trình tối ưu** và **tự động hóa quy trình tính toán, chia sẻ chi phí**. Nhờ sự kết hợp của công nghệ trí tuệ nhân tạo (AI) và cơ chế đồng bộ hóa thời gian thực, ứng dụng giúp loại bỏ hoàn toàn sự cồng kềnh, sai sót trong việc ghi chép sổ sách thủ công sau mỗi chuyến đi.

### Đối tượng khách hàng mục tiêu

- **Nhóm người trẻ và Dân văn phòng:** Những người có thu nhập ổn định, đi du lịch thường xuyên, đòi hỏi trải nghiệm dịch vụ mượt mà, nhanh chóng và tiết kiệm thời gian chuẩn bị.
- **Nhóm Học sinh / Sinh viên:** Những người thường xuyên tổ chức các chuyến đi phượt, đi chơi nhóm đông với ngân sách giới hạn. Nhu cầu cốt lõi là sự minh bạch, chính xác tuyệt đối trong việc chia nhỏ chi phí theo từng đầu người hoặc từng khoản chi cá biệt.

## 2\. Kiến Trúc Công Nghệ (Tech Stack)

Hệ thống được xây dựng theo mô hình phân tán (Distributed/Microservices) nhằm đảm bảo tính sẵn sàng cao, bảo mật và khả năng mở rộng linh hoạt:

| **Thành phần**         | **Công nghệ lựa chọn** | **Vai trò chức năng**                                                                                                   |
| ---------------------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Frontend**           | Flutter                | Xây dựng giao diện đa nền tảng (iOS & Android) mượt mà với một mã nguồn duy nhất.                                       |
| ---                    | ---                    | ---                                                                                                                     |
| **Backend Server**     | ASP.NET Core API       | Xử lý logic nghiệp vụ chính, quản lý người dùng, phân quyền, dữ liệu chuyến đi và các cổng thanh toán,..                |
| ---                    | ---                    | ---                                                                                                                     |
| **AI Service**         | Python (FastAPI)       | Xử lý các mô hình học máy: gợi ý lịch trình thông minh, bóc tách dữ liệu hóa đơn (OCR OCR), …                           |
| ---                    | ---                    | ---                                                                                                                     |
| **Database**           | SQLSever               | Lưu trữ dữ liệu có cấu trúc ổn định, tối ưu hóa các câu truy vấn phức tạp về mối quan hệ dòng tiền giữa các thành viên. |
| ---                    | ---                    | ---                                                                                                                     |
| **Cloud / Serverless** | Firebase               | Xác thực tài khoản qua mạng xã hội (OAuth2: Google, Apple ID) và đẩy thông báo (Push Notification) thời gian thực.      |
| ---                    | ---                    | ---                                                                                                                     |

## 3\. Mô Hình Phân Chia Tính Năng (Free vs Pro)

Để tối ưu hóa chi phí vận hành hệ thống (đặc biệt là hạ tầng Cloud và chi phí xử lý AI tại FastAPI) và xây dựng mô hình doanh thu bền vững, hệ thống tính năng của MIANE được phân chia rõ ràng thành hai phiên bản:

| **Danh mục**                                 | **Phiên bản Miễn phí (MIANE Basic)**                                                                                                                                                            | **Phiên bản Trả phí (MIANE Pro)**                                                                                                                                                                                                                                         |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Giới hạn chuyến đi & thành viên**          | Tối đa 2 chuyến đi hoạt động đồng thời. Giới hạn tối đa 7 thành viên mỗi nhóm.                                                                                                                  | Không giới hạn số lượng chuyến đi. Không giới hạn số lượng thành viên nhóm.                                                                                                                                                                                               |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Sổ cái & Chia sẻ chi phí (Split-wise)**    | Ghi nhận chi phí thủ công. Hỗ trợ các hình thức chia cơ bản (chia đều, chia theo số tiền cụ thể). Biểu đồ cơ cấu chi tiêu dạng tròn cơ bản. Tiền tệ cố định theo Vùng/Quốc gia cấu hình.        | Hỗ trợ chia tiền nâng cao (chia theo tỷ lệ %, chia theo thời gian tham gia chuyến đi của từng người). Xuất báo cáo chi tiêu chi tiết (Excel/PDF). Hỗ trợ đa tiền tệ (Multi-currency): Tự động quy đổi tỷ giá theo thời gian thực khi đi nước ngoài dựa trên cài đặt Vùng. |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Cài đặt Vùng & Ngôn ngữ (Localization)**   | Cho phép thay đổi Ngôn ngữ và Vùng tự do để định dạng hiển thị. Tiền tệ chuyến đi cố định theo Vùng được chọn.                                                                                  | Mở khóa toàn diện: Tự do thay đổi Ngôn ngữ/Vùng. Kích hoạt tính năng tự động chuyển đổi tỷ giá ngoại tệ linh hoạt trong cùng một chuyến đi.                                                                                                                               |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Tính năng Trí tuệ nhân tạo (AI Features)** | Không hỗ trợ.                                                                                                                                                                                   | Quét hóa đơn thông minh (AI OCR): Chụp hóa đơn, AI tự tách tiền và gán người trả.<br><br>AI Trip Planner: Tự động thiết lập lịch trình chi tiết theo ngân sách và gu du lịch.<br><br>Trợ lý ảo cảnh báo & tối ưu ngân sách thông minh.                                    |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Lịch trình di chuyển**                     | Tự lên lịch trình thủ công. Xem bản đồ lộ trình di chuyển tích hợp.                                                                                                                             | Lên lịch trình tự động bằng AI. Đồng bộ hóa lịch trình với Google Calendar / Apple Calendar.                                                                                                                                                                              |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Quyết toán & Gạch nợ tự động**             | Tự động tính toán đường đi ngắn nhất của tiền. Hiển thị VietQR động/MoMo hỗ trợ thanh toán 1 chạm App-to-App. Cơ chế tự động gạch nợ (Auto-Reconciliation) thời gian thực.                      | Đầy đủ tính năng quyết toán của bản Basic. Bổ sung tính năng Quản lý Quỹ nhóm (Trip Pool/Fund): Đóng quỹ chung từ đầu chuyến đi, tự động trừ tiền quỹ khi phát sinh chi phí chung mà không cần chia lẻ.                                                                   |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |
| **Lưu trữ Media & Tiện ích bổ sung**         | Shared Cloud Album giới hạn dung lượng lưu trữ (Tối đa 100MB/chuyến đi). Danh sách chuẩn bị đồ dùng chung (Trip Checklist). Chế độ ngoại tuyến giới hạn (Lưu tối đa 20 khoản chi khi mất mạng). | Shared Cloud Album KHÔNG GIỚI HẠN dung lượng, lưu trữ ảnh/video chất lượng gốc. Hoàn toàn không chứa quảng cáo (Ad-Free). Chế độ ngoại tuyến không giới hạn số lượng khoản chi tạm lưu.                                                                                   |
| ---                                          | ---                                                                                                                                                                                             | ---                                                                                                                                                                                                                                                                       |

## 4\. Chi Tiết Hệ Thống Tính Năng

### A. Nhóm Tính Năng Cốt Lõi (Core Features)

- **Quản lý Nhóm Du Lịch (Trip Workspace):** Trưởng nhóm (Trip Master) dễ dàng khởi tạo chuyến đi và mời các thành viên tham gia tức thì thông qua mã QR hoặc đường liên kết động. Các thành viên có quyền hạn được phân rõ ràng (chỉnh sửa hoặc chỉ xem). Điều phối phân quyền linh hoạt theo gói cước Basic (giới hạn số người) hoặc Pro (không giới hạn).
- **Sổ Cái Chi Tiêu Nâng Cao (Smart Split-wise):**
  - Ghi nhận chi phí linh hoạt: Hỗ trợ nhiều hình thức chia tiền từ cơ bản đến nâng cao (chia đều cho tất cả, chia theo tỷ lệ phần trăm tự cấu hình, chia theo đầu người thụ hưởng thực tế, hoặc tính riêng chi phí phát sinh cá nhân).
  - Tích hợp công nghệ OCR (Trí tuệ nhân tạo - Bản Pro): Người dùng chỉ cần chụp ảnh hóa đơn nhà hàng, khách sạn; dịch vụ AI tại FastAPI sẽ tự động phân tích, bóc tách số tiền, tên dịch vụ và gợi ý gán hóa đơn cho các thành viên tương ứng.
- **Thuật Toán Tối Ưu Hóa Dòng Tiền & Quyết Toán (Debt Settlement):**
  - Tối ưu hóa dòng tiền: Tự động tính toán "đường đi ngắn nhất của tiền" để giảm thiểu tối đa số lượt giao dịch cần chuyển khoản trong nhóm sau chuyến đi.
  - Tích hợp QR động (Viet QR / MoMo): Hệ thống tự động sinh mã QR chứa số tài khoản người nhận, số tiền chính xác, kèm nội dung chuyển khoản (Memo) cố định duy nhất (gợi ý định dạng: MIANE_98234) để phục vụ việc tự động gạch nợ.
  - Quy trình thực hiện phía Người Nợ (Người đi trả): Tại màn hình Quyết toán, người nợ chỉ cần chọn nút "Thanh toán ngay". Hệ thống áp dụng cơ chế App-to-App (Deep Linking) tự động gọi ứng dụng Ngân hàng/MoMo và điền sẵn mọi thông tin. Người nợ chỉ cần xác thực FaceID/Vân tay để hoàn tất thanh toán trong 1 chạm.
  - Quy trình thực hiện phía Người Nhận (Người được trả): Hoàn toàn thụ động nhận tiền. Người nhận bắt buộc phải liên kết Ngân hàng/Số tài khoản/MoMo vào mục Cài đặt ví trên Profile trước đó để hệ thống có cơ sở tạo QR động.
  - Cơ chế Tự động Gạch Nợ (Auto-Reconciliation): Hệ thống Backend (ASP.NET Core) tích hợp Webhook/Open API ngân hàng. Khi giao dịch thành công khớp đúng mã nội dung Memo, hệ thống lập tức cập nhật trạng thái "Đã thanh toán" trong DB, đồng thời gửi thông báo Firebase thời gian thực để xóa khoản nợ khỏi danh sách mà người nhận không cần kiểm tra sao kê thủ công.

### B. Nhóm Tính Năng Thông Minh (AI-Powered Features - Độc quyền bản Pro)

- **AI Trip Planner (Lên lịch trình tự động):** Người dùng chỉ cần cung cấp các tham số đầu vào: điểm đến, số ngày lưu trú, hạn mức ngân sách dự kiến (Giá rẻ / Tiêu chuẩn / Sang chảnh) và gu du lịch (Nghỉ dưỡng, Khám phá văn hóa, Mạo hiểm). Hệ thống sẽ tự động đề xuất lịch trình tối ưu theo từng mốc thời gian kèm bảng ước tính kinh phí chi tiết.
- **Hệ Thống Dự Báo & Cảnh Báo Ngân Sách:** Dựa trên dòng tiền chi tiêu thực tế, AI liên tục phân tích và đưa ra cảnh báo sớm nếu nhóm có xu hướng chi tiêu vượt ngưỡng quỹ kế hoạch ban đầu, từ đó gợi ý cắt giảm ở các hoạt động tiếp theo hoặc cơ cấu lại ngân sách thông minh.

### C. Nhóm Tính Năng Giá Trị Gia Tăng & Bản Địa Hóa (Value-Added & Localization Features)

- **Cấu Hình Cài Đặt Vùng & Ngôn Ngữ (Localization):** Hệ thống tích hợp khả năng đa ngôn ngữ và định hình khu vực hóa sâu sắc.
  - _Ngôn ngữ:_ Chuyển đổi linh hoạt giao diện ngôn ngữ hệ thống hệ thống (Tiếng Việt / Tiếng Anh) qua thư viện localizations trên Flutter.
  - _Quốc gia/Vùng:_ Tự động thiết lập định dạng hiển thị ngày tháng phù hợp (ví dụ: DD/MM/YYYY) và quy chuẩn định dạng số (dấu chấm/phẩy phân cách hàng nghìn). Lựa chọn vùng này đồng thời cấu hình đơn vị tiền tệ mặc định cho chuyến đi (VD: Chọn Vùng là Việt Nam, tiền tệ mặc định sẽ là VNĐ). Đối với bản Pro, cấu hình vùng là tham chiếu gốc để AI tính toán tỷ giá chuyển đổi thời gian thực khi phát sinh các giao dịch ngoại tệ.
- **Bản Đồ Lịch Trình Tương Tác:** Tích hợp Google Maps/OpenStreetMap hiển thị trực quan các điểm đến trong ngày, giúp người dùng dễ dàng tối ưu hóa lộ trình di chuyển, tránh đi ngược đường hoặc trùng lặp tuyến đường.
- **Kho Lưu Trữ Media Chung (Shared Cloud Album):** Không gian lưu trữ hình ảnh và video chất lượng gốc dành riêng cho các thành viên trong chuyến đi, giải quyết triệt để tình trạng giảm chất lượng ảnh khi chia sẻ qua các ứng dụng nhắn tin thông thường (Gói Basic giới hạn 100MB/chuyến, gói Pro không giới hạn).
- **Chế Độ Hoạt Động Ngoại Tuyến (Offline Mode):** Cho phép người dùng nhập dữ liệu chi tiêu và xem lịch trình ngay cả khi ở khu vực mất sóng (núi cao, biển đảo). Dữ liệu sẽ được lưu tạm tại bộ nhớ cục bộ (Local Storage) của Flutter và tự động đồng bộ (Sync) lên hệ thống Postgres khi thiết bị có kết nối Internet trở lại.
- **Danh Sách Chuẩn Bị Đồ (Trip Checklist):** Tính năng cho phép tạo danh sách các đồ dùng cần chuẩn bị trước chuyến đi và phân công/tích chọn chung giữa các thành viên.

## 5\. Yêu Cầu Thiết Kế Giao Diện & Trải Nghiệm Người Dùng (UI/UX)

Để mang lại trải nghiệm đầy hứng khởi cho những chuyến đi và tránh sự khô khan của các ứng dụng quản lý tài chính thông thường, thiết kế của MIANE tuân thủ các nguyên tắc nghiêm ngặt sau:

- **Phong cách thiết kế hình ảnh:** Áp dụng ngôn ngữ thiết kế Hiện đại (Modern Minimalism) kết hợp hiệu ứng kính mờ (Glass Morphism) nhẹ nhàng để tạo cảm giác tự do, phóng khoáng. Bảng màu chủ đạo sử dụng màu Xanh Dương (thể hiện tính công nghệ, sự minh bạch, tin cậy) phối hợp cùng màu Cam/Vàng Cát (truyền tải năng lượng dịch chuyển, khám phá).
- **Trải nghiệm người dùng cốt lõi (UX):**
  - Quy tắc 3 chạm: Thiết kế luồng thao tác tối ưu để người dùng có thể nhập nhanh một khoản chi tiêu phát sinh hoặc tra cứu lịch trình trong tối đa 3 lần chạm màn hình.
  - Trực quan hóa dữ liệu (Data Visualization): Hệ thống biểu đồ tròn, biểu đồ cột động biểu diễn cơ cấu chi phí giúp toàn bộ thành viên nắm bắt tình hình tài chính trong 1 giây.
  - Màn hình Trung tâm Chuyến đi (Trip Dashboard): Hiển thị đồng thời 3 thông số quan trọng nhất ngay khi truy cập ứng dụng: Lịch trình kế tiếp trong ngày, Tổng ngân sách đã chi tiêu của nhóm và Trạng thái tài chính cá nhân (Đang nợ ai hoặc ai đang nợ mình).
  - Chế độ giao diện tối (Dark Mode): Hỗ trợ tối ưu hóa hiển thị vào ban đêm, giúp người dùng dễ dàng thao tác nhập chi tiêu hoặc xem lịch trình khi đang di chuyển ngoài trời tối mà không gây mỏi mắt.
  - Màn hình Cài đặt Hồ sơ mở rộng: Bổ sung khu vực menu tùy chỉnh **Ngôn ngữ (Language)** và **Vùng/Quốc gia (Region)** trực quan, bố trí khoa học bên cạnh mục cấu hình Ví nhận tiền.
  - Phân luồng Giao diện Pro: Các tính năng nâng cao thuộc gói Pro được gắn các chỉ báo trực quan tinh tế (như icon Premium) nhằm khuyến khích người dùng nâng cấp gói cước ngay trên giao diện mà không gây đứt gãy trải nghiệm.

## 6\. Lộ Trình Phát Triển Đề Xuất (Project Roadmap)

- **Giai đoạn 1 (Xây dựng MVP - Bản Basic):** Hoàn thiện các tính năng cốt lõi bao gồm tạo nhóm chuyến đi (giới hạn), cấu hình cài đặt Vùng & Ngôn ngữ nền tảng để định dạng hiển thị, ghi chép sổ cái chi tiêu thủ công đơn tiền tệ, tích hợp cổng VietQR động quyết toán và đồng bộ hóa thời gian thực thông qua Firebase và cơ sở dữ liệu PostgreSQL.
- **Giai đoạn 2 (Tích hợp Trí tuệ nhân tạo & Bản Pro):\*\* Triển khai dịch vụ AI chạy trên nền tảng Python FastAPI để xử lý module tự động lên lịch trình du lịch thông minh (AI Trip Planner) và bóc tách dữ liệu hóa đơn (AI OCR). Bổ sung hệ thống chia tiền nâng cao, mở khóa tính năng tự động quy đổi đa tiền tệ theo tỷ giá thời gian thực dựa trên cài đặt Vùng và cấp quyền lưu trữ không giới hạn cho tài khoản Pro.**
- **Giai đoạn 3 (Tối ưu hóa, Thương mại hóa & Phát hành):\*\* Chuẩn hóa toàn diện giao diện UI/UX bao gồm hệ thống paywall (màn hình thanh toán gói cước), kiểm soát request qua Middleware của ASP.NET Core, hoàn thiện chế độ ngoại tuyến Offline Mode trước khi đưa lên các kho ứng dụng App Store và Google Play.**