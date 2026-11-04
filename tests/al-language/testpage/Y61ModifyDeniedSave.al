// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-modifyallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); table 93252, pages 93259, 93012, 93013, test codeunit 93248
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a row changed on a page whose ModifyAllowed is false, saved other than at Close: a drill-down on a non-editable temporary list
//   whose code modifies Rec (Rec.Modify) or only assigns a field, followed by First and Close; on an editable list over a database table an
//   action that only assigns a field, then Next; an action whose code calls Rec.Modify; SetValue then Next; SetValue then an action that
//   calls CurrPage.SaveRecord; on a Card an action that assigns, then an action with CurrPage.Update(true), then Close. Each step runs in a
//   TryFunction (ok, error text and code); the shown and stored values and the log of OnModifyRecord (P:) and the table's OnModify (T:).
// Neighbours: pageext/lt-z-page-ext-props/ZPageExtProps.al ZModifyAllowed_* (a SetValue then Close: 'Page cannot be saved.', TestWrapped),
//   pages/lt-outside-worksheet/RmReadOnlyBlob.al, pages/lt-y45-save-before-action/Y45SaveBeforeAction.al (ModifyAllowed true).
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): the TestPage step itself returns without error, but the last error is
//   'Page cannot be saved.' (code SaveAbort) at the step that saves a changed row: an action that only assigns (at the action, on List
//   and Card), Next after SetValue, a CurrPage.SaveRecord action, Close of the temporary list after a drill-down that only assigned. The
//   row is not stored and the page keeps showing the changed value. An action or drill-down whose code calls Rec.Modify saves without
//   error (database row stored, the temporary row on the page) and the page moves on.
// BC versions: all (CI)

table 93252 "LT Y61 MD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Status; Integer) { }
    }

    keys { key(PK; Code) { Clustered = true; } }

    trigger OnModify()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('T:OnModify ' + Code + ' status=' + Format(Status) + ' name=' + Name);
    end;

    procedure Fix()
    begin
        Status := 9;
        Modify();
    end;

    procedure FixNoModify()
    begin
        Status := 9;
    end;
}

page 93259 "LT Y61 MD List"
{
    PageType = List;
    SourceTable = "LT Y61 MD Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(StatusCtl; Rec.Status) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FixAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Fix();
                end;
            }
            action(FixNoModifyAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.FixNoModify();
                end;
            }
            action(SaveAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('P:OnModifyRecord ' + Rec.Code);
        exit(true);
    end;
}

page 93012 "LT Y61 MD Temp List"
{
    PageType = List;
    SourceTable = "LT Y61 MD Row";
    SourceTableTemporary = true;
    Editable = false;
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
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(StatusCtl; Rec.Status) { ApplicationArea = All; }
                field(LinkCtl; LinkTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Rec.Fix();
                    end;
                }
                field(Link2Ctl; LinkTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Rec.FixNoModify();
                    end;
                }
            }
        }
    }

    var
        LinkTxt: Text;

    trigger OnOpenPage()
    begin
        AddRow('A');
        AddRow('B');
        AddRow('C');
        Rec.FindFirst();
    end;

    trigger OnAfterGetRecord()
    begin
        LinkTxt := 'fix';
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('P:OnModifyRecord ' + Rec.Code);
        exit(true);
    end;

    local procedure AddRow(C: Code[10])
    begin
        Rec.Init();
        Rec.Code := C;
        Rec.Name := 'n' + C;
        Rec.Status := 1;
        Rec.Insert();
    end;

    procedure StatusOf(C: Code[10]): Integer
    var
        Copy: Record "LT Y61 MD Row" temporary;
    begin
        Copy.Copy(Rec, true);
        Copy.Get(C);
        exit(Copy.Status);
    end;
}

page 93013 "LT Y61 MD Card"
{
    PageType = Card;
    SourceTable = "LT Y61 MD Row";
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(StatusCtl; Rec.Status) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FixNoModifyAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.FixNoModify();
                end;
            }
            action(UpdateAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('P:OnModifyRecord ' + Rec.Code);
        exit(true);
    end;
}

