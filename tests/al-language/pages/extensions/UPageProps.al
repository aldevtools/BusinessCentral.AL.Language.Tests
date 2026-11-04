// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in UPageObjects.al
// Probe (issue 600): states a TestPage reports for controls that a page extension adds or modifies (field, group, part, action, label),
// DecimalPlaces and AutoFormat output, DrillDown and Lookup on or off, part UpdatePropagation, an API page with a part and read only intent,
// and the Enabled property of a profile extension. Object id 69592.

codeunit 69592 "LT U Page Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LookupOpened: Integer;

    local procedure Seed()
    var
        Src: Record "LT U Page Src";
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'first';
        Src.Dec := 1234.5;
        Src.Note := 'note';
        Src.Rel := 1;
        Src.AutoPlain := 1234.5;
        Src.AutoCustom := 1234.5;
        Src.AutoCurrency := 1234.5;
        Src.Insert();
    end;

    [Test]
    procedure PageExt_FieldAndGroupStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Observer.Observe('base_group_visible_field_visible', Format(Card.InVisibleGroup.Visible()));
        Observer.ObserveError('base_group_visible_field_visible');
        Observer.Observe('base_group_editable_field_editable', Format(Card.InEditableGroup.Editable()));
        Observer.Observe('base_group_editable_field_visible', Format(Card.InEditableGroup.Visible()));
        asserterror Observer.Observe('ext_group_hidden_field_visible', Format(Card.ExtInHidden.Visible()));
        Observer.ObserveError('ext_group_hidden_field_visible');
        Observer.Observe('ext_group_readonly_field_editable', Format(Card.ExtInReadOnly.Editable()));
        Observer.Observe('ext_group_readonly_field_visible', Format(Card.ExtInReadOnly.Visible()));
        Observer.Observe('modify_field_enabled_off', Format(Card.EnabledField.Enabled()));
        Observer.Observe('modify_field_enabled_off_editable', Format(Card.EnabledField.Editable()));
        Observer.Observe('ext_field_enabled_off', Format(Card.ExtEnabledOff.Enabled()));
        Observer.Observe('ext_field_enabled_off_editable', Format(Card.ExtEnabledOff.Editable()));
        Observer.Observe('ext_field_default_enabled', Format(Card.ExtDec.Enabled()));
        Observer.Observe('label_enabled_after_modify', Format(Card.Lbl.Enabled()));
        Observer.Observe('label_visible', Format(Card.Lbl.Visible()));
        Card.Close();
        Observer.Expect('base_group_visible_field_visible|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('base_group_visible_field_visible|code', 'TestFieldNotFound');
        Observer.Expect('base_group_editable_field_editable', 'No');
        Observer.Expect('base_group_editable_field_visible', 'Yes');
        Observer.Expect('ext_group_hidden_field_visible|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('ext_group_hidden_field_visible|code', 'TestFieldNotFound');
        Observer.Expect('ext_group_readonly_field_editable', 'No');
        Observer.Expect('ext_group_readonly_field_visible', 'Yes');
        Observer.Expect('modify_field_enabled_off', 'No');
        Observer.Expect('modify_field_enabled_off_editable', 'Yes');
        Observer.Expect('ext_field_enabled_off', 'No');
        Observer.Expect('ext_field_enabled_off_editable', 'Yes');
        Observer.Expect('ext_field_default_enabled', 'Yes');
        Observer.Expect('label_enabled_after_modify', 'Yes');
        Observer.Expect('label_visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_DecimalPlacesAndAutoFormat()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('base_decimal_places_2', Card.DecField.Value);
        Observer.Observe('ext_decimal_places_3', Card.ExtDec.Value);
        Observer.Observe('table_ext_auto_plain', Card.AutoPlainField.Value);
        Observer.Observe('table_ext_auto_custom', Card.AutoCustomField.Value);
        Observer.Observe('table_ext_auto_currency', Card.AutoCurrencyField.Value);
        Observer.Observe('table_ext_auto_custom_on_ext_control', Card.ExtAutoCustom.Value);
        Observer.Observe('page_auto_on_base_control', Card.AutoOnPage.Value);
        Observer.Observe('page_auto_on_ext_control', Card.ExtAutoPage.Value);
        Card.Close();
        Observer.Expect('base_decimal_places_2', '1,234.50');
        Observer.Expect('ext_decimal_places_3', '1,234.500');
        Observer.Expect('table_ext_auto_plain', '1,234.50');
        Observer.Expect('table_ext_auto_custom', '1,234.500');
        Observer.Expect('table_ext_auto_currency', '1,234.50');
        Observer.Expect('table_ext_auto_custom_on_ext_control', '1,234.500');
        Observer.Expect('page_auto_on_base_control', '1,234.5');
        Observer.Expect('page_auto_on_ext_control', '1,234.5');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_DrillDownOnAndOff()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.DrillOn.Drilldown();
        Observer.ObserveError('base_on');
        asserterror Card.DrillOff.Drilldown();
        Observer.ObserveError('base_off');
        asserterror Card.ExtDrillOn.Drilldown();
        Observer.ObserveError('ext_on');
        asserterror Card.ExtDrillOff.Drilldown();
        Observer.ObserveError('ext_off');
        Card.Close();
        Observer.Expect('base_on|text', 'drilled on');
        Observer.Expect('base_on|code', 'TestWrapped:Dialog');
        Observer.Expect('base_off|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('base_off|code', 'MethodNotSupported');
        Observer.Expect('ext_on|text', 'ext drilled on');
        Observer.Expect('ext_on|code', 'TestWrapped:Dialog');
        Observer.Expect('ext_off|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('ext_off|code', 'MethodNotSupported');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure PageExt_LookupOnAndOff()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        LookupOpened := 0;
        Card.LookupField.Lookup();
        Observer.Observe('base_lookup_pages_opened', Format(LookupOpened));
        LookupOpened := 0;
        Card.ExtLookupOn.Lookup();
        Observer.Observe('ext_on_pages_opened', Format(LookupOpened));
        LookupOpened := 0;
        Card.ExtLookupOff.Lookup();
        Observer.Observe('ext_off|no_error', 'true');
        Observer.Observe('ext_off_pages_opened', Format(LookupOpened));
        Card.Close();
        Observer.Expect('base_lookup_pages_opened', '1');
        Observer.Expect('ext_on_pages_opened', '1');
        Observer.Expect('ext_off|no_error', 'true');
        Observer.Expect('ext_off_pages_opened', '0');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LookupHandler(var LookupList: TestPage "LT U Lookup List")
    begin
        LookupOpened += 1;
        LookupList.Cancel().Invoke();
    end;

    [Test]
    procedure PageExt_ActionStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('base_enabled_modified_off', Format(Card.ActEnabled.Enabled()));
        Observer.Observe('base_enabled_modified_off_visible', Format(Card.ActEnabled.Visible()));
        Observer.Observe('base_visible_modified_off', Format(Card.ActVisible.Visible()));
        Observer.Observe('base_visible_modified_off_enabled', Format(Card.ActVisible.Enabled()));
        Observer.Observe('base_scope_page', Format(Card.ActScope.Visible()));
        Observer.Observe('base_footer_false', Format(Card.ActFooter.Visible()));
        Observer.Observe('actionref_hidden_modified_visible', Format(Card.ActRefTarget.Visible()));
        Observer.Observe('ext_enabled_off', Format(Card.ExtActEnabledOff.Enabled()));
        Observer.Observe('ext_enabled_off_visible', Format(Card.ExtActEnabledOff.Visible()));
        Observer.Observe('ext_visible_off', Format(Card.ExtActVisibleOff.Visible()));
        Observer.Observe('ext_visible_off_enabled', Format(Card.ExtActVisibleOff.Enabled()));
        Observer.Observe('ext_scope_repeater_visible', Format(Card.ExtActScope.Visible()));
        Observer.Observe('ext_scope_repeater_enabled', Format(Card.ExtActScope.Enabled()));
        Card.ExtActScope.Invoke();
        Observer.Observe('ext_scope_repeater_invoked', 'ok');
        Card.ExtActEnabledOff.Invoke();
        Observer.Observe('ext_enabled_off_invoke', 'ok');
        Card.Close();
        Observer.Expect('base_enabled_modified_off', 'No');
        Observer.Expect('base_enabled_modified_off_visible', 'Yes');
        Observer.Expect('base_visible_modified_off', 'No');
        Observer.Expect('base_visible_modified_off_enabled', 'Yes');
        Observer.Expect('base_scope_page', 'Yes');
        Observer.Expect('base_footer_false', 'Yes');
        Observer.Expect('actionref_hidden_modified_visible', 'Yes');
        Observer.Expect('ext_enabled_off', 'No');
        Observer.Expect('ext_enabled_off_visible', 'Yes');
        Observer.Expect('ext_visible_off', 'No');
        Observer.Expect('ext_visible_off_enabled', 'Yes');
        Observer.Expect('ext_scope_repeater_visible', 'Yes');
        Observer.Expect('ext_scope_repeater_enabled', 'Yes');
        Observer.Expect('ext_scope_repeater_invoked', 'ok');
        Observer.Expect('ext_enabled_off_invoke', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_PartStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('part_host_visible', Format(Card.PartHost.Visible()));
        Observer.Observe('part_host_editable', Format(Card.PartHost.Editable()));
        Observer.Observe('part_sub_visible', Format(Card.PartSub.Visible()));
        Observer.Observe('part_sub_editable', Format(Card.PartSub.Editable()));
        Observer.Observe('ext_part_visible', Format(Card.ExtPart.Visible()));
        Observer.Observe('ext_part_editable', Format(Card.ExtPart.Editable()));
        Observer.Observe('ext_part_row_id', Card.ExtPart.Id.Value);
        Observer.Observe('ext_part_row_txt', Card.ExtPart.Txt.Value);
        Observer.Observe('ext_part_row_id_editable', Format(Card.ExtPart.Id.Editable()));
        Observer.Observe('ext_part_row_txt_editable', Format(Card.ExtPart.Txt.Editable()));
        Card.ExtPart.Filter.SetFilter(Txt, 'zzz');
        Observer.Observe('ext_part_filtered_first', Format(Card.ExtPart.First()));
        Observer.Observe('ext_part_filtered_first_txt', Card.ExtPart.Txt.Value);
        Card.Close();
        Observer.Expect('part_host_visible', 'Yes');
        Observer.Expect('part_host_editable', 'Yes');
        Observer.Expect('part_sub_visible', 'Yes');
        Observer.Expect('part_sub_editable', 'Yes');
        Observer.Expect('ext_part_visible', 'Yes');
        Observer.Expect('ext_part_editable', 'Yes');
        Observer.Expect('ext_part_row_id', '1');
        Observer.Expect('ext_part_row_txt', 'first');
        Observer.Expect('ext_part_row_id_editable', 'No');
        Observer.Expect('ext_part_row_txt_editable', 'No');
        Observer.Expect('ext_part_filtered_first', 'No');
        Observer.Expect('ext_part_filtered_first_txt', '');
        Observer.Verify();
    end;

    [Test]
    procedure Part_UpdatePropagation_BothAndSubPart()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
        Src: Record "LT U Page Src";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('host_before', Card.DrillOn.Value);
        Card.PartHost.Txt.SetValue('from both');
        Observer.Observe('host_after_part_both_edit', Card.DrillOn.Value);
        Observer.Observe('sibling_sub_part_after_both_edit', Card.PartSub.Txt.Value);
        Card.PartSub.Txt.SetValue('from subpart');
        Observer.Observe('host_after_part_subpart_edit', Card.DrillOn.Value);
        Observer.Observe('sibling_both_part_after_subpart_edit', Card.PartHost.Txt.Value);
        Card.Close();
        Src.Get(1);
        Observer.Observe('record_after_close', Src.Txt);
        Observer.Expect('host_before', 'first');
        Observer.Expect('host_after_part_both_edit', 'first');
        Observer.Expect('sibling_sub_part_after_both_edit', 'from both');
        Observer.Expect('host_after_part_subpart_edit', 'from both');
        Observer.Expect('sibling_both_part_after_subpart_edit', 'from both');
        Observer.Expect('record_after_close', 'from subpart');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_PageLevel_Editable_And_DataCaptionExpression()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT U Lookup List";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('list_caption', List.Caption());
        Observer.Observe('list_txt_editable', Format(List.Txt.Editable()));
        Observer.Observe('list_id_editable', Format(List.Id.Editable()));
        List.Close();
        Card.OpenView();
        Observer.Observe('card_caption', Card.Caption());
        Observer.Observe('card_txt_editable_in_view', Format(Card.DrillOn.Editable()));
        Card.Close();
        Observer.Expect('list_caption', 'LT U Lookup List - LT U ext caption');
        Observer.Expect('list_txt_editable', 'No');
        Observer.Expect('list_id_editable', 'No');
        Observer.Expect('card_caption', 'LT U Base Card - 1');
        Observer.Expect('card_txt_editable_in_view', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ApiPage_PartAndReadOnlyIntent()
    var
        Observer: Codeunit "Probe Observer";
        Api: TestPage "LT U Api Page";
    begin
        Seed();
        Api.OpenView();
        Observer.Observe('first', Format(Api.First()));
        Observer.Observe('txt', Api.txt.Value);
        Observer.Observe('txt_editable', Format(Api.txt.Editable()));
        Observer.Observe('lines_visible', Format(Api.lines.Visible()));
        Observer.Observe('lines_row_txt', Api.lines.Txt.Value);
        Observer.Observe('page_caption', Api.Caption());
        Api.txt.SetValue('changed');
        Observer.Observe('set_on_read_only|no_error', 'true');
        Api.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('txt', 'first');
        Observer.Expect('txt_editable', 'No');
        Observer.Expect('lines_visible', 'Yes');
        Observer.Expect('lines_row_txt', 'first');
        Observer.Expect('page_caption', 'LT U Api Page');
        Observer.Expect('set_on_read_only|no_error', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure PageIntent_ApiPageOpenEditKeepsReadOnly()
    var
        Observer: Codeunit "Probe Observer";
        Api: TestPage "LT U Api Page";
    begin
        Seed();
        Api.OpenEdit();
        Observer.Observe('open_edit|no_error', 'true');
        Observer.Expect('open_edit|no_error', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure ProfileExtension_EnabledFalse_ProfileLookup()
    var
        Observer: Codeunit "Probe Observer";
        Profile: Record "All Profile";
    begin
        Profile.SetRange("Profile ID", 'LT U PROFILE');
        Observer.Observe('count_by_id', Format(Profile.Count()));
        if Profile.FindFirst() then begin
            Observer.Observe('enabled', Format(Profile.Enabled));
            Observer.Observe('role_center_id', Format(Profile."Role Center ID"));
            Observer.Observe('caption', Profile.Description);
        end;
        Profile.Reset();
        Profile.SetRange("Role Center ID", 69590);
        Observer.Observe('count_by_role_center', Format(Profile.Count()));
        Profile.SetRange(Enabled, true);
        Observer.Observe('count_by_role_center_enabled', Format(Profile.Count()));
        Observer.Expect('count_by_id', '1');
        Observer.Expect('enabled', 'No');
        Observer.Expect('role_center_id', '69590');
        Observer.Expect('caption', '');
        Observer.Expect('count_by_role_center', '1');
        Observer.Expect('count_by_role_center_enabled', '0');
        Observer.Verify();
    end;
}
