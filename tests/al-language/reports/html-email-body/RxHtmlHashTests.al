// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RX Row, RX Word Default, RX Word Alpha, RX Html Body of RxHtmlBodyFixtures.al (80012 - 80016);
//   RX Word Rgba, RX Legacy Word, RX Two Items, RX Ext Base, RX Ext Column of RxLayoutSelFixtures.al (80021, 80025 - 80028);
//   NEW: RX Hash Values (report 80030, below) with its generated Word layout; test codeunit 80029
// Probe (al-runner issue 6924, ADR-040 amendment 2026-11-15, Proposed): the exact bytes BC writes for Report.SaveAs(.., Html, ..)
//   of a Word layout, as a SHA-256 and a byte count, for the renders the e-mail body probes already measure. BC makes this Html as
//   WordTransformation.ConvertToHtml(OfficeWordDocumentMerger.MergeWordDocument(layout, dataset, null, ..)); the runner calls the
//   same two methods from the artifact. A hash equal to the runner's own render on each major is the gate of that amendment.
//   Also the hash of Email Message.GetBody after Create(.., Body, true), where System Application runs its rgba replace.
// Facts observed per cell: completed, returned, error text and code, byte count, SHA-256 of the saved bytes, SHA-256 of GetBody,
//   and for the tenant cells whether the hash equals the hash of the same report's own layout (no rewrite of a Tenant Report Layout
//   row's docx on Insert). Expected values differ by major (Aspose.Words 25.7 / 26.3 / 26.10 writes its version into the Html):
//   filled from the local observe host per major, guarded per version.
// Linux suspect: none of these layouts has a picture (a picture cell is queued separately; it needs the Windows nightly).
// local object: the reports' own layouts and their dataset table are what the tests check.
// BC versions: 27 - 29

report 80030 "RX Hash Values"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxHashValues;

    dataset
    {
        dataitem(Row; "RX Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
            column(Amount; Id * 1234.5) { AutoFormatType = 1; }
            column(Day; DMY2Date(1, 2, 2026)) { }
            column(Special; 'A & B <c> "d"') { }
        }
    }

    rendering
    {
        layout(RxHashValues)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxHashValues.docx';
        }
    }
}

codeunit 80029 "RX Html Hash Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";
        TenantGuidNameTxt: Label '{4F1C7B8E-2D3A-4B5C-9E6F-0A1B2C3D4E5F}', Locked = true;

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

    local procedure Sha(Value: Text): Text
    var
        Crypto: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(Crypto.GenerateHash(Value, HashAlgorithmType::SHA256));
    end;

    // Saves ReportId as Html with Rows rows of RX Row, reads the bytes back whole, and observes the facts of the saved file.
    local procedure HashCell(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Rows: Integer; var Body: Text)
    var
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(Rows);
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe('completed', Format(Completed));
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('chars', Format(StrLen(Body)));
        Observer.Observe('sha256', Sha(Body));
    end;

    local procedure GetBodyCell(var Observer: Codeunit "Probe Observer"; Body: Text)
    var
        Message: Codeunit "Email Message";
    begin
        Message.Create('probe@example.com', 'probe', Body, true);
        Observer.Observe('getbody chars', Format(StrLen(Message.GetBody())));
        Observer.Observe('getbody sha256', Sha(Message.GetBody()));
    end;

    [Test]
    procedure Hash_WordDefault_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Word Default", 1, Body);
        GetBodyCell(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_WordDefault_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Word Default", 3, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_WordAlpha_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Word Alpha", 2, Body);
        GetBodyCell(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_WordRgba_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        // The layout's static text holds rgba(r,g,b,1): GetBody differs from the body by System Application's replace.
        HashCell(Observer, Report::"RX Word Rgba", 2, Body);
        GetBodyCell(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_TenantGuid_WordRgba_SameAsOwnLayout()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
        OwnBody: Text;
        Body: Text;
    begin
        Cleanup(Report::"RX Word Rgba");
        Html.Rows(2);
        HashCell(Observer, Report::"RX Word Rgba", 2, OwnBody);
        InsertTenantCopy(Report::"RX Word Rgba", TenantGuidNameTxt);
        Selection.SetTempLayoutSelectedName(TenantGuidNameTxt, NullGuid);
        HashCell(Observer, Report::"RX Word Rgba", 2, Body);
        Cleanup(Report::"RX Word Rgba");
        Observer.Observe('tenant sha256 = own sha256', Format(Sha(Body) = Sha(OwnBody)));
        GetBodyCell(Observer, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_TwoItems_ParentChild()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Two Items", 2, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_ExtColumn()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Ext Base", 2, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_LegacyDefaultLayoutWord()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Legacy Word", 2, Body);
        Observer.Finish();
    end;

    [Test]
    procedure Hash_Values_DecimalDateSpecialChars()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        // Decimal with AutoFormat, a Date, and & < > " in a value: the dataset text the merger binds.
        HashCell(Observer, Report::"RX Hash Values", 2, Body);
        Observer.Finish();
    end;

    // Save-table neighbors of al-runner issue 6924 (not rendering): what SaveAs Pdf answers for a Word layout report with two data
    // items and no dataset row, and while a Report Layout Selection row of the company names a Word layout of the report.
    [Test]
    procedure Pdf_TwoItems_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Html.Rows(0);
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"RX Two Items", '', ReportFormat::Pdf, OutS);
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('has value', Format(TempBlob.HasValue()));
        Observer.Finish();
    end;

    [Test]
    procedure Pdf_CompanySelectionRow_Word()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Html.Rows(1);
        Selection.Init();
        Selection."Report ID" := Report::"RX Two Items";
        Selection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Selection."Company Name"));
        Selection.Type := Selection.Type::"Word (built-in)";
        if not Selection.Insert() then
            Selection.Modify();
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"RX Two Items", '', ReportFormat::Pdf, OutS);
        Selection.Delete();
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('has value', Format(TempBlob.HasValue()));
        Observer.Finish();
    end;
}
