---
name: abap-cloud-naming
description: 'Bảng quy ước đặt tên object ABAP Cloud/UI trong project này (Z##_PK_, Z##_I_, Z##_C_, Z##_CL_, Z##_UI_, Z##_BC_, Z##_IAM_...). TRIGGER — chỉ đọc khi sắp ĐẶT TÊN cho object MỚI sẽ tạo (package, CDS, class, table, data element, behavior definition, service definition/binding, IAM/business catalog, SAPUI5 repository), hoặc khi kiểm tra 1 tên đề xuất có đúng convention/đúng độ dài cho phép không. SKIP — không đọc khi: đọc/sửa/debug object ĐÃ TỒN TẠI (tên có sẵn rồi), hỏi cú pháp - logic - performance ABAP/CDS, tra cứu package, hoặc bất kỳ việc gì không sinh ra tên object mới.'
user-invocable: true
disable-model-invocation: false
---

Khi tạo mới object ABAP Cloud, đặt tên theo đúng convention dưới đây (`##` = mã Module). Chưa biết mã Module của object → hỏi user trước khi tạo.

### ABAP

| Artifact                  | Type           | Length | Naming convention                       |
| ------------------------- | -------------- | ------ | --------------------------------------- |
| TR, CR                    |                | 30     | `[ABAP]_{name}_{current date}_{t-code}` |
| Package                   |                | 30     | `Z##_PK_`                               |
| Database Table            | Active Table   | 16     | `Z##A_`                                 |
| Database Table            | Draft Table    | 16     | `Z##D_`                                 |
| Data Element              |                | 30     | `Z##_DE_`                               |
| Domain                    |                | 30     | `Z##_DO_`                               |
| Structure                 |                | 30     | `Z##_ST_`                               |
| Table Type                |                | 30     | `Z##_TT_`                               |
| Data Definition           | CDS Model      | 30     | `Z##_I_`                                |
| Data Definition           | CDS Projection | 30     | `Z##_C_`                                |
| Data Definition           | CDS Abstract   | 30     | `Z##_A_`                                |
| Metadata Extension        |                | 30     | Base on CDS                             |
| Behavior Definition       | Managed        | 30     | Base on root CDS Model                  |
| Behavior Definition       | Projection     | 30     | Base on root CDS Projection             |
| Behavior Definition       | Abstract       | 30     | Base on root CDS Abstract               |
| Access Control            |                | 30     | Base on CDS                             |
| Business Catalog          |                | 30     | `Z##_BC_`                               |
| IAM App                   |                | 30     | `Z##_IAM_`                              |
| Restriction Field         |                | 30     | `Z##_RF_`                               |
| Restriction Type          |                | 30     | `Z##_RT_`                               |
| Authorization Field       |                | 10     | `Z##_AF_`                               |
| Authorization Object      |                | 10     | `Z##_AO_`                               |
| ABAP Class                |                | 30     | `Z##_CL_`                               |
| ABAP Interface            |                | 30     | `Z##_IF_`                               |
| ABAP Function Group       |                | 26     | `Z##_FG_`                               |
| ABAP Function Model       |                | 30     | `Z##_FM_`                               |
| Message Class             |                | 20     | `Z##_MC_`                               |
| Number Range              |                | 10     | `Z##_NR_`                               |
| Service Definition        |                | 30     | `Z##_UI_`                               |
| Service Binding           | O2             | 30     | `Z##_UI_*_O2`                           |
| Service Binding           | O4             | 30     | `Z##_UI_*_O4`                           |
| HTTP Service              |                | 30     | `Z##_API_`                              |
| Service Consumption Model |                | 30     | `ZSC_`                                  |
| Communication Scenario    |                | 30     | `ZCS_`                                  |
| Outbound Service          |                | 30     | `ZOS_`                                  |

### UI

| Artifact                     | Type | Length | Naming convention                                       |
| ---------------------------- | ---- | ------ | ------------------------------------------------------- |
| Module Name (directory name) |      | 70     | `Z##_`                                                  |
| Application Title            |      | 70     |                                                         |
| Description                  |      | 70     |                                                         |
| SAPUI5 ABAP Repository       |      | 15     | `Z##_`                                                  |
| Semantic Object              |      | 30     |                                                         |
| Action                       |      | 60     | Report = `REPORT`; Form in = `PRINT`; Function = `CRUD` |
| Title                        |      |        |                                                         |
| Subtitle                     |      |        | Tcode                                                   |
