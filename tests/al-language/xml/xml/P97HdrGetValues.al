// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpHeaders.GetValues into Array of Text with a Text key and List of Text, array size limits, and TryAddWithoutValidation(Name, Text) results, invalid names and values
// BC versions: 29 (27 and 28 by CI)

codeunit 74810 "LT P97 Hdr GetValues"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewHeaders(var Headers: HttpHeaders)
    var
        Req: HttpRequestMessage;
    begin
        Req.GetHeaders(Headers);
    end;

    [TryFunction]
    local procedure TryArray2(var Headers: HttpHeaders; HdrKey: Text; var Result: Text)
    var
        Vals: array[2] of Text;
        Found: Boolean;
    begin
        Found := Headers.GetValues(HdrKey, Vals);
        Result := Format(Found) + '|' + Vals[1] + '|' + Vals[2];
    end;

    [TryFunction]
    local procedure TryList(var Headers: HttpHeaders; HdrKey: Text; var Pre: List of [Text]; var Result: Text)
    var
        Found: Boolean;
        V: Text;
        S: Text;
    begin
        Found := Headers.GetValues(HdrKey, Pre);
        foreach V in Pre do
            S += V + ';';
        Result := Format(Found) + '|' + Format(Pre.Count()) + '|' + S;
    end;

    local procedure Arr(var Observer: Codeunit "Probe Observer"; Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        R: Text;
    begin
        if TryArray2(Headers, HdrKey, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure Lst(var Observer: Codeunit "Probe Observer"; Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        R: Text;
        L: List of [Text];
    begin
        if TryList(Headers, HdrKey, L, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryAdd(var Headers: HttpHeaders; Name: Text; Value: Text; var Result: Boolean)
    begin
        Result := Headers.TryAddWithoutValidation(Name, Value);
    end;

    local procedure Tav(var Observer: Codeunit "Probe Observer"; Lbl: Text; var Headers: HttpHeaders; Name: Text; Value: Text)
    var
        R: Boolean;
        Vals: array[3] of Text;
    begin
        if TryAdd(Headers, Name, Value, R) then begin
            Observer.Observe(Lbl, Format(R) + '|' + Format(Headers.Contains(Name)));
            if Headers.GetValues(Name, Vals) then
                Observer.Observe(Lbl + '_val', Vals[1] + '|' + Vals[2]);
        end else
            Observer.ObserveError(Lbl);
    end;

    [Test]
    procedure GetValues_Array_Limits()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-One', 'a');
        Headers.Add('X-Two', 'a');
        Headers.Add('X-Two', 'b');
        Headers.Add('X-Three', 'a');
        Headers.Add('X-Three', 'b');
        Headers.Add('X-Three', 'c');
        Headers.Add('X-Comma', 'a, b');
        Headers.Add('X-Empty', '');
        Arr(Observer, 'one', Headers, 'X-One');
        Arr(Observer, 'two', Headers, 'X-Two');
        Arr(Observer, 'three_into_two', Headers, 'X-Three');
        Arr(Observer, 'comma', Headers, 'X-Comma');
        Arr(Observer, 'empty_value', Headers, 'X-Empty');
        Arr(Observer, 'missing', Headers, 'X-Missing');
        Arr(Observer, 'empty_key', Headers, '');
        Arr(Observer, 'lower_case_key', Headers, 'x-one');
        Observer.Expect('one', 'Yes|a|');
        Observer.Expect('two', 'Yes|a|b');
        Observer.Expect('three_into_two', 'No||');
        Observer.Expect('comma', 'Yes|a, b|');
        Observer.Expect('empty_value', 'Yes||');
        Observer.Expect('missing', 'No||');
        Observer.Expect('empty_key', 'No||');
        Observer.Expect('lower_case_key', 'Yes|a|');
        Observer.Verify();
    end;

    [Test]
    procedure GetValues_List_Overload()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
        Pre: List of [Text];
        R: Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-One', 'a');
        Headers.Add('X-Two', 'a');
        Headers.Add('X-Two', 'b');
        Lst(Observer, 'one', Headers, 'X-One');
        Lst(Observer, 'two', Headers, 'X-Two');
        Lst(Observer, 'missing', Headers, 'X-Missing');
        Lst(Observer, 'empty_key', Headers, '');
        Pre.Add('pre');
        if TryList(Headers, 'X-One', Pre, R) then
            Observer.Observe('prefilled_hit', R)
        else
            Observer.ObserveError('prefilled_hit');
        if TryList(Headers, 'X-Missing', Pre, R) then
            Observer.Observe('prefilled_miss', R)
        else
            Observer.ObserveError('prefilled_miss');
        Observer.Expect('one', 'Yes|1|a;');
        Observer.Expect('two', 'Yes|2|a;b;');
        Observer.Expect('missing', 'No|0|');
        Observer.Expect('empty_key', 'No|0|');
        Observer.Expect('prefilled_hit', 'Yes|2|pre;a;');
        Observer.Expect('prefilled_miss', 'No|2|pre;a;');
        Observer.Verify();
    end;

    [Test]
    procedure GetValues_OfSecretHeader()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
        S: SecretText;
    begin
        NewHeaders(Headers);
        S := SecretText.SecretStrSubstNo('hidden');
        Headers.Add('X-Sec', S);
        Arr(Observer, 'array', Headers, 'X-Sec');
        Lst(Observer, 'list', Headers, 'X-Sec');
        Observer.Observe('contains', Format(Headers.Contains('X-Sec')));
        Observer.Observe('contains_secret', Format(Headers.ContainsSecret('X-Sec')));
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('array', 'No||');
        Observer.Expect('list', 'No|0|');
        Observer.Expect('contains', 'No');
        Observer.Expect('contains_secret', 'Yes');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GetValues_UninitialisedHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        Arr(Observer, 'array', Headers, 'X-One');
        Lst(Observer, 'list', Headers, 'X-One');
        Observer.Expect('array', 'No||');
        Observer.Expect('list', 'No|0|');
        Observer.Verify();
    end;

    [Test]
    procedure TryAddWithoutValidation_Values()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
        Lf: Text[1];
        Cr: Text[1];
    begin
        Lf[1] := 10;
        Cr[1] := 13;
        NewHeaders(Headers);
        Tav(Observer, 'empty_value', Headers, 'X-V1', '');
        Tav(Observer, 'space_value', Headers, 'X-V2', ' ');
        Tav(Observer, 'lf_value', Headers, 'X-V3', 'a' + Lf + 'b');
        Tav(Observer, 'crlf_value', Headers, 'X-V4', 'a' + Cr + Lf + 'b: c');
        Tav(Observer, 'lf_space_value', Headers, 'X-V5', 'a' + Lf + ' b');
        Tav(Observer, 'unicode_value', Headers, 'X-V6', 'caf' + 'é');
        Tav(Observer, 'comma_value', Headers, 'X-V7', 'a, b');
        Tav(Observer, 'leading_trailing', Headers, 'X-V8', '  padded  ');
        Tav(Observer, 'date_invalid', Headers, 'Date', 'not a date');
        Tav(Observer, 'if_modified_invalid', Headers, 'If-Modified-Since', 'yesterday');
        Observer.Expect('empty_value', 'Yes|Yes');
        Observer.Expect('empty_value_val', '|');
        Observer.Expect('space_value', 'Yes|Yes');
        Observer.Expect('space_value_val', ' |');
        Observer.Expect('lf_value', 'Yes|Yes');
        Observer.Expect('lf_value_val', 'a\nb|');
        Observer.Expect('crlf_value', 'Yes|Yes');
        Observer.Expect('crlf_value_val', 'a\r\nb: c|');
        Observer.Expect('lf_space_value', 'Yes|Yes');
        Observer.Expect('lf_space_value_val', 'a\n b|');
        Observer.Expect('unicode_value', 'Yes|Yes');
        Observer.Expect('unicode_value_val', 'café|');
        Observer.Expect('comma_value', 'Yes|Yes');
        Observer.Expect('comma_value_val', 'a, b|');
        Observer.Expect('leading_trailing', 'Yes|Yes');
        Observer.Expect('leading_trailing_val', '  padded  |');
        Observer.Expect('date_invalid', 'Yes|Yes');
        Observer.Expect('date_invalid_val', 'not a date|');
        Observer.Expect('if_modified_invalid', 'Yes|Yes');
        Observer.Expect('if_modified_invalid_val', 'yesterday|');
        Observer.Verify();
    end;

    [Test]
    procedure TryAddWithoutValidation_VersusAdd()
    var
        Observer: Codeunit "Probe Observer";
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Observer.Observe('tav_first', Format(Headers.TryAddWithoutValidation('X-Twice', 'a')));
        Observer.Observe('tav_second', Format(Headers.TryAddWithoutValidation('X-Twice', 'b')));
        Arr(Observer, 'both', Headers, 'X-Twice');
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Observe('add_after', Format(Headers.Add('X-Twice', 'c')));
        Lst(Observer, 'three', Headers, 'X-Twice');
        Observer.Expect('tav_first', 'Yes');
        Observer.Expect('tav_second', 'Yes');
        Observer.Expect('both', 'Yes|a|b');
        Observer.Expect('keys', '1');
        Observer.Expect('add_after', 'Yes');
        Observer.Expect('three', 'Yes|3|a;b;c;');
        Observer.Verify();
    end;
}
