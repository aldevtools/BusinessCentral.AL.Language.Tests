// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Permissions Mock, ALTPermissionSet (60022), objects of UReportObjects.al, UTestIsolation.al, UPageObjects.al
// Probe (issue 601): report layouts selected by RDLCLayout and WordLayout, SaveAs, request page fields (TableRelation, AutoFormat, DateFormula; DrillDownPageID and Width are not probed, see the hand-off note),
// report extension CalcFields and TableRelation, InherentPermissions and request page Permissions under the permissions mock, queries with InherentPermissions,
// XmlPort field and text attribute Occurrence, TextType, validation on import, and the TestIsolation of test runner codeunits. Object id 69789.

codeunit 69789 "LT U Property Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure SeedParent()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Init();
        Parent."Entry No." := 69789;
        Parent.Code := 'LTU-P';
        Parent.Insert();
        Child.Init();
        Child."Entry No." := 69781;
        Child."Parent Entry No." := 69789;
        Child.Code := 'LTU-C1';
        Child.Amount := 10;
        Child.Insert();
        Child."Entry No." := 69782;
        Child.Code := 'LTU-C2';
        Child.Amount := 5;
        Child.Insert();
    end;

    local procedure SeedPageSrc()
    var
        Src: Record "LT U Page Src";
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'one';
        Src.Insert();
    end;

    local procedure After(Value: Text; Marker: Text; Len: Integer): Text
    begin
        if StrPos(Value, Marker) = 0 then
            exit('<not found>');
        exit(CopyStr(Value, StrPos(Value, Marker) + StrLen(Marker), Len));
    end;

    local procedure Capture(CaptureName: Text)
    begin
        Observer.Observe(CaptureName, GetLastErrorText());
        Observer.Observe(CaptureName + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    local procedure ReadAll(var InS: InStream) Result: Text
    var
        Line: Text;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '\n';
        end;
    end;

    [Test]
    procedure Report_RdlcAndWordLayout_AreSelected()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Magic: Text;
        Rdlc: Text;
    begin
        Observer.Observe('rdlc_found', Format(Report.RdlcLayout(Report::"LT U Report", InS)));
        Rdlc := ReadAll(InS);
        Observer.Observe('rdlc_length_positive', Format(StrLen(Rdlc) > 0));
        Observer.Observe('rdlc_is_report_definition', Format(Rdlc.Contains('<Report ')));
        Observer.Observe('rdlc_names_entryno', Format(Rdlc.Contains('EntryNo')));
        Observer.Observe('rdlc_names_parentcode', Format(Rdlc.Contains('ParentCode')));
        Observer.Observe('word_found', Format(Report.WordLayout(Report::"LT U Report", InS)));
        InS.Read(Magic, 2);
        Observer.Observe('word_is_zip', Magic);
        Observer.Observe('plain_rdlc_found', Format(Report.RdlcLayout(Report::"LT U Report Plain", InS)));
        Observer.Observe('plain_word_found', Format(Report.WordLayout(Report::"LT U Report Plain", InS)));
        Observer.Expect('rdlc_found', 'Yes');
        Observer.Expect('rdlc_length_positive', 'Yes');
        Observer.Expect('rdlc_is_report_definition', 'Yes');
        Observer.Expect('rdlc_names_entryno', 'Yes');
        Observer.Expect('rdlc_names_parentcode', 'Yes');
        Observer.Expect('word_found', 'Yes');
        Observer.Expect('word_is_zip', 'PK');
        Observer.Expect('plain_rdlc_found', 'No');
        Observer.Expect('plain_word_found', 'No');
        Observer.Verify();
    end;

    // The rendered formats (Pdf, Word, Html) need the Windows reporting service; the Linux BC of the CI cannot render RDLC (see the hand-off note), so only the Xml format is pinned.
    [Test]
    procedure Report_SaveAs_Xml_UsesTheDataset()
    var
        TempBlob: Codeunit "Temp Blob";
        State: Codeunit "LT U State";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
    begin
        SeedParent();
        State.Reset();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xml := ReadAll(InS);
        Observer.Observe('xml_has_parent_code', Format(Xml.Contains('LTU-P')));
        Observer.Observe('xml_entryno_column', After(Xml, 'name="EntryNo">', 5));
        Observer.Observe('xml_parentcode_column', After(Xml, 'name="ParentCode">', 6));
        Observer.Observe('xml_dataitem_parent', Format(Xml.Contains('name="Parent"')));
        Observer.Expect('xml_has_parent_code', 'Yes');
        Observer.Expect('xml_entryno_column', '69789');
        Observer.Expect('xml_parentcode_column', 'LTU-P<');
        Observer.Expect('xml_dataitem_parent', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReportExtension_CalcFields_AndBaseCalcFields()
    var
        TempBlob: Codeunit "Temp Blob";
        State: Codeunit "LT U State";
        OutS: OutStream;
    begin
        SeedParent();
        State.Reset();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS);
        Observer.Observe('state', State.Dump());
        Observer.Expect('state', 'base count=2 amount=15 first= | ext count=2 amount=15 first=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PermissionedRequestHandler')]
    procedure Report_RequestPagePermissions_AndInherentPermissions()
    var
        Mock: Codeunit "Permissions Mock";
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        WasStarted: Boolean;
    begin
        SeedPageSrc();
        SeedParent();
        State.Reset();
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set('ALTPermissionSet');
        asserterror begin Src.FindFirst(); Error('NOERROR'); end;
        Capture('direct_read_of_src');
        asserterror begin Report.Run(Report::"LT U Report Plain", false, false); Error('NOERROR'); end;
        Capture('plain_report_run');
        Observer.Observe('state_after_plain', State.Dump());
        TempBlob.CreateOutStream(OutS);
        asserterror begin Report.SaveAs(Report::"LT U Report", '', ReportFormat::Xml, OutS); Error('NOERROR'); end;
        Capture('saveas_inherent');
        Observer.Observe('inherent_report_saveas_length_positive', Format(TempBlob.Length() > 0));
        asserterror begin Report.Run(Report::"LT U Report", true, false); Error('NOERROR'); end;
        Capture('run_request_page');
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
        Observer.Expect('direct_read_of_src', 'Sorry, the current permissions prevented the action. (TableData 69585 LT U Page Src Read: AL Language Coverage Tests)');
        Observer.Expect('direct_read_of_src|code', 'DB:ClientReadDenied');
        Observer.Expect('plain_report_run', 'NOERROR');
        Observer.Expect('plain_report_run|code', 'Dialog');
        Observer.Expect('state_after_plain', 'plain report ran');
