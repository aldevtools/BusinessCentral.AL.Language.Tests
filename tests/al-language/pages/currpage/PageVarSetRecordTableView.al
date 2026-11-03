// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-settableview-method
// Scope: in-scope
// Fixtures used: LT STV Row (70374), LT STV List (70375), LT STV Card (70376)
//
// On a Page VARIABLE, which record does the page open on, and which filters does it carry, when
// SetRecord(Entry) and SetTableView(Entry) are both called, in either order? A modal handler
// reads the current row (before any First()), the page's own GetFilters text, then walks the rows.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Writer SF (al-runtime-rs assumption set-table-view-keeps-set-record-position): SF_ tests, pages 89063 and 89064 note the Rec OnOpenPage reads.
//   Facts (corpus CI 27.5, 28.5, 29.0 agree): in either order, OnOpenPage reads Rec as the record SetRecord handed over (also when it is
//   outside the view) with the view's filters; the position of the SetTableView record is not used. The page then shows the first row of
//   the view at or after that record.
// BC versions: 29 (27 and 28 by CI)

table 70374 "LT STV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 70375 "LT STV List"
{
    PageType = List;
    SourceTable = "LT STV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(RowGrp; Rec.Grp) { ApplicationArea = All; }
                field(Flt; FiltersTxt) { ApplicationArea = All; }
            }
        }
    }

    var
        FiltersTxt: Text;

    trigger OnOpenPage()
    begin
        FiltersTxt := Rec.GetFilters();
    end;
}

page 70376 "LT STV Card"
{
    PageType = Card;
    SourceTable = "LT STV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(RowGrp; Rec.Grp) { ApplicationArea = All; }
                field(Flt; FiltersTxt) { ApplicationArea = All; }
            }
        }
    }

    var
        FiltersTxt: Text;

    trigger OnOpenPage()
    begin
        FiltersTxt := Rec.GetFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FiltersTxt := Rec.GetFilters();
    end;
}

