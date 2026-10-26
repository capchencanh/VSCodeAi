---
name: abap-naming-convention
description: 'Quy ước tiền tố biến ABAP trong project này (Global GV_/GT_/GS_/GC_/<GFS_*>, Local LV_/LT_/LS_/LC_/<LFS_*>, Class MV_/MT_/MS_/MC_/MO_). TRIGGER — chỉ đọc khi đang khai báo biến/internal table/structure/constant/field-symbol MỚI trong code ABAP (report classic hoặc method/FORM), hoặc kiểm tra 1 tên biến đề xuất có đúng convention không. SKIP — không đọc khi: đọc/debug code biến đã có sẵn (không đổi tên hàng loạt), đặt tên OBJECT ABAP Cloud mới (dùng skill `abap-cloud-naming` thay vì skill này), hoặc câu hỏi cú pháp/logic không liên quan đặt tên.'
user-invocable: true
disable-model-invocation: false
---

## Naming Convention cho ABAP

Giả định: bạn chỉ nêu 3 mốc (`<GFS_*>`, `<LFS_*>`, `MT_*`), mình suy ra và bổ sung đầy đủ theo đúng pattern chuẩn ABAP OO (Global/Local/Class-member) đang dùng phổ biến. Nếu team có quy ước khác cho các dòng còn lại, báo mình chỉnh lại.

**Global (khai báo ở top-level report/include, ngoài class):**

| Prefix | Ý nghĩa | Ví dụ |
|---|---|---|
| `GV_` | Global variable | `GV_COUNT` |
| `GT_` | Global internal table | `GT_MATNR` |
| `GS_` | Global structure | `GS_HEADER` |
| `GC_` | Global constant | `GC_STATUS_ACTIVE` |
| `<GFS_*>` | Global field-symbol | `<GFS_ITEM>` |

**Local (khai báo trong FORM/METHOD/FUNCTION):**

| Prefix | Ý nghĩa | Ví dụ |
|---|---|---|
| `LV_` | Local variable | `LV_INDEX` |
| `LT_` | Local internal table | `LT_MAKT` |
| `LS_` | Local structure | `LS_MARA` |
| `LC_` | Local constant | `LC_MAX_ROWS` |
| `<LFS_*>` | Local field-symbol | `<LFS_LINE>` |

**Class (thuộc tính/attribute của class, khai báo trong DATA của class):**

| Prefix | Ý nghĩa | Ví dụ |
|---|---|---|
| `MV_` | Member variable | `MV_KUNNR` |
| `MT_` | Member internal table | `MT_ITEMS` |
| `MS_` | Member structure | `MS_HEADER` |
| `MC_` | Member constant | `MC_DEFAULT_PLANT` |
| `MO_` | Member object reference | `MO_LOG` |

Quy tắc áp dụng chung:
- Áp dụng cho cả On-Premise và Public Cloud. Public Cloud không có report program/include classic, code nằm chủ yếu trong class → thực tế dùng nhóm Local và Class.
- Field-symbol luôn bọc trong `< >`.
- Không trộn scope: biến local trong method không được mang prefix `G_`/`GV_`, và ngược lại.
- Khi refactor code cũ không theo convention này, **không đổi tên hàng loạt** — chỉ áp dụng cho biến/field-symbol mới thêm vào (theo nguyên tắc Surgical Changes ở dưới).
