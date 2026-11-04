// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73771, page 73772
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73771 "LT P165 Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Payload; Integer) { }
        field(3; Seen; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    var
        Counter: Integer;

    trigger OnInsert()
    begin
        Seen := 'I' + Format(Counter);
    end;

    trigger OnModify()
    begin
        Seen := 'M' + Format(Counter) + '/' + Format(xRec.GetCounter());
    end;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

page 73772 "LT P165 Page Row Card"
{
    PageType = Card;
    SourceTable = "LT P165 Page Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Payload; Rec.Payload) { ApplicationArea = All; }
                field(Seen; Rec.Seen) { ApplicationArea = All; }
                field(LastCount; LastCount) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetKeyAndBump)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec."No." := 'N1';
                    LastCount := Rec.Bump();
                    Rec.Bump();
                end;
            }
            action(BumpOnly)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    LastCount := Rec.Bump();
                    Rec.Bump();
                end;
            }
            action(BumpAndModify)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Bump();
                    Rec.Bump();
                    Rec.Payload := 7;
                    Rec.Modify(true);
                end;
            }
            action(BumpAndInsert)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec."No." := 'N2';
                    Rec.Bump();
                    Rec.Insert(true);
                end;
            }
            action(ReadCount)
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

codeunit 73770 "LT P165 Page Globals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P165 Page Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
    end;

    [Test]
    procedure Card_ActionModifiesRec_OnModifySeesWhichGlobals()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpAndModify.Invoke();
        Card.ReadCount.Invoke();
        Observer.Observe('counter after the action', Card.LastCount.Value());
        Card.Close();
        Row.Get('A');
        Observer.Observe('row Seen', Row.Seen);
        Observer.Observe('row Payload', Format(Row.Payload));
        Observer.Expect('counter after the action', '2');
        Observer.Expect('row Seen', 'M2/0');
        Observer.Expect('row Payload', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ActionInsertsRec_OnInsertSeesWhichGlobals()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.BumpAndInsert.Invoke();
        Card.ReadCount.Invoke();
        Observer.Observe('counter after the action', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        if Row.Get('N2') then
            Observer.Observe('row N2 Seen', Row.Seen);
        Observer.Expect('counter after the action', '1');
        Observer.Expect('row count', '2');
        Observer.Expect('row N2 Seen', 'I1');
        Observer.Verify();
    end;

    [Test]
    procedure Card_NewDraft_KeySetByActionThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.SetKeyAndBump.Invoke();
        Card.ReadCount.Invoke();
        Observer.Observe('counter after the actions', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        Observer.Observe('N1 exists', Format(Row.Get('N1')));
        if Row.Get('N1') then
            Observer.Observe('N1 Seen', Row.Seen);
        Observer.Expect('counter after the actions', '0');
        Observer.Expect('row count', '2');
        Observer.Expect('N1 exists', 'Yes');
        Observer.Expect('N1 Seen', 'I0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_ActionBumpsOnly_RowIsNotWritten()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('A');
        Card.BumpOnly.Invoke();
        Card.ReadCount.Invoke();
        Observer.Observe('counter after the actions', Card.LastCount.Value());
        Card.Close();
        Row.Get('A');
        Observer.Observe('Seen of the row', Row.Seen);
        Observer.Expect('counter after the actions', '2');
        Observer.Expect('Seen of the row', '');
        Observer.Verify();
    end;

    // Writer QG (runtime PR 380, lane-old-fails): Card_NewDraft_KeySetByActionThenClose shows that after an action set the key of a new
    // draft, the next action sees fresh table globals (Counter 0) and the row is inserted with Seen I0. These pin when the row is stored
    // (right after the action, at a field read, at the next action, at Close) and when the globals are fresh.
    [Test]
    procedure QG_NewDraft_KeySetByAction_WhenStored()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.SetKeyAndBump.Invoke();
        Observer.Observe('stored after the action', Format(Row.Get('N1')));
        Observer.Observe('LastCount read', Card.LastCount.Value());
        Observer.Observe('No. read', Card."No.".Value());
        Observer.Observe('Seen read', Card.Seen.Value());
        Observer.Observe('stored after the reads', Format(Row.Get('N1')));
        Card.ReadCount.Invoke();
        Observer.Observe('stored after the second action', Format(Row.Get('N1')));
        if Row.Get('N1') then
            Observer.Observe('Seen after the second action', Row.Seen);
        Observer.Observe('LastCount after the second action', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        if Row.Get('N1') then
            Observer.Observe('N1 Seen', Row.Seen);
        Observer.Expect('stored after the action', 'Yes');
        Observer.Expect('LastCount read', '1');
        Observer.Expect('No. read', 'N1');
        Observer.Expect('Seen read', 'I0');
        Observer.Expect('stored after the reads', 'Yes');
        Observer.Expect('stored after the second action', 'Yes');
        Observer.Expect('Seen after the second action', 'I0');
        Observer.Expect('LastCount after the second action', '0');
        Observer.Expect('row count', '2');
        Observer.Expect('N1 Seen', 'I0');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NewDraft_KeySetByAction_ThenCloseAtOnce()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.SetKeyAndBump.Invoke();
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        Observer.Observe('N1 exists', Format(Row.Get('N1')));
        if Row.Get('N1') then
            Observer.Observe('N1 Seen', Row.Seen);
        Observer.Expect('row count', '2');
        Observer.Expect('N1 exists', 'Yes');
        Observer.Expect('N1 Seen', 'I0');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NewDraft_KeySetByAction_ThenBumpAction()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.SetKeyAndBump.Invoke();
        Card.BumpOnly.Invoke();
        Observer.Observe('LastCount after BumpOnly', Card.LastCount.Value());
        Card.ReadCount.Invoke();
        Observer.Observe('LastCount after ReadCount', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        if Row.Get('N1') then
            Observer.Observe('N1 Seen', Row.Seen);
        Observer.Expect('LastCount after BumpOnly', '1');
        Observer.Expect('LastCount after ReadCount', '2');
        Observer.Expect('row count', '2');
        Observer.Expect('N1 Seen', 'I0');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NewDraft_KeyTyped_ThenBumpAction()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('N3');
        Observer.Observe('stored after the SetValue', Format(Row.Get('N3')));
        Card.BumpOnly.Invoke();
        Observer.Observe('stored after BumpOnly', Format(Row.Get('N3')));
        if Row.Get('N3') then
            Observer.Observe('Seen after BumpOnly', Row.Seen);
        Card.ReadCount.Invoke();
        Observer.Observe('LastCount after ReadCount', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        if Row.Get('N3') then
            Observer.Observe('N3 Seen', Row.Seen);
        Observer.Expect('stored after the SetValue', 'No');
        Observer.Expect('stored after BumpOnly', 'Yes');
        Observer.Expect('Seen after BumpOnly', 'I0');
        Observer.Expect('LastCount after ReadCount', '2');
        Observer.Expect('row count', '2');
        Observer.Expect('N3 Seen', 'I0');
        Observer.Verify();
    end;

    [Test]
    procedure QG_NewDraft_NoKey_BumpAction_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P165 Page Row Card";
        Row: Record "LT P165 Page Row";
    begin
        Seed();
        Card.OpenNew();
        Card.BumpOnly.Invoke();
        Observer.Observe('LastCount after BumpOnly', Card.LastCount.Value());
        Card.ReadCount.Invoke();
        Observer.Observe('LastCount after ReadCount', Card.LastCount.Value());
        Card.Close();
        Observer.Observe('row count', Format(Row.Count()));
        Observer.Expect('LastCount after BumpOnly', '1');
        Observer.Expect('LastCount after ReadCount', '2');
        Observer.Expect('row count', '1');
        Observer.Verify();
    end;
}
