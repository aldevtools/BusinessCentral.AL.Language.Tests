// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 62600, tables 62601 62602, pages 62603..62605, test codeunit 62607
// Probe: observe-only. Area: the value forms of SubPageLink, SubPageView, RunPageLink and RunPageView that name an enum member with its
//   enum type or an object number constant. Y42LinkQuotedMember.al pins filter() and const() with a bare member name (also with <>),
//   TestCalcFormulaDatabaseConst.Codeunit.al pins const(Database::X) in a CalcFormula and a TableRelation. Not pinned:
//   filter(<> "Enum"::"Member"), filter("Enum"::A | "Enum"::B) and const("Enum"::Member) in a link or a view (al-runner issue 7405);
//   filter(Database::X), const(Database::X), filter(<> Database::X), an or of two Database:: constants and Page::X on an Integer field in
//   a view or a link (al-runner issue 7411).
// Observed per part or run page: the rows it shows and the filter text TestPage reports for the filtered field.
// Rows of H1: 10 Inbound (table no of "PG LV Head"), 20 Outbound (table no of "PG LV Row"), 30 Memo (0), 40 Inbound (table no of
//   "PG LV Row"), 50 Outbound (page no of "PG LV Rows"). H2 has one row, 10 Outbound, that no part of H1 may show.
// local object: the link and view properties of the host page are what the test checks; the enum has members with a space in the name
// BC versions: 27, 28, 29

enum 62600 "PG LV Doc Type"
{
    Extensible = false;
    value(0; "Inbound Document") { Caption = 'Inbound Document'; }
    value(1; "Outbound Document") { Caption = 'Outbound Document'; }
    value(2; Memo) { Caption = 'Memo'; }
}

table 62601 "PG LV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 62602 "PG LV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; "Doc Type"; Enum "PG LV Doc Type") { DataClassification = SystemMetadata; }
        field(4; "Record Table No."; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

page 62603 "PG LV Rows"
{
    PageType = ListPart;
    SourceTable = "PG LV Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Doc Type"; Rec."Doc Type") { ApplicationArea = All; }
                field("Record Table No."; Rec."Record Table No.") { ApplicationArea = All; }
            }
        }
    }
}

page 62604 "PG LV Row List"
{
    PageType = List;
    SourceTable = "PG LV Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Doc Type"; Rec."Doc Type") { ApplicationArea = All; }
                field("Record Table No."; Rec."Record Table No.") { ApplicationArea = All; }
            }
        }
    }
}

page 62605 "PG LV Host"
{
    PageType = Card;
    SourceTable = "PG LV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(NeQual; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Doc Type" = filter(<> "PG LV Doc Type"::"Outbound Document");
            }
            part(EqQual; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Doc Type" = filter("PG LV Doc Type"::"Outbound Document");
            }
            part(OrQual; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Doc Type" = filter("PG LV Doc Type"::"Inbound Document" | "PG LV Doc Type"::Memo);
            }
            part(NePlain; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Doc Type" = filter(<> "Outbound Document");
            }
            part(ConstQual; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Doc Type" = const("PG LV Doc Type"::Memo);
            }
            part(NeQualView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Doc Type" = filter(<> "PG LV Doc Type"::"Outbound Document"));
            }
            part(OrQualView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Doc Type" = filter("PG LV Doc Type"::"Inbound Document" | "PG LV Doc Type"::Memo));
            }
            part(DbFilterView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = filter(Database::"PG LV Head"));
            }
            part(DbConstView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = const(Database::"PG LV Head"));
            }
            part(DbNeView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = filter(<> Database::"PG LV Head"));
            }
            part(DbOrView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = filter(Database::"PG LV Head" | Database::"PG LV Row"));
            }
            part(DbFilterLink; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Record Table No." = filter(Database::"PG LV Row");
            }
            part(DbConstLink; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code), "Record Table No." = const(Database::"PG LV Row");
            }
            part(PageConstView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = const(Page::"PG LV Rows"));
            }
            part(PageFilterView; "PG LV Rows")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field(Code);
                SubPageView = where("Record Table No." = filter(Page::"PG LV Rows"));
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunNeQual)
            {
                ApplicationArea = All;
                RunObject = page "PG LV Row List";
                RunPageLink = "Head Code" = field(Code), "Doc Type" = filter(<> "PG LV Doc Type"::"Outbound Document");
            }
            action(RunDbFilterLink)
            {
                ApplicationArea = All;
                RunObject = page "PG LV Row List";
                RunPageLink = "Head Code" = field(Code), "Record Table No." = filter(Database::"PG LV Row");
            }
            action(RunDbFilterView)
            {
                ApplicationArea = All;
                RunObject = page "PG LV Row List";
                RunPageLink = "Head Code" = field(Code);
                RunPageView = where("Record Table No." = filter(Database::"PG LV Head"));
            }
            action(RunNeQualView)
            {
                ApplicationArea = All;
                RunObject = page "PG LV Row List";
                RunPageLink = "Head Code" = field(Code);
                RunPageView = where("Doc Type" = filter(<> "PG LV Doc Type"::"Outbound Document"));
            }
        }
    }
}

