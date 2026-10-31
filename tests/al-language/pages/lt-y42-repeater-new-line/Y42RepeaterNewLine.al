//sub:pages
// Gap cycle 4, spec G4-07: does a list whose repeater says Editable = false (or an expression) show the blank new-row
// line? Neighbours already pinned (handlers/TestPageNewRowLine_Tests.al:67-260) cover page-level Editable = false,
// InsertAllowed = false and OpenView; here only the repeater's Editable changes: literal false on a List, a Worksheet and a
// ListPart, a page global (the VAT Return Period List shape: OnInsertRecord raises Error('') when it is false) and a field
// of the row.
// BC 27.5-29.0: a repeater Editable = false (List, Worksheet, ListPart) or a false global: Next past the last row answers false;
// a true global lands on the blank line. An empty list runs OnNewRecord at open whatever the repeater says, and New() does not fail.

table 92821 "LT Y42 Nr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        L: Codeunit "LT Y42 Nr Log";
    begin
        L.Add('ins ' + Rec."No.");
    end;
}

codeunit 92823 "LT Y42 Nr Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Editable: Boolean;

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

    procedure SetEditable(NewEditable: Boolean)
    begin
        Editable := NewEditable;
    end;

    procedure GetEditable(): Boolean
    begin
        exit(Editable);
    end;
}

