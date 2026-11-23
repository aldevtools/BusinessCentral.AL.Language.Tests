// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 74775 and 74776, pages 74777, 74778 and 74779, test codeunit 74780
// Probe (al-runner issue 8873): written against a local BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: which rows a list part shows, and the part's Filter.GetFilter of the linked field, for SubPageLink = ... filter(<> '') ("not blank")
// on a Code field next to a field(...) link (the issue's shape), written without the blank (filter(<>'')), alone, and on a Text field;
// the same term in the RunPageLink of an action on a Code and a Text field (rows of the opened list and its Filter.GetFilter).
// BC versions: 27, 28, 29

table 74775 "LT SPNB Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 74776 "LT SPNB Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Arrival No."; Code[10]) { }
        field(4; Note; Text[30]) { }
    }

    keys { key(PK; "Header No.", "Line No.") { Clustered = true; } }
}

page 74777 "LT SPNB Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT SPNB Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field("Arrival No."; Rec."Arrival No.") { ApplicationArea = All; }
            }
        }
    }
}

page 74778 "LT SPNB Card"
{
    PageType = Card;
    SourceTable = "LT SPNB Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(CodeSpaced; "LT SPNB Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), "Arrival No." = filter(<> '');
            }
            part(CodeTight; "LT SPNB Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), "Arrival No." = filter(<>'');
            }
            part(CodeAlone; "LT SPNB Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Arrival No." = filter(<> '');
            }
            part(TextSpaced; "LT SPNB Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), Note = filter(<> '');
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCode)
            {
                ApplicationArea = All;
                RunObject = page "LT SPNB Line List";
                RunPageLink = "Arrival No." = filter(<> '');
            }
            action(RunText)
            {
                ApplicationArea = All;
                RunObject = page "LT SPNB Line List";
                RunPageLink = Note = filter(<> '');
            }
        }
    }
}

page 74779 "LT SPNB Line List"
{
    PageType = List;
    SourceTable = "LT SPNB Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field("Arrival No."; Rec."Arrival No.") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 74780 "LT SubPageLink Not Blank"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT SPNB Header";
        L: Record "LT SPNB Line";
    begin
        H.DeleteAll();
        L.DeleteAll();
        H."No." := 'H1';
        H.Insert();
        H."No." := 'H2';
        H.Insert();
        AddLine('H1', 1, '', '');
        AddLine('H1', 2, 'A1', 'N1');
        AddLine('H1', 3, 'A2', '');
        AddLine('H1', 4, '', 'N4');
        AddLine('H2', 5, 'A5', 'N5');
        AddLine('H2', 6, '', '');
    end;

    local procedure AddLine(HeaderNo: Code[10]; LineNo: Integer; Arrival: Code[10]; NoteText: Text[30])
    var
        L: Record "LT SPNB Line";
    begin
        L."Header No." := HeaderNo;
        L."Line No." := LineNo;
        L."Arrival No." := Arrival;
        L.Note := NoteText;
        L.Insert();
    end;

    local procedure OpenOn(var Card: TestPage "LT SPNB Card"; HeaderNo: Code[10])
    var
        H: Record "LT SPNB Header";
    begin
        H.Get(HeaderNo);
        Card.OpenView();
        Card.GoToRecord(H);
    end;

    [Test]
    procedure SubPageLink_CodeSpaced_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        if Card.CodeSpaced.First() then
            repeat
                Result += Card.CodeSpaced.LineNo.Value + ',';
            until not Card.CodeSpaced.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + Card.CodeSpaced.Filter.GetFilter("Arrival No.") + ']');
        Observer.Observe('head filter', '[' + Card.CodeSpaced.Filter.GetFilter("Header No.") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SubPageLink_CodeTight_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        if Card.CodeTight.First() then
            repeat
                Result += Card.CodeTight.LineNo.Value + ',';
            until not Card.CodeTight.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + Card.CodeTight.Filter.GetFilter("Arrival No.") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SubPageLink_CodeAlone_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        if Card.CodeAlone.First() then
            repeat
                Result += Card.CodeAlone.LineNo.Value + ',';
            until not Card.CodeAlone.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + Card.CodeAlone.Filter.GetFilter("Arrival No.") + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SubPageLink_TextSpaced_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        if Card.TextSpaced.First() then
            repeat
                Result += Card.TextSpaced.LineNo.Value + ',';
            until not Card.TextSpaced.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + Card.TextSpaced.Filter.GetFilter(Note) + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SubPageLink_CodeSpaced_OtherHost_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H2');
        if Card.CodeSpaced.First() then
            repeat
                Result += Card.CodeSpaced.LineNo.Value + ',';
            until not Card.CodeSpaced.Next();
        Observer.Observe('rows', Result);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RunPageLink_Code_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        List: TestPage "LT SPNB Line List";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        List.Trap();
        Card.RunCode.Invoke();
        if List.First() then
            repeat
                Result += List.LineNo.Value + ',';
            until not List.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + List.Filter.GetFilter("Arrival No.") + ']');
        List.Close();
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RunPageLink_Text_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT SPNB Card";
        List: TestPage "LT SPNB Line List";
        Result: Text;
    begin
        Seed();
        OpenOn(Card, 'H1');
        List.Trap();
        Card.RunText.Invoke();
        if List.First() then
            repeat
                Result += List.LineNo.Value + ',';
            until not List.Next();
        Observer.Observe('rows', Result);
        Observer.Observe('filter', '[' + List.Filter.GetFilter(Note) + ']');
        List.Close();
        Card.Close();
        Observer.Finish();
    end;
}
