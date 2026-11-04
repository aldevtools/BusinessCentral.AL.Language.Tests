// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-treeinitialstate-property
// Scope: in-scope
// Fixtures used: own objects 92270 - 92274 (writer Y28); tests in Y28CollapsedTreeTests.al (92279)
// Probe: al-runner issue 6523. A repeater with ShowAsTree = true and TreeInitialState = CollapseAll shows only the rows at indentation 0
//   on a TestPage (PageTree.al P123_ShowAsTreeRows). These objects let the tests read what the page's own AL code sees of Rec in OnOpenPage,
//   OnAfterGetRecord, OnAfterGetCurrRecord and actions, and what the TestPage shows after that code changes Rec.
// Rows (inserted by the tests): 1 Root 1 (0), 2 Child 1A (1), 3 Child 1B (1), 4 Root 2 (0), 5 Child 2A (1).
// BC versions: 27, 28, 29

table 92270 "LT Y28 Tree Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Indent; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The log and the OnOpenPage mode of the Y28 pages. Used by test codeunit 92279 only.
codeunit 92271 "LT Y28 Tree Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        OpenMode: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetMode(NewMode: Text)
    begin
        OpenMode := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(OpenMode);
    end;

    // The filter groups 0..10 of Row that hold a filter, as <group>:<filters>; Row's filter group is restored afterwards.
    procedure Groups(var Row: Record "LT Y28 Tree Row") Result: Text
    var
        Current: Integer;
        Group: Integer;
    begin
        Current := Row.FilterGroup();
        for Group := 0 to 10 do begin
            Row.FilterGroup(Group);
            if Row.GetFilters() <> '' then
                Result += Format(Group) + ':' + Row.GetFilters() + '|';
        end;
        Row.FilterGroup(Current);
        Result := 'fg' + Format(Current) + '[' + Result + ']';
    end;

    // The ids a copy of Row reaches with FindSet/Next, and how many.
    procedure CopyWalk(var Row: Record "LT Y28 Tree Row") Result: Text
    var
        Copy: Record "LT Y28 Tree Row";
        Count: Integer;
    begin
        Copy.Copy(Row);
        if Copy.FindSet() then
            repeat
                Count += 1;
                Result += Format(Copy.Id) + ',';
            until Copy.Next() = 0;
        Result := Format(Count) + '/' + Result;
    end;
}

page 92272 "LT Y28 Collapsed Tree"
{
    PageType = List;
    SourceTable = "LT Y28 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                ShowAsTree = true;
                TreeInitialState = CollapseAll;

                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CountAct)
            {
                ApplicationArea = All;
                Caption = 'Count';

                trigger OnAction()
                var
                    Selected: Record "LT Y28 Tree Row";
                begin
                    Log.Add('act cur=' + Format(Rec.Id) + ' count=' + Format(Rec.Count()) + ' filters=' + Rec.GetFilters() + ' ' + Log.Groups(Rec) + ' copy=' + Log.CopyWalk(Rec));
                    CurrPage.SetSelectionFilter(Selected);
                    Log.Add('sel count=' + Format(Selected.Count()) + ' filters=' + Selected.GetFilters() + ' ' + Log.Groups(Selected) + ' copy=' + Log.CopyWalk(Selected));
                end;
            }
            action(ResetAct)
            {
                ApplicationArea = All;
                Caption = 'Reset';

                trigger OnAction()
                begin
                    Rec.Reset();
                    Log.Add('reset count=' + Format(Rec.Count()));
                    CurrPage.Update(false);
                end;
            }
            action(GoChildAct)
            {
                ApplicationArea = All;
                Caption = 'Go to child';

                trigger OnAction()
                begin
                    Log.Add('get2=' + Format(Rec.Get(2)));
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open count=' + Format(Rec.Count()) + ' filters=' + Rec.GetFilters() + ' ' + Log.Groups(Rec) + ' copy=' + Log.CopyWalk(Rec));
        case Log.Mode() of
            'reset':
                Rec.Reset();
            'findset':
                begin
                    if Rec.FindSet() then
                        repeat
                            Log.Add('fs' + Format(Rec.Id));
                        until Rec.Next() = 0;
                end;
            'setrange1':
                Rec.SetRange(Indent, 1);
            'get2':
                Log.Add('get2=' + Format(Rec.Get(2)));
        end;
        Log.Add('open-end count=' + Format(Rec.Count()) + ' filters=' + Rec.GetFilters());
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr' + Format(Rec.Id) + ' n=' + Format(Rec.Count()));
    end;

    var
        Log: Codeunit "LT Y28 Tree Log";
}

page 92273 "LT Y28 Expanded Tree"
{
    PageType = List;
    SourceTable = "LT Y28 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open count=' + Format(Rec.Count()) + ' filters=' + Rec.GetFilters() + ' ' + Log.Groups(Rec));
    end;

    var
        Log: Codeunit "LT Y28 Tree Log";
}

// IndentationColumn is a page variable that OnAfterGetRecord sets from Rec.Indent.
page 92274 "LT Y28 Var Indent Tree"
{
    PageType = List;
    SourceTable = "LT Y28 Tree Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = IndentLevel;
                ShowAsTree = true;
                TreeInitialState = CollapseAll;

                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('open count=' + Format(Rec.Count()));
    end;

    trigger OnAfterGetRecord()
    begin
        IndentLevel := Rec.Indent;
        Log.Add('agr' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y28 Tree Log";
        IndentLevel: Integer;
}
