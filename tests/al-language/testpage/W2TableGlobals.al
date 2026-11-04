// Probe: the table's global variables on a page's Rec. An insert or modify the page performs without a field validation before it, and the validations the client runs to stamp filter values on a new row.
// Settles: md:613 (insert of a draft row, modify after an action changed Rec, which globals OnInsert / OnModify see), md:614 (validation run for a filter-stamped default: counter before and after).

table 68728 "W2 Glob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Category; Text[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "W2 Glob Log";
            begin
                Log.Add('Category.OnValidate(counter_before=' + Format(Counter) + ')');
                Counter += 10;
            end;
        }
        field(3; Payload; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "W2 Glob Log";
            begin
                Log.Add('Payload.OnValidate(counter_before=' + Format(Counter) + ')');
                Counter += 1;
            end;
        }
        field(4; SeenInsert; Text[40]) { }
        field(5; SeenModify; Text[40]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    var
        Counter: Integer;

    trigger OnInsert()
    var
        Log: Codeunit "W2 Glob Log";
    begin
        SeenInsert := 'counter=' + Format(Counter);
        Log.Add('OnInsert(counter=' + Format(Counter) + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "W2 Glob Log";
    begin
        SeenModify := 'counter=' + Format(Counter);
        Log.Add('OnModify(counter=' + Format(Counter) + ')');
    end;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

codeunit 68729 "W2 Glob Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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

page 68730 "W2 Glob Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Glob Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Category; Rec.Category) { ApplicationArea = All; }
            field(Payload; Rec.Payload) { ApplicationArea = All; }
            field(SeenInsert; Rec.SeenInsert) { ApplicationArea = All; }
            field(SeenModify; Rec.SeenModify) { ApplicationArea = All; }
            field(LastCount; LastCount) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BumpRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Bump();
                    LastCount := Rec.GetCounter();
                end;
            }
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LastCount := Rec.GetCounter();
                end;
            }
            // Changes Rec without Validate and without Modify.
            action(ChangeRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Bump();
                    Rec.Payload := 77;
                    LastCount := Rec.GetCounter();
                end;
            }
            // Changes Rec and saves it itself.
            action(ChangeAndModifyRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Bump();
                    Rec.Payload := 88;
                    Rec.Modify();
                    LastCount := Rec.GetCounter();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if NumberOnNew then
            Rec."No." := 'AUTO';
    end;

    var
        LastCount: Integer;
        NumberOnNew: Boolean;

    trigger OnInit()
    begin
        NumberOnNew := true;
    end;
}

// New rows get Category = 'stamp' from the filter.
page 68732 "W2 Glob Filter Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Glob Row";
    SourceTableView = where(Category = const('stamp'));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Category; Rec.Category) { ApplicationArea = All; }
            field(Payload; Rec.Payload) { ApplicationArea = All; }
            field(SeenInsert; Rec.SeenInsert) { ApplicationArea = All; }
            field(LastCount; LastCount) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BumpRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Bump();
                    LastCount := Rec.GetCounter();
                end;
            }
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    LastCount := Rec.GetCounter();
                end;
            }
        }
    }

    var
        LastCount: Integer;
}

