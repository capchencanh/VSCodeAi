# [DGW] MIGO vẫn cho nhập kho Inbound Delivery chưa duyệt — Enhancement 2.12

- **Dự án / Tcode:** DGW — MIGO (A01 Goods Receipt / R04 Inbound Delivery)
- **Ngày điều tra:** 28.09.2026
- **Trạng thái:** ĐÃ TÌM RA NGUYÊN NHÂN + BA ĐÃ TÁI HIỆN TRÊN DEV — **ĐÃ SỬA CODE LOCAL 28.09.2026** (mục 9), chờ đưa lên DEV + syntax check + test

---

## 1. Tóm tắt 1 câu

Check duyệt IB trong MIGO lấy số IB từ ô **Delivery Note** trên header; ô này chỉ được điền số IB khi **header (tab General) đang mở** → user thu gọn header thì ô rỗng → check bị bỏ qua → IB chưa duyệt vẫn nhập kho được.

## 2. Yêu cầu FS (Enhancement 12 / 2.12)

Khi Check/Post ở MIGO (A01 + R04):
1. Nhập IB → lấy `LIPS-VGBEL` (PO) → `EKKO-BSART` (PO type).
2. PO type không có trong `ZMM_TB_MAP_VL06I` (view `ZMM_MV_MAP_VL06I`) → không check.
3. `ZZREL_CODE = 1` → `LIKP-ZZAPPROVE` rỗng → lỗi `ZMC_DGW 003` "Inbound XXXX chưa được duyệt".
4. `ZZREL_CODE = 2` → `LIKP-ZZRL_CHUYENKT` hoặc `LIKP-ZZAPPROVE` rỗng → lỗi `ZMC_DGW 045` "Inbound chưa được duyệt đủ cấp".

## 3. Hiện trạng user báo (PRD PS4/100)

- IB `1800097633` chưa duyệt → MIGO Check → "Document is O.K." → cho Post. Chỉ gặp ở một số IB.
- BA gửi thêm IB `1800105663` — đã nhập kho (MIGO_GR, chứng từ `5000078870`, user DCHN2, 25.09.2026 14:55:48) dù PO type Z012 (cấp 1) và `ZZAPPROVE` vẫn rỗng.

## 4. Nguyên nhân gốc — 2 đoạn code custom phụ thuộc nhau

### ① Code check — gây lỗi trực tiếp

Class `ZCL_IM_LE_MB_MIGO_BADI`, method `IF_EX_MB_MIGO_BADI~CHECK_HEADER`
(bản local: [IF_EX_MB_MIGO_BADI~CHECK_HEADER.abap](../DGW_VL33N_ENHANCE/MIGO_ENHANCE/IF_EX_MB_MIGO_BADI~CHECK_HEADER.abap))

```abap
" dòng 51 — chỉ check khi ô Delivery Note có giá trị
IF <LFS_GOITEM> IS ASSIGNED AND <LFS_GOHEAD>-XBLNR IS NOT INITIAL.
  SELECT SINGLE MAP~ZZREL_CODE ...
    WHERE LIPS~VBELN = @<LFS_GOHEAD>-XBLNR     " dòng 57 — tìm IB theo XBLNR
  ...
  SELECT SINGLE ZZRL_CHUYENKT, ZZAPPROVE FROM LIKP
    WHERE VBELN = @<LFS_GOHEAD>-XBLNR.         " dòng 64
```

Lịch sử: bản đầu (danhdh 25.05.2026) lấy số IB từ `GOITEM-VLIEF_AVIS` (số IB trên item, luôn có). KhoaLD 05.06.2026 đổi sang `GOHEAD-XBLNR`, danhdh 25.08.2026 giữ nguyên `XBLNR` → từ đó check phụ thuộc ô Delivery Note.

### ② Code điền ô Delivery Note — điều kiện gây lỗi

Enhancement implementation **`ZENH_MIGO_COPY_IB_REF`** (HuyLN) trong function group `MIGO` (program `SAPLMIGO`):

| Phần | Include / vị trí | Nội dung |
|---|---|---|
| Enh 2 | `LMIGOTOP` (cuối include) | `DATA: GV_INBOUND_DELIVERY TYPE GODYNPRO-INBOUND_DELIVERY.` |
| Enh 3 | `LMIGOFL3` — đầu `LCL_MIGO_FIRSTLINE→LIF_MIGO_FRAME~OKCODE_HANDLER` | `GV_INBOUND_DELIVERY = GODYNPRO-INBOUND_DELIVERY.` (luôn chạy) |
| **Enh 1** | `LMIGOHG2` — **cuối `LCL_MIGO_HEADER_GENERAL→PBO`** | A01/R04 + IB tồn tại trong LIKP → `GOHEAD-LFSNR = GV_INBOUND_DELIVERY` |

