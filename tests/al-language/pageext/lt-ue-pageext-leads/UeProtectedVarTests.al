// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in UeProtectedVarObjects.al and UeTriggerObjects.al (table 90330); test codeunit 90349
// Probe: written against the Windows BC 29 container.
// BC versions: 29 (27 and 28 by CI)
// Facts (AL Runner issue 6159): a page extension uses a protected var that another page extension of the same page declares (in the same app here; across apps:
//   tableextension/lt-bw-cross-app/BwCrossAppTests.al): does it compile, is the variable shared, and in which order do the two OnOpenPage triggers run.
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
        List: TestPage "LT UE PV List";
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
        Observer.Finish();
    end;
}
