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
// Observed on the CI builds BC 27.5, 28.5 and 29.0: the converter writes its version into the Html, so hashes differ per Aspose version.
// local object: the reports' own layouts and their dataset tables are what the tests check.
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

    // One chunk of the Html, to read what the converter wrote (observation only).
    local procedure Chunk(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Part: Integer)
    var
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(2);
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe('html ' + Format(Part), CopyStr(Body, (Part - 1) * 1500 + 1, 1500));
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Styles_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Styles", 1);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Styles_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Styles", 2);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Theme_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Theme", 1);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Theme_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Theme", 2);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Numbering_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Numbering", 1);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Numbering_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Numbering", 2);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Header_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Header", 1);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Header_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Header", 2);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Caption_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Caption", 1);
        Observer.Finish();
    end;

    [Test]
    procedure Dump_Caption_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunk(Observer, Report::"RX Wd Caption", 2);
        Observer.Finish();
    end;
}
