// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-enabled-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75300 75301, pages 75302..75305, log codeunit 75306, test codeunit 75307
// Probe (al-runner 7916): an action whose Enabled is a page variable that OnAfterGetRecord sets from the row (NextEnabled :=
//   Rec.Rel <> 0), read with TestAction.Enabled() after the open and after each cursor move: GoToKey to a row with Rel <> 0, to a row
//   with Rel = 0 and back, GoToRecord, Next, Previous, First, Last. Opens: OpenView, OpenEdit, Trap + Page.Run(Page, Rec) with a
//   filter. Neighbors: the variable set in OnAfterGetCurrRecord; Visible = the variable on an action; Enabled and Editable = the
//   variable on a field control; a Card page; the reporter's shape on the virtual Field table.
// Rows: A Rel 0, B 349, C 0, D 349, E 0 (the filtered Page.Run shows B..E).
// Observed per step: the read value, then the log since the last step: agr(X) = OnAfterGetRecord on row X, agcr(X) =
//   OnAfterGetCurrRecord on row X.
// local object: the pages are the shapes under test; the log records the record triggers
// Facts: after every move (GoToKey, GoToRecord, Next, Previous, First, Last) Enabled() and Visible() of the action and Enabled() of the
//   field control give the value OnAfterGetRecord (or OnAfterGetCurrRecord) computed for the row the cursor is on, on every open form,
//   on the Card and on the Field table. A GoToKey on a list reads the rows from the first row of the view up to the target (agr twice and
//   agcr per row). Editable() of the field stays No on the non-editable page.
// BC versions: 27, 28, 29

