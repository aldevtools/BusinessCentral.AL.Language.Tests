// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75360, pages 75361 75362 75363, page extensions 75364 75365, log codeunit
//   75366, test codeunit 75367
// Probe (al-runner 7629): OnAfterGetRecord and OnAfterGetCurrRecord declared only by a page extension (the base page declares neither),
//   at the moves and calls events/extension-events/PageExtensionSender.al does not pin: Last, Previous, GoToKey and GoToRecord on a
//   list, an action, an action with CurrPage.Update(false), New, Close; a page with its own OnAfterGetCurrRecord and an extension-only
//   OnAfterGetRecord; a page with a control bound to a procedure (a function control); Page.Run of the list from an action with
//   RunPageLink.
// Observed per step: the log since the last step: x-agr(X) / x-agcr(X) the extension's triggers on row X, b-agcr(X) the base page's
//   own OnAfterGetCurrRecord, fn(X) the procedure behind the function control, act / act-upd the actions.
// local object: the base pages and their extensions are the shapes under test
// Facts: the extension-only OnAfterGetRecord and OnAfterGetCurrRecord run at every move, action and New, as if the base page declared
//   them (Last on an edit-mode list first runs OnAfterGetCurrRecord on an empty row; New runs only OnAfterGetCurrRecord on the empty
//   line; Close runs neither). With an own OnAfterGetCurrRecord the extension's OnAfterGetRecord runs before it, and the function
//   control is evaluated after each. The RunPageLink list reads its one row like an own trigger would.
// BC versions: 27, 28, 29

table 75360 "PG6 XT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 75361 "PG6 XT List"
{
    PageType = List;
    SourceTable = "PG6 XT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "PG6 XT Log";
                begin
                    Log.Add('act');
                end;
            }
            action(Upd)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "PG6 XT Log";
                begin
                    Log.Add('act-upd');
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

// Own OnAfterGetCurrRecord, a function control; the extension adds only OnAfterGetRecord.
page 75362 "PG6 XT Fn List"
{
    PageType = List;
    SourceTable = "PG6 XT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Fn; NameLength()) { ApplicationArea = All; Caption = 'Fn'; }
            }
        }
    }

    var
        Log: Codeunit "PG6 XT Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('b-agcr(' + Rec."Code" + ')');
    end;

    local procedure NameLength(): Integer
    begin
        Log.Add('fn(' + Rec."Code" + ')');
        exit(StrLen(Rec.Name));
    end;
}

// Opens the extended list with a RunPageLink.
page 75363 "PG6 XT Opener"
{
    PageType = Card;
    SourceTable = "PG6 XT Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenLinked)
            {
                ApplicationArea = All;
                RunObject = page "PG6 XT List";
                RunPageLink = "Code" = field("Code");
            }
        }
    }
}

pageextension 75364 "PG6 XT List Ext" extends "PG6 XT List"
{
    var
        Log: Codeunit "PG6 XT Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('x-agr(' + Rec."Code" + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('x-agcr(' + Rec."Code" + ')');
    end;
}

pageextension 75365 "PG6 XT Fn List Ext" extends "PG6 XT Fn List"
{
    var
        XLog: Codeunit "PG6 XT Log";

    trigger OnAfterGetRecord()
    begin
        XLog.Add('x-agr(' + Rec."Code" + ')');
    end;
}

codeunit 75366 "PG6 XT Log"
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

