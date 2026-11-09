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

    [Test]
    procedure FlowFieldLookupText_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldLookupText with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Lk_const);
        Observer.Observe('H1.const', Format(H.Lk_const));
        H.CalcFields(Lk_field);
        Observer.Observe('H1.field', Format(H.Lk_field));
        H.CalcFields(Lk_filter);
        Observer.Observe('H1.filter', Format(H.Lk_filter));
        H.CalcFields(Lk_constopt);
        Observer.Observe('H1.constopt', Format(H.Lk_constopt));
        H.CalcFields(Lk_constenum);
        Observer.Observe('H1.constenum', Format(H.Lk_constenum));
        H.CalcFields(Lk_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Lk_filterenum));
        H.Get('H2');
        H.CalcFields(Lk_const);
        Observer.Observe('H2.const', Format(H.Lk_const));
        H.CalcFields(Lk_field);
        Observer.Observe('H2.field', Format(H.Lk_field));
        H.CalcFields(Lk_filter);
        Observer.Observe('H2.filter', Format(H.Lk_filter));
        H.CalcFields(Lk_constopt);
        Observer.Observe('H2.constopt', Format(H.Lk_constopt));
        H.CalcFields(Lk_constenum);
        Observer.Observe('H2.constenum', Format(H.Lk_constenum));
        H.CalcFields(Lk_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Lk_filterenum));
        H.Get('H3');
        H.CalcFields(Lk_const);
        Observer.Observe('H3.const', Format(H.Lk_const));
        H.CalcFields(Lk_field);
        Observer.Observe('H3.field', Format(H.Lk_field));
        H.CalcFields(Lk_filter);
        Observer.Observe('H3.filter', Format(H.Lk_filter));
        H.CalcFields(Lk_constopt);
        Observer.Observe('H3.constopt', Format(H.Lk_constopt));
        H.CalcFields(Lk_constenum);
        Observer.Observe('H3.constenum', Format(H.Lk_constenum));
        H.CalcFields(Lk_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Lk_filterenum));
        Observer.Finish();
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
        H.CalcFields(Lk_ffint);
        Observer.Observe('ffint.unset', Format(H.Lk_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Lk_ffint);
        Observer.Observe('ffint.set', Format(H.Lk_ffint));
        H.Reset();
        H.CalcFields(Lk_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Lk_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Lk_ffdec);
        Observer.Observe('ffdec.set', Format(H.Lk_ffdec));
        H.Reset();
        H.CalcFields(Lk_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Lk_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Lk_ffdate);
        Observer.Observe('ffdate.set', Format(H.Lk_ffdate));
        H.Reset();
        H.CalcFields(Lk_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Lk_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Lk_ffcode);
        Observer.Observe('ffcode.set', Format(H.Lk_ffcode));
        H.Reset();
        H.CalcFields(Lk_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Lk_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Lk_ffopt);
        Observer.Observe('ffopt.set', Format(H.Lk_ffopt));
        H.Reset();
        H.CalcFields(Lk_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Lk_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Lk_ffenum);
        Observer.Observe('ffenum.set', Format(H.Lk_ffenum));
        H.Reset();
        H.CalcFields(Lk_fftext);
        Observer.Observe('fftext.unset', Format(H.Lk_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Lk_fftext);
        Observer.Observe('fftext.set', Format(H.Lk_fftext));
        Observer.Finish();
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
        H.CalcFields(Lk_uldate);
        Observer.Observe('uldate.unset', Format(H.Lk_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Lk_uldate);
        Observer.Observe('uldate.set', Format(H.Lk_uldate));
        H.Reset();
        H.CalcFields(Lk_ulint);
        Observer.Observe('ulint.unset', Format(H.Lk_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Lk_ulint);
        Observer.Observe('ulint.set', Format(H.Lk_ulint));
        H.Reset();
        H.CalcFields(Lk_uldec);
        Observer.Observe('uldec.unset', Format(H.Lk_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Lk_uldec);
        Observer.Observe('uldec.set', Format(H.Lk_uldec));
        H.Reset();
        H.CalcFields(Lk_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Lk_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Lk_ulcode);
        Observer.Observe('ulcode.set', Format(H.Lk_ulcode));
        H.Reset();
        H.CalcFields(Lk_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Lk_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Lk_ulopt);
        Observer.Observe('ulopt.set', Format(H.Lk_ulopt));
        H.Reset();
        H.CalcFields(Lk_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Lk_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Lk_ulenum);
        Observer.Observe('ulenum.set', Format(H.Lk_ulenum));
        H.Reset();
        H.CalcFields(Lk_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Lk_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Lk_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Lk_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Lk_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Lk_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Lk_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Lk_ffmismatch));
        H.Reset();
        H.CalcFields(Lk_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Lk_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Lk_ffboth);
        Observer.Observe('ffboth.set', Format(H.Lk_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldLookupText_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldLookupText over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Lk_const);
        Observer.Observe('const.h3', Format(H.Lk_const));
        H.CalcFields(Lk_field);
        Observer.Observe('field.h3', Format(H.Lk_field));
        H.CalcFields(Lk_filter);
        Observer.Observe('filter.h3', Format(H.Lk_filter));
        H.CalcFields(Lk_constopt);
        Observer.Observe('constopt.h3', Format(H.Lk_constopt));
        H.CalcFields(Lk_constenum);
        Observer.Observe('constenum.h3', Format(H.Lk_constenum));
        H.CalcFields(Lk_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Lk_filterenum));
        H.CalcFields(Lk_ffint);
        Observer.Observe('ffint.h3', Format(H.Lk_ffint));
        H.CalcFields(Lk_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Lk_ffdec));
        H.CalcFields(Lk_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Lk_ffdate));
        H.CalcFields(Lk_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Lk_ffcode));
        H.CalcFields(Lk_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Lk_ffopt));
        H.CalcFields(Lk_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Lk_ffenum));
        H.CalcFields(Lk_fftext);
        Observer.Observe('fftext.h3', Format(H.Lk_fftext));
        H.CalcFields(Lk_uldate);
        Observer.Observe('uldate.h3', Format(H.Lk_uldate));
        H.CalcFields(Lk_ulint);
        Observer.Observe('ulint.h3', Format(H.Lk_ulint));
        H.CalcFields(Lk_uldec);
        Observer.Observe('uldec.h3', Format(H.Lk_uldec));
        H.CalcFields(Lk_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Lk_ulcode));
        H.CalcFields(Lk_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Lk_ulopt));
        H.CalcFields(Lk_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Lk_ulenum));
        H.CalcFields(Lk_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Lk_ulfdate));
        H.CalcFields(Lk_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Lk_ffmismatch));
        H.CalcFields(Lk_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Lk_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldLookupDecimal with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(LkDec_const);
        Observer.Observe('H1.const', Format(H.LkDec_const));
        H.CalcFields(LkDec_field);
        Observer.Observe('H1.field', Format(H.LkDec_field));
        H.CalcFields(LkDec_filter);
        Observer.Observe('H1.filter', Format(H.LkDec_filter));
        H.CalcFields(LkDec_constopt);
        Observer.Observe('H1.constopt', Format(H.LkDec_constopt));
        H.CalcFields(LkDec_constenum);
        Observer.Observe('H1.constenum', Format(H.LkDec_constenum));
        H.CalcFields(LkDec_filterenum);
        Observer.Observe('H1.filterenum', Format(H.LkDec_filterenum));
        H.Get('H2');
        H.CalcFields(LkDec_const);
        Observer.Observe('H2.const', Format(H.LkDec_const));
        H.CalcFields(LkDec_field);
        Observer.Observe('H2.field', Format(H.LkDec_field));
        H.CalcFields(LkDec_filter);
        Observer.Observe('H2.filter', Format(H.LkDec_filter));
        H.CalcFields(LkDec_constopt);
        Observer.Observe('H2.constopt', Format(H.LkDec_constopt));
        H.CalcFields(LkDec_constenum);
        Observer.Observe('H2.constenum', Format(H.LkDec_constenum));
        H.CalcFields(LkDec_filterenum);
        Observer.Observe('H2.filterenum', Format(H.LkDec_filterenum));
        H.Get('H3');
        H.CalcFields(LkDec_const);
        Observer.Observe('H3.const', Format(H.LkDec_const));
        H.CalcFields(LkDec_field);
        Observer.Observe('H3.field', Format(H.LkDec_field));
        H.CalcFields(LkDec_filter);
        Observer.Observe('H3.filter', Format(H.LkDec_filter));
        H.CalcFields(LkDec_constopt);
        Observer.Observe('H3.constopt', Format(H.LkDec_constopt));
        H.CalcFields(LkDec_constenum);
        Observer.Observe('H3.constenum', Format(H.LkDec_constenum));
        H.CalcFields(LkDec_filterenum);
        Observer.Observe('H3.filterenum', Format(H.LkDec_filterenum));
        Observer.Finish();
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
        H.CalcFields(LkDec_ffint);
        Observer.Observe('ffint.unset', Format(H.LkDec_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(LkDec_ffint);
        Observer.Observe('ffint.set', Format(H.LkDec_ffint));
        H.Reset();
        H.CalcFields(LkDec_ffdec);
        Observer.Observe('ffdec.unset', Format(H.LkDec_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(LkDec_ffdec);
        Observer.Observe('ffdec.set', Format(H.LkDec_ffdec));
        H.Reset();
        H.CalcFields(LkDec_ffdate);
        Observer.Observe('ffdate.unset', Format(H.LkDec_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(LkDec_ffdate);
        Observer.Observe('ffdate.set', Format(H.LkDec_ffdate));
        H.Reset();
        H.CalcFields(LkDec_ffcode);
        Observer.Observe('ffcode.unset', Format(H.LkDec_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(LkDec_ffcode);
        Observer.Observe('ffcode.set', Format(H.LkDec_ffcode));
        H.Reset();
        H.CalcFields(LkDec_ffopt);
        Observer.Observe('ffopt.unset', Format(H.LkDec_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(LkDec_ffopt);
        Observer.Observe('ffopt.set', Format(H.LkDec_ffopt));
        H.Reset();
        H.CalcFields(LkDec_ffenum);
        Observer.Observe('ffenum.unset', Format(H.LkDec_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(LkDec_ffenum);
        Observer.Observe('ffenum.set', Format(H.LkDec_ffenum));
        H.Reset();
        H.CalcFields(LkDec_fftext);
        Observer.Observe('fftext.unset', Format(H.LkDec_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(LkDec_fftext);
        Observer.Observe('fftext.set', Format(H.LkDec_fftext));
        Observer.Finish();
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
        H.CalcFields(LkDec_uldate);
        Observer.Observe('uldate.unset', Format(H.LkDec_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(LkDec_uldate);
        Observer.Observe('uldate.set', Format(H.LkDec_uldate));
        H.Reset();
        H.CalcFields(LkDec_ulint);
        Observer.Observe('ulint.unset', Format(H.LkDec_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(LkDec_ulint);
        Observer.Observe('ulint.set', Format(H.LkDec_ulint));
        H.Reset();
        H.CalcFields(LkDec_uldec);
        Observer.Observe('uldec.unset', Format(H.LkDec_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(LkDec_uldec);
        Observer.Observe('uldec.set', Format(H.LkDec_uldec));
        H.Reset();
        H.CalcFields(LkDec_ulcode);
        Observer.Observe('ulcode.unset', Format(H.LkDec_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(LkDec_ulcode);
        Observer.Observe('ulcode.set', Format(H.LkDec_ulcode));
        H.Reset();
        H.CalcFields(LkDec_ulopt);
        Observer.Observe('ulopt.unset', Format(H.LkDec_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(LkDec_ulopt);
        Observer.Observe('ulopt.set', Format(H.LkDec_ulopt));
        H.Reset();
        H.CalcFields(LkDec_ulenum);
        Observer.Observe('ulenum.unset', Format(H.LkDec_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(LkDec_ulenum);
        Observer.Observe('ulenum.set', Format(H.LkDec_ulenum));
        H.Reset();
        H.CalcFields(LkDec_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.LkDec_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(LkDec_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.LkDec_ulfdate));
        Observer.Finish();
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
        H.CalcFields(LkDec_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.LkDec_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(LkDec_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.LkDec_ffmismatch));
        H.Reset();
        H.CalcFields(LkDec_ffboth);
        Observer.Observe('ffboth.unset', Format(H.LkDec_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(LkDec_ffboth);
        Observer.Observe('ffboth.set', Format(H.LkDec_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldLookupDecimal_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldLookupDecimal over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(LkDec_const);
        Observer.Observe('const.h3', Format(H.LkDec_const));
        H.CalcFields(LkDec_field);
        Observer.Observe('field.h3', Format(H.LkDec_field));
        H.CalcFields(LkDec_filter);
        Observer.Observe('filter.h3', Format(H.LkDec_filter));
        H.CalcFields(LkDec_constopt);
        Observer.Observe('constopt.h3', Format(H.LkDec_constopt));
        H.CalcFields(LkDec_constenum);
        Observer.Observe('constenum.h3', Format(H.LkDec_constenum));
        H.CalcFields(LkDec_filterenum);
        Observer.Observe('filterenum.h3', Format(H.LkDec_filterenum));
        H.CalcFields(LkDec_ffint);
        Observer.Observe('ffint.h3', Format(H.LkDec_ffint));
        H.CalcFields(LkDec_ffdec);
        Observer.Observe('ffdec.h3', Format(H.LkDec_ffdec));
        H.CalcFields(LkDec_ffdate);
        Observer.Observe('ffdate.h3', Format(H.LkDec_ffdate));
        H.CalcFields(LkDec_ffcode);
        Observer.Observe('ffcode.h3', Format(H.LkDec_ffcode));
        H.CalcFields(LkDec_ffopt);
        Observer.Observe('ffopt.h3', Format(H.LkDec_ffopt));
        H.CalcFields(LkDec_ffenum);
        Observer.Observe('ffenum.h3', Format(H.LkDec_ffenum));
        H.CalcFields(LkDec_fftext);
        Observer.Observe('fftext.h3', Format(H.LkDec_fftext));
        H.CalcFields(LkDec_uldate);
        Observer.Observe('uldate.h3', Format(H.LkDec_uldate));
        H.CalcFields(LkDec_ulint);
        Observer.Observe('ulint.h3', Format(H.LkDec_ulint));
        H.CalcFields(LkDec_uldec);
        Observer.Observe('uldec.h3', Format(H.LkDec_uldec));
        H.CalcFields(LkDec_ulcode);
        Observer.Observe('ulcode.h3', Format(H.LkDec_ulcode));
        H.CalcFields(LkDec_ulopt);
        Observer.Observe('ulopt.h3', Format(H.LkDec_ulopt));
        H.CalcFields(LkDec_ulenum);
        Observer.Observe('ulenum.h3', Format(H.LkDec_ulenum));
        H.CalcFields(LkDec_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.LkDec_ulfdate));
        H.CalcFields(LkDec_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.LkDec_ffmismatch));
        H.CalcFields(LkDec_ffboth);
        Observer.Observe('ffboth.h3', Format(H.LkDec_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedLookupDecimal with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NLkDec_const);
        Observer.Observe('H1.const', Format(H.NLkDec_const));
        H.CalcFields(NLkDec_field);
        Observer.Observe('H1.field', Format(H.NLkDec_field));
        H.CalcFields(NLkDec_filter);
        Observer.Observe('H1.filter', Format(H.NLkDec_filter));
        H.CalcFields(NLkDec_constopt);
        Observer.Observe('H1.constopt', Format(H.NLkDec_constopt));
        H.CalcFields(NLkDec_constenum);
        Observer.Observe('H1.constenum', Format(H.NLkDec_constenum));
        H.CalcFields(NLkDec_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NLkDec_filterenum));
        H.Get('H2');
        H.CalcFields(NLkDec_const);
        Observer.Observe('H2.const', Format(H.NLkDec_const));
        H.CalcFields(NLkDec_field);
        Observer.Observe('H2.field', Format(H.NLkDec_field));
        H.CalcFields(NLkDec_filter);
        Observer.Observe('H2.filter', Format(H.NLkDec_filter));
        H.CalcFields(NLkDec_constopt);
        Observer.Observe('H2.constopt', Format(H.NLkDec_constopt));
        H.CalcFields(NLkDec_constenum);
        Observer.Observe('H2.constenum', Format(H.NLkDec_constenum));
        H.CalcFields(NLkDec_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NLkDec_filterenum));
        H.Get('H3');
        H.CalcFields(NLkDec_const);
        Observer.Observe('H3.const', Format(H.NLkDec_const));
        H.CalcFields(NLkDec_field);
        Observer.Observe('H3.field', Format(H.NLkDec_field));
        H.CalcFields(NLkDec_filter);
        Observer.Observe('H3.filter', Format(H.NLkDec_filter));
        H.CalcFields(NLkDec_constopt);
        Observer.Observe('H3.constopt', Format(H.NLkDec_constopt));
        H.CalcFields(NLkDec_constenum);
        Observer.Observe('H3.constenum', Format(H.NLkDec_constenum));
        H.CalcFields(NLkDec_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NLkDec_filterenum));
        Observer.Finish();
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
        H.CalcFields(NLkDec_ffint);
        Observer.Observe('ffint.unset', Format(H.NLkDec_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NLkDec_ffint);
        Observer.Observe('ffint.set', Format(H.NLkDec_ffint));
        H.Reset();
        H.CalcFields(NLkDec_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NLkDec_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NLkDec_ffdec);
        Observer.Observe('ffdec.set', Format(H.NLkDec_ffdec));
        H.Reset();
        H.CalcFields(NLkDec_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NLkDec_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NLkDec_ffdate);
        Observer.Observe('ffdate.set', Format(H.NLkDec_ffdate));
        H.Reset();
        H.CalcFields(NLkDec_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NLkDec_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NLkDec_ffcode);
        Observer.Observe('ffcode.set', Format(H.NLkDec_ffcode));
        H.Reset();
        H.CalcFields(NLkDec_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NLkDec_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NLkDec_ffopt);
        Observer.Observe('ffopt.set', Format(H.NLkDec_ffopt));
        H.Reset();
        H.CalcFields(NLkDec_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NLkDec_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NLkDec_ffenum);
        Observer.Observe('ffenum.set', Format(H.NLkDec_ffenum));
        H.Reset();
        H.CalcFields(NLkDec_fftext);
        Observer.Observe('fftext.unset', Format(H.NLkDec_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NLkDec_fftext);
        Observer.Observe('fftext.set', Format(H.NLkDec_fftext));
        Observer.Finish();
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
        H.CalcFields(NLkDec_uldate);
        Observer.Observe('uldate.unset', Format(H.NLkDec_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NLkDec_uldate);
        Observer.Observe('uldate.set', Format(H.NLkDec_uldate));
        H.Reset();
        H.CalcFields(NLkDec_ulint);
        Observer.Observe('ulint.unset', Format(H.NLkDec_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NLkDec_ulint);
        Observer.Observe('ulint.set', Format(H.NLkDec_ulint));
        H.Reset();
        H.CalcFields(NLkDec_uldec);
        Observer.Observe('uldec.unset', Format(H.NLkDec_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NLkDec_uldec);
        Observer.Observe('uldec.set', Format(H.NLkDec_uldec));
        H.Reset();
        H.CalcFields(NLkDec_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NLkDec_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NLkDec_ulcode);
        Observer.Observe('ulcode.set', Format(H.NLkDec_ulcode));
        H.Reset();
        H.CalcFields(NLkDec_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NLkDec_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NLkDec_ulopt);
        Observer.Observe('ulopt.set', Format(H.NLkDec_ulopt));
        H.Reset();
        H.CalcFields(NLkDec_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NLkDec_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NLkDec_ulenum);
        Observer.Observe('ulenum.set', Format(H.NLkDec_ulenum));
        H.Reset();
        H.CalcFields(NLkDec_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NLkDec_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NLkDec_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NLkDec_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NLkDec_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NLkDec_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NLkDec_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NLkDec_ffmismatch));
        H.Reset();
        H.CalcFields(NLkDec_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NLkDec_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NLkDec_ffboth);
        Observer.Observe('ffboth.set', Format(H.NLkDec_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedLookupDecimal_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedLookupDecimal over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM Lookup Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NLkDec_const);
        Observer.Observe('const.h3', Format(H.NLkDec_const));
        H.CalcFields(NLkDec_field);
        Observer.Observe('field.h3', Format(H.NLkDec_field));
        H.CalcFields(NLkDec_filter);
        Observer.Observe('filter.h3', Format(H.NLkDec_filter));
        H.CalcFields(NLkDec_constopt);
        Observer.Observe('constopt.h3', Format(H.NLkDec_constopt));
        H.CalcFields(NLkDec_constenum);
        Observer.Observe('constenum.h3', Format(H.NLkDec_constenum));
        H.CalcFields(NLkDec_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NLkDec_filterenum));
        H.CalcFields(NLkDec_ffint);
        Observer.Observe('ffint.h3', Format(H.NLkDec_ffint));
        H.CalcFields(NLkDec_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NLkDec_ffdec));
        H.CalcFields(NLkDec_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NLkDec_ffdate));
        H.CalcFields(NLkDec_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NLkDec_ffcode));
        H.CalcFields(NLkDec_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NLkDec_ffopt));
        H.CalcFields(NLkDec_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NLkDec_ffenum));
        H.CalcFields(NLkDec_fftext);
        Observer.Observe('fftext.h3', Format(H.NLkDec_fftext));
        H.CalcFields(NLkDec_uldate);
        Observer.Observe('uldate.h3', Format(H.NLkDec_uldate));
        H.CalcFields(NLkDec_ulint);
        Observer.Observe('ulint.h3', Format(H.NLkDec_ulint));
        H.CalcFields(NLkDec_uldec);
        Observer.Observe('uldec.h3', Format(H.NLkDec_uldec));
        H.CalcFields(NLkDec_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NLkDec_ulcode));
        H.CalcFields(NLkDec_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NLkDec_ulopt));
        H.CalcFields(NLkDec_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NLkDec_ulenum));
        H.CalcFields(NLkDec_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NLkDec_ulfdate));
        H.CalcFields(NLkDec_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NLkDec_ffmismatch));
        H.CalcFields(NLkDec_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NLkDec_ffboth));
        Observer.Finish();
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