page 92820 "LT Y42 Nr List False"
{
    PageType = List;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Nr Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('new');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('agcr ' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        L.Add('oir');
    end;
}

// The Posted General Journal shape: Worksheet, DeleteAllowed = false, repeater Editable = false.
page 92821 "LT Y42 Nr Worksheet False"
{
    PageType = Worksheet;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Nr Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('new');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('agcr ' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        L.Add('oir');
    end;
}

// The VAT Return Period List shape: repeater Editable = a page global set in OnOpenPage.
page 92822 "LT Y42 Nr List Var"
{
    PageType = List;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = IsEditable;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Nr Log";
        IsEditable: Boolean;

    trigger OnOpenPage()
    begin
        IsEditable := L.GetEditable();
        L.Add('open editable=' + Format(IsEditable));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('new');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('agcr ' + Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        L.Add('oir');
        if not IsEditable then
            Error('');
    end;
}

// Repeater Editable = a field of the row.
page 92823 "LT Y42 Nr List Row Expr"
{
    PageType = List;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = Rec.Flag;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Nr Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        L.Add('new');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        L.Add('agcr ' + Rec."No.");
    end;
}

page 92824 "LT Y42 Nr Part False"
{
    PageType = ListPart;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 92825 "LT Y42 Nr Card"
{
    PageType = Card;
    SourceTable = "LT Y42 Nr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(LPF; "LT Y42 Nr Part False") { ApplicationArea = All; }
        }
    }
}

codeunit 92825 "LT Y42 Nr Repeater Editable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y42 Nr Log";

    local procedure Seed(Keys: Text)
    var
        Row: Record "LT Y42 Nr Row";
        K: Text;
    begin
        Row.DeleteAll();
        if Keys <> '' then
            foreach K in Keys.Split(',') do begin
                Row.Init();
                Row."No." := CopyStr(K, 1, 20);
                Row.Name := CopyStr('name ' + K, 1, 30);
                Row.Insert();
            end;
        L.Take();
    end;

    local procedure RowKeys(): Text
    var
        Row: Record "LT Y42 Nr Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."No." + ',';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ':' + Result);
    end;

    [TryFunction]
    local procedure TryNewListFalse(var TP: TestPage "LT Y42 Nr List False")
    begin
        TP.New();
    end;

    [TryFunction]
    local procedure TryNewListVar(var TP: TestPage "LT Y42 Nr List Var")
    begin
        TP.New();
    end;

    // Step 1: List, repeater Editable = false, two rows: Next past the last row.
    [Test]
    procedure NrEd_ListRepeaterFalse_NextPastLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List False";
    begin
        Seed('A1,A2');
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('no first', TP."No.".Value());
        Observer.Observe('next1', Format(TP.Next()));
        Observer.Observe('no next1', TP."No.".Value());
        Observer.Observe('next2', Format(TP.Next()));
        Observer.Observe('no next2', TP."No.".Value());
        Observer.Observe('editable next2', Format(TP."No.".Editable()));
        Observer.Observe('next3', Format(TP.Next()));
        Observer.Observe('log', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'agcr A1;');
        Observer.Expect('first', 'Yes');
        Observer.Expect('no first', 'A1');
        Observer.Expect('next1', 'Yes');
        Observer.Expect('no next1', 'A2');
        Observer.Expect('next2', 'No');
        Observer.Expect('no next2', 'A2');
        Observer.Expect('editable next2', 'No');
        Observer.Expect('next3', 'No');
        Observer.Expect('log', 'agcr A2;');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '2:A1,A2,');
        Observer.Verify();
    end;

    // Step 2: List, repeater Editable = false, empty table.
    [Test]
    procedure NrEd_ListRepeaterFalse_Empty()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List False";
    begin
        Seed('');
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('name', TP.Name.Value());
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewListFalse(TP)));
        Observer.ObserveError('new');
        Observer.Observe('log', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'new;agcr ;');
        Observer.Expect('first', 'No');
        Observer.Expect('name', '');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('log', 'new;agcr ;');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '0:');
        Observer.Verify();
    end;

    // Step 3: Worksheet, repeater Editable = false, DeleteAllowed = false: via Trap + Page.Run and via OpenEdit.
    [Test]
    procedure NrEd_WorksheetRepeaterFalse_NextPastLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr Worksheet False";
        TP2: TestPage "LT Y42 Nr Worksheet False";
    begin
        Seed('A1');
        TP.Trap();
        Page.Run(Page::"LT Y42 Nr Worksheet False");
        Observer.Observe('run log open', L.Take());
        Observer.Observe('run first', Format(TP.First()));
        Observer.Observe('run next', Format(TP.Next()));
        Observer.Observe('run no', TP."No.".Value());
        Observer.Observe('run log', L.Take());
        TP.Close();
        L.Take();
        TP2.OpenEdit();
        Observer.Observe('edit log open', L.Take());
        Observer.Observe('edit first', Format(TP2.First()));
        Observer.Observe('edit next', Format(TP2.Next()));
        Observer.Observe('edit no', TP2."No.".Value());
        Observer.Observe('edit log', L.Take());
        TP2.Close();
        Observer.Observe('rows', RowKeys());
        Observer.Expect('run log open', 'agcr A1;');
        Observer.Expect('run first', 'Yes');
        Observer.Expect('run next', 'No');
        Observer.Expect('run no', 'A1');
        Observer.Expect('run log', '');
        Observer.Expect('edit log open', 'agcr A1;');
        Observer.Expect('edit first', 'Yes');
        Observer.Expect('edit next', 'No');
        Observer.Expect('edit no', 'A1');
        Observer.Expect('edit log', '');
        Observer.Expect('rows', '1:A1,');
        Observer.Verify();
    end;

    // Step 4: repeater Editable = a page global that is true, empty table: New, SetValue, Close.
    [Test]
    procedure NrEd_ListRepeaterVarTrue_NewInsert()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List Var";
    begin
        Seed('');
        L.SetEditable(true);
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewListVar(TP)));
        Observer.ObserveError('new');
        Observer.Observe('log new', L.Take());
        TP."No.".SetValue('N1');
        TP.Name.SetValue('x');
        Observer.Observe('log setvalue', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'open editable=Yes;new;agcr ;new;agcr ;');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('log new', 'new;agcr ;');
        Observer.Expect('log setvalue', 'oir;ins N1;');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '1:N1,');
        Observer.Verify();
    end;

    // Step 5: repeater Editable = a page global that is false, empty table.
    [Test]
    procedure NrEd_ListRepeaterVarFalse_Empty()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List Var";
    begin
        Seed('');
        L.SetEditable(false);
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        Observer.Observe('first', Format(TP.First()));
        ClearLastError();
        Observer.Observe('new ok', Format(TryNewListVar(TP)));
        Observer.ObserveError('new');
        Observer.Observe('log new', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'open editable=No;new;agcr ;');
        Observer.Expect('first', 'No');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('log new', 'new;agcr ;');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '0:');
        Observer.Verify();
    end;

    // Step 6: repeater Editable = a page global that is false, one row: Next past the last row.
    [Test]
    procedure NrEd_ListRepeaterVarFalse_NextPastLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List Var";
    begin
        Seed('A1');
        L.SetEditable(false);
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('no', TP."No.".Value());
        Observer.Observe('log', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'open editable=No;agcr A1;');
        Observer.Expect('first', 'Yes');
        Observer.Expect('next', 'No');
        Observer.Expect('no', 'A1');
        Observer.Expect('log', '');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '1:A1,');
        Observer.Verify();
    end;

    // Step 6 with the global true, one row (the neighbour that should land on the line).
    [Test]
    procedure NrEd_ListRepeaterVarTrue_NextPastLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr List Var";
    begin
        Seed('A1');
        L.SetEditable(true);
        TP.OpenEdit();
        Observer.Observe('log open', L.Take());
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('no', TP."No.".Value());
        Observer.Observe('log', L.Take());
        TP.Close();
        Observer.Observe('log close', L.Take());
        Observer.Observe('rows', RowKeys());
        Observer.Expect('log open', 'open editable=Yes;agcr A1;');
        Observer.Expect('first', 'Yes');
        Observer.Expect('next', 'Yes');
        Observer.Expect('no', '');
        Observer.Expect('log', 'new;agcr ;');
        Observer.Expect('log close', '');
        Observer.Expect('rows', '1:A1,');
        Observer.Verify();
    end;

    // Step 7: repeater Editable = Rec.Flag; last row Flag false, then last row Flag true.
    [Test]
    procedure NrEd_ListRepeaterRowExpr()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y42 Nr Row";
        TP: TestPage "LT Y42 Nr List Row Expr";
        TP2: TestPage "LT Y42 Nr List Row Expr";
    begin
        Seed('A1,A2');
        Row.Get('A1');
        Row.Flag := true;
        Row.Modify();
        TP.OpenEdit();
        L.Take();
        Observer.Observe('last flag false: last', Format(TP.Last()));
        Observer.Observe('last flag false: next', Format(TP.Next()));
        Observer.Observe('last flag false: no', TP."No.".Value());
        Observer.Observe('last flag false: log', L.Take());
        TP.Close();
        Row.Get('A1');
        Row.Flag := false;
        Row.Modify();
        Row.Get('A2');
        Row.Flag := true;
        Row.Modify();
        TP2.OpenEdit();
        L.Take();
        Observer.Observe('last flag true: last', Format(TP2.Last()));
        Observer.Observe('last flag true: next', Format(TP2.Next()));
        Observer.Observe('last flag true: no', TP2."No.".Value());
        Observer.Observe('last flag true: log', L.Take());
        TP2.Close();
        Observer.Observe('rows', RowKeys());
        Observer.Expect('last flag false: last', 'Yes');
        Observer.Expect('last flag false: next', 'No');
        Observer.Expect('last flag false: no', 'A2');
        Observer.Expect('last flag false: log', 'new;agcr ;agcr A2;');
        Observer.Expect('last flag true: last', 'Yes');
        Observer.Expect('last flag true: next', 'Yes');
        Observer.Expect('last flag true: no', 'A2');
        Observer.Expect('last flag true: log', 'agcr A2;new;agcr ;agcr A2;');
        Observer.Expect('rows', '2:A1,A2,');
        Observer.Verify();
    end;

    // Step 8: a ListPart whose repeater says Editable = false, on an editable card.
    [Test]
    procedure NrEd_PartRepeaterFalse()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Nr Card";
    begin
        Seed('A1');
        TP.OpenEdit();
        Observer.Observe('first', Format(TP.LPF.First()));
        Observer.Observe('no first', TP.LPF."No.".Value());
        Observer.Observe('next', Format(TP.LPF.Next()));
        Observer.Observe('no next', TP.LPF."No.".Value());
        TP.Close();
        Observer.Observe('rows', RowKeys());
        Observer.Expect('first', 'Yes');
        Observer.Expect('no first', 'A1');
        Observer.Expect('next', 'No');
        Observer.Expect('no next', 'A1');
        Observer.Expect('rows', '1:A1,');
        Observer.Verify();
    end;
}
