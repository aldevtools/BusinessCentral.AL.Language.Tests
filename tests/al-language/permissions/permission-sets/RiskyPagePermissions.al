// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: page Permissions property; a TestPage action inserts into a table the user has no grant on.

table 70454 "LT P116 Pg Target"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70455 "LT P116 Pg Open"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

permissionset 70456 "LT P116 Pg Set"
{
    Assignable = true;
    Permissions = tabledata "LT P116 Pg Open" = RIMD;
}

page 70457 "LT P116 Pg With Perms"
{
    PageType = Card;
    SourceTable = "LT P116 Pg Open";
    ApplicationArea = All;
    UsageCategory = None;
    Permissions = tabledata "LT P116 Pg Target" = i;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }
    actions
    {
        area(Processing)
        {
            action(WriteTarget)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Target: Record "LT P116 Pg Target";
                begin
                    Target."Entry No." := 1;
                    Target.Insert();
                end;
            }
        }
    }
}

page 70458 "LT P116 Pg No Perms"
{
    PageType = Card;
    SourceTable = "LT P116 Pg Open";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }
    actions
    {
        area(Processing)
        {
            action(WriteTarget)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Target: Record "LT P116 Pg Target";
                begin
                    Target."Entry No." := 1;
                    Target.Insert();
                end;
            }
        }
    }
}

codeunit 70459 "LT P116 Page Perms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'LT P116 Pg Set', Locked = true;

    [Test]
    procedure P116_PageWithPermissions()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT P116 Pg Target";
        Open: Record "LT P116 Pg Open";
        Page: TestPage "LT P116 Pg With Perms";
        WasStarted: Boolean;
    begin
        Target.DeleteAll();
        Open.DeleteAll();
        Open."Entry No." := 1;
        Open.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Page.OpenView();
        asserterror Page.WriteTarget.Invoke();
        Observer.ObserveError('invoke');
        Page.Close();
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('invoke|text', 'Sorry, the current permissions prevented the action. (TableData 70454 LT P116 Pg Target IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('invoke|code', 'TestWrapped:Permission');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_PageWithoutPermissions()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT P116 Pg Target";
        Open: Record "LT P116 Pg Open";
        Page: TestPage "LT P116 Pg No Perms";
        WasStarted: Boolean;
    begin
        Target.DeleteAll();
        Open.DeleteAll();
        Open."Entry No." := 1;
        Open.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Page.OpenView();
        asserterror Page.WriteTarget.Invoke();
        Observer.ObserveError('invoke');
        Page.Close();
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('invoke|text', 'Sorry, the current permissions prevented the action. (TableData 70454 LT P116 Pg Target Insert: AL Language Coverage Tests)');
        Observer.Expect('invoke|code', 'TestWrapped:Permission');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    local procedure StartMock(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