codeunit 62607 "PG LV Link Value Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        RunRows: Text;
        RunTypeFilter: Text;
        RunTableFilter: Text;

    local procedure Seed()
    var
        Head: Record "PG LV Head";
        Row: Record "PG LV Row";
    begin
        Row.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Insert();
        Head.Code := 'H2';
        Head.Insert();
        AddRow('H1', 10, Row."Doc Type"::"Inbound Document", Database::"PG LV Head");
        AddRow('H1', 20, Row."Doc Type"::"Outbound Document", Database::"PG LV Row");
        AddRow('H1', 30, Row."Doc Type"::Memo, 0);
        AddRow('H1', 40, Row."Doc Type"::"Inbound Document", Database::"PG LV Row");
        AddRow('H1', 50, Row."Doc Type"::"Outbound Document", Page::"PG LV Rows");
        AddRow('H2', 10, Row."Doc Type"::"Outbound Document", Database::"PG LV Head");
    end;

    local procedure AddRow(HeadCode: Code[10]; LineNo: Integer; DocType: Enum "PG LV Doc Type"; TableNo: Integer)
    var
        Row: Record "PG LV Row";
    begin
        Row.Init();
        Row."Head Code" := HeadCode;
        Row."Line No." := LineNo;
        Row."Doc Type" := DocType;
        Row."Record Table No." := TableNo;
        Row.Insert();
    end;

    local procedure OpenHost(var Card: TestPage "PG LV Host")
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('H1');
    end;

    // The numbers of the two tables and the page, so that the filter texts below can be read.
    [Test]
    procedure ObjectNumbers_OfTheConstants()
    begin
        Observer.Observe('head table', Format(Database::"PG LV Head"));
        Observer.Observe('row table', Format(Database::"PG LV Row"));
        Observer.Observe('rows page', Format(Page::"PG LV Rows"));
        Observer.Finish();
    end;


    [Test]
    procedure Part_NeQual_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.NeQual.First() then
            repeat
                Rows += Card.NeQual."Line No.".Value + ' ';
            until not Card.NeQual.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.NeQual.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.NeQual.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_EqQual_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.EqQual.First() then
            repeat
                Rows += Card.EqQual."Line No.".Value + ' ';
            until not Card.EqQual.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.EqQual.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.EqQual.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_OrQual_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.OrQual.First() then
            repeat
                Rows += Card.OrQual."Line No.".Value + ' ';
            until not Card.OrQual.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.OrQual.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.OrQual.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_NePlain_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.NePlain.First() then
            repeat
                Rows += Card.NePlain."Line No.".Value + ' ';
            until not Card.NePlain.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.NePlain.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.NePlain.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_ConstQual_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.ConstQual.First() then
            repeat
                Rows += Card.ConstQual."Line No.".Value + ' ';
            until not Card.ConstQual.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.ConstQual.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.ConstQual.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_NeQualView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.NeQualView.First() then
            repeat
                Rows += Card.NeQualView."Line No.".Value + ' ';
            until not Card.NeQualView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.NeQualView.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.NeQualView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_OrQualView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.OrQualView.First() then
            repeat
                Rows += Card.OrQualView."Line No.".Value + ' ';
            until not Card.OrQualView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.OrQualView.Filter.GetFilter("Doc Type") + ']');
        Observer.Observe('head filter', '[' + Card.OrQualView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbFilterView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbFilterView.First() then
            repeat
                Rows += Card.DbFilterView."Line No.".Value + ' ';
            until not Card.DbFilterView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbFilterView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbFilterView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbConstView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbConstView.First() then
            repeat
                Rows += Card.DbConstView."Line No.".Value + ' ';
            until not Card.DbConstView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbConstView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbConstView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbNeView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbNeView.First() then
            repeat
                Rows += Card.DbNeView."Line No.".Value + ' ';
            until not Card.DbNeView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbNeView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbNeView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbOrView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbOrView.First() then
            repeat
                Rows += Card.DbOrView."Line No.".Value + ' ';
            until not Card.DbOrView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbOrView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbOrView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbFilterLink_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbFilterLink.First() then
            repeat
                Rows += Card.DbFilterLink."Line No.".Value + ' ';
            until not Card.DbFilterLink.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbFilterLink.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbFilterLink.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_DbConstLink_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.DbConstLink.First() then
            repeat
                Rows += Card.DbConstLink."Line No.".Value + ' ';
            until not Card.DbConstLink.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.DbConstLink.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.DbConstLink.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_PageConstView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.PageConstView.First() then
            repeat
                Rows += Card.PageConstView."Line No.".Value + ' ';
            until not Card.PageConstView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.PageConstView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.PageConstView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_PageFilterView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
        Rows: Text;
    begin
        OpenHost(Card);
        if Card.PageFilterView.First() then
            repeat
                Rows += Card.PageFilterView."Line No.".Value + ' ';
            until not Card.PageFilterView.Next();
        Observer.Observe('rows', '[' + Rows + ']');
        Observer.Observe('filter', '[' + Card.PageFilterView.Filter.GetFilter("Record Table No.") + ']');
        Observer.Observe('head filter', '[' + Card.PageFilterView.Filter.GetFilter("Head Code") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure Action_RunNeQual_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
    begin
        OpenHost(Card);
        RunRows := 'handler not called';
        Card.RunNeQual.Invoke();
        Observer.Observe('rows', '[' + RunRows + ']');
        Observer.Observe('type filter', '[' + RunTypeFilter + ']');
        Observer.Observe('table filter', '[' + RunTableFilter + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure Action_RunDbFilterLink_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
    begin
        OpenHost(Card);
        RunRows := 'handler not called';
        Card.RunDbFilterLink.Invoke();
        Observer.Observe('rows', '[' + RunRows + ']');
        Observer.Observe('type filter', '[' + RunTypeFilter + ']');
        Observer.Observe('table filter', '[' + RunTableFilter + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure Action_RunDbFilterView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
    begin
        OpenHost(Card);
        RunRows := 'handler not called';
        Card.RunDbFilterView.Invoke();
        Observer.Observe('rows', '[' + RunRows + ']');
        Observer.Observe('type filter', '[' + RunTypeFilter + ']');
        Observer.Observe('table filter', '[' + RunTableFilter + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure Action_RunNeQualView_RowsAndFilter()
    var
        Card: TestPage "PG LV Host";
    begin
        OpenHost(Card);
        RunRows := 'handler not called';
        Card.RunNeQualView.Invoke();
        Observer.Observe('rows', '[' + RunRows + ']');
        Observer.Observe('type filter', '[' + RunTypeFilter + ']');
        Observer.Observe('table filter', '[' + RunTableFilter + ']');
        Card.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure RowListHandler(var List: TestPage "PG LV Row List")
    begin
        RunRows := '';
        if List.First() then
            repeat
                RunRows += List."Line No.".Value + ' ';
            until not List.Next();
        RunTypeFilter := List.Filter.GetFilter("Doc Type");
        RunTableFilter := List.Filter.GetFilter("Record Table No.");
        List.Close();
    end;
}