codeunit 75367 "PG6 XT Extension Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 XT Log";

    local procedure Initialize()
    var
        Row: Record "PG6 XT Row";
    begin
        Observer.Discard();
        Row.DeleteAll();
        AddRow('A', 'alpha');
        AddRow('B', 'bravo');
        AddRow('C', 'charlie');
        AddRow('D', 'delta');
        Log.Reset();
    end;

    local procedure AddRow(RowCode: Code[10]; RowName: Text[30])
    var
        Row: Record "PG6 XT Row";
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.Insert();
    end;

    local procedure Say(Name: Text)
    begin
        Observer.Observe(Name, Log.Take());
    end;

    [Test]
    procedure List_ExtensionOnly_MovesActionsClose()
    var
        Row: Record "PG6 XT Row";
        P: TestPage "PG6 XT List";
    begin
        Initialize();
        P.OpenEdit();
        Say('open');
        P.Last();
        Say('last');
        P.Previous();
        Say('previous');
        P.GoToKey('A');
        Say('gotokey-a');
        Row.Get('C');
        P.GoToRecord(Row);
        Say('gotorecord-c');
        P.Plain.Invoke();
        Say('action');
        P.Upd.Invoke();
        Say('action-update');
        P.Close();
        Say('closed');
        Observer.Expect('open', '[x-agr(A) x-agr(B) x-agr(C) x-agr(D) x-agr(A) x-agr(A) x-agcr(A)]');
        Observer.Expect('last', '[x-agcr() x-agr(D) x-agr(D) x-agcr(D)]');
        Observer.Expect('previous', '[x-agr(C) x-agr(C) x-agcr(C)]');
        Observer.Expect('gotokey-a', '[x-agr(A) x-agr(A) x-agcr(A)]');
        Observer.Expect('gotorecord-c', '[x-agr(B) x-agr(B) x-agcr(B) x-agr(C) x-agr(C) x-agcr(C)]');
        Observer.Expect('action', '[x-agr(C) act x-agr(C) x-agr(C) x-agr(D) x-agr(C) x-agr(B) x-agr(A) x-agr(C) x-agr(C) x-agcr(C)]');
        Observer.Expect('action-update', '[x-agr(C) act-upd x-agr(C) x-agr(C) x-agr(D) x-agr(C) x-agr(B) x-agr(A) x-agr(C) x-agr(C) x-agcr(C)]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure List_ExtensionOnly_NewThenClose()
    var
        P: TestPage "PG6 XT List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('B');
        Say('open');
        P.New();
        Say('new');
        P.Close();
        Say('closed');
        Observer.Expect('open', '[x-agr(A) x-agr(B) x-agr(C) x-agr(D) x-agr(A) x-agr(A) x-agcr(A) x-agr(B) x-agr(B) x-agcr(B)]');
        Observer.Expect('new', '[x-agcr()]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure List_ExtensionOnly_OpenView_LastPreviousGoToKey()
    var
        P: TestPage "PG6 XT List";
    begin
        Initialize();
        P.OpenView();
        Say('open');
        P.Last();
        Say('last');
        P.Previous();
        Say('previous');
        P.GoToKey('B');
        Say('gotokey-b');
        P.Close();
        Say('closed');
        Observer.Expect('open', '[x-agr(A) x-agr(B) x-agr(C) x-agr(D) x-agr(A) x-agr(A) x-agcr(A)]');
        Observer.Expect('last', '[x-agr(D) x-agr(D) x-agcr(D)]');
        Observer.Expect('previous', '[x-agr(C) x-agr(C) x-agcr(C)]');
        Observer.Expect('gotokey-b', '[x-agr(A) x-agr(A) x-agcr(A) x-agr(B) x-agr(B) x-agcr(B)]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure FnList_OwnCurrRecordExtensionGetRecord_Moves()
    var
        P: TestPage "PG6 XT Fn List";
    begin
        Initialize();
        P.OpenView();
        Say('open');
        P.Last();
        Say('last');
        P.GoToKey('B');
        Say('gotokey-b');
        P.Next();
        Say('next');
        Observer.Observe('fn-value', P.Fn.Value());
        Say('read-fn');
        P.Close();
        Say('closed');
        Observer.Expect('open', '[x-agr(A) fn(A) x-agr(B) fn(B) x-agr(C) fn(C) x-agr(D) fn(D) x-agr(A) x-agr(A) fn(A) b-agcr(A) fn(A)]');
        Observer.Expect('last', '[x-agr(D) x-agr(D) fn(D) b-agcr(D) fn(D)]');
        Observer.Expect('gotokey-b', '[x-agr(A) x-agr(A) fn(A) b-agcr(A) fn(A) x-agr(B) x-agr(B) fn(B) b-agcr(B) fn(B)]');
        Observer.Expect('next', '[x-agr(C) x-agr(C) fn(C) b-agcr(C) fn(C)]');
        Observer.Expect('fn-value', '7');
        Observer.Expect('read-fn', '[]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure List_ExtensionOnly_RunPageLinkFromAction()
    var
        Row: Record "PG6 XT Row";
        Opener: TestPage "PG6 XT Opener";
        P: TestPage "PG6 XT List";
    begin
        Initialize();
        Opener.OpenView();
        Row.Get('B');
        Opener.GoToRecord(Row);
        Say('opener');
        P.Trap();
        Opener.OpenLinked.Invoke();
        Say('linked-open');
        Observer.Observe('linked-code', P."Code".Value());
        P.Next();
        Say('linked-next');
        P.Close();
        Say('linked-closed');
        Opener.Close();
        Observer.Expect('opener', '[]');
        Observer.Expect('linked-open', '[x-agr(B) x-agr(B) x-agcr(B)]');
        Observer.Expect('linked-code', 'B');
        Observer.Expect('linked-next', '[x-agcr(B)]');
        Observer.Expect('linked-closed', '[]');
        Observer.Verify();
    end;
}
