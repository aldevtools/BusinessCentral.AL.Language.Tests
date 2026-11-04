// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in UeProtectedVarObjects.al and UeTriggerObjects.al (table 90330); test codeunit 90349
// Probe: written against the Windows BC 29 container.
// BC versions: 29 (27 and 28 by CI)
// Observed: it compiles; the variable is shared; the declaring extension's OnOpenPage runs first (it saw No), the other one second (it saw Yes and left No).
// Facts (AL Runner issue 6159): a page extension uses a protected var that another page extension of the same page declares (in the same app here; the cross-app form also compiled and shared the variable on BC 29 but is not
//   in the corpus, since a change to a dependency app forces a full CI run): does it compile, is the variable shared, and in which order do the two OnOpenPage triggers run.
codeunit 90349 "LT UE Protected Var Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ProtectedVar_OfAnotherExtension_IsSharedAndAssignable()
    var
        Row: Record "LT UE Row";
        List: TestPage "LT UE PV Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amount := 5;
        Row.Insert();
        List.OpenView();
        Observer.Observe('trace', List.TraceField.Value());
        Observer.Observe('mid visible', Format(List.MidAmount.Visible()));
        Observer.Observe('top visible', Format(List.TopAmount.Visible()));
        List.Close();
        Observer.Expect('trace', 'mid(No)top(Yes)');
        Observer.Expect('mid visible', 'No');
        Observer.Expect('top visible', 'No');
        Observer.Verify();
    end;
}
