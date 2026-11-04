// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 658 (follow-up of writer BA's permissions/lt-ba-testpermissions, which runs without Tests-TestLibraries):
// what each TestPermissions value does to the session's permissions when Microsoft's Tests-TestLibraries app is installed,
// as in a Windows container made with BcContainerHelper. Before each test method, codeunit 130453 "ALTestRunner Reset
// Environment" (Test Runner app) runs 130301 "Reset State Before Test Run" if it is installed, and for a method whose
// TestPermissions is not Disabled also 130302 "Set State Test Run", which lowers the session to the permission set
// 'D365 Full Access' through the Permissions Mock app (130302 -> 132218 "Permission Test Catalog" -> 132217 "Library - Lower
// Permissions"). Without Tests-TestLibraries neither codeunit exists and nothing changes.
// This file holds the shared helper: a table of this app that no permission set grants, and the observations every variant
// codeunit makes. The test codeunits are in BiTp*.al next to this file, one TestPermissions variant per codeunit. Every test
// method declares [HandlerFunctions] and raises one Message, so the bc-linux CI runner routes the codeunit to Microsoft's
// test runner (page 130455, runner 130450) on every BC version; the observation 'runner' shows the runner codeunits on the stack.
// BC versions: 27, 28, 29
table 81550 "LT BI TP Row"
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

codeunit 81551 "LT BI TP Probe"
{
    // The effective permissions of the session, read without writing anything:
    // own = table 81550 of this app (no permission set of the app grants it), cust = Customer (Base Application),
    // gl = G/L Entry (Base Application), ac = Access Control (system table).
    procedure ObservePermissions(var Observer: Codeunit "Probe Observer")
    var
        Own: Record "LT BI TP Row";
        Cust: Record Customer;
        GLEntry: Record "G/L Entry";
        AccessControl: Record "Access Control";
    begin
        Observer.Observe('own_r', Format(Own.ReadPermission()));
        Observer.Observe('own_w', Format(Own.WritePermission()));
        Observer.Observe('cust_r', Format(Cust.ReadPermission()));
        Observer.Observe('cust_w', Format(Cust.WritePermission()));
        Observer.Observe('gl_r', Format(GLEntry.ReadPermission()));
        Observer.Observe('gl_w', Format(GLEntry.WritePermission()));
        Observer.Observe('ac_r', Format(AccessControl.ReadPermission()));
        Observer.Observe('ac_w', Format(AccessControl.WritePermission()));
        Observer.Observe('runner', RunnerFrames());
    end;

    // Inserts a row of table 81550 and then fails on purpose, so the caller's asserterror always catches an error and
    // rolls the insert back: either the permission error of the Insert or 'LT BI inserted'.
    procedure InsertThenFail()
    var
        Own: Record "LT BI TP Row";
    begin
        Own."Entry No." := 1;
        Own.Note := 'LT BI';
        Own.Insert();
        Error('LT BI inserted');
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
