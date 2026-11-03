// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI AF *); System tables Currency and General Ledger Setup
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a TABLE field whose AutoFormatExpression is an expression (Rec."Currency Code"; AutoFormatType 1, 2, 4, 5) shown by plain page
//   controls (no AutoFormat property of their own) on a Card and a List: the text for a currency with places 3:3 / 4:4, a blank code and a
//   code that is no currency; AutoFormatType 10 with AutoFormatExpression = a procedure of the table that logs its calls: when and how often
//   it runs (open, Next, GoToRecord, Value) and what an error raised in it does.
// Settles al-runtime-rs docs/probes-needed.md assumption table-field-auto-format-expression (Tests-ERM 134833 Amount AutoFormat Currency).
// BC versions: 29 (27 and 28 by CI)

table 86820 "LT QI AF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Currency Code"; Code[10]) { }
        field(3; Amt1; Decimal) { AutoFormatType = 1; AutoFormatExpression = Rec."Currency Code"; }
        field(4; Amt2; Decimal) { AutoFormatType = 2; AutoFormatExpression = Rec."Currency Code"; }
        field(5; Amt4; Decimal) { AutoFormatType = 4; AutoFormatExpression = Rec."Currency Code"; }
        field(6; Amt5; Decimal) { AutoFormatType = 5; AutoFormatExpression = Rec."Currency Code"; }
        field(7; Amt10; Decimal) { AutoFormatType = 10; AutoFormatExpression = LoggedFormat(); }
        field(8; FailOnFormat; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure LoggedFormat(): Text
    var
        Log: Codeunit "LT QI AF Log";
    begin
        Log.Add('fmt(' + Rec."No." + ')');
        if Rec.FailOnFormat then
            Error('LT QI format failed for %1', Rec."No.");
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

codeunit 86821 "LT QI AF Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 86822 "LT QI AF Card"
{
    PageType = Card;
    SourceTable = "LT QI AF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(T1; Rec.Amt1) { ApplicationArea = All; }
                field(T2; Rec.Amt2) { ApplicationArea = All; }
                field(T4; Rec.Amt4) { ApplicationArea = All; }
                field(T5; Rec.Amt5) { ApplicationArea = All; }
            }
        }
    }
}

page 86823 "LT QI AF List"
{
    PageType = List;
    SourceTable = "LT QI AF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(T1; Rec.Amt1) { ApplicationArea = All; }
                field(T2; Rec.Amt2) { ApplicationArea = All; }
                field(T4; Rec.Amt4) { ApplicationArea = All; }
                field(T5; Rec.Amt5) { ApplicationArea = All; }
            }
        }
    }
}

page 86824 "LT QI AF10 Card"
{
    PageType = Card;
    SourceTable = "LT QI AF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(T10; Rec.Amt10) { ApplicationArea = All; }
            }
        }
    }
}

