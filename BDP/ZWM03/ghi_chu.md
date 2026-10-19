# ZWM03 – Phiếu nhập kho (chương trình ZWM_PG_PNK)

FS: `FS/BIDIPHAR_FS_EWM_ZWM03_PhieuNhapKho_v1.0.docx` (v1.0). Source ECC: `CODE_FINAL/zwm_pg_pnk` (OneDrive Citek Bidiphar – BIDIPHAR_ECC). Hệ: S/4 On-Premise, MCP `GUI_BDP_DEV_100` (client 100).

## 0. TRẠNG THÁI (12/10/2026, cuối ngày) – ĐỌC TRƯỚC

**Code xong theo FS, đã ở trên SAP DEV client 100, chưa chạy thử lần nào.** Chờ user nhập/chốt các mục "Còn lại" bên dưới rồi chạy `ZWM03`.

- Local: `Program/zwm_pg_pnk/` (`zwm_pg_pnk.abap` main, `zwm_in_pnk_top.abap`, `zwm_in_pnk_f01.abap`, `dictionary/zwm_st_pnk.md`). Bản SAP khớp bản local. SyntaxCheck chương trình thật: 0 lỗi, 1 cảnh báo `MARC has a replacement object`.
- Đã có trên SAP (TR `DEVK900498`, task `DEVK900499`): structure `ZWM_ST_PNK` (package `ZPK_WM`), message class `ZWM03` (11 message, ngôn ngữ EN, nội dung tiếng Việt), chương trình + 2 include (package `ZPK_BDP`), Tcode `ZWM03` → `ZWM_PG_PNK`, Text Symbols 001–003 + 16 Selection texts (ngôn ngữ EN, mỗi text ≤ 30 ký tự – giới hạn của SE38), 4 Smart Form active: `ZWM_SF_PNK`, `ZWM_SF_PNK_OP2`, `ZWM_SF_PNK_OP3`, `ZWM_SF_PNK_OP4` (đã đổi `OP3N` → `OP3` cho đồng bộ).
- ALV màn hình trung gian: `CL_SALV_TABLE` toàn màn hình, `set_screen_status( 'STANDARD' )`, handler `lcl_handler=>on_added_function` xử lý `PREV`, `PRINT`, `SELALL`, `DETAIL`, `EXCEL`. Nút `EXCEL` là nút riêng theo FS (xuất `go_alv->to_xml` xlsx → `gui_download`), trùng chức năng `&XXL` chuẩn của ALV; chưa chạy thử. Nếu muốn bỏ thì phải hỏi BA vì FS có ghi nút này.

**Còn lại (làm theo thứ tự):**
1. **GUI status `STANDARD` của `ZWM_PG_PNK`**: đã có (copy từ `ZWM_PG_BBKNHH`), Active, có `PREV`, `PRINT`, `SELALL`, `EXCEL`. **Thiếu nút `DETAIL`** "Chi tiết điều chỉnh" → user thêm ở SE41 (Change, Items 29–35 ô sau `EXCEL`, Normal application function) rồi Activate. Nếu thiếu thì nút Chi tiết điều chỉnh không bấm được.
2. **Data `ZTWM_MVT_GRP` = 0 dòng** → chương trình báo ZWM03-010 và dừng. Là customizing do BA/Key user nhập qua SM30 (FS 2.6.2), cần cả cột `REV_BWART` (MvT đảo 102, 106, 532, 654, 658, Y18–Y21…). Data mẫu: `../ZWM02/FS/BDP_ZTWM_MVT_GRP 2.xlsx`. Bảng dùng chung với ZWM02 (ZWM02 cũng đang chờ).
3. **Chạy thử `ZWM03` và báo lỗi**: kiểm tra màn hình chọn, ALV trung gian (5 nút), in 4 mẫu (form lệch / trống cột nào), song ngữ, bản in lại "lần n", `P_ADJ` bỏ chọn, nút Excel, F4 chứng từ kho (gọi MB51, DEV có thể không có search help).
4. (Tuỳ chọn) STVARV loại S `ZWM03_MTART_KNL` = loại vật tư có retest (ECC Z21); tạo text tiếng Anh cho message class `ZWM03` (SE63); phân quyền role `M_MSEG_WMB`/`M_MSEG_BMB`/`S_TCODE ZWM03`.
5. Gửi BA: 3 câu hỏi mục 3 + thông báo mục "Chỉ thông báo BA" (chưa soạn thành file riêng; user có thể nhờ soạn theo mẫu `cau_hoi_fs_ZRSD27.md`).


