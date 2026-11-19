// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-eventsubscriber-attribute
// Scope: in-scope
// Fixtures for SbiSubscriberByIdTests.al (al-runner issue 8470 part 1): event subscribers that name their publisher by its object id
//   ([EventSubscriber(ObjectType::Codeunit, 76257, ...)]) instead of by name (Codeunit::"LT SBI Publisher"). The forms Codeunit::76257 and
//   Database::76250 do not compile (syntax error AL0104, must-not-compile cases 3216 to 3221).
// Publishers: an own codeunit (integration, business and IncludeSender events), an own table, an own page, an own report, and the platform
//   codeunits by literal id: Global Triggers 2000000002, Company Triggers 2000000003, UI Helper Triggers 2000000004, Reporting Triggers
//   2000000005, Filter Helper Triggers 2000000007, Extension Triggers 2000000010, and the System Application codeunits Caption Class 42 and
//   Auto Format 45 (ids read from the symbol packages of BC 29).
// Each subscriber appends a tag to "LT SBI Log" (SingleInstance, used by the test codeunit only). Static subscribers to platform and table
//   events write only while a test has called Log.Start() (Active), so they stay silent for every other test. The Company Triggers
//   subscribers write a list of their own (they run when the session opens the company). The Extension Triggers subscribers write rows of
//   "LT SBI Install Log" (DataPerCompany = false) with if Insert() then; (install code must never fail).
// BC versions: 27 - 29

// local object: own rows for the table, page, report, Filter Helper and Auto Format cells.
table 76250 "LT SBI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; D; Date) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// local object: the Global Triggers setup for this table is answered by the subscriber written by id.
table 76251 "LT SBI GT Row A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// local object: the Global Triggers setup for this table is answered by the subscriber written by name.
table 76252 "LT SBI GT Row B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// local object: rows written by the Extension Triggers subscribers while the app is installed.
table 76253 "LT SBI Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[60]) { }
        field(3; Company; Text[60]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// local object: page events by id.
page 76254 "LT SBI Card"
{
    PageType = Card;
    SourceTable = "LT SBI Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

// local object: the Auto Format cell (AutoFormatType is the enum extension value 76270). Only the Auto Format test opens this page: in a
// first run the Auto Format events ran at the first open of a page with this control and not at a later open in the same session.
page 76268 "LT SBI Format Card"
{
    PageType = Card;
    SourceTable = "LT SBI Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Amount; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 76270;
                AutoFormatExpression = 'LTSBI';
            }
        }
    }
}

// local object: a report that publishes an event of its own, and the report the SubstituteReport cell runs.
report 76255 "LT SBI Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT SBI Row") { }
    }

    [IntegrationEvent(false, false)]
    procedure OnSbiReport(var Log: Text)
    begin
    end;

    procedure RaiseIt(): Text
    var
        L: Text;
    begin
        OnSbiReport(L);
        exit(L);
    end;
}

enumextension 76270 "LT SBI Auto Format" extends "Auto Format"
{
    value(76270; "LT SBI Fmt") { }
}

codeunit 76256 "LT SBI Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Opens: Text;
        Active: Boolean;

    procedure Start()
    begin
        Entries := '';
        Active := true;
    end;

    procedure Stop(): Text
    begin
        Active := false;
        exit(Take());
    end;

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure AddOpen(Entry: Text)
    begin
        Opens += Entry + ';';
    end;

    procedure OpenText(): Text
    begin
        exit(Opens);
    end;
}

codeunit 76257 "LT SBI Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnSbiOne(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSbiCross(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSbiManual(var Log: Text)
    begin
    end;

    [BusinessEvent(false)]
    procedure OnSbiBusiness(var Log: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnSbiSender(var Log: Text)
    begin
    end;

    procedure Marker(): Text
    begin
        exit('pub');
    end;

    procedure RaiseOne(): Text
    var
        L: Text;
    begin
        OnSbiOne(L);
        exit(L);
    end;

    procedure RaiseCross(): Text
    var
        L: Text;
    begin
        OnSbiCross(L);
        exit(L);
    end;

    procedure RaiseManual(): Text
    var
        L: Text;
    begin
        OnSbiManual(L);
        exit(L);
    end;

    procedure RaiseBusiness(): Text
    var
        L: Text;
    begin
        OnSbiBusiness(L);
        exit(L);
    end;

    procedure RaiseSender(): Text
    var
        L: Text;
    begin
        OnSbiSender(L);
        exit(L);
    end;
}

