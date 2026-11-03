// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG View List (70148), LT PnG Card View (70161), LT PnG List (70135), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 90 (TestPage): a page that declares SourceTableView, handed a record by Page.Run (how the two views combine)
// Facts: the rows a list and a card show when Page.Run / Page.RunModal hands a record with a filter on the same field, on another field, with no filter, and with a different key
// BC versions: 29 (27 and 28 by CI)

codeunit 70189 "LT PnG Source View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
        Log: Codeunit "LT PnG Log";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to 5 do begin
            Item.Init();
            Item."No." := 'V' + Format(i);
            Item.Name := 'View ' + Format(i);
            Item.Qty := i;
            Item.Insert();
        end;
        Log.Reset();
    end;

    [Test]
    [HandlerFunctions('ViewListHandler')]
    procedure NoRecordHanded()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
    begin
        Seed();
        Page.Run(Page::"LT PnG View List");
        Observer.Observe('rows', Log.Dump());
        Observer.Expect('rows', 'ViewList(V2,V3,V4,V5,,)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewListHandler')]
    procedure HandedRecordWithoutFilters()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Page.Run(Page::"LT PnG View List", Item);
        Observer.Observe('rows', Log.Dump());
        Observer.Expect('rows', 'ViewList(V2,V3,V4,V5,,)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewListHandler')]
    procedure HandedRecordWithAnotherKeyAndDirection()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        Seed();
        Item.SetCurrentKey(Qty);
        Item.Ascending(false);
        asserterror begin Page.Run(Page::"LT PnG View List", Item); Error('LT-NOERROR'); end;
        Observer.ObserveError('descending-key');
        Observer.Expect('descending-key|text', 'LT-NOERROR');
        Observer.Expect('descending-key|code', 'Dialog');
        Observer.Verify();
    end;

    [PageHandler]
    procedure ViewListHandler(var P: TestPage "LT PnG View List")
    var
        Log: Codeunit "LT PnG Log";
        Rows: Text;
        More: Boolean;
    begin
        More := P.First();
        while More do begin
            Rows += P.NoCtl.Value() + ',';
            More := P.Next();
        end;
        Log.Add('ViewList(' + Rows + ')');
    end;

    [PageHandler]
    procedure CardViewHandler(var P: TestPage "LT PnG Card View")
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('CardView(' + P.NoCtl.Value() + '|' + P.QtyCtl.Value() + ')');
    end;
}
