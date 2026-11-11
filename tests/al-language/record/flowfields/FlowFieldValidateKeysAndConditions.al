// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 76610 to 76615, 76619 and 76617, enum 76616, test codeunit 76618
// local object: the CalcFormula of each FlowField, the primary key of each source table and the OnValidate trigger that logs are what is
//   under test, so the probe needs its own tables.
// Probe (al-runner issues 7422 and 7623), two parts of the FlowField area that record/flowfields/DiFwWriteTests.al and FfmOperations.al
//   leave open.
//   Part 1, Validate on a Sum FlowField (the Service Line "Reserved Qty. (Base)" shape of codeunit "Service-Quote to Order": a negated sum
//   over a table whose primary key is "Entry No." and a Boolean, with const() conditions, validated with one argument): a negated sum
//   whose current value and new value are both not 0, the value it already has, the one-argument form after CalcFields and without it,
//   a source table whose key has two fields (Integer, Boolean), a const() condition next to field() conditions, a source table with no
//   row, and a plain sum over the two-field key. Each cell observes the value afterwards, the OnValidate log, CalcFields afterwards and the
//   rows of the source table (Entry No.|Positive|Doc|Line|Kind|Qty).
//   Part 2, a FlowField with a where() condition on a FlowField of its source table (record/flowfields/Y17SumWhereFlowField.al) whose value
//   is converted: a lookup of an Enum into an Enum field and into an Option field, a lookup of a Text longer than the FlowField, a Max of an
//   Enum into an Option field, each next to the same formula without the FlowField condition.
//   Part 3 (al-runner 7427 neighbours, record/keys-sorting/KeyLookupFlowFieldFirst.al pins Boolean, Integer, Date, Text and Decimal): the
//   row order of a key whose first field is a lookup FlowField of a Code field (values that look like numbers and that do not) and of an
//   Option field, ascending and descending, with a filter on a stored field.
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 76610 "REC FFV Entry2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Positive; Boolean) { }
        field(3; "Doc No."; Code[20]) { }
        field(4; "Line No."; Integer) { }
        field(5; Kind; Integer) { }
        field(6; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.", Positive) { Clustered = true; }
    }
}

table 76611 "REC FFV Entry1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(3; "Doc No."; Code[20]) { }
        field(4; "Line No."; Integer) { }
        field(6; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 76612 "REC FFV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Validate Log"; Text[250]) { }
        // -sum over the one-field key, conditions field() only (the pinned shape of FfmOperations.al NSumF, other values)
        field(10; "Neg One"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = - sum("REC FFV Entry1".Qty where("Doc No." = field("Doc No."), "Line No." = field("Line No.")));

            trigger OnValidate()
            begin
                "Validate Log" += 'NegOne=' + Format("Neg One") + ';';
            end;
        }
        // -sum over the two-field key with a const() condition (the Reserved Qty. (Base) shape)
        field(11; "Neg Two"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = - sum("REC FFV Entry2".Qty where("Doc No." = field("Doc No."), "Line No." = field("Line No."), Kind = const(7)));

            trigger OnValidate()
            begin
                "Validate Log" += 'NegTwo=' + Format("Neg Two") + ';';
            end;
        }
        // sum over the two-field key with a const() condition
        field(12; "Pos Two"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("REC FFV Entry2".Qty where("Doc No." = field("Doc No."), "Line No." = field("Line No."), Kind = const(7)));

            trigger OnValidate()
            begin
                "Validate Log" += 'PosTwo=' + Format("Pos Two") + ';';
            end;
        }
        // sum over the one-field key with a const() condition on a field the source row gets
        field(13; "Pos One"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("REC FFV Entry1".Qty where("Doc No." = field("Doc No."), "Line No." = field("Line No.")));

            trigger OnValidate()
            begin
                "Validate Log" += 'PosOne=' + Format("Pos One") + ';';
            end;
        }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

enum 76616 "REC FFV Kind"
{
    Extensible = false;
    value(0; Zero) { }
    value(1; Alpha) { }
    value(2; Beta) { }
    value(5; Gamma) { }
}

