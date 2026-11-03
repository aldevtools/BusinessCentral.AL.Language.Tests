// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Objects.al (tables "LT P116 Trig Src"/"Trig NoPerm", codeunits "LT P116 Writer"/"Writer NoPerm").
// Permissions property on a table and a codeunit: indirect permission for the code of the object.

codeunit 70431 "LT P116 Indirect"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetATok: Label 'LT P116 Set A', Locked = true;

    [Test]
    procedure P116_TableTriggerWithPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Src: Record "LT P116 Trig Src";
        Target: Record "LT P116 Target";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetATok);
        Src."Entry No." := 1;
        Src.Insert();
        Observer.Observe('insert src', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('src count', Format(Src.Count()));
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('insert src', 'no error');
        Observer.Expect('src count', '1');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_TableTriggerWithoutPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Src: Record "LT P116 Trig NoPerm";
        Target: Record "LT P116 Target";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetATok);
        Src."Entry No." := 1;
        Src.Insert();
        Observer.Observe('insert src', 'no error');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('src count', Format(Src.Count()));
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('insert src', 'no error');
        Observer.Expect('src count', '1');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_CodeunitWithPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Writer: Codeunit "LT P116 Writer";
        Target: Record "LT P116 Target";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetATok);
        asserterror Writer.Write(1);
        Observer.ObserveError('write');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('write|text', 'Sorry, the current permissions prevented the action. (TableData 70418 LT P116 Target IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('write|code', 'DB:ClientInsertDenied');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_CodeunitWithoutPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Writer: Codeunit "LT P116 Writer NoPerm";
        Target: Record "LT P116 Target";
        WasStarted: Boolean;
    begin
        Init();
        WasStarted := StartMock(Mock);
        Mock.Set(SetATok);
        asserterror Writer.Write(1);
        Observer.ObserveError('write');
        RestoreMock(Mock, WasStarted);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('write|text', 'Sorry, the current permissions prevented the action. (TableData 70418 LT P116 Target Insert: AL Language Coverage Tests)');
        Observer.Expect('write|code', 'DB:ClientInsertDenied');
        Observer.Expect('target count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P116_NoMockBothWork()
    var
        Observer: Codeunit "Probe Observer";
        W1: Codeunit "LT P116 Writer";
        W2: Codeunit "LT P116 Writer NoPerm";
        Target: Record "LT P116 Target";
    begin
        Init();
        W1.Write(1);
        W2.Write(2);
        Observer.Observe('target count', Format(Target.Count()));
        Observer.Expect('target count', '2');
        Observer.Verify();
    end;

    local procedure Init()
    var
        Src1: Record "LT P116 Trig Src";
        Src2: Record "LT P116 Trig NoPerm";
        Target: Record "LT P116 Target";
    begin
        Src1.DeleteAll();
        Src2.DeleteAll();
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
