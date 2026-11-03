// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Objects.al (own tables and permission sets "LT P116 Set A/B/C").

codeunit 70430 "LT P116 Mock Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetATok: Label 'LT P116 Set A', Locked = true;
        SetBTok: Label 'LT P116 Set B', Locked = true;
        SetCTok: Label 'LT P116 Set C', Locked = true;

    [Test]
    procedure P116_ReadOnlySet()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Open";
        Probe: Record "LT P116 Open";
        WasStarted: Boolean;
    begin
        Init();
        Row."Entry No." := 1;
        Row.Value := 10;
        Row.Insert();
        WasStarted := StartMock(Mock);
        Mock.Set(SetBTok);
        Observer.Observe('is started', Format(Mock.IsStarted()));
        Observer.Observe('get allowed', Format(Probe.Get(1)));
        Observer.Observe('value', Format(Probe.Value));
        Observer.Observe('count', Format(Probe.Count()));
        Observer.Observe('isempty', Format(Probe.IsEmpty()));
        Probe."Entry No." := 2;
        asserterror Probe.Insert();
        Observer.ObserveError('insert refused');
        asserterror Probe.Get(1);
        Observer.ObserveError('af40');
        Probe.Value := 11;
        asserterror Probe.Modify();
        Observer.ObserveError('modify refused');
        asserterror Probe.Delete();
        Observer.ObserveError('delete refused');
        Probe.DeleteAll();
        Observer.Observe('deleteall refused', 'no error');
        Probe.ModifyAll(Value, 5);
        Observer.Observe('modifyall refused', 'no error');
        Probe."Entry No." := 3;
        asserterror Probe.Insert(true);
        Observer.ObserveError('insert true refused');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('after restore count', Format(Row.Count()));
        Observer.Observe('after restore value', Format(Row.Get(1)));
        Observer.Expect('is started', 'Yes');
        Observer.Expect('get allowed', 'Yes');
        Observer.Expect('value', '10');
        Observer.Expect('count', '1');
        Observer.Expect('isempty', 'No');
        Observer.Expect('insert refused|text', 'Sorry, the current permissions prevented the action. (TableData 70415 LT P116 Open Insert: AL Language Coverage Tests)');
        Observer.Expect('insert refused|code', 'DB:ClientInsertDenied');
        Observer.Expect('af40|text', 'The LT P116 Open does not exist. Identification fields and values: Entry No.=''1''');
        Observer.Expect('af40|code', 'DB:RecordNotFound');
        Observer.Expect('modify refused|text', 'Sorry, the current permissions prevented the action. (TableData 70415 LT P116 Open Modify: AL Language Coverage Tests)');
        Observer.Expect('modify refused|code', 'DB:ClientModifyDenied');
        Observer.Expect('delete refused|text', 'Sorry, the current permissions prevented the action. (TableData 70415 LT P116 Open Delete: AL Language Coverage Tests)');
        Observer.Expect('delete refused|code', 'DB:ClientDeleteDenied');
        Observer.Expect('deleteall refused', 'no error');
        Observer.Expect('modifyall refused', 'no error');
        Observer.Expect('insert true refused|text', 'Sorry, the current permissions prevented the action. (TableData 70415 LT P116 Open Insert: AL Language Coverage Tests)');
        Observer.Expect('insert true refused|code', 'DB:ClientInsertDenied');
        Observer.Expect('after restore count', '0');
        Observer.Expect('after restore value', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P116_FullSet()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Open";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetATok);
        Row."Entry No." := 1;
        Row.Value := 1;
        Row.Insert();
        Row.Value := 2;
        Row.Modify();
        Observer.Observe('value', Format(Row.Value));
        Row.Delete();
        Observer.Observe('count', Format(Row.Count()));
        Row.Insert();
        Observer.Observe('insert again', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Expect('value', '2');
        Observer.Expect('count', '0');
        Observer.Expect('insert again', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P116_SetC_InsertReadOnTarget()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT P116 Target";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetCTok);
        Target."Entry No." := 1;
        Target.Value := 3;
        Target.Insert();
        Observer.Observe('count', Format(Target.Count()));
        Target.Value := 4;
        asserterror Target.Modify();
        Observer.ObserveError('modify');
        asserterror Target.Delete();
        Observer.ObserveError('delete');
        RestoreMock(Mock, WasStarted);
        asserterror Target.Get(1);
        Observer.ObserveError('af134');
        Observer.Observe('value after', Format(Target.Value));
        Observer.Expect('count', '1');
        Observer.Expect('modify|text', 'Sorry, the current permissions prevented the action. (TableData 70418 LT P116 Target Modify: AL Language Coverage Tests)');
        Observer.Expect('modify|code', 'DB:ClientModifyDenied');
        Observer.Expect('delete|text', 'Sorry, the current permissions prevented the action. (TableData 70418 LT P116 Target Delete: AL Language Coverage Tests)');
        Observer.Expect('delete|code', 'DB:ClientDeleteDenied');
        Observer.Expect('af134|text', 'The LT P116 Target does not exist. Identification fields and values: Entry No.=''1''');
        Observer.Expect('af134|code', 'DB:RecordNotFound');
        Observer.Expect('value after', '4');
        Observer.Verify();
    end;

    [Test]
    procedure P116_UnknownSet()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Row: Record "LT P116 Open";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        asserterror Mock.Set('LT P116 NO SUCH');
        Observer.ObserveError('set unknown');
        Row."Entry No." := 1;
        asserterror Row.Insert();
        Observer.ObserveError('insert after unknown set');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('is started restored', Format(Mock.IsStarted() = WasStarted));
        Observer.Expect('set unknown|text', 'The Permission Set does not exist. Identification fields and values: Role ID=''LT P116 NO SUCH''');
        Observer.Expect('set unknown|code', 'DB:RecordNotFound');
        Observer.Expect('insert after unknown set|text', 'Sorry, the current permissions prevented the action. (TableData 70415 LT P116 Open Insert: AL Language Coverage Tests)');
        Observer.Expect('insert after unknown set|code', 'DB:ClientInsertDenied');
        Observer.Expect('is started restored', 'Yes');
        Observer.Verify();
    end;

    local procedure Init()
    var
        Open: Record "LT P116 Open";
        Target: Record "LT P116 Target";
    begin
        Open.DeleteAll();
        Target.DeleteAll();
    end;

    local procedure StartMock(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
