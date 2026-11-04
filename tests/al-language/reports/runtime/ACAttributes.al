// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-attributes-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: attributes on procedures and variables in a Cloud app: Caption, None, Obsolete (Pending), Scope (Cloud), ServiceEnabled, InDataSet, SecurityFiltering on a Record variable, TestPermissions on a test procedure, ReportHandler. Settles #629 items 1, 3, 6, 7, 8, 12 (Cloud scope), 13, 14 and 17.
//   Compile errors are in the must-not-compile cases 0967 to 0980. Items that need an OnPrem app are in tests/al-language-onprem-dotnet/lt-ac.
// BC versions: 27, 28, 29
//   RequiredPending is BC 29 (runtime 18.0) and guarded; BC 27 and 28 reject it (must-not-compile case 0971).

table 77530 "LT AC Attr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 77530 "LT AC Attr Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT AC Attr Row")
        {
            trigger OnPreDataItem()
            begin
                ReportState.Note('predataitem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptionValue; OptionValue)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        ReportState: Codeunit "LT AC Report State";
        [InDataSet]
        OptionValue: Integer;

    trigger OnPreReport()
    begin
        ReportState.Note('prereport:' + Format(OptionValue));
    end;

    trigger OnPostReport()
    begin
        ReportState.Note('postreport');
    end;

    procedure SetOptionValue(NewValue: Integer)
    begin
        OptionValue := NewValue;
    end;

    procedure GetOptionValue(): Integer
    begin
        exit(OptionValue);
    end;
}

codeunit 77531 "LT AC Report State"
{
    SingleInstance = true;

    var
        Notes: Text;

    procedure Note(Value: Text)
    begin
        Notes += '[' + Value + ']';
    end;

    procedure Reset()
    begin
        Clear(Notes);
    end;

    procedure Text(): Text
    begin
        exit(Notes);
    end;
}

codeunit 77533 "LT AC Insert Helper"
{
    TableNo = "LT AC Attr Row";

    trigger OnRun()
    begin
        Rec.Insert();
    end;
}

codeunit 77532 "LT AC Attributes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [InDataSet]
        InDataSetFlag: Boolean;
        Calls: Integer;

    [Test]
    procedure AC_Attr_Procedures()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('caption', Captioned());
        Observer.Observe('none', NoneAttr());
        Observer.Observe('obsolete_pending', PendingObsolete());
        Observer.Observe('scope_cloud', ScopeCloud());
        Observer.Observe('service_enabled', ServiceEnabledProc());
        Observer.Observe('in_data_set_flag', Format(InDataSetFlag));
        Observer.Observe('calls', Format(Calls));
        Observer.Expect('caption', 'captioned_ran');
        Observer.Expect('none', 'none_ran');
        Observer.Expect('obsolete_pending', 'obsolete_ran');
        Observer.Expect('scope_cloud', 'cloud_ran');
        Observer.Expect('service_enabled', 'service_enabled_ran');
        Observer.Expect('in_data_set_flag', 'No');
        Observer.Expect('calls', '5');
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure AC_Attr_RequiredPending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('required_pending', RequiredPendingProc());
        Observer.Expect('required_pending', 'required_pending_ran');
        Observer.Verify();
    end;

    [RequiredPending('Use the new procedure', '29.0')]
    local procedure RequiredPendingProc(): Text
    begin
        exit('required_pending_ran');
    end;
#endif

    [Test]
    procedure AC_Attr_SecurityFiltering_Variable()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Validated)]
        ValidatedRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
    begin
        Observer.Observe('plain', Format(PlainRow.SecurityFiltering()));
        Observer.Observe('filtered', Format(FilteredRow.SecurityFiltering()));
        Observer.Observe('validated', Format(ValidatedRow.SecurityFiltering()));
        Observer.Observe('ignored', Format(IgnoredRow.SecurityFiltering()));
        FilteredRow.DeleteAll();
        PlainRow.Id := 1;
        PlainRow.Insert();
        Observer.Observe('filtered_count', Format(FilteredRow.Count()));
        Observer.Observe('validated_count', Format(ValidatedRow.Count()));
        Observer.Observe('ignored_count', Format(IgnoredRow.Count()));
        FilteredRow.DeleteAll();
        Observer.Expect('plain', 'Validated');
        Observer.Expect('filtered', 'Filtered');
        Observer.Expect('validated', 'Validated');
        Observer.Expect('ignored', 'Ignored');
        Observer.Expect('filtered_count', '1');
        Observer.Expect('validated_count', '1');
        Observer.Expect('ignored_count', '1');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure AC_Attr_TestPermissions_Disabled()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        if Row.Insert() then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Row.DeleteAll();
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure AC_Attr_TestPermissions_Restrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.Id := 2;
        if Codeunit.Run(Codeunit::"LT AC Insert Helper", Row) then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    [TestPermissions(TestPermissions::NonRestrictive)]
    procedure AC_Attr_TestPermissions_NonRestrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Attr Row";
    begin
        Row.Id := 3;
        if Codeunit.Run(Codeunit::"LT AC Insert Helper", Row) then
            Observer.Observe('insert', 'ok')
        else
            Observer.ObserveError('insert');
        Observer.Expect('insert', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure AC_Attr_ReportHandler_RunReport()
    var
        Observer: Codeunit "Probe Observer";
        ReportState: Codeunit "LT AC Report State";
    begin
        ReportState.Reset();
        asserterror Report.Run(Report::"LT AC Attr Report");
        Observer.ObserveError('run');
        Observer.Observe('notes', ReportState.Text());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 77530');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('notes', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionsReportHandler')]
    procedure AC_Attr_ReportHandler_Handler()
    var
        Observer: Codeunit "Probe Observer";
        ReportState: Codeunit "LT AC Report State";
    begin
        ReportState.Reset();
        Report.Run(Report::"LT AC Attr Report");
        Observer.Observe('notes', ReportState.Text());
        Observer.Observe('handler_calls', Format(Calls));
        Observer.Expect('notes', '');
        Observer.Expect('handler_calls', '6');
        Observer.Verify();
    end;

    [Test]
    procedure AC_Attr_InDataSet_ReportXml()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Xml: Text;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        if TrySaveAsXml(OutStr) then begin
            TempBlob.CreateInStream(InStr);
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                Xml += Line;
            end;
            Observer.Observe('xml_has_option_value', Format(StrPos(Xml, 'OptionValue') > 0));
            Observer.Observe('xml_has_row', Format(StrPos(Xml, 'Row') > 0));
            Observer.Observe('xml_length_over_zero', Format(StrLen(Xml) > 0));
        end else
            Observer.ObserveError('save_as_xml');
        Observer.Expect('save_as_xml|text', 'Report 77530 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('save_as_xml|code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveAsXml(var OutStr: OutStream)
    begin
        Report.SaveAs(Report::"LT AC Attr Report", '', ReportFormat::Xml, OutStr);
    end;

    [ReportHandler]
    procedure OptionsReportHandler(var AttrReport: Report "LT AC Attr Report")
    begin
        Calls += 1;
        AttrReport.SetOptionValue(42);
    end;

    [ServiceEnabled]
    [Caption('AC caption')]
    local procedure Captioned(): Text
    begin
        Calls += 1;
        exit('captioned_ran');
    end;

    [None]
    local procedure NoneAttr(): Text
    begin
        Calls += 1;
        exit('none_ran');
    end;

    [Obsolete('Pending since 1.0; use something else', '1.0')]
    local procedure PendingObsolete(): Text
    begin
        Calls += 1;
        exit('obsolete_ran');
    end;

    [Scope('Cloud')]
    local procedure ScopeCloud(): Text
    begin
        Calls += 1;
        exit('cloud_ran');
    end;

    [ServiceEnabled]
    local procedure ServiceEnabledProc(): Text
    begin
        Calls += 1;
        exit('service_enabled_ran');
    end;

    // Writer PX (probes-needed, PR 326 "Not done"): what SecurityFiltering() answers on a record declared with [SecurityFiltering(x)] after
    // Clear, ClearAll, Reset, Init, an assignment (both directions, from a record with another attribute and with none), Copy, a parameter,
    // and on a global record of a codeunit (codeunit 86176).
    // Rule seen: the declared attribute stays with the variable: Clear and ClearAll go back to the declared value (also after a SecurityFiltering(x)
    // call), Reset and Init keep it, an assignment or Copy does not carry it over, parameters (by value and var) carry the argument's value.
    [Test]
    procedure PX_Attr_SecurityFiltering_ClearAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FilteredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Ignored)]
        IgnoredRow: Record "LT AC Attr Row";
        [SecurityFiltering(SecurityFilter::Disallowed)]
        DisallowedRow: Record "LT AC Attr Row";
        PlainRow: Record "LT AC Attr Row";
    begin
        Observer.Observe('disallowed', Format(DisallowedRow.SecurityFiltering()));
        Clear(FilteredRow);
        Observer.Observe('filtered_after_clear', Format(FilteredRow.SecurityFiltering()));
        FilteredRow.Reset();
        Observer.Observe('filtered_after_reset', Format(FilteredRow.SecurityFiltering()));
        FilteredRow.Init();
        Observer.Observe('filtered_after_init', Format(FilteredRow.SecurityFiltering()));
        FilteredRow := PlainRow;
        Observer.Observe('filtered_after_plain_assigned', Format(FilteredRow.SecurityFiltering()));
        FilteredRow := IgnoredRow;
        Observer.Observe('filtered_after_ignored_assigned', Format(FilteredRow.SecurityFiltering()));
        PlainRow := IgnoredRow;
        Observer.Observe('plain_after_ignored_assigned', Format(PlainRow.SecurityFiltering()));
        Clear(PlainRow);
        PlainRow.Copy(DisallowedRow);
        Observer.Observe('plain_after_copy_disallowed', Format(PlainRow.SecurityFiltering()));
        Clear(PlainRow);
        PlainRow.SecurityFiltering(SecurityFilter::Ignored);
        Observer.Observe('plain_set_ignored', Format(PlainRow.SecurityFiltering()));
        Clear(PlainRow);
        Observer.Observe('plain_set_ignored_then_clear', Format(PlainRow.SecurityFiltering()));
        IgnoredRow.SecurityFiltering(SecurityFilter::Validated);
        Observer.Observe('ignored_set_validated', Format(IgnoredRow.SecurityFiltering()));
        Clear(IgnoredRow);
        Observer.Observe('ignored_set_validated_then_clear', Format(IgnoredRow.SecurityFiltering()));
        Observer.Observe('by_value_param_of_ignored', PxSecurityOf(IgnoredRow));
        Observer.Observe('var_param_of_ignored', PxSecurityOfVar(IgnoredRow));
        Observer.Expect('disallowed', 'Disallowed');
        Observer.Expect('filtered_after_clear', 'Filtered');
        Observer.Expect('filtered_after_reset', 'Filtered');
        Observer.Expect('filtered_after_init', 'Filtered');
        Observer.Expect('filtered_after_plain_assigned', 'Filtered');
        Observer.Expect('filtered_after_ignored_assigned', 'Filtered');
        Observer.Expect('plain_after_ignored_assigned', 'Validated');
        Observer.Expect('plain_after_copy_disallowed', 'Validated');
        Observer.Expect('plain_set_ignored', 'Ignored');
        Observer.Expect('plain_set_ignored_then_clear', 'Validated');
        Observer.Expect('ignored_set_validated', 'Validated');
        Observer.Expect('ignored_set_validated_then_clear', 'Ignored');
        Observer.Expect('by_value_param_of_ignored', 'Ignored');
        Observer.Expect('var_param_of_ignored', 'Ignored');
        Observer.Verify();
    end;

    local procedure PxSecurityOf(Row: Record "LT AC Attr Row"): Text
    begin
        exit(Format(Row.SecurityFiltering()));
    end;

    local procedure PxSecurityOfVar(var Row: Record "LT AC Attr Row"): Text
    begin
        exit(Format(Row.SecurityFiltering()));
    end;

    [Test]
    procedure PX_Attr_SecurityFiltering_Global()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PX SecFilter Holder";
    begin
        Observer.Observe('global_filtered', Holder.GlobalFiltering());
        Observer.Observe('global_plain', Holder.GlobalPlainFiltering());
        Holder.ClearGlobal();
        Observer.Observe('global_filtered_after_clear', Holder.GlobalFiltering());
        Observer.Observe('clearall', Holder.ClearAllThenRead());
        Observer.Observe('global_filtered_after_clearall', Holder.GlobalFiltering());
        Observer.Observe('global_plain_after_clearall', Holder.GlobalPlainFiltering());
        Observer.Expect('global_filtered', 'Filtered');
        Observer.Expect('global_plain', 'Validated');
        Observer.Expect('global_filtered_after_clear', 'Filtered');
        Observer.Expect('clearall', 'local=Ignored global=Filtered plain_set_ignored=Validated');
        Observer.Expect('global_filtered_after_clearall', 'Filtered');
        Observer.Expect('global_plain_after_clearall', 'Validated');
        Observer.Verify();
    end;
}

codeunit 86176 "LT PX SecFilter Holder"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GlobalRow: Record "LT AC Attr Row";
        GlobalPlain: Record "LT AC Attr Row";

    procedure GlobalFiltering(): Text
    begin
        exit(Format(GlobalRow.SecurityFiltering()));
    end;

    procedure GlobalPlainFiltering(): Text
    begin
        exit(Format(GlobalPlain.SecurityFiltering()));
    end;

    procedure ClearGlobal()
    begin
        Clear(GlobalRow);
    end;

    procedure ClearAllThenRead(): Text
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        LocalRow: Record "LT AC Attr Row";
    begin
        GlobalPlain.SecurityFiltering(SecurityFilter::Ignored);
        ClearAll();
        exit('local=' + Format(LocalRow.SecurityFiltering()) + ' global=' + Format(GlobalRow.SecurityFiltering()) + ' plain_set_ignored=' + Format(GlobalPlain.SecurityFiltering()));
    end;
}
