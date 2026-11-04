// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); pages "LT Y80 MD List", "LT Y80 MD Card", "LT Y80 MD Worksheet" (ModifyAllowed = false) and tables "LT Y80 Row", "LT Y80 Log" (pages/lt-y80-modify-denied, pages/lt-y80-gone-rows); own objects 94646
// Probe (writer Y87, from the runtime lane rt-pages-1102e): the ANSWER of a TestPage move that did not happen. pages/lt-y80-modify-denied/Y80ModifyDenied.al and
//   pages/lt-y61-page-probes/Y61ModifyDeniedSave.al pin that after a SetValue on a page whose ModifyAllowed is false, Next/Previous/First/Last end with
//   'Page cannot be saved.' (code SaveAbort) inside a TryFunction (which itself returns true) and the page stays on the row. Here the code USES the answer:
//   Moved := P.Next() with Moved preset to true and to false (does the assignment happen, and with what value), and if P.Next() then ... else ... .
//   Each move (Next, Previous, First, Last) on a List, a Card and a Worksheet, from the first, the middle and the last row.
// BC versions: 27, 28, 29

codeunit 94646 "LT Y87 Move Answer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Moved: Boolean;
        Branch: Text;

    local procedure Seed()
    var
        Row: Record "LT Y80 Row";
        Log: Record "LT Y80 Log";
        I: Integer;
    begin
        ClearLastError();
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I * 10;
            Row.Txt := 'r' + Format(I * 10);
            Row.Num := I;
            Row.Insert();
        end;
        Log.DeleteAll();
    end;

    local procedure Stored(Id: Integer): Text
    var
        Row: Record "LT Y80 Row";
    begin
        Row.Get(Id);
        exit(Row.Txt + '/' + Format(Row.Num));
    end;

    local procedure Step(Name: Text; Ok: Boolean; WithError: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        if WithError then
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryListMove(var P: TestPage "LT Y80 MD List"; Which: Text; Preset: Boolean)
    begin
        Moved := Preset;
        case Which of
            'next':
                Moved := P.Next();
            'previous':
                Moved := P.Previous();
            'first':
                Moved := P.First();
            'last':
                Moved := P.Last();
        end;
    end;

    [TryFunction]
    local procedure TryListBranch(var P: TestPage "LT Y80 MD List"; Which: Text)
    begin
        Branch := 'none';
        case Which of
            'next':
                if P.Next() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'previous':
                if P.Previous() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'first':
                if P.First() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'last':
                if P.Last() then
                    Branch := 'then'
                else
                    Branch := 'else';
        end;
    end;

    [TryFunction]
    local procedure TryListClose(var P: TestPage "LT Y80 MD List")
    begin
        P.Close();
    end;

    local procedure CaseList(Start: Integer; Which: Text)
    var
        P: TestPage "LT Y80 MD List";
    begin
        P.OpenEdit();
        P.GoToKey(Start);
        P.TxtCtl.SetValue('x');
        Observer.Observe(Format(Start) + ' shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' preset true', TryListMove(P, Which, true), true);
        Observer.Observe(Format(Start) + ' answer preset true', Format(Moved, 0, 9));
        Step(Format(Start) + ' preset false', TryListMove(P, Which, false), false);
        Observer.Observe(Format(Start) + ' answer preset false', Format(Moved, 0, 9));
        Step(Format(Start) + ' branch', TryListBranch(P, Which), false);
        Observer.Observe(Format(Start) + ' branch taken', Branch);
        Observer.Observe(Format(Start) + ' shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' close', TryListClose(P), false);
        Observer.Observe(Format(Start) + ' stored', Stored(Start));
    end;

    [TryFunction]
    local procedure TryCardMove(var P: TestPage "LT Y80 MD Card"; Which: Text; Preset: Boolean)
    begin
        Moved := Preset;
        case Which of
            'next':
                Moved := P.Next();
            'previous':
                Moved := P.Previous();
            'first':
                Moved := P.First();
            'last':
                Moved := P.Last();
        end;
    end;

    [TryFunction]
    local procedure TryCardBranch(var P: TestPage "LT Y80 MD Card"; Which: Text)
    begin
        Branch := 'none';
        case Which of
            'next':
                if P.Next() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'previous':
                if P.Previous() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'first':
                if P.First() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'last':
                if P.Last() then
                    Branch := 'then'
                else
                    Branch := 'else';
        end;
    end;

    [TryFunction]
    local procedure TryCardClose(var P: TestPage "LT Y80 MD Card")
    begin
        P.Close();
    end;

    local procedure CaseCard(Start: Integer; Which: Text)
    var
        P: TestPage "LT Y80 MD Card";
    begin
        P.OpenEdit();
        P.GoToKey(Start);
        P.TxtCtl.SetValue('x');
        Observer.Observe(Format(Start) + ' shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' preset true', TryCardMove(P, Which, true), true);
        Observer.Observe(Format(Start) + ' answer preset true', Format(Moved, 0, 9));
        Step(Format(Start) + ' preset false', TryCardMove(P, Which, false), false);
        Observer.Observe(Format(Start) + ' answer preset false', Format(Moved, 0, 9));
        Step(Format(Start) + ' branch', TryCardBranch(P, Which), false);
        Observer.Observe(Format(Start) + ' branch taken', Branch);
        Observer.Observe(Format(Start) + ' shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' close', TryCardClose(P), false);
        Observer.Observe(Format(Start) + ' stored', Stored(Start));
    end;

    [TryFunction]
    local procedure TryWorksheetMove(var P: TestPage "LT Y80 MD Worksheet"; Which: Text; Preset: Boolean)
    begin
        Moved := Preset;
        case Which of
            'next':
                Moved := P.Next();
            'previous':
                Moved := P.Previous();
            'first':
                Moved := P.First();
            'last':
                Moved := P.Last();
        end;
    end;

    [TryFunction]
    local procedure TryWorksheetBranch(var P: TestPage "LT Y80 MD Worksheet"; Which: Text)
    begin
        Branch := 'none';
        case Which of
            'next':
                if P.Next() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'previous':
                if P.Previous() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'first':
                if P.First() then
                    Branch := 'then'
                else
                    Branch := 'else';
            'last':
                if P.Last() then
                    Branch := 'then'
                else
                    Branch := 'else';
        end;
    end;

    [TryFunction]
    local procedure TryWorksheetClose(var P: TestPage "LT Y80 MD Worksheet")
    begin
        P.Close();
    end;

    local procedure CaseWorksheet(Start: Integer; Which: Text)
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        P.OpenEdit();
        P.GoToKey(Start);
        P.TxtCtl.SetValue('x');
        Observer.Observe(Format(Start) + ' shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' preset true', TryWorksheetMove(P, Which, true), true);
        Observer.Observe(Format(Start) + ' answer preset true', Format(Moved, 0, 9));
        Step(Format(Start) + ' preset false', TryWorksheetMove(P, Which, false), false);
        Observer.Observe(Format(Start) + ' answer preset false', Format(Moved, 0, 9));
        Step(Format(Start) + ' branch', TryWorksheetBranch(P, Which), false);
        Observer.Observe(Format(Start) + ' branch taken', Branch);
        Observer.Observe(Format(Start) + ' shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step(Format(Start) + ' close', TryWorksheetClose(P), false);
        Observer.Observe(Format(Start) + ' stored', Stored(Start));
    end;

    [Test]
    procedure Y87_SA_List_Next()
    begin
        Seed();
        CaseList(10, 'next');
        CaseList(20, 'next');
        CaseList(30, 'next');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_List_Previous()
    begin
        Seed();
        CaseList(10, 'previous');
        CaseList(20, 'previous');
        CaseList(30, 'previous');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', '');
        Observer.Expect('10 preset true|code', '');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'No');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_List_First()
    begin
        Seed();
        CaseList(10, 'first');
        CaseList(20, 'first');
        CaseList(30, 'first');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', '');
        Observer.Expect('10 preset true|code', '');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'No');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_List_Last()
    begin
        Seed();
        CaseList(10, 'last');
        CaseList(20, 'last');
        CaseList(30, 'last');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'true');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'true');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'then');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'true');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'true');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'then');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Card_Next()
    begin
        Seed();
        CaseCard(10, 'next');
        CaseCard(20, 'next');
        CaseCard(30, 'next');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Card_Previous()
    begin
        Seed();
        CaseCard(10, 'previous');
        CaseCard(20, 'previous');
        CaseCard(30, 'previous');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Card_First()
    begin
        Seed();
        CaseCard(10, 'first');
        CaseCard(20, 'first');
        CaseCard(30, 'first');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'true');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'true');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'then');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'true');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'true');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'then');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Card_Last()
    begin
        Seed();
        CaseCard(10, 'last');
        CaseCard(20, 'last');
        CaseCard(30, 'last');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'true');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'true');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'then');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'true');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'true');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'then');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Worksheet_Next()
    begin
        Seed();
        CaseWorksheet(10, 'next');
        CaseWorksheet(20, 'next');
        CaseWorksheet(30, 'next');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Worksheet_Previous()
    begin
        Seed();
        CaseWorksheet(10, 'previous');
        CaseWorksheet(20, 'previous');
        CaseWorksheet(30, 'previous');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', '');
        Observer.Expect('10 preset true|code', '');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'false');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'false');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'else');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'No');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Worksheet_First()
    begin
        Seed();
        CaseWorksheet(10, 'first');
        CaseWorksheet(20, 'first');
        CaseWorksheet(30, 'first');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', '');
        Observer.Expect('10 preset true|code', '');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'No');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'false');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'false');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'else');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'false');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'false');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'else');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;


    [Test]
    procedure Y87_SA_Worksheet_Last()
    begin
        Seed();
        CaseWorksheet(10, 'last');
        CaseWorksheet(20, 'last');
        CaseWorksheet(30, 'last');

        Observer.Expect('10 shown', '10/x');
        Observer.Expect('10 preset true ok', 'Yes');
        Observer.Expect('10 preset true|text', 'Page cannot be saved.');
        Observer.Expect('10 preset true|code', 'SaveAbort');
        Observer.Expect('10 preset true log', '');
        Observer.Expect('10 answer preset true', 'true');
        Observer.Expect('10 preset false ok', 'Yes');
        Observer.Expect('10 preset false log', '');
        Observer.Expect('10 answer preset false', 'true');
        Observer.Expect('10 branch ok', 'Yes');
        Observer.Expect('10 branch log', '');
        Observer.Expect('10 branch taken', 'then');
        Observer.Expect('10 shown after', '10/x');
        Observer.Expect('10 close ok', 'Yes');
        Observer.Expect('10 close log', '');
        Observer.Expect('10 stored', 'r10/1');
        Observer.Expect('20 shown', '20/x');
        Observer.Expect('20 preset true ok', 'Yes');
        Observer.Expect('20 preset true|text', 'Page cannot be saved.');
        Observer.Expect('20 preset true|code', 'SaveAbort');
        Observer.Expect('20 preset true log', '');
        Observer.Expect('20 answer preset true', 'true');
        Observer.Expect('20 preset false ok', 'Yes');
        Observer.Expect('20 preset false log', '');
        Observer.Expect('20 answer preset false', 'true');
        Observer.Expect('20 branch ok', 'Yes');
        Observer.Expect('20 branch log', '');
        Observer.Expect('20 branch taken', 'then');
        Observer.Expect('20 shown after', '20/x');
        Observer.Expect('20 close ok', 'Yes');
        Observer.Expect('20 close log', '');
        Observer.Expect('20 stored', 'r20/2');
        Observer.Expect('30 shown', '30/x');
        Observer.Expect('30 preset true ok', 'Yes');
        Observer.Expect('30 preset true|text', 'Page cannot be saved.');
        Observer.Expect('30 preset true|code', 'SaveAbort');
        Observer.Expect('30 preset true log', '');
        Observer.Expect('30 answer preset true', 'true');
        Observer.Expect('30 preset false ok', 'Yes');
        Observer.Expect('30 preset false log', '');
        Observer.Expect('30 answer preset false', 'true');
        Observer.Expect('30 branch ok', 'Yes');
        Observer.Expect('30 branch log', '');
        Observer.Expect('30 branch taken', 'then');
        Observer.Expect('30 shown after', '30/x');
        Observer.Expect('30 close ok', 'Yes');
        Observer.Expect('30 close log', '');
        Observer.Expect('30 stored', 'r30/3');
        Observer.Verify();
    end;

}
