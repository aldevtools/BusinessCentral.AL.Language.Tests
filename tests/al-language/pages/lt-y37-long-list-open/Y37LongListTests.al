// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y37LongListObjects.al (92615 - 92619)
// Probe: written for gap cycle 3 spec C3-12. Every literal asserted below is what the BC service tier produced.
// Facts: a List page opened by TestPage.OpenView whose OnOpenPage leaves Rec on a row with more rows above it (or after it) than the
//   test client's window of 20 rows: Get(25) of 30 rows, FindLast of 30, Get(5) of 30, Get(21) of 21; a temporary source filled in
//   OnOpenPage by Insert in the order 1..29, 31..40, 30 (Rec left on 30, the middle); the same page without row triggers (values and Next
//   results only); Flag set on the last inserted row without Modify. Per test: the row shown after the open, the trigger log of the open,
//   then Next, Previous, First, Last (result, row, log).
// BC versions: 27, 28, 29

codeunit 92620 "LT Y37 Long List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y37 Long Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT Y37 Long Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row.Id := i;
            Row.Name := Log.RowName(i);
            Row.Insert();
        end;
        Log.Reset();
    end;

    local procedure ReadList(var P: TestPage "LT Y37 Long List"; Moves: Boolean)
    begin
        Observer.Observe('open', P.IdCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        if not Moves then
            exit;
        Observer.Observe('next', Format(P.Next()) + '|' + P.IdCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.IdCtl.Value());
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('first', Format(P.First()) + '|' + P.IdCtl.Value());
        Observer.Observe('first log', Log.Take());
        Observer.Observe('last', Format(P.Last()) + '|' + P.IdCtl.Value());
        Observer.Observe('last log', Log.Take());
    end;

    local procedure ReadPrevious(var P: TestPage "LT Y37 Long List")
    begin
        Log.Take();
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.IdCtl.Value());
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('previous 2', Format(P.Previous()) + '|' + P.IdCtl.Value());
        Observer.Observe('previous 2 log', Log.Take());
    end;

    local procedure ReadTempList(var P: TestPage "LT Y37 Long Temp List"; Moves: Boolean)
    begin
        Observer.Observe('open', P.IdCtl.Value() + '|' + P.NameCtl.Value() + '|' + P.FlagCtl.Value());
        Observer.Observe('open log', Log.Take());
        if not Moves then
            exit;
        Observer.Observe('next', Format(P.Next()) + '|' + P.IdCtl.Value() + '|' + P.FlagCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.IdCtl.Value() + '|' + P.FlagCtl.Value());
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('first', Format(P.First()) + '|' + P.IdCtl.Value());
        Observer.Observe('first log', Log.Take());
        Observer.Observe('last', Format(P.Last()) + '|' + P.IdCtl.Value());
        Observer.Observe('last log', Log.Take());
    end;

    local procedure FillMiddleLast()
    begin
        Log.Reset();
        Log.AddInsert(1, 29);
        Log.AddInsert(31, 40);
        Log.AddInsert(30, 30);
    end;

    [Test]
    procedure LT_C312_List_30Rows_GetRow25()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetGet(25);
        P.OpenView();
        ReadList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_30Rows_GetRow25_Previous()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetGet(25);
        P.OpenView();
        ReadPrevious(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_30Rows_FindLast()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetFindLast();
        P.OpenView();
        ReadList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_30Rows_FindLast_Previous()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetFindLast();
        P.OpenView();
        ReadPrevious(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_TempList_40Rows_LastInsertMiddle()
    var
        P: TestPage "LT Y37 Long Temp List";
    begin
        FillMiddleLast();
        P.OpenView();
        ReadTempList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_TempList_40Rows_LastInsertMiddle_Previous()
    var
        P: TestPage "LT Y37 Long Temp List";
    begin
        FillMiddleLast();
        P.OpenView();
        Log.Take();
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.IdCtl.Value());
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('previous 2', Format(P.Previous()) + '|' + P.IdCtl.Value());
        Observer.Observe('previous 2 log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_NoTriggers_TempList_40Rows_LastInsertMiddle()
    var
        P: TestPage "LT Y37 Long Temp List NoTrg";
        i: Integer;
        Steps: Text;
    begin
        FillMiddleLast();
        P.OpenView();
        Steps := P.IdCtl.Value() + '|' + P.NameCtl.Value();
        for i := 1 to 9 do
            Steps += ';' + Format(P.Next()) + '|' + P.NameCtl.Value();
        Observer.Observe('open then 9 x Next', Steps);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_30Rows_GetRow5()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetGet(5);
        P.OpenView();
        ReadList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_30Rows_GetRow5_Previous()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(30);
        Log.SetGet(5);
        P.OpenView();
        ReadPrevious(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_21Rows_GetRow21()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(21);
        Log.SetGet(21);
        P.OpenView();
        ReadList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_List_21Rows_GetRow20()
    var
        P: TestPage "LT Y37 Long List";
    begin
        Seed(21);
        Log.SetGet(20);
        P.OpenView();
        ReadList(P, true);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LT_C312_TempList_40Rows_BufferChanged()
    var
        P: TestPage "LT Y37 Long Temp List";
    begin
        FillMiddleLast();
        Log.SetFlagAfterFill();
        P.OpenView();
        ReadTempList(P, true);
        P.Close();
        Observer.Finish();
    end;
}