codeunit 68731 "W2 Glob Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W2 Glob Row";
        Log: Codeunit "W2 Glob Log";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Category := 'stamp';
        Row.Insert();
        Row."No." := 'B';
        Row.Category := 'other';
        Row.Insert();
        Log.Take();
    end;

    // ---- md:613 ----

    [Test]
    procedure Insert_DraftRowAfterActions_NoValidation()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Card";
    begin
        Seed();
        Pg.OpenNew();
        Observer.Observe('open_log', Log.Take());
        Observer.Observe('number_from_OnNewRecord', Pg."No.".Value());
        Pg.BumpRec.Invoke();
        Pg.BumpRec.Invoke();
        Observer.Observe('counter_after_two_bumps', Pg.LastCount.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Observer.Observe('row_exists', Format(Row.Get('AUTO')));
        Observer.Observe('seen_by_OnInsert', Row.SeenInsert);
        Observer.Expect('open_log', '');
        Observer.Expect('number_from_OnNewRecord', 'AUTO');
        Observer.Expect('counter_after_two_bumps', '2');
        Observer.Expect('close_log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Expect('seen_by_OnInsert', '');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DraftRowNoActions()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Card";
    begin
        Seed();
        Pg.OpenNew();
        Log.Take();
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Observer.Observe('row_exists', Format(Row.Get('AUTO')));
        Observer.Observe('seen_by_OnInsert', Row.SeenInsert);
        Observer.Expect('close_log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Expect('seen_by_OnInsert', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterActionChangedRec_NoModifyCall()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey('B');
        Pg.BumpRec.Invoke();
        Pg.ChangeRec.Invoke();
        Observer.Observe('counter_after_change', Pg.LastCount.Value());
        Observer.Observe('payload_shown', Pg.Payload.Value());
        Log.Take();
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Row.Get('B');
        Observer.Observe('payload_saved', Format(Row.Payload));
        Observer.Observe('seen_by_OnModify', Row.SeenModify);
        Observer.Expect('counter_after_change', '2');
        Observer.Expect('payload_shown', '77');
        Observer.Expect('close_log', '');
        Observer.Expect('payload_saved', '77');
        Observer.Expect('seen_by_OnModify', 'counter=0');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ActionCallsModifyItself()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey('B');
        Pg.BumpRec.Invoke();
        Log.Take();
        Pg.ChangeAndModifyRec.Invoke();
        Observer.Observe('action_log', Log.Take());
        Observer.Observe('counter_after_change', Pg.LastCount.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Row.Get('B');
        Observer.Observe('payload_saved', Format(Row.Payload));
        Observer.Observe('seen_by_OnModify', Row.SeenModify);
        Observer.Expect('action_log', '');
        Observer.Expect('counter_after_change', '2');
        Observer.Expect('close_log', '');
        Observer.Expect('payload_saved', '88');
        Observer.Expect('seen_by_OnModify', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterActionThenMoveToAnotherRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey('B');
        Pg.BumpRec.Invoke();
        Pg.ChangeRec.Invoke();
        Log.Take();
        Pg.GoToKey('A');
        Observer.Observe('move_log', Log.Take());
        Pg.Close();
        Row.Get('B');
        Observer.Observe('payload_saved', Format(Row.Payload));
        Observer.Observe('seen_by_OnModify', Row.SeenModify);
        Observer.Expect('move_log', '');
        Observer.Expect('payload_saved', '77');
        Observer.Expect('seen_by_OnModify', 'counter=0');
        Observer.Verify();
    end;

    // ---- md:614 ----

    [Test]
    procedure FilterStamp_OpenNewOnFilteredPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Pg: TestPage "W2 Glob Filter Card";
    begin
        Seed();
        Pg.OpenNew();
        Observer.Observe('open_log', Log.Take());
        Observer.Observe('category_shown', Pg.Category.Value());
        Pg.ReadRec.Invoke();
        Observer.Observe('counter_after_open', Pg.LastCount.Value());
        Pg.BumpRec.Invoke();
        Observer.Observe('counter_after_bump', Pg.LastCount.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Observer.Expect('open_log', '');
        Observer.Expect('category_shown', '');
        Observer.Expect('counter_after_open', '0');
        Observer.Expect('counter_after_bump', '1');
        Observer.Expect('close_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure FilterStamp_ThenFieldValidation()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Filter Card";
    begin
        Seed();
        Pg.OpenNew();
        Pg."No.".SetValue('NEW');
        Log.Take();
        Pg.BumpRec.Invoke();
        Pg.Payload.SetValue(5);
        Observer.Observe('payload_validate_log', Log.Take());
        Pg.ReadRec.Invoke();
        Observer.Observe('counter_after_validate', Pg.LastCount.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Row.Get('NEW');
        Observer.Observe('category_saved', Row.Category);
        Observer.Observe('seen_by_OnInsert', Row.SeenInsert);
        Observer.Expect('payload_validate_log', 'OnInsert(counter=0);Payload.OnValidate(counter_before=0);');
        Observer.Expect('counter_after_validate', '0');
        Observer.Expect('close_log', 'OnModify(counter=0);');
        Observer.Expect('category_saved', '');
        Observer.Expect('seen_by_OnInsert', 'counter=0');
        Observer.Verify();
    end;

    [Test]
    procedure FilterStamp_BumpBeforeAnyValidation_ThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Glob Log";
        Row: Record "W2 Glob Row";
        Pg: TestPage "W2 Glob Filter Card";
    begin
        Seed();
        Pg.OpenNew();
        Log.Take();
        Pg.BumpRec.Invoke();
        Pg."No.".SetValue('NEW');
        Observer.Observe('key_validate_log', Log.Take());
        Pg.ReadRec.Invoke();
        Observer.Observe('counter_after_key', Pg.LastCount.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Row.Get('NEW');
        Observer.Observe('seen_by_OnInsert', Row.SeenInsert);
        Observer.Expect('key_validate_log', '');
        Observer.Expect('counter_after_key', '0');
        Observer.Expect('close_log', 'OnInsert(counter=0);');
        Observer.Expect('seen_by_OnInsert', 'counter=0');
        Observer.Verify();
    end;
}
