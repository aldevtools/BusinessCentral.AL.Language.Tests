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
// Observed on the CI builds BC 27.5.46862.58057, 28.5.54151.58194 and 29.0.54011.55816: the 27 and 28 values are equal (the converter is
//   Aspose.Words 26.10.0 there), 29.0 differs (Aspose.Words 26.8.0). The converter writes its version into the Html as a generator meta
//   tag, so the hash and the char count include the converter version string: a different BC build can give a different hash.
// Facts observed per cell: completed, returned, error text and code, byte count, SHA-256 of the saved bytes, SHA-256 of GetBody,
//   and for the tenant cells whether the hash equals the hash of the same report's own layout (no rewrite of a Tenant Report Layout
//   row's docx on Insert). Values taken from the CI observation run of the probe pull request, guarded per version.
// Bound cells: RX Hash Bound (report 80031) with the hand-built RxHashBound.docx binds Text, Integer, Decimal and Date columns in a repeating row section.
// Linux suspect: none of these layouts has a picture (a picture cell is queued separately; it needs the Windows nightly).
// local object: the reports' own layouts and their dataset table are what the tests check.
// BC 29.1 (version change 29.1-aspose-words-version, guard BC29_1PLUS): Aspose.Words 26.10.0 again, so 29.1 takes the 27 and 28 values.
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

