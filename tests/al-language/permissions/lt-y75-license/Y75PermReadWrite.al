// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y24PermObjects.al (table 91936 "LT Y24 Row" and its permission sets); Y19PermObjects.al (the mock helper);
//   Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs issue 6756 (RecordRef.WritePermission and ReadPermission answered true under a set that grants only R). Y24PermReads.al (P19)
//   pins Record.ReadPermission/WritePermission for none, r, rimd, I, IM, IMD and RIMD, but not a direct R alone, not RecordRef, not
//   SetExactPermissionSet, and not an object whose Permissions property grants only r. This file adds them, full surface:
//   sets none, R, r, RI, RIM, I, IM, IMD, RIMD, rimd (direct and indirect), assigned with Set and with SetExactPermissionSet, asked through a
//   Record and a RecordRef, from the test and from codeunits whose Permissions property names the table (rimd; r).
// Shape (Y24PermReads.al): assign the set, read the two Booleans, clear the assignment.
// BC versions: 27, 28, 29

codeunit 94010 "LT Y75 Perm ReadWrite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Y19Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y75_RecordAndRecordRef_Set()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunAll(Observer, false);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y75_RecordAndRecordRef_SetExact()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunAll(Observer, true);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure RunAll(var Obs: Codeunit "Probe Observer"; Exact: Boolean)
    begin
        RunOne(Obs, Exact, 'none', 'LT Y24 None');
        RunOne(Obs, Exact, 'R', 'LT Y24 R');
        RunOne(Obs, Exact, 'ind_r', 'LT Y24 Ind R');
        RunOne(Obs, Exact, 'RI', 'LT Y75 RI');
        RunOne(Obs, Exact, 'RIM', 'LT Y75 RIM');
        RunOne(Obs, Exact, 'I', 'LT Y24 I');
        RunOne(Obs, Exact, 'IM', 'LT Y24 IM');
        RunOne(Obs, Exact, 'IMD', 'LT Y24 IMD');
        RunOne(Obs, Exact, 'RIMD', 'LT Y24 RIMD');
        RunOne(Obs, Exact, 'ind_rimd', 'LT Y24 Ind RIMD');
    end;

    local procedure RunOne(var Obs: Codeunit "Probe Observer"; Exact: Boolean; Tag: Text; SetName: Code[20])
    var
        Row: Record "LT Y24 Row";
        RecRef: RecordRef;
        ReaderRimd: Codeunit "LT Y75 Reader Rimd";
        ReaderR: Codeunit "LT Y75 Reader R";
    begin
        Mock.ClearAssignments();
        if Exact then
            Mock.SetExactPermissionSet(SetName)
        else
            Mock.Set(SetName);
        RecRef.Open(Database::"LT Y24 Row");
        Obs.Observe(Tag + '|record', Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
        Obs.Observe(Tag + '|recordref', Format(RecRef.ReadPermission()) + '/' + Format(RecRef.WritePermission()));
        Obs.Observe(Tag + '|object_rimd_record', ReaderRimd.AsRecord());
        Obs.Observe(Tag + '|object_rimd_recordref', ReaderRimd.AsRecordRef());
        Obs.Observe(Tag + '|object_r_record', ReaderR.AsRecord());
        Obs.Observe(Tag + '|object_r_recordref', ReaderR.AsRecordRef());
        RecRef.Close();
        Mock.ClearAssignments();
    end;
}

codeunit 94011 "LT Y75 Reader Rimd"
{
    Permissions = tabledata "LT Y24 Row" = rimd;

    procedure AsRecord(): Text
    var
        Row: Record "LT Y24 Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;

    procedure AsRecordRef(): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT Y24 Row");
        exit(Format(RecRef.ReadPermission()) + '/' + Format(RecRef.WritePermission()));
    end;
}

codeunit 94012 "LT Y75 Reader R"
{
    Permissions = tabledata "LT Y24 Row" = r;

    procedure AsRecord(): Text
    var
        Row: Record "LT Y24 Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;

    procedure AsRecordRef(): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT Y24 Row");
        exit(Format(RecRef.ReadPermission()) + '/' + Format(RecRef.WritePermission()));
    end;
}

permissionset 94013 "LT Y75 RI"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = RI;
}

permissionset 94014 "LT Y75 RIM"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = RIM;
}
