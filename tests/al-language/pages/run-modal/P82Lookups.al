// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 Group List (71193), LT P82 Item (71184), LT P82 Group (71192), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: TestField.Lookup / Drilldown / AssistEdit run the OnLookup / OnDrillDown / OnAssistEdit trigger of the control (value, log, view and edit mode); Lookup on a field with a table relation opens the lookup page of the related table (modal handler, OK and Cancel); the same calls on fields without such a trigger
// BC versions: 29

codeunit 71205 "LT P82 Lookups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Grp: Record "LT P82 Group";
        Log: Codeunit "LT P82 Log";
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        Log.Reset();
        Grp.Code := 'G1';
        Grp.Descr := 'Group one';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Group two';
        Grp.Insert();
        Item."No." := 'L1';
        Item.Name := 'Lookup one';
        Item.Grp := 'G1';
        Item.Insert();
    end;

    // Selector: 1 LookupCtl, 2 NameCtl, 3 QtyCtl, 4 DrillCtl, 5 AssistCtl
    [TryFunction]
    local procedure TryLookup(var Card: TestPage "LT P82 Card"; Sel: Integer)
    begin
        case Sel of
            1:
                Card.LookupCtl.Lookup();
            2:
                Card.NameCtl.Lookup();
            3:
                Card.QtyCtl.Lookup();
            4:
                Card.DrillCtl.Lookup();
            5:
                Card.AssistCtl.Lookup();
        end;
    end;

    [TryFunction]
    local procedure TryDrill(var Card: TestPage "LT P82 Card"; Sel: Integer)
    begin
        case Sel of
            1:
                Card.LookupCtl.Drilldown();
            2:
                Card.NameCtl.Drilldown();
            4:
                Card.DrillCtl.Drilldown();
            5:
                Card.AssistCtl.Drilldown();
        end;
    end;

    [TryFunction]
    local procedure TryAssist(var Card: TestPage "LT P82 Card"; Sel: Integer)
    begin
        case Sel of
            1:
                Card.LookupCtl.AssistEdit();
            2:
                Card.NameCtl.AssistEdit();
            4:
                Card.DrillCtl.AssistEdit();
            5:
                Card.AssistCtl.AssistEdit();
        end;
    end;

    [ModalPageHandler]
    procedure PickG2(var P: TestPage "LT P82 Group List")
    begin
        Observer.Observe('handler-first', P.CodeCtl.Value());
        P.GoToKey('G2');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelGroup(var P: TestPage "LT P82 Group List")
    begin
        P.GoToKey('G2');
        P.Cancel().Invoke();
    end;

    [Test]
    procedure Lookup_Trigger_EditMode()
    var
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Log.Reset();
        Observer.Observe('value-before', Card.LookupCtl.Value());
        Card.LookupCtl.Lookup();
        Observer.Observe('value-after', Card.LookupCtl.Value());
        Observer.Observe('log', Log.Dump());
        Card.LookupCtl.SetValue('typed');
        Log.Reset();
        Card.LookupCtl.Lookup();
        Observer.Observe('log-with-typed-value', Log.Dump());
        Observer.Observe('value-after-second', Card.LookupCtl.Value());
        Card.Close();
        Observer.Expect('value-before', '');
        Observer.Expect('value-after', 'looked');
        Observer.Expect('log', 'OnLookup()');
        Observer.Expect('log-with-typed-value', 'OnLookup(typed)');
        Observer.Expect('value-after-second', 'looked');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_Trigger_ViewMode()
    var
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('L1');
        Log.Reset();
        Observer.Observe('lookup-ok', Format(TryLookup(Card, 1)));
        Observer.Observe('lookup-error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('lookup-ok', 'Yes');
        Observer.Expect('lookup-error', '');
        Observer.Expect('log', 'OnLookup()');
        Observer.Verify();
    end;

    [Test]
    procedure Drilldown_Trigger()
    var
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Log.Reset();
        Card.DrillCtl.Drilldown();
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Card.OpenView();
        Card.GoToKey('L1');
        Log.Reset();
        Card.DrillCtl.Drilldown();
        Observer.Observe('log-view', Log.Dump());
        Card.Close();
        Observer.Expect('log', 'OnDrillDown');
        Observer.Expect('log-view', 'OnDrillDown');
        Observer.Verify();
    end;

    [Test]
    procedure AssistEdit_Trigger()
    var
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Log.Reset();
        Card.AssistCtl.AssistEdit();
        Observer.Observe('value-after', Card.AssistCtl.Value());
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Card.OpenView();
        Card.GoToKey('L1');
        Log.Reset();
        Observer.Observe('view-ok', Format(TryAssist(Card, 5)));
        Observer.Observe('view-error', GetLastErrorText());
        Observer.Observe('log-view', Log.Dump());
        Card.Close();
        Observer.Expect('value-after', 'assisted');
        Observer.Expect('log', 'OnAssistEdit;OnAfterGetRecord(L1)');
        Observer.Expect('view-ok', 'Yes');
        Observer.Expect('view-error', '');
        Observer.Expect('log-view', 'OnAssistEdit;OnAfterGetRecord(L1)');
        Observer.Verify();
    end;

    [Test]
    procedure WrongKindOfCall_OnTriggerLessFields()
    var
        Log: Codeunit "LT P82 Log";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Log.Reset();
        Observer.Observe('drill-on-name', Format(TryDrill(Card, 2)));
        Observer.Observe('drill-on-name-error', GetLastErrorText());
        Observer.Observe('assist-on-name', Format(TryAssist(Card, 2)));
        Observer.Observe('assist-on-name-error', GetLastErrorText());
        Observer.Observe('lookup-on-name', Format(TryLookup(Card, 2)));
        Observer.Observe('lookup-on-name-error', GetLastErrorText());
        Observer.Observe('lookup-on-qty', Format(TryLookup(Card, 3)));
        Observer.Observe('lookup-on-qty-error', GetLastErrorText());
        Observer.Observe('drill-on-lookupctl', Format(TryDrill(Card, 1)));
        Observer.Observe('drill-on-lookupctl-error', GetLastErrorText());
        Observer.Observe('assist-on-lookupctl', Format(TryAssist(Card, 1)));
        Observer.Observe('assist-on-lookupctl-error', GetLastErrorText());
        Observer.Observe('lookup-on-drillctl', Format(TryLookup(Card, 4)));
        Observer.Observe('lookup-on-drillctl-error', GetLastErrorText());
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('drill-on-name', 'No');
        Observer.Expect('drill-on-name-error', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('assist-on-name', 'No');
        Observer.Expect('assist-on-name-error', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('lookup-on-name', 'Yes');
        Observer.Expect('lookup-on-name-error', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('lookup-on-qty', 'Yes');
        Observer.Expect('lookup-on-qty-error', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('drill-on-lookupctl', 'No');
        Observer.Expect('drill-on-lookupctl-error', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('assist-on-lookupctl', 'No');
        Observer.Expect('assist-on-lookupctl-error', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('lookup-on-drillctl', 'Yes');
        Observer.Expect('lookup-on-drillctl-error', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickG2')]
    procedure Lookup_TableRelation_Ok()
    var
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Observer.Observe('grp-before', Card.GrpCtl.Value());
        Card.GrpCtl.Lookup();
        Observer.Observe('grp-after', Card.GrpCtl.Value());
        Card.Close();
        Item.Get('L1');
        Observer.Observe('grp-stored', Item.Grp);
        Observer.Expect('grp-before', 'G1');
        Observer.Expect('handler-first', 'G1');
        Observer.Expect('grp-after', 'G2');
        Observer.Expect('grp-stored', 'G2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelGroup')]
    procedure Lookup_TableRelation_Cancel()
    var
        Item: Record "LT P82 Item";
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        Card.GrpCtl.Lookup();
        Observer.Observe('grp-after-cancel', Card.GrpCtl.Value());
        Card.Close();
        Item.Get('L1');
        Observer.Observe('grp-stored', Item.Grp);
        Observer.Expect('grp-after-cancel', 'G1');
        Observer.Expect('grp-stored', 'G1');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_TableRelation_WithoutHandler()
    var
        Card: TestPage "LT P82 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L1');
        asserterror Card.GrpCtl.Lookup();
        Observer.ObserveError('lookup-no-handler');
        Observer.Observe('grp-after', Card.GrpCtl.Value());
        Card.Close();
        Observer.Expect('lookup-no-handler|text', 'Unhandled UI: ModalPage 71193');
        Observer.Expect('lookup-no-handler|code', 'TestWrapped:MissingUIHandler');
        Observer.Expect('grp-after', 'G1');
        Observer.Verify();
    end;
}
