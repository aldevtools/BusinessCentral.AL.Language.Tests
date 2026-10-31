// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y19PermObjects.al; Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P8 (stage 1), writer Y19: how long a mock assignment lives.
//   Codeunit 91955, method 1 starts the mock and sets "LT Y19 R" (no insert on the row table) and never stops it; method 2 (same codeunit)
//   inserts into the row table; method 3 sets the narrow set inside asserterror and inserts after the rollback, then cleans up.
//   Codeunit 91956 (the next test codeunit of the run): method 1 inserts before anything else, then method 2 cleans up.
//   Each insert runs inside asserterror and ends with the own error 'LT Y19 ok', so nothing stays.
//   Without Tests-TestLibraries (this app): the runner does not touch the mock between methods or codeunits.
// BC versions: 27, 28, 29

codeunit 91955 "LT Y19 Mock Lifetime A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y19_P8_A1_SetAndLeave()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        Mock.Start();
        Mock.Set('LT Y19 R');
        asserterror InsertRow(1);
        Observer.ObserveError('insert_same_method');
        Observer.Observe('is_started', Format(Mock.IsStarted()));
        Observer.Finish();
    end;

    [Test]
    procedure Y19_P8_A2_NextMethod()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        Observer.Observe('is_started_new_variable', Format(Mock.IsStarted()));
        asserterror InsertRow(2);
        Observer.ObserveError('insert_next_method');
        Observer.Finish();
    end;

    [Test]
    procedure Y19_P8_A3_SetInsideAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        if Mock.IsStarted() then
            Mock.ClearAssignments()
        else
            Mock.Start();
        asserterror InsertRow(3);
        Observer.ObserveError('insert_after_clear');
        asserterror SetThenFail(Mock);
        Observer.ObserveError('set_inside_asserterror');
        asserterror InsertRow(4);
        Observer.ObserveError('insert_after_rollback');
        Mock.ClearAssignments();
        Mock.Stop();
        Observer.Observe('is_started_after_stop', Format(Mock.IsStarted()));
        // Leave the narrow set for the next test codeunit (91956 removes it).
        Mock.Start();
        Mock.Set('LT Y19 R');
        Observer.Finish();
    end;

    local procedure SetThenFail(var Mock: Codeunit "Permissions Mock")
    begin
        Mock.Set('LT Y19 R');
        Error('LT Y19 set done');
    end;

    local procedure InsertRow(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := 91955 + NewId;
        Row.Insert();
        Error('LT Y19 ok %1', NewId);
    end;
}

codeunit 91956 "LT Y19 Mock Lifetime B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y19_P8_B1_NextCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        Observer.Observe('is_started_next_codeunit', Format(Mock.IsStarted()));
        asserterror InsertRow(1);
        Observer.ObserveError('insert_next_codeunit');
        Observer.Finish();
    end;

    [Test]
    procedure Y19_P8_B2_CleanUp()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
    begin
        if not Mock.IsStarted() then
            Mock.Start();
        Mock.ClearAssignments();
        Mock.Stop();
        asserterror InsertRow(2);
        Observer.ObserveError('insert_after_cleanup');
        Observer.Finish();
    end;

    local procedure InsertRow(NewId: Integer)
    var
        Row: Record "LT Y19 Row";
    begin
        Row.Id := 91960 + NewId;
        Row.Insert();
        Error('LT Y19 ok %1', NewId);
    end;
}
