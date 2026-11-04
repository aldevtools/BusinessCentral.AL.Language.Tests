// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enum 72680, tables 72681 and 72682, test codeunit 72683 (P85)
// Probe: written against BC 29 (P85); the facts are measured later on a local BC 29 service tier.
// Facts: Enum to Option and Integer through a Variant, an ordinal beyond the Option members, SetRange / SetFilter / FlowField filter comparing an Option column with an Enum field
// BC versions: 29

enum 72680 "LT P85 Color"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { }
    value(5; Blue) { }
    value(100; Big) { }
}

table 72682 "LT P85 Detail"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Zero,One,Two,Three,Four,Five; }
        field(3; Col; Enum "LT P85 Color") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 72681 "LT P85 Main"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Col; Enum "LT P85 Color") { }
        field(3; Opt; Option) { OptionMembers = Zero,One,Two,Three,Four,Five; }
        field(4; Num; Integer) { }
        field(5; CntByCol; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P85 Detail" where(Opt = field(Col)));
            Editable = false;
        }
        field(6; CntByOpt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P85 Detail" where(Col = field(Opt)));
            Editable = false;
        }
        field(7; CntConst; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P85 Detail" where(Opt = const(Five)));
            Editable = false;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72683 "LT P85 Enum Option Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OptA: Option Zero,One,Two;

    [TryFunction]
    local procedure TryToOption(V: Variant; var Opt: Option Zero,One,Two)
    begin
        Opt := V;
    end;

    [TryFunction]
    local procedure TryToInt(V: Variant; var I: Integer)
    begin
        I := V;
    end;

    [TryFunction]
    local procedure TryToDec(V: Variant; var D: Decimal)
    begin
        D := V;
    end;

    [TryFunction]
    local procedure TryToText(V: Variant; var T: Text)
    begin
        T := V;
    end;

    local procedure OptOutcome(V: Variant): Text
    var
        O: Option Zero,One,Two;
    begin
        if TryToOption(V, O) then
            exit('ok:' + Format(O) + ':' + Format(O, 0, 2));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure IntOutcome(V: Variant): Text
    var
        I: Integer;
    begin
        if TryToInt(V, I) then
            exit('ok:' + Format(I));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure DecOutcome(V: Variant): Text
    var
        D: Decimal;
    begin
        if TryToDec(V, D) then
            exit('ok:' + Format(D));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TextOutcome(V: Variant): Text
    var
        T: Text;
    begin
        if TryToText(V, T) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure EnumVariant_To_Option()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P85 Color";
        V: Variant;
    begin
        E := E::Red;
        V := E;
        Observer.Observe('red', OptOutcome(V));
        E := E::Green;
        V := E;
        Observer.Observe('green', OptOutcome(V));
        E := E::Blue;
        V := E;
        Observer.Observe('blue_5', OptOutcome(V));
        E := E::Big;
        V := E;
        Observer.Observe('big_100', OptOutcome(V));
        Observer.Observe('is_option', Format(V.IsOption()));
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Observer.Expect('red', 'ok:Zero:0');
        Observer.Expect('green', 'ok:One:1');
        Observer.Expect('blue_5', 'ok:5:5');
        Observer.Expect('big_100', 'ok:100:100');
        Observer.Expect('is_option', 'Yes');
        Observer.Expect('is_integer', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure EnumVariant_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P85 Color";
        V: Variant;
    begin
        E := E::Red;
        V := E;
        Observer.Observe('red', IntOutcome(V));
        E := E::Green;
        V := E;
        Observer.Observe('green', IntOutcome(V));
        E := E::Blue;
        V := E;
        Observer.Observe('blue', IntOutcome(V));
        E := E::Big;
        V := E;
        Observer.Observe('big', IntOutcome(V));
        Observer.Observe('dec_big', DecOutcome(V));
        Observer.Observe('text_big', TextOutcome(V));
        Observer.Expect('red', 'ok:0');
        Observer.Expect('green', 'ok:1');
        Observer.Expect('blue', 'ok:5');
        Observer.Expect('big', 'ok:100');
        Observer.Expect('dec_big', 'ok:100');
        Observer.Expect('text_big', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.|TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure EnumVariant_DirectAssign_Option_Integer()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT P85 Color";
        V: Variant;
        I: Integer;
        O: Option Zero,One,Two;
    begin
        E := E::Green;
        V := E;
        O := V;
        I := V;
        Observer.Observe('opt_green', Format(O) + '|' + Format(O, 0, 2));
        Observer.Observe('int_green', Format(I));
        Observer.Expect('opt_green', 'One|1');
        Observer.Expect('int_green', '1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionVariant_To_Enum_Integer()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        E: Enum "LT P85 Color";
        I: Integer;
        O: Option Zero,One,Two;
    begin
        O := O::Two;
        V := O;
        I := V;
        Observer.Observe('opt_to_int', Format(I));
        V := 5;
        O := V;
        Observer.Observe('int5_to_option', Format(O, 0, 2));
        Observer.Expect('opt_to_int', '2');
        Observer.Expect('int5_to_option', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Table_OptionFieldFromEnumField()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT P85 Main";
        V: Variant;
    begin
        M.DeleteAll();
        M.Init();
        M.Id := 1;
        M.Col := M.Col::Blue;
        V := M.Col;
        M.Opt := V;
        Observer.Observe('opt_from_blue', Format(M.Opt, 0, 2));
        M.Col := M.Col::Big;
        V := M.Col;
        M.Num := V;
        Observer.Observe('num_from_big', Format(M.Num));
        M.Opt := M.Opt::Five;
        V := M.Opt;
        M.Col := M.Col::Green;
        M.Opt := M.Col;
        Observer.Observe('direct_opt_from_enum', Format(M.Opt, 0, 2));
        Observer.Expect('opt_from_blue', '5');
        Observer.Expect('num_from_big', '100');
        Observer.Expect('direct_opt_from_enum', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_OptionColumn_SetRange_EnumValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Record "LT P85 Detail";
        M: Record "LT P85 Main";
        i: Integer;
    begin
        D.DeleteAll();
        for i := 0 to 5 do begin
            D.Init();
            D.Id := i + 1;
            D.Opt := i;
            D.Insert();
        end;
        M.Col := M.Col::Green;
        D.SetRange(Opt, M.Col);
        Observer.Observe('range_green_count', Format(D.Count()));
        Observer.Observe('range_green_filter', D.GetFilter(Opt));
        M.Col := M.Col::Blue;
        D.SetRange(Opt, M.Col);
        Observer.Observe('range_blue_count', Format(D.Count()));
        Observer.Observe('range_blue_filter', D.GetFilter(Opt));
        M.Col := M.Col::Big;
        D.SetRange(Opt, M.Col);
        Observer.Observe('range_big_count', Format(D.Count()));
        Observer.Observe('range_big_filter', D.GetFilter(Opt));
        D.SetFilter(Opt, '%1', M.Col::Green);
        Observer.Observe('filter_green_count', Format(D.Count()));
        Observer.Observe('filter_green_filter', D.GetFilter(Opt));
        Observer.Expect('range_green_count', '1');
        Observer.Expect('range_green_filter', 'One');
        Observer.Expect('range_blue_count', '1');
        Observer.Expect('range_blue_filter', 'Five');
        Observer.Expect('range_big_count', '0');
        Observer.Expect('range_big_filter', '100');
        Observer.Expect('filter_green_count', '1');
        Observer.Expect('filter_green_filter', 'Green');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_EnumColumn_SetRange_OptionValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Record "LT P85 Detail";
        M: Record "LT P85 Main";
        i: Integer;
    begin
        D.DeleteAll();
        D.Init();
        D.Id := 1;
        D.Col := D.Col::Green;
        D.Insert();
        D.Id := 2;
        D.Col := D.Col::Blue;
        D.Insert();
        D.Id := 3;
        D.Col := D.Col::Red;
        D.Insert();
        M.Opt := M.Opt::One;
        D.SetRange(Col, M.Opt);
        Observer.Observe('range_one_count', Format(D.Count()));
        Observer.Observe('range_one_filter', D.GetFilter(Col));
        M.Opt := M.Opt::Five;
        D.SetRange(Col, M.Opt);
        Observer.Observe('range_five_count', Format(D.Count()));
        Observer.Observe('range_five_filter', D.GetFilter(Col));
        Observer.Expect('range_one_count', '1');
        Observer.Expect('range_one_filter', 'Green');
        Observer.Expect('range_five_count', '1');
        Observer.Expect('range_five_filter', 'Blue');
        Observer.Verify();
    end;

    [Test]
    procedure FlowField_OptionColumn_EqualsEnumField()
    var
        Observer: Codeunit "Probe Observer";
        D: Record "LT P85 Detail";
        M: Record "LT P85 Main";
        i: Integer;
    begin
        D.DeleteAll();
        M.DeleteAll();
        for i := 0 to 5 do begin
            D.Init();
            D.Id := i + 1;
            D.Opt := i;
            D.Insert();
        end;
        D.Init();
        D.Id := 20;
        D.Opt := 1;
        D.Insert();
        M.Init();
        M.Id := 1;
        M.Col := M.Col::Green;
        M.Opt := M.Opt::One;
        M.Insert();
        M.Id := 2;
        M.Col := M.Col::Blue;
        M.Opt := M.Opt::Five;
        M.Insert();
        M.Id := 3;
        M.Col := M.Col::Big;
        M.Opt := M.Opt::Zero;
        M.Insert();
        M.Id := 4;
        M.Col := M.Col::Red;
        M.Opt := M.Opt::Zero;
        M.Insert();
        for i := 1 to 4 do begin
            M.Get(i);
            M.CalcFields(CntByCol, CntConst);
            Observer.Observe('bycol_' + Format(i), Format(M.CntByCol));
        end;
        Observer.Observe('const_five', Format(M.CntConst));
        Observer.Expect('bycol_1', '2');
        Observer.Expect('bycol_2', '1');
        Observer.Expect('bycol_3', '0');
        Observer.Expect('bycol_4', '1');
        Observer.Expect('const_five', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FlowField_EnumColumn_EqualsOptionField()
    var
        Observer: Codeunit "Probe Observer";
        D: Record "LT P85 Detail";
        M: Record "LT P85 Main";
        i: Integer;
    begin
        D.DeleteAll();
        M.DeleteAll();
        D.Init();
        D.Id := 1;
        D.Col := D.Col::Green;
        D.Insert();
        D.Id := 2;
        D.Col := D.Col::Blue;
        D.Insert();
        D.Id := 3;
        D.Col := D.Col::Green;
        D.Insert();
        M.Init();
        M.Id := 1;
        M.Opt := M.Opt::One;
        M.Insert();
        M.Id := 2;
        M.Opt := M.Opt::Five;
        M.Insert();
        M.Id := 3;
        M.Opt := M.Opt::Two;
        M.Insert();
        for i := 1 to 3 do begin
            M.Get(i);
            M.CalcFields(CntByOpt);
            Observer.Observe('byopt_' + Format(i), Format(M.CntByOpt));
        end;
        Observer.Expect('byopt_1', '2');
        Observer.Expect('byopt_2', '1');
        Observer.Expect('byopt_3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_FlowField_And_Compare()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT P85 Main";
        D: Record "LT P85 Detail";
    begin
        D.DeleteAll();
        M.DeleteAll();
        D.Init();
        D.Id := 1;
        D.Opt := 5;
        D.Insert();
        M.Init();
        M.Id := 1;
        M.Col := M.Col::Blue;
        M.Insert();
        M.Id := 2;
        M.Col := M.Col::Green;
        M.Insert();
        M.SetRange(CntByCol, 1);
        Observer.Observe('flow_filter_count', Format(M.Count()));
        M.SetRange(CntByCol);
        M.SetRange(Col, M.Col::Blue);
        Observer.Observe('col_filter', M.GetFilter(Col) + '|' + Format(M.Count()));
        Observer.Observe('opt_eq_enum_ordinal', Format(M.Opt = M.Col));
        Observer.Expect('flow_filter_count', '1');
        Observer.Expect('col_filter', 'Blue|1');
        Observer.Expect('opt_eq_enum_ordinal', 'No');
        Observer.Verify();
    end;
}
