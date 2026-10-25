// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT RZ Stock Item / Stock Entry / Stock Items / entry pages (RzFixtures.al, writer RZ)
// Probe: an action with RunObject + RunPageLink "Item Code" = field("Code") opens a list that declares SourceTableView (al-runner issue 5826;
//   Base App page 38 "Item Ledger Entries" declares sorting("Entry No.") order(descending)). Targets: a view that sorts descending, a view with a
//   where filter, both; the action adds RunPageView (ascending sorting, a where filter) beside the link; a link on the field the target's view
//   filters too. What the opened page shows: the link filter as TestPage.Filter reads it, the view field's filter, the row it opens on, the
//   rows from First/Next. Entries: 1 I1 +5, 2 I2 +3, 3 I1 -2, 4 I1 +1, 5 I2 -1.
//   A Card target with a where view is pinned in pages/W1RunObject.al (TargetWithSourceTableView_OrNoSourceTable).
// Object ids 88922 (writer RZ).
// BC versions: 27, 28, 29

codeunit 88922 "LT RZ RunPageLink View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Global so the handlers can record; every test starts with Discard (a failed test leaves no pairs behind).
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('NewestFirstHandler')]
    procedure RZ_Link_DescendingView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.NewestFirst.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NewestFirstHandler')]
    procedure RZ_Link_DescendingView_I2()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I2');
        Items.NewestFirst.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PositiveHandler')]
    procedure RZ_Link_WhereView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.PositiveOnly.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PositiveNewestFirstHandler')]
    procedure RZ_Link_DescendingWhereView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.PositiveNewestFirst.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NewestFirstHandler')]
    procedure RZ_LinkAndRunPageViewAscending_DescendingView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.NewestFirstViewAscending.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NewestFirstHandler')]
    procedure RZ_LinkAndRunPageViewWhere_DescendingView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.NewestFirstViewPositive.Invoke();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PositiveHandler')]
    procedure RZ_LinkOnViewField_WhereView_I1()
    var
        Items: TestPage "LT RZ Stock Items";
    begin
        OpenOn(Items, 'I1');
        Items.PositiveLinkPositive.Invoke();
        Observer.Finish();
    end;

    local procedure OpenOn(var Items: TestPage "LT RZ Stock Items"; ItemCode: Code[20])
    begin
        Observer.Discard();
        Setup();
        Items.OpenView();
        Observer.Observe('goto', Format(Items.GoToKey(ItemCode)));
    end;

    [PageHandler]
    procedure NewestFirstHandler(var Entries: TestPage "LT RZ Entries Newest First")
    var
        Result: Text;
    begin
        Observer.Observe('item filter', Entries.Filter.GetFilter("Item Code"));
        Observer.Observe('positive filter', Entries.Filter.GetFilter(Positive));
        Observer.Observe('current', Entries."Entry No.".Value());
        Observer.Observe('next', Format(Entries.Next()) + '|' + Entries."Entry No.".Value());
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Observer.Observe('rows', Result);
    end;

    [PageHandler]
    procedure PositiveHandler(var Entries: TestPage "LT RZ Positive Entries")
    var
        Result: Text;
    begin
        Observer.Observe('item filter', Entries.Filter.GetFilter("Item Code"));
        Observer.Observe('positive filter', Entries.Filter.GetFilter(Positive));
        Observer.Observe('current', Entries."Entry No.".Value());
        Observer.Observe('next', Format(Entries.Next()) + '|' + Entries."Entry No.".Value());
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Observer.Observe('rows', Result);
    end;

    [PageHandler]
    procedure PositiveNewestFirstHandler(var Entries: TestPage "LT RZ Positive Newest First")
    var
        Result: Text;
    begin
        Observer.Observe('item filter', Entries.Filter.GetFilter("Item Code"));
        Observer.Observe('positive filter', Entries.Filter.GetFilter(Positive));
        Observer.Observe('current', Entries."Entry No.".Value());
        Observer.Observe('next', Format(Entries.Next()) + '|' + Entries."Entry No.".Value());
        if Entries.First() then
            repeat
                Result += Entries."Entry No.".Value() + ',';
            until not Entries.Next();
        Observer.Observe('rows', Result);
    end;

    local procedure Setup()
    var
        StockItem: Record "LT RZ Stock Item";
        StockEntry: Record "LT RZ Stock Entry";
    begin
        StockEntry.DeleteAll();
        StockItem.DeleteAll();
        StockItem."Code" := 'I1';
        StockItem.Insert();
        StockItem."Code" := 'I2';
        StockItem.Insert();
        AddEntry(1, 'I1', 5);
        AddEntry(2, 'I2', 3);
        AddEntry(3, 'I1', -2);
        AddEntry(4, 'I1', 1);
        AddEntry(5, 'I2', -1);
    end;

    local procedure AddEntry(EntryNo: Integer; ItemCode: Code[20]; Qty: Decimal)
    var
        StockEntry: Record "LT RZ Stock Entry";
    begin
        StockEntry.Init();
        StockEntry."Entry No." := EntryNo;
        StockEntry."Item Code" := ItemCode;
        StockEntry.Quantity := Qty;
        StockEntry.Positive := Qty > 0;
        StockEntry.Insert();
    end;
}
