// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 69840 - 69861
// Probe: platform events of the Global, Company, Extension, Upgrade, Environment, User, Debugger, SmartList, System Action and Reporting
//        trigger codeunits. One subscriber codeunit subscribes to all of them; it logs each call with its arguments and, when a test asks, changes
//        the var arguments.
// BC versions: 27 - 29

table 69840 "LT V Event Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Event Name"; Text[60]) { }
        field(3; Info; Text[250]) { }
        field(4; "Session Id"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 69841 "LT V Row A"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69842 "LT V Row B"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69843 "LT V Row C"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69844 "LT V Row D"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69845 "LT V Row E"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69846 "LT V Row F"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69847 "LT V Row G"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69848 "LT V Row H"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69849 "LT V Row I"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69850 "LT V Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        EarlyEntries: List of [Text];
        Settings: Dictionary of [Text, Text];
        Active: Boolean;

    procedure Start()
    begin
        Clear(Entries);
        Clear(Settings);
        Active := true;
    end;

    procedure Stop()
    begin
        Active := false;
    end;

    procedure IsActive(): Boolean
    begin
        exit(Active);
    end;

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries.Add(Entry);
    end;

    procedure AddEarly(Entry: Text)
    begin
        EarlyEntries.Add(Entry);
    end;

    procedure Early(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in EarlyEntries do
            R += E + ';';
        exit(R);
    end;

    procedure Take(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        Clear(Entries);
        exit(R);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure SetValue(SettingName: Text; SettingValue: Text)
    begin
        Settings.Set(SettingName, SettingValue);
    end;

    procedure Has(SettingName: Text): Boolean
    begin
        exit(Settings.ContainsKey(SettingName));
    end;

    procedure GetValue(SettingName: Text): Text
    var
        V: Text;
    begin
        if Settings.Get(SettingName, V) then
            exit(V);
        exit('');
    end;

    procedure ChangeIs(EventName: Text): Boolean
    begin
        exit(Active and (GetValue('change') = EventName));
    end;
}

codeunit 69851 "LT V Subs"
{
    var
        Log: Codeunit "LT V Log";

    local procedure IsRow(TableId: Integer): Boolean
    begin
        exit((TableId >= Database::"LT V Row A") and (TableId <= Database::"LT V Row I"));
    end;

    local procedure Show(RecRef: RecordRef): Text
    begin
        exit(Format(RecRef.Field(1).Value) + '/' + Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
    end;

    local procedure WriteRow(EventName: Text; Info: Text)
    var
        Row: Record "LT V Event Log";
    begin
        Row.Init();
        Row."Event Name" := CopyStr(EventName, 1, MaxStrLen(Row."Event Name"));
        Row.Info := CopyStr(Info, 1, MaxStrLen(Row.Info));
        Row."Session Id" := SessionId();
        if Row.Insert() then;
    end;

    local procedure Note(EventName: Text; Info: Text)
    begin
        Log.Add(EventName + '(' + Info + ')');
        Log.AddEarly(EventName + '(' + Info + ')');
    end;

    // ---- Global Triggers ----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure GtMask(TableId: Integer; var TableTriggerMask: Integer)
    begin
        if not IsRow(TableId) or not Log.IsActive() then
            exit;
        Log.Add('Mask(' + Format(TableId) + ',in=' + Format(TableTriggerMask) + ')');
        case TableId of
            Database::"LT V Row B", Database::"LT V Row D", Database::"LT V Row I":
                TableTriggerMask := 15;
            Database::"LT V Row C", Database::"LT V Row E", Database::"LT V Row F", Database::"LT V Row G", Database::"LT V Row H":
                TableTriggerMask := 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GtSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if not IsRow(TableId) or not Log.IsActive() then
            exit;
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): the inbound flags are NoNoNoNo on Linux and YesYesYesYes on Windows (other subscribers run first); not asserted, so they are not logged.
        Log.Add('Setup(' + Format(TableId) + ')');
        case TableId of
            Database::"LT V Row B":
                begin
                    OnDatabaseInsert := false;
                    OnDatabaseModify := false;
                    OnDatabaseDelete := false;
                    OnDatabaseRename := false;
                end;
            Database::"LT V Row C", Database::"LT V Row D", Database::"LT V Row I":
                begin
                    OnDatabaseInsert := true;
                    OnDatabaseModify := true;
                    OnDatabaseDelete := true;
                    OnDatabaseRename := true;
                end;
            Database::"LT V Row E":
                OnDatabaseInsert := true;
            Database::"LT V Row F":
                OnDatabaseModify := true;
            Database::"LT V Row G":
                OnDatabaseDelete := true;
            Database::"LT V Row H":
                OnDatabaseRename := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure GtGlobalInsert(RecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('GI(' + Show(RecRef) + ')');
        if RecRef.Number = Database::"LT V Row I" then
            RecRef.Field(3).Value := 7;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure GtGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('GM(' + Show(RecRef) + ' was ' + Show(xRecRef) + ')');
        if RecRef.Number = Database::"LT V Row I" then
            RecRef.Field(3).Value := 8;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure GtGlobalDelete(RecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('GD(' + Show(RecRef) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure GtGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('GR(' + Show(RecRef) + ' was ' + Show(xRecRef) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure GtDbInsert(RecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('DI(' + Show(RecRef) + ')');
        if RecRef.Number = Database::"LT V Row I" then
            RecRef.Field(2).Value := 'dbmut';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure GtDbModify(RecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('DM(' + Show(RecRef) + ')');
        if RecRef.Number = Database::"LT V Row I" then
            RecRef.Field(2).Value := 'dbmod';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure GtDbDelete(RecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('DD(' + Show(RecRef) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure GtDbRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        if not IsRow(RecRef.Number) or not Log.IsActive() then
            exit;
        Log.Add('DR(' + Show(RecRef) + ' was ' + Show(xRecRef) + ')');
    end;

    // ---- Company, extension, upgrade, environment, user ----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CoOpen()
    begin
        Note('OnCompanyOpen', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CoOpenCompleted()
    begin
        Note('OnCompanyOpenCompleted', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyClose', '', false, false)]
    local procedure CoClose()
    begin
        Note('OnCompanyClose', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure ExtInstallPerCompany()
    begin
        Note('OnInstallAppPerCompany', CompanyName());
        WriteRow('OnInstallAppPerCompany', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure ExtInstallPerDatabase()
    begin
        Note('OnInstallAppPerDatabase', '');
        WriteRow('OnInstallAppPerDatabase', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnUpgradePerCompany', '', false, false)]
    local procedure UpUpgradePerCompany()
    begin
        Note('OnUpgradePerCompany', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnUpgradePerDatabase', '', false, false)]
    local procedure UpUpgradePerDatabase()
    begin
        Note('OnUpgradePerDatabase', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnValidateUpgradePerCompany', '', false, false)]
    local procedure UpValidatePerCompany()
    begin
        Note('OnValidateUpgradePerCompany', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnValidateUpgradePerDatabase', '', false, false)]
    local procedure UpValidatePerDatabase()
    begin
        Note('OnValidateUpgradePerDatabase', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnAfterUpgradeCommitPerCompany', '', false, false)]
    local procedure UpCommitPerCompany()
    begin
        Note('OnAfterUpgradeCommitPerCompany', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Triggers", 'OnAfterUpgradeCommitPerDatabase', '', false, false)]
    local procedure UpCommitPerDatabase()
    begin
        Note('OnAfterUpgradeCommitPerDatabase', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerCompany', '', false, false)]
    local procedure EnvCopyPerCompany(SourceEnvironmentType: Option Production,Sandbox; SourceEnvironmentName: Text; DestinationEnvironmentType: Option Production,Sandbox; DestinationEnvironmentName: Text)
    begin
        Note('OnAfterCopyEnvironmentPerCompany', Format(SourceEnvironmentType) + '/' + SourceEnvironmentName + '/' + Format(DestinationEnvironmentType) + '/' + DestinationEnvironmentName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure EnvCopyPerDatabase(SourceEnvironmentType: Option Production,Sandbox; SourceEnvironmentName: Text; DestinationEnvironmentType: Option Production,Sandbox; DestinationEnvironmentName: Text)
    begin
        Note('OnAfterCopyEnvironmentPerDatabase', Format(SourceEnvironmentType) + '/' + SourceEnvironmentName + '/' + Format(DestinationEnvironmentType) + '/' + DestinationEnvironmentName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentToSandbox', '', false, false)]
    local procedure EnvCopyToSandbox()
    begin
        Note('OnAfterCopyEnvironmentToSandbox', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentToSandboxPerCompany', '', false, false)]
    local procedure EnvCopyToSandboxPerCompany()
    begin
        Note('OnAfterCopyEnvironmentToSandboxPerCompany', CompanyName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Triggers", 'OnAfterUserInitialization', '', false, false)]
    local procedure UserInit()
    begin
        Note('OnAfterUserInitialization', '');
    end;

    // ---- Debugger, SmartList designer, system actions ----

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Debugger Triggers", 'OnDebuggerBreak', '', false, false)]
    local procedure DbgBreak(ErrorMessage: Text)
    begin
        Log.Add('OnDebuggerBreak(' + ErrorMessage + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Triggers", 'OnCreateForTable', '', false, false)]
    local procedure SlCreateForTable(TableId: Integer)
    begin
        Log.Add('OnCreateForTable(' + Format(TableId) + ')');
    end;
#pragma warning restore AL0432

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Triggers", 'OnCreateNewForTableAndView', '', false, false)]
    local procedure SlCreateNew(TableId: Integer; ViewId: Text)
    begin
        Log.Add('OnCreateNewForTableAndView(' + Format(TableId) + ',' + ViewId + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Triggers", 'OnEditQuery', '', false, false)]
    local procedure SlEditQuery(QueryId: Text)
    begin
        Log.Add('OnEditQuery(' + QueryId + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Triggers", 'OnInvalidQueryNavigation', '', false, false)]
    local procedure SlInvalidNav(Id: BigInteger)
    begin
        Log.Add('OnInvalidQueryNavigation(' + Format(Id) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnEditInExcel', '', false, false)]
    local procedure SaEditInExcel(ServiceName: Text[240]; ODataFilter: Text)
    begin
        Log.Add('OnEditInExcel(' + ServiceName + ',' + ODataFilter + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnEditInExcelWithSearchString', '', false, false)]
    local procedure SaEditInExcelSearch(ServiceName: Text[240]; ODataFilter: Text; SearchString: Text)
    begin
        Log.Add('OnEditInExcelWithSearchString(' + ServiceName + ',' + ODataFilter + ',' + SearchString + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnEditInExcelWithStructuredFilter', '', false, false)]
    local procedure SaEditInExcelStructured(ServiceName: Text[240]; SearchString: Text; Filter: JsonObject; Payload: JsonObject)
    begin
        Log.Add('OnEditInExcelWithStructuredFilter(' + ServiceName + ',' + SearchString + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnOpenInExcel', '', false, false)]
    local procedure SaOpenInExcel(Location: Text)
    begin
        Log.Add('OnOpenInExcel(' + Location + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'ChangeCompany', '', false, false)]
    local procedure SaChangeCompany(var NewCompanyName: Text)
    begin
        Log.Add('ChangeCompany(' + NewCompanyName + ')');
        if Log.ChangeIs('ChangeCompany') then
            NewCompanyName := Log.GetValue('company');
    end;

    // ---- Reporting Triggers ----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPrinterName', '', false, false)]
    local procedure RtPrinterName(ReportID: Integer; var PrinterName: Text[250])
    begin
        Log.Add('GetPrinterName(' + Format(ReportID) + ',in=' + PrinterName + ')');
        if Log.ChangeIs('GetPrinterName') then
            PrinterName := 'LT V Printer';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPaperTrayForReport', '', false, false)]
    local procedure RtPaperTray(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
        Log.Add('GetPaperTrayForReport(' + Format(ReportID) + ',in=' + Format(FirstPage) + '/' + Format(DefaultPage) + '/' + Format(LastPage) + ')');
        if Log.ChangeIs('GetPaperTrayForReport') then begin
            FirstPage := 1;
            DefaultPage := 2;
            LastPage := 3;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'HasCustomLayout', '', false, false)]
    local procedure RtHasCustomLayout(ObjectType: Option Report,Page; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
        Log.Add('HasCustomLayout(' + Format(ObjectType) + ',' + Format(ObjectID) + ',in=' + Format(LayoutType) + ')');
        if Log.ChangeIs('HasCustomLayout') then
            LayoutType := LayoutType::Word;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'CustomDocumentMergerEx', '', false, false)]
    local procedure RtCustomMerger(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var Success: Boolean)
    begin
        Log.Add('CustomDocumentMergerEx(' + Format(ObjectID) + ',' + Format(ReportAction) + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('CustomDocumentMergerEx') then begin
            DocumentStream.WriteText('LTV merged');
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ScheduleReport', '', false, false)]
    local procedure RtSchedule(ReportId: Integer; RequestPageXml: Text; var Scheduled: Boolean)
    begin
        Log.Add('ScheduleReport(' + Format(ReportId) + ',in=' + Format(Scheduled) + ')');
        if Log.ChangeIs('ScheduleReport') then
            Scheduled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure RtSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        Log.Add('SubstituteReport(' + Format(ReportId) + ',' + Format(RunMode) + ',in=' + Format(NewReportId) + ')');
        if Log.ChangeIs('SubstituteReport') then
            if ReportId = Report::"LT V Report A" then
                NewReportId := Report::"LT V Report B";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentPrintReady', '', false, false)]
    local procedure RtPrintReady(ObjectType: Option Report,Page; ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        Log.Add('OnDocumentPrintReady(' + Format(ObjectType) + ',' + Format(ObjectId) + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('OnDocumentPrintReady') then
            Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure RtDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        Log.Add('OnDocumentReady(' + Format(ObjectId) + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('OnDocumentReady') then begin
            TargetStream.WriteText('LTV ready');
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnIntermediateDocumentReady', '', false, false)]
    local procedure RtIntermediateReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        Log.Add('OnIntermediateDocumentReady(' + Format(ObjectId) + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('OnIntermediateDocumentReady') then begin
            TargetStream.WriteText('LTV intermediate');
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentDownload', '', false, false)]
    local procedure RtDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        Log.Add('OnDocumentDownload(' + Format(ObjectId) + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('OnDocumentDownload') then
            Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SetupPrinters', '', false, false)]
    local procedure RtSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    var
        Printer: JsonObject;
    begin
        Log.Add('SetupPrinters(in=' + Format(Printers.Count()) + ')');
        if Log.ChangeIs('SetupPrinters') then
            Printers.Add('LT V Printer', Printer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutCode', '', false, false)]
    local procedure RtSelectLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var Success: Boolean)
    begin
        Log.Add('SelectReportLayoutCode(' + Format(ObjectId) + ',in=' + LayoutCode + '/' + Format(LayoutType) + '/' + Format(Success) + ')');
        if Log.ChangeIs('SelectReportLayoutCode') then begin
            LayoutCode := 'LTV';
            LayoutType := LayoutType::RDLC;
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'FetchReportLayoutByCode', '', false, false)]
    local procedure RtFetchLayout(ObjectId: Integer; LayoutCode: Text; var TargetStream: OutStream; var Success: Boolean)
    begin
        Log.Add('FetchReportLayoutByCode(' + Format(ObjectId) + ',' + LayoutCode + ',in=' + Format(Success) + ')');
        if Log.ChangeIs('FetchReportLayoutByCode') then begin
            TargetStream.WriteText('LTV layout');
            Success := true;
        end;
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ApplicationReportMergeStrategy', '', false, false)]
    local procedure RtAppMerge(ObjectId: Integer; LayoutCode: Text; var InApplication: Boolean)
    begin
        Log.Add('ApplicationReportMergeStrategy(' + Format(ObjectId) + ',' + LayoutCode + ',in=' + Format(InApplication) + ')');
        if Log.ChangeIs('ApplicationReportMergeStrategy') then
            InApplication := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'WordDocumentMergerAppMode', '', false, false)]
    local procedure RtWordAppMode(ObjectId: Integer; LayoutCode: Text; var InApplication: Boolean)
    begin
        Log.Add('WordDocumentMergerAppMode(' + Format(ObjectId) + ',' + LayoutCode + ',in=' + Format(InApplication) + ')');
        if Log.ChangeIs('WordDocumentMergerAppMode') then
            InApplication := true;
    end;
#pragma warning restore AL0432

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectedBuiltinLayoutType', '', false, false)]
    local procedure RtBuiltinLayout(ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
        Log.Add('SelectedBuiltinLayoutType(' + Format(ObjectID) + ',in=' + Format(LayoutType) + ')');
        if Log.ChangeIs('SelectedBuiltinLayoutType') then
            LayoutType := LayoutType::RDLC;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutUI', '', false, false)]
    local procedure RtSelectLayoutUi(ObjectId: Integer; var LayoutName: Text; var LayoutAppID: Guid; var Success: Boolean)
    begin
        Log.Add('SelectReportLayoutUI(' + Format(ObjectId) + ',in=' + LayoutName + '/' + Format(Success) + ')');
        if Log.ChangeIs('SelectReportLayoutUI') then begin
            LayoutName := 'LTV';
            Success := true;
        end;
    end;
}

codeunit 69855 "LT V Session Worker"
{
    trigger OnRun()
    var
        Row: Record "LT V Event Log";
    begin
        Row.Init();
        Row."Event Name" := 'Worker';
        Row."Session Id" := SessionId();
        Row.Info := CopyStr(Log.Early(), 1, MaxStrLen(Row.Info));
        Row.Insert();
    end;

    var
        Log: Codeunit "LT V Log";
}

report 69860 "LT V Report A"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(P; "Probe Rep Parent")
        {
            column(PNo; Id) { }
            column(PName; Name) { }
            column(PAmt; Amt) { }
            column(PDate; D) { }
            column(PBool; B) { }

            dataitem(C; "Probe Rep Child")
            {
                DataItemLink = ParentId = field(Id);

                column(CNo; Id) { }
                column(CCode; Code) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Prefix; Prefix) { ApplicationArea = All; }
                }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout.rdl';
            Caption = 'LT V layout A';
        }
    }

    var
        Prefix: Text;
}

report 69861 "LT V Report B"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(P; "Probe Rep Parent")
        {
            column(PNo; Id) { }
            column(PName; Name) { }
            column(PAmt; Amt) { }
            column(PDate; D) { }
            column(PBool; B) { }

            dataitem(C; "Probe Rep Child")
            {
                DataItemLink = ParentId = field(Id);

                column(CNo; Id) { }
                column(CCode; Code) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Prefix; Prefix) { ApplicationArea = All; }
                }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout.rdl';
            Caption = 'LT V layout B';
        }
    }

    var
        Prefix: Text;
}
