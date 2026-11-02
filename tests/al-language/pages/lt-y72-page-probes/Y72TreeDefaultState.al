// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-expand-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93850; page 93850,93851,93852,93853; codeunit 93850
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a tree list (ShowAsTree = true, IndentationColumn = a page variable, no TreeInitialState) with row triggers: which rows the page
//   shows when it opens, what IsExpanded answers, what Expand(true) / Expand(false) add or hide, which row triggers run on open, on
//   Expand and on a move, and where Next / Previous / GoToKey land. Pages: PL (List over a stored table, OnAfterGetRecord and
//   OnAfterGetCurrRecord), PW (Worksheet over a temporary copy filled in OnOpenPage, OnAfterGetCurrRecord also calls Rec.Modify()),
//   PO (OnAfterGetRecord only), PC (OnAfterGetCurrRecord only).
//   Rows (Line No. / Grp / Indent): 10 A 0, 20 A 1, 30 A 1, 40 B 0, 50 B 1, 60 C 0.
//   Log format: agr <line> = OnAfterGetRecord, agcr <line> = OnAfterGetCurrRecord.
// Neighbours: pages/lt-page-runtime/TwTreeExpandTriggers.al (ExpandAll), pageext/lt-page-ext-properties/Y28CollapsedTreeTests.al
//   (CollapseAll), handlers/AhPageTests.al (a tree without row triggers).
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): the tree opens collapsed. Every row is read once at open (agr 10 .. agr 60), then the
//   first row again (agr 10; agr 10; agcr 10); IsExpanded is No and Next walks only the level-0 rows (10, 40, 60), each move running agr,
//   agr, agcr of the row it lands on. Expand(true) on a parent runs no trigger and keeps the row; Next then reaches the children (20, 30
//   after row 10; 50 after row 40) and skips the children of the collapsed rows; Expand(false) hides them again. GoToKey(40) reads all six
//   rows again and moves to 40. GoToKey to a child row (30) while its parent is collapsed finds no row (TestRowNotFound, the log shows the
//   walk over the visible rows and back to row 10). Expand(true) on a leaf row (60) raises nothing and IsExpanded stays No; Expand(false)
//   on a leaf row ends the test with an uncatchable CLR exception ("Expanding and collapsing are not supported on this rowEntry"), kept as
//   the non-test procedure Tree_CollapseLeafRow60. A Worksheet over a temporary copy filtered on Grp = A and expanded (the Order Planning
//   shape) shows rows 10, 20, 30 after the Grp filter and Expand(true) (the filter re-reads those three rows: agr 10; agr 20; agr 30; agr 10; agr 10; agcr 10); filtering
//   on a child's number lands on it (Qty and the page variable of that row). With only OnAfterGetRecord all rows are read at open
//   (agr 10 .. agr 60, agr 10) and the walk after Expand(true) logs nothing (the rows are not read again); with only OnAfterGetCurrRecord
//   open logs agcr 10 and the walk logs agcr of each row reached (20, 30, 40, 60). Expand(true) on an empty tree raises nothing. Last then
//   Previous walks the visible rows (60, 40, 10; with row 40 expanded 60, 50, 40, 10).
// BC versions: all (CI)

table 93850 "LT Y72 Tree Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Grp; Code[20]) { }
        field(4; Indent; Integer) { }
        field(5; Qty; Decimal) { }
    }

    keys { key(PK; "Line No.") { Clustered = true; } }
}

page 93850 "LT Y72 Tree PL"
{
    PageType = List;
    SourceTable = "LT Y72 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = IndentVar;
                IndentationControls = NoCtl;
                ShowAsTree = true;

                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(ShownCtl; Shown) { ApplicationArea = All; }
            }
        }
    }

    var
        IndentVar: Integer;
        Shown: Text;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        IndentVar := Rec.Indent;
        Shown := 'agr ' + Format(Rec."Line No.");
        Log.AddLine('agr ' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('agcr ' + Format(Rec."Line No."));
    end;
}

