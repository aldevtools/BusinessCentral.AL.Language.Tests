// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM CountExist *)
// local object: the CalcFormula definitions are what the tests measure.
// Area: FlowField and FlowFilter matrix, CalcFormula kinds count, -count, exist, -exist crossed with the where-clause forms (const, field, filter,
//   field(filter(F)) over Integer, Decimal, Date, Code, Option, Enum and Text FlowFilters, field(upperlimit(F)), field(upperlimit(filter(F))))
//   and the two states of every FlowFilter (not set, set), read with CalcFields on a record with rows, and on a record with no match.
//   The shapes BC rejects at compile time are pinned in tests/must-not-compile/cases (upperlimit outside field()).
// Nearby: record/flowfields/Y17SumWhereFlowField.al, record/flowfields/CalcFormulaDateLiteral.al, TestCalcFormulaFlowFiltersTests.Codeunit.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

enum 64200 "FFM CountExist Status"
{
    Extensible = true;
    value(0; Open) { }
    value(1; Closed) { }
    value(2; Held) { }
}

table 64201 "FFM CountExist Detail"
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
        field(8; Status; Enum "FFM CountExist Status") { }
        field(9; Flag; Boolean) { }
        field(10; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64202 "FFM CountExist Header"
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
        field(7; EnumF; Enum "FFM CountExist Status") { FieldClass = FlowFilter; }
        field(8; TextF; Text[30]) { FieldClass = FlowFilter; }
        field(100; Cnt_const; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Kind = const('K1'))); }
        field(101; Cnt_field; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Owner = field(Code))); }
        field(102; Cnt_filter; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Qty = filter(2..5))); }
        field(103; Cnt_constopt; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Opt = const(B))); }
        field(104; Cnt_constenum; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Status = const(Closed))); }
        field(105; Cnt_filterenum; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Status = filter(Open|Held))); }
        field(106; Cnt_ffint; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Qty = field(filter(IntF)))); }
        field(107; Cnt_ffdec; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Amt = field(filter(DecF)))); }
        field(108; Cnt_ffdate; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Day = field(filter(DateF)))); }
        field(109; Cnt_ffcode; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Kind = field(filter(CodeF)))); }
        field(110; Cnt_ffopt; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Opt = field(filter(OptF)))); }
        field(111; Cnt_ffenum; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Status = field(filter(EnumF)))); }
        field(112; Cnt_fftext; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Name = field(filter(TextF)))); }
        field(113; Cnt_uldate; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Day = field(upperlimit(DateF)))); }
        field(114; Cnt_ulint; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Qty = field(upperlimit(IntF)))); }
        field(115; Cnt_uldec; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Amt = field(upperlimit(DecF)))); }
        field(116; Cnt_ulcode; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Kind = field(upperlimit(CodeF)))); }
        field(117; Cnt_ulopt; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Opt = field(upperlimit(OptF)))); }
        field(118; Cnt_ulenum; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Status = field(upperlimit(EnumF)))); }
        field(119; Cnt_ulfdate; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Day = field(upperlimit(filter(DateF))))); }
        field(120; Cnt_ffmismatch; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Qty = field(filter(DateF)))); }
        field(121; Cnt_ffboth; Integer) { FieldClass = FlowField; CalcFormula = count("FFM CountExist Detail" where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(122; NCnt_const; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Kind = const('K1'))); }
        field(123; NCnt_field; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Owner = field(Code))); }
        field(124; NCnt_filter; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Qty = filter(2..5))); }
        field(125; NCnt_constopt; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Opt = const(B))); }
        field(126; NCnt_constenum; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Status = const(Closed))); }
        field(127; NCnt_filterenum; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Status = filter(Open|Held))); }
        field(128; NCnt_ffint; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Qty = field(filter(IntF)))); }
        field(129; NCnt_ffdec; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Amt = field(filter(DecF)))); }
        field(130; NCnt_ffdate; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Day = field(filter(DateF)))); }
        field(131; NCnt_ffcode; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Kind = field(filter(CodeF)))); }
        field(132; NCnt_ffopt; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Opt = field(filter(OptF)))); }
        field(133; NCnt_ffenum; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Status = field(filter(EnumF)))); }
        field(134; NCnt_fftext; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Name = field(filter(TextF)))); }
        field(135; NCnt_uldate; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Day = field(upperlimit(DateF)))); }
        field(136; NCnt_ulint; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Qty = field(upperlimit(IntF)))); }
        field(137; NCnt_uldec; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Amt = field(upperlimit(DecF)))); }
        field(138; NCnt_ulcode; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Kind = field(upperlimit(CodeF)))); }
        field(139; NCnt_ulopt; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Opt = field(upperlimit(OptF)))); }
        field(140; NCnt_ulenum; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Status = field(upperlimit(EnumF)))); }
        field(141; NCnt_ulfdate; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Day = field(upperlimit(filter(DateF))))); }
        field(142; NCnt_ffmismatch; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Qty = field(filter(DateF)))); }
        field(143; NCnt_ffboth; Integer) { FieldClass = FlowField; CalcFormula = -count("FFM CountExist Detail" where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(144; Ex_const; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Kind = const('K1'))); }
        field(145; Ex_field; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Owner = field(Code))); }
        field(146; Ex_filter; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Qty = filter(2..5))); }
        field(147; Ex_constopt; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Opt = const(B))); }
        field(148; Ex_constenum; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Status = const(Closed))); }
        field(149; Ex_filterenum; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Status = filter(Open|Held))); }
        field(150; Ex_ffint; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Qty = field(filter(IntF)))); }
        field(151; Ex_ffdec; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Amt = field(filter(DecF)))); }
        field(152; Ex_ffdate; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Day = field(filter(DateF)))); }
        field(153; Ex_ffcode; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Kind = field(filter(CodeF)))); }
        field(154; Ex_ffopt; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Opt = field(filter(OptF)))); }
        field(155; Ex_ffenum; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Status = field(filter(EnumF)))); }
        field(156; Ex_fftext; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Name = field(filter(TextF)))); }
        field(157; Ex_uldate; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Day = field(upperlimit(DateF)))); }
        field(158; Ex_ulint; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Qty = field(upperlimit(IntF)))); }
        field(159; Ex_uldec; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Amt = field(upperlimit(DecF)))); }
        field(160; Ex_ulcode; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Kind = field(upperlimit(CodeF)))); }
        field(161; Ex_ulopt; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Opt = field(upperlimit(OptF)))); }
        field(162; Ex_ulenum; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Status = field(upperlimit(EnumF)))); }
        field(163; Ex_ulfdate; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Day = field(upperlimit(filter(DateF))))); }
        field(164; Ex_ffmismatch; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Qty = field(filter(DateF)))); }
        field(165; Ex_ffboth; Boolean) { FieldClass = FlowField; CalcFormula = exist("FFM CountExist Detail" where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(166; NEx_const; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Kind = const('K1'))); }
        field(167; NEx_field; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Owner = field(Code))); }
        field(168; NEx_filter; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Qty = filter(2..5))); }
        field(169; NEx_constopt; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Opt = const(B))); }
        field(170; NEx_constenum; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Status = const(Closed))); }
        field(171; NEx_filterenum; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Status = filter(Open|Held))); }
        field(172; NEx_ffint; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Qty = field(filter(IntF)))); }
        field(173; NEx_ffdec; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Amt = field(filter(DecF)))); }
        field(174; NEx_ffdate; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Day = field(filter(DateF)))); }
        field(175; NEx_ffcode; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Kind = field(filter(CodeF)))); }
        field(176; NEx_ffopt; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Opt = field(filter(OptF)))); }
        field(177; NEx_ffenum; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Status = field(filter(EnumF)))); }
        field(178; NEx_fftext; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Name = field(filter(TextF)))); }
        field(179; NEx_uldate; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Day = field(upperlimit(DateF)))); }
        field(180; NEx_ulint; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Qty = field(upperlimit(IntF)))); }
        field(181; NEx_uldec; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Amt = field(upperlimit(DecF)))); }
        field(182; NEx_ulcode; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Kind = field(upperlimit(CodeF)))); }
        field(183; NEx_ulopt; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Opt = field(upperlimit(OptF)))); }
        field(184; NEx_ulenum; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Status = field(upperlimit(EnumF)))); }
        field(185; NEx_ulfdate; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Day = field(upperlimit(filter(DateF))))); }
        field(186; NEx_ffmismatch; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Qty = field(filter(DateF)))); }
        field(187; NEx_ffboth; Boolean) { FieldClass = FlowField; CalcFormula = -exist("FFM CountExist Detail" where(Owner = field(Code), Qty = field(filter(IntF)))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 64203 "FFM CountExist Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryCalc_Cnt_const(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_const);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_field(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_field);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_filter(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_constopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_constenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_filterenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffdec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_fftext(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_uldate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ulint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_uldec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ulcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ulopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ulenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ulfdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffmismatch(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Cnt_ffboth(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Cnt_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_const(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_const);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_field(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_field);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_filter(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_constopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_constenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_filterenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffdec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_fftext(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_uldate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ulint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_uldec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ulcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ulopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ulenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ulfdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffmismatch(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Ex_ffboth(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(Ex_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_const(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_const);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_field(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_field);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_filter(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_constopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_constenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_filterenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffdec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_fftext(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_uldate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ulint(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_uldec(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ulcode(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ulopt(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ulenum(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ulfdate(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffmismatch(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NEx_ffboth(var H: Record "FFM CountExist Header")
    begin
        H.CalcFields(NEx_ffboth);
    end;

    [Test]
    procedure FlowFieldCount_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldCount with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Cnt_const(H) then
            Observer.ObserveError('Cnt_const.calc1');
        Observer.Observe('H1.const', Format(H.Cnt_const));
        if not TryCalc_Cnt_field(H) then
            Observer.ObserveError('Cnt_field.calc2');
        Observer.Observe('H1.field', Format(H.Cnt_field));
        if not TryCalc_Cnt_filter(H) then
            Observer.ObserveError('Cnt_filter.calc3');
        Observer.Observe('H1.filter', Format(H.Cnt_filter));
        if not TryCalc_Cnt_constopt(H) then
            Observer.ObserveError('Cnt_constopt.calc4');
        Observer.Observe('H1.constopt', Format(H.Cnt_constopt));
        if not TryCalc_Cnt_constenum(H) then
            Observer.ObserveError('Cnt_constenum.calc5');
        Observer.Observe('H1.constenum', Format(H.Cnt_constenum));
        if not TryCalc_Cnt_filterenum(H) then
            Observer.ObserveError('Cnt_filterenum.calc6');
        Observer.Observe('H1.filterenum', Format(H.Cnt_filterenum));
        H.Get('H2');
        if not TryCalc_Cnt_const(H) then
            Observer.ObserveError('Cnt_const.calc7');
        Observer.Observe('H2.const', Format(H.Cnt_const));
        if not TryCalc_Cnt_field(H) then
            Observer.ObserveError('Cnt_field.calc8');
        Observer.Observe('H2.field', Format(H.Cnt_field));
        if not TryCalc_Cnt_filter(H) then
            Observer.ObserveError('Cnt_filter.calc9');
        Observer.Observe('H2.filter', Format(H.Cnt_filter));
        if not TryCalc_Cnt_constopt(H) then
            Observer.ObserveError('Cnt_constopt.calc10');
        Observer.Observe('H2.constopt', Format(H.Cnt_constopt));
        if not TryCalc_Cnt_constenum(H) then
            Observer.ObserveError('Cnt_constenum.calc11');
        Observer.Observe('H2.constenum', Format(H.Cnt_constenum));
        if not TryCalc_Cnt_filterenum(H) then
            Observer.ObserveError('Cnt_filterenum.calc12');
        Observer.Observe('H2.filterenum', Format(H.Cnt_filterenum));
        H.Get('H3');
        if not TryCalc_Cnt_const(H) then
            Observer.ObserveError('Cnt_const.calc13');
        Observer.Observe('H3.const', Format(H.Cnt_const));
        if not TryCalc_Cnt_field(H) then
            Observer.ObserveError('Cnt_field.calc14');
        Observer.Observe('H3.field', Format(H.Cnt_field));
        if not TryCalc_Cnt_filter(H) then
            Observer.ObserveError('Cnt_filter.calc15');
        Observer.Observe('H3.filter', Format(H.Cnt_filter));
        if not TryCalc_Cnt_constopt(H) then
            Observer.ObserveError('Cnt_constopt.calc16');
        Observer.Observe('H3.constopt', Format(H.Cnt_constopt));
        if not TryCalc_Cnt_constenum(H) then
            Observer.ObserveError('Cnt_constenum.calc17');
        Observer.Observe('H3.constenum', Format(H.Cnt_constenum));
        if not TryCalc_Cnt_filterenum(H) then
            Observer.ObserveError('Cnt_filterenum.calc18');
        Observer.Observe('H3.filterenum', Format(H.Cnt_filterenum));
        Observer.Expect('H1.const', '3');
        Observer.Expect('H1.field', '4');
        Observer.Expect('H1.filter', '4');
        Observer.Expect('H1.constopt', '2');
        Observer.Expect('H1.constenum', '2');
        Observer.Expect('H1.filterenum', '4');
        Observer.Expect('H2.const', '3');
        Observer.Expect('H2.field', '2');
        Observer.Expect('H2.filter', '4');
        Observer.Expect('H2.constopt', '2');
        Observer.Expect('H2.constenum', '2');
        Observer.Expect('H2.filterenum', '4');
        Observer.Expect('H3.const', '3');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '4');
        Observer.Expect('H3.constopt', '2');
        Observer.Expect('H3.constenum', '2');
        Observer.Expect('H3.filterenum', '4');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldCount_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldCount with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Cnt_ffint(H) then
            Observer.ObserveError('Cnt_ffint.calc19');
        Observer.Observe('ffint.unset', Format(H.Cnt_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Cnt_ffint(H) then
            Observer.ObserveError('Cnt_ffint.calc20');
        Observer.Observe('ffint.set', Format(H.Cnt_ffint));
        H.Reset();
        if not TryCalc_Cnt_ffdec(H) then
            Observer.ObserveError('Cnt_ffdec.calc21');
        Observer.Observe('ffdec.unset', Format(H.Cnt_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Cnt_ffdec(H) then
            Observer.ObserveError('Cnt_ffdec.calc22');
        Observer.Observe('ffdec.set', Format(H.Cnt_ffdec));
        H.Reset();
        if not TryCalc_Cnt_ffdate(H) then
            Observer.ObserveError('Cnt_ffdate.calc23');
        Observer.Observe('ffdate.unset', Format(H.Cnt_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Cnt_ffdate(H) then
            Observer.ObserveError('Cnt_ffdate.calc24');
        Observer.Observe('ffdate.set', Format(H.Cnt_ffdate));
        H.Reset();
        if not TryCalc_Cnt_ffcode(H) then
            Observer.ObserveError('Cnt_ffcode.calc25');
        Observer.Observe('ffcode.unset', Format(H.Cnt_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Cnt_ffcode(H) then
            Observer.ObserveError('Cnt_ffcode.calc26');
        Observer.Observe('ffcode.set', Format(H.Cnt_ffcode));
        H.Reset();
        if not TryCalc_Cnt_ffopt(H) then
            Observer.ObserveError('Cnt_ffopt.calc27');
        Observer.Observe('ffopt.unset', Format(H.Cnt_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Cnt_ffopt(H) then
            Observer.ObserveError('Cnt_ffopt.calc28');
        Observer.Observe('ffopt.set', Format(H.Cnt_ffopt));
        H.Reset();
        if not TryCalc_Cnt_ffenum(H) then
            Observer.ObserveError('Cnt_ffenum.calc29');
        Observer.Observe('ffenum.unset', Format(H.Cnt_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Cnt_ffenum(H) then
            Observer.ObserveError('Cnt_ffenum.calc30');
        Observer.Observe('ffenum.set', Format(H.Cnt_ffenum));
        H.Reset();
        if not TryCalc_Cnt_fftext(H) then
            Observer.ObserveError('Cnt_fftext.calc31');
        Observer.Observe('fftext.unset', Format(H.Cnt_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Cnt_fftext(H) then
            Observer.ObserveError('Cnt_fftext.calc32');
        Observer.Observe('fftext.set', Format(H.Cnt_fftext));
        Observer.Expect('ffint.unset', '6');
        Observer.Expect('ffint.set', '3');
        Observer.Expect('ffdec.unset', '6');
        Observer.Expect('ffdec.set', '4');
        Observer.Expect('ffdate.unset', '6');
        Observer.Expect('ffdate.set', '3');
        Observer.Expect('ffcode.unset', '6');
        Observer.Expect('ffcode.set', '3');
        Observer.Expect('ffopt.unset', '6');
        Observer.Expect('ffopt.set', '2');
        Observer.Expect('ffenum.unset', '6');
        Observer.Expect('ffenum.set', '4');
        Observer.Expect('fftext.unset', '6');
        Observer.Expect('fftext.set', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldCount_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldCount with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Cnt_uldate(H) then
            Observer.ObserveError('Cnt_uldate.calc33');
        Observer.Observe('uldate.unset', Format(H.Cnt_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Cnt_uldate(H) then
            Observer.ObserveError('Cnt_uldate.calc34');
        Observer.Observe('uldate.set', Format(H.Cnt_uldate));
        H.Reset();
        if not TryCalc_Cnt_ulint(H) then
            Observer.ObserveError('Cnt_ulint.calc35');
        Observer.Observe('ulint.unset', Format(H.Cnt_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Cnt_ulint(H) then
            Observer.ObserveError('Cnt_ulint.calc36');
        Observer.Observe('ulint.set', Format(H.Cnt_ulint));
        H.Reset();
        if not TryCalc_Cnt_uldec(H) then
            Observer.ObserveError('Cnt_uldec.calc37');
        Observer.Observe('uldec.unset', Format(H.Cnt_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Cnt_uldec(H) then
            Observer.ObserveError('Cnt_uldec.calc38');
        Observer.Observe('uldec.set', Format(H.Cnt_uldec));
        H.Reset();
        if not TryCalc_Cnt_ulcode(H) then
            Observer.ObserveError('Cnt_ulcode.calc39');
        Observer.Observe('ulcode.unset', Format(H.Cnt_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Cnt_ulcode(H) then
            Observer.ObserveError('Cnt_ulcode.calc40');
        Observer.Observe('ulcode.set', Format(H.Cnt_ulcode));
        H.Reset();
        if not TryCalc_Cnt_ulopt(H) then
            Observer.ObserveError('Cnt_ulopt.calc41');
        Observer.Observe('ulopt.unset', Format(H.Cnt_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Cnt_ulopt(H) then
            Observer.ObserveError('Cnt_ulopt.calc42');
        Observer.Observe('ulopt.set', Format(H.Cnt_ulopt));
        H.Reset();
        if not TryCalc_Cnt_ulenum(H) then
            Observer.ObserveError('Cnt_ulenum.calc43');
        Observer.Observe('ulenum.unset', Format(H.Cnt_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Cnt_ulenum(H) then
            Observer.ObserveError('Cnt_ulenum.calc44');
        Observer.Observe('ulenum.set', Format(H.Cnt_ulenum));
        H.Reset();
        if not TryCalc_Cnt_ulfdate(H) then
            Observer.ObserveError('Cnt_ulfdate.calc45');
        Observer.Observe('ulfdate.unset', Format(H.Cnt_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Cnt_ulfdate(H) then
            Observer.ObserveError('Cnt_ulfdate.calc46');
        Observer.Observe('ulfdate.set', Format(H.Cnt_ulfdate));
        Observer.Expect('uldate.unset', '6');
        Observer.Expect('uldate.set', '5');
        Observer.Expect('ulint.unset', '6');
        Observer.Expect('ulint.set', '5');
        Observer.Expect('uldec.unset', '6');
        Observer.Expect('Cnt_uldec.calc38|text', 'The filter expression ">=14" applied to the field DecF in the FFM CountExist Header table results in more than one range.');
        Observer.Expect('Cnt_uldec.calc38|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '6');
        Observer.Expect('ulcode.unset', '6');
        Observer.Expect('ulcode.set', '3');
        Observer.Expect('ulopt.unset', '6');
        Observer.Expect('ulopt.set', '2');
        Observer.Expect('ulenum.unset', '6');
        Observer.Expect('ulenum.set', '6');
        Observer.Expect('ulfdate.unset', '6');
        Observer.Expect('ulfdate.set', '5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldCount_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldCount with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Cnt_ffmismatch(H) then
            Observer.ObserveError('Cnt_ffmismatch.calc47');
        Observer.Observe('ffmismatch.unset', Format(H.Cnt_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Cnt_ffmismatch(H) then
            Observer.ObserveError('Cnt_ffmismatch.calc48');
        Observer.Observe('ffmismatch.set', Format(H.Cnt_ffmismatch));
        H.Reset();
        if not TryCalc_Cnt_ffboth(H) then
            Observer.ObserveError('Cnt_ffboth.calc49');
        Observer.Observe('ffboth.unset', Format(H.Cnt_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Cnt_ffboth(H) then
            Observer.ObserveError('Cnt_ffboth.calc50');
        Observer.Observe('ffboth.set', Format(H.Cnt_ffboth));
        Observer.Expect('ffmismatch.unset', '6');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '4');
        Observer.Expect('ffboth.set', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldCount_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldCount over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Cnt_const(H) then
            Observer.ObserveError('Cnt_const.calc51');
        Observer.Observe('const.h3', Format(H.Cnt_const));
        if not TryCalc_Cnt_field(H) then
            Observer.ObserveError('Cnt_field.calc52');
        Observer.Observe('field.h3', Format(H.Cnt_field));
        if not TryCalc_Cnt_filter(H) then
            Observer.ObserveError('Cnt_filter.calc53');
        Observer.Observe('filter.h3', Format(H.Cnt_filter));
        if not TryCalc_Cnt_constopt(H) then
            Observer.ObserveError('Cnt_constopt.calc54');
        Observer.Observe('constopt.h3', Format(H.Cnt_constopt));
        if not TryCalc_Cnt_constenum(H) then
            Observer.ObserveError('Cnt_constenum.calc55');
        Observer.Observe('constenum.h3', Format(H.Cnt_constenum));
        if not TryCalc_Cnt_filterenum(H) then
            Observer.ObserveError('Cnt_filterenum.calc56');
        Observer.Observe('filterenum.h3', Format(H.Cnt_filterenum));
        if not TryCalc_Cnt_ffint(H) then
            Observer.ObserveError('Cnt_ffint.calc57');
        Observer.Observe('ffint.h3', Format(H.Cnt_ffint));
        if not TryCalc_Cnt_ffdec(H) then
            Observer.ObserveError('Cnt_ffdec.calc58');
        Observer.Observe('ffdec.h3', Format(H.Cnt_ffdec));
        if not TryCalc_Cnt_ffdate(H) then
            Observer.ObserveError('Cnt_ffdate.calc59');
        Observer.Observe('ffdate.h3', Format(H.Cnt_ffdate));
        if not TryCalc_Cnt_ffcode(H) then
            Observer.ObserveError('Cnt_ffcode.calc60');
        Observer.Observe('ffcode.h3', Format(H.Cnt_ffcode));
        if not TryCalc_Cnt_ffopt(H) then
            Observer.ObserveError('Cnt_ffopt.calc61');
        Observer.Observe('ffopt.h3', Format(H.Cnt_ffopt));
        if not TryCalc_Cnt_ffenum(H) then
            Observer.ObserveError('Cnt_ffenum.calc62');
        Observer.Observe('ffenum.h3', Format(H.Cnt_ffenum));
        if not TryCalc_Cnt_fftext(H) then
            Observer.ObserveError('Cnt_fftext.calc63');
        Observer.Observe('fftext.h3', Format(H.Cnt_fftext));
        if not TryCalc_Cnt_uldate(H) then
            Observer.ObserveError('Cnt_uldate.calc64');
        Observer.Observe('uldate.h3', Format(H.Cnt_uldate));
        if not TryCalc_Cnt_ulint(H) then
            Observer.ObserveError('Cnt_ulint.calc65');
        Observer.Observe('ulint.h3', Format(H.Cnt_ulint));
        if not TryCalc_Cnt_uldec(H) then
            Observer.ObserveError('Cnt_uldec.calc66');
        Observer.Observe('uldec.h3', Format(H.Cnt_uldec));
        if not TryCalc_Cnt_ulcode(H) then
            Observer.ObserveError('Cnt_ulcode.calc67');
        Observer.Observe('ulcode.h3', Format(H.Cnt_ulcode));
        if not TryCalc_Cnt_ulopt(H) then
            Observer.ObserveError('Cnt_ulopt.calc68');
        Observer.Observe('ulopt.h3', Format(H.Cnt_ulopt));
        if not TryCalc_Cnt_ulenum(H) then
            Observer.ObserveError('Cnt_ulenum.calc69');
        Observer.Observe('ulenum.h3', Format(H.Cnt_ulenum));
        if not TryCalc_Cnt_ulfdate(H) then
            Observer.ObserveError('Cnt_ulfdate.calc70');
        Observer.Observe('ulfdate.h3', Format(H.Cnt_ulfdate));
        if not TryCalc_Cnt_ffmismatch(H) then
            Observer.ObserveError('Cnt_ffmismatch.calc71');
        Observer.Observe('ffmismatch.h3', Format(H.Cnt_ffmismatch));
        if not TryCalc_Cnt_ffboth(H) then
            Observer.ObserveError('Cnt_ffboth.calc72');
        Observer.Observe('ffboth.h3', Format(H.Cnt_ffboth));
        Observer.Expect('const.h3', '3');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '4');
        Observer.Expect('constopt.h3', '2');
        Observer.Expect('constenum.h3', '2');
        Observer.Expect('filterenum.h3', '4');
        Observer.Expect('ffint.h3', '6');
        Observer.Expect('ffdec.h3', '6');
        Observer.Expect('ffdate.h3', '6');
        Observer.Expect('ffcode.h3', '6');
        Observer.Expect('ffopt.h3', '6');
        Observer.Expect('ffenum.h3', '6');
        Observer.Expect('fftext.h3', '6');
        Observer.Expect('uldate.h3', '6');
        Observer.Expect('ulint.h3', '6');
        Observer.Expect('uldec.h3', '6');
        Observer.Expect('ulcode.h3', '6');
        Observer.Expect('ulopt.h3', '6');
        Observer.Expect('ulenum.h3', '6');
        Observer.Expect('ulfdate.h3', '6');
        Observer.Expect('ffmismatch.h3', '6');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldExist_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldExist with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Ex_const(H) then
            Observer.ObserveError('Ex_const.calc145');
        Observer.Observe('H1.const', Format(H.Ex_const));
        if not TryCalc_Ex_field(H) then
            Observer.ObserveError('Ex_field.calc146');
        Observer.Observe('H1.field', Format(H.Ex_field));
        if not TryCalc_Ex_filter(H) then
            Observer.ObserveError('Ex_filter.calc147');
        Observer.Observe('H1.filter', Format(H.Ex_filter));
        if not TryCalc_Ex_constopt(H) then
            Observer.ObserveError('Ex_constopt.calc148');
        Observer.Observe('H1.constopt', Format(H.Ex_constopt));
        if not TryCalc_Ex_constenum(H) then
            Observer.ObserveError('Ex_constenum.calc149');
        Observer.Observe('H1.constenum', Format(H.Ex_constenum));
        if not TryCalc_Ex_filterenum(H) then
            Observer.ObserveError('Ex_filterenum.calc150');
        Observer.Observe('H1.filterenum', Format(H.Ex_filterenum));
        H.Get('H2');
        if not TryCalc_Ex_const(H) then
            Observer.ObserveError('Ex_const.calc151');
        Observer.Observe('H2.const', Format(H.Ex_const));
        if not TryCalc_Ex_field(H) then
            Observer.ObserveError('Ex_field.calc152');
        Observer.Observe('H2.field', Format(H.Ex_field));
        if not TryCalc_Ex_filter(H) then
            Observer.ObserveError('Ex_filter.calc153');
        Observer.Observe('H2.filter', Format(H.Ex_filter));
        if not TryCalc_Ex_constopt(H) then
            Observer.ObserveError('Ex_constopt.calc154');
        Observer.Observe('H2.constopt', Format(H.Ex_constopt));
        if not TryCalc_Ex_constenum(H) then
            Observer.ObserveError('Ex_constenum.calc155');
        Observer.Observe('H2.constenum', Format(H.Ex_constenum));
        if not TryCalc_Ex_filterenum(H) then
            Observer.ObserveError('Ex_filterenum.calc156');
        Observer.Observe('H2.filterenum', Format(H.Ex_filterenum));
        H.Get('H3');
        if not TryCalc_Ex_const(H) then
            Observer.ObserveError('Ex_const.calc157');
        Observer.Observe('H3.const', Format(H.Ex_const));
        if not TryCalc_Ex_field(H) then
            Observer.ObserveError('Ex_field.calc158');
        Observer.Observe('H3.field', Format(H.Ex_field));
        if not TryCalc_Ex_filter(H) then
            Observer.ObserveError('Ex_filter.calc159');
        Observer.Observe('H3.filter', Format(H.Ex_filter));
        if not TryCalc_Ex_constopt(H) then
            Observer.ObserveError('Ex_constopt.calc160');
        Observer.Observe('H3.constopt', Format(H.Ex_constopt));
        if not TryCalc_Ex_constenum(H) then
            Observer.ObserveError('Ex_constenum.calc161');
        Observer.Observe('H3.constenum', Format(H.Ex_constenum));
        if not TryCalc_Ex_filterenum(H) then
            Observer.ObserveError('Ex_filterenum.calc162');
        Observer.Observe('H3.filterenum', Format(H.Ex_filterenum));
        Observer.Expect('H1.const', 'Yes');
        Observer.Expect('H1.field', 'Yes');
        Observer.Expect('H1.filter', 'Yes');
        Observer.Expect('H1.constopt', 'Yes');
        Observer.Expect('H1.constenum', 'Yes');
        Observer.Expect('H1.filterenum', 'Yes');
        Observer.Expect('H2.const', 'Yes');
        Observer.Expect('H2.field', 'Yes');
        Observer.Expect('H2.filter', 'Yes');
        Observer.Expect('H2.constopt', 'Yes');
        Observer.Expect('H2.constenum', 'Yes');
        Observer.Expect('H2.filterenum', 'Yes');
        Observer.Expect('H3.const', 'Yes');
        Observer.Expect('H3.field', 'No');
        Observer.Expect('H3.filter', 'Yes');
        Observer.Expect('H3.constopt', 'Yes');
        Observer.Expect('H3.constenum', 'Yes');
        Observer.Expect('H3.filterenum', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldExist_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldExist with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Ex_ffint(H) then
            Observer.ObserveError('Ex_ffint.calc163');
        Observer.Observe('ffint.unset', Format(H.Ex_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Ex_ffint(H) then
            Observer.ObserveError('Ex_ffint.calc164');
        Observer.Observe('ffint.set', Format(H.Ex_ffint));
        H.Reset();
        if not TryCalc_Ex_ffdec(H) then
            Observer.ObserveError('Ex_ffdec.calc165');
        Observer.Observe('ffdec.unset', Format(H.Ex_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Ex_ffdec(H) then
            Observer.ObserveError('Ex_ffdec.calc166');
        Observer.Observe('ffdec.set', Format(H.Ex_ffdec));
        H.Reset();
        if not TryCalc_Ex_ffdate(H) then
            Observer.ObserveError('Ex_ffdate.calc167');
        Observer.Observe('ffdate.unset', Format(H.Ex_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Ex_ffdate(H) then
            Observer.ObserveError('Ex_ffdate.calc168');
        Observer.Observe('ffdate.set', Format(H.Ex_ffdate));
        H.Reset();
        if not TryCalc_Ex_ffcode(H) then
            Observer.ObserveError('Ex_ffcode.calc169');
        Observer.Observe('ffcode.unset', Format(H.Ex_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Ex_ffcode(H) then
            Observer.ObserveError('Ex_ffcode.calc170');
        Observer.Observe('ffcode.set', Format(H.Ex_ffcode));
        H.Reset();
        if not TryCalc_Ex_ffopt(H) then
            Observer.ObserveError('Ex_ffopt.calc171');
        Observer.Observe('ffopt.unset', Format(H.Ex_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Ex_ffopt(H) then
            Observer.ObserveError('Ex_ffopt.calc172');
        Observer.Observe('ffopt.set', Format(H.Ex_ffopt));
        H.Reset();
        if not TryCalc_Ex_ffenum(H) then
            Observer.ObserveError('Ex_ffenum.calc173');
        Observer.Observe('ffenum.unset', Format(H.Ex_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Ex_ffenum(H) then
            Observer.ObserveError('Ex_ffenum.calc174');
        Observer.Observe('ffenum.set', Format(H.Ex_ffenum));
        H.Reset();
        if not TryCalc_Ex_fftext(H) then
            Observer.ObserveError('Ex_fftext.calc175');
        Observer.Observe('fftext.unset', Format(H.Ex_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Ex_fftext(H) then
            Observer.ObserveError('Ex_fftext.calc176');
        Observer.Observe('fftext.set', Format(H.Ex_fftext));
        Observer.Expect('ffint.unset', 'Yes');
        Observer.Expect('ffint.set', 'Yes');
        Observer.Expect('ffdec.unset', 'Yes');
        Observer.Expect('ffdec.set', 'Yes');
        Observer.Expect('ffdate.unset', 'Yes');
        Observer.Expect('ffdate.set', 'Yes');
        Observer.Expect('ffcode.unset', 'Yes');
        Observer.Expect('ffcode.set', 'Yes');
        Observer.Expect('ffopt.unset', 'Yes');
        Observer.Expect('ffopt.set', 'Yes');
        Observer.Expect('ffenum.unset', 'Yes');
        Observer.Expect('ffenum.set', 'Yes');
        Observer.Expect('fftext.unset', 'Yes');
        Observer.Expect('fftext.set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldExist_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldExist with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Ex_uldate(H) then
            Observer.ObserveError('Ex_uldate.calc177');
        Observer.Observe('uldate.unset', Format(H.Ex_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Ex_uldate(H) then
            Observer.ObserveError('Ex_uldate.calc178');
        Observer.Observe('uldate.set', Format(H.Ex_uldate));
        H.Reset();
        if not TryCalc_Ex_ulint(H) then
            Observer.ObserveError('Ex_ulint.calc179');
        Observer.Observe('ulint.unset', Format(H.Ex_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Ex_ulint(H) then
            Observer.ObserveError('Ex_ulint.calc180');
        Observer.Observe('ulint.set', Format(H.Ex_ulint));
        H.Reset();
        if not TryCalc_Ex_uldec(H) then
            Observer.ObserveError('Ex_uldec.calc181');
        Observer.Observe('uldec.unset', Format(H.Ex_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Ex_uldec(H) then
            Observer.ObserveError('Ex_uldec.calc182');
        Observer.Observe('uldec.set', Format(H.Ex_uldec));
        H.Reset();
        if not TryCalc_Ex_ulcode(H) then
            Observer.ObserveError('Ex_ulcode.calc183');
        Observer.Observe('ulcode.unset', Format(H.Ex_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Ex_ulcode(H) then
            Observer.ObserveError('Ex_ulcode.calc184');
        Observer.Observe('ulcode.set', Format(H.Ex_ulcode));
        H.Reset();
        if not TryCalc_Ex_ulopt(H) then
            Observer.ObserveError('Ex_ulopt.calc185');
        Observer.Observe('ulopt.unset', Format(H.Ex_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Ex_ulopt(H) then
            Observer.ObserveError('Ex_ulopt.calc186');
        Observer.Observe('ulopt.set', Format(H.Ex_ulopt));
        H.Reset();
        if not TryCalc_Ex_ulenum(H) then
            Observer.ObserveError('Ex_ulenum.calc187');
        Observer.Observe('ulenum.unset', Format(H.Ex_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Ex_ulenum(H) then
            Observer.ObserveError('Ex_ulenum.calc188');
        Observer.Observe('ulenum.set', Format(H.Ex_ulenum));
        H.Reset();
        if not TryCalc_Ex_ulfdate(H) then
            Observer.ObserveError('Ex_ulfdate.calc189');
        Observer.Observe('ulfdate.unset', Format(H.Ex_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Ex_ulfdate(H) then
            Observer.ObserveError('Ex_ulfdate.calc190');
        Observer.Observe('ulfdate.set', Format(H.Ex_ulfdate));
        Observer.Expect('uldate.unset', 'Yes');
        Observer.Expect('uldate.set', 'Yes');
        Observer.Expect('ulint.unset', 'Yes');
        Observer.Expect('ulint.set', 'Yes');
        Observer.Expect('uldec.unset', 'Yes');
        Observer.Expect('Ex_uldec.calc182|text', 'The filter expression ">=14" applied to the field DecF in the FFM CountExist Header table results in more than one range.');
        Observer.Expect('Ex_uldec.calc182|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', 'Yes');
        Observer.Expect('ulcode.unset', 'Yes');
        Observer.Expect('ulcode.set', 'Yes');
        Observer.Expect('ulopt.unset', 'Yes');
        Observer.Expect('ulopt.set', 'Yes');
        Observer.Expect('ulenum.unset', 'Yes');
        Observer.Expect('ulenum.set', 'Yes');
        Observer.Expect('ulfdate.unset', 'Yes');
        Observer.Expect('ulfdate.set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldExist_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldExist with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Ex_ffmismatch(H) then
            Observer.ObserveError('Ex_ffmismatch.calc191');
        Observer.Observe('ffmismatch.unset', Format(H.Ex_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Ex_ffmismatch(H) then
            Observer.ObserveError('Ex_ffmismatch.calc192');
        Observer.Observe('ffmismatch.set', Format(H.Ex_ffmismatch));
        H.Reset();
        if not TryCalc_Ex_ffboth(H) then
            Observer.ObserveError('Ex_ffboth.calc193');
        Observer.Observe('ffboth.unset', Format(H.Ex_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Ex_ffboth(H) then
            Observer.ObserveError('Ex_ffboth.calc194');
        Observer.Observe('ffboth.set', Format(H.Ex_ffboth));
        Observer.Expect('ffmismatch.unset', 'Yes');
        Observer.Expect('ffmismatch.set', 'No');
        Observer.Expect('ffboth.unset', 'Yes');
        Observer.Expect('ffboth.set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldExist_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldExist over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Ex_const(H) then
            Observer.ObserveError('Ex_const.calc195');
        Observer.Observe('const.h3', Format(H.Ex_const));
        if not TryCalc_Ex_field(H) then
            Observer.ObserveError('Ex_field.calc196');
        Observer.Observe('field.h3', Format(H.Ex_field));
        if not TryCalc_Ex_filter(H) then
            Observer.ObserveError('Ex_filter.calc197');
        Observer.Observe('filter.h3', Format(H.Ex_filter));
        if not TryCalc_Ex_constopt(H) then
            Observer.ObserveError('Ex_constopt.calc198');
        Observer.Observe('constopt.h3', Format(H.Ex_constopt));
        if not TryCalc_Ex_constenum(H) then
            Observer.ObserveError('Ex_constenum.calc199');
        Observer.Observe('constenum.h3', Format(H.Ex_constenum));
        if not TryCalc_Ex_filterenum(H) then
            Observer.ObserveError('Ex_filterenum.calc200');
        Observer.Observe('filterenum.h3', Format(H.Ex_filterenum));
        if not TryCalc_Ex_ffint(H) then
            Observer.ObserveError('Ex_ffint.calc201');
        Observer.Observe('ffint.h3', Format(H.Ex_ffint));
        if not TryCalc_Ex_ffdec(H) then
            Observer.ObserveError('Ex_ffdec.calc202');
        Observer.Observe('ffdec.h3', Format(H.Ex_ffdec));
        if not TryCalc_Ex_ffdate(H) then
            Observer.ObserveError('Ex_ffdate.calc203');
        Observer.Observe('ffdate.h3', Format(H.Ex_ffdate));
        if not TryCalc_Ex_ffcode(H) then
            Observer.ObserveError('Ex_ffcode.calc204');
        Observer.Observe('ffcode.h3', Format(H.Ex_ffcode));
        if not TryCalc_Ex_ffopt(H) then
            Observer.ObserveError('Ex_ffopt.calc205');
        Observer.Observe('ffopt.h3', Format(H.Ex_ffopt));
        if not TryCalc_Ex_ffenum(H) then
            Observer.ObserveError('Ex_ffenum.calc206');
        Observer.Observe('ffenum.h3', Format(H.Ex_ffenum));
        if not TryCalc_Ex_fftext(H) then
            Observer.ObserveError('Ex_fftext.calc207');
        Observer.Observe('fftext.h3', Format(H.Ex_fftext));
        if not TryCalc_Ex_uldate(H) then
            Observer.ObserveError('Ex_uldate.calc208');
        Observer.Observe('uldate.h3', Format(H.Ex_uldate));
        if not TryCalc_Ex_ulint(H) then
            Observer.ObserveError('Ex_ulint.calc209');
        Observer.Observe('ulint.h3', Format(H.Ex_ulint));
        if not TryCalc_Ex_uldec(H) then
            Observer.ObserveError('Ex_uldec.calc210');
        Observer.Observe('uldec.h3', Format(H.Ex_uldec));
        if not TryCalc_Ex_ulcode(H) then
            Observer.ObserveError('Ex_ulcode.calc211');
        Observer.Observe('ulcode.h3', Format(H.Ex_ulcode));
        if not TryCalc_Ex_ulopt(H) then
            Observer.ObserveError('Ex_ulopt.calc212');
        Observer.Observe('ulopt.h3', Format(H.Ex_ulopt));
        if not TryCalc_Ex_ulenum(H) then
            Observer.ObserveError('Ex_ulenum.calc213');
        Observer.Observe('ulenum.h3', Format(H.Ex_ulenum));
        if not TryCalc_Ex_ulfdate(H) then
            Observer.ObserveError('Ex_ulfdate.calc214');
        Observer.Observe('ulfdate.h3', Format(H.Ex_ulfdate));
        if not TryCalc_Ex_ffmismatch(H) then
            Observer.ObserveError('Ex_ffmismatch.calc215');
        Observer.Observe('ffmismatch.h3', Format(H.Ex_ffmismatch));
        if not TryCalc_Ex_ffboth(H) then
            Observer.ObserveError('Ex_ffboth.calc216');
        Observer.Observe('ffboth.h3', Format(H.Ex_ffboth));
        Observer.Expect('const.h3', 'Yes');
        Observer.Expect('field.h3', 'No');
        Observer.Expect('filter.h3', 'Yes');
        Observer.Expect('constopt.h3', 'Yes');
        Observer.Expect('constenum.h3', 'Yes');
        Observer.Expect('filterenum.h3', 'Yes');
        Observer.Expect('ffint.h3', 'Yes');
        Observer.Expect('ffdec.h3', 'Yes');
        Observer.Expect('ffdate.h3', 'Yes');
        Observer.Expect('ffcode.h3', 'Yes');
        Observer.Expect('ffopt.h3', 'Yes');
        Observer.Expect('ffenum.h3', 'Yes');
        Observer.Expect('fftext.h3', 'Yes');
        Observer.Expect('uldate.h3', 'Yes');
        Observer.Expect('ulint.h3', 'Yes');
        Observer.Expect('uldec.h3', 'Yes');
        Observer.Expect('ulcode.h3', 'Yes');
        Observer.Expect('ulopt.h3', 'Yes');
        Observer.Expect('ulenum.h3', 'Yes');
        Observer.Expect('ulfdate.h3', 'Yes');
        Observer.Expect('ffmismatch.h3', 'Yes');
        Observer.Expect('ffboth.h3', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedExist_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedExist with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NEx_const(H) then
            Observer.ObserveError('NEx_const.calc217');
        Observer.Observe('H1.const', Format(H.NEx_const));
        if not TryCalc_NEx_field(H) then
            Observer.ObserveError('NEx_field.calc218');
        Observer.Observe('H1.field', Format(H.NEx_field));
        if not TryCalc_NEx_filter(H) then
            Observer.ObserveError('NEx_filter.calc219');
        Observer.Observe('H1.filter', Format(H.NEx_filter));
        if not TryCalc_NEx_constopt(H) then
            Observer.ObserveError('NEx_constopt.calc220');
        Observer.Observe('H1.constopt', Format(H.NEx_constopt));
        if not TryCalc_NEx_constenum(H) then
            Observer.ObserveError('NEx_constenum.calc221');
        Observer.Observe('H1.constenum', Format(H.NEx_constenum));
        if not TryCalc_NEx_filterenum(H) then
            Observer.ObserveError('NEx_filterenum.calc222');
        Observer.Observe('H1.filterenum', Format(H.NEx_filterenum));
        H.Get('H2');
        if not TryCalc_NEx_const(H) then
            Observer.ObserveError('NEx_const.calc223');
        Observer.Observe('H2.const', Format(H.NEx_const));
        if not TryCalc_NEx_field(H) then
            Observer.ObserveError('NEx_field.calc224');
        Observer.Observe('H2.field', Format(H.NEx_field));
        if not TryCalc_NEx_filter(H) then
            Observer.ObserveError('NEx_filter.calc225');
        Observer.Observe('H2.filter', Format(H.NEx_filter));
        if not TryCalc_NEx_constopt(H) then
            Observer.ObserveError('NEx_constopt.calc226');
        Observer.Observe('H2.constopt', Format(H.NEx_constopt));
        if not TryCalc_NEx_constenum(H) then
            Observer.ObserveError('NEx_constenum.calc227');
        Observer.Observe('H2.constenum', Format(H.NEx_constenum));
        if not TryCalc_NEx_filterenum(H) then
            Observer.ObserveError('NEx_filterenum.calc228');
        Observer.Observe('H2.filterenum', Format(H.NEx_filterenum));
        H.Get('H3');
        if not TryCalc_NEx_const(H) then
            Observer.ObserveError('NEx_const.calc229');
        Observer.Observe('H3.const', Format(H.NEx_const));
        if not TryCalc_NEx_field(H) then
            Observer.ObserveError('NEx_field.calc230');
        Observer.Observe('H3.field', Format(H.NEx_field));
        if not TryCalc_NEx_filter(H) then
            Observer.ObserveError('NEx_filter.calc231');
        Observer.Observe('H3.filter', Format(H.NEx_filter));
        if not TryCalc_NEx_constopt(H) then
            Observer.ObserveError('NEx_constopt.calc232');
        Observer.Observe('H3.constopt', Format(H.NEx_constopt));
        if not TryCalc_NEx_constenum(H) then
            Observer.ObserveError('NEx_constenum.calc233');
        Observer.Observe('H3.constenum', Format(H.NEx_constenum));
        if not TryCalc_NEx_filterenum(H) then
            Observer.ObserveError('NEx_filterenum.calc234');
        Observer.Observe('H3.filterenum', Format(H.NEx_filterenum));
        Observer.Expect('H1.const', 'No');
        Observer.Expect('H1.field', 'No');
        Observer.Expect('H1.filter', 'No');
        Observer.Expect('H1.constopt', 'No');
        Observer.Expect('H1.constenum', 'No');
        Observer.Expect('H1.filterenum', 'No');
        Observer.Expect('H2.const', 'No');
        Observer.Expect('H2.field', 'No');
        Observer.Expect('H2.filter', 'No');
        Observer.Expect('H2.constopt', 'No');
        Observer.Expect('H2.constenum', 'No');
        Observer.Expect('H2.filterenum', 'No');
        Observer.Expect('H3.const', 'No');
        Observer.Expect('H3.field', 'Yes');
        Observer.Expect('H3.filter', 'No');
        Observer.Expect('H3.constopt', 'No');
        Observer.Expect('H3.constenum', 'No');
        Observer.Expect('H3.filterenum', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedExist_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedExist with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NEx_ffint(H) then
            Observer.ObserveError('NEx_ffint.calc235');
        Observer.Observe('ffint.unset', Format(H.NEx_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NEx_ffint(H) then
            Observer.ObserveError('NEx_ffint.calc236');
        Observer.Observe('ffint.set', Format(H.NEx_ffint));
        H.Reset();
        if not TryCalc_NEx_ffdec(H) then
            Observer.ObserveError('NEx_ffdec.calc237');
        Observer.Observe('ffdec.unset', Format(H.NEx_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NEx_ffdec(H) then
            Observer.ObserveError('NEx_ffdec.calc238');
        Observer.Observe('ffdec.set', Format(H.NEx_ffdec));
        H.Reset();
        if not TryCalc_NEx_ffdate(H) then
            Observer.ObserveError('NEx_ffdate.calc239');
        Observer.Observe('ffdate.unset', Format(H.NEx_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NEx_ffdate(H) then
            Observer.ObserveError('NEx_ffdate.calc240');
        Observer.Observe('ffdate.set', Format(H.NEx_ffdate));
        H.Reset();
        if not TryCalc_NEx_ffcode(H) then
            Observer.ObserveError('NEx_ffcode.calc241');
        Observer.Observe('ffcode.unset', Format(H.NEx_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NEx_ffcode(H) then
            Observer.ObserveError('NEx_ffcode.calc242');
        Observer.Observe('ffcode.set', Format(H.NEx_ffcode));
        H.Reset();
        if not TryCalc_NEx_ffopt(H) then
            Observer.ObserveError('NEx_ffopt.calc243');
        Observer.Observe('ffopt.unset', Format(H.NEx_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NEx_ffopt(H) then
            Observer.ObserveError('NEx_ffopt.calc244');
        Observer.Observe('ffopt.set', Format(H.NEx_ffopt));
        H.Reset();
        if not TryCalc_NEx_ffenum(H) then
            Observer.ObserveError('NEx_ffenum.calc245');
        Observer.Observe('ffenum.unset', Format(H.NEx_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NEx_ffenum(H) then
            Observer.ObserveError('NEx_ffenum.calc246');
        Observer.Observe('ffenum.set', Format(H.NEx_ffenum));
        H.Reset();
        if not TryCalc_NEx_fftext(H) then
            Observer.ObserveError('NEx_fftext.calc247');
        Observer.Observe('fftext.unset', Format(H.NEx_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NEx_fftext(H) then
            Observer.ObserveError('NEx_fftext.calc248');
        Observer.Observe('fftext.set', Format(H.NEx_fftext));
        Observer.Expect('ffint.unset', 'No');
        Observer.Expect('ffint.set', 'No');
        Observer.Expect('ffdec.unset', 'No');
        Observer.Expect('ffdec.set', 'No');
        Observer.Expect('ffdate.unset', 'No');
        Observer.Expect('ffdate.set', 'No');
        Observer.Expect('ffcode.unset', 'No');
        Observer.Expect('ffcode.set', 'No');
        Observer.Expect('ffopt.unset', 'No');
        Observer.Expect('ffopt.set', 'No');
        Observer.Expect('ffenum.unset', 'No');
        Observer.Expect('ffenum.set', 'No');
        Observer.Expect('fftext.unset', 'No');
        Observer.Expect('fftext.set', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedExist_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedExist with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NEx_uldate(H) then
            Observer.ObserveError('NEx_uldate.calc249');
        Observer.Observe('uldate.unset', Format(H.NEx_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NEx_uldate(H) then
            Observer.ObserveError('NEx_uldate.calc250');
        Observer.Observe('uldate.set', Format(H.NEx_uldate));
        H.Reset();
        if not TryCalc_NEx_ulint(H) then
            Observer.ObserveError('NEx_ulint.calc251');
        Observer.Observe('ulint.unset', Format(H.NEx_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NEx_ulint(H) then
            Observer.ObserveError('NEx_ulint.calc252');
        Observer.Observe('ulint.set', Format(H.NEx_ulint));
        H.Reset();
        if not TryCalc_NEx_uldec(H) then
            Observer.ObserveError('NEx_uldec.calc253');
        Observer.Observe('uldec.unset', Format(H.NEx_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NEx_uldec(H) then
            Observer.ObserveError('NEx_uldec.calc254');
        Observer.Observe('uldec.set', Format(H.NEx_uldec));
        H.Reset();
        if not TryCalc_NEx_ulcode(H) then
            Observer.ObserveError('NEx_ulcode.calc255');
        Observer.Observe('ulcode.unset', Format(H.NEx_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NEx_ulcode(H) then
            Observer.ObserveError('NEx_ulcode.calc256');
        Observer.Observe('ulcode.set', Format(H.NEx_ulcode));
        H.Reset();
        if not TryCalc_NEx_ulopt(H) then
            Observer.ObserveError('NEx_ulopt.calc257');
        Observer.Observe('ulopt.unset', Format(H.NEx_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NEx_ulopt(H) then
            Observer.ObserveError('NEx_ulopt.calc258');
        Observer.Observe('ulopt.set', Format(H.NEx_ulopt));
        H.Reset();
        if not TryCalc_NEx_ulenum(H) then
            Observer.ObserveError('NEx_ulenum.calc259');
        Observer.Observe('ulenum.unset', Format(H.NEx_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NEx_ulenum(H) then
            Observer.ObserveError('NEx_ulenum.calc260');
        Observer.Observe('ulenum.set', Format(H.NEx_ulenum));
        H.Reset();
        if not TryCalc_NEx_ulfdate(H) then
            Observer.ObserveError('NEx_ulfdate.calc261');
        Observer.Observe('ulfdate.unset', Format(H.NEx_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NEx_ulfdate(H) then
            Observer.ObserveError('NEx_ulfdate.calc262');
        Observer.Observe('ulfdate.set', Format(H.NEx_ulfdate));
        Observer.Expect('uldate.unset', 'No');
        Observer.Expect('uldate.set', 'No');
        Observer.Expect('ulint.unset', 'No');
        Observer.Expect('ulint.set', 'No');
        Observer.Expect('uldec.unset', 'No');
        Observer.Expect('NEx_uldec.calc254|text', 'The filter expression ">=14" applied to the field DecF in the FFM CountExist Header table results in more than one range.');
        Observer.Expect('NEx_uldec.calc254|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', 'No');
        Observer.Expect('ulcode.unset', 'No');
        Observer.Expect('ulcode.set', 'No');
        Observer.Expect('ulopt.unset', 'No');
        Observer.Expect('ulopt.set', 'No');
        Observer.Expect('ulenum.unset', 'No');
        Observer.Expect('ulenum.set', 'No');
        Observer.Expect('ulfdate.unset', 'No');
        Observer.Expect('ulfdate.set', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedExist_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedExist with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NEx_ffmismatch(H) then
            Observer.ObserveError('NEx_ffmismatch.calc263');
        Observer.Observe('ffmismatch.unset', Format(H.NEx_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NEx_ffmismatch(H) then
            Observer.ObserveError('NEx_ffmismatch.calc264');
        Observer.Observe('ffmismatch.set', Format(H.NEx_ffmismatch));
        H.Reset();
        if not TryCalc_NEx_ffboth(H) then
            Observer.ObserveError('NEx_ffboth.calc265');
        Observer.Observe('ffboth.unset', Format(H.NEx_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NEx_ffboth(H) then
            Observer.ObserveError('NEx_ffboth.calc266');
        Observer.Observe('ffboth.set', Format(H.NEx_ffboth));
        Observer.Expect('ffmismatch.unset', 'No');
        Observer.Expect('ffmismatch.set', 'Yes');
        Observer.Expect('ffboth.unset', 'No');
        Observer.Expect('ffboth.set', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedExist_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedExist over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NEx_const(H) then
            Observer.ObserveError('NEx_const.calc267');
        Observer.Observe('const.h3', Format(H.NEx_const));
        if not TryCalc_NEx_field(H) then
            Observer.ObserveError('NEx_field.calc268');
        Observer.Observe('field.h3', Format(H.NEx_field));
        if not TryCalc_NEx_filter(H) then
            Observer.ObserveError('NEx_filter.calc269');
        Observer.Observe('filter.h3', Format(H.NEx_filter));
        if not TryCalc_NEx_constopt(H) then
            Observer.ObserveError('NEx_constopt.calc270');
        Observer.Observe('constopt.h3', Format(H.NEx_constopt));
        if not TryCalc_NEx_constenum(H) then
            Observer.ObserveError('NEx_constenum.calc271');
        Observer.Observe('constenum.h3', Format(H.NEx_constenum));
        if not TryCalc_NEx_filterenum(H) then
            Observer.ObserveError('NEx_filterenum.calc272');
        Observer.Observe('filterenum.h3', Format(H.NEx_filterenum));
        if not TryCalc_NEx_ffint(H) then
            Observer.ObserveError('NEx_ffint.calc273');
        Observer.Observe('ffint.h3', Format(H.NEx_ffint));
        if not TryCalc_NEx_ffdec(H) then
            Observer.ObserveError('NEx_ffdec.calc274');
        Observer.Observe('ffdec.h3', Format(H.NEx_ffdec));
        if not TryCalc_NEx_ffdate(H) then
            Observer.ObserveError('NEx_ffdate.calc275');
        Observer.Observe('ffdate.h3', Format(H.NEx_ffdate));
        if not TryCalc_NEx_ffcode(H) then
            Observer.ObserveError('NEx_ffcode.calc276');
        Observer.Observe('ffcode.h3', Format(H.NEx_ffcode));
        if not TryCalc_NEx_ffopt(H) then
            Observer.ObserveError('NEx_ffopt.calc277');
        Observer.Observe('ffopt.h3', Format(H.NEx_ffopt));
        if not TryCalc_NEx_ffenum(H) then
            Observer.ObserveError('NEx_ffenum.calc278');
        Observer.Observe('ffenum.h3', Format(H.NEx_ffenum));
        if not TryCalc_NEx_fftext(H) then
            Observer.ObserveError('NEx_fftext.calc279');
        Observer.Observe('fftext.h3', Format(H.NEx_fftext));
        if not TryCalc_NEx_uldate(H) then
            Observer.ObserveError('NEx_uldate.calc280');
        Observer.Observe('uldate.h3', Format(H.NEx_uldate));
        if not TryCalc_NEx_ulint(H) then
            Observer.ObserveError('NEx_ulint.calc281');
        Observer.Observe('ulint.h3', Format(H.NEx_ulint));
        if not TryCalc_NEx_uldec(H) then
            Observer.ObserveError('NEx_uldec.calc282');
        Observer.Observe('uldec.h3', Format(H.NEx_uldec));
        if not TryCalc_NEx_ulcode(H) then
            Observer.ObserveError('NEx_ulcode.calc283');
        Observer.Observe('ulcode.h3', Format(H.NEx_ulcode));
        if not TryCalc_NEx_ulopt(H) then
            Observer.ObserveError('NEx_ulopt.calc284');
        Observer.Observe('ulopt.h3', Format(H.NEx_ulopt));
        if not TryCalc_NEx_ulenum(H) then
            Observer.ObserveError('NEx_ulenum.calc285');
        Observer.Observe('ulenum.h3', Format(H.NEx_ulenum));
        if not TryCalc_NEx_ulfdate(H) then
            Observer.ObserveError('NEx_ulfdate.calc286');
        Observer.Observe('ulfdate.h3', Format(H.NEx_ulfdate));
        if not TryCalc_NEx_ffmismatch(H) then
            Observer.ObserveError('NEx_ffmismatch.calc287');
        Observer.Observe('ffmismatch.h3', Format(H.NEx_ffmismatch));
        if not TryCalc_NEx_ffboth(H) then
            Observer.ObserveError('NEx_ffboth.calc288');
        Observer.Observe('ffboth.h3', Format(H.NEx_ffboth));
        Observer.Expect('const.h3', 'No');
        Observer.Expect('field.h3', 'Yes');
        Observer.Expect('filter.h3', 'No');
        Observer.Expect('constopt.h3', 'No');
        Observer.Expect('constenum.h3', 'No');
        Observer.Expect('filterenum.h3', 'No');
        Observer.Expect('ffint.h3', 'No');
        Observer.Expect('ffdec.h3', 'No');
        Observer.Expect('ffdate.h3', 'No');
        Observer.Expect('ffcode.h3', 'No');
        Observer.Expect('ffopt.h3', 'No');
        Observer.Expect('ffenum.h3', 'No');
        Observer.Expect('fftext.h3', 'No');
        Observer.Expect('uldate.h3', 'No');
        Observer.Expect('ulint.h3', 'No');
        Observer.Expect('uldec.h3', 'No');
        Observer.Expect('ulcode.h3', 'No');
        Observer.Expect('ulopt.h3', 'No');
        Observer.Expect('ulenum.h3', 'No');
        Observer.Expect('ulfdate.h3', 'No');
        Observer.Expect('ffmismatch.h3', 'No');
        Observer.Expect('ffboth.h3', 'Yes');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        D: Record "FFM CountExist Detail";
        H: Record "FFM CountExist Header";
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
        D: Record "FFM CountExist Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Qty := Quantity;
        D.Amt := Amount;
        D.Day := Date;
        D.Kind := KindCode;
        D.Opt := Option;
        D.Status := "FFM CountExist Status".FromInteger(StatusValue);
        D.Flag := FlagValue;
        D.Name := NameValue;
        D.Insert();
    end;

    local procedure AddHeader(HeaderCode: Code[10])
    var
        H: Record "FFM CountExist Header";
    begin
        H.Init();
        H.Code := HeaderCode;
        H.Insert();
    end;
}