// One subscriber codeunit, both forms. Declared in reverse alphabetical order of the method names; the forms alternate.
codeunit 76258 "LT SBI Subs One"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiOne', '', false, false)]
    local procedure D_Name2(var Log: Text)
    begin
        Log += 'D_Name2;';
    end;

    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiOne', '', false, false)]
    local procedure C_Id2(var Log: Text)
    begin
        Log += 'C_Id2;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiOne', '', false, false)]
    local procedure B_Name(var Log: Text)
    begin
        Log += 'B_Name;';
    end;

    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiOne', '', false, false)]
    local procedure A_Id(var Log: Text)
    begin
        Log += 'A_Id;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiManual', '', false, false)]
    local procedure M_StaticName(var Log: Text)
    begin
        Log += 'M_StaticName;';
    end;

    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiBusiness', '', false, false)]
    local procedure Biz_Id(var Log: Text)
    begin
        Log += 'Biz_Id;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiBusiness', '', false, false)]
    local procedure Biz_Name(var Log: Text)
    begin
        Log += 'Biz_Name;';
    end;

    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiSender', '', false, false)]
    local procedure Snd_Id(sender: Codeunit "LT SBI Publisher"; var Log: Text)
    begin
        Log += 'Snd_Id(' + sender.Marker() + ');';
    end;
}

// Three subscriber codeunits: the ids ascend while the names descend; the middle one names the publisher by id.
codeunit 76259 "LT SBI Z Low"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiCross', '', false, false)]
    local procedure OnCross(var Log: Text)
    begin
        Log += 'ZLow_Name;';
    end;
}

codeunit 76260 "LT SBI M Mid"
{
    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiCross', '', false, false)]
    local procedure OnCross(var Log: Text)
    begin
        Log += 'MMid_Id;';
    end;
}

codeunit 76261 "LT SBI A High"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SBI Publisher", 'OnSbiCross', '', false, false)]
    local procedure OnCross(var Log: Text)
    begin
        Log += 'AHigh_Name;';
    end;
}

codeunit 76262 "LT SBI Manual By Id"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, 76257, 'OnSbiManual', '', false, false)]
    local procedure ManualId(var Log: Text)
    begin
        Log += 'ManualId;';
    end;
}

