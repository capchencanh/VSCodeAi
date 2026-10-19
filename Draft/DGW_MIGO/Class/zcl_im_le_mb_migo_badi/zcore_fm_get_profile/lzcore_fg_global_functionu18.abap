FUNCTION ZCORE_FM_CHECK_EXIST_FILE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IW_FILE_PATH)
*"     REFERENCE(IW_SERVER_LOCAL)
*"  EXPORTING
*"     REFERENCE(EW_EXIST) TYPE  CHAR1
*"--------------------------------------------------------------------
data: lw_server_file_path type dxfile-filename,
        lw_local_file_path  type string.

  " Check on Application Server
  if iw_server_local = 'X'.
    lw_server_file_path = iw_file_path.
    call function 'DX_FILE_EXISTENCE_CHECK'
      exporting
        filename             = lw_server_file_path
        pc                   = ''
      importing
        file_exists          = ew_exist
      exceptions
        rfc_error            = 1
        frontend_error       = 2
        no_authority         = 3
        others               = 4.
  " Check on Front End
  else.
    lw_local_file_path = iw_file_path.
    call method cl_gui_frontend_services=>file_exist
      exporting
        file                 = lw_local_file_path
      receiving
        result               = ew_exist
      exceptions
        cntl_error           = 1
        error_no_gui         = 2
        wrong_parameter      = 3
        not_supported_by_gui = 4
        others               = 5.
  endif.





ENDFUNCTION.

*
* 
