codeunit 89870 "LT TG Scratch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Lit()
    var
        T: Text;
    begin
        T := PadStr('ab', 3);
        T := PadStr('ab', 3.0);
        T := PadStr('ab', 3.4);
        T := PadStr('ab', 3.6, 'x');
        T := PadStr('ab', -1.5);
        T := PadStr('ab', 0.5);
        T := CopyStr('abcdef', 2.4, 3);
        T := CopyStr('abcdef', 2, 3.5);
        T := CopyStr('abcdef', 2.0, 3.0);
        T := DelStr('abcdef', 2.5);
        T := InsStr('abcdef', 'X', 2.5);
        T := SelectStr(2.5, 'a,b,c');
    end;
}
