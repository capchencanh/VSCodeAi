---
name: authorization-iam
description: 'Phân quyền ABAP & IAM — authorization object/field, AUTHORITY-CHECK, DCL access control, IAM app, business catalog/role, restriction type. TRIGGER — chỉ đọc khi (1) tạo/sửa object phân quyền (authorization object, DCL, IAM app, business catalog, restriction type); (2) viết AUTHORITY-CHECK hoặc logic lọc data theo quyền user; (3) debug "user không thấy data/không vào được app" nghi do phân quyền. SKIP — không đọc khi làm việc với logic nghiệp vụ, CDS/class thường không liên quan quyền, hoặc chỉ đọc-giải thích code.'
---

# Authorization & IAM

Guide for implementing authorization checks and identity/access management in ABAP Cloud and on-premise systems.

## Workflow

1. **Determine the user's goal**:
   - Implementing authorization checks in ABAP code
   - Creating CDS access controls (DCL)
   - Setting up IAM apps, business catalogs, and business roles (ABAP Cloud)
   - Managing PFCG roles (on-premise)
   - Defining custom authorization objects
   - Understanding restriction types

2. **Identify the platform**:
   - ABAP Cloud (BTP or S/4HANA embedded) → IAM apps + business catalogs + `CL_ABAP_AUTHORIZATION`
   - On-premise / Standard ABAP → PFCG roles + `AUTHORITY-CHECK`

3. **Guide implementation** with the appropriate authorization model

## Authorization Models

### ABAP Cloud (BTP / S/4HANA Cloud)

```
IAM App → Business Catalog → Business Role → Business User
                                    ↑
                            Restriction Type (field-level restrictions)
```

### On-Premise (Standard ABAP)

```
Authorization Object → PFCG Role → User Assignment
       ↑
Authorization Fields + Permitted Values
```

## Authorization Checks in Code

### ABAP Cloud — `CL_ABAP_AUTHORIZATION`

```abap
"Check authorization using released API
DATA(lo_auth) = cl_abap_authorization=>check_authorization(
  EXPORTING
    authorization_object = 'Z_MY_AUTH'
    authorizations       = VALUE #(
      ( field = 'ACTVT' value = '03' )    "Display
      ( field = 'ZCARR' value = lv_carrier )
    ) ).

IF lo_auth->is_authorized( ) = abap_false.
  "User not authorized
  RAISE EXCEPTION TYPE zcx_not_authorized.
ENDIF.
```

### On-Premise — `AUTHORITY-CHECK`

```abap
AUTHORITY-CHECK OBJECT 'Z_MY_AUTH'
  ID 'ACTVT' FIELD '03'
  ID 'ZCARR' FIELD lv_carrier.

IF sy-subrc <> 0.
  MESSAGE e001(z_msg) WITH lv_carrier.
  RETURN.
ENDIF.
```

### Activity Values (ACTVT)

| Value | Activity |
| ----- | -------- |
| `01`  | Create   |
| `02`  | Change   |
| `03`  | Display  |
| `06`  | Delete   |
| `16`  | Execute  |

## Authorization Objects

### Creating a Custom Authorization Object

In ADT or `SU21`:

```
Authorization Object: Z_MY_AUTH
  Fields:
    ACTVT  — Activity (standard field, linked to domain ACTIV_AUTH)
    ZCARR  — Carrier (custom field, type S_CARR_ID)
    ZREGN  — Region (custom field, type CHAR4)
```

#### Structure

- **Authorization Class**: Groups related objects (e.g., `Z_TRAVEL`)
- **Authorization Object**: Contains 1–10 authorization fields
- **Authorization Field**: Links to a data element; defines the check dimension

## CDS Access Control (DCL)

CDS access controls define row-level authorization for CDS view entities.

### Basic DCL

```cds
@EndUserText.label: 'Access Control for Travel'
@MappingRole: true
define role ZI_Travel {
  grant select on ZI_Travel
    where ( carrier_id ) =
      aspect pfcg_auth ( Z_MY_AUTH, ZCARR, ACTVT = '03' );
}
```

### Multiple Conditions

```cds
define role ZI_Travel {
  grant select on ZI_Travel
    where ( carrier_id ) =
      aspect pfcg_auth ( Z_MY_AUTH, ZCARR, ACTVT = '03' )
      and ( agency_id ) =
      aspect pfcg_auth ( Z_AGENCY_AUTH, ZAGENCY, ACTVT = '03' );
}
```

Nhiều DCL role cùng grant trên 1 view → quyền là UNION giữa các role, 1 role rộng (vd `_unrestrictedAccess`) làm vô hiệu hoá mọi role hẹp khác trên cùng view. Khi debug "user thấy nhiều/ít data hơn mong đợi", liệt kê HẾT các DCL role đang grant trên view đó (không chỉ role vừa sửa) trước khi kết luận.

### Unrestricted Access

```cds
define role ZI_Travel_Admin {
  grant select on ZI_Travel
    where _unrestrictedAccess;
}
```

### Inherited Access Control

Composition child entity (có `association to parent`) — kế thừa điều kiện của parent thay vì lặp lại:

```cds
define role ZI_Booking {
  grant select on ZI_Booking
    where inheriting conditions from entity ZI_Travel;
}
```

Nếu child có `@AccessControl.authorizationCheck: #CHECK` mà KHÔNG role nào grant (kể cả inheriting) → runtime KHÔNG lọc gì, chỉ warning lúc activate — dễ hiểu lầm là "an toàn theo default", thực ra MỞ TOÀN BỘ data. Xác nhận qua case thật: `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md` mục 6.

