// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-expand-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 95420, codeunit 95421 (log), pages 95422 - 95423, test codeunit 95424 (writer r6945)
// local object: the tree pages' own properties (ShowAsTree, TreeInitialState, IndentationColumn) and row triggers are under test; the log must be a SingleInstance codeunit of its own
// Probe: al-runner issue 6947; written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: TestPage.Expand(true) and Expand(false) on every kind of row of a tree: a row with children and a row without, at indentation 0, 1
//   and 2. Two Worksheets over a temporary table filled in OnOpenPage (then FindFirst), repeater ShowAsTree with IndentationColumn = an
//   Integer field, OnAfterGetRecord and OnAfterGetCurrRecord logged; page 95422 has TreeInitialState = CollapseAll, page 95423 ExpandAll.
//   Opened with OpenEdit. Rows (Line No. / indentation): 10/0, 20/1, 30/2, 40/1, 50/0, 60/1, 70/0: 10 holds 20 and 40, 20 holds 30, 50
//   holds 60; 30, 40, 60 and 70 have no children. Log: R<line> = OnAfterGetRecord, C<line> = OnAfterGetCurrRecord.
//   Each step observes <Expand ok>/<IsExpanded>/<line shown>:<log>; a walk is First/Next over the rows that show.
// BC versions: 27, 28, 29

table 95420 "PAG TreeExpand Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Indent; Integer) { }
    }
    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 95422 "PAG TreeExpand Collapsed"
{
    PageType = Worksheet;
    SourceTable = "PAG TreeExpand Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                IndentationControls = "No.";
                ShowAsTree = true;
                TreeInitialState = CollapseAll;

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "PAG TreeExpand Log";
}

page 95423 "PAG TreeExpand Expanded"
{
    PageType = Worksheet;
    SourceTable = "PAG TreeExpand Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                IndentationControls = "No.";
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "PAG TreeExpand Log";
}

codeunit 95421 "PAG TreeExpand Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure Fill(var Row: Record "PAG TreeExpand Row" temporary)
    begin
        Row.Reset();
        Row.DeleteAll();
        AddRow(Row, 10, 'P1', 0);
        AddRow(Row, 20, 'P1-C1', 1);
        AddRow(Row, 30, 'P1-C1-L', 2);
        AddRow(Row, 40, 'P1-L', 1);
        AddRow(Row, 50, 'P2', 0);
        AddRow(Row, 60, 'P2-L', 1);
        AddRow(Row, 70, 'L0', 0);
    end;

    local procedure AddRow(var Row: Record "PAG TreeExpand Row" temporary; LineNo: Integer; No: Code[20]; Indent: Integer)
    begin
        Row.Init();
        Row."Line No." := LineNo;
        Row."No." := No;
        Row.Indent := Indent;
        Row.Insert();
    end;
}

