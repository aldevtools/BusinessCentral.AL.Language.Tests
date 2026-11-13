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
//   OnAfterGetCurrRecord. A GoToRecord to the row the host already stands on (a List with one row, the first of two rows); a part
//   with the triggers and properties of page 1178 (DeleteAllowed, DelayedInsert, OnInit, OnDeleteRecord, a field with OnDrillDown
//   and Editable = false), also as a FactBox with UpdatePropagation = Both (the Base Application hosts of page 1178 set it); a host
//   with OnOpenPage, OnAfterGetRecord and OnAfterGetCurrRecord.
// The reporter's host form (three heads, every part empty, GoToRecord to the last row): a List host with a Caption whose FactBox
//   part of page 1178's shape sets ApplicationArea, Caption, UpdatePropagation = Both and links "No." to the host's "Ref Code"
//   (outside the key); the same with only Caption on the part control, on a host with Editable = false, and on a host with
//   CardPageId. Each OpenEdit and OpenView.
// Fact (observed on BC 27.5, 28.5 and 29.0): in every one of these shapes Rec in the action of the empty part holds the link values of the
//   row the host stands on ("Table ID" 76840, "No." = that row's "Ref Code", Line No. 0): RA as opened, RC after GoToRecord to the
//   last row. Neither UpdatePropagation, the part's Caption, Editable = false nor CardPageId changes it.
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

// The triggers and properties of page 1178 beside the shape of "PG EPL Part": DeleteAllowed, DelayedInsert, OnInit, OnDeleteRecord,
// a field with OnDrillDown and Editable = false.
page 76851 "PG EPL Part Doc"
{
    PageType = ListPart;
    SourceTable = "PG EPL Line";
    DeleteAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        DrillDowns += 1;
                    end;
                }
                field(KindCtl; Rec.Kind)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
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

    trigger OnInit()
    begin
        DrillDowns := 0;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG EPL Log";
    begin
        Log.AddCurr('agcr=' + Format(Rec."Table ID") + '/' + Rec."No." + '/' + Format(Rec."Line No."));
    end;

    var
        DrillDowns: Integer;
}

page 76852 "PG EPL List Doc"
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(76840), "No." = field("No.");
            }
        }
    }
}

// A host with triggers that do not touch the part.
page 76853 "PG EPL List Triggers"
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
                SubPageLink = "Table ID" = const(76840), "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opens += 1;
    end;

    trigger OnAfterGetRecord()
    begin
        Reads += 1;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrReads += 1;
    end;

    var
        Opens: Integer;
        Reads: Integer;
        CurrReads: Integer;
}

// Page 1178's host form: the FactBox has UpdatePropagation = Both.
page 76854 "PG EPL List DocBoth"
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(Database::"PG EPL Head"), "No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

// The reporter's host form (issue 6924): a List page with a Caption whose FactBox part sets ApplicationArea, Caption,
// UpdatePropagation = Both and links "No." to a host field outside the host key, like the Base Application hosts of page 1178.
page 76855 "PG EPL List Rep"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    Caption = 'EPL Reporter List';
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"PG EPL Head"), "No." = field("Ref Code");
                UpdatePropagation = Both;
            }
        }
    }
}

// As "PG EPL List Rep", but the part control has only Caption besides ApplicationArea and SubPageLink.
page 76856 "PG EPL List RepCap"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    Caption = 'EPL Reporter List Caption';
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"PG EPL Head"), "No." = field("Ref Code");
            }
        }
    }
}

// As "PG EPL List Rep", on a host with Editable = false.
page 76857 "PG EPL List RepRO"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    Caption = 'EPL Reporter List Read Only';
    Editable = false;
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"PG EPL Head"), "No." = field("Ref Code");
                UpdatePropagation = Both;
            }
        }
    }
}

// The card page of "PG EPL List RepCard".
page 76858 "PG EPL Head Card"
{
    PageType = Card;
    SourceTable = "PG EPL Head";
    Caption = 'EPL Head Card';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RefCtl; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
    }
}

