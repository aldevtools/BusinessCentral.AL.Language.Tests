// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (PG EPR *)
// local object: the parts' SubPageLink forms and the part actions that read Rec are under test; the SingleInstance log is owned by
//   test codeunit 75171 only.
// Probe (al-runner issue 6924): what Rec holds in the code of a ListPart that shows NO row (its table has no row for the link), read by
//   an action of the part invoked through the TestPart, and by the part's OnAfterGetCurrRecord. Base Application's page 1178
//   "Doc. Attachment List Factbox" (SubPageLink = "Table ID" = const(..), "No." = field("No.")) exits its OpenInDetail action when
//   Rec."Table ID" is 0. SelectionFilterLinkedPartNoRow.al pins Rec in OnAfterGetCurrRecord of a Card's FactBox opened for view.
// Area (one cell per test, one observation per test): the link form (const + field, field only, const only, filter() of one value,
//   filter() of a range), FactBox against the content area, a Card against a Document host, OpenView / OpenEdit / OpenNew of the host,
//   InsertAllowed = false on the part (as page 1178) against the default (the part offers its new-row line on an edit host), a part with
//   rows against one without, the host moved by GoToRecord from a row with lines to one without, and OnAfterGetCurrRecord.
// BC versions: 27-29

table 75160 "PG EPR Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75161 "PG EPR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer) { DataClassification = SystemMetadata; }
        field(2; "No."; Code[20]) { DataClassification = SystemMetadata; }
        field(3; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(4; Kind; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Table ID", "No.", "Line No.") { Clustered = true; }
    }
}

// The shape of page 1178: a ListPart without the new-row line.
page 75162 "PG EPR Part NoInsert"
{
    PageType = ListPart;
    SourceTable = "PG EPR Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "PG EPR Log";
                begin
                    Log.AddAction('act=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No.") + '/' + Rec.Kind);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG EPR Log";
    begin
        Log.AddCurr('agcr=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No."));
    end;
}

// The same ListPart with InsertAllowed left at its default.
page 75163 "PG EPR Part Insert"
{
    PageType = ListPart;
    SourceTable = "PG EPR Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "PG EPR Log";
                begin
                    Log.AddAction('act=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No.") + '/' + Rec.Kind);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG EPR Log";
    begin
        Log.AddCurr('agcr=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No."));
    end;
}

page 75164 "PG EPR Card ConstField"
{
    PageType = Card;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            part(Inline; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(75160), "No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(75160), "No." = field("No.");
            }
        }
    }
}

page 75165 "PG EPR Card FieldOnly"
{
    PageType = Card;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}

page 75166 "PG EPR Card ConstOnly"
{
    PageType = Card;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(75160);
            }
        }
    }
}

page 75167 "PG EPR Card FilterOne"
{
    PageType = Card;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = filter(75160), "No." = field("No.");
            }
        }
    }
}

page 75168 "PG EPR Card FilterRange"
{
    PageType = Card;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = filter(75000 .. 75999), "No." = field("No.");
            }
        }
    }
}

page 75169 "PG EPR Document"
{
    PageType = Document;
    SourceTable = "PG EPR Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG EPR Part Insert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(75160), "No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPR Part NoInsert")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(75160), "No." = field("No.");
            }
        }
    }
}

codeunit 75170 "PG EPR Log"
{
    SingleInstance = true;

    var
        ActionLines: Text;
        Currs: Text;

    procedure Reset()
    begin
        ActionLines := '';
        Currs := '';
    end;

    procedure AddAction(Line: Text)
    begin
        if ActionLines <> '' then
            ActionLines += ' | ';
        ActionLines += Line;
    end;

    procedure AddCurr(Line: Text)
    begin
        if Currs <> '' then
            Currs += ' | ';
        Currs += Line;
    end;

    procedure ActionLog(): Text
    begin
        exit(ActionLines);
    end;

    procedure CurrLog(): Text
    begin
        exit(Currs);
    end;
}

