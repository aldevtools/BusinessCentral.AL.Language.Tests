// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-showastree-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-indentationcolumn-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 77730, pages 77731 77732, log codeunit 77733, test codeunit 77734
// Probe (al-runner 7421): a tree list page (repeater with ShowAsTree = true and IndentationColumn = Lvl, a page variable that
//   OnAfterGetRecord sets from the row's Level) opened with OpenView, over views of 25 and 45 rows (levels 0,1,1,1,1 repeated, and all
//   0), with a stored source and with a temporary source that OnOpenPage fills. Observed: the rows OnAfterGetRecord ran for during
//   OpenView (as ranges of entry numbers, in call order), then the entry numbers a First + Next walk shows and the rows
//   OnAfterGetRecord ran for during the walk, then the triggers of Close.
// local object: the tree pages are the shape under test; the log records OnAfterGetRecord
// BC versions: 27, 28, 29

table 77730 "PG6 TR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; Level; Integer) { DataClassification = SystemMetadata; }
        field(3; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 77731 "PG6 TR Stored Tree"
{
    PageType = List;
    SourceTable = "PG6 TR Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Lvl;
                ShowAsTree = true;

                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 TR Log";
        Lvl: Integer;

    trigger OnOpenPage()
    begin
        Log.Note('open');
    end;

    trigger OnAfterGetRecord()
    begin
        Lvl := Rec.Level;
        Log.Agr(Rec."Entry No.");
    end;

    trigger OnClosePage()
    begin
        Log.Note('close');
    end;
}

page 77732 "PG6 TR Temp Tree"
{
    PageType = List;
    SourceTable = "PG6 TR Row";
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Lvl;
                ShowAsTree = true;

                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 TR Log";
        Lvl: Integer;

    trigger OnOpenPage()
    var
        i: Integer;
    begin
        for i := 1 to Log.RowCount() do begin
            Rec.Init();
            Rec."Entry No." := i;
            Rec.Level := Log.LevelOf(i);
            Rec.Name := 'R' + Format(i);
            Rec.Insert();
        end;
        Log.Note('open');
    end;

    trigger OnAfterGetRecord()
    begin
        Lvl := Rec.Level;
        Log.Agr(Rec."Entry No.");
    end;

    trigger OnClosePage()
    begin
        Log.Note('close');
    end;
}

codeunit 77733 "PG6 TR Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        RunStart: Integer;
        RunEnd: Integer;
        Rows: Integer;
        Mixed: Boolean;

    procedure Reset(NewRows: Integer; NewMixed: Boolean)
    begin
        Entries := '';
        RunStart := 0;
        RunEnd := 0;
        Rows := NewRows;
        Mixed := NewMixed;
    end;

    procedure RowCount(): Integer
    begin
        exit(Rows);
    end;

    // Levels 0,1,1,1,1 repeated when mixed, else 0.
    procedure LevelOf(EntryNo: Integer): Integer
    begin
        if Mixed and ((EntryNo - 1) mod 5 <> 0) then
            exit(1);
        exit(0);
    end;

    // OnAfterGetRecord calls are written as ranges: agr(1-25) for 1, 2, ..., 25 in that order.
    procedure Agr(EntryNo: Integer)
    begin
        if (RunEnd <> 0) and (EntryNo = RunEnd + 1) then begin
            RunEnd := EntryNo;
            exit;
        end;
        FlushRun();
        RunStart := EntryNo;
        RunEnd := EntryNo;
    end;

    procedure Note(Line: Text)
    begin
        FlushRun();
        AddEntry(Line);
    end;

    local procedure FlushRun()
    begin
        if RunEnd = 0 then
            exit;
        if RunStart = RunEnd then
            AddEntry('agr(' + Format(RunStart) + ')')
        else
            AddEntry('agr(' + Format(RunStart) + '-' + Format(RunEnd) + ')');
        RunStart := 0;
        RunEnd := 0;
    end;

    local procedure AddEntry(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        FlushRun();
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

codeunit 77734 "PG6 TR Tree Open Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 TR Log";

    local procedure Initialize(Rows: Integer; Mixed: Boolean; Stored: Boolean)
    var
        Row: Record "PG6 TR Row";
        i: Integer;
    begin
        Observer.Discard();
        Row.DeleteAll();
        Log.Reset(Rows, Mixed);
        if Stored then
            for i := 1 to Rows do begin
                Row.Init();
                Row."Entry No." := i;
                Row.Level := Log.LevelOf(i);
                Row.Name := 'R' + Format(i);
                Row.Insert();
            end;
    end;

    local procedure WalkStored(var P: TestPage "PG6 TR Stored Tree")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Observer.Observe('open', Log.Take());
        if P.First() then
            repeat
                Seen += P."Entry No.".Value() + ',';
                Steps += 1;
            until (not P.Next()) or (Steps >= 60);
        Observer.Observe('walk-seen', Seen);
        Observer.Observe('walk-log', Log.Take());
        P.Close();
        Observer.Observe('closed', Log.Take());
    end;

    local procedure WalkTemp(var P: TestPage "PG6 TR Temp Tree")
    var
        Seen: Text;
        Steps: Integer;
    begin
        Observer.Observe('open', Log.Take());
        if P.First() then
            repeat
                Seen += P."Entry No.".Value() + ',';
                Steps += 1;
            until (not P.Next()) or (Steps >= 60);
        Observer.Observe('walk-seen', Seen);
        Observer.Observe('walk-log', Log.Take());
        P.Close();
        Observer.Observe('closed', Log.Take());
    end;

    [Test]
    procedure Stored_25RowsMixed_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Stored Tree";
    begin
        Initialize(25, true, true);
        P.OpenView();
        WalkStored(P);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_45RowsMixed_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Stored Tree";
    begin
        Initialize(45, true, true);
        P.OpenView();
        WalkStored(P);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_45RowsLevelZero_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Stored Tree";
    begin
        Initialize(45, false, true);
        P.OpenView();
        WalkStored(P);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_45RowsMixed_OpenViewClose()
    var
        P: TestPage "PG6 TR Stored Tree";
    begin
        Initialize(45, true, true);
        P.OpenView();
        Observer.Observe('open', Log.Take());
        P.Close();
        Observer.Observe('closed', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Temp_25RowsMixed_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Temp Tree";
    begin
        Initialize(25, true, false);
        P.OpenView();
        WalkTemp(P);
        Observer.Finish();
    end;

    [Test]
    procedure Temp_45RowsMixed_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Temp Tree";
    begin
        Initialize(45, true, false);
        P.OpenView();
        WalkTemp(P);
        Observer.Finish();
    end;

    [Test]
    procedure Temp_45RowsLevelZero_OpenViewWalkClose()
    var
        P: TestPage "PG6 TR Temp Tree";
    begin
        Initialize(45, false, false);
        P.OpenView();
        WalkTemp(P);
        Observer.Finish();
    end;

    [Test]
    procedure Temp_45RowsMixed_OpenViewClose()
    var
        P: TestPage "PG6 TR Temp Tree";
    begin
        Initialize(45, true, false);
        P.OpenView();
        Observer.Observe('open', Log.Take());
        P.Close();
        Observer.Observe('closed', Log.Take());
        Observer.Finish();
    end;
}
