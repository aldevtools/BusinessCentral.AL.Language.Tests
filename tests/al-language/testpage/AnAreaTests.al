// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-applicationarea-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 79400, page 79417 (AnObjects.al)
// Probe: every literal asserted below is what BC 29.0.54011.55816 produced in the corpus CI (Linux container); BC 27 and 28 are checked by the CI legs.
// Settles corpus issue 640 (TestPage behavior, part 1), items 6 and 7 (item 5 cannot compile: a group has no ApplicationArea, must-not-compile case 1091).
// Facts: SetValue after the session's areas change while the
// TestPage is open; the whole error text and code of Invoke on an action removed by application areas (page compiled in the test app).
// Every test restores the session's application areas it found.

codeunit 79451 "LT AN Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AN Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'ONE';
        Row.Name := 'name';
        Row.Basic := 'basic';
        Row.Suite := 'suite';
        Row.Insert();
    end;

    local procedure OpenCard(var P: TestPage "LT AN Area Card")
    var
        Row: Record "LT AN Row";
    begin
        Row.Get('ONE');
        P.OpenEdit();
        P.GoToRecord(Row);
    end;

    [TryFunction]
    local procedure TrySetSuite(var P: TestPage "LT AN Area Card"; V: Text)
    begin
        P.SuiteCtl.SetValue(V);
    end;

    [TryFunction]
    local procedure TryValueSuite(var P: TestPage "LT AN Area Card"; var Result: Text)
    begin
        Result := P.SuiteCtl.Value();
    end;

    // ---- item 6: the areas change while the TestPage is open ----

    [Test]
    procedure An06_AreaRemovedAfterOpen_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Area Card";
        Previous: Text;
        Value: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        OpenCard(P);
        ApplicationArea('#Basic');
        if TrySetSuite(P, 'changed') then
            Observer.Observe('setValue', 'ok')
        else
            Observer.ObserveError('setValue');
        if TryValueSuite(P, Value) then
            Observer.Observe('value', Value)
        else
            Observer.ObserveError('value');
        P.Close();
        ApplicationArea(Previous);
        Row.Get('ONE');
        Observer.Observe('stored', Row.Suite);
        Observer.Expect('setValue', 'ok');
        Observer.Expect('value', 'changed');
        Observer.Expect('stored', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure An06_AreaAddedAfterOpen_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AN Row";
        P: TestPage "LT AN Area Card";
        Previous: Text;
        Value: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(P);
        ApplicationArea('#Basic,#Suite');
        if TrySetSuite(P, 'changed') then
            Observer.Observe('setValue', 'ok')
        else
            Observer.ObserveError('setValue');
        if TryValueSuite(P, Value) then
            Observer.Observe('value', Value)
        else
            Observer.ObserveError('value');
        P.Close();
        ApplicationArea(Previous);
        Row.Get('ONE');
        Observer.Observe('stored', Row.Suite);
        Observer.Expect('setValue|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('setValue|code', 'TestFieldNotFound');
        Observer.Expect('value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('value|code', 'TestFieldNotFound');
        Observer.Expect('stored', 'suite');
        Observer.Verify();
    end;

    // ---- item 7: the whole error text of Invoke on an action removed by application areas ----

    [Test]
    procedure An07_RemovedAction_InvokeFullText()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AN Area Card";
        Previous: Text;
        ErrText: Text;
        ErrCode: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(P);
        asserterror P.ActSuite.Invoke();
        ErrText := GetLastErrorText();
        ErrCode := GetLastErrorCode();
        ClearLastError();
        P.Close();
        ApplicationArea(Previous);
        // The observer would replace the number after 'with ID = '; the probe records the whole text with that marker changed.
        Observer.Observe('text', ErrText.Replace('with ID = ', 'with ID #'));
        Observer.Observe('code', ErrCode);
        Observer.Expect('text', 'The action with ID #1281090153 is not found on the page.');
        Observer.Expect('code', 'TestActionNotFound');
        Observer.Verify();
    end;
}