## 1. Đối chiếu source ECC với FS – những gì đã sửa

Source ECC **không đáp ứng FS**, viết lại toàn bộ (giữ tên chương trình, đổi tên include theo kiểu ZWM02).

| # | ECC | FS yêu cầu / đã sửa |
|---|---|---|
| 1 | Màn hình chọn chỉ có Chứng từ kho (bắt buộc) + Năm | Thêm Plant (bắt buộc, PID WRK), Ngày HT, MvT, SLoc, NCC, PO, LSX, Người tạo; bắt buộc Chứng từ kho **hoặc** Ngày HT ≤ 31 ngày (ZWM03-002) |
| 2 | Không có tuỳ chọn SL sau điều chỉnh | Checkbox `P_ADJ` (mặc định chọn) |
| 3 | In thẳng, không màn hình trung gian | ALV 1 dòng/chứng từ: Chọn, CT kho, Năm, Ngày HT, MvT, SLoc, NCC/KH, Diễn giải, Số dòng, Có điều chỉnh, Đã in; nút Xem trước / In / Chọn tất cả / Chi tiết điều chỉnh / Excel |
| 4 | Đọc MSEG/MKPF | Đọc `MATDOC` (`RECORD_TYPE = MDOC`), join EKPO/EKKO trong 1 câu |
| 5 | Lấy mọi dòng Debit, XAUTO ≠ X hoặc MvT 309 (cả 2 dòng) | Debit + MvT thuộc `ZTWM_MVT_GRP`; MvT 309 **chỉ** dòng XAUTO = X; loại dòng chứng từ đảo (SMBLN ≠ trống) |
| 6 | Không trừ SL hủy/đảo | Trừ SL dòng đảo (SMBLN/SJAHR/SMBLP, hoặc MvT đảo của bảng qua LFBNR/LFBJA/LFPOS). = 0 → không in (ZWM03-004); chú thích chứng từ đảo cuối bảng |
| 7 | Diễn giải hard-code CASE MvT/SOBKZ/BSART ZP4/ZP5/Plant 1000 | Lấy `TXT_VI`/`TXT_EN` từ `ZTWM_MVT_GRP` (dòng khớp đầu tiên theo SEQNR); nhóm DC nối thêm "mã – tên SLoc cung ứng"; không khớp → Header text + ZWM03-007 |
| 8 | Quyền `M_MSEG_WMB`, `M_MSEG_WWA` (lỗi: xoá theo biến sai), `M_MSEG_LGO` chỉ theo LGORT; không báo số dòng bị loại | `M_MSEG_WMB` (Plant) + `M_MSEG_BMB` (MvT); báo số dòng bị loại (ZWM03-008); loại hết → ZWM03-001 |
| 9 | Header công ty theo Company Code, gọi `ZCORE_FM_GET_PROFILE` với `E_NAME_N_TITLE`, `E_ADDRESS_EN` (**S/4 không còn 2 tham số này → dump**) | Tên, địa chỉ, ĐT, Fax, Website theo Plant; MST theo Company Code; bản song ngữ đọc địa chỉ quốc tế (`I_NATION = 'I'`) |
| 10 | H3 đối tác: KUNNR → LIFNR → KOSTL, rồi 305/315, 101+VGART WF; 671/673 dùng WEMPF | Thứ tự FS: 305/315 kho xuất → lệnh SX ("Phân xưởng " + tên SLoc cấp phát, bỏ "NVL") → STO (SLoc/Plant cung ứng) → KUNNR → LIFNR → KOSTL |
| 11 | Tỷ giá = KURSF × 1000, VND = 1 | Tỷ giá = BKPF-KURSF (bỏ số 0 thừa); không có FI doc thì loại tiền = EKKO-WAERS |
| 12 | Số/ngày HĐ gốc theo MvT 6xx/Z18-20/101 ZP4-ZP5, fallback BKTXT/BLDAT | Theo nhóm: Hàng trả (TH) = text Delivery; Mua hàng (MH) = BKTXT/BLDAT; Sản xuất (SX) = "LSX " + AUFNR; còn lại trống |
| 13 | Nồng độ = 12 đặc tính ZQC_HAMLUONG_A1..B6 + đơn vị | Đặc tính lô `Z_NONG_DO_HL` |
| 14 | Gọi `ZCORE_FM_GET_CRTRT_MULTIVAL` với tham số `EZ_*` (**S/4 không còn → dump**) | Đọc qua `IT_CHARACT` như ZWM02 |
| 15 | Hạn dùng: VFDAT, trống thì QNDAT cho mọi vật tư; nhãn KNL khi MTART Z21 | VFDAT; trống và loại vật tư thuộc STVARV `ZWM03_MTART_KNL` thì QNDAT + nhãn "Hạn dùng/ Ngày KNL" |
| 16 | ĐK bảo quản: đặc tính vật tư `Z_BAO_QUAN` | `Z_BAO_QUAN_BATCH` của lô → MARA-RAUBE → T142T |
| 17 | Không có cột Số lô SAP | Thêm (8a) `CHARG` |
| 18 | Quy đổi: duyệt mọi đơn vị MARM | Theo FS 2.6.4: 2 đơn vị lớn nhất (A, B, C, D); mẫu 4 = SL × tỷ lệ ĐVT nhập, 5 số lẻ. **Tỷ lệ quy đổi lấy bằng `CL_MD_PRODUCT_UNIT_CONVERSION=>CONVERT`** (không tự chia UMREZ/UMREN); phần tách thùng/hộp vẫn tự tính vì FM chuẩn chỉ đổi 1 số lượng sang 1 đơn vị. Không dùng `MD_CONVERT_MATERIAL_UNIT` (kết quả `EKPO-MENGE` chỉ 3 số lẻ, không đủ 5 số lẻ của mẫu 4) và `MATERIAL_UNIT_CONVERSION` (deprecated, class trên là bản thay thế) |
| 19 | Không có nhật ký in, nhãn bản in lại | `ZTWM_PRTLOG` (TCODE = FORMNAME = `ZWM03`, OBJ_KEY = `<MBLNR>/<MJAHR>`, RPT_OPT = mẫu 1–4); lần in ≥ 2 in "Bản in lại – lần n" |
| 20 | Hard-code plant 4000 (long text GRUN), LGORT 1007, one-time vendor/customer | FS không nêu → bỏ (xem mục 3 "Đã bỏ") |
| 21 | 7 Smart Form (4 VI + 3 EN, mẫu 4 không có EN) | 4 form, song ngữ qua nhãn |

