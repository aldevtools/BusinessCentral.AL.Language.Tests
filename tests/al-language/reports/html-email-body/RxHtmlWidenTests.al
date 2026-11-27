// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RX Row, RX Html Body of RxHtmlBodyFixtures.al (80012, 80016); RX Hash Bound of RxHtmlHashTests.al (80031)
//   NEW: table RX Zero Row (80032), reports RX Wd Plain, RX Wd Styles, RX Wd Theme, RX Wd Numbering, RX Wd Header, RX Wd Caption,
//   RX Wd Blank Zero (80033 - 80039, below) with their hand-built Word layouts; test codeunit 80045
// Probe (al-runner issue 6924, ADR-040 amendment 2026-11-15): the Html that BC writes for Report.SaveAs(.., Html, ..) of Word layouts with the
//   parts partner layouts have. Every layout is the bound layout RxHashBound.docx of RxHtmlHashTests.al (static text, a repeating row section
//   with RowId, RowTxt, Amount and Day) plus ONE addition: a styles part (paragraph style "Rx Arial", font Arial, applied to the first
//   paragraph), a theme part (font scheme Georgia / Verdana, referenced by theme fonts on the two static runs), a numbering part (two bulleted
//   paragraphs, no tab stops), a header part (referenced from sectPr). Two more cells: a report with Caption = 'Rx Cap' on the plain bound
//   layout (RxWdCaption.docx), and an Integer column over a table field with BlankZero = true holding 0, next to a column over a plain Integer
//   field holding 0 (BlankZero is a table field property; an AL report column has no such property).
// RX Wd Plain is the control: the plain bound layout with no addition, to say whether an addition changes the Html. The layout files were
//   built by a script from RxHashBound.docx: the namespace of the report is rewritten in the bindings and the two custom XML parts.
// Facts observed per cell: completed, returned, error, char count and SHA-256 of the saved Html and of Email Message.GetBody after
//   Create(.., Body, true), whether the hash equals the hash of the plain layout, the title, the font-family values, the visible text.
// Observed on the CI builds BC 27.5.46862.58057, 28.5.54151.58194 and 29.0.54011.55816: the 27 and 28 values are equal (Aspose.Words 26.10.0),
//   29.0 differs (Aspose.Words 26.8.0, one char less); the converter writes its version into the Html, so every hash is per Aspose version.
// What BC did (same on all three builds unless noted):
//   - Title: the Html <title> is the report Caption when the report has one ('Rx Cap'), else the report name ('RX Wd Plain'). The caption
//     changes the char count by -5 against the plain layout ('Rx Cap' is 6 chars, 'RX Wd Plain' 11).
//   - Styles part: the paragraph style with font Arial gives font-family 'Times New Roman' and Arial
//     (the first is not named in the layout); +89 chars against the plain layout, whose only font-family is Calibri.
//   - Theme part: the theme fonts resolve to the font scheme: font-family Verdana (minor) and Georgia (major); +21 chars.
//   - Numbering part: each bulleted paragraph gets the marker U+2022 in its own span, then a span of nine &#xa0; (no tab character is
//     written), then the paragraph text; +926 chars.
//   - Header part: the header text is written into the Html in a div with the header-primary style before the body paragraphs and is part of
//     the visible text; +153 chars.
//   - BlankZero = true on a table field: the column over that field and a column over a plain Integer field both render 0 (no blank).
//   - Date 1 Feb 2026 is rendered 2/1/2026, Decimal 1,234.50, as in the bound layout probe. The control RX Wd Plain does not hash equal to
//     RX Hash Bound: the report name is part of the Html (title).
// local object: the reports' own layouts and their dataset tables are what the tests check.
// BC 29.1 (version change 29.1-aspose-words-version, guard BC29_1PLUS): Aspose.Words 26.10.0 again, so 29.1 takes the 27 and 28 values.
// BC versions: 27 - 29

