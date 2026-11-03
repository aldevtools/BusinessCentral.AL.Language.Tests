// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: table-level InherentEntitlements (and both inherent properties together).

table 70450 "LT P116 Inh Ent"
{
    InherentEntitlements = RIMD;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70451 "LT P116 Inh Both"
{
    InherentPermissions = RIMD;
    InherentEntitlements = RIMD;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

permissionset 70452 "LT P116 Ent Set"
{
    Assignable = true;
    Permissions = tabledata "LT P116 Inh Ent" = R;
}

codeunit 70453 "LT P116 Inherent Ents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'LT P116 Ent Set', Locked = true;

    [Test]
    procedure P116_InherentEntitlements()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Inh Ent";
        WasStarted: Boolean;
    begin
        Row.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Observer.Observe('count read granted', Format(Row.Count()));
        Row."Entry No." := 1;
        asserterror Row.Insert();
        Observer.ObserveError('insert');
        RestoreMock(Mock, WasStarted);
        Observer.Expect('count read granted', '0');
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 70450 LT P116 Inh Ent Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure P116_BothInherent()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Inh Both";
        WasStarted: Boolean;
    begin
        Row.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Row."Entry No." := 1;
        Row.Insert();
        Observer.Observe('insert', 'no error');
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('count', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Expect('insert', 'no error');
        Observer.Expect('count', '1');
        Observer.Expect('count', 'no error');
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
