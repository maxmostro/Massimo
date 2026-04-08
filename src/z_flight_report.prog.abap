REPORT z_flight_report.

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

DATA: gv_ok_code TYPE sy-ucomm.

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

    " Add nodes to the tree
    PERFORM build_tree.

    " Right Side: ALV Grid for SFLIGHT
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_container_r.

    go_grid->set_table_for_first_display(
      EXPORTING
        i_structure_name = 'SFLIGHT'
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
  DATA: lv_node_text TYPE lvc_node_t.

  LOOP AT gt_spfli INTO DATA(ls_spfli).
    lv_node_text = |{ ls_spfli-carrid } { ls_spfli-connid }|.
    go_tree->add_node(
      EXPORTING
        i_relat_node_key = ''
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = lv_node_text
        is_outtab_line   = ls_spfli ).
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