table 80032 "RX Zero Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
        field(3; Qty; Integer) { }
        field(4; QtyField; Integer) { BlankZero = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 80033 "RX Wd Plain"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdPlain;

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
        layout(RxWdPlain)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdPlain.docx';
        }
    }
}

report 80034 "RX Wd Styles"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdStyles;

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
        layout(RxWdStyles)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdStyles.docx';
        }
    }
}

report 80035 "RX Wd Theme"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdTheme;

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
        layout(RxWdTheme)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdTheme.docx';
        }
    }
}

report 80036 "RX Wd Numbering"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdNumbering;

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
        layout(RxWdNumbering)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdNumbering.docx';
        }
    }
}

report 80037 "RX Wd Header"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdHeader;

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
        layout(RxWdHeader)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdHeader.docx';
        }
    }
}

report 80038 "RX Wd Caption"
{
    Caption = 'Rx Cap';
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdCaption;

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
        layout(RxWdCaption)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdCaption.docx';
        }
    }
}

report 80039 "RX Wd Blank Zero"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWdBlankZero;

    dataset
    {
        dataitem(Row; "RX Zero Row")
        {
            column(RowTxt; Txt) { }
            column(QtyField; QtyField) { }
            column(QtyPlain; Qty) { }
        }
    }

    rendering
    {
        layout(RxWdBlankZero)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWdBlankZero.docx';
        }
    }
}

codeunit 80045 "RX Html Widen Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";

    local procedure Sha(Value: Text): Text
    var
        Crypto: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(Crypto.GenerateHash(Value, HashAlgorithmType::SHA256));
    end;

    local procedure Between(Value: Text; StartTag: Text; EndTag: Text): Text
    var
        StartAt: Integer;
        Rest: Text;
        EndAt: Integer;
    begin
        StartAt := StrPos(Value, StartTag);
        if StartAt = 0 then
            exit('<none>');
        Rest := CopyStr(Value, StartAt + StrLen(StartTag));
        EndAt := StrPos(Rest, EndTag);
        if EndAt = 0 then
            exit('<open>');
        exit(CopyStr(Rest, 1, EndAt - 1));
    end;

    // Every value after font-family: up to the next semicolon or double quote, each distinct one once, in order of appearance.
    local procedure FontFamilies(Value: Text): Text
    var
        Seen: List of [Text];
        Found: Text;
        Rest: Text;
        At: Integer;
        Cut: Integer;
        Cut2: Integer;
        Result: Text;
    begin
        Rest := Value;
        At := StrPos(Rest, 'font-family:');
        while At > 0 do begin
            Rest := CopyStr(Rest, At + StrLen('font-family:'));
            Cut := StrPos(Rest, ';');
            Cut2 := StrPos(Rest, '"');
            if (Cut = 0) or ((Cut2 > 0) and (Cut2 < Cut)) then
                Cut := Cut2;
            if Cut = 0 then
                Cut := StrLen(Rest) + 1;
            Found := CopyStr(Rest, 1, Cut - 1);
            if not Seen.Contains(Found) then begin
                Seen.Add(Found);
                Result += '[' + Found + ']';
            end;
            At := StrPos(Rest, 'font-family:');
        end;
        if Result = '' then
            exit('<none>');
        exit(Result);
    end;

    // The visible text: everything outside < > pairs, runs of markup shown as one bar.
    local procedure TextOnly(Value: Text): Text
    var
        Result: Text;
        InTag: Boolean;
        Ch: Text;
        I: Integer;
        LastBar: Boolean;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := CopyStr(Value, I, 1);
            if Ch = '<' then
                InTag := true
            else
                if Ch = '>' then begin
                    InTag := false;
                    if not LastBar then
                        Result += '|';
                    LastBar := true;
                end else
                    if not InTag then begin
                        Result += Ch;
                        LastBar := false;
                    end;
        end;
        exit(Result);
    end;

    local procedure Around(Value: Text; Part: Text; Before: Integer; After: Integer): Text
    var
        At: Integer;
    begin
        At := StrPos(Value, Part);
        if At = 0 then
            exit('<none>');
        exit(CopyStr(Value, Maximum(1, At - Before), Minimum(At - 1, Before) + StrLen(Part) + After));
    end;

    local procedure Maximum(A: Integer; B: Integer): Integer
    begin
        if A > B then
            exit(A);
        exit(B);
    end;

    local procedure Minimum(A: Integer; B: Integer): Integer
    begin
        if A < B then
            exit(A);
        exit(B);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; ReportId: Integer; var Body: Text)
    var
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
        Message: Codeunit "Email Message";
    begin
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe('completed', Format(Completed));
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Observer.Observe('chars', Format(StrLen(Body)));
        Observer.Observe('sha256', Sha(Body));
        Message.Create('probe@example.com', 'probe', Body, true);
        Observer.Observe('getbody chars', Format(StrLen(Message.GetBody())));
        Observer.Observe('getbody sha256', Sha(Message.GetBody()));
        Observer.Observe('title', Between(Body, '<title>', '</title>'));
        Observer.Observe('font-family', FontFamilies(Body));
        Observer.Observe('count RXROW', Format(Html.CountOf(Body, 'RXROW')));
        Observer.Observe('text', TextOnly(Body));
    end;

    local procedure VersusPlain(var Observer: Codeunit "Probe Observer"; Body: Text)
    var
        PlainBody: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Render(Report::"RX Wd Plain", PlainBody, Completed, Ok, Eos);
        Observer.Observe('sha256 = plain sha256', Format(Sha(Body) = Sha(PlainBody)));
        Observer.Observe('chars - plain chars', Format(StrLen(Body) - StrLen(PlainBody)));
    end;

    [Test]
    procedure Plain_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
        BoundBody: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Plain", Body);
        Html.Render(Report::"RX Hash Bound", BoundBody, Completed, Ok, Eos);
        Observer.Observe('sha256 = RX Hash Bound sha256', Format(Sha(Body) = Sha(BoundBody)));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2213');
