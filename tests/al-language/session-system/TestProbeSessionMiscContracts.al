// Observe-only probes (writer A). Rows: SessionSettings defaults/Init/handler, Notification, ErrorInfo, Version,
// ModuleInfo, IsolatedStorage, NumberSequence, Company, clock/WorkDate/identity/client type, Interface, Enum Names,
// Codeunit.Run with TableNo, Clear of codeunit, CommitBehavior, CodeCoverageLog, LogSecurityAudit, call depth.
interface "PA Misc Iface"
{
    procedure Hi(): Text;
}

codeunit 69813 "PA Misc Impl" implements "PA Misc Iface"
{
    procedure Hi(): Text
    begin
        exit('hi');
    end;
}

enum 69801 "PA Misc Iface Enum" implements "PA Misc Iface"
{
    Extensible = false;
    value(0; Impl) { Implementation = "PA Misc Iface" = "PA Misc Impl"; }
    value(3; Another) { Implementation = "PA Misc Iface" = "PA Misc Impl"; }
}

enumextension 69800 "PA Rec Enum Ext" extends "PA Rec Enum"
{
    value(7; Seven) { Caption = 'Seven Caption'; }
}

codeunit 69814 "PA Misc TableNo Runner"
{
    TableNo = "PA Rec Row";

    trigger OnRun()
    begin
        Rec.Txt := 'set by OnRun';
        Rec.Id := Rec.Id + 100;
    end;
}

