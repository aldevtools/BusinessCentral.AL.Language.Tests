// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-view-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 95986 - 95989 (TP R6977 *)
// local object: the list pages' AutoSplitKey and InsertAllowed are what the test checks
// Probe: from al-runner issue 6977: an editable List (AutoSplitKey = true, InsertAllowed default) over 3 rows of header H1 (and 1 row of
//   H2), opened by Page.Run with a filtered record and handled by a PageHandler: View().Invoke(), then a First/Next walk (the rows it visits
//   and the count). Contrasts: the same without View(); the same list opened by TestPage.OpenEdit with a filter and then View(); opened by
//   TestPage.OpenView; and a second list with InsertAllowed = false.
// BC versions: 27, 28, 29

table 95986 "TP R6977 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[30]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}

page 95987 "TP R6977 Lines"
{
    PageType = List;
    SourceTable = "TP R6977 Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 95988 "TP R6977 Lines No Insert"
{
    PageType = List;
    SourceTable = "TP R6977 Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 95989 "TP R6977 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Visited: Text;
        UseView: Boolean;

    local procedure Initialize()
    var
        Line: Record "TP R6977 Line";
    begin
        Line.DeleteAll();
        InsertLine('H1', 10000, 'a');
        InsertLine('H1', 20000, 'b');
        InsertLine('H1', 30000, 'c');
        InsertLine('H2', 10000, 'z');
        Visited := '';
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer; Descr: Text[30])
    var
        Line: Record "TP R6977 Line";
    begin
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Description := Descr;
        Line.Insert();
    end;

    local procedure WalkLines(var Lines: TestPage "TP R6977 Lines")
    var
        Counter: Integer;
    begin
        if Lines.First() then
            repeat
                Counter += 1;
                Visited += Lines."Line No.".Value() + '/' + Lines.Description.Value() + ';';
            until not Lines.Next();
        Visited += ' n=' + Format(Counter);
    end;

    local procedure WalkNoInsert(var Lines: TestPage "TP R6977 Lines No Insert")
    var
        Counter: Integer;
    begin
        if Lines.First() then
            repeat
                Counter += 1;
                Visited += Lines."Line No.".Value() + '/' + Lines.Description.Value() + ';';
            until not Lines.Next();
        Visited += ' n=' + Format(Counter);
    end;

    local procedure StoredCount(): Text
    var
        Line: Record "TP R6977 Line";
    begin
        exit(Format(Line.Count()));
    end;

    [Test]
    [HandlerFunctions('LinesHandler')]
    procedure TP6977_PageRun_View_FirstNextWalk()
    var
        Line: Record "TP R6977 Line";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        UseView := true;
        Line.SetRange("Header No.", 'H1');
        Page.Run(Page::"TP R6977 Lines", Line);
        Observer.Observe('visited', Visited);
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LinesHandler')]
    procedure TP6977_PageRun_NoView_FirstNextWalk()
    var
        Line: Record "TP R6977 Line";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        UseView := false;
        Line.SetRange("Header No.", 'H1');
        Page.Run(Page::"TP R6977 Lines", Line);
        Observer.Observe('visited', Visited);
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NoInsertHandler')]
    procedure TP6977_PageRun_InsertNotAllowed_View_FirstNextWalk()
    var
        Line: Record "TP R6977 Line";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        UseView := true;
        Line.SetRange("Header No.", 'H1');
        Page.Run(Page::"TP R6977 Lines No Insert", Line);
        Observer.Observe('visited', Visited);
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [Test]
    procedure TP6977_OpenEditFiltered_View_FirstNextWalk()
    var
        Lines: TestPage "TP R6977 Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Lines.OpenEdit();
        Lines.Filter.SetFilter("Header No.", 'H1');
        Lines.View().Invoke();
        WalkLines(Lines);
        Lines.Close();
        Observer.Observe('visited', Visited);
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [Test]
    procedure TP6977_OpenViewFiltered_FirstNextWalk()
    var
        Lines: TestPage "TP R6977 Lines";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Lines.OpenView();
        Lines.Filter.SetFilter("Header No.", 'H1');
        WalkLines(Lines);
        Lines.Close();
        Observer.Observe('visited', Visited);
        Observer.Observe('stored', StoredCount());
        Observer.Finish();
    end;

    [PageHandler]
    procedure LinesHandler(var Lines: TestPage "TP R6977 Lines")
    begin
        if UseView then
            Lines.View().Invoke();
        WalkLines(Lines);
    end;

    [PageHandler]
    procedure NoInsertHandler(var Lines: TestPage "TP R6977 Lines No Insert")
    begin
        if UseView then
            Lines.View().Invoke();
        WalkNoInsert(Lines);
    end;
}
