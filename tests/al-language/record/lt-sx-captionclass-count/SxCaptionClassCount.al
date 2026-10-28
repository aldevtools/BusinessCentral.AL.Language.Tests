// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 89670 and 89671, log codeunit 89672 (used only by test codeunit 89677), pages 89673 to 89676, test codeunit 89677
// Probe: from al-runner issue 5870 (reporter's real-BC run on 29.0.54011.55407, a Card with ONE CaptionClass field: 8 empty-record runs per
//   OpenEdit, none on GoToRecord or Close). Every literal asserted below is what BC produced.
// Facts: a Card or List page over a table with CaptionClass expression fields, three cycles of open, GoToRecord (to row 2 of 3) and Close in
//   one test; the counts are the same in all three cycles on 27.5, 28.5 and 29.0. The expression runs with an empty record (Id 0) and with
//   a row (Id <> 0); the log counts both. Table with ONE expression field: Card 8 empty runs and 1 row run on the open, GoToRecord 1 row
//   run (with the row the page stood on), Close none; List 7 empty runs and 1 row run on the open, GoToRecord and Close none. Table with
//   TWO expression fields (same expression): Card 18 empty and 2 row runs on the open, GoToRecord 2 row runs; List 16 empty and 2 row
//   runs. OpenView and OpenEdit give the same counts. The count is not 20 per field and not linear in the number of fields.
//   Stability: the issue reporter saw 8 for the one-field Card in 12 cycles over three runs on 29.0; the counts here were taken from one
//   CI run per major (24 cycles in all). The comments of QdCaptionClassAreas.al record 240 to 492 calls for its 12-field Card across
//   runs, so these exact counts may not hold for every tier; a count that differs on a later run is to be reported, not re-pinned.
// Neighbours: record/lt-qd-captionclass-areas/QdCaptionClassAreas.al pins which expressions run on a page open (12 fields); its comments record
//   counts that differ between runs. This file counts per step (open, GoToRecord, Close) for tables with one and two expression fields.
// BC versions: 27, 28, 29

table 89670 "LT SX One"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { Caption = 'Amount'; CaptionClass = SxCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure SxCc(): Text[80]
    var
        Log: Codeunit "LT SX Log";
    begin
        Log.Hit(Id);
        exit('3,Row ' + Format(Id));
    end;
}

table 89671 "LT SX Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { Caption = 'Amount'; CaptionClass = SxCc(); }
        field(3; Quantity; Decimal) { Caption = 'Quantity'; CaptionClass = SxCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure SxCc(): Text[80]
    var
        Log: Codeunit "LT SX Log";
    begin
        Log.Hit(Id);
        exit('3,Row ' + Format(Id));
    end;
}

codeunit 89672 "LT SX Log"
{
    SingleInstance = true;

    var
        EmptyRuns: Integer;
        RowRuns: Integer;

    procedure Hit(RowId: Integer)
    begin
        if RowId = 0 then
            EmptyRuns += 1
        else
            RowRuns += 1;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := 'empty=' + Format(EmptyRuns) + ' rows=' + Format(RowRuns);
        EmptyRuns := 0;
        RowRuns := 0;
        exit(Result);
    end;

    procedure TakeEmpty(): Integer
    var
        Result: Integer;
    begin
        Result := EmptyRuns;
        EmptyRuns := 0;
        RowRuns := 0;
        exit(Result);
    end;
}

page 89673 "LT SX Card One"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SX One";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 89674 "LT SX Card Two"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SX Two";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }
}

page 89675 "LT SX List One"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SX One";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 89676 "LT SX List Two"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SX Two";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 89677 "LT SX CaptionClass Count"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SX Log";

    [Test]
    procedure SX_CardOne_OpenEdit()
    var
        P: TestPage "LT SX Card One";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedOne();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenEdit();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetOne(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_CardOne_OpenView()
    var
        P: TestPage "LT SX Card One";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedOne();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenView();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetOne(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|open empty=8 rows=1 goto empty=0 rows=1 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_CardTwo_OpenEdit()
    var
        P: TestPage "LT SX Card Two";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedTwo();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenEdit();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetTwo(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_CardTwo_OpenView()
    var
        P: TestPage "LT SX Card Two";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedTwo();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenView();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetTwo(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|open empty=18 rows=2 goto empty=0 rows=2 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_ListOne_OpenEdit()
    var
        P: TestPage "LT SX List One";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedOne();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenEdit();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetOne(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_ListOne_OpenView()
    var
        P: TestPage "LT SX List One";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedOne();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenView();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetOne(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|open empty=7 rows=1 goto empty=0 rows=0 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_ListTwo_OpenEdit()
    var
        P: TestPage "LT SX List Two";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedTwo();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenEdit();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetTwo(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|');
        Observer.Verify();
    end;

    [Test]
    procedure SX_ListTwo_OpenView()
    var
        P: TestPage "LT SX List Two";
        Observer: Codeunit "Probe Observer";
        Got: Text;
        Round: Integer;
    begin
        SeedTwo();
        for Round := 1 to 3 do begin
            Log.Take();
            P.OpenView();
            Got += 'open ' + Log.Take();
            P.GoToRecord(GetTwo(2));
            Got += ' goto ' + Log.Take();
            P.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Expect('cycles', 'open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|open empty=16 rows=2 goto empty=0 rows=0 close empty=0 rows=0|');
        Observer.Verify();
    end;

    local procedure SeedOne()
    var
        Row: Record "LT SX One";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take();
    end;

    local procedure SeedTwo()
    var
        Row: Record "LT SX Two";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take();
    end;

    local procedure GetOne(RowId: Integer) Row: Record "LT SX One"
    begin
        Row.Get(RowId);
    end;

    local procedure GetTwo(RowId: Integer) Row: Record "LT SX Two"
    begin
        Row.Get(RowId);
    end;
}