codeunit 76263 "LT SBI Table Subs"
{
    [EventSubscriber(ObjectType::Table, 76250, 'OnBeforeInsertEvent', '', false, false)]
    local procedure A_BeforeInsertId(var Rec: Record "LT SBI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('A_BeforeInsertId(' + Format(Rec.Id) + ',' + Format(RunTrigger) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SBI Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure B_BeforeInsertName(var Rec: Record "LT SBI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('B_BeforeInsertName(' + Format(Rec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, 76250, 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsertId(var Rec: Record "LT SBI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('AfterInsertId(' + Format(Rec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, 76250, 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModifyId(var Rec: Record "LT SBI Row"; var xRec: Record "LT SBI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('AfterModifyId(' + Rec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Table, 76250, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteId(var Rec: Record "LT SBI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('AfterDeleteId(' + Format(Rec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, 76250, 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure V_AfterValidateNameId(var Rec: Record "LT SBI Row"; var xRec: Record "LT SBI Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('V_AfterValidateNameId(' + Rec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT SBI Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure W_AfterValidateNameName(var Rec: Record "LT SBI Row"; var xRec: Record "LT SBI Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('W_AfterValidateNameName(' + Rec.Name + ')');
    end;
}

codeunit 76264 "LT SBI Page Subs"
{
    [EventSubscriber(ObjectType::Page, 76254, 'OnOpenPageEvent', '', false, false)]
    local procedure A_OpenId(var Rec: Record "LT SBI Row")
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('A_OpenId');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT SBI Card", 'OnOpenPageEvent', '', false, false)]
    local procedure B_OpenName(var Rec: Record "LT SBI Row")
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('B_OpenName');
    end;

    [EventSubscriber(ObjectType::Page, 76254, 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure C_ValidateNameId(var Rec: Record "LT SBI Row"; var xRec: Record "LT SBI Row")
    var
        L: Codeunit "LT SBI Log";
    begin
        L.Add('C_ValidateNameId(' + Rec.Name + ')');
    end;
}

codeunit 76265 "LT SBI Report Subs"
{
    [EventSubscriber(ObjectType::Report, 76255, 'OnSbiReport', '', false, false)]
    local procedure A_ReportId(var Log: Text)
    begin
        Log += 'A_ReportId;';
    end;

    [EventSubscriber(ObjectType::Report, Report::"LT SBI Report", 'OnSbiReport', '', false, false)]
    local procedure B_ReportName(var Log: Text)
    begin
        Log += 'B_ReportName;';
    end;
}

codeunit 76266 "LT SBI Platform Subs"
{
    // Global Triggers (2000000002)
    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure G1_SetupId(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if TableId = Database::"LT SBI GT Row A" then begin
            L.Add('G1_SetupId(A)');
            OnDatabaseInsert := true;
        end;
        if TableId = Database::"LT SBI GT Row B" then
            L.Add('G1_SetupId(B)');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure G2_SetupName(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if TableId = Database::"LT SBI GT Row B" then begin
            L.Add('G2_SetupName(B)');
            OnDatabaseInsert := true;
        end;
        if TableId = Database::"LT SBI GT Row A" then
            L.Add('G2_SetupName(A)');
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnDatabaseInsert', '', false, false)]
    local procedure G3_InsertId(RecRef: RecordRef)
    var
        L: Codeunit "LT SBI Log";
    begin
        if RecRef.Number = Database::"LT SBI GT Row A" then
            L.Add('G3_InsertId(A)');
        if RecRef.Number = Database::"LT SBI GT Row B" then
            L.Add('G3_InsertId(B)');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure G4_InsertName(RecRef: RecordRef)
    var
        L: Codeunit "LT SBI Log";
    begin
        if RecRef.Number = Database::"LT SBI GT Row A" then
            L.Add('G4_InsertName(A)');
        if RecRef.Number = Database::"LT SBI GT Row B" then
            L.Add('G4_InsertName(B)');
    end;

    // UI Helper Triggers (2000000004)
    [EventSubscriber(ObjectType::Codeunit, 2000000004, 'CaptionClassTranslate', '', false, false)]
    local procedure U1_TranslateId(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    var
        L: Codeunit "LT SBI Log";
    begin
        if not CaptionExpr.StartsWith('LTSBIU,') then
            exit;
        L.Add('U1_TranslateId(in=' + Translation + ')');
        Translation := 'U-id';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'CaptionClassTranslate', '', false, false)]
    local procedure U2_TranslateName(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    var
        L: Codeunit "LT SBI Log";
    begin
        if not CaptionExpr.StartsWith('LTSBIU,') then
            exit;
        L.Add('U2_TranslateName(in=' + Translation + ')');
    end;

    // Caption Class (42, System Application)
    [EventSubscriber(ObjectType::Codeunit, 42, 'OnResolveCaptionClass', '', false, false)]
    local procedure C1_ResolveId(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if CaptionArea <> 'LTSBIC' then
            exit;
        L.Add('C1_ResolveId(' + CaptionExpr + ',resolved=' + Format(Resolved) + ')');
        Caption := 'C-id:' + CaptionExpr;
        Resolved := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure C2_ResolveName(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if CaptionArea <> 'LTSBIC' then
            exit;
        L.Add('C2_ResolveName(' + CaptionExpr + ',resolved=' + Format(Resolved) + ',caption=' + Caption + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, 42, 'OnAfterCaptionClassResolve', '', false, false)]
    local procedure C3_AfterResolveId(Language: Integer; CaptionExpression: Text; var Caption: Text[1024])
    var
        L: Codeunit "LT SBI Log";
    begin
        if not CaptionExpression.StartsWith('LTSBIC,') then
            exit;
        L.Add('C3_AfterResolveId(' + Caption + ')');
    end;

    // Auto Format (45, System Application)
    [EventSubscriber(ObjectType::Codeunit, 45, 'OnResolveAutoFormat', '', false, false)]
    local procedure F1_ResolveId(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if AutoFormatType <> AutoFormatType::"LT SBI Fmt" then
            exit;
        L.Add('F1_ResolveId(' + AutoFormatExpr + ',resolved=' + Format(Resolved) + ')');
        Result := '<Precision,1:1><Standard Format,0>';
        Resolved := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure F2_ResolveName(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    var
        L: Codeunit "LT SBI Log";
    begin
        if AutoFormatType <> AutoFormatType::"LT SBI Fmt" then
            exit;
        L.Add('F2_ResolveName(' + AutoFormatExpr + ',resolved=' + Format(Resolved) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, 45, 'OnAfterResolveAutoFormat', '', false, false)]
    local procedure F3_AfterResolveId(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80])
    var
        L: Codeunit "LT SBI Log";
    begin
        if AutoFormatType <> AutoFormatType::"LT SBI Fmt" then
            exit;
        L.Add('F3_AfterResolveId(' + Result + ')');
    end;

    // Reporting Triggers (2000000005)
    [EventSubscriber(ObjectType::Codeunit, 2000000005, 'SubstituteReport', '', false, false)]
    local procedure R1_SubstituteId(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    var
        L: Codeunit "LT SBI Log";
    begin
        if ReportId <> Report::"LT SBI Report" then
            exit;
        L.Add('R1_SubstituteId(' + Format(RunMode) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure R2_SubstituteName(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    var
        L: Codeunit "LT SBI Log";
    begin
        if ReportId <> Report::"LT SBI Report" then
            exit;
        L.Add('R2_SubstituteName(' + Format(RunMode) + ')');
    end;

    // Filter Helper Triggers (2000000007)
    [EventSubscriber(ObjectType::Codeunit, 2000000007, 'MakeDateFilter', '', false, false)]
    local procedure M1_DateFilterId(var DateFilterText: Text)
    var
        L: Codeunit "LT SBI Log";
    begin
        if DateFilterText <> 'ltsbi' then
            exit;
        L.Add('M1_DateFilterId(' + DateFilterText + ')');
        DateFilterText := '2020-12-31';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeDateFilter', '', false, false)]
    local procedure M2_DateFilterName(var DateFilterText: Text)
    var
        L: Codeunit "LT SBI Log";
    begin
        if (DateFilterText <> 'ltsbi') and (DateFilterText <> '2020-12-31') then
            exit;
        L.Add('M2_DateFilterName(' + DateFilterText + ')');
    end;
}

// Company Triggers (2000000003): run when the session opens the company, before any test; they write the second list of the log.
codeunit 76267 "LT SBI Company Open Subs"
{
    [EventSubscriber(ObjectType::Codeunit, 2000000003, 'OnCompanyOpen', '', false, false)]
    local procedure A_OpenId()
    var
        L: Codeunit "LT SBI Log";
    begin
        L.AddOpen('A_OpenId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure B_OpenName()
    var
        L: Codeunit "LT SBI Log";
    begin
        L.AddOpen('B_OpenName');
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000003, 'OnCompanyOpenCompleted', '', false, false)]
    local procedure C_CompletedId()
    var
        L: Codeunit "LT SBI Log";
    begin
        L.AddOpen('C_CompletedId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure D_CompletedName()
    var
        L: Codeunit "LT SBI Log";
    begin
        L.AddOpen('D_CompletedName');
    end;
}

// Extension Triggers (2000000010): run while this app is installed. Install code must never fail: only if Insert() then; into a
// DataPerCompany = false table.
codeunit 76269 "LT SBI Install Subs"
{
    local procedure Note(Tag: Text)
    var
        Row: Record "LT SBI Install Log";
    begin
        Row.Init();
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row.Company := CopyStr(CompanyName(), 1, MaxStrLen(Row.Company));
        if Row.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000010, 'OnInstallAppPerDatabase', '', false, false)]
    local procedure A_DatabaseId()
    begin
        Note('A_DatabaseId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure B_DatabaseName()
    begin
        Note('B_DatabaseName');
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000010, 'OnInstallAppPerCompany', '', false, false)]
    local procedure C_CompanyId()
    begin
        Note('C_CompanyId');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure D_CompanyName()
    begin
        Note('D_CompanyName');
    end;
}
