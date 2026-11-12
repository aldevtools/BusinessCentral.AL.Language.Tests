// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/pagefield/devenv-onlookup-pagefield-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 77780, pages 77781..77787, page extensions 77788 77789 77790, subscriber
//   codeunit 77791, log codeunit 77792, test codeunit 77793
// Probe (al-runner 7630), four page client paths:
//   1. A subscriber to OnAfterGetCurrRecordEvent of a card with a control bound to a procedure (a function control), and of a temporary
//      list opened by Trap + Page.Run with an empty and a filled buffer: when it is called.
//   2. A page extension sets InsertAllowed, ModifyAllowed and DeleteAllowed against the base value: a temporary list whose base allows no
//      writes (extension true), and a card opened through an Edit action of a list (base ModifyAllowed false, extension true; and base
//      true, extension false). Observed: whether New + SetValue and SetValue + Close raise, and the rows.
//   3. Error('text') out of a control's own OnLookup(var Text): Boolean: the error text and GetLastErrorCode.
//   4. Editable and Enabled bound to page variables that OnAfterGetRecord sets, read on a new repeater line (New), where OnAfterGetRecord
//      did not run for the line.
// Observed per step: the read value and the log since the last step (ev-agcr(X) the subscriber, agr(X) / agcr(X) the page's triggers,
//   fn(X) the function control's procedure, new = OnNewRecord).
// local object: the pages are the shapes under test
// BC versions: 27, 28, 29

table 77780 "PG6 PC Row"
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

page 77781 "PG6 PC Fn Card"
{
    PageType = Card;
    SourceTable = "PG6 PC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Fn; NameLength()) { ApplicationArea = All; Caption = 'Fn'; }
            }
        }
    }

    var
        Log: Codeunit "PG6 PC Log";

    local procedure NameLength(): Integer
    begin
        Log.Add('fn(' + Rec."Code" + ')');
        exit(StrLen(Rec.Name));
    end;
}

page 77782 "PG6 PC Temp List"
{
    PageType = List;
    SourceTable = "PG6 PC Row";
    SourceTableTemporary = true;
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
}

// Base: a temporary list that allows no writes; the extension allows them.
page 77783 "PG6 PC Locked Temp List"
{
    PageType = List;
    SourceTable = "PG6 PC Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
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

    trigger OnClosePage()
    var
        Log: Codeunit "PG6 PC Log";
    begin
        Log.Add('temp-rows=' + Format(Rec.Count()));
    end;
}

page 77784 "PG6 PC Locked Card"
{
    PageType = Card;
    SourceTable = "PG6 PC Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 77785 "PG6 PC Open Card"
{
    PageType = Card;
    SourceTable = "PG6 PC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 77786 "PG6 PC Edit List"
{
    PageType = List;
    SourceTable = "PG6 PC Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditLocked)
            {
                ApplicationArea = All;
                RunObject = page "PG6 PC Locked Card";
                RunPageLink = "Code" = field("Code");
                RunPageMode = Edit;
            }
            action(EditOpen)
            {
                ApplicationArea = All;
                RunObject = page "PG6 PC Open Card";
                RunPageLink = "Code" = field("Code");
                RunPageMode = Edit;
            }
        }
    }
}

// A lookup that fails, and Editable / Enabled from OnAfterGetRecord on a repeater.
page 77787 "PG6 PC Row List"
{
    PageType = List;
    SourceTable = "PG6 PC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Error('PG6 PC lookup refused');
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = RowEditable;
                    Enabled = RowEnabled;
                }
            }
        }
    }

    var
        Log: Codeunit "PG6 PC Log";
        RowEditable: Boolean;
        RowEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        RowEditable := Rec.Name <> 'locked';
        RowEnabled := Rec.Name <> 'locked';
        Log.Add('agr(' + Rec."Code" + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Rec."Code" + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('new');
    end;
}

pageextension 77788 "PG6 PC Locked Temp Ext" extends "PG6 PC Locked Temp List"
{
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
}

pageextension 77789 "PG6 PC Locked Card Ext" extends "PG6 PC Locked Card"
{
    ModifyAllowed = true;
}

pageextension 77790 "PG6 PC Open Card Ext" extends "PG6 PC Open Card"
{
    ModifyAllowed = false;
}

codeunit 77791 "PG6 PC Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"PG6 PC Fn Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure FnCardAfterGetCurrRecord(var Rec: Record "PG6 PC Row")
    var
        Log: Codeunit "PG6 PC Log";
    begin
        Log.Add('ev-agcr(' + Rec."Code" + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"PG6 PC Temp List", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure TempListAfterGetCurrRecord(var Rec: Record "PG6 PC Row")
    var
        Log: Codeunit "PG6 PC Log";
    begin
        Log.Add('ev-agcr(' + Rec."Code" + ')');
    end;
}

codeunit 77792 "PG6 PC Log"
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

