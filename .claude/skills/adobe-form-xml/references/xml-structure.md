# Cấu trúc file XML Adobe Form (SFPI / SFPF) và trạng thái xác nhận

Nguồn: 3 form + 3 interface export thật (SFP → Download) user cung cấp 02.10.2026, để trong skill ở `examples/` (đi kèm skill, ai có skill đều dùng được); mọi điều rút ra đã ghi ở file này.

| Form | Interface (tham số) | Đặc điểm |
|---|---|---|
| `ZAF_BC_NHAN_BARCODE` | `ZIF_BC_NHAN_BARCODE` (`DATA TYPE ZTT_BC_NHAN_BC`) | Tem 80×40 mm, 1 dòng = 1 tem, QR + 6 field, Times New Roman |
| `ZAF_BC_NHAN_BC_LSX_12X16N` | `ZIF_BC_NHAN_BC_LSX` (`DATA TYPE ZTT_BC_NHAN_BC_LSX`; global `LOGO TYPE XSTRING`; Initialization đọc logo SE78) | Tem 120.9×162.56 mm, QR + bảng tĩnh lồng nhau, Arial; context có graphic node nhưng layout **không** dùng |
| `ZFI_AF_PYMT_ORD` (Ủy nhiệm chi) | `ZFI_IF_PYMT_ORD` (`GT_DATA TYPE ZFI_TT_PYMT_ORD`) | Khổ Letter, ảnh PNG mẫu ngân hàng làm nền master page (file 1,3 MB), subform lặp theo dòng, text song ngữ rich text |

2 hệ thống khác nhau; Designer 11.0.1 (tem barcode, ủy nhiệm chi) và 11.0.9 (tem LSX). afgen ghi generator 11.0.1.

## Mục lục
1. Trạng thái xác nhận
2. Upload / Download
3. File interface SFPI
4. File form SFPF — phần values
5. Context (heap)
6. Layout trong SFPF: base64 + CACHE_INFO
7. Context → XML dữ liệu runtime

## 1. Trạng thái xác nhận

| Nội dung | Trạng thái |
|---|---|
| Khung asXML SFPI/SFPF: thẻ, thứ tự, thứ tự heap, base64 | **[CONFIRMED]** afgen đọc → sinh lại khớp từng byte cả 6 file (`af_selftest.py`, 02.10.2026) |
| Packet XDP ngoài template (config, connectionSet, datasets, localeSet, xmpmeta), CACHE_INFO, dataDescription suy từ context | **[CONFIRMED]** khớp từng dòng 3 mẫu |
| Upload **SFPI** do afgen sinh vào SFP + Activate | **[CONFIRMED 07.10.2026]** 2 interface (3 tham số import TYPE table type, global `LOGO XSTRING`, code Initialization đọc logo SE78) upload + activate OK trên 1 hệ S/4 release 816 (BIDIPHAR DEV) — không cần ADS |
| Upload **SFPF** do afgen sinh | **[CHƯA XONG 07.10.2026]** upload form báo "Internal error occurred in SAFP API" (CX_FP_API_INTERNAL), nguyên nhân KHÔNG phải XML: hệ đó chưa có ADS (xem mục 2). Suy ra từ source SAP: file đã qua `CL_FP_HELPER=>CONVERT_XSTRING_TO_FORM` (nếu hỏng sẽ báo "unknown file format" FPUIFB 068) nhưng chưa qua bước ADS → XDP/context chưa được kiểm chứng đầy đủ |
| Upload **SFPF** — hệ thứ 2 (`GUI_BIDIPHAR_DEV100`, release 816) | **[CONFIRMED 07.10.2026]** SFPI upload + activate OK (`FPINTERFACE` state A); SFPF upload báo lại đúng popup "Internal error occurred in SAFP API" tại `CL_FP_HELPER=>SET_NEW_LAYOUT_ID` (raise `CX_FP_API_INTERNAL` sau `COPY_TEMPLATE`). Kiểm ADS qua MCP: `RFCDES` không có destination `ADS`, `FPCONNECT` rỗng (0 dòng) → hệ chưa có ADS, lỗi KHÔNG do XML. Chuyển Basis cấu hình ADS hoặc dùng Smart Form |
| Template XDP afgen sinh, render qua ADS ra bản in đúng | **[TODO]** chưa test (cần ADS) |
| Node context: CONTEXT, LOOP, LOOP_DATA, DATA (generated), GRAPHIC_CONTENT | **[CONFIRMED]** có mẫu |
| Node structure, field đơn, text, address, alternative, single record, text module; điều kiện node; WHERE của loop | chưa có mẫu → afgen không sinh; làm context bằng SFP rồi `inject_layout()` |
| Interface: IMPORT_PARAMETERS, GLOBAL_DATA, INITIALIZATION + OUTPUT_PARAMETERS | **[CONFIRMED]** có mẫu |
| INPUT_PARAMETERS (suy giống OUTPUT: thẻ `FPPARAMETER`), FORMS (suy: thẻ `FPCLINE`) | **[NGHI NGỜ]** chưa có mẫu |
| EXPORT/TABLE_PARAMETERS, EXCEPTIONS, TYPES, FIELDSYMBOLS, REFERENCE_FIELDS | chưa có mẫu, afgen không sinh |
| Tên menu upload trong SFP | **[TODO]** xác nhận trên hệ thống lần đầu upload |
| `TYPE` rỗng = interface ABAP Dictionary-based; `LAYOUT_TYPE=S` = layout chuẩn | suy từ mẫu |