#elif BC29PLUS
        Observer.Expect('chars', '2212');
#else
        Observer.Expect('chars', '2213');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', '8002BE6A1B9CBC1ABD0FD156D5F1DFA4C07067AED1274BBEB9B86548FAE48CD5');
#elif BC29PLUS
        Observer.Expect('sha256', '8A4B210CD0B62D1F5F750AAFDAB38D34805E626F89A669A3ACE1C9518EF878F8');
#else
        Observer.Expect('sha256', '8002BE6A1B9CBC1ABD0FD156D5F1DFA4C07067AED1274BBEB9B86548FAE48CD5');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2212');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2211');
#else
        Observer.Expect('getbody chars', '2212');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', 'ACC582AC89DFD5FE3CC47254646C56D482D7757D9CBD0BA7470FFAB4E6154190');
#elif BC29PLUS
        Observer.Expect('getbody sha256', '8061CCB32FB329DBBB81E49BE8B18BAAFCAD23A77E0DFB80EC640A15F813D458');
#else
        Observer.Expect('getbody sha256', 'ACC582AC89DFD5FE3CC47254646C56D482D7757D9CBD0BA7470FFAB4E6154190');
#endif
        Observer.Expect('title', 'RX Wd Plain');
        Observer.Expect('font-family', '[Calibri]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|RX Wd Plain|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = RX Hash Bound sha256', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Styles_ArialParagraphStyle()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Styles", Body);
        VersusPlain(Observer, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2302');
#elif BC29PLUS
        Observer.Expect('chars', '2301');
#else
        Observer.Expect('chars', '2302');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', '35AF7EE8E5190BA249BB28AF6F871D164234FE7068C0D32C966C5F7E848111AF');
#elif BC29PLUS
        Observer.Expect('sha256', 'ACAA5D7FF49398AA4F8D7C832525FC6C01B762F24C6AC4DB18399A3C15D0ABC0');
#else
        Observer.Expect('sha256', '35AF7EE8E5190BA249BB28AF6F871D164234FE7068C0D32C966C5F7E848111AF');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2301');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2300');
#else
        Observer.Expect('getbody chars', '2301');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', '26A610D3600E78766A7BC6076495051EA9FC41712CC953028CA7D79446E240F8');
#elif BC29PLUS
        Observer.Expect('getbody sha256', '943B6CF7D51EBCF8A6B2B09ED43772F316317B0A29A445BB6062C1636FA67244');
#else
        Observer.Expect('getbody sha256', '26A610D3600E78766A7BC6076495051EA9FC41712CC953028CA7D79446E240F8');
#endif
        Observer.Expect('title', 'RX Wd Styles');
        Observer.Expect('font-family', '[''Times New Roman''][Arial]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|RX Wd Styles|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = plain sha256', 'No');
        Observer.Expect('chars - plain chars', '89');
        Observer.Verify();
    end;

    [Test]
    procedure Theme_FontScheme()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Theme", Body);
        VersusPlain(Observer, Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2234');
#elif BC29PLUS
        Observer.Expect('chars', '2233');
#else
        Observer.Expect('chars', '2234');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', 'DC21E402F29C48FE2155A4276451F041AD12CCFDAA3353904C45331F99828C2C');
#elif BC29PLUS
        Observer.Expect('sha256', '3E7C625E9C244CE6EEEAA90467F7BF5C3E2BC9D8D101379C0966D803E671674F');
#else
        Observer.Expect('sha256', 'DC21E402F29C48FE2155A4276451F041AD12CCFDAA3353904C45331F99828C2C');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2233');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2232');
#else
        Observer.Expect('getbody chars', '2233');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', '7015F7B0305B2B8EBE6E67F2927CA30FE34EB9A1889C39106FBE9DA7D796356D');
#elif BC29PLUS
        Observer.Expect('getbody sha256', 'E6AE200CA82EF0AA39519044BED006417F9B8963A4E15C56928E0D6BA2EB1F38');
#else
        Observer.Expect('getbody sha256', '7015F7B0305B2B8EBE6E67F2927CA30FE34EB9A1889C39106FBE9DA7D796356D');
#endif
        Observer.Expect('title', 'RX Wd Theme');
        Observer.Expect('font-family', '[Verdana][Georgia]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|RX Wd Theme|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = plain sha256', 'No');
        Observer.Expect('chars - plain chars', '21');
        Observer.Verify();
    end;

    [Test]
    procedure Numbering_BulletList_NoTabs()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Numbering", Body);
        VersusPlain(Observer, Body);
        Observer.Observe('around LISTITEM', Around(Body, 'LISTITEM one', 120, 20));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '3139');
