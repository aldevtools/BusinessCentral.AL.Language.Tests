// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 99691
// Probe: observation form. Every test ends in Finish(), so it fails on purpose and its message carries what BC produced.
// Facts: JsonArray.Insert, Set, Get and RemoveAt (index outside the array), SelectToken and ReadFrom, and JsonToken and JsonValue ReadFrom and SelectToken, with the return value used
//   Each failing call is made in five forms: as a statement, assigned (Ok := ...), in a condition (if not ... then),
//   returned (exit(...), also with the caller ignoring that result) and passed as an argument. Observed per form: the
//   return value, the last error text and code, and the JSON text afterwards.
// BC versions: 27, 28 and 29 by the corpus CI matrix

codeunit 99691 "JSON Array Used Return"
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

    local procedure ArrayInsert_IndexAboveCount_Exit(var R: JsonArray): Boolean
    begin
        exit(R.Insert(5, 9));
    end;

    [Test]
    procedure ArrayInsert_IndexAboveCount_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        ClearLastError();
        Ok := true;
        Ok := R.Insert(5, 9);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Insert(5, 9) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArrayInsert_IndexAboveCount_Exit(R)));
        ArrayInsert_IndexAboveCount_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Insert(5, 9)));
        Observer.Observe('format', Format(R.Insert(5, 9)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2]');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayInsert_IndexAboveCount_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
    begin
        R.Add(1);
        R.Add(2);
        asserterror R.Insert(5, 9);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'Index out of bounds.');
        Observer.Expect('statement|code', 'IndexOutOfBounds');
        Observer.Expect('state', '[1,2]');
        Observer.Verify();
    end;

    local procedure ArrayInsert_NegativeIndex_Exit(var R: JsonArray): Boolean
    begin
        exit(R.Insert(-1, 9));
    end;

    [Test]
    procedure ArrayInsert_NegativeIndex_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        ClearLastError();
        Ok := true;
        Ok := R.Insert(-1, 9);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Insert(-1, 9) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArrayInsert_NegativeIndex_Exit(R)));
        ArrayInsert_NegativeIndex_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Insert(-1, 9)));
        Observer.Observe('format', Format(R.Insert(-1, 9)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2]');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayInsert_NegativeIndex_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
    begin
        R.Add(1);
        R.Add(2);
        asserterror R.Insert(-1, 9);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'Index out of bounds.');
        Observer.Expect('statement|code', 'IndexOutOfBounds');
        Observer.Expect('state', '[1,2]');
        Observer.Verify();
    end;

    local procedure ArraySet_IndexOutside_Exit(var R: JsonArray): Boolean
    begin
        exit(R.Set(2, 9));
    end;

    [Test]
    procedure ArraySet_IndexOutside_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        ClearLastError();
        Ok := true;
        Ok := R.Set(2, 9);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.Set(2, 9) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArraySet_IndexOutside_Exit(R)));
        ArraySet_IndexOutside_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Set(2, 9)));
        Observer.Observe('format', Format(R.Set(2, 9)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2]');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ArraySet_IndexOutside_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
    begin
        R.Add(1);
        R.Add(2);
        asserterror R.Set(2, 9);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'Index out of bounds.');
        Observer.Expect('statement|code', 'IndexOutOfBounds');
        Observer.Expect('state', '[1,2]');
        Observer.Verify();
    end;

    local procedure ArrayGet_IndexOutside_Exit(var R: JsonArray): Boolean
    var
        T: JsonToken;
    begin
        exit(R.Get(2, T));
    end;

    [Test]
    procedure ArrayGet_IndexOutside_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.Get(2, T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.Get(2, T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArrayGet_IndexOutside_Exit(R)));
        ArrayGet_IndexOutside_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.Get(2, T)));
        Observer.Observe('format', Format(R.Get(2, T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2] / "marker"');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayGet_IndexOutside_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.Get(2, T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('statement|text', 'Index out of bounds.');
        Observer.Expect('statement|code', 'IndexOutOfBounds');
        Observer.Expect('state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    local procedure ArrayRemoveAt_IndexOutside_Exit(var R: JsonArray): Boolean
    begin
        exit(R.RemoveAt(2));
    end;

    [Test]
    procedure ArrayRemoveAt_IndexOutside_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        ClearLastError();
        Ok := true;
        Ok := R.RemoveAt(2);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.RemoveAt(2) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArrayRemoveAt_IndexOutside_Exit(R)));
        ArrayRemoveAt_IndexOutside_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.RemoveAt(2)));
        Observer.Observe('format', Format(R.RemoveAt(2)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2]');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayRemoveAt_IndexOutside_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
    begin
        R.Add(1);
        R.Add(2);
        asserterror R.RemoveAt(2);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'Index out of bounds.');
        Observer.Expect('statement|code', 'IndexOutOfBounds');
        Observer.Expect('state', '[1,2]');
        Observer.Verify();
    end;

    local procedure ArraySelectToken_MissingPath_Exit(var R: JsonArray): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('[5]', T));
    end;

    [Test]
    procedure ArraySelectToken_MissingPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.SelectToken('[5]', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.SelectToken('[5]', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArraySelectToken_MissingPath_Exit(R)));
        ArraySelectToken_MissingPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('[5]', T)));
        Observer.Observe('format', Format(R.SelectToken('[5]', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '[1,2] / "marker"');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure ArraySelectToken_MissingPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('[5]', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('statement|text', 'The JSON path ''[5]'' does not match any tokens.');
        Observer.Expect('statement|code', 'InvalidJsonPathSelection');
        Observer.Expect('state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    local procedure ArraySelectToken_UnclosedPath_Exit(var R: JsonArray): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('[', T));
    end;

    [Test]
    procedure ArraySelectToken_UnclosedPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.SelectToken('[', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        ClearLastError();
        if not R.SelectToken('[', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArraySelectToken_UnclosedPath_Exit(R)));
        ArraySelectToken_UnclosedPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('[', T)));
        Observer.Observe('format', Format(R.SelectToken('[', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('assign_last_code', 'InvalidOperation');
        Observer.Expect('assign_state', '[1,2] / "marker"');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('end_state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure ArraySelectToken_UnclosedPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.Add(1);
        R.Add(2);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('[', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('statement|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('statement|code', 'InvalidOperation');
        Observer.Expect('state', '[1,2] / "marker"');
        Observer.Verify();
    end;

    local procedure ArrayReadFrom_InvalidText_Exit(var R: JsonArray): Boolean
    begin
        exit(R.ReadFrom('[1,'));
    end;

    [Test]
    procedure ArrayReadFrom_InvalidText_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        ClearLastError();
        Ok := true;
        Ok := R.ReadFrom('[1,');
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R.AsToken()));
        ClearLastError();
        if not R.ReadFrom('[1,') then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(ArrayReadFrom_InvalidText_Exit(R)));
        ArrayReadFrom_InvalidText_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.ReadFrom('[1,')));
        Observer.Observe('format', Format(R.ReadFrom('[1,')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('assign_last_code', 'InvalidJsonData');
        Observer.Expect('assign_state', '[1,2]');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('end_state', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayReadFrom_InvalidText_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
    begin
        R.Add(1);
        R.Add(2);
        asserterror R.ReadFrom('[1,');
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('statement|code', 'InvalidJsonData');
        Observer.Expect('state', '[1,2]');
        Observer.Verify();
    end;

    local procedure TokenReadFrom_InvalidText_Exit(var R: JsonToken): Boolean
    begin
        exit(R.ReadFrom('{"a":'));
    end;

    [Test]
    procedure TokenReadFrom_InvalidText_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonToken;
        Ok: Boolean;
    begin
        R.ReadFrom('{"a":1}');
        ClearLastError();
        Ok := true;
        Ok := R.ReadFrom('{"a":');
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R));
        ClearLastError();
        if not R.ReadFrom('{"a":') then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(TokenReadFrom_InvalidText_Exit(R)));
        TokenReadFrom_InvalidText_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.ReadFrom('{"a":')));
        Observer.Observe('format', Format(R.ReadFrom('{"a":')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('assign_last_code', 'InvalidJsonData');
        Observer.Expect('assign_state', '{"a":1}');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('end_state', '{"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure TokenReadFrom_InvalidText_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonToken;
    begin
        R.ReadFrom('{"a":1}');
        asserterror R.ReadFrom('{"a":');
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R));
        Observer.Expect('statement|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('statement|code', 'InvalidJsonData');
        Observer.Expect('state', '{"a":1}');
        Observer.Verify();
    end;

    local procedure TokenSelectToken_MissingPath_Exit(var R: JsonToken): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('zz', T));
    end;

    [Test]
    procedure TokenSelectToken_MissingPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonToken;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.ReadFrom('{"a":1}');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        ClearLastError();
        Ok := true;
        Ok := R.SelectToken('zz', T);
        Observer.Observe('assign', Format(Ok));
        Observer.Observe('assign_last_text', GetLastErrorText());
        Observer.Observe('assign_last_code', GetLastErrorCode());
        Observer.Observe('assign_state', Txt(R) + ' / ' + Txt(T));
        ClearLastError();
        if not R.SelectToken('zz', T) then
            Observer.Observe('if_not', 'then branch')
        else
            Observer.Observe('if_not', 'else branch');
        Observer.Observe('exit', Format(TokenSelectToken_MissingPath_Exit(R)));
        TokenSelectToken_MissingPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('zz', T)));
        Observer.Observe('format', Format(R.SelectToken('zz', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R) + ' / ' + Txt(T));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '{"a":1} / "marker"');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '{"a":1} / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure TokenSelectToken_MissingPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonToken;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.ReadFrom('{"a":1}');
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('zz', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R) + ' / ' + Txt(T));
        Observer.Expect('statement|text', 'The JSON path ''zz'' does not match any tokens.');
        Observer.Expect('statement|code', 'InvalidJsonPathSelection');
        Observer.Expect('state', '{"a":1} / "marker"');
        Observer.Verify();
    end;

    local procedure ValueReadFrom_InvalidText_Exit(var R: JsonValue): Boolean
    begin
        exit(R.ReadFrom('{"a":'));
    end;

    [Test]
    procedure ValueReadFrom_InvalidText_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonValue;
        Ok: Boolean;
    begin
        R.SetValue(7);
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
        Observer.Observe('exit', Format(ValueReadFrom_InvalidText_Exit(R)));
        ValueReadFrom_InvalidText_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.ReadFrom('{"a":')));
        Observer.Observe('format', Format(R.ReadFrom('{"a":')));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('assign_last_code', 'InvalidJsonData');
        Observer.Expect('assign_state', '7');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', 'The data does not represent a valid JSON token.');
        Observer.Expect('end_state', '7');
        Observer.Verify();
    end;

    [Test]
    procedure ValueReadFrom_InvalidText_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonValue;
    begin
        R.SetValue(7);
        asserterror R.ReadFrom('{"a":');
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('statement|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('statement|code', 'InvalidJsonData');
        Observer.Expect('state', '7');
        Observer.Verify();
    end;

    local procedure ValueSelectToken_MissingPath_Exit(var R: JsonValue): Boolean
    var
        T: JsonToken;
    begin
        exit(R.SelectToken('zz', T));
    end;

    [Test]
    procedure ValueSelectToken_MissingPath_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonValue;
        Marker: JsonValue;
        T: JsonToken;
        Ok: Boolean;
    begin
        R.SetValue(7);
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
        Observer.Observe('exit', Format(ValueSelectToken_MissingPath_Exit(R)));
        ValueSelectToken_MissingPath_Exit(R);
        Observer.Observe('exit_result_ignored', 'no error');
        Observer.Observe('argument', TakeBoolean(R.SelectToken('zz', T)));
        Observer.Observe('format', Format(R.SelectToken('zz', T)));
        Observer.Observe('end_last_text', GetLastErrorText());
        Observer.Observe('end_state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('assign', 'No');
        Observer.Expect('assign_last_text', '');
        Observer.Expect('assign_last_code', '');
        Observer.Expect('assign_state', '7 / "marker"');
        Observer.Expect('if_not', 'then branch');
        Observer.Expect('exit', 'No');
        Observer.Expect('exit_result_ignored', 'no error');
        Observer.Expect('argument', 'false');
        Observer.Expect('format', 'No');
        Observer.Expect('end_last_text', '');
        Observer.Expect('end_state', '7 / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure ValueSelectToken_MissingPath_Statement()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonValue;
        Marker: JsonValue;
        T: JsonToken;
    begin
        R.SetValue(7);
        Marker.SetValue('marker');
        T := Marker.AsToken();
        asserterror R.SelectToken('zz', T);
        Observer.ObserveError('statement');
        Observer.Observe('state', Txt(R.AsToken()) + ' / ' + Txt(T));
        Observer.Expect('statement|text', 'The JSON path ''zz'' does not match any tokens.');
        Observer.Expect('statement|code', 'InvalidJsonPathSelection');
        Observer.Expect('state', '7 / "marker"');
        Observer.Verify();
    end;

    [Test]
    procedure Array_Success_UsedForms()
    var
        Observer: Codeunit "Probe Observer";
        R: JsonArray;
        Ok: Boolean;
    begin
        R.Add(1);
        R.Add(2);
        Ok := R.Insert(0, 9);
        Observer.Observe('insert_assign', Format(Ok));
        if R.Insert(3, 8) then
            Observer.Observe('insert_at_count_if', 'then branch')
        else
            Observer.Observe('insert_at_count_if', 'else branch');
        Observer.Observe('insert_argument', TakeBoolean(R.Insert(1, 7)));
        Ok := false;
        Ok := R.Set(0, 6);
        Observer.Observe('set_assign', Format(Ok));
        Observer.Observe('set_argument', TakeBoolean(R.Set(1, 5)));
        Ok := false;
        Ok := R.RemoveAt(4);
        Observer.Observe('removeat_assign', Format(Ok));
        Observer.Observe('removeat_argument', TakeBoolean(R.RemoveAt(0)));
        Observer.Observe('state', Txt(R.AsToken()));
        Observer.Expect('insert_assign', 'Yes');
        Observer.Expect('insert_at_count_if', 'then branch');
        Observer.Expect('insert_argument', 'true');
        Observer.Expect('set_assign', 'Yes');
        Observer.Expect('set_argument', 'true');
        Observer.Expect('removeat_assign', 'Yes');
        Observer.Expect('removeat_argument', 'true');
        Observer.Expect('state', '[5,1,2]');
        Observer.Verify();
    end;
}
