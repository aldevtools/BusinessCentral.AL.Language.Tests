// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (np3) FlowField filter(= 0D) and filter(=0D) in count and exist, a FlowField over a FlowField of the counted table with that filter (count and lookup), a FlowFilter Date set to 0D (SetRange, SetFilter with =%1 and <>%1) with GetFilter, GetFilters and CalcFields. 0D (the AL date literal, the empty date) inside the filter(...) of a CalcFormula on an own table: exist and count with filter(<> 0D), filter(0D), filter(<>0D); rows with an empty date only, then a dated row (assumption calcformula-filter-date-literal).
// BC versions: 29 (27 and 28 by CI)

table 70383 "LT CFDate Row"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Owner No."; Code[10]) { }
        field(3; "Posting Date"; Date) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 70384 "LT CFDate Owner"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Has Dated"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<> 0D)));
        }
        field(3; "Dated Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<> 0D)));
        }
        field(4; "Empty Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(0D)));
        }
        field(5; "Dated Count Nospace"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<>0D)));
        }
        field(6; "Eq Empty Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(= 0D)));
        }
        field(7; "Eq Empty Nospace"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(=0D)));
        }
        field(8; "Eq Empty Exist"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(= 0D)));
        }
        field(9; "Group No."; Code[10]) { }
        field(10; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(11; "Filtered Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = field("Date Filter")));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 90540 "LT CFDate Group"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Owners With Empty"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Owner" where("Group No." = field("No."), "Eq Empty Exist" = filter(true)));
        }
        field(3; "Owners Without Empty"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Owner" where("Group No." = field("No."), "Eq Empty Count" = filter(0)));
        }
        field(4; "Owner Names With Empty"; Code[10])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT CFDate Owner"."No." where("Group No." = field("No."), "Eq Empty Count" = filter(> 0)));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70385 "LT CFDate Literal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT CFDate Row";
        Owner: Record "LT CFDate Owner";
    begin
        Row.DeleteAll();
        Owner.DeleteAll();
        Owner."No." := 'O1';
        Owner.Insert();
    end;

    local procedure AddRow(No: Integer; D: Date)
    var
        Row: Record "LT CFDate Row";
    begin
        Row."Entry No." := No;
        Row."Owner No." := 'O1';
        Row."Posting Date" := D;
        Row.Insert();
    end;

    local procedure ObserveFlow(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Owner: Record "LT CFDate Owner";
    begin
        Owner.Get('O1');
        Owner.CalcFields("Has Dated", "Dated Count", "Empty Count", "Dated Count Nospace");
        Observer.Observe(Prefix + '_has_dated', Format(Owner."Has Dated"));
        Observer.Observe(Prefix + '_dated_count', Format(Owner."Dated Count"));
        Observer.Observe(Prefix + '_empty_count', Format(Owner."Empty Count"));
        Observer.Observe(Prefix + '_dated_count_nospace', Format(Owner."Dated Count Nospace"));
    end;

    [Test]
    procedure NotEmptyDate_OnlyEmptyRows_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveFlow(Observer, 'no_rows');
        AddRow(1, 0D);
        AddRow(2, 0D);
        ObserveFlow(Observer, 'two_empty');
        Observer.Expect('no_rows_has_dated', 'No');
        Observer.Expect('no_rows_dated_count', '0');
        Observer.Expect('no_rows_empty_count', '0');
        Observer.Expect('no_rows_dated_count_nospace', '0');
        Observer.Expect('two_empty_has_dated', 'No');
        Observer.Expect('two_empty_dated_count', '0');
        Observer.Expect('two_empty_empty_count', '2');
        Observer.Expect('two_empty_dated_count_nospace', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NotEmptyDate_TodayRow_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        AddRow(1, 0D);
        AddRow(2, Today());
        ObserveFlow(Observer, 'today_row');
        Observer.Expect('today_row_has_dated', 'Yes');
        Observer.Expect('today_row_dated_count', '1');
        Observer.Expect('today_row_empty_count', '1');
        Observer.Expect('today_row_dated_count_nospace', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NotEmptyDate_OnlyTodayRow_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        AddRow(1, Today());
        ObserveFlow(Observer, 'only_today');
        Observer.Expect('only_today_has_dated', 'Yes');
        Observer.Expect('only_today_dated_count', '1');
        Observer.Expect('only_today_empty_count', '0');
        Observer.Expect('only_today_dated_count_nospace', '1');
        Observer.Verify();
    end;

    local procedure ObserveEq(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Owner: Record "LT CFDate Owner";
    begin
        Owner.Get('O1');
        Owner.CalcFields("Eq Empty Count", "Eq Empty Nospace", "Eq Empty Exist");
        Observer.Observe(Prefix + '_eq_empty_count', Format(Owner."Eq Empty Count"));
        Observer.Observe(Prefix + '_eq_empty_nospace', Format(Owner."Eq Empty Nospace"));
        Observer.Observe(Prefix + '_eq_empty_exist', Format(Owner."Eq Empty Exist"));
    end;

    [Test]
    procedure EqualsEmptyDate_Rows_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveEq(Observer, 'no_rows');
        AddRow(1, 0D);
        AddRow(2, 0D);
        ObserveEq(Observer, 'two_empty');
        AddRow(3, DMY2Date(5, 3, 2024));
        ObserveEq(Observer, 'with_dated');
        Observer.Expect('no_rows_eq_empty_count', '0');
        Observer.Expect('no_rows_eq_empty_nospace', '0');
        Observer.Expect('no_rows_eq_empty_exist', 'No');
        Observer.Expect('two_empty_eq_empty_count', '2');
        Observer.Expect('two_empty_eq_empty_nospace', '2');
        Observer.Expect('two_empty_eq_empty_exist', 'Yes');
        Observer.Expect('with_dated_eq_empty_count', '2');
        Observer.Expect('with_dated_eq_empty_nospace', '2');
        Observer.Expect('with_dated_eq_empty_exist', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EqualsEmptyDate_OnlyDatedRows_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        AddRow(1, DMY2Date(5, 3, 2024));
        ObserveEq(Observer, 'only_dated');
        Observer.Expect('only_dated_eq_empty_count', '0');
        Observer.Expect('only_dated_eq_empty_nospace', '0');
        Observer.Expect('only_dated_eq_empty_exist', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure EqualsEmptyDate_Chained_GroupOverFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Group: Record "LT CFDate Group";
        Owner: Record "LT CFDate Owner";
    begin
        Seed();
        Group.DeleteAll();
        Group."No." := 'G1';
        Group.Insert();
        Owner.Get('O1');
        Owner."Group No." := 'G1';
        Owner.Modify();
        Group.CalcFields("Owners With Empty", "Owners Without Empty", "Owner Names With Empty");
        Observer.Observe('no_rows_with_empty', Format(Group."Owners With Empty"));
        Observer.Observe('no_rows_without_empty', Format(Group."Owners Without Empty"));
        Observer.Observe('no_rows_names', Group."Owner Names With Empty");
        AddRow(1, 0D);
        Group.CalcFields("Owners With Empty", "Owners Without Empty", "Owner Names With Empty");
        Observer.Observe('empty_row_with_empty', Format(Group."Owners With Empty"));
        Observer.Observe('empty_row_without_empty', Format(Group."Owners Without Empty"));
        Observer.Observe('empty_row_names', Group."Owner Names With Empty");
        AddRow(2, DMY2Date(5, 3, 2024));
        Group.CalcFields("Owners With Empty", "Owners Without Empty", "Owner Names With Empty");
        Observer.Observe('both_rows_with_empty', Format(Group."Owners With Empty"));
        Observer.Observe('both_rows_without_empty', Format(Group."Owners Without Empty"));
        Observer.Observe('both_rows_names', Group."Owner Names With Empty");
        Observer.Expect('no_rows_with_empty', '0');
        Observer.Expect('no_rows_without_empty', '1');
        Observer.Expect('no_rows_names', '');
        Observer.Expect('empty_row_with_empty', '1');
        Observer.Expect('empty_row_without_empty', '0');
        Observer.Expect('empty_row_names', 'O1');
        Observer.Expect('both_rows_with_empty', '1');
        Observer.Expect('both_rows_without_empty', '0');
        Observer.Expect('both_rows_names', 'O1');
        Observer.Verify();
    end;

    [Test]
    procedure EqualsEmptyDate_FlowFilter_TextAndResult()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT CFDate Owner";
    begin
        Seed();
        AddRow(1, 0D);
        AddRow(2, 0D);
        AddRow(3, DMY2Date(5, 3, 2024));
        Owner.Get('O1');
        Owner.SetRange("Date Filter", 0D);
        Observer.Observe('range_0D_filter', Owner.GetFilter("Date Filter"));
        Observer.Observe('range_0D_filters', Owner.GetFilters());
        Owner.CalcFields("Filtered Count");
        Observer.Observe('range_0D_count', Format(Owner."Filtered Count"));
        Owner.SetFilter("Date Filter", '=%1', 0D);
        Observer.Observe('eq_0D_filter', Owner.GetFilter("Date Filter"));
        Owner.CalcFields("Filtered Count");
        Observer.Observe('eq_0D_count', Format(Owner."Filtered Count"));
        Owner.SetFilter("Date Filter", '<>%1', 0D);
        Observer.Observe('ne_0D_filter', Owner.GetFilter("Date Filter"));
        Owner.CalcFields("Filtered Count");
        Observer.Observe('ne_0D_count', Format(Owner."Filtered Count"));
        Observer.Expect('range_0D_filter', '''''');
        Observer.Expect('range_0D_filters', 'Date Filter: ''''');
        Observer.Expect('range_0D_count', '2');
        Observer.Expect('eq_0D_filter', '''''');
        Observer.Expect('eq_0D_count', '2');
        Observer.Expect('ne_0D_filter', '<>''''');
        Observer.Expect('ne_0D_count', '1');
        Observer.Verify();
    end;
}
