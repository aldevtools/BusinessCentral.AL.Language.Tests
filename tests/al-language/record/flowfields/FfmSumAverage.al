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

    [Test]
    procedure FlowFieldSum_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldSum with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Sum_const);
        Observer.Observe('H1.const', Format(H.Sum_const));
        H.CalcFields(Sum_field);
        Observer.Observe('H1.field', Format(H.Sum_field));
        H.CalcFields(Sum_filter);
        Observer.Observe('H1.filter', Format(H.Sum_filter));
        H.CalcFields(Sum_constopt);
        Observer.Observe('H1.constopt', Format(H.Sum_constopt));
        H.CalcFields(Sum_constenum);
        Observer.Observe('H1.constenum', Format(H.Sum_constenum));
        H.CalcFields(Sum_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Sum_filterenum));
        H.Get('H2');
        H.CalcFields(Sum_const);
        Observer.Observe('H2.const', Format(H.Sum_const));
        H.CalcFields(Sum_field);
        Observer.Observe('H2.field', Format(H.Sum_field));
        H.CalcFields(Sum_filter);
        Observer.Observe('H2.filter', Format(H.Sum_filter));
        H.CalcFields(Sum_constopt);
        Observer.Observe('H2.constopt', Format(H.Sum_constopt));
        H.CalcFields(Sum_constenum);
        Observer.Observe('H2.constenum', Format(H.Sum_constenum));
        H.CalcFields(Sum_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Sum_filterenum));
        H.Get('H3');
        H.CalcFields(Sum_const);
        Observer.Observe('H3.const', Format(H.Sum_const));
        H.CalcFields(Sum_field);
        Observer.Observe('H3.field', Format(H.Sum_field));
        H.CalcFields(Sum_filter);
        Observer.Observe('H3.filter', Format(H.Sum_filter));
        H.CalcFields(Sum_constopt);
        Observer.Observe('H3.constopt', Format(H.Sum_constopt));
        H.CalcFields(Sum_constenum);
        Observer.Observe('H3.constenum', Format(H.Sum_constenum));
        H.CalcFields(Sum_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Sum_filterenum));
        Observer.Finish();
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
        H.CalcFields(Sum_ffint);
        Observer.Observe('ffint.unset', Format(H.Sum_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Sum_ffint);
        Observer.Observe('ffint.set', Format(H.Sum_ffint));
        H.Reset();
        H.CalcFields(Sum_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Sum_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Sum_ffdec);
        Observer.Observe('ffdec.set', Format(H.Sum_ffdec));
        H.Reset();
        H.CalcFields(Sum_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Sum_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Sum_ffdate);
        Observer.Observe('ffdate.set', Format(H.Sum_ffdate));
        H.Reset();
        H.CalcFields(Sum_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Sum_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Sum_ffcode);
        Observer.Observe('ffcode.set', Format(H.Sum_ffcode));
        H.Reset();
        H.CalcFields(Sum_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Sum_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Sum_ffopt);
        Observer.Observe('ffopt.set', Format(H.Sum_ffopt));
        H.Reset();
        H.CalcFields(Sum_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Sum_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Sum_ffenum);
        Observer.Observe('ffenum.set', Format(H.Sum_ffenum));
        H.Reset();
        H.CalcFields(Sum_fftext);
        Observer.Observe('fftext.unset', Format(H.Sum_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Sum_fftext);
        Observer.Observe('fftext.set', Format(H.Sum_fftext));
        Observer.Finish();
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
        H.CalcFields(Sum_uldate);
        Observer.Observe('uldate.unset', Format(H.Sum_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Sum_uldate);
        Observer.Observe('uldate.set', Format(H.Sum_uldate));
        H.Reset();
        H.CalcFields(Sum_ulint);
        Observer.Observe('ulint.unset', Format(H.Sum_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Sum_ulint);
        Observer.Observe('ulint.set', Format(H.Sum_ulint));
        H.Reset();
        H.CalcFields(Sum_uldec);
        Observer.Observe('uldec.unset', Format(H.Sum_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Sum_uldec);
        Observer.Observe('uldec.set', Format(H.Sum_uldec));
        H.Reset();
        H.CalcFields(Sum_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Sum_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Sum_ulcode);
        Observer.Observe('ulcode.set', Format(H.Sum_ulcode));
        H.Reset();
        H.CalcFields(Sum_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Sum_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Sum_ulopt);
        Observer.Observe('ulopt.set', Format(H.Sum_ulopt));
        H.Reset();
        H.CalcFields(Sum_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Sum_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Sum_ulenum);
        Observer.Observe('ulenum.set', Format(H.Sum_ulenum));
        H.Reset();
        H.CalcFields(Sum_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Sum_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Sum_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Sum_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Sum_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Sum_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Sum_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Sum_ffmismatch));
        H.Reset();
        H.CalcFields(Sum_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Sum_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Sum_ffboth);
        Observer.Observe('ffboth.set', Format(H.Sum_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldSum_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldSum over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Sum_const);
        Observer.Observe('const.h3', Format(H.Sum_const));
        H.CalcFields(Sum_field);
        Observer.Observe('field.h3', Format(H.Sum_field));
        H.CalcFields(Sum_filter);
        Observer.Observe('filter.h3', Format(H.Sum_filter));
        H.CalcFields(Sum_constopt);
        Observer.Observe('constopt.h3', Format(H.Sum_constopt));
        H.CalcFields(Sum_constenum);
        Observer.Observe('constenum.h3', Format(H.Sum_constenum));
        H.CalcFields(Sum_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Sum_filterenum));
        H.CalcFields(Sum_ffint);
        Observer.Observe('ffint.h3', Format(H.Sum_ffint));
        H.CalcFields(Sum_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Sum_ffdec));
        H.CalcFields(Sum_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Sum_ffdate));
        H.CalcFields(Sum_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Sum_ffcode));
        H.CalcFields(Sum_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Sum_ffopt));
        H.CalcFields(Sum_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Sum_ffenum));
        H.CalcFields(Sum_fftext);
        Observer.Observe('fftext.h3', Format(H.Sum_fftext));
        H.CalcFields(Sum_uldate);
        Observer.Observe('uldate.h3', Format(H.Sum_uldate));
        H.CalcFields(Sum_ulint);
        Observer.Observe('ulint.h3', Format(H.Sum_ulint));
        H.CalcFields(Sum_uldec);
        Observer.Observe('uldec.h3', Format(H.Sum_uldec));
        H.CalcFields(Sum_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Sum_ulcode));
        H.CalcFields(Sum_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Sum_ulopt));
        H.CalcFields(Sum_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Sum_ulenum));
        H.CalcFields(Sum_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Sum_ulfdate));
        H.CalcFields(Sum_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Sum_ffmismatch));
        H.CalcFields(Sum_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Sum_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedSum_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedSum with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NSum_const);
        Observer.Observe('H1.const', Format(H.NSum_const));
        H.CalcFields(NSum_field);
        Observer.Observe('H1.field', Format(H.NSum_field));
        H.CalcFields(NSum_filter);
        Observer.Observe('H1.filter', Format(H.NSum_filter));
        H.CalcFields(NSum_constopt);
        Observer.Observe('H1.constopt', Format(H.NSum_constopt));
        H.CalcFields(NSum_constenum);
        Observer.Observe('H1.constenum', Format(H.NSum_constenum));
        H.CalcFields(NSum_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NSum_filterenum));
        H.Get('H2');
        H.CalcFields(NSum_const);
        Observer.Observe('H2.const', Format(H.NSum_const));
        H.CalcFields(NSum_field);
        Observer.Observe('H2.field', Format(H.NSum_field));
        H.CalcFields(NSum_filter);
        Observer.Observe('H2.filter', Format(H.NSum_filter));
        H.CalcFields(NSum_constopt);
        Observer.Observe('H2.constopt', Format(H.NSum_constopt));
        H.CalcFields(NSum_constenum);
        Observer.Observe('H2.constenum', Format(H.NSum_constenum));
        H.CalcFields(NSum_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NSum_filterenum));
        H.Get('H3');
        H.CalcFields(NSum_const);
        Observer.Observe('H3.const', Format(H.NSum_const));
        H.CalcFields(NSum_field);
        Observer.Observe('H3.field', Format(H.NSum_field));
        H.CalcFields(NSum_filter);
        Observer.Observe('H3.filter', Format(H.NSum_filter));
        H.CalcFields(NSum_constopt);
        Observer.Observe('H3.constopt', Format(H.NSum_constopt));
        H.CalcFields(NSum_constenum);
        Observer.Observe('H3.constenum', Format(H.NSum_constenum));
        H.CalcFields(NSum_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NSum_filterenum));
        Observer.Finish();
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
        H.CalcFields(NSum_ffint);
        Observer.Observe('ffint.unset', Format(H.NSum_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NSum_ffint);
        Observer.Observe('ffint.set', Format(H.NSum_ffint));
        H.Reset();
        H.CalcFields(NSum_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NSum_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NSum_ffdec);
        Observer.Observe('ffdec.set', Format(H.NSum_ffdec));
        H.Reset();
        H.CalcFields(NSum_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NSum_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NSum_ffdate);
        Observer.Observe('ffdate.set', Format(H.NSum_ffdate));
        H.Reset();
        H.CalcFields(NSum_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NSum_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NSum_ffcode);
        Observer.Observe('ffcode.set', Format(H.NSum_ffcode));
        H.Reset();
        H.CalcFields(NSum_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NSum_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NSum_ffopt);
        Observer.Observe('ffopt.set', Format(H.NSum_ffopt));
        H.Reset();
        H.CalcFields(NSum_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NSum_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NSum_ffenum);
        Observer.Observe('ffenum.set', Format(H.NSum_ffenum));
        H.Reset();
        H.CalcFields(NSum_fftext);
        Observer.Observe('fftext.unset', Format(H.NSum_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NSum_fftext);
        Observer.Observe('fftext.set', Format(H.NSum_fftext));
        Observer.Finish();
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
        H.CalcFields(NSum_uldate);
        Observer.Observe('uldate.unset', Format(H.NSum_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NSum_uldate);
        Observer.Observe('uldate.set', Format(H.NSum_uldate));
        H.Reset();
        H.CalcFields(NSum_ulint);
        Observer.Observe('ulint.unset', Format(H.NSum_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NSum_ulint);
        Observer.Observe('ulint.set', Format(H.NSum_ulint));
        H.Reset();
        H.CalcFields(NSum_uldec);
        Observer.Observe('uldec.unset', Format(H.NSum_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NSum_uldec);
        Observer.Observe('uldec.set', Format(H.NSum_uldec));
        H.Reset();
        H.CalcFields(NSum_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NSum_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NSum_ulcode);
        Observer.Observe('ulcode.set', Format(H.NSum_ulcode));
        H.Reset();
        H.CalcFields(NSum_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NSum_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NSum_ulopt);
        Observer.Observe('ulopt.set', Format(H.NSum_ulopt));
        H.Reset();
        H.CalcFields(NSum_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NSum_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NSum_ulenum);
        Observer.Observe('ulenum.set', Format(H.NSum_ulenum));
        H.Reset();
        H.CalcFields(NSum_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NSum_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NSum_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NSum_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NSum_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NSum_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NSum_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NSum_ffmismatch));
        H.Reset();
        H.CalcFields(NSum_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NSum_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NSum_ffboth);
        Observer.Observe('ffboth.set', Format(H.NSum_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedSum_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedSum over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NSum_const);
        Observer.Observe('const.h3', Format(H.NSum_const));
        H.CalcFields(NSum_field);
        Observer.Observe('field.h3', Format(H.NSum_field));
        H.CalcFields(NSum_filter);
        Observer.Observe('filter.h3', Format(H.NSum_filter));
        H.CalcFields(NSum_constopt);
        Observer.Observe('constopt.h3', Format(H.NSum_constopt));
        H.CalcFields(NSum_constenum);
        Observer.Observe('constenum.h3', Format(H.NSum_constenum));
        H.CalcFields(NSum_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NSum_filterenum));
        H.CalcFields(NSum_ffint);
        Observer.Observe('ffint.h3', Format(H.NSum_ffint));
        H.CalcFields(NSum_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NSum_ffdec));
        H.CalcFields(NSum_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NSum_ffdate));
        H.CalcFields(NSum_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NSum_ffcode));
        H.CalcFields(NSum_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NSum_ffopt));
        H.CalcFields(NSum_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NSum_ffenum));
        H.CalcFields(NSum_fftext);
        Observer.Observe('fftext.h3', Format(H.NSum_fftext));
        H.CalcFields(NSum_uldate);
        Observer.Observe('uldate.h3', Format(H.NSum_uldate));
        H.CalcFields(NSum_ulint);
        Observer.Observe('ulint.h3', Format(H.NSum_ulint));
        H.CalcFields(NSum_uldec);
        Observer.Observe('uldec.h3', Format(H.NSum_uldec));
        H.CalcFields(NSum_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NSum_ulcode));
        H.CalcFields(NSum_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NSum_ulopt));
        H.CalcFields(NSum_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NSum_ulenum));
        H.CalcFields(NSum_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NSum_ulfdate));
        H.CalcFields(NSum_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NSum_ffmismatch));
        H.CalcFields(NSum_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NSum_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldAverage_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldAverage with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Avg_const);
        Observer.Observe('H1.const', Format(H.Avg_const));
        H.CalcFields(Avg_field);
        Observer.Observe('H1.field', Format(H.Avg_field));
        H.CalcFields(Avg_filter);
        Observer.Observe('H1.filter', Format(H.Avg_filter));
        H.CalcFields(Avg_constopt);
        Observer.Observe('H1.constopt', Format(H.Avg_constopt));
        H.CalcFields(Avg_constenum);
        Observer.Observe('H1.constenum', Format(H.Avg_constenum));
        H.CalcFields(Avg_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Avg_filterenum));
        H.Get('H2');
        H.CalcFields(Avg_const);
        Observer.Observe('H2.const', Format(H.Avg_const));
        H.CalcFields(Avg_field);
        Observer.Observe('H2.field', Format(H.Avg_field));
        H.CalcFields(Avg_filter);
        Observer.Observe('H2.filter', Format(H.Avg_filter));
        H.CalcFields(Avg_constopt);
        Observer.Observe('H2.constopt', Format(H.Avg_constopt));
        H.CalcFields(Avg_constenum);
        Observer.Observe('H2.constenum', Format(H.Avg_constenum));
        H.CalcFields(Avg_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Avg_filterenum));
        H.Get('H3');
        H.CalcFields(Avg_const);
        Observer.Observe('H3.const', Format(H.Avg_const));
        H.CalcFields(Avg_field);
        Observer.Observe('H3.field', Format(H.Avg_field));
        H.CalcFields(Avg_filter);
        Observer.Observe('H3.filter', Format(H.Avg_filter));
        H.CalcFields(Avg_constopt);
        Observer.Observe('H3.constopt', Format(H.Avg_constopt));
        H.CalcFields(Avg_constenum);
        Observer.Observe('H3.constenum', Format(H.Avg_constenum));
        H.CalcFields(Avg_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Avg_filterenum));
        Observer.Finish();
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
        H.CalcFields(Avg_ffint);
        Observer.Observe('ffint.unset', Format(H.Avg_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Avg_ffint);
        Observer.Observe('ffint.set', Format(H.Avg_ffint));
        H.Reset();
        H.CalcFields(Avg_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Avg_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Avg_ffdec);
        Observer.Observe('ffdec.set', Format(H.Avg_ffdec));
        H.Reset();
        H.CalcFields(Avg_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Avg_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Avg_ffdate);
        Observer.Observe('ffdate.set', Format(H.Avg_ffdate));
        H.Reset();
        H.CalcFields(Avg_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Avg_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Avg_ffcode);
        Observer.Observe('ffcode.set', Format(H.Avg_ffcode));
        H.Reset();
        H.CalcFields(Avg_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Avg_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Avg_ffopt);
        Observer.Observe('ffopt.set', Format(H.Avg_ffopt));
        H.Reset();
        H.CalcFields(Avg_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Avg_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Avg_ffenum);
        Observer.Observe('ffenum.set', Format(H.Avg_ffenum));
        H.Reset();
        H.CalcFields(Avg_fftext);
        Observer.Observe('fftext.unset', Format(H.Avg_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Avg_fftext);
        Observer.Observe('fftext.set', Format(H.Avg_fftext));
        Observer.Finish();
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
        H.CalcFields(Avg_uldate);
        Observer.Observe('uldate.unset', Format(H.Avg_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Avg_uldate);
        Observer.Observe('uldate.set', Format(H.Avg_uldate));
        H.Reset();
        H.CalcFields(Avg_ulint);
        Observer.Observe('ulint.unset', Format(H.Avg_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Avg_ulint);
        Observer.Observe('ulint.set', Format(H.Avg_ulint));
        H.Reset();
        H.CalcFields(Avg_uldec);
        Observer.Observe('uldec.unset', Format(H.Avg_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Avg_uldec);
        Observer.Observe('uldec.set', Format(H.Avg_uldec));
        H.Reset();
        H.CalcFields(Avg_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Avg_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Avg_ulcode);
        Observer.Observe('ulcode.set', Format(H.Avg_ulcode));
        H.Reset();
        H.CalcFields(Avg_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Avg_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Avg_ulopt);
        Observer.Observe('ulopt.set', Format(H.Avg_ulopt));
        H.Reset();
        H.CalcFields(Avg_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Avg_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Avg_ulenum);
        Observer.Observe('ulenum.set', Format(H.Avg_ulenum));
        H.Reset();
        H.CalcFields(Avg_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Avg_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Avg_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Avg_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Avg_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Avg_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Avg_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Avg_ffmismatch));
        H.Reset();
        H.CalcFields(Avg_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Avg_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Avg_ffboth);
        Observer.Observe('ffboth.set', Format(H.Avg_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldAverage_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldAverage over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Avg_const);
        Observer.Observe('const.h3', Format(H.Avg_const));
        H.CalcFields(Avg_field);
        Observer.Observe('field.h3', Format(H.Avg_field));
        H.CalcFields(Avg_filter);
        Observer.Observe('filter.h3', Format(H.Avg_filter));
        H.CalcFields(Avg_constopt);
        Observer.Observe('constopt.h3', Format(H.Avg_constopt));
        H.CalcFields(Avg_constenum);
        Observer.Observe('constenum.h3', Format(H.Avg_constenum));
        H.CalcFields(Avg_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Avg_filterenum));
        H.CalcFields(Avg_ffint);
        Observer.Observe('ffint.h3', Format(H.Avg_ffint));
        H.CalcFields(Avg_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Avg_ffdec));
        H.CalcFields(Avg_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Avg_ffdate));
        H.CalcFields(Avg_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Avg_ffcode));
        H.CalcFields(Avg_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Avg_ffopt));
        H.CalcFields(Avg_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Avg_ffenum));
        H.CalcFields(Avg_fftext);
        Observer.Observe('fftext.h3', Format(H.Avg_fftext));
        H.CalcFields(Avg_uldate);
        Observer.Observe('uldate.h3', Format(H.Avg_uldate));
        H.CalcFields(Avg_ulint);
        Observer.Observe('ulint.h3', Format(H.Avg_ulint));
        H.CalcFields(Avg_uldec);
        Observer.Observe('uldec.h3', Format(H.Avg_uldec));
        H.CalcFields(Avg_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Avg_ulcode));
        H.CalcFields(Avg_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Avg_ulopt));
        H.CalcFields(Avg_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Avg_ulenum));
        H.CalcFields(Avg_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Avg_ulfdate));
        H.CalcFields(Avg_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Avg_ffmismatch));
        H.CalcFields(Avg_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Avg_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedAverage with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NAvg_const);
        Observer.Observe('H1.const', Format(H.NAvg_const));
        H.CalcFields(NAvg_field);
        Observer.Observe('H1.field', Format(H.NAvg_field));
        H.CalcFields(NAvg_filter);
        Observer.Observe('H1.filter', Format(H.NAvg_filter));
        H.CalcFields(NAvg_constopt);
        Observer.Observe('H1.constopt', Format(H.NAvg_constopt));
        H.CalcFields(NAvg_constenum);
        Observer.Observe('H1.constenum', Format(H.NAvg_constenum));
        H.CalcFields(NAvg_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NAvg_filterenum));
        H.Get('H2');
        H.CalcFields(NAvg_const);
        Observer.Observe('H2.const', Format(H.NAvg_const));
        H.CalcFields(NAvg_field);
        Observer.Observe('H2.field', Format(H.NAvg_field));
        H.CalcFields(NAvg_filter);
        Observer.Observe('H2.filter', Format(H.NAvg_filter));
        H.CalcFields(NAvg_constopt);
        Observer.Observe('H2.constopt', Format(H.NAvg_constopt));
        H.CalcFields(NAvg_constenum);
        Observer.Observe('H2.constenum', Format(H.NAvg_constenum));
        H.CalcFields(NAvg_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NAvg_filterenum));
        H.Get('H3');
        H.CalcFields(NAvg_const);
        Observer.Observe('H3.const', Format(H.NAvg_const));
        H.CalcFields(NAvg_field);
        Observer.Observe('H3.field', Format(H.NAvg_field));
        H.CalcFields(NAvg_filter);
        Observer.Observe('H3.filter', Format(H.NAvg_filter));
        H.CalcFields(NAvg_constopt);
        Observer.Observe('H3.constopt', Format(H.NAvg_constopt));
        H.CalcFields(NAvg_constenum);
        Observer.Observe('H3.constenum', Format(H.NAvg_constenum));
        H.CalcFields(NAvg_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NAvg_filterenum));
        Observer.Finish();
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
        H.CalcFields(NAvg_ffint);
        Observer.Observe('ffint.unset', Format(H.NAvg_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NAvg_ffint);
        Observer.Observe('ffint.set', Format(H.NAvg_ffint));
        H.Reset();
        H.CalcFields(NAvg_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NAvg_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NAvg_ffdec);
        Observer.Observe('ffdec.set', Format(H.NAvg_ffdec));
        H.Reset();
        H.CalcFields(NAvg_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NAvg_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NAvg_ffdate);
        Observer.Observe('ffdate.set', Format(H.NAvg_ffdate));
        H.Reset();
        H.CalcFields(NAvg_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NAvg_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NAvg_ffcode);
        Observer.Observe('ffcode.set', Format(H.NAvg_ffcode));
        H.Reset();
        H.CalcFields(NAvg_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NAvg_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NAvg_ffopt);
        Observer.Observe('ffopt.set', Format(H.NAvg_ffopt));
        H.Reset();
        H.CalcFields(NAvg_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NAvg_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NAvg_ffenum);
        Observer.Observe('ffenum.set', Format(H.NAvg_ffenum));
        H.Reset();
        H.CalcFields(NAvg_fftext);
        Observer.Observe('fftext.unset', Format(H.NAvg_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NAvg_fftext);
        Observer.Observe('fftext.set', Format(H.NAvg_fftext));
        Observer.Finish();
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
        H.CalcFields(NAvg_uldate);
        Observer.Observe('uldate.unset', Format(H.NAvg_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NAvg_uldate);
        Observer.Observe('uldate.set', Format(H.NAvg_uldate));
        H.Reset();
        H.CalcFields(NAvg_ulint);
        Observer.Observe('ulint.unset', Format(H.NAvg_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NAvg_ulint);
        Observer.Observe('ulint.set', Format(H.NAvg_ulint));
        H.Reset();
        H.CalcFields(NAvg_uldec);
        Observer.Observe('uldec.unset', Format(H.NAvg_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NAvg_uldec);
        Observer.Observe('uldec.set', Format(H.NAvg_uldec));
        H.Reset();
        H.CalcFields(NAvg_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NAvg_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NAvg_ulcode);
        Observer.Observe('ulcode.set', Format(H.NAvg_ulcode));
        H.Reset();
        H.CalcFields(NAvg_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NAvg_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NAvg_ulopt);
        Observer.Observe('ulopt.set', Format(H.NAvg_ulopt));
        H.Reset();
        H.CalcFields(NAvg_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NAvg_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NAvg_ulenum);
        Observer.Observe('ulenum.set', Format(H.NAvg_ulenum));
        H.Reset();
        H.CalcFields(NAvg_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NAvg_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NAvg_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NAvg_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NAvg_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NAvg_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NAvg_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NAvg_ffmismatch));
        H.Reset();
        H.CalcFields(NAvg_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NAvg_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NAvg_ffboth);
        Observer.Observe('ffboth.set', Format(H.NAvg_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedAverage_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedAverage over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM SumAvg Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NAvg_const);
        Observer.Observe('const.h3', Format(H.NAvg_const));
        H.CalcFields(NAvg_field);
        Observer.Observe('field.h3', Format(H.NAvg_field));
        H.CalcFields(NAvg_filter);
        Observer.Observe('filter.h3', Format(H.NAvg_filter));
        H.CalcFields(NAvg_constopt);
        Observer.Observe('constopt.h3', Format(H.NAvg_constopt));
        H.CalcFields(NAvg_constenum);
        Observer.Observe('constenum.h3', Format(H.NAvg_constenum));
        H.CalcFields(NAvg_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NAvg_filterenum));
        H.CalcFields(NAvg_ffint);
        Observer.Observe('ffint.h3', Format(H.NAvg_ffint));
        H.CalcFields(NAvg_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NAvg_ffdec));
        H.CalcFields(NAvg_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NAvg_ffdate));
        H.CalcFields(NAvg_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NAvg_ffcode));
        H.CalcFields(NAvg_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NAvg_ffopt));
        H.CalcFields(NAvg_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NAvg_ffenum));
        H.CalcFields(NAvg_fftext);
        Observer.Observe('fftext.h3', Format(H.NAvg_fftext));
        H.CalcFields(NAvg_uldate);
        Observer.Observe('uldate.h3', Format(H.NAvg_uldate));
        H.CalcFields(NAvg_ulint);
        Observer.Observe('ulint.h3', Format(H.NAvg_ulint));
        H.CalcFields(NAvg_uldec);
        Observer.Observe('uldec.h3', Format(H.NAvg_uldec));
        H.CalcFields(NAvg_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NAvg_ulcode));
        H.CalcFields(NAvg_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NAvg_ulopt));
        H.CalcFields(NAvg_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NAvg_ulenum));
        H.CalcFields(NAvg_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NAvg_ulfdate));
        H.CalcFields(NAvg_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NAvg_ffmismatch));
        H.CalcFields(NAvg_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NAvg_ffboth));
        Observer.Finish();
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
