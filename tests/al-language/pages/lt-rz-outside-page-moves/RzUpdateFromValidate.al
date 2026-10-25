// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT RZ Line / Log Mgt / Update pages (RzFixtures.al, writer RZ)
// Probe: a field's OnValidate sets a filter on Rec that leaves the row the page stands on, then calls CurrPage.Update(false) or Update(true).
//   Which row the page stands on afterwards, which rows it lists, and the triggers on the way. Pages: a Worksheet with the filter field in a
//   header group, without OnFindRecord/OnNextRecord (the shape of al-runner issue 5824) and with them; a List whose filter field is a
//   repeater field. Data: A G1, B G2, C G1, D G2, E G1, F G2. The same move after an ACTION is pinned in pages/lt-ai-list-order/AiListOrderTests.al.
// Object ids 88920 (writer RZ).
// BC versions: 27, 28, 29

codeunit 88920 "LT RZ Update From Validate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Global so the helpers can record; every test starts with Discard (a failed test leaves no pairs behind).
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RZ Log Mgt";

    // The four rows of issue 5824 on the plain Worksheet.
    [Test]
    procedure RZ_PlainWs_B_G1()
    begin
        PlainWs('B', 'G1', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainWs_D_G1()
    begin
        PlainWs('D', 'G1', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainWs_A_G2()
    begin
        PlainWs('A', 'G2', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainWs_F_G1()
    begin
        PlainWs('F', 'G1', false);
        Observer.Finish();
    end;

    // The filter keeps the current row.
    [Test]
    procedure RZ_PlainWs_C_G1_Keeps()
    begin
        PlainWs('C', 'G1', false);
        Observer.Finish();
    end;

    // The filter leaves no row at all.
    [Test]
    procedure RZ_PlainWs_B_Empty()
    begin
        PlainWs('B', 'G9', false);
        Observer.Finish();
    end;

    // Update(true) instead of Update(false).
    [Test]
    procedure RZ_PlainWs_B_G1_Save()
    begin
        PlainWs('B', 'G1', true);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainWs_F_G1_Save()
    begin
        PlainWs('F', 'G1', true);
        Observer.Finish();
    end;

    // The filter set and then removed again: which row the page stands on after each step.
    [Test]
    procedure RZ_PlainWs_B_G1_ThenCleared()
    var
        Ws: TestPage "LT RZ Update Ws Plain";
    begin
        Observer.Discard();
        Log.SeedLines();
        Ws.OpenEdit();
        Ws.GoToKey('B');
        Ws.GroupFilter.SetValue('G1');
        Observer.Observe('current after G1', Ws."No.".Value());
        Log.Clear();
        Ws.GroupFilter.SetValue('');
        Observer.Observe('clear log', Log.Take());
        Observer.Observe('current after clear', Ws."No.".Value());
        Observer.Observe('rows', PlainWsRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainWs_B_Empty_ThenCleared()
    var
        Ws: TestPage "LT RZ Update Ws Plain";
    begin
        Observer.Discard();
        Log.SeedLines();
        Ws.OpenEdit();
        Ws.GoToKey('B');
        Ws.GroupFilter.SetValue('G9');
        Observer.Observe('current after G9', Ws."No.".Value());
        Log.Clear();
        Ws.GroupFilter.SetValue('');
        Observer.Observe('clear log', Log.Take());
        Observer.Observe('current after clear', Ws."No.".Value());
        Observer.Observe('rows', PlainWsRows(Ws));
        Ws.Close();
        Observer.Finish();
    end;

    // The Worksheet with OnFindRecord and OnNextRecord.
    [Test]
    procedure RZ_LoggedWs_B_G1()
    begin
        LoggedWs('B', 'G1', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_LoggedWs_F_G1()
    begin
        LoggedWs('F', 'G1', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_LoggedWs_A_G2()
    begin
        LoggedWs('A', 'G2', false);
        Observer.Finish();
    end;

    [Test]
    procedure RZ_LoggedWs_B_G1_Save()
    begin
        LoggedWs('B', 'G1', true);
        Observer.Finish();
    end;

    // The List, filter field in the repeater.
    [Test]
    procedure RZ_PlainList_B_G1()
    begin
        PlainList('B', 'G1');
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainList_F_G1()
    begin
        PlainList('F', 'G1');
        Observer.Finish();
    end;

    [Test]
    procedure RZ_PlainList_A_G2()
    begin
        PlainList('A', 'G2');
        Observer.Finish();
    end;

    local procedure PlainWs(StartNo: Code[20]; GroupCode: Code[20]; SaveRecord: Boolean)
    var
        Ws: TestPage "LT RZ Update Ws Plain";
    begin
        Observer.Discard();
        Log.SeedLines();
        Log.Clear();
        Ws.OpenEdit();
        Observer.Observe('goto', Format(Ws.GoToKey(StartNo)));
        Log.Clear();
        if SaveRecord then
            Ws.GroupFilterSave.SetValue(GroupCode)
        else
            Ws.GroupFilter.SetValue(GroupCode);
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', Ws."No.".Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws."No.".Value());
        Observer.Observe('rows', PlainWsRows(Ws));
        Ws.Close();
    end;

    local procedure LoggedWs(StartNo: Code[20]; GroupCode: Code[20]; SaveRecord: Boolean)
    var
        Ws: TestPage "LT RZ Update Ws";
    begin
        Observer.Discard();
        Log.SeedLines();
        Log.Clear();
        Ws.OpenEdit();
        Observer.Observe('goto', Format(Ws.GoToKey(StartNo)));
        Log.Clear();
        if SaveRecord then
            Ws.GroupFilterSave.SetValue(GroupCode)
        else
            Ws.GroupFilter.SetValue(GroupCode);
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', Ws."No.".Value());
        Observer.Observe('rows', LoggedWsRows(Ws));
        Ws.Close();
    end;

    local procedure PlainList(StartNo: Code[20]; GroupCode: Code[20])
    var
        Lst: TestPage "LT RZ Update List Plain";
        Result: Text;
    begin
        Observer.Discard();
        Log.SeedLines();
        Log.Clear();
        Lst.OpenEdit();
        Observer.Observe('goto', Format(Lst.GoToKey(StartNo)));
        Log.Clear();
        Lst.GroupFilter.SetValue(GroupCode);
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', Lst."No.".Value());
        if Lst.First() then
            repeat
                Result += Lst."No.".Value() + ',';
            until not Lst.Next();
        Observer.Observe('rows', Result);
        Lst.Close();
    end;

    local procedure PlainWsRows(var Ws: TestPage "LT RZ Update Ws Plain") Result: Text
    begin
        if Ws.First() then
            repeat
                Result += Ws."No.".Value() + ',';
            until not Ws.Next();
    end;

    local procedure LoggedWsRows(var Ws: TestPage "LT RZ Update Ws") Result: Text
    begin
        if Ws.First() then
            repeat
                Result += Ws."No.".Value() + ',';
            until not Ws.Next();
    end;
}
