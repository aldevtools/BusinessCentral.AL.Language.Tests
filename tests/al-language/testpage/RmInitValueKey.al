// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88277 - 88282 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a page opened without a record whose SourceTableView sorts by a secondary key (SortOrder), over a table whose primary key
//   ("Group Code", Kind, "Line No.") has an InitValue on Kind (B): Rec stands on the primary key ('', B, 0), which no row has, when the page
//   opens; OnOpenPage does not touch Rec. Which row the page opens on, which triggers ran (log: R:<line> = OnAfterGetRecord,
//   C:<line> = OnAfterGetCurrRecord), and where Next and GoToRecord go. List ascending and descending, Card; OpenEdit, OpenView, Page.Run,
//   Page.RunModal; and the same List when a row with the primary key ('', B, 0) exists.
//   Rows of group G: (A,1,SortOrder 20) (B,2,10) (C,3,30) (A,4,-5). Ascending view order: 4, 2, 1, 3.
// Result (BC 27.5, 28.5, 29.0 alike): a List opened with OpenEdit, OpenView or Page.Run opens on the first row of the view (Line No. 4,
//   SortOrder -5; descending: 3), not on the row a search from Rec's SortOrder 0 would reach; run modally it opens on Line No. 2. When a row
//   ('', B, 0) exists the List opens on it. A Card opens on the first row of the view (4) with OpenEdit and run modally.
// Source: al-runner issue 5760.
// BC versions: 27, 28, 29

table 88277 "LT RM Init Key Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[20]) { }
        field(2; Kind; Option)
        {
            OptionMembers = A,B,C;
            InitValue = B;
        }
        field(3; "Line No."; Integer) { }
        field(4; SortOrder; Integer) { }
    }

    keys
    {
        key(PK; "Group Code", Kind, "Line No.") { Clustered = true; }
        key(BySortOrder; SortOrder) { }
    }
}

