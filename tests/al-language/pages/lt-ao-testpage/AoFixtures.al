// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures for corpus issue 641 (TestPage behavior, part 2), writer AO: tables 79500-79502, log 79503, pages 79504-79514, worker codeunits 79515-79517,
// report 79518, control add-in "LT AO Addin". The tests are in AoTests.al (79590, the only user of the SingleInstance log 79503).
// BC versions: 27, 28, 29

table 79500 "LT AO Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Total; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Inserting or modifying a line counts it on the header (item 4: the line trigger modifies the header record).
table 79501 "LT AO Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Bump();
    end;

    trigger OnModify()
    begin
        Bump();
    end;

    local procedure Bump()
    var
        Hdr: Record "LT AO Hdr";
    begin
        if Hdr.Get("Doc No.") then begin
            Hdr.Total += 1;
            Hdr.Modify();
        end;
    end;
}

table 79502 "LT AO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F; Code[10]) { }
        field(3; Name; Text[30]) { }
        field(4; Txt; Text[30]) { }
        field(5; Cd; Code[30]) { }
        field(6; Op; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 79503 "LT AO Log"
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
}

// Items 4 and 13: a card with a lines part linked on the card key (DelayedInsert is false, the default).
page 79504 "LT AO Hdr Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Hdr";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Total; Rec.Total) { ApplicationArea = All; }
            part(Lines; "LT AO Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActLog)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Log.Add('act name=' + Rec.Name + ' total=' + Format(Rec.Total));
                end;
            }
            action(ActModify)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Rec.Name := 'act';
                    Rec.Modify();
                    Log.Add('act modified total=' + Format(Rec.Total));
                end;
            }
        }
    }
}

page 79505 "LT AO Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "LT AO Line";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

// Item 7: Text[30] and Code[30] controls bound to fields and to variables; item 11: RunPageLink with const('') and filter('');
// item 3: a control named like a local variable of the test.
page 79506 "LT AO Text Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            field(Cd; Rec.Cd) { ApplicationArea = All; }
            field(VTxt; VTxt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Log.Add('[' + VTxt + ']');
                end;
            }
            field(VCd; VCd)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Log.Add('[' + VCd + ']');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunConst)
            {
                ApplicationArea = All;
                RunObject = page "LT AO Row List";
                RunPageLink = F = const('');
            }
            action(RunFilter)
            {
                ApplicationArea = All;
                RunObject = page "LT AO Row List";
                RunPageLink = F = filter('');
            }
        }
    }

    var
        VTxt: Text[30];
        VCd: Code[30];
}

// Items 9, 11 and 15: a plain editable list.
page 79507 "LT AO Row List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(F; Rec.F) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

// Item 12: OnFindRecord / OnNextRecord / OnNewRecord logging on a list and on a card.
page 79508 "LT AO Find List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('find ' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('next ' + Format(Steps));
        exit(Rec.Next(Steps));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('new below=' + Format(BelowxRec) + ' x=' + Format(xRec.Id) + '/' + xRec.Name + ' rec=' + Format(Rec.Id));
    end;
}

page 79509 "LT AO Find Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('find ' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('new below=' + Format(BelowxRec) + ' x=' + Format(xRec.Id) + '/' + xRec.Name + ' rec=' + Format(Rec.Id));
    end;
}

// Item 17: a list action deletes the current row and does not call CurrPage.Update.
page 79510 "LT AO Del List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DelOnly)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Log.Add('del ' + Format(Rec.Id));
                    Rec.Delete();
                    Log.Add('deleted');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('agr ' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('agcr ' + Format(Rec.Id));
    end;
}

controladdin "LT AO Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
    event Ready();
}

// Item 18: an action calls a control add-in procedure; a TestPage has no client, so no add-in is created.
page 79511 "LT AO Addin Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            usercontrol(Ctl; "LT AO Addin")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AO Log";
                begin
                    Log.Add('before');
                    CurrPage.Ctl.Say('hello');
                    Log.Add('after');
                end;
            }
        }
    }
}

// Item 1: a card that enqueues one page background task per current row; the row's Op field says what the worker does.
page 79512 "LT AO Bg Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Op; Rec.Op) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Params: Dictionary of [Text, Text];
        TaskId: Integer;
    begin
        if Rec.Op = '' then
            exit;
        Params.Add('Op', Rec.Op);
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"LT AO Bg Worker", Params, 10000);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        Log: Codeunit "LT AO Log";
        R: Text;
    begin
        if not Results.Get('R', R) then
            R := '<none>';
        Log.Add('done ' + R);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        Log: Codeunit "LT AO Log";
    begin
        Log.Add('error code=' + ErrorCode + ' text=' + ErrorText);
        IsHandled := true;
    end;
}

// Item 2 contrast: the same invisible control on a page of the test app itself.
page 79513 "LT AO Vis Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Hidden; Rec.Name) { ApplicationArea = All; Visible = false; }
        }
    }
}

codeunit 79515 "LT AO Bg Worker"
{
    trigger OnRun()
    var
        Row: Record "LT AO Row";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        case Op of
            'commit':
                Commit();
            'runok':
                Codeunit.Run(Codeunit::"LT AO Bg Noop");
            'runfail':
                Codeunit.Run(Codeunit::"LT AO Bg Failing");
            'modify':
                begin
                    Row.Get(1);
                    Row.Name := 'worker';
                    Row.Modify();
                end;
            'modifypend':
                begin
                    Row.Get(2);
                    Row.Name := 'worker';
                    Row.Modify();
                end;
        end;
        Results.Add('R', Op + ' ok');
        Page.SetBackgroundTaskResult(Results);
    end;
}

codeunit 79516 "LT AO Bg Noop"
{
    trigger OnRun()
    begin
    end;
}

codeunit 79517 "LT AO Bg Failing"
{
    trigger OnRun()
    begin
        Error('LT AO inner failure');
    end;
}

// Item 15: a request page data item filter set to '' and ' ' after a filter.
report 79518 "LT AO Rpt"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(RowDI; "LT AO Row")
        {
            RequestFilterFields = F;

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT AO Log";
            begin
                Log.Add('pre filter=' + RowDI.GetFilter(F) + ' count=' + Format(RowDI.Count()));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
            }
        }
    }
}

// Writer SF: a list part over LT AO Row and a card over LT AO Hdr with two copies of it, linked by F = const('') and by F = filter('').
page 89066 "LT SF AO Row Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(F; Rec.F) { ApplicationArea = All; }
            }
        }
    }
}

page 89067 "LT SF AO Link Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Hdr";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(PartConst; "LT SF AO Row Part")
            {
                ApplicationArea = All;
                SubPageLink = F = const('');
            }
            part(PartFilter; "LT SF AO Row Part")
            {
                ApplicationArea = All;
                SubPageLink = F = filter('');
            }
        }
    }
}