codeunit 69815 "PA Misc Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;
        Reached: Text;
        Depth: Integer;

    // ---------------------------------------------------------------- SessionSettings
    [Test]
    procedure SessionSettings_PristineProperties()
    var
        O: Codeunit "Probe Observer";
        S: SessionSettings;
    begin
        O.Observe('languageid', TryNum(1, S));
        O.Observe('localeid', TryNum(2, S));
        O.Observe('timezone', TryNum(3, S));
        O.Observe('profileid', TryNum(4, S));
        O.Observe('profileappid', TryNum(5, S));
        O.Observe('company', TryNum(6, S));
        O.Expect('languageid', '[0]');
        O.Expect('localeid', '[0]');
        O.Expect('timezone', '[]');
        O.Expect('profileid', '[]');
        O.Expect('profileappid', '[{00000000-0000-0000-0000-000000000000}]');
        O.Expect('company', '[]');
        O.Verify();
    end;

    local procedure TryNum(What: Integer; var S: SessionSettings): Text
    var
        Res: Text;
    begin
        if TryNumF(What, S, Res) then
            exit('[' + Res + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNumF(What: Integer; var S: SessionSettings; var Res: Text)
    begin
        case What of
            1:
                Res := Format(S.LanguageId());
            2:
                Res := Format(S.LocaleId());
            3:
                Res := S.TimeZone();
            4:
                Res := S.ProfileId();
            5:
                Res := Format(S.ProfileAppId());
            6:
                Res := S.Company();
        end;
    end;

    [Test]
    [HandlerFunctions('SessionSettingsH')]
    procedure SessionSettings_RequestUpdateFalse_Handler()
    var
        O: Codeunit "Probe Observer";
        S: SessionSettings;
    begin
        HandlerLog := '';
        S.Init();
        S.RequestSessionUpdate(false);
        O.Observe('handler_log', HandlerLog);
        O.Expect('handler_log', 'called;');
        O.Verify();
    end;

    [SessionSettingsHandler]
    procedure SessionSettingsH(var S: SessionSettings): Boolean
    begin
        HandlerLog += 'called;';
        exit(false);
    end;

    // ---------------------------------------------------------------- Notification
    [Test]
    procedure Notification_UnsetProperties()
    var
        O: Codeunit "Probe Observer";
        N: Notification;
    begin
        O.Observe('message', TryNotif(1, N));
        O.Observe('scope', TryNotif(2, N));
        O.Observe('getdata_unset', TryNotif(3, N));
        O.Observe('hasdata_unset', Format(N.HasData('x')));
        O.Observe('id_is_null', Format(IsNullGuid(N.Id())));
        O.Expect('message', '[]');
        O.Expect('scope', '[LocalScope]');
        O.Expect('getdata_unset', '[]');
        O.Expect('hasdata_unset', 'No');
        O.Expect('id_is_null', 'Yes');
        O.Verify();
    end;

    local procedure TryNotif(What: Integer; var N: Notification): Text
    var
        Res: Text;
    begin
        if TryNotifF(What, N, Res) then
            exit('[' + Res + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNotifF(What: Integer; var N: Notification; var Res: Text)
    begin
        case What of
            1:
                Res := N.Message();
            2:
                Res := Format(N.Scope());
            3:
                Res := N.GetData('x');
        end;
    end;

    [Test]
    procedure Notification_ScopeOrdinals()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('LocalScope', Format(NotificationScope::LocalScope, 0, 1));
        O.Observe('GlobalScope', Format(NotificationScope::GlobalScope, 0, 1));
        O.Expect('LocalScope', 'LocalScope');
        O.Expect('GlobalScope', 'GlobalScope');
        O.Verify();
    end;

    [Test]
    procedure Notification_SendWithoutHandler()
    var
        O: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Message := 'hello';
        N.Send();
        O.Observe('send_no_handler', 'no error');
        O.Expect('send_no_handler', 'no error');
        O.Verify();
    end;

    [Test]
    procedure Notification_RecallNeverSent()
    var
        O: Codeunit "Probe Observer";
        N: Notification;
        R: Boolean;
    begin
        N.Message := 'hello';
        O.Observe('recall_never_sent', TryRecall(N));
        O.Expect('recall_never_sent', 'No');
        O.Verify();
    end;

    local procedure TryRecall(var N: Notification): Text
    var
        Res: Boolean;
    begin
        if TryRecallF(N, Res) then
            exit(Format(Res));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRecallF(var N: Notification; var Res: Boolean)
    begin
        Res := N.Recall();
    end;

    [Test]
    [HandlerFunctions('NotifHandlerFalse')]
    procedure Notification_HandlerAnswersFalse()
    var
        O: Codeunit "Probe Observer";
        N: Notification;
    begin
        HandlerLog := '';
        N.Message := 'hello';
        N.SetData('k', 'v');
        N.Send();
        O.Observe('send_handler_false', 'no error');
        O.Observe('handler_log', HandlerLog);
        O.Expect('send_handler_false', 'no error');
        O.Expect('handler_log', 'msg=hello;scope=LocalScope;k=v;');
        O.Verify();
    end;

    [SendNotificationHandler]
    procedure NotifHandlerFalse(var N: Notification): Boolean
    begin
        HandlerLog += 'msg=' + N.Message() + ';scope=' + Format(N.Scope()) + ';k=' + N.GetData('k') + ';';
        exit(false);
    end;

    // ---------------------------------------------------------------- ErrorInfo
    [Test]
    procedure ErrorInfo_UnsetAndOrdinals()
    var
        O: Codeunit "Probe Observer";
        E: ErrorInfo;
    begin
        O.Observe('errortype_unset', TryEI(1, E));
        O.Observe('message_unset', '[' + E.Message() + ']');
        O.Observe('verbosity_unset', Format(E.Verbosity()));
        O.Observe('dataclassification_unset', Format(E.DataClassification()));
        O.Observe('collectible_unset', Format(E.Collectible()));
        O.Observe('verbosity_Critical', Format(Verbosity::Critical, 0, 1));
        O.Observe('verbosity_Error', Format(Verbosity::Error, 0, 1));
        O.Observe('verbosity_Warning', Format(Verbosity::Warning, 0, 1));
        O.Observe('verbosity_Normal', Format(Verbosity::Normal, 0, 1));
        O.Observe('verbosity_Verbose', Format(Verbosity::Verbose, 0, 1));
        O.Observe('dc_CustomerContent', Format(DataClassification::CustomerContent, 0, 1));
        O.Observe('dc_ToBeClassified', Format(DataClassification::ToBeClassified, 0, 1));
        O.Observe('dc_EndUserIdentifiableInformation', Format(DataClassification::EndUserIdentifiableInformation, 0, 1));
        O.Observe('dc_AccountData', Format(DataClassification::AccountData, 0, 1));
        O.Observe('dc_EndUserPseudonymousIdentifiers', Format(DataClassification::EndUserPseudonymousIdentifiers, 0, 1));
        O.Observe('dc_OrganizationIdentifiableInformation', Format(DataClassification::OrganizationIdentifiableInformation, 0, 1));
        O.Observe('dc_SystemMetadata', Format(DataClassification::SystemMetadata, 0, 1));
        O.Observe('errortype_Client', Format(ErrorType::Client, 0, 1));
        O.Observe('errortype_Internal', Format(ErrorType::Internal, 0, 1));
        O.Expect('errortype_unset', '[Client]');
        O.Expect('message_unset', '[]');
        O.Expect('verbosity_unset', 'Error');
        O.Expect('dataclassification_unset', 'CustomerContent');
        O.Expect('collectible_unset', 'No');
        O.Expect('verbosity_Critical', 'Critical');
        O.Expect('verbosity_Error', 'Error');
        O.Expect('verbosity_Warning', 'Warning');
        O.Expect('verbosity_Normal', 'Normal');
        O.Expect('verbosity_Verbose', 'Verbose');
        O.Expect('dc_CustomerContent', 'CustomerContent');
        O.Expect('dc_ToBeClassified', 'ToBeClassified');
        O.Expect('dc_EndUserIdentifiableInformation', 'EndUserIdentifiableInformation');
        O.Expect('dc_AccountData', 'AccountData');
        O.Expect('dc_EndUserPseudonymousIdentifiers', 'EndUserPseudonymousIdentifiers');
        O.Expect('dc_OrganizationIdentifiableInformation', 'OrganizationIdentifiableInformation');
        O.Expect('dc_SystemMetadata', 'SystemMetadata');
        O.Expect('errortype_Client', 'Client');
        O.Expect('errortype_Internal', 'Internal');
        O.Verify();
    end;

    local procedure TryEI(What: Integer; var E: ErrorInfo): Text
    var
        Res: Text;
    begin
        if TryEIF(What, E, Res) then
            exit('[' + Res + ']');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEIF(What: Integer; var E: ErrorInfo; var Res: Text)
    begin
        case What of
            1:
                Res := Format(E.ErrorType());
        end;
    end;

    [Test]
    procedure ErrorInfo_ErrorClientAndInternal()
    var
        O: Codeunit "Probe Observer";
        E: ErrorInfo;
    begin
        E := ErrorInfo.Create('client message');
        E.ErrorType := ErrorType::Client;
        asserterror Error(E);
        O.ObserveError('error_client');
        E := ErrorInfo.Create('internal message');
        E.ErrorType := ErrorType::Internal;
        asserterror Error(E);
        O.ObserveError('error_internal');
        E := ErrorInfo.Create('with code');
        E.ErrorType := ErrorType::Client;
        E.Message := 'with code message';
        asserterror Error(E);
        O.ObserveError('error_with_message_assigned');
        O.Expect('error_client|text', 'client message');
        O.Expect('error_client|code', 'Dialog');
        O.Expect('error_internal|text', 'An error has occurred. If the error persists, please contact your system administrator.\Correlation ID: x');
        O.Expect('error_internal|code', 'Dialog');
        O.Expect('error_with_message_assigned|text', 'with code message');
        O.Expect('error_with_message_assigned|code', 'Dialog');
        O.Verify();
    end;

    [Test]
    procedure ErrorInfo_CreateOverloads()
    var
        O: Codeunit "Probe Observer";
        E: ErrorInfo;
        R: Record "PA Rec Row";
    begin
        R.Id := 5;
        E := ErrorInfo.Create('m3', true, R);
        O.Observe('create3_collectible', Format(E.Collectible()) + ' tableid=' + Format(E.TableId()) + ' fieldno=' + Format(E.FieldNo()) + ' recordid=' + Format(E.RecordId()));
        E := ErrorInfo.Create('m4', true, R, 2);
        O.Observe('create4', Format(E.Collectible()) + ' tableid=' + Format(E.TableId()) + ' fieldno=' + Format(E.FieldNo()));
        E := ErrorInfo.Create('m5', true, R, 2, 77);
        O.Observe('create5_pageno', Format(E.PageNo()) + ' controlname=[' + E.ControlName() + ']');
        E := ErrorInfo.Create('m6', true, R, 2, 77, 'Ctl');
        O.Observe('create6_controlname', Format(E.PageNo()) + ' controlname=[' + E.ControlName() + ']');
        E := ErrorInfo.Create('m7', true, R, 2, 77, 'Ctl', Verbosity::Warning);
        O.Observe('create7_verbosity', Format(E.Verbosity()));
        E := ErrorInfo.Create('m8', true, R, 2, 77, 'Ctl', Verbosity::Warning, DataClassification::AccountData);
        O.Observe('create8_dataclassification', Format(E.DataClassification()));
        O.Observe('create8_message', E.Message());
        O.Expect('create3_collectible', 'Yes tableid=69804 fieldno=0 recordid=PA Rec Row: 5');
        O.Expect('create4', 'Yes tableid=69804 fieldno=2');
        O.Expect('create5_pageno', '77 controlname=[]');
        O.Expect('create6_controlname', '77 controlname=[Ctl]');
        O.Expect('create7_verbosity', 'Warning');
        O.Expect('create8_dataclassification', 'AccountData');
        O.Expect('create8_message', 'm8');
        O.Verify();
    end;

    [Test]
    procedure ErrorInfo_Callstack_IsAvailable()
    var
        O: Codeunit "Probe Observer";
        E: ErrorInfo;
    begin
        E := ErrorInfo.Create('x');
        O.Observe('callstack_before_error', '[' + E.Callstack() + ']');
        O.Expect('callstack_before_error', '[]');
        O.Verify();
    end;

    // ---------------------------------------------------------------- Error collection
    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTwo()
    var
        E: ErrorInfo;
    begin
        E := ErrorInfo.Create('first collected', true);
        Error(E);
        Reached += 'after-first;';
        E := ErrorInfo.Create('second collected', true);
        Error(E);
        Reached += 'after-second;';
    end;

    [Test]
    procedure ErrorCollection_ScopeExitText()
    var
        O: Codeunit "Probe Observer";
    begin
        Reached := '';
        asserterror CollectTwo();
        O.ObserveError('scope_exit_two_errors');
        O.Observe('reached', Reached);
        O.Expect('scope_exit_two_errors|text', 'Multiple errors occurred during the operation the first of which is: first collected. All errors can be found under ''Detailed Information''.');
        O.Expect('scope_exit_two_errors|code', 'Dialog');
        O.Expect('reached', 'after-first;after-second;');
        O.Verify();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectOne()
    var
        E: ErrorInfo;
    begin
        E := ErrorInfo.Create('only one', true);
        Error(E);
        Reached += 'after-only;';
    end;

    [Test]
    procedure ErrorCollection_SingleError()
    var
        O: Codeunit "Probe Observer";
    begin
        Reached := '';
        asserterror CollectOne();
        O.ObserveError('scope_exit_one_error');
        O.Observe('reached', Reached);
        O.Expect('scope_exit_one_error|text', 'only one');
        O.Expect('scope_exit_one_error|code', 'Dialog');
        O.Expect('reached', 'after-only;');
        O.Verify();
    end;

    [Test]
    procedure ErrorCollection_OutsideScope()
    var
        O: Codeunit "Probe Observer";
        Errs: List of [ErrorInfo];
    begin
        Errs := GetCollectedErrors();
        O.Observe('collected_outside_scope_count', Format(Errs.Count()));
        O.Observe('has_collected_errors', Format(HasCollectedErrors()));
        O.Expect('collected_outside_scope_count', '0');
        O.Expect('has_collected_errors', 'Yes');
        O.Verify();
    end;

    // ---------------------------------------------------------------- Version / ModuleInfo
    [Test]
    procedure Version_Forms()
    var
        O: Codeunit "Probe Observer";
        V: Version;
        V2: Version;
    begin
        V := Version.Create(1, 2, 3, 4);
        O.Observe('create4', Format(V) + ' major=' + Format(V.Major()) + ' minor=' + Format(V.Minor()) + ' build=' + Format(V.Build()) + ' revision=' + Format(V.Revision()));
        V := Version.Create(1, 2);
        O.Observe('create2', Format(V));
        V := Version.Create(1, 2, 3);
        O.Observe('create3', Format(V));
        V := Version.Create('5.6.7.8');
        O.Observe('create_text', Format(V));
        V2 := Version.Create(1, 2, 3, 5);
        O.Observe('compare_less', Format(V < V2));
        O.Observe('compare_equal_text', Format(Version.Create('1.2.3.5') = V2));
        O.Observe('totext', V.ToText());
        asserterror O.Observe('totext_default_format', Format(V, 0, 9));
        O.ObserveError('totext_default_format');
        O.Expect('create4', '1.2.3.4 major=1 minor=2 build=3 revision=4');
        O.Expect('create2', '1.2.0.0');
        O.Expect('create3', '1.2.3.0');
        O.Expect('create_text', '5.6.7.8');
        O.Expect('compare_less', 'No');
        O.Expect('compare_equal_text', 'Yes');
        O.Expect('totext', '5.6.7.8');
        O.Expect('totext_default_format|text', 'Standard format number 9 does not exist for the type ''Version''.');
        O.Expect('totext_default_format|code', 'InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure ModuleInfo_CurrentModule()
    var
        O: Codeunit "Probe Observer";
        I: ModuleInfo;
        D: Version;
        Deps: List of [ModuleDependencyInfo];
        Dep: ModuleDependencyInfo;
    begin
        NavApp.GetCurrentModuleInfo(I);
        O.Observe('name', I.Name());
        O.Observe('publisher', I.Publisher());
        O.Observe('id', Format(I.Id()));
        O.Observe('packageid_equals_id', Format(I.PackageId() = I.Id()));
        D := I.DataVersion();
        O.Observe('dataversion_equals_appversion', Format(I.DataVersion() = I.AppVersion()));
        O.Observe('publisher_isempty', Format(I.Publisher() = ''));
        O.Observe('dependencies_count', Format(I.Dependencies().Count()));
        foreach Dep in I.Dependencies() do
            O.Observe('dependency_' + Dep.Name, Format(Dep.Id) + ' ' + Dep.Publisher);
        O.Expect('name', 'AL Language Coverage Tests');
        O.Expect('publisher', 'AL Language');
        O.Expect('id', '{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}');
        O.Expect('packageid_equals_id', 'No');
        O.Expect('dataversion_equals_appversion', 'Yes');
        O.Expect('publisher_isempty', 'No');
        // 9 since the three cross-app fixtures (CONTRIBUTING.md, "Multi-app fixtures") became dependencies of this app. Dependencies()
        // lists the apps in ascending app id order (the six earlier entries were already in that order).
        O.Expect('dependencies_count', '9');
        O.Expect('dependency_AL Language XApp C', '{0DF0FADC-D339-4B0F-A1D5-51DC51F10900} Bravo Probe Publisher');
        O.Expect('dependency_Permissions Mock', '{40860557-A18D-42AD-AECB-22B7DD80DC80} Microsoft');
        O.Expect('dependency_Base Application', '{437DBF0E-84FF-417A-965D-ED2BB9650972} Microsoft');
        O.Expect('dependency_System Application', '{63CA2FA4-4F03-4F2B-A480-172FEF340D3F} Microsoft');
        O.Expect('dependency_System Application Test Library', '{9856AE4F-D1A7-46EF-89BB-6EF056398228} Microsoft');
        O.Expect('dependency_Application', '{C1335042-3002-4257-BF8A-75C898CCB1B8} Microsoft');
        O.Expect('dependency_AL Language XApp B', '{C87CED6D-11A6-4AD2-87C7-AC10083D0A2F} Zulu Probe Publisher');
        O.Expect('dependency_AL Language XApp A', '{CD6A4292-F27B-4AF9-89BC-15A5956F5C71} AL Language');
        O.Expect('dependency_AL Internals Test Fixture', '{F1E2D3C4-B5A6-7890-FEDC-BA9876543210} AL Language');
        O.Verify();
    end;

    [Test]
    procedure ModuleInfo_NullAppId()
    var
        O: Codeunit "Probe Observer";
        I: ModuleInfo;
        Null: Guid;
    begin
        O.Observe('getmoduleinfo_null_result', Format(NavApp.GetModuleInfo(Null, I)));
        O.Observe('name', I.Name());
        O.Observe('publisher', I.Publisher());
        O.Observe('id', Format(I.Id()));
        O.Observe('dataversion_major_ge_27', Format(I.DataVersion().Major() >= 27));
        O.Expect('getmoduleinfo_null_result', 'Yes');
        O.Expect('name', 'W1');
        O.Expect('publisher', 'Microsoft');
        O.Expect('id', '{00000000-0000-0000-0000-000000000000}');
        O.Expect('dataversion_major_ge_27', 'Yes');
        O.Verify();
    end;

    // ---------------------------------------------------------------- IsolatedStorage
    [Test]
    procedure IsolatedStorage_Behaviour()
    var
        O: Codeunit "Probe Observer";
        V: Text;
        P: Text;
    begin
        if IsolatedStorage.Delete('probekey', DataScope::Module) then;
        if IsolatedStorage.Delete('probekey', DataScope::Company) then;
        O.Observe('set_module', Format(IsolatedStorage.Set('probekey', 'modval', DataScope::Module)));
        O.Observe('set_company', Format(IsolatedStorage.Set('probekey', 'compval', DataScope::Company)));
        V := 'untouched';
        O.Observe('get_module', Format(IsolatedStorage.Get('probekey', DataScope::Module, V)) + ' ' + V);
        O.Observe('get_company', Format(IsolatedStorage.Get('probekey', DataScope::Company, V)) + ' ' + V);
        O.Observe('contains_module', Format(IsolatedStorage.Contains('probekey', DataScope::Module)));
        V := 'untouched';
        O.Observe('get_missing', Format(IsolatedStorage.Get('nokey', DataScope::Module, V)) + ' ' + V);
        O.Observe('get_user_scope', TryGetScope(DataScope::User));
        O.Observe('get_companyanduser_scope', TryGetScope(DataScope::CompanyAndUser));
        if IsolatedStorage.Delete('probekey', DataScope::Module) then;
        if IsolatedStorage.Delete('probekey', DataScope::Company) then;
        O.Expect('set_module', 'Yes');
        O.Expect('set_company', 'Yes');
        O.Expect('get_module', 'Yes modval');
        O.Expect('get_company', 'Yes compval');
        O.Expect('contains_module', 'Yes');
        O.Expect('get_missing', 'No ');
        O.Expect('get_user_scope', 'No ');
        O.Expect('get_companyanduser_scope', 'No ');
        O.Verify();
    end;

    local procedure TryDelete(K: Text): Text
    begin
        if TryDeleteF(K) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDeleteF(K: Text)
    begin
        IsolatedStorage.Delete(K, DataScope::Module);
    end;

    local procedure TryGetScope(Scope: DataScope): Text
    var
        Res: Text;
    begin
        if TryGetScopeF(Scope, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGetScopeF(Scope: DataScope; var Res: Text)
    var
        V: Text;
    begin
        Res := Format(IsolatedStorage.Get('probekey', Scope, V)) + ' ' + V;
    end;

    [Test]
    procedure IsolatedStorage_NotRolledBack()
    var
        O: Codeunit "Probe Observer";
        V: Text;
    begin
        if IsolatedStorage.Delete('probekey2', DataScope::Module) then;
        asserterror begin
            IsolatedStorage.Set('probekey2', 'inside', DataScope::Module);
            Error('stop');
        end;
        V := 'untouched';
        O.Observe('get_after_asserterror', Format(IsolatedStorage.Get('probekey2', DataScope::Module, V)) + ' ' + V);
        if IsolatedStorage.Delete('probekey2', DataScope::Module) then;
        O.Expect('get_after_asserterror', 'No ');
        O.Verify();
    end;

    // ---------------------------------------------------------------- NumberSequence
    local procedure TryCurrent(N: Text): Text
    var
        Res: Text;
    begin
        if TryCurrentF(N, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCurrentF(N: Text; var Res: Text)
    begin
        Res := Format(NumberSequence.Current(N));
    end;

    local procedure TryRange(N: Text; C: Integer): Text
    var
        Res: Text;
    begin
        if TryRangeF(N, C, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRangeF(N: Text; C: Integer; var Res: Text)
    var
        First: BigInteger;
    begin
        First := NumberSequence.Range(N, C);
        Res := 'first=' + Format(First);
    end;

    [Test]
    procedure NumberSequence_InsertDefaults()
    var
        O: Codeunit "Probe Observer";
    begin
        if NumberSequence.Exists('ProbeSeqB') then
            NumberSequence.Delete('ProbeSeqB');
        NumberSequence.Insert('ProbeSeqB');
        O.Observe('insert_name_only_next_1', Format(NumberSequence.Next('ProbeSeqB')));
        O.Observe('insert_name_only_next_2', Format(NumberSequence.Next('ProbeSeqB')));
        NumberSequence.Delete('ProbeSeqB');
        NumberSequence.Insert('ProbeSeqB', 50);
        O.Observe('insert_seed_only_next_1', Format(NumberSequence.Next('ProbeSeqB')));
        O.Observe('insert_seed_only_next_2', Format(NumberSequence.Next('ProbeSeqB')));
        NumberSequence.Delete('ProbeSeqB');
        O.Expect('insert_name_only_next_1', '0');
        O.Expect('insert_name_only_next_2', '1');
        O.Expect('insert_seed_only_next_1', '50');
        O.Expect('insert_seed_only_next_2', '51');
        O.Verify();
    end;

    [Test]
    procedure NumberSequence_NotRolledBack()
    var
        O: Codeunit "Probe Observer";
        Dummy: BigInteger;
    begin
        if NumberSequence.Exists('ProbeSeqC') then
            NumberSequence.Delete('ProbeSeqC');
        NumberSequence.Insert('ProbeSeqC', 1, 1);
        asserterror begin
            Dummy := NumberSequence.Next('ProbeSeqC');
            Dummy := NumberSequence.Next('ProbeSeqC');
            Error('stop');
        end;
        O.Observe('next_after_asserterror', Format(NumberSequence.Next('ProbeSeqC')));
        NumberSequence.Delete('ProbeSeqC');
        O.Expect('next_after_asserterror', '3');
        O.Verify();
    end;

    // ---------------------------------------------------------------- Company, clock, identity
    [Test]
    procedure Company_Names()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
        C: Record Company;
    begin
        O.Observe('companyname', CompanyName());
        O.Observe('displayname', TryProp(1));
        O.Observe('urlname', TryProp(2));
        O.Observe('company_table_count_ge_1', Format(C.Count() >= 1));
        R.ChangeCompany(CompanyName());
        O.Observe('changecompany_same', Format(R.CurrentCompany()));
        R.ChangeCompany('');
        O.Observe('changecompany_empty_currentcompany', '[' + R.CurrentCompany() + ']');
        O.Observe('changecompany_empty_count', TryCount(R));
        O.Observe('changecompany_missing', TryChange(R, 'no such company here'));
        O.Expect('companyname', '<Company>');
        O.Expect('displayname', '<Company>');
        O.Expect('urlname', '<Company>');
        O.Expect('company_table_count_ge_1', 'Yes');
        O.Expect('changecompany_same', '<Company>');
        O.Expect('changecompany_empty_currentcompany', '[<Company>]');
        O.Expect('changecompany_empty_count', '0');
        O.Expect('changecompany_missing', 'ERR:The company "no such company here" does not exist./DB:RecordNotFound');
        O.Verify();
    end;

    local procedure TryProp(What: Integer): Text
    var
        Res: Text;
    begin
        if TryPropF(What, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryPropF(What: Integer; var Res: Text)
    begin
        case What of
            1:
                Res := CompanyProperty.DisplayName();
            2:
                Res := CompanyProperty.UrlName();
            3:
                Res := Format(CompanyProperty.ID());
        end;
    end;

    local procedure TryCount(var R: Record "PA Rec Row"): Text
    var
        Res: Text;
    begin
        if TryCountF(R, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCountF(var R: Record "PA Rec Row"; var Res: Text)
    begin
        Res := Format(R.Count());
    end;

    local procedure TryChange(var R: Record "PA Rec Row"; N: Text): Text
    var
        Res: Text;
    begin
        if TryChangeF(R, N, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryChangeF(var R: Record "PA Rec Row"; N: Text; var Res: Text)
    begin
        R.ChangeCompany(N);
        Res := 'changed, count=' + Format(R.Count());
    end;

    [Test]
    procedure Clock_TodayTimeNow_Consistency()
    var
        O: Codeunit "Probe Observer";
        T1: DateTime;
        T2: DateTime;
        D: Date;
    begin
        T1 := CurrentDateTime();
        Sleep(120);
        T2 := CurrentDateTime();
        O.Observe('sleep_120_elapsed_at_least_100', Format(T2 - T1 >= 100));
        O.Observe('sleep_120_elapsed_below_2000', Format(T2 - T1 < 2000));
        O.Observe('today_equals_dt2date_now_diff', Format(Today() - DT2Date(CurrentDateTime()) <= 1));
        O.Observe('time_has_ms_part_sometimes', Format(Time() <> 0T));
        O.Observe('year_ge_2025', Format(Date2DMY(Today(), 3) >= 2025));
        O.Observe('today_vs_dt2date_utc_diff', Format(Today() - DT2Date(CurrentDateTime())));
        O.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;

    [Test]
    procedure WorkDate_A_SetAndLeave()
    var
        O: Codeunit "Probe Observer";
    begin
        WorkDate(DMY2Date(15, 6, 2001));
        O.Observe('after_set', Format(WorkDate(), 0, 9));
        O.Expect('after_set', '2001-06-15');
        O.Verify();
    end;

    [Test]
    procedure WorkDate_B_StartsAtTodayAgain()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('workdate_minus_today_in_next_test', Format(WorkDate() - Today()));
        O.Observe('workdate_when_set_in_prior_test_of_same_codeunit', Format(WorkDate(), 0, 9));
        O.Expect('workdate_minus_today_in_next_test', Format(DMY2Date(15, 6, 2001) - Today()));
        O.Expect('workdate_when_set_in_prior_test_of_same_codeunit', '2001-06-15');
        O.Verify();
    end;

    [Test]
    procedure WorkDate_SetUndefined()
    var
        O: Codeunit "Probe Observer";
    begin
        WorkDate(0D);
        O.Observe('after_set_0D_minus_today', Format(WorkDate() - Today()));
        WorkDate(Today());
        O.Expect('after_set_0D_minus_today', '0');
        O.Verify();
    end;

    [Test]
    procedure Identity_Values()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('userid', UserId());
        O.Observe('usersecurityid', Format(UserSecurityId()));
        O.Observe('sessionid_positive', Format(SessionId() > 0));
        O.Observe('sessionid', Format(SessionId()));
        O.Observe('serviceinstanceid', Format(ServiceInstanceId()));
        O.Observe('tenantid', TenantId());
        O.Observe('companyname', CompanyName());
        O.Observe('currentclienttype', Format(CurrentClientType()));
        O.Observe('defaultclienttype', Format(DefaultClientType()));
        O.Observe('currentexecutioncontext', Format(CurrentExecutionMode()));
        O.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;

    [Test]
    procedure ClientType_Ordinals()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('Windows', Format(ClientType::Windows, 0, 1));
        O.Observe('Web', Format(ClientType::Web, 0, 1));
        O.Observe('Background', Format(ClientType::Background, 0, 1));
        O.Observe('Phone', Format(ClientType::Phone, 0, 1));
        O.Observe('Tablet', Format(ClientType::Tablet, 0, 1));
        O.Observe('Desktop', Format(ClientType::Desktop, 0, 1));
        O.Observe('Api', Format(ClientType::Api, 0, 1));
        O.Observe('ODataV4', Format(ClientType::ODataV4, 0, 1));
        O.Observe('SOAP', Format(ClientType::SOAP, 0, 1));
        O.Observe('OData', Format(ClientType::OData, 0, 1));
        O.Observe('Management', Format(ClientType::Management, 0, 1));
        O.Observe('NavUserService', Format(ClientType::NAS, 0, 1));
        O.Expect('Windows', 'Windows');
        O.Expect('Web', 'Web');
        O.Expect('Background', 'Background');
        O.Expect('Phone', 'Phone');
        O.Expect('Tablet', 'Tablet');
        O.Expect('Desktop', 'Desktop');
        O.Expect('Api', 'Api');
        O.Expect('ODataV4', 'ODataV4');
        O.Expect('SOAP', 'SOAP');
        O.Expect('OData', 'OData');
        O.Expect('Management', 'Management');
        O.Expect('NavUserService', 'NAS');
        O.Verify();
    end;

    // ---------------------------------------------------------------- Interface / enum
    [Test]
    procedure Interface_CallOnUnassigned()
    var
        O: Codeunit "Probe Observer";
        I: Interface "PA Misc Iface";
        R: Text;
    begin
        asserterror R := I.Hi();
        O.ObserveError('call_unassigned');
        O.Expect('call_unassigned|text', 'Interface not initialized');
        O.Expect('call_unassigned|code', 'InvalidOperation');
        O.Verify();
    end;

    [Test]
    procedure Interface_CastUndeclaredOrdinal()
    var
        O: Codeunit "Probe Observer";
        E: Enum "PA Misc Iface Enum";
        I: Interface "PA Misc Iface";
        R: Text;
    begin
        E := "PA Misc Iface Enum".FromInteger(0);
        I := E;
        O.Observe('declared_0', I.Hi());
        E := "PA Misc Iface Enum".FromInteger(9);
        asserterror I := E;
        O.ObserveError('undeclared_9_assign');
        O.Expect('declared_0', 'hi');
        O.Expect('undeclared_9_assign|text', 'Enum does not contain value 9.');
        O.Expect('undeclared_9_assign|code', 'ArgumentOutOfRange');
        O.Verify();
    end;

    [Test]
    procedure Enum_NamesOrdinalsOrder()
    var
        O: Codeunit "Probe Observer";
        E: Enum "PA Rec Enum";
        Names: List of [Text];
        Ords: List of [Integer];
        i: Integer;
        S: Text;
    begin
        Names := E.Names();
        Ords := E.Ordinals();
        for i := 1 to Names.Count() do
            S += Names.Get(i) + '=' + Format(Ords.Get(i)) + ';';
        O.Observe('names_ordinals', S);
        O.Observe('count', Format(Names.Count()) + ' ' + Format(Ords.Count()));
        E := "PA Rec Enum".FromInteger(7);
        O.Observe('ext_value_7_format', Format(E));
        O.Observe('ext_value_7_name_f2', Format(E, 0, 2));
        O.Observe('caption_five', Format("PA Rec Enum"::Five));
        O.Observe('no_caption_one', Format("PA Rec Enum"::One));
        O.Expect('names_ordinals', 'Zero=0;One=1;Five=5;Seven=7;');
        O.Expect('count', '4 4');
        O.Expect('ext_value_7_format', 'Seven Caption');
        O.Expect('ext_value_7_name_f2', '7');
        O.Expect('caption_five', 'Five Caption');
        O.Expect('no_caption_one', 'One');
        O.Verify();
    end;

    // ---------------------------------------------------------------- Codeunit.Run with TableNo / Clear
    [Test]
    procedure CodeunitRun_TableNo_WithRecord()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
    begin
        R.Id := 1;
        Codeunit.Run(Codeunit::"PA Misc TableNo Runner", R);
        O.Observe('txt', R.Txt);
        O.Expect('txt', 'set by OnRun');
        O.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_NoRecord()
    var
        O: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        O.Observe('run_without_record', TryRunNoRec());
        O.Expect('run_without_record', 'ok');
        O.Verify();
    end;

    local procedure TryRunNoRec(): Text
    begin
        if TryRunNoRecF() then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRunNoRecF()
    begin
        Codeunit.Run(Codeunit::"PA Misc TableNo Runner");
    end;

    [Test]
    procedure CodeunitRun_TableNo_TemporaryRecord()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row" temporary;
    begin
        R.Id := 1;
        Codeunit.Run(Codeunit::"PA Misc TableNo Runner", R);
        O.Observe('txt', R.Txt);
        O.Expect('txt', 'set by OnRun');
        O.Verify();
    end;

    // ---------------------------------------------------------------- misc platform
    local procedure TryCommit(What: Integer): Text
    begin
        if TryCommitF(What) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCommitF(What: Integer)
    begin
        case What of
            0:
                Commit();
            1:
                CommitIgnore();
            2:
                CommitError();
        end;
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure CommitIgnore()
    begin
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CommitError()
    begin
        Commit();
    end;

    [Test]
    procedure CodeCoverageLog_Flags()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('log_off_default', Format(CodeCoverageLog()));
        O.Observe('log_on', Format(CodeCoverageLog(true, false)));
        O.Observe('log_state_after_on', Format(CodeCoverageLog()));
        O.Observe('log_off', Format(CodeCoverageLog(false, false)));
        O.Observe('log_state_after_off', Format(CodeCoverageLog()));
        O.Expect('log_off_default', 'No');
        O.Expect('log_on', 'Yes');
        O.Expect('log_state_after_on', 'Yes');
        O.Expect('log_off', 'No');
        O.Expect('log_state_after_off', 'No');
        O.Verify();
    end;

    // ---------------------------------------------------------------- call depth
    local procedure Recurse(N: Integer)
    begin
        Depth := N;
        if N > 0 then
            Recurse(N - 1);
    end;

    local procedure RecurseUp(N: Integer; Max: Integer)
    begin
        Depth := N;
        if N < Max then
            RecurseUp(N + 1, Max);
    end;

    [Test]
    procedure CallDepth_990()
    var
        O: Codeunit "Probe Observer";
    begin
        Depth := 0;
        RecurseUp(1, 990);
        O.Observe('reached_depth', Format(Depth));
        O.Expect('reached_depth', '990');
        O.Verify();
    end;

    [Test]
    procedure CallDepth_1000()
    var
        O: Codeunit "Probe Observer";
    begin
        Depth := 0;
        O.Observe('result', TryDepth(1000));
        O.Observe('reached_depth', Format(Depth));
        O.Expect('result', 'ERR:There is insufficient memory to execute this function. This can be caused by recursive function calls. Contact your system administrator./StackOverflow');
        O.Expect('reached_depth', '988');
        O.Verify();
    end;

    [Test]
    procedure CallDepth_1001()
    var
        O: Codeunit "Probe Observer";
    begin
        Depth := 0;
        O.Observe('result', TryDepth(1001));
        O.Observe('reached_depth', Format(Depth));
        O.Expect('result', 'ERR:There is insufficient memory to execute this function. This can be caused by recursive function calls. Contact your system administrator./StackOverflow');
        O.Expect('reached_depth', '988');
        O.Verify();
    end;

    local procedure TryDepth(Max: Integer): Text
    begin
        if TryDepthF(Max) then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDepthF(Max: Integer)
    begin
        RecurseUp(1, Max);
    end;

    // ---------------------------------------------------------------- Dictionary / List / arithmetic errors
    [Test]
    procedure Dictionary_List_ErrorTexts()
    var
        O: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        L: List of [Integer];
        LR: List of [Integer];
        V: Integer;
        T: Text;
    begin
        L.Add(10);
        L.Add(20);
        L.Add(30);
        D.Add('a', 1);
        asserterror V := D.Get('missing');
        O.ObserveError('dict_get_missing');
        asserterror D.Add('a', 2);
        O.ObserveError('dict_add_duplicate');
        asserterror V := D.Get('missing');
        O.Observe('dict_get_value_form_code', GetLastErrorCode());
        D.Remove('missing');
        O.Observe('dict_remove_missing', 'no error');
        O.Observe('dict_get_out_form', Format(D.Get('missing', V)));
        asserterror V := L.Get(0);
        O.ObserveError('list_get_0');
        asserterror V := L.Get(4);
        O.ObserveError('list_get_4');
        asserterror L.RemoveAt(4);
        O.ObserveError('list_removeat_4');
        asserterror L.RemoveAt(0);
        O.ObserveError('list_removeat_0');
        asserterror L.Set(4, 1);
        O.ObserveError('list_set_4');
        asserterror L.Insert(5, 1);
        O.ObserveError('list_insert_5');
        asserterror L.Insert(0, 1);
        O.ObserveError('list_insert_0');
        O.Observe('list_insert_4_ok', TryListInsert(L, 4));
        asserterror LR := L.GetRange(3, 5);
        O.ObserveError('list_getrange_past_end');
        asserterror LR := L.GetRange(0, 1);
        O.ObserveError('list_getrange_start_0');
        asserterror L.RemoveRange(3, 5);
        O.ObserveError('list_removerange_past_end');
        asserterror L.RemoveRange(0, 1);
        O.ObserveError('list_removerange_0');
        asserterror T := Format(L.IndexOf(1) / (L.Count() - L.Count()));
        O.ObserveError('division_by_zero');
        O.Expect('dict_get_missing|text', 'The given key was not present in the dictionary.');
        O.Expect('dict_get_missing|code', 'KeyNotFound');
        O.Expect('dict_add_duplicate|text', 'An item with the same key has already been added.');
        O.Expect('dict_add_duplicate|code', 'Argument');
        O.Expect('dict_get_value_form_code', 'KeyNotFound');
        O.Expect('dict_remove_missing', 'no error');
        O.Expect('dict_get_out_form', 'No');
        O.Expect('list_get_0|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_get_0|code', 'ArgumentOutOfRange');
        O.Expect('list_get_4|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_get_4|code', 'ArgumentOutOfRange');
        O.Expect('list_removeat_4|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_removeat_4|code', 'ArgumentOutOfRange');
        O.Expect('list_removeat_0|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_removeat_0|code', 'ArgumentOutOfRange');
        O.Expect('list_set_4|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_set_4|code', 'ArgumentOutOfRange');
        O.Expect('list_insert_5|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_insert_5|code', 'ArgumentOutOfRange');
        O.Expect('list_insert_0|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_insert_0|code', 'ArgumentOutOfRange');
        O.Expect('list_insert_4_ok', 'count=4');
        O.Expect('list_getrange_past_end|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_getrange_past_end|code', 'Argument');
        O.Expect('list_getrange_start_0|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_getrange_start_0|code', 'ArgumentOutOfRange');
        O.Expect('list_removerange_past_end|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_removerange_past_end|code', 'Argument');
        O.Expect('list_removerange_0|text', 'An invalid argument was passed to a ''List'' data type method.');
        O.Expect('list_removerange_0|code', 'ArgumentOutOfRange');
        O.Expect('division_by_zero|text', 'Attempted to divide by zero.');
        O.Expect('division_by_zero|code', 'AL:DivideByZero');
        O.Verify();
    end;

    local procedure TryListInsert(var L: List of [Integer]; Pos: Integer): Text
    begin
        L.Insert(Pos, 99);
        exit('count=' + Format(L.Count()));
    end;

    [Test]
    procedure Arithmetic_ErrorTexts()
    var
        O: Codeunit "Probe Observer";
        I: Integer;
        Z: Integer;
        D: Decimal;
        Bi: BigInteger;
        Mx: Integer;
    begin
        Z := 0;
        Mx := 2147483647;
        asserterror I := 5 div Z;
        O.ObserveError('int_div_zero');
        asserterror I := 5 mod Z;
        O.ObserveError('int_mod_zero');
        asserterror D := 5.5 / Z;
        O.ObserveError('decimal_div_zero');
        asserterror I := Mx + 1;
        O.ObserveError('int_overflow_add');
        asserterror I := -Mx - 2;
        O.ObserveError('int_underflow_sub');
        asserterror I := Mx * 2;
        O.ObserveError('int_overflow_mul');
        Evaluate(Bi, '9223372036854775807');
        asserterror Bi := Bi + 1;
        O.ObserveError('biginteger_overflow');
        asserterror Evaluate(I, '2147483648');
        O.ObserveError('evaluate_int_overflow_statement');
        O.Expect('int_div_zero|text', 'Attempted to divide by zero.');
        O.Expect('int_div_zero|code', 'AL:DivideByZero');
        O.Expect('int_mod_zero|text', 'Attempted to divide by zero.');
        O.Expect('int_mod_zero|code', 'AL:DivideByZero');
        O.Expect('decimal_div_zero|text', 'Attempted to divide by zero.');
        O.Expect('decimal_div_zero|code', 'AL:DivideByZero');
        O.Expect('int_overflow_add|text', 'Arithmetic operation resulted in an overflow.');
        O.Expect('int_overflow_add|code', 'AL:Overflow');
        O.Expect('int_underflow_sub|text', 'Arithmetic operation resulted in an overflow.');
        O.Expect('int_underflow_sub|code', 'AL:Overflow');
        O.Expect('int_overflow_mul|text', 'Arithmetic operation resulted in an overflow.');
        O.Expect('int_overflow_mul|code', 'AL:Overflow');
        O.Expect('biginteger_overflow|text', 'Arithmetic operation resulted in an overflow.');
        O.Expect('biginteger_overflow|code', 'AL:Overflow');
        O.Expect('evaluate_int_overflow_statement|text', 'The value "2147483648" can''t be evaluated into type Integer.');
        O.Expect('evaluate_int_overflow_statement|code', 'Evaluate');
        O.Verify();
    end;

    // ---------------------------------------------------------------- partial records
    [Test]
    procedure PartialRecords_AreFieldsLoaded()
    var
        O: Codeunit "Probe Observer";
        R: Record "PA Rec Row";
        R2: Record "PA Rec Row";
        L: Boolean;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Cd := 'C';
        R.Txt := 'T';
        R.Insert();
        R2.Get(1);
        O.Observe('no_setloadfields_txt', TryLoaded(R2, 3));
        Clear(R2);
        R2.SetLoadFields(Cd);
        R2.Get(1);
        O.Observe('loadfields_cd_has_cd', TryLoaded(R2, 2));
        O.Observe('loadfields_cd_has_txt', TryLoaded(R2, 3));
        O.Observe('loadfields_cd_has_id', TryLoaded(R2, 1));
        O.Observe('read_txt_ondemand', R2.Txt);
        O.Observe('after_read_txt_loaded', TryLoaded(R2, 3));
        Clear(R2);
        O.Observe('addloadfields_without_set', TryAddLoad(R2));
        R2.SetLoadFields(Cd);
        R2.AddLoadFields(Txt);
        R2.Get(1);
        O.Observe('add_loaded_txt', TryLoaded(R2, 3));
        O.Observe('add_loaded_dec', TryLoaded(R2, 8));
        R2.SetLoadFields();
        R2.Get(1);
        O.Observe('empty_setloadfields_dec', TryLoaded(R2, 8));
        O.Observe('empty_setloadfields_txt', TryLoaded(R2, 3));
        R2.Reset();
        R2.SetLoadFields(Cd);
        R2.SetBaseLoadFields();
        R2.Get(1);
        O.Observe('baseloadfields_txt', TryLoaded(R2, 3));
        R.DeleteAll();
        O.Expect('no_setloadfields_txt', 'Yes');
        O.Expect('loadfields_cd_has_cd', 'Yes');
        O.Expect('loadfields_cd_has_txt', 'Yes');
        O.Expect('loadfields_cd_has_id', 'Yes');
        O.Expect('read_txt_ondemand', 'T');
        O.Expect('after_read_txt_loaded', 'Yes');
        O.Expect('addloadfields_without_set', 'ok; txt loaded after Get-less: n/a');
        O.Expect('add_loaded_txt', 'Yes');
        O.Expect('add_loaded_dec', 'Yes');
        O.Expect('empty_setloadfields_dec', 'Yes');
        O.Expect('empty_setloadfields_txt', 'Yes');
        O.Expect('baseloadfields_txt', 'Yes');
        O.Verify();
    end;

    local procedure TryAddLoad(var R: Record "PA Rec Row"): Text
    begin
        R.AddLoadFields(Txt);
        exit('ok; txt loaded after Get-less: n/a');
    end;

    local procedure TryLoaded(var R: Record "PA Rec Row"; No: Integer): Text
    var
        Res: Boolean;
    begin
        if TryLoadedF(R, No, Res) then
            exit(Format(Res));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLoadedF(var R: Record "PA Rec Row"; No: Integer; var Res: Boolean)
    begin
        case No of
            1:
                Res := R.AreFieldsLoaded(Id);
            2:
                Res := R.AreFieldsLoaded(Cd);
            3:
                Res := R.AreFieldsLoaded(Txt);
            8:
                Res := R.AreFieldsLoaded(Dec);
        end;
    end;
}

codeunit 69821 "PA Misc Log"
{
    SingleInstance = true;
    var
        Lines: List of [Text];

    procedure Add(T: Text)
    begin
        Lines.Add(T);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Text(): Text
    var
        L: Text;
        R: Text;
    begin
        foreach L in Lines do
            R += L + ' ; ';
        exit(R);
    end;
}
