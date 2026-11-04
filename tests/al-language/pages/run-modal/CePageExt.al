// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in CeObjects.al (84340 to 84364); Base Application page 302 "Customer Entry Statistics";
//   LT QK Setup Rows (86940)
// Corpus issue 667 (part B), writer CE: ClearAll in a base page and the globals of a page extension (microsoft/AL issue 6499) and
// Visible of an extension action from a variable set in the extension's OnOpenPage (issue 4684).
// Probe: written against a local BC 29.0 service tier; every literal below is what that tier produced; 27.5 and 28.5 by the CI matrix.
// Facts (BC 29.0): ClearAll() in the base page's OnAfterGetRecord clears the globals of a page extension, for a base page of the same
// app and for page 302 of the Base Application (the extension's flag set in its OnOpenPage reads false in every OnAfterGetRecord).
// An extension action with Visible = <variable set true in the extension's OnOpenPage> is visible on the TestPage; one whose
// variable is never set is not.

codeunit 84363 "LT CE Page Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedOne()
    var
        Row: Record "LT CE Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    procedure ClearAll_InOwnBasePage_ExtensionGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Ext Log";
        Card: TestPage "LT CE ClearAll Card";
    begin
        SeedOne();
        Log.Take();
        Card.OpenView();
        Observer.Observe('open', Log.Take());
        Card.Close();
        Observer.Expect('open', 'base AGR before ClearAll flag=Yes;base AGR after ClearAll flag=No;ext AGR flag=No;');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_InBaseAppPage_ExtensionGlobal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CE Ext Log";
        Cust: Record Customer;
        Stat: TestPage "Customer Entry Statistics";
        Trace: Text;
        Ok: Boolean;
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        if not Cust.Get('LTCE-C1') then begin
            Cust.Init();
            Cust."No." := 'LTCE-C1';
            Cust.Name := 'LT CE customer';
            Cust.Insert();
        end;
        Commit();
        // Writer QK (owner 2026-10-21): page 302's OnAfterGetRecord reads Accounting Period around WorkDate (DateFilter-Calc); the test
        // writes its own periods (2090 to 2092) and sets WorkDate 2091-03-15 (QkSetupRows.al) instead of reading the demo periods.
        QkRows.WriteAccountingPeriods();
        Log.Take();
        Ok := OpenStat(Stat, Cust);
        Observer.Observe('open|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open');
        // How often the TestPage reads the record (7 times on BC 29.0) is not asserted: only the order and the flag.
        Trace := Log.Take();
        QkRows.RestoreAccountingPeriods();
        Observer.Observe('open_start', CopyStr(Trace, 1, StrLen('ext OnOpenPage;ext AGR flag=No;')));
        Observer.Observe('flag_yes_in_any_ext_AGR', Format(StrPos(Trace, 'flag=Yes') > 0));
        Observer.Expect('open|ok', 'Yes');
        Observer.Expect('open_start', 'ext OnOpenPage;ext AGR flag=No;');
        Observer.Expect('flag_yes_in_any_ext_AGR', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure OpenStat(var Stat: TestPage "Customer Entry Statistics"; Cust: Record Customer)
    begin
        Stat.OpenView();
        Stat.GoToRecord(Cust);
    end;

    [Test]
    procedure ExtensionAction_VisibleFromVariableSetInOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CE Vis Card";
    begin
        SeedOne();
        Card.OpenView();
        Observer.Observe('base_act', Format(Card.BaseAct.Visible()));
        Observer.Observe('ext_act', Format(Card.ExtAct.Visible()));
        Observer.Observe('ext_act_never_set', Format(Card.ExtActNeverSet.Visible()));
        Card.Close();
        Observer.Expect('base_act', 'Yes');
        Observer.Expect('ext_act', 'Yes');
        Observer.Expect('ext_act_never_set', 'No');
        Observer.Verify();
    end;
}
