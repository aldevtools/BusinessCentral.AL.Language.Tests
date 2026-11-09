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

    [Test]
    procedure FlowFieldCount_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldCount with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Cnt_const);
        Observer.Observe('H1.const', Format(H.Cnt_const));
        H.CalcFields(Cnt_field);
        Observer.Observe('H1.field', Format(H.Cnt_field));
        H.CalcFields(Cnt_filter);
        Observer.Observe('H1.filter', Format(H.Cnt_filter));
        H.CalcFields(Cnt_constopt);
        Observer.Observe('H1.constopt', Format(H.Cnt_constopt));
        H.CalcFields(Cnt_constenum);
        Observer.Observe('H1.constenum', Format(H.Cnt_constenum));
        H.CalcFields(Cnt_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Cnt_filterenum));
        H.Get('H2');
        H.CalcFields(Cnt_const);
        Observer.Observe('H2.const', Format(H.Cnt_const));
        H.CalcFields(Cnt_field);
        Observer.Observe('H2.field', Format(H.Cnt_field));
        H.CalcFields(Cnt_filter);
        Observer.Observe('H2.filter', Format(H.Cnt_filter));
        H.CalcFields(Cnt_constopt);
        Observer.Observe('H2.constopt', Format(H.Cnt_constopt));
        H.CalcFields(Cnt_constenum);
        Observer.Observe('H2.constenum', Format(H.Cnt_constenum));
        H.CalcFields(Cnt_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Cnt_filterenum));
        H.Get('H3');
        H.CalcFields(Cnt_const);
        Observer.Observe('H3.const', Format(H.Cnt_const));
        H.CalcFields(Cnt_field);
        Observer.Observe('H3.field', Format(H.Cnt_field));
        H.CalcFields(Cnt_filter);
        Observer.Observe('H3.filter', Format(H.Cnt_filter));
        H.CalcFields(Cnt_constopt);
        Observer.Observe('H3.constopt', Format(H.Cnt_constopt));
        H.CalcFields(Cnt_constenum);
        Observer.Observe('H3.constenum', Format(H.Cnt_constenum));
        H.CalcFields(Cnt_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Cnt_filterenum));
        Observer.Finish();
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
        H.CalcFields(Cnt_ffint);
        Observer.Observe('ffint.unset', Format(H.Cnt_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Cnt_ffint);
        Observer.Observe('ffint.set', Format(H.Cnt_ffint));
        H.Reset();
        H.CalcFields(Cnt_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Cnt_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Cnt_ffdec);
        Observer.Observe('ffdec.set', Format(H.Cnt_ffdec));
        H.Reset();
        H.CalcFields(Cnt_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Cnt_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Cnt_ffdate);
        Observer.Observe('ffdate.set', Format(H.Cnt_ffdate));
        H.Reset();
        H.CalcFields(Cnt_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Cnt_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Cnt_ffcode);
        Observer.Observe('ffcode.set', Format(H.Cnt_ffcode));
        H.Reset();
        H.CalcFields(Cnt_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Cnt_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Cnt_ffopt);
        Observer.Observe('ffopt.set', Format(H.Cnt_ffopt));
        H.Reset();
        H.CalcFields(Cnt_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Cnt_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Cnt_ffenum);
        Observer.Observe('ffenum.set', Format(H.Cnt_ffenum));
        H.Reset();
        H.CalcFields(Cnt_fftext);
        Observer.Observe('fftext.unset', Format(H.Cnt_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Cnt_fftext);
        Observer.Observe('fftext.set', Format(H.Cnt_fftext));
        Observer.Finish();
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
        H.CalcFields(Cnt_uldate);
        Observer.Observe('uldate.unset', Format(H.Cnt_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Cnt_uldate);
        Observer.Observe('uldate.set', Format(H.Cnt_uldate));
        H.Reset();
        H.CalcFields(Cnt_ulint);
        Observer.Observe('ulint.unset', Format(H.Cnt_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Cnt_ulint);
        Observer.Observe('ulint.set', Format(H.Cnt_ulint));
        H.Reset();
        H.CalcFields(Cnt_uldec);
        Observer.Observe('uldec.unset', Format(H.Cnt_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Cnt_uldec);
        Observer.Observe('uldec.set', Format(H.Cnt_uldec));
        H.Reset();
        H.CalcFields(Cnt_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Cnt_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Cnt_ulcode);
        Observer.Observe('ulcode.set', Format(H.Cnt_ulcode));
        H.Reset();
        H.CalcFields(Cnt_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Cnt_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Cnt_ulopt);
        Observer.Observe('ulopt.set', Format(H.Cnt_ulopt));
        H.Reset();
        H.CalcFields(Cnt_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Cnt_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Cnt_ulenum);
        Observer.Observe('ulenum.set', Format(H.Cnt_ulenum));
        H.Reset();
        H.CalcFields(Cnt_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Cnt_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Cnt_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Cnt_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Cnt_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Cnt_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Cnt_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Cnt_ffmismatch));
        H.Reset();
        H.CalcFields(Cnt_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Cnt_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Cnt_ffboth);
        Observer.Observe('ffboth.set', Format(H.Cnt_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldCount_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldCount over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Cnt_const);
        Observer.Observe('const.h3', Format(H.Cnt_const));
        H.CalcFields(Cnt_field);
        Observer.Observe('field.h3', Format(H.Cnt_field));
        H.CalcFields(Cnt_filter);
        Observer.Observe('filter.h3', Format(H.Cnt_filter));
        H.CalcFields(Cnt_constopt);
        Observer.Observe('constopt.h3', Format(H.Cnt_constopt));
        H.CalcFields(Cnt_constenum);
        Observer.Observe('constenum.h3', Format(H.Cnt_constenum));
        H.CalcFields(Cnt_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Cnt_filterenum));
        H.CalcFields(Cnt_ffint);
        Observer.Observe('ffint.h3', Format(H.Cnt_ffint));
        H.CalcFields(Cnt_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Cnt_ffdec));
        H.CalcFields(Cnt_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Cnt_ffdate));
        H.CalcFields(Cnt_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Cnt_ffcode));
        H.CalcFields(Cnt_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Cnt_ffopt));
        H.CalcFields(Cnt_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Cnt_ffenum));
        H.CalcFields(Cnt_fftext);
        Observer.Observe('fftext.h3', Format(H.Cnt_fftext));
        H.CalcFields(Cnt_uldate);
        Observer.Observe('uldate.h3', Format(H.Cnt_uldate));
        H.CalcFields(Cnt_ulint);
        Observer.Observe('ulint.h3', Format(H.Cnt_ulint));
        H.CalcFields(Cnt_uldec);
        Observer.Observe('uldec.h3', Format(H.Cnt_uldec));
        H.CalcFields(Cnt_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Cnt_ulcode));
        H.CalcFields(Cnt_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Cnt_ulopt));
        H.CalcFields(Cnt_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Cnt_ulenum));
        H.CalcFields(Cnt_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Cnt_ulfdate));
        H.CalcFields(Cnt_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Cnt_ffmismatch));
        H.CalcFields(Cnt_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Cnt_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedCount_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedCount with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NCnt_const);
        Observer.Observe('H1.const', Format(H.NCnt_const));
        H.CalcFields(NCnt_field);
        Observer.Observe('H1.field', Format(H.NCnt_field));
        H.CalcFields(NCnt_filter);
        Observer.Observe('H1.filter', Format(H.NCnt_filter));
        H.CalcFields(NCnt_constopt);
        Observer.Observe('H1.constopt', Format(H.NCnt_constopt));
        H.CalcFields(NCnt_constenum);
        Observer.Observe('H1.constenum', Format(H.NCnt_constenum));
        H.CalcFields(NCnt_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NCnt_filterenum));
        H.Get('H2');
        H.CalcFields(NCnt_const);
        Observer.Observe('H2.const', Format(H.NCnt_const));
        H.CalcFields(NCnt_field);
        Observer.Observe('H2.field', Format(H.NCnt_field));
        H.CalcFields(NCnt_filter);
        Observer.Observe('H2.filter', Format(H.NCnt_filter));
        H.CalcFields(NCnt_constopt);
        Observer.Observe('H2.constopt', Format(H.NCnt_constopt));
        H.CalcFields(NCnt_constenum);
        Observer.Observe('H2.constenum', Format(H.NCnt_constenum));
        H.CalcFields(NCnt_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NCnt_filterenum));
        H.Get('H3');
        H.CalcFields(NCnt_const);
        Observer.Observe('H3.const', Format(H.NCnt_const));
        H.CalcFields(NCnt_field);
        Observer.Observe('H3.field', Format(H.NCnt_field));
        H.CalcFields(NCnt_filter);
        Observer.Observe('H3.filter', Format(H.NCnt_filter));
        H.CalcFields(NCnt_constopt);
        Observer.Observe('H3.constopt', Format(H.NCnt_constopt));
        H.CalcFields(NCnt_constenum);
        Observer.Observe('H3.constenum', Format(H.NCnt_constenum));
        H.CalcFields(NCnt_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NCnt_filterenum));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedCount_WhereFieldFilter_UnsetAndSet()
    // CLAIM: FlowFieldNegatedCount with a field(filter(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        H.CalcFields(NCnt_ffint);
        Observer.Observe('ffint.unset', Format(H.NCnt_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NCnt_ffint);
        Observer.Observe('ffint.set', Format(H.NCnt_ffint));
        H.Reset();
        H.CalcFields(NCnt_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NCnt_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NCnt_ffdec);
        Observer.Observe('ffdec.set', Format(H.NCnt_ffdec));
        H.Reset();
        H.CalcFields(NCnt_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NCnt_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NCnt_ffdate);
        Observer.Observe('ffdate.set', Format(H.NCnt_ffdate));
        H.Reset();
        H.CalcFields(NCnt_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NCnt_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NCnt_ffcode);
        Observer.Observe('ffcode.set', Format(H.NCnt_ffcode));
        H.Reset();
        H.CalcFields(NCnt_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NCnt_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NCnt_ffopt);
        Observer.Observe('ffopt.set', Format(H.NCnt_ffopt));
        H.Reset();
        H.CalcFields(NCnt_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NCnt_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NCnt_ffenum);
        Observer.Observe('ffenum.set', Format(H.NCnt_ffenum));
        H.Reset();
        H.CalcFields(NCnt_fftext);
        Observer.Observe('fftext.unset', Format(H.NCnt_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NCnt_fftext);
        Observer.Observe('fftext.set', Format(H.NCnt_fftext));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedCount_WhereUpperLimit_UnsetAndSet()
    // CLAIM: FlowFieldNegatedCount with a field(upperlimit(F)) condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        H.CalcFields(NCnt_uldate);
        Observer.Observe('uldate.unset', Format(H.NCnt_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NCnt_uldate);
        Observer.Observe('uldate.set', Format(H.NCnt_uldate));
        H.Reset();
        H.CalcFields(NCnt_ulint);
        Observer.Observe('ulint.unset', Format(H.NCnt_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NCnt_ulint);
        Observer.Observe('ulint.set', Format(H.NCnt_ulint));
        H.Reset();
        H.CalcFields(NCnt_uldec);
        Observer.Observe('uldec.unset', Format(H.NCnt_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NCnt_uldec);
        Observer.Observe('uldec.set', Format(H.NCnt_uldec));
        H.Reset();
        H.CalcFields(NCnt_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NCnt_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NCnt_ulcode);
        Observer.Observe('ulcode.set', Format(H.NCnt_ulcode));
        H.Reset();
        H.CalcFields(NCnt_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NCnt_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NCnt_ulopt);
        Observer.Observe('ulopt.set', Format(H.NCnt_ulopt));
        H.Reset();
        H.CalcFields(NCnt_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NCnt_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NCnt_ulenum);
        Observer.Observe('ulenum.set', Format(H.NCnt_ulenum));
        H.Reset();
        H.CalcFields(NCnt_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NCnt_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NCnt_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NCnt_ulfdate));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedCount_WhereMixed_UnsetAndSet()
    // CLAIM: FlowFieldNegatedCount with a a FlowFilter of another type, and field plus FlowFilter condition: the value with the FlowFilter not set and set.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.Reset();
        H.CalcFields(NCnt_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NCnt_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NCnt_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NCnt_ffmismatch));
        H.Reset();
        H.CalcFields(NCnt_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NCnt_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NCnt_ffboth);
        Observer.Observe('ffboth.set', Format(H.NCnt_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedCount_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedCount over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NCnt_const);
        Observer.Observe('const.h3', Format(H.NCnt_const));
        H.CalcFields(NCnt_field);
        Observer.Observe('field.h3', Format(H.NCnt_field));
        H.CalcFields(NCnt_filter);
        Observer.Observe('filter.h3', Format(H.NCnt_filter));
        H.CalcFields(NCnt_constopt);
        Observer.Observe('constopt.h3', Format(H.NCnt_constopt));
        H.CalcFields(NCnt_constenum);
        Observer.Observe('constenum.h3', Format(H.NCnt_constenum));
        H.CalcFields(NCnt_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NCnt_filterenum));
        H.CalcFields(NCnt_ffint);
        Observer.Observe('ffint.h3', Format(H.NCnt_ffint));
        H.CalcFields(NCnt_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NCnt_ffdec));
        H.CalcFields(NCnt_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NCnt_ffdate));
        H.CalcFields(NCnt_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NCnt_ffcode));
        H.CalcFields(NCnt_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NCnt_ffopt));
        H.CalcFields(NCnt_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NCnt_ffenum));
        H.CalcFields(NCnt_fftext);
        Observer.Observe('fftext.h3', Format(H.NCnt_fftext));
        H.CalcFields(NCnt_uldate);
        Observer.Observe('uldate.h3', Format(H.NCnt_uldate));
        H.CalcFields(NCnt_ulint);
        Observer.Observe('ulint.h3', Format(H.NCnt_ulint));
        H.CalcFields(NCnt_uldec);
        Observer.Observe('uldec.h3', Format(H.NCnt_uldec));
        H.CalcFields(NCnt_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NCnt_ulcode));
        H.CalcFields(NCnt_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NCnt_ulopt));
        H.CalcFields(NCnt_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NCnt_ulenum));
        H.CalcFields(NCnt_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NCnt_ulfdate));
        H.CalcFields(NCnt_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NCnt_ffmismatch));
        H.CalcFields(NCnt_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NCnt_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldExist_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldExist with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(Ex_const);
        Observer.Observe('H1.const', Format(H.Ex_const));
        H.CalcFields(Ex_field);
        Observer.Observe('H1.field', Format(H.Ex_field));
        H.CalcFields(Ex_filter);
        Observer.Observe('H1.filter', Format(H.Ex_filter));
        H.CalcFields(Ex_constopt);
        Observer.Observe('H1.constopt', Format(H.Ex_constopt));
        H.CalcFields(Ex_constenum);
        Observer.Observe('H1.constenum', Format(H.Ex_constenum));
        H.CalcFields(Ex_filterenum);
        Observer.Observe('H1.filterenum', Format(H.Ex_filterenum));
        H.Get('H2');
        H.CalcFields(Ex_const);
        Observer.Observe('H2.const', Format(H.Ex_const));
        H.CalcFields(Ex_field);
        Observer.Observe('H2.field', Format(H.Ex_field));
        H.CalcFields(Ex_filter);
        Observer.Observe('H2.filter', Format(H.Ex_filter));
        H.CalcFields(Ex_constopt);
        Observer.Observe('H2.constopt', Format(H.Ex_constopt));
        H.CalcFields(Ex_constenum);
        Observer.Observe('H2.constenum', Format(H.Ex_constenum));
        H.CalcFields(Ex_filterenum);
        Observer.Observe('H2.filterenum', Format(H.Ex_filterenum));
        H.Get('H3');
        H.CalcFields(Ex_const);
        Observer.Observe('H3.const', Format(H.Ex_const));
        H.CalcFields(Ex_field);
        Observer.Observe('H3.field', Format(H.Ex_field));
        H.CalcFields(Ex_filter);
        Observer.Observe('H3.filter', Format(H.Ex_filter));
        H.CalcFields(Ex_constopt);
        Observer.Observe('H3.constopt', Format(H.Ex_constopt));
        H.CalcFields(Ex_constenum);
        Observer.Observe('H3.constenum', Format(H.Ex_constenum));
        H.CalcFields(Ex_filterenum);
        Observer.Observe('H3.filterenum', Format(H.Ex_filterenum));
        Observer.Finish();
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
        H.CalcFields(Ex_ffint);
        Observer.Observe('ffint.unset', Format(H.Ex_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Ex_ffint);
        Observer.Observe('ffint.set', Format(H.Ex_ffint));
        H.Reset();
        H.CalcFields(Ex_ffdec);
        Observer.Observe('ffdec.unset', Format(H.Ex_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Ex_ffdec);
        Observer.Observe('ffdec.set', Format(H.Ex_ffdec));
        H.Reset();
        H.CalcFields(Ex_ffdate);
        Observer.Observe('ffdate.unset', Format(H.Ex_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Ex_ffdate);
        Observer.Observe('ffdate.set', Format(H.Ex_ffdate));
        H.Reset();
        H.CalcFields(Ex_ffcode);
        Observer.Observe('ffcode.unset', Format(H.Ex_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Ex_ffcode);
        Observer.Observe('ffcode.set', Format(H.Ex_ffcode));
        H.Reset();
        H.CalcFields(Ex_ffopt);
        Observer.Observe('ffopt.unset', Format(H.Ex_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Ex_ffopt);
        Observer.Observe('ffopt.set', Format(H.Ex_ffopt));
        H.Reset();
        H.CalcFields(Ex_ffenum);
        Observer.Observe('ffenum.unset', Format(H.Ex_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Ex_ffenum);
        Observer.Observe('ffenum.set', Format(H.Ex_ffenum));
        H.Reset();
        H.CalcFields(Ex_fftext);
        Observer.Observe('fftext.unset', Format(H.Ex_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(Ex_fftext);
        Observer.Observe('fftext.set', Format(H.Ex_fftext));
        Observer.Finish();
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
        H.CalcFields(Ex_uldate);
        Observer.Observe('uldate.unset', Format(H.Ex_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Ex_uldate);
        Observer.Observe('uldate.set', Format(H.Ex_uldate));
        H.Reset();
        H.CalcFields(Ex_ulint);
        Observer.Observe('ulint.unset', Format(H.Ex_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Ex_ulint);
        Observer.Observe('ulint.set', Format(H.Ex_ulint));
        H.Reset();
        H.CalcFields(Ex_uldec);
        Observer.Observe('uldec.unset', Format(H.Ex_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(Ex_uldec);
        Observer.Observe('uldec.set', Format(H.Ex_uldec));
        H.Reset();
        H.CalcFields(Ex_ulcode);
        Observer.Observe('ulcode.unset', Format(H.Ex_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(Ex_ulcode);
        Observer.Observe('ulcode.set', Format(H.Ex_ulcode));
        H.Reset();
        H.CalcFields(Ex_ulopt);
        Observer.Observe('ulopt.unset', Format(H.Ex_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(Ex_ulopt);
        Observer.Observe('ulopt.set', Format(H.Ex_ulopt));
        H.Reset();
        H.CalcFields(Ex_ulenum);
        Observer.Observe('ulenum.unset', Format(H.Ex_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(Ex_ulenum);
        Observer.Observe('ulenum.set', Format(H.Ex_ulenum));
        H.Reset();
        H.CalcFields(Ex_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.Ex_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Ex_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.Ex_ulfdate));
        Observer.Finish();
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
        H.CalcFields(Ex_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.Ex_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(Ex_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.Ex_ffmismatch));
        H.Reset();
        H.CalcFields(Ex_ffboth);
        Observer.Observe('ffboth.unset', Format(H.Ex_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(Ex_ffboth);
        Observer.Observe('ffboth.set', Format(H.Ex_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldExist_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldExist over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(Ex_const);
        Observer.Observe('const.h3', Format(H.Ex_const));
        H.CalcFields(Ex_field);
        Observer.Observe('field.h3', Format(H.Ex_field));
        H.CalcFields(Ex_filter);
        Observer.Observe('filter.h3', Format(H.Ex_filter));
        H.CalcFields(Ex_constopt);
        Observer.Observe('constopt.h3', Format(H.Ex_constopt));
        H.CalcFields(Ex_constenum);
        Observer.Observe('constenum.h3', Format(H.Ex_constenum));
        H.CalcFields(Ex_filterenum);
        Observer.Observe('filterenum.h3', Format(H.Ex_filterenum));
        H.CalcFields(Ex_ffint);
        Observer.Observe('ffint.h3', Format(H.Ex_ffint));
        H.CalcFields(Ex_ffdec);
        Observer.Observe('ffdec.h3', Format(H.Ex_ffdec));
        H.CalcFields(Ex_ffdate);
        Observer.Observe('ffdate.h3', Format(H.Ex_ffdate));
        H.CalcFields(Ex_ffcode);
        Observer.Observe('ffcode.h3', Format(H.Ex_ffcode));
        H.CalcFields(Ex_ffopt);
        Observer.Observe('ffopt.h3', Format(H.Ex_ffopt));
        H.CalcFields(Ex_ffenum);
        Observer.Observe('ffenum.h3', Format(H.Ex_ffenum));
        H.CalcFields(Ex_fftext);
        Observer.Observe('fftext.h3', Format(H.Ex_fftext));
        H.CalcFields(Ex_uldate);
        Observer.Observe('uldate.h3', Format(H.Ex_uldate));
        H.CalcFields(Ex_ulint);
        Observer.Observe('ulint.h3', Format(H.Ex_ulint));
        H.CalcFields(Ex_uldec);
        Observer.Observe('uldec.h3', Format(H.Ex_uldec));
        H.CalcFields(Ex_ulcode);
        Observer.Observe('ulcode.h3', Format(H.Ex_ulcode));
        H.CalcFields(Ex_ulopt);
        Observer.Observe('ulopt.h3', Format(H.Ex_ulopt));
        H.CalcFields(Ex_ulenum);
        Observer.Observe('ulenum.h3', Format(H.Ex_ulenum));
        H.CalcFields(Ex_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.Ex_ulfdate));
        H.CalcFields(Ex_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.Ex_ffmismatch));
        H.CalcFields(Ex_ffboth);
        Observer.Observe('ffboth.h3', Format(H.Ex_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedExist_WhereConstFieldFilter_Values()
    // CLAIM: FlowFieldNegatedExist with const, field and filter conditions, on a header with rows, one with others rows and one without rows.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H1');
        H.CalcFields(NEx_const);
        Observer.Observe('H1.const', Format(H.NEx_const));
        H.CalcFields(NEx_field);
        Observer.Observe('H1.field', Format(H.NEx_field));
        H.CalcFields(NEx_filter);
        Observer.Observe('H1.filter', Format(H.NEx_filter));
        H.CalcFields(NEx_constopt);
        Observer.Observe('H1.constopt', Format(H.NEx_constopt));
        H.CalcFields(NEx_constenum);
        Observer.Observe('H1.constenum', Format(H.NEx_constenum));
        H.CalcFields(NEx_filterenum);
        Observer.Observe('H1.filterenum', Format(H.NEx_filterenum));
        H.Get('H2');
        H.CalcFields(NEx_const);
        Observer.Observe('H2.const', Format(H.NEx_const));
        H.CalcFields(NEx_field);
        Observer.Observe('H2.field', Format(H.NEx_field));
        H.CalcFields(NEx_filter);
        Observer.Observe('H2.filter', Format(H.NEx_filter));
        H.CalcFields(NEx_constopt);
        Observer.Observe('H2.constopt', Format(H.NEx_constopt));
        H.CalcFields(NEx_constenum);
        Observer.Observe('H2.constenum', Format(H.NEx_constenum));
        H.CalcFields(NEx_filterenum);
        Observer.Observe('H2.filterenum', Format(H.NEx_filterenum));
        H.Get('H3');
        H.CalcFields(NEx_const);
        Observer.Observe('H3.const', Format(H.NEx_const));
        H.CalcFields(NEx_field);
        Observer.Observe('H3.field', Format(H.NEx_field));
        H.CalcFields(NEx_filter);
        Observer.Observe('H3.filter', Format(H.NEx_filter));
        H.CalcFields(NEx_constopt);
        Observer.Observe('H3.constopt', Format(H.NEx_constopt));
        H.CalcFields(NEx_constenum);
        Observer.Observe('H3.constenum', Format(H.NEx_constenum));
        H.CalcFields(NEx_filterenum);
        Observer.Observe('H3.filterenum', Format(H.NEx_filterenum));
        Observer.Finish();
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
        H.CalcFields(NEx_ffint);
        Observer.Observe('ffint.unset', Format(H.NEx_ffint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NEx_ffint);
        Observer.Observe('ffint.set', Format(H.NEx_ffint));
        H.Reset();
        H.CalcFields(NEx_ffdec);
        Observer.Observe('ffdec.unset', Format(H.NEx_ffdec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NEx_ffdec);
        Observer.Observe('ffdec.set', Format(H.NEx_ffdec));
        H.Reset();
        H.CalcFields(NEx_ffdate);
        Observer.Observe('ffdate.unset', Format(H.NEx_ffdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NEx_ffdate);
        Observer.Observe('ffdate.set', Format(H.NEx_ffdate));
        H.Reset();
        H.CalcFields(NEx_ffcode);
        Observer.Observe('ffcode.unset', Format(H.NEx_ffcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NEx_ffcode);
        Observer.Observe('ffcode.set', Format(H.NEx_ffcode));
        H.Reset();
        H.CalcFields(NEx_ffopt);
        Observer.Observe('ffopt.unset', Format(H.NEx_ffopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NEx_ffopt);
        Observer.Observe('ffopt.set', Format(H.NEx_ffopt));
        H.Reset();
        H.CalcFields(NEx_ffenum);
        Observer.Observe('ffenum.unset', Format(H.NEx_ffenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NEx_ffenum);
        Observer.Observe('ffenum.set', Format(H.NEx_ffenum));
        H.Reset();
        H.CalcFields(NEx_fftext);
        Observer.Observe('fftext.unset', Format(H.NEx_fftext));
        H.SetFilter(TextF, 'alpha|charlie');
        H.CalcFields(NEx_fftext);
        Observer.Observe('fftext.set', Format(H.NEx_fftext));
        Observer.Finish();
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
        H.CalcFields(NEx_uldate);
        Observer.Observe('uldate.unset', Format(H.NEx_uldate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NEx_uldate);
        Observer.Observe('uldate.set', Format(H.NEx_uldate));
        H.Reset();
        H.CalcFields(NEx_ulint);
        Observer.Observe('ulint.unset', Format(H.NEx_ulint));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NEx_ulint);
        Observer.Observe('ulint.set', Format(H.NEx_ulint));
        H.Reset();
        H.CalcFields(NEx_uldec);
        Observer.Observe('uldec.unset', Format(H.NEx_uldec));
        H.SetFilter(DecF, '>=14');
        H.CalcFields(NEx_uldec);
        Observer.Observe('uldec.set', Format(H.NEx_uldec));
        H.Reset();
        H.CalcFields(NEx_ulcode);
        Observer.Observe('ulcode.unset', Format(H.NEx_ulcode));
        H.SetFilter(CodeF, 'K1');
        H.CalcFields(NEx_ulcode);
        Observer.Observe('ulcode.set', Format(H.NEx_ulcode));
        H.Reset();
        H.CalcFields(NEx_ulopt);
        Observer.Observe('ulopt.unset', Format(H.NEx_ulopt));
        H.SetRange(OptF, H.OptF::B);
        H.CalcFields(NEx_ulopt);
        Observer.Observe('ulopt.set', Format(H.NEx_ulopt));
        H.Reset();
        H.CalcFields(NEx_ulenum);
        Observer.Observe('ulenum.unset', Format(H.NEx_ulenum));
        H.SetFilter(EnumF, '%1|%2', H.EnumF::Closed, H.EnumF::Held);
        H.CalcFields(NEx_ulenum);
        Observer.Observe('ulenum.set', Format(H.NEx_ulenum));
        H.Reset();
        H.CalcFields(NEx_ulfdate);
        Observer.Observe('ulfdate.unset', Format(H.NEx_ulfdate));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NEx_ulfdate);
        Observer.Observe('ulfdate.set', Format(H.NEx_ulfdate));
        Observer.Finish();
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
        H.CalcFields(NEx_ffmismatch);
        Observer.Observe('ffmismatch.unset', Format(H.NEx_ffmismatch));
        H.SetRange(DateF, 20260201D, 20260430D);
        H.CalcFields(NEx_ffmismatch);
        Observer.Observe('ffmismatch.set', Format(H.NEx_ffmismatch));
        H.Reset();
        H.CalcFields(NEx_ffboth);
        Observer.Observe('ffboth.unset', Format(H.NEx_ffboth));
        H.SetFilter(IntF, '3..5');
        H.CalcFields(NEx_ffboth);
        Observer.Observe('ffboth.set', Format(H.NEx_ffboth));
        Observer.Finish();
    end;

    [Test]
    procedure FlowFieldNegatedExist_NoMatchingRows_EmptyResult()
    // CLAIM: FlowFieldNegatedExist over a header with no rows of its own: what every form gives when nothing matches.
    var
        H: Record "FFM CountExist Header";
    begin
        Initialize();
        H.Get('H3');
        H.CalcFields(NEx_const);
        Observer.Observe('const.h3', Format(H.NEx_const));
        H.CalcFields(NEx_field);
        Observer.Observe('field.h3', Format(H.NEx_field));
        H.CalcFields(NEx_filter);
        Observer.Observe('filter.h3', Format(H.NEx_filter));
        H.CalcFields(NEx_constopt);
        Observer.Observe('constopt.h3', Format(H.NEx_constopt));
        H.CalcFields(NEx_constenum);
        Observer.Observe('constenum.h3', Format(H.NEx_constenum));
        H.CalcFields(NEx_filterenum);
        Observer.Observe('filterenum.h3', Format(H.NEx_filterenum));
        H.CalcFields(NEx_ffint);
        Observer.Observe('ffint.h3', Format(H.NEx_ffint));
        H.CalcFields(NEx_ffdec);
        Observer.Observe('ffdec.h3', Format(H.NEx_ffdec));
        H.CalcFields(NEx_ffdate);
        Observer.Observe('ffdate.h3', Format(H.NEx_ffdate));
        H.CalcFields(NEx_ffcode);
        Observer.Observe('ffcode.h3', Format(H.NEx_ffcode));
        H.CalcFields(NEx_ffopt);
        Observer.Observe('ffopt.h3', Format(H.NEx_ffopt));
        H.CalcFields(NEx_ffenum);
        Observer.Observe('ffenum.h3', Format(H.NEx_ffenum));
        H.CalcFields(NEx_fftext);
        Observer.Observe('fftext.h3', Format(H.NEx_fftext));
        H.CalcFields(NEx_uldate);
        Observer.Observe('uldate.h3', Format(H.NEx_uldate));
        H.CalcFields(NEx_ulint);
        Observer.Observe('ulint.h3', Format(H.NEx_ulint));
        H.CalcFields(NEx_uldec);
        Observer.Observe('uldec.h3', Format(H.NEx_uldec));
        H.CalcFields(NEx_ulcode);
        Observer.Observe('ulcode.h3', Format(H.NEx_ulcode));
        H.CalcFields(NEx_ulopt);
        Observer.Observe('ulopt.h3', Format(H.NEx_ulopt));
        H.CalcFields(NEx_ulenum);
        Observer.Observe('ulenum.h3', Format(H.NEx_ulenum));
        H.CalcFields(NEx_ulfdate);
        Observer.Observe('ulfdate.h3', Format(H.NEx_ulfdate));
        H.CalcFields(NEx_ffmismatch);
        Observer.Observe('ffmismatch.h3', Format(H.NEx_ffmismatch));
        H.CalcFields(NEx_ffboth);
        Observer.Observe('ffboth.h3', Format(H.NEx_ffboth));
        Observer.Finish();
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