codeunit 95424 "PAG TreeExpand Leaf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PAG TreeExpand Log";

    [TryFunction]
    local procedure TryExpandC(var P: TestPage "PAG TreeExpand Collapsed"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    [TryFunction]
    local procedure TryExpandE(var P: TestPage "PAG TreeExpand Expanded"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    local procedure StepC(var P: TestPage "PAG TreeExpand Collapsed"; Name: Text; Expand: Boolean)
    var
        Ok: Boolean;
    begin
        Ok := TryExpandC(P, Expand);
        Observer.Observe(Name, Format(Ok) + '/' + Format(P.IsExpanded()) + '/' + P."Line No.".Value() + ':' + Log.Take());
        if not Ok then
            Observer.ObserveError(Name + ' error');
    end;

    local procedure StepE(var P: TestPage "PAG TreeExpand Expanded"; Name: Text; Expand: Boolean)
    var
        Ok: Boolean;
    begin
        Ok := TryExpandE(P, Expand);
        Observer.Observe(Name, Format(Ok) + '/' + Format(P.IsExpanded()) + '/' + P."Line No.".Value() + ':' + Log.Take());
        if not Ok then
            Observer.ObserveError(Name + ' error');
    end;

    local procedure WalkC(var P: TestPage "PAG TreeExpand Collapsed"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if P.First() then
            repeat
                Rows += P."Line No.".Value() + ',';
                i += 1;
            until (not P.Next()) or (i >= 10);
        exit(Rows + ':' + Log.Take());
    end;

    local procedure WalkE(var P: TestPage "PAG TreeExpand Expanded"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if P.First() then
            repeat
                Rows += P."Line No.".Value() + ',';
                i += 1;
            until (not P.Next()) or (i >= 10);
        exit(Rows + ':' + Log.Take());
    end;

    local procedure MoveC(var P: TestPage "PAG TreeExpand Collapsed"; Name: Text; First: Boolean)
    var
        Ok: Boolean;
    begin
        if First then
            Ok := P.First()
        else
            Ok := P.Next();
        Observer.Observe(Name, Format(Ok) + '/' + P."Line No.".Value() + ':' + Log.Take());
    end;

    local procedure MoveE(var P: TestPage "PAG TreeExpand Expanded"; Name: Text; First: Boolean)
    var
        Ok: Boolean;
    begin
        if First then
            Ok := P.First()
        else
            Ok := P.Next();
        Observer.Observe(Name, Format(Ok) + '/' + P."Line No.".Value() + ':' + Log.Take());
    end;

    local procedure OpenC(var P: TestPage "PAG TreeExpand Collapsed")
    begin
        Log.Take();
        P.OpenEdit();
        Observer.Observe('open', Format(P.IsExpanded()) + '/' + P."Line No.".Value() + ':' + Log.Take());
    end;

    local procedure OpenE(var P: TestPage "PAG TreeExpand Expanded")
    begin
        Log.Take();
        P.OpenEdit();
        Observer.Observe('open', Format(P.IsExpanded()) + '/' + P."Line No.".Value() + ':' + Log.Take());
    end;

    // CollapseAll: Expand(true) twice on row 40, a row at indentation 1 without children, under row 10.
    [Test]
    procedure Collapsed_ExpandTrue_LeafLevel1()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        MoveC(P, 'first', true);
        StepC(P, 'expand 10', true);
        MoveC(P, 'next 1', false);
        MoveC(P, 'next 2', false);
        StepC(P, 'expand 40', true);
        StepC(P, 'expand 40 again', true);
        MoveC(P, 'next 3', false);
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll: Expand(true) on row 30, a row at indentation 2 without children, under row 20.
    [Test]
    procedure Collapsed_ExpandTrue_LeafLevel2()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        StepC(P, 'expand 10', true);
        MoveC(P, 'next 1', false);
        StepC(P, 'expand 20', true);
        MoveC(P, 'next 2', false);
        StepC(P, 'expand 30', true);
        MoveC(P, 'next 3', false);
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll: Expand(true) on row 60, the last child of row 50, with a row at indentation 0 after it.
    [Test]
    procedure Collapsed_ExpandTrue_LastLeafLevel1()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        MoveC(P, 'next 1', false);
        StepC(P, 'expand 50', true);
        MoveC(P, 'next 2', false);
        StepC(P, 'expand 60', true);
        MoveC(P, 'next 3', false);
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll: Expand(true) on row 70, a row at indentation 0 without children, the last row.
    [Test]
    procedure Collapsed_ExpandTrue_LeafLevel0()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        MoveC(P, 'next 1', false);
        MoveC(P, 'next 2', false);
        StepC(P, 'expand 70', true);
        MoveC(P, 'next 3', false);
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll, the reporter's walk: First and Next over the rows, Expand(true) on each row the walk stands on.
    [Test]
    procedure Collapsed_WalkExpandingEveryRow()
    var
        P: TestPage "PAG TreeExpand Collapsed";
        Walked: Text;
        i: Integer;
    begin
        OpenC(P);
        if P.First() then
            repeat
                Walked += P."Line No.".Value() + ',';
                P.Expand(true);
                i += 1;
            until (not P.Next()) or (i >= 10);
        Observer.Observe('walked', Walked);
        Observer.Observe('walk log', Log.Take());
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll: row 20 (indentation 1, with a child): Expand(false) while collapsed, Expand(true), then Expand(false) twice.
    [Test]
    procedure Collapsed_Level1Parent_ExpandAndCollapse()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        StepC(P, 'expand 10', true);
        MoveC(P, 'next 1', false);
        StepC(P, 'collapse 20 collapsed', false);
        StepC(P, 'expand 20', true);
        MoveC(P, 'next 2', false);
        MoveC(P, 'first', true);
        MoveC(P, 'next 3', false);
        StepC(P, 'collapse 20', false);
        StepC(P, 'collapse 20 again', false);
        Observer.Observe('walk', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // CollapseAll: collapse row 10 while its child 20 is expanded, then expand 10 again: does row 30 show again?
    [Test]
    procedure Collapsed_RootCollapse_KeepsChildState()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        OpenC(P);
        StepC(P, 'expand 10', true);
        MoveC(P, 'next 1', false);
        StepC(P, 'expand 20', true);
        MoveC(P, 'first', true);
        StepC(P, 'collapse 10', false);
        Observer.Observe('walk 1', WalkC(P));
        MoveC(P, 'first again', true);
        StepC(P, 'expand 10 again', true);
        Observer.Observe('walk 2', WalkC(P));
        P.Close();
        Observer.Finish();
    end;

    // Expand(false) on a row without children, at any indentation (rows 30, 40, 60, 70), ends the test with an uncatchable CLR
    // exception ("Expanding and collapsing are not supported on this rowEntry", also inside a TryFunction; measured on 27.5, 28.5
    // and 29.0 with both pages), so it is not a test.
    local procedure Collapsed_CollapseLeafRow40()
    var
        P: TestPage "PAG TreeExpand Collapsed";
    begin
        P.OpenEdit();
        P.Expand(true);
        P.Next();
        P.Next();
        P.Expand(false);
        P.Close();
    end;

    // ExpandAll, filled in OnOpenPage: which rows show at open, and Expand(true) on rows with and without children.
    [Test]
    procedure Expanded_FilledOnOpen_RowsShown()
    var
        P: TestPage "PAG TreeExpand Expanded";
    begin
        OpenE(P);
        Observer.Observe('walk', WalkE(P));
        P.Close();
        Observer.Finish();
    end;

    // ExpandAll: Expand(true) on row 10, then on row 40 (indentation 1, no children) and row 20, then on row 30 (indentation 2).
    [Test]
    procedure Expanded_ExpandTrue_LeafRows()
    var
        P: TestPage "PAG TreeExpand Expanded";
    begin
        OpenE(P);
        StepE(P, 'expand 10', true);
        MoveE(P, 'next 1', false);
        MoveE(P, 'next 2', false);
        StepE(P, 'expand 40', true);
        MoveE(P, 'first', true);
        MoveE(P, 'next 3', false);
        StepE(P, 'expand 20', true);
        MoveE(P, 'next 4', false);
        StepE(P, 'expand 30', true);
        Observer.Observe('walk', WalkE(P));
        P.Close();
        Observer.Finish();
    end;

    // ExpandAll: the walk with Expand(true) on every row.
    [Test]
    procedure Expanded_WalkExpandingEveryRow()
    var
        P: TestPage "PAG TreeExpand Expanded";
        Walked: Text;
        i: Integer;
    begin
        OpenE(P);
        if P.First() then
            repeat
                Walked += P."Line No.".Value() + ',';
                P.Expand(true);
                i += 1;
            until (not P.Next()) or (i >= 10);
        Observer.Observe('walked', Walked);
        Observer.Observe('walk log', Log.Take());
        P.Close();
        Observer.Finish();
    end;
}
