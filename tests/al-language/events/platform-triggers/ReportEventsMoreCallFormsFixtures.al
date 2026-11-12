// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: own codeunits 96790 and 96791 (used by ReportEventsMoreCallForms.al only).
// Why a separate log: "LT V Log" (PeVFixtures.al) is SingleInstance and already used by test codeunit "LT V Platform Event Tests".
//   A SingleInstance fixture shared by two test codeunits is not reset between them, so codeunit 96630 keeps its own log and its own
//   manual subscriber. The subscriber only records what Reporting Triggers raises, in the same text form as "LT V Subs" and "LT PW V Arg Subs".
// BC versions: 27.5, 28.5, 29.0

codeunit 96790 "LT REV Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
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

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries.Add(Entry);
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
}

codeunit 96791 "LT REV Subs"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT REV Log";

    local procedure Append(Entry: Text)
    begin
        Log.SetValue('pwargs', Log.GetValue('pwargs') + Entry + ';');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPrinterName', '', false, false)]
    local procedure RtPrinterName(ReportID: Integer; var PrinterName: Text[250])
    begin
        Log.Add('GetPrinterName(' + Format(ReportID) + ',in=' + PrinterName + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPaperTrayForReport', '', false, false)]
    local procedure RtPaperTray(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
        Log.Add('GetPaperTrayForReport(' + Format(ReportID) + ',in=' + Format(FirstPage) + '/' + Format(DefaultPage) + '/' + Format(LastPage) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'HasCustomLayout', '', false, false)]
    local procedure RtHasCustomLayout(ObjectType: Option Report,Page; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
        Log.Add('HasCustomLayout(' + Format(ObjectType) + ',' + Format(ObjectID) + ',in=' + Format(LayoutType) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure RtSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        Log.Add('SubstituteReport(' + Format(ReportId) + ',' + Format(RunMode) + ',in=' + Format(NewReportId) + ')');
        if not Log.Has('pwcollect') then
            exit;
        Append('Sub(' + Format(RunMode) + ',xmlLen>0=' + Format(StrLen(RequestPageXml) > 0) + ',xmlHasDataItem=' + Format(RequestPageXml.Contains('<DataItem')) +
            ',xmlHasPrefix=' + Format(RequestPageXml.Contains('Prefix')) + ',recNo=' + Format(RecordRef.Number()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure RtDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        Keys: Text;
        K: Text;
        Head: Text;
        Tok: JsonToken;
        DocType: Text;
    begin
        Log.Add('OnDocumentReady(' + Format(ObjectId) + ',in=' + Format(Success) + ')');
        if not Log.Has('pwcollect') then
            exit;
        foreach K in ObjectPayload.Keys() do
            Keys += K + ',';
        if ObjectPayload.Get('documenttype', Tok) then
            DocType := Tok.AsValue().AsText();
        DocumentStream.ReadText(Head, 40);
        Append('Ready(keys=' + Keys + ' documenttype=' + DocType + ' head=' + Head + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentDownload', '', false, false)]
    local procedure RtDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        Log.Add('OnDocumentDownload(' + Format(ObjectId) + ',in=' + Format(Success) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SetupPrinters', '', false, false)]
    local procedure RtSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    begin
        Log.Add('SetupPrinters(in=' + Format(Printers.Count()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutCode', '', false, false)]
    local procedure RtSelectLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var Success: Boolean)
    begin
        Log.Add('SelectReportLayoutCode(' + Format(ObjectId) + ',in=' + LayoutCode + '/' + Format(LayoutType) + '/' + Format(Success) + ')');
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ApplicationReportMergeStrategy', '', false, false)]
    local procedure RtAppMerge(ObjectId: Integer; LayoutCode: Text; var InApplication: Boolean)
    begin
        Log.Add('ApplicationReportMergeStrategy(' + Format(ObjectId) + ',' + LayoutCode + ',in=' + Format(InApplication) + ')');
    end;
#pragma warning restore AL0432

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectedBuiltinLayoutType', '', false, false)]
    local procedure RtBuiltinLayout(ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
        Log.Add('SelectedBuiltinLayoutType(' + Format(ObjectID) + ',in=' + Format(LayoutType) + ')');
    end;
}
