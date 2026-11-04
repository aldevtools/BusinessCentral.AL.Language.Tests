// Probe writer-c: builtins refused until probed (docs/probes-needed.md "Builtins refused until a probe pins them"),
// except RequestPage.Update, Report.Preview and FileUpload.CreateInStream (another writer).
// Plus SessionInformation.Callstack from a procedure with a quoted name.
// Fixtures: reports 69730, 69731; codeunits 69732 (capture), 69733 (tests), 69734 (quoted-name helper).
// Reuses table "PW PE Table" (69710) from PWPageVariableEditable.al.

codeunit 69732 "PW BI Capture"
{
    SingleInstance = true;

    var
        Captured: Text;

    procedure Add(T: Text)
    begin
        Captured += T + ' | ';
    end;

    procedure Get(): Text
    begin
        exit(Captured);
    end;

    procedure Reset()
    begin
        Captured := '';
    end;
}

report 69730 "PW OID Captioned"
{
    Caption = 'PW Captioned Report';
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        Cap: Codeunit "PW BI Capture";
    begin
        Cap.Add('CurrReport.ObjectId(false)=' + CurrReport.ObjectId(false));
        Cap.Add('CurrReport.ObjectId(true)=' + CurrReport.ObjectId(true));
        Cap.Add('CurrReport.ObjectId()=' + CurrReport.ObjectId());
    end;
}

report 69731 "PW OID No Caption"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        Cap: Codeunit "PW BI Capture";
    begin
        Cap.Add('CurrReport.ObjectId(false)=' + CurrReport.ObjectId(false));
        Cap.Add('CurrReport.ObjectId(true)=' + CurrReport.ObjectId(true));
    end;
}

codeunit 69734 "PW Quoted Proc Name Helper"
{
    procedure "Read The Call Stack (Quoted)"(): Text
    begin
        exit(SessionInformation.Callstack);
    end;
}

codeunit 69733 "PW Refused Builtins Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Cap: Codeunit "PW BI Capture";

    [Test]
    procedure ReportObjectId_CurrReportInCaptionedReport()
    begin
        Cap.Reset();
        Report.Run(Report::"PW OID Captioned");
        Observer.Observe('captioned_report', Cap.Get());
        Observer.Expect('captioned_report', 'CurrReport.ObjectId(false)=Report 69730 | CurrReport.ObjectId(true)=Report PW Captioned Report | CurrReport.ObjectId()=Report PW Captioned Report | ');
        Observer.Verify();
    end;

    [Test]
    procedure ReportObjectId_CurrReportInReportWithoutCaption()
    begin
        Cap.Reset();
        Report.Run(Report::"PW OID No Caption");
        Observer.Observe('no_caption_report', Cap.Get());
        Observer.Expect('no_caption_report', 'CurrReport.ObjectId(false)=Report 69731 | CurrReport.ObjectId(true)=Report PW OID No Caption | ');
        Observer.Verify();
    end;

    [Test]
    procedure ReportObjectId_ReportVariable()
    var
        R: Report "PW OID Captioned";
    begin
        Observer.Observe('variable_false', R.ObjectId(false));
        Observer.Observe('variable_true', R.ObjectId(true));
        Observer.Expect('variable_false', 'Report 69730');
        Observer.Expect('variable_true', 'Report PW Captioned Report');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_WithErrorInfo_TextAndCode()
    var
        Row: Record "PW PE Table";
        Info: ErrorInfo;
    begin
        Row.Id := 5;
        Row.Txt := 'x';
        Info := ErrorInfo.Create('my message');
        asserterror Row.FieldError(Txt, Info);
        Observer.ObserveError('fielderror_errorinfo');
        Observer.Observe('errorinfo_message_after', Info.Message);
        Observer.Expect('fielderror_errorinfo|text', 'Txt my message in PW PE Table Id=''5''.');
        Observer.Expect('fielderror_errorinfo|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('errorinfo_message_after', 'my message');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_WithErrorInfo_FieldRef()
    var
        Row: Record "PW PE Table";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Info: ErrorInfo;
    begin
        Row.Id := 5;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(Row.FieldNo(Txt));
        Info := ErrorInfo.Create('fieldref message');
        asserterror FldRef.FieldError(Info);
        Observer.ObserveError('fieldref_fielderror_errorinfo');
        Observer.Expect('fieldref_fielderror_errorinfo|text', 'Txt fieldref message in PW PE Table Id=''5''.');
        Observer.Expect('fieldref_fielderror_errorinfo|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure FieldError_WithErrorInfo_InCollectScope()
    var
        Row: Record "PW PE Table";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        E: ErrorInfo;
        Collected: Text;
    begin
        Row.Id := 5;
        Info := ErrorInfo.Create('collected message');
        Info.Collectible(true);
        Row.FieldError(Txt, Info);
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        foreach E in Errs do
            Collected += E.Message + ' code=' + Format(E.ErrorType) + ' ; ';
        Observer.Observe('collected', Collected);
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected', 'Txt collected message in PW PE Table Id=''5''. code=Client ; ');
        Observer.Verify();
    end;

    [Test]
    procedure HttpRequestMessage_NewInstance_MethodAndUri()
    var
        Req: HttpRequestMessage;
    begin
        Observer.Observe('method_before_set', Req.Method);
        Observer.Observe('uri_before_set', Req.GetRequestUri());
        Observer.Expect('method_before_set', 'GET');
        Observer.Expect('uri_before_set', '');
        Observer.Verify();
    end;

    [Test]
    procedure HttpRequestMessage_SetRequestUri_ValidAndInvalid()
    var
        Req: HttpRequestMessage;
    begin
        Req.SetRequestUri('https://example.com/a?b=1');
        Observer.Observe('uri_valid', Req.GetRequestUri());
        asserterror Req.SetRequestUri('not a uri');
        Observer.ObserveError('set_invalid_uri');
        Observer.Observe('uri_after_invalid', Req.GetRequestUri());
        Observer.Expect('uri_valid', 'https://example.com/a?b=1');
        Observer.Expect('set_invalid_uri|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('set_invalid_uri|code', 'CreateUrl:UriFormat');
        Observer.Expect('uri_after_invalid', 'https://example.com/a?b=1');
        Observer.Verify();
    end;

    [Test]
    procedure HttpRequestMessage_SetMethod_Roundtrip()
    var
        Req: HttpRequestMessage;
    begin
        Req.Method := 'post';
        Observer.Observe('method_lowercase_set', Req.Method);
        Observer.Expect('method_lowercase_set', 'post');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_SetPermissionFilter_NoOp()
    var
        Row: Record "PW PE Table";
        RecRef: RecordRef;
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Insert();
        RecRef.Open(Database::"PW PE Table");
        RecRef.SetPermissionFilter();
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('filters', RecRef.GetFilters());
        Observer.Expect('count', '1');
        Observer.Expect('filters', '');
        Observer.Verify();
    end;

    [Test]
    procedure Callstack_QuotedProcedureName()
    var
        Helper: Codeunit "PW Quoted Proc Name Helper";
        Stack: Text;
        FirstFrame: Text;
    begin
        Stack := Helper."Read The Call Stack (Quoted)"();
        FirstFrame := CopyStr(Stack, 1, StrPos(Stack, '\') - 1);
        Observer.Observe('first_frame', FirstFrame);
        Observer.Expect('first_frame', '"PW Quoted Proc Name Helper"(CodeUnit 69734)."Read The Call Stack (Quoted)" line 2 - AL Language Coverage Tests by AL Language version x');
        Observer.Verify();
    end;
}
