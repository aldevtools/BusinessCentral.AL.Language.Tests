// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: own objects 90140 - 90143 (writer TW); Assert (60021)
// Probe: al-runner issue 6114 (reporter's real-BC 29.0 run, 11/11 green), objects renamed. A list page with
//   SourceTableView = sorting("Sort No.") order(descending) (and the same page with order(ascending)), Editable = false, run with
//   Page.Run or Page.RunModal and a record filtered on "Group Code" (not positioned, positioned with FindFirst, ascending or
//   descending), or with no record. Log: filter=<Group Code filter seen by the TestPage> entry=<row the TestPage stands on when
//   the handler starts> rows=<First, then Next to the end>.
// Facts: the rows always run in the view's direction. Page.Run on the descending view enters on the FIRST row of the view's order
//   (E3S30) for a record that is not positioned, ascending or descending, and with no record; Page.RunModal with the same
//   filtered record enters on the LAST row (E2S10). A record positioned with FindFirst opens on that row with either call.
// Neighbours: PageSourceViewCurrentRow.al (RunModal only, view on the primary key), types/lt-code-digits-page-run-view/P145PageRunView.al
//   (Page.Run row order, not the entry row).
// BC versions: 27, 28, 29

table 90140 "LT TW View Order Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; "Entry No."; Integer) { }
        field(3; "Sort No."; Integer) { }
        field(4; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Group Code", "Entry No.") { Clustered = true; }
        key(BySort; "Group Code", "Sort No.") { }
    }
}

