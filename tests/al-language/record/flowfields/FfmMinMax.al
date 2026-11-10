// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM MinMax *)
// local object: the CalcFormula definitions are what the tests measure.
// Area: FlowField and FlowFilter matrix, CalcFormula kinds min, -min, max, -max crossed with the where-clause forms (const, field, filter,
//   field(filter(F)) over Integer, Decimal, Date, Code, Option, Enum and Text FlowFilters, field(upperlimit(F)), field(upperlimit(filter(F))))
//   and the two states of every FlowFilter (not set, set), read with CalcFields on a record with rows, and on a record with no match.
//   The shapes BC rejects at compile time are pinned in tests/must-not-compile/cases (upperlimit outside field()).
// Nearby: record/flowfields/Y17SumWhereFlowField.al, record/flowfields/CalcFormulaDateLiteral.al, TestCalcFormulaFlowFiltersTests.Codeunit.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

enum 64300 "FFM MinMax Status"
{
    Extensible = true;
    value(0; Open) { }
    value(1; Closed) { }
    value(2; Held) { }
}

table 64301 "FFM MinMax Detail"
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
        field(8; Status; Enum "FFM MinMax Status") { }
        field(9; Flag; Boolean) { }
        field(10; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64302 "FFM MinMax Header"
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
        field(7; EnumF; Enum "FFM MinMax Status") { FieldClass = FlowFilter; }
        field(8; TextF; Text[30]) { FieldClass = FlowFilter; }
        field(100; Min_const; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Kind = const('K1'))); }
        field(101; Min_field; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Owner = field(Code))); }
        field(102; Min_filter; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Qty = filter(2..5))); }
        field(103; Min_constopt; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Opt = const(B))); }
        field(104; Min_constenum; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Status = const(Closed))); }
        field(105; Min_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Status = filter(Open|Held))); }
        field(106; Min_ffint; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Qty = field(filter(IntF)))); }
        field(107; Min_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Amt = field(filter(DecF)))); }
        field(108; Min_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Day = field(filter(DateF)))); }
        field(109; Min_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(110; Min_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Opt = field(filter(OptF)))); }
        field(111; Min_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Status = field(filter(EnumF)))); }
        field(112; Min_fftext; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Name = field(filter(TextF)))); }
        field(113; Min_uldate; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(114; Min_ulint; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(115; Min_uldec; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(116; Min_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(117; Min_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(118; Min_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(119; Min_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(120; Min_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Qty = field(filter(DateF)))); }
        field(121; Min_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = min("FFM MinMax Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(122; NMin_const; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Kind = const('K1'))); }
        field(123; NMin_field; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Owner = field(Code))); }
        field(124; NMin_filter; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Qty = filter(2..5))); }
        field(125; NMin_constopt; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Opt = const(B))); }
        field(126; NMin_constenum; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Status = const(Closed))); }
        field(127; NMin_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Status = filter(Open|Held))); }
        field(128; NMin_ffint; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Qty = field(filter(IntF)))); }
        field(129; NMin_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Amt = field(filter(DecF)))); }
        field(130; NMin_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Day = field(filter(DateF)))); }
        field(131; NMin_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(132; NMin_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Opt = field(filter(OptF)))); }
        field(133; NMin_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Status = field(filter(EnumF)))); }
        field(134; NMin_fftext; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Name = field(filter(TextF)))); }
        field(135; NMin_uldate; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(136; NMin_ulint; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(137; NMin_uldec; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(138; NMin_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(139; NMin_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(140; NMin_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(141; NMin_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(142; NMin_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Qty = field(filter(DateF)))); }
        field(143; NMin_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = -min("FFM MinMax Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(144; Max_const; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Kind = const('K1'))); }
        field(145; Max_field; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Owner = field(Code))); }
        field(146; Max_filter; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Qty = filter(2..5))); }
        field(147; Max_constopt; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Opt = const(B))); }
        field(148; Max_constenum; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Status = const(Closed))); }
        field(149; Max_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Status = filter(Open|Held))); }
        field(150; Max_ffint; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Qty = field(filter(IntF)))); }
        field(151; Max_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Amt = field(filter(DecF)))); }
        field(152; Max_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Day = field(filter(DateF)))); }
        field(153; Max_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(154; Max_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Opt = field(filter(OptF)))); }
        field(155; Max_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Status = field(filter(EnumF)))); }
        field(156; Max_fftext; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Name = field(filter(TextF)))); }
        field(157; Max_uldate; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(158; Max_ulint; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(159; Max_uldec; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(160; Max_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(161; Max_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(162; Max_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(163; Max_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(164; Max_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Qty = field(filter(DateF)))); }
        field(165; Max_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = max("FFM MinMax Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(166; NMax_const; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Kind = const('K1'))); }
        field(167; NMax_field; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Owner = field(Code))); }
        field(168; NMax_filter; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Qty = filter(2..5))); }
        field(169; NMax_constopt; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Opt = const(B))); }
        field(170; NMax_constenum; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Status = const(Closed))); }
        field(171; NMax_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Status = filter(Open|Held))); }
        field(172; NMax_ffint; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Qty = field(filter(IntF)))); }
        field(173; NMax_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Amt = field(filter(DecF)))); }
        field(174; NMax_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Day = field(filter(DateF)))); }
        field(175; NMax_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(176; NMax_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Opt = field(filter(OptF)))); }
        field(177; NMax_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Status = field(filter(EnumF)))); }
        field(178; NMax_fftext; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Name = field(filter(TextF)))); }
        field(179; NMax_uldate; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(180; NMax_ulint; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(181; NMax_uldec; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(182; NMax_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(183; NMax_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(184; NMax_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(185; NMax_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(186; NMax_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Qty = field(filter(DateF)))); }
        field(187; NMax_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = -max("FFM MinMax Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 64303 "FFM MinMax Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryCalc_Min_const(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_const);
    end;

    [TryFunction]
    local procedure TryCalc_Min_field(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_field);
    end;

    [TryFunction]
    local procedure TryCalc_Min_filter(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Min_constopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Min_constenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Min_filterenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffdec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Min_fftext(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Min_uldate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ulint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Min_uldec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ulcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ulopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ulenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ulfdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffmismatch(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Min_ffboth(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Min_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_const(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_const);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_field(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_field);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_filter(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_constopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_constenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_filterenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffdec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_fftext(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_uldate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ulint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_uldec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ulcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ulopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ulenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ulfdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffmismatch(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NMin_ffboth(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMin_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_Max_const(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_const);
    end;

    [TryFunction]
    local procedure TryCalc_Max_field(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_field);
    end;

    [TryFunction]
    local procedure TryCalc_Max_filter(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Max_constopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Max_constenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Max_filterenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffdec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Max_fftext(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Max_uldate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ulint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Max_uldec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ulcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ulopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ulenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ulfdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffmismatch(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Max_ffboth(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(Max_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_const(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_const);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_field(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_field);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_filter(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_constopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_constenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_filterenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffdec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_fftext(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_uldate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ulint(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_uldec(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ulcode(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ulopt(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ulenum(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ulfdate(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffmismatch(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NMax_ffboth(var H: Record "FFM MinMax Header")
    begin
        H.CalcFields(NMax_ffboth);
    end;

    [Test]
    procedure FlowFieldMin_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldMin with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Min_const(H) then
            Observer.ObserveError('Min_const.calc1');
        Observer.Observe('H1.const', Format(H.Min_const));
        if not TryCalc_Min_field(H) then
            Observer.ObserveError('Min_field.calc2');
        Observer.Observe('H1.field', Format(H.Min_field));
        if not TryCalc_Min_filter(H) then
            Observer.ObserveError('Min_filter.calc3');
        Observer.Observe('H1.filter', Format(H.Min_filter));
        if not TryCalc_Min_constopt(H) then
            Observer.ObserveError('Min_constopt.calc4');
        Observer.Observe('H1.constopt', Format(H.Min_constopt));
        if not TryCalc_Min_constenum(H) then
            Observer.ObserveError('Min_constenum.calc5');
        Observer.Observe('H1.constenum', Format(H.Min_constenum));
        if not TryCalc_Min_filterenum(H) then
            Observer.ObserveError('Min_filterenum.calc6');
        Observer.Observe('H1.filterenum', Format(H.Min_filterenum));
        H.Get('H2');
        if not TryCalc_Min_const(H) then
            Observer.ObserveError('Min_const.calc7');
        Observer.Observe('H2.const', Format(H.Min_const));
        if not TryCalc_Min_field(H) then
            Observer.ObserveError('Min_field.calc8');
        Observer.Observe('H2.field', Format(H.Min_field));
        if not TryCalc_Min_filter(H) then
            Observer.ObserveError('Min_filter.calc9');
        Observer.Observe('H2.filter', Format(H.Min_filter));
        if not TryCalc_Min_constopt(H) then
            Observer.ObserveError('Min_constopt.calc10');
        Observer.Observe('H2.constopt', Format(H.Min_constopt));
        if not TryCalc_Min_constenum(H) then
            Observer.ObserveError('Min_constenum.calc11');
        Observer.Observe('H2.constenum', Format(H.Min_constenum));
        if not TryCalc_Min_filterenum(H) then
            Observer.ObserveError('Min_filterenum.calc12');
        Observer.Observe('H2.filterenum', Format(H.Min_filterenum));
        H.Get('H3');
        if not TryCalc_Min_const(H) then
            Observer.ObserveError('Min_const.calc13');
        Observer.Observe('H3.const', Format(H.Min_const));
        if not TryCalc_Min_field(H) then
            Observer.ObserveError('Min_field.calc14');
        Observer.Observe('H3.field', Format(H.Min_field));
        if not TryCalc_Min_filter(H) then
            Observer.ObserveError('Min_filter.calc15');
        Observer.Observe('H3.filter', Format(H.Min_filter));
        if not TryCalc_Min_constopt(H) then
            Observer.ObserveError('Min_constopt.calc16');
        Observer.Observe('H3.constopt', Format(H.Min_constopt));
        if not TryCalc_Min_constenum(H) then
            Observer.ObserveError('Min_constenum.calc17');
        Observer.Observe('H3.constenum', Format(H.Min_constenum));
        if not TryCalc_Min_filterenum(H) then
            Observer.ObserveError('Min_filterenum.calc18');
        Observer.Observe('H3.filterenum', Format(H.Min_filterenum));
        Observer.Expect('H1.const', '7');
        Observer.Expect('H1.field', '10.5');
        Observer.Expect('H1.filter', '7');
        Observer.Expect('H1.constopt', '10.5');
        Observer.Expect('H1.constenum', '7');
        Observer.Expect('H1.filterenum', '10.5');
        Observer.Expect('H2.const', '7');
        Observer.Expect('H2.field', '7');
        Observer.Expect('H2.filter', '7');
        Observer.Expect('H2.constopt', '10.5');
        Observer.Expect('H2.constenum', '7');
        Observer.Expect('H2.filterenum', '10.5');
        Observer.Expect('H3.const', '7');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '7');
        Observer.Expect('H3.constopt', '10.5');
        Observer.Expect('H3.constenum', '7');
        Observer.Expect('H3.filterenum', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMin_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldMin with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Min_ffint(H) then
            Observer.ObserveError('Min_ffint.calc19');
        Observer.Observe('ffint.unset', Format(H.Min_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Min_ffint(H) then
            Observer.ObserveError('Min_ffint.calc20');
        Observer.Observe('ffint.set', Format(H.Min_ffint));
        H.Reset();
        if not TryCalc_Min_ffdec(H) then
            Observer.ObserveError('Min_ffdec.calc21');
        Observer.Observe('ffdec.unset', Format(H.Min_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Min_ffdec(H) then
            Observer.ObserveError('Min_ffdec.calc22');
        Observer.Observe('ffdec.set', Format(H.Min_ffdec));
        H.Reset();
        if not TryCalc_Min_ffdate(H) then
            Observer.ObserveError('Min_ffdate.calc23');
        Observer.Observe('ffdate.unset', Format(H.Min_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Min_ffdate(H) then
            Observer.ObserveError('Min_ffdate.calc24');
        Observer.Observe('ffdate.set', Format(H.Min_ffdate));
        H.Reset();
        if not TryCalc_Min_ffcode(H) then
            Observer.ObserveError('Min_ffcode.calc25');
        Observer.Observe('ffcode.unset', Format(H.Min_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Min_ffcode(H) then
            Observer.ObserveError('Min_ffcode.calc26');
        Observer.Observe('ffcode.set', Format(H.Min_ffcode));
        H.Reset();
        if not TryCalc_Min_ffopt(H) then
            Observer.ObserveError('Min_ffopt.calc27');
        Observer.Observe('ffopt.unset', Format(H.Min_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Min_ffopt(H) then
            Observer.ObserveError('Min_ffopt.calc28');
        Observer.Observe('ffopt.set', Format(H.Min_ffopt));
        H.Reset();
        if not TryCalc_Min_ffenum(H) then
            Observer.ObserveError('Min_ffenum.calc29');
        Observer.Observe('ffenum.unset', Format(H.Min_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Min_ffenum(H) then
            Observer.ObserveError('Min_ffenum.calc30');
        Observer.Observe('ffenum.set', Format(H.Min_ffenum));
        H.Reset();
        if not TryCalc_Min_fftext(H) then
            Observer.ObserveError('Min_fftext.calc31');
        Observer.Observe('fftext.unset', Format(H.Min_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Min_fftext(H) then
            Observer.ObserveError('Min_fftext.calc32');
        Observer.Observe('fftext.set', Format(H.Min_fftext));
        Observer.Expect('ffint.unset', '7');
        Observer.Expect('ffint.set', '14');
        Observer.Expect('ffdec.unset', '7');
        Observer.Expect('ffdec.set', '14');
        Observer.Expect('ffdate.unset', '7');
        Observer.Expect('ffdate.set', '20');
        Observer.Expect('ffcode.unset', '7');
        Observer.Expect('ffcode.set', '7');
        Observer.Expect('ffopt.unset', '7');
        Observer.Expect('ffopt.set', '10.5');
        Observer.Expect('ffenum.unset', '7');
        Observer.Expect('ffenum.set', '7');
        Observer.Expect('fftext.unset', '7');
        Observer.Expect('fftext.set', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMin_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldMin with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Min_uldate(H) then
            Observer.ObserveError('Min_uldate.calc33');
        Observer.Observe('uldate.unset', Format(H.Min_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Min_uldate(H) then
            Observer.ObserveError('Min_uldate.calc34');
        Observer.Observe('uldate.set', Format(H.Min_uldate));
        H.Reset();
        if not TryCalc_Min_ulint(H) then
            Observer.ObserveError('Min_ulint.calc35');
        Observer.Observe('ulint.unset', Format(H.Min_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Min_ulint(H) then
            Observer.ObserveError('Min_ulint.calc36');
        Observer.Observe('ulint.set', Format(H.Min_ulint));
        H.Reset();
        if not TryCalc_Min_uldec(H) then
            Observer.ObserveError('Min_uldec.calc37');
        Observer.Observe('uldec.unset', Format(H.Min_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Min_uldec(H) then
            Observer.ObserveError('Min_uldec.calc38');
        Observer.Observe('uldec.set', Format(H.Min_uldec));
        H.Reset();
        if not TryCalc_Min_ulcode(H) then
            Observer.ObserveError('Min_ulcode.calc39');
        Observer.Observe('ulcode.unset', Format(H.Min_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Min_ulcode(H) then
            Observer.ObserveError('Min_ulcode.calc40');
        Observer.Observe('ulcode.set', Format(H.Min_ulcode));
        H.Reset();
        if not TryCalc_Min_ulopt(H) then
            Observer.ObserveError('Min_ulopt.calc41');
        Observer.Observe('ulopt.unset', Format(H.Min_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Min_ulopt(H) then
            Observer.ObserveError('Min_ulopt.calc42');
        Observer.Observe('ulopt.set', Format(H.Min_ulopt));
        H.Reset();
        if not TryCalc_Min_ulenum(H) then
            Observer.ObserveError('Min_ulenum.calc43');
        Observer.Observe('ulenum.unset', Format(H.Min_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Min_ulenum(H) then
            Observer.ObserveError('Min_ulenum.calc44');
        Observer.Observe('ulenum.set', Format(H.Min_ulenum));
        H.Reset();
        if not TryCalc_Min_ulfdate(H) then
            Observer.ObserveError('Min_ulfdate.calc45');
        Observer.Observe('ulfdate.unset', Format(H.Min_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Min_ulfdate(H) then
            Observer.ObserveError('Min_ulfdate.calc46');
        Observer.Observe('ulfdate.set', Format(H.Min_ulfdate));
        Observer.Expect('uldate.unset', '7');
        Observer.Expect('uldate.set', '7');
        Observer.Expect('ulint.unset', '7');
        Observer.Expect('ulint.set', '7');
        Observer.Expect('uldec.unset', '7');
        Observer.Expect('Min_uldec.calc38|text', 'The filter expression ">=14" applied to the field DecF in the FFM MinMax Header table results in more than one range.');
        Observer.Expect('Min_uldec.calc38|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '7');
        Observer.Expect('ulcode.unset', '7');
        Observer.Expect('ulcode.set', '7');
        Observer.Expect('ulopt.unset', '7');
        Observer.Expect('ulopt.set', '10.5');
        Observer.Expect('ulenum.unset', '7');
        Observer.Expect('ulenum.set', '7');
        Observer.Expect('ulfdate.unset', '7');
        Observer.Expect('ulfdate.set', '7');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMin_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldMin with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Min_ffmismatch(H) then
            Observer.ObserveError('Min_ffmismatch.calc47');
        Observer.Observe('ffmismatch.unset', Format(H.Min_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Min_ffmismatch(H) then
            Observer.ObserveError('Min_ffmismatch.calc48');
        Observer.Observe('ffmismatch.set', Format(H.Min_ffmismatch));
        H.Reset();
        if not TryCalc_Min_ffboth(H) then
            Observer.ObserveError('Min_ffboth.calc49');
        Observer.Observe('ffboth.unset', Format(H.Min_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Min_ffboth(H) then
            Observer.ObserveError('Min_ffboth.calc50');
        Observer.Observe('ffboth.set', Format(H.Min_ffboth));
        Observer.Expect('ffmismatch.unset', '7');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '10.5');
        Observer.Expect('ffboth.set', '20');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMin_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldMin over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Min_const(H) then
            Observer.ObserveError('Min_const.calc51');
        Observer.Observe('const.h3', Format(H.Min_const));
        if not TryCalc_Min_field(H) then
            Observer.ObserveError('Min_field.calc52');
        Observer.Observe('field.h3', Format(H.Min_field));
        if not TryCalc_Min_filter(H) then
            Observer.ObserveError('Min_filter.calc53');
        Observer.Observe('filter.h3', Format(H.Min_filter));
        if not TryCalc_Min_constopt(H) then
            Observer.ObserveError('Min_constopt.calc54');
        Observer.Observe('constopt.h3', Format(H.Min_constopt));
        if not TryCalc_Min_constenum(H) then
            Observer.ObserveError('Min_constenum.calc55');
        Observer.Observe('constenum.h3', Format(H.Min_constenum));
        if not TryCalc_Min_filterenum(H) then
            Observer.ObserveError('Min_filterenum.calc56');
        Observer.Observe('filterenum.h3', Format(H.Min_filterenum));
        if not TryCalc_Min_ffint(H) then
            Observer.ObserveError('Min_ffint.calc57');
        Observer.Observe('ffint.h3', Format(H.Min_ffint));
        if not TryCalc_Min_ffdec(H) then
            Observer.ObserveError('Min_ffdec.calc58');
        Observer.Observe('ffdec.h3', Format(H.Min_ffdec));
        if not TryCalc_Min_ffdate(H) then
            Observer.ObserveError('Min_ffdate.calc59');
        Observer.Observe('ffdate.h3', Format(H.Min_ffdate));
        if not TryCalc_Min_ffcode(H) then
            Observer.ObserveError('Min_ffcode.calc60');
        Observer.Observe('ffcode.h3', Format(H.Min_ffcode));
        if not TryCalc_Min_ffopt(H) then
            Observer.ObserveError('Min_ffopt.calc61');
        Observer.Observe('ffopt.h3', Format(H.Min_ffopt));
        if not TryCalc_Min_ffenum(H) then
            Observer.ObserveError('Min_ffenum.calc62');
        Observer.Observe('ffenum.h3', Format(H.Min_ffenum));
        if not TryCalc_Min_fftext(H) then
            Observer.ObserveError('Min_fftext.calc63');
        Observer.Observe('fftext.h3', Format(H.Min_fftext));
        if not TryCalc_Min_uldate(H) then
            Observer.ObserveError('Min_uldate.calc64');
        Observer.Observe('uldate.h3', Format(H.Min_uldate));
        if not TryCalc_Min_ulint(H) then
            Observer.ObserveError('Min_ulint.calc65');
        Observer.Observe('ulint.h3', Format(H.Min_ulint));
        if not TryCalc_Min_uldec(H) then
            Observer.ObserveError('Min_uldec.calc66');
        Observer.Observe('uldec.h3', Format(H.Min_uldec));
        if not TryCalc_Min_ulcode(H) then
            Observer.ObserveError('Min_ulcode.calc67');
        Observer.Observe('ulcode.h3', Format(H.Min_ulcode));
        if not TryCalc_Min_ulopt(H) then
            Observer.ObserveError('Min_ulopt.calc68');
        Observer.Observe('ulopt.h3', Format(H.Min_ulopt));
        if not TryCalc_Min_ulenum(H) then
            Observer.ObserveError('Min_ulenum.calc69');
        Observer.Observe('ulenum.h3', Format(H.Min_ulenum));
        if not TryCalc_Min_ulfdate(H) then
            Observer.ObserveError('Min_ulfdate.calc70');
        Observer.Observe('ulfdate.h3', Format(H.Min_ulfdate));
        if not TryCalc_Min_ffmismatch(H) then
            Observer.ObserveError('Min_ffmismatch.calc71');
        Observer.Observe('ffmismatch.h3', Format(H.Min_ffmismatch));
        if not TryCalc_Min_ffboth(H) then
            Observer.ObserveError('Min_ffboth.calc72');
        Observer.Observe('ffboth.h3', Format(H.Min_ffboth));
        Observer.Expect('const.h3', '7');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '7');
        Observer.Expect('constopt.h3', '10.5');
        Observer.Expect('constenum.h3', '7');
        Observer.Expect('filterenum.h3', '10.5');
        Observer.Expect('ffint.h3', '7');
        Observer.Expect('ffdec.h3', '7');
        Observer.Expect('ffdate.h3', '7');
        Observer.Expect('ffcode.h3', '7');
        Observer.Expect('ffopt.h3', '7');
        Observer.Expect('ffenum.h3', '7');
        Observer.Expect('fftext.h3', '7');
        Observer.Expect('uldate.h3', '7');
        Observer.Expect('ulint.h3', '7');
        Observer.Expect('uldec.h3', '7');
        Observer.Expect('ulcode.h3', '7');
        Observer.Expect('ulopt.h3', '7');
        Observer.Expect('ulenum.h3', '7');
        Observer.Expect('ulfdate.h3', '7');
        Observer.Expect('ffmismatch.h3', '7');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMin_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedMin with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NMin_const(H) then
            Observer.ObserveError('NMin_const.calc73');
        Observer.Observe('H1.const', Format(H.NMin_const));
        if not TryCalc_NMin_field(H) then
            Observer.ObserveError('NMin_field.calc74');
        Observer.Observe('H1.field', Format(H.NMin_field));
        if not TryCalc_NMin_filter(H) then
            Observer.ObserveError('NMin_filter.calc75');
        Observer.Observe('H1.filter', Format(H.NMin_filter));
        if not TryCalc_NMin_constopt(H) then
            Observer.ObserveError('NMin_constopt.calc76');
        Observer.Observe('H1.constopt', Format(H.NMin_constopt));
        if not TryCalc_NMin_constenum(H) then
            Observer.ObserveError('NMin_constenum.calc77');
        Observer.Observe('H1.constenum', Format(H.NMin_constenum));
        if not TryCalc_NMin_filterenum(H) then
            Observer.ObserveError('NMin_filterenum.calc78');
        Observer.Observe('H1.filterenum', Format(H.NMin_filterenum));
        H.Get('H2');
        if not TryCalc_NMin_const(H) then
            Observer.ObserveError('NMin_const.calc79');
        Observer.Observe('H2.const', Format(H.NMin_const));
        if not TryCalc_NMin_field(H) then
            Observer.ObserveError('NMin_field.calc80');
        Observer.Observe('H2.field', Format(H.NMin_field));
        if not TryCalc_NMin_filter(H) then
            Observer.ObserveError('NMin_filter.calc81');
        Observer.Observe('H2.filter', Format(H.NMin_filter));
        if not TryCalc_NMin_constopt(H) then
            Observer.ObserveError('NMin_constopt.calc82');
        Observer.Observe('H2.constopt', Format(H.NMin_constopt));
        if not TryCalc_NMin_constenum(H) then
            Observer.ObserveError('NMin_constenum.calc83');
        Observer.Observe('H2.constenum', Format(H.NMin_constenum));
        if not TryCalc_NMin_filterenum(H) then
            Observer.ObserveError('NMin_filterenum.calc84');
        Observer.Observe('H2.filterenum', Format(H.NMin_filterenum));
        H.Get('H3');
        if not TryCalc_NMin_const(H) then
            Observer.ObserveError('NMin_const.calc85');
        Observer.Observe('H3.const', Format(H.NMin_const));
        if not TryCalc_NMin_field(H) then
            Observer.ObserveError('NMin_field.calc86');
        Observer.Observe('H3.field', Format(H.NMin_field));
        if not TryCalc_NMin_filter(H) then
            Observer.ObserveError('NMin_filter.calc87');
        Observer.Observe('H3.filter', Format(H.NMin_filter));
        if not TryCalc_NMin_constopt(H) then
            Observer.ObserveError('NMin_constopt.calc88');
        Observer.Observe('H3.constopt', Format(H.NMin_constopt));
        if not TryCalc_NMin_constenum(H) then
            Observer.ObserveError('NMin_constenum.calc89');
        Observer.Observe('H3.constenum', Format(H.NMin_constenum));
        if not TryCalc_NMin_filterenum(H) then
            Observer.ObserveError('NMin_filterenum.calc90');
        Observer.Observe('H3.filterenum', Format(H.NMin_filterenum));
        Observer.Expect('H1.const', '-7');
        Observer.Expect('H1.field', '-10.5');
        Observer.Expect('H1.filter', '-7');
        Observer.Expect('H1.constopt', '-10.5');
        Observer.Expect('H1.constenum', '-7');
        Observer.Expect('H1.filterenum', '-10.5');
        Observer.Expect('H2.const', '-7');
        Observer.Expect('H2.field', '-7');
        Observer.Expect('H2.filter', '-7');
        Observer.Expect('H2.constopt', '-10.5');
        Observer.Expect('H2.constenum', '-7');
        Observer.Expect('H2.filterenum', '-10.5');
        Observer.Expect('H3.const', '-7');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '-7');
        Observer.Expect('H3.constopt', '-10.5');
        Observer.Expect('H3.constenum', '-7');
        Observer.Expect('H3.filterenum', '-10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMin_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMin with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMin_ffint(H) then
            Observer.ObserveError('NMin_ffint.calc91');
        Observer.Observe('ffint.unset', Format(H.NMin_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMin_ffint(H) then
            Observer.ObserveError('NMin_ffint.calc92');
        Observer.Observe('ffint.set', Format(H.NMin_ffint));
        H.Reset();
        if not TryCalc_NMin_ffdec(H) then
            Observer.ObserveError('NMin_ffdec.calc93');
        Observer.Observe('ffdec.unset', Format(H.NMin_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NMin_ffdec(H) then
            Observer.ObserveError('NMin_ffdec.calc94');
        Observer.Observe('ffdec.set', Format(H.NMin_ffdec));
        H.Reset();
        if not TryCalc_NMin_ffdate(H) then
            Observer.ObserveError('NMin_ffdate.calc95');
        Observer.Observe('ffdate.unset', Format(H.NMin_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMin_ffdate(H) then
            Observer.ObserveError('NMin_ffdate.calc96');
        Observer.Observe('ffdate.set', Format(H.NMin_ffdate));
        H.Reset();
        if not TryCalc_NMin_ffcode(H) then
            Observer.ObserveError('NMin_ffcode.calc97');
        Observer.Observe('ffcode.unset', Format(H.NMin_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NMin_ffcode(H) then
            Observer.ObserveError('NMin_ffcode.calc98');
        Observer.Observe('ffcode.set', Format(H.NMin_ffcode));
        H.Reset();
        if not TryCalc_NMin_ffopt(H) then
            Observer.ObserveError('NMin_ffopt.calc99');
        Observer.Observe('ffopt.unset', Format(H.NMin_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NMin_ffopt(H) then
            Observer.ObserveError('NMin_ffopt.calc100');
        Observer.Observe('ffopt.set', Format(H.NMin_ffopt));
        H.Reset();
        if not TryCalc_NMin_ffenum(H) then
            Observer.ObserveError('NMin_ffenum.calc101');
        Observer.Observe('ffenum.unset', Format(H.NMin_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NMin_ffenum(H) then
            Observer.ObserveError('NMin_ffenum.calc102');
        Observer.Observe('ffenum.set', Format(H.NMin_ffenum));
        H.Reset();
        if not TryCalc_NMin_fftext(H) then
            Observer.ObserveError('NMin_fftext.calc103');
        Observer.Observe('fftext.unset', Format(H.NMin_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NMin_fftext(H) then
            Observer.ObserveError('NMin_fftext.calc104');
        Observer.Observe('fftext.set', Format(H.NMin_fftext));
        Observer.Expect('ffint.unset', '-7');
        Observer.Expect('ffint.set', '-14');
        Observer.Expect('ffdec.unset', '-7');
        Observer.Expect('ffdec.set', '-14');
        Observer.Expect('ffdate.unset', '-7');
        Observer.Expect('ffdate.set', '-20');
        Observer.Expect('ffcode.unset', '-7');
        Observer.Expect('ffcode.set', '-7');
        Observer.Expect('ffopt.unset', '-7');
        Observer.Expect('ffopt.set', '-10.5');
        Observer.Expect('ffenum.unset', '-7');
        Observer.Expect('ffenum.set', '-7');
        Observer.Expect('fftext.unset', '-7');
        Observer.Expect('fftext.set', '-10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMin_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMin with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMin_uldate(H) then
            Observer.ObserveError('NMin_uldate.calc105');
        Observer.Observe('uldate.unset', Format(H.NMin_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMin_uldate(H) then
            Observer.ObserveError('NMin_uldate.calc106');
        Observer.Observe('uldate.set', Format(H.NMin_uldate));
        H.Reset();
        if not TryCalc_NMin_ulint(H) then
            Observer.ObserveError('NMin_ulint.calc107');
        Observer.Observe('ulint.unset', Format(H.NMin_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMin_ulint(H) then
            Observer.ObserveError('NMin_ulint.calc108');
        Observer.Observe('ulint.set', Format(H.NMin_ulint));
        H.Reset();
        if not TryCalc_NMin_uldec(H) then
            Observer.ObserveError('NMin_uldec.calc109');
        Observer.Observe('uldec.unset', Format(H.NMin_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NMin_uldec(H) then
            Observer.ObserveError('NMin_uldec.calc110');
        Observer.Observe('uldec.set', Format(H.NMin_uldec));
        H.Reset();
        if not TryCalc_NMin_ulcode(H) then
            Observer.ObserveError('NMin_ulcode.calc111');
        Observer.Observe('ulcode.unset', Format(H.NMin_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NMin_ulcode(H) then
            Observer.ObserveError('NMin_ulcode.calc112');
        Observer.Observe('ulcode.set', Format(H.NMin_ulcode));
        H.Reset();
        if not TryCalc_NMin_ulopt(H) then
            Observer.ObserveError('NMin_ulopt.calc113');
        Observer.Observe('ulopt.unset', Format(H.NMin_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NMin_ulopt(H) then
            Observer.ObserveError('NMin_ulopt.calc114');
        Observer.Observe('ulopt.set', Format(H.NMin_ulopt));
        H.Reset();
        if not TryCalc_NMin_ulenum(H) then
            Observer.ObserveError('NMin_ulenum.calc115');
        Observer.Observe('ulenum.unset', Format(H.NMin_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NMin_ulenum(H) then
            Observer.ObserveError('NMin_ulenum.calc116');
        Observer.Observe('ulenum.set', Format(H.NMin_ulenum));
        H.Reset();
        if not TryCalc_NMin_ulfdate(H) then
            Observer.ObserveError('NMin_ulfdate.calc117');
        Observer.Observe('ulfdate.unset', Format(H.NMin_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMin_ulfdate(H) then
            Observer.ObserveError('NMin_ulfdate.calc118');
        Observer.Observe('ulfdate.set', Format(H.NMin_ulfdate));
        Observer.Expect('uldate.unset', '-7');
        Observer.Expect('uldate.set', '-7');
        Observer.Expect('ulint.unset', '-7');
        Observer.Expect('ulint.set', '-7');
        Observer.Expect('uldec.unset', '-7');
        Observer.Expect('NMin_uldec.calc110|text', 'The filter expression ">=14" applied to the field DecF in the FFM MinMax Header table results in more than one range.');
        Observer.Expect('NMin_uldec.calc110|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '-7');
        Observer.Expect('ulcode.unset', '-7');
        Observer.Expect('ulcode.set', '-7');
        Observer.Expect('ulopt.unset', '-7');
        Observer.Expect('ulopt.set', '-10.5');
        Observer.Expect('ulenum.unset', '-7');
        Observer.Expect('ulenum.set', '-7');
        Observer.Expect('ulfdate.unset', '-7');
        Observer.Expect('ulfdate.set', '-7');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMin_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMin with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMin_ffmismatch(H) then
            Observer.ObserveError('NMin_ffmismatch.calc119');
        Observer.Observe('ffmismatch.unset', Format(H.NMin_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMin_ffmismatch(H) then
            Observer.ObserveError('NMin_ffmismatch.calc120');
        Observer.Observe('ffmismatch.set', Format(H.NMin_ffmismatch));
        H.Reset();
        if not TryCalc_NMin_ffboth(H) then
            Observer.ObserveError('NMin_ffboth.calc121');
        Observer.Observe('ffboth.unset', Format(H.NMin_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMin_ffboth(H) then
            Observer.ObserveError('NMin_ffboth.calc122');
        Observer.Observe('ffboth.set', Format(H.NMin_ffboth));
        Observer.Expect('ffmismatch.unset', '-7');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '-10.5');
        Observer.Expect('ffboth.set', '-20');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMin_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedMin over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NMin_const(H) then
            Observer.ObserveError('NMin_const.calc123');
        Observer.Observe('const.h3', Format(H.NMin_const));
        if not TryCalc_NMin_field(H) then
            Observer.ObserveError('NMin_field.calc124');
        Observer.Observe('field.h3', Format(H.NMin_field));
        if not TryCalc_NMin_filter(H) then
            Observer.ObserveError('NMin_filter.calc125');
        Observer.Observe('filter.h3', Format(H.NMin_filter));
        if not TryCalc_NMin_constopt(H) then
            Observer.ObserveError('NMin_constopt.calc126');
        Observer.Observe('constopt.h3', Format(H.NMin_constopt));
        if not TryCalc_NMin_constenum(H) then
            Observer.ObserveError('NMin_constenum.calc127');
        Observer.Observe('constenum.h3', Format(H.NMin_constenum));
        if not TryCalc_NMin_filterenum(H) then
            Observer.ObserveError('NMin_filterenum.calc128');
        Observer.Observe('filterenum.h3', Format(H.NMin_filterenum));
        if not TryCalc_NMin_ffint(H) then
            Observer.ObserveError('NMin_ffint.calc129');
        Observer.Observe('ffint.h3', Format(H.NMin_ffint));
        if not TryCalc_NMin_ffdec(H) then
            Observer.ObserveError('NMin_ffdec.calc130');
        Observer.Observe('ffdec.h3', Format(H.NMin_ffdec));
        if not TryCalc_NMin_ffdate(H) then
            Observer.ObserveError('NMin_ffdate.calc131');
        Observer.Observe('ffdate.h3', Format(H.NMin_ffdate));
        if not TryCalc_NMin_ffcode(H) then
            Observer.ObserveError('NMin_ffcode.calc132');
        Observer.Observe('ffcode.h3', Format(H.NMin_ffcode));
        if not TryCalc_NMin_ffopt(H) then
            Observer.ObserveError('NMin_ffopt.calc133');
        Observer.Observe('ffopt.h3', Format(H.NMin_ffopt));
        if not TryCalc_NMin_ffenum(H) then
            Observer.ObserveError('NMin_ffenum.calc134');
        Observer.Observe('ffenum.h3', Format(H.NMin_ffenum));
        if not TryCalc_NMin_fftext(H) then
            Observer.ObserveError('NMin_fftext.calc135');
        Observer.Observe('fftext.h3', Format(H.NMin_fftext));
        if not TryCalc_NMin_uldate(H) then
            Observer.ObserveError('NMin_uldate.calc136');
        Observer.Observe('uldate.h3', Format(H.NMin_uldate));
        if not TryCalc_NMin_ulint(H) then
            Observer.ObserveError('NMin_ulint.calc137');
        Observer.Observe('ulint.h3', Format(H.NMin_ulint));
        if not TryCalc_NMin_uldec(H) then
            Observer.ObserveError('NMin_uldec.calc138');
        Observer.Observe('uldec.h3', Format(H.NMin_uldec));
        if not TryCalc_NMin_ulcode(H) then
            Observer.ObserveError('NMin_ulcode.calc139');
        Observer.Observe('ulcode.h3', Format(H.NMin_ulcode));
        if not TryCalc_NMin_ulopt(H) then
            Observer.ObserveError('NMin_ulopt.calc140');
        Observer.Observe('ulopt.h3', Format(H.NMin_ulopt));
        if not TryCalc_NMin_ulenum(H) then
            Observer.ObserveError('NMin_ulenum.calc141');
        Observer.Observe('ulenum.h3', Format(H.NMin_ulenum));
        if not TryCalc_NMin_ulfdate(H) then
            Observer.ObserveError('NMin_ulfdate.calc142');
        Observer.Observe('ulfdate.h3', Format(H.NMin_ulfdate));
        if not TryCalc_NMin_ffmismatch(H) then
            Observer.ObserveError('NMin_ffmismatch.calc143');
        Observer.Observe('ffmismatch.h3', Format(H.NMin_ffmismatch));
        if not TryCalc_NMin_ffboth(H) then
            Observer.ObserveError('NMin_ffboth.calc144');
        Observer.Observe('ffboth.h3', Format(H.NMin_ffboth));
        Observer.Expect('const.h3', '-7');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '-7');
        Observer.Expect('constopt.h3', '-10.5');
        Observer.Expect('constenum.h3', '-7');
        Observer.Expect('filterenum.h3', '-10.5');
        Observer.Expect('ffint.h3', '-7');
        Observer.Expect('ffdec.h3', '-7');
        Observer.Expect('ffdate.h3', '-7');
        Observer.Expect('ffcode.h3', '-7');
        Observer.Expect('ffopt.h3', '-7');
        Observer.Expect('ffenum.h3', '-7');
        Observer.Expect('fftext.h3', '-7');
        Observer.Expect('uldate.h3', '-7');
        Observer.Expect('ulint.h3', '-7');
        Observer.Expect('uldec.h3', '-7');
        Observer.Expect('ulcode.h3', '-7');
        Observer.Expect('ulopt.h3', '-7');
        Observer.Expect('ulenum.h3', '-7');
        Observer.Expect('ulfdate.h3', '-7');
        Observer.Expect('ffmismatch.h3', '-7');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMax_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldMax with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Max_const(H) then
            Observer.ObserveError('Max_const.calc145');
        Observer.Observe('H1.const', Format(H.Max_const));
        if not TryCalc_Max_field(H) then
            Observer.ObserveError('Max_field.calc146');
        Observer.Observe('H1.field', Format(H.Max_field));
        if not TryCalc_Max_filter(H) then
            Observer.ObserveError('Max_filter.calc147');
        Observer.Observe('H1.filter', Format(H.Max_filter));
        if not TryCalc_Max_constopt(H) then
            Observer.ObserveError('Max_constopt.calc148');
        Observer.Observe('H1.constopt', Format(H.Max_constopt));
        if not TryCalc_Max_constenum(H) then
            Observer.ObserveError('Max_constenum.calc149');
        Observer.Observe('H1.constenum', Format(H.Max_constenum));
        if not TryCalc_Max_filterenum(H) then
            Observer.ObserveError('Max_filterenum.calc150');
        Observer.Observe('H1.filterenum', Format(H.Max_filterenum));
        H.Get('H2');
        if not TryCalc_Max_const(H) then
            Observer.ObserveError('Max_const.calc151');
        Observer.Observe('H2.const', Format(H.Max_const));
        if not TryCalc_Max_field(H) then
            Observer.ObserveError('Max_field.calc152');
        Observer.Observe('H2.field', Format(H.Max_field));
        if not TryCalc_Max_filter(H) then
            Observer.ObserveError('Max_filter.calc153');
        Observer.Observe('H2.filter', Format(H.Max_filter));
        if not TryCalc_Max_constopt(H) then
            Observer.ObserveError('Max_constopt.calc154');
        Observer.Observe('H2.constopt', Format(H.Max_constopt));
        if not TryCalc_Max_constenum(H) then
            Observer.ObserveError('Max_constenum.calc155');
        Observer.Observe('H2.constenum', Format(H.Max_constenum));
        if not TryCalc_Max_filterenum(H) then
            Observer.ObserveError('Max_filterenum.calc156');
        Observer.Observe('H2.filterenum', Format(H.Max_filterenum));
        H.Get('H3');
        if not TryCalc_Max_const(H) then
            Observer.ObserveError('Max_const.calc157');
        Observer.Observe('H3.const', Format(H.Max_const));
        if not TryCalc_Max_field(H) then
            Observer.ObserveError('Max_field.calc158');
        Observer.Observe('H3.field', Format(H.Max_field));
        if not TryCalc_Max_filter(H) then
            Observer.ObserveError('Max_filter.calc159');
        Observer.Observe('H3.filter', Format(H.Max_filter));
        if not TryCalc_Max_constopt(H) then
            Observer.ObserveError('Max_constopt.calc160');
        Observer.Observe('H3.constopt', Format(H.Max_constopt));
        if not TryCalc_Max_constenum(H) then
            Observer.ObserveError('Max_constenum.calc161');
        Observer.Observe('H3.constenum', Format(H.Max_constenum));
        if not TryCalc_Max_filterenum(H) then
            Observer.ObserveError('Max_filterenum.calc162');
        Observer.Observe('H3.filterenum', Format(H.Max_filterenum));
        Observer.Expect('H1.const', '40.25');
        Observer.Expect('H1.field', '80');
        Observer.Expect('H1.filter', '40.25');
        Observer.Expect('H1.constopt', '80');
        Observer.Expect('H1.constenum', '20');
        Observer.Expect('H1.filterenum', '80');
        Observer.Expect('H2.const', '40.25');
        Observer.Expect('H2.field', '14');
        Observer.Expect('H2.filter', '40.25');
        Observer.Expect('H2.constopt', '80');
        Observer.Expect('H2.constenum', '20');
        Observer.Expect('H2.filterenum', '80');
        Observer.Expect('H3.const', '40.25');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '40.25');
        Observer.Expect('H3.constopt', '80');
        Observer.Expect('H3.constenum', '20');
        Observer.Expect('H3.filterenum', '80');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMax_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldMax with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Max_ffint(H) then
            Observer.ObserveError('Max_ffint.calc163');
        Observer.Observe('ffint.unset', Format(H.Max_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Max_ffint(H) then
            Observer.ObserveError('Max_ffint.calc164');
        Observer.Observe('ffint.set', Format(H.Max_ffint));
        H.Reset();
        if not TryCalc_Max_ffdec(H) then
            Observer.ObserveError('Max_ffdec.calc165');
        Observer.Observe('ffdec.unset', Format(H.Max_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Max_ffdec(H) then
            Observer.ObserveError('Max_ffdec.calc166');
        Observer.Observe('ffdec.set', Format(H.Max_ffdec));
        H.Reset();
        if not TryCalc_Max_ffdate(H) then
            Observer.ObserveError('Max_ffdate.calc167');
        Observer.Observe('ffdate.unset', Format(H.Max_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Max_ffdate(H) then
            Observer.ObserveError('Max_ffdate.calc168');
        Observer.Observe('ffdate.set', Format(H.Max_ffdate));
        H.Reset();
        if not TryCalc_Max_ffcode(H) then
            Observer.ObserveError('Max_ffcode.calc169');
        Observer.Observe('ffcode.unset', Format(H.Max_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Max_ffcode(H) then
            Observer.ObserveError('Max_ffcode.calc170');
        Observer.Observe('ffcode.set', Format(H.Max_ffcode));
        H.Reset();
        if not TryCalc_Max_ffopt(H) then
            Observer.ObserveError('Max_ffopt.calc171');
        Observer.Observe('ffopt.unset', Format(H.Max_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Max_ffopt(H) then
            Observer.ObserveError('Max_ffopt.calc172');
        Observer.Observe('ffopt.set', Format(H.Max_ffopt));
        H.Reset();
        if not TryCalc_Max_ffenum(H) then
            Observer.ObserveError('Max_ffenum.calc173');
        Observer.Observe('ffenum.unset', Format(H.Max_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Max_ffenum(H) then
            Observer.ObserveError('Max_ffenum.calc174');
        Observer.Observe('ffenum.set', Format(H.Max_ffenum));
        H.Reset();
        if not TryCalc_Max_fftext(H) then
            Observer.ObserveError('Max_fftext.calc175');
        Observer.Observe('fftext.unset', Format(H.Max_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Max_fftext(H) then
            Observer.ObserveError('Max_fftext.calc176');
        Observer.Observe('fftext.set', Format(H.Max_fftext));
        Observer.Expect('ffint.unset', '80');
        Observer.Expect('ffint.set', '40.25');
        Observer.Expect('ffdec.unset', '80');
        Observer.Expect('ffdec.set', '80');
        Observer.Expect('ffdate.unset', '80');
        Observer.Expect('ffdate.set', '80');
        Observer.Expect('ffcode.unset', '80');
        Observer.Expect('ffcode.set', '40.25');
        Observer.Expect('ffopt.unset', '80');
        Observer.Expect('ffopt.set', '80');
        Observer.Expect('ffenum.unset', '80');
        Observer.Expect('ffenum.set', '40.25');
        Observer.Expect('fftext.unset', '80');
        Observer.Expect('fftext.set', '40.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMax_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldMax with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Max_uldate(H) then
            Observer.ObserveError('Max_uldate.calc177');
        Observer.Observe('uldate.unset', Format(H.Max_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Max_uldate(H) then
            Observer.ObserveError('Max_uldate.calc178');
        Observer.Observe('uldate.set', Format(H.Max_uldate));
        H.Reset();
        if not TryCalc_Max_ulint(H) then
            Observer.ObserveError('Max_ulint.calc179');
        Observer.Observe('ulint.unset', Format(H.Max_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Max_ulint(H) then
            Observer.ObserveError('Max_ulint.calc180');
        Observer.Observe('ulint.set', Format(H.Max_ulint));
        H.Reset();
        if not TryCalc_Max_uldec(H) then
            Observer.ObserveError('Max_uldec.calc181');
        Observer.Observe('uldec.unset', Format(H.Max_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Max_uldec(H) then
            Observer.ObserveError('Max_uldec.calc182');
        Observer.Observe('uldec.set', Format(H.Max_uldec));
        H.Reset();
        if not TryCalc_Max_ulcode(H) then
            Observer.ObserveError('Max_ulcode.calc183');
        Observer.Observe('ulcode.unset', Format(H.Max_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Max_ulcode(H) then
            Observer.ObserveError('Max_ulcode.calc184');
        Observer.Observe('ulcode.set', Format(H.Max_ulcode));
        H.Reset();
        if not TryCalc_Max_ulopt(H) then
            Observer.ObserveError('Max_ulopt.calc185');
        Observer.Observe('ulopt.unset', Format(H.Max_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Max_ulopt(H) then
            Observer.ObserveError('Max_ulopt.calc186');
        Observer.Observe('ulopt.set', Format(H.Max_ulopt));
        H.Reset();
        if not TryCalc_Max_ulenum(H) then
            Observer.ObserveError('Max_ulenum.calc187');
        Observer.Observe('ulenum.unset', Format(H.Max_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Max_ulenum(H) then
            Observer.ObserveError('Max_ulenum.calc188');
        Observer.Observe('ulenum.set', Format(H.Max_ulenum));
        H.Reset();
        if not TryCalc_Max_ulfdate(H) then
            Observer.ObserveError('Max_ulfdate.calc189');
        Observer.Observe('ulfdate.unset', Format(H.Max_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Max_ulfdate(H) then
            Observer.ObserveError('Max_ulfdate.calc190');
        Observer.Observe('ulfdate.set', Format(H.Max_ulfdate));
        Observer.Expect('uldate.unset', '80');
        Observer.Expect('uldate.set', '80');
        Observer.Expect('ulint.unset', '80');
        Observer.Expect('ulint.set', '40.25');
        Observer.Expect('uldec.unset', '80');
        Observer.Expect('Max_uldec.calc182|text', 'The filter expression ">=14" applied to the field DecF in the FFM MinMax Header table results in more than one range.');
        Observer.Expect('Max_uldec.calc182|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '80');
        Observer.Expect('ulcode.unset', '80');
        Observer.Expect('ulcode.set', '40.25');
        Observer.Expect('ulopt.unset', '80');
        Observer.Expect('ulopt.set', '80');
        Observer.Expect('ulenum.unset', '80');
        Observer.Expect('ulenum.set', '80');
        Observer.Expect('ulfdate.unset', '80');
        Observer.Expect('ulfdate.set', '80');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMax_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldMax with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Max_ffmismatch(H) then
            Observer.ObserveError('Max_ffmismatch.calc191');
        Observer.Observe('ffmismatch.unset', Format(H.Max_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Max_ffmismatch(H) then
            Observer.ObserveError('Max_ffmismatch.calc192');
        Observer.Observe('ffmismatch.set', Format(H.Max_ffmismatch));
        H.Reset();
        if not TryCalc_Max_ffboth(H) then
            Observer.ObserveError('Max_ffboth.calc193');
        Observer.Observe('ffboth.unset', Format(H.Max_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Max_ffboth(H) then
            Observer.ObserveError('Max_ffboth.calc194');
        Observer.Observe('ffboth.set', Format(H.Max_ffboth));
        Observer.Expect('ffmismatch.unset', '80');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '80');
        Observer.Expect('ffboth.set', '40.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldMax_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldMax over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Max_const(H) then
            Observer.ObserveError('Max_const.calc195');
        Observer.Observe('const.h3', Format(H.Max_const));
        if not TryCalc_Max_field(H) then
            Observer.ObserveError('Max_field.calc196');
        Observer.Observe('field.h3', Format(H.Max_field));
        if not TryCalc_Max_filter(H) then
            Observer.ObserveError('Max_filter.calc197');
        Observer.Observe('filter.h3', Format(H.Max_filter));
        if not TryCalc_Max_constopt(H) then
            Observer.ObserveError('Max_constopt.calc198');
        Observer.Observe('constopt.h3', Format(H.Max_constopt));
        if not TryCalc_Max_constenum(H) then
            Observer.ObserveError('Max_constenum.calc199');
        Observer.Observe('constenum.h3', Format(H.Max_constenum));
        if not TryCalc_Max_filterenum(H) then
            Observer.ObserveError('Max_filterenum.calc200');
        Observer.Observe('filterenum.h3', Format(H.Max_filterenum));
        if not TryCalc_Max_ffint(H) then
            Observer.ObserveError('Max_ffint.calc201');
        Observer.Observe('ffint.h3', Format(H.Max_ffint));
        if not TryCalc_Max_ffdec(H) then
            Observer.ObserveError('Max_ffdec.calc202');
        Observer.Observe('ffdec.h3', Format(H.Max_ffdec));
        if not TryCalc_Max_ffdate(H) then
            Observer.ObserveError('Max_ffdate.calc203');
        Observer.Observe('ffdate.h3', Format(H.Max_ffdate));
        if not TryCalc_Max_ffcode(H) then
            Observer.ObserveError('Max_ffcode.calc204');
        Observer.Observe('ffcode.h3', Format(H.Max_ffcode));
        if not TryCalc_Max_ffopt(H) then
            Observer.ObserveError('Max_ffopt.calc205');
        Observer.Observe('ffopt.h3', Format(H.Max_ffopt));
        if not TryCalc_Max_ffenum(H) then
            Observer.ObserveError('Max_ffenum.calc206');
        Observer.Observe('ffenum.h3', Format(H.Max_ffenum));
        if not TryCalc_Max_fftext(H) then
            Observer.ObserveError('Max_fftext.calc207');
        Observer.Observe('fftext.h3', Format(H.Max_fftext));
        if not TryCalc_Max_uldate(H) then
            Observer.ObserveError('Max_uldate.calc208');
        Observer.Observe('uldate.h3', Format(H.Max_uldate));
        if not TryCalc_Max_ulint(H) then
            Observer.ObserveError('Max_ulint.calc209');
        Observer.Observe('ulint.h3', Format(H.Max_ulint));
        if not TryCalc_Max_uldec(H) then
            Observer.ObserveError('Max_uldec.calc210');
        Observer.Observe('uldec.h3', Format(H.Max_uldec));
        if not TryCalc_Max_ulcode(H) then
            Observer.ObserveError('Max_ulcode.calc211');
        Observer.Observe('ulcode.h3', Format(H.Max_ulcode));
        if not TryCalc_Max_ulopt(H) then
            Observer.ObserveError('Max_ulopt.calc212');
        Observer.Observe('ulopt.h3', Format(H.Max_ulopt));
        if not TryCalc_Max_ulenum(H) then
            Observer.ObserveError('Max_ulenum.calc213');
        Observer.Observe('ulenum.h3', Format(H.Max_ulenum));
        if not TryCalc_Max_ulfdate(H) then
            Observer.ObserveError('Max_ulfdate.calc214');
        Observer.Observe('ulfdate.h3', Format(H.Max_ulfdate));
        if not TryCalc_Max_ffmismatch(H) then
            Observer.ObserveError('Max_ffmismatch.calc215');
        Observer.Observe('ffmismatch.h3', Format(H.Max_ffmismatch));
        if not TryCalc_Max_ffboth(H) then
            Observer.ObserveError('Max_ffboth.calc216');
        Observer.Observe('ffboth.h3', Format(H.Max_ffboth));
        Observer.Expect('const.h3', '40.25');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '40.25');
        Observer.Expect('constopt.h3', '80');
        Observer.Expect('constenum.h3', '20');
        Observer.Expect('filterenum.h3', '80');
        Observer.Expect('ffint.h3', '80');
        Observer.Expect('ffdec.h3', '80');
        Observer.Expect('ffdate.h3', '80');
        Observer.Expect('ffcode.h3', '80');
        Observer.Expect('ffopt.h3', '80');
        Observer.Expect('ffenum.h3', '80');
        Observer.Expect('fftext.h3', '80');
        Observer.Expect('uldate.h3', '80');
        Observer.Expect('ulint.h3', '80');
        Observer.Expect('uldec.h3', '80');
        Observer.Expect('ulcode.h3', '80');
        Observer.Expect('ulopt.h3', '80');
        Observer.Expect('ulenum.h3', '80');
        Observer.Expect('ulfdate.h3', '80');
        Observer.Expect('ffmismatch.h3', '80');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMax_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedMax with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NMax_const(H) then
            Observer.ObserveError('NMax_const.calc217');
        Observer.Observe('H1.const', Format(H.NMax_const));
        if not TryCalc_NMax_field(H) then
            Observer.ObserveError('NMax_field.calc218');
        Observer.Observe('H1.field', Format(H.NMax_field));
        if not TryCalc_NMax_filter(H) then
            Observer.ObserveError('NMax_filter.calc219');
        Observer.Observe('H1.filter', Format(H.NMax_filter));
        if not TryCalc_NMax_constopt(H) then
            Observer.ObserveError('NMax_constopt.calc220');
        Observer.Observe('H1.constopt', Format(H.NMax_constopt));
        if not TryCalc_NMax_constenum(H) then
            Observer.ObserveError('NMax_constenum.calc221');
        Observer.Observe('H1.constenum', Format(H.NMax_constenum));
        if not TryCalc_NMax_filterenum(H) then
            Observer.ObserveError('NMax_filterenum.calc222');
        Observer.Observe('H1.filterenum', Format(H.NMax_filterenum));
        H.Get('H2');
        if not TryCalc_NMax_const(H) then
            Observer.ObserveError('NMax_const.calc223');
        Observer.Observe('H2.const', Format(H.NMax_const));
        if not TryCalc_NMax_field(H) then
            Observer.ObserveError('NMax_field.calc224');
        Observer.Observe('H2.field', Format(H.NMax_field));
        if not TryCalc_NMax_filter(H) then
            Observer.ObserveError('NMax_filter.calc225');
        Observer.Observe('H2.filter', Format(H.NMax_filter));
        if not TryCalc_NMax_constopt(H) then
            Observer.ObserveError('NMax_constopt.calc226');
        Observer.Observe('H2.constopt', Format(H.NMax_constopt));
        if not TryCalc_NMax_constenum(H) then
            Observer.ObserveError('NMax_constenum.calc227');
        Observer.Observe('H2.constenum', Format(H.NMax_constenum));
        if not TryCalc_NMax_filterenum(H) then
            Observer.ObserveError('NMax_filterenum.calc228');
        Observer.Observe('H2.filterenum', Format(H.NMax_filterenum));
        H.Get('H3');
        if not TryCalc_NMax_const(H) then
            Observer.ObserveError('NMax_const.calc229');
        Observer.Observe('H3.const', Format(H.NMax_const));
        if not TryCalc_NMax_field(H) then
            Observer.ObserveError('NMax_field.calc230');
        Observer.Observe('H3.field', Format(H.NMax_field));
        if not TryCalc_NMax_filter(H) then
            Observer.ObserveError('NMax_filter.calc231');
        Observer.Observe('H3.filter', Format(H.NMax_filter));
        if not TryCalc_NMax_constopt(H) then
            Observer.ObserveError('NMax_constopt.calc232');
        Observer.Observe('H3.constopt', Format(H.NMax_constopt));
        if not TryCalc_NMax_constenum(H) then
            Observer.ObserveError('NMax_constenum.calc233');
        Observer.Observe('H3.constenum', Format(H.NMax_constenum));
        if not TryCalc_NMax_filterenum(H) then
            Observer.ObserveError('NMax_filterenum.calc234');
        Observer.Observe('H3.filterenum', Format(H.NMax_filterenum));
        Observer.Expect('H1.const', '-40.25');
        Observer.Expect('H1.field', '-80');
        Observer.Expect('H1.filter', '-40.25');
        Observer.Expect('H1.constopt', '-80');
        Observer.Expect('H1.constenum', '-20');
        Observer.Expect('H1.filterenum', '-80');
        Observer.Expect('H2.const', '-40.25');
        Observer.Expect('H2.field', '-14');
        Observer.Expect('H2.filter', '-40.25');
        Observer.Expect('H2.constopt', '-80');
        Observer.Expect('H2.constenum', '-20');
        Observer.Expect('H2.filterenum', '-80');
        Observer.Expect('H3.const', '-40.25');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '-40.25');
        Observer.Expect('H3.constopt', '-80');
        Observer.Expect('H3.constenum', '-20');
        Observer.Expect('H3.filterenum', '-80');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMax_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMax with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMax_ffint(H) then
            Observer.ObserveError('NMax_ffint.calc235');
        Observer.Observe('ffint.unset', Format(H.NMax_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMax_ffint(H) then
            Observer.ObserveError('NMax_ffint.calc236');
        Observer.Observe('ffint.set', Format(H.NMax_ffint));
        H.Reset();
        if not TryCalc_NMax_ffdec(H) then
            Observer.ObserveError('NMax_ffdec.calc237');
        Observer.Observe('ffdec.unset', Format(H.NMax_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NMax_ffdec(H) then
            Observer.ObserveError('NMax_ffdec.calc238');
        Observer.Observe('ffdec.set', Format(H.NMax_ffdec));
        H.Reset();
        if not TryCalc_NMax_ffdate(H) then
            Observer.ObserveError('NMax_ffdate.calc239');
        Observer.Observe('ffdate.unset', Format(H.NMax_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMax_ffdate(H) then
            Observer.ObserveError('NMax_ffdate.calc240');
        Observer.Observe('ffdate.set', Format(H.NMax_ffdate));
        H.Reset();
        if not TryCalc_NMax_ffcode(H) then
            Observer.ObserveError('NMax_ffcode.calc241');
        Observer.Observe('ffcode.unset', Format(H.NMax_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NMax_ffcode(H) then
            Observer.ObserveError('NMax_ffcode.calc242');
        Observer.Observe('ffcode.set', Format(H.NMax_ffcode));
        H.Reset();
        if not TryCalc_NMax_ffopt(H) then
            Observer.ObserveError('NMax_ffopt.calc243');
        Observer.Observe('ffopt.unset', Format(H.NMax_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NMax_ffopt(H) then
            Observer.ObserveError('NMax_ffopt.calc244');
        Observer.Observe('ffopt.set', Format(H.NMax_ffopt));
        H.Reset();
        if not TryCalc_NMax_ffenum(H) then
            Observer.ObserveError('NMax_ffenum.calc245');
        Observer.Observe('ffenum.unset', Format(H.NMax_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NMax_ffenum(H) then
            Observer.ObserveError('NMax_ffenum.calc246');
        Observer.Observe('ffenum.set', Format(H.NMax_ffenum));
        H.Reset();
        if not TryCalc_NMax_fftext(H) then
            Observer.ObserveError('NMax_fftext.calc247');
        Observer.Observe('fftext.unset', Format(H.NMax_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NMax_fftext(H) then
            Observer.ObserveError('NMax_fftext.calc248');
        Observer.Observe('fftext.set', Format(H.NMax_fftext));
        Observer.Expect('ffint.unset', '-80');
        Observer.Expect('ffint.set', '-40.25');
        Observer.Expect('ffdec.unset', '-80');
        Observer.Expect('ffdec.set', '-80');
        Observer.Expect('ffdate.unset', '-80');
        Observer.Expect('ffdate.set', '-80');
        Observer.Expect('ffcode.unset', '-80');
        Observer.Expect('ffcode.set', '-40.25');
        Observer.Expect('ffopt.unset', '-80');
        Observer.Expect('ffopt.set', '-80');
        Observer.Expect('ffenum.unset', '-80');
        Observer.Expect('ffenum.set', '-40.25');
        Observer.Expect('fftext.unset', '-80');
        Observer.Expect('fftext.set', '-40.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMax_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMax with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMax_uldate(H) then
            Observer.ObserveError('NMax_uldate.calc249');
        Observer.Observe('uldate.unset', Format(H.NMax_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMax_uldate(H) then
            Observer.ObserveError('NMax_uldate.calc250');
        Observer.Observe('uldate.set', Format(H.NMax_uldate));
        H.Reset();
        if not TryCalc_NMax_ulint(H) then
            Observer.ObserveError('NMax_ulint.calc251');
        Observer.Observe('ulint.unset', Format(H.NMax_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMax_ulint(H) then
            Observer.ObserveError('NMax_ulint.calc252');
        Observer.Observe('ulint.set', Format(H.NMax_ulint));
        H.Reset();
        if not TryCalc_NMax_uldec(H) then
            Observer.ObserveError('NMax_uldec.calc253');
        Observer.Observe('uldec.unset', Format(H.NMax_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NMax_uldec(H) then
            Observer.ObserveError('NMax_uldec.calc254');
        Observer.Observe('uldec.set', Format(H.NMax_uldec));
        H.Reset();
        if not TryCalc_NMax_ulcode(H) then
            Observer.ObserveError('NMax_ulcode.calc255');
        Observer.Observe('ulcode.unset', Format(H.NMax_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NMax_ulcode(H) then
            Observer.ObserveError('NMax_ulcode.calc256');
        Observer.Observe('ulcode.set', Format(H.NMax_ulcode));
        H.Reset();
        if not TryCalc_NMax_ulopt(H) then
            Observer.ObserveError('NMax_ulopt.calc257');
        Observer.Observe('ulopt.unset', Format(H.NMax_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NMax_ulopt(H) then
            Observer.ObserveError('NMax_ulopt.calc258');
        Observer.Observe('ulopt.set', Format(H.NMax_ulopt));
        H.Reset();
        if not TryCalc_NMax_ulenum(H) then
            Observer.ObserveError('NMax_ulenum.calc259');
        Observer.Observe('ulenum.unset', Format(H.NMax_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NMax_ulenum(H) then
            Observer.ObserveError('NMax_ulenum.calc260');
        Observer.Observe('ulenum.set', Format(H.NMax_ulenum));
        H.Reset();
        if not TryCalc_NMax_ulfdate(H) then
            Observer.ObserveError('NMax_ulfdate.calc261');
        Observer.Observe('ulfdate.unset', Format(H.NMax_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMax_ulfdate(H) then
            Observer.ObserveError('NMax_ulfdate.calc262');
        Observer.Observe('ulfdate.set', Format(H.NMax_ulfdate));
        Observer.Expect('uldate.unset', '-80');
        Observer.Expect('uldate.set', '-80');
        Observer.Expect('ulint.unset', '-80');
        Observer.Expect('ulint.set', '-40.25');
        Observer.Expect('uldec.unset', '-80');
        Observer.Expect('NMax_uldec.calc254|text', 'The filter expression ">=14" applied to the field DecF in the FFM MinMax Header table results in more than one range.');
        Observer.Expect('NMax_uldec.calc254|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '-80');
        Observer.Expect('ulcode.unset', '-80');
        Observer.Expect('ulcode.set', '-40.25');
        Observer.Expect('ulopt.unset', '-80');
        Observer.Expect('ulopt.set', '-80');
        Observer.Expect('ulenum.unset', '-80');
        Observer.Expect('ulenum.set', '-80');
        Observer.Expect('ulfdate.unset', '-80');
        Observer.Expect('ulfdate.set', '-80');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMax_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedMax with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NMax_ffmismatch(H) then
            Observer.ObserveError('NMax_ffmismatch.calc263');
        Observer.Observe('ffmismatch.unset', Format(H.NMax_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NMax_ffmismatch(H) then
            Observer.ObserveError('NMax_ffmismatch.calc264');
        Observer.Observe('ffmismatch.set', Format(H.NMax_ffmismatch));
        H.Reset();
        if not TryCalc_NMax_ffboth(H) then
            Observer.ObserveError('NMax_ffboth.calc265');
        Observer.Observe('ffboth.unset', Format(H.NMax_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NMax_ffboth(H) then
            Observer.ObserveError('NMax_ffboth.calc266');
        Observer.Observe('ffboth.set', Format(H.NMax_ffboth));
        Observer.Expect('ffmismatch.unset', '-80');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '-80');
        Observer.Expect('ffboth.set', '-40.25');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedMax_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedMax over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NMax_const(H) then
            Observer.ObserveError('NMax_const.calc267');
        Observer.Observe('const.h3', Format(H.NMax_const));
        if not TryCalc_NMax_field(H) then
            Observer.ObserveError('NMax_field.calc268');
        Observer.Observe('field.h3', Format(H.NMax_field));
        if not TryCalc_NMax_filter(H) then
            Observer.ObserveError('NMax_filter.calc269');
        Observer.Observe('filter.h3', Format(H.NMax_filter));
        if not TryCalc_NMax_constopt(H) then
            Observer.ObserveError('NMax_constopt.calc270');
        Observer.Observe('constopt.h3', Format(H.NMax_constopt));
        if not TryCalc_NMax_constenum(H) then
            Observer.ObserveError('NMax_constenum.calc271');
        Observer.Observe('constenum.h3', Format(H.NMax_constenum));
        if not TryCalc_NMax_filterenum(H) then
            Observer.ObserveError('NMax_filterenum.calc272');
        Observer.Observe('filterenum.h3', Format(H.NMax_filterenum));
        if not TryCalc_NMax_ffint(H) then
            Observer.ObserveError('NMax_ffint.calc273');
        Observer.Observe('ffint.h3', Format(H.NMax_ffint));
        if not TryCalc_NMax_ffdec(H) then
            Observer.ObserveError('NMax_ffdec.calc274');
        Observer.Observe('ffdec.h3', Format(H.NMax_ffdec));
        if not TryCalc_NMax_ffdate(H) then
            Observer.ObserveError('NMax_ffdate.calc275');
        Observer.Observe('ffdate.h3', Format(H.NMax_ffdate));
        if not TryCalc_NMax_ffcode(H) then
            Observer.ObserveError('NMax_ffcode.calc276');
        Observer.Observe('ffcode.h3', Format(H.NMax_ffcode));
        if not TryCalc_NMax_ffopt(H) then
            Observer.ObserveError('NMax_ffopt.calc277');
        Observer.Observe('ffopt.h3', Format(H.NMax_ffopt));
        if not TryCalc_NMax_ffenum(H) then
            Observer.ObserveError('NMax_ffenum.calc278');
        Observer.Observe('ffenum.h3', Format(H.NMax_ffenum));
        if not TryCalc_NMax_fftext(H) then
            Observer.ObserveError('NMax_fftext.calc279');
        Observer.Observe('fftext.h3', Format(H.NMax_fftext));
        if not TryCalc_NMax_uldate(H) then
            Observer.ObserveError('NMax_uldate.calc280');
        Observer.Observe('uldate.h3', Format(H.NMax_uldate));
        if not TryCalc_NMax_ulint(H) then
            Observer.ObserveError('NMax_ulint.calc281');
        Observer.Observe('ulint.h3', Format(H.NMax_ulint));
        if not TryCalc_NMax_uldec(H) then
            Observer.ObserveError('NMax_uldec.calc282');
        Observer.Observe('uldec.h3', Format(H.NMax_uldec));
        if not TryCalc_NMax_ulcode(H) then
            Observer.ObserveError('NMax_ulcode.calc283');
        Observer.Observe('ulcode.h3', Format(H.NMax_ulcode));
        if not TryCalc_NMax_ulopt(H) then
            Observer.ObserveError('NMax_ulopt.calc284');
        Observer.Observe('ulopt.h3', Format(H.NMax_ulopt));
        if not TryCalc_NMax_ulenum(H) then
            Observer.ObserveError('NMax_ulenum.calc285');
        Observer.Observe('ulenum.h3', Format(H.NMax_ulenum));
        if not TryCalc_NMax_ulfdate(H) then
            Observer.ObserveError('NMax_ulfdate.calc286');
        Observer.Observe('ulfdate.h3', Format(H.NMax_ulfdate));
        if not TryCalc_NMax_ffmismatch(H) then
            Observer.ObserveError('NMax_ffmismatch.calc287');
        Observer.Observe('ffmismatch.h3', Format(H.NMax_ffmismatch));
        if not TryCalc_NMax_ffboth(H) then
            Observer.ObserveError('NMax_ffboth.calc288');
        Observer.Observe('ffboth.h3', Format(H.NMax_ffboth));
        Observer.Expect('const.h3', '-40.25');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '-40.25');
        Observer.Expect('constopt.h3', '-80');
        Observer.Expect('constenum.h3', '-20');
        Observer.Expect('filterenum.h3', '-80');
        Observer.Expect('ffint.h3', '-80');
        Observer.Expect('ffdec.h3', '-80');
        Observer.Expect('ffdate.h3', '-80');
        Observer.Expect('ffcode.h3', '-80');
        Observer.Expect('ffopt.h3', '-80');
        Observer.Expect('ffenum.h3', '-80');
        Observer.Expect('fftext.h3', '-80');
        Observer.Expect('uldate.h3', '-80');
        Observer.Expect('ulint.h3', '-80');
        Observer.Expect('uldec.h3', '-80');
        Observer.Expect('ulcode.h3', '-80');
        Observer.Expect('ulopt.h3', '-80');
        Observer.Expect('ulenum.h3', '-80');
        Observer.Expect('ulfdate.h3', '-80');
        Observer.Expect('ffmismatch.h3', '-80');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        D: Record "FFM MinMax Detail";
        H: Record "FFM MinMax Header";
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
        D: Record "FFM MinMax Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Qty := Quantity;
        D.Amt := Amount;
        D.Day := Date;
        D.Kind := KindCode;
        D.Opt := Option;
        D.Status := "FFM MinMax Status".FromInteger(StatusValue);
        D.Flag := FlagValue;
        D.Name := NameValue;
        D.Insert();
    end;

    local procedure AddHeader(HeaderCode: Code[10])
    var
        H: Record "FFM MinMax Header";
    begin
        H.Init();
        H.Code := HeaderCode;
        H.Insert();
    end;
}
