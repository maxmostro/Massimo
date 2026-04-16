REPORT z_salv_tree_demo.

*----------------------------------------------------------------------*
* Local Class Definition
*----------------------------------------------------------------------*
CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_data,
             icon_column TYPE char4,
             text_column TYPE string,
           END OF ty_data.

    CLASS-METHODS run.

  PRIVATE SECTION.
    CLASS-DATA: gt_data TYPE STANDARD TABLE OF ty_data WITH EMPTY KEY.
ENDCLASS.

*----------------------------------------------------------------------*
* Local Class Implementation
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.
  METHOD run.
    DATA: lo_tree    TYPE REF TO cl_salv_tree,
          lo_nodes   TYPE REF TO cl_salv_nodes,
          lo_node    TYPE REF TO cl_salv_node,
          lo_columns TYPE REF TO cl_salv_columns,
          lo_column  TYPE REF TO cl_salv_column_tree,
          ls_data    TYPE ty_data.

    " 1. Create SALV Tree instance
    TRY.
        cl_salv_tree=>factory(
          IMPORTING
            r_salv_tree = lo_tree
          CHANGING
            t_table     = gt_data ).
      CATCH cx_salv_error.
        " Handle error
        RETURN.
    ENDTRY.

    " 2. Enable Icon column
    lo_columns = lo_tree->get_columns( ).
    TRY.
        lo_column ?= lo_columns->get_column( 'ICON_COLUMN' ).
        lo_column->set_icon( abap_true ).
        lo_column->set_long_text( 'Status Icon' ).
      CATCH cx_salv_not_found.
        " Handle error
    ENDTRY.

    " 3. Set Hierarchy Header
    DATA(lo_settings) = lo_tree->get_tree_settings( ).
    lo_settings->set_hierarchy_header( 'Hierarchy' ).
    lo_settings->set_hierarchy_size( 30 ).

    " 4. Add Nodes
    lo_nodes = lo_tree->get_nodes( ).

    " Node 1: Positive Style (Teal/Blue)
    CLEAR ls_data.
    ls_data-icon_column = '@01@'. " ICON_CHECKED
    ls_data-text_column = 'Completed Task'.
    TRY.
        lo_node = lo_nodes->add_node(
          related_node = ''
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_data
          text         = 'Node 1' ).
        lo_node->set_icon( '@0V@' ). " ICON_LED_GREEN (Hierarchy Icon)
        lo_node->set_row_style( if_salv_c_tree_style=>emphasized_positive ).
      CATCH cx_salv_error.
    ENDTRY.

    " Node 2: Negative Style (Red/Pink)
    CLEAR ls_data.
    ls_data-icon_column = '@02@'. " ICON_INCOMPLETE
    ls_data-text_column = 'Pending Task'.
    TRY.
        lo_node = lo_nodes->add_node(
          related_node = ''
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_data
          text         = 'Node 2' ).
        lo_node->set_icon( '@0W@' ). " ICON_LED_RED
        lo_node->set_row_style( if_salv_c_tree_style=>emphasized_negative ).
      CATCH cx_salv_error.
    ENDTRY.

    " Node 3: Intensified Style (Orange/Yellow)
    CLEAR ls_data.
    ls_data-icon_column = '@09@'. " ICON_ALARM
    ls_data-text_column = 'Urgent Task'.
    TRY.
        lo_node = lo_nodes->add_node(
          related_node = ''
          relationship = cl_gui_column_tree=>relat_last_child
          data_row     = ls_data
          text         = 'Node 3' ).
        lo_node->set_icon( '@0X@' ). " ICON_LED_YELLOW
        lo_node->set_row_style( if_salv_c_tree_style=>intensified ).
      CATCH cx_salv_error.
    ENDTRY.

    " 5. Display Tree
    lo_tree->display( ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  lcl_report=>run( ).
