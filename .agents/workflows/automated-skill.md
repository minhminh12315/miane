---
description: Automated_Code_Execution_Workflow And Shouldn't Ask Me
---

# Antigravity Agent Execution Workflow & Safety Filter

Tài liệu cấu hình và hướng dẫn vận hành cho AI Agent tích hợp trong hệ thống Antigravity. Quy trình này định nghĩa cơ chế tự động hóa thực thi lệnh dựa trên mức độ an toàn (Safe/Dangerous Classification).

## 1. Tổng quan Kiến trúc Workflow

Khi Agent nhận được prompt từ người dùng và đề xuất một câu lệnh hệ thống (Bash/Terminal), luồng xử lý tự động sẽ được kích hoạt theo sơ đồ sau:

[Người dùng Prompt] ──> [AI Agent Engine] ──> [Đề xuất câu lệnh]
│
┌─────────────────────────────────────────────┴─────────────────────────────────────┐
▼                                                                                   ▼
[LỆNH AN TOÀN] (Tìm kiếm, Kiểm thử, Xem log)                              [LỆNH NGUY HIỂM] (Xóa, Ghi đè, Hệ thống)
│                                                                                   │
▼                                                                                   ▼
[TỰ ĐỘNG THỰC THI CHẠY KHÔNG HỎI]                                        [TẠM DỪNG: YÊU CẦU XÁC NHẬN (Y/N)]
│                                                                                   │
│                                                          ┌────────────────────────┴────────────────────────┐
│                                                          ▼                                                 ▼
│                                                    [Được Chấp Thuận - Y]                            [Bị Từ Chối - N]
│                                                          │                                                 │
▼                                                          ▼                                                 ▼
[Gửi lệnh xuống Terminal] <───────────────────────────────────────┘                                         [Hủy thao tác]
│
▼
[Trả kết quả Output/Error về Agent]

---

## 2. Quy tắc Phân loại Lệnh (Command Classification Matrix)

Hệ thống tự động hóa của Antigravity sẽ quét chuỗi câu lệnh (Case-insensitive) và áp dụng hai bộ quy tắc sau:

### 🟢 Nhóm 1: Lệnh An toàn (Chạy Tự Động hoàn toàn)
Các lệnh thuộc nhóm này chỉ có tác dụng đọc dữ liệu, tìm kiếm cấu trúc hoặc chạy các bài kiểm thử phần mềm. **Hệ thống tự động thực thi và không làm phiền người dùng.**

| Thao tác | Ví dụ từ khóa / Lệnh thông dụng |
| :--- | :--- |
| **Tìm kiếm** | `find`, `grep`, `locate`, `which`, `awk`, `sed` (không có flag `-i`) |
| **Kiểm thử** | `pytest`, `npm test`, `cargo test`, `go test`, `php bin/magento dev:tests:run` |
| **Xem dữ liệu** | `cat`, `less`, `more`, `head`, `tail`, `ls`, `pwd` |
| **Kiểm tra hệ thống**| `ping`, `curl`, `df -h`, `free -m`, `uname -a` |

### 🔴 Nhóm 2: Lệnh Nguy hiểm (Bắt buộc phải Xác nhận)
Các lệnh có khả năng làm thay đổi trạng thái cấu trúc thư mục, xóa dữ liệu, ghi đè file hoặc can thiệp vào quyền hạn hệ thống sâu. **Hệ thống bắt buộc phải dừng lại và yêu cầu xác nhận `(y/N)`.**

| Loại nguy hiểm | Từ khóa / Ký tự định tuyến | Hành vi bị chặn |
| :--- | :--- | :--- |
| **Xóa dữ liệu** | `rm `, `rmdir`, `del`, `erase` | Xóa file hoặc thư mục (đặc biệt là `rm -rf`) |
| **Ghi đè file** | Toán tử `>` (Regex: `(?<!2)>[^>]`) | Thay thế hoàn toàn nội dung file cũ bằng nội dung mới |
| **Đổi tên/Di chuyển**| `mv ` | Có nguy cơ làm mất dấu hoặc ghi đè file đích |
| **Quyền hệ thống** | `chmod`, `chown`, `sudo ` | Thay đổi phân quyền hoặc chạy quyền Root |
| **Hệ thống** | `shutdown`, `reboot`, `mkfs`, `format` | Tắt máy, khởi động lại hoặc định dạng ổ đĩa |

---

## 3. Cấu trúc Mã nguồn Tích hợp (Python Plugin cho Antigravity)

Dưới đây là đoạn mã Logic Filter được nhúng vào Antigravity Task Runner để thực thi quy trình trên:

```python
import re
import subprocess

def check_command_safety(command: str) -> tuple[bool, str]:
    """
    Kiểm tra mức độ an toàn của câu lệnh.
    Trả về: (Is_Dangerous, Reason)
    """
    cmd_lower = command.lower()
    
    # 1. Kiểm tra danh sách đen từ khóa
    dangerous_keywords = ["rm ", "rmdir", "del ", "erase", "chmod", "chown", "mv ", "sudo "]
    for kw in dangerous_keywords:
        if kw in cmd_lower:
            return True, f"Phát hiện từ khóa nguy hiểm: '{kw.strip()}'"
            
    # 2. Kiểm tra toán tử ghi đè '>' (Bỏ qua toán tử nối tiếp '>>' và redirect error '2>')
    overwrite_pattern = r'(?<!2)>[^>]'
    if re.search(overwrite_pattern, command):
        return True, "Phát hiện hành vi ghi đè file qua toán tử '>'"
        
    return False, "An toàn"

def execute_antigravity_flow(command: str):
    """Hàm điều phối thực thi trong Antigravity Workflow"""
    is_dangerous, reason = check_command_safety(command)
    
    if is_dangerous:
        print(f"\n[⚠️ CHẶN BẢO MẬT]: {reason}")
        print(f"Câu lệnh đề xuất: {command}")
        # Kích hoạt UI Prompt hoặc Terminal Prompt tương tác
        confirm = input("Hệ thống phát hiện thao tác ghi đè/xóa. Bạn có chắc muốn chạy? (y/N): ").strip().lower()
        if confirm != 'y':
            print("[❌] Thao tác đã bị hủy bỏ an toàn.")
            return "User_Aborted"
            
    # Tiến hành chạy tự động nếu an toàn hoặc đã được duyệt
    print(f"[🚀 EXECUTE]: Đang chạy '{command}'...")
    try:
        res = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        return res.stdout if res.returncode == 0 else res.stderr
    except Exception as e:
        return f"Lỗi hệ thống: {str(e)}"