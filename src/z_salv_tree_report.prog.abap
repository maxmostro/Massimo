REPORT z_salv_tree_report.

*----------------------------------------------------------------------*
* Data Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_report,
         ebeln TYPE ekko-ebeln,
         bukrs TYPE ekko-bukrs,
         aedat TYPE ekko-aedat,
         ernam TYPE ekko-ernam,
         lifnr TYPE ekko-lifnr,
         ebelp TYPE ekpo-ebelp,
         matnr TYPE ekpo-matnr,
         matkl TYPE ekpo-matkl,
         menge TYPE ekpo-menge,
         meins TYPE ekpo-meins,
         netpr TYPE ekpo-netpr,
       END OF ty_report.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA gt_report   TYPE STANDARD TABLE OF ty_report WITH EMPTY KEY.
DATA gt_ekko     TYPE STANDARD TABLE OF ekko WITH EMPTY KEY.
DATA gt_ekpo     TYPE STANDARD TABLE OF ekpo WITH EMPTY KEY.
DATA go_alv_tree TYPE REF TO cl_salv_tree.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  " Fetch data
  SELECT * FROM ekko INTO TABLE @gt_ekko UP TO 10 ROWS.
  IF sy-subrc <> 0.
    MESSAGE 'No Purchase Orders found' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT * FROM ekpo INTO TABLE @gt_ekpo
    FOR ALL ENTRIES IN @gt_ekko
    WHERE ebeln = @gt_ekko-ebeln.
  IF sy-subrc <> 0.
    " No items found for these POs
    MESSAGE 'No items found for selected Purchase Orders' TYPE 'S'.
  ENDIF.

  " Create SALV Tree instance
  TRY.
      cl_salv_tree=>factory(
        IMPORTING
          r_salv_tree = go_alv_tree
        CHANGING
          t_table      = gt_report ).
    CATCH cx_salv_error.
      MESSAGE 'Error creating SALV tree' TYPE 'E'.
      RETURN.
  ENDTRY.

  " Set Tree Settings (Hierarchy Header)
  DATA(lo_settings) = go_alv_tree->get_tree_settings( ).
  lo_settings->set_hierarchy_header( 'Purchase Documents' ).
  lo_settings->set_hierarchy_size( 30 ).

  " Get Nodes object to build the hierarchy
  DATA(lo_nodes) = go_alv_tree->get_nodes( ).
  DATA lo_parent_node TYPE REF TO cl_salv_node.
  DATA lv_parent_key  TYPE salv_de_node_key.

  " Build Tree: PO Header (EKKO) -> PO Item (EKPO)
  LOOP AT gt_ekko INTO DATA(ls_ekko).
    " HEADER ROW (Orange/Yellow style)
    DATA ls_header_row TYPE ty_report.
    MOVE-CORRESPONDING ls_ekko TO ls_header_row.

    TRY.
        lo_parent_node = lo_nodes->add_node(
          related_node = ''
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_header_row
          text         = CONV #( ls_ekko-ebeln )
          folder       = abap_true ).
        " Use HEADING or INTENSIFIED for the header style
        lo_parent_node->set_row_style( if_salv_c_tree_style=>intensified ).
        lv_parent_key = lo_parent_node->get_key( ).
      CATCH cx_salv_msg.
        CONTINUE.
    ENDTRY.

    " ITEM ROWS (Blue style)
    LOOP AT gt_ekpo INTO DATA(ls_ekpo) WHERE ebeln = ls_ekko-ebeln.
      DATA ls_item_row TYPE ty_report.
      MOVE-CORRESPONDING ls_ekpo TO ls_item_row.
      " Clear header fields to emphasize it's an item row, matching the image style
      CLEAR: ls_item_row-bukrs, ls_item_row-aedat, ls_item_row-ernam, ls_item_row-lifnr.

      TRY.
          DATA(lo_item_node) = lo_nodes->add_node(
            related_node = lv_parent_key
            relationship = cl_gui_column_tree=>relat_last_child
            data_row     = ls_item_row
            text         = CONV #( ls_ekpo-ebeln ) ).
          lo_item_node->set_row_style( if_salv_c_tree_style=>emphasized_positive ).
        CATCH cx_salv_msg.
          " Handle exception
      ENDTRY.
    ENDLOOP.
  ENDLOOP.

  " Enable standard functions (Toolbar)
  DATA(lo_functions) = go_alv_tree->get_functions( ).
  lo_functions->set_all( ).

  " Optimize columns
  DATA(lo_columns) = go_alv_tree->get_columns( ).
  lo_columns->set_optimize( ).

  " Display the Tree
  go_alv_tree->display( ).
