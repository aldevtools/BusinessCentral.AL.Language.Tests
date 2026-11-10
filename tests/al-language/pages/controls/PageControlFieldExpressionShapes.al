// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 66400, pages 66401 and 66404, page extension 66402, test codeunit 66403
// local object: the controls of the pages and of the page extension are what the tests measure.
// Probe (al-runner issue 7442: a read of "Page Control Field" filtered on TableNo, PageNo and a FieldNo, for a page that a page extension
//   gives a control bound to `(not IsNullGuid(Rec."E-Document Link"))`): observation form, the values are read from the corpus CI matrix.
// Area: the "Page Control Field" (2000000192) row of a control bound to an expression, by the shape of the expression: not, parentheses,
//   comparisons, and / or, in, arithmetic, unary minus, div and mod, text concatenation, a built-in call with a field argument, nested
//   calls, a literal, a global variable, and a field for contrast; on a Card page, in a repeater of a List page, and added by a page
//   extension. Columns read: TableNo, FieldNo, Enabled, Editable, Visible, SourceExpression, OptionString, Sequence. And the reported
//   read: a filter on TableNo, PageNo and FieldNo (a field that only expressions name, a field a control is bound to, a field no control
//   names), with IsEmpty and Count.
// Existing pins: record/X3PageControlCalls.al (procedure calls), record/PageControlFieldSourceFormsSM.al (array elements, quoted names,
//   Format(Rec.Quantity)), record/WbPageControlBuiltIn.al (a built-in call without arguments), record/TestPageControlFieldPageExtension.al
//   (a field-bound control of a page extension).
// BC versions: 27, 28, 29 by CI

table 66400 "PG PcfExpr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Link; Guid) { }
        field(5; Name; Text[30]) { }
        field(6; Flag; Boolean) { }
        field(7; Day; Date) { }
        field(8; Unused; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 66401 "PG PcfExpr Card"
{
    PageType = Card;
    SourceTable = "PG PcfExpr Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NotNullGuidParen; (not IsNullGuid(Rec.Link))) { ApplicationArea = All; }
                field(NotNullGuid; not IsNullGuid(Rec.Link)) { ApplicationArea = All; }
                field(NotFlag; not Rec.Flag) { ApplicationArea = All; }
                field(Compare; Rec.Qty > 0) { ApplicationArea = All; }
                field(CompareParen; (Rec.Qty <> 0)) { ApplicationArea = All; }
                field(AndExpr; (Rec.Qty > 0) and Rec.Flag) { ApplicationArea = All; }
                field(OrExpr; Rec.Flag or (Rec.Amount = 0)) { ApplicationArea = All; }
                field(InExpr; Rec.Qty in [1 .. 3]) { ApplicationArea = All; }
                field(BuiltIn; IsNullGuid(Rec.Link)) { ApplicationArea = All; }
                field(ParenField; (Rec.Qty)) { ApplicationArea = All; }
                field(SumExpr; Rec.Qty + 1) { ApplicationArea = All; }
                field(Product; Rec.Qty * Rec.Amount) { ApplicationArea = All; }
                field(Negate; -Rec.Qty) { ApplicationArea = All; }
                field(DivExpr; Rec.Qty div 2) { ApplicationArea = All; }
                field(ModExpr; Rec.Qty mod 2) { ApplicationArea = All; }
                field(Concat; Rec."No." + ' ' + Rec.Name) { ApplicationArea = All; }
                field(Nested; UpperCase(CopyStr(Rec.Name, 1, 5))) { ApplicationArea = All; }
                field(FormatDay; Format(Rec.Day, 0, 9)) { ApplicationArea = All; }
                field(TextLiteral; 'fixed') { ApplicationArea = All; }
                field(NumberLiteral; 42) { ApplicationArea = All; }
                field(GlobalVar; GlobalText) { ApplicationArea = All; }
                field(NotGlobal; not GlobalFlag) { ApplicationArea = All; }
                field(GlobalAndField; GlobalFlag and Rec.Flag) { ApplicationArea = All; }
            }
        }
    }

    var
        GlobalText: Text;
        GlobalFlag: Boolean;
}

