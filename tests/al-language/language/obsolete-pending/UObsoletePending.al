// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects of UObsoleteObjects.al
// Probe (issue 602): Pending objects and controls still compile and run. The warning a Pending object gives is not visible to AL code or to the must-not-compile harness (it records errors only). Object id 69799.

codeunit 69799 "LT U Obsolete Pending Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Pending_CodeunitInterfaceEnum_StillRun()
    var
        Observer: Codeunit "Probe Observer";
        Obsolete: Codeunit "LT U Obsolete CU";
        Intf: Interface "LT U Obsolete Interface";
        ScopeIntf: Interface "LT U Scope Interface";
        Value: Enum "LT U Obsolete Enum";
        Ordinals: List of [Integer];
        Index: Integer;
        Names: Text;
    begin
        Observer.Observe('codeunit_answer', Format(Obsolete.Answer()));
        Intf := Obsolete;
        Observer.Observe('interface_answer', Format(Intf.Answer()));
        ScopeIntf := Obsolete;
        Observer.Observe('scope_cloud_interface_ping', Format(ScopeIntf.Ping()));
        Value := Value::Old;
        Observer.Observe('enum_value_old', Format(Value));
        Observer.Observe('enum_value_old_ordinal', Format(Value.AsInteger()));
        Value := Value::ExtOld;
        Observer.Observe('enum_ext_value_old', Format(Value));
        Observer.Observe('enum_ext_value_old_ordinal', Format(Value.AsInteger()));
        Ordinals := Value.Ordinals();
        foreach Index in Ordinals do
            Names += Value.Names().Get(Ordinals.IndexOf(Index)) + ',';
        Observer.Observe('enum_names', Names);
        Observer.Expect('codeunit_answer', '42');
        Observer.Expect('interface_answer', '42');
        Observer.Expect('scope_cloud_interface_ping', '7');
        Observer.Expect('enum_value_old', 'Old');
        Observer.Expect('enum_value_old_ordinal', '1');
        Observer.Expect('enum_ext_value_old', 'ExtOld');
        Observer.Expect('enum_ext_value_old_ordinal', '69793');
        Observer.Expect('enum_names', 'Current,Old,ExtOld,ExtCurrent,');
        Observer.Verify();
    end;

    [Test]
    procedure Pending_PageAndControls_StillOpen()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT U Page Src";
        Card: TestPage "LT U Obsolete Page";
        Value: Text;
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'one';
        Src.Insert();
        Card.OpenView();
        asserterror begin Value := Card.InObsGroup.Value; Error('NOERROR'); end;
        Observer.Observe('group_field', Outcome(Value));
        asserterror begin Value := Format(Card.InObsGroup.Visible()); Error('NOERROR'); end;
        Observer.Observe('group_field_visible', Outcome(Value));
        asserterror begin Value := Card.InObsCue.Value; Error('NOERROR'); end;
        Observer.Observe('cue_field', Outcome(Value));
        asserterror begin Value := Format(Card.ObsLabel.Visible()); Error('NOERROR'); end;
        Observer.Observe('label_visible', Outcome(Value));
        asserterror begin Value := Format(Card.ObsAction.Enabled()); Error('NOERROR'); end;
        Observer.Observe('action_enabled', Outcome(Value));
        asserterror begin Value := Format(Card.ObsExtField.Visible()); Error('NOERROR'); end;
        Observer.Observe('ext_field_visible', Outcome(Value));
        asserterror begin Value := Card.InObsExtGroup.Value; Error('NOERROR'); end;
        Observer.Observe('ext_group_field', Outcome(Value));
        asserterror begin Value := Format(Card.ObsExtAction.Enabled()); Error('NOERROR'); end;
        Observer.Observe('ext_action_enabled', Outcome(Value));
        Card.ObsAction.Invoke();
        Observer.Expect('group_field', 'one');
        Observer.Expect('group_field_visible', 'Yes');
        Observer.Expect('cue_field', '1');
        Observer.Expect('label_visible', 'Yes');
        Observer.Expect('action_enabled', 'Yes');
        Observer.Expect('ext_field_visible', 'Yes');
        Observer.Expect('ext_group_field', '0.00');
        Observer.Expect('ext_action_enabled', 'Yes');
        Observer.Verify();
    end;

    local procedure Outcome(Value: Text): Text
    begin
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            exit(Value);
        end;
        Value := 'ERR ' + GetLastErrorCode();
        ClearLastError();
        exit(Value);
    end;

    [Test]
    procedure Pending_QueryReportXmlPort_StillRun()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Src: Record "LT U Page Src";
        Qry: Query "LT U Obsolete Query";
        Row: Record "LT U Isolation Row";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 7;
        Src.Insert();
        Observer.Observe('query_open', Format(Qry.Open()));
        Observer.Observe('query_read', Format(Qry.Read()));
        Observer.Observe('query_id', Format(Qry.Id));
        Qry.Close();
        Row.DeleteAll();
        Report.Run(Report::"LT U Obsolete Report", false, false);
        Observer.Observe('report_row_inserted', Format(Row.Get(100)));
        Observer.Observe('report_row_note', Row.Note);
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U Obsolete XmlPort", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '\n';
        end;
        Observer.Observe('xmlport_export', Xml);
        Observer.Expect('query_open', 'Yes');
        Observer.Expect('query_read', 'Yes');
        Observer.Expect('query_id', '7');
        Observer.Expect('report_row_inserted', 'Yes');
        Observer.Expect('report_row_note', 'obsolete report ran');
        Observer.Expect('xmlport_export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\n<Root>\n  <Src>\n    <Id>7</Id>\n  </Src>\n</Root>\n');
        Observer.Verify();
    end;
}
