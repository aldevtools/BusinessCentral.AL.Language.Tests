// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG List (70135), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 58 (TestPage): GoToKey / GoToRecord scan forward from the first row and populate every row they pass (which triggers run, in which order)
// Facts: the OnAfterGetRecord / OnAfterGetCurrRecord log of GoToKey and GoToRecord on hits, misses, from the first row and from a later row
// BC versions: 29 (27 and 28 by CI)

codeunit 70175 "LT PnG GoTo Scan"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Item: Record "LT PnG Item";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to Rows do begin
            Item.Init();
            Item."No." := 'R' + Format(i);
            Item.Name := 'Row ' + Format(i);
            Item.Qty := i;
            Item.Insert();
        end;
    end;

    [Test]
    procedure GoToKeyFromTheFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(8);
        List.OpenView();
        Log.Reset();
        Observer.Observe('hit', Format(List.GoToKey('R4')));
        Observer.Observe('current', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        List.Close();
        Observer.Expect('hit', 'Yes');
        Observer.Expect('current', 'R4');
        Observer.Expect('log', 'List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R2);List.AGR(R4,Row 4);List.AGR(R4,Row 4);List.AGCR(R4,R3)');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyFromALaterRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(8);
        List.OpenView();
        List.GoToKey('R6');
        Log.Reset();
        Observer.Observe('hit-backwards', Format(List.GoToKey('R2')));
        Observer.Observe('current', List.NoCtl.Value());
        Observer.Observe('log-backwards', Log.Dump());
        Log.Reset();
        Observer.Observe('hit-same', Format(List.GoToKey('R2')));
        Observer.Observe('log-same', Log.Dump());
        Log.Reset();
        Observer.Observe('hit-forwards', Format(List.GoToKey('R3')));
        Observer.Observe('log-forwards', Log.Dump());
        List.Close();
        Observer.Expect('hit-backwards', 'Yes');
        Observer.Expect('current', 'R2');
        Observer.Expect('log-backwards', 'List.AGR(R1,Row 1);List.AGR(R1,Row 1);List.AGCR(R1,R6);List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1)');
        Observer.Expect('hit-same', 'Yes');
        Observer.Expect('log-same', 'List.AGR(R1,Row 1);List.AGR(R1,Row 1);List.AGCR(R1,R2);List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1)');
        Observer.Expect('hit-forwards', 'Yes');
        Observer.Expect('log-forwards', 'List.AGR(R1,Row 1);List.AGR(R1,Row 1);List.AGCR(R1,R2);List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R2)');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyMiss()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(5);
        List.OpenView();
        List.GoToKey('R3');
        Log.Reset();
        Observer.Observe('miss', Format(List.GoToKey('NOPE')));
        Observer.Observe('current-after-miss', List.NoCtl.Value());
        Observer.Observe('log-miss', Log.Dump());
        Log.Reset();
        asserterror begin List.GoToKey('NOPE'); Error('LT-NOERROR'); end;
        Observer.ObserveError('miss-discarded');
        Observer.Observe('current-after-discarded', List.NoCtl.Value());
        List.Close();
        Observer.Expect('miss', 'No');
        Observer.Expect('current-after-miss', 'R3');
        Observer.Expect('log-miss', 'List.AGR(R1,Row 1);List.AGR(R1,Row 1);List.AGCR(R1,R3);List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R2);List.AGR(R4,Row 4);List.AGR(R4,Row 4);List.AGCR(R4,R3);List.AGR(R5,Row 5);List.AGR(R5,Row 5);List.AGCR(R5,R4);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R5)');
        Observer.Expect('miss-discarded|text', 'The row does not exist on the TestPage.');
        Observer.Expect('miss-discarded|code', 'TestRowNotFound');
        Observer.Expect('current-after-discarded', 'R3');
        Observer.Verify();
    end;

    [Test]
    procedure GoToRecordFromTheFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
        Item: Record "LT PnG Item";
    begin
        Seed(8);
        List.OpenView();
        Item.Get('R5');
        Log.Reset();
        Observer.Observe('hit', Format(List.GoToRecord(Item)));
        Observer.Observe('current', List.NoCtl.Value());
        Observer.Observe('log', Log.Dump());
        Item."No." := 'ZZZ';
        Log.Reset();
        Observer.Observe('miss', Format(List.GoToRecord(Item)));
        Observer.Observe('current-after-miss', List.NoCtl.Value());
        Observer.Observe('log-miss', Log.Dump());
        List.Close();
        Observer.Expect('hit', 'Yes');
        Observer.Expect('current', 'R5');
        Observer.Expect('log', 'List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R2);List.AGR(R4,Row 4);List.AGR(R4,Row 4);List.AGCR(R4,R3);List.AGR(R5,Row 5);List.AGR(R5,Row 5);List.AGCR(R5,R4)');
        Observer.Expect('miss', 'No');
        Observer.Expect('current-after-miss', 'R5');
        Observer.Expect('log-miss', 'List.AGR(R1,Row 1);List.AGR(R1,Row 1);List.AGCR(R1,R5);List.AGR(R2,Row 2);List.AGR(R2,Row 2);List.AGCR(R2,R1);List.AGR(R3,Row 3);List.AGR(R3,Row 3);List.AGCR(R3,R2);List.AGR(R4,Row 4);List.AGR(R4,Row 4);List.AGCR(R4,R3);List.AGR(R5,Row 5);List.AGR(R5,Row 5);List.AGCR(R5,R4);List.AGR(R6,Row 6);List.AGR(R6,Row 6);List.AGCR(R6,R5);List.AGR(R7,Row 7);List.AGR(R7,Row 7);List.AGCR(R7,R6);List.AGR(R8,Row 8);List.AGR(R8,Row 8);List.AGCR(R8,R7);List.AGR(R5,Row 5);List.AGR(R5,Row 5);List.AGCR(R5,R8)');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyOverTheWindowBoundary()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        List: TestPage "LT PnG List";
    begin
        Seed(60);
        Log.Reset();
        List.OpenView();
        Observer.Observe('log-open-count', Format(Log.Count()));
        Log.Reset();
        Observer.Observe('hit-far', Format(List.GoToKey('R55')));
        Observer.Observe('current', List.NoCtl.Value());
        Observer.Observe('log-count-far', Format(Log.Count()));
        Log.Reset();
        Observer.Observe('hit-back-near', Format(List.GoToKey('R2')));
        Observer.Observe('log-count-back', Format(Log.Count()));
        List.Close();
        Observer.Expect('log-open-count', '25');
        Observer.Expect('hit-far', 'Yes');
        Observer.Expect('current', 'R55');
        Observer.Expect('log-count-far', '192');
        Observer.Expect('hit-back-near', 'Yes');
        Observer.Expect('log-count-back', '36');
        Observer.Verify();
    end;
}
