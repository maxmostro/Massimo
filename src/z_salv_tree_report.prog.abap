REPORT z_salv_tree_report.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA gt_ekko TYPE STANDARD TABLE OF ekko WITH EMPTY KEY.
DATA gt_ekpo TYPE STANDARD TABLE OF ekpo WITH EMPTY KEY.

" Structures for FM K_KKB_HIER_SEQU_LIST_DISPLAY
DATA ls_layout TYPE kkblo_layout.
DATA lt_fieldcat TYPE kkblo_t_fieldcat.
DATA ls_keyinfo TYPE slis_keyinfo_alv.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  " Fetch Header Data
  SELECT * FROM ekko INTO TABLE @gt_ekko UP TO 10 ROWS.
  IF sy-subrc <> 0.
    MESSAGE 'No Purchase Orders found' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Fetch Item Data
  SELECT * FROM ekpo INTO TABLE @gt_ekpo
    FOR ALL ENTRIES IN @gt_ekko
    WHERE ebeln = @gt_ekko-ebeln.
  IF sy-subrc <> 0.
    " Optional: Handle case where no items exist
    MESSAGE 'No items found' TYPE 'S'.
  ENDIF.

  " Prepare Key Information for Hierarchy
  " SLIS_KEYINFO_ALV has fields: header01, item01, etc.
  ls_keyinfo-header01 = 'EBELN'.
  ls_keyinfo-item01   = 'EBELN'.

  " Call the requested function
  " K_KKB_HIER_SEQU_LIST_DISPLAY accepts KKBLO_KEYINFO.
  " If SLIS_KEYINFO_ALV doesn't cast directly, I might need to adjust.
  " But they are usually identical in layout.
  CALL FUNCTION 'K_KKB_HIER_SEQU_LIST_DISPLAY'
    EXPORTING
      i_tabname_header     = 'GT_EKKO'
      i_tabname_item       = 'GT_EKPO'
      is_keyinfo           = ls_keyinfo
      i_structure_name_header = 'EKKO'
      i_structure_name_item   = 'EKPO'
    TABLES
      t_outtab_header      = gt_ekko
      t_outtab_item        = gt_ekpo
    EXCEPTIONS
      error_message        = 1
      OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying hierarchical list' TYPE 'E'.
  ENDIF.
