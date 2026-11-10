// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 99690
// Probe: observation form. Every test ends in Finish(), so it fails on purpose and its message carries what BC produced.
// Facts: JsonObject.Add (duplicate key), Replace, Get and Remove (missing key), SelectToken (missing and unclosed path) and ReadFrom (invalid text) with the return value used
//   Each failing call is made in five forms: as a statement, assigned (Ok := ...), in a condition (if not ... then),
//   returned (exit(...), also with the caller ignoring that result) and passed as an argument. Observed per form: the
//   return value, the last error text and code, and the JSON text afterwards.
// BC versions: 27, 28 and 29 by the corpus CI matrix

codeunit 99690 "JSON Object Used Return"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Txt(T: JsonToken): Text
    var
        R: Text;
    begin
        T.WriteTo(R);
        exit(R);
    end;

    local procedure TakeBoolean(B: Boolean): Text
    begin
        if B then
            exit('true');
        exit('false');
    end;

    local procedure ObjectAdd_DuplicateKey_Exit(var R: JsonObject): Boolean
    begin
        exit(R.Add('a', 2));
    end;

    [Test]
    procedure ObjectAdd_DuplicateKey_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.Add('a', 2);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Add('a', 2) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectAdd_DuplicateKey_Exit(R)));
        ObjectAdd_DuplicateKey_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Add('a', 2)));
        Observer.Observe('format', Format(R.Add('a', 2)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectAdd_DuplicateKey_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        asserterror R.Add('a', 2);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    local procedure ObjectAdd_DuplicateKeyText_Exit(var R: JsonObject): Boolean
    begin
        exit(R.Add('b', 'other'));
    end;

    [Test]
    procedure ObjectAdd_DuplicateKeyText_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.Add('b', 'other');
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Add('b', 'other') then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectAdd_DuplicateKeyText_Exit(R)));
        ObjectAdd_DuplicateKeyText_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Add('b', 'other')));
        Observer.Observe('format', Format(R.Add('b', 'other')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectAdd_DuplicateKeyText_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        asserterror R.Add('b', 'other');
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    local procedure ObjectAdd_DuplicateKeyObject_Exit(var R: JsonObject): Boolean
    var
        Inner: JsonObject;
    begin
        exit(R.Add('a', Inner));
    end;

    [Test]
    procedure ObjectAdd_DuplicateKeyObject_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Inner: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.Add('a', Inner);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Add('a', Inner) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectAdd_DuplicateKeyObject_Exit(R)));
        ObjectAdd_DuplicateKeyObject_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Add('a', Inner)));
        Observer.Observe('format', Format(R.Add('a', Inner)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectAdd_DuplicateKeyObject_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Inner: JsonObject;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        asserterror R.Add('a', Inner);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    local procedure ObjectReplace_MissingKey_Exit(var R: JsonObject): Boolean
    begin
        exit(R.Replace('zz', 2));
    end;

    [Test]
    procedure ObjectReplace_MissingKey_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.Replace('zz', 2);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Replace('zz', 2) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectReplace_MissingKey_Exit(R)));
        ObjectReplace_MissingKey_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Replace('zz', 2)));
        Observer.Observe('format', Format(R.Replace('zz', 2)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectReplace_MissingKey_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        asserterror R.Replace('zz', 2);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    local procedure ObjectGet_MissingKey_Exit(var R: JsonObject): Boolean
    var
        T: JsonToken;
    begin
        exit(R.Get('zz', T));
    end;

    [Test]
    procedure ObjectGet_MissingKey_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.Get('zz', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.Get('zz', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectGet_MissingKey_Exit(R)));
        ObjectGet_MissingKey_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Get('zz', T)));
        Observer.Observe('format', Format(R.Get('zz', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectGet_MissingKey_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.Get('zz', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    local procedure ObjectRemove_MissingKey_Exit(var R: JsonObject): Boolean
    begin
        exit(R.Remove('zz'));
    end;

    [Test]
    procedure ObjectRemove_MissingKey_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.Remove('zz');
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Remove('zz') then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectRemove_MissingKey_Exit(R)));
        ObjectRemove_MissingKey_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Remove('zz')));
        Observer.Observe('format', Format(R.Remove('zz')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    local procedure ObjectSelectToken_MissingPath_Exit(var R: JsonObject): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('zz', T));
    end;

    [Test]
    procedure ObjectSelectToken_MissingPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.SelectToken('zz', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.SelectToken('zz', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectSelectToken_MissingPath_Exit(R)));
        ObjectSelectToken_MissingPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('zz', T)));
        Observer.Observe('format', Format(R.SelectToken('zz', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectSelectToken_MissingPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('zz', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    local procedure ObjectSelectToken_UnclosedPath_Exit(var R: JsonObject): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('a[', T));
    end;

    [Test]
    procedure ObjectSelectToken_UnclosedPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.SelectToken('a[', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.SelectToken('a[', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectSelectToken_UnclosedPath_Exit(R)));
        ObjectSelectToken_UnclosedPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('a[', T)));
        Observer.Observe('format', Format(R.SelectToken('a[', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectSelectToken_UnclosedPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('a[', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Finish();
    end;

    local procedure ObjectReadFrom_InvalidText_Exit(var R: JsonObject): Boolean
    begin
        exit(R.ReadFrom('{"a":'));
    end;

    [Test]
    procedure ObjectReadFrom_InvalidText_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        ClearLastError();
        Ok := true;
        Ok := R.ReadFrom('{"a":');
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.ReadFrom('{"a":') then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ObjectReadFrom_InvalidText_Exit(R)));
        ObjectReadFrom_InvalidText_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.ReadFrom('{"a":')));
        Observer.Observe('format', Format(R.ReadFrom('{"a":')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure ObjectReadFrom_InvalidText_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
    begin
        R.Add('a', 1);
        R.Add('b', 'x');
        asserterror R.ReadFrom('{"a":');
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;

    [Test]
    procedure Object_Success_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonObject;
        Ok: Boolean;
    begin
        Ok := R.Add('a', 1);
        Observer.Observe('add_assign', Format(Ok));
        if R.Add('b', 2) then
            Observer.Observe('add_if', 'then branch')
        else
            Observer.Observe('add_if', 'else branch');
        Observer.Observe('add_argument', TakeBoolean(R.Add('c', 3)));
        Ok := false;
        Ok := R.Replace('a', 5);
        Observer.Observe('replace_assign', Format(Ok));
        Observer.Observe('replace_argument', TakeBoolean(R.Replace('b', 6)));
        Ok := false;
        Ok := R.Remove('c');
        Observer.Observe('remove_assign', Format(Ok));
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Finish();
    end;
}
