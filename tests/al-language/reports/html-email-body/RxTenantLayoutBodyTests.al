// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RX Row, RX Word Alpha and RX Html Body of RxHtmlBodyFixtures.al (80012, 80014, 80016);
//   RX Word Default (80013); RX Word Rgba, RX Legacy Word, RX Two Items, RX Ext Base, RX Ext Column of RxLayoutSelFixtures.al
//   (80021, 80025 - 80028); test codeunit 80024
// Probe (al-runner issue 6924): the Html of a report saved through a TEMPORARY layout selection that names a user-defined Tenant Report
//   Layout row (Word, named by a GUID as the reporter's layouts are, or by a plain name; its docx is the report's own Word layout, read with
//   Report.WordLayout), as Report Selections.SaveReportAsHTML saves an e-mail body, then passed through Email Message.Create and GetBody
//   (Email Message Impl. ReplaceRgbaColorsWithRgb). Asked: the 'rgba(' and 'rgb(' counts of the body and of GetBody, GetBody = body and
//   the length, Html true and false; for RX Word Alpha (transparent colors) and RX Word Rgba, whose static text holds rgba(1,2,3,1),
//   rgba(4,5,6,0.5), rgba(7, 8, 9, 1.0) and rgb(1, 2, 3); the default layout of RX Word Rgba as the control.
// The same replace on the report's default Word layout without a selection: RxEmailBodyTests.al.
// Also the same body facts for: a report declared with the legacy DefaultLayout = Word and WordLayout (RX Legacy Word), a report with a
//   parent and a child data item (RX Two Items), a report whose reportextension adds a column (RX Ext Base, RX Ext Column), and the call
//   form of Report Selections.DoSaveReportAsHTMLInTempBlob: SetTempLayoutSelectedName(''), then the statement form of the five-argument
//   Report.SaveAs with a RecordRef filtered to one of two rows.
// BC versions: 27 - 29