page 93851 "LT Y72 Tree PW"
{
    PageType = Worksheet;
    SourceTable = "LT Y72 Tree Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = IndentVar;
                IndentationControls = NoCtl;
                ShowAsTree = true;

                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
                field(ShownCtl; Shown) { ApplicationArea = All; }
            }
        }
    }

    var
        IndentVar: Integer;
        Shown: Text;

    trigger OnOpenPage()
    var
        Stored: Record "LT Y72 Tree Row";
    begin
        if Stored.FindSet() then
            repeat
                Rec := Stored;
                Rec.Insert();
            until Stored.Next() = 0;
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        IndentVar := Rec.Indent;
        Shown := 'agr ' + Format(Rec."Line No.");
        Log.AddLine('agr ' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('agcr ' + Format(Rec."Line No."));
        if Rec."Line No." <> 0 then
            Rec.Modify();
    end;
}

page 93852 "LT Y72 Tree PO"
{
    PageType = List;
    SourceTable = "LT Y72 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = IndentVar;
                IndentationControls = NoCtl;
                ShowAsTree = true;

                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    var
        IndentVar: Integer;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        IndentVar := Rec.Indent;
        Log.AddLine('agr ' + Format(Rec."Line No."));
    end;
}

page 93853 "LT Y72 Tree PC"
{
    PageType = List;
    SourceTable = "LT Y72 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                IndentationControls = NoCtl;
                ShowAsTree = true;

                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('agcr ' + Format(Rec."Line No."));
    end;
}

