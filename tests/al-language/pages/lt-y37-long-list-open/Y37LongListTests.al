// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y37LongListObjects.al (92615 - 92619)
// Probe: written for gap cycle 3 spec C3-12. Every literal asserted below is what the BC service tier produced.
// Facts: a List page opened by TestPage.OpenView whose OnOpenPage leaves Rec on a row with more rows above it (or after it) than the
//   test client's window of 20 rows: Get(25) of 30 rows, FindLast of 30, Get(5) of 30, Get(21) of 21; a temporary source filled in
//   OnOpenPage by Insert in the order 1..29, 31..40, 30 (Rec left on 30, the middle); the same page without row triggers (values and Next
//   results only); Flag set on the last inserted row without Modify. Per test: the row shown after the open, the trigger log of the open,
//   then Next, Previous, First, Last (result, row, log).
//   BC (28.5 Windows, 29 SaaS alike): the page opens on the row OnOpenPage left Rec on. The open read is: that row and the rows after it, at
//   most 20 rows in all (Get(5) of 30 reads 5..24); then, stepping back from the row, at most 20 rows above it (Get(25) of 30 reads 24..5,
//   FindLast reads 29..10, the temporary source reads 30..40 then 29..10); then the row twice more and OnAfterGetCurrRecord. Each Next and
//   Previous inside the read rows logs R:<row>;R:<row>;C:<row>; First and Last read the rows of the view not yet read first (First after
//   FindLast: R:10..R:1, then R:1;C:1). Flag set on the last inserted row without Modify is not shown (No): the page reads the table.
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
        Observer.Expect('open', '25|N025');
        Observer.Expect('open log', 'O:25;R:25;R:26;R:27;R:28;R:29;R:30;R:25;R:24;R:23;R:22;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:9;R:8;R:7;R:6;R:5;R:25;R:25;C:25;');
        Observer.Expect('next', 'Yes|26');
        Observer.Expect('next log', 'R:26;R:26;C:26;');
        Observer.Expect('previous', 'Yes|25');
        Observer.Expect('previous log', 'R:25;R:25;C:25;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:5;R:4;R:3;R:2;R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|30');
        Observer.Expect('last log', 'R:30;R:30;C:30;');
        Observer.Verify();
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
        Observer.Expect('previous', 'Yes|24');
        Observer.Expect('previous log', 'R:24;R:24;C:24;');
        Observer.Expect('previous 2', 'Yes|23');
        Observer.Expect('previous 2 log', 'R:23;R:23;C:23;');
        Observer.Verify();
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
        Observer.Expect('open', '30|N030');
        Observer.Expect('open log', 'O:30;R:30;R:29;R:28;R:27;R:26;R:25;R:24;R:23;R:22;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:30;R:30;C:30;');
        Observer.Expect('next', 'No|30');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|29');
        Observer.Expect('previous log', 'R:29;R:29;C:29;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:10;R:9;R:8;R:7;R:6;R:5;R:4;R:3;R:2;R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|30');
        Observer.Expect('last log', 'R:30;R:30;C:30;');
        Observer.Verify();
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
        Observer.Expect('previous', 'Yes|29');
        Observer.Expect('previous log', 'R:29;R:29;C:29;');
        Observer.Expect('previous 2', 'Yes|28');
        Observer.Expect('previous 2 log', 'R:28;R:28;C:28;');
        Observer.Verify();
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
        Observer.Expect('open', '30|N030|No');
        Observer.Expect('open log', 'O:30;R:30;R:31;R:32;R:33;R:34;R:35;R:36;R:37;R:38;R:39;R:40;R:30;R:29;R:28;R:27;R:26;R:25;R:24;R:23;R:22;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:30;R:30;C:30;');
        Observer.Expect('next', 'Yes|31|No');
        Observer.Expect('next log', 'R:31;R:31;C:31;');
        Observer.Expect('previous', 'Yes|30|No');
        Observer.Expect('previous log', 'R:30;R:30;C:30;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:10;R:9;R:8;R:7;R:6;R:5;R:4;R:3;R:2;R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|40');
        Observer.Expect('last log', 'R:40;R:40;C:40;');
        Observer.Verify();
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
        Observer.Expect('previous', 'Yes|29');
        Observer.Expect('previous log', 'R:29;R:29;C:29;');
        Observer.Expect('previous 2', 'Yes|28');
        Observer.Expect('previous 2 log', 'R:28;R:28;C:28;');
        Observer.Verify();
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
        Observer.Expect('open then 9 x Next', '30|N030;Yes|N031;Yes|N032;Yes|N033;Yes|N034;Yes|N035;Yes|N036;Yes|N037;Yes|N038;Yes|N039');
        Observer.Verify();
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
        Observer.Expect('open', '5|N005');
        Observer.Expect('open log', 'O:5;R:5;R:6;R:7;R:8;R:9;R:10;R:11;R:12;R:13;R:14;R:15;R:16;R:17;R:18;R:19;R:20;R:21;R:22;R:23;R:24;R:5;R:4;R:3;R:2;R:1;R:5;R:5;C:5;');
        Observer.Expect('next', 'Yes|6');
        Observer.Expect('next log', 'R:6;R:6;C:6;');
        Observer.Expect('previous', 'Yes|5');
        Observer.Expect('previous log', 'R:5;R:5;C:5;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|30');
        Observer.Expect('last log', 'R:24;R:25;R:26;R:27;R:28;R:29;R:30;R:30;C:30;');
        Observer.Verify();
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
        Observer.Expect('previous', 'Yes|4');
        Observer.Expect('previous log', 'R:4;R:4;C:4;');
        Observer.Expect('previous 2', 'Yes|3');
        Observer.Expect('previous 2 log', 'R:3;R:3;C:3;');
        Observer.Verify();
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
        Observer.Expect('open', '21|N021');
        Observer.Expect('open log', 'O:21;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:9;R:8;R:7;R:6;R:5;R:4;R:3;R:2;R:1;R:21;R:21;C:21;');
        Observer.Expect('next', 'No|21');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|20');
        Observer.Expect('previous log', 'R:20;R:20;C:20;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|21');
        Observer.Expect('last log', 'R:21;R:21;C:21;');
        Observer.Verify();
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
        Observer.Expect('open', '20|N020');
        Observer.Expect('open log', 'O:20;R:20;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:9;R:8;R:7;R:6;R:5;R:4;R:3;R:2;R:1;R:20;R:20;C:20;');
        Observer.Expect('next', 'Yes|21');
        Observer.Expect('next log', 'R:21;R:21;C:21;');
        Observer.Expect('previous', 'Yes|20');
        Observer.Expect('previous log', 'R:20;R:20;C:20;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|21');
        Observer.Expect('last log', 'R:21;R:21;C:21;');
        Observer.Verify();
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
        Observer.Expect('open', '30|N030|No');
        Observer.Expect('open log', 'O:30;R:30;R:31;R:32;R:33;R:34;R:35;R:36;R:37;R:38;R:39;R:40;R:30;R:29;R:28;R:27;R:26;R:25;R:24;R:23;R:22;R:21;R:20;R:19;R:18;R:17;R:16;R:15;R:14;R:13;R:12;R:11;R:10;R:30;R:30;C:30;');
        Observer.Expect('next', 'Yes|31|No');
        Observer.Expect('next log', 'R:31;R:31;C:31;');
        Observer.Expect('previous', 'Yes|30|No');
        Observer.Expect('previous log', 'R:30;R:30;C:30;');
        Observer.Expect('first', 'Yes|1');
        Observer.Expect('first log', 'R:10;R:9;R:8;R:7;R:6;R:5;R:4;R:3;R:2;R:1;R:1;C:1;');
        Observer.Expect('last', 'Yes|40');
        Observer.Expect('last log', 'R:40;R:40;C:40;');
        Observer.Verify();
    end;
}
