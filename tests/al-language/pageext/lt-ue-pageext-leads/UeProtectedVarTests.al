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
        List: TestPage "LT UE PV Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amount := 5;
        Row.Insert();
        List.OpenView();
        Observer.Observe('id', List.Id.Value());
        Observer.Observe('trace try', Format(TryTrace(List)));
        Observer.ObserveError('trace try');
        Observer.Observe('mid try', Format(TryMid(List)));
        Observer.ObserveError('mid try');
        Observer.Observe('top try', Format(TryTop(List)));
        Observer.ObserveError('top try');
        List.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryTrace(var List: TestPage "LT UE PV Card")
    begin
        Observer.Observe('trace', List.TraceField.Value());
    end;

    [TryFunction]
    local procedure TryMid(var List: TestPage "LT UE PV Card")
    begin
        Observer.Observe('mid visible', Format(List.MidAmount.Visible()));
    end;

    [TryFunction]
    local procedure TryTop(var List: TestPage "LT UE PV Card")
    begin
        Observer.Observe('top visible', Format(List.TopAmount.Visible()));
    end;
}
