// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 91251, pages 91252 / 91254, log codeunit 91253 and test codeunit 91255
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: CurrPage.Update(false) and CurrPage.Update(true) called by an action on a list page whose current record is not a stored row: a list opened with
//   OpenView while its table has rows, the draft row after New(), and a list whose view shows no row at all (the page filters every row out in OnOpenPage)
//   while the table has rows. The log records every OnAfterGetCurrRecord (key of Rec and the row count seen), the key of Rec before and after Update,
//   and whether the call raised an error.
// BC versions: 27, 28, 29
table 91251 "LT SC Upd Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91253 "LT SC Upd Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Clear2()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' ; ';
            Result += Line;
        end;
        exit(Result);
    end;
}

page 91252 "LT SC Upd List"
{
    PageType = List;
    SourceTable = "LT SC Upd Row";
    UsageCategory = None;

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

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT SC Upd Log";
                begin
                    Log.Add('before id=' + Format(Rec.Id));
                    CurrPage.Update(false);
                    Log.Add('after id=' + Format(Rec.Id));
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT SC Upd Log";
                begin
                    Log.Add('before id=' + Format(Rec.Id));
                    CurrPage.Update(true);
                    Log.Add('after id=' + Format(Rec.Id));
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SC Upd Log";
    begin
        Log.Add('agcr id=' + Format(Rec.Id) + ' count=' + Format(Rec.Count()));
    end;
}

page 91254 "LT SC Upd Empty View List"
{
    PageType = List;
    SourceTable = "LT SC Upd Row";
    UsageCategory = None;

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
            action(UpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT SC Upd Log";
                begin
                    Log.Add('before id=' + Format(Rec.Id));
                    CurrPage.Update(false);
                    Log.Add('after id=' + Format(Rec.Id));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Id, -5);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT SC Upd Log";
    begin
        Log.Add('agcr id=' + Format(Rec.Id) + ' count=' + Format(Rec.Count()));
    end;
}

codeunit 91255 "LT SC Update Empty Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT SC Upd Row";
        Log: Codeunit "LT SC Upd Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Clear2();
    end;

    [TryFunction]
    local procedure TryInvokeOpenView(UpdateSave: Boolean)
    var
        TP: TestPage "LT SC Upd List";
    begin
        TP.OpenView();
        if UpdateSave then
            TP.UpdateTrue.Invoke()
        else
            TP.UpdateFalse.Invoke();
        TP.Close();
    end;

    [Test]
    procedure OpenView_RowsExist_ActionUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SC Upd Log";
    begin
        Seed();
        Observer.Observe('update false completed', Format(TryInvokeOpenView(false)));
        Observer.Observe('update false log', Log.Joined());
        Seed();
        Observer.Observe('update true completed', Format(TryInvokeOpenView(true)));
        Observer.Observe('update true log', Log.Joined());
        Observer.Expect('update false completed', 'Yes');
        Observer.Expect('update false log', 'agcr id=1 count=2 ; before id=1 ; after id=1 ; agcr id=1 count=2');
        Observer.Expect('update true completed', 'Yes');
        Observer.Expect('update true log', 'agcr id=1 count=2 ; before id=1 ; after id=1 ; agcr id=1 count=2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewThenInvoke()
    var
        TP: TestPage "LT SC Upd List";
    begin
        TP.OpenView();
        TP.New();
        TP.UpdateFalse.Invoke();
        TP.Close();
    end;

    [Test]
    procedure OpenView_NewDraftRow_ActionUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SC Upd Log";
        Row: Record "LT SC Upd Row";
    begin
        Seed();
        Observer.Observe('completed', Format(TryNewThenInvoke()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Format(Row.Count()));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('log', 'agcr id=1 count=2 ; agcr id=0 count=2 ; before id=0 ; after id=0 ; agcr id=1 count=2');
        Observer.Expect('rows after', '2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEmptyViewInvoke()
    var
        TP: TestPage "LT SC Upd Empty View List";
    begin
        TP.OpenView();
        TP.UpdateFalse.Invoke();
        TP.Close();
    end;

    [Test]
    procedure OpenView_ViewShowsNoRowWhileTableHasRows_ActionUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SC Upd Log";
        Row: Record "LT SC Upd Row";
    begin
        Seed();
        Observer.Observe('completed', Format(TryEmptyViewInvoke()));
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Format(Row.Count()));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('log', 'before id=0 ; after id=0');
        Observer.Expect('rows after', '2');
        Observer.Verify();
    end;
}
