REPORT z_flight_report.

TYPE-POOLS: lvc.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA: gt_spfli   TYPE TABLE OF spfli,
      gt_sflight TYPE TABLE OF sflight.

DATA: go_container     TYPE REF TO cl_gui_custom_container,
      go_splitter      TYPE REF TO cl_gui_splitter_container,
      go_container_l   TYPE REF TO cl_gui_container,
      go_container_r   TYPE REF TO cl_gui_container,
      go_tree          TYPE REF TO cl_gui_alv_tree,
      go_grid          TYPE REF TO cl_gui_alv_grid.

DATA: gv_ok_code TYPE sy-ucomm,
      gv_dd_handle TYPE i.

*----------------------------------------------------------------------*
* Drag & Drop Handler Class
*----------------------------------------------------------------------*
CLASS lcl_drag_drop_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      on_drag FOR EVENT on_drag OF cl_gui_alv_grid
        IMPORTING e_row e_column es_row_no e_dragdropobj,
      on_drop FOR EVENT on_drop OF cl_gui_alv_tree
        IMPORTING node_key drag_drop_object.
ENDCLASS.

CLASS lcl_drag_drop_handler IMPLEMENTATION.
  METHOD on_drag.
    " Define the data to be dragged
    DATA: lr_sflight TYPE REF TO sflight.
    CREATE DATA lr_sflight.
    READ TABLE gt_sflight INTO lr_sflight->* INDEX es_row_no-row_id.
    IF sy-subrc = 0.
      e_dragdropobj->object = lr_sflight.
    ENDIF.
  ENDMETHOD.

  METHOD on_drop.
    " Handle the dropped data
    DATA: lr_sflight TYPE REF TO sflight.
    lr_sflight ?= drag_drop_object->object.

    IF lr_sflight IS BOUND.
      MESSAGE |Dropped flight { lr_sflight->carrid } { lr_sflight->connid } on node { node_key }| TYPE 'I'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: go_handler TYPE REF TO lcl_drag_drop_handler.

*----------------------------------------------------------------------*
* Selection Screen (Not strictly required but good for completeness)
*----------------------------------------------------------------------*
* No selection screen requested, so we'll just fetch all data.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  SELECT * FROM spfli INTO TABLE gt_spfli.
  SELECT * FROM sflight INTO TABLE gt_sflight.

  CALL SCREEN 0100.

*----------------------------------------------------------------------*
* PBO Module
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_100'.
  SET TITLEBAR 'TITLE_100'.

  IF go_splitter IS INITIAL.
    " In a real SAP system, 'CONTAINER' would be the name of a custom control on the screen.
    " For this exercise, we'll assume a custom container or use docking.
    CREATE OBJECT go_splitter
      EXPORTING
        parent  = cl_gui_container=>screen0
        rows    = 1
        columns = 2.

    go_container_l = go_splitter->get_container( row = 1 column = 1 ).
    go_container_r = go_splitter->get_container( row = 1 column = 2 ).

    " Drag & Drop Initialization
    DATA: lo_dragdrop TYPE REF TO cl_gui_dragdrop,
          lv_handle   TYPE i.

    CREATE OBJECT lo_dragdrop.
    lo_dragdrop->add(
      EXPORTING
        flavor     = 'FLIGHT'
        dragsrc    = 'X'
        droptarget = 'X'
        effect     = cl_gui_dragdrop=>heavy ).

    lo_dragdrop->get_handle( IMPORTING handle = gv_dd_handle ).

    " Left Side: ALV Tree for SPFLI
    CREATE OBJECT go_tree
      EXPORTING
        parent              = go_container_l
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection      = 'X'
        no_toolbar          = ''
        no_html_header      = 'X'.

    " Hierarchy header
    DATA: ls_hierarchy_header TYPE treev_hhdr.
    ls_hierarchy_header-heading = 'Flight Schedule'.
    ls_hierarchy_header-width   = 30.

    " Structure table for tree (should be empty during initialization)
    DATA: lt_tree_structure TYPE TABLE OF spfli.

    go_tree->set_table_for_first_display(
      EXPORTING
        i_structure_name    = 'SPFLI'
        is_hierarchy_header = ls_hierarchy_header
      CHANGING
        it_outtab           = lt_tree_structure ).

    " Event Registration and Drag&Drop handle for Tree
    DATA: lt_events TYPE cntl_simple_events,
          ls_event  TYPE cntl_simple_event.

    ls_event-eventid = cl_gui_column_tree=>eventid_drop.
    ls_event-appl_event = 'X'.
    APPEND ls_event TO lt_events.

    CREATE OBJECT go_handler.

    go_tree->set_registered_events( events = lt_events ).
    SET HANDLER go_handler->on_drop FOR go_tree.

    " Set D&D handle for tree nodes - this typically requires node layout or setting it globally
    " For simplicity, we'll assume the flavor match is enough or set it in nodes.

    " Add nodes to the tree
    PERFORM build_tree.

    " Right Side: ALV Grid for SFLIGHT
    DATA: ls_layout TYPE lvc_s_layo.
    ls_layout-s_dragdrop-row_dd_hndl = gv_dd_handle.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_container_r.

    " Event Registration for Grid
    SET HANDLER go_handler->on_drag FOR go_grid.

    go_grid->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SFLIGHT'
        is_layout        = ls_layout
      CHANGING
        it_outtab        = gt_sflight ).
  ENDIF.
ENDMODULE.

*----------------------------------------------------------------------*
* Form Build Tree
*----------------------------------------------------------------------*
FORM build_tree.
  " This is a simplified tree build. In a real scenario, you'd loop through gt_spfli
  " and use go_tree->add_node.
  " For brevity in this script:
  DATA: lv_node_text   TYPE lvc_value,
        ls_node_layout TYPE lvc_s_layn.

  ls_node_layout-dragdropid = gv_dd_handle.

  LOOP AT gt_spfli INTO DATA(ls_spfli).
    CLEAR lv_node_text.
    CONCATENATE ls_spfli-carrid ls_spfli-connid INTO lv_node_text SEPARATED BY space.
    go_tree->add_node(
      EXPORTING
        i_relat_node_key = ''
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = lv_node_text
        is_outtab_line   = ls_spfli
        is_node_layout   = ls_node_layout ).
  ENDLOOP.

  go_tree->frontend_update( ).
ENDFORM.

*----------------------------------------------------------------------*
* PAI Module
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_ok_code = sy-ucomm.
  CASE gv_ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN OTHERS.
      " Other commands
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
