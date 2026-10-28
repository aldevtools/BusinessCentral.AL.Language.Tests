codeunit 89870 "LT TG Scratch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Flag: Boolean;

    [Test]
    procedure DeadBranch()
    var
        T: Text;
    begin
        if Flag then
            T := PadStr('ab', 3.4);
        Obs.Observe('dead', 'ran');
        Obs.Finish();
    end;

    [Test]
    procedure InTry()
    var
        T: Text;
        Ok: Boolean;
    begin
        Ok := TryLit(T);
        Obs.Observe('try', Format(Ok) + '|' + T);
        Obs.ObserveError('try');
        Obs.Finish();
    end;

    [Test]
    procedure WholeLiteral()
    var
        T: Text;
    begin
        T := PadStr('ab', 3.0);
        Obs.Observe('whole', T + '|' + CopyStr('abcdef', 2.0, 3.0));
        Obs.Finish();
    end;

    [Test]
    procedure TwoInOne()
    var
        T: Text;
    begin
        Obs.Observe('before', 'ran');
        T := CopyStr('abcdef', 2, 3.5);
        Obs.Observe('after', T);
        Obs.Finish();
    end;

    [TryFunction]
    local procedure TryLit(var T: Text)
    begin
        T := PadStr('ab', 3.4);
    end;
}
