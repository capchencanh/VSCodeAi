# Ghi chú dự án ZRSD27 — Báo cáo theo dõi tình hình thực hiện gói thầu (Bidiphar)

FS: `FS/BIDIPHAR_FS_SD_ZRSD27_BaoCaoTheoDoiThucHienGoiThau_V1.0.docx` (V1.0, Trần Đoàn Kim Ngân, 24/09/2026)
Đọc FS + viết code + kiểm cú pháp: 08/10/2026. Hướng dẫn tạo object trên hệ: [Program/huong_dan_tao.md](Program/huong_dan_tao.md).
Đã tạo + activate trên DEV/200 cùng ngày (TR `DEVK900376`). Câu hỏi gửi BA (FS thiếu / lệch): [cau_hoi_fs_ZRSD27.md](cau_hoi_fs_ZRSD27.md).

## Đọc trước khi làm tiếp (cập nhật 08/10/2026)

**Trạng thái:** code xong và đã activate trên DEV/200 (TR `DEVK900376`, ATC 0 lỗi / 0 warning). **Đang chờ BA trả lời 5 câu** ở [cau_hoi_fs_ZRSD27.md](cau_hoi_fs_ZRSD27.md); **chưa sửa code sau đó**. Chưa client nào có hợp đồng/hóa đơn nên chưa kiểm được số liệu thật.

**Khi BA trả lời, sửa code theo thứ tự:**
1. Loại hợp đồng cấp 2 → mặc định hoặc giới hạn `S_AUART` (hiện chỉ loại `ZCQ1`, để lọt `ZCQ3`/`ZCQ4`).
2. Danh sách loại hóa đơn (+)/(−) → lọc `FKART` trong `GET_BILLING` (hiện chỉ lọc `VBTYP` M/O).
3. `GET_BILLING`: thêm đường trả hàng từ đơn bán (`VGTYP = C`) và từ hợp đồng (`VGTYP = G`), và kiểm `VBAK-VBTYP = 'H'` của đơn trả trung gian (hiện chỉ đi qua hóa đơn gốc `VGTYP = M`, không phân biệt đơn trả `H` với yêu cầu ghi có `K`).
4. Nguồn Giá trúng thầu (28), Loại hợp đồng cụ thể (12), Ghi chú (49), SPCL (47), tên TDV/ASM (51)(53), trường hợp đồng giấy.
Code đang chạy trên hệ = file local trong `Program/` (chỉ khác header Citek ở chương trình chính). MCP **không ghi được** source trên hệ này (`TK 730`): sửa local, user tự dán lên SE38.

**Cách làm việc đã thống nhất với user:**
- Kiểm cú pháp bằng `SyntaxCheck` mượn `object_url` `/sap/bc/adt/programs/programs/zpg_sd_thcpvc` (class tạm cho `null` cả với code sai, không tin). Kiểm bản đã activate: `SyntaxCheck` trên chính `zpg_sd_tdthgt` (include lấy từ hệ) + `RunATCCheck`.
- Customizing đối chiếu FS thì đọc **client 100** (`RunQuery ... USING CLIENT '100'`); client 200 chưa được transport.
- Code mới: không đánh marker tên/ngày (theo `NOTE/note.md`); TR đặt theo quy ước trong `note.md`.
- User **không cần gợi ý cách test**; chỉ cần đối chiếu đúng FS chưa.
- Tin nhắn gửi BA: ngắn, **chỉ câu chặn code**; mỗi câu chỉ rõ mục / chỉ tiêu / dòng tham số / hình trong FS đang ghi gì và thiếu gì; điểm đã tự giả định gom thành danh sách riêng; không đoán giới tính BA (dùng "bạn / mình"). Ký tên "Đặng Hoàng Danh – Citek".
- Đã mắc 1 lỗi cần tránh: từng ghi cột (12) có ở màn hình tham số — thực tế chỉ có ở Hình 3 (mẫu báo cáo). Trích FS phải kiểm lại đúng hình / mục (tách `word/document.xml`, `comments.xml`), comment "hợp đồng giấy" gắn ở chỉ tiêu (15) chứ không phải dòng tham số.

