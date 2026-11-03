// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74997, page 74998, codeunits 70005 (log) and 74999
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetView/GetView on a record with marks (MarkedOnly), on a temporary record, after SetCurrentKey and SetAscending, copying the view into another record, and the rows a page shows when opened with Page.RunModal on such a record
// BC versions: 29 (27 and 28 by CI)

table 74997 "LT P146 View Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
        key(ByAmount; Amount) { }
    }
}

page 74998 "LT P146 View List"
{
    PageType = List;
    SourceTable = "LT P146 View Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

codeunit 70005 "LT P146 View Log"
{
    SingleInstance = true;

    var
        Rows: Text;

    procedure Clear()
    begin
        Rows := '';
    end;

    procedure Add(Value: Text)
    begin
        Rows += Value + ';';
    end;

    procedure GetRows(): Text
    begin
        exit(Rows);
    end;
}

codeunit 74999 "LT P146 View Marked Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedReal()
    var
        R: Record "LT P146 View Row";
    begin
        R.DeleteAll();
        AddRow(R, 1, 'Delta', 40);
        AddRow(R, 2, 'Alpha', 10);
        AddRow(R, 3, 'Charlie', 30);
        AddRow(R, 4, 'Bravo', 20);
    end;

    local procedure AddRow(var R: Record "LT P146 View Row"; NewId: Integer; NewName: Text[30]; NewAmount: Decimal)
    begin
        R.Init();
        R.Id := NewId;
        R.Name := NewName;
        R.Amount := NewAmount;
        R.Insert();
    end;

    local procedure Walk(var R: Record "LT P146 View Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure P146_GetView_MarkedOnly_Real()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P146 View Row";
        Other: Record "LT P146 View Row";
    begin
        SeedReal();
        R.Get(2);
        R.Mark(true);
        R.Get(4);
        R.Mark(true);
        Observer.Observe('view before markedonly', R.GetView());
        R.MarkedOnly(true);
        Observer.Observe('markedonly', Format(R.MarkedOnly()));
        Observer.Observe('view markedonly', R.GetView());
        Observer.Observe('view markedonly false arg', R.GetView(false));
        Observer.Observe('walk', Walk(R));
        Observer.Observe('count', Format(R.Count()));
        Other.SetView(R.GetView());
        Observer.Observe('other markedonly', Format(Other.MarkedOnly()));
        Observer.Observe('other walk', Walk(Other));
        Other.Reset();
        Other.Copy(R);
        Observer.Observe('copy markedonly', Format(Other.MarkedOnly()));
        Observer.Observe('copy walk', Walk(Other));
        R.MarkedOnly(false);
        Observer.Observe('view after markedonly false', R.GetView());
        Observer.Observe('walk after false', Walk(R));
        R.ClearMarks();
        Observer.Observe('after clearmarks markedonly', Format(R.MarkedOnly()));
        R.DeleteAll();
        Observer.Expect('view before markedonly', 'VERSION(1) SORTING(Id)');
        Observer.Expect('markedonly', 'Yes');
        Observer.Expect('view markedonly', 'VERSION(1) SORTING(Id)');
        Observer.Expect('view markedonly false arg', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('walk', '2,4,');
        Observer.Expect('count', '2');
        Observer.Expect('other markedonly', 'No');
        Observer.Expect('other walk', '1,2,3,4,');
        Observer.Expect('copy markedonly', 'Yes');
        Observer.Expect('copy walk', '2,4,');
        Observer.Expect('view after markedonly false', 'VERSION(1) SORTING(Id)');
        Observer.Expect('walk after false', '1,2,3,4,');
        Observer.Expect('after clearmarks markedonly', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P146_GetView_MarkedOnly_WithFilterAndKey()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P146 View Row";
    begin
        SeedReal();
        R.SetCurrentKey(Name);
        R.SetAscending(Name, false);
        R.SetFilter(Amount, '>=20');
        R.FindSet();
        repeat
            R.Mark(true);
        until R.Next() = 0;
        R.MarkedOnly(true);
        Observer.Observe('view', R.GetView());
        Observer.Observe('walk', Walk(R));
        R.SetRange(Amount, 30, 40);
        Observer.Observe('view narrowed', R.GetView());
        Observer.Observe('walk narrowed', Walk(R));
        R.Reset();
        Observer.Observe('view after reset', R.GetView());
        Observer.Observe('markedonly after reset', Format(R.MarkedOnly()));
        Observer.Observe('walk after reset', Walk(R));
        R.DeleteAll();
        Observer.Expect('view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>=20))');
        Observer.Expect('walk', '1,3,4,');
        Observer.Expect('view narrowed', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(30..40))');
        Observer.Expect('walk narrowed', '1,3,');
        Observer.Expect('view after reset', 'VERSION(1) SORTING(Id)');
        Observer.Expect('markedonly after reset', 'No');
        Observer.Expect('walk after reset', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure P146_GetView_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P146 View Row" temporary;
        T2: Record "LT P146 View Row" temporary;
    begin
        AddRow(T, 1, 'Delta', 40);
        AddRow(T, 2, 'Alpha', 10);
        AddRow(T, 3, 'Charlie', 30);
        AddRow(T, 4, 'Bravo', 20);
        Observer.Observe('view default', T.GetView());
        T.SetCurrentKey(Name);
        Observer.Observe('view key name', T.GetView());
        Observer.Observe('walk key name', Walk(T));
        T.SetAscending(Name, false);
        Observer.Observe('view descending', T.GetView());
        Observer.Observe('walk descending', Walk(T));
        T.SetFilter(Amount, '>10');
        Observer.Observe('view filtered', T.GetView());
        Observer.Observe('walk filtered', Walk(T));
        T.FindFirst();
        T.Mark(true);
        T.FindLast();
        T.Mark(true);
        T.MarkedOnly(true);
        Observer.Observe('view marked', T.GetView());
        Observer.Observe('walk marked', Walk(T));
        T2.Copy(T, true);
        Observer.Observe('sharetable markedonly', Format(T2.MarkedOnly()));
        Observer.Observe('sharetable view', T2.GetView());
        Observer.Observe('sharetable walk', Walk(T2));
        T2.Reset();
        Observer.Observe('sharetable reset walk', Walk(T2));
        Observer.Observe('original walk after sharetable reset', Walk(T));
        Observer.Expect('view default', 'VERSION(1) SORTING(Id)');
        Observer.Expect('view key name', 'VERSION(1) SORTING(Name)');
        Observer.Expect('walk key name', '2,4,3,1,');
        Observer.Expect('view descending', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Observer.Expect('walk descending', '1,3,4,2,');
        Observer.Expect('view filtered', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10))');
        Observer.Expect('walk filtered', '1,3,4,');
        Observer.Expect('view marked', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10))');
        Observer.Expect('walk marked', '1,4,');
        Observer.Expect('sharetable markedonly', 'Yes');
        Observer.Expect('sharetable view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10))');
        Observer.Expect('sharetable walk', '1,4,');
        Observer.Expect('sharetable reset walk', '1,2,3,4,');
        Observer.Expect('original walk after sharetable reset', '1,4,');
        Observer.Verify();
    end;

    [Test]
    procedure P146_SetView_OnTemporary_AfterMarks()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P146 View Row" temporary;
    begin
        AddRow(T, 1, 'Delta', 40);
        AddRow(T, 2, 'Alpha', 10);
        AddRow(T, 3, 'Charlie', 30);
        AddRow(T, 4, 'Bravo', 20);
        T.Get(1);
        T.Mark(true);
        T.Get(3);
        T.Mark(true);
        T.SetView('SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>=20))');
        Observer.Observe('view after setview', T.GetView());
        Observer.Observe('walk', Walk(T));
        T.MarkedOnly(true);
        Observer.Observe('walk marked within view', Walk(T));
        T.SetView('SORTING(Amount)');
        Observer.Observe('markedonly after setview', Format(T.MarkedOnly()));
        Observer.Observe('walk after second setview', Walk(T));
        Observer.Observe('view after second setview', T.GetView());
        T.ClearMarks();
        Observer.Observe('walk after clearmarks', Walk(T));
        Observer.Expect('view after setview', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>=20))');
        Observer.Expect('walk', '1,3,4,');
        Observer.Expect('walk marked within view', '1,3,');
        Observer.Expect('markedonly after setview', 'Yes');
        Observer.Expect('walk after second setview', '1,3,');
        Observer.Expect('view after second setview', 'VERSION(1) SORTING(Amount) ORDER(Descending)');
        Observer.Expect('walk after clearmarks', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P146_PageRunModal_MarkedOnly_Real()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 View Log";
        R: Record "LT P146 View Row";
    begin
        SeedReal();
        Commit();
        Log.Clear();
        R.Get(1);
        R.Mark(true);
        R.Get(3);
        R.Mark(true);
        R.MarkedOnly(true);
        Page.RunModal(Page::"LT P146 View List", R);
        Observer.Observe('rows of marked real', Log.GetRows());
        R.Reset();
        R.DeleteAll();
        Commit();
        Observer.Expect('rows of marked real', '1:Delta;3:Charlie;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P146_PageRunModal_SortedFiltered_Real()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 View Log";
        R: Record "LT P146 View Row";
    begin
        SeedReal();
        Commit();
        Log.Clear();
        R.SetCurrentKey(Name);
        R.SetAscending(Name, false);
        R.SetFilter(Amount, '>=20');
        Page.RunModal(Page::"LT P146 View List", R);
        Observer.Observe('rows of sorted filtered real', Log.GetRows());
        R.Reset();
        R.DeleteAll();
        Commit();
        Observer.Expect('rows of sorted filtered real', '4:Bravo;3:Charlie;1:Delta;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P146_PageRunModal_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P146 View Log";
        T: Record "LT P146 View Row" temporary;
    begin
        AddRow(T, 1, 'Delta', 40);
        AddRow(T, 2, 'Alpha', 10);
        AddRow(T, 3, 'Charlie', 30);
        AddRow(T, 4, 'Bravo', 20);
        Log.Clear();
        Page.RunModal(Page::"LT P146 View List", T);
        Observer.Observe('rows of temporary', Log.GetRows());
        Log.Clear();
        T.SetCurrentKey(Name);
        T.SetAscending(Name, false);
        Page.RunModal(Page::"LT P146 View List", T);
        Observer.Observe('rows of temporary sorted', Log.GetRows());
        Log.Clear();
        T.Reset();
        T.Get(2);
        T.Mark(true);
        T.Get(4);
        T.Mark(true);
        T.MarkedOnly(true);
        Page.RunModal(Page::"LT P146 View List", T);
        Observer.Observe('rows of temporary marked', Log.GetRows());
        Observer.Expect('rows of temporary', '1:Delta;2:Alpha;3:Charlie;4:Bravo;');
        Observer.Expect('rows of temporary sorted', '2:Alpha;4:Bravo;3:Charlie;1:Delta;');
        Observer.Expect('rows of temporary marked', '2:Alpha;4:Bravo;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ListHandler(var ListPage: TestPage "LT P146 View List")
    var
        Log: Codeunit "LT P146 View Log";
    begin
        if ListPage.First() then
            repeat
                Log.Add(ListPage.Id.Value() + ':' + ListPage.Name.Value());
            until not ListPage.Next();
        ListPage.OK().Invoke();
    end;
}
