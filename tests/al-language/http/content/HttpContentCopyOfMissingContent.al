// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 75103
// Probe (observe only): al-runner issue 7466. PnE12HttpContent.al (PW_RequestWithoutContent_CopyAndStream) pins ReadAs(Text) and ReadAs(InStream)
//   with the result used on a copy of the content of a fresh HttpRequestMessage, and Y62ContentHeaders.al pins GetHeaders on Req.Content itself.
//   This probe asks the rest for the copy (C := Req.Content of a request that has no content):
//     the reported shape (SetRequestUri, Method := 'GET', then C := Req.Content and `if C.ReadAs(Text)`),
//     GetHeaders with the result used (if, assignment, exit) and as a statement, and the headers variable afterwards,
//     ReadAs(Text) as a statement, a second ReadAs after a failed one,
//     WriteFrom on the copy (does the request get the content), Clear of the copy, a copy of the copy, the copy handed to a procedure by value
//     and by var, the copy assigned back to the request,
//   and the same reads on a copy of the content of a fresh HttpResponseMessage and on an HttpContent variable that was never written (controls).
//   Each step runs in a TryFunction: `ok <answer>` or the error text and code.
// BC versions: 27, 28, 29

codeunit 75103 "LT HCM Copy Of Missing Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReadByValue(C: HttpContent; var T: Text): Boolean
    begin
        exit(C.ReadAs(T));
    end;

    local procedure ReadByVar(var C: HttpContent; var T: Text): Boolean
    begin
        exit(C.ReadAs(T));
    end;

    local procedure HeadersAsExit(var C: HttpContent; var H: HttpHeaders): Boolean
    begin
        exit(C.GetHeaders(H));
    end;

    local procedure HeaderNames(var H: HttpHeaders): Text
    var
        Names: List of [Text];
        Name: Text;
        Result: Text;
    begin
        Names := H.Keys();
        foreach Name in Names do
            Result += Name + ';';
        exit('[' + Result + ']');
    end;

    [TryFunction]
    local procedure TryStep(Step: Integer; var Answer: Text)
    var
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        C: HttpContent;
        C2: HttpContent;
        Never: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        T: Text;
        Ok: Boolean;
    begin
        T := 'kept';
        case Step of
            1:
                begin
                    Req.SetRequestUri('https://example.com/lt-hcm');
                    Req.Method := 'GET';
                    C := Req.Content();
                    if C.ReadAs(T) then
                        Answer := 'read true text=' + T
                    else
                        Answer := 'read false text=' + T;
                end;
            2:
                begin
                    C := Req.Content;
                    if C.GetHeaders(H) then
                        Answer := 'headers true ' + HeaderNames(H)
                    else
                        Answer := 'headers false ' + HeaderNames(H);
                end;
            3:
                begin
                    C := Req.Content;
                    Ok := C.GetHeaders(H);
                    Answer := 'headers ' + Format(Ok) + ' ' + HeaderNames(H);
                end;
            4:
                begin
                    C := Req.Content;
                    Answer := 'headers ' + Format(HeadersAsExit(C, H)) + ' ' + HeaderNames(H);
                end;
            5:
                begin
                    C := Req.Content;
                    C.GetHeaders(H);
                    Answer := 'statement ran ' + HeaderNames(H);
                end;
            6:
                begin
                    C := Req.Content;
                    C.ReadAs(T);
                    Answer := 'statement ran text=' + T;
                end;
            7:
                begin
                    C := Req.Content;
                    Ok := C.ReadAs(T);
                    Answer := 'first ' + Format(Ok);
                    Ok := C.ReadAs(T);
                    Answer += ' second ' + Format(Ok);
                    Ok := C.GetHeaders(H);
                    Answer += ' headers ' + Format(Ok);
                    Ok := C.ReadAs(InS);
                    Answer += ' stream ' + Format(Ok);
                end;
            8:
                begin
                    C := Req.Content;
                    C.WriteFrom('written to the copy');
                    Ok := C.ReadAs(T);
                    Answer := 'copy ' + Format(Ok) + ' text=' + T;
                    T := 'kept';
                    Ok := Req.Content.ReadAs(T);
                    Answer += ' request ' + Format(Ok) + ' text=' + T;
                end;
            9:
                begin
                    C := Req.Content;
                    Clear(C);
                    Ok := C.ReadAs(T);
                    Answer := 'after Clear ' + Format(Ok) + ' text=' + T;
                    Ok := C.GetHeaders(H);
                    Answer += ' headers ' + Format(Ok) + ' ' + HeaderNames(H);
                end;
            10:
                begin
                    C := Req.Content;
                    C2 := C;
                    Ok := C2.ReadAs(T);
                    Answer := 'copy of the copy ' + Format(Ok) + ' text=' + T;
                    Ok := C2.GetHeaders(H);
                    Answer += ' headers ' + Format(Ok);
                end;
            11:
                begin
                    C := Req.Content;
                    Answer := 'by value ' + Format(ReadByValue(C, T)) + ' text=' + T;
                    Answer += ' by var ' + Format(ReadByVar(C, T)) + ' text=' + T;
                end;
            12:
                begin
                    C := Req.Content;
                    Req.Content := C;
                    Ok := Req.Content.ReadAs(T);
                    Answer := 'request after the copy is assigned back ' + Format(Ok) + ' text=' + T;
                end;
            13:
                begin
                    C := Resp.Content;
                    Ok := C.ReadAs(T);
                    Answer := 'response copy read ' + Format(Ok) + ' text=' + T;
                    Ok := C.GetHeaders(H);
                    Answer += ' headers ' + Format(Ok) + ' ' + HeaderNames(H);
                end;
            14:
                begin
                    Ok := Never.ReadAs(T);
                    Answer := 'never written read ' + Format(Ok) + ' text=' + T;
                    Ok := Never.GetHeaders(H);
                    Answer += ' headers ' + Format(Ok) + ' ' + HeaderNames(H);
                end;
            15:
                begin
                    Req.Method := 'POST';
                    C := Req.Content;
                    Ok := C.ReadAs(T);
                    Answer := 'POST request copy read ' + Format(Ok) + ' text=' + T;
                end;
            16:
                begin
                    C := Req.Content;
                    Ok := C.ReadAs(InS);
                    Answer := 'stream ' + Format(Ok) + ' EOS=' + Format(InS.EOS());
                end;
        end;
    end;

    local procedure ObserveStep(var Observer: Codeunit "Probe Observer"; Step: Integer; Name: Text)
    var
        Answer: Text;
    begin
        ClearLastError();
        if TryStep(Step, Answer) then
            Observer.Observe(Name, 'ok ' + Answer)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure CopyOfMissingRequestContent_ReadAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 1, 'GET request with a URI, if ReadAs');
        ObserveStep(Observer, 6, 'ReadAs as a statement');
        ObserveStep(Observer, 7, 'ReadAs twice, GetHeaders, ReadAs stream');
        ObserveStep(Observer, 15, 'POST request');
        ObserveStep(Observer, 16, 'ReadAs stream then EOS');
        Observer.Finish();
    end;

    [Test]
    procedure CopyOfMissingRequestContent_GetHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 2, 'if GetHeaders');
        ObserveStep(Observer, 3, 'GetHeaders assigned');
        ObserveStep(Observer, 4, 'GetHeaders in exit');
        ObserveStep(Observer, 5, 'GetHeaders as a statement');
        Observer.Finish();
    end;

    [Test]
    procedure CopyOfMissingRequestContent_WriteClearCopyPass()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 8, 'WriteFrom on the copy');
        ObserveStep(Observer, 9, 'Clear of the copy');
        ObserveStep(Observer, 10, 'copy of the copy');
        ObserveStep(Observer, 11, 'handed to a procedure');
        ObserveStep(Observer, 12, 'assigned back to the request');
        Observer.Finish();
    end;

    [Test]
    procedure CopyOfMissingResponseContent_AndNeverWritten_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 13, 'copy of the content of a fresh response');
        ObserveStep(Observer, 14, 'content variable never written');
        Observer.Finish();
    end;
}
