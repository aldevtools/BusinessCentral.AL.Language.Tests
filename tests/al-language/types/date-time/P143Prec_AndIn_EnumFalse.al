// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators-and-expressions
// Scope: in-scope
// Fixtures used: enum 74649 "LT P143 Color" (own file Enum.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// If this file does not compile the expression is a must-not-compile candidate. BC versions: 29

codeunit 74741 "LT P143 Prec 74741"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P143_AndIn_EnumFalse()
    var
        Observer: Codeunit "Probe Observer";
        a: Boolean;
        b: Boolean;
        i: Integer;
        j: Integer;
        k: Integer;
        e: Enum "LT P143 Color";
        t: Text;
        u: Text;
        v: Text;
    begin
        a := true;
        b := false;
        i := 1;
        j := 2;
        k := 3;
        e := e::Green;
        t := 'a';
        u := 'b';
        v := 'ab';
        Observer.Observe('lit', Format(false and "LT P143 Color"::Green in ["LT P143 Color"::Green]));
        Observer.Observe('var', Format(b and e in ["LT P143 Color"::Green]));
        Observer.Expect('lit', 'No');
        Observer.Expect('var', 'No');
        Observer.Verify();
    end;
}
