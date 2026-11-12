// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-types-and-layouts
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75310 75311 75312, part pages 75313 75314, host pages 75315 75316 75317,
//   codeunit 75318 (the send codeunit), log codeunit 75319, test codeunit 75320
// Probe (al-runner 7922): the journal shape of a workflow status FactBox. The host's OnOpenPage, OnAfterGetCurrRecord and an action all run
//   ShowStatus := CurrPage.Status.Page.Fill(Rec."No."); the part control has Editable = false, Enabled = false, ShowFilter = false and
//   Visible = ShowStatus. The action first calls a codeunit that takes the host's Rec (by value, or by var) and inserts the request row
//   that the part's procedure then finds. HiddenPartOtherHostTypes.al pins the plainer shape with OpenEdit + GoToKey; here the page opens
//   with OpenView and moves with GoToRecord, on a Worksheet and a List host, and one host has a part over the stored table that the
//   procedure filters with SetRange instead of filling a temporary table.
// Observed per step: the number of request rows, the part's Visible() and the log: host-* the host (open, agcr = OnAfterGetCurrRecord,
//   close), act-send the action, cu-send the codeunit, st-* the part (open, agr = OnAfterGetRecord, agcr, fill(doc,rows) its procedure,
//   close).
// local object: the hosts, the part and its Visible settings are what the test checks; the log records the triggers
// Facts: OnOpenPage calls the part procedure before the part's OnOpenPage, with an empty Rec; the action makes the part visible
//   (Visible() Yes) and its rows are read twice, before and after the host's OnAfterGetCurrRecord; GoToRecord to the current row runs
//   nothing; Next runs the host's OnAfterGetCurrRecord and the procedure but no part trigger, and Visible() turns No. By value or by
//   var, Worksheet or List, temporary or stored part: the same log.
// BC versions: 27, 28, 29

