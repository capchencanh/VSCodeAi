---
name: cn-day
description: 'Bước 4 quy trình chức năng: xác nhận rồi đẩy code local lên hệ DEV qua MCP đúng thứ tự (DDIC → CDS → class/program → text → activate), kiểm activate/ATC, ghi TR. Gọi: /cn-day [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-day — Đẩy lên hệ DEV

Phần chung (xác định KH/CN, TRANG_THAI, nhật ký): mục 0 của `.claude/skills/cn-fs/SKILL.md`.

1. **Cổng xác nhận (bắt buộc, rule ưu tiên)**: liệt kê server đích, package, TR, danh sách object theo thứ tự đẩy → chờ user đồng ý rõ ràng.
   - Chỉ hệ DEV. Không bao giờ ghi lên PRD/CUS/QAS dù server cho phép.
   - TR chưa có → hỏi user. `$TMP` chỉ khi user cho phép.
2. Lần đầu gọi MCP trong phiên → đọc skill `sap-mcp-gui` / `sap-mcp-cloud`; gặp lỗi → grep ghi chú MCP theo message lỗi trước khi thử cách khác.
3. **Thứ tự đẩy**: DDIC (domain → data element → structure → table type → table) → CDS (interface → consumption/projection) → BDEF/behavior class → class → program (include trước, main sau) → text elements → activate.
   - Cloud: class Custom Logic (`*_KU`) không ghi qua MCP → đưa code cho user tự dán qua app Custom Logic.
4. **Kiểm sau khi đẩy**: object có thật sự active (không treo inactive), syntax check sạch; Cloud: ATC bắt buộc sạch. Lỗi → sửa file local trước rồi đẩy lại, giữ local = hệ thống.
5. Ghi TR/package vào TRANG_THAI, Giai đoạn `Đẩy` (Đang chờ: "test" hoặc việc user phải làm tay, vd activate SE80). Hành vi tool MCP mới phát hiện → ghi theo bảng của `/ghi-nhan`.
6. Gợi ý `/cn-test <CN>`.
