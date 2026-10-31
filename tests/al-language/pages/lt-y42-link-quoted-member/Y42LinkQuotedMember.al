//sub:pages
// Gap cycle 4, spec G4-09: a SubPageLink or RunPageLink filter() / const() with a quoted Option or Enum member that has
// blanks (the Bank Acc. Reconciliation part link `filter(Open | "Bank Acc. Entry Applied" | "Check Entry Applied")` and the
// Transfer Order RunPageLink on an Enum). Observed: the rows of each part, what GetFilter / GetFilters give in the part's
// OnOpenPage and at its first OnAfterGetCurrRecord, and the TestPage Filter of the part. Unquoted links and the
// TableRelation form are pinned elsewhere (handlers/TestPageSubpagePartConstFilter.al, record/lt-table-relation-quotes/).

enum 92820 "LT Y42 Lq Kind"
{
    Extensible = false;

    value(0; "Inbound Transfer") { }
    value(1; "Outbound Transfer") { }
    value(2; Other) { }
}

table 92823 "LT Y42 Lq Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Acc No."; Code[20]) { }
        field(3; Open; Boolean) { }
        field(4; Status; Option)
        {
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(5; Kind; Enum "LT Y42 Lq Kind") { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 92824 "LT Y42 Lq Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Acc No."; Code[20]) { }
    }

    keys
    {
        key(PK; "Acc No.") { Clustered = true; }
    }
}

codeunit 92828 "LT Y42 Lq Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Filters(Tag: Text; var E: Record "LT Y42 Lq Entry")
    var
        Group: Integer;
        Fg4Status: Text;
    begin
        Group := E.FilterGroup();
        E.FilterGroup(4);
        Fg4Status := E.GetFilter(Status);
        E.FilterGroup(Group);
        Add(Tag + ' status=[' + E.GetFilter(Status) + '] kind=[' + E.GetFilter(Kind) + '] fg4status=[' + Fg4Status + '] all=[' + E.GetFilters() + ']');
    end;
}

page 92828 "LT Y42 Lq Part"
{
    PageType = ListPart;
    SourceTable = "LT Y42 Lq Entry";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Lq Log";
        Seen: Boolean;

    trigger OnOpenPage()
    begin
        L.Filters('part open', Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Seen then
            exit;
        Seen := true;
        L.Filters('part agcr', Rec);
    end;
}

// The Apply Bank Acc. Ledger Entries shape: the part sets the same Status filter itself in OnOpenPage.
page 92829 "LT Y42 Lq Part SetFilter"
{
    PageType = ListPart;
    SourceTable = "LT Y42 Lq Entry";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Lq Log";
        Seen: Boolean;

    trigger OnOpenPage()
    begin
        Rec.SetFilter(Status, '%1|%2|%3', Rec.Status::Open, Rec.Status::"Bank Acc. Entry Applied", Rec.Status::"Check Entry Applied");
        L.Filters('part2 open', Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Seen then
            exit;
        Seen := true;
        L.Filters('part2 agcr', Rec);
    end;
}

page 92830 "LT Y42 Lq Card"
{
    PageType = Card;
    SourceTable = "LT Y42 Lq Head";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Acc No."; Rec."Acc No.") { ApplicationArea = All; }
            part(P1; "LT Y42 Lq Part")
            {
                ApplicationArea = All;
                SubPageLink = "Acc No." = field("Acc No."), Open = const(true), Status = filter(Open | "Bank Acc. Entry Applied" | "Check Entry Applied");
            }
            part(P2; "LT Y42 Lq Part SetFilter")
            {
                ApplicationArea = All;
                SubPageLink = "Acc No." = field("Acc No."), Open = const(true), Status = filter(Open | "Bank Acc. Entry Applied" | "Check Entry Applied");
            }
            part(P3; "LT Y42 Lq Part")
            {
                ApplicationArea = All;
                SubPageLink = "Acc No." = field("Acc No."), Kind = filter("Inbound Transfer" | "Outbound Transfer");
            }
            part(P4; "LT Y42 Lq Part")
            {
                ApplicationArea = All;
                SubPageLink = "Acc No." = field("Acc No."), Status = const("Check Entry Applied");
            }
            part(P5; "LT Y42 Lq Part")
            {
                ApplicationArea = All;
                SubPageLink = "Acc No." = field("Acc No."), Status = filter(<> "Bank Acc. Entry Applied");
            }
        }
    }
}

page 92831 "LT Y42 Lq Entries"
{
    PageType = List;
    SourceTable = "LT Y42 Lq Entry";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y42 Lq Log";

    trigger OnOpenPage()
    begin
        L.Filters('list open', Rec);
    end;
}

// The Transfer Order shape: a RunPageLink filter() with quoted Enum members.
page 92832 "LT Y42 Lq Card Run"
{
    PageType = Card;
    SourceTable = "LT Y42 Lq Head";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Acc No."; Rec."Acc No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenEntries)
            {
                ApplicationArea = All;
                RunObject = page "LT Y42 Lq Entries";
                RunPageLink = Kind = filter("Inbound Transfer" | "Outbound Transfer"), "Acc No." = field("Acc No.");
            }
        }
    }
}

