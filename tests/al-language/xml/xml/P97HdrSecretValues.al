// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpHeaders.GetSecretValues into Array and List of SecretText, for secret, plain, missing and multiple values
// BC versions: 29 (27 and 28 by CI)

codeunit 74809 "LT P97 Hdr SecretValues"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewHeaders(var Headers: HttpHeaders)
    var
        Req: HttpRequestMessage;
    begin
        Req.GetHeaders(Headers);
    end;

    local procedure Secret(Value: Text): SecretText
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo(Value);
        exit(S);
    end;

    [TryFunction]
    local procedure TryArray(var Headers: HttpHeaders; HdrKey: Text; var Result: Text)
    var
        Vals: array[3] of SecretText;
        Found: Boolean;
    begin
        Found := Headers.GetSecretValues(HdrKey, Vals);
        Result := Format(Found) + '|' + Format(Vals[1].IsEmpty()) + '|' + Format(Vals[2].IsEmpty()) + '|' + Format(Vals[3].IsEmpty());
    end;

    [TryFunction]
    local procedure TryList(var Headers: HttpHeaders; HdrKey: Text; var Vals: List of [SecretText]; var Result: Text)
    var
        Found: Boolean;
        V: SecretText;
        S: Text;
    begin
        Found := Headers.GetSecretValues(HdrKey, Vals);
        foreach V in Vals do
            S += Format(V.IsEmpty()) + ';';
        Result := Format(Found) + '|' + Format(Vals.Count()) + '|' + S;
    end;

    local procedure Arr(var Observer: Codeunit "Probe Observer"; Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        R: Text;
    begin
        if TryArray(Headers, HdrKey, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure Lst(var Observer: Codeunit "Probe Observer"; Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        R: Text;
        Vals: List of [SecretText];
    begin
        if TryList(Headers, HdrKey, Vals, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure GetSecretValues_Array()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Sec', Secret('s1'));
        Headers.Add('X-Sec2', Secret('a'));
        Headers.Add('X-Sec2', Secret('b'));
        Headers.Add('X-Sec3', Secret('a'));
        Headers.Add('X-Sec3', Secret('b'));
        Headers.Add('X-Sec3', Secret('c'));
        Headers.Add('X-Sec4', Secret('a'));
        Headers.Add('X-Sec4', Secret('b'));
        Headers.Add('X-Sec4', Secret('c'));
        Headers.Add('X-Sec4', Secret('d'));
        Headers.Add('X-Plain', 'p1');
        Arr(Observer, 'one', Headers, 'X-Sec');
        Arr(Observer, 'two', Headers, 'X-Sec2');
        Arr(Observer, 'three', Headers, 'X-Sec3');
        Arr(Observer, 'four_into_three', Headers, 'X-Sec4');
        Arr(Observer, 'plain', Headers, 'X-Plain');
        Arr(Observer, 'missing', Headers, 'X-Missing');
        Arr(Observer, 'empty_key', Headers, '');
        Arr(Observer, 'lower_case_key', Headers, 'x-sec');
        Arr(Observer, 'upper_case_key', Headers, 'X-SEC');
        Observer.Expect('one', 'Yes|No|Yes|Yes');
        Observer.Expect('two', 'Yes|No|No|Yes');
        Observer.Expect('three', 'Yes|No|No|No');
        Observer.Expect('four_into_three', 'No|Yes|Yes|Yes');
        Observer.Expect('plain', 'No|Yes|Yes|Yes');
        Observer.Expect('missing', 'No|Yes|Yes|Yes');
        Observer.Expect('empty_key', 'No|Yes|Yes|Yes');
        Observer.Expect('lower_case_key', 'Yes|No|Yes|Yes');
        Observer.Expect('upper_case_key', 'Yes|No|Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetSecretValues_List()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Sec', Secret('s1'));
        Headers.Add('X-Sec2', Secret('a'));
        Headers.Add('X-Sec2', Secret('b'));
        Headers.Add('X-Plain', 'p1');
        Headers.Add('X-Empty', Secret(''));
        Lst(Observer, 'one', Headers, 'X-Sec');
        Lst(Observer, 'two', Headers, 'X-Sec2');
        Lst(Observer, 'plain', Headers, 'X-Plain');
        Lst(Observer, 'missing', Headers, 'X-Missing');
        Lst(Observer, 'empty_secret', Headers, 'X-Empty');
        Lst(Observer, 'empty_key', Headers, '');
        Lst(Observer, 'lower_case_key', Headers, 'x-sec2');
        Observer.Expect('one', 'Yes|1|No;');
        Observer.Expect('two', 'Yes|2|No;No;');
        Observer.Expect('plain', 'No|0|');
        Observer.Expect('missing', 'No|0|');
        Observer.Expect('empty_secret', 'Yes|1|Yes;');
        Observer.Expect('empty_key', 'No|0|');
        Observer.Expect('lower_case_key', 'Yes|2|No;No;');
        Observer.Verify();
    end;

    [Test]
    procedure GetSecretValues_ListIsClearedOrAppended()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
        Vals: List of [SecretText];
        R: Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Sec', Secret('s1'));
        Vals.Add(Secret('pre'));
        if TryList(Headers, 'X-Sec', Vals, R) then
            Observer.Observe('prefilled_hit', R)
        else
            Observer.ObserveError('prefilled_hit');
        if TryList(Headers, 'X-Missing', Vals, R) then
            Observer.Observe('prefilled_miss', R)
        else
            Observer.ObserveError('prefilled_miss');
        Observer.Expect('prefilled_hit', 'Yes|2|No;No;');
        Observer.Expect('prefilled_miss', 'No|2|No;No;');
        Observer.Verify();
    end;

    [Test]
    procedure GetSecretValues_AfterRemoveAndClear()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Sec', Secret('s1'));
        Observer.Observe('contains_secret', Format(Headers.ContainsSecret('X-Sec')));
        Arr(Observer, 'before', Headers, 'X-Sec');
        Observer.Observe('remove', Format(Headers.Remove('X-Sec')));
        Arr(Observer, 'after_remove', Headers, 'X-Sec');
        Headers.Add('X-Sec', Secret('s2'));
        Headers.Clear();
        Arr(Observer, 'after_clear', Headers, 'X-Sec');
        Observer.Expect('contains_secret', 'Yes');
        Observer.Expect('before', 'Yes|No|Yes|Yes');
        Observer.Expect('remove', 'Yes');
        Observer.Expect('after_remove', 'No|Yes|Yes|Yes');
        Observer.Expect('after_clear', 'No|Yes|Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetSecretValues_AddedWithoutValidation()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Observer.Observe('try_add', Format(Headers.TryAddWithoutValidation('X-Tav', Secret('t1'))));
        Observer.Observe('contains_secret', Format(Headers.ContainsSecret('X-Tav')));
        Arr(Observer, 'values', Headers, 'X-Tav');
        Observer.Observe('try_add_plain', Format(Headers.TryAddWithoutValidation('X-Tav2', 'plain')));
        Observer.Observe('contains_secret_plain', Format(Headers.ContainsSecret('X-Tav2')));
        Arr(Observer, 'values_plain', Headers, 'X-Tav2');
        Observer.Expect('try_add', 'Yes');
        Observer.Expect('contains_secret', 'Yes');
        Observer.Expect('values', 'Yes|No|Yes|Yes');
        Observer.Expect('try_add_plain', 'Yes');
        Observer.Expect('contains_secret_plain', 'No');
        Observer.Expect('values_plain', 'No|Yes|Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetSecretValues_UninitialisedHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        Arr(Observer, 'array', Headers, 'X-Sec');
        Lst(Observer, 'list', Headers, 'X-Sec');
        Observer.Expect('array', 'No|Yes|Yes|Yes');
        Observer.Expect('list', 'No|0|');
        Observer.Verify();
    end;
}
