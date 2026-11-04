// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpContent.IsSecretContent, WriteFrom(SecretText), ReadAs(SecretText) and the interaction with Text and InStream content
// BC versions: 29 (27 and 28 by CI)

codeunit 74811 "LT P97 Content Secret"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Secret(Value: Text): SecretText
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo(Value);
        exit(S);
    end;

    [TryFunction]
    local procedure TryReadSecret(var C: HttpContent; var Result: Text)
    var
        S: SecretText;
        Ok: Boolean;
    begin
        Ok := C.ReadAs(S);
        Result := Format(Ok) + '|' + Format(S.IsEmpty());
    end;

    [TryFunction]
    local procedure TryReadText(var C: HttpContent; var Result: Text)
    var
        T: Text;
        Ok: Boolean;
    begin
        Ok := C.ReadAs(T);
        Result := Format(Ok) + '|' + T;
    end;

    [TryFunction]
    local procedure TryReadStream(var C: HttpContent; var Result: Text)
    var
        InS: InStream;
        T: Text;
        Ok: Boolean;
    begin
        Ok := C.ReadAs(InS);
        if not InS.EOS() then
            InS.ReadText(T);
        Result := Format(Ok) + '|' + T;
    end;

    [TryFunction]
    local procedure TryIsSecret(var C: HttpContent; var Result: Text)
    begin
        Result := Format(C.IsSecretContent());
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; var C: HttpContent)
    var
        R: Text;
    begin
        if TryIsSecret(C, R) then
            Observer.Observe(Name + '_is', R)
        else
            Observer.ObserveError(Name + '_is');
        if TryReadSecret(C, R) then
            Observer.Observe(Name + '_secret', R)
        else
            Observer.ObserveError(Name + '_secret');
        if TryReadText(C, R) then
            Observer.Observe(Name + '_text', R)
        else
            Observer.ObserveError(Name + '_text');
        if TryReadStream(C, R) then
            Observer.Observe(Name + '_stream', R)
        else
            Observer.ObserveError(Name + '_stream');
    end;

    [Test]
    procedure Secret_Content_Basics()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
    begin
        Report(Observer, 'new', C);
        C.WriteFrom(Secret('s3cret'));
        Report(Observer, 'written', C);
        Observer.Expect('new_is', 'No');
        Observer.Expect('new_secret', 'Yes|Yes');
        Observer.Expect('new_text', 'Yes|');
        Observer.Expect('new_stream', 'Yes|');
        Observer.Expect('written_is', 'Yes');
        Observer.Expect('written_secret', 'Yes|No');
        Observer.Expect('written_text', 'No|');
        Observer.Expect('written_stream|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('written_stream|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_Content_Basics()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
    begin
        C.WriteFrom('plain');
        Report(Observer, 'written', C);
        Observer.Expect('written_is', 'No');
        Observer.Expect('written_secret', 'Yes|No');
        Observer.Expect('written_text', 'Yes|plain');
        Observer.Expect('written_stream', 'Yes|plain');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_Overwrite_Order()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        R: Text;
    begin
        C.WriteFrom('plain');
        C.WriteFrom(Secret('s1'));
        Report(Observer, 'plain_then_secret', C);
        C.WriteFrom('plain2');
        Report(Observer, 'then_plain_again', C);
        C.WriteFrom(Secret('s2'));
        C.Clear();
        Report(Observer, 'secret_then_clear', C);
        Observer.Expect('plain_then_secret_is', 'Yes');
        Observer.Expect('plain_then_secret_secret', 'Yes|No');
        Observer.Expect('plain_then_secret_text', 'No|');
        Observer.Expect('plain_then_secret_stream|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('plain_then_secret_stream|code', 'NotInitialized');
        Observer.Expect('then_plain_again_is', 'No');
        Observer.Expect('then_plain_again_secret', 'Yes|No');
        Observer.Expect('then_plain_again_text', 'Yes|plain2');
        Observer.Expect('then_plain_again_stream', 'Yes|plain2');
        Observer.Expect('secret_then_clear_is', 'No');
        Observer.Expect('secret_then_clear_secret', 'Yes|Yes');
        Observer.Expect('secret_then_clear_text', 'Yes|');
        Observer.Expect('secret_then_clear_stream', 'Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_EmptyValue()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        Empty: SecretText;
    begin
        C.WriteFrom(Empty);
        Report(Observer, 'empty_secret', C);
        Observer.Expect('empty_secret_is', 'Yes');
        Observer.Expect('empty_secret_secret', 'Yes|Yes');
        Observer.Expect('empty_secret_text', 'No|');
        Observer.Expect('empty_secret_stream|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('empty_secret_stream|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_WriteFromInStream()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('from stream');
        TempBlob.CreateInStream(InS);
        C.WriteFrom(Secret('first'));
        C.WriteFrom(InS);
        Report(Observer, 'secret_then_stream', C);
        Observer.Expect('secret_then_stream_is', 'No');
        Observer.Expect('secret_then_stream_secret', 'Yes|No');
        Observer.Expect('secret_then_stream_text', 'Yes|from stream');
        Observer.Expect('secret_then_stream_stream', 'Yes|from stream');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_Content_Headers()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        Vals: array[2] of Text;
    begin
        C.WriteFrom(Secret('s3cret'));
        C.GetHeaders(H);
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Observe('has_type', Format(H.Contains('Content-Type')));
        if H.GetValues('Content-Type', Vals) then
            Observer.Observe('type', Vals[1]);
        Observer.Expect('keys', '1');
        Observer.Expect('has_type', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_Content_OnRequest()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: HttpContent;
        C2: HttpContent;
    begin
        C.WriteFrom(Secret('s3cret'));
        Req.Content(C);
        C2 := Req.Content();
        Report(Observer, 'back', C2);
        Observer.Expect('back_is', 'Yes');
        Observer.Expect('back_secret', 'Yes|No');
        Observer.Expect('back_text', 'No|');
        Observer.Expect('back_stream|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('back_stream|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Secret_Content_Unicode_Long()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        R: Text;
        Long: Text;
        I: Integer;
    begin
        C.WriteFrom(Secret('caf' + 'é ' + '日本'));
        if TryReadSecret(C, R) then
            Observer.Observe('unicode', R)
        else
            Observer.ObserveError('unicode');
        for I := 1 to 200 do
            Long += 'abcde';
        C.WriteFrom(Secret(Long));
        if TryReadSecret(C, R) then
            Observer.Observe('long_len', Format(StrLen(R)))
        else
            Observer.ObserveError('long_len');
        Observer.Expect('unicode', 'Yes|No');
        Observer.Expect('long_len', '6');
        Observer.Verify();
    end;
}
