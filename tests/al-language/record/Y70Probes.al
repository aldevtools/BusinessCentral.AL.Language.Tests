// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-programming-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables in Y70Tables.al
// Probe (writer Y70): runtime assumptions that had no corpus pin, measured on BC SaaS 29 (Dev sandbox). One test per element. Object ids 93740-93747.

codeunit 93740 "LT Y70 Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryFormat(V: Variant; Picture: Text; var Result: Text)
    begin
        Result := Format(V, 0, Picture);
    end;

    local procedure Fmt(V: Variant; Picture: Text): Text
    var
        R: Text;
    begin
        if TryFormat(V, Picture, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode());
    end;

    // ---- Format code names: `Filler Char` against `Filler Character`
    [Test]
    procedure FormatCode_FillerChar()
    begin
        Obs.Observe('int_character', Fmt(5, '<Integer,4><Filler Character,0>'));
        Obs.Observe('int_char', Fmt(5, '<Integer,4><Filler Char,0>'));
        Obs.Observe('int_char_lower', Fmt(5, '<Integer,4><Filler char,0>'));
        Obs.Observe('int_char_blank', Fmt(5, '<Integer,4><Filler Char, 0>'));
        Obs.Observe('dec_character', Fmt(5.5, '<Integer,4><Filler Character,0><Decimals,3>'));
        Obs.Observe('dec_char', Fmt(5.5, '<Integer,4><Filler Char,0><Decimals,3>'));
        Obs.Observe('text_character', Fmt('ab', '<Text,6><Filler Character,.>'));
        Obs.Observe('text_char', Fmt('ab', '<Text,6><Filler Char,.>'));
        Obs.Observe('code_char', Fmt('ab', '<Text,6><Filler Char,#>'));
                Obs.Expect('int_character', '0005');
        Obs.Expect('int_char', '0005');
        Obs.Expect('int_char_lower', '0005');
        Obs.Expect('int_char_blank', 'ERR:InvalidFormatString');
        Obs.Expect('dec_character', '0005.50');
        Obs.Expect('dec_char', '0005.50');
        Obs.Expect('text_character', 'ab....');
        Obs.Expect('text_char', 'ab....');
        Obs.Expect('code_char', 'ab####');
        Obs.Verify();
    end;

    [Test]
    procedure FormatCode_FillerCharPrefixes()
    begin
        Obs.Observe('int_filler', Fmt(5, '<Integer,4><Filler,0>'));
        Obs.Observe('int_filler_c', Fmt(5, '<Integer,4><Filler C,0>'));
        Obs.Observe('int_filler_cha', Fmt(5, '<Integer,4><Filler Cha,0>'));
        Obs.Observe('int_filler_charx', Fmt(5, '<Integer,4><Filler Charx,0>'));
        Obs.Observe('int_filler_character_s', Fmt(5, '<Integer,4><Filler Characters,0>'));
        Obs.Observe('int_fil', Fmt(5, '<Integer,4><Fil,0>'));
        Obs.Observe('int_f', Fmt(5, '<Integer,4><F,0>'));
        Obs.Observe('int_int', Fmt(5, '<Int,4><Filler Char,0>'));
        Obs.Observe('int_integer_lower', Fmt(5, '<integer,4><filler char,0>'));
        Obs.Observe('int_char_hash', Fmt(5, '<Integer,4><Filler Char,#>'));
        Obs.Observe('int_char_z_len6', Fmt(5, '<Integer,6><Filler Char,z>'));
                Obs.Expect('int_filler', '0005');
        Obs.Expect('int_filler_c', '0005');
        Obs.Expect('int_filler_cha', '0005');
        Obs.Expect('int_filler_charx', 'ERR:InvalidFormatString');
        Obs.Expect('int_filler_character_s', 'ERR:InvalidFormatString');
        Obs.Expect('int_fil', '0005');
        Obs.Expect('int_f', '0005');
        Obs.Expect('int_int', '0005');
        Obs.Expect('int_integer_lower', '0005');
        Obs.Expect('int_char_hash', '###5');
        Obs.Expect('int_char_z_len6', 'zzzzz5');
        Obs.Verify();
    end;

    // ---- Format code names: ISO week and weekday for every week of 2021 and the year ends around it
    [Test]
    procedure FormatCode_WeekIsIso()
    var
        D: Date;
        Mismatch: Text;
        Count: Integer;
    begin
        for D := DMY2Date(28, 12, 2020) to DMY2Date(9, 1, 2022) do begin
            Count += 1;
            if (Format(D, 0, '<Week>') <> Format(Date2DWY(D, 2))) or
               (Format(D, 0, '<Week,2>') <> CopyStr('0' + Format(Date2DWY(D, 2)), StrLen(Format(Date2DWY(D, 2))), 2)) or
               (Format(D, 0, '<Weekday>') <> Format(Date2DWY(D, 1)))
            then
                Mismatch += Format(D, 0, 9) + '=' + Format(D, 0, '<Week>') + '/' + Format(D, 0, '<Week,2>') + '/' + Format(D, 0, '<Weekday>') + ' ';
        end;
        Obs.Observe('days', Format(Count));
        Obs.Observe('mismatch', Mismatch);
        Obs.Observe('2021-01-01', Format(DMY2Date(1, 1, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2021-01-03', Format(DMY2Date(3, 1, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2021-01-04', Format(DMY2Date(4, 1, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2021-04-15', Format(DMY2Date(15, 4, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2021-06-30', Format(DMY2Date(30, 6, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2021-12-31', Format(DMY2Date(31, 12, 2021), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2020-12-31', Format(DMY2Date(31, 12, 2020), 0, '<Week>/<Week,2>/<Weekday>'));
        Obs.Observe('2024-12-30', Format(DMY2Date(30, 12, 2024), 0, '<Week>/<Week,2>/<Weekday>'));
                Obs.Expect('days', '378');
        Obs.Expect('mismatch', '');
        Obs.Expect('2021-01-01', '53/53/5');
        Obs.Expect('2021-01-03', '53/53/7');
        Obs.Expect('2021-01-04', '1/01/1');
        Obs.Expect('2021-04-15', '15/15/4');
        Obs.Expect('2021-06-30', '26/26/3');
        Obs.Expect('2021-12-31', '52/52/5');
        Obs.Expect('2020-12-31', '53/53/4');
        Obs.Expect('2024-12-30', '1/01/1');
        Obs.Verify();
    end;

    // ---- Evaluate into a Time: six digits with minutes or seconds from 60
    [Test]
    procedure EvaluateTime_DigitForms()
    var
        T: Time;
        Ok: Boolean;
    begin
        Ok := Evaluate(T, '086000');
        Obs.Observe('086000', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '085960');
        Obs.Observe('085960', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '085959');
        Obs.Observe('085959', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '086100');
        Obs.Observe('086100', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '240000');
        Obs.Observe('240000', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '235959');
        Obs.Observe('235959', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '08:60:00');
        Obs.Observe('08:60:00', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '0860');
        Obs.Observe('0860', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '0859');
        Obs.Observe('0859', Format(Ok) + '/' + Format(T, 0, 9));
        Clear(T);
        Ok := Evaluate(T, '085606');
        Obs.Observe('085606', Format(Ok) + '/' + Format(T, 0, 9));
                Obs.Expect('086000', 'No/');
        Obs.Expect('085960', 'No/');
        Obs.Expect('085959', 'Yes/08:59:59');
        Obs.Expect('086100', 'No/');
        Obs.Expect('240000', 'No/');
        Obs.Expect('235959', 'Yes/23:59:59');
        Obs.Expect('08:60:00', 'No/');
        Obs.Expect('0860', 'No/');
        Obs.Expect('0859', 'Yes/08:59:00');
        Obs.Expect('085606', 'Yes/08:56:06');
        Obs.Verify();
    end;

    // ---- Date to DateTime: every conversion path that compiles
    [Test]
    procedure DateToDateTime_Paths()
    var
        Row: Record "LT Y70 Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        D: Date;
        DT: DateTime;
        V: Variant;
        Blank: Date;
        Ok: Boolean;
    begin
        D := DMY2Date(15, 3, 2024);
        V := D;
        DT := V;
        Obs.Observe('variant_defined', Format(DT, 0, 9));
        V := Blank;
        DT := V;
        Obs.Observe('variant_blank', Format(DT, 0, 9) + '/' + Format(DT = 0DT));
        Row.Init();
        Row."No." := 'A';
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(3);
        FldRef.Value := D;
        Obs.Observe('fieldref_defined', Format(FldRef.Value, 0, 9));
        FldRef.Value := Blank;
        Obs.Observe('fieldref_blank', Format(FldRef.Value, 0, 9));
        Ok := Evaluate(DT, Format(D, 0, 9));
        Obs.Observe('evaluate_date_text', Format(Ok) + '/' + Format(DT, 0, 9));
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'B';
        Row.Stamp := CreateDateTime(D, 0T);
        Row.Day := D;
        Row.Insert();
        Row.Reset();
        Row.DeleteAll();
                Obs.Expect('variant_defined', '2024-03-15T00:00:00Z');
        Obs.Expect('variant_blank', '/Yes');
        Obs.Expect('fieldref_defined', '2024-03-15T00:00:00Z');
        Obs.Expect('fieldref_blank', '');
        Obs.Expect('evaluate_date_text', 'Yes/2024-03-15T00:00:00Z');
        Obs.Verify();
    end;

    // ---- Filter on a DateFormula field: the empty text
    [Test]
    procedure FilterDateFormula_EmptyText()
    var
        Row: Record "LT Y70 Row";
        Formula: DateFormula;
    begin
        Row.DeleteAll();
        Evaluate(Formula, '<1M>');
        Row.Init();
        Row."No." := 'W';
        Row.DF := Formula;
        Row.Insert();
        Row.Init();
        Row."No." := 'W2';
        Evaluate(Formula, '<-CM+2D>');
        Row.DF := Formula;
        Row.Insert();
        Row.Init();
        Row."No." := 'WO';
        Row.Insert();
        Row.Reset();
        Obs.Observe('all', Format(Row.Count()));
        Clear(Formula);
        Row.SetFilter(DF, '<>%1', Formula);
        Obs.Observe('ne_blank_formula', Format(Row.Count()));
        Row.Reset();
        Row.SetFilter(DF, '''''');
        Obs.Observe('filter_two_quotes', Format(Row.Count()));
        Row.Reset();
        Row.SetFilter(DF, '<>''''');
        Obs.Observe('filter_ne_two_quotes', Format(Row.Count()));
        Row.Reset();
        asserterror Row.SetFilter(DF, '<1M>');
        Obs.Observe('filter_formula_text_code', GetLastErrorCode());
        ClearLastError();
        Row.Reset();
        Row.DeleteAll();
                Obs.Expect('all', '3');
        Obs.Expect('ne_blank_formula', '2');
        Obs.Expect('filter_two_quotes', '1');
        Obs.Expect('filter_ne_two_quotes', '2');
        Obs.Expect('filter_formula_text_code', 'Filter:CSide');
        Obs.Verify();
    end;

    // ---- Text argument: a Guid given where a Text is expected, in the functions GuidAsTextArgument.al does not cover
    [Test]
    procedure GuidAsText_OtherFunctions()
    var
        G: Guid;
        S: Text;
        Parts: List of [Text];
        TB: TextBuilder;
        Row: Record "LT Y70 Text Key";
    begin
        Evaluate(G, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        S := 'x{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}y{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}';
        Obs.Observe('endswith', Format(('ab' + Format(G)).EndsWith(G)));
        Obs.Observe('lastindexof', Format(S.LastIndexOf(G)));
        Parts := S.Split(G);
        Obs.Observe('split_count', Format(Parts.Count()));
        Obs.Observe('split_1', Parts.Get(1));
        Obs.Observe('split_2', Parts.Get(2));
        Obs.Observe('split_3', Parts.Get(3));
        TB.Append(G);
        Obs.Observe('tb_append', TB.ToText());
        TB.Clear();
        TB.AppendLine(G);
        Obs.Observe('tb_appendline_len', Format(StrLen(TB.ToText())));
        TB.Clear();
        TB.Append('q');
        TB.Insert(2, G);
        Obs.Observe('tb_insert', TB.ToText());
        TB.Clear();
        TB.Append(S);
        TB.Replace(G, 'R');
        Obs.Observe('tb_replace', TB.ToText());
        Obs.Observe('trimstart', Format(StrLen(Format(G).TrimStart(G))));
        Obs.Observe('trimend', Format(StrLen(Format(G).TrimEnd(G))));
        Obs.Observe('trim', Format(StrLen(Format(G).Trim())));
        Obs.Observe('indexofany', Format(S.IndexOfAny(G)));
                Obs.Expect('endswith', 'Yes');
        Obs.Expect('lastindexof', '41');
        Obs.Expect('split_count', '3');
        Obs.Expect('split_1', 'x');
        Obs.Expect('split_2', 'y');
        Obs.Expect('split_3', '');
        Obs.Expect('tb_append', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('tb_appendline_len', '40');
        Obs.Expect('tb_insert', 'q{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('tb_replace', 'xRyR');
        Obs.Expect('trimstart', '0');
        Obs.Expect('trimend', '0');
        Obs.Expect('trim', '38');
        Obs.Expect('indexofany', '2');
        Obs.Verify();
    end;

    [Test]
    procedure GuidAsText_RecordAndFormat()
    var
        G: Guid;
        S: Text;
        Row: Record "LT Y70 Text Key";
    begin
        Evaluate(G, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        S := 'x{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}y{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}';
        Obs.Observe('replace_in', S.Replace(G, 'R'));
        Obs.Observe('substno_arg', StrSubstNo('%1 %2', G, G));
        Row.DeleteAll();
        Row.Init();
        Row.Name := CopyStr(Format(G), 1, 10);
        Row.Note := G;
        Row.Insert();
        Obs.Observe('field_assign_note', Row.Note);
        Row.SetRange(Name, CopyStr(Format(G), 1, 10));
        Obs.Observe('setrange_name', Format(Row.Count()));
        Row.Reset();
        Row.DeleteAll();
                Obs.Expect('replace_in', 'xRyR');
        Obs.Expect('substno_arg', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('field_assign_note', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('setrange_name', '1');
        Obs.Verify();
    end;

    // ---- Get with a value that is not of the key's type, on a Text and a Code key
    [Test]
    procedure RecordGet_BooleanOnTextKey()
    var
        TextRow: Record "LT Y70 Text Key";
        CodeRow: Record "LT Y70 Code Key";
        D: Date;
        G: Guid;
    begin
        TextRow.DeleteAll();
        CodeRow.DeleteAll();
        InsertText('Yes');
        InsertText('YES');
        InsertText('No');
        InsertText('1');
        InsertText('0');
        InsertCode('YES');
        InsertCode('NO');
        InsertCode('1');
        D := DMY2Date(15, 3, 2024);
        Evaluate(G, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        Obs.Observe('text_true', GetText(true));
        Obs.Observe('text_false', GetText(false));
        Obs.Observe('text_int1', GetText(1));
        Obs.Observe('text_int0', GetText(0));
        Obs.Observe('code_true', GetCode(true));
        Obs.Observe('code_false', GetCode(false));
        Obs.Observe('code_int1', GetCode(1));
        TextRow.DeleteAll();
        CodeRow.DeleteAll();
                Obs.Expect('text_true', 'Yes');
        Obs.Expect('text_false', 'No');
        Obs.Expect('text_int1', '1');
        Obs.Expect('text_int0', '0');
        Obs.Expect('code_true', 'YES');
        Obs.Expect('code_false', 'NO');
        Obs.Expect('code_int1', '1');
        Obs.Verify();
    end;

    local procedure InsertText(Name: Text[10])
    var
        Row: Record "LT Y70 Text Key";
    begin
        Row.Name := Name;
        Row.Insert();
    end;

    local procedure InsertCode(Name: Code[10])
    var
        Row: Record "LT Y70 Code Key";
    begin
        Row.Name := Name;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryGetText(V: Variant; var Found: Text)
    var
        Row: Record "LT Y70 Text Key";
    begin
        if Row.Get(V) then
            Found := Row.Name
        else
            Found := '<none>';
    end;

    [TryFunction]
    local procedure TryGetCode(V: Variant; var Found: Text)
    var
        Row: Record "LT Y70 Code Key";
    begin
        if Row.Get(V) then
            Found := Row.Name
        else
            Found := '<none>';
    end;

    local procedure GetText(V: Variant): Text
    var
        Found: Text;
    begin
        if TryGetText(V, Found) then
            exit(Found);
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure GetCode(V: Variant): Text
    var
        Found: Text;
    begin
        if TryGetCode(V, Found) then
            exit(Found);
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    // ---- Get with a Text on an Integer and a BigInteger key
    [Test]
    procedure RecordGet_TextOnIntegerKey()
    var
        IntRow: Record "LT Y70 Int Key";
    begin
        IntRow.DeleteAll();
        IntRow.Id := 5;
        IntRow.Insert();
        Obs.Observe('int_format5', GetInt(Format(5)));
        Obs.Observe('int_text5', GetInt('5'));
        Obs.Observe('int_padded', GetInt(' 5 '));
        Obs.Observe('int_plus', GetInt('+5'));
        Obs.Observe('int_x', GetInt('x'));
        Obs.Observe('int_empty', GetInt(''));
        Obs.Observe('int_decimal_text', GetInt('5.0'));
        Obs.Observe('int_code', GetInt(Code10('5')));
        IntRow.DeleteAll();
                Obs.Expect('int_format5', '5');
        Obs.Expect('int_text5', '5');
        Obs.Expect('int_padded', '5');
        Obs.Expect('int_plus', '5');
#if BC28PLUS
        Obs.Expect('int_x', 'ERR:Evaluate:Format:The value "x" can''t be evaluated into type Integer.');
#else
        Obs.Expect('int_x', 'ERR:NotSupportedType:The type NavInteger is unknown.');
#endif
#if BC28PLUS
        Obs.Expect('int_empty', 'ERR:Evaluate:Format:The value "" can''t be evaluated into type Integer.');
#else
        Obs.Ignore('int_empty');
#endif
#if BC28PLUS
        Obs.Expect('int_decimal_text', 'ERR:Evaluate:Format:The value "5.0" can''t be evaluated into type Integer.');
#else
        Obs.Ignore('int_decimal_text');
#endif
        Obs.Expect('int_code', '5');
        Obs.Verify();
    end;

    [Test]
    procedure RecordGet_TextOnBigIntegerKey()
    var
        BigRow: Record "LT Y70 Big Key";
    begin
        BigRow.DeleteAll();
        BigRow.Id := 5;
        BigRow.Insert();
        Obs.Observe('big_format5', GetBig(Format(5)));
        Obs.Observe('big_text5', GetBig('5'));
        Obs.Observe('big_padded', GetBig(' 5 '));
        Obs.Observe('big_x', GetBig('x'));
        Obs.Observe('big_empty', GetBig(''));
        BigRow.DeleteAll();
                Obs.Expect('big_format5', '5');
        Obs.Expect('big_text5', '5');
        Obs.Expect('big_padded', '5');
#if BC28PLUS
        Obs.Expect('big_x', 'ERR:Evaluate:Format:The value "x" can''t be evaluated into type BigInteger.');
#else
        Obs.Expect('big_x', 'ERR:NotSupportedType:The type NavBigInteger is unknown.');
#endif
#if BC28PLUS
        Obs.Expect('big_empty', 'ERR:Evaluate:Format:The value "" can''t be evaluated into type BigInteger.');
#else
        Obs.Ignore('big_empty');
#endif
        Obs.Verify();
    end;

    local procedure Code10(C: Code[10]): Code[10]
    begin
        exit(C);
    end;

    [TryFunction]
    local procedure TryGetInt(V: Variant; var Found: Text)
    var
        Row: Record "LT Y70 Int Key";
    begin
        if Row.Get(V) then
            Found := Format(Row.Id)
        else
            Found := '<none>';
    end;

    [TryFunction]
    local procedure TryGetBig(V: Variant; var Found: Text)
    var
        Row: Record "LT Y70 Big Key";
    begin
        if Row.Get(V) then
            Found := Format(Row.Id)
        else
            Found := '<none>';
    end;

    local procedure GetInt(V: Variant): Text
    var
        Found: Text;
    begin
        if TryGetInt(V, Found) then
            exit(Found);
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure GetBig(V: Variant): Text
    var
        Found: Text;
    begin
        if TryGetBig(V, Found) then
            exit(Found);
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    // ---- JsonValue.AsBoolean (and the other getters) of strings that are not true or false
    [Test]
    procedure JsonValue_AsBooleanOtherText()
    begin
        Obs.Observe('not_a_boolean', AsBool('not a boolean'));
        Obs.Observe('not_a_boolean_text', AsBoolText('not a boolean'));
        Obs.Observe('a1', AsBool('a1'));
        Obs.Observe('dash', AsBool('-'));
        Obs.Observe('true_bang', AsBool('true!'));
        Obs.Observe('true_space', AsBool('true '));
        Obs.Observe('True_upper', AsBool('TRUE'));
        Obs.Observe('yes', AsBool('yes'));
        Obs.Observe('one', AsBool('1'));
                Obs.Expect('not_a_boolean', 'ERR:Conversion');
        Obs.Expect('not_a_boolean_text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Boolean.');
        Obs.Expect('a1', 'ERR:Conversion');
        Obs.Expect('dash', 'ERR:Conversion');
        Obs.Expect('true_bang', 'ERR:Conversion');
        Obs.Expect('true_space', 'Yes');
        Obs.Expect('True_upper', 'Yes');
        Obs.Expect('yes', 'ERR:Conversion');
        Obs.Expect('one', 'ERR:Conversion');
        Obs.Verify();
    end;

    [Test]
    procedure JsonValue_OtherGettersOtherText()
    begin
        Obs.Observe('letters', AsBool('abc'));
        Obs.Observe('digits', AsBool('123'));
        Obs.Observe('empty', AsBool(''));
        Obs.Observe('int_not_a_boolean', AsInt('not a number'));
        Obs.Observe('dec_a1', AsDec('a1'));
        Obs.Observe('date_dash', AsDate('-'));
                Obs.Expect('letters', 'ERR:Conversion');
        Obs.Expect('digits', 'ERR:Conversion');
        Obs.Expect('empty', 'ERR:Conversion');
        Obs.Expect('int_not_a_boolean', 'ERR:Conversion');
        Obs.Expect('dec_a1', 'ERR:Conversion');
        Obs.Expect('date_dash', 'ERR:Conversion');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryAsBool(Txt: Text; var R: Text)
    var
        J: JsonValue;
    begin
        J.SetValue(Txt);
        R := Format(J.AsBoolean());
    end;

    local procedure AsBool(Txt: Text): Text
    var
        R: Text;
    begin
        if TryAsBool(Txt, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode());
    end;

    local procedure AsBoolText(Txt: Text): Text
    var
        R: Text;
    begin
        if TryAsBool(Txt, R) then
            exit(R);
        exit(GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryAsInt(Txt: Text; var R: Text)
    var
        J: JsonValue;
    begin
        J.SetValue(Txt);
        R := Format(J.AsInteger());
    end;

    local procedure AsInt(Txt: Text): Text
    var
        R: Text;
    begin
        if TryAsInt(Txt, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAsDec(Txt: Text; var R: Text)
    var
        J: JsonValue;
    begin
        J.SetValue(Txt);
        R := Format(J.AsDecimal());
    end;

    local procedure AsDec(Txt: Text): Text
    var
        R: Text;
    begin
        if TryAsDec(Txt, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAsDate(Txt: Text; var R: Text)
    var
        J: JsonValue;
    begin
        J.SetValue(Txt);
        R := Format(J.AsDate());
    end;

    local procedure AsDate(Txt: Text): Text
    var
        R: Text;
    begin
        if TryAsDate(Txt, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode());
    end;

    // ---- Evaluate into a RecordId: a Code key value with blanks around it
    [Test]
    procedure EvaluateRecordId_BlanksAroundCodeKey()
    begin
        Obs.Observe('leading', EvalRid('LT Y70 Code Key: ' + ' ABC'));
        Obs.Observe('trailing', EvalRid('LT Y70 Code Key: ABC '));
        Obs.Observe('both', EvalRid('LT Y70 Code Key:  ABC '));
        Obs.Observe('ten_leading_blank', EvalRid('LT Y70 Code Key:  GUAAAAAAB'));
        Obs.Observe('eleven', EvalRid('LT Y70 Code Key: ABCDEFGHIJK'));
        Obs.Observe('ten_after_trim', EvalRid('LT Y70 Code Key:  ABCDEFGHIJ'));
        Obs.Observe('plain', EvalRid('LT Y70 Code Key: ABC'));
                Obs.Expect('leading', 'true:[LT Y70 Code Key: ABC]20/93742');
        Obs.Expect('trailing', 'true:[LT Y70 Code Key: ABC]20/93742');
        Obs.Expect('both', 'true:[LT Y70 Code Key: ABC]20/93742');
        Obs.Expect('ten_leading_blank', 'true:[LT Y70 Code Key: GUAAAAAAB]26/93742');
        Obs.Expect('eleven', 'false:The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK');
        Obs.Expect('ten_after_trim', 'true:[LT Y70 Code Key: ABCDEFGHIJ]27/93742');
        Obs.Expect('plain', 'true:[LT Y70 Code Key: ABC]20/93742');
        Obs.Verify();
    end;

    local procedure EvalRid(Txt: Text): Text
    var
        Rid: RecordId;
        Ok: Boolean;
        Shown: Text;
    begin
        Ok := Evaluate(Rid, Txt);
        if not Ok then
            exit('false:' + GetLastErrorText());
        Shown := Format(Rid);
        exit('true:[' + Shown + ']' + Format(StrLen(Shown)) + '/' + Format(Rid.TableNo));
    end;

    // ---- Option InitValue as a number
    [Test]
    procedure OptionInitValue_Ordinal()
    var
        Row: Record "LT Y70 Option Init";
        Again: Record "LT Y70 Option Init";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Obs.Observe('fresh', Format(Row.Day) + '/' + Format(Ordinal(Row.Day)));
        Row.Init();
        Obs.Observe('init', Format(Row.Day) + '/' + Format(Ordinal(Row.Day)));
        Row.Id := 1;
        Row.Insert();
        Again.Get(1);
        Obs.Observe('get', Format(Again.Day) + '/' + Format(Ordinal(Again.Day)));
        Obs.Observe('two', Format(Row.DayTwo) + '/' + Format(Again.DayTwo));
        RecRef.Open(Database::"LT Y70 Option Init");
        RecRef.Init();
        Obs.Observe('recref_init', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        RecRef.Close();
        Row.DeleteAll();
                Obs.Expect('fresh', 'Monday/1');
        Obs.Expect('init', 'Monday/1');
        Obs.Expect('get', 'Monday/1');
        Obs.Expect('two', 'Tuesday/Tuesday');
        Obs.Expect('recref_init', 'Monday/Tuesday');
        Obs.Verify();
    end;

    local procedure Ordinal(O: Option): Integer
    begin
        exit(O);
    end;

    // ---- The Field row of a field with ObsoleteState = PendingMove
    [Test]
    procedure FieldRow_PendingMove()
    var
        Fld: Record Field;
    begin
        Fld.Get(Database::"LT Y70 Pending Move", 2);
        Obs.Observe('moving_state_0', Format(Fld.ObsoleteState));
        Obs.Observe('moving_state_2', Format(Fld.ObsoleteState, 0, 2));
        Obs.Observe('moving_reason', Fld.ObsoleteReason);
        Fld.Get(Database::"LT Y70 Pending Move", 3);
        Obs.Observe('staying_state_0', Format(Fld.ObsoleteState));
        Obs.Observe('staying_state_2', Format(Fld.ObsoleteState, 0, 2));
        Fld.Get(Database::"LT Y70 Pending Move", 4);
        Obs.Observe('pending_state_0', Format(Fld.ObsoleteState));
        Obs.Observe('pending_state_2', Format(Fld.ObsoleteState, 0, 2));
        Obs.Observe('moving_ne_removed', FieldCount(2, '<>%1', Fld.ObsoleteState::Removed));
        Obs.Observe('moving_eq_pending', FieldCount(2, '%1', Fld.ObsoleteState::Pending));
        Obs.Observe('moving_eq_no', FieldCount(2, '%1', Fld.ObsoleteState::No));
        Obs.Observe('moving_eq_removed', FieldCount(2, '%1', Fld.ObsoleteState::Removed));
        Obs.Observe('moving_ne_no', FieldCount(2, '<>%1', Fld.ObsoleteState::No));
        Obs.Observe('pending_eq_pending', FieldCount(4, '%1', Fld.ObsoleteState::Pending));
        Obs.Observe('staying_ne_removed', FieldCount(3, '<>%1', Fld.ObsoleteState::Removed));
                Obs.Expect('moving_state_0', '3');
        Obs.Expect('moving_state_2', '3');
        Obs.Expect('moving_reason', 'Moved to another app.');
        Obs.Expect('staying_state_0', 'No');
        Obs.Expect('staying_state_2', '0');
        Obs.Expect('pending_state_0', 'Pending');
        Obs.Expect('pending_state_2', '1');
        Obs.Expect('moving_ne_removed', '1');
        Obs.Expect('moving_eq_pending', '0');
        Obs.Expect('moving_eq_no', '0');
        Obs.Expect('moving_eq_removed', '0');
        Obs.Expect('moving_ne_no', '1');
        Obs.Expect('pending_eq_pending', '1');
        Obs.Expect('staying_ne_removed', '1');
        Obs.Verify();
    end;

    local procedure FieldCount(FieldNo: Integer; Expr: Text; State: Option): Text
    var
        Fld: Record Field;
    begin
        Fld.SetRange(TableNo, Database::"LT Y70 Pending Move");
        Fld.SetRange("No.", FieldNo);
        Fld.SetFilter(ObsoleteState, Expr, State);
        exit(Format(Fld.Count()));
    end;

    // ---- SystemId of the Field rows of the system fields
    [Test]
    procedure FieldRow_SystemFieldSystemId()
    var
    begin
        ObserveFieldRow('f1', 1);
        ObserveFieldRow('f2000000000', 2000000000);
        ObserveFieldRow('f2000000001', 2000000001);
        ObserveFieldRow('f2000000002', 2000000002);
        ObserveFieldRow('f2000000003', 2000000003);
        ObserveFieldRow('f2000000004', 2000000004);
        #if BC28PLUS
        Obs.Expect('f1', '{77359429-6E2C-0001-0100-000000000000} No.');
        Obs.Expect('f2000000000', '{77359429-6E2C-0001-0094-357700000000} $systemId');
        Obs.Expect('f2000000001', '{77359429-6E2C-0001-0194-357700000000} SystemCreatedAt');
        Obs.Expect('f2000000002', '{77359429-6E2C-0001-0294-357700000000} SystemCreatedBy');
        Obs.Expect('f2000000003', '{77359429-6E2C-0001-0394-357700000000} SystemModifiedAt');
        Obs.Expect('f2000000004', '{77359429-6E2C-0001-0494-357700000000} SystemModifiedBy');
#else
        Obs.Expect('f1', '{00000000-0000-0000-0000-000000000000} No.');
        Obs.Expect('f2000000000', '{00000000-0000-0000-0000-000000000000} $systemId');
        Obs.Expect('f2000000001', '{00000000-0000-0000-0000-000000000000} SystemCreatedAt');
        Obs.Expect('f2000000002', '{00000000-0000-0000-0000-000000000000} SystemCreatedBy');
        Obs.Expect('f2000000003', '{00000000-0000-0000-0000-000000000000} SystemModifiedAt');
        Obs.Expect('f2000000004', '{00000000-0000-0000-0000-000000000000} SystemModifiedBy');
#endif
        Obs.Verify();
    end;

    local procedure ObserveFieldRow(Name: Text; FieldNo: Integer)
    var
        Fld: Record Field;
    begin
        if Fld.Get(Database::"LT Y70 Row", FieldNo) then
            Obs.Observe(Name, Format(Fld.SystemId) + ' ' + Fld.FieldName)
        else
            Obs.Observe(Name, 'none');
    end;

    // ---- Transaction state after a read under ReadUncommitted
    [Test]
    procedure ReadUncommitted_NoWriteTransaction()
    var
        Row: Record "LT Y70 Int Key";
    begin
        Commit();
        Obs.Observe('start', Format(Database.IsInWriteTransaction()));
        Row.ReadIsolation := IsolationLevel::ReadUncommitted;
        if Row.FindFirst() then;
        Obs.Observe('after_uncommitted_find', Format(Database.IsInWriteTransaction()));
        Row.ReadIsolation := IsolationLevel::ReadCommitted;
        if Row.FindFirst() then;
        Obs.Observe('after_committed_find', Format(Database.IsInWriteTransaction()));
        Row.ReadIsolation := IsolationLevel::UpdLock;
        if Row.FindFirst() then;
        Obs.Observe('after_updlock_find', Format(Database.IsInWriteTransaction()));
        Commit();
        Row.ReadIsolation := IsolationLevel::ReadUncommitted;
        if Row.Count() > 0 then;
        Obs.Observe('after_uncommitted_count', Format(Database.IsInWriteTransaction()));
                Obs.Expect('start', 'No');
        Obs.Expect('after_uncommitted_find', 'No');
        Obs.Expect('after_committed_find', 'No');
        Obs.Expect('after_updlock_find', 'Yes');
        Obs.Expect('after_uncommitted_count', 'No');
        Obs.Verify();
    end;

    // ---- Feature Key: Modify without a change, with a change that is put back
    [Test]
    procedure FeatureKey_Modify()
    var
        FK: Record "Feature Key";
        Again: Record "Feature Key";
        Original: Option;
        Id: Text;
        Flipped: Option;
    begin
        Obs.Observe('rows_gt0', Format(FK.Count() > 0));
        FK.SetFilter(Enabled, '<>%1', FK.Enabled::None);
        if FK.FindFirst() then
            Flipped := FK.Enabled::None
        else begin
            FK.Reset();
            FK.FindFirst();
            Flipped := FK.Enabled::"All Users";
        end;
        Id := FK.ID;
        Original := FK.Enabled;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('unchanged_modify_keeps', Format(Again.Enabled = Original));
        FK.Enabled := FK.Enabled;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('same_value_modify_keeps', Format(Again.Enabled = Original));
        FK.Enabled := Flipped;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('flipped_get_is_new', Format(Again.Enabled = Flipped));
        FK.Reset();
        FK.SetRange(ID, Id);
        FK.FindFirst();
        Obs.Observe('flipped_findfirst_is_new', Format(FK.Enabled = Flipped));
        FK.Reset();
        FK.SetRange(ID, Id);
        FK.SetRange(Enabled, Flipped);
        Obs.Observe('flipped_filter_count', Format(FK.Count()));
        FK.Reset();
        FK.Get(Id);
        FK.Enabled := Original;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('restored', Format(Again.Enabled = Original));
                Obs.Expect('rows_gt0', 'Yes');
        Obs.Expect('unchanged_modify_keeps', 'Yes');
        Obs.Expect('same_value_modify_keeps', 'Yes');
        Obs.Expect('flipped_get_is_new', 'Yes');
        Obs.Expect('flipped_findfirst_is_new', 'Yes');
        Obs.Expect('flipped_filter_count', '1');
        Obs.Expect('restored', 'Yes');
        Obs.Verify();
    end;

    // ---- IsolatedStorage: SetEncrypted over an existing key, Set over an encrypted key, each right after a Commit
    // Linux suspect: the Linux CI containers have no encryption key (SetEncrypted raises NavEncryptionKeyNotFoundException), so this is not a [Test].
    procedure Suspect_IsolatedStorage_EncryptedOverwrite()
    begin
        if IsolatedStorage.Contains('LTY70iso', DataScope::Module) then
            IsolatedStorage.Delete('LTY70iso', DataScope::Module);
        Commit();
        Obs.Observe('set_encrypted_new', Format(IsolatedStorage.SetEncrypted('LTY70iso', 'v1', DataScope::Module)));
        Obs.Observe('after_new', Format(Database.IsInWriteTransaction()));
        Commit();
        Obs.Observe('before_encrypted_again', Format(Database.IsInWriteTransaction()));
        Obs.Observe('set_encrypted_again', Format(IsolatedStorage.SetEncrypted('LTY70iso', 'v2', DataScope::Module)));
        Obs.Observe('after_encrypted_again', Format(Database.IsInWriteTransaction()));
        Commit();
        Obs.Observe('set_encrypted_same', Format(IsolatedStorage.SetEncrypted('LTY70iso', 'v2', DataScope::Module)));
        Obs.Observe('after_encrypted_same', Format(Database.IsInWriteTransaction()));
        Commit();
        Obs.Observe('set_plain_over_encrypted', Format(IsolatedStorage.Set('LTY70iso', 'v3', DataScope::Module)));
        Obs.Observe('after_plain_over_encrypted', Format(Database.IsInWriteTransaction()));
        Commit();
        IsolatedStorage.Delete('LTY70iso', DataScope::Module);
        Commit();
        Obs.Finish();
    end;

    local procedure Dirty(var RecRef: RecordRef): Text
    var
        R: Text;
    begin
        if TryDirty(RecRef, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryDirty(var RecRef: RecordRef; var R: Text)
    begin
        R := Format(RecRef.IsDirty());
    end;

    // ---- RecordRef.IsDirty of a buffer that did not come from a read or write through the ref
    [Test]
    procedure RecordRefIsDirty_Shapes()
    var
        Row: Record "LT Y70 Text Key";
        Same: Record "LT Y70 Text Key";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row.Name := 'K';
        Row.Note := 'stored';
        Row.Insert();
        Same.Get('K');
        RecRef.GetTable(Same);
        Obs.Observe('gettable_read', Dirty(RecRef));
        Same.Note := 'changed';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_changed_unsaved', Dirty(RecRef));
        Same.Init();
        RecRef.GetTable(Same);
        Obs.Observe('gettable_init', Dirty(RecRef));
        Same.Name := 'K';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_key_only', Dirty(RecRef));
        Same.Name := 'NOROW';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_no_stored_row', Dirty(RecRef));
        Clear(RecRef);
        Obs.Observe('after_clear', Dirty(RecRef));
        RecRef.Open(Database::"LT Y70 Text Key");
        Obs.Observe('open_fresh', Dirty(RecRef));
        RecRef.Init();
        Obs.Observe('open_init', Dirty(RecRef));
        RecRef.Field(1).Value := 'K';
        Obs.Observe('open_key_set', Dirty(RecRef));
        RecRef.Field(2).Value := 'x';
        Obs.Observe('open_note_set', Dirty(RecRef));
        RecRef.Get(Row.RecordId);
        Obs.Observe('after_get', Dirty(RecRef));
        RecRef.Field(2).Value := 'y';
        Obs.Observe('after_get_changed', Dirty(RecRef));
        Row.DeleteAll();
        Clear(Same);
        Same.Init();
        RecRef.GetTable(Same);
        Obs.Observe('gettable_blank_no_stored_row', Dirty(RecRef));
        Row.DeleteAll();
                Obs.Expect('gettable_read', 'No');
        Obs.Expect('gettable_changed_unsaved', 'Yes');
        Obs.Expect('gettable_init', 'Yes');
        Obs.Expect('gettable_key_only', 'Yes');
        Obs.Expect('gettable_no_stored_row', 'Yes');
        Obs.Expect('after_clear', 'ERR:RecordNotOpened:The record is not open.');
        Obs.Expect('open_fresh', 'No');
        Obs.Expect('open_init', 'No');
        Obs.Expect('open_key_set', 'Yes');
        Obs.Expect('open_note_set', 'Yes');
        Obs.Expect('after_get', 'No');
        Obs.Expect('after_get_changed', 'Yes');
        Obs.Expect('gettable_blank_no_stored_row', 'No');
        Obs.Verify();
    end;
}