## 2. Upload / Download

- Download: SFP → chọn Form hoặc Interface → nhập tên → Utilities → Download. Tên file SAP đặt: `SFPF_<FORM>.XML`, `SFPI_<INTERFACE>.XML`.
- File **không** chứa tên object (chỉ có trong `connectionSet` của XDP) → tên do người upload nhập.
- **Upload SFPF cần ADS (Adobe Document Services); upload SFPI thì không.** Luồng upload form (`CL_FP_FB_FORM->IF_FP_FB_OBJECT~UPLOAD`): đọc file → `CL_FP_HELPER=>CONVERT_XSTRING_TO_FORM` (sai khung XML → báo "Error occurred when uploading file (unknown file format)") → `SET_NEW_LAYOUT_ID` (gọi ADS qua `CL_FP_TEMPLATE_SERVICES=>COPY_TEMPLATE` để cấp layout ID mới; ADS lỗi/không có → ném `CX_FP_API_INTERNAL` không textid = popup **"Internal error occurred in SAFP API"**) → `CL_FP_WB_FORM=>CREATE`/`SAVE`. Kiểm ADS trước khi upload form: RFC destination `ADS` trong SM59 (`CL_FP` mặc định tên `ADS`) và report `FP_PDF_TEST_00` (test kết nối ADS); qua MCP: `SELECT rfcdest FROM rfcdes WHERE rfcdest LIKE 'ADS%'` (bảng `FPCONNECT` chỉ được điền sau lần kết nối ADS thành công — rỗng = chưa từng nối được). Hệ không có ADS → không upload/tạo được Adobe Form, dùng Smart Form.
- Thứ tự upload: interface → Activate → form (thẻ `INTERFACE` trỏ tới interface đã active) → Activate → mở tab Layout kiểm tra.
- Ngôn ngữ gốc: `LANGUAGE` của FPINTERFACET/FPCONTEXTT/FPLAYOUTT = `E` ở cả 3 mẫu (afgen mặc định `E`).

## 3. File interface SFPI

```
asx:values   VERSION=1, TYPE (rỗng), INTERFACE href,
             INTERFACET/FPINTERFACET: NAME, STATE, LANGUAGE, ID, TEXT (= mô tả interface)
asx:heap     CL_FP_INTERFACE_DATA: CODING, PARAMETERS, GLOBAL_DEFINITIONS, REFERENCE_FIELDS (href), XSD_DEFINITIONS
             CL_FP_REFERENCE_FIELDS: REFERENCE_FIELDS
             CL_FP_GLOBAL_DEFINITIONS: GLOBAL_DATA/SFPGDATA (NAME, TYPING, TYPENAME, DEFAULTVAL, CONSTANT), TYPES, FIELDSYMBOLS
             CL_FP_PARAMETERS: IMPORT_PARAMETERS/SFPIOPAR (NAME, TYPING, TYPENAME, OPTIONAL, BYVALUE, DEFAULTVAL,
                               STANDARD, CONSTANT), EXPORT_PARAMETERS, TABLE_PARAMETERS, EXCEPTIONS
             CL_FP_CODING: INPUT_PARAMETERS, OUTPUT_PARAMETERS/FPPARAMETER, INITIALIZATION/FPCLINE (1 dòng code), FORMS
```

- Mỗi đối tượng con có thêm khối `CL_FP_INTERFACE_DATA_CHANGED/INTERFACE_DATA href` trỏ ngược về interface.
- Khác Smart Forms: interface **không** có tham số chuẩn SAP tự thêm; FM sinh ra tự có `/1BCDWB/DOCPARAMS`, `/1BCDWB/FORMOUTPUT` (xem `abap-call.md`).
- `FPCLINE`: escape XML (`=>` → `=&gt;`), giữ nguyên comment `"` và dấu nháy đơn.
- Logo SE78 (mẫu LSX): global `LOGO TYPE XSTRING` + Initialization gọi `CL_SSF_XSF_UTILITIES=>GET_BDS_GRAPHIC_AS_BMP` (`P_OBJECT 'GRAPHICS'`, `P_NAME` tên ảnh, `P_ID 'BMAP'`, `P_BTYPE 'BCOL'`) + `OUTPUT_PARAMETERS` = `LOGO` → afgen `Interface.logo_bds()`.

## 4. File form SFPF — phần values

`VERSION=1`, `TYPE`, `INTERFACE` = tên interface, `OFFLINEHANDLER`, `DATAPROVIDER`, `FRTYPE`, `CNTSET`, `FNTEMB`, `MIRRORING` (rỗng cả 3 mẫu), `CONTEXT href`, `CONTEXTT`, `LAYOUT href`, `LAYOUTT/FPLAYOUTT` (`NAME`, `STATE`, `LANGUAGE`, `ID`, `DIRTY`, `LAYOUT` = XDP base64, `LAYOUTM` rỗng).

