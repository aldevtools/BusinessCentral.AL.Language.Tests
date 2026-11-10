// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-last-method
// Scope: in-scope (Cloud). TestPage; ModalPageHandler with a TestPage.
// local object: the row count against the client's window of rows, the lookup mode and the tree repeater are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63430, log codeunit 63431, pages 63432 and 63433, test codeunit 63439
// Probe (al-runner issues 7475 and 7421): lists that hold more rows than the test client reads when the page opens.
//   7475: TestPage.Last() on a list of 41, 61 and 100 rows: opened with OpenView and OpenEdit, run modally from a Page variable with
//   Editable(false) and LookupMode(true) (then GetRecord), and with Page.RunModal(Page::X, Rec). The reading is the result of Last(), the row
//   shown, the row Previous() goes to, the rows OnAfterGetRecord read (as runs), the returned Action and the record the caller gets.
//   7421: TestPage.OpenView of a tree (ShowAsTree, a temporary source that OnOpenPage fills, as page "Manual Setup" does) with 15 and 60 rows:
//   whether it opens, the row shown, how many rows First / Next walk through, the last of them, and the rows read at the open.
//   Already pinned: testpage/ListRowsWindow.al (GoToKey to the last row of 41, 60 and 61 rows), pages/list-key-navigation/SgListKeyObjects.al
//   (Last over 30 rows), testpage/Y72TreeDefaultState.al (a tree of 6 rows), testpage/TwBlockEdge.al (GoToRecord in a lookup of 45 rows).
//   Log: the Id of every OnAfterGetRecord, written as runs (1..20 means the rows 1 to 20 in this order), with the number of reads in front.
// BC versions: 27, 28, 29

table 63430 "PNL LL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Indent; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 63431 "PNL LL Log"
{
    SingleInstance = true;

    var
        Ids: List of [Integer];
        TreeRows: Integer;

    procedure Add(Id: Integer)
    begin
        Ids.Add(Id);
    end;

    procedure SetTreeRows(Count: Integer)
    begin
        TreeRows := Count;
    end;

    procedure GetTreeRows(): Integer
    begin
        exit(TreeRows);
    end;

    // The reads as runs of consecutive ids (up or down), with the number of reads in front: "25: 1..20,41..45".
    procedure Take() Result: Text
    var
        Id: Integer;
        First: Integer;
        Previous: Integer;
        Step: Integer;
        Index: Integer;
    begin
        Result := Format(Ids.Count()) + ': ';
        for Index := 1 to Ids.Count() do begin
            Id := Ids.Get(Index);
            if Index = 1 then begin
                First := Id;
                Step := 0;
            end else
                if (Step = 0) and (Abs(Id - Previous) = 1) then
                    Step := Id - Previous
                else
                    if (Step = 0) or (Id - Previous <> Step) then begin
                        Result += RunText(First, Previous) + ',';
                        First := Id;
                        Step := 0;
                    end;
            Previous := Id;
        end;
        if Ids.Count() > 0 then
            Result += RunText(First, Previous);
        Clear(Ids);
    end;

    local procedure RunText(First: Integer; Last: Integer): Text
    begin
        if First = Last then
            exit(Format(First));
        exit(Format(First) + '..' + Format(Last));
    end;
}

page 63432 "PNL LL List"
{
    PageType = List;
    SourceTable = "PNL LL Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add(Rec.Id);
    end;

    var
        Log: Codeunit "PNL LL Log";
}

page 63433 "PNL LL Tree"
{
    PageType = List;
    SourceTable = "PNL LL Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indent;

                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    // Every fifth row (1, 6, 11, ...) is a parent at indentation 0, the four rows after it are its children at indentation 1.
    trigger OnOpenPage()
    var
        i: Integer;
    begin
        for i := 1 to Log.GetTreeRows() do begin
            Rec.Init();
            Rec.Id := i;
            Rec.Name := 'N' + Format(i);
            if i mod 5 = 1 then
                Rec.Indent := 0
            else
                Rec.Indent := 1;
            Rec.Insert();
        end;
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add(Rec.Id);
    end;

    var
        Log: Codeunit "PNL LL Log";
}

