REPORT z_salv_tree_report.

*----------------------------------------------------------------------*
* Data Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_report,
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
         cityfrom TYPE spfli-cityfrom,
         connid   TYPE spfli-connid,
         cityto   TYPE spfli-cityto,
         deptime  TYPE spfli-deptime,
         arrtime  TYPE spfli-arrtime,
       END OF ty_report.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA gt_report   TYPE STANDARD TABLE OF ty_report WITH EMPTY KEY.
DATA gt_scarr    TYPE STANDARD TABLE OF scarr WITH EMPTY KEY.
DATA gt_spfli    TYPE STANDARD TABLE OF spfli WITH EMPTY KEY.
DATA go_alv_tree TYPE REF TO cl_salv_tree.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  " Fetch data
  SELECT * FROM scarr INTO TABLE @gt_scarr.
  IF sy-subrc <> 0.
    MESSAGE 'No airlines found' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT * FROM spfli INTO TABLE @gt_spfli.
  IF sy-subrc <> 0.
    MESSAGE 'No flight connections found' TYPE 'S'.
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
  lo_settings->set_hierarchy_header( 'Airlines / Locations / Flights' ).
  lo_settings->set_hierarchy_size( 40 ).

  " Get Nodes object to build the hierarchy
  DATA(lo_nodes) = go_alv_tree->get_nodes( ).
  DATA lo_airline_node  TYPE REF TO cl_salv_node.
  DATA lo_location_node TYPE REF TO cl_salv_node.
  DATA lv_airline_key   TYPE salv_de_node_key.
  DATA lv_location_key  TYPE salv_de_node_key.
  DATA lv_prev_location TYPE spfli-cityfrom.

  " Sort flights to group by Airline and Departure City
  SORT gt_spfli BY carrid cityfrom.

  " Build Tree: Airlines (SCARR) -> Locations (SPFLI-CITYFROM) -> Flights (SPFLI)
  LOOP AT gt_scarr INTO DATA(ls_scarr).
    " AIRLINE LEVEL (Root)
    DATA ls_airline_row TYPE ty_report.
    ls_airline_row-carrid   = ls_scarr-carrid.
    ls_airline_row-carrname = ls_scarr-carrname.

    TRY.
        lo_airline_node = lo_nodes->add_node(
          related_node = ''
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_airline_row
          text         = CONV #( ls_scarr-carrid )
          folder       = abap_true ).
        lv_airline_key = lo_airline_node->get_key( ).
      CATCH cx_salv_msg.
        CONTINUE.
    ENDTRY.

    CLEAR lv_prev_location.

    " LOCATION & FLIGHT LEVELS
    LOOP AT gt_spfli INTO DATA(ls_spfli) WHERE carrid = ls_scarr-carrid.

      " LOCATION LEVEL (New!)
      IF ls_spfli-cityfrom <> lv_prev_location.
        DATA ls_location_row TYPE ty_report.
        ls_location_row-carrid   = ls_scarr-carrid.
        ls_location_row-cityfrom = ls_spfli-cityfrom.

        TRY.
            lo_location_node = lo_nodes->add_node(
              related_node = lv_airline_key
              relationship = cl_gui_column_tree=>relat_last_child
              data_row     = ls_location_row
              text         = CONV #( |Departure: { ls_spfli-cityfrom }| )
              folder       = abap_true ).
            lv_location_key = lo_location_node->get_key( ).
          CATCH cx_salv_msg.
            CONTINUE.
        ENDTRY.
        lv_prev_location = ls_spfli-cityfrom.
      ENDIF.

      " FLIGHT LEVEL
      DATA ls_flight_row TYPE ty_report.
      MOVE-CORRESPONDING ls_spfli TO ls_flight_row.

      TRY.
          lo_nodes->add_node(
            related_node = lv_location_key
            relationship = cl_gui_column_tree=>relat_last_child
            data_row     = ls_flight_row
            text         = CONV #( ls_spfli-connid ) ).
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
