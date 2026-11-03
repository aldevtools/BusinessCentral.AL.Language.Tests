// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: log 69880, subscribers 69881, runner 69882, table 69883, pages 69884 and 69885
// Probe: the platform business events of the codeunits "Version Triggers", "UI Helper Triggers", "Filter Helper Triggers", "Company Triggers", "Feature Management Triggers",
// "Reporting Triggers", "SmartList Designer Triggers" and "System Action Triggers" (issues 606 and 607 of the corpus): which AL statements make the platform raise them in a
// test session, with which arguments, and whether a subscriber's change to a var parameter takes effect.
// The subscribers do nothing while the log mode is 0 (the default), log the arguments while it is 1 and also change every var parameter while it is 2.
// BC versions: 27.0 to 29.0 (BC28PLUS and BC29PLUS where they differ)

codeunit 69880 "LT W Pt Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        ModeValue: Integer;
        WhichValue: Text;
        ResultValue: Text;

    procedure SetMode(NewMode: Integer)
    begin
        ModeValue := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(ModeValue);
    end;

    procedure Reset()
    begin
        Clear(Lines);
        ResultValue := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure CountOf(Prefix: Text): Integer
    var
        Line: Text;
        N: Integer;
    begin
        foreach Line in Lines do
            if Line.StartsWith(Prefix) then
                N += 1;
        exit(N);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Joined: Text;
    begin
        foreach Line in Lines do begin
            if Joined <> '' then
                Joined += ' | ';
            Joined += Line;
        end;
        exit('[' + Joined + ']');
    end;

    procedure SetWhich(NewWhich: Text)
    begin
        WhichValue := NewWhich;
    end;

    procedure Which(): Text
    begin
        exit(WhichValue);
    end;

    procedure SetResult(NewResult: Text)
    begin
        ResultValue := NewResult;
    end;

    procedure Result(): Text
    begin
        exit(ResultValue);
    end;
}

