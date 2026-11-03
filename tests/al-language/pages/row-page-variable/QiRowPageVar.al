// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onaftergetrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI RV *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a repeater control over a page (global) variable that OnAfterGetRecord sets, one that OnAfterGetCurrRecord sets, on a
//   List of 3 rows and on a ListPart of a card: Value() after OpenView, First, Next, Last, Previous,
//   GoToRecord, after an action that changes the variables (with and without CurrPage.Update) and on a new row.
// Settles al-runtime-rs docs/probes-needed.md row "A list's repeater control over a page variable that OnAfterGetRecord computes"
//   (Tests-ERM 134760 TestPreviewEmployee, TestPreviewVendor, TestPreviewForeignCustomer).
// BC versions: 29 (27 and 28 by CI)

table 86860 "LT QI RV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Host Code"; Code[10]) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86865 "LT QI RV Host"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 86861 "LT QI RV List"
{
    PageType = List;
    SourceTable = "LT QI RV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(AgrVarCtl; AgrVar) { ApplicationArea = All; Editable = false; }
                field(CurVarCtl; CurVar) { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetVarAct)
            {
                ApplicationArea = All;
                Caption = 'Set variables';

                trigger OnAction()
                begin
                    AgrVar := 'action';
                    CurVar := 'action';
                end;
            }
            action(SetVarUpdateAct)
            {
                ApplicationArea = All;
                Caption = 'Set variables and update';

                trigger OnAction()
                begin
                    AgrVar := 'action';
                    CurVar := 'action';
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AgrVar := 'agr ' + Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurVar := 'cur ' + Format(Rec.Id);
    end;

    var
        AgrVar: Text;
        CurVar: Text;
}

page 86862 "LT QI RV Part"
{
    PageType = ListPart;
    SourceTable = "LT QI RV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(AgrVarCtl; AgrVar) { ApplicationArea = All; Editable = false; }
                field(CurVarCtl; CurVar) { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetVarAct)
            {
                ApplicationArea = All;
                Caption = 'Set variables';

                trigger OnAction()
                begin
                    AgrVar := 'action';
                    CurVar := 'action';
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AgrVar := 'agr ' + Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurVar := 'cur ' + Format(Rec.Id);
    end;

    var
        AgrVar: Text;
        CurVar: Text;
}

page 86863 "LT QI RV Host Card"
{
    PageType = Card;
    SourceTable = "LT QI RV Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            }
            part(Lines; "LT QI RV Part")
            {
                ApplicationArea = All;
                SubPageLink = "Host Code" = field("Code");
            }
        }
    }
}