report 80031 "RX Hash Bound"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxHashBound;

    dataset
    {
        dataitem(Row; "RX Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
            column(Amount; Id * 1234.5) { AutoFormatType = 1; }
            column(Day; DMY2Date(1, 2, 2026)) { }
        }
    }

    rendering
    {
        layout(RxHashBound)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxHashBound.docx';
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
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '429');
        Observer.Expect('sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
        Observer.Expect('getbody chars', '429');
        Observer.Expect('getbody sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
#elif BC29PLUS
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', 'F17FE0E0CF4E23671E7C3221256F3F46F58505B479EB209E39C9C25AF872AE20');
        Observer.Expect('getbody chars', '428');
        Observer.Expect('getbody sha256', 'F17FE0E0CF4E23671E7C3221256F3F46F58505B479EB209E39C9C25AF872AE20');
#else
        Observer.Expect('chars', '429');
        Observer.Expect('sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
        Observer.Expect('getbody chars', '429');
        Observer.Expect('getbody sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_WordDefault_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Word Default", 3, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '429');
        Observer.Expect('sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
#elif BC29PLUS
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', 'F17FE0E0CF4E23671E7C3221256F3F46F58505B479EB209E39C9C25AF872AE20');
#else
        Observer.Expect('chars', '429');
        Observer.Expect('sha256', '08A98ED74F8ED6422E0F47C6C79DE89A54CD73DCB8A7A5CD1541E107FB99DE5D');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_WordAlpha_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Word Alpha", 2, Body);
        GetBodyCell(Observer, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1748');
        Observer.Expect('sha256', 'B9A3BCDDC928B21D9A7371CBE7A841BEF74C17FC4364A7D73DDDD9C5EBB4387B');
        Observer.Expect('getbody chars', '1748');
        Observer.Expect('getbody sha256', 'B9A3BCDDC928B21D9A7371CBE7A841BEF74C17FC4364A7D73DDDD9C5EBB4387B');
#elif BC29PLUS
        Observer.Expect('chars', '1747');
        Observer.Expect('sha256', '096C6CDFFA8D335E84FE37FABAA8A070C77F03103898FAE81DDE30BC2D69BB30');
        Observer.Expect('getbody chars', '1747');
        Observer.Expect('getbody sha256', '096C6CDFFA8D335E84FE37FABAA8A070C77F03103898FAE81DDE30BC2D69BB30');
#else
        Observer.Expect('chars', '1748');
        Observer.Expect('sha256', 'B9A3BCDDC928B21D9A7371CBE7A841BEF74C17FC4364A7D73DDDD9C5EBB4387B');
        Observer.Expect('getbody chars', '1748');
        Observer.Expect('getbody sha256', 'B9A3BCDDC928B21D9A7371CBE7A841BEF74C17FC4364A7D73DDDD9C5EBB4387B');
#endif
        Observer.Verify();
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
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
        Observer.Expect('getbody chars', '1330');
        Observer.Expect('getbody sha256', '2FBCF34F41BF065F463724DD4422B0891D253AA2CF2B3A6CAA124A607864C55E');
#elif BC29PLUS
        Observer.Expect('chars', '1336');
        Observer.Expect('sha256', '2F6A43A8F0CE15CFED0C90D266F2F9CE2B1FA62A9052A2B025BFA1854AC84C29');
        Observer.Expect('getbody chars', '1329');
        Observer.Expect('getbody sha256', 'CA6543A38BA5626FE3A2C0082923C6FA62D7B4D663523CD01BA2114B471BA50E');
#else
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
        Observer.Expect('getbody chars', '1330');
        Observer.Expect('getbody sha256', '2FBCF34F41BF065F463724DD4422B0891D253AA2CF2B3A6CAA124A607864C55E');
#endif
        Observer.Verify();
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
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
#elif BC29PLUS
        Observer.Expect('chars', '1336');
        Observer.Expect('sha256', '2F6A43A8F0CE15CFED0C90D266F2F9CE2B1FA62A9052A2B025BFA1854AC84C29');
#else
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
#endif
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
#elif BC29PLUS
        Observer.Expect('chars', '1336');
        Observer.Expect('sha256', '2F6A43A8F0CE15CFED0C90D266F2F9CE2B1FA62A9052A2B025BFA1854AC84C29');
#else
        Observer.Expect('chars', '1337');
        Observer.Expect('sha256', '66C10E37E1C9D3B4EAF515472E216CDEC0041F471855636C88A5DF1AD91E6D1F');
#endif
        Observer.Expect('tenant sha256 = own sha256', 'Yes');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '1330');
        Observer.Expect('getbody sha256', '2FBCF34F41BF065F463724DD4422B0891D253AA2CF2B3A6CAA124A607864C55E');
#elif BC29PLUS
        Observer.Expect('getbody chars', '1329');
        Observer.Expect('getbody sha256', 'CA6543A38BA5626FE3A2C0082923C6FA62D7B4D663523CD01BA2114B471BA50E');
#else
        Observer.Expect('getbody chars', '1330');
        Observer.Expect('getbody sha256', '2FBCF34F41BF065F463724DD4422B0891D253AA2CF2B3A6CAA124A607864C55E');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_TwoItems_ParentChild()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Two Items", 2, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '426');
        Observer.Expect('sha256', 'D019C73543B39C0383ABADADF021884226F954F6C98737BFC40C270E8CA89A81');
#elif BC29PLUS
        Observer.Expect('chars', '425');
        Observer.Expect('sha256', '210B3BD7FE0076834F035CBF470223568A35CB3C06328A835EFD87FC431AC5DB');
#else
        Observer.Expect('chars', '426');
        Observer.Expect('sha256', 'D019C73543B39C0383ABADADF021884226F954F6C98737BFC40C270E8CA89A81');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_ExtColumn()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Ext Base", 2, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '425');
        Observer.Expect('sha256', '509E377892CD7B011484D4AFDD04ADC261BB7901240EA03EC8DFE9D5D8DEA044');
#elif BC29PLUS
        Observer.Expect('chars', '424');
        Observer.Expect('sha256', '290F1C18D4D8623D231D944466A499DB960DC83D33D2FC0471688DCF0C5D9F73');
#else
        Observer.Expect('chars', '425');
        Observer.Expect('sha256', '509E377892CD7B011484D4AFDD04ADC261BB7901240EA03EC8DFE9D5D8DEA044');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_LegacyDefaultLayoutWord()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Legacy Word", 2, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', '929BBA7B63A62913DFB5B26CE8110F33434412034A9FB18068198C97AF91B307');
#elif BC29PLUS
        Observer.Expect('chars', '427');
        Observer.Expect('sha256', '7ADB40FAB2163897CACE9EE3F231B99C69C72B46DF32BEA860563DD2E1CEAF60');
#else
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', '929BBA7B63A62913DFB5B26CE8110F33434412034A9FB18068198C97AF91B307');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Hash_Values_DecimalDateSpecialChars()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        // Decimal with AutoFormat, a Date, and & < > " in a value: the dataset text the merger binds.
        HashCell(Observer, Report::"RX Hash Values", 2, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', '1F295BA297A97A8DCA8DB1FEE05269DE5B2F6844E9BED71B7F2F8CD98AD2AC7F');
#elif BC29PLUS
        Observer.Expect('chars', '427');
        Observer.Expect('sha256', 'AFCF8B6262AAF294A49A4F0D0F25601B7B87CC7A5D4B1B179A99996C7E968664');
#else
        Observer.Expect('chars', '428');
        Observer.Expect('sha256', '1F295BA297A97A8DCA8DB1FEE05269DE5B2F6844E9BED71B7F2F8CD98AD2AC7F');
#endif
        Observer.Verify();
    end;

    // Hand-built layout RxHashBound.docx: two static paragraphs with rgba(), and a repeating row section whose cells are bound to a
    // Text, an Integer, a Decimal (AutoFormatType 1) and a Date column of the dataset.
    local procedure BoundFacts(var Observer: Codeunit "Probe Observer"; Body: Text)
    begin
        Observer.Observe('count RXROW', Format(Html.CountOf(Body, 'RXROW')));
        Observer.Observe('has RXROW1', Format(StrPos(Body, 'RXROW1') > 0));
        Observer.Observe('has RXROW3', Format(StrPos(Body, 'RXROW3') > 0));
        Observer.Observe('has 1,234.5', Format(StrPos(Body, '1,234.5') > 0));
        Observer.Observe('has 3,703.5', Format(StrPos(Body, '3,703.5') > 0));
        Observer.Observe('has 1/2/2026', Format(StrPos(Body, '1/2/2026') > 0));
        Observer.Observe('has 01/02/2026', Format(StrPos(Body, '01/02/2026') > 0));
        Observer.Observe('has 2026-02-01', Format(StrPos(Body, '2026-02-01') > 0));
    end;

    [Test]
    procedure Bound_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Hash Bound", 1, Body);
        BoundFacts(Observer, Body);
        GetBodyCell(Observer, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1443');
        Observer.Expect('sha256', 'BFDED14D7DA92062A2DED3074D0984C9ABF692092D1663A3B1836833A73E94A8');
#elif BC29PLUS
        Observer.Expect('chars', '1442');
        Observer.Expect('sha256', '98179F947EC44226830B77796ADC753B270CA3993AE9811F1DBC65BDA4436286');
#else
        Observer.Expect('chars', '1443');
        Observer.Expect('sha256', 'BFDED14D7DA92062A2DED3074D0984C9ABF692092D1663A3B1836833A73E94A8');
#endif
        Observer.Expect('count RXROW', '1');
        Observer.Expect('has RXROW1', 'Yes');
        Observer.Expect('has RXROW3', 'No');
        Observer.Expect('has 1,234.5', 'Yes');
        Observer.Expect('has 3,703.5', 'No');
        Observer.Expect('has 1/2/2026', 'No');
        Observer.Expect('has 01/02/2026', 'No');
        Observer.Expect('has 2026-02-01', 'No');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '1442');
        Observer.Expect('getbody sha256', '2E3211DB325BDC8A4857A0CAF9620BA304657FF2BACD6CC5A110808994D860FC');
#elif BC29PLUS
        Observer.Expect('getbody chars', '1441');
        Observer.Expect('getbody sha256', '97A845E022309E20DA87091ABDB2AF03F91A8133240A506E10614D367DC01AA2');
#else
        Observer.Expect('getbody chars', '1442');
        Observer.Expect('getbody sha256', '2E3211DB325BDC8A4857A0CAF9620BA304657FF2BACD6CC5A110808994D860FC');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Bound_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        HashCell(Observer, Report::"RX Hash Bound", 3, Body);
        BoundFacts(Observer, Body);
        GetBodyCell(Observer, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2987');
        Observer.Expect('sha256', 'AB8185113763729DE655C022C6B4EF8974FC7CD6B11E233D03C5F7BD6D8FCB43');
#elif BC29PLUS
        Observer.Expect('chars', '2986');
        Observer.Expect('sha256', 'B10772A6C995FD0BC067AE49DE2A07703AC15A7A771FDA537FB5D0805766DB0E');
#else
        Observer.Expect('chars', '2987');
        Observer.Expect('sha256', 'AB8185113763729DE655C022C6B4EF8974FC7CD6B11E233D03C5F7BD6D8FCB43');
#endif
        Observer.Expect('count RXROW', '3');
        Observer.Expect('has RXROW1', 'Yes');
        Observer.Expect('has RXROW3', 'Yes');
        Observer.Expect('has 1,234.5', 'Yes');
        Observer.Expect('has 3,703.5', 'Yes');
        Observer.Expect('has 1/2/2026', 'No');
        Observer.Expect('has 01/02/2026', 'No');
        Observer.Expect('has 2026-02-01', 'No');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2986');
        Observer.Expect('getbody sha256', 'D0EB55D4A677E35FB7D038AEDB32D9D9F88500821B318D42B3E4E0076D028B2A');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2985');
        Observer.Expect('getbody sha256', '5F5B84CDD171A541F97F0B315295D1A952BEC717469E112C87D9977ABEDF76F2');
#else
        Observer.Expect('getbody chars', '2986');
        Observer.Expect('getbody sha256', 'D0EB55D4A677E35FB7D038AEDB32D9D9F88500821B318D42B3E4E0076D028B2A');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Bound_RowCountChangesHash()
    var
        Observer: Codeunit "Probe Observer";
        One: Text;
        Three: Text;
    begin
        HashCell(Observer, Report::"RX Hash Bound", 1, One);
        HashCell(Observer, Report::"RX Hash Bound", 3, Three);
        Observer.Observe('sha 1 row = sha 3 rows', Format(Sha(One) = Sha(Three)));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1443');
        Observer.Expect('sha256', 'BFDED14D7DA92062A2DED3074D0984C9ABF692092D1663A3B1836833A73E94A8');
#elif BC29PLUS
        Observer.Expect('chars', '1442');
        Observer.Expect('sha256', '98179F947EC44226830B77796ADC753B270CA3993AE9811F1DBC65BDA4436286');
#else
        Observer.Expect('chars', '1443');
        Observer.Expect('sha256', 'BFDED14D7DA92062A2DED3074D0984C9ABF692092D1663A3B1836833A73E94A8');
#endif
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2987');
        Observer.Expect('sha256', 'AB8185113763729DE655C022C6B4EF8974FC7CD6B11E233D03C5F7BD6D8FCB43');
#elif BC29PLUS
        Observer.Expect('chars', '2986');
        Observer.Expect('sha256', 'B10772A6C995FD0BC067AE49DE2A07703AC15A7A771FDA537FB5D0805766DB0E');
#else
        Observer.Expect('chars', '2987');
        Observer.Expect('sha256', 'AB8185113763729DE655C022C6B4EF8974FC7CD6B11E233D03C5F7BD6D8FCB43');
#endif
        Observer.Expect('sha 1 row = sha 3 rows', 'No');
        Observer.Verify();
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
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('err|code', 'ReportResultEmpty');
        Observer.Expect('has value', 'No');
        Observer.Verify();
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
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('has value', 'Yes');
        Observer.Verify();
    end;
}