**Kiểm lại 12/10/2026 (MCP `GUI_BDP_DEV_100`):** 6 object (`ZPG_SD_TDTHGT` + 5 include `ZIN_SD_TDTHGT_*`, gói `ZPK_BDP`) đều active (không có trong danh sách inactive), nội dung trên hệ khớp file local; ATC 0 lỗi / 0 warning, 53 info (chuỗi tiếng Việt chưa có text element — đã gắn `#EC NOTEXT`, bỏ qua). Client 100 vẫn 0 hợp đồng (`VBAK-VBTYP = G`) và 0 hóa đơn (`VBRK`). File FS local vẫn là V1.0 (08/10); chưa có bản FS mới, chưa có trả lời của BA → chưa sửa code.

**Chốt 09/10/2026 — phần FS thiếu, code đang xử lý thế nào (đã rà lại `f01`/`f02` cùng user):** user hỏi "FS thiếu thì để trống phải không" → trả lời: *không phải chỗ nào cũng để trống*.
- **Để trống thật** (cột có trong ALV nhưng không gán giá trị, không có chỗ lấy): (12) `LOAI_CT` — `f02` ~dòng 208; (49) `NOTE` — `f02` ~dòng 252; "hợp đồng giấy" + tham số "Hợp đồng thầy": chưa có cột/tham số.
- **Đã code theo giả định (có dữ liệu ra, khi BA trả lời chỉ sửa điều kiện/nguồn):** (28) giá = `NETPR/KPEIN` dòng hợp đồng (`f01` ~dòng 600); (51)(53) tên TDV/ASM = `PA0001-ENAME`; cấp 2 = mọi hợp đồng `VBTYP G` khác `ZCQ1`; hóa đơn không lọc `FKART`; trả hàng truy qua hóa đơn gốc (`f01` ~dòng 298-312).
- **(47) SPCL:** code đã đọc đặc tính `Z_SPCL` đúng FS (`f01` ~dòng 437); cột trống vì đặc tính chưa có trên hệ, không phải code thiếu.
- Nên gửi BA **cả file** `cau_hoi_fs_ZRSD27.md` (gồm đoạn "Các điểm khác mình đã tự giả định") chứ không chỉ 5 câu, để BA biết mình đã tự chọn gì.
- Chưa kiểm được: số liệu thật (chưa client nào có hợp đồng/hóa đơn), nội dung màn hình 0100 và function code GUI status (MCP không đọc được).

## Tóm tắt

Báo cáo **ALV Grid** (`CL_GUI_ALV_GRID`, giống ZRSD26), chỉ đọc. **1 dòng báo cáo = 1 dòng hợp đồng cấp 2**
(còn hiệu lực trong tháng báo cáo), kèm số liệu thực hiện theo **tháng / quý / năm** lấy từ hóa đơn (VF03).
Có khối tiêu đề phía trên lưới: tiêu đề + ngày chạy + tỷ lệ thực hiện chung.

**Cột động:** số cột năm/quý/tháng sinh theo tháng báo cáo → bảng kết quả tạo lúc chạy bằng RTTI
(`CL_ABAP_STRUCTDESCR=>CREATE`), field catalog dựng theo cùng danh sách cột:
- Các năm cũ (trước năm liền trước): chỉ cột "Số lượng năm / Thành tiền năm", từ năm sớm nhất có hóa đơn.
- Năm liền trước: 12 tháng, 4 quý (sau tháng 3/6/9/12), tổng năm.
- Năm báo cáo: tháng 1 → tháng báo cáo, quý chỉ hiện khi đủ quý.
- Sau đó 4 cột lũy kế (thực hiện / chưa thực hiện đến ngày cuối tháng) rồi các cột PO, nhóm, TDV, ASM.

## Code (`Program/`)

`zpg_sd_tdthgt.abap` (chính) + `zin_sd_tdthgt_top` / `_pbo` / `_pai` / `_f01` (logic) / `_f02` (ALV + cột động).
Tên chương trình theo mẫu `ZPG_SD_<viết tắt>` (ZRSD26 = `ZPG_SD_THCPVC`); `TDTHGT` = Theo Dõi Thực Hiện Gói Thầu.

Luồng `GET_DATA`: phân quyền → dòng hợp đồng (1 câu SQL JOIN) → hóa đơn (2 câu SQL GROUP BY) →
quy đổi đơn vị + gộp theo tháng → dữ liệu phụ (tên KH, nhân viên, SPCL, PO báo giá) → cột động → ghép từng dòng.
Không dùng `FOR ALL ENTRIES`; lọc theo danh sách key bằng `JOIN @itab` (skill `abap-performance-hana`).

## Kết quả kiểm tra trên DEV/200 (08/10/2026)

