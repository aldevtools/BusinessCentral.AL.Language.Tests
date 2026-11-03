// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.RunModal with a record on a list page whose SourceTableView names a sorting, an order and a where clause: the row that is current when the page opens,
//   the order the rows are read in, which rows show, with no record, a record positioned on a row inside the view, a record on a row outside the where clause,
//   a record with its own filter and key, and a page whose SourceTableView sorts by a non-primary key.
// BC versions: 29 (27 and 28 by CI)

table 71956 "LT PSV Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Grp; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(NameKey; Name) { }
    }
}

page 71957 "LT PSV Desc List"
{
    PageType = List;
    SourceTable = "LT PSV Row";
    SourceTableView = sorting("No.") order(descending) where(Grp = filter(1));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 71958 "LT PSV Name List"
{
    PageType = List;
    SourceTable = "LT PSV Row";
    SourceTableView = sorting(Name);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 71959 "LT PSV Page View Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AtOpen: Text;
        Walk: Text;

    local procedure Seed()
    var
        R: Record "LT PSV Row";
    begin
        R.DeleteAll();
        Add(1, 'Zed', 1);
        Add(2, 'Amy', 1);
        Add(3, 'Mid', 1);
        Add(4, 'Bob', 2);
        Clear(AtOpen);
        Clear(Walk);
    end;

    local procedure Add(NewNo: Integer; NewName: Text[20]; NewGrp: Integer)
    var
        R: Record "LT PSV Row";
    begin
        R."No." := NewNo;
        R.Name := NewName;
        R.Grp := NewGrp;
        R.Insert();
    end;

    [ModalPageHandler]
    procedure DescHandler(var P: TestPage "LT PSV Desc List")
    begin
        AtOpen := P."No.".Value();
        if P.First() then
            repeat
                Walk += P."No.".Value() + ',';
            until not P.Next();
    end;

    [ModalPageHandler]
    procedure SafeDescHandler(var P: TestPage "LT PSV Desc List")
    begin
        Walk := 'rows:';
        if P.First() then
            repeat
                Walk += P."No.".Value() + ',';
            until not P.Next();
    end;

    [ModalPageHandler]
    procedure NameHandler(var P: TestPage "LT PSV Name List")
    begin
        AtOpen := P."No.".Value();
        if P.First() then
            repeat
                Walk += P."No.".Value() + ',';
            until not P.Next();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure P184_RunModal_NoRecord_DescendingView()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        Page.RunModal(Page::"LT PSV Desc List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '1');
        Observer.Expect('rows in order', '3,2,1,0,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure P184_RunModal_RecordOnRowInsideView()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        R.Get(2);
        Page.RunModal(Page::"LT PSV Desc List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '2');
        Observer.Expect('rows in order', '3,2,1,0,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure P184_RunModal_RecordOnRowOutsideWhere()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        R.Get(4);
        Page.RunModal(Page::"LT PSV Desc List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '3');
        Observer.Expect('rows in order', '3,2,1,0,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure P184_RunModal_RecordWithOwnFilterAndKey()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        R.SetCurrentKey(Name);
        R.SetFilter("No.", '<3');
        Page.RunModal(Page::"LT PSV Desc List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '1');
        Observer.Expect('rows in order', '2,1,0,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SafeDescHandler')]
    procedure P184_RunModal_RecordWithConflictingGroupFilter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        R.SetRange(Grp, 2);
        Page.RunModal(Page::"LT PSV Desc List", R);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('rows in order', 'rows:');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NameHandler')]
    procedure P184_RunModal_NameSortedView_NoRecord_And_Positioned()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        Page.RunModal(Page::"LT PSV Name List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '2');
        Observer.Expect('rows in order', '2,4,3,1,0,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NameHandler')]
    procedure P184_RunModal_NameSortedView_RecordOnRow()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PSV Row";
    begin
        Seed();
        R.Get(3);
        Page.RunModal(Page::"LT PSV Name List", R);
        Observer.Observe('current at open', AtOpen);
        Observer.Observe('rows in order', Walk);
        Observer.Expect('current at open', '3');
        Observer.Expect('rows in order', '2,4,3,1,0,');
        Observer.Verify();
    end;
}
