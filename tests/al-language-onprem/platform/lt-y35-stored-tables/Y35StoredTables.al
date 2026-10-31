// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Webhook Subscription, Webhook Notification, MCP Configuration, MCP Configuration Tool and Tenant Profile
//   Setting have Scope = OnPrem)
// Fixtures used: Probe Observer (69160) and profile "ALT Profile SameApp" (main app a1b2c3d4-e5f6-7890-abcd-ef1234567890), from the AL
//   Language Coverage Tests app; row text helper "LT AW OnPrem Row Text" (98452, platform/lt-aw-fresh-tenant/AwOnPremTests.al)
// Probe (gap cycle 3, C3-03): rows at the start, writes and filtered reads of the stored platform tables Webhook Subscription (2000000199),
//   Webhook Notification (2000000194), MCP Configuration Tool (2000000293) and Tenant Profile Setting (2000000083) on the corpus container:
//   does the container hold rows, does the platform fill or check a column on a write, how do filters, Delete(true), DeleteAll(true) and
//   ModifyAll answer. Neighbours: lt-y21-env-columns/Y21EnvColumnsOnPrem.al:317-344 (Webhook Subscription "Created By" kept as written),
//   lt-aw-fresh-tenant/AwOnPremTests.al:174-225 (MCP Configuration rows). Every test deletes its own keys first (prefix LT-C303 / LT C303).
// BC versions: 27.5, 28.5, 29.0. "API Version" of MCP Configuration Tool exists on BC 28 and later; its "Object Type" has the members
//   Query and Codeunit on BC 29 only (BC 27/28: Page), so the second tool is a Page on BC 27/28.

codeunit 98668 "LT Y35 Webhook Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        SystemSkipTok: Label 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion', Locked = true;
        EndpointTok: Label 'https://lt.example/hook', Locked = true;

    local procedure SubscriptionRows(var Sub: Record "Webhook Subscription"): Text
    var
        RR: RecordRef;
        Rows: Text;
    begin
        if Sub.FindSet() then
            repeat
                RR.GetTable(Sub);
                Rows += '[' + RowTexts.RowText(RR, SystemSkipTok) + ']';
            until Sub.Next() = 0;
        exit(Rows);
    end;

    local procedure NotificationRows(var Notification: Record "Webhook Notification"): Text
    var
        RR: RecordRef;
        Rows: Text;
    begin
        if Notification.FindSet() then
            repeat
                RR.GetTable(Notification);
                Rows += '[' + RowTexts.RowText(RR, SystemSkipTok + '|ID') + 'ID null=' + Format(IsNullGuid(Notification.ID)) + ';Notification has value=' + Format(Notification.Notification.HasValue()) + ';]';
            until Notification.Next() = 0;
        exit(Rows);
    end;

    [TryFunction]
    local procedure TryInsertSubscription(SubscriptionId: Text[150]; CreatedBy: Code[50]; var Shown: Text)
    var
        Sub: Record "Webhook Subscription";
    begin
        Sub.Init();
        Sub."Subscription ID" := SubscriptionId;
        Sub.Endpoint := EndpointTok;
        Sub."Created By" := CreatedBy;
        Sub."Client State" := 'state';
        Shown := Format(Sub.Insert());
    end;

    local procedure Clean()
    var
        Sub: Record "Webhook Subscription";
        Notification: Record "Webhook Notification";
    begin
        Sub.SetFilter("Subscription ID", 'LT-C303*');
        Sub.DeleteAll();
        Notification.SetFilter("Subscription ID", 'LT-C303*');
        Notification.DeleteAll();
    end;

    [Test]
    procedure C303_Webhook_RowsAtStart()
    var
        Sub: Record "Webhook Subscription";
        Notification: Record "Webhook Notification";
    begin
        Observer.Observe('sub_count_start', Format(Sub.Count()));
        Observer.Observe('sub_rows_start', SubscriptionRows(Sub));
        Observer.Observe('notification_count_start', Format(Notification.Count()));
        Observer.Observe('notification_rows_start', NotificationRows(Notification));
        Observer.Finish();
    end;

    [Test]
    procedure C303_Webhook_RowsAndWrites()
    var
        Sub: Record "Webhook Subscription";
        Shown: Text;
    begin
        Clean();
        if TryInsertSubscription('LT-C303-B', 'X PAYPAL Y', Shown) then
            Observer.Observe('insert_b', Shown)
        else
            Observer.ObserveError('insert_b');
        if TryInsertSubscription('LT-C303-A', '', Shown) then
            Observer.Observe('insert_a', Shown)
        else
            Observer.ObserveError('insert_a');
        if TryInsertSubscription('LT-C303-B', '', Shown) then
            Observer.Observe('insert_dup', Shown)
        else
            Observer.ObserveError('insert_dup');
        Sub.SetFilter("Subscription ID", 'LT-C303*');
        Observer.Observe('count_own', Format(Sub.Count()));
        Observer.Observe('rows_own', SubscriptionRows(Sub));
        Sub.SetFilter("Created By", '@*paypal*');
        Observer.Observe('count_created_by_paypal', Format(Sub.Count()));
        Sub.Reset();
        Sub.SetFilter("Subscription ID", '@%1', 'lt-c303-a');
        Observer.Observe('isempty_case_insensitive', Format(Sub.IsEmpty()));
        Sub.Reset();
        Sub.SetFilter("Subscription ID", 'LT-C303*');
        Sub.FindFirst();
        Observer.Observe('first_key', Sub."Subscription ID");
        Observer.Observe('delete_true', Format(Sub.Delete(true)));
        Observer.Observe('count_after_delete', Format(Sub.Count()));
        Sub.DeleteAll(true);
        Observer.Observe('count_after_deleteall', Format(Sub.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure C303_WebhookNotification_Insert()
    var
        Notification: Record "Webhook Notification";
        OutS: OutStream;
    begin
        Clean();
        Notification.Init();
        Notification.ID := CreateGuid();
        Notification."Sequence Number" := 7;
        Notification."Subscription ID" := 'LT-C303-N';
        Notification."Resource ID" := 'r1';
        Notification."Change Type" := 'created';
        Notification."Resource Type Name" := 'LT';
        Notification.Notification.CreateOutStream(OutS);
        OutS.WriteText('{}');
        Observer.Observe('insert', Format(Notification.Insert()));
        Notification.Reset();
        Notification.SetFilter("Subscription ID", 'LT-C303*');
        Observer.Observe('count_own', Format(Notification.Count()));
        Observer.Observe('rows_own', NotificationRows(Notification));
        Notification.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Notification.Count()));
        Observer.Finish();
    end;
}