// As "PG EPL List Rep", on a host with CardPageId.
page 76859 "PG EPL List RepCard"
{
    PageType = List;
    SourceTable = "PG EPL Head";
    Caption = 'EPL Reporter List Card';
    CardPageId = "PG EPL Head Card";
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
            part(Box; "PG EPL Part Doc")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"PG EPL Head"), "No." = field("Ref Code");
                UpdatePropagation = Both;
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

    // Head A only (Ref Code RA), no line: a GoToRecord to A stays on the row the host stands on.
    local procedure InitializeOneHead()
    var
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Head.Get('B');
        Head.Delete();
    end;

    // Heads A, B and C (Ref Code RA, RB and RC), no line: C is the last row of the host.
    local procedure InitializeThree()
    var
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Head."No." := 'C';
        Head."Ref Code" := 'RC';
        Head.Insert();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('next', 'Yes');
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('next', 'Yes');
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('next', 'Yes');
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('next', 'Yes');
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/A/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0/B/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/RB/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/RB/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/RA/0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/A/7/K');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/8/L');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=0//0/');
        Observer.Verify();
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
        Observer.Expect('action', 'act=76840/B/0/ | act=76840/B/0/');
        Observer.Verify();
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
        Observer.Expect('curr', 'agcr=76840/A/0 | agcr=76840/A/0 | agcr=76840/A/0');
        Observer.Verify();
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
        Observer.Expect('curr', 'agcr=76840/B/0 | agcr=76840/B/0 | agcr=76840/B/0');
        Observer.Verify();
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
        Observer.Expect('curr', 'agcr=76840/A/0 | agcr=76840/A/0');
        Observer.Verify();
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
        Observer.Expect('curr', 'agcr=76840/B/0 | agcr=76840/B/0');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_Content_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Inline.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_OneHead_GoToSameRow_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenView();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_OneHead_GoToSameRow_Content_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenView();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Inline.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToFirstRow_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToFirstRow_Content_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Inline.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToFirstRow_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Log.Reset();
        Head.Get('A');
        Host.GoToRecord(Head);

        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Expect('curr', '');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_OneHead_GoToSameRow_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List ConstField";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenView();
        Log.Reset();
        Head.Get('A');
        Host.GoToRecord(Head);

        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Expect('curr', '');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_PartDoc_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Doc";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_PartDoc_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Doc";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_PartDoc_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Doc";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_PartDoc_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Doc";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_PartDoc_OnAfterGetCurrRecordReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Doc";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();

        Observer.Observe('curr', Log.CurrLog());
        Host.Close();
        Observer.Expect('curr', 'agcr=76840/A/0');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_HostTriggers_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Triggers";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_HostTriggers_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Triggers";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_HostTriggers_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Triggers";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_Next_HostTriggers_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Triggers";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        if Host.Next() then;
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_HostTriggers_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Triggers";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();

        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_PartDocBoth_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List DocBoth";
    begin
        Initialize();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToRecord_PartDocBoth_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List DocBoth";
        Head: Record "PG EPL Head";
    begin
        Initialize();
        Host.OpenEdit();
        Head.Get('B');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/B/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_OneHead_GoToSameRow_PartDocBoth_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List DocBoth";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenEdit();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_OneHead_GoToSameRow_PartDocBoth_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List DocBoth";
        Head: Record "PG EPL Head";
    begin
        InitializeOneHead();
        Host.OpenView();
        Head.Get('A');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/A/0/');
        Observer.Verify();
    end;

    // The reporter's host form (issue 6924): heads A, B and C, every part empty; GoToRecord moves to the last row C.
    [Test]
    procedure EmptyPart_ListOpenEdit_Reporter_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Rep";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenEdit();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RA/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_Reporter_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Rep";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenView();
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RA/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToLastRow_Reporter_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Rep";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenEdit();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToLastRow_Reporter_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List Rep";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenView();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToLastRow_ReporterCaptionOnly_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepCap";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenEdit();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToLastRow_ReporterCaptionOnly_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepCap";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenView();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToLastRow_ReporterNotEditable_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepRO";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenEdit();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToLastRow_ReporterNotEditable_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepRO";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenView();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenEdit_GoToLastRow_ReporterCardPage_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepCard";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenEdit();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyPart_ListOpenView_GoToLastRow_ReporterCardPage_FactBox_ActionReadsRec()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "PG EPL List RepCard";
        Head: Record "PG EPL Head";
    begin
        InitializeThree();
        Host.OpenView();
        Head.Get('C');
        Host.GoToRecord(Head);
        Host.Box.ReadRec.Invoke();
        Observer.Observe('action', Log.ActionLog());
        Host.Close();
        Observer.Expect('action', 'act=76840/RC/0/');
        Observer.Verify();
    end;
}
