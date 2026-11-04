// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 List (71188), LT P82 Card (71187), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: members of a Page variable (Update, Close, Activate, SaveRecord, SetSelectionFilter, ObjectId, Caption, Editable, LookupMode, GetRecord) called before the page runs, while its modal page is open (from the handler through the variable) and after it closed
// BC versions: 29

codeunit 71207 "LT P82 Page Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
        Log: Codeunit "LT P82 Log";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'V1';
        Item.Name := 'Var one';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'V2';
        Item.Name := 'Var two';
        Item.Qty := 2;
        Item.Insert();
    end;

    [TryFunction]
    local procedure TryUpdate(var Pg: Page "LT P82 List"; Save: Boolean)
    begin
        Pg.Update(Save);
    end;

    [TryFunction]
    local procedure TryClose(var Pg: Page "LT P82 List")
    begin
        Pg.Close();
    end;

    [TryFunction]
    local procedure TryActivate(var Pg: Page "LT P82 List")
    begin
        Pg.Activate();
    end;

    [TryFunction]
    local procedure TrySaveRecord(var Pg: Page "LT P82 List")
    begin
        Pg.SaveRecord();
    end;

    [TryFunction]
    local procedure TrySetSelectionFilter(var Pg: Page "LT P82 List"; var Item: Record "LT P82 Item")
    begin
        Pg.SetSelectionFilter(Item);
    end;

    [TryFunction]
    local procedure TryGetRecord(var Pg: Page "LT P82 List"; var Item: Record "LT P82 Item")
    begin
        Pg.GetRecord(Item);
    end;

    [Test]
    procedure BeforeRun_Members()
    var
        Pg: Page "LT P82 List";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Observer.Observe('update-false', Format(TryUpdate(Pg, false)));
        Observer.Observe('update-false-error', GetLastErrorText());
        Observer.Observe('update-true', Format(TryUpdate(Pg, true)));
        Observer.Observe('update-true-error', GetLastErrorText());
        Observer.Observe('close', Format(TryClose(Pg)));
        Observer.Observe('close-error', GetLastErrorText());
        Observer.Observe('activate', Format(TryActivate(Pg)));
        Observer.Observe('activate-error', GetLastErrorText());
        Observer.Observe('saverecord', Format(TrySaveRecord(Pg)));
        Observer.Observe('saverecord-error', GetLastErrorText());
        Observer.Observe('selectionfilter', Format(TrySetSelectionFilter(Pg, Item)));
        Observer.Observe('selectionfilter-error', GetLastErrorText());
        Observer.Observe('getrecord', Format(TryGetRecord(Pg, Item)));
        Observer.Observe('getrecord-error', GetLastErrorText());
        Observer.Observe('getrecord-no', Item."No.");
        Observer.Observe('editable', Format(Pg.Editable()));
        Observer.Observe('lookupmode', Format(Pg.LookupMode()));
        Observer.Expect('update-false', 'Yes');
        Observer.Expect('update-false-error', '');
        Observer.Expect('update-true', 'Yes');
        Observer.Expect('update-true-error', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close-error', '');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate-error', '');
        Observer.Expect('saverecord', 'Yes');
        Observer.Expect('saverecord-error', '');
        Observer.Expect('selectionfilter', 'Yes');
        Observer.Expect('selectionfilter-error', '');
        Observer.Expect('getrecord', 'Yes');
        Observer.Expect('getrecord-error', '');
        Observer.Expect('getrecord-no', '');
        Observer.Expect('editable', 'Yes');
        Observer.Expect('lookupmode', 'No');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure Closer(var P: TestPage "LT P82 List")
    begin
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('Closer')]
    procedure AfterRunModal_Members()
    var
        Pg: Page "LT P82 List";
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('V2');
        Pg.SetRecord(Item);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Clear(Item);
        Observer.Observe('getrecord', Format(TryGetRecord(Pg, Item)));
        Observer.Observe('getrecord-error', GetLastErrorText());
        Observer.Observe('getrecord-no', Item."No.");
        Observer.Observe('update', Format(TryUpdate(Pg, false)));
        Observer.Observe('update-error', GetLastErrorText());
        Observer.Observe('close', Format(TryClose(Pg)));
        Observer.Observe('close-error', GetLastErrorText());
        Observer.Observe('activate', Format(TryActivate(Pg)));
        Observer.Observe('activate-error', GetLastErrorText());
        Observer.Observe('saverecord', Format(TrySaveRecord(Pg)));
        Observer.Observe('saverecord-error', GetLastErrorText());
        Observer.Expect('action', 'OK');
        Observer.Expect('getrecord', 'Yes');
        Observer.Expect('getrecord-error', '');
        Observer.Expect('getrecord-no', 'V2');
        Observer.Expect('update', 'Yes');
        Observer.Expect('update-error', '');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close-error', '');
        Observer.Expect('activate', 'Yes');
        Observer.Expect('activate-error', '');
        Observer.Expect('saverecord', 'Yes');
        Observer.Expect('saverecord-error', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Closer')]
    procedure RunModal_Twice_SameVariable()
    var
        Pg: Page "LT P82 List";
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        Result := Pg.RunModal();
        Observer.Observe('first', Format(Result));
        Result := Pg.RunModal();
        Observer.Observe('second', Format(Result));
        Observer.Expect('first', 'OK');
        Observer.Expect('second', 'OK');
        Observer.Verify();
    end;

    local procedure Finish()
    begin
        Observer.Finish();
    end;
}