page 88278 "LT RM Init Key List"
{
    PageType = List;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(ascending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(SortOrderCtl; Rec.SortOrder) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

page 88279 "LT RM Init Key List Desc"
{
    PageType = List;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(descending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(SortOrderCtl; Rec.SortOrder) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

page 88280 "LT RM Init Key Card"
{
    PageType = Card;
    SourceTable = "LT RM Init Key Line";
    SourceTableView = sorting(SortOrder) order(ascending);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(LineNoCtl; Rec."Line No.") { }
            field(SortOrderCtl; Rec.SortOrder) { }
        }
    }

    trigger OnOpenPage()
    begin
        Opened := true;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RM Init Key Log";
        Opened: Boolean;
}

codeunit 88281 "LT RM Init Key Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 88282 "LT RM Init Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Init Key Log";

    local procedure Seed(WithInitRow: Boolean)
    var
        Line: Record "LT RM Init Key Line";
    begin
        Line.DeleteAll();
        InsertLine('G', Line.Kind::A, 1, 20);
        InsertLine('G', Line.Kind::B, 2, 10);
        InsertLine('G', Line.Kind::C, 3, 30);
        InsertLine('G', Line.Kind::A, 4, -5);
        if WithInitRow then
            InsertLine('', Line.Kind::B, 0, 15);
        Log.Reset();
    end;

    local procedure InsertLine(GroupCode: Code[20]; Kind: Option; LineNo: Integer; SortOrder: Integer)
    var
        Line: Record "LT RM Init Key Line";
    begin
        Line."Group Code" := GroupCode;
        Line.Kind := Kind;
        Line."Line No." := LineNo;
        Line.SortOrder := SortOrder;
        Line.Insert();
    end;

    local procedure ObserveList(var Lines: TestPage "LT RM Init Key List")
    var
        Line: Record "LT RM Init Key Line";
    begin
        Observer.Observe('open', Lines.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Lines.Next()) + '|' + Lines.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Line.Get('G', Line.Kind::C, 3);
        Lines.GoToRecord(Line);
        Observer.Observe('goto', Lines.LineNoCtl.Value());
        Observer.Observe('goto log', Log.Take());
        Observer.Observe('first', Format(Lines.First()) + '|' + Lines.LineNoCtl.Value());
    end;

    [Test]
    procedure RM_List_OpenEdit()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.OpenEdit();
        ObserveList(Lines);
        Lines.Close();
        Observer.Expect('open', '4');
        Observer.Expect('open log', 'R:4;R:2;R:1;R:3;R:4;R:4;R:4;C:4;');
        Observer.Expect('next', 'Yes|2');
        Observer.Expect('next log', 'R:2;R:2;R:2;C:2;');
        Observer.Expect('goto', '3');
        Observer.Expect('goto log', 'R:4;R:4;R:4;C:4;R:2;R:2;R:2;C:2;R:1;R:1;R:1;C:1;R:3;R:3;R:3;C:3;');
        Observer.Expect('first', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    procedure RM_List_OpenView()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.OpenView();
        ObserveList(Lines);
        Lines.Close();
        Observer.Expect('open', '4');
        Observer.Expect('open log', 'R:4;R:2;R:1;R:3;R:4;R:4;R:4;C:4;');
        Observer.Expect('next', 'Yes|2');
        Observer.Expect('next log', 'R:2;R:2;R:2;C:2;');
        Observer.Expect('goto', '3');
        Observer.Expect('goto log', 'R:4;R:4;R:4;C:4;R:2;R:2;R:2;C:2;R:1;R:1;R:1;C:1;R:3;R:3;R:3;C:3;');
        Observer.Expect('first', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    procedure RM_List_PageRun()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(false);
        Lines.Trap();
        Page.Run(Page::"LT RM Init Key List");
        ObserveList(Lines);
        Lines.Close();
        Observer.Expect('open', '4');
        Observer.Expect('open log', 'R:4;R:2;R:1;R:3;R:4;R:4;R:4;C:4;');
        Observer.Expect('next', 'Yes|2');
        Observer.Expect('next log', 'R:2;R:2;R:2;C:2;');
        Observer.Expect('goto', '3');
        Observer.Expect('goto log', 'R:4;R:4;R:4;C:4;R:2;R:2;R:2;C:2;R:1;R:1;R:1;C:1;R:3;R:3;R:3;C:3;');
        Observer.Expect('first', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure RM_List_RunModal()
    begin
        Seed(false);
        Page.RunModal(Page::"LT RM Init Key List");
        Observer.Expect('open', '2');
        Observer.Expect('open log', 'R:2;R:1;R:3;R:2;R:4;R:2;R:2;R:2;C:2;');
        Observer.Expect('next', 'Yes|1');
        Observer.Expect('next log', 'R:1;R:1;R:1;C:1;');
        Observer.Expect('goto', '3');
        Observer.Expect('goto log', 'R:4;R:4;R:4;C:4;R:2;R:2;R:2;C:2;R:1;R:1;R:1;C:1;R:3;R:3;R:3;C:3;');
        Observer.Expect('first', 'Yes|4');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var Lines: TestPage "LT RM Init Key List")
    begin
        ObserveList(Lines);
    end;

    [Test]
    procedure RM_List_OpenEdit_InitKeyRowExists()
    var
        Lines: TestPage "LT RM Init Key List";
    begin
        Seed(true);
        Lines.OpenEdit();
        ObserveList(Lines);
        Lines.Close();
        Observer.Expect('open', '0');
        Observer.Expect('open log', 'R:0;R:0;R:1;R:3;R:0;R:2;R:4;R:0;R:0;R:0;C:0;');
        Observer.Expect('next', 'Yes|1');
        Observer.Expect('next log', 'R:1;R:1;R:1;C:1;');
        Observer.Expect('goto', '3');
        Observer.Expect('goto log', 'R:4;R:4;R:4;C:4;R:2;R:2;R:2;C:2;R:0;R:0;R:0;C:0;R:1;R:1;R:1;C:1;R:3;R:3;R:3;C:3;');
        Observer.Expect('first', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    procedure RM_ListDesc_OpenEdit()
    var
        Lines: TestPage "LT RM Init Key List Desc";
    begin
        Seed(false);
        Lines.OpenEdit();
        Observer.Observe('open', Lines.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Lines.Next()) + '|' + Lines.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Lines.Close();
        Observer.Expect('open', '3');
        Observer.Expect('open log', 'R:3;R:1;R:2;R:4;R:3;R:3;R:3;C:3;');
        Observer.Expect('next', 'Yes|1');
        Observer.Expect('next log', 'R:1;R:1;R:1;C:1;');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Card_OpenEdit()
    var
        Card: TestPage "LT RM Init Key Card";
    begin
        Seed(false);
        Card.OpenEdit();
        Observer.Observe('open', Card.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Card.Next()) + '|' + Card.LineNoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Card.Close();
        Observer.Expect('open', '4');
        Observer.Expect('open log', 'R:4;C:4;');
        Observer.Expect('next', 'Yes|2');
        Observer.Expect('next log', 'R:2;C:2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure RM_Card_RunModal()
    begin
        Seed(false);
        Page.RunModal(Page::"LT RM Init Key Card");
        Observer.Expect('open', '4');
        Observer.Expect('open log', 'R:4;C:4;');
        Observer.Expect('next', 'Yes|2');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT RM Init Key Card")
    begin
        Observer.Observe('open', Card.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(Card.Next()) + '|' + Card.LineNoCtl.Value());
    end;
}