## 2. Logic chính / giả định

- **Phạm vi MvT**: chỉ MvT có trong `ZTWM_MVT_GRP` (FS 2.6.1 + flowchart). Bảng rỗng → ZWM03-010 (message thêm ngoài FS) và dừng. MvT có trong bảng nhưng không dòng nào khớp điều kiện (SOBKZ, có LSX, loại PO, item category, Plant) → diễn giải = Header text + ZWM03-007.
- **Mã nhóm**: MH = Mua hàng, SX = Sản xuất, TH = Hàng trả, DC = Điều chuyển (theo thiết kế bảng BA gửi cho ZWM02).
- **Năm chứng từ**: bắt buộc (FS) nhưng chỉ dùng để lọc khi có nhập Chứng từ kho; chỉ nhập Ngày HT thì không lọc theo năm.
- **Ngắt trang**: mẫu 1, 2, 4 mỗi (chứng từ + SLoc) 1 lần gọi form; mẫu 3 các chứng từ đã chọn chung 1 lần gọi, **header lấy theo dòng đầu của chứng từ đầu tiên** (như ECC).
- **Cộng dồn dòng**: cùng chứng từ + vật tư + lô + SLoc, **thêm ĐVT và PO** (FS chỉ ghi vật tư + lô + SLoc; thêm ĐVT để cộng được, thêm PO để cột Số PO không sai).
- **Tiêu đề "chờ kiểm nghiệm"**: mẫu 3 **hoặc** có dòng nhập vào tồn QI (`INSMK = 2`).
- **SL thực nhận**: tính theo SL cơ sở (MENGE) rồi quy về ĐVT nhập theo tỷ lệ của dòng gốc. Bỏ chọn `P_ADJ`: in SL gốc, không loại chứng từ, chú thích "bản đối chiếu".
- **Text ID hàng trả**: tạm dùng ID ECC `ZLF1` (số HĐ), `ZLF2` (ngày HĐ) như ZWM02 – FS ghi "thay ZLF1/ZLF2" nhưng chưa có ID mới. Đổi hằng số `GC_TXT_*` trong TOP khi có.
- **Tên hàng**: MAKT ngôn ngữ VI (`V`), thiếu thì EN; song ngữ thêm EN ở `MAKTX_EN`.
- **NSX**: `Z_NSX` (là số → tên NCC) → MFRNR của MATNR (rồi của EMATN). **Nước**: `Z_NUOC_SX` (mã → tên nước, không phải mã thì giữ nguyên) → MARC-HERKL → nước của NSX.
- **F4 chứng từ kho**: giữ cách ECC/ZWM02 (gọi MB51, lấy PID MBN/MJA). DEV không có search help gắn với MBLNR. Cần thử lại trên DEV.
- **Performance**: không dùng FOR ALL ENTRIES; join MATDOC–EKPO–EKKO trong 1 câu; master data đọc 1 lần bằng `INNER JOIN @itab`; đặc tính lô gọi FM 1 lần/lô.

