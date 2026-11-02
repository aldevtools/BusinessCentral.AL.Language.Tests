// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-programming-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables in Y70Tables.al
// Probe (writer Y70): runtime assumptions that had no corpus pin. One test per element, grouped in the file by element. Object id 93740.

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
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
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
        Obs.Observe('int_filler', Fmt(5, '<Integer,4><Filler,0>'));
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Row.Validate(Stamp, D);
        Obs.Observe('validate_defined', Format(Row.Stamp, 0, 9));
        Row.Validate(Stamp, Blank);
        Obs.Observe('validate_blank', Format(Row.Stamp, 0, 9) + '/' + Format(Row.Stamp = 0DT));
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
        Row.SetRange(Stamp, D);
        Obs.Observe('setrange_defined', Format(Row.Count()));
        Row.SetFilter(Stamp, '%1', D);
        Obs.Observe('setfilter_defined', Format(Row.Count()));
        Row.Reset();
        Row.SetRange(Stamp, Blank);
        Obs.Observe('setrange_blank', Format(Row.Count()));
        Row.Reset();
        Row.SetRange(Stamp, ClosingDate(D));
        Obs.Observe('setrange_closingdate', Format(Row.Count()));
        Row.DeleteAll();
        Obs.Finish();
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
        Row.SetFilter(DF, '<>%1', '');
        Obs.Observe('ne_empty_text', Format(Row.Count()));
        Row.Reset();
        Row.SetFilter(DF, '%1', '');
        Obs.Observe('eq_empty_text', Format(Row.Count()));
        Row.Reset();
        Row.SetRange(DF, '');
        Obs.Observe('range_empty_text', Format(Row.Count()));
        Row.Reset();
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
        Row.SetFilter(DF, '<1M>');
        Obs.Observe('filter_formula_text', Format(Row.Count()));
        Row.Reset();
        Row.DeleteAll();
        Obs.Finish();
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
        Obs.Observe('padleft', Format(StrLen(PadStr('', 2, G))));
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
        Obs.Finish();
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
        InsertText('1.5');
        InsertText('0');
        InsertText('15.03.24');
        InsertCode('YES');
        InsertCode('NO');
        InsertCode('1');
        D := DMY2Date(15, 3, 2024);
        Evaluate(G, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        Obs.Observe('text_true', GetText(true));
        Obs.Observe('text_false', GetText(false));
        Obs.Observe('text_int1', GetText(1));
        Obs.Observe('text_int0', GetText(0));
        Obs.Observe('text_dec', GetText(1.5));
        Obs.Observe('text_date', GetText(D));
        Obs.Observe('code_true', GetCode(true));
        Obs.Observe('code_false', GetCode(false));
        Obs.Observe('code_int1', GetCode(1));
        TextRow.DeleteAll();
        CodeRow.DeleteAll();
        Obs.Finish();
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
        BigRow: Record "LT Y70 Big Key";
    begin
        IntRow.DeleteAll();
        BigRow.DeleteAll();
        IntRow.Id := 5;
        IntRow.Insert();
        BigRow.Id := 5;
        BigRow.Insert();
        Obs.Observe('int_format5', GetInt(Format(5)));
        Obs.Observe('int_text5', GetInt('5'));
        Obs.Observe('int_padded', GetInt(' 5 '));
        Obs.Observe('int_plus', GetInt('+5'));
        Obs.Observe('int_x', GetInt('x'));
        Obs.Observe('int_empty', GetInt(''));
        Obs.Observe('int_decimal_text', GetInt('5.0'));
        Obs.Observe('int_code', GetInt(Code10('5')));
        Obs.Observe('big_format5', GetBig(Format(5)));
        Obs.Observe('big_text5', GetBig('5'));
        Obs.Observe('big_padded', GetBig(' 5 '));
        Obs.Observe('big_x', GetBig('x'));
        Obs.Observe('big_empty', GetBig(''));
        IntRow.DeleteAll();
        BigRow.DeleteAll();
        Obs.Finish();
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
        Obs.Observe('a1', AsBool('a1'));
        Obs.Observe('dash', AsBool('-'));
        Obs.Observe('true_bang', AsBool('true!'));
        Obs.Observe('true_space', AsBool('true '));
        Obs.Observe('True_upper', AsBool('TRUE'));
        Obs.Observe('yes', AsBool('yes'));
        Obs.Observe('one', AsBool('1'));
        Obs.Observe('letters', AsBool('abc'));
        Obs.Observe('digits', AsBool('123'));
        Obs.Observe('empty', AsBool(''));
        Obs.Observe('int_not_a_boolean', AsInt('not a number'));
        Obs.Observe('dec_a1', AsDec('a1'));
        Obs.Observe('date_dash', AsDate('-'));
        Obs.Finish();
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
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
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
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
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
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
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
        exit('ERR:' + GetLastErrorCode() + ':' + GetLastErrorText());
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
        Obs.Finish();
    end;

    local procedure EvalRid(Txt: Text): Text
    var
        Rid: RecordId;
        RecRef: RecordRef;
        Ok: Boolean;
    begin
        Ok := Evaluate(Rid, Txt);
        if not Ok then
            exit('false:' + GetLastErrorText());
        RecRef.Get(Rid);
        exit('true:[' + Format(RecRef.Field(1).Value) + ']' + Format(StrLen(Format(RecRef.Field(1).Value))));
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
        Obs.Observe('fresh', Format(Row.Day) + '/' + Format(Row.Day.AsInteger()));
        Row.Init();
        Obs.Observe('init', Format(Row.Day) + '/' + Format(Row.Day.AsInteger()));
        Row.Id := 1;
        Row.Insert();
        Again.Get(1);
        Obs.Observe('get', Format(Again.Day) + '/' + Format(Again.Day.AsInteger()));
        RecRef.Open(Database::"LT Y70 Option Init");
        RecRef.Init();
        Obs.Observe('recref_init', Format(RecRef.Field(2).Value));
        RecRef.Close();
        Row.DeleteAll();
        Obs.Finish();
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
        Fld.Reset();
        Fld.SetRange(TableNo, Database::"LT Y70 Pending Move");
        Fld.SetFilter(FieldName, '<>Id');
        Fld.SetFilter(ObsoleteState, '<>%1', Fld.ObsoleteState::Removed);
        Obs.Observe('ne_removed', Format(Fld.Count()));
        Fld.SetRange(ObsoleteState, Fld.ObsoleteState::Pending);
        Obs.Observe('eq_pending', Format(Fld.Count()));
        Fld.SetRange(ObsoleteState);
        Fld.SetRange(ObsoleteState, Fld.ObsoleteState::No);
        Obs.Observe('eq_no', Format(Fld.Count()));
        Fld.SetRange(ObsoleteState);
        Fld.SetFilter(ObsoleteState, '<>%1&<>%2', Fld.ObsoleteState::Removed, Fld.ObsoleteState::Pending);
        Obs.Observe('ne_removed_ne_pending', Format(Fld.Count()));
        Obs.Finish();
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
        Obs.Finish();
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
        Row.Count();
        Obs.Observe('after_uncommitted_count', Format(Database.IsInWriteTransaction()));
        Obs.Finish();
    end;

    // ---- Feature Key: Modify without a change, with a change that is put back
    [Test]
    procedure FeatureKey_Modify()
    var
        FK: Record "Feature Key";
        Again: Record "Feature Key";
        Original: Option;
        Id: Text;
    begin
        FK.FindFirst();
        Id := FK.ID;
        Original := FK.Enabled;
        Obs.Observe('first_enabled', Format(FK.Enabled));
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('unchanged_modify_enabled', Format(Again.Enabled));
        FK.Enabled := FK.Enabled;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('same_value_modify_enabled', Format(Again.Enabled));
        FK.Enabled := FK.Enabled::None;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('none_modify_enabled', Format(Again.Enabled));
        FK.Reset();
        FK.SetRange(ID, Id);
        FK.FindFirst();
        Obs.Observe('findfirst_after', Format(FK.Enabled));
        Obs.Observe('count_all_gt0', Format(Again.Count() > 0));
        FK.Enabled := Original;
        FK.Modify();
        Again.Get(Id);
        Obs.Observe('restored', Format(Again.Enabled = Original));
        Obs.Finish();
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
        Obs.Observe('gettable_read', Format(RecRef.IsDirty()));
        Same.Note := 'changed';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_changed_unsaved', Format(RecRef.IsDirty()));
        Same.Init();
        RecRef.GetTable(Same);
        Obs.Observe('gettable_init', Format(RecRef.IsDirty()));
        Same.Name := 'K';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_key_only', Format(RecRef.IsDirty()));
        Same.Name := 'NOROW';
        RecRef.GetTable(Same);
        Obs.Observe('gettable_no_stored_row', Format(RecRef.IsDirty()));
        RecRef.Clear();
        Obs.Observe('after_clear', Format(RecRef.IsDirty()));
        RecRef.Open(Database::"LT Y70 Text Key");
        Obs.Observe('open_fresh', Format(RecRef.IsDirty()));
        RecRef.Init();
        Obs.Observe('open_init', Format(RecRef.IsDirty()));
        RecRef.Field(1).Value := 'K';
        Obs.Observe('open_key_set', Format(RecRef.IsDirty()));
        RecRef.Field(2).Value := 'x';
        Obs.Observe('open_note_set', Format(RecRef.IsDirty()));
        RecRef.Get(Same.RecordId);
        Obs.Observe('after_get', Format(RecRef.IsDirty()));
        RecRef.Field(2).Value := 'y';
        Obs.Observe('after_get_changed', Format(RecRef.IsDirty()));
        Row.DeleteAll();
        Obs.Finish();
    end;
}