#elif BC29PLUS
        Observer.Expect('chars', '3138');
#else
        Observer.Expect('chars', '3139');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', 'FADA0FBA887D1240B58BCBBA2A1AC35697509312288067E6866ADF182837FAAF');
#elif BC29PLUS
        Observer.Expect('sha256', 'D32A79D5C5EBC5F307E76797A8FD075A3B4088DC877ADCB7838A50A239DBE9AC');
#else
        Observer.Expect('sha256', 'FADA0FBA887D1240B58BCBBA2A1AC35697509312288067E6866ADF182837FAAF');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '3138');
#elif BC29PLUS
        Observer.Expect('getbody chars', '3137');
#else
        Observer.Expect('getbody chars', '3138');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', '8718716F416C25C851BE567CAC7ACB169D06E2441A4E92C05EB7E4D5BB26EA28');
#elif BC29PLUS
        Observer.Expect('getbody sha256', '4020087487815CDC1D5AFE86FCD0CDCAD28339E565A8B4164C7B23BF192536C8');
#else
        Observer.Expect('getbody sha256', '8718716F416C25C851BE567CAC7ACB169D06E2441A4E92C05EB7E4D5BB26EA28');
#endif
        Observer.Expect('title', 'RX Wd Numbering');
        Observer.Expect('font-family', '[Calibri]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|RX Wd Numbering|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|•|&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0; |LISTITEM one|•|&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0; |LISTITEM two|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = plain sha256', 'No');
        Observer.Expect('chars - plain chars', '926');
        Observer.Expect('around LISTITEM', 'n''; display:inline-block; -aw-import:spaces">&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0;&#xa0; </span></span><span>LISTITEM one</span></p><p style=');
        Observer.Verify();
    end;

    [Test]
    procedure Header_FromSectPr()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Header", Body);
        VersusPlain(Observer, Body);
        Observer.Observe('has HEADERTEXT', Format(StrPos(Body, 'HEADERTEXT') > 0));
        Observer.Observe('around HEADERTEXT', Around(Body, 'HEADERTEXT', 80, 40));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2366');
