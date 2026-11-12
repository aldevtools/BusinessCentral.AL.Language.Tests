// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-readas-secrettext-method
// Scope: in-scope (OnPrem app only because SecretText.Unwrap is Scope OnPrem; the read itself is Cloud surface)
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: from al-runner issue 7862 (HttpContent.ReadAs(SecretText) as a statement on the content of a request, in a test mock
//   that records the request body and unwraps it).
// Area: HttpContent.ReadAs(var SecretText) as a statement and with its result used, on:
//   - a content written from a SecretText, a content written from a Text, a new content nobody wrote to;
//   - the content of a request that got one with Req.Content(C), read in place (Req.Content.ReadAs(S)) and through a copy;
//   - the content of a request that has none, read in place and through a copy, plain and inside a TryFunction;
//   - an empty body written from a Text.
//   Each case reads the destination afterwards (IsEmpty and Unwrap) and the error code and text when the call raises.
// Already pinned elsewhere, not repeated: the result-used form on a written or new content with IsEmpty only
//   (tests/al-language/xml/xml/P97ContentSecret.al).
// Measured: observe form on a local BC 28.5 service tier, turned into assertions; the corpus CI checks 27.5, 28.5 and 29.0.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 98786 "N4 ReadAs Secret Statement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Show(S: SecretText): Text
    begin
        exit(Format(S.IsEmpty()) + '|' + S.Unwrap());
    end;

    [TryFunction]
    local procedure TryStatement(var C: HttpContent; var S: SecretText)
    begin
        C.ReadAs(S);
    end;

    [TryFunction]
    local procedure TryUsed(var C: HttpContent; var S: SecretText; var Ok: Boolean)
    begin
        Ok := C.ReadAs(S);
    end;

    [TryFunction]
    local procedure TryRequestStatement(var Req: HttpRequestMessage; var S: SecretText)
    begin
        Req.Content.ReadAs(S);
    end;

    [TryFunction]
    local procedure TryRequestUsed(var Req: HttpRequestMessage; var S: SecretText; var Ok: Boolean)
    begin
        Ok := Req.Content.ReadAs(S);
    end;

    local procedure Statement(Name: Text; var C: HttpContent)
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo('before');
        ClearLastError();
        if TryStatement(C, S) then
            Observer.Observe(Name, 'ok|' + Show(S))
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '_dest', Show(S));
        end;
    end;

    local procedure Used(Name: Text; var C: HttpContent)
    var
        S: SecretText;
        Ok: Boolean;
    begin
        S := SecretText.SecretStrSubstNo('before');
        ClearLastError();
        if TryUsed(C, S, Ok) then
            Observer.Observe(Name, Format(Ok) + '|' + Show(S))
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '_dest', Show(S));
        end;
    end;

    local procedure RequestStatement(Name: Text; var Req: HttpRequestMessage)
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo('before');
        ClearLastError();
        if TryRequestStatement(Req, S) then
            Observer.Observe(Name, 'ok|' + Show(S))
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '_dest', Show(S));
        end;
    end;

    local procedure RequestUsed(Name: Text; var Req: HttpRequestMessage)
    var
        S: SecretText;
        Ok: Boolean;
    begin
        S := SecretText.SecretStrSubstNo('before');
        ClearLastError();
        if TryRequestUsed(Req, S, Ok) then
            Observer.Observe(Name, Format(Ok) + '|' + Show(S))
        else begin
            Observer.ObserveError(Name);
            Observer.Observe(Name + '_dest', Show(S));
        end;
    end;

    [Test]
    procedure N4_ReadAsSecret_Statement_Contents()
    var
        Secret: HttpContent;
        Plain: HttpContent;
        Fresh: HttpContent;
        Empty: HttpContent;
    begin
        Secret.WriteFrom(SecretText.SecretStrSubstNo('s3cret body'));
        Plain.WriteFrom('plain body');
        Empty.WriteFrom('');
        Statement('secret', Secret);
        Statement('plain', Plain);
        Statement('fresh', Fresh);
        Statement('empty', Empty);
        Statement('secret_again', Secret);
        Observer.Expect('secret', 'ok|No|s3cret body');
        Observer.Expect('plain', 'ok|No|plain body');
        Observer.Expect('fresh', 'ok|Yes|');
        Observer.Expect('empty', 'ok|Yes|');
        Observer.Expect('secret_again', 'ok|No|s3cret body');
        Observer.Verify();
    end;

    [Test]
    procedure N4_ReadAsSecret_Used_Contents()
    var
        Secret: HttpContent;
        Plain: HttpContent;
        Fresh: HttpContent;
        Empty: HttpContent;
    begin
        Secret.WriteFrom(SecretText.SecretStrSubstNo('s3cret body'));
        Plain.WriteFrom('plain body');
        Empty.WriteFrom('');
        Used('secret', Secret);
        Used('plain', Plain);
        Used('fresh', Fresh);
        Used('empty', Empty);
        Observer.Expect('secret', 'Yes|No|s3cret body');
        Observer.Expect('plain', 'Yes|No|plain body');
        Observer.Expect('fresh', 'Yes|Yes|');
        Observer.Expect('empty', 'Yes|Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure N4_ReadAsSecret_RequestWithContent()
    var
        Req: HttpRequestMessage;
        PlainReq: HttpRequestMessage;
        C: HttpContent;
        P: HttpContent;
        Copy: HttpContent;
    begin
        C.WriteFrom(SecretText.SecretStrSubstNo('token=abc'));
        Req.Content(C);
        P.WriteFrom('{"a":1}');
        PlainReq.Content(P);
        RequestStatement('secret_inplace_statement', Req);
        RequestUsed('secret_inplace_used', Req);
        RequestStatement('plain_inplace_statement', PlainReq);
        RequestUsed('plain_inplace_used', PlainReq);
        Copy := Req.Content;
        Statement('secret_copy_statement', Copy);
        Used('secret_copy_used', Copy);
        Observer.Expect('secret_inplace_statement', 'ok|No|token=abc');
        Observer.Expect('secret_inplace_used', 'Yes|No|token=abc');
        Observer.Expect('plain_inplace_statement', 'ok|No|{"a":1}');
        Observer.Expect('plain_inplace_used', 'Yes|No|{"a":1}');
        Observer.Expect('secret_copy_statement', 'ok|No|token=abc');
        Observer.Expect('secret_copy_used', 'Yes|No|token=abc');
        Observer.Verify();
    end;

    [Test]
    procedure N4_ReadAsSecret_RequestWithoutContent_TryFunction()
    var
        Req: HttpRequestMessage;
        Copy: HttpContent;
    begin
        Req.Method := 'GET';
        RequestStatement('inplace_statement', Req);
        RequestUsed('inplace_used', Req);
        Copy := Req.Content;
        Statement('copy_statement', Copy);
        Used('copy_used', Copy);
        Observer.Expect('inplace_statement|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('inplace_statement|code', 'NotInitialized');
        Observer.Expect('inplace_statement_dest', 'No|before');
        Observer.Expect('inplace_used', 'No|No|before');
        Observer.Expect('copy_statement|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('copy_statement|code', 'NotInitialized');
        Observer.Expect('copy_statement_dest', 'No|before');
        Observer.Expect('copy_used', 'No|No|before');
        Observer.Verify();
    end;

    [Test]
    procedure N4_ReadAsSecret_RequestWithoutContent_Plain()
    var
        Req: HttpRequestMessage;
        S: SecretText;
    begin
        Req.Method := 'GET';
        S := SecretText.SecretStrSubstNo('before');
        asserterror Req.Content.ReadAs(S);
        Observer.ObserveError('inplace_statement');
        Observer.Observe('inplace_statement_dest', Show(S));
        Observer.Expect('inplace_statement|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('inplace_statement|code', 'NotInitialized');
        Observer.Expect('inplace_statement_dest', 'No|before');
        Observer.Verify();
    end;
}
