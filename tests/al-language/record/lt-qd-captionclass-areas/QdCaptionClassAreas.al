// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 86500, pages 86501 and 86502, log codeunit 86503 (used only by test codeunit 86504),
//   test codeunit 86504; Base Application's Sales Header / Sales Line and its OnResolveCaptionClass subscribers (areas 1, 2, 5, 101).
//   LT QK Setup Rows (86940) writes the General Ledger Setup / Dimension rows of Literals_FieldCaption and Expressions_FieldCaption.
// Probe: writer QD, for the al-runtime-rs refusal "a CaptionClass expression result with another area" (the top Tests-ERM refusal) and the
//   assumption field-caption-class-expression-per-read. Observed values; every literal asserted below is what the BC tier produced.
// Facts: the caption FieldCaption, FieldRef.Caption and a TestPage control give for a table field whose CaptionClass is a literal or an
//   expression with area 2 ('2,0,x', '2,1,x', VAT), 5 ('5,3,', County), 101 (Currency), 1 (Dimension), an area no subscriber resolves, an
//   empty text and '3,'; how often the expression runs per read and with which record; Sales Line "Inv. Discount Amount".
// Results:
//   - An expression result goes through the same resolvers as a literal: '2,0,x' -> 'x Excl. VAT', '2,1,x' -> 'x Incl. VAT', '5,3,' ->
//     'Bill-to County', '101,0,Amount (%1)' -> the LCY code, '1,1,1' -> the global dimension 1 caption. An area nobody resolves ('9,x') and
//     '2,x' (VAT without a second comma) read as the whole CaptionClass text.
//   - An empty result and '3,' read as the field's Caption in FieldCaption and FieldRef.Caption, but as '' on a page control.
//   - FieldCaption and FieldRef.Caption run the expression once per read, with the record that reads it (its current values, Id 0 for a
//     RecordRef.Open); what the expression changes on Rec (a field, a table global) stays changed. FieldName does not run it.
//   - A page open runs the expression of EVERY CaptionClass expression field of the table, also those without a control, 20 times with an
//     empty record, then once for each field with a control on the current row; Caption() of a control reads the value of the open
//     and runs nothing. A page control's own CaptionClass expression resolves the same way.
//   - Sales Line "Inv. Discount Amount" / "Line Amount": Excl. VAT without a Sales Header, Incl. VAT when the header has Prices Including VAT.
// Writer QF: own table 86643, pages 86640 (List), 86641 (ListPart) and 86642 (Card hosting the part); tests QF_* in 86504 (still the only
//   user of log 86503). Results: a List page opened with OpenView or OpenEdit runs every expression field of the table 9 times with an empty
//   record (108 calls), Page.Run of the List (trapped) 111 calls, a Card hosting the ListPart 108 (counts seen on every major, but not
//   asserted: the same card open counted 240 and 492 in two BC 29 runs); then once per expression control on the first row only. Next (List, ListPart and Card) runs no expression, and Caption() after Next still reads the value of the open (first row).
//   The corpus database's General Ledger Setup: LCY Code GBP, Global Dimension 1 DEPARTMENT ('Department Code'), Global Dimension 2
//   CUSTOMERGROUP ('Customergroup Code'), Additional Reporting Currency EUR from BC 28 ('' on BC 27.5).
// Writer QO (al-runtime-rs assumptions page-open-caption-class-expressions and page-open-caption-class-empty-record-count): own tables
//   87090 (document header, expression field 60 logs its Seq) and 87091 (lines, expression fields 70 and 71 log their Line No.), a Document
//   page 87092 with the ListPart 87093 (SubPageLink "Doc No." = field("No.")); QO_ tests in 86504. Which expressions run, and with which
//   row, on OpenEdit and OpenNew of the Document page, on OpenEdit of the QD card, and after a part SetValue, a part Next, a host SetValue,
//   an action with CurrPage.Update() and a host Next that refills the part. The empty-record counts of repeated opens are observed to find
//   a stable form.
// Writer SF (al-runtime-rs assumptions page-open-caption-class-empty-record-count and page-open-caption-class-expressions): SF_ tests
//   in 86504 (repeated opens counted, CurrPage.Update on the Document page without a SetValue, an action without CurrPage.Update,
//   OpenNew of the Card and the List) and the action NoUpdate of page 87092.
//   Facts (corpus CI 27.5, 28.5, 29.0, two runs): on the Document page an action with CurrPage.Update() and no SetValue before it runs the
//   host's expression twice, then the part's once; an action WITHOUT CurrPage.Update runs the same (host twice, part once), and after a
//   host SetValue it runs the host's three times and the part's once, as with CurrPage.Update. After a part SetValue, the host's action
//   runs the part's first, then the host's twice, then the part's again. OpenNew of the Card and the List runs empty-record calls whose
//   count differs between fields, and no call with a row. Five opens of the same page in one test count the same.
// BC versions: 27, 28, 29

table 86500 "LT QD Cap Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Incl VAT"; Boolean) { }
        field(3; Tag; Text[30]) { }
        field(10; "Lit 2-0"; Decimal) { Caption = 'Cap Lit 2-0'; CaptionClass = '2,0,Inv. Discount Amount'; }
        field(11; "Lit 2-1"; Decimal) { Caption = 'Cap Lit 2-1'; CaptionClass = '2,1,Inv. Discount Amount'; }
        field(12; "Lit 5-3"; Text[30]) { Caption = 'Cap Lit 5-3'; CaptionClass = '5,3,'; }
        field(13; "Lit 5-3 Code"; Text[30]) { Caption = 'Cap Lit 5-3 Code'; CaptionClass = '5,3,QDX'; }
        field(14; "Lit 101-0"; Decimal) { Caption = 'Cap Lit 101-0'; CaptionClass = '101,0,Amount (%1)'; }
        field(15; "Lit 1-1"; Code[20]) { Caption = 'Cap Lit 1-1'; CaptionClass = '1,1,1'; }
        field(20; "Expr 2-0"; Decimal) { Caption = 'Cap Expr 2-0'; CaptionClass = QdCc(20); }
        field(21; "Expr 2-1"; Decimal) { Caption = 'Cap Expr 2-1'; CaptionClass = QdCc(21); }
        field(22; "Expr 5-3"; Text[30]) { Caption = 'Cap Expr 5-3'; CaptionClass = QdCc(22); }
        field(23; "Expr VAT"; Decimal) { Caption = 'Cap Expr VAT'; CaptionClass = QdCc(23); }
        field(24; "Expr Id"; Integer) { Caption = 'Cap Expr Id'; CaptionClass = QdCc(24); }
        field(25; "Expr Empty"; Integer) { Caption = 'Cap Expr Empty'; CaptionClass = QdCc(25); }
        field(26; "Expr 9"; Integer) { Caption = 'Cap Expr 9'; CaptionClass = QdCc(26); }
        field(27; "Expr 2-x"; Integer) { Caption = 'Cap Expr 2-x'; CaptionClass = QdCc(27); }
        field(28; "Expr 3-"; Integer) { Caption = 'Cap Expr 3-'; CaptionClass = QdCc(28); }
        field(29; "Expr 101"; Decimal) { Caption = 'Cap Expr 101'; CaptionClass = QdCc(29); }
        field(30; "Expr 1-1"; Code[20]) { Caption = 'Cap Expr 1-1'; CaptionClass = QdCc(30); }
        field(31; "Expr Touch"; Integer) { Caption = 'Cap Expr Touch'; CaptionClass = QdCc(31); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Touched: Integer;

    procedure QdCc(FieldNumber: Integer): Text[80]
    var
        Log: Codeunit "LT QD Cap Log";
    begin
        Log.Hit(FieldNumber, Id);
        case FieldNumber of
            20:
                exit('2,0,Inv. Discount Amount');
            21:
                exit('2,1,Inv. Discount Amount');
            22:
                exit('5,3,');
            23:
                exit('2,' + Format("Incl VAT", 0, 2) + ',Inv. Discount Amount');
            24:
                exit('3,Id ' + Format(Id) + ' call ' + Format(Log.Total()));
            25:
                exit('');
            26:
                exit('9,x');
            27:
                exit('2,x');
            28:
                exit('3,');
            29:
                exit('101,0,Amount (%1)');
            30:
                exit('1,1,1');
            31:
                begin
                    Touched += 1;
                    Tag := 'touched ' + Format(Touched);
                    exit('3,Touch ' + Format(Touched));
                end;
        end;
    end;

    procedure TouchedCount(): Integer
    begin
        exit(Touched);
    end;
}