page 86825 "LT QI AF10 List"
{
    PageType = List;
    SourceTable = "LT QI AF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(T10; Rec.Amt10) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 86826 "LT QI Table Field AutoFormat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SavedAmountPlaces: Text;
        SavedUnitPlaces: Text;
        SavedShowCurrency: Enum "Show Currency";

    local procedure SetSetup(ShowCurrency: Enum "Show Currency")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        SavedAmountPlaces := GLSetup."Amount Decimal Places";
        SavedUnitPlaces := GLSetup."Unit-Amount Decimal Places";
        SavedShowCurrency := GLSetup."Show Currency";
        GLSetup."Amount Decimal Places" := '2:2';
        GLSetup."Unit-Amount Decimal Places" := '2:5';
        GLSetup."Show Currency" := ShowCurrency;
        GLSetup.Modify();
    end;

    // The BC 27.5 test runner commits what a test leaves (autoformat/PWAutoFormatTypes.al RestoreSetup), so every test puts the setup back.
    local procedure RestoreSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then
            exit;
        GLSetup."Amount Decimal Places" := CopyStr(SavedAmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(SavedUnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := SavedShowCurrency;
        GLSetup.Modify();
    end;

    local procedure SeedCurrency()
    var
        Currency: Record Currency;
    begin
        if Currency.Get('QIC') then
            Currency.Delete();
        Currency.Init();
        Currency.Code := 'QIC';
        Currency.Symbol := 'Q$';
        Currency."Amount Decimal Places" := '3:3';
        Currency."Unit-Amount Decimal Places" := '4:4';
        Currency.Insert();
        if Currency.Get('QINONE') then
            Currency.Delete();
    end;

    local procedure DropCurrency()
    var
        Currency: Record Currency;
    begin
        if Currency.Get('QIC') then
            Currency.Delete();
    end;

    local procedure AddRow(No: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Fail: Boolean)
    var
        Row: Record "LT QI AF Row";
    begin
        Row.Init();
        Row."No." := No;
        Row."Currency Code" := CurrencyCode;
        Row.Amt1 := Amount;
        Row.Amt2 := Amount;
        Row.Amt4 := Amount;
        Row.Amt5 := Amount;
        Row.Amt10 := Amount;
        Row.FailOnFormat := Fail;
        Row.Insert();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT QI AF Row";
    begin
        Row.DeleteAll();
        AddRow('A', 'QIC', 1234.56789, false);
        AddRow('B', '', 1234.56789, false);
        AddRow('C', 'QINONE', 1234.56789, false);
    end;

    local procedure ReadCard(var Observer: Codeunit "Probe Observer"; Tag: Text; No: Code[20])
    var
        Row: Record "LT QI AF Row";
        Card: TestPage "LT QI AF Card";
    begin
        Row.Get(No);
        Card.OpenView();
        Card.GoToRecord(Row);
        Observer.Observe(Tag + '_t1', Card.T1.Value());
        Observer.Observe(Tag + '_t2', Card.T2.Value());
        Observer.Observe(Tag + '_t4', Card.T4.Value());
        Observer.Observe(Tag + '_t5', Card.T5.Value());
        Card.Close();
    end;

    local procedure ReadListRow(var Observer: Codeunit "Probe Observer"; var List: TestPage "LT QI AF List"; Tag: Text)
    begin
        Observer.Observe(Tag + '_no', List.NoCtl.Value());
        Observer.Observe(Tag + '_t1', List.T1.Value());
        Observer.Observe(Tag + '_t2', List.T2.Value());
        Observer.Observe(Tag + '_t4', List.T4.Value());
        Observer.Observe(Tag + '_t5', List.T5.Value());
    end;

    [Test]
    procedure QI_TableFieldExpression_Card_ShowCurrencyNever()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        SeedCurrency();
        SeedRows();
        ReadCard(Observer, 'cur', 'A');
        ReadCard(Observer, 'blank', 'B');
        ReadCard(Observer, 'nocur', 'C');
        DropCurrency();
        RestoreSetup();
        Observer.Expect('cur_t1', '1,234.568');
        Observer.Expect('cur_t2', '1,234.5679');
        Observer.Expect('cur_t4', '1,234.568');
        Observer.Expect('cur_t5', '1,234.5679');
        Observer.Expect('blank_t1', '1,234.57');
        Observer.Expect('blank_t2', '1,234.56789');
        Observer.Expect('blank_t4', '1,234.57');
        Observer.Expect('blank_t5', '1,234.56789');
        Observer.Expect('nocur_t1', '1,234.57');
        Observer.Expect('nocur_t2', '1,234.56789');
        Observer.Expect('nocur_t4', '1,234.57');
        Observer.Expect('nocur_t5', '1,234.56789');
        Observer.Verify();
    end;

    [Test]
    procedure QI_TableFieldExpression_List_ShowCurrencyNever()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QI AF List";
    begin
        SetSetup("Show Currency"::Never);
        SeedCurrency();
        SeedRows();
        List.OpenView();
        Observer.Observe('first', Format(List.First()));
        ReadListRow(Observer, List, 'row1');
        Observer.Observe('next', Format(List.Next()));
        ReadListRow(Observer, List, 'row2');
        Observer.Observe('next2', Format(List.Next()));
        ReadListRow(Observer, List, 'row3');
        Observer.Observe('previous', Format(List.Previous()));
        ReadListRow(Observer, List, 'back2');
        List.Close();
        DropCurrency();
        RestoreSetup();
        Observer.Expect('first', 'Yes');
        Observer.Expect('row1_no', 'A');
        Observer.Expect('row1_t1', '1,234.568');
        Observer.Expect('row1_t2', '1,234.5679');
        Observer.Expect('row1_t4', '1,234.568');
        Observer.Expect('row1_t5', '1,234.5679');
        Observer.Expect('next', 'Yes');
        Observer.Expect('row2_no', 'B');
        Observer.Expect('row2_t1', '1,234.57');
        Observer.Expect('row2_t2', '1,234.56789');
        Observer.Expect('row2_t4', '1,234.57');
        Observer.Expect('row2_t5', '1,234.56789');
        Observer.Expect('next2', 'Yes');
        Observer.Expect('row3_no', 'C');
        Observer.Expect('row3_t1', '1,234.57');
        Observer.Expect('row3_t2', '1,234.56789');
        Observer.Expect('row3_t4', '1,234.57');
        Observer.Expect('row3_t5', '1,234.56789');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('back2_no', 'B');
        Observer.Expect('back2_t1', '1,234.57');
        Observer.Expect('back2_t2', '1,234.56789');
        Observer.Expect('back2_t4', '1,234.57');
        Observer.Expect('back2_t5', '1,234.56789');
        Observer.Verify();
    end;

    [Test]
    procedure QI_TableFieldExpression_Card_ShowFcyCodeOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::"FCY Currency Code Only");
        SeedCurrency();
        SeedRows();
        ReadCard(Observer, 'cur', 'A');
        ReadCard(Observer, 'blank', 'B');
        ReadCard(Observer, 'nocur', 'C');
        DropCurrency();
        RestoreSetup();
        Observer.Expect('cur_t1', '1,234.568');
        Observer.Expect('cur_t2', '1,234.5679');
        Observer.Expect('cur_t4', '1,234.568');
        Observer.Expect('cur_t5', '1,234.5679');
        Observer.Expect('blank_t1', '1,234.57');
        Observer.Expect('blank_t2', '1,234.56789');
        Observer.Expect('blank_t4', '1,234.57');
        Observer.Expect('blank_t5', '1,234.56789');
        Observer.Expect('nocur_t1', '1,234.57');
        Observer.Expect('nocur_t2', '1,234.56789');
        Observer.Expect('nocur_t4', '1,234.57');
        Observer.Expect('nocur_t5', '1,234.56789');
        Observer.Verify();
    end;

    [Test]
    procedure QI_TableFieldExpression_Card_ShowFcySymbolOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::"FCY Symbol Only");
        SeedCurrency();
        SeedRows();
        ReadCard(Observer, 'cur', 'A');
        ReadCard(Observer, 'blank', 'B');
        DropCurrency();
        RestoreSetup();
        Observer.Expect('cur_t1', '1,234.568');
        Observer.Expect('cur_t2', '1,234.5679');
        Observer.Expect('cur_t4', '1,234.568');
        Observer.Expect('cur_t5', '1,234.5679');
        Observer.Expect('blank_t1', '1,234.57');
        Observer.Expect('blank_t2', '1,234.56789');
        Observer.Expect('blank_t4', '1,234.57');
        Observer.Expect('blank_t5', '1,234.56789');
        Observer.Verify();
    end;

    // Format() in code does not go through a page control: does it use the table field's AutoFormat?
    [Test]
    procedure QI_TableFieldExpression_FormatInCode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QI AF Row";
    begin
        SetSetup("Show Currency"::Never);
        SeedCurrency();
        SeedRows();
        Row.Get('A');
        Observer.Observe('format_amt1', Format(Row.Amt1));
        Observer.Observe('format_amt2', Format(Row.Amt2));
        Observer.Observe('format_amt10', Format(Row.Amt10));
        DropCurrency();
        RestoreSetup();
        Observer.Expect('format_amt1', '1,234.568');
        Observer.Expect('format_amt2', '1,234.5679');
        Observer.Expect('format_amt10', '1,234.568');
        Observer.Verify();
    end;

    [Test]
    procedure QI_Type10Procedure_Card_Calls()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI AF Log";
        Row: Record "LT QI AF Row";
        Card: TestPage "LT QI AF10 Card";
    begin
        SeedRows();
        Log.Reset();
        Card.OpenView();
        Observer.Observe('after-open', Log.Take());
        Observer.Observe('no', Card.NoCtl.Value());
        Observer.Observe('after-no-read', Log.Take());
        Observer.Observe('t10', Card.T10.Value());
        Observer.Observe('after-t10-read', Log.Take());
        Observer.Observe('t10-again', Card.T10.Value());
        Observer.Observe('after-t10-again', Log.Take());
        Observer.Observe('next', Format(Card.Next()));
        Observer.Observe('after-next', Log.Take());
        Observer.Observe('t10-row2', Card.T10.Value());
        Observer.Observe('after-t10-row2', Log.Take());
        Row.Get('C');
        Card.GoToRecord(Row);
        Observer.Observe('after-gotorecord', Log.Take());
        Observer.Observe('t10-row3', Card.T10.Value());
        Observer.Observe('after-t10-row3', Log.Take());
        Card.Close();
        Observer.Observe('after-close', Log.Take());
        Observer.Expect('after-open', 'fmt();fmt(A);');
        Observer.Expect('no', 'A');
        Observer.Expect('after-no-read', '');
        Observer.Expect('t10', '1,234.568');
        Observer.Expect('after-t10-read', '');
        Observer.Expect('t10-again', '1,234.568');
        Observer.Expect('after-t10-again', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('after-next', 'fmt(B);');
        Observer.Expect('t10-row2', '1,234.568');
        Observer.Expect('after-t10-row2', '');
        Observer.Expect('after-gotorecord', 'fmt(A);fmt(B);fmt(C);');
        Observer.Expect('t10-row3', '1,234.568');
        Observer.Expect('after-t10-row3', '');
        Observer.Expect('after-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QI_Type10Procedure_List_Calls()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI AF Log";
        Row: Record "LT QI AF Row";
        List: TestPage "LT QI AF10 List";
    begin
        SeedRows();
        Log.Reset();
        List.OpenView();
        Observer.Observe('after-open', Log.Take());
        Observer.Observe('t10', List.T10.Value());
        Observer.Observe('after-t10-read', Log.Take());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('after-next', Log.Take());
        Observer.Observe('t10-row2', List.T10.Value());
        Observer.Observe('after-t10-row2', Log.Take());
        Row.Get('C');
        List.GoToRecord(Row);
        Observer.Observe('after-gotorecord', Log.Take());
        Observer.Observe('t10-row3', List.T10.Value());
        Observer.Observe('after-t10-row3', Log.Take());
        List.Close();
        Observer.Observe('after-close', Log.Take());
        Observer.Expect('after-open', 'fmt();fmt(A);fmt(B);fmt(C);');
        Observer.Expect('t10', '1,234.568');
        Observer.Expect('after-t10-read', '');
        Observer.Expect('next', 'Yes');
        Observer.Expect('after-next', '');
        Observer.Expect('t10-row2', '1,234.568');
        Observer.Expect('after-t10-row2', '');
        Observer.Expect('after-gotorecord', '');
        Observer.Expect('t10-row3', '1,234.568');
        Observer.Expect('after-t10-row3', '');
        Observer.Expect('after-close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QI_Type10Procedure_ErrorOnFirstRow_CardOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI AF Log";
        Row: Record "LT QI AF Row";
        Card: TestPage "LT QI AF10 Card";
    begin
        Row.DeleteAll();
        AddRow('A', '', 1.5, true);
        AddRow('B', '', 2.5, false);
        Log.Reset();
        asserterror Card.OpenView();
        Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Expect('open|text', 'LT QI format failed for A');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'fmt();fmt(A);');
        Observer.Verify();
    end;

    [Test]
    procedure QI_Type10Procedure_ErrorOnSecondRow_CardMoves()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI AF Log";
        Row: Record "LT QI AF Row";
        Card: TestPage "LT QI AF10 Card";
    begin
        Row.DeleteAll();
        AddRow('A', '', 1.5, false);
        AddRow('B', '', 2.5, true);
        AddRow('C', '', 3.5, false);
        Log.Reset();
        Card.OpenView();
        Observer.Observe('t10-row1', Card.T10.Value());
        Observer.Observe('log-open', Log.Take());
        asserterror Card.Next();
        Observer.ObserveError('next');
        Observer.Observe('log-next', Log.Take());
        Observer.Expect('t10-row1', '1.500');
        Observer.Expect('log-open', 'fmt();fmt(A);');
        Observer.Expect('next|text', 'LT QI format failed for B');
        Observer.Expect('next|code', 'Dialog');
        Observer.Expect('log-next', 'fmt(B);');
        Observer.Verify();
    end;

    [Test]
    procedure QI_Type10Procedure_ErrorOnSecondRow_ListOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI AF Log";
        Row: Record "LT QI AF Row";
        List: TestPage "LT QI AF10 List";
    begin
        Row.DeleteAll();
        AddRow('A', '', 1.5, false);
        AddRow('B', '', 2.5, true);
        AddRow('C', '', 3.5, false);
        Log.Reset();
        asserterror List.OpenView();
        Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Expect('open|text', 'LT QI format failed for B');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'fmt();fmt(A);fmt(B);');
        Observer.Verify();
    end;
}
