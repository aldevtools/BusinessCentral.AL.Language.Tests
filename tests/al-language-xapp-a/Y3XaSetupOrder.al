// Cross-app subscriber order probe (corpus writer Y3): subscribers of Base Application's GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup
// in partner apps whose app ids lie on both sides of Microsoft's Tests-TestLibraries (5d86850b-..., codeunit 130011 "Backup Management", which
// assigns all four flags true for a table id in 1..99999 when a company is open). XApp C (0df0fadc-..., lower app id, codeunit 61153) and XApp A
// (cd6a4292-..., higher app id, codeunit 61137) log the flags they receive for table 61152 only, with a sequence number. Receiving Yes means the
// subscriber ran after 130011. Tests: tests/al-language-testlibraries/lt-y3-setup-order/Y3SetupOrderTests.al (the CI job with Tests-TestLibraries).

table 61139 "LT Y3 Order Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Entry; Text[100]) { }
        field(2; Detail; Text[250]) { }
    }

    keys { key(PK; Entry) { Clustered = true; } }
}

codeunit 61109 "LT Y3 XA Order Log Mgt"
{
    procedure Add(Who: Text; OnDatabaseInsert: Boolean; OnDatabaseModify: Boolean; OnDatabaseDelete: Boolean; OnDatabaseRename: Boolean)
    var
        L: Record "LT Y3 Order Log";
        Seq: Integer;
    begin
        Seq := L.Count() + 1;
        L.Entry := CopyStr(Who, 1, MaxStrLen(L.Entry));
        L.Detail := 'seq=' + Format(Seq) + ' in=' + Format(OnDatabaseInsert) + Format(OnDatabaseModify) + Format(OnDatabaseDelete) + Format(OnDatabaseRename);
        if L.Insert() then;
    end;
}

codeunit 61137 "LT Y3 XA Setup Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Codeunit "LT Y3 XA Order Log Mgt";
    begin
        if TableId <> 61152 then
            exit;
        Log.Add('A', OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;
}