codeunit 75171 "PG EPR Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "PG EPR Log";

    // Heads A and B, no line.
    local procedure Initialize()
    var
        Head: Record "PG EPR Head";
        Line: Record "PG EPR Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'A';
        Head.Insert();
        Head."No." := 'B';
        Head.Insert();
        Log.Reset();
    end;

    local procedure AddLine(No: Code[20]; LineNo: Integer; Kind: Code[10])
    var
        Line: Record "PG EPR Line";
    begin
        Line."Table ID" := 75160;
        Line."No." := No;
        Line."Line No." := LineNo;
        Line.Kind := Kind;
        Line.Insert();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenEdit_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenEdit();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenView();
        Card.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenEdit_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenEdit();
        Card.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_FactBoxFieldOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card FieldOnly";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_FactBoxConstOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstOnly";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160//0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_FactBoxFilterOneValue_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card FilterOne";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_FactBoxFilterRange_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card FilterRange";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure PartWithRow_CardOpenView_FactBoxConstField_ActionReadsRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/7/K');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenView_GoToRecordFromRowWithLines_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
        Head: Record "PG EPR Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Card.OpenView();
        Head.Get('B');
        Card.GoToRecord(Head);
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/B/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_CardOpenNew_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenNew();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160//0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_DocumentOpenEdit_ContentWithNewLine_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PG EPR Document";
    begin
        Initialize();
        Doc.OpenEdit();
        Doc.Lines.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Doc.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_DocumentOpenView_ContentWithNewLine_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PG EPR Document";
    begin
        Initialize();
        Doc.OpenView();
        Doc.Lines.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Doc.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_DocumentOpenEdit_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PG EPR Document";
    begin
        Initialize();
        Doc.OpenEdit();
        Doc.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Doc.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_DocumentOpenView_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PG EPR Document";
    begin
        Initialize();
        Doc.OpenView();
        Doc.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Doc.Close();
        Observer.Expect('action', 'act=75160/A/0/');
        Observer.Verify();
    end;

    // OnAfterGetCurrRecord of the two parts of the Card (the FactBox and the content part, the same link), opened for edit.
    [Test]
    procedure EmptyPart_CardOpenEdit_ConstField_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenEdit();
        Observer.Observe('curr', Log.CurrLog());
        Card.Close();
        Observer.Expect('curr', 'agcr=75160/A/0 | agcr=75160/A/0 | agcr=75160/A/0');
        Observer.Verify();
    end;

    // OnAfterGetCurrRecord of the FactBox of the Card with a field-only link, opened for view.
    [Test]
    procedure EmptyPart_CardOpenView_FieldOnly_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card FieldOnly";
    begin
        Initialize();
        Card.OpenView();
        Observer.Observe('curr', Log.CurrLog());
        Card.Close();
        Observer.Expect('curr', 'agcr=0/A/0');
        Observer.Verify();
    end;

    // The action twice: the second read sees what the first left.
    [Test]
    procedure EmptyPart_CardOpenView_FactBoxConstField_ActionTwice()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card ConstField";
    begin
        Initialize();
        Card.OpenView();
        Card.Box.ReadRec.Invoke();
        Card.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Card.Close();
        Observer.Expect('action', 'act=75160/A/0/ | act=75160/A/0/');
        Observer.Verify();
    end;

    // OnAfterGetCurrRecord of the one FactBox of the Card with a field-only link, opened for edit (the Card with two parts runs it
    // three times in all).
    [Test]
    procedure EmptyPart_CardOpenEdit_FieldOnly_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PG EPR Card FieldOnly";
    begin
        Initialize();
        Card.OpenEdit();
        Observer.Observe('curr', Log.CurrLog());
        Card.Close();
        Observer.Expect('curr', 'agcr=0/A/0 | agcr=0/A/0');
        Observer.Verify();
    end;
}