#if BC29PLUS
        Observer.Expect('saveas_inherent', 'Sorry, the current permissions prevented the action. (TableData 79 Company Information Read: Base Application)');
#else
        Observer.Expect('saveas_inherent', 'NOERROR');
#endif
#if BC29PLUS
        Observer.Expect('saveas_inherent|code', 'DB:ClientReadDenied');
#else
        Observer.Expect('saveas_inherent|code', 'Dialog');
#endif
#if BC29PLUS
        Observer.Expect('inherent_report_saveas_length_positive', 'No');
#else
        Observer.Expect('inherent_report_saveas_length_positive', 'Yes');
#endif
        Observer.Expect('request_page_rel_with_permissions', '1');
        Observer.Expect('amount_set', 'NOERROR');
        Observer.Expect('amount_set|code', 'Dialog');
        Observer.Expect('amount_value', '1,234.500');
        Observer.Expect('date_formula_1d_set', 'NOERROR');
        Observer.Expect('date_formula_1d_set|code', 'Dialog');
        Observer.Expect('date_formula_1d', '1D');
        Observer.Expect('date_formula_1w_set', 'NOERROR');
        Observer.Expect('date_formula_1w_set|code', 'Dialog');
        Observer.Expect('date_formula_1w', '1W');
        Observer.Expect('date_formula_cm_set', 'NOERROR');
        Observer.Expect('date_formula_cm_set|code', 'Dialog');
        Observer.Expect('date_formula_cm', 'CM+1D');
        Observer.Expect('rel_missing_set', 'NOERROR');
        Observer.Expect('rel_missing_set|code', 'Dialog');
        Observer.Expect('request_page_ext_rel', 'The field with ID = n is not found on the page.');
        Observer.Expect('request_page_ext_rel|code', 'TestFieldNotFound');
        Observer.Expect('run_request_page', 'NOERROR');
        Observer.Expect('run_request_page|code', 'Dialog');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PermissionedRequestHandler(var Req: TestRequestPage "LT U Report")
    var
    begin
        Req.RelField.SetValue(1);
        Observer.Observe('request_page_rel_with_permissions', Req.RelField.Value);
        asserterror begin Req.AmtField.SetValue(1234.5); Error('NOERROR'); end;
        Capture('amount_set');
        Observer.Observe('amount_value', Req.AmtField.Value);
        asserterror begin Req.DfField.SetValue('1D'); Error('NOERROR'); end;
        Capture('date_formula_1d_set');
        Observer.Observe('date_formula_1d', Req.DfField.Value);
        asserterror begin Req.DfField.SetValue('<1W>'); Error('NOERROR'); end;
        Capture('date_formula_1w_set');
        Observer.Observe('date_formula_1w', Req.DfField.Value);
        asserterror begin Req.DfField.SetValue('CM+1D'); Error('NOERROR'); end;
        Capture('date_formula_cm_set');
        Observer.Observe('date_formula_cm', Req.DfField.Value);
        asserterror begin Req.RelField.SetValue(9999); Error('NOERROR'); end;
        Capture('rel_missing_set');
        asserterror begin Req.ExtRelField.SetValue(1); Error('NOERROR'); end;
        Capture('request_page_ext_rel');
        Req.Cancel().Invoke();
    end;

    [Test]
    procedure Query_InherentPermissions_UnderTheMock()
    var
        Mock: Codeunit "Permissions Mock";
        Inherent: Query "LT U Query Inherent";
        Plain: Query "LT U Query Plain";
        Universal: Record "ALT Universal";
        WasStarted: Boolean;
    begin
        Universal.DeleteAll();
        Universal."Entry No." := 69789;
        Universal.Insert();
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set('ALTPermissionSet');
        Observer.Observe('plain_open', Format(Plain.Open()));
        Observer.ObserveError('plain_open');
        Observer.Observe('inherent_open', Format(Inherent.Open()));
        Observer.Observe('inherent_read', Format(Inherent.Read()));
        Observer.Observe('inherent_entryno', Format(Inherent.EntryNo));
        Inherent.Close();
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
        Universal.DeleteAll();
        Observer.Expect('plain_open', 'Yes');
        Observer.Expect('plain_open|text', '');
        Observer.Expect('plain_open|code', '');
        Observer.Expect('inherent_open', 'Yes');
        Observer.Expect('inherent_read', 'Yes');
        Observer.Expect('inherent_entryno', '69789');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImport(XmlText: Text)
    begin
        ImportText(XmlText);
    end;

    local procedure ImportObserve(Name: Text; XmlText: Text)
    var
        Ok: Boolean;
    begin
        Ok := TryImport(XmlText);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
    end;

    local procedure ImportText(XmlText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(XmlText);
        TempBlob.CreateInStream(InS);
        Xmlport.Import(Xmlport::"LT U XmlPort", InS);
    end;

    [Test]
    procedure XmlPort_Import_Occurrence_Validation_TextType()
    var
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
    begin
        SeedPageSrc();
        State.Reset();
        ImportObserve('full_row', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="10" Dec="2.5" RequiredText="r" OptionalText="o" BigAttr="bigvalue"><Txt>abc</Txt><Rel>1</Rel><Rel2>9999</Rel2></Row></Root>');
        Observer.Observe('state_full_row', State.Dump());
        Observer.Observe('row10_exists', Format(Src.Get(10)));
        Observer.Observe('row10_note', Src.Note);
        Observer.Observe('row10_dec', Format(Src.Dec));
        Observer.Observe('row10_rel', Format(Src.Rel));
        Observer.Observe('row10_rel2', Format(Src.Rel2));
        Observer.Expect('full_row|ok', 'Yes');
        Observer.Expect('state_full_row', 'import required=r optional=o bigLength=8 big=bigvalue');
        Observer.Expect('row10_exists', 'Yes');
        Observer.Expect('row10_note', 'validated abc');
        Observer.Expect('row10_dec', '2.5');
        Observer.Expect('row10_rel', '1');
        Observer.Expect('row10_rel2', '9999');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_Import_MissingAndInvalid()
    var
        State: Codeunit "LT U State";
        Src: Record "LT U Page Src";
    begin
        SeedPageSrc();
        State.Reset();
        ImportObserve('missing_required_field_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Dec="2.5" RequiredText="r"><Txt>abc</Txt></Row></Root>');
        ImportObserve('missing_required_text_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="11" Dec="2.5"><Txt>abc</Txt></Row></Root>');
        ImportObserve('missing_optional_field_attribute', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="12" RequiredText="r"><Txt>abc</Txt></Row></Root>');
        Observer.Observe('row12_exists', Format(Src.Get(12)));
        Observer.Observe('row12_note', Src.Note);
        Observer.Observe('row12_txt', Src.Txt);
        ImportObserve('bad_relation_validated', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="13" RequiredText="r"><Rel>9999</Rel></Row></Root>');
        Observer.Observe('row13_exists', Format(Src.Get(13)));
        ImportObserve('bad_relation_not_validated', '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="14" RequiredText="r"><Rel2>9999</Rel2></Row></Root>');
        Observer.Observe('row14_exists', Format(Src.Get(14)));
        Observer.Observe('row14_rel2', Format(Src.Rel2));
        Observer.Observe('state', State.Dump());
        Observer.Expect('missing_required_field_attribute|ok', 'No');
        Observer.Expect('missing_required_field_attribute|text', 'Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.');
        Observer.Expect('missing_required_field_attribute|code', 'XmlPortInvalidXml');
        Observer.Expect('missing_required_text_attribute|ok', 'No');
        Observer.Expect('missing_required_text_attribute|text', 'Imported XML cannot validate with the schema: The required attribute ''RequiredText'' is missing.');
        Observer.Expect('missing_required_text_attribute|code', 'XmlPortInvalidXml');
        Observer.Expect('missing_optional_field_attribute|ok', 'Yes');
        Observer.Expect('row12_exists', 'Yes');
        Observer.Expect('row12_note', 'validated abc');
        Observer.Expect('row12_txt', 'abc');
        Observer.Expect('bad_relation_validated|ok', 'No');
        Observer.Expect('bad_relation_validated|text', 'The field Rel of table LT U Page Src contains a value (9999) that cannot be found in the related table (LT U Page Src).');
        Observer.Expect('bad_relation_validated|code', 'DB:PrimRecordNotFound');
        Observer.Expect('row13_exists', 'No');
        Observer.Expect('bad_relation_not_validated|ok', 'Yes');
        Observer.Expect('row14_exists', 'Yes');
        Observer.Expect('row14_rel2', '9999');
        Observer.Expect('state', 'import required=r optional= bigLength=0 big= | import required=r optional= bigLength=0 big=');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_Export_OptionalAttributes()
    var
        TempBlob: Codeunit "Temp Blob";
        Src: Record "LT U Page Src";
        OutS: OutStream;
        InS: InStream;
    begin
        SeedPageSrc();
        Src.Get(1);
        Src.Dec := 0;
        Src.Modify();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U XmlPort", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('export_zero_dec', ReadAll(InS));
        Src.Dec := 7.5;
        Src.Modify();
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U XmlPort", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('export_dec_7_5', ReadAll(InS));
        Observer.Expect('export_zero_dec', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\n<Root>\n  <Row Id="1" Dec="0.00" RequiredText="req" BigAttr="big">\n    <Txt>one</Txt>\n    <Rel>0</Rel>\n    <Rel2>0</Rel2>\n  </Row>\n</Root>\n');
        Observer.Expect('export_dec_7_5', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\n<Root>\n  <Row Id="1" Dec="7.50" RequiredText="req" BigAttr="big">\n    <Txt>one</Txt>\n    <Rel>0</Rel>\n    <Rel2>0</Rel2>\n  </Row>\n</Root>\n');
        Observer.Verify();
    end;
}
