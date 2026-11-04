// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums of OjT71038.al, self-contained test codeunit 71046
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Enum in List, Dictionary and Variant
// BC versions: 29 (27 and 28 by CI)

codeunit 71046 "LT OjT Enum Collections"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure List_OfEnum()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Enum "LT OjT Color"];
        C: Enum "LT OjT Color";
        i: Integer;
    begin
        L.Add(Enum::"LT OjT Color"::Green);
        L.Add(Enum::"LT OjT Color"::Red);
        L.Add(Enum::"LT OjT Color"::Green);
        L.Add(Enum::"LT OjT Color"::Yellow);
        Observer.Observe('count', Format(L.Count()));
        for i := 1 to L.Count() do begin
            Observer.Observe('item' + Format(i), Format(L.Get(i), 0, 2));
        end;
        Observer.Observe('containsRed', Format(L.Contains(Enum::"LT OjT Color"::Red)));
        Observer.Observe('containsBlue', Format(L.Contains(Enum::"LT OjT Color"::"Dark Blue")));
        Observer.Observe('indexGreen', Format(L.IndexOf(Enum::"LT OjT Color"::Green)));
        Observer.Observe('lastIndexGreen', Format(L.LastIndexOf(Enum::"LT OjT Color"::Green)));
        Observer.Observe('indexBlue', Format(L.IndexOf(Enum::"LT OjT Color"::"Dark Blue")));
        L.Remove(Enum::"LT OjT Color"::Green);
        Observer.Observe('afterRemove', Format(L.Count()));
        L.Reverse();
        Observer.Observe('reversedFirst', Format(L.Get(1)));
        foreach C in L do begin
            Observer.Observe('each' + Format(C, 0, 2), Format(C));
        end;
        Observer.Expect('count', '4');
        Observer.Expect('item1', '1');
        Observer.Expect('item2', '0');
        Observer.Expect('item3', '1');
        Observer.Expect('item4', '10');
        Observer.Expect('containsRed', 'Yes');
        Observer.Expect('containsBlue', 'No');
        Observer.Expect('indexGreen', '1');
        Observer.Expect('lastIndexGreen', '3');
        Observer.Expect('indexBlue', '0');
        Observer.Expect('afterRemove', '3');
        Observer.Expect('reversedFirst', 'Sunny');
        Observer.Expect('each10', 'Sunny');
        Observer.Expect('each1', 'Green Caption');
        Observer.Expect('each0', 'Red');
        Observer.Verify();
    end;

    [Test]
    procedure List_OfEnum_Errors()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Enum "LT OjT Color"];
        C: Enum "LT OjT Color";
    begin
        L.Add(Enum::"LT OjT Color"::Red);
        asserterror C := L.Get(2);
        Observer.ObserveError('getOut');
        asserterror C := L.Get(0);
        Observer.ObserveError('getZero');
        Observer.Expect('getOut|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getOut|code', 'ArgumentOutOfRange');
        Observer.Expect('getZero|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getZero|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_EnumKey()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Enum "LT OjT Color", Text];
        C: Enum "LT OjT Color";
        T: Text;
    begin
        D.Add(Enum::"LT OjT Color"::Red, 'r');
        D.Add(Enum::"LT OjT Color"::"Dark Blue", 'b');
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('hasRed', Format(D.ContainsKey(Enum::"LT OjT Color"::Red)));
        Observer.Observe('hasGreen', Format(D.ContainsKey(Enum::"LT OjT Color"::Green)));
        Observer.Observe('getBlue', D.Get(Enum::"LT OjT Color"::"Dark Blue"));
        Observer.Observe('tryGet', Format(D.Get(Enum::"LT OjT Color"::Red, T)) + '|' + T);
        Observer.Observe('tryGetMissing', Format(D.Get(Enum::"LT OjT Color"::Yellow, T)));
        D.Set(Enum::"LT OjT Color"::Red, 'r2');
        Observer.Observe('set', D.Get(Enum::"LT OjT Color"::Red));
        D.Set(Enum::"LT OjT Color"::Yellow, 'y');
        Observer.Observe('setNew', Format(D.Count()));
        foreach C in D.Keys() do begin
            Observer.Observe('key' + Format(C, 0, 2), D.Get(C));
        end;
        Observer.Observe('remove', Format(D.Remove(Enum::"LT OjT Color"::Red)));
        Observer.Observe('removeAgain', Format(D.Remove(Enum::"LT OjT Color"::Red)));
        Observer.Expect('count', '2');
        Observer.Expect('hasRed', 'Yes');
        Observer.Expect('hasGreen', 'No');
        Observer.Expect('getBlue', 'b');
        Observer.Expect('tryGet', 'Yes|r');
        Observer.Expect('tryGetMissing', 'No');
        Observer.Expect('set', 'r2');
        Observer.Expect('setNew', '3');
        Observer.Expect('key0', 'r2');
        Observer.Expect('key5', 'b');
        Observer.Expect('key10', 'y');
        Observer.Expect('remove', 'Yes');
        Observer.Expect('removeAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_EnumKey_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Enum "LT OjT Color", Text];
        T: Text;
    begin
        D.Add(Enum::"LT OjT Color"::Red, 'r');
        asserterror D.Add(Enum::"LT OjT Color"::Red, 'again');
        Observer.ObserveError('addDuplicate');
        asserterror T := D.Get(Enum::"LT OjT Color"::Green);
        Observer.ObserveError('getMissing');
        Observer.Expect('addDuplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('addDuplicate|code', 'Argument');
        Observer.Expect('getMissing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('getMissing|code', 'KeyNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_EnumValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Enum "LT OjT Color"];
    begin
        D.Add('a', Enum::"LT OjT Color"::Green);
        D.Add('b', Enum::"LT OjT Color"::"Dark Blue");
        Observer.Observe('a', Format(D.Get('a')));
        Observer.Observe('b', Format(D.Get('b'), 0, 2));
        Observer.Observe('values', Format(D.Values().Count()));
        Observer.Expect('a', 'Green Caption');
        Observer.Expect('b', '5');
        Observer.Expect('values', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_HoldingEnum()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        C: Enum "LT OjT Color";
    begin
        C := Enum::"LT OjT Color"::"Dark Blue";
        V := C;
        Observer.Observe('format', Format(V));
        Observer.Observe('format2', Format(V, 0, 2));
        Observer.Observe('isOption', Format(V.IsOption()));
        Observer.Observe('isInteger', Format(V.IsInteger()));
        Observer.Observe('isText', Format(V.IsText()));
        Observer.Observe('isCode', Format(V.IsCode()));
        Observer.Observe('isDecimal', Format(V.IsDecimal()));
        V := Enum::"LT OjT Color"::Yellow;
        Observer.Observe('literal', Format(V));
        Observer.Expect('format', 'Navy');
        Observer.Expect('format2', '5');
        Observer.Expect('isOption', 'Yes');
        Observer.Expect('isInteger', 'No');
        Observer.Expect('isText', 'No');
        Observer.Expect('isCode', 'No');
        Observer.Expect('isDecimal', 'No');
        Observer.Expect('literal', 'Sunny');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_EqualityOfEnums()
    var
        Observer: Codeunit "Probe Observer";
        V1: Variant;
        V2: Variant;
    begin
        V1 := Enum::"LT OjT Color"::Green;
        V2 := Enum::"LT OjT Color"::Green;
        Observer.Observe('same', Format(Format(V1) = Format(V2)));
        V2 := Enum::"LT OjT Color"::Red;
        Observer.Observe('different', Format(Format(V1) = Format(V2)));
        Observer.Expect('same', 'Yes');
        Observer.Expect('different', 'No');
        Observer.Verify();
    end;
}
