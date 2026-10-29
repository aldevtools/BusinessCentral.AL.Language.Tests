// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures B (page extension 61119, UeXbPageExt.al) and C (page extension 61129, UeXcPageExt.al); test codeunit 90350
// Probe: written against the Windows BC 29 container.
// BC versions: 29 (27 and 28 by CI)
// Facts (AL Runner issue 6159): a page extension in app C uses protected variables that a page extension of the same page in app B declares, with app C depending on app B:
//   it compiles, and both extensions share the variables (the trace shows the order of the two OnOpenPage triggers and the value each one saw).
codeunit 90350 "LT UE Cross App Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ProtectedVar_OfExtensionInDependencyApp_IsSharedAndAssignable()
    var
        Master: Record "LT BW XB Master";
        Card: TestPage "LT BW XB Master Card";
    begin
        Master.DeleteAll();
        Master."No." := 'UE1';
        Master.Insert();
        Card.OpenView();
        Card.GoToRecord(Master);
        Observer.Observe('trace', Card.UeTopField.Value());
        Observer.Observe('mid text', Card.UeMidField.Value());
        Observer.Observe('mid visible', Format(Card.UeMidField.Visible()));
        Observer.Observe('top shown visible', Format(Card.UeTopShown.Visible()));
        Card.Close();
        Observer.Finish();
    end;
}