pageextension 66402 "PG PcfExpr Card Ext" extends "PG PcfExpr Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtNotNullGuidParen; (not IsNullGuid(Rec.Link))) { ApplicationArea = All; }
            field(ExtCompare; Rec.Amount > 0) { ApplicationArea = All; }
            field(ExtConcat; Rec.Name + '!') { ApplicationArea = All; }
            field(ExtName; Rec.Name) { ApplicationArea = All; }
            field(ExtGlobal; not ExtFlag) { ApplicationArea = All; }
        }
    }

    var
        ExtFlag: Boolean;
}

page 66404 "PG PcfExpr List"
{
    PageType = List;
    SourceTable = "PG PcfExpr Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NotNullGuidParen; (not IsNullGuid(Rec.Link))) { ApplicationArea = All; }
                field(Compare; Rec.Qty > 0) { ApplicationArea = All; }
                field(Concat; Rec."No." + ' ' + Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 66403 "PG PcfExpr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        R: Record "PG PcfExpr Row";
    begin
        R.DeleteAll();
    end;

    local procedure Row(PageNo: Integer; ControlName: Text): Text
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, PageNo);
        PageControlField.SetRange(ControlName, ControlName);
        if not PageControlField.FindFirst() then
            exit('no row');
        exit(StrSubstNo('T=%1 F=%2 En=[%3] Ed=[%4] Vis=[%5] Src=[%6] Opt=[%7] Seq=%8',
            OwnTable(PageControlField.TableNo), PageControlField.FieldNo, PageControlField.Enabled, PageControlField.Editable,
            PageControlField.Visible, PageControlField.SourceExpression, PageControlField.OptionString, PageControlField.Sequence));
    end;

    local procedure OwnTable(TableNo: Integer): Text
    begin
        if TableNo = Database::"PG PcfExpr Row" then
            exit('own');
        exit(Format(TableNo));
    end;

    local procedure Read(var Observer: Codeunit "Probe Observer"; PageNo: Integer; ControlName: Text)
    begin
        Observer.Observe(ControlName, Row(PageNo, ControlName));
    end;

    [TryFunction]
    local procedure TryFiltered(PageNo: Integer; FieldNo: Integer; var Result: Text)
    var
        PageControlField: Record "Page Control Field";
        Names: Text;
    begin
        PageControlField.SetRange(TableNo, Database::"PG PcfExpr Row");
        PageControlField.SetRange(PageNo, PageNo);
        PageControlField.SetRange(FieldNo, FieldNo);
        Result := 'IsEmpty=' + Format(PageControlField.IsEmpty(), 0, 9) + ' Count=' + Format(PageControlField.Count());
        if PageControlField.FindSet() then
            repeat
                Names += PageControlField.ControlName + ' ';
            until PageControlField.Next() = 0;
        Result += ' controls=' + Names;
    end;

    local procedure Filtered(var Observer: Codeunit "Probe Observer"; Name: Text; PageNo: Integer; FieldNo: Integer)
    var
        Result: Text;
    begin
        if TryFiltered(PageNo, FieldNo, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Card_NotAndComparisonControls_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Read(Observer, Page::"PG PcfExpr Card", 'NotNullGuidParen');
        Read(Observer, Page::"PG PcfExpr Card", 'NotNullGuid');
        Read(Observer, Page::"PG PcfExpr Card", 'NotFlag');
        Read(Observer, Page::"PG PcfExpr Card", 'Compare');
        Read(Observer, Page::"PG PcfExpr Card", 'CompareParen');
        Read(Observer, Page::"PG PcfExpr Card", 'AndExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'OrExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'InExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'BuiltIn');
        Observer.Expect('NotNullGuidParen', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(not IsNullGuid(Rec.Link))] Opt=[] Seq=1');
        Observer.Expect('NotNullGuid', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[not IsNullGuid(Rec.Link)] Opt=[] Seq=2');
        Observer.Expect('NotFlag', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[not Rec.Flag] Opt=[] Seq=3');
        Observer.Expect('Compare', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty > 0] Opt=[] Seq=4');
        Observer.Expect('CompareParen', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(Rec.Qty <> 0)] Opt=[] Seq=5');
        Observer.Expect('AndExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(Rec.Qty > 0) and Rec.Flag] Opt=[] Seq=6');
        Observer.Expect('OrExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Flag or (Rec.Amount = 0)] Opt=[] Seq=7');
        Observer.Expect('InExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty in [1 .. 3]] Opt=[] Seq=8');
        Observer.Expect('BuiltIn', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[IsNullGuid(Rec.Link)] Opt=[] Seq=9');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ArithmeticAndTextControls_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Read(Observer, Page::"PG PcfExpr Card", 'ParenField');
        Read(Observer, Page::"PG PcfExpr Card", 'SumExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'Product');
        Read(Observer, Page::"PG PcfExpr Card", 'Negate');
        Read(Observer, Page::"PG PcfExpr Card", 'DivExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'ModExpr');
        Read(Observer, Page::"PG PcfExpr Card", 'Concat');
        Read(Observer, Page::"PG PcfExpr Card", 'Nested');
        Read(Observer, Page::"PG PcfExpr Card", 'FormatDay');
        Observer.Expect('ParenField', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(Rec.Qty)] Opt=[] Seq=10');
        Observer.Expect('SumExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty + 1] Opt=[] Seq=11');
        Observer.Expect('Product', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty * Rec.Amount] Opt=[] Seq=12');
        Observer.Expect('Negate', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[-Rec.Qty] Opt=[] Seq=13');
        Observer.Expect('DivExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty div 2] Opt=[] Seq=14');
        Observer.Expect('ModExpr', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty mod 2] Opt=[] Seq=15');
        Observer.Expect('Concat', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec."No." + '' '' + Rec.Name] Opt=[] Seq=16');
        Observer.Expect('Nested', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[UpperCase(CopyStr(Rec.Name, 1, 5))] Opt=[] Seq=17');
        Observer.Expect('FormatDay', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Format(Rec.Day, 0, 9)] Opt=[] Seq=18');
        Observer.Verify();
    end;

    [Test]
    procedure Card_LiteralVariableAndFieldControls_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Read(Observer, Page::"PG PcfExpr Card", 'NoCtl');
        Read(Observer, Page::"PG PcfExpr Card", 'TextLiteral');
        Read(Observer, Page::"PG PcfExpr Card", 'NumberLiteral');
        Read(Observer, Page::"PG PcfExpr Card", 'GlobalVar');
        Read(Observer, Page::"PG PcfExpr Card", 'NotGlobal');
        Read(Observer, Page::"PG PcfExpr Card", 'GlobalAndField');
        Observer.Expect('NoCtl', 'T=own F=1 En=[true] Ed=[True] Vis=[true] Src=[No.] Opt=[] Seq=0');
        Observer.Expect('TextLiteral', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[''fixed''] Opt=[] Seq=19');
        Observer.Expect('NumberLiteral', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[42] Opt=[] Seq=20');
        Observer.Expect('GlobalVar', 'T=own F=0 En=[true] Ed=[True] Vis=[true] Src=[GlobalText] Opt=[] Seq=21');
        Observer.Expect('NotGlobal', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[not GlobalFlag] Opt=[] Seq=22');
        Observer.Expect('GlobalAndField', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[GlobalFlag and Rec.Flag] Opt=[] Seq=23');
        Observer.Verify();
    end;

    [Test]
    procedure PageExtension_ExpressionControls_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Read(Observer, Page::"PG PcfExpr Card", 'ExtNotNullGuidParen');
        Read(Observer, Page::"PG PcfExpr Card", 'ExtCompare');
        Read(Observer, Page::"PG PcfExpr Card", 'ExtConcat');
        Read(Observer, Page::"PG PcfExpr Card", 'ExtName');
        Read(Observer, Page::"PG PcfExpr Card", 'ExtGlobal');
        Observer.Expect('ExtNotNullGuidParen', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(not IsNullGuid(Rec.Link))] Opt=[] Seq=24');
        Observer.Expect('ExtCompare', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Amount > 0] Opt=[] Seq=25');
        Observer.Expect('ExtConcat', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Name + ''!''] Opt=[] Seq=26');
        Observer.Expect('ExtName', 'T=own F=5 En=[true] Ed=[True] Vis=[true] Src=[Name] Opt=[] Seq=27');
        Observer.Expect('ExtGlobal', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[not ExtFlag] Opt=[] Seq=28');
        Observer.Verify();
    end;

    [Test]
    procedure ListRepeater_ExpressionControls_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Read(Observer, Page::"PG PcfExpr List", 'NoCtl');
        Read(Observer, Page::"PG PcfExpr List", 'NotNullGuidParen');
        Read(Observer, Page::"PG PcfExpr List", 'Compare');
        Read(Observer, Page::"PG PcfExpr List", 'Concat');
        Observer.Expect('NoCtl', 'T=own F=1 En=[true] Ed=[True] Vis=[true] Src=[No.] Opt=[] Seq=0');
        Observer.Expect('NotNullGuidParen', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[(not IsNullGuid(Rec.Link))] Opt=[] Seq=1');
        Observer.Expect('Compare', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec.Qty > 0] Opt=[] Seq=2');
        Observer.Expect('Concat', 'T=own F=0 En=[true] Ed=[False] Vis=[true] Src=[Rec."No." + '' '' + Rec.Name] Opt=[] Seq=3');
        Observer.Verify();
    end;

    [Test]
    procedure FilterOnFieldNo_PageWithExpressionControls_ReportedRead()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "PG PcfExpr Row";
    begin
        Initialize();
        Filtered(Observer, 'card, Link (only in expressions)', Page::"PG PcfExpr Card", R.FieldNo(Link));
        Filtered(Observer, 'card, No. (a bound control)', Page::"PG PcfExpr Card", R.FieldNo("No."));
        Filtered(Observer, 'card, Name (bound by the extension)', Page::"PG PcfExpr Card", R.FieldNo(Name));
        Filtered(Observer, 'card, Qty (only in expressions)', Page::"PG PcfExpr Card", R.FieldNo(Qty));
        Filtered(Observer, 'card, Unused (no control)', Page::"PG PcfExpr Card", R.FieldNo(Unused));
        Filtered(Observer, 'list, Link (only in expressions)', Page::"PG PcfExpr List", R.FieldNo(Link));
        Filtered(Observer, 'list, No. (a bound control)', Page::"PG PcfExpr List", R.FieldNo("No."));
        Observer.Expect('card, Link (only in expressions)', 'IsEmpty=true Count=0 controls=');
        Observer.Expect('card, No. (a bound control)', 'IsEmpty=false Count=1 controls=NoCtl ');
        Observer.Expect('card, Name (bound by the extension)', 'IsEmpty=false Count=1 controls=ExtName ');
        Observer.Expect('card, Qty (only in expressions)', 'IsEmpty=true Count=0 controls=');
        Observer.Expect('card, Unused (no control)', 'IsEmpty=true Count=0 controls=');
        Observer.Expect('list, Link (only in expressions)', 'IsEmpty=true Count=0 controls=');
        Observer.Expect('list, No. (a bound control)', 'IsEmpty=false Count=1 controls=NoCtl ');
        Observer.Verify();
    end;

    [Test]
    procedure FilterOnFieldNoZero_PageWithExpressionControls_ControlNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Filtered(Observer, 'card, FieldNo 0', Page::"PG PcfExpr Card", 0);
        Filtered(Observer, 'list, FieldNo 0', Page::"PG PcfExpr List", 0);
        Observer.Expect('card, FieldNo 0', 'IsEmpty=false Count=27 controls=ModExpr SumExpr Concat Negate ExtConcat AndExpr BuiltIn Compare GlobalAndField NotNullGuid Product InExpr ExtNotNullGuidParen GlobalVar CompareParen NotFlag Nested ParenField ExtGlobal OrExpr DivExpr NumberLiteral ExtCompare NotNullGuidParen FormatDay NotGlobal TextLiteral ');
        Observer.Expect('list, FieldNo 0', 'IsEmpty=false Count=3 controls=Compare Concat NotNullGuidParen ');
        Observer.Verify();
    end;
}
