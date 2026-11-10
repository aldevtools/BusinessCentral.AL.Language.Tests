// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM SumAvg *)
// local object: the CalcFormula definitions are what the tests measure.
// Area: FlowField and FlowFilter matrix, CalcFormula kinds sum, -sum, average, -average crossed with the where-clause forms (const, field, filter,
//   field(filter(F)) over Integer, Decimal, Date, Code, Option, Enum and Text FlowFilters, field(upperlimit(F)), field(upperlimit(filter(F))))
//   and the two states of every FlowFilter (not set, set), read with CalcFields on a record with rows, and on a record with no match.
//   The shapes BC rejects at compile time are pinned in tests/must-not-compile/cases (upperlimit outside field()).
// Nearby: record/flowfields/Y17SumWhereFlowField.al, record/flowfields/CalcFormulaDateLiteral.al, TestCalcFormulaFlowFiltersTests.Codeunit.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

enum 64100 "FFM SumAvg Status"
{
    Extensible = true;
    value(0; Open) { }
    value(1; Closed) { }
    value(2; Held) { }
}

table 64101 "FFM SumAvg Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Qty; Integer) { }
        field(4; Amt; Decimal) { }
        field(5; Day; Date) { }
        field(6; Kind; Code[10]) { }
        field(7; Opt; Option) { OptionMembers = A,B,C; }
        field(8; Status; Enum "FFM SumAvg Status") { }
        field(9; Flag; Boolean) { }
        field(10; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64102 "FFM SumAvg Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; IntF; Integer) { FieldClass = FlowFilter; }
        field(3; DecF; Decimal) { FieldClass = FlowFilter; }
        field(4; DateF; Date) { FieldClass = FlowFilter; }
        field(5; CodeF; Code[10]) { FieldClass = FlowFilter; }
        field(6; OptF; Option) { OptionMembers = A,B,C; FieldClass = FlowFilter; }
        field(7; EnumF; Enum "FFM SumAvg Status") { FieldClass = FlowFilter; }
        field(8; TextF; Text[30]) { FieldClass = FlowFilter; }
        field(100; Sum_const; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Kind = const('K1'))); }
        field(101; Sum_field; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Owner = field(Code))); }
        field(102; Sum_filter; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Qty = filter(2..5))); }
        field(103; Sum_constopt; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Opt = const(B))); }
        field(104; Sum_constenum; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Status = const(Closed))); }
        field(105; Sum_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Status = filter(Open|Held))); }
        field(106; Sum_ffint; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Qty = field(filter(IntF)))); }
        field(107; Sum_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Amt = field(filter(DecF)))); }
        field(108; Sum_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Day = field(filter(DateF)))); }
        field(109; Sum_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(110; Sum_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Opt = field(filter(OptF)))); }
        field(111; Sum_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Status = field(filter(EnumF)))); }
        field(112; Sum_fftext; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Name = field(filter(TextF)))); }
        field(113; Sum_uldate; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(114; Sum_ulint; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(115; Sum_uldec; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(116; Sum_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(117; Sum_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(118; Sum_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(119; Sum_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(120; Sum_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Qty = field(filter(DateF)))); }
        field(121; Sum_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = sum("FFM SumAvg Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(122; NSum_const; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Kind = const('K1'))); }
        field(123; NSum_field; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Owner = field(Code))); }
        field(124; NSum_filter; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Qty = filter(2..5))); }
        field(125; NSum_constopt; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Opt = const(B))); }
        field(126; NSum_constenum; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Status = const(Closed))); }
        field(127; NSum_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Status = filter(Open|Held))); }
        field(128; NSum_ffint; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Qty = field(filter(IntF)))); }
        field(129; NSum_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Amt = field(filter(DecF)))); }
        field(130; NSum_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Day = field(filter(DateF)))); }
        field(131; NSum_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(132; NSum_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Opt = field(filter(OptF)))); }
        field(133; NSum_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Status = field(filter(EnumF)))); }
        field(134; NSum_fftext; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Name = field(filter(TextF)))); }
        field(135; NSum_uldate; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(136; NSum_ulint; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(137; NSum_uldec; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(138; NSum_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(139; NSum_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(140; NSum_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(141; NSum_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(142; NSum_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Qty = field(filter(DateF)))); }
        field(143; NSum_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = -sum("FFM SumAvg Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(144; Avg_const; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Kind = const('K1'))); }
        field(145; Avg_field; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Owner = field(Code))); }
        field(146; Avg_filter; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Qty = filter(2..5))); }
        field(147; Avg_constopt; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Opt = const(B))); }
        field(148; Avg_constenum; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Status = const(Closed))); }
        field(149; Avg_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Status = filter(Open|Held))); }
        field(150; Avg_ffint; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Qty = field(filter(IntF)))); }
        field(151; Avg_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Amt = field(filter(DecF)))); }
        field(152; Avg_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Day = field(filter(DateF)))); }
        field(153; Avg_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(154; Avg_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Opt = field(filter(OptF)))); }
        field(155; Avg_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Status = field(filter(EnumF)))); }
        field(156; Avg_fftext; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Name = field(filter(TextF)))); }
        field(157; Avg_uldate; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(158; Avg_ulint; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(159; Avg_uldec; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(160; Avg_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(161; Avg_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(162; Avg_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(163; Avg_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(164; Avg_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Qty = field(filter(DateF)))); }
        field(165; Avg_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = average("FFM SumAvg Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(166; NAvg_const; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Kind = const('K1'))); }
        field(167; NAvg_field; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Owner = field(Code))); }
        field(168; NAvg_filter; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Qty = filter(2..5))); }
        field(169; NAvg_constopt; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Opt = const(B))); }
        field(170; NAvg_constenum; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Status = const(Closed))); }
        field(171; NAvg_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Status = filter(Open|Held))); }
        field(172; NAvg_ffint; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Qty = field(filter(IntF)))); }
        field(173; NAvg_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Amt = field(filter(DecF)))); }
        field(174; NAvg_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Day = field(filter(DateF)))); }
        field(175; NAvg_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(176; NAvg_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Opt = field(filter(OptF)))); }
        field(177; NAvg_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Status = field(filter(EnumF)))); }
        field(178; NAvg_fftext; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Name = field(filter(TextF)))); }
        field(179; NAvg_uldate; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(180; NAvg_ulint; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(181; NAvg_uldec; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(182; NAvg_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(183; NAvg_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(184; NAvg_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(185; NAvg_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(186; NAvg_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Qty = field(filter(DateF)))); }
        field(187; NAvg_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = -average("FFM SumAvg Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 64103 "FFM SumAvg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryCalc_Sum_const(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_const);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_field(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_field);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_filter(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_constopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_constenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_filterenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffdec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_fftext(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_uldate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ulint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_uldec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ulcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ulopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ulenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ulfdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffmismatch(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Sum_ffboth(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Sum_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_const(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_const);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_field(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_field);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_filter(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_constopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_constenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_filterenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffdec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_fftext(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_uldate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ulint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_uldec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ulcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ulopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ulenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ulfdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffmismatch(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NSum_ffboth(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NSum_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_const(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_const);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_field(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_field);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_filter(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_constopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_constenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_filterenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffdec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_fftext(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_uldate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ulint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_uldec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ulcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ulopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ulenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ulfdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffmismatch(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Avg_ffboth(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(Avg_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_const(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_const);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_field(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_field);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_filter(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_constopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_constenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_filterenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffdec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_fftext(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_uldate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ulint(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_uldec(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ulcode(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ulopt(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ulenum(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ulfdate(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffmismatch(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NAvg_ffboth(var H: Record "FFM SumAvg Header")
    begin
        H.CalcFields(NAvg_ffboth);
    end;

    [Test]
    procedure FlowFieldSum_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldSum with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Sum_const(H) then
            Observer.ObserveError('Sum_const.calc1');
        Observer.Observe('H1.const', Format(H.Sum_const));
        if not TryCalc_Sum_field(H) then
            Observer.ObserveError('Sum_field.calc2');
        Observer.Observe('H1.field', Format(H.Sum_field));
        if not TryCalc_Sum_filter(H) then
            Observer.ObserveError('Sum_filter.calc3');
        Observer.Observe('H1.filter', Format(H.Sum_filter));
        if not TryCalc_Sum_constopt(H) then
            Observer.ObserveError('Sum_constopt.calc4');
        Observer.Observe('H1.constopt', Format(H.Sum_constopt));
        if not TryCalc_Sum_constenum(H) then
            Observer.ObserveError('Sum_constenum.calc5');
        Observer.Observe('H1.constenum', Format(H.Sum_constenum));
        if not TryCalc_Sum_filterenum(H) then
            Observer.ObserveError('Sum_filterenum.calc6');
        Observer.Observe('H1.filterenum', Format(H.Sum_filterenum));
        H.Get('H2');
        if not TryCalc_Sum_const(H) then
            Observer.ObserveError('Sum_const.calc7');
        Observer.Observe('H2.const', Format(H.Sum_const));
        if not TryCalc_Sum_field(H) then
            Observer.ObserveError('Sum_field.calc8');
        Observer.Observe('H2.field', Format(H.Sum_field));
        if not TryCalc_Sum_filter(H) then
            Observer.ObserveError('Sum_filter.calc9');
        Observer.Observe('H2.filter', Format(H.Sum_filter));
        if not TryCalc_Sum_constopt(H) then
            Observer.ObserveError('Sum_constopt.calc10');
        Observer.Observe('H2.constopt', Format(H.Sum_constopt));
        if not TryCalc_Sum_constenum(H) then
            Observer.ObserveError('Sum_constenum.calc11');
        Observer.Observe('H2.constenum', Format(H.Sum_constenum));
        if not TryCalc_Sum_filterenum(H) then
            Observer.ObserveError('Sum_filterenum.calc12');
        Observer.Observe('H2.filterenum', Format(H.Sum_filterenum));
        H.Get('H3');
        if not TryCalc_Sum_const(H) then
            Observer.ObserveError('Sum_const.calc13');
        Observer.Observe('H3.const', Format(H.Sum_const));
        if not TryCalc_Sum_field(H) then
            Observer.ObserveError('Sum_field.calc14');
        Observer.Observe('H3.field', Format(H.Sum_field));
        if not TryCalc_Sum_filter(H) then
            Observer.ObserveError('Sum_filter.calc15');
        Observer.Observe('H3.filter', Format(H.Sum_filter));
        if not TryCalc_Sum_constopt(H) then
            Observer.ObserveError('Sum_constopt.calc16');
        Observer.Observe('H3.constopt', Format(H.Sum_constopt));
        if not TryCalc_Sum_constenum(H) then
            Observer.ObserveError('Sum_constenum.calc17');
        Observer.Observe('H3.constenum', Format(H.Sum_constenum));
        if not TryCalc_Sum_filterenum(H) then
            Observer.ObserveError('Sum_filterenum.calc18');
        Observer.Observe('H3.filterenum', Format(H.Sum_filterenum));
        Observer.Expect('H1.const', '57.75');
        Observer.Expect('H1.field', '150.75');
        Observer.Expect('H1.filter', '81.25');
        Observer.Expect('H1.constopt', '90.5');
        Observer.Expect('H1.constenum', '27');
        Observer.Expect('H1.filterenum', '144.75');
        Observer.Expect('H2.const', '57.75');
        Observer.Expect('H2.field', '21');
        Observer.Expect('H2.filter', '81.25');
        Observer.Expect('H2.constopt', '90.5');
        Observer.Expect('H2.constenum', '27');
        Observer.Expect('H2.filterenum', '144.75');
        Observer.Expect('H3.const', '57.75');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '81.25');
        Observer.Expect('H3.constopt', '90.5');
        Observer.Expect('H3.constenum', '27');
        Observer.Expect('H3.filterenum', '144.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSum_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldSum with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Sum_ffint(H) then
            Observer.ObserveError('Sum_ffint.calc19');
        Observer.Observe('ffint.unset', Format(H.Sum_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Sum_ffint(H) then
            Observer.ObserveError('Sum_ffint.calc20');
        Observer.Observe('ffint.set', Format(H.Sum_ffint));
        H.Reset();
        if not TryCalc_Sum_ffdec(H) then
            Observer.ObserveError('Sum_ffdec.calc21');
        Observer.Observe('ffdec.unset', Format(H.Sum_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Sum_ffdec(H) then
            Observer.ObserveError('Sum_ffdec.calc22');
        Observer.Observe('ffdec.set', Format(H.Sum_ffdec));
        H.Reset();
        if not TryCalc_Sum_ffdate(H) then
            Observer.ObserveError('Sum_ffdate.calc23');
        Observer.Observe('ffdate.unset', Format(H.Sum_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Sum_ffdate(H) then
            Observer.ObserveError('Sum_ffdate.calc24');
        Observer.Observe('ffdate.set', Format(H.Sum_ffdate));
        H.Reset();
        if not TryCalc_Sum_ffcode(H) then
            Observer.ObserveError('Sum_ffcode.calc25');
        Observer.Observe('ffcode.unset', Format(H.Sum_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Sum_ffcode(H) then
            Observer.ObserveError('Sum_ffcode.calc26');
        Observer.Observe('ffcode.set', Format(H.Sum_ffcode));
        H.Reset();
        if not TryCalc_Sum_ffopt(H) then
            Observer.ObserveError('Sum_ffopt.calc27');
        Observer.Observe('ffopt.unset', Format(H.Sum_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Sum_ffopt(H) then
            Observer.ObserveError('Sum_ffopt.calc28');
        Observer.Observe('ffopt.set', Format(H.Sum_ffopt));
        H.Reset();
        if not TryCalc_Sum_ffenum(H) then
            Observer.ObserveError('Sum_ffenum.calc29');
        Observer.Observe('ffenum.unset', Format(H.Sum_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Sum_ffenum(H) then
            Observer.ObserveError('Sum_ffenum.calc30');
        Observer.Observe('ffenum.set', Format(H.Sum_ffenum));
        H.Reset();
        if not TryCalc_Sum_fftext(H) then
            Observer.ObserveError('Sum_fftext.calc31');
        Observer.Observe('fftext.unset', Format(H.Sum_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Sum_fftext(H) then
            Observer.ObserveError('Sum_fftext.calc32');
        Observer.Observe('fftext.set', Format(H.Sum_fftext));
        Observer.Expect('ffint.unset', '171.75');
        Observer.Expect('ffint.set', '74.25');
        Observer.Expect('ffdec.unset', '171.75');
        Observer.Expect('ffdec.set', '154.25');
        Observer.Expect('ffdate.unset', '171.75');
        Observer.Expect('ffdate.set', '140.25');
        Observer.Expect('ffcode.unset', '171.75');
        Observer.Expect('ffcode.set', '57.75');
        Observer.Expect('ffopt.unset', '171.75');
        Observer.Expect('ffopt.set', '90.5');
        Observer.Expect('ffenum.unset', '171.75');
        Observer.Expect('ffenum.set', '81.25');
        Observer.Expect('fftext.unset', '171.75');
        Observer.Expect('fftext.set', '50.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSum_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldSum with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Sum_uldate(H) then
            Observer.ObserveError('Sum_uldate.calc33');
        Observer.Observe('uldate.unset', Format(H.Sum_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Sum_uldate(H) then
            Observer.ObserveError('Sum_uldate.calc34');
        Observer.Observe('uldate.set', Format(H.Sum_uldate));
        H.Reset();
        if not TryCalc_Sum_ulint(H) then
            Observer.ObserveError('Sum_ulint.calc35');
        Observer.Observe('ulint.unset', Format(H.Sum_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Sum_ulint(H) then
            Observer.ObserveError('Sum_ulint.calc36');
        Observer.Observe('ulint.set', Format(H.Sum_ulint));
        H.Reset();
        if not TryCalc_Sum_uldec(H) then
            Observer.ObserveError('Sum_uldec.calc37');
        Observer.Observe('uldec.unset', Format(H.Sum_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Sum_uldec(H) then
            Observer.ObserveError('Sum_uldec.calc38');
        Observer.Observe('uldec.set', Format(H.Sum_uldec));
        H.Reset();
        if not TryCalc_Sum_ulcode(H) then
            Observer.ObserveError('Sum_ulcode.calc39');
        Observer.Observe('ulcode.unset', Format(H.Sum_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Sum_ulcode(H) then
            Observer.ObserveError('Sum_ulcode.calc40');
        Observer.Observe('ulcode.set', Format(H.Sum_ulcode));
        H.Reset();
        if not TryCalc_Sum_ulopt(H) then
            Observer.ObserveError('Sum_ulopt.calc41');
        Observer.Observe('ulopt.unset', Format(H.Sum_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Sum_ulopt(H) then
            Observer.ObserveError('Sum_ulopt.calc42');
        Observer.Observe('ulopt.set', Format(H.Sum_ulopt));
        H.Reset();
        if not TryCalc_Sum_ulenum(H) then
            Observer.ObserveError('Sum_ulenum.calc43');
        Observer.Observe('ulenum.unset', Format(H.Sum_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Sum_ulenum(H) then
            Observer.ObserveError('Sum_ulenum.calc44');
        Observer.Observe('ulenum.set', Format(H.Sum_ulenum));
        H.Reset();
        if not TryCalc_Sum_ulfdate(H) then
            Observer.ObserveError('Sum_ulfdate.calc45');
        Observer.Observe('ulfdate.unset', Format(H.Sum_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Sum_ulfdate(H) then
            Observer.ObserveError('Sum_ulfdate.calc46');
        Observer.Observe('ulfdate.set', Format(H.Sum_ulfdate));
        Observer.Expect('uldate.unset', '171.75');
        Observer.Expect('uldate.set', '157.75');
        Observer.Expect('ulint.unset', '171.75');
        Observer.Expect('ulint.set', '91.75');
        Observer.Expect('uldec.unset', '171.75');
        Observer.Expect('Sum_uldec.calc38|text', 'The filter expression ">=14" applied to the field DecF in the FFM SumAvg Header table results in more than one range.');
        Observer.Expect('Sum_uldec.calc38|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '171.75');
        Observer.Expect('ulcode.unset', '171.75');
        Observer.Expect('ulcode.set', '57.75');
        Observer.Expect('ulopt.unset', '171.75');
        Observer.Expect('ulopt.set', '90.5');
        Observer.Expect('ulenum.unset', '171.75');
        Observer.Expect('ulenum.set', '171.75');
        Observer.Expect('ulfdate.unset', '171.75');
        Observer.Expect('ulfdate.set', '157.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSum_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldSum with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Sum_ffmismatch(H) then
            Observer.ObserveError('Sum_ffmismatch.calc47');
        Observer.Observe('ffmismatch.unset', Format(H.Sum_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Sum_ffmismatch(H) then
            Observer.ObserveError('Sum_ffmismatch.calc48');
        Observer.Observe('ffmismatch.set', Format(H.Sum_ffmismatch));
        H.Reset();
        if not TryCalc_Sum_ffboth(H) then
            Observer.ObserveError('Sum_ffboth.calc49');
        Observer.Observe('ffboth.unset', Format(H.Sum_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Sum_ffboth(H) then
            Observer.ObserveError('Sum_ffboth.calc50');
        Observer.Observe('ffboth.set', Format(H.Sum_ffboth));
        Observer.Expect('ffmismatch.unset', '171.75');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '150.75');
        Observer.Expect('ffboth.set', '60.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldSum_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldSum over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Sum_const(H) then
            Observer.ObserveError('Sum_const.calc51');
        Observer.Observe('const.h3', Format(H.Sum_const));
        if not TryCalc_Sum_field(H) then
            Observer.ObserveError('Sum_field.calc52');
        Observer.Observe('field.h3', Format(H.Sum_field));
        if not TryCalc_Sum_filter(H) then
            Observer.ObserveError('Sum_filter.calc53');
        Observer.Observe('filter.h3', Format(H.Sum_filter));
        if not TryCalc_Sum_constopt(H) then
            Observer.ObserveError('Sum_constopt.calc54');
        Observer.Observe('constopt.h3', Format(H.Sum_constopt));
        if not TryCalc_Sum_constenum(H) then
            Observer.ObserveError('Sum_constenum.calc55');
        Observer.Observe('constenum.h3', Format(H.Sum_constenum));
        if not TryCalc_Sum_filterenum(H) then
            Observer.ObserveError('Sum_filterenum.calc56');
        Observer.Observe('filterenum.h3', Format(H.Sum_filterenum));
        if not TryCalc_Sum_ffint(H) then
            Observer.ObserveError('Sum_ffint.calc57');
        Observer.Observe('ffint.h3', Format(H.Sum_ffint));
        if not TryCalc_Sum_ffdec(H) then
            Observer.ObserveError('Sum_ffdec.calc58');
        Observer.Observe('ffdec.h3', Format(H.Sum_ffdec));
        if not TryCalc_Sum_ffdate(H) then
            Observer.ObserveError('Sum_ffdate.calc59');
        Observer.Observe('ffdate.h3', Format(H.Sum_ffdate));
        if not TryCalc_Sum_ffcode(H) then
            Observer.ObserveError('Sum_ffcode.calc60');
        Observer.Observe('ffcode.h3', Format(H.Sum_ffcode));
        if not TryCalc_Sum_ffopt(H) then
            Observer.ObserveError('Sum_ffopt.calc61');
        Observer.Observe('ffopt.h3', Format(H.Sum_ffopt));
        if not TryCalc_Sum_ffenum(H) then
            Observer.ObserveError('Sum_ffenum.calc62');
        Observer.Observe('ffenum.h3', Format(H.Sum_ffenum));
        if not TryCalc_Sum_fftext(H) then
            Observer.ObserveError('Sum_fftext.calc63');
        Observer.Observe('fftext.h3', Format(H.Sum_fftext));
        if not TryCalc_Sum_uldate(H) then
            Observer.ObserveError('Sum_uldate.calc64');
        Observer.Observe('uldate.h3', Format(H.Sum_uldate));
        if not TryCalc_Sum_ulint(H) then
            Observer.ObserveError('Sum_ulint.calc65');
        Observer.Observe('ulint.h3', Format(H.Sum_ulint));
        if not TryCalc_Sum_uldec(H) then
            Observer.ObserveError('Sum_uldec.calc66');
        Observer.Observe('uldec.h3', Format(H.Sum_uldec));
        if not TryCalc_Sum_ulcode(H) then
            Observer.ObserveError('Sum_ulcode.calc67');
        Observer.Observe('ulcode.h3', Format(H.Sum_ulcode));
        if not TryCalc_Sum_ulopt(H) then
            Observer.ObserveError('Sum_ulopt.calc68');
        Observer.Observe('ulopt.h3', Format(H.Sum_ulopt));
        if not TryCalc_Sum_ulenum(H) then
            Observer.ObserveError('Sum_ulenum.calc69');
        Observer.Observe('ulenum.h3', Format(H.Sum_ulenum));
        if not TryCalc_Sum_ulfdate(H) then
            Observer.ObserveError('Sum_ulfdate.calc70');
        Observer.Observe('ulfdate.h3', Format(H.Sum_ulfdate));
        if not TryCalc_Sum_ffmismatch(H) then
            Observer.ObserveError('Sum_ffmismatch.calc71');
        Observer.Observe('ffmismatch.h3', Format(H.Sum_ffmismatch));
        if not TryCalc_Sum_ffboth(H) then
            Observer.ObserveError('Sum_ffboth.calc72');
        Observer.Observe('ffboth.h3', Format(H.Sum_ffboth));
        Observer.Expect('const.h3', '57.75');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '81.25');
        Observer.Expect('constopt.h3', '90.5');
        Observer.Expect('constenum.h3', '27');
        Observer.Expect('filterenum.h3', '144.75');
        Observer.Expect('ffint.h3', '171.75');
        Observer.Expect('ffdec.h3', '171.75');
        Observer.Expect('ffdate.h3', '171.75');
        Observer.Expect('ffcode.h3', '171.75');
        Observer.Expect('ffopt.h3', '171.75');
        Observer.Expect('ffenum.h3', '171.75');
        Observer.Expect('fftext.h3', '171.75');
        Observer.Expect('uldate.h3', '171.75');
        Observer.Expect('ulint.h3', '171.75');
        Observer.Expect('uldec.h3', '171.75');
        Observer.Expect('ulcode.h3', '171.75');
        Observer.Expect('ulopt.h3', '171.75');
        Observer.Expect('ulenum.h3', '171.75');
        Observer.Expect('ulfdate.h3', '171.75');
        Observer.Expect('ffmismatch.h3', '171.75');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedSum_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedSum with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NSum_const(H) then
            Observer.ObserveError('NSum_const.calc73');
        Observer.Observe('H1.const', Format(H.NSum_const));
        if not TryCalc_NSum_field(H) then
            Observer.ObserveError('NSum_field.calc74');
        Observer.Observe('H1.field', Format(H.NSum_field));
        if not TryCalc_NSum_filter(H) then
            Observer.ObserveError('NSum_filter.calc75');
        Observer.Observe('H1.filter', Format(H.NSum_filter));
        if not TryCalc_NSum_constopt(H) then
            Observer.ObserveError('NSum_constopt.calc76');
        Observer.Observe('H1.constopt', Format(H.NSum_constopt));
        if not TryCalc_NSum_constenum(H) then
            Observer.ObserveError('NSum_constenum.calc77');
        Observer.Observe('H1.constenum', Format(H.NSum_constenum));
        if not TryCalc_NSum_filterenum(H) then
            Observer.ObserveError('NSum_filterenum.calc78');
        Observer.Observe('H1.filterenum', Format(H.NSum_filterenum));
        H.Get('H2');
        if not TryCalc_NSum_const(H) then
            Observer.ObserveError('NSum_const.calc79');
        Observer.Observe('H2.const', Format(H.NSum_const));
        if not TryCalc_NSum_field(H) then
            Observer.ObserveError('NSum_field.calc80');
        Observer.Observe('H2.field', Format(H.NSum_field));
        if not TryCalc_NSum_filter(H) then
            Observer.ObserveError('NSum_filter.calc81');
        Observer.Observe('H2.filter', Format(H.NSum_filter));
        if not TryCalc_NSum_constopt(H) then
            Observer.ObserveError('NSum_constopt.calc82');
        Observer.Observe('H2.constopt', Format(H.NSum_constopt));
        if not TryCalc_NSum_constenum(H) then
            Observer.ObserveError('NSum_constenum.calc83');
        Observer.Observe('H2.constenum', Format(H.NSum_constenum));
        if not TryCalc_NSum_filterenum(H) then
            Observer.ObserveError('NSum_filterenum.calc84');
        Observer.Observe('H2.filterenum', Format(H.NSum_filterenum));
        H.Get('H3');
        if not TryCalc_NSum_const(H) then
            Observer.ObserveError('NSum_const.calc85');
        Observer.Observe('H3.const', Format(H.NSum_const));
        if not TryCalc_NSum_field(H) then
            Observer.ObserveError('NSum_field.calc86');
        Observer.Observe('H3.field', Format(H.NSum_field));
        if not TryCalc_NSum_filter(H) then
            Observer.ObserveError('NSum_filter.calc87');
        Observer.Observe('H3.filter', Format(H.NSum_filter));
        if not TryCalc_NSum_constopt(H) then
            Observer.ObserveError('NSum_constopt.calc88');
        Observer.Observe('H3.constopt', Format(H.NSum_constopt));
        if not TryCalc_NSum_constenum(H) then
            Observer.ObserveError('NSum_constenum.calc89');
        Observer.Observe('H3.constenum', Format(H.NSum_constenum));
        if not TryCalc_NSum_filterenum(H) then
            Observer.ObserveError('NSum_filterenum.calc90');
        Observer.Observe('H3.filterenum', Format(H.NSum_filterenum));
        Observer.Expect('H1.const', '-57.75');
        Observer.Expect('H1.field', '-150.75');
        Observer.Expect('H1.filter', '-81.25');
        Observer.Expect('H1.constopt', '-90.5');
        Observer.Expect('H1.constenum', '-27');
        Observer.Expect('H1.filterenum', '-144.75');
        Observer.Expect('H2.const', '-57.75');
        Observer.Expect('H2.field', '-21');
        Observer.Expect('H2.filter', '-81.25');
        Observer.Expect('H2.constopt', '-90.5');
        Observer.Expect('H2.constenum', '-27');
        Observer.Expect('H2.filterenum', '-144.75');
        Observer.Expect('H3.const', '-57.75');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '-81.25');
        Observer.Expect('H3.constopt', '-90.5');
        Observer.Expect('H3.constenum', '-27');
        Observer.Expect('H3.filterenum', '-144.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedSum_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedSum with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NSum_ffint(H) then
            Observer.ObserveError('NSum_ffint.calc91');
        Observer.Observe('ffint.unset', Format(H.NSum_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NSum_ffint(H) then
            Observer.ObserveError('NSum_ffint.calc92');
        Observer.Observe('ffint.set', Format(H.NSum_ffint));
        H.Reset();
        if not TryCalc_NSum_ffdec(H) then
            Observer.ObserveError('NSum_ffdec.calc93');
        Observer.Observe('ffdec.unset', Format(H.NSum_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NSum_ffdec(H) then
            Observer.ObserveError('NSum_ffdec.calc94');
        Observer.Observe('ffdec.set', Format(H.NSum_ffdec));
        H.Reset();
        if not TryCalc_NSum_ffdate(H) then
            Observer.ObserveError('NSum_ffdate.calc95');
        Observer.Observe('ffdate.unset', Format(H.NSum_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NSum_ffdate(H) then
            Observer.ObserveError('NSum_ffdate.calc96');
        Observer.Observe('ffdate.set', Format(H.NSum_ffdate));
        H.Reset();
        if not TryCalc_NSum_ffcode(H) then
            Observer.ObserveError('NSum_ffcode.calc97');
        Observer.Observe('ffcode.unset', Format(H.NSum_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NSum_ffcode(H) then
            Observer.ObserveError('NSum_ffcode.calc98');
        Observer.Observe('ffcode.set', Format(H.NSum_ffcode));
        H.Reset();
        if not TryCalc_NSum_ffopt(H) then
            Observer.ObserveError('NSum_ffopt.calc99');
        Observer.Observe('ffopt.unset', Format(H.NSum_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NSum_ffopt(H) then
            Observer.ObserveError('NSum_ffopt.calc100');
        Observer.Observe('ffopt.set', Format(H.NSum_ffopt));
        H.Reset();
        if not TryCalc_NSum_ffenum(H) then
            Observer.ObserveError('NSum_ffenum.calc101');
        Observer.Observe('ffenum.unset', Format(H.NSum_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NSum_ffenum(H) then
            Observer.ObserveError('NSum_ffenum.calc102');
        Observer.Observe('ffenum.set', Format(H.NSum_ffenum));
        H.Reset();
        if not TryCalc_NSum_fftext(H) then
            Observer.ObserveError('NSum_fftext.calc103');
        Observer.Observe('fftext.unset', Format(H.NSum_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NSum_fftext(H) then
            Observer.ObserveError('NSum_fftext.calc104');
        Observer.Observe('fftext.set', Format(H.NSum_fftext));
        Observer.Expect('ffint.unset', '-171.75');
        Observer.Expect('ffint.set', '-74.25');
        Observer.Expect('ffdec.unset', '-171.75');
        Observer.Expect('ffdec.set', '-154.25');
        Observer.Expect('ffdate.unset', '-171.75');
        Observer.Expect('ffdate.set', '-140.25');
        Observer.Expect('ffcode.unset', '-171.75');
        Observer.Expect('ffcode.set', '-57.75');
        Observer.Expect('ffopt.unset', '-171.75');
        Observer.Expect('ffopt.set', '-90.5');
        Observer.Expect('ffenum.unset', '-171.75');
        Observer.Expect('ffenum.set', '-81.25');
        Observer.Expect('fftext.unset', '-171.75');
        Observer.Expect('fftext.set', '-50.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedSum_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedSum with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NSum_uldate(H) then
            Observer.ObserveError('NSum_uldate.calc105');
        Observer.Observe('uldate.unset', Format(H.NSum_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NSum_uldate(H) then
            Observer.ObserveError('NSum_uldate.calc106');
        Observer.Observe('uldate.set', Format(H.NSum_uldate));
        H.Reset();
        if not TryCalc_NSum_ulint(H) then
            Observer.ObserveError('NSum_ulint.calc107');
        Observer.Observe('ulint.unset', Format(H.NSum_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NSum_ulint(H) then
            Observer.ObserveError('NSum_ulint.calc108');
        Observer.Observe('ulint.set', Format(H.NSum_ulint));
        H.Reset();
        if not TryCalc_NSum_uldec(H) then
            Observer.ObserveError('NSum_uldec.calc109');
        Observer.Observe('uldec.unset', Format(H.NSum_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NSum_uldec(H) then
            Observer.ObserveError('NSum_uldec.calc110');
        Observer.Observe('uldec.set', Format(H.NSum_uldec));
        H.Reset();
        if not TryCalc_NSum_ulcode(H) then
            Observer.ObserveError('NSum_ulcode.calc111');
        Observer.Observe('ulcode.unset', Format(H.NSum_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NSum_ulcode(H) then
            Observer.ObserveError('NSum_ulcode.calc112');
        Observer.Observe('ulcode.set', Format(H.NSum_ulcode));
        H.Reset();
        if not TryCalc_NSum_ulopt(H) then
            Observer.ObserveError('NSum_ulopt.calc113');
        Observer.Observe('ulopt.unset', Format(H.NSum_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NSum_ulopt(H) then
            Observer.ObserveError('NSum_ulopt.calc114');
        Observer.Observe('ulopt.set', Format(H.NSum_ulopt));
        H.Reset();
        if not TryCalc_NSum_ulenum(H) then
            Observer.ObserveError('NSum_ulenum.calc115');
        Observer.Observe('ulenum.unset', Format(H.NSum_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NSum_ulenum(H) then
            Observer.ObserveError('NSum_ulenum.calc116');
        Observer.Observe('ulenum.set', Format(H.NSum_ulenum));
        H.Reset();
        if not TryCalc_NSum_ulfdate(H) then
            Observer.ObserveError('NSum_ulfdate.calc117');
        Observer.Observe('ulfdate.unset', Format(H.NSum_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NSum_ulfdate(H) then
            Observer.ObserveError('NSum_ulfdate.calc118');
        Observer.Observe('ulfdate.set', Format(H.NSum_ulfdate));
        Observer.Expect('uldate.unset', '-171.75');
        Observer.Expect('uldate.set', '-157.75');
        Observer.Expect('ulint.unset', '-171.75');
        Observer.Expect('ulint.set', '-91.75');
        Observer.Expect('uldec.unset', '-171.75');
        Observer.Expect('NSum_uldec.calc110|text', 'The filter expression ">=14" applied to the field DecF in the FFM SumAvg Header table results in more than one range.');
        Observer.Expect('NSum_uldec.calc110|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '-171.75');
        Observer.Expect('ulcode.unset', '-171.75');
        Observer.Expect('ulcode.set', '-57.75');
        Observer.Expect('ulopt.unset', '-171.75');
        Observer.Expect('ulopt.set', '-90.5');
        Observer.Expect('ulenum.unset', '-171.75');
        Observer.Expect('ulenum.set', '-171.75');
        Observer.Expect('ulfdate.unset', '-171.75');
        Observer.Expect('ulfdate.set', '-157.75');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedSum_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedSum with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NSum_ffmismatch(H) then
            Observer.ObserveError('NSum_ffmismatch.calc119');
        Observer.Observe('ffmismatch.unset', Format(H.NSum_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NSum_ffmismatch(H) then
            Observer.ObserveError('NSum_ffmismatch.calc120');
        Observer.Observe('ffmismatch.set', Format(H.NSum_ffmismatch));
        H.Reset();
        if not TryCalc_NSum_ffboth(H) then
            Observer.ObserveError('NSum_ffboth.calc121');
        Observer.Observe('ffboth.unset', Format(H.NSum_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NSum_ffboth(H) then
            Observer.ObserveError('NSum_ffboth.calc122');
        Observer.Observe('ffboth.set', Format(H.NSum_ffboth));
        Observer.Expect('ffmismatch.unset', '-171.75');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '-150.75');
        Observer.Expect('ffboth.set', '-60.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedSum_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedSum over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NSum_const(H) then
            Observer.ObserveError('NSum_const.calc123');
        Observer.Observe('const.h3', Format(H.NSum_const));
        if not TryCalc_NSum_field(H) then
            Observer.ObserveError('NSum_field.calc124');
        Observer.Observe('field.h3', Format(H.NSum_field));
        if not TryCalc_NSum_filter(H) then
            Observer.ObserveError('NSum_filter.calc125');
        Observer.Observe('filter.h3', Format(H.NSum_filter));
        if not TryCalc_NSum_constopt(H) then
            Observer.ObserveError('NSum_constopt.calc126');
        Observer.Observe('constopt.h3', Format(H.NSum_constopt));
        if not TryCalc_NSum_constenum(H) then
            Observer.ObserveError('NSum_constenum.calc127');
        Observer.Observe('constenum.h3', Format(H.NSum_constenum));
        if not TryCalc_NSum_filterenum(H) then
            Observer.ObserveError('NSum_filterenum.calc128');
        Observer.Observe('filterenum.h3', Format(H.NSum_filterenum));
        if not TryCalc_NSum_ffint(H) then
            Observer.ObserveError('NSum_ffint.calc129');
        Observer.Observe('ffint.h3', Format(H.NSum_ffint));
        if not TryCalc_NSum_ffdec(H) then
            Observer.ObserveError('NSum_ffdec.calc130');
        Observer.Observe('ffdec.h3', Format(H.NSum_ffdec));
        if not TryCalc_NSum_ffdate(H) then
            Observer.ObserveError('NSum_ffdate.calc131');
        Observer.Observe('ffdate.h3', Format(H.NSum_ffdate));
        if not TryCalc_NSum_ffcode(H) then
            Observer.ObserveError('NSum_ffcode.calc132');
        Observer.Observe('ffcode.h3', Format(H.NSum_ffcode));
        if not TryCalc_NSum_ffopt(H) then
            Observer.ObserveError('NSum_ffopt.calc133');
        Observer.Observe('ffopt.h3', Format(H.NSum_ffopt));
        if not TryCalc_NSum_ffenum(H) then
            Observer.ObserveError('NSum_ffenum.calc134');
        Observer.Observe('ffenum.h3', Format(H.NSum_ffenum));
        if not TryCalc_NSum_fftext(H) then
            Observer.ObserveError('NSum_fftext.calc135');
        Observer.Observe('fftext.h3', Format(H.NSum_fftext));
        if not TryCalc_NSum_uldate(H) then
            Observer.ObserveError('NSum_uldate.calc136');
        Observer.Observe('uldate.h3', Format(H.NSum_uldate));
        if not TryCalc_NSum_ulint(H) then
            Observer.ObserveError('NSum_ulint.calc137');
        Observer.Observe('ulint.h3', Format(H.NSum_ulint));
        if not TryCalc_NSum_uldec(H) then
            Observer.ObserveError('NSum_uldec.calc138');
        Observer.Observe('uldec.h3', Format(H.NSum_uldec));
        if not TryCalc_NSum_ulcode(H) then
            Observer.ObserveError('NSum_ulcode.calc139');
        Observer.Observe('ulcode.h3', Format(H.NSum_ulcode));
        if not TryCalc_NSum_ulopt(H) then
            Observer.ObserveError('NSum_ulopt.calc140');
        Observer.Observe('ulopt.h3', Format(H.NSum_ulopt));
        if not TryCalc_NSum_ulenum(H) then
            Observer.ObserveError('NSum_ulenum.calc141');
        Observer.Observe('ulenum.h3', Format(H.NSum_ulenum));
        if not TryCalc_NSum_ulfdate(H) then
            Observer.ObserveError('NSum_ulfdate.calc142');
        Observer.Observe('ulfdate.h3', Format(H.NSum_ulfdate));
        if not TryCalc_NSum_ffmismatch(H) then
            Observer.ObserveError('NSum_ffmismatch.calc143');
        Observer.Observe('ffmismatch.h3', Format(H.NSum_ffmismatch));
        if not TryCalc_NSum_ffboth(H) then
            Observer.ObserveError('NSum_ffboth.calc144');
        Observer.Observe('ffboth.h3', Format(H.NSum_ffboth));
        Observer.Expect('const.h3', '-57.75');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '-81.25');
        Observer.Expect('constopt.h3', '-90.5');
        Observer.Expect('constenum.h3', '-27');
        Observer.Expect('filterenum.h3', '-144.75');
        Observer.Expect('ffint.h3', '-171.75');
        Observer.Expect('ffdec.h3', '-171.75');
        Observer.Expect('ffdate.h3', '-171.75');
        Observer.Expect('ffcode.h3', '-171.75');
        Observer.Expect('ffopt.h3', '-171.75');
        Observer.Expect('ffenum.h3', '-171.75');
        Observer.Expect('fftext.h3', '-171.75');
        Observer.Expect('uldate.h3', '-171.75');
        Observer.Expect('ulint.h3', '-171.75');
        Observer.Expect('uldec.h3', '-171.75');
        Observer.Expect('ulcode.h3', '-171.75');
        Observer.Expect('ulopt.h3', '-171.75');
        Observer.Expect('ulenum.h3', '-171.75');
        Observer.Expect('ulfdate.h3', '-171.75');
        Observer.Expect('ffmismatch.h3', '-171.75');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldAverage_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldAverage with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Avg_const(H) then
            Observer.ObserveError('Avg_const.calc145');
        Observer.Observe('H1.const', Format(H.Avg_const));
        if not TryCalc_Avg_field(H) then
            Observer.ObserveError('Avg_field.calc146');
        Observer.Observe('H1.field', Format(H.Avg_field));
        if not TryCalc_Avg_filter(H) then
            Observer.ObserveError('Avg_filter.calc147');
        Observer.Observe('H1.filter', Format(H.Avg_filter));
        if not TryCalc_Avg_constopt(H) then
            Observer.ObserveError('Avg_constopt.calc148');
        Observer.Observe('H1.constopt', Format(H.Avg_constopt));
        if not TryCalc_Avg_constenum(H) then
            Observer.ObserveError('Avg_constenum.calc149');
        Observer.Observe('H1.constenum', Format(H.Avg_constenum));
        if not TryCalc_Avg_filterenum(H) then
            Observer.ObserveError('Avg_filterenum.calc150');
        Observer.Observe('H1.filterenum', Format(H.Avg_filterenum));
        H.Get('H2');
        if not TryCalc_Avg_const(H) then
            Observer.ObserveError('Avg_const.calc151');
        Observer.Observe('H2.const', Format(H.Avg_const));
        if not TryCalc_Avg_field(H) then
            Observer.ObserveError('Avg_field.calc152');
        Observer.Observe('H2.field', Format(H.Avg_field));
        if not TryCalc_Avg_filter(H) then
            Observer.ObserveError('Avg_filter.calc153');
        Observer.Observe('H2.filter', Format(H.Avg_filter));
        if not TryCalc_Avg_constopt(H) then
            Observer.ObserveError('Avg_constopt.calc154');
        Observer.Observe('H2.constopt', Format(H.Avg_constopt));
        if not TryCalc_Avg_constenum(H) then
            Observer.ObserveError('Avg_constenum.calc155');
        Observer.Observe('H2.constenum', Format(H.Avg_constenum));
        if not TryCalc_Avg_filterenum(H) then
            Observer.ObserveError('Avg_filterenum.calc156');
        Observer.Observe('H2.filterenum', Format(H.Avg_filterenum));
        H.Get('H3');
        if not TryCalc_Avg_const(H) then
            Observer.ObserveError('Avg_const.calc157');
        Observer.Observe('H3.const', Format(H.Avg_const));
        if not TryCalc_Avg_field(H) then
            Observer.ObserveError('Avg_field.calc158');
        Observer.Observe('H3.field', Format(H.Avg_field));
        if not TryCalc_Avg_filter(H) then
            Observer.ObserveError('Avg_filter.calc159');
        Observer.Observe('H3.filter', Format(H.Avg_filter));
        if not TryCalc_Avg_constopt(H) then
            Observer.ObserveError('Avg_constopt.calc160');
        Observer.Observe('H3.constopt', Format(H.Avg_constopt));
        if not TryCalc_Avg_constenum(H) then
            Observer.ObserveError('Avg_constenum.calc161');
        Observer.Observe('H3.constenum', Format(H.Avg_constenum));
        if not TryCalc_Avg_filterenum(H) then
            Observer.ObserveError('Avg_filterenum.calc162');
        Observer.Observe('H3.filterenum', Format(H.Avg_filterenum));
        Observer.Expect('H1.const', '19.25');
        Observer.Expect('H1.field', '37.6875');
        Observer.Expect('H1.filter', '20.3125');
        Observer.Expect('H1.constopt', '45.25');
        Observer.Expect('H1.constenum', '13.5');
        Observer.Expect('H1.filterenum', '36.1875');
        Observer.Expect('H2.const', '19.25');
        Observer.Expect('H2.field', '10.5');
        Observer.Expect('H2.filter', '20.3125');
        Observer.Expect('H2.constopt', '45.25');
        Observer.Expect('H2.constenum', '13.5');
        Observer.Expect('H2.filterenum', '36.1875');
        Observer.Expect('H3.const', '19.25');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '20.3125');
        Observer.Expect('H3.constopt', '45.25');
        Observer.Expect('H3.constenum', '13.5');
        Observer.Expect('H3.filterenum', '36.1875');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldAverage_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldAverage with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Avg_ffint(H) then
            Observer.ObserveError('Avg_ffint.calc163');
        Observer.Observe('ffint.unset', Format(H.Avg_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Avg_ffint(H) then
            Observer.ObserveError('Avg_ffint.calc164');
        Observer.Observe('ffint.set', Format(H.Avg_ffint));
        H.Reset();
        if not TryCalc_Avg_ffdec(H) then
            Observer.ObserveError('Avg_ffdec.calc165');
        Observer.Observe('ffdec.unset', Format(H.Avg_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Avg_ffdec(H) then
            Observer.ObserveError('Avg_ffdec.calc166');
        Observer.Observe('ffdec.set', Format(H.Avg_ffdec));
        H.Reset();
        if not TryCalc_Avg_ffdate(H) then
            Observer.ObserveError('Avg_ffdate.calc167');
        Observer.Observe('ffdate.unset', Format(H.Avg_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Avg_ffdate(H) then
            Observer.ObserveError('Avg_ffdate.calc168');
        Observer.Observe('ffdate.set', Format(H.Avg_ffdate));
        H.Reset();
        if not TryCalc_Avg_ffcode(H) then
            Observer.ObserveError('Avg_ffcode.calc169');
        Observer.Observe('ffcode.unset', Format(H.Avg_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Avg_ffcode(H) then
            Observer.ObserveError('Avg_ffcode.calc170');
        Observer.Observe('ffcode.set', Format(H.Avg_ffcode));
        H.Reset();
        if not TryCalc_Avg_ffopt(H) then
            Observer.ObserveError('Avg_ffopt.calc171');
        Observer.Observe('ffopt.unset', Format(H.Avg_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Avg_ffopt(H) then
            Observer.ObserveError('Avg_ffopt.calc172');
        Observer.Observe('ffopt.set', Format(H.Avg_ffopt));
        H.Reset();
        if not TryCalc_Avg_ffenum(H) then
            Observer.ObserveError('Avg_ffenum.calc173');
        Observer.Observe('ffenum.unset', Format(H.Avg_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Avg_ffenum(H) then
            Observer.ObserveError('Avg_ffenum.calc174');
        Observer.Observe('ffenum.set', Format(H.Avg_ffenum));
        H.Reset();
        if not TryCalc_Avg_fftext(H) then
            Observer.ObserveError('Avg_fftext.calc175');
        Observer.Observe('fftext.unset', Format(H.Avg_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Avg_fftext(H) then
            Observer.ObserveError('Avg_fftext.calc176');
        Observer.Observe('fftext.set', Format(H.Avg_fftext));
        Observer.Expect('ffint.unset', '28.625');
        Observer.Expect('ffint.set', '24.75');
        Observer.Expect('ffdec.unset', '28.625');
        Observer.Expect('ffdec.set', '38.5625');
        Observer.Expect('ffdate.unset', '28.625');
        Observer.Expect('ffdate.set', '46.75');
        Observer.Expect('ffcode.unset', '28.625');
        Observer.Expect('ffcode.set', '19.25');
        Observer.Expect('ffopt.unset', '28.625');
        Observer.Expect('ffopt.set', '45.25');
        Observer.Expect('ffenum.unset', '28.625');
        Observer.Expect('ffenum.set', '20.3125');
        Observer.Expect('fftext.unset', '28.625');
        Observer.Expect('fftext.set', '25.375');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldAverage_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldAverage with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Avg_uldate(H) then
            Observer.ObserveError('Avg_uldate.calc177');
        Observer.Observe('uldate.unset', Format(H.Avg_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Avg_uldate(H) then
            Observer.ObserveError('Avg_uldate.calc178');
        Observer.Observe('uldate.set', Format(H.Avg_uldate));
        H.Reset();
        if not TryCalc_Avg_ulint(H) then
            Observer.ObserveError('Avg_ulint.calc179');
        Observer.Observe('ulint.unset', Format(H.Avg_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Avg_ulint(H) then
            Observer.ObserveError('Avg_ulint.calc180');
        Observer.Observe('ulint.set', Format(H.Avg_ulint));
        H.Reset();
        if not TryCalc_Avg_uldec(H) then
            Observer.ObserveError('Avg_uldec.calc181');
        Observer.Observe('uldec.unset', Format(H.Avg_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Avg_uldec(H) then
            Observer.ObserveError('Avg_uldec.calc182');
        Observer.Observe('uldec.set', Format(H.Avg_uldec));
        H.Reset();
        if not TryCalc_Avg_ulcode(H) then
            Observer.ObserveError('Avg_ulcode.calc183');
        Observer.Observe('ulcode.unset', Format(H.Avg_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Avg_ulcode(H) then
            Observer.ObserveError('Avg_ulcode.calc184');
        Observer.Observe('ulcode.set', Format(H.Avg_ulcode));
        H.Reset();
        if not TryCalc_Avg_ulopt(H) then
            Observer.ObserveError('Avg_ulopt.calc185');
        Observer.Observe('ulopt.unset', Format(H.Avg_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Avg_ulopt(H) then
            Observer.ObserveError('Avg_ulopt.calc186');
        Observer.Observe('ulopt.set', Format(H.Avg_ulopt));
        H.Reset();
        if not TryCalc_Avg_ulenum(H) then
            Observer.ObserveError('Avg_ulenum.calc187');
        Observer.Observe('ulenum.unset', Format(H.Avg_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Avg_ulenum(H) then
            Observer.ObserveError('Avg_ulenum.calc188');
        Observer.Observe('ulenum.set', Format(H.Avg_ulenum));
        H.Reset();
        if not TryCalc_Avg_ulfdate(H) then
            Observer.ObserveError('Avg_ulfdate.calc189');
        Observer.Observe('ulfdate.unset', Format(H.Avg_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Avg_ulfdate(H) then
            Observer.ObserveError('Avg_ulfdate.calc190');
        Observer.Observe('ulfdate.set', Format(H.Avg_ulfdate));
        Observer.Expect('uldate.unset', '28.625');
        Observer.Expect('uldate.set', '31.55');
        Observer.Expect('ulint.unset', '28.625');
        Observer.Expect('ulint.set', '18.35');
        Observer.Expect('uldec.unset', '28.625');
        Observer.Expect('Avg_uldec.calc182|text', 'The filter expression ">=14" applied to the field DecF in the FFM SumAvg Header table results in more than one range.');
        Observer.Expect('Avg_uldec.calc182|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '28.625');
        Observer.Expect('ulcode.unset', '28.625');
        Observer.Expect('ulcode.set', '19.25');
        Observer.Expect('ulopt.unset', '28.625');
        Observer.Expect('ulopt.set', '45.25');
        Observer.Expect('ulenum.unset', '28.625');
        Observer.Expect('ulenum.set', '28.625');
        Observer.Expect('ulfdate.unset', '28.625');
        Observer.Expect('ulfdate.set', '31.55');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldAverage_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldAverage with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Avg_ffmismatch(H) then
            Observer.ObserveError('Avg_ffmismatch.calc191');
        Observer.Observe('ffmismatch.unset', Format(H.Avg_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Avg_ffmismatch(H) then
            Observer.ObserveError('Avg_ffmismatch.calc192');
        Observer.Observe('ffmismatch.set', Format(H.Avg_ffmismatch));
        H.Reset();
        if not TryCalc_Avg_ffboth(H) then
            Observer.ObserveError('Avg_ffboth.calc193');
        Observer.Observe('ffboth.unset', Format(H.Avg_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Avg_ffboth(H) then
            Observer.ObserveError('Avg_ffboth.calc194');
        Observer.Observe('ffboth.set', Format(H.Avg_ffboth));
        Observer.Expect('ffmismatch.unset', '28.625');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '37.6875');
        Observer.Expect('ffboth.set', '30.125');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldAverage_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldAverage over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Avg_const(H) then
            Observer.ObserveError('Avg_const.calc195');
        Observer.Observe('const.h3', Format(H.Avg_const));
        if not TryCalc_Avg_field(H) then
            Observer.ObserveError('Avg_field.calc196');
        Observer.Observe('field.h3', Format(H.Avg_field));
        if not TryCalc_Avg_filter(H) then
            Observer.ObserveError('Avg_filter.calc197');
        Observer.Observe('filter.h3', Format(H.Avg_filter));
        if not TryCalc_Avg_constopt(H) then
            Observer.ObserveError('Avg_constopt.calc198');
        Observer.Observe('constopt.h3', Format(H.Avg_constopt));
        if not TryCalc_Avg_constenum(H) then
            Observer.ObserveError('Avg_constenum.calc199');
        Observer.Observe('constenum.h3', Format(H.Avg_constenum));
        if not TryCalc_Avg_filterenum(H) then
            Observer.ObserveError('Avg_filterenum.calc200');
        Observer.Observe('filterenum.h3', Format(H.Avg_filterenum));
        if not TryCalc_Avg_ffint(H) then
            Observer.ObserveError('Avg_ffint.calc201');
        Observer.Observe('ffint.h3', Format(H.Avg_ffint));
        if not TryCalc_Avg_ffdec(H) then
            Observer.ObserveError('Avg_ffdec.calc202');
        Observer.Observe('ffdec.h3', Format(H.Avg_ffdec));
        if not TryCalc_Avg_ffdate(H) then
            Observer.ObserveError('Avg_ffdate.calc203');
        Observer.Observe('ffdate.h3', Format(H.Avg_ffdate));
        if not TryCalc_Avg_ffcode(H) then
            Observer.ObserveError('Avg_ffcode.calc204');
        Observer.Observe('ffcode.h3', Format(H.Avg_ffcode));
        if not TryCalc_Avg_ffopt(H) then
            Observer.ObserveError('Avg_ffopt.calc205');
        Observer.Observe('ffopt.h3', Format(H.Avg_ffopt));
        if not TryCalc_Avg_ffenum(H) then
            Observer.ObserveError('Avg_ffenum.calc206');
        Observer.Observe('ffenum.h3', Format(H.Avg_ffenum));
        if not TryCalc_Avg_fftext(H) then
            Observer.ObserveError('Avg_fftext.calc207');
        Observer.Observe('fftext.h3', Format(H.Avg_fftext));
        if not TryCalc_Avg_uldate(H) then
            Observer.ObserveError('Avg_uldate.calc208');
        Observer.Observe('uldate.h3', Format(H.Avg_uldate));
        if not TryCalc_Avg_ulint(H) then
            Observer.ObserveError('Avg_ulint.calc209');
        Observer.Observe('ulint.h3', Format(H.Avg_ulint));
        if not TryCalc_Avg_uldec(H) then
            Observer.ObserveError('Avg_uldec.calc210');
        Observer.Observe('uldec.h3', Format(H.Avg_uldec));
        if not TryCalc_Avg_ulcode(H) then
            Observer.ObserveError('Avg_ulcode.calc211');
        Observer.Observe('ulcode.h3', Format(H.Avg_ulcode));
        if not TryCalc_Avg_ulopt(H) then
            Observer.ObserveError('Avg_ulopt.calc212');
        Observer.Observe('ulopt.h3', Format(H.Avg_ulopt));
        if not TryCalc_Avg_ulenum(H) then
            Observer.ObserveError('Avg_ulenum.calc213');
        Observer.Observe('ulenum.h3', Format(H.Avg_ulenum));
        if not TryCalc_Avg_ulfdate(H) then
            Observer.ObserveError('Avg_ulfdate.calc214');
        Observer.Observe('ulfdate.h3', Format(H.Avg_ulfdate));
        if not TryCalc_Avg_ffmismatch(H) then
            Observer.ObserveError('Avg_ffmismatch.calc215');
        Observer.Observe('ffmismatch.h3', Format(H.Avg_ffmismatch));
        if not TryCalc_Avg_ffboth(H) then
            Observer.ObserveError('Avg_ffboth.calc216');
        Observer.Observe('ffboth.h3', Format(H.Avg_ffboth));
        Observer.Expect('const.h3', '19.25');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '20.3125');
        Observer.Expect('constopt.h3', '45.25');
        Observer.Expect('constenum.h3', '13.5');
        Observer.Expect('filterenum.h3', '36.1875');
        Observer.Expect('ffint.h3', '28.625');
        Observer.Expect('ffdec.h3', '28.625');
        Observer.Expect('ffdate.h3', '28.625');
        Observer.Expect('ffcode.h3', '28.625');
        Observer.Expect('ffopt.h3', '28.625');
        Observer.Expect('ffenum.h3', '28.625');
        Observer.Expect('fftext.h3', '28.625');
        Observer.Expect('uldate.h3', '28.625');
        Observer.Expect('ulint.h3', '28.625');
        Observer.Expect('uldec.h3', '28.625');
        Observer.Expect('ulcode.h3', '28.625');
        Observer.Expect('ulopt.h3', '28.625');
        Observer.Expect('ulenum.h3', '28.625');
        Observer.Expect('ulfdate.h3', '28.625');
        Observer.Expect('ffmismatch.h3', '28.625');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedAverage with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NAvg_const(H) then
            Observer.ObserveError('NAvg_const.calc217');
        Observer.Observe('H1.const', Format(H.NAvg_const));
        if not TryCalc_NAvg_field(H) then
            Observer.ObserveError('NAvg_field.calc218');
        Observer.Observe('H1.field', Format(H.NAvg_field));
        if not TryCalc_NAvg_filter(H) then
            Observer.ObserveError('NAvg_filter.calc219');
        Observer.Observe('H1.filter', Format(H.NAvg_filter));
        if not TryCalc_NAvg_constopt(H) then
            Observer.ObserveError('NAvg_constopt.calc220');
        Observer.Observe('H1.constopt', Format(H.NAvg_constopt));
        if not TryCalc_NAvg_constenum(H) then
            Observer.ObserveError('NAvg_constenum.calc221');
        Observer.Observe('H1.constenum', Format(H.NAvg_constenum));
        if not TryCalc_NAvg_filterenum(H) then
            Observer.ObserveError('NAvg_filterenum.calc222');
        Observer.Observe('H1.filterenum', Format(H.NAvg_filterenum));
        H.Get('H2');
        if not TryCalc_NAvg_const(H) then
            Observer.ObserveError('NAvg_const.calc223');
        Observer.Observe('H2.const', Format(H.NAvg_const));
        if not TryCalc_NAvg_field(H) then
            Observer.ObserveError('NAvg_field.calc224');
        Observer.Observe('H2.field', Format(H.NAvg_field));
        if not TryCalc_NAvg_filter(H) then
            Observer.ObserveError('NAvg_filter.calc225');
        Observer.Observe('H2.filter', Format(H.NAvg_filter));
        if not TryCalc_NAvg_constopt(H) then
            Observer.ObserveError('NAvg_constopt.calc226');
        Observer.Observe('H2.constopt', Format(H.NAvg_constopt));
        if not TryCalc_NAvg_constenum(H) then
            Observer.ObserveError('NAvg_constenum.calc227');
        Observer.Observe('H2.constenum', Format(H.NAvg_constenum));
        if not TryCalc_NAvg_filterenum(H) then
            Observer.ObserveError('NAvg_filterenum.calc228');
        Observer.Observe('H2.filterenum', Format(H.NAvg_filterenum));
        H.Get('H3');
        if not TryCalc_NAvg_const(H) then
            Observer.ObserveError('NAvg_const.calc229');
        Observer.Observe('H3.const', Format(H.NAvg_const));
        if not TryCalc_NAvg_field(H) then
            Observer.ObserveError('NAvg_field.calc230');
        Observer.Observe('H3.field', Format(H.NAvg_field));
        if not TryCalc_NAvg_filter(H) then
            Observer.ObserveError('NAvg_filter.calc231');
        Observer.Observe('H3.filter', Format(H.NAvg_filter));
        if not TryCalc_NAvg_constopt(H) then
            Observer.ObserveError('NAvg_constopt.calc232');
        Observer.Observe('H3.constopt', Format(H.NAvg_constopt));
        if not TryCalc_NAvg_constenum(H) then
            Observer.ObserveError('NAvg_constenum.calc233');
        Observer.Observe('H3.constenum', Format(H.NAvg_constenum));
        if not TryCalc_NAvg_filterenum(H) then
            Observer.ObserveError('NAvg_filterenum.calc234');
        Observer.Observe('H3.filterenum', Format(H.NAvg_filterenum));
        Observer.Expect('H1.const', '-19.25');
        Observer.Expect('H1.field', '-37.6875');
        Observer.Expect('H1.filter', '-20.3125');
        Observer.Expect('H1.constopt', '-45.25');
        Observer.Expect('H1.constenum', '-13.5');
        Observer.Expect('H1.filterenum', '-36.1875');
        Observer.Expect('H2.const', '-19.25');
        Observer.Expect('H2.field', '-10.5');
        Observer.Expect('H2.filter', '-20.3125');
        Observer.Expect('H2.constopt', '-45.25');
        Observer.Expect('H2.constenum', '-13.5');
        Observer.Expect('H2.filterenum', '-36.1875');
        Observer.Expect('H3.const', '-19.25');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '-20.3125');
        Observer.Expect('H3.constopt', '-45.25');
        Observer.Expect('H3.constenum', '-13.5');
        Observer.Expect('H3.filterenum', '-36.1875');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedAverage with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NAvg_ffint(H) then
            Observer.ObserveError('NAvg_ffint.calc235');
        Observer.Observe('ffint.unset', Format(H.NAvg_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NAvg_ffint(H) then
            Observer.ObserveError('NAvg_ffint.calc236');
        Observer.Observe('ffint.set', Format(H.NAvg_ffint));
        H.Reset();
        if not TryCalc_NAvg_ffdec(H) then
            Observer.ObserveError('NAvg_ffdec.calc237');
        Observer.Observe('ffdec.unset', Format(H.NAvg_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NAvg_ffdec(H) then
            Observer.ObserveError('NAvg_ffdec.calc238');
        Observer.Observe('ffdec.set', Format(H.NAvg_ffdec));
        H.Reset();
        if not TryCalc_NAvg_ffdate(H) then
            Observer.ObserveError('NAvg_ffdate.calc239');
        Observer.Observe('ffdate.unset', Format(H.NAvg_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NAvg_ffdate(H) then
            Observer.ObserveError('NAvg_ffdate.calc240');
        Observer.Observe('ffdate.set', Format(H.NAvg_ffdate));
        H.Reset();
        if not TryCalc_NAvg_ffcode(H) then
            Observer.ObserveError('NAvg_ffcode.calc241');
        Observer.Observe('ffcode.unset', Format(H.NAvg_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NAvg_ffcode(H) then
            Observer.ObserveError('NAvg_ffcode.calc242');
        Observer.Observe('ffcode.set', Format(H.NAvg_ffcode));
        H.Reset();
        if not TryCalc_NAvg_ffopt(H) then
            Observer.ObserveError('NAvg_ffopt.calc243');
        Observer.Observe('ffopt.unset', Format(H.NAvg_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NAvg_ffopt(H) then
            Observer.ObserveError('NAvg_ffopt.calc244');
        Observer.Observe('ffopt.set', Format(H.NAvg_ffopt));
        H.Reset();
        if not TryCalc_NAvg_ffenum(H) then
            Observer.ObserveError('NAvg_ffenum.calc245');
        Observer.Observe('ffenum.unset', Format(H.NAvg_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NAvg_ffenum(H) then
            Observer.ObserveError('NAvg_ffenum.calc246');
        Observer.Observe('ffenum.set', Format(H.NAvg_ffenum));
        H.Reset();
        if not TryCalc_NAvg_fftext(H) then
            Observer.ObserveError('NAvg_fftext.calc247');
        Observer.Observe('fftext.unset', Format(H.NAvg_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NAvg_fftext(H) then
            Observer.ObserveError('NAvg_fftext.calc248');
        Observer.Observe('fftext.set', Format(H.NAvg_fftext));
        Observer.Expect('ffint.unset', '-28.625');
        Observer.Expect('ffint.set', '-24.75');
        Observer.Expect('ffdec.unset', '-28.625');
        Observer.Expect('ffdec.set', '-38.5625');
        Observer.Expect('ffdate.unset', '-28.625');
        Observer.Expect('ffdate.set', '-46.75');
        Observer.Expect('ffcode.unset', '-28.625');
        Observer.Expect('ffcode.set', '-19.25');
        Observer.Expect('ffopt.unset', '-28.625');
        Observer.Expect('ffopt.set', '-45.25');
        Observer.Expect('ffenum.unset', '-28.625');
        Observer.Expect('ffenum.set', '-20.3125');
        Observer.Expect('fftext.unset', '-28.625');
        Observer.Expect('fftext.set', '-25.375');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedAverage with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NAvg_uldate(H) then
            Observer.ObserveError('NAvg_uldate.calc249');
        Observer.Observe('uldate.unset', Format(H.NAvg_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NAvg_uldate(H) then
            Observer.ObserveError('NAvg_uldate.calc250');
        Observer.Observe('uldate.set', Format(H.NAvg_uldate));
        H.Reset();
        if not TryCalc_NAvg_ulint(H) then
            Observer.ObserveError('NAvg_ulint.calc251');
        Observer.Observe('ulint.unset', Format(H.NAvg_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NAvg_ulint(H) then
            Observer.ObserveError('NAvg_ulint.calc252');
        Observer.Observe('ulint.set', Format(H.NAvg_ulint));
        H.Reset();
        if not TryCalc_NAvg_uldec(H) then
            Observer.ObserveError('NAvg_uldec.calc253');
        Observer.Observe('uldec.unset', Format(H.NAvg_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NAvg_uldec(H) then
            Observer.ObserveError('NAvg_uldec.calc254');
        Observer.Observe('uldec.set', Format(H.NAvg_uldec));
        H.Reset();
        if not TryCalc_NAvg_ulcode(H) then
            Observer.ObserveError('NAvg_ulcode.calc255');
        Observer.Observe('ulcode.unset', Format(H.NAvg_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NAvg_ulcode(H) then
            Observer.ObserveError('NAvg_ulcode.calc256');
        Observer.Observe('ulcode.set', Format(H.NAvg_ulcode));
        H.Reset();
        if not TryCalc_NAvg_ulopt(H) then
            Observer.ObserveError('NAvg_ulopt.calc257');
        Observer.Observe('ulopt.unset', Format(H.NAvg_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NAvg_ulopt(H) then
            Observer.ObserveError('NAvg_ulopt.calc258');
        Observer.Observe('ulopt.set', Format(H.NAvg_ulopt));
        H.Reset();
        if not TryCalc_NAvg_ulenum(H) then
            Observer.ObserveError('NAvg_ulenum.calc259');
        Observer.Observe('ulenum.unset', Format(H.NAvg_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NAvg_ulenum(H) then
            Observer.ObserveError('NAvg_ulenum.calc260');
        Observer.Observe('ulenum.set', Format(H.NAvg_ulenum));
        H.Reset();
        if not TryCalc_NAvg_ulfdate(H) then
            Observer.ObserveError('NAvg_ulfdate.calc261');
        Observer.Observe('ulfdate.unset', Format(H.NAvg_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NAvg_ulfdate(H) then
            Observer.ObserveError('NAvg_ulfdate.calc262');
        Observer.Observe('ulfdate.set', Format(H.NAvg_ulfdate));
        Observer.Expect('uldate.unset', '-28.625');
        Observer.Expect('uldate.set', '-31.55');
        Observer.Expect('ulint.unset', '-28.625');
        Observer.Expect('ulint.set', '-18.35');
        Observer.Expect('uldec.unset', '-28.625');
        Observer.Expect('NAvg_uldec.calc254|text', 'The filter expression ">=14" applied to the field DecF in the FFM SumAvg Header table results in more than one range.');
        Observer.Expect('NAvg_uldec.calc254|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '-28.625');
        Observer.Expect('ulcode.unset', '-28.625');
        Observer.Expect('ulcode.set', '-19.25');
        Observer.Expect('ulopt.unset', '-28.625');
        Observer.Expect('ulopt.set', '-45.25');
        Observer.Expect('ulenum.unset', '-28.625');
        Observer.Expect('ulenum.set', '-28.625');
        Observer.Expect('ulfdate.unset', '-28.625');
        Observer.Expect('ulfdate.set', '-31.55');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedAverage with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NAvg_ffmismatch(H) then
            Observer.ObserveError('NAvg_ffmismatch.calc263');
        Observer.Observe('ffmismatch.unset', Format(H.NAvg_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NAvg_ffmismatch(H) then
            Observer.ObserveError('NAvg_ffmismatch.calc264');
        Observer.Observe('ffmismatch.set', Format(H.NAvg_ffmismatch));
        H.Reset();
        if not TryCalc_NAvg_ffboth(H) then
            Observer.ObserveError('NAvg_ffboth.calc265');
        Observer.Observe('ffboth.unset', Format(H.NAvg_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NAvg_ffboth(H) then
            Observer.ObserveError('NAvg_ffboth.calc266');
        Observer.Observe('ffboth.set', Format(H.NAvg_ffboth));
        Observer.Expect('ffmismatch.unset', '-28.625');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '-37.6875');
        Observer.Expect('ffboth.set', '-30.125');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedAverage over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NAvg_const(H) then
            Observer.ObserveError('NAvg_const.calc267');
        Observer.Observe('const.h3', Format(H.NAvg_const));
        if not TryCalc_NAvg_field(H) then
            Observer.ObserveError('NAvg_field.calc268');
        Observer.Observe('field.h3', Format(H.NAvg_field));
        if not TryCalc_NAvg_filter(H) then
            Observer.ObserveError('NAvg_filter.calc269');
        Observer.Observe('filter.h3', Format(H.NAvg_filter));
        if not TryCalc_NAvg_constopt(H) then
            Observer.ObserveError('NAvg_constopt.calc270');
        Observer.Observe('constopt.h3', Format(H.NAvg_constopt));
        if not TryCalc_NAvg_constenum(H) then
            Observer.ObserveError('NAvg_constenum.calc271');
        Observer.Observe('constenum.h3', Format(H.NAvg_constenum));
        if not TryCalc_NAvg_filterenum(H) then
            Observer.ObserveError('NAvg_filterenum.calc272');
        Observer.Observe('filterenum.h3', Format(H.NAvg_filterenum));
        if not TryCalc_NAvg_ffint(H) then
            Observer.ObserveError('NAvg_ffint.calc273');
        Observer.Observe('ffint.h3', Format(H.NAvg_ffint));
        if not TryCalc_NAvg_ffdec(H) then
            Observer.ObserveError('NAvg_ffdec.calc274');
        Observer.Observe('ffdec.h3', Format(H.NAvg_ffdec));
        if not TryCalc_NAvg_ffdate(H) then
            Observer.ObserveError('NAvg_ffdate.calc275');
        Observer.Observe('ffdate.h3', Format(H.NAvg_ffdate));
        if not TryCalc_NAvg_ffcode(H) then
            Observer.ObserveError('NAvg_ffcode.calc276');
        Observer.Observe('ffcode.h3', Format(H.NAvg_ffcode));
        if not TryCalc_NAvg_ffopt(H) then
            Observer.ObserveError('NAvg_ffopt.calc277');
        Observer.Observe('ffopt.h3', Format(H.NAvg_ffopt));
        if not TryCalc_NAvg_ffenum(H) then
            Observer.ObserveError('NAvg_ffenum.calc278');
        Observer.Observe('ffenum.h3', Format(H.NAvg_ffenum));
        if not TryCalc_NAvg_fftext(H) then
            Observer.ObserveError('NAvg_fftext.calc279');
        Observer.Observe('fftext.h3', Format(H.NAvg_fftext));
        if not TryCalc_NAvg_uldate(H) then
            Observer.ObserveError('NAvg_uldate.calc280');
        Observer.Observe('uldate.h3', Format(H.NAvg_uldate));
        if not TryCalc_NAvg_ulint(H) then
            Observer.ObserveError('NAvg_ulint.calc281');
        Observer.Observe('ulint.h3', Format(H.NAvg_ulint));
        if not TryCalc_NAvg_uldec(H) then
            Observer.ObserveError('NAvg_uldec.calc282');
        Observer.Observe('uldec.h3', Format(H.NAvg_uldec));
        if not TryCalc_NAvg_ulcode(H) then
            Observer.ObserveError('NAvg_ulcode.calc283');
        Observer.Observe('ulcode.h3', Format(H.NAvg_ulcode));
        if not TryCalc_NAvg_ulopt(H) then
            Observer.ObserveError('NAvg_ulopt.calc284');
        Observer.Observe('ulopt.h3', Format(H.NAvg_ulopt));
        if not TryCalc_NAvg_ulenum(H) then
            Observer.ObserveError('NAvg_ulenum.calc285');
        Observer.Observe('ulenum.h3', Format(H.NAvg_ulenum));
        if not TryCalc_NAvg_ulfdate(H) then
            Observer.ObserveError('NAvg_ulfdate.calc286');
        Observer.Observe('ulfdate.h3', Format(H.NAvg_ulfdate));
        if not TryCalc_NAvg_ffmismatch(H) then
            Observer.ObserveError('NAvg_ffmismatch.calc287');
        Observer.Observe('ffmismatch.h3', Format(H.NAvg_ffmismatch));
        if not TryCalc_NAvg_ffboth(H) then
            Observer.ObserveError('NAvg_ffboth.calc288');
        Observer.Observe('ffboth.h3', Format(H.NAvg_ffboth));
        Observer.Expect('const.h3', '-19.25');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '-20.3125');
        Observer.Expect('constopt.h3', '-45.25');
        Observer.Expect('constenum.h3', '-13.5');
        Observer.Expect('filterenum.h3', '-36.1875');
        Observer.Expect('ffint.h3', '-28.625');
        Observer.Expect('ffdec.h3', '-28.625');
        Observer.Expect('ffdate.h3', '-28.625');
        Observer.Expect('ffcode.h3', '-28.625');
        Observer.Expect('ffopt.h3', '-28.625');
        Observer.Expect('ffenum.h3', '-28.625');
        Observer.Expect('fftext.h3', '-28.625');
        Observer.Expect('uldate.h3', '-28.625');
        Observer.Expect('ulint.h3', '-28.625');
        Observer.Expect('uldec.h3', '-28.625');
        Observer.Expect('ulcode.h3', '-28.625');
        Observer.Expect('ulopt.h3', '-28.625');
        Observer.Expect('ulenum.h3', '-28.625');
        Observer.Expect('ulfdate.h3', '-28.625');
        Observer.Expect('ffmismatch.h3', '-28.625');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        D: Record "FFM SumAvg Detail";
        H: Record "FFM SumAvg Header";
    begin
        D.DeleteAll();
        H.DeleteAll();
        AddDetail(1, 'H1', 1, 10.5, 20260110D, 'K1', 1, 0, true, 'alpha');
        AddDetail(2, 'H1', 3, 20, 20260210D, 'K2', 2, 1, false, 'bravo');
        AddDetail(3, 'H1', 5, 40.25, 20260310D, 'K1', 3, 2, true, 'charlie');
        AddDetail(4, 'H1', 7, 80, 20260410D, 'K2', 1, 0, false, 'delta');
        AddDetail(5, 'H2', 2, 7, 20260110D, 'K1', 2, 1, true, 'echo');
        AddDetail(6, 'H2', 4, 14, 20260510D, 'K2', 3, 2, false, 'foxtrot');
        AddHeader('H1');
        AddHeader('H2');
        AddHeader('H3');
    end;

    local procedure AddDetail(EntryNo: Integer; OwnerCode: Code[10]; Quantity: Integer; Amount: Decimal; Date: Date; KindCode: Code[10]; Option: Integer; StatusValue: Integer; FlagValue: Boolean; NameValue: Text[30])
    var
        D: Record "FFM SumAvg Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Qty := Quantity;
        D.Amt := Amount;
        D.Day := Date;
        D.Kind := KindCode;
        D.Opt := Option;
        D.Status := "FFM SumAvg Status".FromInteger(StatusValue);
        D.Flag := FlagValue;
        D.Name := NameValue;
        D.Insert();
    end;

    local procedure AddHeader(HeaderCode: Code[10])
    var
        H: Record "FFM SumAvg Header";
    begin
        H.Init();
        H.Code := HeaderCode;
        H.Insert();
    end;
}
