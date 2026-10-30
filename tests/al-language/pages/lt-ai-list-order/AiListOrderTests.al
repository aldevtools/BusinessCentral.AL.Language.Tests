// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT AI Row / Log Mgt / List pages (AiFixtures.al)
// Probe: trigger order of list pages: Update with the current row kept, Update on an unchanged view, with and without OnAfterGetCurrRecord,
//        Update after the view dropped the current row (no OnNextRecord, no row after), Next past the last row, cursor not on the first row, 20+ rows.
//        Writer QP: QP_EmptyView_* (pages in QpUpdateEmptyList.al): Update(false) on a list that showed no row, after the filter changed so rows exist.
// Object ids 78860 - 78862.

codeunit 78860 "LT AI List Update Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Keep_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1002;R:R1002;A:filter;A:done;R:R1002;F:=>=Yes;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=0;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Same_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1002;R:R1002;A:update;A:done;R:R1002;F:=>=Yes;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Keep_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Expect('update', 'R:R1002;A:filter;A:done;R:R1002;F:=>=Yes;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=0;R:R1002;N:-1=-1;R:R1001;N:-1=0;R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', 'R:R1001;F:==Yes;R:R1001;C:R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Same_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Expect('update', 'R:R1002;A:update;A:done;R:R1002;F:=>=Yes;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1002;N:-1=-1;R:R1001;N:-1=0;R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', 'R:R1001;F:==Yes;R:R1001;C:R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Same_Nav_OnOpenRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('update', 'R:R1001;A:update;A:done;R:R1001;F:=>=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1001');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Same_NavCurr_OnOpenRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('update', 'R:R1001;A:update;A:done;R:R1001;F:=>=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('current', 'R1001');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Keep_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.KeepFilter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1002;R:R1002;A:filter;A:done;R:R1002;R:R1002;R:R1003;R:R1004;R:R1002;R:R1001');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure Same_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001;R:R1001;C:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1002;R:R1002;C:R1002');
        Observer.Expect('update', 'R:R1002;A:update;A:done;R:R1002;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1002;R:R1001;R:R1002;R:R1002;C:R1002');
        Observer.Expect('current', 'R1002');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', 'R:R1001;R:R1001;C:R1001');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_FindOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List FindOnly";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1002;R:R1002;A:filter;A:done;R:R1003;F:=>=Yes;R:R1003;R:R1004;R:R1005;R:R1006;R:R1003');
        Observer.Expect('current', 'R1003');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1003');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1002;R:R1002;A:filter;A:done;R:R1003;R:R1003;R:R1004;R:R1005;R:R1006;R:R1003');
        Observer.Expect('current', 'R1003');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1003');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_RowsAfter_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1002')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001;R:R1001;C:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1002;R:R1002;C:R1002');
        Observer.Expect('update', 'R:R1002;A:filter;A:done;R:R1003;R:R1003;R:R1004;R:R1005;R:R1006;R:R1003;R:R1003;C:R1003');
        Observer.Expect('current', 'R1003');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1003');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1006')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1006;R:R1006;A:filter;A:done;N:1=0;N:-1=-1;R:R1005;F:=>=Yes;R:R1005;N:1=0;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1005');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1006')));
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('update', 'R:R1006;A:filter;A:done;N:1=0;N:-1=-1;R:R1005;F:=>=Yes;R:R1005;N:1=0;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0;R:R1005;F:==Yes;R:R1005;C:R1005');
        Observer.Expect('current', 'R1005');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', 'R:R1001;F:==Yes;R:R1001;C:R1001');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_FindOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List FindOnly";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1006')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1006;R:R1006;A:filter;A:done;R:R1005;F:=>=Yes;R:R1005;R:R1004;R:R1003;R:R1002;R:R1001');
        Observer.Expect('current', 'R1005');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;

    [Test]
    procedure DropCurrent_NoRowsAfter_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1006')));
        Observer.Observe('goto_log', Log.Dump());
        Log.Clear();
        P.DropCurrentNoRowsAfter.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_no', P.NoCtl.Value());
        Observer.Observe('after_first', Log.Dump());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('update', 'R:R1006;R:R1006;A:filter;A:done;R:R1005;R:R1005;R:R1004;R:R1003;R:R1002;R:R1001');
        Observer.Expect('current', 'R1005');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('after_first', '');
        Observer.Verify();
    end;
}

