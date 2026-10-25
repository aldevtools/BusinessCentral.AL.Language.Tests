// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT RZ Line / Log Mgt / Update pages (RzFixtures.al, writer RZ)
// Probe: a field's OnValidate sets a filter on Rec that leaves the row the page stands on, then calls CurrPage.Update(false) or Update(true).
//   Which row the page stands on afterwards, which rows it lists, and the triggers on the way. Pages: a Worksheet with the filter field in a
//   header group, without OnFindRecord/OnNextRecord (the shape of al-runner issue 5824) and with them; a List whose filter field is a
//   repeater field. Data: A G1, B G2, C G1, D G2, E G1, F G2. The same move after an ACTION is pinned in pages/lt-ai-list-order/AiListOrderTests.al.
// Result (BC 29.0, Windows container): when the filter leaves the current row, the page stands on the next row of the filtered set after
//   the old key, or on the previous one when none follows (B/G1 -> C, D/G1 -> E, A/G2 -> B, F/G1 -> E), the same with Update(true), on the
//   Worksheet with and without OnFindRecord/OnNextRecord and on the List. With OnFindRecord the page asks Find('=>') first and Find('=><')
//   when that finds nothing. A filter with no rows leaves a blank row; removing the filter again opens on the first row.
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
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;R:C;R:E;R:C;R:A;R:C;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('next', 'Yes|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainWs_D_G1()
    begin
        PlainWs('D', 'G1', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter D;A:done D;R:E;R:C;R:A;R:E;R:E;C:E');
        Observer.Expect('current', 'E');
        Observer.Expect('next', 'No|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainWs_A_G2()
    begin
        PlainWs('A', 'G2', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter A;A:done A;R:B;R:D;R:F;R:B;R:B;C:B');
        Observer.Expect('current', 'B');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('rows', 'B,D,F,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainWs_F_G1()
    begin
        PlainWs('F', 'G1', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter F;A:done F;R:E;R:C;R:A;R:E;R:E;C:E');
        Observer.Expect('current', 'E');
        Observer.Expect('next', 'No|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    // The filter keeps the current row.
    [Test]
    procedure RZ_PlainWs_C_G1_Keeps()
    begin
        PlainWs('C', 'G1', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter C;A:done C;R:C;R:E;R:C;R:A;R:C;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('next', 'Yes|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    // The filter leaves no row at all.
    [Test]
    procedure RZ_PlainWs_B_Empty()
    begin
        PlainWs('B', 'G9', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;C:');
        Observer.Expect('current', '');
        Observer.Expect('next', 'No|');
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    // Update(true) instead of Update(false).
    [Test]
    procedure RZ_PlainWs_B_G1_Save()
    begin
        PlainWs('B', 'G1', true);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;R:C;R:E;R:C;R:A;R:C;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('next', 'Yes|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainWs_F_G1_Save()
    begin
        PlainWs('F', 'G1', true);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter F;A:done F;R:E;R:C;R:A;R:E;R:E;C:E');
        Observer.Expect('current', 'E');
        Observer.Expect('next', 'No|E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
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
        Observer.Expect('current after G1', 'C');
        Observer.Expect('clear log', 'A:filter C;A:done C;R:C;R:D;R:E;R:F;R:C;R:B;R:A;R:C;R:C;C:C');
        Observer.Expect('current after clear', 'C');
        Observer.Expect('rows', 'A,B,C,D,E,F,');
        Observer.Verify();
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
        Observer.Expect('current after G9', '');
        Observer.Expect('clear log', 'A:filter ;A:done ;R:A;R:B;R:C;R:D;R:E;R:F;R:A;R:A;C:A');
        Observer.Expect('current after clear', 'A');
        Observer.Expect('rows', 'A,B,C,D,E,F,');
        Observer.Verify();
    end;

    // The Worksheet with OnFindRecord and OnNextRecord.
    [Test]
    procedure RZ_LoggedWs_B_G1()
    begin
        LoggedWs('B', 'G1', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;F:=>=Yes;R:C;N:1=1;R:E;N:1=0;R:C;N:-1=-1;R:A;N:-1=0;R:C;F:==Yes;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_LoggedWs_F_G1()
    begin
        LoggedWs('F', 'G1', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter F;A:done F;F:=>=No;F:=><=Yes;R:E;N:1=0;N:-1=-1;R:C;N:-1=-1;R:A;N:-1=0;R:E;F:==Yes;R:E;C:E');
        Observer.Expect('current', 'E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_LoggedWs_A_G2()
    begin
        LoggedWs('A', 'G2', false);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter A;A:done A;F:=>=Yes;R:B;N:1=1;R:D;N:1=1;R:F;N:1=0;R:B;N:-1=0;F:==Yes;R:B;C:B');
        Observer.Expect('current', 'B');
        Observer.Expect('rows', 'B,D,F,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_LoggedWs_B_G1_Save()
    begin
        LoggedWs('B', 'G1', true);
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;F:=>=Yes;R:C;N:1=1;R:E;N:1=0;R:C;N:-1=-1;R:A;N:-1=0;R:C;F:==Yes;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    // The List, filter field in the repeater.
    [Test]
    procedure RZ_PlainList_B_G1()
    begin
        PlainList('B', 'G1');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter B;A:done B;R:C;R:E;R:C;R:A;R:C;R:C;C:C');
        Observer.Expect('current', 'C');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainList_F_G1()
    begin
        PlainList('F', 'G1');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter F;A:done F;R:E;R:C;R:A;R:E;R:E;C:E');
        Observer.Expect('current', 'E');
        Observer.Expect('rows', 'A,C,E,');
        Observer.Verify();
    end;

    [Test]
    procedure RZ_PlainList_A_G2()
    begin
        PlainList('A', 'G2');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('validate log', 'A:filter A;A:done A;R:B;R:D;R:F;R:B;R:B;C:B');
        Observer.Expect('current', 'B');
        Observer.Expect('rows', 'B,D,F,');
        Observer.Verify();
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
