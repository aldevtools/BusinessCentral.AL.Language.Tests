// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 70710, 70711, enum 70713
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TransferFields between an Enum field and an Option field with the same field number: whether the ordinal moves; an Option ordinal the Enum lacks
// BC versions: 29 (27 and 28 by CI)

codeunit 70728 "LT P68 Transfer Enum Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOptToEnum(var Dest: Record "LT P68 X1"; var Src: Record "LT P68 X2"; Init: Boolean)
    begin
        Dest.TransferFields(Src, Init);
    end;

    [TryFunction]
    local procedure TryEnumToOpt(var Dest: Record "LT P68 X2"; var Src: Record "LT P68 X1"; Init: Boolean)
    begin
        Dest.TransferFields(Src, Init);
    end;

    [TryFunction]
    local procedure TryOptToEnumSkip(var Dest: Record "LT P68 X1"; var Src: Record "LT P68 X2")
    begin
        Dest.TransferFields(Src, false, true);
    end;

    [TryFunction]
    local procedure TryEnumToOptSkip(var Dest: Record "LT P68 X2"; var Src: Record "LT P68 X1")
    begin
        Dest.TransferFields(Src, false, true);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Option_To_Enum_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT P68 X2";
        Dest: Record "LT P68 X1";
        i: Integer;
    begin
        for i := 0 to 6 do begin
            Clear(Dest);
            Src.Init();
            Src.Id := 5;
            Src.Opt := i;
            Src.Txt := 'src';
            Observer.Observe('opt' + Format(i), Outcome(TryOptToEnum(Dest, Src, false)));
            Observer.Observe('opt' + Format(i) + '-enum-ordinal', Format(Dest.Opt, 0, 2));
            Observer.Observe('opt' + Format(i) + '-enum-text', Format(Dest.Opt));
        end;
        Observer.Expect('opt0', 'ok');
        Observer.Expect('opt0-enum-ordinal', '0');
        Observer.Expect('opt0-enum-text', 'A');
        Observer.Expect('opt1', 'ok');
        Observer.Expect('opt1-enum-ordinal', '1');
        Observer.Expect('opt1-enum-text', 'B');
        Observer.Expect('opt2', 'ok');
        Observer.Expect('opt2-enum-ordinal', '2');
        Observer.Expect('opt2-enum-text', 'C');
        Observer.Expect('opt3', 'ok');
        Observer.Expect('opt3-enum-ordinal', '3');
        Observer.Expect('opt3-enum-text', 'D');
        Observer.Expect('opt4', 'ok');
        Observer.Expect('opt4-enum-ordinal', '4');
        Observer.Expect('opt4-enum-text', 'E');
        Observer.Expect('opt5', 'ok');
        Observer.Expect('opt5-enum-ordinal', '5');
        Observer.Expect('opt5-enum-text', '5');
        Observer.Expect('opt6', 'ok');
        Observer.Expect('opt6-enum-ordinal', '6');
        Observer.Expect('opt6-enum-text', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_To_Option_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT P68 X1";
        Dest: Record "LT P68 X2";
        Ordinals: List of [Integer];
        i: Integer;
    begin
        Ordinals.Add(0);
        Ordinals.Add(1);
        Ordinals.Add(2);
        Ordinals.Add(3);
        Ordinals.Add(4);
        Ordinals.Add(100);
        foreach i in Ordinals do begin
            Clear(Dest);
            Src.Init();
            Src.Id := 6;
            Src.Opt := "LT P68 Kind".FromInteger(i);
            Src.Txt := 'src';
            Observer.Observe('enum' + Format(i), Outcome(TryEnumToOpt(Dest, Src, false)));
            Observer.Observe('enum' + Format(i) + '-opt-ordinal', Format(Dest.Opt, 0, 2));
            Observer.Observe('enum' + Format(i) + '-opt-text', Format(Dest.Opt));
        end;
        Observer.Expect('enum0', 'ok');
        Observer.Expect('enum0-opt-ordinal', '0');
        Observer.Expect('enum0-opt-text', 'O0');
        Observer.Expect('enum1', 'ok');
        Observer.Expect('enum1-opt-ordinal', '1');
        Observer.Expect('enum1-opt-text', 'O1');
        Observer.Expect('enum2', 'ok');
        Observer.Expect('enum2-opt-ordinal', '2');
        Observer.Expect('enum2-opt-text', 'O2');
        Observer.Expect('enum3', 'ok');
        Observer.Expect('enum3-opt-ordinal', '3');
        Observer.Expect('enum3-opt-text', 'O3');
        Observer.Expect('enum4', 'ok');
        Observer.Expect('enum4-opt-ordinal', '4');
        Observer.Expect('enum4-opt-text', 'O4');
        Observer.Expect('enum100', 'ok');
        Observer.Expect('enum100-opt-ordinal', '100');
        Observer.Expect('enum100-opt-text', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Other_Fields_And_Key_Transfer()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT P68 X2";
        Dest: Record "LT P68 X1";
    begin
        Src.Id := 5;
        Src.Opt := 2;
        Src.Txt := 'payload';
        Dest.Id := 99;
        Dest.Txt := 'old';
        Observer.Observe('init-false', Outcome(TryOptToEnum(Dest, Src, false)));
        Observer.Observe('id-after-false', Format(Dest.Id));
        Observer.Observe('txt-after-false', Dest.Txt);
        Observer.Observe('enum-after-false', Format(Dest.Opt, 0, 2));
        Observer.Observe('init-true', Outcome(TryOptToEnum(Dest, Src, true)));
        Observer.Observe('id-after-true', Format(Dest.Id));
        Observer.Observe('txt-after-true', Dest.Txt);
        Observer.Observe('enum-after-true', Format(Dest.Opt, 0, 2));
        Observer.Expect('init-false', 'ok');
        Observer.Expect('id-after-false', '99');
        Observer.Expect('txt-after-false', 'payload');
        Observer.Expect('enum-after-false', '2');
        Observer.Expect('init-true', 'ok');
        Observer.Expect('id-after-true', '5');
        Observer.Expect('txt-after-true', 'payload');
        Observer.Expect('enum-after-true', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_Fields_Not_Matching_Type()
    var
        Observer: Codeunit "Probe Observer";
        S2: Record "LT P68 X2";
        D1: Record "LT P68 X1";
        S1: Record "LT P68 X1";
        D2: Record "LT P68 X2";
    begin
        S2.Opt := 3;
        S2.Txt := 'o3';
        D1.Opt := D1.Opt::E;
        D1.Txt := 'keep';
        Observer.Observe('opt-to-enum-skip', Outcome(TryOptToEnumSkip(D1, S2)));
        Observer.Observe('enum-after', Format(D1.Opt, 0, 2));
        Observer.Observe('txt-after', D1.Txt);
        S1.Opt := S1.Opt::D;
        S1.Txt := 'e3';
        D2.Opt := 6;
        D2.Txt := 'keep';
        Observer.Observe('enum-to-opt-skip', Outcome(TryEnumToOptSkip(D2, S1)));
        Observer.Observe('opt-after', Format(D2.Opt, 0, 2));
        Observer.Observe('txt-after2', D2.Txt);
        Observer.Expect('opt-to-enum-skip', 'ok');
        Observer.Expect('enum-after', '3');
        Observer.Expect('txt-after', 'o3');
        Observer.Expect('enum-to-opt-skip', 'ok');
        Observer.Expect('opt-after', '3');
        Observer.Expect('txt-after2', 'e3');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Trip_And_Stored_Row()
    var
        Observer: Codeunit "Probe Observer";
        S2: Record "LT P68 X2";
        D1: Record "LT P68 X1";
        Back: Record "LT P68 X2";
    begin
        D1.DeleteAll();
        S2.Id := 1;
        S2.Opt := 4;
        S2.Txt := 'rt';
        D1.TransferFields(S2);
        D1.Insert();
        Clear(D1);
        D1.Get(1);
        Observer.Observe('stored-enum', Format(D1.Opt, 0, 2));
        Observer.Observe('stored-enum-text', Format(D1.Opt));
        Back.TransferFields(D1);
        Observer.Observe('back-opt', Format(Back.Opt, 0, 2));
        Observer.Observe('back-opt-text', Format(Back.Opt));
        Observer.Expect('stored-enum', '4');
        Observer.Expect('stored-enum-text', 'E');
        Observer.Expect('back-opt', '4');
        Observer.Expect('back-opt-text', 'O4');
        Observer.Verify();
    end;

    // ---- Added by writer bs (corpus issue #668, item 76): table 83157 "LT BS Opt Row" (Option with 6 members M0..M5) in
    //      tableextension/lt-bs-tableext-leads/BsObjects.al. `Rec.Opt := 16` compiles (runtimes 16.1, 17.1, 18.0). ----

    [TryFunction]
    local procedure BsTrySetFilter(var Row: Record "LT BS Opt Row"; Filter: Text)
    begin
        Row.SetFilter(Opt, Filter);
    end;

    [TryFunction]
    local procedure BsTryValidate(var Row: Record "LT BS Opt Row"; Value: Integer)
    begin
        Row.Validate(Opt, Value);
    end;

    [TryFunction]
    local procedure BsTryEvaluate(var Row: Record "LT BS Opt Row"; Value: Text)
    begin
        Evaluate(Row.Opt, Value);
    end;

    local procedure BsInsert(Id: Integer; Value: Integer)
    var
        Row: Record "LT BS Opt Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Opt := Value;
        Row.Insert();
    end;

    [Test]
    procedure OptionField_OrdinalNotAMember_AssignStoreAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BS Opt Row";
    begin
        Row.DeleteAll();
        BsInsert(1, 2);
        BsInsert(2, 5);
        BsInsert(3, 16);
        Row.Get(3);
        Observer.Observe('stored_16_format', Format(Row.Opt));
        Observer.Observe('stored_16_ordinal', Format(Row.Opt, 0, 2));
        Row.Reset();
        Row.SetRange(Opt, 16);
        Observer.Observe('setrange_16_count', Format(Row.Count()));
        Observer.Observe('setrange_16_getfilter', Row.GetFilter(Opt));
        Row.SetRange(Opt, 6);
        Observer.Observe('setrange_6_count', Format(Row.Count()));
        Row.SetRange(Opt, 2, 16);
        Observer.Observe('setrange_2_16_count', Format(Row.Count()));
        Observer.Observe('setrange_2_16_getfilter', Row.GetFilter(Opt));
        Row.Reset();
        Observer.Observe('setfilter_16', Outcome(BsTrySetFilter(Row, '16')));
        Observer.Observe('setfilter_16_count', Format(Row.Count()));
        Observer.Observe('setfilter_16_getfilter', Row.GetFilter(Opt));
        Row.Reset();
        Observer.Observe('setfilter_m5_or_16', Outcome(BsTrySetFilter(Row, 'M5|16')));
        Observer.Observe('setfilter_m5_or_16_count', Format(Row.Count()));
        Row.Reset();
        Observer.Observe('setfilter_name_unknown', Outcome(BsTrySetFilter(Row, 'M9')));
        Row.DeleteAll();
        Observer.Expect('stored_16_format', '16');
        Observer.Expect('stored_16_ordinal', '16');
        Observer.Expect('setrange_16_count', '1');
        Observer.Expect('setrange_16_getfilter', '16');
        Observer.Expect('setrange_6_count', '0');
        Observer.Expect('setrange_2_16_count', '3');
        Observer.Expect('setrange_2_16_getfilter', 'M2..16');
        Observer.Expect('setfilter_16', 'ok');
        Observer.Expect('setfilter_16_count', '1');
        Observer.Expect('setfilter_16_getfilter', '16');
        Observer.Expect('setfilter_m5_or_16', 'ok');
        Observer.Expect('setfilter_m5_or_16_count', '2');
        Observer.Expect('setfilter_name_unknown', 'error:The filter "M9" is not valid for the Opt field on the LT BS Opt Row table. ''M9'' is not an option. The existing options are: M0,M1,M2,M3,M4,M5|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure OptionField_OrdinalNotAMember_ValidateAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BS Opt Row";
    begin
        Row.Init();
        Observer.Observe('validate_16', Outcome(BsTryValidate(Row, 16)));
        Observer.Observe('validate_16_value', Format(Row.Opt, 0, 2));
        Row.Init();
        Observer.Observe('validate_minus_1', Outcome(BsTryValidate(Row, -1)));
        Observer.Observe('validate_minus_1_value', Format(Row.Opt, 0, 2));
        Row.Init();
        Observer.Observe('evaluate_16', Outcome(BsTryEvaluate(Row, '16')));
        Observer.Observe('evaluate_16_value', Format(Row.Opt, 0, 2));
        Row.Init();
        Observer.Observe('evaluate_6', Outcome(BsTryEvaluate(Row, '6')));
        Observer.Observe('evaluate_6_value', Format(Row.Opt, 0, 2));
        Row.Init();
        Observer.Observe('evaluate_name_unknown', Outcome(BsTryEvaluate(Row, 'M9')));
        Observer.Expect('validate_16', 'ok');
        Observer.Expect('validate_16_value', '16');
        Observer.Expect('validate_minus_1', 'ok');
        Observer.Expect('validate_minus_1_value', '-1');
        Observer.Expect('evaluate_16', 'ok');
        Observer.Expect('evaluate_16_value', '16');
        Observer.Expect('evaluate_6', 'ok');
        Observer.Expect('evaluate_6_value', '6');
        Observer.Expect('evaluate_name_unknown', 'error:''M9'' is not an option. The existing options are: M0,M1,M2,M3,M4,M5|InvalidOptionString');
        Observer.Verify();
    end;
}
