// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), test codeunit 72693 (P85); a fixed Guid literal is used, no CreateGuid
// Probe: written against BC 29 (P85); the facts are measured later on a local BC 29 service tier.
// Facts: Guid assigned to Text[40], Text, Code[40], Dictionary of [Text, Text], List of [Text], Evaluate(T, G) forms
// BC versions: 29

codeunit 72693 "LT P85 Guid To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvalText(G: Guid; var T: Text)
    var
        Ok: Boolean;
    begin
        Ok := Evaluate(T, G);
    end;

    local procedure Fixed(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        exit(G);
    end;

    [Test]
    procedure Guid_To_Text40_Text_Code40()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
        TAny: Text;
        C40: Code[40];
        T50: Text[50];
        C50: Code[50];
    begin
        G := Fixed();
        T40 := G;
        TAny := G;
        C40 := G;
        T50 := G;
        C50 := G;
        Observer.Observe('t40', T40);
        Observer.Observe('t40_len', Format(StrLen(T40)));
        Observer.Observe('text', TAny);
        Observer.Observe('text_len', Format(StrLen(TAny)));
        Observer.Observe('c40', C40);
        Observer.Observe('c40_len', Format(StrLen(C40)));
        Observer.Observe('t50', T50);
        Observer.Observe('c50', C50);
        Observer.Observe('t40_eq_format', Format(T40 = Format(G)));
        Observer.Observe('text_eq_format', Format(TAny = Format(G)));
        Observer.Observe('c40_eq_format', Format(C40 = Format(G)));
        Observer.Observe('c40_eq_upper_format', Format(C40 = UpperCase(Format(G))));
        Observer.Observe('t40_eq_lower_format', Format(T40 = LowerCase(Format(G))));
        Observer.Expect('t40', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('t40_len', '38');
        Observer.Expect('text', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('text_len', '38');
        Observer.Expect('c40', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('c40_len', '38');
        Observer.Expect('t50', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('c50', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('t40_eq_format', 'Yes');
        Observer.Expect('text_eq_format', 'Yes');
        Observer.Expect('c40_eq_format', 'Yes');
        Observer.Expect('c40_eq_upper_format', 'Yes');
        Observer.Expect('t40_eq_lower_format', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Null_To_Text()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
        TAny: Text;
        C40: Code[40];
    begin
        T40 := G;
        TAny := G;
        C40 := G;
        Observer.Observe('t40', T40);
        Observer.Observe('text', TAny);
        Observer.Observe('c40', C40);
        Observer.Observe('t40_len', Format(StrLen(T40)));
        Observer.Observe('c40_len', Format(StrLen(C40)));
        Observer.Expect('t40', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('text', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('c40', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('t40_len', '38');
        Observer.Expect('c40_len', '38');
        Observer.Verify();
    end;

    [Test]
    procedure Text_To_Guid_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
        T40: Text[40];
        C40: Code[40];
    begin
        G := Fixed();
        T40 := G;
        G2 := T40;
        Observer.Observe('t40_roundtrip_equal', Format(G = G2));
        C40 := G;
        G2 := C40;
        Observer.Observe('c40_roundtrip_equal', Format(G = G2));
        T40 := '{ab12cd34-ef56-4a78-9b01-23456789abcd}';
        G2 := T40;
        Observer.Observe('lowercase_equal', Format(G = G2));
        T40 := 'AB12CD34-EF56-4A78-9B01-23456789ABCD';
        G2 := T40;
        Observer.Observe('nobraces_equal', Format(G = G2));
        T40 := 'AB12CD34EF564A789B0123456789ABCD';
        G2 := T40;
        Observer.Observe('nodashes_equal', Format(G = G2));
        Observer.Expect('t40_roundtrip_equal', 'Yes');
        Observer.Expect('c40_roundtrip_equal', 'Yes');
        Observer.Expect('lowercase_equal', 'Yes');
        Observer.Expect('nobraces_equal', 'Yes');
        Observer.Expect('nodashes_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_To_Text_BadText_Errors()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T40: Text[40];
    begin
        T40 := 'not a guid';
        asserterror G := T40;
        Observer.ObserveError('bad_text');
        T40 := '';
        asserterror G := T40;
        Observer.ObserveError('af121');
        Observer.Observe('empty_text_is_null', Format(IsNullGuid(G)));
        T40 := '{AB12CD34-EF56-4A78-9B01-23456789ABC}';
        asserterror G := T40;
        Observer.ObserveError('short');
        Observer.Expect('bad_text|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('bad_text|code', 'InvalidGuidFormat');
        Observer.Expect('af121|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('af121|code', 'InvalidGuidFormat');
        Observer.Expect('empty_text_is_null', 'Yes');
        Observer.Expect('short|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('short|code', 'InvalidGuidFormat');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_Text_Text_Add_Guid()
    var
        Observer: Codeunit "Probe Observer";
        Dict: Dictionary of [Text, Text];
        G: Guid;
        T: Text;
    begin
        G := Fixed();
        Dict.Add('k', G);
        Observer.Observe('count', Format(Dict.Count()));
        Observer.Observe('value', Dict.Get('k'));
        Observer.Observe('len', Format(StrLen(Dict.Get('k'))));
        Observer.Observe('contains', Format(Dict.ContainsKey('k')));
        Dict.Set('k', G);
        Observer.Observe('set_value', Dict.Get('k'));
        Dict.Add('null', CreateNullGuid());
        Observer.Observe('null_value', Dict.Get('null'));
        Dict.Get('k', T);
        Observer.Observe('get_out', T);
        Observer.Expect('count', '1');
        Observer.Expect('value', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('len', '38');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('set_value', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('null_value', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('get_out', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Verify();
    end;

    local procedure CreateNullGuid(): Guid
    var
        G: Guid;
    begin
        exit(G);
    end;

    [Test]
    procedure List_Of_Text_Add_Guid_And_Dict_Of_Guid()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        DG: Dictionary of [Text, Guid];
        LG: List of [Guid];
        G: Guid;
    begin
        G := Fixed();
        L.Add(G);
        Observer.Observe('list_text', L.Get(1));
        Observer.Observe('list_contains_format', Format(L.Contains(Format(G))));
        DG.Add('k', G);
        Observer.Observe('dict_guid_value', Format(DG.Get('k')));
        LG.Add(G);
        Observer.Observe('list_guid', Format(LG.Get(1)));
        Observer.Observe('list_guid_contains', Format(LG.Contains(G)));
        Observer.Expect('list_text', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('list_contains_format', 'Yes');
        Observer.Expect('dict_guid_value', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('list_guid', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('list_guid_contains', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Text_From_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
        T40: Text[40];
        C40: Code[40];
        Ok: Boolean;
    begin
        G := Fixed();
        Ok := Evaluate(T, G);
        Observer.Observe('text_ok', Format(Ok) + '|' + T);
        Ok := Evaluate(T40, G);
        Observer.Observe('t40_ok', Format(Ok) + '|' + T40);
        Ok := Evaluate(C40, G);
        Observer.Observe('c40_ok', Format(Ok) + '|' + C40);
        Ok := Evaluate(T, Format(G));
        Observer.Observe('text_format_ok', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 1));
        Observer.Observe('text_format1', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 2));
        Observer.Observe('text_format2', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 3));
        Observer.Observe('text_format3', Format(Ok) + '|' + T);
        Ok := Evaluate(T, Format(G, 0, 4));
        Observer.Observe('text_format4', Format(Ok) + '|' + T);
        Observer.Expect('text_ok', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('t40_ok', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('c40_ok', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('text_format_ok', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('text_format1', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('text_format2', 'Yes|{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Expect('text_format3', 'Yes|AB12CD34EF564A789B0123456789ABCD');
        Observer.Expect('text_format4', 'Yes|AB12CD34-EF56-4A78-9B01-23456789ABCD');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Guid_From_Text_Forms()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        Ref: Guid;
        Ok: Boolean;
    begin
        Ref := Fixed();
        Ok := Evaluate(G, Format(Ref));
        Observer.Observe('braced', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, Format(Ref, 0, 4));
        Observer.Observe('format4', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, Format(Ref, 0, 2));
        Observer.Observe('format2', Format(Ok) + '|' + Format(G = Ref));
        Clear(G);
        Ok := Evaluate(G, 'garbage');
        Observer.Observe('garbage', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Ok := Evaluate(G, '');
        Observer.Observe('empty', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Ok := Evaluate(G, Ref);
        Observer.Observe('guid_arg', Format(Ok) + '|' + Format(G = Ref));
        Ok := Evaluate(G, '{00000000-0000-0000-0000-000000000000}');
        Observer.Observe('null_text', Format(Ok) + '|' + Format(IsNullGuid(G)));
        Observer.Expect('braced', 'Yes|Yes');
        Observer.Expect('format4', 'Yes|Yes');
        Observer.Expect('format2', 'Yes|Yes');
        Observer.Expect('garbage', 'No|Yes');
        Observer.Expect('empty', 'No|Yes');
        Observer.Expect('guid_arg', 'Yes|Yes');
        Observer.Expect('null_text', 'Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Text_From_Guid_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
    begin
        G := Fixed();
        if TryEvalText(G, T) then
            Observer.Observe('try_ok', T)
        else
            Observer.Observe('try_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('try_ok', '{AB12CD34-EF56-4A78-9B01-23456789ABCD}');
        Observer.Verify();
    end;
}