codeunit 70377 "LT STV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;
        CurrentRow: Text;
        FilterText: Text;
        Rows: Integer;
        OpenRecText: Text;

    local procedure Seed()
    var
        Row: Record "LT STV Row";
    begin
        Row.DeleteAll();
        Seen := '';
        CurrentRow := '';
        FilterText := '';
        Rows := 0;
        Add('A', 1);
        Add('B', 2);
        Add('C', 1);
        Add('D', 2);
        Add('E', 1);
    end;

    local procedure Add(No: Code[20]; Grp: Integer)
    var
        Row: Record "LT STV Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Grp := Grp;
        Row.Insert();
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('currentRow', CurrentRow);
        Observer.Observe('filterField', FilterText);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('seen', Seen);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetRecordOnly()
    var
        Row: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('C');
        ListPage.SetRecord(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'C');
        Observer.Expect('filterField', '');
        Observer.Expect('rows', '6');
        Observer.Expect('seen', '[A][B][C][D][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetTableViewOnly()
    var
        Row: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange(Grp, 2);
        ListPage.SetTableView(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'B');
        Observer.Expect('filterField', 'Grp: 2');
        Observer.Expect('rows', '3');
        Observer.Expect('seen', '[B][D][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetRecordThenSetTableView_RecordInsideView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('C');
        Filtered.SetRange(Grp, 1);
        ListPage.SetRecord(Row);
        ListPage.SetTableView(Filtered);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'C');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetRecordThenSetTableView_RecordOutsideView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('B');
        Filtered.SetRange(Grp, 1);
        ListPage.SetRecord(Row);
        ListPage.SetTableView(Filtered);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'C');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetTableViewThenSetRecord_RecordInsideView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('C');
        Filtered.SetRange(Grp, 1);
        ListPage.SetTableView(Filtered);
        ListPage.SetRecord(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'C');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetTableViewThenSetRecord_RecordOutsideView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('B');
        Filtered.SetRange(Grp, 1);
        ListPage.SetTableView(Filtered);
        ListPage.SetRecord(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'C');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetRecordCarriesItsOwnFilter_ThenSetTableView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange(Grp, 2);
        Row.Get('D');
        Filtered.SetRange(Grp, 1);
        ListPage.SetRecord(Row);
        ListPage.SetTableView(Filtered);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'E');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetTableViewEntryIsTheSameRecord()
    var
        Row: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        // SetTableView(Entry) with the very record passed to SetRecord(Entry): the Base Application shape.
        Seed();
        Row.SetRange(Grp, 1);
        Row.Get('E');
        ListPage.SetRecord(Row);
        ListPage.SetTableView(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'E');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure P157_List_SetTableViewEntryIsTheSameRecord_Reverse()
    var
        Row: Record "LT STV Row";
        ListPage: Page "LT STV List";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange(Grp, 1);
        Row.Get('E');
        ListPage.SetTableView(Row);
        ListPage.SetRecord(Row);
        ListPage.RunModal();
        Report(Observer);
        Observer.Expect('currentRow', 'E');
        Observer.Expect('filterField', 'Grp: 1');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P157_Card_SetRecordThenSetTableView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        CardPage: Page "LT STV Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('D');
        Filtered.SetRange(Grp, 2);
        CardPage.SetRecord(Row);
        CardPage.SetTableView(Filtered);
        CardPage.RunModal();
        Observer.Observe('currentRow', CurrentRow);
        Observer.Observe('filterField', FilterText);
        Observer.Expect('currentRow', 'D');
        Observer.Expect('filterField', 'Grp: 2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P157_Card_SetTableViewThenSetRecord()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        CardPage: Page "LT STV Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('D');
        Filtered.SetRange(Grp, 2);
        CardPage.SetTableView(Filtered);
        CardPage.SetRecord(Row);
        CardPage.RunModal();
        Observer.Observe('currentRow', CurrentRow);
        Observer.Observe('filterField', FilterText);
        Observer.Expect('currentRow', 'D');
        Observer.Expect('filterField', 'Grp: 2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure P157_Card_SetRecordOutsideView()
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        CardPage: Page "LT STV Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get('A');
        Filtered.SetRange(Grp, 2);
        CardPage.SetRecord(Row);
        CardPage.SetTableView(Filtered);
        CardPage.RunModal();
        Observer.Observe('currentRow', CurrentRow);
        Observer.Observe('filterField', FilterText);
        Observer.Expect('currentRow', 'B');
        Observer.Expect('filterField', 'Grp: 2');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ListHandler(var TP: TestPage "LT STV List")
    begin
        CurrentRow := TP.RowNo.Value();
        FilterText := TP.Flt.Value();
        if TP.First() then
            repeat
                Rows += 1;
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;

    [ModalPageHandler]
    procedure CardHandler(var TP: TestPage "LT STV Card")
    begin
        CurrentRow := TP.RowNo.Value();
        FilterText := TP.Flt.Value();
    end;

    // ---- writer SF (al-runtime-rs assumption set-table-view-keeps-set-record-position): what Rec holds in OnOpenPage when SetRecord(A)
    //      and SetTableView(B) are both called and B has a filter and another position than A, in both orders. ----

    local procedure SfReport(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('onOpenPage', OpenRecText);
        Observer.Observe('currentRow', CurrentRow);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('seen', Seen);
    end;

    local procedure SfRun(var Observer: Codeunit "Probe Observer"; RecNo: Code[20]; ViewGrp: Integer; SetRecordFirst: Boolean; UseCard: Boolean)
    var
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT SF STV List";
        CardPage: Page "LT SF STV Card";
    begin
        Seed();
        OpenRecText := '';
        Row.Get(RecNo);
        Filtered.SetRange(Grp, ViewGrp);
        Filtered.FindLast();
        Observer.Observe('viewPosition', Filtered."No.");
        if UseCard then begin
            if SetRecordFirst then begin
                CardPage.SetRecord(Row);
                CardPage.SetTableView(Filtered);
            end else begin
                CardPage.SetTableView(Filtered);
                CardPage.SetRecord(Row);
            end;
            CardPage.RunModal();
        end else begin
            if SetRecordFirst then begin
                ListPage.SetRecord(Row);
                ListPage.SetTableView(Filtered);
            end else begin
                ListPage.SetTableView(Filtered);
                ListPage.SetRecord(Row);
            end;
            ListPage.RunModal();
        end;
        SfReport(Observer);
    end;

    [Test]
    [HandlerFunctions('SfListHandler')]
    procedure SF_List_SetRecordThenSetTableView_RecordInsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'C', 1, true, false);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=C grp=1 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfListHandler')]
    procedure SF_List_SetTableViewThenSetRecord_RecordInsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'C', 1, false, false);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=C grp=1 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfListHandler')]
    procedure SF_List_SetRecordThenSetTableView_RecordOutsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'B', 1, true, false);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=B grp=2 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfListHandler')]
    procedure SF_List_SetTableViewThenSetRecord_RecordOutsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'B', 1, false, false);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=B grp=2 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '4');
        Observer.Expect('seen', '[A][C][E][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfCardHandler')]
    procedure SF_Card_SetRecordThenSetTableView_RecordInsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'C', 1, true, true);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=C grp=1 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfCardHandler')]
    procedure SF_Card_SetTableViewThenSetRecord_RecordInsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'C', 1, false, true);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=C grp=1 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SfCardHandler')]
    procedure SF_Card_SetRecordThenSetTableView_RecordOutsideView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SfRun(Observer, 'B', 1, true, true);
        Observer.Expect('viewPosition', 'E');
        Observer.Expect('onOpenPage', 'no=B grp=2 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Expect('rows', '0');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    // Page.Run (not modal) of the page variable, trapped.
    [Test]
    procedure SF_List_SetRecordThenSetTableView_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT STV Row";
        Filtered: Record "LT STV Row";
        ListPage: Page "LT SF STV List";
        TP: TestPage "LT SF STV List";
    begin
        Seed();
        Row.Get('C');
        Filtered.SetRange(Grp, 1);
        Filtered.FindLast();
        ListPage.SetRecord(Row);
        ListPage.SetTableView(Filtered);
        TP.Trap();
        ListPage.Run();
        Observer.Observe('onOpenPage', TP.OpenRec.Value());
        Observer.Observe('currentRow', TP.RowNo.Value());
        TP.Close();
        Observer.Expect('onOpenPage', 'no=C grp=1 filters=Grp: 1');
        Observer.Expect('currentRow', 'C');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure SfListHandler(var TP: TestPage "LT SF STV List")
    begin
        OpenRecText := TP.OpenRec.Value();
        CurrentRow := TP.RowNo.Value();
        if TP.First() then
            repeat
                Rows += 1;
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;

    [ModalPageHandler]
    procedure SfCardHandler(var TP: TestPage "LT SF STV Card")
    begin
        OpenRecText := TP.OpenRec.Value();
        CurrentRow := TP.RowNo.Value();
    end;
}

// Writer SF: the list and card above with OnOpenPage noting the record it reads (No., Grp and filters) in a control.
page 89063 "LT SF STV List"
{
    PageType = List;
    SourceTable = "LT STV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(RowGrp; Rec.Grp) { ApplicationArea = All; }
                field(OpenRec; OpenRecText) { ApplicationArea = All; }
            }
        }
    }

    var
        OpenRecText: Text;

    trigger OnOpenPage()
    begin
        OpenRecText := 'no=' + Rec."No." + ' grp=' + Format(Rec.Grp) + ' filters=' + Rec.GetFilters();
    end;
}

page 89064 "LT SF STV Card"
{
    PageType = Card;
    SourceTable = "LT STV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(RowGrp; Rec.Grp) { ApplicationArea = All; }
                field(OpenRec; OpenRecText) { ApplicationArea = All; }
            }
        }
    }

    var
        OpenRecText: Text;

    trigger OnOpenPage()
    begin
        OpenRecText := 'no=' + Rec."No." + ' grp=' + Format(Rec.Grp) + ' filters=' + Rec.GetFilters();
    end;
}
