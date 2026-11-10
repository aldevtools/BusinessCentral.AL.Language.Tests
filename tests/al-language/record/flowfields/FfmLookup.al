// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (FFM Lookup *)
// local object: the CalcFormula definitions are what the tests measure.
// Area: FlowField and FlowFilter matrix, CalcFormula kinds lookup, -lookup (over a Text and a Decimal field) crossed with the where-clause forms (const, field, filter,
//   field(filter(F)) over Integer, Decimal, Date, Code, Option, Enum and Text FlowFilters, field(upperlimit(F)), field(upperlimit(filter(F))))
//   and the two states of every FlowFilter (not set, set), read with CalcFields on a record with rows, and on a record with no match.
//   The shapes BC rejects at compile time are pinned in tests/must-not-compile/cases (upperlimit outside field()).
// Nearby: record/flowfields/Y17SumWhereFlowField.al, record/flowfields/CalcFormulaDateLiteral.al, TestCalcFormulaFlowFiltersTests.Codeunit.al
// Probe: values recorded on BC; the corpus CI matrix checks the other versions.

enum 64400 "FFM Lookup Status"
{
    Extensible = true;
    value(0; Open) { }
    value(1; Closed) { }
    value(2; Held) { }
}

table 64401 "FFM Lookup Detail"
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
        field(8; Status; Enum "FFM Lookup Status") { }
        field(9; Flag; Boolean) { }
        field(10; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 64402 "FFM Lookup Header"
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
        field(7; EnumF; Enum "FFM Lookup Status") { FieldClass = FlowFilter; }
        field(8; TextF; Text[30]) { FieldClass = FlowFilter; }
        field(100; Lk_const; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Kind = const('K1'))); }
        field(101; Lk_field; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Owner = field(Code))); }
        field(102; Lk_filter; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Qty = filter(2..5))); }
        field(103; Lk_constopt; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Opt = const(B))); }
        field(104; Lk_constenum; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Status = const(Closed))); }
        field(105; Lk_filterenum; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Status = filter(Open|Held))); }
        field(106; Lk_ffint; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Qty = field(filter(IntF)))); }
        field(107; Lk_ffdec; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Amt = field(filter(DecF)))); }
        field(108; Lk_ffdate; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Day = field(filter(DateF)))); }
        field(109; Lk_ffcode; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Kind = field(filter(CodeF)))); }
        field(110; Lk_ffopt; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Opt = field(filter(OptF)))); }
        field(111; Lk_ffenum; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Status = field(filter(EnumF)))); }
        field(112; Lk_fftext; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Name = field(filter(TextF)))); }
        field(113; Lk_uldate; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Day = field(upperlimit(DateF)))); }
        field(114; Lk_ulint; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Qty = field(upperlimit(IntF)))); }
        field(115; Lk_uldec; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Amt = field(upperlimit(DecF)))); }
        field(116; Lk_ulcode; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Kind = field(upperlimit(CodeF)))); }
        field(117; Lk_ulopt; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Opt = field(upperlimit(OptF)))); }
        field(118; Lk_ulenum; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Status = field(upperlimit(EnumF)))); }
        field(119; Lk_ulfdate; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Day = field(upperlimit(filter(DateF))))); }
        field(120; Lk_ffmismatch; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Qty = field(filter(DateF)))); }
        field(121; Lk_ffboth; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Name where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(122; LkDec_const; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Kind = const('K1'))); }
        field(123; LkDec_field; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Owner = field(Code))); }
        field(124; LkDec_filter; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Qty = filter(2..5))); }
        field(125; LkDec_constopt; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Opt = const(B))); }
        field(126; LkDec_constenum; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Status = const(Closed))); }
        field(127; LkDec_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Status = filter(Open|Held))); }
        field(128; LkDec_ffint; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Qty = field(filter(IntF)))); }
        field(129; LkDec_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Amt = field(filter(DecF)))); }
        field(130; LkDec_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Day = field(filter(DateF)))); }
        field(131; LkDec_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(132; LkDec_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Opt = field(filter(OptF)))); }
        field(133; LkDec_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Status = field(filter(EnumF)))); }
        field(134; LkDec_fftext; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Name = field(filter(TextF)))); }
        field(135; LkDec_uldate; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(136; LkDec_ulint; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(137; LkDec_uldec; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(138; LkDec_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(139; LkDec_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(140; LkDec_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(141; LkDec_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(142; LkDec_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Qty = field(filter(DateF)))); }
        field(143; LkDec_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = lookup("FFM Lookup Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
        field(144; NLkDec_const; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Kind = const('K1'))); }
        field(145; NLkDec_field; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Owner = field(Code))); }
        field(146; NLkDec_filter; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Qty = filter(2..5))); }
        field(147; NLkDec_constopt; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Opt = const(B))); }
        field(148; NLkDec_constenum; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Status = const(Closed))); }
        field(149; NLkDec_filterenum; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Status = filter(Open|Held))); }
        field(150; NLkDec_ffint; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Qty = field(filter(IntF)))); }
        field(151; NLkDec_ffdec; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Amt = field(filter(DecF)))); }
        field(152; NLkDec_ffdate; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Day = field(filter(DateF)))); }
        field(153; NLkDec_ffcode; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Kind = field(filter(CodeF)))); }
        field(154; NLkDec_ffopt; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Opt = field(filter(OptF)))); }
        field(155; NLkDec_ffenum; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Status = field(filter(EnumF)))); }
        field(156; NLkDec_fftext; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Name = field(filter(TextF)))); }
        field(157; NLkDec_uldate; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Day = field(upperlimit(DateF)))); }
        field(158; NLkDec_ulint; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Qty = field(upperlimit(IntF)))); }
        field(159; NLkDec_uldec; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Amt = field(upperlimit(DecF)))); }
        field(160; NLkDec_ulcode; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Kind = field(upperlimit(CodeF)))); }
        field(161; NLkDec_ulopt; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Opt = field(upperlimit(OptF)))); }
        field(162; NLkDec_ulenum; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Status = field(upperlimit(EnumF)))); }
        field(163; NLkDec_ulfdate; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Day = field(upperlimit(filter(DateF))))); }
        field(164; NLkDec_ffmismatch; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Qty = field(filter(DateF)))); }
        field(165; NLkDec_ffboth; Decimal) { FieldClass = FlowField; CalcFormula = -lookup("FFM Lookup Detail".Amt where(Owner = field(Code), Qty = field(filter(IntF)))); }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 64403 "FFM Lookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryCalc_Lk_const(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_const);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_field(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_field);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_filter(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_filter);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_constopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_constenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_filterenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffdec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_fftext(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_uldate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ulint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_uldec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ulcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ulopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ulenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ulfdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffmismatch(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_Lk_ffboth(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(Lk_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_const(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_const);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_field(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_field);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_filter(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_filter);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_constopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_constenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_filterenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffdec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_fftext(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_uldate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ulint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_uldec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ulcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ulopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ulenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ulfdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffmismatch(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_LkDec_ffboth(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(LkDec_ffboth);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_const(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_const);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_field(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_field);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_filter(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_filter);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_constopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_constopt);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_constenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_constenum);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_filterenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_filterenum);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffint);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffdec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffdec);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffdate);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffcode);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffopt);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffenum);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_fftext(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_fftext);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_uldate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_uldate);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ulint(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ulint);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_uldec(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_uldec);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ulcode(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ulcode);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ulopt(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ulopt);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ulenum(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ulenum);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ulfdate(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ulfdate);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffmismatch(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffmismatch);
    end;

    [TryFunction]
    local procedure TryCalc_NLkDec_ffboth(var H: Record "FFM Lookup Header")
    begin
        H.CalcFields(NLkDec_ffboth);
    end;

    [Test]
    procedure FlowFieldLookupText_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldLookupText with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_Lk_const(H) then
            Observer.ObserveError('Lk_const.calc1');
        Observer.Observe('H1.const', Format(H.Lk_const));
        if not TryCalc_Lk_field(H) then
            Observer.ObserveError('Lk_field.calc2');
        Observer.Observe('H1.field', Format(H.Lk_field));
        if not TryCalc_Lk_filter(H) then
            Observer.ObserveError('Lk_filter.calc3');
        Observer.Observe('H1.filter', Format(H.Lk_filter));
        if not TryCalc_Lk_constopt(H) then
            Observer.ObserveError('Lk_constopt.calc4');
        Observer.Observe('H1.constopt', Format(H.Lk_constopt));
        if not TryCalc_Lk_constenum(H) then
            Observer.ObserveError('Lk_constenum.calc5');
        Observer.Observe('H1.constenum', Format(H.Lk_constenum));
        if not TryCalc_Lk_filterenum(H) then
            Observer.ObserveError('Lk_filterenum.calc6');
        Observer.Observe('H1.filterenum', Format(H.Lk_filterenum));
        H.Get('H2');
        if not TryCalc_Lk_const(H) then
            Observer.ObserveError('Lk_const.calc7');
        Observer.Observe('H2.const', Format(H.Lk_const));
        if not TryCalc_Lk_field(H) then
            Observer.ObserveError('Lk_field.calc8');
        Observer.Observe('H2.field', Format(H.Lk_field));
        if not TryCalc_Lk_filter(H) then
            Observer.ObserveError('Lk_filter.calc9');
        Observer.Observe('H2.filter', Format(H.Lk_filter));
        if not TryCalc_Lk_constopt(H) then
            Observer.ObserveError('Lk_constopt.calc10');
        Observer.Observe('H2.constopt', Format(H.Lk_constopt));
        if not TryCalc_Lk_constenum(H) then
            Observer.ObserveError('Lk_constenum.calc11');
        Observer.Observe('H2.constenum', Format(H.Lk_constenum));
        if not TryCalc_Lk_filterenum(H) then
            Observer.ObserveError('Lk_filterenum.calc12');
        Observer.Observe('H2.filterenum', Format(H.Lk_filterenum));
        H.Get('H3');
        if not TryCalc_Lk_const(H) then
            Observer.ObserveError('Lk_const.calc13');
        Observer.Observe('H3.const', Format(H.Lk_const));
        if not TryCalc_Lk_field(H) then
            Observer.ObserveError('Lk_field.calc14');
        Observer.Observe('H3.field', Format(H.Lk_field));
        if not TryCalc_Lk_filter(H) then
            Observer.ObserveError('Lk_filter.calc15');
        Observer.Observe('H3.filter', Format(H.Lk_filter));
        if not TryCalc_Lk_constopt(H) then
            Observer.ObserveError('Lk_constopt.calc16');
        Observer.Observe('H3.constopt', Format(H.Lk_constopt));
        if not TryCalc_Lk_constenum(H) then
            Observer.ObserveError('Lk_constenum.calc17');
        Observer.Observe('H3.constenum', Format(H.Lk_constenum));
        if not TryCalc_Lk_filterenum(H) then
            Observer.ObserveError('Lk_filterenum.calc18');
        Observer.Observe('H3.filterenum', Format(H.Lk_filterenum));
        Observer.Expect('H1.const', 'alpha');
        Observer.Expect('H1.field', 'alpha');
        Observer.Expect('H1.filter', 'bravo');
        Observer.Expect('H1.constopt', 'alpha');
        Observer.Expect('H1.constenum', 'bravo');
        Observer.Expect('H1.filterenum', 'alpha');
        Observer.Expect('H2.const', 'alpha');
        Observer.Expect('H2.field', 'echo');
        Observer.Expect('H2.filter', 'bravo');
        Observer.Expect('H2.constopt', 'alpha');
        Observer.Expect('H2.constenum', 'bravo');
        Observer.Expect('H2.filterenum', 'alpha');
        Observer.Expect('H3.const', 'alpha');
        Observer.Expect('H3.field', '');
        Observer.Expect('H3.filter', 'bravo');
        Observer.Expect('H3.constopt', 'alpha');
        Observer.Expect('H3.constenum', 'bravo');
        Observer.Expect('H3.filterenum', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupText_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldLookupText with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Lk_ffint(H) then
            Observer.ObserveError('Lk_ffint.calc19');
        Observer.Observe('ffint.unset', Format(H.Lk_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Lk_ffint(H) then
            Observer.ObserveError('Lk_ffint.calc20');
        Observer.Observe('ffint.set', Format(H.Lk_ffint));
        H.Reset();
        if not TryCalc_Lk_ffdec(H) then
            Observer.ObserveError('Lk_ffdec.calc21');
        Observer.Observe('ffdec.unset', Format(H.Lk_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Lk_ffdec(H) then
            Observer.ObserveError('Lk_ffdec.calc22');
        Observer.Observe('ffdec.set', Format(H.Lk_ffdec));
        H.Reset();
        if not TryCalc_Lk_ffdate(H) then
            Observer.ObserveError('Lk_ffdate.calc23');
        Observer.Observe('ffdate.unset', Format(H.Lk_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Lk_ffdate(H) then
            Observer.ObserveError('Lk_ffdate.calc24');
        Observer.Observe('ffdate.set', Format(H.Lk_ffdate));
        H.Reset();
        if not TryCalc_Lk_ffcode(H) then
            Observer.ObserveError('Lk_ffcode.calc25');
        Observer.Observe('ffcode.unset', Format(H.Lk_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Lk_ffcode(H) then
            Observer.ObserveError('Lk_ffcode.calc26');
        Observer.Observe('ffcode.set', Format(H.Lk_ffcode));
        H.Reset();
        if not TryCalc_Lk_ffopt(H) then
            Observer.ObserveError('Lk_ffopt.calc27');
        Observer.Observe('ffopt.unset', Format(H.Lk_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Lk_ffopt(H) then
            Observer.ObserveError('Lk_ffopt.calc28');
        Observer.Observe('ffopt.set', Format(H.Lk_ffopt));
        H.Reset();
        if not TryCalc_Lk_ffenum(H) then
            Observer.ObserveError('Lk_ffenum.calc29');
        Observer.Observe('ffenum.unset', Format(H.Lk_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Lk_ffenum(H) then
            Observer.ObserveError('Lk_ffenum.calc30');
        Observer.Observe('ffenum.set', Format(H.Lk_ffenum));
        H.Reset();
        if not TryCalc_Lk_fftext(H) then
            Observer.ObserveError('Lk_fftext.calc31');
        Observer.Observe('fftext.unset', Format(H.Lk_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_Lk_fftext(H) then
            Observer.ObserveError('Lk_fftext.calc32');
        Observer.Observe('fftext.set', Format(H.Lk_fftext));
        Observer.Expect('ffint.unset', 'alpha');
        Observer.Expect('ffint.set', 'bravo');
        Observer.Expect('ffdec.unset', 'alpha');
        Observer.Expect('ffdec.set', 'bravo');
        Observer.Expect('ffdate.unset', 'alpha');
        Observer.Expect('ffdate.set', 'bravo');
        Observer.Expect('ffcode.unset', 'alpha');
        Observer.Expect('ffcode.set', 'alpha');
        Observer.Expect('ffopt.unset', 'alpha');
        Observer.Expect('ffopt.set', 'alpha');
        Observer.Expect('ffenum.unset', 'alpha');
        Observer.Expect('ffenum.set', 'bravo');
        Observer.Expect('fftext.unset', 'alpha');
        Observer.Expect('fftext.set', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupText_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldLookupText with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Lk_uldate(H) then
            Observer.ObserveError('Lk_uldate.calc33');
        Observer.Observe('uldate.unset', Format(H.Lk_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Lk_uldate(H) then
            Observer.ObserveError('Lk_uldate.calc34');
        Observer.Observe('uldate.set', Format(H.Lk_uldate));
        H.Reset();
        if not TryCalc_Lk_ulint(H) then
            Observer.ObserveError('Lk_ulint.calc35');
        Observer.Observe('ulint.unset', Format(H.Lk_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Lk_ulint(H) then
            Observer.ObserveError('Lk_ulint.calc36');
        Observer.Observe('ulint.set', Format(H.Lk_ulint));
        H.Reset();
        if not TryCalc_Lk_uldec(H) then
            Observer.ObserveError('Lk_uldec.calc37');
        Observer.Observe('uldec.unset', Format(H.Lk_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_Lk_uldec(H) then
            Observer.ObserveError('Lk_uldec.calc38');
        Observer.Observe('uldec.set', Format(H.Lk_uldec));
        H.Reset();
        if not TryCalc_Lk_ulcode(H) then
            Observer.ObserveError('Lk_ulcode.calc39');
        Observer.Observe('ulcode.unset', Format(H.Lk_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_Lk_ulcode(H) then
            Observer.ObserveError('Lk_ulcode.calc40');
        Observer.Observe('ulcode.set', Format(H.Lk_ulcode));
        H.Reset();
        if not TryCalc_Lk_ulopt(H) then
            Observer.ObserveError('Lk_ulopt.calc41');
        Observer.Observe('ulopt.unset', Format(H.Lk_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_Lk_ulopt(H) then
            Observer.ObserveError('Lk_ulopt.calc42');
        Observer.Observe('ulopt.set', Format(H.Lk_ulopt));
        H.Reset();
        if not TryCalc_Lk_ulenum(H) then
            Observer.ObserveError('Lk_ulenum.calc43');
        Observer.Observe('ulenum.unset', Format(H.Lk_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_Lk_ulenum(H) then
            Observer.ObserveError('Lk_ulenum.calc44');
        Observer.Observe('ulenum.set', Format(H.Lk_ulenum));
        H.Reset();
        if not TryCalc_Lk_ulfdate(H) then
            Observer.ObserveError('Lk_ulfdate.calc45');
        Observer.Observe('ulfdate.unset', Format(H.Lk_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Lk_ulfdate(H) then
            Observer.ObserveError('Lk_ulfdate.calc46');
        Observer.Observe('ulfdate.set', Format(H.Lk_ulfdate));
        Observer.Expect('uldate.unset', 'alpha');
        Observer.Expect('uldate.set', 'alpha');
        Observer.Expect('ulint.unset', 'alpha');
        Observer.Expect('ulint.set', 'alpha');
        Observer.Expect('uldec.unset', 'alpha');
        Observer.Expect('Lk_uldec.calc38|text', 'The filter expression ">=14" applied to the field DecF in the FFM Lookup Header table results in more than one range.');
        Observer.Expect('Lk_uldec.calc38|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', 'alpha');
        Observer.Expect('ulcode.unset', 'alpha');
        Observer.Expect('ulcode.set', 'alpha');
        Observer.Expect('ulopt.unset', 'alpha');
        Observer.Expect('ulopt.set', 'alpha');
        Observer.Expect('ulenum.unset', 'alpha');
        Observer.Expect('ulenum.set', 'alpha');
        Observer.Expect('ulfdate.unset', 'alpha');
        Observer.Expect('ulfdate.set', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupText_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldLookupText with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_Lk_ffmismatch(H) then
            Observer.ObserveError('Lk_ffmismatch.calc47');
        Observer.Observe('ffmismatch.unset', Format(H.Lk_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_Lk_ffmismatch(H) then
            Observer.ObserveError('Lk_ffmismatch.calc48');
        Observer.Observe('ffmismatch.set', Format(H.Lk_ffmismatch));
        H.Reset();
        if not TryCalc_Lk_ffboth(H) then
            Observer.ObserveError('Lk_ffboth.calc49');
        Observer.Observe('ffboth.unset', Format(H.Lk_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_Lk_ffboth(H) then
            Observer.ObserveError('Lk_ffboth.calc50');
        Observer.Observe('ffboth.set', Format(H.Lk_ffboth));
        Observer.Expect('ffmismatch.unset', 'alpha');
        Observer.Expect('ffmismatch.set', '');
        Observer.Expect('ffboth.unset', 'alpha');
        Observer.Expect('ffboth.set', 'bravo');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupText_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldLookupText over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_Lk_const(H) then
            Observer.ObserveError('Lk_const.calc51');
        Observer.Observe('const.h3', Format(H.Lk_const));
        if not TryCalc_Lk_field(H) then
            Observer.ObserveError('Lk_field.calc52');
        Observer.Observe('field.h3', Format(H.Lk_field));
        if not TryCalc_Lk_filter(H) then
            Observer.ObserveError('Lk_filter.calc53');
        Observer.Observe('filter.h3', Format(H.Lk_filter));
        if not TryCalc_Lk_constopt(H) then
            Observer.ObserveError('Lk_constopt.calc54');
        Observer.Observe('constopt.h3', Format(H.Lk_constopt));
        if not TryCalc_Lk_constenum(H) then
            Observer.ObserveError('Lk_constenum.calc55');
        Observer.Observe('constenum.h3', Format(H.Lk_constenum));
        if not TryCalc_Lk_filterenum(H) then
            Observer.ObserveError('Lk_filterenum.calc56');
        Observer.Observe('filterenum.h3', Format(H.Lk_filterenum));
        if not TryCalc_Lk_ffint(H) then
            Observer.ObserveError('Lk_ffint.calc57');
        Observer.Observe('ffint.h3', Format(H.Lk_ffint));
        if not TryCalc_Lk_ffdec(H) then
            Observer.ObserveError('Lk_ffdec.calc58');
        Observer.Observe('ffdec.h3', Format(H.Lk_ffdec));
        if not TryCalc_Lk_ffdate(H) then
            Observer.ObserveError('Lk_ffdate.calc59');
        Observer.Observe('ffdate.h3', Format(H.Lk_ffdate));
        if not TryCalc_Lk_ffcode(H) then
            Observer.ObserveError('Lk_ffcode.calc60');
        Observer.Observe('ffcode.h3', Format(H.Lk_ffcode));
        if not TryCalc_Lk_ffopt(H) then
            Observer.ObserveError('Lk_ffopt.calc61');
        Observer.Observe('ffopt.h3', Format(H.Lk_ffopt));
        if not TryCalc_Lk_ffenum(H) then
            Observer.ObserveError('Lk_ffenum.calc62');
        Observer.Observe('ffenum.h3', Format(H.Lk_ffenum));
        if not TryCalc_Lk_fftext(H) then
            Observer.ObserveError('Lk_fftext.calc63');
        Observer.Observe('fftext.h3', Format(H.Lk_fftext));
        if not TryCalc_Lk_uldate(H) then
            Observer.ObserveError('Lk_uldate.calc64');
        Observer.Observe('uldate.h3', Format(H.Lk_uldate));
        if not TryCalc_Lk_ulint(H) then
            Observer.ObserveError('Lk_ulint.calc65');
        Observer.Observe('ulint.h3', Format(H.Lk_ulint));
        if not TryCalc_Lk_uldec(H) then
            Observer.ObserveError('Lk_uldec.calc66');
        Observer.Observe('uldec.h3', Format(H.Lk_uldec));
        if not TryCalc_Lk_ulcode(H) then
            Observer.ObserveError('Lk_ulcode.calc67');
        Observer.Observe('ulcode.h3', Format(H.Lk_ulcode));
        if not TryCalc_Lk_ulopt(H) then
            Observer.ObserveError('Lk_ulopt.calc68');
        Observer.Observe('ulopt.h3', Format(H.Lk_ulopt));
        if not TryCalc_Lk_ulenum(H) then
            Observer.ObserveError('Lk_ulenum.calc69');
        Observer.Observe('ulenum.h3', Format(H.Lk_ulenum));
        if not TryCalc_Lk_ulfdate(H) then
            Observer.ObserveError('Lk_ulfdate.calc70');
        Observer.Observe('ulfdate.h3', Format(H.Lk_ulfdate));
        if not TryCalc_Lk_ffmismatch(H) then
            Observer.ObserveError('Lk_ffmismatch.calc71');
        Observer.Observe('ffmismatch.h3', Format(H.Lk_ffmismatch));
        if not TryCalc_Lk_ffboth(H) then
            Observer.ObserveError('Lk_ffboth.calc72');
        Observer.Observe('ffboth.h3', Format(H.Lk_ffboth));
        Observer.Expect('const.h3', 'alpha');
        Observer.Expect('field.h3', '');
        Observer.Expect('filter.h3', 'bravo');
        Observer.Expect('constopt.h3', 'alpha');
        Observer.Expect('constenum.h3', 'bravo');
        Observer.Expect('filterenum.h3', 'alpha');
        Observer.Expect('ffint.h3', 'alpha');
        Observer.Expect('ffdec.h3', 'alpha');
        Observer.Expect('ffdate.h3', 'alpha');
        Observer.Expect('ffcode.h3', 'alpha');
        Observer.Expect('ffopt.h3', 'alpha');
        Observer.Expect('ffenum.h3', 'alpha');
        Observer.Expect('fftext.h3', 'alpha');
        Observer.Expect('uldate.h3', 'alpha');
        Observer.Expect('ulint.h3', 'alpha');
        Observer.Expect('uldec.h3', 'alpha');
        Observer.Expect('ulcode.h3', 'alpha');
        Observer.Expect('ulopt.h3', 'alpha');
        Observer.Expect('ulenum.h3', 'alpha');
        Observer.Expect('ulfdate.h3', 'alpha');
        Observer.Expect('ffmismatch.h3', 'alpha');
        Observer.Expect('ffboth.h3', '');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldLookupDecimal with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_LkDec_const(H) then
            Observer.ObserveError('LkDec_const.calc73');
        Observer.Observe('H1.const', Format(H.LkDec_const));
        if not TryCalc_LkDec_field(H) then
            Observer.ObserveError('LkDec_field.calc74');
        Observer.Observe('H1.field', Format(H.LkDec_field));
        if not TryCalc_LkDec_filter(H) then
            Observer.ObserveError('LkDec_filter.calc75');
        Observer.Observe('H1.filter', Format(H.LkDec_filter));
        if not TryCalc_LkDec_constopt(H) then
            Observer.ObserveError('LkDec_constopt.calc76');
        Observer.Observe('H1.constopt', Format(H.LkDec_constopt));
        if not TryCalc_LkDec_constenum(H) then
            Observer.ObserveError('LkDec_constenum.calc77');
        Observer.Observe('H1.constenum', Format(H.LkDec_constenum));
        if not TryCalc_LkDec_filterenum(H) then
            Observer.ObserveError('LkDec_filterenum.calc78');
        Observer.Observe('H1.filterenum', Format(H.LkDec_filterenum));
        H.Get('H2');
        if not TryCalc_LkDec_const(H) then
            Observer.ObserveError('LkDec_const.calc79');
        Observer.Observe('H2.const', Format(H.LkDec_const));
        if not TryCalc_LkDec_field(H) then
            Observer.ObserveError('LkDec_field.calc80');
        Observer.Observe('H2.field', Format(H.LkDec_field));
        if not TryCalc_LkDec_filter(H) then
            Observer.ObserveError('LkDec_filter.calc81');
        Observer.Observe('H2.filter', Format(H.LkDec_filter));
        if not TryCalc_LkDec_constopt(H) then
            Observer.ObserveError('LkDec_constopt.calc82');
        Observer.Observe('H2.constopt', Format(H.LkDec_constopt));
        if not TryCalc_LkDec_constenum(H) then
            Observer.ObserveError('LkDec_constenum.calc83');
        Observer.Observe('H2.constenum', Format(H.LkDec_constenum));
        if not TryCalc_LkDec_filterenum(H) then
            Observer.ObserveError('LkDec_filterenum.calc84');
        Observer.Observe('H2.filterenum', Format(H.LkDec_filterenum));
        H.Get('H3');
        if not TryCalc_LkDec_const(H) then
            Observer.ObserveError('LkDec_const.calc85');
        Observer.Observe('H3.const', Format(H.LkDec_const));
        if not TryCalc_LkDec_field(H) then
            Observer.ObserveError('LkDec_field.calc86');
        Observer.Observe('H3.field', Format(H.LkDec_field));
        if not TryCalc_LkDec_filter(H) then
            Observer.ObserveError('LkDec_filter.calc87');
        Observer.Observe('H3.filter', Format(H.LkDec_filter));
        if not TryCalc_LkDec_constopt(H) then
            Observer.ObserveError('LkDec_constopt.calc88');
        Observer.Observe('H3.constopt', Format(H.LkDec_constopt));
        if not TryCalc_LkDec_constenum(H) then
            Observer.ObserveError('LkDec_constenum.calc89');
        Observer.Observe('H3.constenum', Format(H.LkDec_constenum));
        if not TryCalc_LkDec_filterenum(H) then
            Observer.ObserveError('LkDec_filterenum.calc90');
        Observer.Observe('H3.filterenum', Format(H.LkDec_filterenum));
        Observer.Expect('H1.const', '10.5');
        Observer.Expect('H1.field', '10.5');
        Observer.Expect('H1.filter', '20');
        Observer.Expect('H1.constopt', '10.5');
        Observer.Expect('H1.constenum', '20');
        Observer.Expect('H1.filterenum', '10.5');
        Observer.Expect('H2.const', '10.5');
        Observer.Expect('H2.field', '7');
        Observer.Expect('H2.filter', '20');
        Observer.Expect('H2.constopt', '10.5');
        Observer.Expect('H2.constenum', '20');
        Observer.Expect('H2.filterenum', '10.5');
        Observer.Expect('H3.const', '10.5');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '20');
        Observer.Expect('H3.constopt', '10.5');
        Observer.Expect('H3.constenum', '20');
        Observer.Expect('H3.filterenum', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldLookupDecimal with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_LkDec_ffint(H) then
            Observer.ObserveError('LkDec_ffint.calc91');
        Observer.Observe('ffint.unset', Format(H.LkDec_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_LkDec_ffint(H) then
            Observer.ObserveError('LkDec_ffint.calc92');
        Observer.Observe('ffint.set', Format(H.LkDec_ffint));
        H.Reset();
        if not TryCalc_LkDec_ffdec(H) then
            Observer.ObserveError('LkDec_ffdec.calc93');
        Observer.Observe('ffdec.unset', Format(H.LkDec_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_LkDec_ffdec(H) then
            Observer.ObserveError('LkDec_ffdec.calc94');
        Observer.Observe('ffdec.set', Format(H.LkDec_ffdec));
        H.Reset();
        if not TryCalc_LkDec_ffdate(H) then
            Observer.ObserveError('LkDec_ffdate.calc95');
        Observer.Observe('ffdate.unset', Format(H.LkDec_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_LkDec_ffdate(H) then
            Observer.ObserveError('LkDec_ffdate.calc96');
        Observer.Observe('ffdate.set', Format(H.LkDec_ffdate));
        H.Reset();
        if not TryCalc_LkDec_ffcode(H) then
            Observer.ObserveError('LkDec_ffcode.calc97');
        Observer.Observe('ffcode.unset', Format(H.LkDec_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_LkDec_ffcode(H) then
            Observer.ObserveError('LkDec_ffcode.calc98');
        Observer.Observe('ffcode.set', Format(H.LkDec_ffcode));
        H.Reset();
        if not TryCalc_LkDec_ffopt(H) then
            Observer.ObserveError('LkDec_ffopt.calc99');
        Observer.Observe('ffopt.unset', Format(H.LkDec_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_LkDec_ffopt(H) then
            Observer.ObserveError('LkDec_ffopt.calc100');
        Observer.Observe('ffopt.set', Format(H.LkDec_ffopt));
        H.Reset();
        if not TryCalc_LkDec_ffenum(H) then
            Observer.ObserveError('LkDec_ffenum.calc101');
        Observer.Observe('ffenum.unset', Format(H.LkDec_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_LkDec_ffenum(H) then
            Observer.ObserveError('LkDec_ffenum.calc102');
        Observer.Observe('ffenum.set', Format(H.LkDec_ffenum));
        H.Reset();
        if not TryCalc_LkDec_fftext(H) then
            Observer.ObserveError('LkDec_fftext.calc103');
        Observer.Observe('fftext.unset', Format(H.LkDec_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_LkDec_fftext(H) then
            Observer.ObserveError('LkDec_fftext.calc104');
        Observer.Observe('fftext.set', Format(H.LkDec_fftext));
        Observer.Expect('ffint.unset', '10.5');
        Observer.Expect('ffint.set', '20');
        Observer.Expect('ffdec.unset', '10.5');
        Observer.Expect('ffdec.set', '20');
        Observer.Expect('ffdate.unset', '10.5');
        Observer.Expect('ffdate.set', '20');
        Observer.Expect('ffcode.unset', '10.5');
        Observer.Expect('ffcode.set', '10.5');
        Observer.Expect('ffopt.unset', '10.5');
        Observer.Expect('ffopt.set', '10.5');
        Observer.Expect('ffenum.unset', '10.5');
        Observer.Expect('ffenum.set', '20');
        Observer.Expect('fftext.unset', '10.5');
        Observer.Expect('fftext.set', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldLookupDecimal with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_LkDec_uldate(H) then
            Observer.ObserveError('LkDec_uldate.calc105');
        Observer.Observe('uldate.unset', Format(H.LkDec_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_LkDec_uldate(H) then
            Observer.ObserveError('LkDec_uldate.calc106');
        Observer.Observe('uldate.set', Format(H.LkDec_uldate));
        H.Reset();
        if not TryCalc_LkDec_ulint(H) then
            Observer.ObserveError('LkDec_ulint.calc107');
        Observer.Observe('ulint.unset', Format(H.LkDec_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_LkDec_ulint(H) then
            Observer.ObserveError('LkDec_ulint.calc108');
        Observer.Observe('ulint.set', Format(H.LkDec_ulint));
        H.Reset();
        if not TryCalc_LkDec_uldec(H) then
            Observer.ObserveError('LkDec_uldec.calc109');
        Observer.Observe('uldec.unset', Format(H.LkDec_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_LkDec_uldec(H) then
            Observer.ObserveError('LkDec_uldec.calc110');
        Observer.Observe('uldec.set', Format(H.LkDec_uldec));
        H.Reset();
        if not TryCalc_LkDec_ulcode(H) then
            Observer.ObserveError('LkDec_ulcode.calc111');
        Observer.Observe('ulcode.unset', Format(H.LkDec_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_LkDec_ulcode(H) then
            Observer.ObserveError('LkDec_ulcode.calc112');
        Observer.Observe('ulcode.set', Format(H.LkDec_ulcode));
        H.Reset();
        if not TryCalc_LkDec_ulopt(H) then
            Observer.ObserveError('LkDec_ulopt.calc113');
        Observer.Observe('ulopt.unset', Format(H.LkDec_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_LkDec_ulopt(H) then
            Observer.ObserveError('LkDec_ulopt.calc114');
        Observer.Observe('ulopt.set', Format(H.LkDec_ulopt));
        H.Reset();
        if not TryCalc_LkDec_ulenum(H) then
            Observer.ObserveError('LkDec_ulenum.calc115');
        Observer.Observe('ulenum.unset', Format(H.LkDec_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_LkDec_ulenum(H) then
            Observer.ObserveError('LkDec_ulenum.calc116');
        Observer.Observe('ulenum.set', Format(H.LkDec_ulenum));
        H.Reset();
        if not TryCalc_LkDec_ulfdate(H) then
            Observer.ObserveError('LkDec_ulfdate.calc117');
        Observer.Observe('ulfdate.unset', Format(H.LkDec_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_LkDec_ulfdate(H) then
            Observer.ObserveError('LkDec_ulfdate.calc118');
        Observer.Observe('ulfdate.set', Format(H.LkDec_ulfdate));
        Observer.Expect('uldate.unset', '10.5');
        Observer.Expect('uldate.set', '10.5');
        Observer.Expect('ulint.unset', '10.5');
        Observer.Expect('ulint.set', '10.5');
        Observer.Expect('uldec.unset', '10.5');
        Observer.Expect('LkDec_uldec.calc110|text', 'The filter expression ">=14" applied to the field DecF in the FFM Lookup Header table results in more than one range.');
        Observer.Expect('LkDec_uldec.calc110|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '10.5');
        Observer.Expect('ulcode.unset', '10.5');
        Observer.Expect('ulcode.set', '10.5');
        Observer.Expect('ulopt.unset', '10.5');
        Observer.Expect('ulopt.set', '10.5');
        Observer.Expect('ulenum.unset', '10.5');
        Observer.Expect('ulenum.set', '10.5');
        Observer.Expect('ulfdate.unset', '10.5');
        Observer.Expect('ulfdate.set', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldLookupDecimal with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_LkDec_ffmismatch(H) then
            Observer.ObserveError('LkDec_ffmismatch.calc119');
        Observer.Observe('ffmismatch.unset', Format(H.LkDec_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_LkDec_ffmismatch(H) then
            Observer.ObserveError('LkDec_ffmismatch.calc120');
        Observer.Observe('ffmismatch.set', Format(H.LkDec_ffmismatch));
        H.Reset();
        if not TryCalc_LkDec_ffboth(H) then
            Observer.ObserveError('LkDec_ffboth.calc121');
        Observer.Observe('ffboth.unset', Format(H.LkDec_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_LkDec_ffboth(H) then
            Observer.ObserveError('LkDec_ffboth.calc122');
        Observer.Observe('ffboth.set', Format(H.LkDec_ffboth));
        Observer.Expect('ffmismatch.unset', '10.5');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '10.5');
        Observer.Expect('ffboth.set', '20');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldLookupDecimal over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_LkDec_const(H) then
            Observer.ObserveError('LkDec_const.calc123');
        Observer.Observe('const.h3', Format(H.LkDec_const));
        if not TryCalc_LkDec_field(H) then
            Observer.ObserveError('LkDec_field.calc124');
        Observer.Observe('field.h3', Format(H.LkDec_field));
        if not TryCalc_LkDec_filter(H) then
            Observer.ObserveError('LkDec_filter.calc125');
        Observer.Observe('filter.h3', Format(H.LkDec_filter));
        if not TryCalc_LkDec_constopt(H) then
            Observer.ObserveError('LkDec_constopt.calc126');
        Observer.Observe('constopt.h3', Format(H.LkDec_constopt));
        if not TryCalc_LkDec_constenum(H) then
            Observer.ObserveError('LkDec_constenum.calc127');
        Observer.Observe('constenum.h3', Format(H.LkDec_constenum));
        if not TryCalc_LkDec_filterenum(H) then
            Observer.ObserveError('LkDec_filterenum.calc128');
        Observer.Observe('filterenum.h3', Format(H.LkDec_filterenum));
        if not TryCalc_LkDec_ffint(H) then
            Observer.ObserveError('LkDec_ffint.calc129');
        Observer.Observe('ffint.h3', Format(H.LkDec_ffint));
        if not TryCalc_LkDec_ffdec(H) then
            Observer.ObserveError('LkDec_ffdec.calc130');
        Observer.Observe('ffdec.h3', Format(H.LkDec_ffdec));
        if not TryCalc_LkDec_ffdate(H) then
            Observer.ObserveError('LkDec_ffdate.calc131');
        Observer.Observe('ffdate.h3', Format(H.LkDec_ffdate));
        if not TryCalc_LkDec_ffcode(H) then
            Observer.ObserveError('LkDec_ffcode.calc132');
        Observer.Observe('ffcode.h3', Format(H.LkDec_ffcode));
        if not TryCalc_LkDec_ffopt(H) then
            Observer.ObserveError('LkDec_ffopt.calc133');
        Observer.Observe('ffopt.h3', Format(H.LkDec_ffopt));
        if not TryCalc_LkDec_ffenum(H) then
            Observer.ObserveError('LkDec_ffenum.calc134');
        Observer.Observe('ffenum.h3', Format(H.LkDec_ffenum));
        if not TryCalc_LkDec_fftext(H) then
            Observer.ObserveError('LkDec_fftext.calc135');
        Observer.Observe('fftext.h3', Format(H.LkDec_fftext));
        if not TryCalc_LkDec_uldate(H) then
            Observer.ObserveError('LkDec_uldate.calc136');
        Observer.Observe('uldate.h3', Format(H.LkDec_uldate));
        if not TryCalc_LkDec_ulint(H) then
            Observer.ObserveError('LkDec_ulint.calc137');
        Observer.Observe('ulint.h3', Format(H.LkDec_ulint));
        if not TryCalc_LkDec_uldec(H) then
            Observer.ObserveError('LkDec_uldec.calc138');
        Observer.Observe('uldec.h3', Format(H.LkDec_uldec));
        if not TryCalc_LkDec_ulcode(H) then
            Observer.ObserveError('LkDec_ulcode.calc139');
        Observer.Observe('ulcode.h3', Format(H.LkDec_ulcode));
        if not TryCalc_LkDec_ulopt(H) then
            Observer.ObserveError('LkDec_ulopt.calc140');
        Observer.Observe('ulopt.h3', Format(H.LkDec_ulopt));
        if not TryCalc_LkDec_ulenum(H) then
            Observer.ObserveError('LkDec_ulenum.calc141');
        Observer.Observe('ulenum.h3', Format(H.LkDec_ulenum));
        if not TryCalc_LkDec_ulfdate(H) then
            Observer.ObserveError('LkDec_ulfdate.calc142');
        Observer.Observe('ulfdate.h3', Format(H.LkDec_ulfdate));
        if not TryCalc_LkDec_ffmismatch(H) then
            Observer.ObserveError('LkDec_ffmismatch.calc143');
        Observer.Observe('ffmismatch.h3', Format(H.LkDec_ffmismatch));
        if not TryCalc_LkDec_ffboth(H) then
            Observer.ObserveError('LkDec_ffboth.calc144');
        Observer.Observe('ffboth.h3', Format(H.LkDec_ffboth));
        Observer.Expect('const.h3', '10.5');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '20');
        Observer.Expect('constopt.h3', '10.5');
        Observer.Expect('constenum.h3', '20');
        Observer.Expect('filterenum.h3', '10.5');
        Observer.Expect('ffint.h3', '10.5');
        Observer.Expect('ffdec.h3', '10.5');
        Observer.Expect('ffdate.h3', '10.5');
        Observer.Expect('ffcode.h3', '10.5');
        Observer.Expect('ffopt.h3', '10.5');
        Observer.Expect('ffenum.h3', '10.5');
        Observer.Expect('fftext.h3', '10.5');
        Observer.Expect('uldate.h3', '10.5');
        Observer.Expect('ulint.h3', '10.5');
        Observer.Expect('uldec.h3', '10.5');
        Observer.Expect('ulcode.h3', '10.5');
        Observer.Expect('ulopt.h3', '10.5');
        Observer.Expect('ulenum.h3', '10.5');
        Observer.Expect('ulfdate.h3', '10.5');
        Observer.Expect('ffmismatch.h3', '10.5');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedLookupDecimal with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        if not TryCalc_NLkDec_const(H) then
            Observer.ObserveError('NLkDec_const.calc145');
        Observer.Observe('H1.const', Format(H.NLkDec_const));
        if not TryCalc_NLkDec_field(H) then
            Observer.ObserveError('NLkDec_field.calc146');
        Observer.Observe('H1.field', Format(H.NLkDec_field));
        if not TryCalc_NLkDec_filter(H) then
            Observer.ObserveError('NLkDec_filter.calc147');
        Observer.Observe('H1.filter', Format(H.NLkDec_filter));
        if not TryCalc_NLkDec_constopt(H) then
            Observer.ObserveError('NLkDec_constopt.calc148');
        Observer.Observe('H1.constopt', Format(H.NLkDec_constopt));
        if not TryCalc_NLkDec_constenum(H) then
            Observer.ObserveError('NLkDec_constenum.calc149');
        Observer.Observe('H1.constenum', Format(H.NLkDec_constenum));
        if not TryCalc_NLkDec_filterenum(H) then
            Observer.ObserveError('NLkDec_filterenum.calc150');
        Observer.Observe('H1.filterenum', Format(H.NLkDec_filterenum));
        H.Get('H2');
        if not TryCalc_NLkDec_const(H) then
            Observer.ObserveError('NLkDec_const.calc151');
        Observer.Observe('H2.const', Format(H.NLkDec_const));
        if not TryCalc_NLkDec_field(H) then
            Observer.ObserveError('NLkDec_field.calc152');
        Observer.Observe('H2.field', Format(H.NLkDec_field));
        if not TryCalc_NLkDec_filter(H) then
            Observer.ObserveError('NLkDec_filter.calc153');
        Observer.Observe('H2.filter', Format(H.NLkDec_filter));
        if not TryCalc_NLkDec_constopt(H) then
            Observer.ObserveError('NLkDec_constopt.calc154');
        Observer.Observe('H2.constopt', Format(H.NLkDec_constopt));
        if not TryCalc_NLkDec_constenum(H) then
            Observer.ObserveError('NLkDec_constenum.calc155');
        Observer.Observe('H2.constenum', Format(H.NLkDec_constenum));
        if not TryCalc_NLkDec_filterenum(H) then
            Observer.ObserveError('NLkDec_filterenum.calc156');
        Observer.Observe('H2.filterenum', Format(H.NLkDec_filterenum));
        H.Get('H3');
        if not TryCalc_NLkDec_const(H) then
            Observer.ObserveError('NLkDec_const.calc157');
        Observer.Observe('H3.const', Format(H.NLkDec_const));
        if not TryCalc_NLkDec_field(H) then
            Observer.ObserveError('NLkDec_field.calc158');
        Observer.Observe('H3.field', Format(H.NLkDec_field));
        if not TryCalc_NLkDec_filter(H) then
            Observer.ObserveError('NLkDec_filter.calc159');
        Observer.Observe('H3.filter', Format(H.NLkDec_filter));
        if not TryCalc_NLkDec_constopt(H) then
            Observer.ObserveError('NLkDec_constopt.calc160');
        Observer.Observe('H3.constopt', Format(H.NLkDec_constopt));
        if not TryCalc_NLkDec_constenum(H) then
            Observer.ObserveError('NLkDec_constenum.calc161');
        Observer.Observe('H3.constenum', Format(H.NLkDec_constenum));
        if not TryCalc_NLkDec_filterenum(H) then
            Observer.ObserveError('NLkDec_filterenum.calc162');
        Observer.Observe('H3.filterenum', Format(H.NLkDec_filterenum));
        Observer.Expect('H1.const', '10.5');
        Observer.Expect('H1.field', '10.5');
        Observer.Expect('H1.filter', '20');
        Observer.Expect('H1.constopt', '10.5');
        Observer.Expect('H1.constenum', '20');
        Observer.Expect('H1.filterenum', '10.5');
        Observer.Expect('H2.const', '10.5');
        Observer.Expect('H2.field', '7');
        Observer.Expect('H2.filter', '20');
        Observer.Expect('H2.constopt', '10.5');
        Observer.Expect('H2.constenum', '20');
        Observer.Expect('H2.filterenum', '10.5');
        Observer.Expect('H3.const', '10.5');
        Observer.Expect('H3.field', '0');
        Observer.Expect('H3.filter', '20');
        Observer.Expect('H3.constopt', '10.5');
        Observer.Expect('H3.constenum', '20');
        Observer.Expect('H3.filterenum', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedLookupDecimal with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NLkDec_ffint(H) then
            Observer.ObserveError('NLkDec_ffint.calc163');
        Observer.Observe('ffint.unset', Format(H.NLkDec_ffint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NLkDec_ffint(H) then
            Observer.ObserveError('NLkDec_ffint.calc164');
        Observer.Observe('ffint.set', Format(H.NLkDec_ffint));
        H.Reset();
        if not TryCalc_NLkDec_ffdec(H) then
            Observer.ObserveError('NLkDec_ffdec.calc165');
        Observer.Observe('ffdec.unset', Format(H.NLkDec_ffdec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NLkDec_ffdec(H) then
            Observer.ObserveError('NLkDec_ffdec.calc166');
        Observer.Observe('ffdec.set', Format(H.NLkDec_ffdec));
        H.Reset();
        if not TryCalc_NLkDec_ffdate(H) then
            Observer.ObserveError('NLkDec_ffdate.calc167');
        Observer.Observe('ffdate.unset', Format(H.NLkDec_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NLkDec_ffdate(H) then
            Observer.ObserveError('NLkDec_ffdate.calc168');
        Observer.Observe('ffdate.set', Format(H.NLkDec_ffdate));
        H.Reset();
        if not TryCalc_NLkDec_ffcode(H) then
            Observer.ObserveError('NLkDec_ffcode.calc169');
        Observer.Observe('ffcode.unset', Format(H.NLkDec_ffcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NLkDec_ffcode(H) then
            Observer.ObserveError('NLkDec_ffcode.calc170');
        Observer.Observe('ffcode.set', Format(H.NLkDec_ffcode));
        H.Reset();
        if not TryCalc_NLkDec_ffopt(H) then
            Observer.ObserveError('NLkDec_ffopt.calc171');
        Observer.Observe('ffopt.unset', Format(H.NLkDec_ffopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NLkDec_ffopt(H) then
            Observer.ObserveError('NLkDec_ffopt.calc172');
        Observer.Observe('ffopt.set', Format(H.NLkDec_ffopt));
        H.Reset();
        if not TryCalc_NLkDec_ffenum(H) then
            Observer.ObserveError('NLkDec_ffenum.calc173');
        Observer.Observe('ffenum.unset', Format(H.NLkDec_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NLkDec_ffenum(H) then
            Observer.ObserveError('NLkDec_ffenum.calc174');
        Observer.Observe('ffenum.set', Format(H.NLkDec_ffenum));
        H.Reset();
        if not TryCalc_NLkDec_fftext(H) then
            Observer.ObserveError('NLkDec_fftext.calc175');
        Observer.Observe('fftext.unset', Format(H.NLkDec_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        if not TryCalc_NLkDec_fftext(H) then
            Observer.ObserveError('NLkDec_fftext.calc176');
        Observer.Observe('fftext.set', Format(H.NLkDec_fftext));
        Observer.Expect('ffint.unset', '10.5');
        Observer.Expect('ffint.set', '20');
        Observer.Expect('ffdec.unset', '10.5');
        Observer.Expect('ffdec.set', '20');
        Observer.Expect('ffdate.unset', '10.5');
        Observer.Expect('ffdate.set', '20');
        Observer.Expect('ffcode.unset', '10.5');
        Observer.Expect('ffcode.set', '10.5');
        Observer.Expect('ffopt.unset', '10.5');
        Observer.Expect('ffopt.set', '10.5');
        Observer.Expect('ffenum.unset', '10.5');
        Observer.Expect('ffenum.set', '20');
        Observer.Expect('fftext.unset', '10.5');
        Observer.Expect('fftext.set', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedLookupDecimal with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NLkDec_uldate(H) then
            Observer.ObserveError('NLkDec_uldate.calc177');
        Observer.Observe('uldate.unset', Format(H.NLkDec_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NLkDec_uldate(H) then
            Observer.ObserveError('NLkDec_uldate.calc178');
        Observer.Observe('uldate.set', Format(H.NLkDec_uldate));
        H.Reset();
        if not TryCalc_NLkDec_ulint(H) then
            Observer.ObserveError('NLkDec_ulint.calc179');
        Observer.Observe('ulint.unset', Format(H.NLkDec_ulint));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NLkDec_ulint(H) then
            Observer.ObserveError('NLkDec_ulint.calc180');
        Observer.Observe('ulint.set', Format(H.NLkDec_ulint));
        H.Reset();
        if not TryCalc_NLkDec_uldec(H) then
            Observer.ObserveError('NLkDec_uldec.calc181');
        Observer.Observe('uldec.unset', Format(H.NLkDec_uldec));
        H.SetFilter(DecF, '>=14');
        if not TryCalc_NLkDec_uldec(H) then
            Observer.ObserveError('NLkDec_uldec.calc182');
        Observer.Observe('uldec.set', Format(H.NLkDec_uldec));
        H.Reset();
        if not TryCalc_NLkDec_ulcode(H) then
            Observer.ObserveError('NLkDec_ulcode.calc183');
        Observer.Observe('ulcode.unset', Format(H.NLkDec_ulcode));
        H.SetFilter(CodeF, 'K1');
        if not TryCalc_NLkDec_ulcode(H) then
            Observer.ObserveError('NLkDec_ulcode.calc184');
        Observer.Observe('ulcode.set', Format(H.NLkDec_ulcode));
        H.Reset();
        if not TryCalc_NLkDec_ulopt(H) then
            Observer.ObserveError('NLkDec_ulopt.calc185');
        Observer.Observe('ulopt.unset', Format(H.NLkDec_ulopt));
        H.SetRange(OptF, H.OptF::B);
        if not TryCalc_NLkDec_ulopt(H) then
            Observer.ObserveError('NLkDec_ulopt.calc186');
        Observer.Observe('ulopt.set', Format(H.NLkDec_ulopt));
        H.Reset();
        if not TryCalc_NLkDec_ulenum(H) then
            Observer.ObserveError('NLkDec_ulenum.calc187');
        Observer.Observe('ulenum.unset', Format(H.NLkDec_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        if not TryCalc_NLkDec_ulenum(H) then
            Observer.ObserveError('NLkDec_ulenum.calc188');
        Observer.Observe('ulenum.set', Format(H.NLkDec_ulenum));
        H.Reset();
        if not TryCalc_NLkDec_ulfdate(H) then
            Observer.ObserveError('NLkDec_ulfdate.calc189');
        Observer.Observe('ulfdate.unset', Format(H.NLkDec_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NLkDec_ulfdate(H) then
            Observer.ObserveError('NLkDec_ulfdate.calc190');
        Observer.Observe('ulfdate.set', Format(H.NLkDec_ulfdate));
        Observer.Expect('uldate.unset', '10.5');
        Observer.Expect('uldate.set', '10.5');
        Observer.Expect('ulint.unset', '10.5');
        Observer.Expect('ulint.set', '10.5');
        Observer.Expect('uldec.unset', '10.5');
        Observer.Expect('NLkDec_uldec.calc182|text', 'The filter expression ">=14" applied to the field DecF in the FFM Lookup Header table results in more than one range.');
        Observer.Expect('NLkDec_uldec.calc182|code', 'DB:NotIntervalFilter');
        Observer.Expect('uldec.set', '10.5');
        Observer.Expect('ulcode.unset', '10.5');
        Observer.Expect('ulcode.set', '10.5');
        Observer.Expect('ulopt.unset', '10.5');
        Observer.Expect('ulopt.set', '10.5');
        Observer.Expect('ulenum.unset', '10.5');
        Observer.Expect('ulenum.set', '10.5');
        Observer.Expect('ulfdate.unset', '10.5');
        Observer.Expect('ulfdate.set', '10.5');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedLookupDecimal with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        if not TryCalc_NLkDec_ffmismatch(H) then
            Observer.ObserveError('NLkDec_ffmismatch.calc191');
        Observer.Observe('ffmismatch.unset', Format(H.NLkDec_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        if not TryCalc_NLkDec_ffmismatch(H) then
            Observer.ObserveError('NLkDec_ffmismatch.calc192');
        Observer.Observe('ffmismatch.set', Format(H.NLkDec_ffmismatch));
        H.Reset();
        if not TryCalc_NLkDec_ffboth(H) then
            Observer.ObserveError('NLkDec_ffboth.calc193');
        Observer.Observe('ffboth.unset', Format(H.NLkDec_ffboth));
        H.SetFilter(IntF, '3..5');
        if not TryCalc_NLkDec_ffboth(H) then
            Observer.ObserveError('NLkDec_ffboth.calc194');
        Observer.Observe('ffboth.set', Format(H.NLkDec_ffboth));
        Observer.Expect('ffmismatch.unset', '10.5');
        Observer.Expect('ffmismatch.set', '0');
        Observer.Expect('ffboth.unset', '10.5');
        Observer.Expect('ffboth.set', '20');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedLookupDecimal over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        if not TryCalc_NLkDec_const(H) then
            Observer.ObserveError('NLkDec_const.calc195');
        Observer.Observe('const.h3', Format(H.NLkDec_const));
        if not TryCalc_NLkDec_field(H) then
            Observer.ObserveError('NLkDec_field.calc196');
        Observer.Observe('field.h3', Format(H.NLkDec_field));
        if not TryCalc_NLkDec_filter(H) then
            Observer.ObserveError('NLkDec_filter.calc197');
        Observer.Observe('filter.h3', Format(H.NLkDec_filter));
        if not TryCalc_NLkDec_constopt(H) then
            Observer.ObserveError('NLkDec_constopt.calc198');
        Observer.Observe('constopt.h3', Format(H.NLkDec_constopt));
        if not TryCalc_NLkDec_constenum(H) then
            Observer.ObserveError('NLkDec_constenum.calc199');
        Observer.Observe('constenum.h3', Format(H.NLkDec_constenum));
        if not TryCalc_NLkDec_filterenum(H) then
            Observer.ObserveError('NLkDec_filterenum.calc200');
        Observer.Observe('filterenum.h3', Format(H.NLkDec_filterenum));
        if not TryCalc_NLkDec_ffint(H) then
            Observer.ObserveError('NLkDec_ffint.calc201');
        Observer.Observe('ffint.h3', Format(H.NLkDec_ffint));
        if not TryCalc_NLkDec_ffdec(H) then
            Observer.ObserveError('NLkDec_ffdec.calc202');
        Observer.Observe('ffdec.h3', Format(H.NLkDec_ffdec));
        if not TryCalc_NLkDec_ffdate(H) then
            Observer.ObserveError('NLkDec_ffdate.calc203');
        Observer.Observe('ffdate.h3', Format(H.NLkDec_ffdate));
        if not TryCalc_NLkDec_ffcode(H) then
            Observer.ObserveError('NLkDec_ffcode.calc204');
        Observer.Observe('ffcode.h3', Format(H.NLkDec_ffcode));
        if not TryCalc_NLkDec_ffopt(H) then
            Observer.ObserveError('NLkDec_ffopt.calc205');
        Observer.Observe('ffopt.h3', Format(H.NLkDec_ffopt));
        if not TryCalc_NLkDec_ffenum(H) then
            Observer.ObserveError('NLkDec_ffenum.calc206');
        Observer.Observe('ffenum.h3', Format(H.NLkDec_ffenum));
        if not TryCalc_NLkDec_fftext(H) then
            Observer.ObserveError('NLkDec_fftext.calc207');
        Observer.Observe('fftext.h3', Format(H.NLkDec_fftext));
        if not TryCalc_NLkDec_uldate(H) then
            Observer.ObserveError('NLkDec_uldate.calc208');
        Observer.Observe('uldate.h3', Format(H.NLkDec_uldate));
        if not TryCalc_NLkDec_ulint(H) then
            Observer.ObserveError('NLkDec_ulint.calc209');
        Observer.Observe('ulint.h3', Format(H.NLkDec_ulint));
        if not TryCalc_NLkDec_uldec(H) then
            Observer.ObserveError('NLkDec_uldec.calc210');
        Observer.Observe('uldec.h3', Format(H.NLkDec_uldec));
        if not TryCalc_NLkDec_ulcode(H) then
            Observer.ObserveError('NLkDec_ulcode.calc211');
        Observer.Observe('ulcode.h3', Format(H.NLkDec_ulcode));
        if not TryCalc_NLkDec_ulopt(H) then
            Observer.ObserveError('NLkDec_ulopt.calc212');
        Observer.Observe('ulopt.h3', Format(H.NLkDec_ulopt));
        if not TryCalc_NLkDec_ulenum(H) then
            Observer.ObserveError('NLkDec_ulenum.calc213');
        Observer.Observe('ulenum.h3', Format(H.NLkDec_ulenum));
        if not TryCalc_NLkDec_ulfdate(H) then
            Observer.ObserveError('NLkDec_ulfdate.calc214');
        Observer.Observe('ulfdate.h3', Format(H.NLkDec_ulfdate));
        if not TryCalc_NLkDec_ffmismatch(H) then
            Observer.ObserveError('NLkDec_ffmismatch.calc215');
        Observer.Observe('ffmismatch.h3', Format(H.NLkDec_ffmismatch));
        if not TryCalc_NLkDec_ffboth(H) then
            Observer.ObserveError('NLkDec_ffboth.calc216');
        Observer.Observe('ffboth.h3', Format(H.NLkDec_ffboth));
        Observer.Expect('const.h3', '10.5');
        Observer.Expect('field.h3', '0');
        Observer.Expect('filter.h3', '20');
        Observer.Expect('constopt.h3', '10.5');
        Observer.Expect('constenum.h3', '20');
        Observer.Expect('filterenum.h3', '10.5');
        Observer.Expect('ffint.h3', '10.5');
        Observer.Expect('ffdec.h3', '10.5');
        Observer.Expect('ffdate.h3', '10.5');
        Observer.Expect('ffcode.h3', '10.5');
        Observer.Expect('ffopt.h3', '10.5');
        Observer.Expect('ffenum.h3', '10.5');
        Observer.Expect('fftext.h3', '10.5');
        Observer.Expect('uldate.h3', '10.5');
        Observer.Expect('ulint.h3', '10.5');
        Observer.Expect('uldec.h3', '10.5');
        Observer.Expect('ulcode.h3', '10.5');
        Observer.Expect('ulopt.h3', '10.5');
        Observer.Expect('ulenum.h3', '10.5');
        Observer.Expect('ulfdate.h3', '10.5');
        Observer.Expect('ffmismatch.h3', '10.5');
        Observer.Expect('ffboth.h3', '0');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        D: Record "FFM Lookup Detail";
        H: Record "FFM Lookup Header";
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
        D: Record "FFM Lookup Detail";
    begin
        D.Init();
        D."Entry No." := EntryNo;
        D.Owner := OwnerCode;
        D.Qty := Quantity;
        D.Amt := Amount;
        D.Day := Date;
        D.Kind := KindCode;
        D.Opt := Option;
        D.Status := "FFM Lookup Status".FromInteger(StatusValue);
        D.Flag := FlagValue;
        D.Name := NameValue;
        D.Insert();
    end;

    local procedure AddHeader(HeaderCode: Code[10])
    var
        H: Record "FFM Lookup Header";
    begin
        H.Init();
        H.Code := HeaderCode;
        H.Insert();
    end;
}
