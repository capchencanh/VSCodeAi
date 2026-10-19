FUNCTION ZCORE_FM_EXCEL_GENERATE_FILE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IW_INPUT_FILE_NAME) TYPE  ZDE_REPORT_NAME
*"  TABLES
*"      IT_XML_DATA
*"--------------------------------------------------------------------
data: lw_file_name        type string,
        lw_file_path_full   type string,
        lw_user_action      type i,
        lw_report_date      type sy-datum,
        lw_report_time      type sy-uzeit.

  " Case Run online
  if sy-batch = ''.
    " Init Download Local Folder Path
    data: lw_desktop_path type string.
    call method cl_gui_frontend_services=>get_desktop_directory
      changing
        desktop_directory     = lw_desktop_path
      exceptions
        cntl_error            = 1.
    if sy-subrc <> 0.
     message id sy-msgid type sy-msgty number sy-msgno
                with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
    call method cl_gui_cfw=>update_view.

    data: lw_input_file_name type string.
    lw_input_file_name = iw_input_file_name.
    call function 'GUI_FILE_SAVE_DIALOG'
      exporting
        initial_directory = lw_desktop_path
        default_file_name = lw_input_file_name
      importing
        filename          = lw_file_name
        fullpath          = lw_file_path_full
        user_action       = lw_user_action.

    " Cancel
    if lw_user_action = 9.
      exit.
    endif.

    " Concatenate Full File Name with Extension
    concatenate lw_file_path_full '.xls' into lw_file_path_full.
    check lw_file_name is not initial.

    call function 'GUI_DOWNLOAD'
      exporting
        filename  = lw_file_path_full
        codepage  = '4102'
        write_bom = 'X'
      tables
        data_tab  = it_xml_data
      exceptions
        others.

    " Do not open file after download
*    CL_GUI_FRONTEND_SERVICES=>EXECUTE(
*      EXPORTING
*        DOCUMENT    = LW_FILENAME
*        MAXIMIZED   = 'X'
*      EXCEPTIONS
*        CNTL_ERROR = 1 ).

  " Case Run in Background Process
  elseif sy-batch = 'X'.
    lw_report_date = sy-datum.
    lw_report_time = sy-uzeit.

    " Concatenate Full File Name with Extension
    concatenate '/tmp/' lw_report_date sy-uzeit '_' sy-mandt '_' sy-uname '_' iw_input_file_name '.xls' into lw_file_path_full.

    " Open file for write
    open dataset lw_file_path_full for output in text mode encoding utf-8.

    data: ls_xml_data type string.
    loop at it_xml_data[] into ls_xml_data.
      transfer ls_xml_data to lw_file_path_full.
    endloop.

    " Close file
    close dataset lw_file_path_full.

    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
                          with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

    " Write File To Database From Application Server When Run in Background Process
    call function 'ZCORE_FM_EXCEL_WRITE2DB_SERVER'
      exporting
        iw_server_file_path        = lw_file_path_full
        iw_report_date             = lw_report_date
        iw_report_time             = lw_report_time
        iw_report_name             = iw_input_file_name
      exceptions
        error_not_exist            = 1
        error_can_not_insert       = 2
        others                     = 3.

    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
                          with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

    " Process to Delete Excel file from Application Server (/tmp)
    call function 'ZCORE_FM_EXCEL_DEL_FILE_SERVER'
      exporting
        iw_server_file_path        = lw_file_path_full
      exceptions
        error_not_exist            = 1
        error_can_not_delete       = 2
        others                     = 3.

    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
                          with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endif.





ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*001   &1&2&3&4&5&6&7&8
*398   & & & &
*
* Message class: Hard coded
*   Template was not found !
*
* Message class: VZ
*000   & & & &

*
*