codeunit 93248 "LT Y61 Modify Denied Save"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "LT Y61 MD Row";
        Log: Record "LT Y61 Log";
    begin
        ClearLastError();
        Observer.Discard();
        R.DeleteAll();
        AddRow('A');
        AddRow('B');
        AddRow('C');
        Log.ClearLog();
    end;

    local procedure AddRow(C: Code[10])
    var
        R: Record "LT Y61 MD Row";
    begin
        R.Init();
        R.Code := C;
        R.Name := 'n' + C;
        R.Status := 1;
        R.Insert();
    end;

    local procedure Stored(C: Code[10]): Text
    var
        R: Record "LT Y61 MD Row";
    begin
        R.Get(C);
        exit(R.Name + '/' + Format(R.Status));
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    var
        Log: Record "LT Y61 Log";
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure Shown(var P: TestPage "LT Y61 MD Temp List"; WithName: Boolean): Text
    var
        Txt: Text;
    begin
        if not TryTempShown(P, Txt) then
            Txt := 'unreadable: ' + GetLastErrorText();
        ClearLastError();
        exit(Txt);
    end;

    [TryFunction]
    local procedure TryTempShown(var P: TestPage "LT Y61 MD Temp List"; var Txt: Text)
    begin
        Txt := P.CodeCtl.Value() + '/' + P.StatusCtl.Value();
    end;

    local procedure Shown(var P: TestPage "LT Y61 MD List"; WithName: Boolean): Text
    var
        Txt: Text;
    begin
        if not TryListShown(P, WithName, Txt) then
            Txt := 'unreadable: ' + GetLastErrorText();
        ClearLastError();
        exit(Txt);
    end;

    [TryFunction]
    local procedure TryListShown(var P: TestPage "LT Y61 MD List"; WithName: Boolean; var Txt: Text)
    begin
        if WithName then
            Txt := P.CodeCtl.Value() + '/' + P.NameCtl.Value()
        else
            Txt := P.CodeCtl.Value() + '/' + P.StatusCtl.Value();
    end;

    local procedure Shown(var P: TestPage "LT Y61 MD Card"; WithName: Boolean): Text
    var
        Txt: Text;
    begin
        if not TryCardShown(P, Txt) then
            Txt := 'unreadable: ' + GetLastErrorText();
        ClearLastError();
        exit(Txt);
    end;

    [TryFunction]
    local procedure TryCardShown(var P: TestPage "LT Y61 MD Card"; var Txt: Text)
    begin
        Txt := P.CodeCtl.Value() + '/' + P.StatusCtl.Value();
    end;

    [TryFunction]
    local procedure TryTempDrill(var P: TestPage "LT Y61 MD Temp List"; Second: Boolean)
    begin
        if Second then
            P.Link2Ctl.Drilldown()
        else
            P.LinkCtl.Drilldown();
    end;

    [TryFunction]
    local procedure TryTempFirst(var P: TestPage "LT Y61 MD Temp List")
    begin
        P.First();
    end;

    [TryFunction]
    local procedure TryTempNext(var P: TestPage "LT Y61 MD Temp List")
    begin
        P.Next();
    end;

    [TryFunction]
    local procedure TryTempClose(var P: TestPage "LT Y61 MD Temp List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryListAction(var P: TestPage "LT Y61 MD List"; Which: Text)
    begin
        case Which of
            'fix':
                P.FixAct.Invoke();
            'fixnomodify':
                P.FixNoModifyAct.Invoke();
            'save':
                P.SaveAct.Invoke();
            'next':
                P.Next();
            'first':
                P.First();
            'close':
                P.Close();
            'setname':
                P.NameCtl.SetValue('x');
        end;
    end;

    [TryFunction]
    local procedure TryCardAction(var P: TestPage "LT Y61 MD Card"; Which: Text)
    begin
        case Which of
            'fixnomodify':
                P.FixNoModifyAct.Invoke();
            'update':
                P.UpdateAct.Invoke();
            'close':
                P.Close();
        end;
    end;

    [Test]
    procedure G617a_Temp_NotEditable_DrillDownModify_ThenFirst()
    var
        P: TestPage "LT Y61 MD Temp List";
    begin
        Seed();
        P.OpenView();
        P.First();
        Step('drilldown', TryTempDrill(P, false));
        Observer.Observe('drilldown shown', Shown(P, false));
        Step('first', TryTempFirst(P));
        Observer.Observe('first shown', Shown(P, false));
        Step('next', TryTempNext(P));
        Observer.Observe('next shown', Shown(P, false));
        Step('close', TryTempClose(P));
        Observer.Observe('stored A', Stored('A'));
        Observer.Expect('drilldown ok', 'Yes');
        Observer.Expect('drilldown|text', '');
        Observer.Expect('drilldown|code', '');
        Observer.Expect('drilldown log', '');
        Observer.Expect('drilldown shown', 'A/9');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', '');
        Observer.Expect('first|code', '');
        Observer.Expect('first log', '');
        Observer.Expect('first shown', 'A/9');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('next shown', 'B/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A', 'nA/1');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Temp_NotEditable_DrillDownAssign_ThenFirst()
    var
        P: TestPage "LT Y61 MD Temp List";
    begin
        Seed();
        P.OpenView();
        P.First();
        Step('drilldown', TryTempDrill(P, true));
        Observer.Observe('drilldown shown', Shown(P, false));
        Step('next', TryTempNext(P));
        Observer.Observe('next shown', Shown(P, false));
        Step('first', TryTempFirst(P));
        Observer.Observe('first shown', Shown(P, false));
        Step('close', TryTempClose(P));
        Observer.Expect('drilldown ok', 'Yes');
        Observer.Expect('drilldown|text', '');
        Observer.Expect('drilldown|code', '');
        Observer.Expect('drilldown log', '');
        Observer.Expect('drilldown shown', 'A/9');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('next shown', 'B/1');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', '');
        Observer.Expect('first|code', '');
        Observer.Expect('first log', '');
        Observer.Expect('first shown', 'A/9');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', 'Page cannot be saved.');
        Observer.Expect('close|code', 'SaveAbort');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Db_Editable_ActionAssign_ThenNext()
    var
        P: TestPage "LT Y61 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Step('action', TryListAction(P, 'fixnomodify'));
        Observer.Observe('action shown', Shown(P, false));
        Step('next', TryListAction(P, 'next'));
        Observer.Observe('next shown', Shown(P, false));
        Step('first', TryListAction(P, 'first'));
        Observer.Observe('first shown', Shown(P, false));
        Observer.Observe('stored A', Stored('A'));
        Step('close', TryListAction(P, 'close'));
        Observer.Observe('stored A after close', Stored('A'));
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('action|text', 'Page cannot be saved.');
        Observer.Expect('action|code', 'SaveAbort');
        Observer.Expect('action log', '');
        Observer.Expect('action shown', 'A/9');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('next shown', 'A/9');
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('first|text', '');
        Observer.Expect('first|code', '');
        Observer.Expect('first log', '');
        Observer.Expect('first shown', 'A/9');
        Observer.Expect('stored A', 'nA/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A after close', 'nA/1');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Db_Editable_ActionModify()
    var
        P: TestPage "LT Y61 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Step('action', TryListAction(P, 'fix'));
        Observer.Observe('action shown', Shown(P, false));
        Observer.Observe('stored A', Stored('A'));
        Step('next', TryListAction(P, 'next'));
        Observer.Observe('next shown', Shown(P, false));
        Step('close', TryListAction(P, 'close'));
        Observer.Observe('stored A after close', Stored('A'));
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('action|text', '');
        Observer.Expect('action|code', '');
        Observer.Expect('action log', '');
        Observer.Expect('action shown', 'A/9');
        Observer.Expect('stored A', 'nA/9');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('next log', '');
        Observer.Expect('next shown', 'B/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A after close', 'nA/9');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Db_Editable_SetValue_ThenNext()
    var
        P: TestPage "LT Y61 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Step('setvalue', TryListAction(P, 'setname'));
        Step('next', TryListAction(P, 'next'));
        Observer.Observe('next shown', Shown(P, true));
        Observer.Observe('stored A', Stored('A'));
        Step('close', TryListAction(P, 'close'));
        Observer.Observe('stored A after close', Stored('A'));
        Observer.Expect('setvalue ok', 'Yes');
        Observer.Expect('setvalue|text', '');
        Observer.Expect('setvalue|code', '');
        Observer.Expect('setvalue log', '');
        Observer.Expect('next ok', 'Yes');
        Observer.Expect('next|text', 'Page cannot be saved.');
        Observer.Expect('next|code', 'SaveAbort');
        Observer.Expect('next log', '');
        Observer.Expect('next shown', 'A/x');
        Observer.Expect('stored A', 'nA/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A after close', 'nA/1');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Db_SaveRecordAction()
    var
        P: TestPage "LT Y61 MD List";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Step('setvalue', TryListAction(P, 'setname'));
        Step('save', TryListAction(P, 'save'));
        Observer.Observe('save shown', Shown(P, true));
        Observer.Observe('stored A', Stored('A'));
        Step('close', TryListAction(P, 'close'));
        Observer.Observe('stored A after close', Stored('A'));
        Observer.Expect('setvalue ok', 'Yes');
        Observer.Expect('setvalue|text', '');
        Observer.Expect('setvalue|code', '');
        Observer.Expect('setvalue log', '');
        Observer.Expect('save ok', 'Yes');
        Observer.Expect('save|text', 'Page cannot be saved.');
        Observer.Expect('save|code', 'SaveAbort');
        Observer.Expect('save log', '');
        Observer.Expect('save shown', 'A/x');
        Observer.Expect('stored A', 'nA/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A after close', 'nA/1');
        Observer.Verify();
    end;

    [Test]
    procedure G617a_Card_ActionAssign_ThenUpdate_ThenClose()
    var
        P: TestPage "LT Y61 MD Card";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('A');
        Step('action', TryCardAction(P, 'fixnomodify'));
        Observer.Observe('action shown', Shown(P, false));
        Step('update', TryCardAction(P, 'update'));
        Observer.Observe('update shown', Shown(P, false));
        Observer.Observe('stored A', Stored('A'));
        Step('close', TryCardAction(P, 'close'));
        Observer.Observe('stored A after close', Stored('A'));
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('action|text', 'Page cannot be saved.');
        Observer.Expect('action|code', 'SaveAbort');
        Observer.Expect('action log', '');
        Observer.Expect('action shown', 'A/9');
        Observer.Expect('update ok', 'Yes');
        Observer.Expect('update|text', '');
        Observer.Expect('update|code', '');
        Observer.Expect('update log', '');
        Observer.Expect('update shown', 'A/9');
        Observer.Expect('stored A', 'nA/1');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored A after close', 'nA/1');
        Observer.Verify();
    end;
}
