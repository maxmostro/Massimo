REPORT z_salv_tree_report.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA gt_ekko TYPE STANDARD TABLE OF ekko WITH EMPTY KEY.
DATA gt_ekpo TYPE STANDARD TABLE OF ekpo WITH EMPTY KEY.

" Structures for FM K_KKB_HIER_SEQU_LIST_DISPLAY
DATA ls_layout TYPE kkblo_layout.
DATA lt_fieldcat TYPE kkblo_t_fieldcat.
DATA ls_keyinfo TYPE kkblo_keyinfo.

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
    " No items found for these POs, continue anyway
    MESSAGE 'No items found' TYPE 'S'.
  ENDIF.

  " Prepare Key Information for Hierarchy
  ls_keyinfo-header01 = 'EBELN'.
  ls_keyinfo-item01   = 'EBELN'.

  " Prepare Field Catalog (Simplified)
  " In a real scenario, we'd use a catalog merge or manual population.
  " Here we assume the structures are sufficient or handled by structure names.

  " Call the requested function
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
