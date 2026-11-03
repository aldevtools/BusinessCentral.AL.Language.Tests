// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 71038-71041, self-contained test codeunit 71042
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Enum Ordinals/Names, Format with format numbers, captions, extension values, default value, blank names
// BC versions: 29 (27 and 28 by CI)

enum 71038 "LT OjT Color"
{
    Extensible = true;

    value(0; Red) { }
    value(1; Green) { Caption = 'Green Caption'; }
    value(5; "Dark Blue") { Caption = 'Navy'; }
}

enumextension 71039 "LT OjT Color Ext" extends "LT OjT Color"
{
    value(10; Yellow) { Caption = 'Sunny'; }
}

enum 71040 "LT OjT NoZero"
{
    Extensible = false;

    value(1; One) { }
    value(2; Two) { }
}

enum 71041 "LT OjT BlankName"
{
    Extensible = false;

    value(0; " ") { }
    value(3; Three) { }
}

codeunit 71042 "LT OjT Enum Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OrdinalsAndNames_Color()
    var
        Observer: Codeunit "Probe Observer";
        Ords: List of [Integer];
        Nms: List of [Text];
        i: Integer;
    begin
        Ords := Enum::"LT OjT Color".Ordinals();
        Nms := Enum::"LT OjT Color".Names();
        Observer.Observe('ordCount', Format(Ords.Count()));
        Observer.Observe('nameCount', Format(Nms.Count()));
        for i := 1 to Ords.Count() do begin
            Observer.Observe('ord' + Format(i), Format(Ords.Get(i)));
        end;
        for i := 1 to Nms.Count() do begin
            Observer.Observe('name' + Format(i), Nms.Get(i));
        end;
        Observer.Observe('ordHas5', Format(Ords.Contains(5)));
        Observer.Observe('ordHas2', Format(Ords.Contains(2)));
        Observer.Observe('ordHas10', Format(Ords.Contains(10)));
        Observer.Observe('nameHasDarkBlue', Format(Nms.Contains('Dark Blue')));
        Observer.Observe('nameHasNavy', Format(Nms.Contains('Navy')));
        Observer.Observe('nameHasYellow', Format(Nms.Contains('Yellow')));
        Observer.Observe('nameHasLower', Format(Nms.Contains('red')));
        Observer.Observe('idxRed', Format(Nms.IndexOf('Red')));
        Observer.Observe('idxYellow', Format(Nms.IndexOf('Yellow')));
        Observer.Expect('ordCount', '4');
        Observer.Expect('nameCount', '4');
        Observer.Expect('ord1', '0');
        Observer.Expect('ord2', '1');
        Observer.Expect('ord3', '5');
        Observer.Expect('ord4', '10');
        Observer.Expect('name1', 'Red');
        Observer.Expect('name2', 'Green');
        Observer.Expect('name3', 'Dark Blue');
        Observer.Expect('name4', 'Yellow');
        Observer.Expect('ordHas5', 'Yes');
        Observer.Expect('ordHas2', 'No');
        Observer.Expect('ordHas10', 'Yes');
        Observer.Expect('nameHasDarkBlue', 'Yes');
        Observer.Expect('nameHasNavy', 'No');
        Observer.Expect('nameHasYellow', 'Yes');
        Observer.Expect('nameHasLower', 'No');
        Observer.Expect('idxRed', '1');
        Observer.Expect('idxYellow', '4');
        Observer.Verify();
    end;

    [Test]
    procedure OrdinalsAndNames_NoZeroAndBlank()
    var
        Observer: Codeunit "Probe Observer";
        Ords: List of [Integer];
        Nms: List of [Text];
        i: Integer;
    begin
        Ords := Enum::"LT OjT NoZero".Ordinals();
        Nms := Enum::"LT OjT NoZero".Names();
        Observer.Observe('nz.ordCount', Format(Ords.Count()));
        for i := 1 to Ords.Count() do begin
            Observer.Observe('nz.ord' + Format(i), Format(Ords.Get(i)));
            Observer.Observe('nz.name' + Format(i), Nms.Get(i));
        end;
        Ords := Enum::"LT OjT BlankName".Ordinals();
        Nms := Enum::"LT OjT BlankName".Names();
        Observer.Observe('bl.ordCount', Format(Ords.Count()));
        for i := 1 to Ords.Count() do begin
            Observer.Observe('bl.ord' + Format(i), Format(Ords.Get(i)));
            Observer.Observe('bl.name' + Format(i), '[' + Nms.Get(i) + ']');
        end;
        Observer.Expect('nz.ordCount', '2');
        Observer.Expect('nz.ord1', '1');
        Observer.Expect('nz.name1', 'One');
        Observer.Expect('nz.ord2', '2');
        Observer.Expect('nz.name2', 'Two');
        Observer.Expect('bl.ordCount', '2');
        Observer.Expect('bl.ord1', '0');
        Observer.Expect('bl.name1', '[ ]');
        Observer.Expect('bl.ord2', '3');
        Observer.Expect('bl.name2', '[Three]');
        Observer.Verify();
    end;

    [Test]
    procedure Format_AllValues()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        Ords: List of [Integer];
        i: Integer;
        Prefix: Text;
    begin
        Ords := Enum::"LT OjT Color".Ordinals();
        for i := 1 to Ords.Count() do begin
            C := Enum::"LT OjT Color".FromInteger(Ords.Get(i));
            Prefix := 'o' + Format(Ords.Get(i));
            Observer.Observe(Prefix + '.default', Format(C));
            Observer.Observe(Prefix + '.n0', Format(C, 0, 0));
            Observer.Observe(Prefix + '.n1', Format(C, 0, 1));
            Observer.Observe(Prefix + '.n2', Format(C, 0, 2));
            Observer.Observe(Prefix + '.n9', Format(C, 0, 9));
        end;
        Observer.Expect('o0.default', 'Red');
        Observer.Expect('o0.n0', 'Red');
        Observer.Expect('o0.n1', 'Red');
        Observer.Expect('o0.n2', '0');
        Observer.Expect('o0.n9', '0');
        Observer.Expect('o1.default', 'Green Caption');
        Observer.Expect('o1.n0', 'Green Caption');
        Observer.Expect('o1.n1', 'Green Caption');
        Observer.Expect('o1.n2', '1');
        Observer.Expect('o1.n9', '1');
        Observer.Expect('o5.default', 'Navy');
        Observer.Expect('o5.n0', 'Navy');
        Observer.Expect('o5.n1', 'Navy');
        Observer.Expect('o5.n2', '5');
        Observer.Expect('o5.n9', '5');
        Observer.Expect('o10.default', 'Sunny');
        Observer.Expect('o10.n0', 'Sunny');
        Observer.Expect('o10.n1', 'Sunny');
        Observer.Expect('o10.n2', '10');
        Observer.Expect('o10.n9', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Format_InvalidFormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        T: Text;
        i: Integer;
    begin
        C := Enum::"LT OjT Color"::Green;
        for i := 3 to 8 do begin
            asserterror T := Format(C, 0, i);
            Observer.ObserveError('n' + Format(i));
        end;
        Observer.Expect('n3|text', 'Standard format number 3 does not exist for the type ''Option''.');
        Observer.Expect('n3|code', 'InvalidStandardFormat');
        Observer.Expect('n4|text', 'Standard format number 4 does not exist for the type ''Option''.');
        Observer.Expect('n4|code', 'InvalidStandardFormat');
        Observer.Expect('n5|text', 'Standard format number 5 does not exist for the type ''Option''.');
        Observer.Expect('n5|code', 'InvalidStandardFormat');
        Observer.Expect('n6|text', 'Standard format number 6 does not exist for the type ''Option''.');
        Observer.Expect('n6|code', 'InvalidStandardFormat');
        Observer.Expect('n7|text', 'Standard format number 7 does not exist for the type ''Option''.');
        Observer.Expect('n7|code', 'InvalidStandardFormat');
        Observer.Expect('n8|text', 'Standard format number 8 does not exist for the type ''Option''.');
        Observer.Expect('n8|code', 'InvalidStandardFormat');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Length()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
    begin
        C := Enum::"LT OjT Color"::"Dark Blue";
        Observer.Observe('len10', '[' + Format(C, 10, 0) + ']');
        Observer.Observe('len-10', '[' + Format(C, -10, 0) + ']');
        Observer.Observe('len2', '[' + Format(C, 2, 0) + ']');
        Observer.Observe('len10n2', '[' + Format(C, 10, 2) + ']');
        Observer.Observe('len1n2', '[' + Format(C, 1, 2) + ']');
        Observer.Observe('len10n1', '[' + Format(C, 10, 1) + ']');
        Observer.Observe('len3n1', '[' + Format(C, 3, 1) + ']');
        Observer.Expect('len10', '[Navy      ]');
        Observer.Expect('len-10', '[Navy]');
        Observer.Expect('len2', '[Na]');
        Observer.Expect('len10n2', '[5         ]');
        Observer.Expect('len1n2', '[5]');
        Observer.Expect('len10n1', '[Navy      ]');
        Observer.Expect('len3n1', '[Nav]');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultValues()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        N: Enum "LT OjT NoZero";
        B: Enum "LT OjT BlankName";
    begin
        Observer.Observe('color.default', Format(C));
        Observer.Observe('color.ord', Format(C, 0, 2));
        Observer.Observe('nozero.default', '[' + Format(N) + ']');
        Observer.Observe('nozero.ord', Format(N, 0, 2));
        Observer.Observe('blank.default', '[' + Format(B) + ']');
        Observer.Observe('blank.ord', Format(B, 0, 2));
        C := Enum::"LT OjT Color"::Yellow;
        Clear(C);
        Observer.Observe('color.cleared', Format(C));
        N := Enum::"LT OjT NoZero"::Two;
        Clear(N);
        Observer.Observe('nozero.cleared', Format(N, 0, 2));
        Observer.Observe('nozero.eqOne', Format(N = Enum::"LT OjT NoZero"::One));
        Observer.Expect('color.default', 'Red');
        Observer.Expect('color.ord', '0');
        Observer.Expect('nozero.default', '[0]');
        Observer.Expect('nozero.ord', '0');
        Observer.Expect('blank.default', '[ ]');
        Observer.Expect('blank.ord', '0');
        Observer.Expect('color.cleared', 'Red');
        Observer.Expect('nozero.cleared', '0');
        Observer.Expect('nozero.eqOne', 'No');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 7477): enum methods written without parentheses: Names and Ordinals as the list
    // of a foreach, AsInteger on a value, and an enum value's AsInteger used as an array index.
    [Test]
    procedure BP_EnumMethods_WithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
        Color: Enum "LT OjT Color";
        Arr: array[20] of Text;
        N: Text;
        I: Integer;
        T: Text;
    begin
        foreach N in Enum::"LT OjT Color".Names do
            T += N + ',';
        Observer.Observe('names', T);
        T := '';
        foreach I in Enum::"LT OjT Color".Ordinals do
            T += Format(I) + ',';
        Observer.Observe('ordinals', T);
        Observer.Observe('static AsInteger', Format(Enum::"LT OjT Color"::"Dark Blue".AsInteger));
        Color := Color::Yellow;
        I := Color.AsInteger;
        Observer.Observe('variable AsInteger', Format(I));
        Arr[Enum::"LT OjT Color"::"Dark Blue".AsInteger] := 'five';
        Observer.Observe('array index', Arr[5]);
        Observer.Expect('names', 'Red,Green,Dark Blue,Yellow,');
        Observer.Expect('ordinals', '0,1,5,10,');
        Observer.Expect('static AsInteger', '5');
        Observer.Expect('variable AsInteger', '10');
        Observer.Expect('array index', 'five');
        Observer.Verify();
    end;
}