codeunit 63439 "PNL Last On Long List"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PNL LL Log";

    local procedure Initialize()
    var
        Row: Record "PNL LL Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Log.Take();
    end;

    local procedure Seed(Count: Integer)
    var
        Row: Record "PNL LL Row";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'N' + Format(i);
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryLast(var P: TestPage "PNL LL List"; var Moved: Boolean)
    begin
        Moved := P.Last();
    end;

    [TryFunction]
    local procedure TryPrevious(var P: TestPage "PNL LL List"; var Moved: Boolean)
    begin
        Moved := P.Previous();
    end;

    local procedure LastAndPrevious(var P: TestPage "PNL LL List")
    var
        Moved: Boolean;
    begin
        Observer.Observe('opened on', P.Id.Value());
        Observer.Observe('reads of the open', Log.Take());
        if TryLast(P, Moved) then
            Observer.Observe('Last', Format(Moved))
        else
            Observer.ObserveError('Last error');
        Observer.Observe('shown after Last', P.Id.Value());
        Observer.Observe('reads of Last', Log.Take());
        if TryPrevious(P, Moved) then
            Observer.Observe('Previous', Format(Moved))
        else
            Observer.ObserveError('Previous error');
        Observer.Observe('shown after Previous', P.Id.Value());
        Observer.Observe('reads of Previous', Log.Take());
    end;

    local procedure OpenViewLast(Count: Integer)
    var
        P: TestPage "PNL LL List";
    begin
        Seed(Count);
        P.OpenView();
        LastAndPrevious(P);
        P.Close();
    end;

    [Test]
    procedure OpenView_41Rows_Last()
    begin
        Initialize();
        OpenViewLast(41);
        Observer.Finish();
    end;

    [Test]
    procedure OpenView_61Rows_Last()
    begin
        Initialize();
        OpenViewLast(61);
        Observer.Finish();
    end;

    [Test]
    procedure OpenView_100Rows_Last()
    begin
        Initialize();
        OpenViewLast(100);
        Observer.Finish();
    end;

    [Test]
    procedure OpenEdit_100Rows_Last()
    var
        P: TestPage "PNL LL List";
    begin
        Initialize();
        Seed(100);
        P.OpenEdit();
        LastAndPrevious(P);
        P.Close();
        Observer.Finish();
    end;

    local procedure LookupVariableLast(Count: Integer)
    var
        Row: Record "PNL LL Row";
        List: Page "PNL LL List";
        Result: Action;
    begin
        // The reporter's steps of issue 7475.
        Seed(Count);
        List.Editable(false);
        List.LookupMode(true);
        Result := List.RunModal();
        Observer.Observe('action', Format(Result));
        List.GetRecord(Row);
        Observer.Observe('GetRecord', Format(Row.Id));
        Observer.Observe('reads after the handler', Log.Take());
    end;

    [Test]
    [HandlerFunctions('LastThenOkHandler')]
    procedure LookupVariable_41Rows_Last_GetRecord()
    begin
        Initialize();
        LookupVariableLast(41);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LastThenOkHandler')]
    procedure LookupVariable_61Rows_Last_GetRecord()
    begin
        Initialize();
        LookupVariableLast(61);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LastThenOkHandler')]
    procedure LookupVariable_100Rows_Last_GetRecord()
    begin
        Initialize();
        LookupVariableLast(100);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LastThenOkHandler')]
    procedure StaticRunModal_100Rows_Last_RecAfter()
    var
        Row: Record "PNL LL Row";
        Result: Action;
    begin
        Initialize();
        Seed(100);
        Result := Page.RunModal(Page::"PNL LL List", Row);
        Observer.Observe('action', Format(Result));
        Observer.Observe('rec after', Format(Row.Id));
        Observer.Observe('reads after the handler', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LastThenOkHandler(var P: TestPage "PNL LL List")
    begin
        Observer.Observe('editable', Format(P.Editable()));
        LastAndPrevious(P);
        P.Last();
        Log.Take();
        P.OK().Invoke();
    end;

    // ---- issue 7421: a tree over a temporary source with more rows than the open reads ----

    [TryFunction]
    local procedure TryOpenTree(var P: TestPage "PNL LL Tree")
    begin
        P.OpenView();
    end;

    local procedure OpenTree(Count: Integer)
    var
        P: TestPage "PNL LL Tree";
        Walked: Integer;
        LastId: Text;
    begin
        Log.SetTreeRows(Count);
        if not TryOpenTree(P) then begin
            Observer.ObserveError('open error');
            exit;
        end;
        Observer.Observe('opened on', P.Id.Value());
        Observer.Observe('reads of the open', Log.Take());
        if P.First() then
            repeat
                Walked += 1;
                LastId := P.Id.Value();
            until not P.Next();
        Observer.Observe('rows walked', Format(Walked));
        Observer.Observe('last row walked', LastId);
        Observer.Observe('reads of the walk', Log.Take());
        P.Close();
    end;

    [Test]
    procedure Tree_TempSource_15Rows_OpenView_Walk()
    begin
        Initialize();
        OpenTree(15);
        Observer.Finish();
    end;

    [Test]
    procedure Tree_TempSource_60Rows_OpenView_Walk()
    begin
        Initialize();
        OpenTree(60);
        Observer.Finish();
    end;
}
