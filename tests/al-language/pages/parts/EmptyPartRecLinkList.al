// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects declared in this file (PG EPL *)
// local object: the List hosts, the ListPart and its action that reads Rec are under test; the SingleInstance log is owned by test
//   codeunit 76850 only.
// Probe (al-runner issue 6924, List hosts): what Rec holds in the action of a ListPart that shows NO row, when the host is a
//   PageType = List page. EmptyPartRecLink.al measures Card and Document hosts. The reporter's host is a List page whose FactBox is
//   Base Application's page 1178 "Doc. Attachment List Factbox" (SubPageLink = "Table ID" = const(..), "No." = field(..)), opened
//   with OpenEdit, moved with GoToRecord, then the part's OpenInDetail action reads Rec."Table ID".
// Area (one cell per test): FactBox against the content area, OpenEdit against OpenView, the host as opened, after GoToRecord (from a
//   row without lines and from one with lines), after Next, the link form (const + field, field only, const only, filter() of one
//   value, filter() of a range), a link field of the host outside its key, a part with rows, a List without rows, and
//   OnAfterGetCurrRecord.
// BC versions: 27-29

table 76840 "PG EPL Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = SystemMetadata; }
        field(2; "Ref Code"; Code[20]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 76841 "PG EPL Line"
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
page 76842 "PG EPL Part"
{
    PageType = ListPart;
    SourceTable = "PG EPL Line";
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
                    Log: Codeunit "PG EPL Log";
                begin
                    Log.AddAction('act=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No.") + '/' + Rec.Kind);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG EPL Log";
    begin
        Log.AddCurr('agcr=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No."));
    end;
}

page 76843 "PG EPL List ConstField"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
            part(Inline; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(76840), "No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(76840), "No." = field("No.");
            }
        }
    }
}

// The link fields of the following Lists differ from the first one; each has only the FactBox.
page 76844 "PG EPL List FieldOnly"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}

page 76845 "PG EPL List ConstOnly"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(76840);
            }
        }
    }
}

page 76846 "PG EPL List FilterOne"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = filter(76840), "No." = field("No.");
            }
        }
    }
}

page 76847 "PG EPL List FilterRange"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = filter(76000 .. 76999), "No." = field("No.");
            }
        }
    }
}

// The reporter's link: the field of the host is outside its key.
page 76848 "PG EPL List RefCode"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Heads)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Box; "PG EPL Part")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(76840), "No." = field("Ref Code");
            }
        }
    }
}

codeunit 76849 "PG EPL Log"
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

codeunit 76850 "PG EPL Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "PG EPL Log";

    // Heads A and B (Ref Code RA and RB), no line.
    local procedure Initialize()
    var
        Head: Record "PG EPL Head";
        Line: Record "PG EPL Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'A';
        Head."Ref Code" := 'RA';
        Head.Insert();
        Head."No." := 'B';
        Head."Ref Code" := 'RB';
        Head.Insert();
        Log.Reset();
    end;

    local procedure AddLine(No: Code[20]; LineNo: Integer; Kind: Code[10])
    var
        Line: Record "PG EPL Line";
    begin
        Line."Table ID" := 76840;
        Line."No." := No;
        Line."Line No." := LineNo;
        Line.Kind := Kind;
        Line.Insert();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecordFromRowWithLines_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_Next_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Observer.Observe('next', Format(Host.Next()));
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_NextFromRowWithLines_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Host.OpenEdit();
        Observer.Observe('next', Format(Host.Next()));
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_ContentConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Inline.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecordFromRowWithLines_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_Next_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Observer.Observe('next', Format(Host.Next()));
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_NextFromRowWithLines_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Host.OpenView();
        Observer.Observe('next', Format(Host.Next()));
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxFieldOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FieldOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxFieldOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FieldOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxConstOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxConstOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxFilterOneValue_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterOne";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxFilterOneValue_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterOne";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxFilterRange_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterRange";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxFilterRange_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterRange";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_FactBoxFieldOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FieldOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxFieldOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FieldOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_FactBoxConstOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxConstOnly_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstOnly";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_FactBoxFilterOneValue_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterOne";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxFilterOneValue_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterOne";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_FactBoxFilterRange_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterRange";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxFilterRange_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List FilterRange";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    // The reporter's shape: OpenEdit, GoToRecord, then the FactBox action.
    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxRefCode_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RefCode";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_FactBoxRefCode_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RefCode";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_FactBoxRefCode_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RefCode";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PartWithRow_ListOpenEdit_FactBoxConstField_ActionReadsRow()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('A', 7, 'K');
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PartWithRow_ListOpenEdit_GoToRecord_FactBoxConstField_ActionReadsRow()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        AddLine('B', 8, 'L');
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    // The List shows no row.
    [Test]
    procedure EmptyPart_ListOpenEdit_NoHeads_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Head.DeleteAll();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_NoHeads_FactBoxConstField_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Head.DeleteAll();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_FactBoxConstField_ActionTwice()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_ConstField_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_ConstField_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Log.Reset();
        Head.Get('B');
        Host.GoToRecord(Head);
        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_ConstField_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToRecord_ConstField_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Log.Reset();
        Head.Get('B');
        Host.GoToRecord(Head);
        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Finish();
    end;
}