codeunit 98669 "LT Y35 MCP Tool Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        SkipTok: Label 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion|ID', Locked = true;

    local procedure ToolRows(var Tool: Record "MCP Configuration Tool"): Text
    var
        RR: RecordRef;
        Rows: Text;
    begin
        if Tool.FindSet() then
            repeat
                RR.GetTable(Tool);
                Rows += '[' + RowTexts.RowText(RR, SkipTok) + ']';
            until Tool.Next() = 0;
        exit(Rows);
    end;

    local procedure ToolRow(var Tool: Record "MCP Configuration Tool"): Text
    var
        RR: RecordRef;
    begin
        RR.GetTable(Tool);
        exit(RowTexts.RowText(RR, SkipTok));
    end;

    local procedure OwnConfig(Name: Text[100]): Guid
    var
        Config: Record "MCP Configuration";
        Tool: Record "MCP Configuration Tool";
    begin
        if Config.Get(Name) then begin
            Tool.SetRange(ID, Config.SystemId);
            Tool.DeleteAll();
            Config.Delete();
        end;
        Config.Init();
        Config.Name := Name;
        Config.Insert();
        exit(Config.SystemId);
    end;

    [TryFunction]
    local procedure TryInsertTool(ConfigId: Guid; ObjectType: Option; ObjectId: Integer; var Shown: Text)
    var
        Tool: Record "MCP Configuration Tool";
    begin
        Tool.Init();
        Tool.ID := ConfigId;
        Tool."Object Type" := ObjectType;
        Tool."Object ID" := ObjectId;
        Tool."Allow Read" := true;
#if BC28PLUS
        Tool."API Version" := 'v2.0';
#endif
        Shown := Format(Tool.Insert());
    end;

    local procedure InsertTool(Op: Text; ConfigId: Guid; ObjectType: Option; ObjectId: Integer)
    var
        Shown: Text;
    begin
        if TryInsertTool(ConfigId, ObjectType, ObjectId, Shown) then
            Observer.Observe(Op, Shown)
        else
            Observer.ObserveError(Op);
    end;

    [Test]
    procedure C303_McpTool_RowsAtStart()
    var
        Tool: Record "MCP Configuration Tool";
        Config: Record "MCP Configuration";
        UnderDefault: Integer;
    begin
        Observer.Observe('count_start', Format(Tool.Count()));
        Observer.Observe('rows_start', ToolRows(Tool));
        if Config.Get('') then begin
            Tool.SetRange(ID, Config.SystemId);
            UnderDefault := Tool.Count();
        end;
        Observer.Observe('count_under_default_config', Format(UnderDefault));
        Observer.Finish();
    end;

    [Test]
    procedure C303_McpTool_RowsAndWrites()
    var
        Tool: Record "MCP Configuration Tool";
        Tool2: Record "MCP Configuration Tool";
        ConfigId: Guid;
        ToolSystemId: Guid;
    begin
        ConfigId := OwnConfig('LT C303');
        Observer.Observe('config_systemid_null', Format(IsNullGuid(ConfigId)));
        Tool.Init();
        Tool.ID := ConfigId;
        Tool."Object Type" := Tool."Object Type"::Page;
        Tool."Object ID" := 1;
        Tool."Allow Read" := true;
        Tool."Allow Create" := true;
