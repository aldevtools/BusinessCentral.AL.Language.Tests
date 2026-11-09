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

    [Test]
    procedure FlowFieldMin_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldMin with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Min_const);
        Observer.Observe('H1.const', Format(H.Min_const));
        H.CalcFields(Min_field);
        Observer.Observe('H1.field', Format(H.Min_field));
        H.CalcFields(Min_filter);
        Observer.Observe('H1.filter', Format(H.Min_filter));
        H.CalcFields(Min_constopt);
        Observer.Observe('H1.constopt', Format(H.Min_constopt));
        H.CalcFields(Min_constenum);
        Observer.Observe('H1.constenum', Format(H.Min_constenum));
        H.CalcFields(Min_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Min_filterenum));
        H.Get('H2');
        H.CalcFields(Min_const);
        Observer.Observe('H2.const', Format(H.Min_const));
        H.CalcFields(Min_field);
        Observer.Observe('H2.field', Format(H.Min_field));
        H.CalcFields(Min_filter);
        Observer.Observe('H2.filter', Format(H.Min_filter));
        H.CalcFields(Min_constopt);
        Observer.Observe('H2.constopt', Format(H.Min_constopt));
        H.CalcFields(Min_constenum);
        Observer.Observe('H2.constenum', Format(H.Min_constenum));
        H.CalcFields(Min_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Min_filterenum));
        H.Get('H3');
        H.CalcFields(Min_const);
        Observer.Observe('H3.const', Format(H.Min_const));
        H.CalcFields(Min_field);
        Observer.Observe('H3.field', Format(H.Min_field));
        H.CalcFields(Min_filter);
        Observer.Observe('H3.filter', Format(H.Min_filter));
        H.CalcFields(Min_constopt);
        Observer.Observe('H3.constopt', Format(H.Min_constopt));
        H.CalcFields(Min_constenum);
        Observer.Observe('H3.constenum', Format(H.Min_constenum));
        H.CalcFields(Min_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Min_filterenum));
        Observer.Finish();
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
        H.CalcFields(Min_ffint);
        Observer.Observe('ffint.unset', Format(H.Min_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Min_ffint);
        Observer.Observe('ffint.set', Format(H.Min_ffint));
        H.Reset();
        H.CalcFields(Min_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Min_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Min_ffdec);
        Observer.Observe('ffdec.set', Format(H.Min_ffdec));
        H.Reset();
        H.CalcFields(Min_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Min_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Min_ffdate);
        Observer.Observe('ffdate.set', Format(H.Min_ffdate));
        H.Reset();
        H.CalcFields(Min_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Min_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Min_ffcode);
        Observer.Observe('ffcode.set', Format(H.Min_ffcode));
        H.Reset();
        H.CalcFields(Min_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Min_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Min_ffopt);
        Observer.Observe('ffopt.set', Format(H.Min_ffopt));
        H.Reset();
        H.CalcFields(Min_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Min_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Min_ffenum);
        Observer.Observe('ffenum.set', Format(H.Min_ffenum));
        H.Reset();
        H.CalcFields(Min_fftext);
        Observer.Observe('fftext.unset', Format(H.Min_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Min_fftext);
        Observer.Observe('fftext.set', Format(H.Min_fftext));
        Observer.Finish();
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
        H.CalcFields(Min_uldate);
        Observer.Observe('uldate.unset', Format(H.Min_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Min_uldate);
        Observer.Observe('uldate.set', Format(H.Min_uldate));
        H.Reset();
        H.CalcFields(Min_ulint);
        Observer.Observe('ulint.unset', Format(H.Min_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Min_ulint);
        Observer.Observe('ulint.set', Format(H.Min_ulint));
        H.Reset();
        H.CalcFields(Min_uldec);
        Observer.Observe('uldec.unset', Format(H.Min_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Min_uldec);
        Observer.Observe('uldec.set', Format(H.Min_uldec));
        H.Reset();
        H.CalcFields(Min_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Min_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Min_ulcode);
        Observer.Observe('ulcode.set', Format(H.Min_ulcode));
        H.Reset();
        H.CalcFields(Min_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Min_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Min_ulopt);
        Observer.Observe('ulopt.set', Format(H.Min_ulopt));
        H.Reset();
        H.CalcFields(Min_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Min_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Min_ulenum);
        Observer.Observe('ulenum.set', Format(H.Min_ulenum));
        H.Reset();
        H.CalcFields(Min_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Min_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Min_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Min_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Min_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Min_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Min_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Min_ffmismatch));
        H.Reset();
        H.CalcFields(Min_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Min_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Min_ffboth);
        Observer.Observe('ffboth.set', Format(H.Min_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldMin_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldMin over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Min_const);
        Observer.Observe('const.h3', Format(H.Min_const));
        H.CalcFields(Min_field);
        Observer.Observe('field.h3', Format(H.Min_field));
        H.CalcFields(Min_filter);
        Observer.Observe('filter.h3', Format(H.Min_filter));
        H.CalcFields(Min_constopt);
        Observer.Observe('constopt.h3', Format(H.Min_constopt));
        H.CalcFields(Min_constenum);
        Observer.Observe('constenum.h3', Format(H.Min_constenum));
        H.CalcFields(Min_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Min_filterenum));
        H.CalcFields(Min_ffint);
        Observer.Observe('ffint.h3', Format(H.Min_ffint));
        H.CalcFields(Min_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Min_ffdec));
        H.CalcFields(Min_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Min_ffdate));
        H.CalcFields(Min_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Min_ffcode));
        H.CalcFields(Min_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Min_ffopt));
        H.CalcFields(Min_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Min_ffenum));
        H.CalcFields(Min_fftext);
        Observer.Observe('fftext.h3', Format(H.Min_fftext));
        H.CalcFields(Min_uldate);
        Observer.Observe('uldate.h3', Format(H.Min_uldate));
        H.CalcFields(Min_ulint);
        Observer.Observe('ulint.h3', Format(H.Min_ulint));
        H.CalcFields(Min_uldec);
        Observer.Observe('uldec.h3', Format(H.Min_uldec));
        H.CalcFields(Min_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Min_ulcode));
        H.CalcFields(Min_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Min_ulopt));
        H.CalcFields(Min_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Min_ulenum));
        H.CalcFields(Min_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Min_ulfdate));
        H.CalcFields(Min_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Min_ffmismatch));
        H.CalcFields(Min_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Min_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedMin_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedMin with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NMin_const);
        Observer.Observe('H1.const', Format(H.NMin_const));
        H.CalcFields(NMin_field);
        Observer.Observe('H1.field', Format(H.NMin_field));
        H.CalcFields(NMin_filter);
        Observer.Observe('H1.filter', Format(H.NMin_filter));
        H.CalcFields(NMin_constopt);
        Observer.Observe('H1.constopt', Format(H.NMin_constopt));
        H.CalcFields(NMin_constenum);
        Observer.Observe('H1.constenum', Format(H.NMin_constenum));
        H.CalcFields(NMin_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NMin_filterenum));
        H.Get('H2');
        H.CalcFields(NMin_const);
        Observer.Observe('H2.const', Format(H.NMin_const));
        H.CalcFields(NMin_field);
        Observer.Observe('H2.field', Format(H.NMin_field));
        H.CalcFields(NMin_filter);
        Observer.Observe('H2.filter', Format(H.NMin_filter));
        H.CalcFields(NMin_constopt);
        Observer.Observe('H2.constopt', Format(H.NMin_constopt));
        H.CalcFields(NMin_constenum);
        Observer.Observe('H2.constenum', Format(H.NMin_constenum));
        H.CalcFields(NMin_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NMin_filterenum));
        H.Get('H3');
        H.CalcFields(NMin_const);
        Observer.Observe('H3.const', Format(H.NMin_const));
        H.CalcFields(NMin_field);
        Observer.Observe('H3.field', Format(H.NMin_field));
        H.CalcFields(NMin_filter);
        Observer.Observe('H3.filter', Format(H.NMin_filter));
        H.CalcFields(NMin_constopt);
        Observer.Observe('H3.constopt', Format(H.NMin_constopt));
        H.CalcFields(NMin_constenum);
        Observer.Observe('H3.constenum', Format(H.NMin_constenum));
        H.CalcFields(NMin_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NMin_filterenum));
        Observer.Finish();
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
        H.CalcFields(NMin_ffint);
        Observer.Observe('ffint.unset', Format(H.NMin_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMin_ffint);
        Observer.Observe('ffint.set', Format(H.NMin_ffint));
        H.Reset();
        H.CalcFields(NMin_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NMin_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NMin_ffdec);
        Observer.Observe('ffdec.set', Format(H.NMin_ffdec));
        H.Reset();
        H.CalcFields(NMin_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NMin_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMin_ffdate);
        Observer.Observe('ffdate.set', Format(H.NMin_ffdate));
        H.Reset();
        H.CalcFields(NMin_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NMin_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NMin_ffcode);
        Observer.Observe('ffcode.set', Format(H.NMin_ffcode));
        H.Reset();
        H.CalcFields(NMin_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NMin_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NMin_ffopt);
        Observer.Observe('ffopt.set', Format(H.NMin_ffopt));
        H.Reset();
        H.CalcFields(NMin_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NMin_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NMin_ffenum);
        Observer.Observe('ffenum.set', Format(H.NMin_ffenum));
        H.Reset();
        H.CalcFields(NMin_fftext);
        Observer.Observe('fftext.unset', Format(H.NMin_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NMin_fftext);
        Observer.Observe('fftext.set', Format(H.NMin_fftext));
        Observer.Finish();
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
        H.CalcFields(NMin_uldate);
        Observer.Observe('uldate.unset', Format(H.NMin_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMin_uldate);
        Observer.Observe('uldate.set', Format(H.NMin_uldate));
        H.Reset();
        H.CalcFields(NMin_ulint);
        Observer.Observe('ulint.unset', Format(H.NMin_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMin_ulint);
        Observer.Observe('ulint.set', Format(H.NMin_ulint));
        H.Reset();
        H.CalcFields(NMin_uldec);
        Observer.Observe('uldec.unset', Format(H.NMin_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NMin_uldec);
        Observer.Observe('uldec.set', Format(H.NMin_uldec));
        H.Reset();
        H.CalcFields(NMin_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NMin_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NMin_ulcode);
        Observer.Observe('ulcode.set', Format(H.NMin_ulcode));
        H.Reset();
        H.CalcFields(NMin_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NMin_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NMin_ulopt);
        Observer.Observe('ulopt.set', Format(H.NMin_ulopt));
        H.Reset();
        H.CalcFields(NMin_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NMin_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NMin_ulenum);
        Observer.Observe('ulenum.set', Format(H.NMin_ulenum));
        H.Reset();
        H.CalcFields(NMin_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NMin_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMin_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NMin_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NMin_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NMin_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMin_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NMin_ffmismatch));
        H.Reset();
        H.CalcFields(NMin_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NMin_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMin_ffboth);
        Observer.Observe('ffboth.set', Format(H.NMin_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedMin_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedMin over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NMin_const);
        Observer.Observe('const.h3', Format(H.NMin_const));
        H.CalcFields(NMin_field);
        Observer.Observe('field.h3', Format(H.NMin_field));
        H.CalcFields(NMin_filter);
        Observer.Observe('filter.h3', Format(H.NMin_filter));
        H.CalcFields(NMin_constopt);
        Observer.Observe('constopt.h3', Format(H.NMin_constopt));
        H.CalcFields(NMin_constenum);
        Observer.Observe('constenum.h3', Format(H.NMin_constenum));
        H.CalcFields(NMin_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NMin_filterenum));
        H.CalcFields(NMin_ffint);
        Observer.Observe('ffint.h3', Format(H.NMin_ffint));
        H.CalcFields(NMin_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NMin_ffdec));
        H.CalcFields(NMin_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NMin_ffdate));
        H.CalcFields(NMin_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NMin_ffcode));
        H.CalcFields(NMin_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NMin_ffopt));
        H.CalcFields(NMin_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NMin_ffenum));
        H.CalcFields(NMin_fftext);
        Observer.Observe('fftext.h3', Format(H.NMin_fftext));
        H.CalcFields(NMin_uldate);
        Observer.Observe('uldate.h3', Format(H.NMin_uldate));
        H.CalcFields(NMin_ulint);
        Observer.Observe('ulint.h3', Format(H.NMin_ulint));
        H.CalcFields(NMin_uldec);
        Observer.Observe('uldec.h3', Format(H.NMin_uldec));
        H.CalcFields(NMin_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NMin_ulcode));
        H.CalcFields(NMin_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NMin_ulopt));
        H.CalcFields(NMin_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NMin_ulenum));
        H.CalcFields(NMin_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NMin_ulfdate));
        H.CalcFields(NMin_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NMin_ffmismatch));
        H.CalcFields(NMin_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NMin_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldMax_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldMax with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Max_const);
        Observer.Observe('H1.const', Format(H.Max_const));
        H.CalcFields(Max_field);
        Observer.Observe('H1.field', Format(H.Max_field));
        H.CalcFields(Max_filter);
        Observer.Observe('H1.filter', Format(H.Max_filter));
        H.CalcFields(Max_constopt);
        Observer.Observe('H1.constopt', Format(H.Max_constopt));
        H.CalcFields(Max_constenum);
        Observer.Observe('H1.constenum', Format(H.Max_constenum));
        H.CalcFields(Max_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Max_filterenum));
        H.Get('H2');
        H.CalcFields(Max_const);
        Observer.Observe('H2.const', Format(H.Max_const));
        H.CalcFields(Max_field);
        Observer.Observe('H2.field', Format(H.Max_field));
        H.CalcFields(Max_filter);
        Observer.Observe('H2.filter', Format(H.Max_filter));
        H.CalcFields(Max_constopt);
        Observer.Observe('H2.constopt', Format(H.Max_constopt));
        H.CalcFields(Max_constenum);
        Observer.Observe('H2.constenum', Format(H.Max_constenum));
        H.CalcFields(Max_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Max_filterenum));
        H.Get('H3');
        H.CalcFields(Max_const);
        Observer.Observe('H3.const', Format(H.Max_const));
        H.CalcFields(Max_field);
        Observer.Observe('H3.field', Format(H.Max_field));
        H.CalcFields(Max_filter);
        Observer.Observe('H3.filter', Format(H.Max_filter));
        H.CalcFields(Max_constopt);
        Observer.Observe('H3.constopt', Format(H.Max_constopt));
        H.CalcFields(Max_constenum);
        Observer.Observe('H3.constenum', Format(H.Max_constenum));
        H.CalcFields(Max_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Max_filterenum));
        Observer.Finish();
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
        H.CalcFields(Max_ffint);
        Observer.Observe('ffint.unset', Format(H.Max_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Max_ffint);
        Observer.Observe('ffint.set', Format(H.Max_ffint));
        H.Reset();
        H.CalcFields(Max_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Max_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Max_ffdec);
        Observer.Observe('ffdec.set', Format(H.Max_ffdec));
        H.Reset();
        H.CalcFields(Max_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Max_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Max_ffdate);
        Observer.Observe('ffdate.set', Format(H.Max_ffdate));
        H.Reset();
        H.CalcFields(Max_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Max_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Max_ffcode);
        Observer.Observe('ffcode.set', Format(H.Max_ffcode));
        H.Reset();
        H.CalcFields(Max_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Max_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Max_ffopt);
        Observer.Observe('ffopt.set', Format(H.Max_ffopt));
        H.Reset();
        H.CalcFields(Max_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Max_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Max_ffenum);
        Observer.Observe('ffenum.set', Format(H.Max_ffenum));
        H.Reset();
        H.CalcFields(Max_fftext);
        Observer.Observe('fftext.unset', Format(H.Max_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Max_fftext);
        Observer.Observe('fftext.set', Format(H.Max_fftext));
        Observer.Finish();
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
        H.CalcFields(Max_uldate);
        Observer.Observe('uldate.unset', Format(H.Max_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Max_uldate);
        Observer.Observe('uldate.set', Format(H.Max_uldate));
        H.Reset();
        H.CalcFields(Max_ulint);
        Observer.Observe('ulint.unset', Format(H.Max_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Max_ulint);
        Observer.Observe('ulint.set', Format(H.Max_ulint));
        H.Reset();
        H.CalcFields(Max_uldec);
        Observer.Observe('uldec.unset', Format(H.Max_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Max_uldec);
        Observer.Observe('uldec.set', Format(H.Max_uldec));
        H.Reset();
        H.CalcFields(Max_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Max_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Max_ulcode);
        Observer.Observe('ulcode.set', Format(H.Max_ulcode));
        H.Reset();
        H.CalcFields(Max_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Max_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Max_ulopt);
        Observer.Observe('ulopt.set', Format(H.Max_ulopt));
        H.Reset();
        H.CalcFields(Max_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Max_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Max_ulenum);
        Observer.Observe('ulenum.set', Format(H.Max_ulenum));
        H.Reset();
        H.CalcFields(Max_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Max_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Max_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Max_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Max_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Max_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Max_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Max_ffmismatch));
        H.Reset();
        H.CalcFields(Max_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Max_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Max_ffboth);
        Observer.Observe('ffboth.set', Format(H.Max_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldMax_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldMax over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Max_const);
        Observer.Observe('const.h3', Format(H.Max_const));
        H.CalcFields(Max_field);
        Observer.Observe('field.h3', Format(H.Max_field));
        H.CalcFields(Max_filter);
        Observer.Observe('filter.h3', Format(H.Max_filter));
        H.CalcFields(Max_constopt);
        Observer.Observe('constopt.h3', Format(H.Max_constopt));
        H.CalcFields(Max_constenum);
        Observer.Observe('constenum.h3', Format(H.Max_constenum));
        H.CalcFields(Max_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Max_filterenum));
        H.CalcFields(Max_ffint);
        Observer.Observe('ffint.h3', Format(H.Max_ffint));
        H.CalcFields(Max_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Max_ffdec));
        H.CalcFields(Max_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Max_ffdate));
        H.CalcFields(Max_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Max_ffcode));
        H.CalcFields(Max_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Max_ffopt));
        H.CalcFields(Max_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Max_ffenum));
        H.CalcFields(Max_fftext);
        Observer.Observe('fftext.h3', Format(H.Max_fftext));
        H.CalcFields(Max_uldate);
        Observer.Observe('uldate.h3', Format(H.Max_uldate));
        H.CalcFields(Max_ulint);
        Observer.Observe('ulint.h3', Format(H.Max_ulint));
        H.CalcFields(Max_uldec);
        Observer.Observe('uldec.h3', Format(H.Max_uldec));
        H.CalcFields(Max_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Max_ulcode));
        H.CalcFields(Max_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Max_ulopt));
        H.CalcFields(Max_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Max_ulenum));
        H.CalcFields(Max_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Max_ulfdate));
        H.CalcFields(Max_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Max_ffmismatch));
        H.CalcFields(Max_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Max_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedMax_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedMax with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NMax_const);
        Observer.Observe('H1.const', Format(H.NMax_const));
        H.CalcFields(NMax_field);
        Observer.Observe('H1.field', Format(H.NMax_field));
        H.CalcFields(NMax_filter);
        Observer.Observe('H1.filter', Format(H.NMax_filter));
        H.CalcFields(NMax_constopt);
        Observer.Observe('H1.constopt', Format(H.NMax_constopt));
        H.CalcFields(NMax_constenum);
        Observer.Observe('H1.constenum', Format(H.NMax_constenum));
        H.CalcFields(NMax_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NMax_filterenum));
        H.Get('H2');
        H.CalcFields(NMax_const);
        Observer.Observe('H2.const', Format(H.NMax_const));
        H.CalcFields(NMax_field);
        Observer.Observe('H2.field', Format(H.NMax_field));
        H.CalcFields(NMax_filter);
        Observer.Observe('H2.filter', Format(H.NMax_filter));
        H.CalcFields(NMax_constopt);
        Observer.Observe('H2.constopt', Format(H.NMax_constopt));
        H.CalcFields(NMax_constenum);
        Observer.Observe('H2.constenum', Format(H.NMax_constenum));
        H.CalcFields(NMax_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NMax_filterenum));
        H.Get('H3');
        H.CalcFields(NMax_const);
        Observer.Observe('H3.const', Format(H.NMax_const));
        H.CalcFields(NMax_field);
        Observer.Observe('H3.field', Format(H.NMax_field));
        H.CalcFields(NMax_filter);
        Observer.Observe('H3.filter', Format(H.NMax_filter));
        H.CalcFields(NMax_constopt);
        Observer.Observe('H3.constopt', Format(H.NMax_constopt));
        H.CalcFields(NMax_constenum);
        Observer.Observe('H3.constenum', Format(H.NMax_constenum));
        H.CalcFields(NMax_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NMax_filterenum));
        Observer.Finish();
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
        H.CalcFields(NMax_ffint);
        Observer.Observe('ffint.unset', Format(H.NMax_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMax_ffint);
        Observer.Observe('ffint.set', Format(H.NMax_ffint));
        H.Reset();
        H.CalcFields(NMax_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NMax_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NMax_ffdec);
        Observer.Observe('ffdec.set', Format(H.NMax_ffdec));
        H.Reset();
        H.CalcFields(NMax_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NMax_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMax_ffdate);
        Observer.Observe('ffdate.set', Format(H.NMax_ffdate));
        H.Reset();
        H.CalcFields(NMax_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NMax_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NMax_ffcode);
        Observer.Observe('ffcode.set', Format(H.NMax_ffcode));
        H.Reset();
        H.CalcFields(NMax_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NMax_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NMax_ffopt);
        Observer.Observe('ffopt.set', Format(H.NMax_ffopt));
        H.Reset();
        H.CalcFields(NMax_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NMax_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NMax_ffenum);
        Observer.Observe('ffenum.set', Format(H.NMax_ffenum));
        H.Reset();
        H.CalcFields(NMax_fftext);
        Observer.Observe('fftext.unset', Format(H.NMax_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NMax_fftext);
        Observer.Observe('fftext.set', Format(H.NMax_fftext));
        Observer.Finish();
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
        H.CalcFields(NMax_uldate);
        Observer.Observe('uldate.unset', Format(H.NMax_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMax_uldate);
        Observer.Observe('uldate.set', Format(H.NMax_uldate));
        H.Reset();
        H.CalcFields(NMax_ulint);
        Observer.Observe('ulint.unset', Format(H.NMax_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMax_ulint);
        Observer.Observe('ulint.set', Format(H.NMax_ulint));
        H.Reset();
        H.CalcFields(NMax_uldec);
        Observer.Observe('uldec.unset', Format(H.NMax_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NMax_uldec);
        Observer.Observe('uldec.set', Format(H.NMax_uldec));
        H.Reset();
        H.CalcFields(NMax_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NMax_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NMax_ulcode);
        Observer.Observe('ulcode.set', Format(H.NMax_ulcode));
        H.Reset();
        H.CalcFields(NMax_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NMax_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NMax_ulopt);
        Observer.Observe('ulopt.set', Format(H.NMax_ulopt));
        H.Reset();
        H.CalcFields(NMax_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NMax_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NMax_ulenum);
        Observer.Observe('ulenum.set', Format(H.NMax_ulenum));
        H.Reset();
        H.CalcFields(NMax_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NMax_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMax_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NMax_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NMax_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NMax_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NMax_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NMax_ffmismatch));
        H.Reset();
        H.CalcFields(NMax_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NMax_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NMax_ffboth);
        Observer.Observe('ffboth.set', Format(H.NMax_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedMax_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedMax over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM MinMax Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NMax_const);
        Observer.Observe('const.h3', Format(H.NMax_const));
        H.CalcFields(NMax_field);
        Observer.Observe('field.h3', Format(H.NMax_field));
        H.CalcFields(NMax_filter);
        Observer.Observe('filter.h3', Format(H.NMax_filter));
        H.CalcFields(NMax_constopt);
        Observer.Observe('constopt.h3', Format(H.NMax_constopt));
        H.CalcFields(NMax_constenum);
        Observer.Observe('constenum.h3', Format(H.NMax_constenum));
        H.CalcFields(NMax_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NMax_filterenum));
        H.CalcFields(NMax_ffint);
        Observer.Observe('ffint.h3', Format(H.NMax_ffint));
        H.CalcFields(NMax_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NMax_ffdec));
        H.CalcFields(NMax_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NMax_ffdate));
        H.CalcFields(NMax_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NMax_ffcode));
        H.CalcFields(NMax_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NMax_ffopt));
        H.CalcFields(NMax_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NMax_ffenum));
        H.CalcFields(NMax_fftext);
        Observer.Observe('fftext.h3', Format(H.NMax_fftext));
        H.CalcFields(NMax_uldate);
        Observer.Observe('uldate.h3', Format(H.NMax_uldate));
        H.CalcFields(NMax_ulint);
        Observer.Observe('ulint.h3', Format(H.NMax_ulint));
        H.CalcFields(NMax_uldec);
        Observer.Observe('uldec.h3', Format(H.NMax_uldec));
        H.CalcFields(NMax_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NMax_ulcode));
        H.CalcFields(NMax_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NMax_ulopt));
        H.CalcFields(NMax_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NMax_ulenum));
        H.CalcFields(NMax_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NMax_ulfdate));
        H.CalcFields(NMax_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NMax_ffmismatch));
        H.CalcFields(NMax_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NMax_ffboth));
        Observer.Finish();
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
