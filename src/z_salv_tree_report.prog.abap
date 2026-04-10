REPORT z_salv_tree_report.

*----------------------------------------------------------------------*
* Data Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_report,
         carrid   TYPE spfli-carrid,
         connid   TYPE spfli-connid,
         cityfrom TYPE spfli-cityfrom,
         cityto   TYPE spfli-cityto,
       END OF ty_report.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
" Template for columns
DATA gt_report   TYPE STANDARD TABLE OF ty_report WITH EMPTY KEY.
DATA gt_spfli    TYPE STANDARD TABLE OF spfli WITH EMPTY KEY.
DATA go_alv_tree TYPE REF TO cl_salv_tree.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  " Fetch data from SPFLI
  SELECT * FROM spfli INTO TABLE @gt_spfli.
  IF sy-subrc <> 0.
    MESSAGE 'No data found in SPFLI' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
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
  lo_settings->set_hierarchy_header( 'Flight Connections' ).
  lo_settings->set_hierarchy_size( 30 ).

  " Get Nodes object to build the hierarchy
  DATA(lo_nodes) = go_alv_tree->get_nodes( ).
  DATA lo_node       TYPE REF TO cl_salv_node.
  DATA lv_parent_key TYPE salv_de_node_key.
  DATA lv_prev_carrid TYPE spfli-carrid.

  " Sort data for grouping
  SORT gt_spfli BY carrid.

  LOOP AT gt_spfli INTO DATA(ls_spfli).
    " Create a parent node for each Airline Carrier
    IF ls_spfli-carrid <> lv_prev_carrid.
      TRY.
          lo_node = lo_nodes->add_node(
            related_node = ''
            relationship = cl_gui_column_tree=>relat_last_child
            text         = CONV #( ls_spfli-carrid )
            folder       = abap_true ).
          lv_parent_key = lo_node->get_key( ).
        CATCH cx_salv_msg.
          " Handle exception
      ENDTRY.
      lv_prev_carrid = ls_spfli-carrid.
    ENDIF.

    " Create child nodes for each connection
    DATA ls_row TYPE ty_report.
    MOVE-CORRESPONDING ls_spfli TO ls_row.

    TRY.
        lo_nodes->add_node(
          related_node = lv_parent_key
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_row
          text         = CONV #( ls_spfli-connid ) ).
      CATCH cx_salv_msg.
        " Handle exception
    ENDTRY.
  ENDLOOP.

  " Enable standard functions (Toolbar)
  DATA(lo_functions) = go_alv_tree->get_functions( ).
  lo_functions->set_all( ).

  " Display the Tree
  go_alv_tree->display( ).