## 3. Câu hỏi còn mở cho BA

1. **MvT không có trong `ZTWM_MVT_GRP` có in không?** FS 2.6.1: *"Lấy dòng MATDOC có chỉ báo Debit (SHKZG = S) và MvT thuộc ZTWM_MVT_GRP"*, nhưng 2.6.2 lại ghi *"không có trong bảng → Header text (BKTXT)"* và message ZWM03-007 *"Movement Type &1 chưa khai báo trong ZTWM_MVT_GRP – diễn giải lấy theo Header text"*. Code hiện chỉ lấy MvT có trong bảng; ZWM03-007 chỉ hiện khi MvT có trong bảng nhưng không dòng nào khớp điều kiện.
2. **Bảng tham số loại vật tư có retest** – FS (9): *"vật tư thuộc nhóm có retest (ECC: material type Z21 – loại S/4 tương ứng khai báo trong bảng tham số)"*. FS không nói bảng nào. Code tạm dùng STVARV `ZWM03_MTART_KNL`; chưa khai báo thì không lấy Ngày KNL.
3. **Công thức mẫu 4 với nguyên liệu Active Ingredient** – FS 2.6.4 ghi đang là vấn đề mở 3. Code giữ công thức ECC (SL × tỷ lệ quy đổi ĐVT nhập, 5 số lẻ).

### Chỉ thông báo BA (chưa cấu hình / chưa có data, code đã chạy tạm)

- `ZTWM_MVT_GRP` đang 0 dòng trên DEV → ZWM03 chưa chạy được; cần thêm cột MvT đảo (`REV_BWART`) cho các dòng nhập (102, 106, 532, 654, 658, Y18–Y21…).
- Đặc tính lô `Z_NONG_DO_HL`, `Z_QC_DOAM1`, `Z_DO_AM_PKN`, `Z_NSX`, `Z_NUOC_SX`, `Z_BATCH_NSX`, `Z_QUY_CACH_BATCH`, `Z_BAO_QUAN_BATCH` chưa có trên DEV → các cột tương ứng trống.
- Text ID Delivery hàng trả chưa cấu hình → tạm ZLF1/ZLF2.
- `ZTWM_PRTLOG` không có cột máy in (FS có nêu) → chưa ghi (bảng dùng chung).

### Đã bỏ (ECC có, FS không nêu – không hỏi BA)

