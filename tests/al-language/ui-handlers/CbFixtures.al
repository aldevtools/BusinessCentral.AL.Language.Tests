// Fixtures for corpus issue #667 items 17 to 32 (writer CB): a row table with a table global and a table OnLookup that raises an error,
// an empty table, a log, a card, a StandardDialog, a list, a NavigatePage and a Role Center. Used by CbHandlerTests.al and CbPageTriggerTests.al only.
// Object ids 84160 - 84167 and 84170 - 84172. The pages and the SingleInstance log of CbHandlerTests.al (84170 - 84172) are copies of
// the card, dialog and log that CbPageTriggerTests.al uses: a SingleInstance codeunit may belong to one test codeunit only.

table 84160 "LT CB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT CB Log";
            begin
                Log.Add('table Name.OnValidate flag=' + Format(PageFlag));
            end;
        }
        field(3; Qty; Integer) { }
        field(4; LookupErr; Code[20])
        {
            trigger OnLookup()
            var
                Log: Codeunit "LT CB Log";
            begin
                Log.Add('table LookupErr.OnLookup');
                Error('LT CB table lookup failed');
            end;
        }
        field(5; Assist; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    var
        PageFlag: Boolean;

    procedure SetPageFlag(NewFlag: Boolean)
    begin
        PageFlag := NewFlag;
    end;

    procedure GetPageFlag(): Boolean
    begin
        exit(PageFlag);
    end;
}

table 84161 "LT CB Empty"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 84162 "LT CB Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        NewRecordMode: Integer;

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

    procedure SetNewRecordMode(Mode: Integer)
    begin
        NewRecordMode := Mode;
    end;

    procedure GetNewRecordMode(): Integer
    begin
        exit(NewRecordMode);
    end;
}

page 84163 "LT CB Card"
{
    PageType = Card;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(LookupErrCtl; Rec.LookupErr) { ApplicationArea = All; }
            field(AssistCtl; Rec.Assist)
            {
                ApplicationArea = All;

                trigger OnAssistEdit()
                begin
                    Log.Add('page AssistCtl.OnAssistEdit editable=' + Format(CurrPage.Editable));
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDialogModal)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Dialog: Page "LT CB Dialog";
                begin
                    Log.Add('card OnAction OpenDialogModal');
                    Dialog.SetRecord(Rec);
                    Log.Add('card RunModal=' + Format(Dialog.RunModal()));
                end;
            }
            action(DialogLinked)
            {
                ApplicationArea = All;
                RunObject = page "LT CB Dialog";
                RunPageLink = "No." = field("No.");
                RunPageView = where(Qty = filter(> 0));
                RunPageMode = View;
            }
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('card OnAction ' + Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT CB Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('card OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('card OnAfterGetCurrRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Empty: Record "LT CB Empty";
    begin
        case Log.GetNewRecordMode() of
            1:
                begin
                    Log.Add('card OnNewRecord FindFirst');
                    Empty.FindFirst();
                    Log.Add('card OnNewRecord after FindFirst');
                end;
            2:
                begin
                    Log.Add('card OnNewRecord Find');
                    Empty.Find();
                    Log.Add('card OnNewRecord after Find');
                end;
            3:
                begin
                    Log.Add('card OnNewRecord Rec.Find');
                    Rec.Find();
                    Log.Add('card OnNewRecord after Rec.Find');
                end;
            4:
                Log.Add('card OnNewRecord if Find=' + Format(Empty.Find()));
        end;
    end;
}

page 84164 "LT CB Dialog"
{
    PageType = StandardDialog;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT CB Log";
    begin
        Log.Add('dialog OnOpenPage filters=[' + Rec.GetFilters() + '] editable=' + Format(CurrPage.Editable));
    end;
}

page 84165 "LT CB List"
{
    PageType = List;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowFlag)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('list ShowFlag rec flag=' + Format(Rec.GetPageFlag()));
                end;
            }
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('list OnAction ' + Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT CB Log";
        PageFlagG: Boolean;
        LogTriggers: Boolean;

    procedure SetPageFlagOnPage(NewFlag: Boolean)
    begin
        PageFlagG := NewFlag;
    end;

    procedure SetLogTriggers(NewLogTriggers: Boolean)
    begin
        LogTriggers := NewLogTriggers;
    end;

    trigger OnAfterGetRecord()
    begin
        if LogTriggers then
            Log.Add('list OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.SetPageFlag(PageFlagG);
        if LogTriggers then
            Log.Add('list OnAfterGetCurrRecord ' + Rec."No.");
    end;
}

page 84166 "LT CB Navigate"
{
    PageType = NavigatePage;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Act)
            {
                ApplicationArea = All;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Log.Add('nav OnAction ' + Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT CB Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('nav OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('nav OnAfterGetCurrRecord ' + Rec."No.");
    end;
}

page 84167 "LT CB Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;

    actions
    {
        area(Processing)
        {
            action(RcAct)
            {
                ApplicationArea = All;
                RunObject = page "LT CB Card";
            }
        }
    }
}

codeunit 84170 "LT CB Hnd Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        NewRecordMode: Integer;

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

    procedure SetNewRecordMode(Mode: Integer)
    begin
        NewRecordMode := Mode;
    end;

    procedure GetNewRecordMode(): Integer
    begin
        exit(NewRecordMode);
    end;
}

page 84171 "LT CB Hnd Card"
{
    PageType = Card;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(LookupErrCtl; Rec.LookupErr) { ApplicationArea = All; }
            field(AssistCtl; Rec.Assist)
            {
                ApplicationArea = All;

                trigger OnAssistEdit()
                begin
                    Log.Add('page AssistCtl.OnAssistEdit editable=' + Format(CurrPage.Editable));
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDialogModal)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Dialog: Page "LT CB Hnd Dialog";
                begin
                    Log.Add('card OnAction OpenDialogModal');
                    Dialog.SetRecord(Rec);
                    Log.Add('card RunModal=' + Format(Dialog.RunModal()));
                end;
            }
            action(DialogLinked)
            {
                ApplicationArea = All;
                RunObject = page "LT CB Hnd Dialog";
                RunPageLink = "No." = field("No.");
                RunPageView = where(Qty = filter(> 0));
                RunPageMode = View;
            }
            action(Act)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('card OnAction ' + Rec."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT CB Hnd Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('card OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('card OnAfterGetCurrRecord ' + Rec."No.");
    end;
}

page 84172 "LT CB Hnd Dialog"
{
    PageType = StandardDialog;
    SourceTable = "LT CB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT CB Hnd Log";
    begin
        Log.Add('dialog OnOpenPage filters=[' + Rec.GetFilters() + '] editable=' + Format(CurrPage.Editable));
    end;
}