page 86501 "LT QD Cap Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QD Cap Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Lit20; Rec."Lit 2-0") { ApplicationArea = All; }
                field(Lit21; Rec."Lit 2-1") { ApplicationArea = All; }
                field(Lit53; Rec."Lit 5-3") { ApplicationArea = All; }
                field(Expr20; Rec."Expr 2-0") { ApplicationArea = All; }
                field(Expr21; Rec."Expr 2-1") { ApplicationArea = All; }
                field(Expr53; Rec."Expr 5-3") { ApplicationArea = All; }
                field(ExprVAT; Rec."Expr VAT") { ApplicationArea = All; }
                field(ExprId; Rec."Expr Id") { ApplicationArea = All; }
                field(ExprEmpty; Rec."Expr Empty") { ApplicationArea = All; }
                field(Expr9; Rec."Expr 9") { ApplicationArea = All; }
                field(Expr2x; Rec."Expr 2-x") { ApplicationArea = All; }
                field(Expr3; Rec."Expr 3-") { ApplicationArea = All; }
                field(PageExpr; Rec.Tag) { ApplicationArea = All; Caption = 'Cap Page Expr'; CaptionClass = PageCc(); }
            }
        }
    }

    local procedure PageCc(): Text
    begin
        exit('2,1,Page Control');
    end;
}

page 86502 "LT QD Cap Sales Lines"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Sales Line";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(No; Rec."No.") { ApplicationArea = All; }
                field(InvDisc; Rec."Inv. Discount Amount") { ApplicationArea = All; }
                field(LineAmount; Rec."Line Amount") { ApplicationArea = All; }
            }
        }
    }
}

table 87090 "LT QO Cap Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Seq; Integer) { }
        field(3; Descr; Text[30]) { }
        field(60; "Head Expr"; Decimal) { Caption = 'Cap Head Expr'; CaptionClass = QoHc(); }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    procedure QoHc(): Text[80]
    var
        Log: Codeunit "LT QD Cap Log";
    begin
        Log.Hit(60, Seq);
        exit('3,Head ' + Format(Seq));
    end;
}

table 87091 "LT QO Cap Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(70; "Expr A"; Decimal) { Caption = 'Cap Expr A'; CaptionClass = QoLc(70); }
        field(71; "Expr B"; Decimal) { Caption = 'Cap Expr B'; CaptionClass = QoLc(71); }
    }

    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }

    procedure QoLc(FieldNumber: Integer): Text[80]
    var
        Log: Codeunit "LT QD Cap Log";
    begin
        Log.Hit(FieldNumber, "Line No.");
        if FieldNumber = 70 then
            exit('3,Line ' + Format("Line No."));
        exit('2,0,Amount');
    end;
}

codeunit 86503 "LT QD Cap Log"
{
    SingleInstance = true;

    var
        Calls: Text;
        Count: Integer;

    procedure Hit(FieldNumber: Integer; RecId: Integer)
    begin
        Count += 1;
        Calls += Format(FieldNumber) + '@' + Format(RecId) + ';';
    end;

    procedure Total(): Integer
    begin
        exit(Count);
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    procedure Reset()
    begin
        Calls := '';
        Count := 0;
    end;
}