codeunit 77793 "PG6 PC Unpinned Paths"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 PC Log";

    local procedure Initialize()
    var
        Row: Record "PG6 PC Row";
    begin
        Observer.Discard();
        Row.DeleteAll();
        AddRow('A', 'alpha');
        AddRow('B', 'locked');
        AddRow('C', 'charlie');
        // asserterror rolls back the uncommitted writes of the test
        Commit();
        Log.Reset();
        ClearLastError();
    end;

    local procedure AddRow(RowCode: Code[10]; RowName: Text[30])
    var
        Row: Record "PG6 PC Row";
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.Insert();
    end;

    local procedure Names() Result: Text
    var
        Row: Record "PG6 PC Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
    end;

    local procedure Say(Name: Text)
    begin
        Observer.Observe(Name, Log.Take());
    end;

    local procedure SayEnd(Name: Text)
    var
        Txt: Text;
    begin
        Txt := GetLastErrorText();
        if Txt = 'NO_ERROR' then
            Txt := 'ok';
        Observer.Observe(Name, Txt + ' ' + Log.Take());
        ClearLastError();
    end;

    [Test]
    procedure Subscriber_FnCard_OpenViewMovesClose()
    var
        P: TestPage "PG6 PC Fn Card";
    begin
        Initialize();
        P.OpenView();
        Say('open');
        P.GoToKey('C');
        Say('gotokey-c');
        P.Previous();
        Say('previous');
        Observer.Observe('fn', P.Fn.Value());
        Say('read-fn');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_TempList_PageRunEmptyBuffer()
    var
        TempRow: Record "PG6 PC Row" temporary;
        P: TestPage "PG6 PC Temp List";
    begin
        Initialize();
        P.Trap();
        Page.Run(Page::"PG6 PC Temp List", TempRow);
        Say('open');
        Observer.Observe('first', Format(P.First()));
        Say('first-log');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Subscriber_TempList_PageRunFilledBuffer()
    var
        TempRow: Record "PG6 PC Row" temporary;
        P: TestPage "PG6 PC Temp List";
    begin
        Initialize();
        TempRow."Code" := 'T1';
        TempRow.Insert();
        TempRow."Code" := 'T2';
        TempRow.Insert();
        P.Trap();
        Page.Run(Page::"PG6 PC Temp List", TempRow);
        Say('open');
        Observer.Observe('code', P."Code".Value());
        P.Next();
        Say('next');
        P.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure ExtensionAllowsWrites_LockedTempList_NewSetValue()
    var
        P: TestPage "PG6 PC Locked Temp List";
    begin
        Initialize();
        P.OpenEdit();
        Observer.Observe('editable', Format(P.Editable()));
        asserterror begin
            P.New();
            P."Code".SetValue('N1');
            P.Name.SetValue('new');
            P.Next();
            Error('NO_ERROR');
        end;
        SayEnd('new-setvalue');
        P.Close();
        Say('closed');
        Observer.Observe('rows', Names());
        Observer.Finish();
    end;

    [Test]
    procedure ExtensionAllowsModify_LockedCardFromEditAction()
    var
        L: TestPage "PG6 PC Edit List";
        P: TestPage "PG6 PC Locked Card";
    begin
        Initialize();
        L.OpenView();
        L.GoToKey('A');
        P.Trap();
        L.EditLocked.Invoke();
        Observer.Observe('editable', Format(P.Editable()) + '/' + Format(P.Name.Editable()));
        asserterror begin
            P.Name.SetValue('edited');
            P.Close();
            Observer.Observe('rows-in', Names());
            Error('NO_ERROR');
        end;
        SayEnd('setvalue-close');
        L.Close();
        Observer.Observe('rows', Names());
        Observer.Finish();
    end;

    [Test]
    procedure ExtensionDeniesModify_OpenCardFromEditAction()
    var
        L: TestPage "PG6 PC Edit List";
        P: TestPage "PG6 PC Open Card";
    begin
        Initialize();
        L.OpenView();
        L.GoToKey('A');
        P.Trap();
        L.EditOpen.Invoke();
        Observer.Observe('editable', Format(P.Editable()) + '/' + Format(P.Name.Editable()));
        asserterror begin
            P.Name.SetValue('edited');
            P.Close();
            Observer.Observe('rows-in', Names());
            Error('NO_ERROR');
        end;
        SayEnd('setvalue-close');
        L.Close();
        Observer.Observe('rows', Names());
        Observer.Finish();
    end;

    [Test]
    procedure ControlOnLookupError_TextAndCode()
    var
        P: TestPage "PG6 PC Row List";
    begin
        Initialize();
        P.OpenEdit();
        P.GoToKey('A');
        Log.Take();
        asserterror P."Code".Lookup();
        Observer.ObserveError('lookup');
        Say('log');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RowExpressions_NewLine_EditableEnabled()
    var
        P: TestPage "PG6 PC Row List";
    begin
        Initialize();
        P.OpenEdit();
        Observer.Observe('open', Format(P.Name.Editable()) + '/' + Format(P.Name.Enabled()) + ' ' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey-b', Format(P.Name.Editable()) + '/' + Format(P.Name.Enabled()) + ' ' + Log.Take());
        P.New();
        Observer.Observe('new-after-b', Format(P.Name.Editable()) + '/' + Format(P.Name.Enabled()) + ' ' + Log.Take());
        P.GoToKey('A');
        Observer.Observe('gotokey-a', Format(P.Name.Editable()) + '/' + Format(P.Name.Enabled()) + ' ' + Log.Take());
        P.New();
        Observer.Observe('new-after-a', Format(P.Name.Editable()) + '/' + Format(P.Name.Enabled()) + ' ' + Log.Take());
        P.Close();
        Observer.Finish();
    end;
}
