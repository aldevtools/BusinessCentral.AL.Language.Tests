// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-custom
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835); own objects 70831-70834
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// LT RptMrg Capture records every call (object id, ReportAction name and ordinal, IsHandled on entry, flattened ObjectPayload, XmlData text and byte info,
// LayoutData text) and by default handles the call and writes 'LMC-OUT' to DocumentStream. LT RptMrg Sub One / Sub Two are two more manual subscribers that log into
// the single instance codeunit LT RptMrg Order Log, which only the test codeunit of ReportMergerSubscribers.al uses.
// Note: the corpus app also holds the always bound subscriber "Report Layout ByName Capture" (60532) that handles every call with 'RLB-RENDERED'.
// BC versions: 29 (the final facts get added later)

codeunit 70831 "LT RptMrg Capture"
{
    EventSubscriberInstance = Manual;

    var
        Ids: List of [Text];
        ActionNames: List of [Text];
        ActionOrdinals: List of [Text];
        EntryHandled: List of [Text];
        Payloads: List of [Text];
        PayloadKeys: List of [Text];
        XmlTexts: List of [Text];
        XmlInfos: List of [Text];
        LayoutTexts: List of [Text];
        LayoutInfos: List of [Text];
        HandleCalls: Boolean;
        HandleSet: Boolean;
        OutText: Text;

    procedure SetHandle(Value: Boolean)
    begin
        HandleSet := true;
        HandleCalls := Value;
    end;

    procedure CallCount(): Integer
    begin
        exit(Ids.Count());
    end;

    procedure Item(Kind: Text; Index: Integer): Text
    begin
        if (Index < 1) or (Index > Ids.Count()) then
            exit('<no call ' + Format(Index) + '>');
        case Kind of
            'id':
                exit(Ids.Get(Index));
            'action':
                exit(ActionNames.Get(Index));
            'ordinal':
                exit(ActionOrdinals.Get(Index));
            'entry handled':
                exit(EntryHandled.Get(Index));
            'payload':
                exit(Payloads.Get(Index));
            'payload keys':
                exit(PayloadKeys.Get(Index));
            'xml':
                exit(XmlTexts.Get(Index));
            'xml info':
                exit(XmlInfos.Get(Index));
            'layout':
                exit(LayoutTexts.Get(Index));
            'layout info':
                exit(LayoutInfos.Get(Index));
        end;
        exit('<unknown kind>');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnCustomDocumentMergerEx, '', true, true)]
    local procedure OnMerge(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Token: JsonToken;
        Ordinal: Integer;
        XmlText: Text;
        XmlInfo: Text;
        LayoutText: Text;
        LayoutInfo: Text;
        KeyList: Text;
        KeyName: Text;
    begin
        Ordinal := ReportAction;
        Ids.Add(Format(ObjectID));
        ActionNames.Add(Format(ReportAction));
        ActionOrdinals.Add(Format(Ordinal));
        EntryHandled.Add(Format(IsHandled));
        Token := ObjectPayload.AsToken();
        Payloads.Add(Helper.Flatten(Token));
        foreach KeyName in ObjectPayload.Keys() do begin
            if KeyList <> '' then
                KeyList += ',';
            KeyList += KeyName;
        end;
        PayloadKeys.Add(KeyList);
        Helper.Describe(XmlData, XmlText, XmlInfo);
        XmlTexts.Add(XmlText);
        XmlInfos.Add(XmlInfo);
        Helper.Describe(LayoutData, LayoutText, LayoutInfo);
        LayoutTexts.Add(LayoutText);
        LayoutInfos.Add(LayoutInfo);
        if (not HandleSet) or HandleCalls then begin
            if OutText = '' then
                DocumentStream.WriteText('LMC-OUT')
            else
                DocumentStream.WriteText(OutText);
            IsHandled := true;
        end;
    end;
}

codeunit 70832 "LT RptMrg Order Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        Counter: Integer;

    procedure Reset()
    begin
        Lines := '';
        Counter := 0;
    end;

    procedure Add(Who: Text; EntryHandled: Boolean)
    begin
        Counter += 1;
        if Lines <> '' then
            Lines += ' ; ';
        Lines += StrSubstNo('%1 call %2 entry IsHandled=%3', Who, Counter, EntryHandled);
    end;

    procedure Joined(): Text
    begin
        exit(Lines);
    end;

    procedure Calls(): Integer
    begin
        exit(Counter);
    end;
}

codeunit 70833 "LT RptMrg Sub One"
{
    EventSubscriberInstance = Manual;

    var
        HandleCall: Boolean;

    procedure SetHandle(Value: Boolean)
    begin
        HandleCall := Value;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnCustomDocumentMergerEx, '', true, true)]
    local procedure OnMerge(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    var
        Log: Codeunit "LT RptMrg Order Log";
    begin
        Log.Add('One', IsHandled);
        if HandleCall then begin
            DocumentStream.WriteText('OUT-ONE');
            IsHandled := true;
        end;
    end;
}

codeunit 70834 "LT RptMrg Sub Two"
{
    EventSubscriberInstance = Manual;

    var
        HandleCall: Boolean;

    procedure SetHandle(Value: Boolean)
    begin
        HandleCall := Value;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnCustomDocumentMergerEx, '', true, true)]
    local procedure OnMerge(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    var
        Log: Codeunit "LT RptMrg Order Log";
    begin
        Log.Add('Two', IsHandled);
        if HandleCall then begin
            DocumentStream.WriteText('OUT-TWO');
            IsHandled := true;
        end;
    end;
}
