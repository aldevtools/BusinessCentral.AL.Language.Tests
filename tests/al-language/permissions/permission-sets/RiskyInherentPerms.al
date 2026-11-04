// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: table-level InherentPermissions.

table 70445 "LT P116 Inh RIMD"
{
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70446 "LT P116 Inh R"
{
    InherentPermissions = R;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70447 "LT P116 Inh None"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

permissionset 70448 "LT P116 Inh Set"
{
    Assignable = true;
    Permissions = tabledata "LT P116 Inh None" = R;
}

codeunit 70449 "LT P116 Inherent Perms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'LT P116 Inh Set', Locked = true;

    [Test]
    procedure P116_InherentRIMD()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Inh RIMD";
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
        Row.DeleteAll();
        Observer.Observe('deleteall', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('count after', Format(Row.Count()));
        Observer.Expect('insert', 'no error');
        Observer.Expect('count', '1');
        Observer.Expect('count', 'no error');
        Observer.Expect('deleteall', 'no error');
        Observer.Expect('count after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_InherentR()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Inh R";
        WasStarted: Boolean;
    begin
        Row.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Row."Entry No." := 1;
        asserterror Row.Insert();
        Observer.ObserveError('insert');
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('count', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 70446 LT P116 Inh R Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('count', '0');
        Observer.Expect('count', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P116_NoInherent()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Inh None";
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
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 70447 LT P116 Inh None Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ClientInsertDenied');
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