#elif BC29PLUS
        Observer.Expect('chars', '2365');
#else
        Observer.Expect('chars', '2366');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', 'E71F717FB2C0CB44864D78B0A82A383F5F48175ACE2FC18992D068B624595F19');
#elif BC29PLUS
        Observer.Expect('sha256', 'B04B60B950E56F71CF6937AB70D997821A137CC5E33DA79F8E1FD669D8B5C44C');
#else
        Observer.Expect('sha256', 'E71F717FB2C0CB44864D78B0A82A383F5F48175ACE2FC18992D068B624595F19');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2365');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2364');
#else
        Observer.Expect('getbody chars', '2365');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', 'E590A5ED4AB0346ACB69B85D3059180B59A21DF955E15F489F2F7EE35150A506');
#elif BC29PLUS
        Observer.Expect('getbody sha256', 'DAEC1ED6F092AC2E203B7E7363770CE39F6D4E1F506913B0485185708050521A');
#else
        Observer.Expect('getbody sha256', 'E590A5ED4AB0346ACB69B85D3059180B59A21DF955E15F489F2F7EE35150A506');
#endif
        Observer.Expect('title', 'RX Wd Header');
        Observer.Expect('font-family', '[Calibri]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|RX Wd Header|HEADERTEXT page header|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = plain sha256', 'No');
        Observer.Expect('chars - plain chars', '153');
        Observer.Expect('has HEADERTEXT', 'Yes');
        Observer.Expect('around HEADERTEXT', ':header-primary; clear:both"><p style="margin-top:0pt; margin-bottom:8pt"><span>HEADERTEXT page header</span></p></div><p style="m');
        Observer.Verify();
    end;

    [Test]
    procedure Caption_RxCap_PlainBoundLayout()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Html.Rows(2);
        Cell(Observer, Report::"RX Wd Caption", Body);
        VersusPlain(Observer, Body);
        Observer.Observe('has Rx Cap', Format(StrPos(Body, 'Rx Cap') > 0));
        Observer.Observe('around Rx Cap', Around(Body, 'Rx Cap', 60, 40));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '2208');
#elif BC29PLUS
        Observer.Expect('chars', '2207');
#else
        Observer.Expect('chars', '2208');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', 'CA6C288729B989F0D8AFBF5EE149C2DAE7EEAE8AD794BAF43167442E30BFE5D9');
#elif BC29PLUS
        Observer.Expect('sha256', '08B2E7097961B225D2786B647D64E51A685231F37C1554A7CAAF518BD6C19CEC');
#else
        Observer.Expect('sha256', 'CA6C288729B989F0D8AFBF5EE149C2DAE7EEAE8AD794BAF43167442E30BFE5D9');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '2207');
#elif BC29PLUS
        Observer.Expect('getbody chars', '2206');