table 75310 "PG6 HJ Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75311 "PG6 HJ Request"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 75312 "PG6 HJ Status"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// A temporary ListPart that a procedure refills from the stored requests of one document and answers whether it has rows.
page 75313 "PG6 HJ Status Part"
{
    PageType = ListPart;
    SourceTable = "PG6 HJ Status";
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
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 HJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('st-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('st-agr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('st-agcr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnClosePage()
    begin
        Log.Add('st-close');
    end;

    procedure Fill(DocNo: Code[10]): Boolean
    var
        Request: Record "PG6 HJ Request";
    begin
        Rec.DeleteAll();
        Request.SetRange("Doc No.", DocNo);
        if Request.FindSet() then
            repeat
                Rec.Init();
                Rec."Entry No." := Request."Entry No.";
                Rec."Doc No." := Request."Doc No.";
                Rec.Insert();
            until Request.Next() = 0;
        Log.Add('st-fill(' + DocNo + ',' + Format(Rec.Count()) + ')');
        exit(not Rec.IsEmpty());
    end;
}

// The same over the stored requests: the procedure filters instead of filling.
page 75314 "PG6 HJ Stored Part"
{
    PageType = ListPart;
    SourceTable = "PG6 HJ Request";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "PG6 HJ Log";

    trigger OnOpenPage()
    begin
        Log.Add('st-open');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('st-agr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('st-agcr(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnClosePage()
    begin
        Log.Add('st-close');
    end;

    procedure Fill(DocNo: Code[10]): Boolean
    begin
        Rec.SetRange("Doc No.", DocNo);
        Log.Add('st-fill(' + DocNo + ',' + Format(Rec.Count()) + ')');
        exit(not Rec.IsEmpty());
    end;
}

page 75315 "PG6 HJ Worksheet"
{
    PageType = Worksheet;
    SourceTable = "PG6 HJ Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Status; "PG6 HJ Status Part")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowStatus;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendVal)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Send: Codeunit "PG6 HJ Send";
                begin
                    Log.Add('act-send');
                    Send.SendByValue(Rec);
                    RefreshStatus();
                end;
            }
            action(SendVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Send: Codeunit "PG6 HJ Send";
                begin
                    Log.Add('act-send');
                    Send.SendByVar(Rec);
                    RefreshStatus();
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 HJ Log";
        ShowStatus: Boolean;

    local procedure RefreshStatus()
    begin
        ShowStatus := CurrPage.Status.Page.Fill(Rec."No.");
    end;

    trigger OnOpenPage()
    begin
        Log.Add('host-open');
        RefreshStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
        RefreshStatus();
    end;

    trigger OnClosePage()
    begin
        Log.Add('host-close');
    end;
}

page 75316 "PG6 HJ List"
{
    PageType = List;
    SourceTable = "PG6 HJ Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Status; "PG6 HJ Status Part")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowStatus;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendVal)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Send: Codeunit "PG6 HJ Send";
                begin
                    Log.Add('act-send');
                    Send.SendByValue(Rec);
                    RefreshStatus();
                end;
            }
            action(SendVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Send: Codeunit "PG6 HJ Send";
                begin
                    Log.Add('act-send');
                    Send.SendByVar(Rec);
                    RefreshStatus();
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 HJ Log";
        ShowStatus: Boolean;

    local procedure RefreshStatus()
    begin
        ShowStatus := CurrPage.Status.Page.Fill(Rec."No.");
    end;

    trigger OnOpenPage()
    begin
        Log.Add('host-open');
        RefreshStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
        RefreshStatus();
    end;

    trigger OnClosePage()
    begin
        Log.Add('host-close');
    end;
}

page 75317 "PG6 HJ Worksheet Stored"
{
    PageType = Worksheet;
    SourceTable = "PG6 HJ Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Status; "PG6 HJ Stored Part")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowStatus;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendVal)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Send: Codeunit "PG6 HJ Send";
                begin
                    Log.Add('act-send');
                    Send.SendByValue(Rec);
                    RefreshStatus();
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 HJ Log";
        ShowStatus: Boolean;

    local procedure RefreshStatus()
    begin
        ShowStatus := CurrPage.Status.Page.Fill(Rec."No.");
    end;

    trigger OnOpenPage()
    begin
        Log.Add('host-open');
        RefreshStatus();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('host-agcr(' + Rec."No." + ')');
        RefreshStatus();
    end;

    trigger OnClosePage()
    begin
        Log.Add('host-close');
    end;
}

codeunit 75318 "PG6 HJ Send"
{
    procedure SendByValue(Doc: Record "PG6 HJ Doc")
    begin
        AddRequest(Doc."No.");
    end;

    procedure SendByVar(var Doc: Record "PG6 HJ Doc")
    begin
        AddRequest(Doc."No.");
    end;

    local procedure AddRequest(DocNo: Code[10])
    var
        Request: Record "PG6 HJ Request";
        Log: Codeunit "PG6 HJ Log";
        NextNo: Integer;
    begin
        if Request.FindLast() then
            NextNo := Request."Entry No.";
        Request.Init();
        Request."Entry No." := NextNo + 1;
        Request."Doc No." := DocNo;
        Request.Insert();
        Log.Add('cu-send(' + DocNo + ')');
    end;
}

codeunit 75319 "PG6 HJ Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

codeunit 75320 "PG6 HJ Journal Shape"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 HJ Log";

    local procedure Initialize()
    var
        Doc: Record "PG6 HJ Doc";
        Request: Record "PG6 HJ Request";
    begin
        Observer.Discard();
        Request.DeleteAll();
        Doc.DeleteAll();
        Doc.Init();
        Doc."No." := 'H1';
        Doc.Insert();
        Doc.Init();
        Doc."No." := 'H2';
        Doc.Insert();
        Log.Reset();
    end;

    local procedure Say(Name: Text; PartVisible: Boolean)
    var
        Request: Record "PG6 HJ Request";
    begin
        Observer.Observe(Name, Format(Request.Count()) + ' ' + Format(PartVisible) + ' ' + Log.Take());
    end;

    local procedure Say(Name: Text)
    var
        Request: Record "PG6 HJ Request";
    begin
        Observer.Observe(Name, Format(Request.Count()) + ' ' + Log.Take());
    end;

    [Test]
    procedure Worksheet_OpenViewGoToRecord_SendByValueThenNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        P: TestPage "PG6 HJ Worksheet";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.Status.Visible());
        Doc.Get('H1');
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.SendVal.Invoke();
        Say('send', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('open', '0 No [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,0) st-agcr(0)]');
        Observer.Expect('gotorecord', '0 No []');
        Observer.Expect('send', '1 Yes [act-send cu-send(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1) host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;

    [Test]
    procedure Worksheet_OpenViewGoToRecord_SendByVarThenNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        P: TestPage "PG6 HJ Worksheet";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.Status.Visible());
        Doc.Get('H1');
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.SendVar.Invoke();
        Say('send', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('open', '0 No [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,0) st-agcr(0)]');
        Observer.Expect('gotorecord', '0 No []');
        Observer.Expect('send', '1 Yes [act-send cu-send(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1) host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenViewGoToRecord_SendByValueThenNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        P: TestPage "PG6 HJ List";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.Status.Visible());
        Doc.Get('H1');
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.SendVal.Invoke();
        Say('send', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('open', '0 No [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,0) st-agcr(0)]');
        Observer.Expect('gotorecord', '0 No []');
        Observer.Expect('send', '1 Yes [act-send cu-send(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1) host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenViewGoToRecord_SendByVarThenNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        P: TestPage "PG6 HJ List";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.Status.Visible());
        Doc.Get('H1');
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.SendVar.Invoke();
        Say('send', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('open', '0 No [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,0) st-agcr(0)]');
        Observer.Expect('gotorecord', '0 No []');
        Observer.Expect('send', '1 Yes [act-send cu-send(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1) host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;

    // The request for H1 exists before the page opens: OnOpenPage and OnAfterGetCurrRecord answer true without the action.
    [Test]
    procedure Worksheet_RequestBeforeOpen_OpenViewGoToRecordNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        Send: Codeunit "PG6 HJ Send";
        P: TestPage "PG6 HJ Worksheet";
    begin
        Initialize();
        Doc.Get('H1');
        Send.SendByValue(Doc);
        Say('setup');
        P.OpenView();
        Say('open', P.Status.Visible());
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Previous();
        Say('previous', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('setup', '1 [cu-send(H1)]');
        Observer.Expect('open', '1 Yes [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('gotorecord', '1 Yes []');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('previous', '1 Yes [host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;

    [Test]
    procedure WorksheetStored_OpenViewGoToRecord_SendByValueThenNextClose()
    var
        Doc: Record "PG6 HJ Doc";
        P: TestPage "PG6 HJ Worksheet Stored";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.Status.Visible());
        Doc.Get('H1');
        P.GoToRecord(Doc);
        Say('gotorecord', P.Status.Visible());
        P.SendVal.Invoke();
        Say('send', P.Status.Visible());
        P.Next();
        Say('next', P.Status.Visible());
        P.Close();
        Say('closed');
        Observer.Expect('open', '0 No [host-open st-fill(,0) st-open host-agcr(H1) st-fill(H1,0) st-agcr(0)]');
        Observer.Expect('gotorecord', '0 No []');
        Observer.Expect('send', '1 Yes [act-send cu-send(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1) host-agcr(H1) st-fill(H1,1) st-agr(1) st-agr(1) st-agcr(1)]');
        Observer.Expect('next', '1 No [host-agcr(H2) st-fill(H2,0)]');
        Observer.Expect('closed', '1 [st-close host-close]');
        Observer.Verify();
    end;
}