- Plant 4000 lấy tên hàng từ long text GRUN (trừ MTART Z51/Z62); LGORT 1007 chỉ in mã; nhà cung cấp/khách vãng lai (`ZCORE_FM_GET_PROFILE_SD/_MM`); MvT 671/673 lấy WEMPF.
- `M_MSEG_LGO`: FS ghi "nếu dự án bật" → chưa kiểm.
- Công nghệ form: FS "Adobe Form (đề xuất) hoặc Smartform" → dùng Smartform như ZWM02.

## 4. Khi BA trả lời / khi có dữ liệu

- Câu 1 chốt "in cả MvT ngoài bảng": bỏ điều kiện `bwart IN lr_bwart` trong `GET_DATA` và check `gt_mvt IS INITIAL` ở main.
- Câu 2 có bảng tham số: thay đọc STVARV trong `GET_MASTER_DATA`.
- Có Text ID mới: sửa `GC_TXT_SOHD`, `GC_TXT_NGAYHD`.

## 5. Message class ZWM03 (VI / EN)

| Số | Loại | Nội dung |
|---|---|---|
| 001 | E | Bạn không có quyền trên Plant &1 / Movement Type &2. / You are not authorized for plant &1 / movement type &2. |
| 002 | E | Vui lòng nhập Chứng từ kho hoặc Ngày hạch toán (tối đa 31 ngày). / Enter material document or posting date (max. 31 days). |
| 003 | S | Không có dữ liệu thỏa điều kiện. / No data found. |
| 004 | W | Chứng từ &1 đã được hủy/điều chỉnh toàn bộ, không in. / Document &1 fully reversed/adjusted, not printed. |
| 005 | I | Chứng từ &1 có dòng đã trừ số lượng điều chỉnh (&2). / Document &1 has items reduced by adjustments (&2). |
| 006 | I | Chứng từ &1 đã in &2 lần. Bản in này được đánh dấu "Bản in lại". / Document &1 printed &2 times. This copy is marked "Reprint". |
| 007 | W | Movement Type &1 chưa khai báo trong ZTWM_MVT_GRP – diễn giải lấy theo Header text. / Movement type &1 not maintained in ZTWM_MVT_GRP – header text used. |
| 008 | W | Đã loại &1 dòng không có quyền (Plant &2 / Movement Type &3). / &1 items removed – no authorization (plant &2 / mvt &3). — thêm ngoài FS (mục Phân quyền yêu cầu báo số dòng bị loại) |
| 009 | E | Chưa chọn chứng từ. / No document selected. — thêm ngoài FS |
| 010 | S | Bảng ZTWM_MVT_GRP chưa khai báo Movement Type nào. / No movement type maintained in ZTWM_MVT_GRP. — thêm ngoài FS |
| 011 | S | Các chứng từ đã chọn không có điều chỉnh. / Selected documents have no adjustments. — thêm ngoài FS |

## 6. Interface Smart Form (4 form)

Import `GS_PARAMETER TYPE ZCORE_ST_PARAMETER`; Tables `IT_DATA LIKE ZWM_ST_PNK`. Nhãn song ngữ đã ghép sẵn dạng "Việt/ Anh" khi chọn In song ngữ.