#else
        Observer.Expect('getbody chars', '2207');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', '496361EFE5C78ACC9A5E70F9A5CD1EB9DA846D94C32B9806EA2A381CE6D105C1');
#elif BC29PLUS
        Observer.Expect('getbody sha256', '74B8ABAAA3225FCCE90B453C6A5837C5DCD93753C1490044ED165A21E5B9ED26');
#else
        Observer.Expect('getbody sha256', '496361EFE5C78ACC9A5E70F9A5CD1EB9DA846D94C32B9806EA2A381CE6D105C1');
#endif
        Observer.Expect('title', 'Rx Cap');
        Observer.Expect('font-family', '[Calibri]');
        Observer.Expect('count RXROW', '2');
        Observer.Expect('text', '|Rx Cap|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|1|RXROW1|1,234.50|2/1/2026|2|RXROW2|2,469.00|2/1/2026|END|');
        Observer.Expect('sha256 = plain sha256', 'No');
        Observer.Expect('chars - plain chars', '-5');
        Observer.Expect('has Rx Cap', 'Yes');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('around Rx Cap', 'generator" content="Aspose.Words for .NET 26.10.0" /><title>Rx Cap</title></head><body style="line-height:');
#elif BC29PLUS
        Observer.Expect('around Rx Cap', '"generator" content="Aspose.Words for .NET 26.8.0" /><title>Rx Cap</title></head><body style="line-height:');
#else
        Observer.Expect('around Rx Cap', 'generator" content="Aspose.Words for .NET 26.10.0" /><title>Rx Cap</title></head><body style="line-height:');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure BlankZero_IntegerZero()
    var
        Observer: Codeunit "Probe Observer";
        Zero: Record "RX Zero Row";
        Body: Text;
    begin
        Zero.DeleteAll();
        Zero.Init();
        Zero.Id := 1;
        Zero.Txt := 'RXROW1';
        Zero.Qty := 0;
        Zero.QtyField := 0;
        Zero.Insert();
        Cell(Observer, Report::"RX Wd Blank Zero", Body);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('chars', '1246');
#elif BC29PLUS
        Observer.Expect('chars', '1245');
#else
        Observer.Expect('chars', '1246');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('sha256', 'DAC06CA9A1C8C016A63C3D93439EC6D240830317B0B0D6CB80B54EC27514CB43');
#elif BC29PLUS
        Observer.Expect('sha256', '5381DCC20B4EE01570FF4847535F35AA8A961CF051371C9D092731DE74AB1BCE');
#else
        Observer.Expect('sha256', 'DAC06CA9A1C8C016A63C3D93439EC6D240830317B0B0D6CB80B54EC27514CB43');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody chars', '1245');
#elif BC29PLUS
        Observer.Expect('getbody chars', '1244');
#else
        Observer.Expect('getbody chars', '1245');
#endif
#if BC29_1PLUS
        // version change: 29.1-aspose-words-version (29.1 renders with Aspose.Words 26.10.0 like 27.5 and 28.5; 29.0 had 26.8.0)
        Observer.Expect('getbody sha256', '8A2DDAF7252C167D6267A3AEE46605B4E84C752C5216F6EC077C175EECED113F');
#elif BC29PLUS
        Observer.Expect('getbody sha256', '5C738BEF80A1727409E0475A564FB648A88C1FEA6888E4A5B30E90EAB18CCEB1');
#else
        Observer.Expect('getbody sha256', '8A2DDAF7252C167D6267A3AEE46605B4E84C752C5216F6EC077C175EECED113F');
#endif
        Observer.Expect('title', 'RX Wd Blank Zero');
        Observer.Expect('font-family', '[Calibri]');
        Observer.Expect('count RXROW', '1');
        Observer.Expect('text', '|RX Wd Blank Zero|STATIC rgba(1,2,3,1) END|RUN rgba(4,5,6,0.5) END|RXROW1|0|0|END|');
        Observer.Verify();
    end;










}
