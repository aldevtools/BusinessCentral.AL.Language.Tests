// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-expand-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 92961, pages 92963 - 92964, codeunits 92962 - 92964 (writer Y50)
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-17: TestPage.Expand on the edges the pinned tests do not reach (P82TestPage.al:283 only expands a row WITH
//   children and only reads IsExpanded). A Worksheet over a temporary source, InsertAllowed = false, repeater ShowAsTree with
//   IndentationColumn and TreeInitialState = ExpandAll; OnOpenPage fills Rec, sets a key and calls CurrPage.Update(false); row triggers log.
//   Shapes: FLAT = rows 10, 20, 30 all at Indent 1 (no level-0 row: every row is a leaf without parent), MIXED = 10 (Indent 0), 20 and 30
//   (Indent 1, children of 10), 40 (Indent 0, no children). Opened by Page.RunModal, the steps run in the ModalPageHandler.
//   Log: agr = OnAfterGetRecord, agcr = OnAfterGetCurrRecord, val = Selected.OnValidate.
// BC versions: 27, 28, 29

table 92961 "LT Y50 TE Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Grp; Code[20]) { }
        field(3; Indent; Integer) { }
        field(4; Selected; Boolean) { }
        field(5; Amount; Decimal) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByGrp; Grp) { }
    }
}

codeunit 92962 "LT Y50 TE Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Shape: Text;

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

    procedure SetShape(NewShape: Text)
    begin
        Shape := NewShape;
    end;

    procedure Fill(var Line: Record "LT Y50 TE Line")
    begin
        Line.Reset();
        Line.DeleteAll();
        if Shape = 'FLAT' then begin
            AddLine(Line, 10, 'A', 1);
            AddLine(Line, 20, 'B', 1);
            AddLine(Line, 30, 'C', 1);
        end else begin
            AddLine(Line, 10, 'A', 0);
            AddLine(Line, 20, 'B', 1);
            AddLine(Line, 30, 'C', 1);
            AddLine(Line, 40, 'D', 0);
        end;
    end;

    local procedure AddLine(var Line: Record "LT Y50 TE Line"; EntryNo: Integer; Grp: Code[20]; Indent: Integer)
    begin
        Line.Init();
        Line."Entry No." := EntryNo;
        Line.Grp := Grp;
        Line.Indent := Indent;
        Line.Amount := EntryNo * 10;
        Line.Insert();
    end;
}

page 92963 "LT Y50 TE Tree"
{
    PageType = Worksheet;
    SourceTable = "LT Y50 TE Line";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indent;
                TreeInitialState = ExpandAll;

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('val ' + Format(Rec."Entry No."));
                    end;
                }
                field(Amount; Rec.Amount)
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
        Rec.SetCurrentKey(Grp);
        CurrPage.Update(false);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr ' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr ' + Format(Rec."Entry No."));
    end;

    var
        Log: Codeunit "LT Y50 TE Log";
}

page 92964 "LT Y50 TE Tree Plain"
{
    PageType = Worksheet;
    SourceTable = "LT Y50 TE Line";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indent;

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Rec.SetCurrentKey(Grp);
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "LT Y50 TE Log";
}

codeunit 92963 "LT Y50 TE Driver"
{
    procedure RunTree(Shape: Text)
    var
        Log: Codeunit "LT Y50 TE Log";
    begin
        Log.SetShape(Shape);
        Page.RunModal(Page::"LT Y50 TE Tree");
    end;

    procedure RunPlain(Shape: Text)
    var
        Log: Codeunit "LT Y50 TE Log";
    begin
        Log.SetShape(Shape);
        Page.RunModal(Page::"LT Y50 TE Tree Plain");
    end;
}