| Mục | Kết quả |
|---|---|
| Object ZRSD27 / `ZPG_SD_TDTHGT` / Tcode `ZRSD27` | Lúc kiểm đầu tiên: chưa có (Tcode hiện có `ZRSD25`, `ZRSD26`). **Sau đó user đã tạo — xem mục "Trạng thái trên hệ"**; package `ZPK_BDP` |
| `VBAK`, `VBAP`, `VBPA`, `VBRK`, `VBRP` | Đủ field cần dùng (`GUEBG`, `GUEEN`, `VGBEL`, `VGPOS`, `VGTYP`, `AUBEL`, `AUPOS`...) |
| Dữ liệu | **`VBAK` rỗng** — chưa có hợp đồng/hóa đơn nào → chưa chạy thử kết quả thật |
| Authorization | `V_VBAK_VKO` = VKORG, VTWEG, SPART, ACTVT; `V_VBAK_AAT` = AUART, ACTVT |
| Loại hợp đồng (`VBTYP = G`) | Client 200: `AD1 GCQ GVC JSDQ KM MV PHAM VBOS WK1 WK2 WV` — **không có `ZCQ1`** (customizing chưa transport). **Client 100 có `ZCQ1` HĐ thầu cấp 1, `ZCQ2` HĐ thầu cấp 2, `ZCQ3` HĐ bán hàng, `ZCQ4` HĐ bán XK** |
| Partner function | DB lưu `AG` (Sold-to), `VE` (Sales employee), `KM`; `SE`/`SP` trong FS là tên hiển thị. **Client 100: `KM` = "ASM"** (client 200 còn tên chuẩn "Credit manager") |
| `PA0001`, `CABN` (`Z_SPCL`), condition type "giá trúng thầu" | Rỗng / không có |
| `VND` | `TCURX-CURRDEC = 0` → cột tiền tham chiếu `WAERS` để hiện không số lẻ |
| Kiểm cú pháp | `SyntaxCheck` mượn `object_url` `zpg_sd_thcpvc` (đã bật Fixed point), kiểm bản gộp 5 include: lần cuối **0 lỗi** (còn 4 warning về bảng khóa phụ trợ, đã sửa bằng bảng SORTED + `INSERT`; phần sửa đó kiểm riêng lại → sạch). Sau khi user activate: `SyntaxCheck` trên object thật sạch; ATC 0 lỗi / 0 warning / 53 info |

## Trạng thái trên hệ (đối chiếu qua MCP 08/10/2026, sau khi user tạo object)

- **Object:** `ZPG_SD_TDTHGT` (executable, Fixed point = X, Unicode = X) + 5 include `ZIN_SD_TDTHGT_TOP/PBO/PAI/F01/F02`, Tcode `ZRSD27`
  (program `ZPG_SD_TDTHGT`, screen 1000, mô tả "Bao cao theo doi thuc hien goi thau"), screen 0100 + 1000 đã generate, GUI status/title có
  (`D345T` lưu 08/10/2026 14:31). Tất cả `R3STATE = A`; không có object inactive.
- **Transport:** `DEVK900376` (workbench, đang modifiable), mô tả `DanhDH_SD_ZRSD27_08.10.2026_BC theo doi thuc hien goi thau` — đúng quy ước `NOTE/note.md`;
  chứa 6 PROG + TRAN `ZRSD27`.
- **Source trên hệ = file local:** số dòng trong cảnh báo ATC khớp file local từng chỗ. Khác duy nhất: chương trình chính trên hệ có thêm khối header Citek
  (template SE38), file local `zpg_sd_tdthgt.abap` chưa có.