codeunit 86864 "LT QI RV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QI RV Row";
        Host: Record "LT QI RV Host";
        i: Integer;
    begin
        Row.DeleteAll();
        Host.DeleteAll();
        Host."Code" := 'H';
        Host.Insert();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row."Host Code" := 'H';
            Row.Name := 'row ' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure ReadList(var Observer: Codeunit "Probe Observer"; var List: TestPage "LT QI RV List"; Tag: Text)
    begin
        Observer.Observe(Tag, List.IdCtl.Value() + ' | ' + List.AgrVarCtl.Value() + ' | ' + List.CurVarCtl.Value());
    end;

    local procedure ReadPart(var Observer: Codeunit "Probe Observer"; var Host: TestPage "LT QI RV Host Card"; Tag: Text)
    begin
        Observer.Observe(Tag, Host.Lines.IdCtl.Value() + ' | ' + Host.Lines.AgrVarCtl.Value() + ' | ' + Host.Lines.CurVarCtl.Value());
    end;

    [Test]
    procedure QI_RV_List_Navigation()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QI RV Row";
        List: TestPage "LT QI RV List";
    begin
        Seed();
        List.OpenView();
        ReadList(Observer, List, 'open');
        ReadList(Observer, List, 'open-again');
        Observer.Observe('first', Format(List.First()));
        ReadList(Observer, List, 'at-first');
        Observer.Observe('next', Format(List.Next()));
        ReadList(Observer, List, 'at-next');
        Observer.Observe('last', Format(List.Last()));
        ReadList(Observer, List, 'at-last');
        Observer.Observe('previous', Format(List.Previous()));
        ReadList(Observer, List, 'at-previous');
        Row.Get(1);
        List.GoToRecord(Row);
        ReadList(Observer, List, 'at-gotorecord-1');
        Row.Get(3);
        List.GoToRecord(Row);
        ReadList(Observer, List, 'at-gotorecord-3');
        List.Close();
        Observer.Expect('open', '1 | agr 1 | cur 1');
        Observer.Expect('open-again', '1 | agr 1 | cur 1');
        Observer.Expect('first', 'Yes');
        Observer.Expect('at-first', '1 | agr 1 | cur 1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('at-next', '2 | agr 2 | cur 2');
        Observer.Expect('last', 'Yes');
        Observer.Expect('at-last', '3 | agr 3 | cur 3');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('at-previous', '2 | agr 2 | cur 2');
        Observer.Expect('at-gotorecord-1', '1 | agr 1 | cur 1');
        Observer.Expect('at-gotorecord-3', '3 | agr 3 | cur 3');
        Observer.Verify();
    end;

    [Test]
    procedure QI_RV_List_Actions()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QI RV List";
    begin
        Seed();
        List.OpenView();
        List.Next();
        ReadList(Observer, List, 'at-row2');
        List.SetVarAct.Invoke();
        ReadList(Observer, List, 'after-action');
        List.Next();
        ReadList(Observer, List, 'after-action-next');
        List.Previous();
        ReadList(Observer, List, 'after-action-previous');
        List.SetVarUpdateAct.Invoke();
        ReadList(Observer, List, 'after-update-action');
        List.First();
        ReadList(Observer, List, 'after-update-action-first');
        List.Close();
        Observer.Expect('at-row2', '2 | agr 2 | cur 2');
        Observer.Expect('after-action', '2 | agr 2 | cur 2');
        Observer.Expect('after-action-next', '3 | agr 3 | cur 3');
        Observer.Expect('after-action-previous', '2 | agr 2 | cur 2');
        Observer.Expect('after-update-action', '2 | agr 2 | cur 2');
        Observer.Expect('after-update-action-first', '1 | agr 1 | cur 1');
        Observer.Verify();
    end;

    [Test]
    procedure QI_RV_List_NewRow()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QI RV List";
    begin
        Seed();
        List.OpenEdit();
        List.Last();
        ReadList(Observer, List, 'at-last');
        List.New();
        ReadList(Observer, List, 'at-new');
        List.Close();
        Observer.Expect('at-last', '3 | agr 3 | cur 3');
        Observer.Expect('at-new', '0 | agr 3 | cur 0');
        Observer.Verify();
    end;

    [Test]
    procedure QI_RV_Part_Navigation()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QI RV Row";
        Host: TestPage "LT QI RV Host Card";
    begin
        Seed();
        Host.OpenView();
        ReadPart(Observer, Host, 'open');
        Observer.Observe('first', Format(Host.Lines.First()));
        ReadPart(Observer, Host, 'at-first');
        Observer.Observe('next', Format(Host.Lines.Next()));
        ReadPart(Observer, Host, 'at-next');
        Observer.Observe('last', Format(Host.Lines.Last()));
        ReadPart(Observer, Host, 'at-last');
        Observer.Observe('previous', Format(Host.Lines.Previous()));
        ReadPart(Observer, Host, 'at-previous');
        Row.Get(1);
        Host.Lines.GoToRecord(Row);
        ReadPart(Observer, Host, 'at-gotorecord-1');
        Host.Lines.Next();
        Host.Lines.SetVarAct.Invoke();
        ReadPart(Observer, Host, 'after-action');
        Host.Lines.Next();
        ReadPart(Observer, Host, 'after-action-next');
        Host.Close();
        Observer.Expect('open', '1 | agr 1 | cur 1');
        Observer.Expect('first', 'Yes');
        Observer.Expect('at-first', '1 | agr 1 | cur 1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('at-next', '2 | agr 2 | cur 2');
        Observer.Expect('last', 'Yes');
        Observer.Expect('at-last', '3 | agr 3 | cur 3');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('at-previous', '2 | agr 2 | cur 2');
        Observer.Expect('at-gotorecord-1', '1 | agr 1 | cur 1');
        Observer.Expect('after-action', '2 | agr 2 | cur 2');
        Observer.Expect('after-action-next', '3 | agr 3 | cur 3');
        Observer.Verify();
    end;
}