codeunit 69881 "LT W Pt Subs"
{
    local procedure Txt(Value: JsonObject): Text
    var
        Json: Text;
    begin
        Value.WriteTo(Json);
        exit(Json);
    end;

    local procedure Txt(Value: JsonArray): Text
    var
        Json: Text;
    begin
        Value.WriteTo(Json);
        exit(Json);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Version Triggers", 'GetApplicationVersion', '', false, false)]
    local procedure GetApplicationVersion(var Version: Text[248])
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetApplicationVersion(' + 'Version=' + Version + ')');
        if Log.Mode() = 2 then begin
            Version := CopyStr('W:Version', 1, MaxStrLen(Version));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Version Triggers", 'GetReleaseVersion', '', false, false)]
    local procedure GetReleaseVersion(var Version: Text[50])
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetReleaseVersion(' + 'Version=' + Version + ')');
        if Log.Mode() = 2 then begin
            Version := CopyStr('W:Version', 1, MaxStrLen(Version));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Version Triggers", 'GetApplicationBuild', '', false, false)]
    local procedure GetApplicationBuild(var Build: Text[80])
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetApplicationBuild(' + 'Build=' + Build + ')');
        if Log.Mode() = 2 then begin
            Build := CopyStr('W:Build', 1, MaxStrLen(Build));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'AutoFormatTranslate', '', false, false)]
    local procedure AutoFormatTranslate(AutoFormatType: Integer; AutoFormatExpr: Text[80]; var Translation: Text[80])
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('AutoFormatTranslate(' + 'AutoFormatType=' + Format(AutoFormatType) + ',' + 'AutoFormatExpr=' + AutoFormatExpr + ',' + 'Translation=' + Translation + ')');
        if Log.Mode() = 2 then begin
            Translation := CopyStr('W:Translation', 1, MaxStrLen(Translation));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetDefaultRoundingPrecision', '', false, false)]
    local procedure GetDefaultRoundingPrecision(var AmountRoundingPrecision: Decimal)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetDefaultRoundingPrecision(' + 'AmountRoundingPrecision=' + Format(AmountRoundingPrecision) + ')');
        if Log.Mode() = 2 then begin
            AmountRoundingPrecision := 0.123;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'CaptionClassTranslate', '', false, false)]
    local procedure CaptionClassTranslate(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('CaptionClassTranslate(' + 'Language=' + Format(Language) + ',' + 'CaptionExpr=' + CaptionExpr + ',' + 'Translation=' + Translation + ')');
        if Log.Mode() = 2 then begin
            Translation := CopyStr('W:Translation', 1, MaxStrLen(Translation));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetSystemIndicator', '', false, false)]
    local procedure GetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetSystemIndicator(' + 'Text=' + Text + ',' + 'Style=' + Format(Style) + ')');
        if Log.Mode() = 2 then begin
            Text := CopyStr('W:Text', 1, MaxStrLen(Text));
            Style := 3;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetCueStyle', '', false, false)]
    local procedure GetCueStyle(TableId: Integer; FieldNo: Integer; CueValue: Decimal; var StyleText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetCueStyle(' + 'TableId=' + Format(TableId) + ',' + 'FieldNo=' + Format(FieldNo) + ',' + 'CueValue=' + Format(CueValue) + ',' + 'StyleText=' + StyleText + ')');
        if Log.Mode() = 2 then begin
            StyleText := 'W:StyleText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetApplicationLanguage', '', false, false)]
    local procedure GetApplicationLanguage(var Language: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetApplicationLanguage(' + 'Language=' + Format(Language) + ')');
        if Log.Mode() = 2 then begin
            Language := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateTimeFilter', '', false, false)]
    local procedure MakeDateTimeFilter(var DateTimeFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeDateTimeFilter(' + 'DateTimeFilterText=' + DateTimeFilterText + ')');
        if Log.Mode() = 3 then begin
            if DateTimeFilterText.Contains('..') then
                DateTimeFilterText := '01/01/20 12:00 PM..12/31/20 12:00 PM'
            else
                DateTimeFilterText := '12/31/20 12:00 PM';
        end;
        if Log.Mode() = 2 then begin
            DateTimeFilterText := 'W:DateTimeFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeIntFilter', '', false, false)]
    local procedure MakeIntFilter(var IntFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeIntFilter(' + 'IntFilterText=' + IntFilterText + ')');
        if Log.Mode() = 3 then begin
            if IntFilterText.Contains('..') then
                IntFilterText := '1..5'
            else
                IntFilterText := '5';
        end;
        if Log.Mode() = 2 then begin
            IntFilterText := 'W:IntFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateFilter', '', false, false)]
    local procedure MakeDateFilter(var DateFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeDateFilter(' + 'DateFilterText=' + DateFilterText + ')');
        if Log.Mode() = 3 then begin
            if DateFilterText.Contains('..') then
                DateFilterText := '2020-01-01..2020-12-31'
            else
                DateFilterText := '2020-12-31';
        end;
        if Log.Mode() = 2 then begin
            DateFilterText := 'W:DateFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeTextFilter', '', false, false)]
    local procedure MakeTextFilter(var TextFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeTextFilter(' + 'TextFilterText=' + TextFilterText + ')');
        if Log.Mode() = 3 then begin
            if TextFilterText.Contains('..') then
                TextFilterText := 'A*'
            else
                TextFilterText := 'A*';
        end;
        if Log.Mode() = 2 then begin
            TextFilterText := 'W:TextFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeCodeFilter', '', false, false)]
    local procedure MakeCodeFilter(var TextFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeCodeFilter(' + 'TextFilterText=' + TextFilterText + ')');
        if Log.Mode() = 3 then begin
            if TextFilterText.Contains('..') then
                TextFilterText := 'A*'
            else
                TextFilterText := 'A*';
        end;
        if Log.Mode() = 2 then begin
            TextFilterText := 'W:TextFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeTimeFilter', '', false, false)]
    local procedure MakeTimeFilter(var TimeFilterText: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('MakeTimeFilter(' + 'TimeFilterText=' + TimeFilterText + ')');
        if Log.Mode() = 3 then begin
            if TimeFilterText.Contains('..') then
                TimeFilterText := '12:00:00..13:00:00'
            else
                TimeFilterText := '12:00:00';
        end;
        if Log.Mode() = 2 then begin
            TimeFilterText := 'W:TimeFilterText';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OpenCompanySettings', '', false, false)]
    local procedure OpenCompanySettings()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenCompanySettings');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Triggers", 'OpenFeatureManagement', '', false, false)]
    local procedure OpenFeatureManagement()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenFeatureManagement');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetFilename', '', false, false)]
    local procedure GetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var FileName: Text; var Success: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetFilename(' + 'ReportID=' + Format(ReportID) + ',' + 'Caption=' + Caption + ',' + 'ObjectPayload=' + Txt(ObjectPayload) + ',' + 'FileExtension=' + FileExtension + ',' + 'ReportRecordRef=' + ReportRecordRef.Name() + ',' + 'FileName=' + FileName + ',' + 'Success=' + Format(Success) + ')');
        if Log.Mode() = 2 then begin
            FileName := 'W:FileName';
            Success := not Success;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Triggers", 'GetEnabled', '', false, false)]
    local procedure GetEnabled(var Enabled: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetEnabled(' + 'Enabled=' + Format(Enabled) + ')');
        if Log.Mode() = 2 then begin
            Enabled := not Enabled;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetDefaultRoleCenterID', '', false, false)]
    local procedure GetDefaultRoleCenterID(var ID: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetDefaultRoleCenterID(' + 'ID=' + Format(ID) + ')');
        if Log.Mode() = 2 then begin
            ID := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'CustomizeChart', '', false, false)]
    local procedure CustomizeChart(var TempChart: Record Chart temporary; var LookupOK: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('CustomizeChart(' + 'TempChart=' + Format(TempChart.Count()) + ',' + 'LookupOK=' + Format(LookupOK) + ')');
        if Log.Mode() = 2 then begin
            LookupOK := not LookupOK;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenSettings', '', false, false)]
    local procedure OpenSettings()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenSettings');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenContactMSSales', '', false, false)]
    local procedure OpenContactMSSales()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenContactMSSales');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenDebugger', '', false, false)]
    local procedure OpenDebugger()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenDebugger');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'InvokeExtensionInstallation', '', false, false)]
    local procedure InvokeExtensionInstallation(AppId: Text; ResponseUrl: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('InvokeExtensionInstallation(' + 'AppId=' + AppId + ',' + 'ResponseUrl=' + ResponseUrl + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenLastErrorPage', '', false, false)]
    local procedure OpenLastErrorPage()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenLastErrorPage');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetSupportInformation', '', false, false)]
    local procedure GetSupportInformation(var Name: Text; var Email: Text; var Url: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetSupportInformation(' + 'Name=' + Name + ',' + 'Email=' + Email + ',' + 'Url=' + Url + ')');
        if Log.Mode() = 2 then begin
            Name := 'W:Name';
            Email := 'W:Email';
            Url := 'W:Url';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'SetNotificationStatus', '', false, false)]
    local procedure SetNotificationStatus(NotificationId: Guid; Enable: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('SetNotificationStatus(' + 'NotificationId=' + Format(NotificationId) + ',' + 'Enable=' + Format(Enable) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetNotificationStatus', '', false, false)]
    local procedure GetNotificationStatus(NotificationId: Guid; var IsEnabled: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetNotificationStatus(' + 'NotificationId=' + Format(NotificationId) + ',' + 'IsEnabled=' + Format(IsEnabled) + ')');
        if Log.Mode() = 2 then begin
            IsEnabled := not IsEnabled;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenRoleBasedSetupExperience', '', false, false)]
    local procedure OpenRoleBasedSetupExperience()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenRoleBasedSetupExperience');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenGeneralSetupExperience', '', false, false)]
    local procedure OpenGeneralSetupExperience()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenGeneralSetupExperience');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenAppSourceMarket', '', false, false)]
    local procedure OpenAppSourceMarket()
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenAppSourceMarket');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetAutoStartTours', '', false, false)]
    local procedure GetAutoStartTours(var IsEnabled: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetAutoStartTours(' + 'IsEnabled=' + Format(IsEnabled) + ')');
        if Log.Mode() = 2 then begin
            IsEnabled := not IsEnabled;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetIsLegacyActionBarEnabled', '', false, false)]
    local procedure GetIsLegacyActionBarEnabled(var IsEnabled: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetIsLegacyActionBarEnabled(' + 'IsEnabled=' + Format(IsEnabled) + ')');
        if Log.Mode() = 2 then begin
            IsEnabled := not IsEnabled;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'ConfirmPrivacyNoticeApproval', '', false, false)]
    local procedure ConfirmPrivacyNoticeApproval(PrivacyNoticeIntegrationName: Text; var IsApproved: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('ConfirmPrivacyNoticeApproval(' + 'PrivacyNoticeIntegrationName=' + PrivacyNoticeIntegrationName + ',' + 'IsApproved=' + Format(IsApproved) + ')');
        if Log.Mode() = 2 then begin
            IsApproved := not IsApproved;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPrivacyNoticeApprovalState', '', false, false)]
    local procedure GetPrivacyNoticeApprovalState(PrivacyNoticeIntegrationName: Text; var PrivacyNoticeApprovalState: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetPrivacyNoticeApprovalState(' + 'PrivacyNoticeIntegrationName=' + PrivacyNoticeIntegrationName + ',' + 'PrivacyNoticeApprovalState=' + Format(PrivacyNoticeApprovalState) + ')');
        if Log.Mode() = 2 then begin
            PrivacyNoticeApprovalState := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPowerPlatformEnvironmentId', '', false, false)]
    local procedure GetPowerPlatformEnvironmentId(Scenario: Text; var EnvironmentId: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetPowerPlatformEnvironmentId(' + 'Scenario=' + Scenario + ',' + 'EnvironmentId=' + EnvironmentId + ')');
        if Log.Mode() = 2 then begin
            EnvironmentId := 'W:EnvironmentId';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPerformanceTroubleshooterPageId', '', false, false)]
    local procedure GetPerformanceTroubleshooterPageId(var PageId: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetPerformanceTroubleshooterPageId(' + 'PageId=' + Format(PageId) + ')');
        if Log.Mode() = 2 then begin
            PageId := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetProfilerSchedulesPageId', '', false, false)]
    local procedure GetProfilerSchedulesPageId(var PageId: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetProfilerSchedulesPageId(' + 'PageId=' + Format(PageId) + ')');
        if Log.Mode() = 2 then begin
            PageId := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetFindEntriesPageId', '', false, false)]
    local procedure GetFindEntriesPageId(var PageId: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetFindEntriesPageId(' + 'PageId=' + Format(PageId) + ')');
        if Log.Mode() = 2 then begin
            PageId := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetDataSearchPageId', '', false, false)]
    local procedure GetDataSearchPageId(var PageId: Integer)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetDataSearchPageId(' + 'PageId=' + Format(PageId) + ')');
        if Log.Mode() = 2 then begin
            PageId := 424242;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenDataSearchPage', '', false, false)]
    local procedure OpenDataSearchPage(SearchValue: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OpenDataSearchPage(' + 'SearchValue=' + SearchValue + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetCopilotCapabilityStatus', '', false, false)]
    local procedure GetCopilotCapabilityStatus(Capability: Integer; var IsEnabled: Boolean; AppId: Guid; Silent: Boolean)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetCopilotCapabilityStatus(' + 'Capability=' + Format(Capability) + ',' + 'IsEnabled=' + Format(IsEnabled) + ',' + 'AppId=' + Format(AppId) + ',' + 'Silent=' + Format(Silent) + ')');
        if Log.Mode() = 2 then begin
            IsEnabled := not IsEnabled;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetDataSearchSetup', '', false, false)]
    local procedure GetDataSearchSetup(var SetupInfo: JsonArray)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetDataSearchSetup(' + 'SetupInfo=' + Txt(SetupInfo) + ')');
        if Log.Mode() = 2 then begin
            SetupInfo.Add('W:set');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetDisplayPageId', '', false, false)]
    local procedure GetDisplayPageId(TableNo: Integer; SystemId: Guid; var DisplayPageId: Integer; var DisplayTableNo: Integer; var DisplaySystemId: Guid)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetDisplayPageId(' + 'TableNo=' + Format(TableNo) + ',' + 'SystemId=' + Format(SystemId) + ',' + 'DisplayPageId=' + Format(DisplayPageId) + ',' + 'DisplayTableNo=' + Format(DisplayTableNo) + ',' + 'DisplaySystemId=' + Format(DisplaySystemId) + ')');
        if Log.Mode() = 2 then begin
            DisplayPageId := 424242;
            DisplayTableNo := 424242;
            DisplaySystemId := '{11111111-2222-3333-4444-555555555555}';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetCopilotCapabilityInfo', '', false, false)]
    local procedure GetCopilotCapabilityInfo(Capability: Integer; AppId: Guid; var CapabilityInfo: JsonObject)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetCopilotCapabilityInfo(' + 'Capability=' + Format(Capability) + ',' + 'AppId=' + Format(AppId) + ',' + 'CapabilityInfo=' + Txt(CapabilityInfo) + ')');
        if Log.Mode() = 2 then begin
            CapabilityInfo.Add('W', 'set');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPageSummary', '', false, false)]
    local procedure GetPageSummary(PageId: Integer; Bookmark: Text; var Summary: Text)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('GetPageSummary(' + 'PageId=' + Format(PageId) + ',' + 'Bookmark=' + Bookmark + ',' + 'Summary=' + Summary + ')');
        if Log.Mode() = 2 then begin
            Summary := 'W:Summary';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnCopilotFeedbackProperties', '', false, false)]
    local procedure OnCopilotFeedbackProperties(CustomDimensions: JsonObject)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OnCopilotFeedbackProperties(' + 'CustomDimensions=' + Txt(CustomDimensions) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnCopilotSystemActionInvokedProperties', '', false, false)]
    local procedure OnCopilotSystemActionInvokedProperties(CustomDimensions: JsonObject)
    var
        Log: Codeunit "LT W Pt Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('OnCopilotSystemActionInvokedProperties(' + 'CustomDimensions=' + Txt(CustomDimensions) + ')');
    end;

}
