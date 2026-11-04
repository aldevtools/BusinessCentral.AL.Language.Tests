// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 (P67Defs.al), self-contained test codeunit 70198
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 = and <> between enums of different types
// BC versions: 29 (27 and 28 by CI)

codeunit 70198 "LT P67 Enum Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SrcAndDst_Equal()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT P67 Src";
        D: Enum "LT P67 Dst";
        Ords: List of [Integer];
        i: Integer;
    begin
        Ords := Enum::"LT P67 Src".Ordinals();
        D := D::Uno;
        for i := 1 to Ords.Count() do begin
            S := Enum::"LT P67 Src".FromInteger(Ords.Get(i));
            Observer.Observe('s_eq_d_' + Format(Ords.Get(i)), Format(S = D));
            Observer.Observe('s_ne_d_' + Format(Ords.Get(i)), Format(S <> D));
        end;
        Observer.Expect('s_eq_d_0', 'No');
        Observer.Expect('s_ne_d_0', 'Yes');
        Observer.Expect('s_eq_d_1', 'Yes');
        Observer.Expect('s_ne_d_1', 'No');
        Observer.Expect('s_eq_d_3', 'No');
        Observer.Expect('s_ne_d_3', 'Yes');
        Observer.Expect('s_eq_d_7', 'No');
        Observer.Expect('s_ne_d_7', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DstAndSrc_Equal()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT P67 Src";
        D: Enum "LT P67 Dst";
        Ords: List of [Integer];
        i: Integer;
    begin
        Ords := Enum::"LT P67 Dst".Ordinals();
        S := S::Three;
        for i := 1 to Ords.Count() do begin
            D := Enum::"LT P67 Dst".FromInteger(Ords.Get(i));
            Observer.Observe('d_eq_s_' + Format(Ords.Get(i)), Format(D = S));
            Observer.Observe('d_ne_s_' + Format(Ords.Get(i)), Format(D <> S));
        end;
        Observer.Expect('d_eq_s_0', 'No');
        Observer.Expect('d_ne_s_0', 'Yes');
        Observer.Expect('d_eq_s_1', 'No');
        Observer.Expect('d_ne_s_1', 'Yes');
        Observer.Expect('d_eq_s_2', 'No');
        Observer.Expect('d_ne_s_2', 'Yes');
        Observer.Expect('d_eq_s_3', 'Yes');
        Observer.Expect('d_ne_s_3', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SrcAndDst_Literals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('one_uno', Format(Enum::"LT P67 Src"::One = Enum::"LT P67 Dst"::Uno));
        Observer.Observe('three_tres', Format(Enum::"LT P67 Src"::Three = Enum::"LT P67 Dst"::Tres));
        Observer.Observe('seven_none', Format(Enum::"LT P67 Src"::Seven = Enum::"LT P67 Dst"::None));
        Observer.Observe('none_none', Format(Enum::"LT P67 Src"::None = Enum::"LT P67 Dst"::None));
        Observer.Observe('one_dos', Format(Enum::"LT P67 Src"::One <> Enum::"LT P67 Dst"::Dos));
        Observer.Expect('one_uno', 'Yes');
        Observer.Expect('three_tres', 'Yes');
        Observer.Expect('seven_none', 'No');
        Observer.Expect('none_none', 'Yes');
        Observer.Expect('one_dos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFieldVsOtherEnum()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Row.Kind := Row.Kind::Uno;
        S := S::One;
        Observer.Observe('field_eq_one', Format(Row.Kind = S));
        S := S::Three;
        Observer.Observe('field_eq_three', Format(Row.Kind = S));
        Observer.Observe('field_ne_three', Format(Row.Kind <> S));
        Observer.Expect('field_eq_one', 'Yes');
        Observer.Expect('field_eq_three', 'No');
        Observer.Expect('field_ne_three', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EnumVsOptionAndInteger()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        Opt: Option A,B,C,D,E;
    begin
        D := D::Dos;
        Opt := Opt::C;
        Observer.Observe('eq_opt', Format(D = Opt));
        Observer.Observe('ne_opt', Format(D <> Opt));
        Opt := Opt::B;
        Observer.Observe('eq_opt_b', Format(D = Opt));
        Observer.Observe('eq_int2', Format(D = 2));
        Observer.Observe('eq_int1', Format(D = 1));
        Observer.Expect('eq_opt', 'Yes');
        Observer.Expect('ne_opt', 'No');
        Observer.Expect('eq_opt_b', 'No');
        Observer.Expect('eq_int2', 'Yes');
        Observer.Expect('eq_int1', 'No');
        Observer.Verify();
    end;
}
