// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: own tables 89670 and 89671, log codeunit 89672 (used only by test codeunit 89677), pages 89673 to 89676, test codeunit 89677
// Probe: from al-runner issue 5870 (reporter's real-BC run on 29.0.54011.55407, a Card with ONE CaptionClass field: 8 empty-record runs per
//   OpenEdit, none on GoToRecord or Close). Every literal asserted below is what BC produced.
// Facts: OBSERVE
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_CardOne_OpenView()
    var
        P: TestPage "LT SX Card One";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_CardTwo_OpenEdit()
    var
        P: TestPage "LT SX Card Two";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_CardTwo_OpenView()
    var
        P: TestPage "LT SX Card Two";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_ListOne_OpenEdit()
    var
        P: TestPage "LT SX List One";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_ListOne_OpenView()
    var
        P: TestPage "LT SX List One";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_ListTwo_OpenEdit()
    var
        P: TestPage "LT SX List Two";
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
        Error('OBSERVE:' + Got);
    end;

    [Test]
    procedure SX_ListTwo_OpenView()
    var
        P: TestPage "LT SX List Two";
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
        Error('OBSERVE:' + Got);
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