codeunit 78861 "LT AI List Navigation Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Next_OneRow_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=0;N:-1=0');
        Observer.Expect('next1', 'No');
        Observer.Expect('next1_log', '');
        Observer.Expect('next1_no', 'R1001');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Next_OneRow_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=0;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('next1', 'No');
        Observer.Expect('next1_log', '');
        Observer.Expect('next1_no', 'R1001');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Next_TwoRows_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('next1', 'Yes');
        Observer.Expect('next1_log', '');
        Observer.Expect('next1_no', 'R1002');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1002');
        Observer.Verify();
    end;

    [Test]
    procedure Next_TwoRows_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('next1', 'Yes');
        Observer.Expect('next1_log', 'R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Expect('next1_no', 'R1002');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1002');
        Observer.Verify();
    end;

    [Test]
    procedure Next_OneRow_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(1);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'R:R1001');
        Observer.Expect('next1', 'No');
        Observer.Expect('next1_log', '');
        Observer.Expect('next1_no', 'R1001');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Next_TwoRows_PlainCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List PlainCurr";
    begin
        Log.Seed(2);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next1', Format(P.Next()));
        Observer.Observe('next1_log', Log.Dump());
        Observer.Observe('next1_no', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next2', Format(P.Next()));
        Observer.Observe('next2_log', Log.Dump());
        Observer.Observe('next2_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('open', 'R:R1001;R:R1002;R:R1001;R:R1001;C:R1001');
        Observer.Expect('next1', 'Yes');
        Observer.Expect('next1_log', 'R:R1002;R:R1002;C:R1002');
        Observer.Expect('next1_no', 'R1002');
        Observer.Expect('next2', 'No');
        Observer.Expect('next2_log', '');
        Observer.Expect('next2_no', 'R1002');
        Observer.Verify();
    end;

    [Test]
    procedure Next_EmptyList_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(0);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=No');
        Observer.Expect('next', 'No');
        Observer.Expect('next_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecord_BeforeAnyNavigation_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
        P: TestPage "LT AI List";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Row.Get('R1004');
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('goto_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', '');
        Observer.Expect('current', 'R1004');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecord_BeforeAnyNavigation_NavCurr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
        P: TestPage "LT AI List Curr";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Log.Clear();
        Row.Get('R1004');
        Observer.Observe('goto', Format(P.GoToRecord(Row)));
        Observer.Observe('goto_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1002;F:==Yes;R:R1002;C:R1002;R:R1003;F:==Yes;R:R1003;C:R1003;R:R1004;F:==Yes;R:R1004;C:R1004');
        Observer.Expect('current', 'R1004');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', 'R:R1005;F:==Yes;R:R1005;C:R1005');
        Observer.Verify();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(6);
        Log.SetStartKey('R1004');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_log', Log.Dump());
        Log.SetStartKey('');
        P.Close();
        Observer.Expect('open', 'R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1004');
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_Next()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(6);
        Log.SetStartKey('R1004');
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.SetStartKey('');
        P.Close();
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current', 'R1005');
        Observer.Verify();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_LastRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(6);
        Log.SetStartKey('R1006');
        Log.Clear();
        P.OpenView();
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Log.SetStartKey('');
        P.Close();
        Observer.Expect('current', 'R1006');
        Observer.Expect('next', 'No');
        Observer.Expect('next_log', '');
        Observer.Verify();
    end;

    // Probe (corpus writer Y3, al-runtime-rs docs/probes-needed.md "Page row window"): the reads while the list opens on its last row (R1006) and on the
    // row before it (R1005), with rows above. Is the opening row read again before OnNextRecord(-1)?
    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_LastRow_OpenLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(6);
        Log.SetStartKey('R1006');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.SetStartKey('');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OpenOnRow_SetPositionInOnOpenPage_SecondLastRow_OpenLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(6);
        Log.SetStartKey('R1005');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.SetStartKey('');
        P.Close();
        Observer.Finish();
    end;
}

codeunit 78862 "LT AI List Paging Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [PageHandler]
    procedure RunHandler(var P: TestPage "LT AI List")
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current2', P.NoCtl.Value());
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordOnFifthRow()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(12);
        Log.Clear();
        Row.Get('R1005');
        Page.Run(Page::"LT AI List", Row);
        Observer.Expect('open', 'F:=>=Yes;R:R1005;N:1=1;R:R1006;N:1=1;R:R1007;N:1=1;R:R1008;N:1=1;R:R1009;N:1=1;R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=0;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1005');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current2', 'R1006');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordWithFilterOnFifthRow()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(12);
        Log.Clear();
        Row.SetFilter(Qty, '>=%1', 3);
        Row.Get('R1005');
        Page.Run(Page::"LT AI List", Row);
        Observer.Expect('open', 'F:=>=Yes;R:R1005;N:1=1;R:R1006;N:1=1;R:R1007;N:1=1;R:R1008;N:1=1;R:R1009;N:1=1;R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=0;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=0');
        Observer.Expect('current', 'R1005');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current2', 'R1006');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_Open_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        P.Close();
        Observer.Expect('open', 'F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=1;R:R1007;N:1=1;R:R1008;N:1=1;R:R1009;N:1=1;R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=1;R:R1013;N:1=1;R:R1014;N:1=1;R:R1015;N:1=1;R:R1016;N:1=1;R:R1017;N:1=1;R:R1018;N:1=1;R:R1019;N:1=1;R:R1020;R:R1001;N:-1=0');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_OpenThenNext_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current', 'R1002');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_Last_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('last_log', Log.Dump());
        Observer.Observe('last_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('last', 'Yes');
        Observer.Expect('last_log', 'R:R1020;N:1=1;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=0');
        Observer.Expect('last_no', 'R1025');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_LastThenFirst_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        P.Last();
        Log.Clear();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('first_log', Log.Dump());
        Observer.Observe('first_no', P.NoCtl.Value());
        P.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('first_log', '');
        Observer.Expect('first_no', 'R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_GoToKey_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        Log.Clear();
        Observer.Observe('goto', Format(P.GoToKey('R1021')));
        Observer.Observe('goto_log', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto_log', 'R:R1019;R:R1020;N:1=1;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=0');
        Observer.Expect('current', 'R1021');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_GoToKeyThenWalk_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        P.GoToKey('R1021');
        Log.Clear();
        while P.Next() do
            Observer.Observe('at' + P.NoCtl.Value(), Log.Dump());
        Observer.Observe('end', P.NoCtl.Value());
        Observer.Observe('end_log', Log.Dump());
        P.Close();
        Observer.Expect('atR1022', '');
        Observer.Expect('atR1023', '');
        Observer.Expect('atR1024', '');
        Observer.Expect('atR1025', '');
        Observer.Expect('end', 'R1025');
        Observer.Expect('end_log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_UpdateOnRowTwentyOne_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        P.GoToKey('R1021');
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Expect('update', 'R:R1021;R:R1021;A:update;A:done;R:R1021;F:=>=Yes;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=0;R:R1021;N:-1=-1;R:R1020;N:-1=-1;R:R1019;N:-1=-1;R:R1018;N:-1=-1;R:R1017;N:-1=-1;R:R1016;N:-1=-1;R:R1015;N:-1=-1;R:R1014;N:-1=-1;R:R1013;N:-1=-1;R:R1012;N:-1=-1;R:R1011;N:-1=-1;R:R1010;N:-1=-1;R:R1009;N:-1=-1;R:R1008;N:-1=-1;R:R1007;N:-1=-1;R:R1006;N:-1=-1;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001');
        Observer.Expect('current', 'R1021');
        Observer.Verify();
    end;

    [Test]
    procedure Paging_UpdateOnRowTwentyOne_Plain()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Plain";
    begin
        Log.Seed(25);
        Log.Clear();
        P.OpenView();
        P.GoToKey('R1021');
        Log.Clear();
        P.SameView.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        P.Close();
        Observer.Expect('update', 'R:R1021;R:R1021;A:update;A:done;R:R1021;R:R1021;R:R1022;R:R1023;R:R1024;R:R1025;R:R1021;R:R1020;R:R1019;R:R1018;R:R1017;R:R1016;R:R1015;R:R1014;R:R1013;R:R1012;R:R1011;R:R1010;R:R1009;R:R1008;R:R1007;R:R1006;R:R1005;R:R1004;R:R1003;R:R1002;R:R1001');
        Observer.Expect('current', 'R1021');
        Observer.Verify();
    end;

    // Writer BE (corpus #660, asked by al-runtime-rs assumption list-open-full-window-rows-before): the open read of a list whose
    // first window of 20 rows is full and that has rows before its first row (40 rows, opened on R1010), with OnFindRecord,
    // OnNextRecord and OnAfterGetRecord, without OnAfterGetCurrRecord (LT AI List, LT AI List Pos) and with it (LT AI List Curr).
    // Measured (BC 29.0): 20 rows forward, then back from the first row one row at a time until OnNextRecord(-1) answers 0 or 20 rows
    // are read back; without OnAfterGetCurrRecord the read ends there (no OnFindRecord('=')), with it it ends 'R;F:=;R;C' on the first row.
    [PageHandler]
    procedure RunCurrHandler(var P: TestPage "LT AI List Curr")
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current2', P.NoCtl.Value());
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordOnTenthOfForty_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(40);
        Log.Clear();
        Row.Get('R1010');
        Page.Run(Page::"LT AI List", Row);
        Observer.Expect('open', 'F:=>=Yes;R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=1;R:R1013;N:1=1;R:R1014;N:1=1;R:R1015;N:1=1;R:R1016;N:1=1;R:R1017;N:1=1;R:R1018;N:1=1;R:R1019;N:1=1;R:R1020;N:1=1;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=1;R:R1026;N:1=1;R:R1027;N:1=1;R:R1028;N:1=1;R:R1029;R:R1010;N:-1=-1;R:R1009;N:-1=-1;R:R1008;N:-1=-1;R:R1007;N:-1=-1;R:R1006;N:-1=-1;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1010');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current2', 'R1011');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RunCurrHandler')]
    procedure PageRun_RecordOnTenthOfForty_NavCurr()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(40);
        Log.Clear();
        Row.Get('R1010');
        Page.Run(Page::"LT AI List Curr", Row);
        Observer.Expect('open', 'F:=>=Yes;R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=1;R:R1013;N:1=1;R:R1014;N:1=1;R:R1015;N:1=1;R:R1016;N:1=1;R:R1017;N:1=1;R:R1018;N:1=1;R:R1019;N:1=1;R:R1020;N:1=1;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=1;R:R1026;N:1=1;R:R1027;N:1=1;R:R1028;N:1=1;R:R1029;R:R1010;N:-1=-1;R:R1009;N:-1=-1;R:R1008;N:-1=-1;R:R1007;N:-1=-1;R:R1006;N:-1=-1;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0;R:R1010;F:==Yes;R:R1010;C:R1010');
        Observer.Expect('current', 'R1010');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', 'R:R1011;F:==Yes;R:R1011;C:R1011');
        Observer.Expect('current2', 'R1011');
        Observer.Verify();
    end;

    [Test]
    procedure OpenOnRow_TenthOfForty_Pos()
    var
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT AI List Pos";
    begin
        Log.Seed(40);
        Log.SetStartKey('R1010');
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_log', Log.Dump());
        Observer.Observe('current2', P.NoCtl.Value());
        Log.SetStartKey('');
        P.Close();
        Observer.Expect('open', 'R:R1010;N:1=1;R:R1011;N:1=1;R:R1012;N:1=1;R:R1013;N:1=1;R:R1014;N:1=1;R:R1015;N:1=1;R:R1016;N:1=1;R:R1017;N:1=1;R:R1018;N:1=1;R:R1019;N:1=1;R:R1020;N:1=1;R:R1021;N:1=1;R:R1022;N:1=1;R:R1023;N:1=1;R:R1024;N:1=1;R:R1025;N:1=1;R:R1026;N:1=1;R:R1027;N:1=1;R:R1028;N:1=1;R:R1029;R:R1010;N:-1=-1;R:R1009;N:-1=-1;R:R1008;N:-1=-1;R:R1007;N:-1=-1;R:R1006;N:-1=-1;R:R1005;N:-1=-1;R:R1004;N:-1=-1;R:R1003;N:-1=-1;R:R1002;N:-1=-1;R:R1001;N:-1=0');
        Observer.Expect('current', 'R1010');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current2', 'R1011');
        Observer.Verify();
    end;

    // More rows before the first than a window holds (60 rows, opened on R1030): does the read back stop?
    [Test]
    [HandlerFunctions('RunHandler')]
    procedure PageRun_RecordOnThirtiethOfSixty_Nav()
    var
        Log: Codeunit "LT AI Log Mgt";
        Row: Record "LT AI Row";
    begin
        Log.Seed(60);
        Log.Clear();
        Row.Get('R1030');
        Page.Run(Page::"LT AI List", Row);
        Observer.Expect('open', 'F:=>=Yes;R:R1030;N:1=1;R:R1031;N:1=1;R:R1032;N:1=1;R:R1033;N:1=1;R:R1034;N:1=1;R:R1035;N:1=1;R:R1036;N:1=1;R:R1037;N:1=1;R:R1038;N:1=1;R:R1039;N:1=1;R:R1040;N:1=1;R:R1041;N:1=1;R:R1042;N:1=1;R:R1043;N:1=1;R:R1044;N:1=1;R:R1045;N:1=1;R:R1046;N:1=1;R:R1047;N:1=1;R:R1048;N:1=1;R:R1049;R:R1030;N:-1=-1;R:R1029;N:-1=-1;R:R1028;N:-1=-1;R:R1027;N:-1=-1;R:R1026;N:-1=-1;R:R1025;N:-1=-1;R:R1024;N:-1=-1;R:R1023;N:-1=-1;R:R1022;N:-1=-1;R:R1021;N:-1=-1;R:R1020;N:-1=-1;R:R1019;N:-1=-1;R:R1018;N:-1=-1;R:R1017;N:-1=-1;R:R1016;N:-1=-1;R:R1015;N:-1=-1;R:R1014;N:-1=-1;R:R1013;N:-1=-1;R:R1012;N:-1=-1;R:R1011;N:-1=-1;R:R1010');
        Observer.Expect('current', 'R1030');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_log', '');
        Observer.Expect('current2', 'R1031');
        Observer.Verify();
    end;

    [Test]
    procedure QP_EmptyView_UpdateFalse_ShowAll_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT QP AI Empty Nav";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('open_current', P.NoCtl.Value());
        Log.Clear();
        P.ShowAll.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_no', P.NoCtl.Value());
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'O;F:=><=No');
        Observer.Expect('open_current', '');
        Observer.Expect('update', 'A:filter;A:done;F:=><=Yes;R:R1001;N:1=1;R:R1002;N:1=1;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1001;N:-1=0;F:==Yes;R:R1001;C:R1001');
        Observer.Expect('current', 'R1001');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_no', 'R1002');
        Observer.Expect('next_log', 'R:R1002;F:==Yes;R:R1002;C:R1002');
        Observer.Verify();
    end;

    [Test]
    procedure QP_EmptyView_UpdateFalse_ShowFromThree_Nav()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT QP AI Empty Nav";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('open_current', P.NoCtl.Value());
        Log.Clear();
        P.ShowFromThree.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_no', P.NoCtl.Value());
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'O;F:=><=No');
        Observer.Expect('open_current', '');
        Observer.Expect('update', 'A:filter;A:done;F:=><=Yes;R:R1003;N:1=1;R:R1004;N:1=1;R:R1005;N:1=1;R:R1006;N:1=0;R:R1003;N:-1=0;F:==Yes;R:R1003;C:R1003');
        Observer.Expect('current', 'R1003');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_no', 'R1004');
        Observer.Expect('next_log', 'R:R1004;F:==Yes;R:R1004;C:R1004');
        Observer.Verify();
    end;

    [Test]
    procedure QP_EmptyView_UpdateFalse_ShowAll_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT QP AI Empty Plain";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('open_current', P.NoCtl.Value());
        Log.Clear();
        P.ShowAll.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_no', P.NoCtl.Value());
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'O');
        Observer.Expect('open_current', '');
        Observer.Expect('update', 'A:filter;A:done;R:R1001;R:R1002;R:R1003;R:R1004;R:R1005;R:R1006;R:R1001;R:R1001;C:R1001');
        Observer.Expect('current', 'R1001');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_no', 'R1002');
        Observer.Expect('next_log', 'R:R1002;R:R1002;C:R1002');
        Observer.Verify();
    end;

    [Test]
    procedure QP_EmptyView_UpdateFalse_ShowFromThree_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AI Log Mgt";
        P: TestPage "LT QP AI Empty Plain";
    begin
        Log.Seed(6);
        Log.Clear();
        P.OpenView();
        Observer.Observe('open', Log.Dump());
        Observer.Observe('open_current', P.NoCtl.Value());
        Log.Clear();
        P.ShowFromThree.Invoke();
        Observer.Observe('update', Log.Dump());
        Observer.Observe('current', P.NoCtl.Value());
        Log.Clear();
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next_no', P.NoCtl.Value());
        Observer.Observe('next_log', Log.Dump());
        P.Close();
        Observer.Expect('open', 'O');
        Observer.Expect('open_current', '');
        Observer.Expect('update', 'A:filter;A:done;R:R1003;R:R1004;R:R1005;R:R1006;R:R1003;R:R1003;C:R1003');
        Observer.Expect('current', 'R1003');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next_no', 'R1004');
        Observer.Expect('next_log', 'R:R1004;R:R1004;C:R1004');
        Observer.Verify();
    end;
}