table 76613 "REC FFV Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Src Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 76614 "REC FFV Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Head Code"; Code[20]) { }
        field(3; Kind; Enum "REC FFV Kind") { }
        field(4; Txt; Text[50]) { }
        field(10; "Detail Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("REC FFV Detail" where("Src Code" = field("Code")));
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 76615 "REC FFV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        // with a condition on the FlowField "Detail Count" of the source table
        field(10; "Kind Cond"; Enum "REC FFV Kind")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Kind where("Head Code" = field("Code"), "Detail Count" = filter(> 0)));
        }
        field(11; "Kind Opt Cond"; Option)
        {
            OptionMembers = Zero,One,Two,Three,Four,Five;
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Kind where("Head Code" = field("Code"), "Detail Count" = filter(> 0)));
        }
        field(12; "Txt Cond"; Text[5])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Txt where("Head Code" = field("Code"), "Detail Count" = filter(> 0)));
        }
        field(13; "Max Opt Cond"; Option)
        {
            OptionMembers = Zero,One,Two,Three,Four,Five;
            FieldClass = FlowField;
            CalcFormula = max("REC FFV Src".Kind where("Head Code" = field("Code"), "Detail Count" = filter(> 0)));
        }
        // the same formulas without the FlowField condition
        field(20; "Kind Plain"; Enum "REC FFV Kind")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Kind where("Head Code" = field("Code")));
        }
        field(21; "Kind Opt Plain"; Option)
        {
            OptionMembers = Zero,One,Two,Three,Four,Five;
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Kind where("Head Code" = field("Code")));
        }
        field(22; "Txt Plain"; Text[5])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Src".Txt where("Head Code" = field("Code")));
        }
        field(23; "Max Opt Plain"; Option)
        {
            OptionMembers = Zero,One,Two,Three,Four,Five;
            FieldClass = FlowField;
            CalcFormula = max("REC FFV Src".Kind where("Head Code" = field("Code")));
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 76617 "REC FFV Key Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Code[20]) { }
        field(3; Opt; Option) { OptionMembers = " ",Low,High,Mid; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 76619 "REC FFV Key Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Type Code"; Code[10]) { }
        field(3; Grp; Integer) { }
        field(10; LkCode; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Key Setup".Val where("Code" = field("Type Code")));
        }
        field(11; LkOpt; Option)
        {
            OptionMembers = " ",Low,High,Mid;
            FieldClass = FlowField;
            CalcFormula = lookup("REC FFV Key Setup".Opt where("Code" = field("Type Code")));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 76618 "REC FFV Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Reset()
    var
        Line: Record "REC FFV Line";
        E1: Record "REC FFV Entry1";
        E2: Record "REC FFV Entry2";
    begin
        Line.DeleteAll();
        E1.DeleteAll();
        E2.DeleteAll();
        Line.Init();
        Line."Doc No." := 'D1';
        Line."Line No." := 10000;
        Line.Insert();
    end;

    local procedure AddE1(EntryNo: Integer; LineNo: Integer; Qty: Decimal)
    var
        E1: Record "REC FFV Entry1";
    begin
        E1.Init();
        E1."Entry No." := EntryNo;
        E1."Doc No." := 'D1';
        E1."Line No." := LineNo;
        E1.Qty := Qty;
        E1.Insert();
    end;

    local procedure AddE2(EntryNo: Integer; Positive: Boolean; LineNo: Integer; Kind: Integer; Qty: Decimal)
    var
        E2: Record "REC FFV Entry2";
    begin
        E2.Init();
        E2."Entry No." := EntryNo;
        E2.Positive := Positive;
        E2."Doc No." := 'D1';
        E2."Line No." := LineNo;
        E2.Kind := Kind;
        E2.Qty := Qty;
        E2.Insert();
    end;

    local procedure Rows1(): Text
    var
        E1: Record "REC FFV Entry1";
        Result: Text;
    begin
        Result := 'n=' + Format(E1.Count());
        if E1.FindSet() then
            repeat
                Result += ';' + Format(E1."Entry No.") + '|' + E1."Doc No." + '|' + Format(E1."Line No.") + '|' + Format(E1.Qty);
            until E1.Next() = 0;
        exit(Result);
    end;

    local procedure Rows2(): Text
    var
        E2: Record "REC FFV Entry2";
        Result: Text;
    begin
        Result := 'n=' + Format(E2.Count());
        if E2.FindSet() then
            repeat
                Result += ';' + Format(E2."Entry No.") + '|' + Format(E2.Positive) + '|' + E2."Doc No." + '|' + Format(E2."Line No.") + '|' + Format(E2.Kind) + '|' + Format(E2.Qty);
            until E2.Next() = 0;
        exit(Result);
    end;

    // Runs one Validate in a [TryFunction]-free way: the call is the last statement of an asserterror block that raises a marker after it,
    // so a write it made is rolled back afterwards; the observations are taken inside the block before the marker.
    local procedure ValidateCell(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; WithValue: Boolean; NewValue: Decimal; CalcFirst: Boolean; Assign: Boolean; Assigned: Decimal)
    var
        Line: Record "REC FFV Line";
        Recalc: Record "REC FFV Line";
        RecalcRef: RecordRef;
        Fld: FieldRef;
        RecRef: RecordRef;
        Seen: Text;
    begin
        Line.Get('D1', 10000);
        RecRef.GetTable(Line);
        Fld := RecRef.Field(FieldNo);
        if CalcFirst then
            Fld.CalcField();
        if Assign then
            Fld.Value := Assigned;
        Seen := 'held=' + Format(Fld.Value);
        RecRef.SetTable(Line);
        ClearLastError();
        asserterror
        begin
            case FieldNo of
                10:
                    if WithValue then Line.Validate("Neg One", NewValue) else Line.Validate("Neg One");
                11:
                    if WithValue then Line.Validate("Neg Two", NewValue) else Line.Validate("Neg Two");
                12:
                    if WithValue then Line.Validate("Pos Two", NewValue) else Line.Validate("Pos Two");
                13:
                    if WithValue then Line.Validate("Pos One", NewValue) else Line.Validate("Pos One");
            end;
            RecRef.GetTable(Line);
            Recalc.Get('D1', 10000);
            case FieldNo of
                10:
                    Recalc.CalcFields("Neg One");
                11:
                    Recalc.CalcFields("Neg Two");
                12:
                    Recalc.CalcFields("Pos Two");
                13:
                    Recalc.CalcFields("Pos One");
            end;
            Seen += ' value=' + Format(RecRef.Field(FieldNo).Value) + ' log=' + Line."Validate Log";
            RecalcRef.GetTable(Recalc);
            Seen += ' recalc=' + Format(RecalcRef.Field(FieldNo).Value) + ' rows1=' + Rows1() + ' rows2=' + Rows2();
            Error('REC_FFV_DONE %1', Seen);
        end;
        if GetLastErrorText().StartsWith('REC_FFV_DONE ') then
            Observer.Observe(Name, CopyStr(GetLastErrorText(), StrLen('REC_FFV_DONE ') + 1))
        else begin
            Observer.Observe(Name, Seen + ' error');
            Observer.Observe(Name + '|text', GetLastErrorText());
            Observer.Observe(Name + '|code', GetLastErrorCode());
        end;
        ClearLastError();
    end;

    // A negated sum over the one-field key whose current value is not 0 (rows 3 and 1 make -4): new values that are not 0, the value it
    // already has, 0, and the one-argument form with CalcFields first, with an assigned value and without either.
    [Test]
    procedure NegatedSum_OneFieldKey_CurrentAndNewNotZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        AddE1(1, 10000, 3);
        AddE1(2, 10000, 1);
        AddE1(3, 20000, 50);
        ValidateCell(Observer, 'new_5_5', 10, true, 5.5, false, false, 0);
        ValidateCell(Observer, 'new_5_5_calc', 10, true, 5.5, true, false, 0);
        ValidateCell(Observer, 'new_minus_2', 10, true, -2, true, false, 0);
        ValidateCell(Observer, 'same_minus_4', 10, true, -4, true, false, 0);
        ValidateCell(Observer, 'new_0', 10, true, 0, true, false, 0);
        ValidateCell(Observer, 'onearg_calc', 10, false, 0, true, false, 0);
        ValidateCell(Observer, 'onearg_assigned_6', 10, false, 0, false, true, 6);
        ValidateCell(Observer, 'onearg_nothing', 10, false, 0, false, false, 0);
        Observer.Finish();
    end;

    // The Reserved Qty. (Base) shape: a negated sum over a source table whose key is (Integer, Boolean), with a const() condition.
    [Test]
    procedure NegatedSum_TwoFieldKey_ConstCondition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        AddE2(1, true, 10000, 7, 3);
        AddE2(1, false, 10000, 7, -1);
        AddE2(2, true, 10000, 8, 100);
        ValidateCell(Observer, 'onearg_nothing', 11, false, 0, false, false, 0);
        ValidateCell(Observer, 'onearg_calc', 11, false, 0, true, false, 0);
        ValidateCell(Observer, 'new_5', 11, true, 5, true, false, 0);
        ValidateCell(Observer, 'new_0', 11, true, 0, true, false, 0);
        ValidateCell(Observer, 'onearg_assigned_6', 11, false, 0, false, true, 6);
        Observer.Finish();
    end;

    // The same shape with no matching source row (the current sum is 0), as in the reported conversion of a quote line (line 0 of a new order).
    [Test]
    procedure NegatedSum_TwoFieldKey_NoMatchingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        AddE2(5, true, 20000, 7, 2);
        ValidateCell(Observer, 'onearg_nothing', 11, false, 0, false, false, 0);
        ValidateCell(Observer, 'onearg_calc', 11, false, 0, true, false, 0);
        ValidateCell(Observer, 'new_0', 11, true, 0, false, false, 0);
        ValidateCell(Observer, 'new_3', 11, true, 3, false, false, 0);
        Observer.Finish();
    end;

    // A plain sum over the two-field key with a const() condition, with and without matching rows.
    [Test]
    procedure PlainSum_TwoFieldKey_ConstCondition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        AddE2(1, true, 10000, 7, 3);
        AddE2(4, false, 10000, 7, 2);
        ValidateCell(Observer, 'new_9', 12, true, 9, true, false, 0);
        ValidateCell(Observer, 'same_5', 12, true, 5, true, false, 0);
        ValidateCell(Observer, 'onearg_assigned_1', 12, false, 0, false, true, 1);
        Observer.Finish();
    end;

    // Sums whose source table has no row at all.
    [Test]
    procedure Sum_EmptySourceTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        ValidateCell(Observer, 'pos_one_new_4', 13, true, 4, false, false, 0);
        ValidateCell(Observer, 'neg_one_new_4', 10, true, 4, false, false, 0);
        ValidateCell(Observer, 'pos_two_new_4', 12, true, 4, false, false, 0);
        ValidateCell(Observer, 'neg_two_new_4', 11, true, 4, false, false, 0);
        ValidateCell(Observer, 'neg_two_onearg', 11, false, 0, false, false, 0);
        Observer.Finish();
    end;

    local procedure SeedHead(KindValue: Enum "REC FFV Kind"; TxtValue: Text[50]; WithDetail: Boolean)
    var
        Head: Record "REC FFV Head";
        Src: Record "REC FFV Src";
        Detail: Record "REC FFV Detail";
    begin
        Head.DeleteAll();
        Src.DeleteAll();
        Detail.DeleteAll();
        Head.Init();
        Head."Code" := 'H1';
        Head.Insert();
        Src.Init();
        Src."Code" := 'S1';
        Src."Head Code" := 'H1';
        Src.Kind := KindValue;
        Src.Txt := TxtValue;
        Src.Insert();
        if WithDetail then begin
            Detail.Init();
            Detail."Entry No." := 1;
            Detail."Src Code" := 'S1';
            Detail.Insert();
        end;
    end;

    local procedure CalcOne(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer)
    var
        Head: Record "REC FFV Head";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Head.Get('H1');
        RecRef.GetTable(Head);
        Fld := RecRef.Field(FieldNo);
        ClearLastError();
        asserterror
        begin
            Fld.CalcField();
            Error('REC_FFV_CALC %1 ord=%2', Format(Fld.Value), Format(Fld.Value, 0, 9));
        end;
        if GetLastErrorText().StartsWith('REC_FFV_CALC ') then
            Observer.Observe(Name, CopyStr(GetLastErrorText(), StrLen('REC_FFV_CALC ') + 1))
        else begin
            Observer.Observe(Name, 'error');
            Observer.Observe(Name + '|text', GetLastErrorText());
            Observer.Observe(Name + '|code', GetLastErrorCode());
        end;
        ClearLastError();
    end;

    local procedure CalcAll(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        CalcOne(Observer, Prefix + 'kind_cond', 10);
        CalcOne(Observer, Prefix + 'kind_plain', 20);
        CalcOne(Observer, Prefix + 'kind_opt_cond', 11);
        CalcOne(Observer, Prefix + 'kind_opt_plain', 21);
        CalcOne(Observer, Prefix + 'txt_cond', 12);
        CalcOne(Observer, Prefix + 'txt_plain', 22);
        CalcOne(Observer, Prefix + 'max_opt_cond', 13);
        CalcOne(Observer, Prefix + 'max_opt_plain', 23);
    end;

    // Conversions of a lookup and a max with a condition on a FlowField of the source table, next to the same formula without it.
    [Test]
    procedure FlowFieldCondition_ConvertedValues_Beta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedHead("REC FFV Kind"::Beta, 'abcdefghij', true);
        CalcAll(Observer, 'beta_');
        Observer.Finish();
    end;

    // The source member has ordinal 5 (Gamma), which the Option fields have as their sixth member.
    [Test]
    procedure FlowFieldCondition_ConvertedValues_Gamma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedHead("REC FFV Kind"::Gamma, 'xyz', true);
        CalcAll(Observer, 'gamma_');
        Observer.Finish();
    end;

    // The condition on the FlowField does not hold (no detail row): the FlowFields with the condition find no row.
    [Test]
    procedure FlowFieldCondition_ConditionFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedHead("REC FFV Kind"::Beta, 'abcdefghij', false);
        CalcAll(Observer, 'nodetail_');
        Observer.Finish();
    end;

    local procedure SeedKeys()
    var
        Setup: Record "REC FFV Key Setup";
        Row: Record "REC FFV Key Row";
        i: Integer;
    begin
        Setup.DeleteAll();
        Row.DeleteAll();
        // setup codes S1..S6: Val '10', '9', 'A', '100', '', 'B 1'; Opt Mid, Low, High, ' ', Low, High
        AddSetup('S1', '10', 3);
        AddSetup('S2', '9', 1);
        AddSetup('S3', 'A', 2);
        AddSetup('S4', '100', 0);
        AddSetup('S5', '', 1);
        AddSetup('S6', 'B 1', 2);
        for i := 1 to 8 do begin
            Row.Init();
            Row.Id := i;
            Row."Type Code" := 'S' + Format(((i * 5) mod 7));
            Row.Grp := i mod 3;
            Row.Insert();
        end;
    end;

    local procedure AddSetup(Code: Code[10]; Val: Code[20]; Opt: Integer)
    var
        Setup: Record "REC FFV Key Setup";
    begin
        Setup.Init();
        Setup."Code" := Code;
        Setup.Val := Val;
        Setup.Opt := Opt;
        Setup.Insert();
    end;

    local procedure KeyOrder(var Row: Record "REC FFV Key Row") Result: Text
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ' ';
            until Row.Next() = 0;
    end;

    // Row order by a key whose first field is a lookup FlowField of a Code field and of an Option field.
    [Test]
    procedure LookupFirstKey_CodeAndOption_RowOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC FFV Key Row";
    begin
        SeedKeys();
        Observer.Observe('type codes', KeyOrder(Row));
        Row.SetCurrentKey(LkCode, Grp);
        Observer.Observe('code all', KeyOrder(Row));
        Row.Ascending(false);
        Observer.Observe('code descending', KeyOrder(Row));
        Row.Ascending(true);
        Row.SetRange(Grp, 1, 2);
        Observer.Observe('code grp 1..2', KeyOrder(Row));
        Clear(Row);
        Row.SetCurrentKey(LkOpt, Grp);
        Observer.Observe('opt all', KeyOrder(Row));
        Row.Ascending(false);
        Observer.Observe('opt descending', KeyOrder(Row));
        Row.Ascending(true);
        Row.SetRange(Grp, 1, 2);
        Observer.Observe('opt grp 1..2', KeyOrder(Row));
        Observer.Finish();
    end;
}
