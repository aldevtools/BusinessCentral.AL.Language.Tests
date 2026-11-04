// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160, main app); objects below
// Probe (corpus issue 648), OnPrem app because these platform tables are Scope = OnPrem (AL0296 in a Cloud app): the rows of
// API Webhook Entity for an API page of this app, "Tenant ID" of Published Application for the test apps and Base Application,
// the rows, Insert and Delete of Performance Profile Scheduler and MCP Configuration (BC 28 and later), and the Table Information
// row of a table declared ObsoleteState = Moved (table 80301 of the main app).
// Object ids 98450-98460.

table 98450 "LT AW Api Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 98451 "LT AW Api Page"
{
    PageType = API;
    APIPublisher = 'ltaw';
    APIGroup = 'probe';
    APIVersion = 'v1.0';
    EntityName = 'awEntity';
    EntitySetName = 'awEntities';
    SourceTable = "LT AW Api Src";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { }
                field(number; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }
}

codeunit 98452 "LT AW OnPrem Row Text"
{
    procedure RowText(var RR: RecordRef; Skip: Text): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Class = FieldClass::Normal) and (FR.Type <> FieldType::Blob) and (FR.Type <> FieldType::Media) and (FR.Type <> FieldType::MediaSet) then
                if not ('|' + Skip + '|').Contains('|' + FR.Name + '|') then
                    Result += FR.Name + '=' + Format(FR.Value, 0, 9) + ';';
        end;
        exit(Result);
    end;
}

