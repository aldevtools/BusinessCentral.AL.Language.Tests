codeunit 89870 "LT TG Scratch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    [Test]
    procedure Lit()
    var
        T: Text;
    begin
        asserterror T := PadStr('ab', 3);
        Obs.Observe('a', T);
        asserterror T := PadStr('ab', 3.4);
        Obs.ObserveError('b');
        asserterror T := PadStr('ab', 3.6, 'x');
        Obs.ObserveError('c');
        asserterror T := PadStr('ab', -1.5);
        Obs.ObserveError('d');
        asserterror T := CopyStr('abcdef', 2.4, 3);
        Obs.ObserveError('e');
        asserterror T := CopyStr('abcdef', 2, 3.5);
        Obs.ObserveError('f');
        asserterror T := DelStr('abcdef', 2.5);
        Obs.ObserveError('g');
        asserterror T := InsStr('abcdef', 'X', 2.5);
        Obs.ObserveError('h');
        asserterror T := SelectStr(2.5, 'a,b,c');
        Obs.ObserveError('i');
        Obs.Finish();
    end;
}