#if BC28PLUS
        Tool."API Version" := 'v2.0';
#endif
        Observer.Observe('insert_page', Format(Tool.Insert()));
        ToolSystemId := Tool.SystemId;
        Observer.Observe('page_row', ToolRow(Tool));
        Tool2.Init();
        Tool2.ID := ConfigId;
#if BC29PLUS
        Tool2."Object Type" := Tool2."Object Type"::Query;
#else
        Tool2."Object Type" := Tool2."Object Type"::Page;
#endif
        Tool2."Object ID" := 2;
        Tool2."Allow Modify" := true;
        Tool2."Allow Create" := true;
        Observer.Observe('insert_query', Format(Tool2.Insert()));
        Clear(Tool);
        Observer.Observe('get_by_key', Format(Tool.Get(ConfigId, Tool."Object Type"::Page, 1)));
        Observer.Observe('get_row', ToolRow(Tool));
        Clear(Tool);
        Observer.Observe('get_by_systemid', Format(Tool.GetBySystemId(ToolSystemId)));
        Observer.Observe('get_by_systemid_object', Format(Tool."Object Type") + ' ' + Format(Tool."Object ID"));
        Tool."Allow Delete" := true;
        Observer.Observe('modify', Format(Tool.Modify()));
        Observer.Observe('modified_row', ToolRow(Tool));
        Tool.Reset();
        Tool.SetRange(ID, ConfigId);
        Tool.ModifyAll("Allow Create", false);
        Observer.Observe('rows_after_modifyall', ToolRows(Tool));
        Tool2.Find();
        Observer.Observe('delete_query', Format(Tool2.Delete()));
        Observer.Observe('count_after_delete', Format(Tool.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure C303_McpTool_ParentChecks()
    var
        Tool: Record "MCP Configuration Tool";
        Config: Record "MCP Configuration";
        DefaultId: Guid;
        OwnId: Guid;
        NoParent: Guid;
    begin
        NoParent := CreateGuid();
        InsertTool('insert_no_config', NoParent, Tool."Object Type"::Page, 1);
        Tool.SetRange(ID, NoParent);
        Observer.Observe('count_no_config', Format(Tool.Count()));
        Tool.DeleteAll();
        if Config.Get('') then
            DefaultId := Config.SystemId;
        InsertTool('insert_default_config', DefaultId, Tool."Object Type"::Page, 3);
        Tool.SetRange(ID, DefaultId);
        Tool.SetRange("Object ID", 3);
        Tool.DeleteAll();
        OwnId := OwnConfig('LT C303 M2');
        InsertTool('insert_own', OwnId, Tool."Object Type"::Page, 4);
#if BC29PLUS
        InsertTool('insert_codeunit_0', OwnId, Tool."Object Type"::Codeunit, 0);
#else
        InsertTool('insert_codeunit_0', OwnId, Tool."Object Type"::Page, 0);
#endif
        InsertTool('insert_page_not_api', OwnId, Tool."Object Type"::Page, 2000000000);
        Config.Get('LT C303 M2');
        Observer.Observe('delete_config', Format(Config.Delete()));
        Tool.Reset();
        Tool.SetRange(ID, OwnId);
        Observer.Observe('tools_after_config_delete', Format(Tool.Count()));
        OwnId := OwnConfig('LT C303 M2T');
        InsertTool('insert_own_t', OwnId, Tool."Object Type"::Page, 4);
        Config.Get('LT C303 M2T');
        Observer.Observe('delete_config_true', Format(Config.Delete(true)));
        Tool.SetRange(ID, OwnId);
        Observer.Observe('tools_after_config_delete_true', Format(Tool.Count()));
        Observer.Finish();
    end;
}

codeunit 98670 "LT Y35 Tenant Profile Setting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        RowTexts: Codeunit "LT AW OnPrem Row Text";
        SkipTok: Label 'SystemId|SystemCreatedAt|SystemCreatedBy|SystemModifiedAt|SystemModifiedBy|SystemRowVersion', Locked = true;
        MainAppTok: Label 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', Locked = true;

    local procedure Rows(var Setting: Record "Tenant Profile Setting"): Text
    var
        RR: RecordRef;
        Result: Text;
    begin
        if Setting.FindSet() then
            repeat
                RR.GetTable(Setting);
                Result += '[' + RowTexts.RowText(RR, SkipTok) + ']';
            until Setting.Next() = 0;
        exit(Result);
    end;

    local procedure OwnProfileId(): Code[30]
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("App ID", MainAppTok);
        AllProfile.SetRange(Caption, 'ALT Profile SameApp');
        if AllProfile.FindFirst() then
            exit(AllProfile."Profile ID");
        AllProfile.SetRange(Caption);
        AllProfile.SetFilter("Profile ID", '@ALT PROFILE SAMEAPP');
        if AllProfile.FindFirst() then
            exit(AllProfile."Profile ID");
        exit('NOT FOUND');
    end;

    [TryFunction]
    local procedure TryInsert(AppId: Guid; ProfileId: Code[30]; var Shown: Text)
    var
        Setting: Record "Tenant Profile Setting";
    begin
        Setting.Init();
        Setting."App ID" := AppId;
        Setting."Profile ID" := ProfileId;
        Setting."Default Role Center" := true;
        Shown := Format(Setting.Insert());
    end;

    [TryFunction]
    local procedure TryModifyAll()
    var
        Setting: Record "Tenant Profile Setting";
    begin
        Setting.ModifyAll("Default Role Center", false);
    end;

    local procedure Insert(Op: Text; AppId: Guid; ProfileId: Code[30])
    var
        Shown: Text;
    begin
        if TryInsert(AppId, ProfileId, Shown) then
            Observer.Observe(Op, Shown)
        else
            Observer.ObserveError(Op);
    end;

    local procedure AllProfileState(ProfileId: Code[30]): Text
    var
        AllProfile: Record "All Profile";
    begin
        if not AllProfile.Get(AllProfile.Scope::Tenant, MainAppTok, ProfileId) then
            exit('not found');
        exit('Default Role Center=' + Format(AllProfile."Default Role Center") + ';Disable Personalization=' + Format(AllProfile."Disable Personalization"));
    end;

    local procedure DefaultProfiles(): Text
    var
        AllProfile: Record "All Profile";
        Result: Text;
    begin
        AllProfile.SetRange("Default Role Center", true);
        if AllProfile.FindSet() then
            repeat
                Result += Format(AllProfile.Scope) + ':' + AllProfile."Profile ID" + ';';
            until AllProfile.Next() = 0;
        exit(Format(AllProfile.Count()) + '|' + Result);
    end;

    [Test]
    procedure C303_TenantProfileSetting_RowsAndWrites()
    var
        Setting: Record "Tenant Profile Setting";
        ProfileId: Code[30];
    begin
        ProfileId := OwnProfileId();
        Observer.Observe('own_profile_id', ProfileId);
        Observer.Observe('count_start', Format(Setting.Count()));
        Observer.Observe('rows_start', Rows(Setting));
        if TryModifyAll() then
            Observer.Observe('modifyall', 'ok')
        else
            Observer.ObserveError('modifyall');
        Setting.SetRange("Default Role Center", true);
        Observer.Observe('count_default_after_modifyall', Format(Setting.Count()));
        Setting.Reset();
        Setting.SetRange("App ID", MainAppTok);
        Setting.DeleteAll();
        Insert('insert_own_profile', MainAppTok, ProfileId);
        Insert('insert_no_profile', CreateGuid(), 'NOPROFILE');
        Setting.Reset();
        Setting.SetRange("Profile ID", ProfileId);
        Observer.Observe('own_rows', Rows(Setting));
        Setting.SetRange("Profile ID", 'NOPROFILE');
        Observer.Observe('count_no_profile', Format(Setting.Count()));
        Setting.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure C303_TenantProfileSetting_AllProfileLink()
    var
        Setting: Record "Tenant Profile Setting";
        ProfileId: Code[30];
    begin
        ProfileId := OwnProfileId();
        Observer.Observe('all_profile_before', AllProfileState(ProfileId));
        Observer.Observe('default_profiles_before', DefaultProfiles());
        Setting.SetRange("App ID", MainAppTok);
        Setting.DeleteAll();
        Insert('insert_own_profile', MainAppTok, ProfileId);
        Observer.Observe('all_profile_after_insert', AllProfileState(ProfileId));
        Observer.Observe('default_profiles_after_insert', DefaultProfiles());
        Setting.Reset();
        Setting.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Setting.Count()));
        Observer.Observe('all_profile_after_deleteall', AllProfileState(ProfileId));
        Observer.Observe('default_profiles_after_deleteall', DefaultProfiles());
        Observer.Finish();
    end;
}
