// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 95670, list page 95671 (SourceTableTemporary not set), test codeunit 95672
// Probe (al-runner issue 7018): Page.Run(Id, TempRec) and Page.RunModal(Id, TempRec) of a list page over a stored source table, with a
//   temporary record of that table, answered by a Page-typed PageHandler / ModalPageHandler (`var Pg: Page ".."`). The table also has a
//   stored row. Logged by the handler: GetRecord into a temporary record, the Count, the current row and IsTemporary of the page's Rec.
//   Then the caller's temporary record (row, count) and the stored rows.
// local object: the page's source table and its methods are under test
// Seen on BC 29 (Linux CI): the page's Rec becomes temporary and shares the caller's rows, filters and current row (stored rows stay
//   out); the caller keeps its row and count; RunModal answers LookupOK.
// BC versions: 27-29

table 95670 "LT THS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; Msg; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 95671 "LT THS List"
{
    PageType = List;
    SourceTable = "LT THS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure RowCount(): Integer
    begin
        exit(Rec.Count());
    end;

    procedure CurId(): Integer
    begin
        exit(Rec.Id);
    end;

    procedure IsTemp(): Boolean
    begin
        exit(Rec.IsTemporary());
    end;
}

codeunit 95672 "LT THS Tests"
{
    Subtype = Test;

    var
        Seen: Text;

    local procedure Fill(var Temp: Record "LT THS Row" temporary)
    var
        Stored: Record "LT THS Row";
    begin
        Stored.DeleteAll();
        Stored.Id := 9;
        Stored.Msg := 'db';
        Stored.Insert();
        Temp.Id := 1;
        Temp.Msg := 'a';
        Temp.Insert();
        Temp.Id := 2;
        Temp.Msg := 'b';
        Temp.Insert();
        Temp.Id := 3;
        Temp.Msg := 'c';
        Temp.Insert();
        Seen := '';
    end;

    local procedure ObserveAfter(var Observer: Codeunit "Probe Observer"; var Temp: Record "LT THS Row" temporary)
    var
        Stored: Record "LT THS Row";
    begin
        Observer.Observe('handler', Seen);
        Observer.Observe('caller id', Format(Temp.Id));
        Observer.Observe('caller count', Format(Temp.Count()));
        Observer.Observe('stored count', Format(Stored.Count()));
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure TypedPageHandler_TempRecordStoredSource_PageRun_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT THS Row" temporary;
    begin
        Fill(Temp);
        Temp.SetRange(Id, 2, 3);
        Temp.FindFirst();
        Page.Run(Page::"LT THS List", Temp);
        ObserveAfter(Observer, Temp);
        Observer.Expect('handler', 'got=2/b pagecount=2 cur=2 temp=Yes');
        Observer.Expect('caller id', '2');
        Observer.Expect('caller count', '2');
        Observer.Expect('stored count', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure TypedPageHandler_TempRecordStoredSource_PageRun_OnRowTwo()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT THS Row" temporary;
    begin
        Fill(Temp);
        Temp.Get(2);
        Page.Run(Page::"LT THS List", Temp);
        ObserveAfter(Observer, Temp);
        Observer.Expect('handler', 'got=2/b pagecount=3 cur=2 temp=Yes');
        Observer.Expect('caller id', '2');
        Observer.Expect('caller count', '3');
        Observer.Expect('stored count', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageH')]
    procedure TypedPageHandler_TempRecordStoredSource_PageRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT THS Row" temporary;
        Stored: Record "LT THS Row";
    begin
        Stored.DeleteAll();
        Stored.Id := 9;
        Stored.Insert();
        Seen := '';
        Page.Run(Page::"LT THS List", Temp);
        ObserveAfter(Observer, Temp);
        Observer.Expect('handler', 'got=0/ pagecount=0 cur=0 temp=Yes');
        Observer.Expect('caller id', '0');
        Observer.Expect('caller count', '0');
        Observer.Expect('stored count', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalH')]
    procedure TypedModalHandler_TempRecordStoredSource_PageRunModal_OnRowTwo()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT THS Row" temporary;
    begin
        Fill(Temp);
        Temp.Get(2);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT THS List", Temp)));
        ObserveAfter(Observer, Temp);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('handler', 'got=2/b pagecount=3 cur=2 temp=Yes');
        Observer.Expect('caller id', '2');
        Observer.Expect('caller count', '3');
        Observer.Expect('stored count', '1');
        Observer.Verify();
    end;

    local procedure Describe(var Pg: Page "LT THS List"): Text
    var
        Got: Record "LT THS Row" temporary;
    begin
        Pg.GetRecord(Got);
        exit('got=' + Format(Got.Id) + '/' + Got.Msg + ' pagecount=' + Format(Pg.RowCount()) + ' cur=' + Format(Pg.CurId()) +
            ' temp=' + Format(Pg.IsTemp()));
    end;

    [PageHandler]
    procedure PageH(var Pg: Page "LT THS List")
    begin
        Seen := Describe(Pg);
    end;

    [ModalPageHandler]
    procedure ModalH(var Pg: Page "LT THS List"; var Reply: Action)
    begin
        Seen := Describe(Pg);
        Reply := Action::LookupOK;
    end;
}