| Field GS_PARAMETER | Nội dung |
|---|---|
| LOGO | `ZLOGO_0001` |
| HEADER01–06 | (H1) Tên Plant (in hoa), địa chỉ, "Điện thoại: …", "Fax: …", "MST: …" (theo Company Code), "Website: …" |
| HEADER39 / HEADER40 | Tên / địa chỉ quốc tế của Plant (chỉ song ngữ) |
| TITLE_REPORT / TITLE_REPORT_EN | (T1) Tiêu đề VI / EN (EN chỉ khi song ngữ) |
| HEADER08 | (H2) "Ngày dd tháng mm năm yyyy" |
| HEADER09 / 10 | Nhãn / (H3) tên NCC – KH |
| HEADER12 / 13 | Nhãn / (H4) mã NCC – KH |
| HEADER14 / 15 | Nhãn / (H5) địa chỉ |
| HEADER16 / 17 | Nhãn / (H6) MST |
| HEADER24 / 30 | Nhãn / (H7) loại tiền |
| HEADER23 / 31 | Nhãn / (H8) tỷ giá |
| HEADER19 / 32 | Nhãn / (H9) số chứng từ kho (mẫu 3 trống) |
| HEADER20 / 33 | Nhãn / (H10) số chứng từ kế toán |
| HEADER21 / 26 | Nhãn / (H11) "mã – tên SLoc" |
| HEADER22 / 34 | Nhãn / (H12) số hóa đơn gốc |
| HEADER25 / 35 | Nhãn / (H13) ngày hóa đơn gốc |
| HEADER27 / 28 | Nhãn / (H14) diễn giải |
| PARAMETER01–16 | Tiêu đề cột (1) STT … (14) ĐK bảo quản, (15) Chứng từ kho = PARAMETER16; PARAMETER09 = Số lô SAP; PARAMETER10 đổi thành "Hạn dùng/ Ngày KNL" khi có dòng lấy Ngày KNL |
| FOOTER01 / 02 / 04 | Người lập phiếu / Thủ kho / Trưởng bộ phận |
| SIGN01 | Mẫu 3: "Người lập phiếu/ Người giao" |
| SIGN02 | "(Ký, ghi rõ họ tên)" |
| FOOTER05 | "Ngày ….. tháng ….. năm …….." |
| FOOTER03 | (F1) "In lúc: dd/mm/yyyy hh:mm:ss – User: …" |
| FOOTER06 | "Trang" (form tự in x/y) |
| FOOTER07 | "Bản in lại – lần n" (lần đầu trống) |
| ISO_LINE01 | "Lần in: 1" / "Bản in lại – lần n" (góc phải trên như hình 4 FS) |
| LONG_TEXT1 | Chú thích cuối bảng: "Số lượng đã trừ chứng từ điều chỉnh: …" hoặc "bản đối chiếu" khi bỏ chọn SL sau điều chỉnh |

Cột theo mẫu (FS 2.5): mẫu 1 (1)–(12) gồm (8a); mẫu 2 (1)–(4), (7)–(14); mẫu 3 (1), (15), (3), (4), (7)–(14); mẫu 4 như mẫu 2. A4 ngang, lề trái 2 cm, còn lại 1,5 cm.

Bố cục form đã sinh: 1 table trong MAIN (rộng 26,2 cm). Header event = folder chỉ trang đầu (logo + đơn vị + lần in, tiêu đề + ngày, khối thông tin) + dòng tiêu đề cột lặp mỗi trang. Main = dòng chi tiết. Footer = chú thích điều chỉnh (khi có) + ngày ký + 3 ô ký (giữ cùng trang). Window phụ: FOOTER03 + FOOTER07 (trái), "Trang x/y" (phải). Mẫu 3 theo hình 5 FS: khối thông tin chỉ có NCC/KH, mã, nhập tại kho, số HĐ gốc, diễn giải.

Điểm chưa xác nhận của form: font theo style `ZCORE_STYLE_REPORT` (tiêu đề `B5` 15 pt, FS ghi 16); Hạn dùng in đủ ngày theo định dạng user (hình FS chỉ in tháng/năm); logo `ZLOGO_0001` cố định như ZWM02 (chưa đọc `GS_PARAMETER-LOGO`).

## 7. Bắt đầu phiên mới

1. Đọc `CodeABAP/BDP/NOTE/note.md` rồi file này (mục 0).
2. Hỏi user đã làm tới bước nào ở mục 0 (đã thêm nút `DETAIL` chưa, BA đã nhập `ZTWM_MVT_GRP` chưa, đã chạy thử chưa, kết quả/lỗi thế nào). MCP `GUI_BDP_DEV_100` ghi được (EditSource / UpdateObjectAtomic / SetTextElements): sửa code xong SyntaxCheck chương trình thật `/sap/bc/adt/programs/programs/zwm_pg_pnk` (tool chỉ báo lỗi đầu tiên → sửa xong chạy lại); đồng bộ lại file local.
3. Lưu ý khi đẩy: SAP khóa object nếu user đang mở trong SE38 (EU510) → nhờ user thoát; object đã khóa trong TR `DEVK900498` nên dùng đúng TR đó (không dùng task `DEVK900499`). Comment code viết tiếng Việt ngắn (theo `NOTE/note.md`); text elements ≤ 30 ký tự.