page 90141 "LT TW View Order Asc List"
{
    PageType = List;
    SourceTable = "LT TW View Order Line";
    SourceTableView = sorting("Sort No.") order(ascending);
    UsageCategory = None;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Sort No."; Rec."Sort No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 90142 "LT TW View Order Desc List"
{
    PageType = List;
    SourceTable = "LT TW View Order Line";
    SourceTableView = sorting("Sort No.") order(descending);
    UsageCategory = None;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Sort No."; Rec."Sort No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 90143 "LT TW View Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Log: Text;

    [Test]
    [HandlerFunctions('AscModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AscViewAscRecPositioned()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.FindFirst();
        Page.RunModal(Page::"LT TW View Order Asc List", Line);
        Assert.AreEqual('filter=G1 entry=E1S20 rows=E2S10,E1S20,E3S30,', Log, 'RunModal, view sorting(Sort No.) order(ascending), record ascending on primary key after FindFirst');
    end;

    [Test]
    [HandlerFunctions('AscModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AscViewAscRec()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Page.RunModal(Page::"LT TW View Order Asc List", Line);
        Assert.AreEqual('filter=G1 entry=E2S10 rows=E2S10,E1S20,E3S30,', Log, 'RunModal, view order(ascending), record ascending, not positioned');
    end;

    [Test]
    [HandlerFunctions('DescModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewAscRec()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Page.RunModal(Page::"LT TW View Order Desc List", Line);
        Assert.AreEqual('filter=G1 entry=E2S10 rows=E3S30,E1S20,E2S10,', Log, 'RunModal, view order(descending), record ascending, not positioned');
    end;

    [Test]
    [HandlerFunctions('AscModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AscViewDescRec()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.Ascending(false);
        Page.RunModal(Page::"LT TW View Order Asc List", Line);
        Assert.AreEqual('filter=G1 entry=E2S10 rows=E2S10,E1S20,E3S30,', Log, 'RunModal, view order(ascending), record descending, not positioned');
    end;

    [Test]
    [HandlerFunctions('DescModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewAscRecPositioned()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.FindFirst();
        Page.RunModal(Page::"LT TW View Order Desc List", Line);
        Assert.AreEqual('filter=G1 entry=E1S20 rows=E3S30,E1S20,E2S10,', Log, 'RunModal, view order(descending), record ascending on primary key after FindFirst');
    end;

    [Test]
    [HandlerFunctions('DescPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewAscRecPageRun()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Page.Run(Page::"LT TW View Order Desc List", Line);
        Assert.AreEqual('filter=G1 entry=E3S30 rows=E3S30,E1S20,E2S10,', Log, 'Page.Run, view order(descending), record ascending, not positioned');
    end;

    [Test]
    [HandlerFunctions('AscPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AscViewDescRecPageRun()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.Ascending(false);
        Page.Run(Page::"LT TW View Order Asc List", Line);
        Assert.AreEqual('filter=G1 entry=E2S10 rows=E2S10,E1S20,E3S30,', Log, 'Page.Run, view order(ascending), record descending, not positioned');
    end;

    [Test]
    [HandlerFunctions('DescPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewDescRecPageRun()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.Ascending(false);
        Page.Run(Page::"LT TW View Order Desc List", Line);
        Assert.AreEqual('filter=G1 entry=E3S30 rows=E3S30,E1S20,E2S10,', Log, 'Page.Run, view order(descending), record descending, not positioned');
    end;

    [Test]
    [HandlerFunctions('DescPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewAscRecPositionedPageRun()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Line.FindFirst();
        Page.Run(Page::"LT TW View Order Desc List", Line);
        Assert.AreEqual('filter=G1 entry=E1S20 rows=E3S30,E1S20,E2S10,', Log, 'Page.Run, view order(descending), record ascending on primary key after FindFirst');
    end;

    [Test]
    [HandlerFunctions('AscPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AscViewAscRecPageRun()
    var
        Line: Record "LT TW View Order Line";
    begin
        Initialize();
        Line.SetRange("Group Code", 'G1');
        Page.Run(Page::"LT TW View Order Asc List", Line);
        Assert.AreEqual('filter=G1 entry=E2S10 rows=E2S10,E1S20,E3S30,', Log, 'Page.Run, view order(ascending), record ascending, not positioned');
    end;

    [Test]
    [HandlerFunctions('DescPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DescViewNoRecPageRun()
    begin
        Initialize();
        Page.Run(Page::"LT TW View Order Desc List");
        Assert.AreEqual('filter= entry=E3S30 rows=E3S30,E1S20,E2S10,G2E1,', Log, 'Page.Run, view order(descending), no record');
    end;

    local procedure Initialize()
    var
        Line: Record "LT TW View Order Line";
    begin
        Log := '';
        Line.DeleteAll();
        InsertLine('G1', 1, 20, 'E1S20');
        InsertLine('G1', 2, 10, 'E2S10');
        InsertLine('G1', 3, 30, 'E3S30');
        InsertLine('G2', 1, 5, 'G2E1');
        Commit();
    end;

    local procedure InsertLine(GroupCode: Code[20]; EntryNo: Integer; SortNo: Integer; Desc: Text[50])
    var
        Line: Record "LT TW View Order Line";
    begin
        Line."Group Code" := GroupCode;
        Line."Entry No." := EntryNo;
        Line."Sort No." := SortNo;
        Line.Description := Desc;
        Line.Insert();
    end;

    [ModalPageHandler]
    procedure AscModalHandler(var ListPage: TestPage "LT TW View Order Asc List")
    begin
        Log := 'filter=' + ListPage.Filter.GetFilter("Group Code") + ' entry=' + ListPage.Description.Value() + ' rows=';
        if ListPage.First() then
            repeat
                Log += ListPage.Description.Value() + ',';
            until not ListPage.Next();
    end;

    [ModalPageHandler]
    procedure DescModalHandler(var ListPage: TestPage "LT TW View Order Desc List")
    begin
        Log := 'filter=' + ListPage.Filter.GetFilter("Group Code") + ' entry=' + ListPage.Description.Value() + ' rows=';
        if ListPage.First() then
            repeat
                Log += ListPage.Description.Value() + ',';
            until not ListPage.Next();
    end;

    [PageHandler]
    procedure AscPageHandler(var ListPage: TestPage "LT TW View Order Asc List")
    begin
        Log := 'filter=' + ListPage.Filter.GetFilter("Group Code") + ' entry=' + ListPage.Description.Value() + ' rows=';
        if ListPage.First() then
            repeat
                Log += ListPage.Description.Value() + ',';
            until not ListPage.Next();
    end;

    [PageHandler]
    procedure DescPageHandler(var ListPage: TestPage "LT TW View Order Desc List")
    begin
        Log := 'filter=' + ListPage.Filter.GetFilter("Group Code") + ' entry=' + ListPage.Description.Value() + ' rows=';
        if ListPage.First() then
            repeat
                Log += ListPage.Description.Value() + ',';
            until not ListPage.Next();
    end;
}