codeunit 92829 "LT Y42 Lq Link Quoted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y42 Lq Log";

    local procedure Seed()
    var
        H: Record "LT Y42 Lq Head";
        E: Record "LT Y42 Lq Entry";
    begin
        H.DeleteAll();
        E.DeleteAll();
        H."Acc No." := 'A1';
        H.Insert();
        H."Acc No." := 'A2';
        H.Insert();
        Add(1, 'A1', true, E.Status::Open, E.Kind::"Inbound Transfer");
        Add(2, 'A1', true, E.Status::"Bank Acc. Entry Applied", E.Kind::"Outbound Transfer");
        Add(3, 'A1', true, E.Status::"Check Entry Applied", E.Kind::Other);
        Add(4, 'A1', true, E.Status::Closed, E.Kind::"Inbound Transfer");
        Add(5, 'A1', false, E.Status::"Bank Acc. Entry Applied", E.Kind::"Inbound Transfer");
        Add(6, 'A2', true, E.Status::Open, E.Kind::"Outbound Transfer");
        Add(7, 'A1', true, E.Status::Open, E.Kind::Other);
        Add(8, 'A1', true, E.Status::"Check Entry Applied", E.Kind::"Outbound Transfer");
        L.Take();
    end;

    local procedure Add(No: Integer; Acc: Code[20]; IsOpen: Boolean; St: Option; K: Enum "LT Y42 Lq Kind")
    var
        E: Record "LT Y42 Lq Entry";
    begin
        E."Entry No." := No;
        E."Acc No." := Acc;
        E.Open := IsOpen;
        E.Status := St;
        E.Kind := K;
        E.Insert();
    end;

    local procedure OpenCard(var Card: TestPage "LT Y42 Lq Card")
    var
        H: Record "LT Y42 Lq Head";
    begin
        H.Get('A1');
        Card.OpenView();
        Card.GoToRecord(H);
    end;

    // Step 1 and 7: Option field, filter(A | "B C" | "D E").
    [Test]
    procedure Lq_Option_FilterQuoted()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y42 Lq Card";
        Rows: Text;
    begin
        Seed();
        OpenCard(Card);
        if Card.P1.First() then
            repeat
                Rows += Card.P1."Entry No.".Value() + ',';
            until not Card.P1.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter status', Card.P1.Filter.GetFilter(Status));
        Observer.Observe('log', L.Take());
        Card.Close();
        Observer.Finish();
    end;

    // Step 2: the same link, and the part sets the same filter in OnOpenPage (page 379 shape).
    [Test]
    procedure Lq_Option_PartAlsoSetsFilter()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y42 Lq Card";
        Rows: Text;
    begin
        Seed();
        OpenCard(Card);
        if Card.P2.First() then
            repeat
                Rows += Card.P2."Entry No.".Value() + ',';
            until not Card.P2.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter status', Card.P2.Filter.GetFilter(Status));
        Card.Close();
        Observer.Finish();
    end;

    // Step 3 and 7: Enum field, filter("B C" | "D E").
    [Test]
    procedure Lq_Enum_FilterQuoted()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y42 Lq Card";
        Rows: Text;
    begin
        Seed();
        OpenCard(Card);
        if Card.P3.First() then
            repeat
                Rows += Card.P3."Entry No.".Value() + ',';
            until not Card.P3.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter kind', Card.P3.Filter.GetFilter(Kind));
        Card.Close();
        Observer.Finish();
    end;

    // Step 4: const("B C").
    [Test]
    procedure Lq_Option_ConstQuoted()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y42 Lq Card";
        Rows: Text;
    begin
        Seed();
        OpenCard(Card);
        if Card.P4.First() then
            repeat
                Rows += Card.P4."Entry No.".Value() + ',';
            until not Card.P4.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter status', Card.P4.Filter.GetFilter(Status));
        Card.Close();
        Observer.Finish();
    end;

    // Step 5: filter(<> "B C").
    [Test]
    procedure Lq_Option_NotEqualQuoted()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y42 Lq Card";
        Rows: Text;
    begin
        Seed();
        OpenCard(Card);
        if Card.P5.First() then
            repeat
                Rows += Card.P5."Entry No.".Value() + ',';
            until not Card.P5.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter status', Card.P5.Filter.GetFilter(Status));
        Card.Close();
        Observer.Finish();
    end;

    // Step 6: RunPageLink filter() with quoted Enum members.
    [Test]
    procedure Lq_RunPageLink_EnumQuoted()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y42 Lq Head";
        Card: TestPage "LT Y42 Lq Card Run";
        List: TestPage "LT Y42 Lq Entries";
        Rows: Text;
    begin
        Seed();
        H.Get('A1');
        Card.OpenView();
        Card.GoToRecord(H);
        L.Take();
        List.Trap();
        Card.OpenEntries.Invoke();
        if List.First() then
            repeat
                Rows += List."Entry No.".Value() + ',';
            until not List.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('tp filter kind', List.Filter.GetFilter(Kind));
        Observer.Observe('log', L.Take());
        List.Close();
        Card.Close();
        Observer.Finish();
    end;
}
