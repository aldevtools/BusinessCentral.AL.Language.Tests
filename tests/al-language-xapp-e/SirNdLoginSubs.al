// Cross-app fixture E (al-runner issue 8696, login without a dependency): a subscriber of "System Initialization".OnAfterLogin
// that reaches the SingleInstance state of two apps it does NOT depend on:
// - XApp A (tests/al-language-xapp-a/SirNdXaTriggerState.al) through the platform: the first read of table 98032 and the
//   first read and the write of table 98033 make the platform ask GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup
//   (and, for the write, OnAfterOnDatabaseInsert or OnAfterOnDatabaseModify), which XApp A's SingleInstance codeunit subscribes to.
//   This is the shape of a partner login that writes a table and so runs the trigger setup subscriber of Microsoft's
//   Backup Management (codeunit 130011) without depending on Tests-TestLibraries.
// - XApp B (tests/al-language-xapp-b/SirNdXbEventState.al) through an integration event of the AL Internals Test Fixture.
// The writes use the return value forms, so a login never raises. The probe is tests/al-language/codeunits/SirLoginNoDep.al.
table 98032 "SIR ND Read Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 98033 "SIR ND Write Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Logins; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 98034 "SIR ND Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        ReadRow: Record "SIR ND Read Row";
        WriteRow: Record "SIR ND Write Row";
        Events: Codeunit "SIR ND Login Events";
    begin
        if ReadRow.IsEmpty() then;
        if WriteRow.Get(1) then begin
            WriteRow.Logins += 1;
            if WriteRow.Modify() then;
        end else begin
            WriteRow.Init();
            WriteRow.Id := 1;
            WriteRow.Logins := 1;
            if WriteRow.Insert() then;
        end;
        Events.Raise();
    end;
}