### DCL and PRIVILEGED ACCESS

```abap
"Bypass DCL access control when needed (e.g., in background jobs)
SELECT FROM zi_travel
  FIELDS travel_id, description
  INTO TABLE @DATA(lt_all)
  PRIVILEGED ACCESS.
```

`WITH PRIVILEGED ACCESS` KHÔNG được kết hợp cùng JOIN (`INNER JOIN`/path expression) trong cùng 1 FROM clause — lỗi grammar. Nếu logic gốc cần JOIN để lọc, bỏ JOIN khỏi câu SELECT có PRIVILEGED ACCESS, lọc lại bằng ABAP thuần sau đó. Chi tiết + case thật: `.claude/skills/sap-mcp-cloud/reference/_ghichu_mcp_cloud.md` mục 5.

## IAM in ABAP Cloud

### IAM App

Created in ADT, links a service binding to the authorization model:

```
ADT: New → Other → IAM App
Name: Z_TRAVEL_IAM
Type: EXT - External App (for OData services)
Service Binding: ZUI_TRAVEL_O4
```

Assign authorization objects to the IAM App to define which checks apply.

### Business Catalog

Groups IAM Apps into logical bundles:

```
ADT: New → Other → Business Catalog
Name: Z_BC_TRAVEL_MGMT
Description: Travel Management
IAM Apps: Z_TRAVEL_IAM, Z_BOOKING_IAM
```

### Business Role

Created in Fiori app "Maintain Business Roles":

1. Create new business role (e.g., `Z_BR_TRAVEL_MANAGER`)
2. Add business catalogs
3. Configure restriction types (field-level access)
4. Assign business users

### Restriction Types

Define field-level restrictions in business roles:

| Restriction Type | Description                               |
| ---------------- | ----------------------------------------- |
| **Unrestricted** | Full access to all values                 |
| **Restricted**   | Access limited to specified values        |
| **No Access**    | No access to the associated functionality |

Example: A travel manager role might restrict `ZCARR` to only `LH` and `AA`.

## On-Premise: PFCG Roles

### Creating a PFCG Role

1. Open `PFCG` transaction
2. Enter role name (e.g., `Z_TRAVEL_DISPLAY`)
3. **Menu tab**: Add transaction codes, Fiori tiles, or apps
4. **Authorizations tab**: Maintain authorization values
   - Set authorization objects and field values
   - Generate the authorization profile
5. **User tab**: Assign users to the role

### Composite Roles

Bundle multiple single roles:

```
Z_TRAVEL_COMPOSITE (Composite Role)
├── Z_TRAVEL_DISPLAY (Single Role — display only)
├── Z_TRAVEL_EDIT (Single Role — create/change)
└── Z_TRAVEL_ADMIN (Single Role — full access)
```

## RAP Authorization

### Instance Authorization in RAP

```abap
"In behavior definition:
define behavior for ZR_Travel alias Travel
  authorization master ( instance )
{
  ...
}
```

```abap
"In behavior implementation:
METHOD get_instance_authorizations.
  READ ENTITIES OF zr_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( carrier_id )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  LOOP AT lt_travels INTO DATA(ls_travel).
    DATA(lo_auth) = cl_abap_authorization=>check_authorization(
      authorization_object = 'Z_MY_AUTH'
      authorizations       = VALUE #(
        ( field = 'ZCARR' value = ls_travel-carrier_id )
        ( field = 'ACTVT' value = COND #(
            WHEN requested_authorizations-%update = if_abap_behv=>mk-on
              THEN '02'
            WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
              THEN '06'
            ELSE '03' ) )
      ) ).

    APPEND VALUE #(
      %tky = ls_travel-%tky
      %update = COND #( WHEN lo_auth->is_authorized( ) THEN if_abap_behv=>auth-allowed
                        ELSE if_abap_behv=>auth-unauthorized )
      %delete = COND #( WHEN lo_auth->is_authorized( ) THEN if_abap_behv=>auth-allowed
                        ELSE if_abap_behv=>auth-unauthorized )
    ) TO result.
  ENDLOOP.
ENDMETHOD.
```

### Global Authorization in RAP

```abap
"In behavior definition:
define behavior for ZR_Travel alias Travel
  authorization master ( global )
{
  ...
}
```

```abap
METHOD get_global_authorizations.
  DATA(lo_auth) = cl_abap_authorization=>check_authorization(
    authorization_object = 'Z_MY_AUTH'
    authorizations       = VALUE #(
      ( field = 'ACTVT' value = '01' ) ) ).  "Create

  IF lo_auth->is_authorized( ).
    result-%create = if_abap_behv=>auth-allowed.
  ELSE.
    result-%create = if_abap_behv=>auth-unauthorized.
  ENDIF.
ENDMETHOD.
```

## Output Format

When helping with authorization/IAM topics, structure responses as:

```markdown
## Authorization Guidance

### Platform

- [ABAP Cloud / On-Premise]
- Approach: [CDS DCL / AUTHORITY-CHECK / CL_ABAP_AUTHORIZATION / IAM]

### Implementation

[Step-by-step with code examples]

### Role Configuration

[How to set up roles and assign access]
```

## References

- ABAP Authorization Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets
- CDS Access Control: https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/access-controls
- IAM Guide: https://help.sap.com/docs/btp/sap-business-technology-platform/identity-and-access-management-iam
