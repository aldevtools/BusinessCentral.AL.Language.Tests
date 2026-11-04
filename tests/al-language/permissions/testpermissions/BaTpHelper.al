// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 658: which TestPermissions value applies to a test that declares none, and what each value does to the
// session's effective permissions under Microsoft's test runner (the runner the corpus CI uses).
// This file holds the shared helper: a table of this app that no permission set grants, and the observations every
// variant codeunit makes. The test codeunits are in BaTp*.al next to this file, one TestPermissions variant per codeunit.
// Every test method of those codeunits declares [HandlerFunctions] and raises one Message, so the bc-linux CI runner
// routes the codeunit to Microsoft's test runner codeunit (page 130455, runner 130450) on every BC version, never to the
// TestRunnerHub (which runs no test runner codeunit). The observation 'runner' shows which runner codeunits are on the stack.
// BC versions: 27, 28, 29
table 80750 "LT BA TP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 80751 "LT BA TP Probe"
{
    // The effective permissions of the session, read without writing anything:
    // own = table 80750 of this app (no permission set of the app grants it), cust = Customer (Base Application),
    // ac = Access Control (system table).
    procedure ObservePermissions(var Observer: Codeunit "Probe Observer")
    var
        Own: Record "LT BA TP Row";
        Cust: Record Customer;
        AccessControl: Record "Access Control";
    begin
        Observer.Observe('own_r', Format(Own.ReadPermission()));
        Observer.Observe('own_w', Format(Own.WritePermission()));
        Observer.Observe('cust_r', Format(Cust.ReadPermission()));
        Observer.Observe('cust_w', Format(Cust.WritePermission()));
        Observer.Observe('ac_r', Format(AccessControl.ReadPermission()));
        Observer.Observe('ac_w', Format(AccessControl.WritePermission()));
        Observer.Observe('runner', RunnerFrames());
    end;

    // Inserts a row of table 80750 and then fails on purpose, so the caller's asserterror always catches an error and
    // rolls the insert back: either the permission error of the Insert or 'LT BA inserted'.
    procedure InsertThenFail()
    var
        Own: Record "LT BA TP Row";
    begin
        Own."Entry No." := 1;
        Own.Note := 'LT BA';
        Own.Insert();
        Error('LT BA inserted');
    end;

    // Which test runner codeunits are on the AL call stack of the running test.
    procedure RunnerFrames(): Text
    var
        Stack: Text;
        Ids: List of [Integer];
        Id: Integer;
        Result: Text;
    begin
        Stack := SessionInformation.Callstack();
        Ids.Add(130450);
        Ids.Add(130451);
        Ids.Add(130454);
        Ids.Add(99903);
        foreach Id in Ids do
            if Stack.Contains('(CodeUnit ' + Format(Id) + ')') then
                Result += Format(Id) + ',';
        if Result = '' then
            exit('none');
        exit(Result);
    end;
}
