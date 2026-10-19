# ZWM01 – Phiếu yêu cầu vật tư (chương trình ZWM_PG_PYCVT)

FS: `FS/BIDIPHAR_FS_EWM_ZWM01_PhieuYeuCauVatTu_v1.0.docx` (v1.0, 16/09/2026). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_200` (chỉ đọc được — ghi bị chặn TK 730, user tự dán code).

## 0. TRẠNG THÁI (cập nhật 09/10/2026 ~15:00) — ĐỌC TRƯỚC

**Code: XONG theo FS**, chỉ còn chờ BA 2 câu (mục 4) và dữ liệu cấu hình. Đã kiểm trên DEV 200:
- 7 object chương trình active, SAP khớp file local (chỉ khác vài dòng comment). SyntaxCheck: 0 lỗi, 1 cảnh báo `BWART may contain NULL` (F01 ~dòng 107, bỏ qua được).
- Bảng `ZTWM01_PARAM` (+ SM30) và `ZTWM01_PRTLOG` active. Screen 0100, status `STANDARD`, title `TITLE` có. Smart Form `ZWM_SF_PYCVT` upload + activate 09/10 14:53.
- ATC lần chạy trước: 0 lỗi, 5 cảnh báo (JOIN `T001L` có buffer; `SELECT ZTWM01_PARAM` không WHERE — cố ý; 3 `CATCH` rỗng ở F02) — chưa xử lý, không chặn.

**Việc còn lại:**
1. SM30 `ZTWM01_PARAM` (client 200 đang TRỐNG): nhập `PSA_LGTYP / WNH1 / SX01`. W498, WTK1, mã biểu mẫu GMP: chờ BA.
2. Cập nhật FS theo bảng log mới (mục 6).
3. Chưa test chạy thật được: DEV không có tồn IM/EWM, không có ánh xạ ERP–EWM (mục 2).

## 1. Object

| Object | Ghi chú |
|---|---|
| `ZWM_PG_PYCVT` + include `_TOP`, `_CLS`, `_PBO`, `_PAI`, `_F01`, `_F02` | Package `ZPK_WM` (TOP, F01, main) / `ZPK_BDP` (CLS, PBO, PAI, F02). Dán theo thứ tự top → cls → pbo → pai → f01 → f02 → main |
| Structure `ZWM_ST_PYCVT` | Đủ field màn hình trung gian |
| Bảng `ZTWM01_PARAM` + SM30 (FG `ZFG_WM01_PARAM`) | Tham số: `PSA_LGTYP` (KEY1 = Warehouse, KEY2 = Storage Type PSA), `FORM_CODE` (KEY1 = Plant, PVALUE = mã biểu mẫu). 5 data element `ZDE_WM01_PARAM_*`. Delivery class đang `A` |
| Bảng `ZTWM01_PRTLOG` | Nhật ký in: key MANDT, RSNUM, RSPOS, PRT_NO; RPT_OPT, PRT_USER, PRT_DATE, PRT_TIME, TDDEST. Mỗi lần in, mỗi dòng vật tư 1 bản ghi. Log data changes bật |
| Smart Form `ZWM_SF_PYCVT` | Sinh bằng `Smartforms/gen_zwm_sf_pycvt.py` → `Smartforms/FS_v1.0/ZWM_SF_PYCVT.xml`. **Sửa form thì sửa script rồi sinh lại, chạy `sf_validate.py` trước khi upload.** Các XML ở `Smartforms/` (ngoài `FS_v1.0`) là bản cũ, không dùng |
| FM `ZCORE_FM_GET_COMCODE` | Có sẵn (FG `ZCORE_FG_GLOBAL_FUNCTION`, `ZPK_CORE_GEN`) |
| Message class `ZWM01` (000–007), T-code `ZWM01` | Có |
| Screen 0100 (Custom control `CC_MAIN`, OK code `GV_OK`), status `STANDARD` (copy từ `ZWM_PG_TKBIN`), title `TITLE` | Có |

**Không dùng** `ZTWM_PRTLOG` nữa: bảng dùng chung với `ZWM_IN_BCNXTSL_F03`, `ZWM_IN_BCTK_F03`, `ZMM_IN_ZMF60_F01` (1 dòng/khóa, không có Output device) — đổi cấu trúc sẽ hỏng chương trình khác.

## 2. Giả định / điểm kỹ thuật cần nhớ

- **DDIC MARA/EMARA trên DEV 200 từng lỗi (sáng 09/10)**: `LIKE MARA-x` và `JOIN MARA` trong report classic báo `Inconsistency in the dictionary for structure EMARA/MARA`. Khoảng 14:27 MARA được generate lại, hết lỗi. Code đã né sẵn: `MEINS TYPE MEINS`, bỏ `JOIN MARA` (MTART không dùng).
- **DEV không có dữ liệu**: client 100/200 không có tồn IM (`NSDM_E_MARD/MCHB` = 0), không có ánh xạ ERP–EWM (`/SCWM/TMAPPLANT` = 0) → mọi SLoc bị coi là không quản lý EWM, cột eWM trống, đèn tính theo tồn IM.
- **Warehouse của Plant/SLoc**: `/SCWM/IF_STOCKID_MAPPING->GET_WME_ORG_BY_ERP_LOC`.
- **Tồn eWM** (`I_EWM_PhysStockProd`, quant đổi sang Plant/SLoc bằng `GET_ERP_STLOC`): vật lý = mọi loại tồn (FS "tổng quant"); khả dụng = unrestricted − lượng gán cho WT mở (`I_EWM_OpenWarehouseTasks_2`, Bin nguồn; WT theo HU lấy cả HU); PSA = unrestricted tại Storage Type PSA của Warehouse (theo `ZTWM01_PARAM`), mọi SLoc cùng Plant.
- **Đang giữ cho YC khác**: RESB khác cùng Material + Plant + SLoc (+ Batch nếu dòng có Batch), XLOEK/KZEAR ≠ X, còn SL, BDTER ≤ BDTER dòng đang xét, không trừ chính dòng.
- **Đèn xanh dương**: SAP không có → `ICON_MESSAGE_INFORMATION`. Hình 6 dòng 1 lệch công thức Hình 11 → code theo Hình 11.
- **Lần in** = số lần in của Reservation (FS ghi rõ) = MAX(PRT_NO) trong `ZTWM01_PRTLOG` + 1. Xem trước không ghi log, trừ khi in từ màn hình xem trước. Phiếu loại (2) loại dòng đã có log `RPT_OPT = '2'`.
- **Message ZWM01** đánh số lệch FS 1 số (000 quyền … 007 thiếu cấu hình) → code dùng số của hệ.
- **Loại lệnh (1),(2)**: Order Category 10/40. **Backflush/NO_DISP**: chưa lọc (FS để Technical xác nhận). **Tên hàng**: MAKT theo `SY-LANGU`, LEFT JOIN (không có mô tả thì vẫn lên phiếu).
- **Form**: STT reset mỗi phiếu (`CLEAR GW_STT` đầu Main window); lề dưới 1,5 cm; song ngữ có "(Signature, full name)". Mỗi node điều kiện phải dùng `sf.cond()` riêng (dùng chung → trùng `%CONDITIONn`, activate form văng lỗi GUI).

## 3. Lịch sử sửa chính (09/10/2026)

- Dọn toàn bộ code cũ bị comment (bản gốc lưu ở `Temp/zwm_pg_pycvt_truoc_xoa_comment_09102026/`).
- Theo review FS: MAKT theo ngôn ngữ đăng nhập; STT reset; CLEAR trước READ (thiết bị/kho/tài sản), `GT_T001L` thêm WERKS; tồn vật lý gồm QI/Blocked; nhật ký in sang `ZTWM01_PRTLOG` + Output device (lấy từ `SSF_OPEN` → `JOB_OUTPUT_OPTIONS-TDDEST`); "Làm mới" giữ lựa chọn; message "đã in n lần" cả khi in từ xem trước; validate màn hình chọn chạy cả background; form song ngữ chữ ký + lề dưới.

## 4. Câu hỏi còn mở cho BA

Chỉ hỏi chỗ FS thiếu/trống/đang bàn (quy tắc: `CodeABAP/BDP/NOTE/note.md`).
1. **Dữ liệu cấu hình đang chờ** — FS 2.6.4: *"Storage Type PSA theo Warehouse – WNH1: SX01 (ví dụ theo sheet ZWM01); W498/WTK1: chờ BP chốt"*; *"Mã biểu mẫu GMP theo Plant – Chờ BIDIPHAR cung cấp"*. Code: đọc `ZTWM01_PARAM`, chưa có thì để trống.
2. **MPN** — FS: *"Mã NSX (MPN) – RESB-EMATN"*; *"Tên hàng: Nếu có RESB-EMATN: mô tả của mã MPN; ngược lại MAKT-MAKTX (vấn đề mở 3)"*. S/4 không còn `RESB-EMATN`. Code: cột MPN trống, tên hàng lấy MAKT, `P_MPN` chưa có tác dụng.

Tự xử lý, không hỏi: backflush/NO_DISP (Technical), PSA lấy cả Storage Type (không theo khu cấp phát/PRVBE), số message, SHKZG, dòng giữ không Batch.

## 5. Khi BA trả lời

- Câu 1: chỉ nhập SM30 `ZTWM01_PARAM`, không sửa code.
- Câu 2: cần sửa code — lấy MPN gán vào `ZWM_ST_PYCVT-EMATN` (F01 `FILL_DATA`), tên hàng theo MPN, lọc tồn theo nhà sản xuất khi `P_MPN` (F02 `EVAL_LINE`: chỉ tính lô có Z_NSX = MFRNR của MPN).

## 6. Cập nhật FS (chờ BA/người giữ FS sửa)

BA đã đồng ý dùng bảng riêng `ZTWM01_PRTLOG` (09/10/2026). Cần sửa FS:
- **Mục 2.6.3 Nhật ký in**: "Bảng Z đề xuất ZTWM_PRTLOG: …" → `ZTWM01_PRTLOG`, field: RSNUM, RSPOS, PRT_NO (lần in), RPT_OPT (loại phiếu), PRT_USER, PRT_DATE, PRT_TIME, TDDEST (output device); mỗi lần in, mỗi dòng vật tư 1 bản ghi; bật table logging.
- **Mục 3 Nguồn dữ liệu**, dòng "ZTWM_PRTLOG, ZTWM01_PARAM – Bảng Z mới": đổi `ZTWM_PRTLOG` → `ZTWM01_PRTLOG`; cột tham chiếu "Xem mục 3.5.3, 3.5.4" sửa thành "2.6.3, 2.6.4" (FS đánh số sai).
- (Tuỳ) mục 2.4.1, cột 13 "Tồn tại PSA": "(bảng tham số mục 3.5.4)" → "mục 2.6.4".
