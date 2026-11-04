// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 and helper codeunit 70199 (P67Defs.al), self-contained test codeunit 70197
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Enum of another type as argument, return value, var, Variant
// BC versions: 29 (27 and 28 by CI)

codeunit 70197 "LT P67 Enum Args"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ByValueArgument()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P67 Helper";
        S: Enum "LT P67 Src";
        Ords: List of [Integer];
        i: Integer;
    begin
        Ords := Enum::"LT P67 Src".Ordinals();
        for i := 1 to Ords.Count() do begin
            S := Enum::"LT P67 Src".FromInteger(Ords.Get(i));
            Observer.Observe('arg' + Format(Ords.Get(i)), H.TakeDst(S));
        end;
        Observer.Expect('arg0', 'None|0');
        Observer.Expect('arg1', 'Uno|1');
        Observer.Expect('arg3', 'Tres Cap|3');
        Observer.Expect('arg7', '7|7');
        Observer.Verify();
    end;

    [Test]
    procedure ReturnWithExit()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P67 Helper";
        S: Enum "LT P67 Src";
        D: Enum "LT P67 Dst";
        Ords: List of [Integer];
        i: Integer;
    begin
        Ords := Enum::"LT P67 Src".Ordinals();
        for i := 1 to Ords.Count() do begin
            S := Enum::"LT P67 Src".FromInteger(Ords.Get(i));
            D := H.SrcToDst(S);
            Observer.Observe('ret' + Format(Ords.Get(i)), '[' + Format(D) + ']|' + Format(D.AsInteger()));
            Observer.Observe('loc' + Format(Ords.Get(i)), H.SrcToDstVarLocal(S));
        end;
        Observer.Expect('ret0', '[None]|0');
        Observer.Expect('loc0', 'None|0');
        Observer.Expect('ret1', '[Uno]|1');
        Observer.Expect('loc1', 'Uno|1');
        Observer.Expect('ret3', '[Tres Cap]|3');
        Observer.Expect('loc3', 'Tres Cap|3');
        Observer.Expect('ret7', '[7]|7');
        Observer.Expect('loc7', '7|7');
        Observer.Verify();
    end;

    [Test]
    procedure ReturnValueDirectUse()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P67 Helper";
        S: Enum "LT P67 Src";
    begin
        S := S::Three;
        Observer.Observe('format', Format(H.SrcToDst(S)));
        Observer.Observe('eq_tres', Format(H.SrcToDst(S) = Enum::"LT P67 Dst"::Tres));
        S := S::Seven;
        Observer.Observe('format_seven', Format(H.SrcToDst(S)));
        Observer.Observe('eq_none', Format(H.SrcToDst(S) = Enum::"LT P67 Dst"::None));
        Observer.Expect('format', 'Tres Cap');
        Observer.Expect('eq_tres', 'Yes');
        Observer.Expect('format_seven', '7');
        Observer.Expect('eq_none', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure VarAndOutArguments()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P67 Helper";
        D: Enum "LT P67 Dst";
        S: Enum "LT P67 Src";
    begin
        Observer.Observe('default', Format(D));
        H.BumpDst(D);
        Observer.Observe('bumped', Format(D));
        S := S::Seven;
        H.OutDst(D, S);
        Observer.Observe('out_seven', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        S := S::One;
        H.OutDst(D, S);
        Observer.Observe('out_one', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        Observer.Expect('default', 'None');
        Observer.Expect('bumped', 'Dos');
        Observer.Expect('out_seven', '[7]|7');
        Observer.Expect('out_one', '[Uno]|1');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerArgumentAndReturn()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P67 Helper";
        D: Enum "LT P67 Dst";
        i: Integer;
    begin
        for i := 0 to 3 do begin
            D := H.TakeInt(i);
            Observer.Observe('int' + Format(i), Format(D));
        end;
        D := H.TakeInt(7);
        Observer.Observe('int7', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        D := H.TakeInt(-1);
        Observer.Observe('int_minus1', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        Observer.Expect('int0', 'None');
        Observer.Expect('int1', 'Uno');
        Observer.Expect('int2', 'Dos');
        Observer.Expect('int3', 'Tres Cap');
        Observer.Expect('int7', '[7]|7');
        Observer.Expect('int_minus1', '[-1]|-1');
        Observer.Verify();
    end;
}
