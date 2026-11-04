// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on a whole array of Integer and of Text (elements after), Clear on a SecretText (IsEmpty before and after). Own file: compile-risky (array argument, SecretText argument).
// BC versions: 29 (27 and 28 by CI)

codeunit 71727 "LT SCL Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_WholeArrays()
    var
        Observer: Codeunit "Probe Observer";
        Ints: array[3] of Integer;
        Texts: array[3] of Text;
        Dates: array[2] of Date;
    begin
        Ints[1] := 11;
        Ints[2] := 22;
        Ints[3] := 33;
        Texts[1] := 'a';
        Texts[2] := 'b';
        Texts[3] := 'c';
        Dates[1] := DMY2Date(1, 2, 2020);
        Clear(Ints);
        Clear(Texts);
        Clear(Dates);
        Observer.Observe('int1', Format(Ints[1]));
        Observer.Observe('int2', Format(Ints[2]));
        Observer.Observe('int3', Format(Ints[3]));
        Observer.Observe('text1', '[' + Texts[1] + ']');
        Observer.Observe('text2', '[' + Texts[2] + ']');
        Observer.Observe('text3', '[' + Texts[3] + ']');
        Observer.Observe('date1', Format(Dates[1]));
        Observer.Observe('dim_int', Format(ArrayLen(Ints)));
        Observer.Expect('int1', '0');
        Observer.Expect('int2', '0');
        Observer.Expect('int3', '0');
        Observer.Expect('text1', '[]');
        Observer.Expect('text2', '[]');
        Observer.Expect('text3', '[]');
        Observer.Expect('date1', '');
        Observer.Expect('dim_int', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SingleArrayElementAndWhole()
    var
        Observer: Codeunit "Probe Observer";
        Ints: array[3] of Integer;
    begin
        Ints[1] := 11;
        Ints[2] := 22;
        Ints[3] := 33;
        Clear(Ints[2]);
        Observer.Observe('after_element', Format(Ints[1]) + ',' + Format(Ints[2]) + ',' + Format(Ints[3]));
        Clear(Ints);
        Observer.Observe('after_whole', Format(Ints[1]) + ',' + Format(Ints[2]) + ',' + Format(Ints[3]));
        Observer.Expect('after_element', '11,0,33');
        Observer.Expect('after_whole', '0,0,0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SecretText()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Other: SecretText;
    begin
        Observer.Observe('fresh_is_empty', Format(Secret.IsEmpty()));
        Secret := SecretStrSubstNo('abc');
        Other := Secret;
        Observer.Observe('filled_is_empty', Format(Secret.IsEmpty()));
        Clear(Secret);
        Observer.Observe('cleared_is_empty', Format(Secret.IsEmpty()));
        Observer.Observe('copy_is_empty', Format(Other.IsEmpty()));
        Clear(Other);
        Observer.Observe('copy_cleared_is_empty', Format(Other.IsEmpty()));
        Observer.Expect('fresh_is_empty', 'Yes');
        Observer.Expect('filled_is_empty', 'No');
        Observer.Expect('cleared_is_empty', 'Yes');
        Observer.Expect('copy_is_empty', 'No');
        Observer.Expect('copy_cleared_is_empty', 'Yes');
        Observer.Verify();
    end;
}