`CONTEXTT/FPCONTEXTT` (NAME, STATE, LANGUAGE, ID, TEXT): mục `ID` rỗng = mô tả form (VD "Ủy nhiệm chi"); mục `ID` = GUID node = mô tả node (VD "Graphic Node GRAPHIC" — mô tả SFP tự đặt).

## 5. Context (heap)

Mỗi node = 1 đối tượng heap: khối `CL_FP_NODE` (`ID` GUID 32 hex hoa, `NAME`, `GENERATED`, `STATE=A`, `CONDITION`, `PARENT`, `SUCCESSOR`, `CHILD` dạng href) + khối riêng theo loại:

| Lớp | Khối riêng | Ghi chú |
|---|---|---|
| `CL_FP_CONTEXT` | `<CL_FP_CONTEXT classVersion="1"/>` | gốc, `NAME=CONTEXT`, không có CONDITION |
| `CL_FP_LOOP` | `TABLE_NAME`, `LOOP_INTO=X`, `WORK_AREA` (= TABLE_NAME), `FIRST_LINE`/`LAST_LINE=0000000000`, `WHERE_CONDITION` href, `SORTED`, `CONTROL_LEVEL` | node bảng = kéo tham số `TYPE <table type>` vào context |
| `CL_FP_LOOP_DATA` | rỗng | con duy nhất của LOOP, luôn tên `DATA` |
| `CL_FP_DATA` | `FIELD` = `<WORK_AREA>-<FIELD>`, `FIELD_LABEL` | con của DATA, `GENERATED=X`, đủ **mọi** field của line type theo thứ tự DDIC |
| `CL_FP_GRAPHIC_CONTENT` | `<CL_FP_GRAPHIC classVersion="1"/>` + `GRAPHIC_FIELD` (biến XSTRING), `GRAPHIC_MIME/MIME` (`image/bmp`), `MIMEFIELD` | ảnh lấy từ biến |

- `CHILD` = con đầu, `SUCCESSOR` = anh em kế tiếp, `PARENT` trỏ ngược.
- Mọi node trừ gốc có 1 `CL_FP_CONDITION` (`NODE` href, `CONDITIONS` rỗng); LOOP có thêm 1 cái cho WHERE.
- Thứ tự heap SAP ghi = duyệt stack LIFO, mỗi đối tượng đẩy tham chiếu theo thứ tự thuộc tính (CONDITION, PARENT, SUCCESSOR, CHILD, [WHERE]), xuất phát [CONTEXT, LAYOUT] → `CL_FP_LAYOUT` luôn đứng đầu heap. Id `oN` tuỳ ý miễn khớp href (SAP xuất id lộn xộn, VD mẫu LSX). afgen tái tạo đúng thứ tự này.

## 6. Layout trong SFPF: base64 + CACHE_INFO

- `LAYOUT` = base64 của file XDP UTF-8 (không BOM), 76 ký tự/dòng, xuống dòng LF, không có LF cuối. Phần còn lại của file nằm trên 1 dòng → không sửa tay.
- XDP: dòng 1 `<?xml ...?>` kết thúc LF, các dòng sau CRLF (Designer ghi vậy).
- `CL_FP_LAYOUT`: `TRANSLATION_TYPE` rỗng, `CACHE_INFO` = `<timeStamp>$<uuid>$0$en_US$v1.0$?` **khớp** thuộc tính `timeStamp`/`uuid` của `<xdp:xdp>` (cả 3 mẫu), `LAYOUT_TYPE=S`, `FORM_TECH` rỗng. afgen và `inject_layout()` luôn đổi cả 2 cùng lúc; `af_validate` báo lỗi khi lệch.
- Form tạo bằng SFP mà chưa mở tab Layout lần nào → chưa có XDP → `inject_layout()` từ chối; mở Layout 1 lần, Save, Download lại.

## 7. Context → XML dữ liệu runtime

SAP gửi ADS 1 XML dữ liệu gốc `<data>`, mỗi node context thành 1 phần tử cùng tên; `dd:dataDescription` trong XDP mô tả đúng cây này (SAP tự sinh khi mở Layout, afgen sinh giống hệt):

```
<data>
  <GT_DATA>            ← LOOP            dd:minOccur="0"
    <DATA>             ← LOOP_DATA, 1 phần tử / dòng   dd:maxOccur="-1"
      <MATNR/> ...     ← DATA field (đủ mọi field, kể cả field layout không dùng)
    </DATA>
  </GT_DATA>
  <GRAPHIC/>           ← GRAPHIC_CONTENT
</data>
```

Đường bind tương ứng: `$.GT_DATA.DATA[*]` (mọi dòng), `$.GT_DATA.DATA[0].MATNR` (dòng đầu), `$.MATNR` (trong subform đã bind vào 1 dòng). Chi tiết: `xdp-layout.md` mục 3.