codeunit 92964 "LT Y50 TE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y50 TE Log";
        Driver: Codeunit "LT Y50 TE Driver";
        Mode: Integer;

    [TryFunction]
    local procedure TryExpand(var P: TestPage "LT Y50 TE Tree"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    [TryFunction]
    local procedure TryExpandPlain(var P: TestPage "LT Y50 TE Tree Plain"; Expand: Boolean)
    begin
        P.Expand(Expand);
    end;

    local procedure Walk(var P: TestPage "LT Y50 TE Tree"): Text
    var
        Rows: Text;
        i: Integer;
    begin
        if P.First() then
            repeat
                Rows += P."Entry No.".Value() + ',';
                i += 1;
            until (not P.Next()) or (i >= 10);
        exit(Rows);
    end;

    local procedure DoExpand(var P: TestPage "LT Y50 TE Tree"; Name: Text; Expand: Boolean)
    var
        Ok: Boolean;
    begin
        Ok := TryExpand(P, Expand);
        Observer.Observe(Name, Format(Ok) + '/' + Format(P.IsExpanded()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        if not Ok then
            Observer.ObserveError(Name + ' error');
    end;

    // T1, the Microsoft shape: FLAT, Expand(true) on the first row, Next, Selected.SetValue, OK.
    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure G517_Flat_ExpandTrueOnFirst_ThenNext()
    begin
        Log.Take();
        Mode := 1;
        Driver.RunTree('FLAT');
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // T2: FLAT, Expand(true) on the first row, then the walk.
    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure G517_Flat_ExpandTrue_WalkRows()
    begin
        Log.Take();
        Mode := 2;
        Driver.RunTree('FLAT');
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // T3: MIXED, Expand(true) on row 40 (level 0, no children).
    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure G517_Mixed_ExpandTrueOnLeafLevel0()
    begin
        Log.Take();
        Mode := 3;
        Driver.RunTree('MIXED');
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // T4: MIXED, Expand(false) twice on row 10 (has children) right after open.
    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure G517_Mixed_ExpandFalseOnCollapsed()
    begin
        Log.Take();
        Mode := 4;
        Driver.RunTree('MIXED');
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // T5: MIXED, Expand(true) twice on row 10, the walk after each.
    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure G517_Mixed_ExpandTrueTwice_Walk()
    begin
        Log.Take();
        Mode := 5;
        Driver.RunTree('MIXED');
        Observer.Observe('after', Log.Take());
        Observer.Finish();
    end;

    // T6: FLAT on the plain tree (no row triggers, no TreeInitialState), as T1 up to the Next.
    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure G517_W2_Flat_ExpandTrueOnLeaf()
    begin
        Log.Take();
        Driver.RunPlain('FLAT');
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure TreeHandler(var P: TestPage "LT Y50 TE Tree")
    begin
        Observer.Observe('open', Format(P.IsExpanded()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
        case Mode of
            1:
                begin
                    DoExpand(P, 'expand', true);
                    Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
                    P.Selected.SetValue(true);
                    Observer.Observe('setvalue', P."Entry No.".Value() + '/' + P.Selected.Value() + ':' + Log.Take());
                end;
            2:
                begin
                    DoExpand(P, 'expand', true);
                    Observer.Observe('walk', Walk(P) + ':' + Log.Take());
                end;
            3:
                begin
                    Observer.Observe('goto', Format(P.GoToKey(40)) + '/' + Format(P.IsExpanded()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
                    DoExpand(P, 'expand', true);
                    Observer.Observe('walk', Walk(P) + ':' + Log.Take());
                end;
            4:
                begin
                    Observer.Observe('goto', Format(P.GoToKey(10)) + '/' + Format(P.IsExpanded()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
                    DoExpand(P, 'collapse 1', false);
                    Observer.Observe('walk 1', Walk(P) + ':' + Log.Take());
                    P.GoToKey(10);
                    Log.Take();
                    DoExpand(P, 'collapse 2', false);
                    Observer.Observe('walk 2', Walk(P) + ':' + Log.Take());
                end;
            5:
                begin
                    Observer.Observe('goto', Format(P.GoToKey(10)) + '/' + Format(P.IsExpanded()) + '/' + P."Entry No.".Value() + ':' + Log.Take());
                    DoExpand(P, 'expand 1', true);
                    Observer.Observe('walk 1', Walk(P) + ':' + Log.Take());
                    P.GoToKey(10);
                    Log.Take();
                    DoExpand(P, 'expand 2', true);
                    Observer.Observe('walk 2', Walk(P) + ':' + Log.Take());
                end;
        end;
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PlainHandler(var P: TestPage "LT Y50 TE Tree Plain")
    var
        Ok: Boolean;
    begin
        Observer.Observe('open', Format(P.IsExpanded()) + '/' + P."Entry No.".Value());
        Ok := TryExpandPlain(P, true);
        Observer.Observe('expand', Format(Ok) + '/' + Format(P.IsExpanded()) + '/' + P."Entry No.".Value());
        if not Ok then
            Observer.ObserveError('expand error');
        Observer.Observe('next', Format(P.Next()) + '/' + P."Entry No.".Value());
        P.OK().Invoke();
    end;
}
