codeunit 89870 "LT TG Scratch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    [Test]
    procedure AssertErrAssign()
    var
        T: Text;
    begin
        asserterror T := PadStr('ab', 3.4);
        Obs.ObserveError('b');
        Obs.Finish();
    end;

    [Test]
    procedure AssertErrCopy()
    var
        T: Text;
    begin
        asserterror T := CopyStr('abcdef', 2, 3.5);
        Obs.ObserveError('f');
        asserterror Error('%1', CopyStr('abcdef', 2.4, 3));
        Obs.ObserveError('g');
        Obs.Finish();
    end;
}
