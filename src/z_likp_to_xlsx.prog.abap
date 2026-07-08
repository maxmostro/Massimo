REPORT z_likp_to_xlsx.

TYPES: BEGIN OF ty_likp,
         vbeln TYPE vbeln,
         erdat TYPE erdat,
         erzet TYPE erzet,
         ernam TYPE ernam,
       END OF ty_likp.

DATA: gt_likp TYPE TABLE OF ty_likp,
      gv_xml  TYPE string.

START-OF-SELECTION.
  PERFORM select_data.
  PERFORM generate_xlsx.
  PERFORM download_file.

FORM select_data.
  SELECT vbeln, erdat, erzet, ernam
    FROM likp
    INTO TABLE @gt_likp
    UP TO 100 ROWS.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
ENDFORM.

FORM generate_xlsx.
  DATA: lv_line TYPE string.

  CONCATENATE
    '<?xml version="1.0"?>'
    '<?mso-application progid="Excel.Sheet"?>'
    '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'
    ' xmlns:o="urn:schemas-microsoft-com:office:office"'
    ' xmlns:x="urn:schemas-microsoft-com:office:excel"'
    ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'
    ' xmlns:html="http://www.w3.org/TR/REC-html40">'
    '<Styles>'
    ' <Style ss:ID="Header">'
    '  <Font ss:Bold="1"/>'
    '  <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>'
    ' </Style>'
    ' <Style ss:ID="BoldData">'
    '  <Font ss:Bold="1"/>'
    ' </Style>'
    '</Styles>'
    '<Worksheet ss:Name="LIKP Data">'
    '<Table>'
    '<Row ss:StyleID="Header">'
    '<Cell><Data ss:Type="String">Delivery</Data></Cell>'
    '<Cell><Data ss:Type="String">Date</Data></Cell>'
    '<Cell><Data ss:Type="String">Time</Data></Cell>'
    '<Cell><Data ss:Type="String">Created By</Data></Cell>'
    '</Row>' INTO gv_xml.

  LOOP AT gt_likp INTO DATA(ls_likp).
    lv_line = '<Row>' &&
              '<Cell ss:StyleID="BoldData"><Data ss:Type="String">' && ls_likp-vbeln && '</Data></Cell>' &&
              '<Cell><Data ss:Type="String">' && ls_likp-erdat && '</Data></Cell>' &&
              '<Cell><Data ss:Type="String">' && ls_likp-erzet && '</Data></Cell>' &&
              '<Cell><Data ss:Type="String">' && ls_likp-ernam && '</Data></Cell>' &&
              '</Row>'.
    gv_xml = gv_xml && lv_line.
  ENDLOOP.

  gv_xml = gv_xml && '</Table></Worksheet></Workbook>'.
ENDFORM.

FORM download_file.
  DATA: lt_data TYPE TABLE OF string,
        lv_filename TYPE string,
        lv_path TYPE string,
        lv_fullpath TYPE string.

  IF gv_xml IS INITIAL.
    RETURN.
  ENDIF.

  APPEND gv_xml TO lt_data.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = 'xls'
      default_file_name = 'LIKP_Export.xls'
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
    EXCEPTIONS
      OTHERS            = 1 ).

  IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filename                = lv_fullpath
      filetype                = 'ASC'
    CHANGING
      data_tab                = lt_data
    EXCEPTIONS
      OTHERS                  = 1 ).

  IF sy-subrc = 0.
    MESSAGE 'File downloaded successfully' TYPE 'S'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* ABAP Unit Tests
*----------------------------------------------------------------------*
CLASS lcl_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      test_xml_generation FOR TESTING.
ENDCLASS.

CLASS lcl_test IMPLEMENTATION.
  METHOD test_xml_generation.
    " Setup test data
    APPEND VALUE #( vbeln = '0080000001' erdat = '20230101' erzet = '120000' ernam = 'JULES' ) TO gt_likp.

    PERFORM generate_xlsx.

    cl_abap_unit_assert=>assert_not_initial(
      act = gv_xml
      msg = 'XML string should not be initial' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = gv_xml
      exp = '*<Workbook*'
      msg = 'XML should contain Workbook tag' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = gv_xml
      exp = '*ss:ID="Header"*'
      msg = 'XML should contain Header style' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = gv_xml
      exp = '*0080000001*'
      msg = 'XML should contain test delivery number' ).
  ENDMETHOD.
ENDCLASS.
