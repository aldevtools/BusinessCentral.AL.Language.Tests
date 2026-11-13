// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 67211-67213, pages 67211-67214, page extension 67215, test codeunit 67216 (TP R7392 *)
// Probe: from al-runner issue 7392 (the reporter's smaller shape; follow-up of 7362 and 7748, see ProviderPartOutsideFactBoxes.al for the
//   same chain on a header with lines). A Card over a header table with a ListPart `Lines` (SubPageLink to the header's key), and a page
//   extension that adds a ListPart `Details` after it, outside FactBoxes, with Provider = Lines and a SubPageLink to two fields of the
//   Provider's row. The test opens the Card, goes to a header with no lines and calls First() on both parts (the reporter saw false and
//   false on BC 29.1), or to a header with one line and one detail (the control). Neighbors: Details.First() without Lines.First() first;
//   the values both parts show without a move; Last() and Next() on both parts; OpenEdit with GoToKey; and the same chain declared in the
//   base page, with Details in the FactBoxes area.
// BC versions: 27+ (tested by the corpus CI matrix)

table 67211 "TP R7392 Header"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67212 "TP R7392 Line"
{
    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }
    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}

table 67213 "TP R7392 Detail"
{
    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Seq; Integer) { }
    }
    keys
    {
        key(PK; "Header No.", "Line No.", Seq) { Clustered = true; }
    }
}

page 67211 "TP R7392 Card"
{
    PageType = Card;
    SourceTable = "TP R7392 Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "TP R7392 Line Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}

page 67212 "TP R7392 Line Part"
{
    PageType = ListPart;
    SourceTable = "TP R7392 Line";
    ApplicationArea = All;
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

page 67213 "TP R7392 Detail Part"
{
    PageType = ListPart;
    SourceTable = "TP R7392 Detail";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Seq; Rec.Seq) { ApplicationArea = All; }
            }
        }
    }
}

// The neighbor host: the same chain declared in the base page, Details in the FactBoxes area.
page 67214 "TP R7392 FactBox Card"
{
    PageType = Card;
    SourceTable = "TP R7392 Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "TP R7392 Line Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Details; "TP R7392 Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Header No." = field("Header No."), "Line No." = field("Line No.");
            }
        }
    }
}

pageextension 67215 "TP R7392 Card Ext" extends "TP R7392 Card"
{
    layout
    {
        addafter(Lines)
        {
            part(Details; "TP R7392 Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Header No." = field("Header No."), "Line No." = field("Line No.");
            }
        }
    }
}

codeunit 67216 "TP R7392 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // H1 has one line (10000) with one detail (Seq 1); H2 has no line.
    local procedure Setup()
    var
        Header: Record "TP R7392 Header";
        Line: Record "TP R7392 Line";
        Detail: Record "TP R7392 Detail";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Detail.DeleteAll();
        Header."No." := 'H1';
        Header.Insert();
        Header."No." := 'H2';
        Header.Insert();
        Line."Header No." := 'H1';
        Line."Line No." := 10000;
        Line.Insert();
        Detail."Header No." := 'H1';
        Detail."Line No." := 10000;
        Detail.Seq := 1;
        Detail.Insert();
    end;

    [Test]
    procedure TP7392_ExtOutside_NoLines_OpenView_First()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Header.Get('H2');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('lines first', Format(Card.Lines.First()));
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_ExtOutside_WithLines_OpenView_First()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Header.Get('H1');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('details value before', Card.Details.Seq.Value());
        Observer.Observe('lines first', Format(Card.Lines.First()));
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_ExtOutside_NoLines_OpenView_DetailsFirstOnly()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Header.Get('H2');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_ExtOutside_NoLines_OpenView_NoMove()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Header.Get('H2');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_ExtOutside_NoLines_OpenView_LastNext()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Header.Get('H2');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('lines last', Format(Card.Lines.Last()));
        Observer.Observe('details last', Format(Card.Details.Last()));
        Observer.Observe('lines next', Format(Card.Lines.Next()));
        Observer.Observe('details next', Format(Card.Details.Next()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_ExtOutside_NoLines_OpenEditGoToKey_First()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP R7392 Card";
    begin
        Setup();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Observer.Observe('lines first', Format(Card.Lines.First()));
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_BaseFactBoxes_NoLines_OpenView_First()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 FactBox Card";
    begin
        Setup();
        Header.Get('H2');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('lines first', Format(Card.Lines.First()));
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TP7392_BaseFactBoxes_WithLines_OpenView_First()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "TP R7392 Header";
        Card: TestPage "TP R7392 FactBox Card";
    begin
        Setup();
        Header.Get('H1');
        Card.OpenView();
        Card.GoToRecord(Header);
        Observer.Observe('details value before', Card.Details.Seq.Value());
        Observer.Observe('lines first', Format(Card.Lines.First()));
        Observer.Observe('details first', Format(Card.Details.First()));
        Observer.Observe('lines value', Card.Lines."Line No.".Value());
        Observer.Observe('details value', Card.Details.Seq.Value());
        Card.Close();
        Observer.Finish();
    end;
}
