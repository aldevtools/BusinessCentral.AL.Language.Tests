// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-securityfiltering-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 77530 "LT AC Attr Row" (ACAttributes.al)
// Probe: what Record.SecurityFiltering() reads on a record variable declared with [SecurityFiltering(x)], and what Clear and ClearAll
//   restore, in the cases ACAttributes.al (codeunit 77532) does not pin: TransferFields, RecordRef GetTable/SetTable, Clear in a callee
//   on a by-value and a var parameter, Codeunit.Run with a declared record, a temporary parameter, a Variant, ClearAll after a
//   SecurityFiltering(x) call on a codeunit global and on a test codeunit global, the attribute on a global of a table, a page and a report,
//   and on an array of records.
// BC versions: 27, 28, 29

// local object: its own definition is under test (the attribute on a global of a table)
table 77534 "LT SF Global Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GlobalRow: Record "LT AC Attr Row";

    procedure GlobalFiltering(): Text
    begin
        exit(Format(GlobalRow.SecurityFiltering()));
    end;

    procedure SetIgnoredThenClearAll(): Text
    var
        BeforeClearAll: Text;
    begin
        GlobalRow.SecurityFiltering(SecurityFilter::Ignored);
        BeforeClearAll := Format(GlobalRow.SecurityFiltering());
        ClearAll();
        exit(BeforeClearAll + '>' + Format(GlobalRow.SecurityFiltering()));
    end;
}

// local object: its own definition is under test (the attribute on a global of a page)
page 77534 "LT SF Global Page"
{
    PageType = Card;
    SourceTable = "LT AC Attr Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GlobalRow: Record "LT AC Attr Row";

    procedure GlobalFiltering(): Text
    begin
        exit(Format(GlobalRow.SecurityFiltering()));
    end;

    procedure SetIgnoredThenClearAll(): Text
    var
        BeforeClearAll: Text;
    begin
        GlobalRow.SecurityFiltering(SecurityFilter::Ignored);
        BeforeClearAll := Format(GlobalRow.SecurityFiltering());
        ClearAll();
        exit(BeforeClearAll + '>' + Format(GlobalRow.SecurityFiltering()));
    end;
}

// local object: its own definition is under test (the attribute on a global of a report)
report 77534 "LT SF Global Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT AC Attr Row")
        {
        }
    }

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GlobalRow: Record "LT AC Attr Row";

    procedure GlobalFiltering(): Text
    begin
        exit(Format(GlobalRow.SecurityFiltering()));
    end;

    procedure SetIgnoredThenClearAll(): Text
    var
        BeforeClearAll: Text;
    begin
        GlobalRow.SecurityFiltering(SecurityFilter::Ignored);
        BeforeClearAll := Format(GlobalRow.SecurityFiltering());
        ClearAll();
        exit(BeforeClearAll + '>' + Format(GlobalRow.SecurityFiltering()));
    end;
}

// local object: its own definition is under test (OnRun of a codeunit with TableNo reads the Rec it was run with)
// Rec.Id = 1: Clear(Rec) first. Writes what Rec.SecurityFiltering() reads into Rec.Name, which goes back to the caller's record.
codeunit 77535 "LT SF Run Reader"
{
    TableNo = "LT AC Attr Row";

    trigger OnRun()
    begin
        if Rec.Id = 1 then
            Clear(Rec);
        Rec.Name := CopyStr(Format(Rec.SecurityFiltering()), 1, MaxStrLen(Rec.Name));
    end;
}

// local object: its own definition is under test (the attribute on a codeunit global, with ClearAll after a SecurityFiltering(x) call)
codeunit 77536 "LT SF Holder"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GlobalRow: Record "LT AC Attr Row";

    procedure GlobalFiltering(): Text
    begin
        exit(Format(GlobalRow.SecurityFiltering()));
    end;

    procedure SetGlobal(NewFilter: SecurityFilter)
    begin
        GlobalRow.SecurityFiltering(NewFilter);
    end;

    procedure ClearAllNow()
    begin
        ClearAll();
    end;
}

