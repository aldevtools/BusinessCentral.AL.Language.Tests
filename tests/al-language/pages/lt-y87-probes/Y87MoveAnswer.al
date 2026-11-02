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

    [Test]
    procedure Y87_SA_List_Next()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryListMove(P, 'next', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryListMove(P, 'next', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryListBranch(P, 'next'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryListMove(P, 'next', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryListMove(P, 'next', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryListBranch(P, 'next'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryListMove(P, 'next', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryListMove(P, 'next', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryListBranch(P, 'next'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_List_Next_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_List_Previous()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryListMove(P, 'previous', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryListMove(P, 'previous', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryListBranch(P, 'previous'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryListMove(P, 'previous', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryListMove(P, 'previous', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryListBranch(P, 'previous'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryListMove(P, 'previous', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryListMove(P, 'previous', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryListBranch(P, 'previous'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_List_Previous_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_List_First()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryListMove(P, 'first', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryListMove(P, 'first', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryListBranch(P, 'first'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryListMove(P, 'first', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryListMove(P, 'first', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryListBranch(P, 'first'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryListMove(P, 'first', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryListMove(P, 'first', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryListBranch(P, 'first'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_List_First_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_List_Last()
    var
        P: TestPage "LT Y80 MD List";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryListMove(P, 'last', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryListMove(P, 'last', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryListBranch(P, 'last'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryListMove(P, 'last', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryListMove(P, 'last', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryListBranch(P, 'last'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryListMove(P, 'last', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryListMove(P, 'last', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryListBranch(P, 'last'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_List_Last_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Card_Next()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryCardMove(P, 'next', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryCardMove(P, 'next', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryCardBranch(P, 'next'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryCardMove(P, 'next', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryCardMove(P, 'next', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryCardBranch(P, 'next'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryCardMove(P, 'next', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryCardMove(P, 'next', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryCardBranch(P, 'next'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Card_Next_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Card_Previous()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryCardMove(P, 'previous', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryCardMove(P, 'previous', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryCardBranch(P, 'previous'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryCardMove(P, 'previous', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryCardMove(P, 'previous', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryCardBranch(P, 'previous'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryCardMove(P, 'previous', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryCardMove(P, 'previous', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryCardBranch(P, 'previous'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Card_Previous_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Card_First()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryCardMove(P, 'first', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryCardMove(P, 'first', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryCardBranch(P, 'first'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryCardMove(P, 'first', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryCardMove(P, 'first', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryCardBranch(P, 'first'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryCardMove(P, 'first', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryCardMove(P, 'first', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryCardBranch(P, 'first'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Card_First_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Card_Last()
    var
        P: TestPage "LT Y80 MD Card";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryCardMove(P, 'last', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryCardMove(P, 'last', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryCardBranch(P, 'last'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryCardMove(P, 'last', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryCardMove(P, 'last', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryCardBranch(P, 'last'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryCardMove(P, 'last', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryCardMove(P, 'last', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryCardBranch(P, 'last'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Card_Last_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Next()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryWorksheetMove(P, 'next', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryWorksheetMove(P, 'next', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryWorksheetBranch(P, 'next'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryWorksheetMove(P, 'next', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryWorksheetMove(P, 'next', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryWorksheetBranch(P, 'next'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryWorksheetMove(P, 'next', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryWorksheetMove(P, 'next', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryWorksheetBranch(P, 'next'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Next_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Previous()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryWorksheetMove(P, 'previous', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryWorksheetMove(P, 'previous', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryWorksheetBranch(P, 'previous'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryWorksheetMove(P, 'previous', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryWorksheetMove(P, 'previous', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryWorksheetBranch(P, 'previous'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryWorksheetMove(P, 'previous', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryWorksheetMove(P, 'previous', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryWorksheetBranch(P, 'previous'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Previous_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Worksheet_First()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryWorksheetMove(P, 'first', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryWorksheetMove(P, 'first', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryWorksheetBranch(P, 'first'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryWorksheetMove(P, 'first', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryWorksheetMove(P, 'first', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryWorksheetBranch(P, 'first'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryWorksheetMove(P, 'first', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryWorksheetMove(P, 'first', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryWorksheetBranch(P, 'first'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Worksheet_First_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Last()
    var
        P: TestPage "LT Y80 MD Worksheet";
    begin
        Seed();
                P.OpenEdit();
        P.GoToKey(10);
        P.TxtCtl.SetValue('x');
        Observer.Observe('10 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('10 preset true', TryWorksheetMove(P, 'last', true), true);
        Observer.Observe('10 answer preset true', Format(Moved, 0, 9));
        Step('10 preset false', TryWorksheetMove(P, 'last', false), false);
        Observer.Observe('10 answer preset false', Format(Moved, 0, 9));
        Step('10 branch', TryWorksheetBranch(P, 'last'), false);
        Observer.Observe('10 branch taken', Branch);
        Observer.Observe('10 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('10 stored', Stored(10));
        P.OpenEdit();
        P.GoToKey(20);
        P.TxtCtl.SetValue('x');
        Observer.Observe('20 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('20 preset true', TryWorksheetMove(P, 'last', true), true);
        Observer.Observe('20 answer preset true', Format(Moved, 0, 9));
        Step('20 preset false', TryWorksheetMove(P, 'last', false), false);
        Observer.Observe('20 answer preset false', Format(Moved, 0, 9));
        Step('20 branch', TryWorksheetBranch(P, 'last'), false);
        Observer.Observe('20 branch taken', Branch);
        Observer.Observe('20 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('20 stored', Stored(20));
        P.OpenEdit();
        P.GoToKey(30);
        P.TxtCtl.SetValue('x');
        Observer.Observe('30 shown', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        Step('30 preset true', TryWorksheetMove(P, 'last', true), true);
        Observer.Observe('30 answer preset true', Format(Moved, 0, 9));
        Step('30 preset false', TryWorksheetMove(P, 'last', false), false);
        Observer.Observe('30 answer preset false', Format(Moved, 0, 9));
        Step('30 branch', TryWorksheetBranch(P, 'last'), false);
        Observer.Observe('30 branch taken', Branch);
        Observer.Observe('30 shown after', P.IdCtl.Value() + '/' + P.TxtCtl.Value());
        P.Close();
        Observer.Observe('30 stored', Stored(30));

        Observer.Finish();
    end;

    [Test]
    procedure Y87_SA_Worksheet_Last_More1()
    begin
        Observer.More();
    end;
}
