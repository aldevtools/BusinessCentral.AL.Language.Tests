// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); from pages/actions/ActionReportInsertsRowsOnEmptyList.al: table "PAG AddRows Line",
//   report "PAG AddRows Report" (its request page sets how many rows it inserts), pages "PAG AddRows Delayed" and "PAG AddRows Plain";
//   own codeunit 96660.
// Probe: al-runner issue 7478, the cell that file leaves out: the report inserts ONE row behind a List that stands on its new-row line over
//   an empty view (the file above inserts two or three). Observation form: every test ends in Observer.Finish(), so its failure message
//   holds BC's values.
// Area: after the action, the test calls OK, Close, Next, Previous, Last or GoToKey on the TestPage. Observed: the rows of the table, the row
//   the page shows before and after, the answer of the call and its error, and the rows after the page closed.
// Each case deletes the rows of earlier tests first and commits before the report's request page opens (see the file above).
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

codeunit 96660 "PAG OneRow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Stored(): Text
    var
        Line: Record "PAG AddRows Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += '[' + Line."Parent No." + ' ' + Format(Line."Line No.") + ' ' + Line.Description + ']';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure ShownDelayed(var Pg: TestPage "PAG AddRows Delayed"): Text
    begin
        exit('[' + Pg."Parent No.".Value + ' ' + Pg."Line No.".Value + ' ' + Pg.Description.Value + ']');
    end;

    local procedure ShownPlain(var Pg: TestPage "PAG AddRows Plain"): Text
    begin
        exit('[' + Pg."Parent No.".Value + ' ' + Pg."Line No.".Value + ' ' + Pg.Description.Value + ']');
    end;

    [TryFunction]
    local procedure TryCallDelayed(var Pg: TestPage "PAG AddRows Delayed"; Call: Text; var Answer: Text)
    begin
        case Call of
            'ok':
                Pg.OK().Invoke();
            'close':
                Pg.Close();
            'next':
                Answer := Format(Pg.Next());
            'previous':
                Answer := Format(Pg.Previous());
            'last':
                Answer := Format(Pg.Last());
            'gotokey':
                Answer := Format(Pg.GoToKey('P1', 10000));
        end;
    end;

    [TryFunction]
    local procedure TryOkPlain(var Pg: TestPage "PAG AddRows Plain")
    begin
        Pg.OK().Invoke();
    end;

    local procedure RunDelayed(Call: Text)
    var
        Line: Record "PAG AddRows Line";
        Pg: TestPage "PAG AddRows Delayed";
        Answer: Text;
        Ok: Boolean;
    begin
        Observer.Discard(); // a test that BC ended with an error left its observations in the codeunit's observer
        Line.DeleteAll();
        Commit(); // no write may be pending when the report's request page opens
        Pg.OpenEdit();
        Pg.Filter.SetFilter("Parent No.", 'P1');
        Observer.Observe('row before', ShownDelayed(Pg));
        Pg.AddByReport.Invoke();
        Observer.Observe('stored after action', Stored());
        Observer.Observe('row after action', ShownDelayed(Pg));
        Ok := TryCallDelayed(Pg, Call, Answer);
        Observer.Observe(Call, Format(Ok) + ' ' + Answer);
        Observer.ObserveError(Call);
        if Ok and not (Call in ['ok', 'close']) then begin
            Observer.Observe('row after ' + Call, ShownDelayed(Pg));
            Observer.Observe('ok after ' + Call, Format(TryCallDelayed(Pg, 'ok', Answer)));
            Observer.ObserveError('ok after ' + Call);
        end;
        Observer.Observe('stored after closing', Stored());
        Line.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_Ok()
    begin
        RunDelayed('ok');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('ok', 'Yes ');
        Observer.Expect('ok|text', '');
        Observer.Expect('ok|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_Close()
    begin
        RunDelayed('close');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('close', 'Yes ');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_Next()
    begin
        RunDelayed('next');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('next', 'Yes No');
        Observer.Expect('next|text', '');
        Observer.Expect('next|code', '');
        Observer.Expect('row after next', '[P1 0 ]');
        Observer.Expect('ok after next', 'Yes');
        Observer.Expect('ok after next|text', '');
        Observer.Expect('ok after next|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_Previous()
    begin
        RunDelayed('previous');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('previous', 'Yes Yes');
        Observer.Expect('previous|text', '');
        Observer.Expect('previous|code', '');
        Observer.Expect('row after previous', '[P1 10000 by report 1]');
        Observer.Expect('ok after previous', 'Yes');
        Observer.Expect('ok after previous|text', '');
        Observer.Expect('ok after previous|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_Last()
    begin
        RunDelayed('last');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('last', 'Yes Yes');
        Observer.Expect('last|text', '');
        Observer.Expect('last|code', '');
        Observer.Expect('row after last', '[P1 10000 by report 1]');
        Observer.Expect('ok after last', 'Yes');
        Observer.Expect('ok after last|text', '');
        Observer.Expect('ok after last|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_DelayedInsertList_ReportWithRequestPage_GoToKey()
    begin
        RunDelayed('gotokey');
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('gotokey', 'Yes Yes');
        Observer.Expect('gotokey|text', '');
        Observer.Expect('gotokey|code', '');
        Observer.Expect('row after gotokey', '[P1 10000 by report 1]');
        Observer.Expect('ok after gotokey', 'Yes');
        Observer.Expect('ok after gotokey|text', '');
        Observer.Expect('ok after gotokey|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OneRowHandler')]
    procedure OneRow_PlainList_ReportWithRequestPage_Ok()
    var
        Line: Record "PAG AddRows Line";
        Pg: TestPage "PAG AddRows Plain";
    begin
        Observer.Discard();
        Line.DeleteAll();
        Commit();
        Pg.OpenEdit();
        Pg.Filter.SetFilter("Parent No.", 'P1');
        Observer.Observe('row before', ShownPlain(Pg));
        Pg.AddByReport.Invoke();
        Observer.Observe('stored after action', Stored());
        Observer.Observe('row after action', ShownPlain(Pg));
        Observer.Observe('ok', Format(TryOkPlain(Pg)));
        Observer.ObserveError('ok');
        Observer.Observe('stored after closing', Stored());
        Line.DeleteAll();
        Observer.Expect('row before', '[P1 0 ]');
        Observer.Expect('stored after action', '[P1 10000 by report 1]');
        Observer.Expect('row after action', '[P1 0 ]');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('ok|text', '');
        Observer.Expect('ok|code', '');
        Observer.Expect('stored after closing', '[P1 10000 by report 1]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OneRowHandler(var RP: TestRequestPage "PAG AddRows Report")
    begin
        RP.HowManyCtl.SetValue(1);
        RP.OK().Invoke();
    end;
}
