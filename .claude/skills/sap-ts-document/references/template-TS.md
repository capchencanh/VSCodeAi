# TÀI LIỆU THIẾT KẾ KỸ THUẬT

<!--
Template TS chuẩn CITEK — S/4HANA On-Premise.
Cách dùng: copy file này thành <MãDA>_TS_<TênChứcNăng>_<Mã>_V<x.y>.md rồi điền.
Xoá hết comment <!-- ... --> trước khi bàn giao.
Mục không áp dụng: ghi N/A — KHÔNG xoá mục, KHÔNG để trống.
Quy tắc điền từng mục: xem SKILL.md §3.
-->

Phân hệ <!-- VD: Quản lý vật tư (MM - Materials Management) --> – SAP S/4HANA

## THÔNG TIN TÀI LIỆU

| | |
|---|---|
| Mã Dự Án | <!-- VD: GGFs --> |
| Phân hệ | <!-- VD: MM --> |
| Tên báo cáo | <!-- VD: MM.13 – Quy trình trả hàng bán nội bộ --> |
| Người thiết kế | <!-- tên người thật, KHÔNG ghi tên AI --> |
| Phiên bản | 1.0 |
| Ngày cập nhật | <!-- dd/mm/yyyy --> |

## BẢNG GHI NHẬN THAY ĐỔI

| Ngày thay đổi | Mục, bảng, sơ đồ thay đổi | Mô tả thay đổi | T / S / X | Phiên bản |
|---|---|---|---|---|
| <!-- dd/mm/yyyy --> | Toàn bộ | Tạo mới tài liệu | T | 1.0 |

T - Thêm mới    S - Sửa đổi    X - Xóa

---

# 1. Tổng quan

## 1.1. Mô tả chung

<!-- 1–3 câu mô tả phạm vi chức năng. -->

## 1.2. Yêu cầu nghiệp vụ chi tiết

Tài liệu FS:
<!-- Tên file FS + version, VD: GGFs_FS_Chucnang&TichhopAPI_trahangbannoibo_MM13_V2.0 -->

# 2. Mô tả kỹ thuật

## 2.1. Cấu hình hệ thống

<!-- Interface qua PI/PO: tách sub-section theo từng API.
     Chức năng thuần ABAP: ghi N/A. -->

### 2.1.1. <!-- API 5 -->

File import Enterprise Service Builder
File import Integration Builder

## 2.2. Object List

<!-- Nhiều API/nhiều chương trình → tách sub-section 2.2.1, 2.2.2...
     Object dùng chung thì lặp lại ở từng bảng.
     Object Type: Program | Include | Transaction | Class/Interface |
     Implementing Class | Method | Enhancement Implementation Point |
     Table | Structure | Message Class | Function Module | Search Help |
     Data Element | Domain -->

### 2.2.1. <!-- API 5 / Tên chức năng -->

| No. | Object Name | Object Type | Description | File |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |

## 2.3. Flow Diagram

### 2.3.1. <!-- API 5 / Tên chức năng -->

Luồng tích hợp

> 📷 **[ẢNH]** <!-- sơ đồ luồng: hệ thống nguồn → SAP → hệ thống đích, ghi rõ API nào ở bước nào -->

## 2.4. Enhancement

<!-- Toàn bộ object DDIC tự tạo + enhancement implementation.
     Mỗi object: 1 dòng nhãn + 1 ảnh SE11/SE19 (+ bảng field nếu cần). -->

Message Class: <!-- ZMC_xxx -->

> 📷 **[ẢNH]** SE91 → <!-- ZMC_xxx --> — danh sách message

Transparent Table: <!-- ZTB_xxx_HD -->

> 📷 **[ẢNH]** SE11 → <!-- ZTB_xxx_HD --> → tab Fields — chụp đủ cột Key/Initial/Data element

| Field | Key | Data element | Mô tả |
|---|---|---|---|
| | | | |

Structure: <!-- Zxx_ST_xxx -->

> 📷 **[ẢNH]** SE11 → <!-- Zxx_ST_xxx --> → tab Components

## 2.5. Job Scheduling

N/A
<!-- Có chạy nền: tên job, biến thể, tần suất, user chạy. -->

## 2.6. Error Handling

N/A
<!-- Message class + mã message, ghi log, cơ chế retry.
     Interface: phân biệt lỗi kỹ thuật vs lỗi nghiệp vụ, có post lại được không. -->

## 2.7. Function Module

N/A
<!-- Tên FM + ảnh Import/Export/Tables + source code. -->

<!--
ZFM_xxx

> 📷 **[ẢNH]** SE37 → ZFM_xxx → tab Import
> 📷 **[ẢNH]** SE37 → ZFM_xxx → tab Export
> 📷 **[ẢNH]** SE37 → ZFM_xxx → tab Tables

Source code:
```abap
```
-->

## 2.8. Parameter/Selection-screen

### 2.8.1. <!-- MM.13_Tên chức năng trên màn hình -->

> 📷 **[ẢNH]** Chạy <!-- Tcode --> → <!-- option --> — chụp toàn bộ selection-screen

Mô tả:

| Description | Type | Field name | SAP table | Default | Required |
|---|---|---|---|---|---|
| | | | | | |

<!-- Type: Select option | Parameter | Check box | Radio button
     Field name: S_* (select-option), P_* (parameter/checkbox)
     SAP table: <BẢNG>-<FIELD>, hoặc kiểu dữ liệu nếu không tham chiếu bảng -->

## 2.9. Display output

### 2.9.1. <!-- MM.13_Tên chức năng -->

<!-- Có nhiều trạng thái hiển thị → tách rõ từng trường hợp, mỗi trường hợp 1 ảnh. -->

> 📷 **[ẢNH]** ALV kết quả — <!-- nêu rõ trường hợp nào --> (chụp nửa trái + nửa phải)

Mô tả:

| Description | SAP field | Logic |
|---|---|---|
| | | |

<!-- Cột Logic BẮT BUỘC có giá trị, 1 trong 4 dạng:
     1. <BẢNG>-<FIELD>
     2. Mapping <BẢNG>-<FIELD> theo <đủ khóa nối>
     3. Kết quả subrountine <TÊN> với tham số <input>
     4. Field check box / Icon trạng thái
     Field icon: <FIELD>_ICON — field giá trị cập nhật: <FIELD>_U -->

## 2.10. Logic lấy data

### 2.10.1. <!-- MM.13_Tên chức năng -->

1. <!-- Lấy data từ table ... theo điều kiện lọc từ màn hình tham số. -->
2. <!-- Lấy data mapping từ table ... -->
3. <!-- Mapping field ... và xử lý giá trị các field status. -->
4. <!-- Tạo field catalog bằng FM LVC_FIELDCATALOG_MERGE, chỉnh sửa hiển thị field và mô tả. -->
5. <!-- Hiển thị ALV bằng FM REUSE_ALV_GRID_DISPLAY_LVC. -->
6. <!-- Xử lý fcode ... -->
   1. <!-- fcode 1 -->
      1. <!-- bước -->
   2. <!-- fcode 2 -->

<!-- Bắt buộc: tên bảng/FM/subroutine/fcode thật; nhánh điều kiện ghi đủ 2 chiều;
     điều kiện lọc ghi giá trị thật (RLSTATUS = '02'); ghi rõ điểm gọi API/commit/
     update bảng Z; thay đổi dữ liệu nghiệp vụ phải qua BAPI (ghi rõ tên BAPI). -->