codeunit 77537 "LT SF Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        TestGlobalRow: Record "LT AC Attr Row";

    [Test]
    procedure SF_TransferFields()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
        PlainSetRow: Record "LT AC Attr Row";
    begin
        FilteredRow.TransferFields(PlainRow);
        Observer.Observe('filtered_from_plain', Format(FilteredRow.SecurityFiltering()));
        FilteredRow.TransferFields(IgnoredRow);
        Observer.Observe('filtered_from_ignored', Format(FilteredRow.SecurityFiltering()));
        PlainRow.TransferFields(IgnoredRow);
        Observer.Observe('plain_from_ignored', Format(PlainRow.SecurityFiltering()));
        PlainSetRow.SecurityFiltering(SecurityFilter::Disallowed);
        FilteredRow.TransferFields(PlainSetRow);
        Observer.Observe('filtered_from_plain_set_disallowed', Format(FilteredRow.SecurityFiltering()));
        FilteredRow.SecurityFiltering(SecurityFilter::Ignored);
        FilteredRow.TransferFields(PlainRow);
        Observer.Observe('filtered_set_ignored_from_plain', Format(FilteredRow.SecurityFiltering()));
        Clear(FilteredRow);
        Observer.Observe('filtered_set_ignored_from_plain_then_clear', Format(FilteredRow.SecurityFiltering()));
        PlainRow.SecurityFiltering(SecurityFilter::Ignored);
        PlainRow.TransferFields(FilteredRow, false);
        Observer.Observe('plain_set_ignored_from_filtered_no_init', Format(PlainRow.SecurityFiltering()));
        Observer.Expect('filtered_from_plain', 'Filtered');
        Observer.Expect('filtered_from_ignored', 'Filtered');
        Observer.Expect('plain_from_ignored', 'Validated');
        Observer.Expect('filtered_from_plain_set_disallowed', 'Filtered');
        Observer.Expect('filtered_set_ignored_from_plain', 'Ignored');
        Observer.Expect('filtered_set_ignored_from_plain_then_clear', 'Filtered');
        Observer.Expect('plain_set_ignored_from_filtered_no_init', 'Ignored');
        Observer.Verify();
    end;

    [Test]
    procedure SF_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
    begin
        RecRef.Open(Database::"LT AC Attr Row");
        Observer.Observe('recref_open', Format(RecRef.SecurityFiltering()));
        RecRef.Close();
        RecRef.GetTable(FilteredRow);
        Observer.Observe('recref_gettable_filtered', Format(RecRef.SecurityFiltering()));
        RecRef.GetTable(IgnoredRow);
        Observer.Observe('recref_gettable_ignored', Format(RecRef.SecurityFiltering()));
        RecRef.GetTable(PlainRow);
        Observer.Observe('recref_gettable_plain', Format(RecRef.SecurityFiltering()));
        PlainRow.SecurityFiltering(SecurityFilter::Disallowed);
        RecRef.GetTable(PlainRow);
        Observer.Observe('recref_gettable_plain_set_disallowed', Format(RecRef.SecurityFiltering()));
        Clear(PlainRow);
        RecRef.GetTable(IgnoredRow);
        RecRef.SetTable(FilteredRow);
        Observer.Observe('filtered_after_settable_from_ignored', Format(FilteredRow.SecurityFiltering()));
        RecRef.SetTable(PlainRow);
        Observer.Observe('plain_after_settable_from_ignored', Format(PlainRow.SecurityFiltering()));
        Clear(PlainRow);
        RecRef.GetTable(PlainRow);
        RecRef.SecurityFiltering(SecurityFilter::Disallowed);
        RecRef.SetTable(PlainRow);
        Observer.Observe('plain_after_settable_from_recref_set_disallowed', Format(PlainRow.SecurityFiltering()));
        RecRef.GetTable(FilteredRow);
        RecRef.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('filtered_after_its_recref_set_ignored', Format(FilteredRow.SecurityFiltering()));
        RecRef.SetTable(FilteredRow);
        Observer.Observe('filtered_after_settable_from_recref_set_ignored', Format(FilteredRow.SecurityFiltering()));
        Clear(FilteredRow);
        Observer.Observe('filtered_after_settable_then_clear', Format(FilteredRow.SecurityFiltering()));
        Clear(RecRef);
        RecRef.Open(Database::"LT AC Attr Row");
        Observer.Observe('recref_reopen_after_clear', Format(RecRef.SecurityFiltering()));
        Observer.Expect('recref_open', 'Validated');
        Observer.Expect('recref_gettable_filtered', 'Validated');
        Observer.Expect('recref_gettable_ignored', 'Validated');
        Observer.Expect('recref_gettable_plain', 'Validated');
        Observer.Expect('recref_gettable_plain_set_disallowed', 'Validated');
        Observer.Expect('filtered_after_settable_from_ignored', 'Filtered');
        Observer.Expect('plain_after_settable_from_ignored', 'Validated');
        Observer.Expect('plain_after_settable_from_recref_set_disallowed', 'Validated');
        Observer.Expect('filtered_after_its_recref_set_ignored', 'Filtered');
        Observer.Expect('filtered_after_settable_from_recref_set_ignored', 'Filtered');
        Observer.Expect('filtered_after_settable_then_clear', 'Filtered');
        Observer.Expect('recref_reopen_after_clear', 'Validated');
        Observer.Verify();
    end;

    [Test]
    procedure SF_ParameterClear()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
    begin
        Observer.Observe('byvalue_clear_of_filtered', ClearByValue(FilteredRow));
        Observer.Observe('filtered_after_callee_byvalue_clear', Format(FilteredRow.SecurityFiltering()));
        Observer.Observe('var_clear_of_filtered', ClearVar(FilteredRow));
        Observer.Observe('filtered_after_callee_var_clear', Format(FilteredRow.SecurityFiltering()));
        PlainRow.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('byvalue_clear_of_plain_set_ignored', ClearByValue(PlainRow));
        Observer.Observe('var_clear_of_plain_set_ignored', ClearVar(PlainRow));
        FilteredRow.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('byvalue_of_filtered_set_ignored', ReadByValue(FilteredRow));
        Observer.Observe('var_of_filtered_set_ignored', ReadVar(FilteredRow));
        Observer.Observe('byvalue_clear_of_filtered_set_ignored', ClearByValue(FilteredRow));
        Observer.Observe('filtered_set_ignored_after_callee_byvalue_clear', Format(FilteredRow.SecurityFiltering()));
        Observer.Observe('var_clear_of_filtered_set_ignored', ClearVar(FilteredRow));
        Observer.Observe('filtered_set_ignored_after_callee_var_clear', Format(FilteredRow.SecurityFiltering()));
        Observer.Observe('nested_byvalue_clear_of_filtered', NestedClearByValue(FilteredRow));
        Observer.Expect('byvalue_clear_of_filtered', 'Filtered');
        Observer.Expect('filtered_after_callee_byvalue_clear', 'Filtered');
        Observer.Expect('var_clear_of_filtered', 'Filtered');
        Observer.Expect('filtered_after_callee_var_clear', 'Filtered');
        Observer.Expect('byvalue_clear_of_plain_set_ignored', 'Validated');
        Observer.Expect('var_clear_of_plain_set_ignored', 'Validated');
        Observer.Expect('byvalue_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('var_of_filtered_set_ignored', 'Ignored');
        Observer.Expect('byvalue_clear_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('filtered_set_ignored_after_callee_byvalue_clear', 'Ignored');
        Observer.Expect('var_clear_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('filtered_set_ignored_after_callee_var_clear', 'Filtered');
        Observer.Expect('nested_byvalue_clear_of_filtered', 'Filtered');
        Observer.Verify();
    end;

    [Test]
    procedure SF_CodeunitRunTemporaryVariant()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
        V: Variant;
        Result: Text;
    begin
        Codeunit.Run(Codeunit::"LT SF Run Reader", FilteredRow);
        Observer.Observe('onrun_rec_of_filtered', FilteredRow.Name);
        Observer.Observe('filtered_after_run', Format(FilteredRow.SecurityFiltering()));
        Codeunit.Run(Codeunit::"LT SF Run Reader", PlainRow);
        Observer.Observe('onrun_rec_of_plain', PlainRow.Name);
        Clear(PlainRow);
        FilteredRow.SecurityFiltering(SecurityFilter::Ignored);
        Codeunit.Run(Codeunit::"LT SF Run Reader", FilteredRow);
        Observer.Observe('onrun_rec_of_filtered_set_ignored', FilteredRow.Name);
        FilteredRow.Id := 1;
        Codeunit.Run(Codeunit::"LT SF Run Reader", FilteredRow);
        Observer.Observe('onrun_clear_rec_of_filtered_set_ignored', FilteredRow.Name);
        Observer.Observe('filtered_set_ignored_after_onrun_clear', Format(FilteredRow.SecurityFiltering()));
        Clear(FilteredRow);

        if TryReadTemporary(FilteredRow, Result) then
            Observer.Observe('temporary_param_of_filtered', Result)
        else
            Observer.ObserveError('temporary_param_of_filtered');
        FilteredRow.SecurityFiltering(SecurityFilter::Ignored);
        if TryReadTemporary(FilteredRow, Result) then
            Observer.Observe('temporary_param_of_filtered_set_ignored', Result)
        else
            Observer.ObserveError('temporary_param_of_filtered_set_ignored');
        if TryClearTemporary(FilteredRow, Result) then
            Observer.Observe('temporary_param_clear_of_filtered_set_ignored', Result)
        else
            Observer.ObserveError('temporary_param_clear_of_filtered_set_ignored');

        V := FilteredRow;
        PlainRow := V;
        Observer.Observe('plain_from_variant_of_filtered_set_ignored', Format(PlainRow.SecurityFiltering()));
        Clear(FilteredRow);
        V := IgnoredRow;
        FilteredRow := V;
        Observer.Observe('filtered_from_variant_of_ignored', Format(FilteredRow.SecurityFiltering()));
        V := FilteredRow;
        IgnoredRow := V;
        Observer.Observe('ignored_from_variant_of_filtered', Format(IgnoredRow.SecurityFiltering()));
        Clear(PlainRow);
        V := IgnoredRow;
        PlainRow := V;
        Observer.Observe('plain_from_variant_of_ignored', Format(PlainRow.SecurityFiltering()));
        Observer.Expect('onrun_rec_of_filtered', 'Filtered');
        Observer.Expect('filtered_after_run', 'Filtered');
        Observer.Expect('onrun_rec_of_plain', 'Validated');
        Observer.Expect('onrun_rec_of_filtered_set_ignored', 'Ignored');
        Observer.Expect('onrun_clear_rec_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('filtered_set_ignored_after_onrun_clear', 'Filtered');
        Observer.Expect('temporary_param_of_filtered', 'Filtered');
        Observer.Expect('temporary_param_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('temporary_param_clear_of_filtered_set_ignored', 'Filtered');
        Observer.Expect('plain_from_variant_of_filtered_set_ignored', 'Validated');
        Observer.Expect('filtered_from_variant_of_ignored', 'Filtered');
        Observer.Expect('ignored_from_variant_of_filtered', 'Ignored');
        Observer.Expect('plain_from_variant_of_ignored', 'Validated');
        Observer.Verify();
    end;

    [Test]
    procedure SF_ClearAllAfterSet()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT SF Holder";
    begin
        Holder.SetGlobal(SecurityFilter::Ignored);
        Observer.Observe('holder_global_set_ignored', Holder.GlobalFiltering());
        Holder.ClearAllNow();
        Observer.Observe('holder_global_set_ignored_then_clearall', Holder.GlobalFiltering());
        Holder.SetGlobal(SecurityFilter::Disallowed);
        Clear(Holder);
        Observer.Observe('holder_global_set_disallowed_then_clear_codeunit_var', Holder.GlobalFiltering());
        TestGlobalRow.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('test_global_set_ignored', Format(TestGlobalRow.SecurityFiltering()));
        ClearAll();
        Observer.Observe('test_global_set_ignored_then_clearall', Format(TestGlobalRow.SecurityFiltering()));
        Observer.Expect('holder_global_set_ignored', 'Ignored');
        Observer.Expect('holder_global_set_ignored_then_clearall', 'Filtered');
        Observer.Expect('holder_global_set_disallowed_then_clear_codeunit_var', 'Filtered');
        Observer.Expect('test_global_set_ignored', 'Ignored');
        Observer.Expect('test_global_set_ignored_then_clearall', 'Filtered');
        Observer.Verify();
    end;

    [Test]
    procedure SF_ObjectGlobals()
    var
        Observer: Codeunit "Probe Observer";
        TableRow: Record "LT SF Global Table";
        GlobalPage: Page "LT SF Global Page";
        GlobalReport: Report "LT SF Global Report";
    begin
        Observer.Observe('table_global', TableRow.GlobalFiltering());
        Observer.Observe('table_global_set_ignored_then_clearall', TableRow.SetIgnoredThenClearAll());
        Observer.Observe('page_global', GlobalPage.GlobalFiltering());
        Observer.Observe('page_global_set_ignored_then_clearall', GlobalPage.SetIgnoredThenClearAll());
        Observer.Observe('report_global', GlobalReport.GlobalFiltering());
        Observer.Observe('report_global_set_ignored_then_clearall', GlobalReport.SetIgnoredThenClearAll());
        Observer.Expect('table_global', 'Filtered');
        Observer.Expect('table_global_set_ignored_then_clearall', 'Ignored>Filtered');
        Observer.Expect('page_global', 'Filtered');
        Observer.Expect('page_global_set_ignored_then_clearall', 'Ignored>Filtered');
        Observer.Expect('report_global', 'Filtered');
        Observer.Expect('report_global_set_ignored_then_clearall', 'Ignored>Filtered');
        Observer.Verify();
    end;

    [Test]
    procedure SF_ArrayAndTemporaryVariable()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Rows: array[2] of Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TempRow: Record "LT AC Attr Row" temporary;
    begin
        Observer.Observe('array_1', Format(Rows[1].SecurityFiltering()));
        Observer.Observe('array_2', Format(Rows[2].SecurityFiltering()));
        Rows[1].SecurityFiltering(SecurityFilter::Ignored);
        Rows[2].SecurityFiltering(SecurityFilter::Ignored);
        Clear(Rows[1]);
        Observer.Observe('array_1_set_ignored_then_clear_element', Format(Rows[1].SecurityFiltering()));
        Observer.Observe('array_2_set_ignored', Format(Rows[2].SecurityFiltering()));
        Clear(Rows);
        Observer.Observe('array_2_set_ignored_then_clear_array', Format(Rows[2].SecurityFiltering()));
        Observer.Observe('temporary_variable', Format(TempRow.SecurityFiltering()));
        TempRow.SecurityFiltering(SecurityFilter::Ignored);
        Clear(TempRow);
        Observer.Observe('temporary_variable_set_ignored_then_clear', Format(TempRow.SecurityFiltering()));
        Observer.Expect('array_1', 'Filtered');
        Observer.Expect('array_2', 'Filtered');
        Observer.Expect('array_1_set_ignored_then_clear_element', 'Filtered');
        Observer.Expect('array_2_set_ignored', 'Ignored');
        Observer.Expect('array_2_set_ignored_then_clear_array', 'Filtered');
        Observer.Expect('temporary_variable', 'Filtered');
        Observer.Expect('temporary_variable_set_ignored_then_clear', 'Filtered');
        Observer.Verify();
    end;

    local procedure ReadByValue(Row: Record "LT AC Attr Row"): Text
    begin
        exit(Format(Row.SecurityFiltering()));
    end;

    local procedure ReadVar(var Row: Record "LT AC Attr Row"): Text
    begin
        exit(Format(Row.SecurityFiltering()));
    end;

    local procedure ClearByValue(Row: Record "LT AC Attr Row"): Text
    begin
        Clear(Row);
        exit(Format(Row.SecurityFiltering()));
    end;

    local procedure ClearVar(var Row: Record "LT AC Attr Row"): Text
    begin
        Clear(Row);
        exit(Format(Row.SecurityFiltering()));
    end;

    local procedure NestedClearByValue(Row: Record "LT AC Attr Row"): Text
    begin
        exit(ClearByValue(Row));
    end;

    [TryFunction]
    local procedure TryReadTemporary(Row: Record "LT AC Attr Row" temporary; var Result: Text)
    begin
        Result := Format(Row.SecurityFiltering());
    end;

    [TryFunction]
    local procedure TryClearTemporary(Row: Record "LT AC Attr Row" temporary; var Result: Text)
    begin
        Clear(Row);
        Result := Format(Row.SecurityFiltering());
    end;
}
