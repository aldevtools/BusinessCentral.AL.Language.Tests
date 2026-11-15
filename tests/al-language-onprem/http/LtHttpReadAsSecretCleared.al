// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-readas-secrettext-method
// Scope: in-scope (OnPrem app only because SecretText.Unwrap is Scope OnPrem; the read itself is Cloud surface)
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: al-runner assumption http-readas-secret-statement, shape "cleared secret copy, asked".
//   tests/al-language/http/CzHttpNoNetwork.al:25-57 (DescribeContent) takes a content made by codeunit "Http Content".Create(SecretText)
//   by value, asks IsSecretContent, reads it with ReadAs(SecretText) as a statement and pins the secret only as "not empty".
//   This file runs the same sequence and records the unwrapped text, its length and IsEmpty at each step.
// Steps (same order as CzHttpNoNetwork.al): Create(Secret).GetHttpContent() -> copy taken by value -> GetHeaders -> IsSecretContent
//   -> ReadAs(SecretText) as a statement -> read the destination (IsEmpty, Length, Unwrap). Also: the destination before the read
//   (unchanged or not), a second statement read, a result-used read, and the variant with Create(SecretText; ContentType).
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 98795 "LT HTTP ReadAs Secret Cleared"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure Show(S: SecretText): Text
    begin
        exit('empty=' + Format(S.IsEmpty()) + ' len=' + Format(StrLen(S.Unwrap())) + ' text=[' + S.Unwrap() + ']');
    end;

    // The copy comes in by value, as DescribeContent does in CzHttpNoNetwork.al.
    local procedure StatementOnCopy(Content: HttpContent; Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Headers: HttpHeaders;
        Secret: SecretText;
    begin
        Secret := Sec('before');
        Observer.Observe(Prefix + '_dest_before', Show(Secret));
        Observer.Observe(Prefix + '_is_secret_1', Format(Content.IsSecretContent()));
        Content.GetHeaders(Headers);
        Observer.Observe(Prefix + '_is_secret_2', Format(Content.IsSecretContent()));
        Content.ReadAs(Secret);
        Observer.Observe(Prefix + '_statement', Show(Secret));
        Secret := Sec('again');
        Content.ReadAs(Secret);
        Observer.Observe(Prefix + '_statement_second', Show(Secret));
        Secret := Sec('used');
        Observer.Observe(Prefix + '_used_result', Format(Content.ReadAs(Secret)));
        Observer.Observe(Prefix + '_used', Show(Secret));
    end;

    [Test]
    procedure HttpContentCodeunit_CreateSecret_StatementRead_Unwrapped()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
    begin
        StatementOnCopy(HttpContent.Create(Sec('test')).GetHttpContent(), Observer, 'create');
        Observer.Finish();
    end;

    [Test]
    procedure HttpContentCodeunit_CreateSecretWithType_StatementRead_Unwrapped()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
    begin
        StatementOnCopy(HttpContent.Create(Sec('test'), 'application/json').GetHttpContent(), Observer, 'typed');
        Observer.Finish();
    end;

    [Test]
    procedure HttpContentCodeunit_CreateSecret_Longer_StatementRead_Unwrapped()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
    begin
        StatementOnCopy(HttpContent.Create(Sec('Line one' + ' and some more text, 123')).GetHttpContent(), Observer, 'long');
        Observer.Finish();
    end;

    [Test]
    procedure HttpContentCodeunit_CreateSecret_StatementRead_NoQuery()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
        Content: HttpContent;
        Secret: SecretText;
    begin
        // The same read with no IsSecretContent and no GetHeaders before it, on the copy in a variable.
        Content := HttpContent.Create(Sec('test')).GetHttpContent();
        Secret := Sec('before');
        Content.ReadAs(Secret);
        Observer.Observe('direct_statement', Show(Secret));
        Observer.Finish();
    end;
}