- **Kiểm tra:** `SyntaxCheck` trên object thật (include lấy từ hệ) sạch. `RunATCCheck`: 0 lỗi, 0 warning, 53 info (SLIN 1700/1713 *"Strings without text elements
  are not translated"* ở `BUILD_COLUMNS`, `ADD_YEAR_BLOCK`, `BUILD_FIELDCAT`, `BUILD_TOP_DOC`) — không chặn. Không có SLIN 0701 → GUI status `STANDARD`
  và title `TITLE` tồn tại.
- **Chưa xác nhận được qua MCP:** nội dung screen 0100 (`D021S`/`D022S` bị chặn quyền; `CallRFC`/`GetTextElements`/`GetVariants`/`RunReport` lỗi WebSocket `ZADT_VSP`)
  → chưa biết Custom Control có đúng tên `CONTAINER` và function code của status không.

## Điểm lệch / rủi ro tìm thấy khi đối chiếu customizing client 100 (08/10/2026)

Client 100 ("Development & Config") mới có customizing; client 200 chưa được transport. Đọc bằng `RunQuery ... USING CLIENT '100'`. 5 câu bắt buộc + danh sách giả định gửi BA (kèm vị trí trong FS): [cau_hoi_fs_ZRSD27.md](cau_hoi_fs_ZRSD27.md); các giả định còn lại (mục "Giả định") chưa gửi.

1. **Phạm vi loại hợp đồng:** `ZCQ1` HĐ thầu cấp 1, `ZCQ2` cấp 2, `ZCQ3` HĐ bán hàng, `ZCQ4` HĐ bán XK. Code chỉ loại `ZCQ1`; tham số (4) để trống sẽ lọt `ZCQ3`/`ZCQ4` và mọi loại hợp đồng chuẩn khác.
2. **Liên kết cấp 1 → cấp 2:** `TVCPA` không có dòng nào có đích `ZCQ1`–`ZCQ4` → chưa tạo được hợp đồng bằng tham chiếu; `VBAP-VGBEL` của cấp 2 sẽ không trỏ cấp 1 → cột/tham số cấp 1 rỗng.
3. **Loại hóa đơn:** category M gồm `ZFT*` (bán), `ZFB*` (KM/tặng/hàng mẫu/TDNB), `ZFK*` (ký gửi), `ZFD*`, `F2`; category O gồm `ZFR*`/`ZFW*` (trả hàng), `ZFC*`
   (điều chỉnh giảm công nợ/CKTM/giảm giá/CK tiền, sinh từ yêu cầu ghi có `ZCR*` `VBTYP = K`), `ZFXN` (đổi hàng). Code chỉ lọc theo `VBTYP` nên (+) lọt hóa đơn KM/ký gửi; (−) có thể trừ nhầm `ZFC*`.
4. **Đơn trả hàng** (`VBTYP = H`: `ZRE1 ZRE5–ZRE8 ZREA ZRB1 ZRB2 ZKR`) tạo được từ hóa đơn `F2` (chỉ loại này), từ đơn bán (`ZOR*`, `ZBT*`, `TA`…) và từ hợp đồng `ZCQ2` (`ZRE1 ZRE7 ZREA`).
   Code (`GET_BILLING`, câu SQL thứ 2) chỉ truy đơn trả → hóa đơn gốc → đơn bán → hợp đồng và không kiểm `VBAK-VBTYP = 'H'` của đơn trung gian → sót trả hàng tạo từ đơn bán/hợp đồng, có thể lẫn yêu cầu ghi có (`K`).
5. **Dữ liệu nền chưa có:** `TVV1` (Customer group 1) rỗng; không có condition type "giá trúng thầu" (chỉ `PR00`, `ZRRW`, `ZRWR`, `ZRWT`, `ZRT1`…); `CABN` không có `Z_SPCL`; `PA0001` rỗng (client 100 và 200);
   không client nào (050/100/200/300/500) có hợp đồng hay hóa đơn (`VBAK` = 0) → chưa kiểm được số liệu thật.
6. **Đã khớp FS:** `T189T` = hình thức thầu (P1 Thầu Sở y tế/TTYt … PE Kênh dịch vụ) đúng cột (11); `KM` = "ASM"; `VKORG` = chi nhánh.

## Lệch so với FS — đã xử lý theo hệ thật

1. **`VBKD-KVGR1` KHÔNG tồn tại** (FS ghi *"VBKD-KVGR1, đọc với POSNR '000000'"*). Trên hệ `KVGR1` nằm ở **`VBAK-KVGR1`**
   (cùng họ với `KVGR2` đã gặp ở ZRSD26). → Tỉnh thành (13) và cột (6) lấy `VBAK-KVGR1`. Cần báo FS sửa.
2. **Partner function:** FS ghi `SP`, `SE` (tên hiển thị tiếng Anh); DB lưu `AG`, `VE`. `KM` giữ nguyên (FS gọi là ASM,
   DEV đang là "Credit manager"). Hằng số ở đầu `zin_sd_tdthgt_top.abap` (`GC_PARVW_*`).

## Giả định chưa được FS xác nhận (đã code theo hướng hợp lý — cần BA/FS chốt)

1. **Liên kết hóa đơn ↔ dòng hợp đồng:** FS ghi "Số HĐ cấp 2 + Material". Code gắn **theo dòng hợp đồng**:
   hóa đơn → `VBRP-AUBEL/AUPOS` (đơn hàng) → `VBAP-VGBEL/VGPOS` (dòng hợp đồng, `VGTYP = G`). Nếu 1 hợp đồng có 2 dòng
   cùng mã hàng thì mỗi dòng nhận số liệu riêng (khác cách gộp theo Material).
2. **Hóa đơn trả hàng:** hóa đơn trả (`VBTYP = O`) → đơn trả → hóa đơn bán gốc (`VBAP-VGTYP = M`) → đơn hàng → dòng hợp đồng,
   trừ vào số lượng/thành tiền. Nếu đơn trả tham chiếu thẳng đơn hàng (không qua hóa đơn) thì chưa tính.
3. **Hóa đơn hủy:** loại hóa đơn đã bị hủy (`VBRK-FKSTO = X`) và không lấy chứng từ hủy (`VBTYP N, S`) → trừ đúng bằng 0, không cần xử lý dấu.
   Chỉ lấy `VBTYP = M` (+) và `O` (−); không lọc theo loại hóa đơn (`FKART`).
4. **Quy đổi đơn vị:** số lượng hóa đơn quy về đơn vị của dòng hợp đồng (`VBAP-ZIEME`, thiếu thì `VRKME`) bằng
   `MD_CONVERT_MATERIAL_UNIT`; lỗi quy đổi thì giữ nguyên số lượng.
5. **Giá trúng thầu (28):** FS ghi *"Conditions → Giá trúng thầu (chưa VAT)"* nhưng DEV không có condition type nào tên đó.
   Tạm lấy **`VBAP-NETPR / KPEIN`** (đơn giá thuần). Khi biết condition type thật thì đổi cách lấy.
6. **Thành tiền năm cũ (32):** = số lượng năm × giá (28) đúng FS; còn thành tiền năm liền trước (38) = tổng 12 tháng (FS).
7. **Số tháng tròn (21)(22):** tính cả ngày cuối (`GUEBG` → `GUEEN + 1`, trừ 1 nếu ngày kết thúc < ngày bắt đầu);
   (22) chặn không vượt (21); (23) = (21) − (22). FS (23) ghi nhầm "Số tháng còn lại − Số tháng đã thực hiện".
8. **Hợp đồng cấp 1:** là hợp đồng loại `ZCQ1` được dòng hợp đồng cấp 2 tham chiếu (`VBAP-VGBEL`). Hợp đồng `ZCQ1` bị **loại khỏi
   dòng báo cáo** (khóa báo cáo là cấp 2). Hợp đồng không có cấp 1 vẫn lên báo cáo, các cột cấp 1 để trống.
9. **Số báo giá (13):** `VBAK-VGBEL` của hợp đồng cấp 2 khi `VBAK-VGTYP = B`; không có thì lấy từ hợp đồng cấp 1. PO (43): ưu tiên PO hợp đồng cấp 1, sau đó PO báo giá.
10. **Mã chi nhánh (2) / Chi nhánh (4):** FS ghi *Sales Org* (`VBAK-VKORG`) + diễn giải `TVKOT`, nhưng tham số "Chi nhánh" lọc `VBAK-VKBUR`
    (Sales Office) — hai nguồn khác nhau. **[ĐÃ KIỂM 08/10/2026, client 100]** Sales Org chính là chi nhánh (`TVKOT`: 1101 Chi nhánh Hà Nội, 1102 Nghệ An… 1112 Hải Phòng, 1000 trụ sở) và Sales Office dùng cùng mã (`TVKBT`) → không lệch giữa cột và tham số.
    Khu vực (3): `TVGRT` có 100 Miền Bắc / 200 Gia Lai và lân cận / 300 Miền Nam; code hiện **tên** (CHAR 20 theo FS), không hiện mã — BA chưa xác nhận mã hay tên.
11. **Tỉnh (5)** = tên vùng (`T005U`) của `ADRC-REGION` qua `KNA1-ADRNR`; **Nhóm (46)** = tên nhóm vật tư (`T023T`), **Nhóm tác dụng dược lý (48)** = tên `T179T` của `MARA-PRDHA` (độ dài CHAR 20/40 của FS khớp text, không khớp mã).
12. **Tên TDV/ASM (51)(53):** `PA0001-ENAME` còn hiệu lực tại ngày cuối tháng báo cáo (`PA0001` rỗng trên DEV).
13. **SPCL (47):** đặc tính `Z_SPCL` của vật tư (`AUSP`/`CABN`, class type `001`) — chưa có trên DEV nên chưa kiểm chứng.
14. **Tỷ lệ thực hiện ở tiêu đề:** FS chỉ có hình mẫu (58,420 %). Tính = Σ thành tiền thực hiện (40) / Σ thành tiền trúng thầu (30) × 100 trên các dòng đang hiển thị.
15. **Phân quyền:** lọc im lặng theo tổ hợp (tổ chức bán hàng + kênh + ngành hàng với `V_VBAK_VKO`, loại chứng từ với `V_VBAK_AAT`, `ACTVT = 03`);
    không có quyền với bất kỳ tổ hợp nào thì báo "Không có quyền…". Dùng ngày hiệu lực chứ không dùng ngày chạy để chọn hợp đồng: `GUEEN ≥ ngày đầu tháng` và `GUEBG ≤ ngày cuối tháng`.
16. **Dòng hợp đồng bị từ chối** (`VBAP-ABGRU`) vẫn lên báo cáo — FS không nói loại.

## Phần FS còn thiếu / chưa làm

- **Cột (12) "Loại hợp đồng cụ thể"** chỉ có trong Hình 3 (mục 2.2.2, mẫu báo cáo); **bảng mô tả mục 2.2.3 nhảy từ (11) sang (13)** và mục 2.2.1 không có tham số tương ứng → cột có mặt nhưng để trống.
- **Chỉ tiêu (15) "Số hợp đồng cấp 2"** (mục 2.2.3) đang ghi y hệt (14): *"Reference document: VBAP-VGBEL của dòng hợp đồng, với VBAP-VGTYP bằng 'G'"* (copy nhầm); tham số cùng tên ghi `VBAK-VBELN`. Code dùng `VBAK-VBELN`.
- **Cột (49) "Ghi chú"** (Additional Data) — không tìm thấy field/text ID trên hệ → để trống.
- **Trường "hợp đồng giấy":** 2 comment trong FS (gắn ở **chỉ tiêu (15)**, không phải ở dòng tham số): *"Bổ sung trường hợp đồng giấy → dạng Custom Field trên VA23"* và *"Trường hợp đồng giấy không bắt buộc khi tạo Hợp đồng"*. Dòng tham số "Hợp đồng thầy" (mục 2.2.1) bỏ trống, không có comment. Chưa có field trên hệ, chưa làm.
- **Tham số "Mã ASM"** có trong bảng tham số + comment FS nhưng không có trên hình màn hình → đặt cuối khối "Chiều phân tích", không đánh số.
- **Tham số (7) "Loại hợp đồng"** FS ghi *"[Screen Field] Loại hợp đồng"* → lọc theo `VBKD-PLTYP` (Price List Type, đúng với chỉ tiêu (11)).
- **Search help số hợp đồng cấp 2** "phụ thuộc tham số (4)": chưa làm (dùng search help chuẩn của `VBELN`); hợp đồng cấp 1 đã có search help chỉ hiện loại `ZCQ1`.
- **Dạng hiển thị "Bảng tính":** như ZRSD26 — vẫn hiện ALV (có sẵn nút Export), kèm thông báo. Chưa có form ZXLWB.

## Việc cần làm tiếp

1. ~~Tạo object trên hệ, activate, chạy ATC~~ — xong 08/10/2026.
2. Gửi [cau_hoi_fs_ZRSD27.md](cau_hoi_fs_ZRSD27.md) cho BA. Sửa code theo trả lời, dự kiến: mặc định/giới hạn loại hợp đồng (`S_AUART`); lọc `FKART` hóa đơn bán/trả;
   `GET_BILLING` thêm đường trả hàng từ đơn bán và hợp đồng + kiểm `VBAK-VBTYP = 'H'`; nguồn Giá trúng thầu / Ghi chú / Loại hợp đồng cụ thể / hợp đồng giấy; ẩn hoặc điền 2 cột đang trống.
3. Khi có dữ liệu thật: so sánh số liệu thực hiện / lũy kế với VF03, đối chiếu hóa đơn trả hàng đúng dòng hợp đồng.
4. Cột/ALV trên dữ liệu lớn (hàng nghìn dòng × ~130 cột): theo dõi bộ nhớ nếu cần giảm số cột.
