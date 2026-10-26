---
name: cn-xong
description: 'Bước 6 quy trình chức năng: kiểm tiêu chí xong, viết hướng dẫn tạo tay/TS, rút kinh nghiệm vào đúng nơi, đóng TRANG_THAI và lưu repo dự án (hỏi trước). Gọi: /cn-xong [KH] <CN>'
argument-hint: '[KH] <CN>'
disable-model-invocation: true
---

# /cn-xong — Bàn giao + đóng chức năng

Phần chung (xác định KH/CN, TRANG_THAI, nhật ký): mục 0 của `.claude/skills/cn-fs/SKILL.md`.

1. **Tiêu chí xong** — báo từng mục Đạt/Chưa:
   - `CAU_HOI_FS_<CN>.md` hết [CHẶN]; câu còn mở ghi rõ ai đang giữ.
   - Code local = hệ thống; object active; cảnh báo còn lại có giải thích.
   - TC chức năng chính Đạt; lỗi còn lại có quyết định (bỏ qua/để sau).
2. **Bàn giao**:
   - GUI: `HUONG_DAN_TAO_<CN>.md` (object list, thứ tự tạo tay, text, T-code, lưu ý khi chuyển hệ). AVN theo `avn-huong-dan-tao-tay`.
   - TS nếu cần: hỏi user định dạng → `sap-ts-document` (Word) hoặc `abap-ts-excel` (Excel).
3. **Rút kinh nghiệm**: rà nhật ký + bảng lỗi → điều gì dùng lại được thì ghi theo bảng của `/ghi-nhan` (dự án vs team).
4. **Đóng**: TRANG_THAI `Xong` + mục nhật ký cuối (object chính, TR, việc còn chờ bên ngoài).
5. **Lưu**: hỏi user rồi chạy `<gốc>\scripts\git-du-an.ps1 luu <KH> -m "<CN>: xong"`. Có sửa `.claude/skills/**` → chạy `check-repo.ps1 -All` và nhắc user commit repo team (không tự commit).
