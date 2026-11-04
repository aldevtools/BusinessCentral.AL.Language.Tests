// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95167 and 95168, pages 95169-95172, test codeunit 95173
// Probe: (al-runner issue 6926) a Card host opened for edit on a header with two lines, and four ListPart controls (DelayedInsert)
// linked to it: one whose part control says Editable = false, one whose page says Editable = false, one whose page says
// InsertAllowed = false, and one with none of these. On each part: First, then Next until it answers No (at most four times), Last,
// Next from the last row, Previous, GoToRecord of a shown row and of a row of another header; what each answers and which row the
// part then shows, and what is stored at Close.
// Seen on BC 29 (Linux CI): on the three parts that are not editable or allow no insert, Next from the last row answers No and the part
// stays on that row, so First/Next visits each row once; Previous from the last row goes back one row. On the plain part Next from the
// last row answers Yes onto the blank new-row line, the next Next answers No, and Previous from that line goes back to the last row.
// GoToRecord of a shown row answers Yes; of a row of another header No, and the part stays where it was. Nothing is stored.
// BC versions: 27+

table 95167 "LT R6926 Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95168 "LT R6926 Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Head No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 95169 "LT R6926 Lines"
{
    PageType = ListPart;
    SourceTable = "LT R6926 Line";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 95170 "LT R6926 Lines RO"
{
    PageType = ListPart;
    SourceTable = "LT R6926 Line";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 95171 "LT R6926 Lines NoIns"
{
    PageType = ListPart;
    SourceTable = "LT R6926 Line";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 95172 "LT R6926 Card"
{
    PageType = Card;
    SourceTable = "LT R6926 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(CtlRO; "LT R6926 Lines")
            {
                ApplicationArea = All;
                Editable = false;
                SubPageLink = "Head No." = field("No.");
            }
            part(PageRO; "LT R6926 Lines RO")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
            part(NoIns; "LT R6926 Lines NoIns")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
            part(Plain; "LT R6926 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }
}

codeunit 95173 "LT R6926 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT R6926 Head";
        Line: Record "LT R6926 Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        AddLine('L1', 'H1');
        AddLine('L2', 'H1');
        AddLine('L9', 'H2');
    end;

    local procedure AddLine(LineNo: Code[10]; HeadNo: Code[10])
    var
        Line: Record "LT R6926 Line";
    begin
        Line."Line No." := LineNo;
        Line."Head No." := HeadNo;
        Line.Insert();
    end;

    local procedure Open(var Card: TestPage "LT R6926 Card")
    var
        Head: Record "LT R6926 Head";
    begin
        Head.Get('H1');
        Card.OpenEdit();
        Card.GoToRecord(Head);
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer")
    var
        Line: Record "LT R6926 Line";
        Rows: Text;
    begin
        if Line.FindSet() then
            repeat
                Rows += '[' + Line."Line No." + '|' + Line."Head No." + ']';
            until Line.Next() = 0;
        Observer.Observe('stored', Rows);
    end;

    local procedure Row(Shown: Text): Text
    begin
        exit('[' + Shown + ']');
    end;

    [Test]
    procedure R6926_CtlRO_Walk()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Steps: Text;
        i: Integer;
        Going: Boolean;
    begin
        Seed();
        Open(Card);
        Observer.Observe('first', Format(Card.CtlRO.First()) + Row(Card.CtlRO."Line No.".Value()));
        Going := true;
        while Going and (i < 4) do begin
            i += 1;
            if Steps <> '' then
                Steps += ' ';
            Going := Card.CtlRO.Next();
            if Going then
                Steps += 'Yes' + Row(Card.CtlRO."Line No.".Value())
            else
                Steps += 'No';
        end;
        Observer.Observe('next_walk', Steps);
        Observer.Observe('row_after_walk', Row(Card.CtlRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('first', 'Yes[L1]');
        Observer.Expect('next_walk', 'Yes[L2] No');
        Observer.Expect('row_after_walk', '[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_CtlRO_LastNextPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
    begin
        Seed();
        Open(Card);
        Observer.Observe('last', Format(Card.CtlRO.Last()) + Row(Card.CtlRO."Line No.".Value()));
        Observer.Observe('next_after_last', Format(Card.CtlRO.Next()) + Row(Card.CtlRO."Line No.".Value()));
        Observer.Observe('previous', Format(Card.CtlRO.Previous()) + Row(Card.CtlRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('last', 'Yes[L2]');
        Observer.Expect('next_after_last', 'No[L2]');
        Observer.Expect('previous', 'Yes[L1]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_CtlRO_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Line: Record "LT R6926 Line";
    begin
        Seed();
        Open(Card);
        Line.Get('L2');
        Observer.Observe('goto_shown', Format(Card.CtlRO.GoToRecord(Line)) + Row(Card.CtlRO."Line No.".Value()));
        Observer.Observe('next_after_goto', Format(Card.CtlRO.Next()) + Row(Card.CtlRO."Line No.".Value()));
        Line.Get('L9');
        Observer.Observe('goto_other_head', Format(Card.CtlRO.GoToRecord(Line)) + Row(Card.CtlRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('goto_shown', 'Yes[L2]');
        Observer.Expect('next_after_goto', 'No[L2]');
        Observer.Expect('goto_other_head', 'No[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;
    [Test]
    procedure R6926_PageRO_Walk()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Steps: Text;
        i: Integer;
        Going: Boolean;
    begin
        Seed();
        Open(Card);
        Observer.Observe('first', Format(Card.PageRO.First()) + Row(Card.PageRO."Line No.".Value()));
        Going := true;
        while Going and (i < 4) do begin
            i += 1;
            if Steps <> '' then
                Steps += ' ';
            Going := Card.PageRO.Next();
            if Going then
                Steps += 'Yes' + Row(Card.PageRO."Line No.".Value())
            else
                Steps += 'No';
        end;
        Observer.Observe('next_walk', Steps);
        Observer.Observe('row_after_walk', Row(Card.PageRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('first', 'Yes[L1]');
        Observer.Expect('next_walk', 'Yes[L2] No');
        Observer.Expect('row_after_walk', '[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_PageRO_LastNextPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
    begin
        Seed();
        Open(Card);
        Observer.Observe('last', Format(Card.PageRO.Last()) + Row(Card.PageRO."Line No.".Value()));
        Observer.Observe('next_after_last', Format(Card.PageRO.Next()) + Row(Card.PageRO."Line No.".Value()));
        Observer.Observe('previous', Format(Card.PageRO.Previous()) + Row(Card.PageRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('last', 'Yes[L2]');
        Observer.Expect('next_after_last', 'No[L2]');
        Observer.Expect('previous', 'Yes[L1]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_PageRO_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Line: Record "LT R6926 Line";
    begin
        Seed();
        Open(Card);
        Line.Get('L2');
        Observer.Observe('goto_shown', Format(Card.PageRO.GoToRecord(Line)) + Row(Card.PageRO."Line No.".Value()));
        Observer.Observe('next_after_goto', Format(Card.PageRO.Next()) + Row(Card.PageRO."Line No.".Value()));
        Line.Get('L9');
        Observer.Observe('goto_other_head', Format(Card.PageRO.GoToRecord(Line)) + Row(Card.PageRO."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('goto_shown', 'Yes[L2]');
        Observer.Expect('next_after_goto', 'No[L2]');
        Observer.Expect('goto_other_head', 'No[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;
    [Test]
    procedure R6926_NoIns_Walk()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Steps: Text;
        i: Integer;
        Going: Boolean;
    begin
        Seed();
        Open(Card);
        Observer.Observe('first', Format(Card.NoIns.First()) + Row(Card.NoIns."Line No.".Value()));
        Going := true;
        while Going and (i < 4) do begin
            i += 1;
            if Steps <> '' then
                Steps += ' ';
            Going := Card.NoIns.Next();
            if Going then
                Steps += 'Yes' + Row(Card.NoIns."Line No.".Value())
            else
                Steps += 'No';
        end;
        Observer.Observe('next_walk', Steps);
        Observer.Observe('row_after_walk', Row(Card.NoIns."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('first', 'Yes[L1]');
        Observer.Expect('next_walk', 'Yes[L2] No');
        Observer.Expect('row_after_walk', '[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_NoIns_LastNextPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
    begin
        Seed();
        Open(Card);
        Observer.Observe('last', Format(Card.NoIns.Last()) + Row(Card.NoIns."Line No.".Value()));
        Observer.Observe('next_after_last', Format(Card.NoIns.Next()) + Row(Card.NoIns."Line No.".Value()));
        Observer.Observe('previous', Format(Card.NoIns.Previous()) + Row(Card.NoIns."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('last', 'Yes[L2]');
        Observer.Expect('next_after_last', 'No[L2]');
        Observer.Expect('previous', 'Yes[L1]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_NoIns_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Line: Record "LT R6926 Line";
    begin
        Seed();
        Open(Card);
        Line.Get('L2');
        Observer.Observe('goto_shown', Format(Card.NoIns.GoToRecord(Line)) + Row(Card.NoIns."Line No.".Value()));
        Observer.Observe('next_after_goto', Format(Card.NoIns.Next()) + Row(Card.NoIns."Line No.".Value()));
        Line.Get('L9');
        Observer.Observe('goto_other_head', Format(Card.NoIns.GoToRecord(Line)) + Row(Card.NoIns."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('goto_shown', 'Yes[L2]');
        Observer.Expect('next_after_goto', 'No[L2]');
        Observer.Expect('goto_other_head', 'No[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;
    [Test]
    procedure R6926_Plain_Walk()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Steps: Text;
        i: Integer;
        Going: Boolean;
    begin
        Seed();
        Open(Card);
        Observer.Observe('first', Format(Card.Plain.First()) + Row(Card.Plain."Line No.".Value()));
        Going := true;
        while Going and (i < 4) do begin
            i += 1;
            if Steps <> '' then
                Steps += ' ';
            Going := Card.Plain.Next();
            if Going then
                Steps += 'Yes' + Row(Card.Plain."Line No.".Value())
            else
                Steps += 'No';
        end;
        Observer.Observe('next_walk', Steps);
        Observer.Observe('row_after_walk', Row(Card.Plain."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('first', 'Yes[L1]');
        Observer.Expect('next_walk', 'Yes[L2] Yes[] No');
        Observer.Expect('row_after_walk', '[]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_Plain_LastNextPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
    begin
        Seed();
        Open(Card);
        Observer.Observe('last', Format(Card.Plain.Last()) + Row(Card.Plain."Line No.".Value()));
        Observer.Observe('next_after_last', Format(Card.Plain.Next()) + Row(Card.Plain."Line No.".Value()));
        Observer.Observe('previous', Format(Card.Plain.Previous()) + Row(Card.Plain."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('last', 'Yes[L2]');
        Observer.Expect('next_after_last', 'Yes[]');
        Observer.Expect('previous', 'Yes[L2]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;

    [Test]
    procedure R6926_Plain_GoToRecord()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6926 Card";
        Line: Record "LT R6926 Line";
    begin
        Seed();
        Open(Card);
        Line.Get('L2');
        Observer.Observe('goto_shown', Format(Card.Plain.GoToRecord(Line)) + Row(Card.Plain."Line No.".Value()));
        Observer.Observe('next_after_goto', Format(Card.Plain.Next()) + Row(Card.Plain."Line No.".Value()));
        Line.Get('L9');
        Observer.Observe('goto_other_head', Format(Card.Plain.GoToRecord(Line)) + Row(Card.Plain."Line No.".Value()));
        Card.Close();
        Stored(Observer);
        Observer.Expect('goto_shown', 'Yes[L2]');
        Observer.Expect('next_after_goto', 'Yes[]');
        Observer.Expect('goto_other_head', 'No[]');
        Observer.Expect('stored', '[L1|H1][L2|H1][L9|H2]');
        Observer.Verify();
    end;
}
