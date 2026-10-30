// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-custom
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT RptMrg Row (70826), LT RptMrg Blob (70825), LT RptMrg Helper (70835), report 70883 (ReportMergerFixtures.al);
//                own objects 90864-90867; layout files ./ReportMergerLayoutY2_NoCaption.rlblayout and ./ReportMergerLayoutY2_View.rlblayout of the app root
// Probe: written for al-runtime-rs assumption custom-layout-merger (writer Y2). The other files of this folder mask the values that name the user, the
//        company, the run and the clock. This file compares them with what AL can read (UserSecurityId(), CompanyName(), the app id of the module) instead
//        of printing them: the text form of invokedby, reportrunid, layoutapplicationid, invokeddatetime and companyname. It also reads filterviews after
//        SetTableView, with a RecordRef, with a data item view in the request parameters and for a report with DataItemTableView, and objectname of a
//        report without a Caption.
// Facts: see the asserted values below.
// BC versions: 27, 28, 29

report 90864 "LT Y2 RptMrg NoCaption"
{
    UseRequestPage = false;
    DefaultRenderingLayout = Y2NoCap;

    dataset
    {
        dataitem(Rows; "LT RptMrg Row")
        {
            column(RowId; Id) { }
        }
    }

    rendering
    {
        layout(Y2NoCap)
        {
            Type = Custom;
            LayoutFile = './ReportMergerLayoutY2_NoCaption.rlblayout';
            MimeType = 'application/x-lmc-layout-y2';
        }
    }
}

report 90865 "LT Y2 RptMrg View"
{
    Caption = 'LT Y2 Merger View';
    UseRequestPage = false;
    DefaultRenderingLayout = Y2View;

    dataset
    {
        dataitem(Rows; "LT RptMrg Row")
        {
            DataItemTableView = sorting(Id) where(Id = const(1));
            column(RowId; Id) { }
        }
    }

    rendering
    {
        layout(Y2View)
        {
            Type = Custom;
            LayoutFile = './ReportMergerLayoutY2_View.rlblayout';
            MimeType = 'application/x-lmc-layout-y2';
        }
    }
}

codeunit 90866 "LT Y2 RptMrg Raw Capture"
{
    EventSubscriberInstance = Manual;

    var
        Payloads: List of [Text];

    procedure CallCount(): Integer
    begin
        exit(Payloads.Count());
    end;

    procedure Payload(Index: Integer; var Result: JsonObject): Boolean
    begin
        if (Index < 1) or (Index > Payloads.Count()) then
            exit(false);
        exit(Result.ReadFrom(Payloads.Get(Index)));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnCustomDocumentMergerEx, '', true, true)]
    local procedure OnMerge(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    var
        Raw: Text;
    begin
        ObjectPayload.WriteTo(Raw);
        Payloads.Add(Raw);
        if not IsHandled then begin
            DocumentStream.WriteText('Y2-OUT');
            IsHandled := true;
        end;
    end;
}