codeunit 93850 "LT Y72 Tree Default State"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddRow(Line: Integer; Grp: Code[20]; Indent: Integer)
    var
        Row: Record "LT Y72 Tree Row";
    begin
        Row.Init();
        Row."Line No." := Line;
        Row."No." := 'N' + Format(Line);
        Row.Grp := Grp;
        Row.Indent := Indent;
        Row.Qty := Line;
        Row.Insert();
    end;

    local procedure Seed()
    var
        Row: Record "LT Y72 Tree Row";
        Log: Record "LT Y61 Log";
    begin
        ClearLastError();
        Observer.Discard();
        Row.DeleteAll();
        AddRow(10, 'A', 0);
        AddRow(20, 'A', 1);
        AddRow(30, 'A', 1);
        AddRow(40, 'B', 0);
        AddRow(50, 'B', 1);
        AddRow(60, 'C', 0);
        Log.ClearLog();
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y61 Log";
    begin
        exit(Log.Take());
    end;

    // Rows from the current one to the end by Next (at most 12 steps): <line>:<expanded Y/N>;
    local procedure WalkPL(var P: TestPage "LT Y72 Tree PL"): Text
    var
        Result: Text;
        Steps: Integer;
    begin
        repeat
            Result += P.LineCtl.Value() + ':' + Format(P.IsExpanded()) + ';';
            Steps += 1;
        until (Steps >= 12) or not P.Next();
        exit(Result);
    end;

    local procedure WalkPW(var P: TestPage "LT Y72 Tree PW"): Text
    var
        Result: Text;
        Steps: Integer;
    begin
        repeat
            Result += P.LineCtl.Value() + ':' + Format(P.IsExpanded()) + ';';
            Steps += 1;
        until (Steps >= 12) or not P.Next();
        exit(Result);
    end;

    local procedure LinesBackPL(var P: TestPage "LT Y72 Tree PL"): Text
    var
        Result: Text;
        Steps: Integer;
    begin
        repeat
            Result += P.LineCtl.Value() + ';';
            Steps += 1;
        until (Steps >= 12) or not P.Previous();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryGoToKeyPL(var P: TestPage "LT Y72 Tree PL"; Line: Integer)
    begin
        P.GoToKey(Line);
    end;

    [TryFunction]
    local procedure TryExpandPL(var P: TestPage "LT Y72 Tree PL"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    [TryFunction]
    local procedure TryExpandPW(var P: TestPage "LT Y72 Tree PW"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    [Test]
    procedure TreeDefault_OpenShows()
    var
        P: TestPage "LT Y72 Tree PL";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open line', P.LineCtl.Value());
        Observer.Observe('open expanded', Format(P.IsExpanded()));
        P.First();
        Observer.Observe('first log', TakeLog());
        Observer.Observe('walk', WalkPL(P));
        Observer.Observe('walk log', TakeLog());
        P.Close();
        Observer.Expect('open log', 'agr 10;agr 20;agr 30;agr 40;agr 50;agr 60;agr 10;agr 10;agcr 10');
        Observer.Expect('open line', '10');
        Observer.Expect('open expanded', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('walk', '10:No;40:No;60:No;');
        Observer.Expect('walk log', 'agr 40;agr 40;agcr 40;agr 60;agr 60;agcr 60');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_ExpandCollapse_Row10()
    var
        P: TestPage "LT Y72 Tree PL";
    begin
        Seed();
        P.OpenView();
        P.First();
        TakeLog();
        P.Expand(true);
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand line', P.LineCtl.Value());
        Observer.Observe('expand expanded', Format(P.IsExpanded()));
        Observer.Observe('expand walk', WalkPL(P));
        Observer.Observe('expand walk log', TakeLog());
        P.First();
        TakeLog();
        P.Expand(false);
        Observer.Observe('collapse log', TakeLog());
        Observer.Observe('collapse expanded', Format(P.IsExpanded()));
        Observer.Observe('collapse walk', WalkPL(P));
        Observer.Observe('collapse walk log', TakeLog());
        P.Close();
        Observer.Expect('expand log', '');
        Observer.Expect('expand line', '10');
        Observer.Expect('expand expanded', 'Yes');
        Observer.Expect('expand walk', '10:Yes;20:No;30:No;40:No;60:No;');
        Observer.Expect('expand walk log', 'agr 20;agr 20;agcr 20;agr 30;agr 30;agcr 30;agr 40;agr 40;agcr 40;agr 60;agr 60;agcr 60');
        Observer.Expect('collapse log', '');
        Observer.Expect('collapse expanded', 'No');
        Observer.Expect('collapse walk', '10:No;40:No;60:No;');
        Observer.Expect('collapse walk log', 'agr 40;agr 40;agcr 40;agr 60;agr 60;agcr 60');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_ExpandCollapse_Row40()
    var
        P: TestPage "LT Y72 Tree PL";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('goto 40', Format(P.GoToKey(40)));
        Observer.Observe('goto log', TakeLog());
        Observer.Observe('goto line', P.LineCtl.Value());
        Observer.Observe('goto expanded', Format(P.IsExpanded()));
        P.Expand(true);
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand expanded', Format(P.IsExpanded()));
        Observer.Observe('expand walk', WalkPL(P));
        Observer.Observe('expand walk log', TakeLog());
        Observer.Observe('goto 40 again', Format(P.GoToKey(40)));
        TakeLog();
        P.Expand(false);
        Observer.Observe('collapse log', TakeLog());
        Observer.Observe('collapse expanded', Format(P.IsExpanded()));
        Observer.Observe('collapse walk', WalkPL(P));
        P.Close();
        Observer.Expect('goto 40', 'Yes');
        Observer.Expect('goto log', 'agr 10;agr 20;agr 30;agr 40;agr 50;agr 60;agr 10;agr 10;agcr 10;agr 40;agr 40;agcr 40');
        Observer.Expect('goto line', '40');
        Observer.Expect('goto expanded', 'No');
        Observer.Expect('expand log', '');
        Observer.Expect('expand expanded', 'Yes');
        Observer.Expect('expand walk', '40:Yes;50:No;60:No;');
        Observer.Expect('expand walk log', 'agr 50;agr 50;agcr 50;agr 60;agr 60;agcr 60');
        Observer.Expect('goto 40 again', 'Yes');
        Observer.Expect('collapse log', '');
        Observer.Expect('collapse expanded', 'No');
        Observer.Expect('collapse walk', '40:No;60:No;');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_Expand_LeafRow60_Open()
    var
        P: TestPage "LT Y72 Tree PL";
        Ok: Boolean;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('goto 60', Format(P.GoToKey(60)));
        TakeLog();
        Ok := TryExpandPL(P, true);
        Observer.Observe('expand true ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('expand true');
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand line', P.LineCtl.Value());
        Observer.Observe('expand expanded', Format(P.IsExpanded()));
        P.Close();
        Observer.Expect('goto 60', 'Yes');
        Observer.Expect('expand true ok', 'Yes');
        Observer.Expect('expand log', '');
        Observer.Expect('expand line', '60');
        Observer.Expect('expand expanded', 'No');
        Observer.Verify();
    end;


    // Expand(false) on a leaf row ends the test with an uncatchable CLR exception ("Expanding and collapsing are not supported on this
    // rowEntry", BC 29 SaaS), so it is not a test.
    local procedure Tree_CollapseLeafRow60()
    var
        P: TestPage "LT Y72 Tree PL";
    begin
        Seed();
        P.OpenView();
        P.GoToKey(60);
        P.Expand(false);
        P.Close();
    end;

    [Test]
    procedure TreeDefault_FilterThenExpand_Worksheet()
    var
        P: TestPage "LT Y72 Tree PW";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open line', P.LineCtl.Value());
        P.Filter.SetFilter(Grp, 'A');
        Observer.Observe('filter log', TakeLog());
        Observer.Observe('filter line', P.LineCtl.Value());
        P.Expand(true);
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand line', P.LineCtl.Value());
        Observer.Observe('expand walk', WalkPW(P));
        TakeLog();
        P.Filter.SetFilter("No.", 'N30');
        Observer.Observe('child log', TakeLog());
        Observer.Observe('child line', P.LineCtl.Value());
        Observer.Observe('child qty', P.QtyCtl.Value());
        Observer.Observe('child shown', P.ShownCtl.Value());
        Observer.Observe('child expanded', Format(P.IsExpanded()));
        P.Close();
        Observer.Expect('open log', 'agr 10;agr 20;agr 30;agr 40;agr 50;agr 60;agr 10;agr 10;agcr 10');
        Observer.Expect('open line', '10');
        Observer.Expect('filter log', 'agr 10;agr 20;agr 30;agr 10;agr 10;agcr 10');
        Observer.Expect('filter line', '10');
        Observer.Expect('expand log', '');
        Observer.Expect('expand line', '10');
        Observer.Expect('expand walk', '10:Yes;20:No;30:No;');
        Observer.Expect('child log', 'agr 30;agr 30;agcr 30');
        Observer.Expect('child line', '30');
        Observer.Expect('child qty', '30.00');
        Observer.Expect('child shown', 'agr 30');
        Observer.Expect('child expanded', 'No');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_GoToKey_ChildRow()
    var
        P: TestPage "LT Y72 Tree PL";
        Ok: Boolean;
    begin
        Seed();
        P.OpenView();
        TakeLog();
        Ok := TryGoToKeyPL(P, 30);
        Observer.Observe('goto ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('goto');
        Observer.Observe('goto log', TakeLog());
        Observer.Observe('goto line', P.LineCtl.Value());
        Observer.Observe('goto expanded', Format(P.IsExpanded()));
        Observer.Observe('goto 10', Format(P.GoToKey(10)));
        Observer.Observe('parent expanded', Format(P.IsExpanded()));
        P.Close();
        Observer.Expect('goto ok', 'No');
        Observer.Expect('goto|text', 'The row does not exist on the TestPage.');
        Observer.Expect('goto|code', 'TestRowNotFound');
        Observer.Expect('goto log', 'agr 40;agr 40;agcr 40;agr 60;agr 60;agcr 60;agr 10;agr 10;agcr 10');
        Observer.Expect('goto line', '10');
        Observer.Expect('goto expanded', 'No');
        Observer.Expect('goto 10', 'Yes');
        Observer.Expect('parent expanded', 'No');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetRecordOnly()
    var
        P: TestPage "LT Y72 Tree PO";
        Result: Text;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open line', P.LineCtl.Value());
        P.First();
        Observer.Observe('first log', TakeLog());
        P.Expand(true);
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand expanded', Format(P.IsExpanded()));
        Result := P.LineCtl.Value();
        while P.Next() do
            Result += ';' + P.LineCtl.Value();
        Observer.Observe('walk', Result);
        Observer.Observe('walk log', TakeLog());
        P.Close();
        Observer.Expect('open log', 'agr 10;agr 20;agr 30;agr 40;agr 50;agr 60;agr 10');
        Observer.Expect('open line', '10');
        Observer.Expect('first log', '');
        Observer.Expect('expand log', '');
        Observer.Expect('expand expanded', 'Yes');
        Observer.Expect('walk', '10;20;30;40;60');
        Observer.Expect('walk log', '');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetCurrRecordOnly()
    var
        P: TestPage "LT Y72 Tree PC";
        Result: Text;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open line', P.LineCtl.Value());
        P.First();
        Observer.Observe('first log', TakeLog());
        P.Expand(true);
        Observer.Observe('expand log', TakeLog());
        Observer.Observe('expand expanded', Format(P.IsExpanded()));
        Result := P.LineCtl.Value();
        while P.Next() do
            Result += ';' + P.LineCtl.Value();
        Observer.Observe('walk', Result);
        Observer.Observe('walk log', TakeLog());
        P.Close();
        Observer.Expect('open log', 'agcr 10');
        Observer.Expect('open line', '10');
        Observer.Expect('first log', '');
        Observer.Expect('expand log', '');
        Observer.Expect('expand expanded', 'Yes');
        Observer.Expect('walk', '10;20;30;40;60');
        Observer.Expect('walk log', 'agcr 20;agcr 30;agcr 40;agcr 60');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_Previous_Last()
    var
        P: TestPage "LT Y72 Tree PL";
    begin
        Seed();
        P.OpenView();
        P.Last();
        Observer.Observe('last line', P.LineCtl.Value());
        Observer.Observe('back before', LinesBackPL(P));
        P.GoToKey(40);
        P.Expand(true);
        P.Last();
        Observer.Observe('last after expand', P.LineCtl.Value());
        Observer.Observe('back after', LinesBackPL(P));
        TakeLog();
        P.Close();
        Observer.Expect('last line', '60');
        Observer.Expect('back before', '60;40;10;');
        Observer.Expect('last after expand', '60');
        Observer.Expect('back after', '60;50;40;10;');
        Observer.Verify();
    end;




    [Test]
    procedure TreeDefault_ExpandOnEmptyTree()
    var
        P: TestPage "LT Y72 Tree PW";
        Row: Record "LT Y72 Tree Row";
        Ok: Boolean;
    begin
        Seed();
        Row.DeleteAll();
        P.OpenEdit();
        Observer.Observe('open line', P.LineCtl.Value());
        Observer.Observe('open log', TakeLog());
        Ok := TryExpandPW(P, true);
        Observer.Observe('expand ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('expand');
        Observer.Observe('expand log', TakeLog());
        P.Close();
        Observer.Expect('open line', '');
        Observer.Expect('open log', 'agcr 0');
        Observer.Expect('expand ok', 'Yes');
        Observer.Expect('expand log', '');
        Observer.Verify();
    end;



}
