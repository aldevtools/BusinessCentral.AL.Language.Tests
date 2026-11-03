// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 91306, log codeunit 91307, page 91308 and test codeunit 91309
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: an action on a list page opened with OpenView whose current record is the draft row of TestPage.New(), and the draft is left untouched:
//   CurrPage.Update(true), an action that calls no Update at all, and CurrPage.Update(false) when New() was called while the second or the last row
//   was current; and the same three actions on a list over an empty table. The log records every OnAfterGetCurrRecord (key of Rec and the row count
//   seen) and the key of Rec before and after the action body; the rows of the table are read after the page is closed.
//   ScUpdateEmptyRow.al pins Update(false) on a draft row started on the first row.
// BC versions: 27, 28, 29
table 91306 "LT Y6 Upd Row"
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

codeunit 91307 "LT Y6 Upd Log"
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

page 91308 "LT Y6 Upd List"
{
    PageType = List;
    SourceTable = "LT Y6 Upd Row";
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
                    Log: Codeunit "LT Y6 Upd Log";
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
                    Log: Codeunit "LT Y6 Upd Log";
                begin
                    Log.Add('before id=' + Format(Rec.Id));
                    CurrPage.Update(true);
                    Log.Add('after id=' + Format(Rec.Id));
                end;
            }
            action(NoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT Y6 Upd Log";
                begin
                    Log.Add('body id=' + Format(Rec.Id));
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y6 Upd Log";
    begin
        Log.Add('agcr id=' + Format(Rec.Id) + ' count=' + Format(Rec.Count()));
    end;
}

codeunit 91309 "LT Y6 Update Draft Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(RowCount: Integer)
    var
        Row: Record "LT Y6 Upd Row";
        Log: Codeunit "LT Y6 Upd Log";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to RowCount do begin
            Row.Id := i;
            Row.Name := 'row' + Format(i);
            Row.Insert();
        end;
        Log.Clear2();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT Y6 Upd Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += '[' + Format(Row.Id) + ':' + Row.Name + ']';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ' ' + Result);
    end;

    [Test]
    procedure Draft_FromFirstRow_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(2);
        TP.OpenView();
        TP.New();
        TP.UpdateTrue.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '1');
        Observer.Expect('log', 'agcr id=1 count=2 ; agcr id=0 count=2 ; before id=0 ; after id=0 ; agcr id=1 count=2');
        Observer.Expect('rows after', '2 [1:row1][2:row2]');
        Observer.Verify();
    end;

    [Test]
    procedure Draft_FromFirstRow_NoUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(2);
        TP.OpenView();
        TP.New();
        TP.NoUpdate.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '1');
        Observer.Expect('log', 'agcr id=1 count=2 ; agcr id=0 count=2 ; body id=0 ; agcr id=1 count=2');
        Observer.Expect('rows after', '2 [1:row1][2:row2]');
        Observer.Verify();
    end;

    [Test]
    procedure Draft_FromLastRow_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(3);
        TP.OpenView();
        TP.Last();
        TP.New();
        TP.UpdateFalse.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '3');
        Observer.Expect('log', 'agcr id=1 count=3 ; agcr id=3 count=3 ; agcr id=0 count=3 ; before id=0 ; after id=0 ; agcr id=3 count=3');
        Observer.Expect('rows after', '3 [1:row1][2:row2][3:row3]');
        Observer.Verify();
    end;

    [Test]
    procedure Draft_FromSecondRow_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(3);
        TP.OpenView();
        TP.Next();
        TP.New();
        TP.UpdateFalse.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '2');
        Observer.Expect('log', 'agcr id=1 count=3 ; agcr id=2 count=3 ; agcr id=0 count=3 ; before id=0 ; after id=0 ; agcr id=2 count=3');
        Observer.Expect('rows after', '3 [1:row1][2:row2][3:row3]');
        Observer.Verify();
    end;

    [Test]
    procedure Draft_FromLastRow_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(3);
        TP.OpenView();
        TP.Last();
        TP.New();
        TP.UpdateTrue.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '1');
        Observer.Expect('log', 'agcr id=1 count=3 ; agcr id=3 count=3 ; agcr id=0 count=3 ; before id=0 ; after id=0 ; agcr id=1 count=3');
        Observer.Expect('rows after', '3 [1:row1][2:row2][3:row3]');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyTable_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(0);
        TP.OpenView();
        TP.UpdateFalse.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '');
        Observer.Expect('log', 'before id=0 ; after id=0');
        Observer.Expect('rows after', '0 ');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyTable_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(0);
        TP.OpenView();
        TP.UpdateTrue.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '');
        Observer.Expect('log', 'before id=0 ; after id=0');
        Observer.Expect('rows after', '0 ');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyTable_NoUpdate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(0);
        TP.OpenView();
        TP.NoUpdate.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '');
        Observer.Expect('log', 'body id=0');
        Observer.Expect('rows after', '0 ');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyTable_NewThenUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y6 Upd Log";
        TP: TestPage "LT Y6 Upd List";
    begin
        Seed(0);
        TP.OpenView();
        TP.New();
        TP.UpdateTrue.Invoke();
        Observer.Observe('page id after', TP.Id.Value());
        TP.Close();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rows after', Rows());
        Observer.Expect('page id after', '');
        Observer.Expect('log', 'agcr id=0 count=0 ; before id=0 ; after id=0');
        Observer.Expect('rows after', '0 ');
        Observer.Verify();
    end;
}