SAP chuẩn trong `LCL_MIGO_HEADER_GENERAL→PAI` (cùng include `LMIGOHG2`):

```abap
gohead-xblnr = gohead-lfsnr.
```

→ PBO/PAI của `LCL_MIGO_HEADER_GENERAL` **chỉ chạy khi tab General của header đang hiển thị**.

### Chuỗi gây lỗi

```
User thu gọn header (chỉ còn nút "Head.data") hoặc đứng ở tab Vendor
  → PBO/PAI tab General không chạy → Enh 1 không điền LFSNR, XBLNR không được gán số IB
  → XBLNR giữ giá trị SAP chuẩn: LIKP-LIFEX (External ID) nếu có, không có thì RỖNG
  → CHECK_HEADER: XBLNR rỗng → bỏ qua check (hoặc XBLNR = LIFEX → SELECT LIPS không ra dòng → bỏ qua)
  → MIGO báo "Document is O.K." → cho Post
```

MIGO nhớ trạng thái thu gọn/mở header **theo từng user** → lỗi tập trung ở vài user (DCHN2, DGDN1), nên trông như "chỉ một số IB bị".

### Code đã rà, KHÔNG liên quan

- [DELIVERY_FINAL_CHECK.abap](../DGW_VL33N_ENHANCE/IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK.abap): mọi check giới hạn `SY-TCODE = VL31N/VL32N/VL33N` (khối 2.19 chặn GR chỉ khi `SY-UCOMM = 'WABU_T'` trong VL32N/VL33N) → không phải lớp chặn dự phòng cho MIGO. Khối 2.19 lấy số IB trực tiếp `LS_XLIKP-VBELN` → không bị lỗi này.
- [MV50AFZ1.abap](../DGW_VL33N_ENHANCE/MV50AFZ1.abap): chỉ copy `ZZSHD/ZZSERIHD` PO → IB và ngày PGI/billing; không đụng `LIFEX/VERUR/XBLNR`.
- Modification `NghiaNT` (DS4K901384) trong `LMIGOFL3` `MIGO_OK_GO`: `GODYNPRO-DELIVERY_NOTE = GODYNPRO-INBOUND_DELIVERY` — chỉ vào khoá tìm chứng từ tham chiếu, không ảnh hưởng ô Delivery Note trên header.
- Enhancement `ZENH_MIGO_DEFAULT_BUDAT_CAN` (Long.Nguyen, #25637): chỉ A03/R02 gán `BUDAT = sy-datum`.

## 5. Bằng chứng dữ liệu (PRD, chứng từ nhập kho IB bằng MIGO từ 01.09.2026)

Query trong [query_check_migo_ib_chua_duyet.sql](../../sql/query_check_migo_ib_chua_duyet.sql) (ZSQL là ABAP SQL: không `;` cuối câu, chạy 1 câu/lần). File export: [Data/](Data/).

| Ô Delivery Note (MKPF-XBLNR) lúc post | Số chứng từ | Giải thích |
|---|---|---|
| = số IB | 501 | Header mở → Enh 1 chạy |
| = LIFEX (số 6140xxxxxx) | 14 | Header thu gọn, IB có External ID (đều PO type ZPO7, không cần duyệt) |
| **Rỗng** | **58** | Header thu gọn, IB không có External ID → **check bị bỏ qua** |

- Trong 360 chứng từ thuộc PO type phải duyệt: 302 được check, **58 bị bỏ qua**; 57/58 IB hiện đã tick duyệt (không biết duyệt trước hay sau khi nhập kho), **1 IB lọt rõ ràng: `1800105663`** (vẫn chưa duyệt).
- 58 chứng từ rỗng: DCHN2 43, DGDN1 15 (cùng user vẫn có chứng từ đúng → do thao tác màn hình, không do dữ liệu IB).
- Đã loại trừ: `LIKP-LIFEX/VERUR/BOLNR/XABLN` (query 11), `MKPF-TCODE/BKTXT/LE_VBELN`, ngày chứng từ, IB bị sửa sau nhập kho (`LIKP-AEDAT`) — query 13.

Lưu ý cấu hình: `ZMM_TB_MAP_VL06I` **lệch DEV/PRD** — PRD Z012 = cấp 1; DEV Z012 = cấp 2 (DEV: Z001/Z002/Z003/Z012 = 2, Z010/Z011 = 1).

## 6. Tái hiện trên DEV (DS4/110) — BA đã tái hiện thành công 28.09.2026

IB test: `1800000756` (PO `4000000107`, Z001, cấp 2, đã duyệt kho, chưa duyệt kế toán, chưa nhập kho). IB khác: query 10 trong file sql.

**Trường hợp lỗi (header thu gọn):**
1. MIGO → bấm icon thu gọn header (bên trái tab General/Vendor) → chỉ còn nút **Head.data**.
2. A01 Goods Receipt → R04 Inbound Delivery → nhập `1800000756` → Enter.
3. Nhập Storage Location cho các dòng item.
4. Check → **"Document is O.K."**, không có lỗi "chưa được duyệt đủ cấp" ← LỖI.

**Trường hợp đúng (header mở):**
5. Bấm **Head.data** → tab General (ô Delivery Note hiện `1800000756`).
6. Check → lỗi **"Inbound 1800000756 chưa được duyệt đủ cấp"** ← ĐÚNG.

Không Post ở trường hợp lỗi nếu muốn giữ IB để test lại sau khi sửa.

## 7. Hướng sửa đề xuất — CHƯA LÀM, chờ user bảo sửa

1. **`CHECK_HEADER`**: không lấy số IB từ `GOHEAD-XBLNR` nữa; lấy từ dữ liệu luôn có sẵn, không phụ thuộc màn hình: `GODYNPRO-INBOUND_DELIVERY` và/hoặc `GOITEM-VLIEF_AVIS` (fallback `XBLNR` chỉ khi đúng là 1 VBELN có trong LIKP).
   - Cần làm rõ vì sao KhoaLD bỏ `VLIEF_AVIS` ngày 05.06.2026 (nghi `GOITEM` rỗng lúc Check/Post trong 1 số trường hợp). Nếu không chắc → phương án chắc hơn: gom số IB từng dòng qua method `LINE_MODIFY` vào attribute của class implement rồi check ở `CHECK_HEADER`.
   - Test sau khi sửa: cả 2 trường hợp ở mục 6 đều phải ra lỗi 045.
2. **(Cần BA quyết)** `ZENH_MIGO_COPY_IB_REF` dính cùng lỗi: header thu gọn → chứng từ vật tư không có số IB ở ô Reference (58 chứng từ trên PRD). Nếu sửa: chuyển việc gán số IB sang chỗ luôn chạy (không nằm trong PBO/PAI subscreen header).

### Ý kiến BA Tâm (28.09.2026) và đánh giá

| Ý BA | Đánh giá |
|---|---|
| 1. Lấy IB từ ô nhập ở dòng đầu (`GODYNPRO-INBOUND_DELIVERY`) | Không dùng: ô này lúc còn số lúc bị xoá (ảnh DEV IB 1800000756 trống, ảnh Tâm IB 1800003870 còn số); ô gõ được → load IB chưa duyệt, gõ đè số IB đã duyệt, không Enter, bấm Check → lách được |
| 2. Làm cho ô Delivery Note trên header luôn có số IB | Đúng hướng cho ô Reference (58 chứng từ thiếu số IB), nhưng BAdI MIGO không sửa được header, phải debug tìm chỗ điền an toàn; và check vẫn phụ thuộc 1 enhancement khác → tách làm cải tiến riêng, không gộp với check |

**Chốt với user 28.09.2026:** mục tiêu chính là **chặn nhập kho IB chưa duyệt, không phụ thuộc thao tác màn hình của user** → theo đúng FS ("Nhập Inbound Delivery vào LIPS-VBELN" = số IB của chứng từ đang nhập) → lấy số IB từ dữ liệu item qua `LINE_MODIFY` (mục 7.1). Vẫn chờ lệnh sửa + code `LINE_MODIFY`/`LINE_DELETE`/`RESET`/Private Section của `ZCL_IM_LE_MB_MIGO_BADI`.

### Code class hiện tại (user cung cấp 28.09.2026)

Toàn bộ class `ZCL_IM_LE_MB_MIGO_BADI`: [Class/zcl_im_le_mb_migo_badi/](Class/zcl_im_le_mb_migo_badi/) (`CHECK_HEADER` trùng bản trong `DGW_VL33N_ENHANCE/MIGO_ENHANCE`).

- Class **đã dùng sẵn pattern ghi nhớ dòng item** cho CR #34926 (CS.DuyHTK, 14.09.2026, chặn nhập xuất kho không tham chiếu): `MT_TP_LINE` (`ZTT_TP_MIGO_LINE` = LINE_ID + BWART), ghi ở `LINE_MODIFY`, xoá ở `LINE_DELETE`, clear ở `RESET`, `MODE_SET` lưu `MV_TP_ACTION/MV_TP_REFDOC` → cách sửa 7.1 dùng đúng cơ chế đang chạy thật trên hệ thống.
- Dự kiến thêm attribute riêng (vd `MT_IB_LINE`, type khai trong class) thay vì thêm field vào `ZST_TP_MIGO_LINE` → không đụng DDIC/transport của CR khác.
- **Bẫy:** `LINE_MODIFY` có lệnh thoát sớm — dòng 14 `CHECK CS_GOITEM-SMBLN = CS_GOITEM-MBLNR` và dòng 77-79 `RETURN` khi có RSNUM mà không đọc được RESB → code mới phải đặt **đầu method**. (Phát hiện phụ: code CR #34926 ở cuối method bị bỏ qua trong 2 trường hợp thoát sớm này — chưa báo/sửa.)

## 8. Việc cần BA trả lời

- Xử lý IB `1800105663` đã nhập kho khi chưa duyệt thế nào (reverse chứng từ `5000078870`? duyệt bổ sung?).
- Có sửa luôn `ZENH_MIGO_COPY_IB_REF` (mục 7.2) không.
- Bảng `ZMM_TB_MAP_VL06I` lệch DEV/PRD (Z012) có chủ ý không.

## 9. Code đã sửa (28.09.2026 18:02:40) — CHỈ sửa `CHECK_HEADER`

### Debug DEV trước khi sửa (DS4/110, IB 1800000756, breakpoint `CHECK_HEADER` dòng 51)

| Trường hợp | `GOITEM-VLIEF_AVIS` | `GOHEAD-XBLNR` | `GODYNPRO-INBOUND_DELIVERY` | Kết quả Check |
|---|---|---|---|---|
| Thu gọn header + detail **sau khi** nhập IB | 1800000756 | 1800000756 | rỗng | Lỗi 045 (đúng) |
| Thu gọn header + detail **trước khi** nhập IB (thoát MIGO, mở lại) | **1800000756** | **rỗng** | rỗng | Lọt (tái hiện lỗi PRD) |

→ Xác nhận trực tiếp nguyên nhân (XBLNR rỗng); `GOITEM-VLIEF_AVIS` luôn có số IB kể cả khi detail item chưa từng hiển thị → chỉ cần sửa `CHECK_HEADER`. `GODYNPRO-INBOUND_DELIVERY` bị MIGO xoá sau Enter → ý 1 của BA không dùng được.

(Phương án 5 chỗ — attribute `MT_IB_LINE` + `LINE_MODIFY`/`LINE_DELETE`/`RESET` — đã viết rồi **gỡ bỏ** theo yêu cầu user sửa gọn; các file đó đã trả về nguyên bản.)

### Nội dung sửa

File: [check_header.abap](Class/zcl_im_le_mb_migo_badi/public_methods/if_ex_mb_migo_badi~check_header.abap#L91-L143) — **bản user tự chỉnh 28.09.2026 18:04** (file local đã bỏ 6 dòng header export → số dòng file = số dòng SE24). Claude rà lại: logic + cú pháp đúng.

| Dòng | Sửa |
|---|---|
| 48-49 | Giữ `FIELD-SYMBOLS <LFS_GOITEM>` + `ASSIGN ('(SAPLMIGO)GOITEM')` |
| 51-88 | Comment khối cũ (lấy IB từ `XBLNR`) |
| 91-101 | `LV_IBD = <LFS_GOITEM>-VLIEF_AVIS`; dự phòng `XBLNR` nếu đúng là VBELN có trong LIKP |
| 104-142 | Check theo `LV_IBD`: cấp 1 → lỗi 003, cấp 2 → lỗi 045, `MESSAGE_V1 = LV_IBD` |

Marker `"danhdh add begin/end 28.09.2026 18:02:40` (góp ý: thêm marker `"danhdh comment begin/end` cho khối 51-88 + 1 dòng ghi chú lý do). Không đụng method/attribute khác, không đụng `ZENH_MIGO_COPY_IB_REF`.

Giới hạn còn lại: `GOITEM` chỉ là 1 dòng item → nếu 1 chứng từ MIGO gom **nhiều IB khác nhau** thì chỉ check IB của dòng đó. Data PRD 01.09–28.09.2026: 573 chứng từ, mỗi chứng từ đúng 1 IB → chấp nhận được.

Bản `CHECK_HEADER` trong `DGW_VL33N_ENHANCE/MIGO_ENHANCE/` là bản cũ — dùng bản trong `Class/`.

### Test DEV sau khi đưa code lên (IB `1800000756`)

| Trường hợp | Kỳ vọng |
|---|---|
| Thu gọn header + detail **trước khi** nhập IB → Check | Lỗi 045 (trước đây lọt) |
| Header mở → Check | Lỗi 045 |
| IB đã duyệt đủ cấp → Check | Không lỗi |
| PO type không trong `ZMM_TB_MAP_VL06I` → Check | Không lỗi |
| Post IB chưa duyệt, header thu gọn | Bị chặn |