table 75300 "PG6 EW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Rel; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 75301 "PG6 EW Rel Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { DataClassification = SystemMetadata; }
        field(2; RelCode; Code[10]) { DataClassification = SystemMetadata; TableRelation = "PG6 EW Row"; }
        field(3; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// The reporter's shape on an own table: a non-editable list, one action whose Enabled is set by OnAfterGetRecord.
page 75302 "PG6 EW List"
{
    PageType = List;
    SourceTable = "PG6 EW Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(RelCtl; Rec.Rel) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextAction)
            {
                ApplicationArea = All;
                Enabled = NextEnabled;

                trigger OnAction()
                begin
                    Log.Add('act-next');
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 EW Log";
        NextEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        NextEnabled := Rec.Rel <> 0;
        Log.Add('agr(' + Rec."Code" + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Rec."Code" + ')');
    end;
}

// The neighbors: a variable set in OnAfterGetCurrRecord (CurrAction), Visible bound to the OnAfterGetRecord variable (VisAction),
// and a field control whose Enabled and Editable are that variable (FlagCtl).
page 75303 "PG6 EW List Mix"
{
    PageType = List;
    SourceTable = "PG6 EW Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(FlagCtl; Rec.Rel)
                {
                    ApplicationArea = All;
                    Enabled = NextEnabled;
                    Editable = NextEnabled;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CurrAction)
            {
                ApplicationArea = All;
                Enabled = CurrEnabled;

                trigger OnAction()
                begin
                    Log.Add('act-curr');
                end;
            }
            action(VisAction)
            {
                ApplicationArea = All;
                Visible = NextEnabled;

                trigger OnAction()
                begin
                    Log.Add('act-vis');
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 EW Log";
        NextEnabled: Boolean;
        CurrEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        NextEnabled := Rec.Rel <> 0;
        Log.Add('agr(' + Rec."Code" + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrEnabled := Rec.Rel <> 0;
        Log.Add('agcr(' + Rec."Code" + ')');
    end;
}

page 75304 "PG6 EW Card"
{
    PageType = Card;
    SourceTable = "PG6 EW Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(FlagCtl; Rec.Rel)
                {
                    ApplicationArea = All;
                    Enabled = NextEnabled;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextAction)
            {
                ApplicationArea = All;
                Enabled = NextEnabled;

                trigger OnAction()
                begin
                    Log.Add('act-next');
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 EW Log";
        NextEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        NextEnabled := Rec.Rel <> 0;
        Log.Add('agr(' + Rec."Code" + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Rec."Code" + ')');
    end;
}

// The reporter's page on the virtual Field table.
page 75305 "PG6 EW Field List"
{
    PageType = List;
    SourceTable = Field;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(RelCtl; Rec.RelationTableNo) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextAction)
            {
                ApplicationArea = All;
                Enabled = NextEnabled;

                trigger OnAction()
                begin
                    Log.Add('act-next');
                end;
            }
        }
    }

    var
        Log: Codeunit "PG6 EW Log";
        NextEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        NextEnabled := Rec.RelationTableNo <> 0;
        Log.Add('agr(' + Format(Rec."No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr(' + Format(Rec."No.") + ')');
    end;
}

codeunit 75306 "PG6 EW Log"
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

codeunit 75307 "PG6 EW Enabled Walk"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG6 EW Log";

    local procedure Initialize()
    var
        Row: Record "PG6 EW Row";
        Src: Record "PG6 EW Rel Src";
    begin
        Observer.Discard();
        Row.DeleteAll();
        Src.DeleteAll();
        AddRow('A', 0);
        AddRow('B', 349);
        AddRow('C', 0);
        AddRow('D', 349);
        AddRow('E', 0);
        Log.Reset();
    end;

    local procedure AddRow(RowCode: Code[10]; RelValue: Integer)
    var
        Row: Record "PG6 EW Row";
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.Rel := RelValue;
        Row.Insert();
    end;

    local procedure Say(Name: Text; Value: Boolean)
    begin
        Observer.Observe(Name, Format(Value) + ' ' + Log.Take());
    end;

    local procedure WalkList(var P: TestPage "PG6 EW List")
    var
        Row: Record "PG6 EW Row";
    begin
        Say('open', P.NextAction.Enabled());
        P.GoToKey('B');
        Say('gotokey-b', P.NextAction.Enabled());
        P.GoToKey('C');
        Say('gotokey-c', P.NextAction.Enabled());
        P.GoToKey('D');
        Say('gotokey-d', P.NextAction.Enabled());
        Row.Get('E');
        P.GoToRecord(Row);
        Say('gotorecord-e', P.NextAction.Enabled());
        Row.Get('B');
        P.GoToRecord(Row);
        Say('gotorecord-b', P.NextAction.Enabled());
        P.Next();
        Say('next', P.NextAction.Enabled());
        P.Previous();
        Say('previous', P.NextAction.Enabled());
        P.First();
        Say('first', P.NextAction.Enabled());
        P.Last();
        Say('last', P.NextAction.Enabled());
        P.Close();
        Observer.Observe('closed', Log.Take());
    end;

    [Test]
    procedure List_OpenView_EnabledAfterEachMove()
    var
        P: TestPage "PG6 EW List";
    begin
        Initialize();
        P.OpenView();
        WalkList(P);
        Observer.Expect('open', 'No [agr(A) agr(B) agr(C) agr(D) agr(E) agr(A) agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('gotorecord-b', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B)]');
        Observer.Expect('next', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('previous', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('first', 'No [agr(A) agr(A) agcr(A)]');
        Observer.Expect('last', 'No [agr(E) agr(E) agcr(E)]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenEdit_EnabledAfterEachMove()
    var
        P: TestPage "PG6 EW List";
    begin
        Initialize();
        P.OpenEdit();
        WalkList(P);
        Observer.Expect('open', 'No [agr(A) agr(B) agr(C) agr(D) agr(E) agr(A) agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('gotorecord-b', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B)]');
        Observer.Expect('next', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('previous', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('first', 'No [agr(A) agr(A) agcr(A)]');
        Observer.Expect('last', 'No [agr(E) agr(E) agcr(E)]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure List_TrapPageRunFiltered_EnabledAfterEachMove()
    var
        Row: Record "PG6 EW Row";
        P: TestPage "PG6 EW List";
    begin
        Initialize();
        Row.SetRange("Code", 'B', 'E');
        P.Trap();
        Page.Run(Page::"PG6 EW List", Row);
        WalkList(P);
        Observer.Expect('open', 'Yes [agr(B) agr(C) agr(D) agr(E) agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-b', 'Yes []');
        Observer.Expect('gotokey-c', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes [agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No [agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('gotorecord-b', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('next', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('previous', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('first', 'Yes []');
        Observer.Expect('last', 'No [agr(E) agr(E) agcr(E)]');
        Observer.Expect('closed', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure ListMix_CurrRecordVariable_EnabledAfterEachMove()
    var
        Row: Record "PG6 EW Row";
        P: TestPage "PG6 EW List Mix";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.CurrAction.Enabled());
        P.GoToKey('B');
        Say('gotokey-b', P.CurrAction.Enabled());
        P.GoToKey('C');
        Say('gotokey-c', P.CurrAction.Enabled());
        P.GoToKey('D');
        Say('gotokey-d', P.CurrAction.Enabled());
        Row.Get('E');
        P.GoToRecord(Row);
        Say('gotorecord-e', P.CurrAction.Enabled());
        Row.Get('B');
        P.GoToRecord(Row);
        Say('gotorecord-b', P.CurrAction.Enabled());
        P.Next();
        Say('next', P.CurrAction.Enabled());
        P.Previous();
        Say('previous', P.CurrAction.Enabled());
        P.First();
        Say('first', P.CurrAction.Enabled());
        P.Last();
        Say('last', P.CurrAction.Enabled());
        P.Close();
        Observer.Expect('open', 'No [agr(A) agr(B) agr(C) agr(D) agr(E) agr(A) agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('gotorecord-b', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B)]');
        Observer.Expect('next', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('previous', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('first', 'No [agr(A) agr(A) agcr(A)]');
        Observer.Expect('last', 'No [agr(E) agr(E) agcr(E)]');
        Observer.Verify();
    end;

    [Test]
    procedure ListMix_ActionVisible_AfterEachMove()
    var
        Row: Record "PG6 EW Row";
        P: TestPage "PG6 EW List Mix";
    begin
        Initialize();
        P.OpenView();
        Say('open', P.VisAction.Visible());
        P.GoToKey('B');
        Say('gotokey-b', P.VisAction.Visible());
        P.GoToKey('C');
        Say('gotokey-c', P.VisAction.Visible());
        P.GoToKey('D');
        Say('gotokey-d', P.VisAction.Visible());
        Row.Get('E');
        P.GoToRecord(Row);
        Say('gotorecord-e', P.VisAction.Visible());
        Row.Get('B');
        P.GoToRecord(Row);
        Say('gotorecord-b', P.VisAction.Visible());
        P.Next();
        Say('next', P.VisAction.Visible());
        P.Previous();
        Say('previous', P.VisAction.Visible());
        P.First();
        Say('first', P.VisAction.Visible());
        P.Last();
        Say('last', P.VisAction.Visible());
        P.Close();
        Observer.Expect('open', 'No [agr(A) agr(B) agr(C) agr(D) agr(E) agr(A) agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('gotorecord-b', 'Yes [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B)]');
        Observer.Expect('next', 'No [agr(C) agr(C) agcr(C)]');
        Observer.Expect('previous', 'Yes [agr(B) agr(B) agcr(B)]');
        Observer.Expect('first', 'No [agr(A) agr(A) agcr(A)]');
        Observer.Expect('last', 'No [agr(E) agr(E) agcr(E)]');
        Observer.Verify();
    end;

    [Test]
    procedure ListMix_FieldEnabledEditable_AfterEachMove()
    var
        Row: Record "PG6 EW Row";
        P: TestPage "PG6 EW List Mix";
    begin
        Initialize();
        P.OpenEdit();
        Observer.Observe('open', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey-b', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.GoToKey('C');
        Observer.Observe('gotokey-c', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.GoToKey('D');
        Observer.Observe('gotokey-d', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        Row.Get('E');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord-e', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.Previous();
        Observer.Observe('previous', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.First();
        Observer.Observe('first', Format(P.FlagCtl.Enabled()) + '/' + Format(P.FlagCtl.Editable()) + ' ' + Log.Take());
        P.Close();
        Observer.Expect('open', 'No/No [agr(A) agr(B) agr(C) agr(D) agr(E) agr(A) agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes/No [agr(B) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No/No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes/No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No/No [agr(A) agr(A) agcr(A) agr(B) agr(B) agcr(B) agr(C) agr(C) agcr(C) agr(D) agr(D) agcr(D) agr(E) agr(E) agcr(E)]');
        Observer.Expect('previous', 'Yes/No [agr(D) agr(D) agcr(D)]');
        Observer.Expect('first', 'No/No [agr(A) agr(A) agcr(A)]');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenView_EnabledAfterEachMove()
    var
        Row: Record "PG6 EW Row";
        P: TestPage "PG6 EW Card";
    begin
        Initialize();
        P.OpenView();
        Observer.Observe('open', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.GoToKey('B');
        Observer.Observe('gotokey-b', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.GoToKey('C');
        Observer.Observe('gotokey-c', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.GoToKey('D');
        Observer.Observe('gotokey-d', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        Row.Get('E');
        P.GoToRecord(Row);
        Observer.Observe('gotorecord-e', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.Previous();
        Observer.Observe('previous', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.First();
        Observer.Observe('first', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.Last();
        Observer.Observe('last', Format(P.NextAction.Enabled()) + '/' + Format(P.FlagCtl.Enabled()) + ' ' + Log.Take());
        P.Close();
        Observer.Expect('open', 'No/No [agr(A) agcr(A)]');
        Observer.Expect('gotokey-b', 'Yes/Yes [agr(A) agcr(A) agr(B) agcr(B)]');
        Observer.Expect('gotokey-c', 'No/No [agr(A) agcr(A) agr(B) agcr(B) agr(C) agcr(C)]');
        Observer.Expect('gotokey-d', 'Yes/Yes [agr(A) agcr(A) agr(B) agcr(B) agr(C) agcr(C) agr(D) agcr(D)]');
        Observer.Expect('gotorecord-e', 'No/No [agr(A) agcr(A) agr(B) agcr(B) agr(C) agcr(C) agr(D) agcr(D) agr(E) agcr(E)]');
        Observer.Expect('previous', 'Yes/Yes [agr(D) agcr(D)]');
        Observer.Expect('first', 'No/No [agr(A) agcr(A)]');
        Observer.Expect('last', 'No/No [agr(E) agcr(E)]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TrapPageRun_EnabledAfterGoToKey()
    var
        F: Record Field;
        P: TestPage "PG6 EW Field List";
    begin
        Initialize();
        F.SetRange(TableNo, Database::"PG6 EW Rel Src");
        F.SetRange("No.", 1, 3);
        P.Trap();
        Page.Run(Page::"PG6 EW Field List", F);
        Observer.Observe('open', Format(P.NextAction.Enabled()) + ' rel=' + P.RelCtl.Value() + ' ' + Log.Take());
        P.GoToKey(Database::"PG6 EW Rel Src", 2);
        Observer.Observe('gotokey-2', Format(P.NextAction.Enabled()) + ' rel=' + Format(P.RelCtl.AsInteger() <> 0) + ' ' + Log.Take());
        P.GoToKey(Database::"PG6 EW Rel Src", 1);
        Observer.Observe('gotokey-1', Format(P.NextAction.Enabled()) + ' rel=' + P.RelCtl.Value() + ' ' + Log.Take());
        P.GoToKey(Database::"PG6 EW Rel Src", 2);
        Observer.Observe('gotokey-2-again', Format(P.NextAction.Enabled()) + ' ' + Log.Take());
        P.GoToKey(Database::"PG6 EW Rel Src", 3);
        Observer.Observe('gotokey-3', Format(P.NextAction.Enabled()) + ' ' + Log.Take());
        P.Close();
        Observer.Expect('open', 'No rel=0 [agr(1) agr(2) agr(3) agr(1) agr(1) agcr(1)]');
        Observer.Expect('gotokey-2', 'Yes rel=Yes [agr(2) agr(2) agcr(2)]');
        Observer.Expect('gotokey-1', 'No rel=0 [agr(1) agr(1) agcr(1)]');
        Observer.Expect('gotokey-2-again', 'Yes [agr(2) agr(2) agcr(2)]');
        Observer.Expect('gotokey-3', 'No [agr(1) agr(1) agcr(1) agr(2) agr(2) agcr(2) agr(3) agr(3) agcr(3)]');
        Observer.Verify();
    end;
}
