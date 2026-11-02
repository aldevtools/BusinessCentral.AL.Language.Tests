// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-expand-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); table 93850, pages 93850-93853, test codeunit 93850
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_OpenShows_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_OpenShows_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_OpenShows_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row10_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row10_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row10_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row40_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row40_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandCollapse_Row40_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_Expand_LeafRow60_Open_More1()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_FilterThenExpand_Worksheet_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_FilterThenExpand_Worksheet_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_FilterThenExpand_Worksheet_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_GoToKey_ChildRow_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_GoToKey_ChildRow_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_GoToKey_ChildRow_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetRecordOnly_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetRecordOnly_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetRecordOnly_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetCurrRecordOnly_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetCurrRecordOnly_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_RowTriggerVariants_OnAfterGetCurrRecordOnly_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_Previous_Last_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_Previous_Last_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_Previous_Last_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure TreeDefault_ExpandOnEmptyTree_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandOnEmptyTree_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TreeDefault_ExpandOnEmptyTree_More3()
    begin
        Observer.More();
    end;
}
