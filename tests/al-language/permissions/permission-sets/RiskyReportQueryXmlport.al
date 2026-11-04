// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: Permissions on report, query, xmlport; InherentPermissions on query and xmlport/report.

table 70460 "LT P116 Rq Src"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70461 "LT P116 Rq Target"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

permissionset 70462 "LT P116 Rq Set"
{
    Assignable = true;
    Permissions = tabledata "LT P116 Rq Src" = R;
}

report 70463 "LT P116 Rpt Perms"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    Permissions = tabledata "LT P116 Rq Target" = i;

    trigger OnPreReport()
    var
        Target: Record "LT P116 Rq Target";
    begin
        Target."Entry No." := 1;
        Target.Insert();
    end;
}

report 70464 "LT P116 Rpt No Perms"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        Target: Record "LT P116 Rq Target";
    begin
        Target."Entry No." := 1;
        Target.Insert();
    end;
}

query 70465 "LT P116 Qry Perms"
{
    QueryType = Normal;
    Permissions = tabledata "LT P116 Rq Src" = r;

    elements
    {
        dataitem(Src; "LT P116 Rq Src")
        {
            column(EntryNo; "Entry No.") { }
        }
    }
}

xmlport 70466 "LT P116 Xml Perms"
{
    Direction = Export;
    Format = Xml;
    Permissions = tabledata "LT P116 Rq Src" = r;

    schema
    {
        textelement(Root)
        {
            tableelement(Src; "LT P116 Rq Src")
            {
                fieldelement(EntryNo; Src."Entry No.") { }
            }
        }
    }
}

codeunit 70467 "LT P116 Rpt Qry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'LT P116 Rq Set', Locked = true;

    [Test]
    procedure P116_ReportWithPermissions()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT P116 Rq Target";
        WasStarted: Boolean;
    begin
        Target.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        asserterror Report.Run(Report::"LT P116 Rpt Perms");
        Observer.ObserveError('run');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('run|text', 'Sorry, the current permissions prevented the action. (TableData 70461 LT P116 Rq Target IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('run|code', 'DB:ClientInsertDenied');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_ReportWithoutPermissions()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT P116 Rq Target";
        WasStarted: Boolean;
    begin
        Target.DeleteAll();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        asserterror Report.Run(Report::"LT P116 Rpt No Perms");
        Observer.ObserveError('run');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('run|text', 'Sorry, the current permissions prevented the action. (TableData 70461 LT P116 Rq Target Insert: AL Language Coverage Tests)');
        Observer.Expect('run|code', 'DB:ClientInsertDenied');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_QueryWithPermissions()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Src: Record "LT P116 Rq Src";
        Qry: Query "LT P116 Qry Perms";
        WasStarted: Boolean;
        N: Integer;
    begin
        Src.DeleteAll();
        Src."Entry No." := 1;
        Src.Insert();
        Src."Entry No." := 2;
        Src.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(SetTok);
        Qry.Open();
        while Qry.Read() do
            N += 1;
        Qry.Close();
        Observer.Observe('rows', Format(N));
        RestoreMock(Mock, WasStarted);
        Observer.Expect('rows', '2');
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