codeunit 80024 "RX Tenant Layout Body Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";
        ToTxt: Label 'rx.probe@contoso.com', Locked = true;
        TenantGuidNameTxt: Label '{3C9D2A71-6B4E-4F08-A1D5-7E2F9B0C4D63}', Locked = true;
        TenantPlainNameTxt: Label 'RX Tenant Rgba', Locked = true;

    local procedure Cleanup(ReportId: Integer)
    var
        TenantLayout: Record "Tenant Report Layout";
        Selection: Record "Report Layout Selection";
    begin
        TenantLayout.SetRange("Report ID", ReportId);
        TenantLayout.DeleteAll();
        Selection.ClearTempLayoutSelected();
    end;

    local procedure InsertTenantCopy(ReportId: Integer; LayoutName: Text[250])
    var
        TenantLayout: Record "Tenant Report Layout";
        InS: InStream;
    begin
        TenantLayout.Init();
        TenantLayout."Report ID" := ReportId;
        TenantLayout.Name := LayoutName;
        TenantLayout."Layout Format" := TenantLayout."Layout Format"::Word;
        TenantLayout.Description := 'RX user-defined word layout';
        Report.WordLayout(ReportId, InS);
        TenantLayout.Layout.ImportStream(InS, 'RX user-defined word layout');
        TenantLayout.Insert();
    end;

    local procedure RenderFacts(var Observer: Codeunit "Probe Observer"; ReportId: Integer; var Body: Text)
    var
        Selection: Record "Report Layout Selection";
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(2);
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe('completed', Format(Completed));
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('eos after read', Format(Eos));
        Observer.Observe('starts <html', Format(LowerCase(CopyStr(Body, 1, 5)) = '<html'));
        Observer.Observe('selected name after', Selection.GetTempSelectedLayoutName().Replace(TenantGuidNameTxt, '<tenant guid>'));
    end;

    local procedure BodyFacts(var Observer: Codeunit "Probe Observer"; Body: Text)
    var
        MsgHtml: Codeunit "Email Message";
        MsgPlain: Codeunit "Email Message";
        Got: Text;
    begin
        Observer.Observe('body <> empty', Format(Body <> ''));
        Observer.Observe('body rgba( count', Format(Html.CountOf(Body, 'rgba(')));
        Observer.Observe('body rgb( count', Format(Html.CountOf(Body, 'rgb(')));
        MsgHtml.Create(ToTxt, 'RX subject', Body, true);
        Got := MsgHtml.GetBody();
        Observer.Observe('html GetBody = body', Format(Got = Body));
        Observer.Observe('html length equal', Format(StrLen(Got) = StrLen(Body)));
        Observer.Observe('html GetBody rgba( count', Format(Html.CountOf(Got, 'rgba(')));
        Observer.Observe('html GetBody rgb( count', Format(Html.CountOf(Got, 'rgb(')));
        MsgPlain.Create(ToTxt, 'RX subject', Body, false);
        Got := MsgPlain.GetBody();
        Observer.Observe('plain GetBody = body', Format(Got = Body));
        Observer.Observe('plain length equal', Format(StrLen(Got) = StrLen(Body)));
    end;

    local procedure TextCounts(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    begin
        Observer.Observe(Name + ' rgba(1,2,3,1)', Format(Html.CountOf(Value, 'rgba(1,2,3,1)')));
        Observer.Observe(Name + ' rgb(1, 2, 3)', Format(Html.CountOf(Value, 'rgb(1, 2, 3)')));
        Observer.Observe(Name + ' rgba(4,5,6,0.5)', Format(Html.CountOf(Value, 'rgba(4,5,6,0.5)')));
        Observer.Observe(Name + ' rgba(7, 8, 9, 1.0)', Format(Html.CountOf(Value, 'rgba(7, 8, 9, 1.0)')));
        Observer.Observe(Name + ' rgb(7, 8, 9)', Format(Html.CountOf(Value, 'rgb(7, 8, 9)')));
    end;

    local procedure RgbaTextFacts(var Observer: Codeunit "Probe Observer"; Body: Text)
    var
        MsgHtml: Codeunit "Email Message";
        MsgPlain: Codeunit "Email Message";
    begin
        TextCounts(Observer, 'body', Body);
        MsgHtml.Create(ToTxt, 'RX subject', Body, true);
        TextCounts(Observer, 'html GetBody', MsgHtml.GetBody());
        MsgPlain.Create(ToTxt, 'RX subject', Body, false);
        TextCounts(Observer, 'plain GetBody', MsgPlain.GetBody());
    end;

    [Test]
    procedure TenantGuid_WordAlpha_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
        Body: Text;
    begin
        Cleanup(Report::"RX Word Alpha");
        InsertTenantCopy(Report::"RX Word Alpha", TenantGuidNameTxt);
        Selection.SetTempLayoutSelectedName(TenantGuidNameTxt, NullGuid);
        RenderFacts(Observer, Report::"RX Word Alpha", Body);
        Cleanup(Report::"RX Word Alpha");
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure TenantGuid_WordRgba_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
        Body: Text;
    begin
        Cleanup(Report::"RX Word Rgba");
        InsertTenantCopy(Report::"RX Word Rgba", TenantGuidNameTxt);
        Selection.SetTempLayoutSelectedName(TenantGuidNameTxt, NullGuid);
        RenderFacts(Observer, Report::"RX Word Rgba", Body);
        Cleanup(Report::"RX Word Rgba");
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure TenantGuid_WordRgba_TextCounts()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Cleanup(Report::"RX Word Rgba");
        InsertTenantCopy(Report::"RX Word Rgba", TenantGuidNameTxt);
        Selection.SetTempLayoutSelectedName(TenantGuidNameTxt, NullGuid);
        Html.Rows(2);
        Html.Render(Report::"RX Word Rgba", Body, Completed, Ok, Eos);
        Cleanup(Report::"RX Word Rgba");
        Observer.Observe('returned', Format(Ok));
        RgbaTextFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure TenantPlainName_WordRgba_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
        Body: Text;
    begin
        Cleanup(Report::"RX Word Rgba");
        InsertTenantCopy(Report::"RX Word Rgba", TenantPlainNameTxt);
        Selection.SetTempLayoutSelectedName(TenantPlainNameTxt, NullGuid);
        RenderFacts(Observer, Report::"RX Word Rgba", Body);
        Cleanup(Report::"RX Word Rgba");
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Default_WordRgba_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Cleanup(Report::"RX Word Rgba");
        RenderFacts(Observer, Report::"RX Word Rgba", Body);
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Default_WordRgba_TextCounts()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Cleanup(Report::"RX Word Rgba");
        Html.Rows(2);
        Html.Render(Report::"RX Word Rgba", Body, Completed, Ok, Eos);
        Observer.Observe('returned', Format(Ok));
        RgbaTextFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure LegacyDefaultLayoutWord_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        RenderFacts(Observer, Report::"RX Legacy Word", Body);
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure ParentChildDataItems_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        RenderFacts(Observer, Report::"RX Two Items", Body);
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure ReportExtensionColumn_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        RenderFacts(Observer, Report::"RX Ext Base", Body);
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySaveWithRecRef(ReportId: Integer; var TempBlob: Codeunit "Temp Blob"; RecRef: RecordRef)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Report.SaveAs(ReportId, '', ReportFormat::Html, OutS, RecRef);
    end;

    // The call form of Report Selections.DoSaveReportAsHTMLInTempBlob: an empty temporary selection, then the statement form of the
    // five-argument SaveAs with a RecordRef of the document (here filtered to row 1 of 2).
    [Test]
    procedure ReportSelectionsForm_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        Row: Record "RX Row";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InS: InStream;
        NullGuid: Guid;
        Body: Text;
        Completed: Boolean;
    begin
        Html.Rows(2);
        Selection.SetTempLayoutSelectedName('', NullGuid);
        Row.SetRange(Id, 1);
        RecRef.GetTable(Row);
        ClearLastError();
        Completed := TrySaveWithRecRef(Report::"RX Word Default", TempBlob, RecRef);
        Observer.Observe('completed', Format(Completed));
        Observer.ObserveError('err');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
        Observer.Observe('starts <html', Format(LowerCase(CopyStr(Body, 1, 5)) = '<html'));
        Observer.Observe('holds RXROW1', Format(StrPos(Body, 'RXROW1') > 0));
        Observer.Observe('holds RXROW2', Format(StrPos(Body, 'RXROW2') > 0));
        BodyFacts(Observer, Body);
        Observer.Finish();
    end;
}