codeunit 98453 "LT AW OnPrem Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SystemSkipTok: Label 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion', Locked = true;
        // Package ID is the id of the published package: it changes with every publish, so it is not compared.
        PackageSkipTok: Label '|Package ID', Locked = true;

    [Test]
    procedure ApiWebhookEntity_RowOfOwnApiPage()
    var
        Entity: Record "API Webhook Entity";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Observer.Observe('total_not_empty', Format(not Entity.IsEmpty()));
        Entity.SetRange("Object ID", Page::"LT AW Api Page");
        Observer.Observe('own_rows', Format(Entity.Count()));
        if Entity.FindFirst() then begin
            RR.GetTable(Entity);
            Observer.Observe('own_row', RowTexts.RowText(RR, SystemSkipTok + PackageSkipTok));
        end;
        Observer.Expect('total_not_empty', 'Yes');
        Observer.Expect('own_rows', '1');
        Observer.Expect('own_row', 'Publisher=ltaw;Group=probe;Version=v1.0;Name=awEntities;Table No.=98450;Table Temporary=false;Key Fields=2000000000;OData Key Specified=true;Object Type=8;Object ID=98451;');
        Observer.Verify();
    end;

    [Test]
    procedure ApiWebhookEntity_FirstRow()
    var
        Entity: Record "API Webhook Entity";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        if Entity.FindFirst() then begin
            RR.GetTable(Entity);
            Observer.Observe('first_row', RowTexts.RowText(RR, SystemSkipTok + PackageSkipTok));
        end;
        Observer.Expect('first_row', 'Publisher=;Group=;Version=beta;Name=customerSales;Table No.=18;Table Temporary=false;Key Fields=1;OData Key Specified=false;Object Type=9;Object ID=5480;');
        Observer.Verify();
    end;

    local procedure TenantIdOf(AppId: Guid): Text
    var
        PublishedApp: Record "Published Application";
        Result: Text;
    begin
        PublishedApp.SetRange(ID, AppId);
        Result := Format(PublishedApp.Count()) + ' rows;';
        if PublishedApp.FindSet() then
            repeat
                Result += '[tenant=' + PublishedApp."Tenant ID" + ' as=' + Format(PublishedApp."Published As") + ']';
            until PublishedApp.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure PublishedApplication_TenantId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('base_application', TenantIdOf('437dbf0e-84ff-417a-965d-ed2bb9650972'));
        Observer.Observe('coverage_tests', TenantIdOf('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
        Observer.Observe('onprem_tests', TenantIdOf('3f8c1a52-9d4e-4b17-8c26-5ea70b93d418'));
        Observer.Observe('session_tenant', TenantId());
        Observer.Expect('base_application', '1 rows;[tenant= as=Global]');
        Observer.Expect('coverage_tests', '1 rows;[tenant=default as= Dev]');
        Observer.Expect('onprem_tests', '1 rows;[tenant=default as= Dev]');
        Observer.Expect('session_tenant', 'default');
        Observer.Verify();
    end;

    [Test]
    procedure PerformanceProfileScheduler_RowsInsertDelete()
    var
        Scheduler: Record "Performance Profile Scheduler";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Observer.Observe('count', Format(Scheduler.Count()));
        Scheduler.Init();
        RR.GetTable(Scheduler);
        Observer.Observe('init_row', RowTexts.RowText(RR, SystemSkipTok));
        Observer.Observe('insert', Format(Scheduler.Insert()));
        Observer.Observe('count_after_insert', Format(Scheduler.Count()));
        Scheduler.FindFirst();
        RR.GetTable(Scheduler);
        Observer.Observe('stored_row', RowTexts.RowText(RR, SystemSkipTok + '|Schedule ID|User ID|Client Type'));
        Observer.Observe('delete', Format(Scheduler.Delete()));
        Observer.Observe('count_after_delete', Format(Scheduler.Count()));
        Observer.Expect('count', '0');
        Observer.Expect('init_row', 'Schedule ID={00000000-0000-0000-0000-000000000000};Client Type=0;User ID={00000000-0000-0000-0000-000000000000};Starting Date-Time=;Ending Date-Time=;Description=;Enabled=false;Frequency=0;Profile Creation Threshold=P0DT0H0M0.0S;');
        Observer.Expect('insert', 'Yes');
        Observer.Expect('count_after_insert', '1');
        Observer.Expect('stored_row', 'Starting Date-Time=;Ending Date-Time=;Description=;Enabled=false;Frequency=0;Profile Creation Threshold=P0DT0H0M0.0S;');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('count_after_delete', '0');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure McpConfiguration_Rows()
    var
        Config: Record "MCP Configuration";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Rows: Text;
    begin
        Observer.Observe('count', Format(Config.Count()));
        if Config.FindSet() then
            repeat
                RR.GetTable(Config);
                Rows += '[' + RowTexts.RowText(RR, SystemSkipTok) + ']';
            until Config.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Expect('count', '1');
#if BC29PLUS
        Observer.Expect('rows', '[Name=;Description=Default MCP configuration;EnableDynamicToolMode=true;Active=true;AllowProdChanges=true;DiscoverReadOnlyObjects=true;Default=true;EnableApiTools=true;EnableAlQueryTools=false;]');
#else
        Observer.Expect('rows', '[Name=;Description=Default MCP configuration;EnableDynamicToolMode=true;Active=true;AllowProdChanges=true;DiscoverReadOnlyObjects=true;Default=true;]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure McpConfiguration_InsertDelete()
    var
        Config: Record "MCP Configuration";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Config.Init();
        Config.Name := 'LT AW';
        Observer.Observe('insert', Format(Config.Insert()));
        Observer.Observe('count_after_insert', Format(Config.Count()));
        Config.Get('LT AW');
        RR.GetTable(Config);
        Observer.Observe('stored_row', RowTexts.RowText(RR, SystemSkipTok));
        Observer.Observe('delete', Format(Config.Delete()));
        Observer.Observe('count_after_delete', Format(Config.Count()));
        Config.Get('');
        Observer.Observe('delete_fresh_row', Format(Config.Delete()));
        Observer.Observe('count_after_delete_fresh', Format(Config.Count()));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('count_after_insert', '2');
#if BC29PLUS
        Observer.Expect('stored_row', 'Name=LT AW;Description=;EnableDynamicToolMode=false;Active=false;AllowProdChanges=false;DiscoverReadOnlyObjects=false;Default=false;EnableApiTools=true;EnableAlQueryTools=false;');
#else
        Observer.Expect('stored_row', 'Name=LT AW;Description=;EnableDynamicToolMode=false;Active=false;AllowProdChanges=false;DiscoverReadOnlyObjects=false;Default=false;');
#endif
        Observer.Expect('delete', 'Yes');
        Observer.Expect('count_after_delete', '1');
        Observer.Expect('delete_fresh_row', 'Yes');
        Observer.Expect('count_after_delete_fresh', '0');
        Observer.Verify();
    end;

    [Test]
    procedure AgentCreationControl_Rows()
    var
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Rows: Text;
    begin
        RR.Open(2000000297);
        Observer.Observe('name', RR.Name);
        Observer.Observe('count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Rows += '[' + RowTexts.RowText(RR, SystemSkipTok) + ']';
            until RR.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Expect('name', 'Agent Creation Control');
        Observer.Expect('count', '1');
        Observer.Expect('rows', '[ID=1;User Security ID={00000000-0000-0000-0000-000000000000};Agent Metadata Provider=-1;Company Name=;Description=Default: Allow all users with required permissions to create agents;]');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure MovedTable_TableInformation()
    var
        TableInfo: Record "Table Information";
        Observer: Codeunit "Probe Observer";
    begin
        TableInfo.SetRange("Table No.", 80301);
        Observer.Observe('own_moved_rows', Format(TableInfo.Count()));
        if TableInfo.FindFirst() then
            Observer.Observe('own_moved_name', TableInfo."Table Name" + ' company=' + Format(TableInfo."Company Name" = CompanyName()));
        TableInfo.SetRange("Table No.", 308);
        TableInfo.SetRange("Company Name", CompanyName());
        Observer.Observe('no_series_rows', Format(TableInfo.Count()));
        Observer.Expect('own_moved_rows', '0');
        Observer.Expect('no_series_rows', '1');
        Observer.Verify();
    end;
}