codeunit 90867 "LT Y2 RptMrg Unmasked"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BareGuid(G: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(G), '=', '{}')));
    end;

    local procedure Value(var Payload: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Payload.Get(KeyName, Token) then
            exit('<missing>');
        if not Token.IsValue() then
            exit('<not a value>');
        if Token.AsValue().IsNull() then
            exit('<null>');
        exit(Token.AsValue().AsText());
    end;

    local procedure Raw(var Payload: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
        Result: Text;
    begin
        if not Payload.Get(KeyName, Token) then
            exit('<missing>');
        Token.WriteTo(Result);
        exit(Result);
    end;

    local procedure Digits(T: Text): Text
    var
        i: Integer;
        Result: Text;
        C: Text;
    begin
        for i := 1 to StrLen(T) do begin
            C := CopyStr(T, i, 1);
            if C in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] then
                Result += 'd'
            else
                Result += C;
        end;
        exit(Result);
    end;

    local procedure GuidShape(T: Text): Text
    begin
        exit(StrSubstNo('len=%1 lower=%2 braces=%3 dashes=%4', StrLen(T), T = LowerCase(T), StrPos(T, '{') > 0,
            StrLen(T) - StrLen(DelChr(T, '=', '-'))));
    end;

    local procedure SaveMain(var Cap: Codeunit "LT Y2 RptMrg Raw Capture"; var Payload: JsonObject)
    var
        Rep: Report "LT RptMrg Report";
        Tmp: Record "LT RptMrg Blob" temporary;
        OutS: OutStream;
    begin
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs('', ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(Cap.CallCount(), Payload);
    end;

    [Test]
    procedure Payload_Unmasked_UserRunAppCompany()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Payload: JsonObject;
        Info: ModuleInfo;
    begin
        Helper.SeedRows(2);
        SaveMain(Cap, Payload);
        NavApp.GetCurrentModuleInfo(Info);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('invokedby shape', GuidShape(Value(Payload, 'invokedby')));
        Observer.Observe('invokedby = UserSecurityId', Format(Value(Payload, 'invokedby') = BareGuid(UserSecurityId())));
        Observer.Observe('invokedby raw quoted', Format(Raw(Payload, 'invokedby') = '"' + BareGuid(UserSecurityId()) + '"'));
        Observer.Observe('layoutapplicationid shape', GuidShape(Value(Payload, 'layoutapplicationid')));
        Observer.Observe('layoutapplicationid = app id', Format(Value(Payload, 'layoutapplicationid') = BareGuid(Info.Id)));
        Observer.Observe('reportrunid shape', GuidShape(Value(Payload, 'reportrunid')));
        Observer.Observe('reportrunid null guid', Format(Value(Payload, 'reportrunid') = BareGuid(EmptyGuid())));
        Observer.Observe('companyname = CompanyName', Format(Value(Payload, 'companyname') = CompanyName()));
        Observer.Observe('companyname raw quoted', Format(Raw(Payload, 'companyname') = '"' + CompanyName() + '"'));
        Observer.Finish();
    end;

    local procedure EmptyGuid(): Guid
    var
        G: Guid;
    begin
        exit(G);
    end;

    [Test]
    procedure Payload_Unmasked_InvokedDateTime()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Payload: JsonObject;
        Before: DateTime;
        After: DateTime;
        Stamp: DateTime;
        Txt: Text;
    begin
        Helper.SeedRows(1);
        Before := CurrentDateTime();
        SaveMain(Cap, Payload);
        After := CurrentDateTime();
        Txt := Value(Payload, 'invokeddatetime');
        Observer.Observe('raw is a string', Format(CopyStr(Raw(Payload, 'invokeddatetime'), 1, 1) = '"'));
        Observer.Observe('shape', Digits(Txt));
        Observer.Observe('evaluates', Format(Evaluate(Stamp, Txt, 9)));
        Observer.Observe('within the call (1 s slack)', Format((Stamp >= Before - 1000) and (Stamp <= After + 1000)));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_Unmasked_ReportRunIdPerCall()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        First: JsonObject;
        Second: JsonObject;
    begin
        Helper.SeedRows(1);
        SaveMain(Cap, First);
        SaveMain(Cap, Second);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('reportrunid differs', Format(Value(First, 'reportrunid') <> Value(Second, 'reportrunid')));
        Observer.Observe('invokedby same', Format(Value(First, 'invokedby') = Value(Second, 'invokedby')));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_FilterViews_AfterSetTableView()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Rep: Report "LT RptMrg Report";
        Row: Record "LT RptMrg Row";
        Tmp: Record "LT RptMrg Blob" temporary;
        Payload: JsonObject;
        OutS: OutStream;
    begin
        Helper.SeedRows(2);
        Row.SetRange(Id, 1);
        Row.SetFilter(Name, 'Al*');
        Rep.SetTableView(Row);
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs('', ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('filterviews', Raw(Payload, 'filterviews'));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_FilterViews_WithRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Tmp: Record "LT RptMrg Blob" temporary;
        RecRef: RecordRef;
        Payload: JsonObject;
        OutS: OutStream;
    begin
        Helper.SeedRows(2);
        RecRef.Open(Database::"LT RptMrg Row");
        RecRef.Field(1).SetRange(2);
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Report.SaveAs(Report::"LT RptMrg Report", '', ReportFormat::Pdf, OutS, RecRef);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('filterviews', Raw(Payload, 'filterviews'));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_FilterViews_RequestParametersView()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Rep: Report "LT RptMrg Report";
        Tmp: Record "LT RptMrg Blob" temporary;
        Payload: JsonObject;
        OutS: OutStream;
        Params: Text;
    begin
        Helper.SeedRows(2);
        Params := '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RptMrg Report" id="70883"><DataItems><DataItem name="Rows">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem></DataItems></ReportParameters>';
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs(Params, ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('filterviews', Raw(Payload, 'filterviews'));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_FilterViews_RequestParametersOptionsOnly()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Rep: Report "LT RptMrg Report";
        Tmp: Record "LT RptMrg Blob" temporary;
        Payload: JsonObject;
        OutS: OutStream;
        Params: Text;
    begin
        Helper.SeedRows(2);
        Params := '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RptMrg Report" id="70883"><Options><Field name="ModeVal">3</Field></Options></ReportParameters>';
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs(Params, ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('filterviews', Raw(Payload, 'filterviews'));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_FilterViews_DataItemTableView()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Rep: Report "LT Y2 RptMrg View";
        Tmp: Record "LT RptMrg Blob" temporary;
        Payload: JsonObject;
        OutS: OutStream;
    begin
        Helper.SeedRows(2);
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs('', ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('filterviews', Raw(Payload, 'filterviews'));
        Observer.Observe('objectname', Raw(Payload, 'objectname'));
        Observer.Observe('layoutname', Raw(Payload, 'layoutname'));
        Observer.Finish();
    end;

    [Test]
    procedure Payload_ReportWithoutCaption()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT Y2 RptMrg Raw Capture";
        Rep: Report "LT Y2 RptMrg NoCaption";
        Tmp: Record "LT RptMrg Blob" temporary;
        Payload: JsonObject;
        OutS: OutStream;
    begin
        Helper.SeedRows(1);
        Tmp.Data.CreateOutStream(OutS);
        BindSubscription(Cap);
        Rep.SaveAs('', ReportFormat::Pdf, OutS);
        UnbindSubscription(Cap);
        Cap.Payload(1, Payload);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('objectname', Raw(Payload, 'objectname'));
        Observer.Observe('objectid', Raw(Payload, 'objectid'));
        Observer.Observe('layoutname', Raw(Payload, 'layoutname'));
        Observer.Observe('layoutmimetype', Raw(Payload, 'layoutmimetype'));
        Observer.Finish();
    end;
}
