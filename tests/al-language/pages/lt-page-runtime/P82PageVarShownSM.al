// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Facts: Page variable members that P82PageVar.al does not cover: Update() without an argument on a variable that never ran and after its modal page closed,
// Update(true) after close, and Activate(), Activate(true), Update(), Update(false) on the variable while its page is shown (Page.Run caught by TestPage.Trap):
// ok or the error text, which row triggers run (log), and whether the page shows a change made to the row in the database before the call.
// BC versions: 27, 28, 29

codeunit 89242 "LT SM P82 Shown Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
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

    local procedure Rename(No: Code[20]; NewName: Text[50])
    var
        Item: Record "LT P82 Item";
    begin
        Item.Get(No);
        Item.Name := NewName;
        Item.Modify();
    end;

    [TryFunction]
    local procedure TryUpdateNoArg(var Pg: Page "LT P82 Card")
    begin
        Pg.Update();
    end;

    [TryFunction]
    local procedure TryUpdate(var Pg: Page "LT P82 Card"; Save: Boolean)
    begin
        Pg.Update(Save);
    end;

    [TryFunction]
    local procedure TryActivate(var Pg: Page "LT P82 Card"; Refresh: Boolean)
    begin
        Pg.Activate(Refresh);
    end;

    [TryFunction]
    local procedure TryActivateNoArg(var Pg: Page "LT P82 Card")
    begin
        Pg.Activate();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        Observer.Observe(Name + '-error', GetLastErrorText());
        Observer.Observe(Name + '-log', Log.Dump());
        Log.Reset();
        ClearLastError();
    end;

    [Test]
    procedure NeverRan_UpdateNoArg()
    var
        Pg: Page "LT P82 Card";
    begin
        Seed();
        Step('update', TryUpdateNoArg(Pg));
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure CardCloser(var P: TestPage "LT P82 Card")
    begin
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CardCloser')]
    procedure AfterRunModal_UpdateNoArg_UpdateTrue()
    var
        Pg: Page "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V2');
        Pg.SetRecord(Item);
        Observer.Observe('action', Format(Pg.RunModal()));
        Log.Reset();
        Step('update', TryUpdateNoArg(Pg));
        Step('update-true', TryUpdate(Pg, true));
        Step('activate-true', TryActivate(Pg, true));
        Observer.Finish();
    end;

    [Test]
    procedure Shown_ActivateNoArg_AfterDatabaseChange()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        Observer.Observe('open-log', Log.Dump());
        Log.Reset();
        Rename('V1', 'Changed one');
        Step('activate', TryActivateNoArg(Pg));
        Observer.Observe('name', TP.NameCtl.Value());
        TP.Close();
        Observer.Observe('close-log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure Shown_ActivateTrue_AfterDatabaseChange()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        Log.Reset();
        Rename('V1', 'Changed one');
        Step('activate-true', TryActivate(Pg, true));
        Observer.Observe('name', TP.NameCtl.Value());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Shown_ActivateFalse_AfterDatabaseChange()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        Log.Reset();
        Rename('V1', 'Changed one');
        Step('activate-false', TryActivate(Pg, false));
        Observer.Observe('name', TP.NameCtl.Value());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Shown_UpdateNoArg_AfterDatabaseChange()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        Log.Reset();
        Rename('V1', 'Changed one');
        Step('update', TryUpdateNoArg(Pg));
        Observer.Observe('name', TP.NameCtl.Value());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Shown_UpdateFalse_AfterDatabaseChange()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        Log.Reset();
        Rename('V1', 'Changed one');
        Step('update-false', TryUpdate(Pg, false));
        Observer.Observe('name', TP.NameCtl.Value());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure AfterTestPageClose_UpdateTrue_ActivateTrue()
    var
        Pg: Page "LT P82 Card";
        TP: TestPage "LT P82 Card";
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('V1');
        Pg.SetRecord(Item);
        TP.Trap();
        Pg.Run();
        TP.Close();
        Log.Reset();
        Step('update-true', TryUpdate(Pg, true));
        Step('update', TryUpdateNoArg(Pg));
        Step('activate-true', TryActivate(Pg, true));
        Observer.Finish();
    end;
}