codeunit 86504 "LT QD CaptionClass Areas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QD Cap Log";

    local procedure Cap(var Observer: Codeunit "Probe Observer"; Name: Text; Caption: Text)
    begin
        Observer.Observe(Name, Caption);
        Observer.Observe(Name + '_calls', Log.Take());
    end;

    // The calls of a page open, folded: how many ran with an empty record (Id 0) and for which fields, then the other calls in order.
    local procedure Summarize(Calls: Text): Text
    var
        Part: Text;
        FieldText: Text;
        Fields0: List of [Text];
        Fields0Text: Text;
        Id0: Integer;
        Rest: Text;
    begin
        foreach Part in Calls.Split(';') do
            if Part <> '' then
                if Part.EndsWith('@0') then begin
                    Id0 += 1;
                    FieldText := Part.Substring(1, Part.IndexOf('@') - 1);
                    if not Fields0.Contains(FieldText) then
                        Fields0.Add(FieldText);
                end else
                    Rest += Part + ';';
        foreach FieldText in Fields0 do
            Fields0Text += FieldText + ',';
        exit('id0=' + Format(Id0) + ' fields0=' + Fields0Text + ' rest=' + Rest);
    end;

    [Test]
    procedure Literals_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        // Writer QK (owner 2026-10-21): areas 101 and 1 read General Ledger Setup and the Dimension row the test writes (QkSetupRows.al):
        // LCY Code 'GBP', Global Dimension 1 'DEPARTMENT' with Code Caption 'Department Code' (kept at the demo values: the session keeps
        // resolved captions, see QkSetupRows.al).
        QkRows.WriteGLSetupCaptions();
        Log.Reset();
        R.Id := 1;
        Cap(Observer, 'lit20', R.FieldCaption("Lit 2-0"));
        Cap(Observer, 'lit21', R.FieldCaption("Lit 2-1"));
        Cap(Observer, 'lit53', R.FieldCaption("Lit 5-3"));
        Cap(Observer, 'lit53code', R.FieldCaption("Lit 5-3 Code"));
        Cap(Observer, 'lit101', R.FieldCaption("Lit 101-0"));
        Cap(Observer, 'lit11', R.FieldCaption("Lit 1-1"));
        QkRows.RestoreGLSetupCaptions();
        Observer.Expect('lit20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('lit20_calls', '');
        Observer.Expect('lit21', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('lit21_calls', '');
        Observer.Expect('lit53', 'Bill-to County');
        Observer.Expect('lit53_calls', '');
        Observer.Expect('lit53code', '5,3,QDX');
        Observer.Expect('lit53code_calls', '');
        Observer.Expect('lit101', 'Amount (GBP)');
        Observer.Expect('lit101_calls', '');
        Observer.Expect('lit11', 'Department Code');
        Observer.Expect('lit11_calls', '');
        Observer.Verify();
    end;

    [Test]
    procedure Expressions_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        // Writer QK (owner 2026-10-21): areas 101 and 1 read General Ledger Setup and the Dimension row the test writes (QkSetupRows.al):
        // LCY Code 'GBP', Global Dimension 1 'DEPARTMENT' with Code Caption 'Department Code' (kept at the demo values: the session keeps
        // resolved captions, see QkSetupRows.al).
        QkRows.WriteGLSetupCaptions();
        Log.Reset();
        R.Id := 1;
        Cap(Observer, 'expr20', R.FieldCaption("Expr 2-0"));
        Cap(Observer, 'expr21', R.FieldCaption("Expr 2-1"));
        Cap(Observer, 'expr53', R.FieldCaption("Expr 5-3"));
        Cap(Observer, 'exprEmpty', R.FieldCaption("Expr Empty"));
        Cap(Observer, 'expr9', R.FieldCaption("Expr 9"));
        Cap(Observer, 'expr2x', R.FieldCaption("Expr 2-x"));
        Cap(Observer, 'expr3', R.FieldCaption("Expr 3-"));
        Cap(Observer, 'expr101', R.FieldCaption("Expr 101"));
        Cap(Observer, 'expr11', R.FieldCaption("Expr 1-1"));
        QkRows.RestoreGLSetupCaptions();
        Observer.Expect('expr20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('expr20_calls', '20@1;');
        Observer.Expect('expr21', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('expr21_calls', '21@1;');
        Observer.Expect('expr53', 'Bill-to County');
        Observer.Expect('expr53_calls', '22@1;');
        Observer.Expect('exprEmpty', 'Cap Expr Empty');
        Observer.Expect('exprEmpty_calls', '25@1;');
        Observer.Expect('expr9', '9,x');
        Observer.Expect('expr9_calls', '26@1;');
        Observer.Expect('expr2x', '2,x');
        Observer.Expect('expr2x_calls', '27@1;');
        Observer.Expect('expr3', 'Cap Expr 3-');
        Observer.Expect('expr3_calls', '28@1;');
        Observer.Expect('expr101', 'Amount (GBP)');
        Observer.Expect('expr101_calls', '29@1;');
        Observer.Expect('expr11', 'Department Code');
        Observer.Expect('expr11_calls', '30@1;');
        Observer.Verify();
    end;

    [Test]
    procedure Expression_VatSwitch_SameRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        R."Incl VAT" := false;
        Cap(Observer, 'excl', R.FieldCaption("Expr VAT"));
        R."Incl VAT" := true;
        Cap(Observer, 'incl', R.FieldCaption("Expr VAT"));
        R."Incl VAT" := false;
        Cap(Observer, 'excl_again', R.FieldCaption("Expr VAT"));
        Observer.Expect('excl', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('excl_calls', '23@1;');
        Observer.Expect('incl', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('incl_calls', '23@1;');
        Observer.Expect('excl_again', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('excl_again_calls', '23@1;');
        Observer.Verify();
    end;

    [Test]
    procedure Expression_PerRead_CallCount()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        R2: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        R2.Id := 2;
        Cap(Observer, 'r1_first', R.FieldCaption("Expr Id"));
        Cap(Observer, 'r1_second', R.FieldCaption("Expr Id"));
        Cap(Observer, 'r2', R2.FieldCaption("Expr Id"));
        Cap(Observer, 'r1_fieldname', R.FieldName("Expr Id"));
        Observer.Observe('total', Format(Log.Total()));
        Observer.Expect('r1_first', 'Id 1 call 1');
        Observer.Expect('r1_first_calls', '24@1;');
        Observer.Expect('r1_second', 'Id 1 call 2');
        Observer.Expect('r1_second_calls', '24@1;');
        Observer.Expect('r2', 'Id 2 call 3');
        Observer.Expect('r2_calls', '24@2;');
        Observer.Expect('r1_fieldname', 'Expr Id');
        Observer.Expect('r1_fieldname_calls', '');
        Observer.Expect('total', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Expression_ChangesRec()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 4;
        R.Tag := 'before';
        Cap(Observer, 'first', R.FieldCaption("Expr Touch"));
        Observer.Observe('tag_after_first', R.Tag);
        Observer.Observe('touched_after_first', Format(R.TouchedCount()));
        Cap(Observer, 'second', R.FieldCaption("Expr Touch"));
        Observer.Observe('tag_after_second', R.Tag);
        Observer.Observe('touched_after_second', Format(R.TouchedCount()));
        Observer.Expect('first', 'Touch 1');
        Observer.Expect('first_calls', '31@4;');
        Observer.Expect('tag_after_first', 'touched 1');
        Observer.Expect('touched_after_first', '1');
        Observer.Expect('second', 'Touch 2');
        Observer.Expect('second_calls', '31@4;');
        Observer.Expect('tag_after_second', 'touched 2');
        Observer.Expect('touched_after_second', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Expressions_FieldRefCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        Ref: RecordRef;
        Fresh: RecordRef;
    begin
        Log.Reset();
        R.Id := 7;
        R."Incl VAT" := true;
        Ref.GetTable(R);
        Cap(Observer, 'ref_expr20', Ref.Field(20).Caption());
        Cap(Observer, 'ref_expr21', Ref.Field(21).Caption());
        Cap(Observer, 'ref_expr53', Ref.Field(22).Caption());
        Cap(Observer, 'ref_exprVAT', Ref.Field(23).Caption());
        Cap(Observer, 'ref_exprId', Ref.Field(24).Caption());
        Cap(Observer, 'ref_exprEmpty', Ref.Field(25).Caption());
        Cap(Observer, 'ref_lit20', Ref.Field(10).Caption());
        Cap(Observer, 'ref_lit53', Ref.Field(12).Caption());
        Fresh.Open(Database::"LT QD Cap Row");
        Cap(Observer, 'fresh_exprId', Fresh.Field(24).Caption());
        Cap(Observer, 'fresh_exprVAT', Fresh.Field(23).Caption());
        Observer.Expect('ref_expr20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('ref_expr20_calls', '20@7;');
        Observer.Expect('ref_expr21', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('ref_expr21_calls', '21@7;');
        Observer.Expect('ref_expr53', 'Bill-to County');
        Observer.Expect('ref_expr53_calls', '22@7;');
        Observer.Expect('ref_exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('ref_exprVAT_calls', '23@7;');
        Observer.Expect('ref_exprId', 'Id 7 call 5');
        Observer.Expect('ref_exprId_calls', '24@7;');
        Observer.Expect('ref_exprEmpty', 'Cap Expr Empty');
        Observer.Expect('ref_exprEmpty_calls', '25@7;');
        Observer.Expect('ref_lit20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('ref_lit20_calls', '');
        Observer.Expect('ref_lit53', 'Bill-to County');
        Observer.Expect('ref_lit53_calls', '');
        Observer.Expect('fresh_exprId', 'Id 0 call 7');
        Observer.Expect('fresh_exprId_calls', '24@0;');
        Observer.Expect('fresh_exprVAT', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('fresh_exprVAT_calls', '23@0;');
        Observer.Verify();
    end;

    [Test]
    procedure Page_ControlCaptions()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        R.DeleteAll();
        R.Id := 3;
        R."Incl VAT" := true;
        R.Insert();
        Log.Reset();
        P.OpenView();
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'lit20', P.Lit20.Caption());
        Cap(Observer, 'lit21', P.Lit21.Caption());
        Cap(Observer, 'lit53', P.Lit53.Caption());
        Cap(Observer, 'expr20', P.Expr20.Caption());
        Cap(Observer, 'expr21', P.Expr21.Caption());
        Cap(Observer, 'expr53', P.Expr53.Caption());
        Cap(Observer, 'exprVAT', P.ExprVAT.Caption());
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'exprId_again', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'exprEmpty', P.ExprEmpty.Caption());
        Cap(Observer, 'expr9', P.Expr9.Caption());
        Cap(Observer, 'expr2x', P.Expr2x.Caption());
        Cap(Observer, 'expr3', P.Expr3.Caption());
        Cap(Observer, 'pageExpr', P.PageExpr.Caption());
        P.Close();
        Observer.Observe('close_calls', Summarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('lit20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('lit20_calls', '');
        Observer.Expect('lit21', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('lit21_calls', '');
        Observer.Expect('lit53', 'Bill-to County');
        Observer.Expect('lit53_calls', '');
        Observer.Expect('expr20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('expr20_calls', '');
        Observer.Expect('expr21', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('expr21_calls', '');
        Observer.Expect('expr53', 'Bill-to County');
        Observer.Expect('expr53_calls', '');
        Observer.Expect('exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('exprVAT_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('exprId_again', 'Id 3');
        Observer.Expect('exprId_again_calls', '');
        Observer.Expect('exprEmpty', '');
        Observer.Expect('exprEmpty_calls', '');
        Observer.Expect('expr9', '9,x');
        Observer.Expect('expr9_calls', '');
        Observer.Expect('expr2x', '2,x');
        Observer.Expect('expr2x_calls', '');
        Observer.Expect('expr3', '');
        Observer.Expect('expr3_calls', '');
        Observer.Expect('pageExpr', 'Page Control Incl. VAT');
        Observer.Expect('pageExpr_calls', '');
        Observer.Expect('close_calls', 'id0=0 fields0= rest=');
        Observer.Verify();
    end;

    [Test]
    procedure SalesLine_InvDiscountAmount_NoHeader()
    var
        Observer: Codeunit "Probe Observer";
        SalesLine: Record "Sales Line";
        Ref: RecordRef;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'QD-NOHEADER';
        Observer.Observe('invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Observe('lineamount', SalesLine.FieldCaption("Line Amount"));
        Observer.Observe('no', SalesLine.FieldCaption("No."));
        Ref.GetTable(SalesLine);
        Observer.Observe('ref_invdisc', Ref.Field(SalesLine.FieldNo("Inv. Discount Amount")).Caption());
        Observer.Expect('invdisc', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('lineamount', 'Line Amount Excl. VAT');
        Observer.Expect('no', 'No.');
        Observer.Expect('ref_invdisc', 'Inv. Discount Amount Excl. VAT');
        Observer.Verify();
    end;

    [Test]
    procedure SalesLine_InvDiscountAmount_PricesInclVat()
    var
        Observer: Codeunit "Probe Observer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Ref: RecordRef;
        P: TestPage "LT QD Cap Sales Lines";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := 'QD-INCLVAT';
        SalesHeader."Prices Including VAT" := true;
        SalesHeader.Insert(false);
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'QD-INCLVAT';
        SalesLine."Line No." := 10000;
        SalesLine.Insert(false);
        Observer.Observe('invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Observe('lineamount', SalesLine.FieldCaption("Line Amount"));
        Observer.Observe('no', SalesLine.FieldCaption("No."));
        Ref.GetTable(SalesLine);
        Observer.Observe('ref_invdisc', Ref.Field(SalesLine.FieldNo("Inv. Discount Amount")).Caption());
        P.OpenView();
        P.Filter.SetFilter("Document No.", 'QD-INCLVAT');
        P.First();
        Observer.Observe('page_invdisc', P.InvDisc.Caption());
        Observer.Observe('page_lineamount', P.LineAmount.Caption());
        Observer.Observe('page_no', P.No.Caption());
        P.Close();
        SalesLine."Document No." := 'QD-OTHER';
        Observer.Observe('other_doc_invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Expect('invdisc', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('lineamount', 'Line Amount Incl. VAT');
        Observer.Expect('no', 'No.');
        Observer.Expect('ref_invdisc', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('page_invdisc', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('page_lineamount', 'Line Amount Incl. VAT');
        Observer.Expect('page_no', 'No.');
        Observer.Expect('other_doc_invdisc', 'Inv. Discount Amount Excl. VAT');
        Observer.Verify();
    end;

    // Writer QF (al-runtime-rs assumption page-open-caption-class-expressions): the card log above on a List page opened with OpenView,
    // OpenEdit and Page.Run, on a ListPart of a card, and after Next on the list and on the card. Two rows: Id 3 (Incl VAT) and Id 5.
    local procedure QfSeedTwo()
    var
        R: Record "LT QD Cap Row";
    begin
        R.DeleteAll();
        R.Id := 3;
        R."Incl VAT" := true;
        R.Insert();
        R.Id := 5;
        R."Incl VAT" := false;
        R.Insert();
        Log.Reset();
    end;

    // The empty-record calls of a page open are counted differently between runs (Page_ControlCaptions saw 240 and 492 on BC 29 CI): only
    // whether there were any is asserted; the counts seen are in the header. QfNoCall cuts the running call count off the "Expr Id" caption.
    local procedure QfSummarize(Calls: Text): Text
    var
        Folded: Text;
        At: Integer;
    begin
        Folded := Summarize(Calls);
        At := Folded.IndexOf(' fields0=');
        exit('id0>0=' + Format(CopyStr(Folded, 5, At - 5) <> '0') + CopyStr(Folded, At));
    end;

    local procedure QfNoCall(Caption: Text): Text
    begin
        if Caption.IndexOf(' call ') = 0 then
            exit(Caption);
        exit(CopyStr(Caption, 1, Caption.IndexOf(' call ') - 1));
    end;

    [Test]
    procedure QF_List_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
    begin
        QfSeedTwo();
        P.OpenView();
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'row', P.Id.Value());
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'exprVAT', P.ExprVAT.Caption());
        Cap(Observer, 'expr20', P.Expr20.Caption());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'next_row', P.Id.Value());
        Cap(Observer, 'next_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'next_exprVAT', P.ExprVAT.Caption());
        P.Close();
        Observer.Observe('close_calls', QfSummarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=20@3;23@3;24@3;');
        Observer.Expect('row', '3');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('exprVAT_calls', '');
        Observer.Expect('expr20', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('expr20_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_calls', 'id0>0=No fields0= rest=');
        Observer.Expect('next_row', '5');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('next_exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('next_exprVAT_calls', '');
        Observer.Expect('close_calls', 'id0>0=No fields0= rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QF_List_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
    begin
        QfSeedTwo();
        P.OpenEdit();
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'row', P.Id.Value());
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'exprVAT', P.ExprVAT.Caption());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'next_row', P.Id.Value());
        Cap(Observer, 'next_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'next_exprVAT', P.ExprVAT.Caption());
        P.Close();
        Observer.Observe('close_calls', QfSummarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=20@3;23@3;24@3;');
        Observer.Expect('row', '3');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('exprVAT_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_calls', 'id0>0=No fields0= rest=');
        Observer.Expect('next_row', '5');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('next_exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('next_exprVAT_calls', '');
        Observer.Expect('close_calls', 'id0>0=No fields0= rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QF_List_PageRun()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
    begin
        QfSeedTwo();
        P.Trap();
        Page.Run(Page::"LT QF Cap List");
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'row', P.Id.Value());
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'exprVAT', P.ExprVAT.Caption());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'next_row', P.Id.Value());
        Cap(Observer, 'next_exprId', QfNoCall(P.ExprId.Caption()));
        P.Close();
        Observer.Observe('close_calls', QfSummarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=20@3;23@3;24@3;');
        Observer.Expect('row', '3');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('exprVAT_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_calls', 'id0>0=No fields0= rest=');
        Observer.Expect('next_row', '5');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('close_calls', 'id0>0=No fields0= rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QF_ListPart_OnCard()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT QF Cap Host Row";
        H: TestPage "LT QF Cap Host";
    begin
        Host.DeleteAll();
        Host.Id := 1;
        Host.Insert();
        QfSeedTwo();
        H.OpenView();
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'row', H.Lines.Id.Value());
        Cap(Observer, 'exprId', QfNoCall(H.Lines.ExprId.Caption()));
        Cap(Observer, 'exprVAT', H.Lines.ExprVAT.Caption());
        Observer.Observe('next', Format(H.Lines.Next()));
        Observer.Observe('next_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'next_row', H.Lines.Id.Value());
        Cap(Observer, 'next_exprId', QfNoCall(H.Lines.ExprId.Caption()));
        Cap(Observer, 'next_exprVAT', H.Lines.ExprVAT.Caption());
        H.Close();
        Observer.Observe('close_calls', QfSummarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=23@3;24@3;');
        Observer.Expect('row', '3');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('exprVAT_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_calls', 'id0>0=No fields0= rest=');
        Observer.Expect('next_row', '5');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('next_exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('next_exprVAT_calls', '');
        Observer.Expect('close_calls', 'id0>0=No fields0= rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QF_Card_Next()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
    begin
        QfSeedTwo();
        P.OpenView();
        Observer.Observe('open_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'row', P.Id.Value());
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_calls', QfSummarize(Log.Take()));
        Cap(Observer, 'next_row', P.Id.Value());
        Cap(Observer, 'next_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'next_exprVAT', P.ExprVAT.Caption());
        P.Close();
        Observer.Observe('close_calls', QfSummarize(Log.Take()));
        Observer.Expect('open_calls', 'id0>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('row', '3');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_calls', 'id0>0=No fields0= rest=');
        Observer.Expect('next_row', '5');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('next_exprVAT', 'Inv. Discount Amount Incl. VAT');
        Observer.Expect('next_exprVAT_calls', '');
        Observer.Expect('close_calls', 'id0>0=No fields0= rest=');
        Observer.Verify();
    end;

    // Writer QF: the General Ledger Setup row and the global dimension captions of the corpus database, which Base Application's
    // OnResolveCaptionClass reads for areas 101 (currency) and 1 (dimension) above.
    [Test]
    procedure QF_GLSetup_CorpusRow()
    var
        Observer: Codeunit "Probe Observer";
        GLSetup: Record "General Ledger Setup";
        Dim: Record Dimension;
    begin
        Observer.Observe('count', Format(GLSetup.Count()));
        Observer.Observe('get', Format(GLSetup.Get()));
        Observer.Observe('primaryKey', GLSetup."Primary Key");
        Observer.Observe('lcyCode', GLSetup."LCY Code");
        Observer.Observe('globalDim1', GLSetup."Global Dimension 1 Code");
        Observer.Observe('globalDim2', GLSetup."Global Dimension 2 Code");
        Observer.Observe('addReportingCurrency', GLSetup."Additional Reporting Currency");
        Observer.Observe('dim1_get', Format(Dim.Get(GLSetup."Global Dimension 1 Code")));
        Observer.Observe('dim1_codeCaption', Dim."Code Caption");
        Observer.Observe('dim2_get', Format(Dim.Get(GLSetup."Global Dimension 2 Code")));
        Observer.Observe('dim2_codeCaption', Dim."Code Caption");
        Observer.Expect('count', '1');
        Observer.Expect('get', 'Yes');
        Observer.Expect('primaryKey', '');
        Observer.Expect('lcyCode', 'GBP');
        Observer.Expect('globalDim1', 'DEPARTMENT');
        Observer.Expect('globalDim2', 'CUSTOMERGROUP');
#if BC28PLUS
        Observer.Expect('addReportingCurrency', 'EUR');
#else
        Observer.Expect('addReportingCurrency', '');
#endif
        Observer.Expect('dim1_get', 'Yes');
        Observer.Expect('dim1_codeCaption', 'Department Code');
        Observer.Expect('dim2_get', 'Yes');
        Observer.Expect('dim2_codeCaption', 'Customergroup Code');
        Observer.Verify();
    end;

    // Writer QO. The per-field count of empty-record calls is not asserted: it was 20 per card field and 10 per Document page field
    // in the QO runs, but other BC runs counted 240 and 492 for the same card open, so only the stable form below is an oracle.
    // The stable part: whether any empty-record call ran, every field that had one, each field the same number of times, and the rest.
    local procedure QoStable(Calls: Text): Text
    var
        Part: Text;
        FieldText: Text;
        Fields0: List of [Text];
        Counts0: Dictionary of [Text, Integer];
        FieldsText: Text;
        Rest: Text;
        First: Integer;
        Same: Boolean;
    begin
        foreach Part in Calls.Split(';') do
            if Part <> '' then
                if Part.EndsWith('@0') then begin
                    FieldText := Part.Substring(1, Part.IndexOf('@') - 1);
                    if not Fields0.Contains(FieldText) then begin
                        Fields0.Add(FieldText);
                        Counts0.Add(FieldText, 0);
                    end;
                    Counts0.Set(FieldText, Counts0.Get(FieldText) + 1);
                end else
                    Rest += Part + ';';
        Same := true;
        foreach FieldText in Fields0 do begin
            FieldsText += FieldText + ',';
            if First = 0 then
                First := Counts0.Get(FieldText);
            if Counts0.Get(FieldText) <> First then
                Same := false;
        end;
        exit('empty>0=' + Format(Fields0.Count() > 0) + ' fields0=' + FieldsText + ' same=' + Format(Same) + ' rest=' + Rest);
    end;

    local procedure QoStep(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Calls: Text;
    begin
        Calls := Log.Take();
        Observer.Observe(Name, QoStable(Calls));
    end;

    local procedure QoSeedDocs()
    var
        D: Record "LT QO Cap Doc";
        L: Record "LT QO Cap Line";
    begin
        L.DeleteAll();
        D.DeleteAll();
        D."No." := 'D1';
        D.Seq := 1;
        D.Insert();
        D."No." := 'D2';
        D.Seq := 2;
        D.Insert();
        L."Doc No." := 'D1';
        L."Line No." := 1;
        L.Insert();
        L."Line No." := 2;
        L.Insert();
        L."Doc No." := 'D2';
        L."Line No." := 3;
        L.Insert();
        L."Line No." := 4;
        L.Insert();
        Log.Reset();
    end;

    [Test]
    procedure QO_Doc_OpenEdit_Open()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        QoStep(Observer, 'open');
        Cap(Observer, 'head', H.HeadExpr.Caption());
        Cap(Observer, 'row', H.Lines."Line No.".Value());
        Cap(Observer, 'exprA', H.Lines.ExprA.Caption());
        Cap(Observer, 'exprB', H.Lines.ExprB.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('open', 'empty>0=Yes fields0=60,70,71, same=Yes rest=60@1;70@1;71@1;');
        Observer.Expect('head', 'Head 1');
        Observer.Expect('head_calls', '');
        Observer.Expect('row', '1');
        Observer.Expect('row_calls', '');
        Observer.Expect('exprA', 'Line 1');
        Observer.Expect('exprA_calls', '');
        Observer.Expect('exprB', 'Amount Excl. VAT');
        Observer.Expect('exprB_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QO_Doc_OpenEdit_PartSteps()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.Lines.Amount.SetValue(5);
        QoStep(Observer, 'part_setvalue');
        Observer.Observe('part_next', Format(H.Lines.Next()));
        QoStep(Observer, 'part_next');
        Cap(Observer, 'next_row', H.Lines."Line No.".Value());
        Cap(Observer, 'next_exprA', H.Lines.ExprA.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('part_setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('part_next', 'Yes');
        Observer.Expect('part_next', 'empty>0=No fields0= same=Yes rest=70@1;71@1;');
        Observer.Expect('next_row', '2');
        Observer.Expect('next_row_calls', '');
        Observer.Expect('next_exprA', 'Line 1');
        Observer.Expect('next_exprA_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QO_Doc_OpenEdit_HostSteps()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.Descr.SetValue('x');
        QoStep(Observer, 'host_setvalue');
        H.Refresh.Invoke();
        QoStep(Observer, 'update');
        Cap(Observer, 'update_exprA', H.Lines.ExprA.Caption());
        Observer.Observe('host_next', Format(H.Next()));
        QoStep(Observer, 'host_next');
        Cap(Observer, 'host_next_head', H.HeadExpr.Caption());
        Cap(Observer, 'host_next_row', H.Lines."Line No.".Value());
        Cap(Observer, 'host_next_exprA', H.Lines.ExprA.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('host_setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('update', 'empty>0=No fields0= same=Yes rest=60@1;60@1;60@1;70@1;71@1;');
        Observer.Expect('update_exprA', 'Line 1');
        Observer.Expect('update_exprA_calls', '');
        Observer.Expect('host_next', 'Yes');
        Observer.Expect('host_next', 'empty>0=No fields0= same=Yes rest=70@3;71@3;');
        Observer.Expect('host_next_head', 'Head 1');
        Observer.Expect('host_next_head_calls', '');
        Observer.Expect('host_next_row', '3');
        Observer.Expect('host_next_row_calls', '');
        Observer.Expect('host_next_exprA', 'Line 3');
        Observer.Expect('host_next_exprA_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QO_Doc_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        // On OpenNew the counts differed between fields (11, 14, 14), so same= and the empty-record call list may vary: not asserted.
        Observer.Ignore('open');
        Observer.Ignore('exprA_calls');
        QoSeedDocs();
        H.OpenNew();
        QoStep(Observer, 'open');
        Cap(Observer, 'head', H.HeadExpr.Caption());
        Cap(Observer, 'exprA', H.Lines.ExprA.Caption());
        H."No.".SetValue('D9');
        QoStep(Observer, 'no_setvalue');
        Cap(Observer, 'no_row', H.Lines."Line No.".Value());
        Cap(Observer, 'no_exprA', H.Lines.ExprA.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('head', 'Head 0');
        Observer.Expect('head_calls', '');
        Observer.Expect('exprA', 'Line 0');
        Observer.Expect('no_setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('no_row', '0');
        Observer.Expect('no_row_calls', '');
        Observer.Expect('no_exprA', 'Line 0');
        Observer.Expect('no_exprA_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    [Test]
    procedure QO_Card_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
    begin
        QfSeedTwo();
        P.OpenEdit();
        QoStep(Observer, 'open');
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        P.Lit20.SetValue(5);
        QoStep(Observer, 'setvalue');
        Cap(Observer, 'setvalue_exprId', QfNoCall(P.ExprId.Caption()));
        Observer.Observe('next', Format(P.Next()));
        QoStep(Observer, 'next');
        Cap(Observer, 'next_exprId', QfNoCall(P.ExprId.Caption()));
        P.Close();
        QoStep(Observer, 'close');
        Observer.Expect('open', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=Yes rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('exprId', 'Id 3');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('setvalue_exprId', 'Id 3');
        Observer.Expect('setvalue_exprId_calls', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next', 'empty>0=No fields0= same=Yes rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('next_exprId', 'Id 3');
        Observer.Expect('next_exprId_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // The empty-record counts of the same open repeated in one test.
    [Test]
    procedure QO_Count_CardOpenThreeTimes()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
        Round: Integer;
    begin
        QfSeedTwo();
        for Round := 1 to 3 do begin
            P.OpenView();
            QoStep(Observer, 'open' + Format(Round));
            P.Close();
            Log.Take();
        end;
        Observer.Expect('open1', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=Yes rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('open2', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=Yes rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Expect('open3', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=Yes rest=20@3;21@3;22@3;23@3;24@3;25@3;26@3;27@3;28@3;');
        Observer.Verify();
    end;

    [Test]
    procedure QO_Count_DocOpenTwice()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
        Round: Integer;
    begin
        QoSeedDocs();
        for Round := 1 to 2 do begin
            H.OpenView();
            QoStep(Observer, 'open' + Format(Round));
            H.Close();
            Log.Take();
        end;
        Observer.Expect('open1', 'empty>0=Yes fields0=60,70,71, same=Yes rest=60@1;70@1;71@1;');
        Observer.Expect('open2', 'empty>0=Yes fields0=60,70,71, same=Yes rest=60@1;70@1;71@1;');
        Observer.Verify();
    end;

    // ---- writer SF (al-runtime-rs assumptions page-open-caption-class-empty-record-count and page-open-caption-class-expressions) ----

    // The empty-record calls of one step, counted: the total and the count of each field, in the order the fields first ran.
    local procedure SfCounts(Calls: Text): Text
    var
        Part: Text;
        FieldText: Text;
        Fields0: List of [Text];
        Counts0: Dictionary of [Text, Integer];
        Total: Integer;
        Result: Text;
    begin
        foreach Part in Calls.Split(';') do
            if Part.EndsWith('@0') then begin
                Total += 1;
                FieldText := Part.Substring(1, Part.IndexOf('@') - 1);
                if not Fields0.Contains(FieldText) then begin
                    Fields0.Add(FieldText);
                    Counts0.Add(FieldText, 0);
                end;
                Counts0.Set(FieldText, Counts0.Get(FieldText) + 1);
            end;
        foreach FieldText in Fields0 do
            Result += FieldText + ':' + Format(Counts0.Get(FieldText)) + ',';
        exit('total0=' + Format(Total) + ' per=' + Result);
    end;

    // Folds SfCounts of one open against the first open of the test: whether it made empty-record calls, whether every field ran the same
    // number of times, and whether the counts equal those of the first open.
    local procedure SfStable(Counts: Text; FirstCounts: Text): Text
    var
        Part: Text;
        PerText: Text;
        Count: Text;
        First: Text;
        Same: Boolean;
    begin
        PerText := CopyStr(Counts, Counts.IndexOf(' per=') + 5);
        Same := true;
        foreach Part in PerText.Split(',') do
            if Part <> '' then begin
                Count := CopyStr(Part, Part.IndexOf(':') + 1);
                if First = '' then
                    First := Count;
                if Count <> First then
                    Same := false;
            end;
        exit('empty>0=' + Format(PerText <> '') + ' same=' + Format(Same) + ' as_open1=' + Format(Counts = FirstCounts));
    end;

    // The same open five times in one test. The counts seen on the corpus CI (27.5, 28.5, 29.0, writer SF): every field 20 times for
    // the Card (240 calls), 9 times for the List (108), 10 times for the Document page (30); the same in all five opens. They are not
    // asserted: other runs counted 480 and 492 for the same Card open (QO_Count_CardOpenThreeTimes header), so only the stable form is.
    [Test]
    procedure SF_Count_CardOpenViewFiveTimes()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
        Round: Integer;
        Counts: Text;
        FirstCounts: Text;
    begin
        QfSeedTwo();
        for Round := 1 to 5 do begin
            P.OpenView();
            Counts := SfCounts(Log.Take());
            if Round = 1 then
                FirstCounts := Counts;
            Observer.Observe('open' + Format(Round), SfStable(Counts, FirstCounts));
            P.Close();
            Log.Take();
        end;
        Observer.Expect('open1', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open2', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open3', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open4', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open5', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Count_ListOpenViewFiveTimes()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
        Round: Integer;
        Counts: Text;
        FirstCounts: Text;
    begin
        QfSeedTwo();
        for Round := 1 to 5 do begin
            P.OpenView();
            Counts := SfCounts(Log.Take());
            if Round = 1 then
                FirstCounts := Counts;
            Observer.Observe('open' + Format(Round), SfStable(Counts, FirstCounts));
            P.Close();
            Log.Take();
        end;
        Observer.Expect('open1', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open2', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open3', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open4', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open5', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SF_Count_DocOpenEditFiveTimes()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
        Round: Integer;
        Counts: Text;
        FirstCounts: Text;
    begin
        QoSeedDocs();
        for Round := 1 to 5 do begin
            H.OpenEdit();
            Counts := SfCounts(Log.Take());
            if Round = 1 then
                FirstCounts := Counts;
            Observer.Observe('open' + Format(Round), SfStable(Counts, FirstCounts));
            H.Close();
            Log.Take();
        end;
        Observer.Expect('open1', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open2', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open3', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open4', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Expect('open5', 'empty>0=Yes same=Yes as_open1=Yes');
        Observer.Verify();
    end;

    // An action with CurrPage.Update() on the Document page without a SetValue before it, twice.
    [Test]
    procedure SF_Doc_OpenEdit_RefreshWithoutSetValue()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.Refresh.Invoke();
        QoStep(Observer, 'update1');
        Cap(Observer, 'update1_head', H.HeadExpr.Caption());
        Cap(Observer, 'update1_exprA', H.Lines.ExprA.Caption());
        H.Refresh.Invoke();
        QoStep(Observer, 'update2');
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('update1', 'empty>0=No fields0= same=Yes rest=60@1;60@1;70@1;71@1;');
        Observer.Expect('update1_head', 'Head 1');
        Observer.Expect('update1_head_calls', '');
        Observer.Expect('update1_exprA', 'Line 1');
        Observer.Expect('update1_exprA_calls', '');
        Observer.Expect('update2', 'empty>0=No fields0= same=Yes rest=60@1;60@1;70@1;71@1;');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // A host SetValue, then an action whose trigger has no CurrPage.Update, then an action with CurrPage.Update.
    [Test]
    procedure SF_Doc_OpenEdit_SetValueThenActionWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.Descr.SetValue('x');
        QoStep(Observer, 'host_setvalue');
        H.NoUpdate.Invoke();
        QoStep(Observer, 'action_no_update');
        Cap(Observer, 'action_exprA', H.Lines.ExprA.Caption());
        H.Refresh.Invoke();
        QoStep(Observer, 'update_after');
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('host_setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('action_no_update', 'empty>0=No fields0= same=Yes rest=60@1;60@1;60@1;70@1;71@1;');
        Observer.Expect('action_exprA', 'Line 1');
        Observer.Expect('action_exprA_calls', '');
        Observer.Expect('update_after', 'empty>0=No fields0= same=Yes rest=60@1;60@1;70@1;71@1;');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // An action without CurrPage.Update and no SetValue before it.
    [Test]
    procedure SF_Doc_OpenEdit_ActionWithoutUpdate()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.NoUpdate.Invoke();
        QoStep(Observer, 'action_no_update');
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('action_no_update', 'empty>0=No fields0= same=Yes rest=60@1;60@1;70@1;71@1;');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // A SetValue on the part, then the host's action with CurrPage.Update().
    [Test]
    procedure SF_Doc_OpenEdit_PartSetValueThenRefresh()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        Log.Take();
        H.Lines.Amount.SetValue(5);
        QoStep(Observer, 'part_setvalue');
        H.Refresh.Invoke();
        QoStep(Observer, 'update');
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('part_setvalue', 'empty>0=No fields0= same=Yes rest=');
        Observer.Expect('update', 'empty>0=No fields0= same=Yes rest=70@1;71@1;60@1;60@1;70@1;71@1;');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // The same action on a Document page opened with OpenView.
    [Test]
    procedure SF_Doc_OpenView_Refresh()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenView();
        QoStep(Observer, 'open');
        H.Refresh.Invoke();
        QoStep(Observer, 'update');
        H.Close();
        QoStep(Observer, 'close');
        Observer.Expect('open', 'empty>0=Yes fields0=60,70,71, same=Yes rest=60@1;70@1;71@1;');
        Observer.Expect('update', 'empty>0=No fields0= same=Yes rest=60@1;60@1;70@1;71@1;');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // Other open modes: OpenNew of the Card and of the List.
    [Test]
    procedure SF_Card_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
    begin
        QfSeedTwo();
        P.OpenNew();
        QoStep(Observer, 'open');
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        P.Close();
        QoStep(Observer, 'close');
        Observer.Expect('open', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=No rest=');
        Observer.Expect('exprId', 'Id 0');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    [Test]
    procedure SF_List_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
    begin
        QfSeedTwo();
        P.OpenNew();
        QoStep(Observer, 'open');
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        P.Close();
        QoStep(Observer, 'close');
        Observer.Expect('open', 'empty>0=Yes fields0=20,21,22,23,24,25,26,27,28,29,30,31, same=No rest=');
        Observer.Expect('exprId', 'Id 0');
        Observer.Expect('exprId_calls', '');
        Observer.Expect('close', 'empty>0=No fields0= same=Yes rest=');
        Observer.Verify();
    end;

    // Writer SI (al-runner issue 5858, assumption page-open-caption-class-expressions "other fills after the open"): GoToRecord, GoToKey,
    // First, Last and Previous on the QD card, the QF list, a Document page without a part (89150) and the QO Document page with its part.
    // Three rows: Id 1 and 2 with Incl VAT, Id 3 without, so the "Expr Id" and "Expr VAT" captions tell which row an expression ran with.
    local procedure SiSeedThree()
    var
        R: Record "LT QD Cap Row";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R.Id := i;
            R."Incl VAT" := i < 3;
            R.Insert();
        end;
        Log.Reset();
    end;

    local procedure SiCaps(var Observer: Codeunit "Probe Observer"; Prefix: Text; var P: TestPage "LT QD Cap Card")
    begin
        Cap(Observer, Prefix + 'row', P.Id.Value());
        Cap(Observer, Prefix + 'exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, Prefix + 'exprVAT', P.ExprVAT.Caption());
    end;

    [Test]
    procedure SI_Card_OpenEdit_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        SiCaps(Observer, '', P);
        R.Get(3);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        SiCaps(Observer, 'goto_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_OpenView_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenView();
        QoStep(Observer, 'open');
        SiCaps(Observer, '', P);
        R.Get(3);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        SiCaps(Observer, 'goto_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_OpenEdit_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        Observer.Observe('goto', Format(P.GoToKey(3)));
        QoStep(Observer, 'goto_calls');
        SiCaps(Observer, 'goto_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_GoToRecord_SameRow()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        R.Get(1);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        SiCaps(Observer, 'goto_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_GoToRecord_Twice()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        R.Get(3);
        Observer.Observe('goto3', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto3_calls');
        R.Get(2);
        Observer.Observe('goto2', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto2_calls');
        SiCaps(Observer, 'goto2_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_GoToRecord_ThenNext()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        R.Get(2);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        Observer.Observe('next', Format(P.Next()));
        QoStep(Observer, 'next_calls');
        SiCaps(Observer, 'next_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_Last_Previous_First()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        Observer.Observe('last', Format(P.Last()));
        QoStep(Observer, 'last_calls');
        SiCaps(Observer, 'last_', P);
        Observer.Observe('previous', Format(P.Previous()));
        QoStep(Observer, 'previous_calls');
        SiCaps(Observer, 'previous_', P);
        Observer.Observe('first', Format(P.First()));
        QoStep(Observer, 'first_calls');
        SiCaps(Observer, 'first_', P);
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Card_SetValueThenGoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        P.Lit20.SetValue(5);
        QoStep(Observer, 'setvalue_calls');
        R.Get(3);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        SiCaps(Observer, 'goto_', P);
        P.Close();
        QoStep(Observer, 'close');
        R.Get(1);
        Observer.Observe('row1_lit20', Format(R."Lit 2-0"));
        Observer.Finish();
    end;

    [Test]
    procedure SI_List_OpenView_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QF Cap List";
    begin
        SiSeedThree();
        P.OpenView();
        QoStep(Observer, 'open');
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        R.Get(3);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_row', P.Id.Value());
        Cap(Observer, 'goto_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'goto_exprVAT', P.ExprVAT.Caption());
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_List_OpenEdit_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT QF Cap List";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        Observer.Observe('goto', Format(P.GoToKey(3)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_row', P.Id.Value());
        Cap(Observer, 'goto_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'goto_exprVAT', P.ExprVAT.Caption());
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    // The reporter's Document page: a Document page without a part over the QD row.
    [Test]
    procedure SI_Doc_OpenEdit_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT SI Cap Doc";
    begin
        SiSeedThree();
        P.OpenEdit();
        QoStep(Observer, 'open');
        Cap(Observer, 'exprId', QfNoCall(P.ExprId.Caption()));
        R.Get(3);
        Observer.Observe('goto', Format(P.GoToRecord(R)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_row', P.Id.Value());
        Cap(Observer, 'goto_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'goto_exprVAT', P.ExprVAT.Caption());
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    [Test]
    procedure SI_Doc_OpenView_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SI Cap Doc";
    begin
        SiSeedThree();
        P.OpenView();
        QoStep(Observer, 'open');
        Observer.Observe('goto', Format(P.GoToKey(3)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_row', P.Id.Value());
        Cap(Observer, 'goto_exprId', QfNoCall(P.ExprId.Caption()));
        Cap(Observer, 'goto_exprVAT', P.ExprVAT.Caption());
        P.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    // The QO Document page with its ListPart: the host moves to D2, so the part is refilled with D2's lines (3 and 4).
    [Test]
    procedure SI_DocPart_OpenEdit_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        D: Record "LT QO Cap Doc";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        QoStep(Observer, 'open');
        D.Get('D2');
        Observer.Observe('goto', Format(H.GoToRecord(D)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_no', H."No.".Value());
        Cap(Observer, 'goto_head', H.HeadExpr.Caption());
        Cap(Observer, 'goto_line', H.Lines."Line No.".Value());
        Cap(Observer, 'goto_exprA', H.Lines.ExprA.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;

    // A move inside the part: GoToKey to the second line of D1.
    [Test]
    procedure SI_DocPart_Part_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "LT QO Cap Doc";
    begin
        QoSeedDocs();
        H.OpenEdit();
        QoStep(Observer, 'open');
        Observer.Observe('goto', Format(H.Lines.GoToKey('D1', 2)));
        QoStep(Observer, 'goto_calls');
        Cap(Observer, 'goto_line', H.Lines."Line No.".Value());
        Cap(Observer, 'goto_exprA', H.Lines.ExprA.Caption());
        Cap(Observer, 'goto_head', H.HeadExpr.Caption());
        H.Close();
        QoStep(Observer, 'close');
        Observer.Finish();
    end;
}

page 87092 "LT QO Cap Doc"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QO Cap Doc";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Seq; Rec.Seq) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(HeadExpr; Rec."Head Expr") { ApplicationArea = All; }
            }
            part(Lines; "LT QO Cap Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';

                trigger OnAction()
                begin
                    CurrPage.Update();
                end;
            }
            // Writer SF: an action whose trigger has no CurrPage.Update.
            action(NoUpdate)
            {
                ApplicationArea = All;
                Caption = 'No Update';

                trigger OnAction()
                begin
                    NoUpdateClicks += 1;
                end;
            }
        }
    }

    var
        NoUpdateClicks: Integer;
}

page 87093 "LT QO Cap Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QO Cap Line";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(ExprA; Rec."Expr A") { ApplicationArea = All; }
                field(ExprB; Rec."Expr B") { ApplicationArea = All; }
            }
        }
    }
}

table 86643 "LT QF Cap Host Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 86640 "LT QF Cap List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QD Cap Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Expr20; Rec."Expr 2-0") { ApplicationArea = All; }
                field(ExprVAT; Rec."Expr VAT") { ApplicationArea = All; }
                field(ExprId; Rec."Expr Id") { ApplicationArea = All; }
            }
        }
    }
}

page 86641 "LT QF Cap Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QD Cap Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(ExprVAT; Rec."Expr VAT") { ApplicationArea = All; }
                field(ExprId; Rec."Expr Id") { ApplicationArea = All; }
            }
        }
    }
}

page 86642 "LT QF Cap Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QF Cap Host Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            part(Lines; "LT QF Cap Part") { ApplicationArea = All; }
        }
    }
}

// Writer SI: the Document page of al-runner issue 5858 (no part) over the QD row.
page 89150 "LT SI Cap Doc"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QD Cap Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Expr20; Rec."Expr 2-0") { ApplicationArea = All; }
                field(ExprVAT; Rec."Expr VAT") { ApplicationArea = All; }
                field(ExprId; Rec."Expr Id") { ApplicationArea = All; }
            }
        }
    }
}
