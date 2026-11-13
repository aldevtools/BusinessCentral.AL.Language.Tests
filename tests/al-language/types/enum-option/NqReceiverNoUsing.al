// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-frominteger-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 70021 "NQ Probe Kind" in namespace XYZ.Probe.Kinds (NqEnumDefs.al)
// Probe: al-runner issue 7920. A namespace-qualified enum name WITHOUT the Enum:: prefix as the receiver of a static call,
//   XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(n), from a codeunit in another namespace and with no `using` of the enum's namespace:
//   as a case selector, assigned to an enum variable, and inside Format. The Enum::Ns."X".FromInteger form is pinned in
//   ProbeNamespacedEnumQualified.al; the `using` form of this file is NqReceiverUsing.al.
// BC versions: 27, 28, 29
namespace XYZ.Probe.Callers;

codeunit 70022 "NQ Receiver No Using"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QualifiedReceiver_NoUsing_CaseSelector()
    var
        Observer: Codeunit "Probe Observer";
        Branch: Text;
    begin
        case XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(2) of
            XYZ.Probe.Kinds."NQ Probe Kind"::Zero:
                Branch := 'Zero';
            XYZ.Probe.Kinds."NQ Probe Kind"::One:
                Branch := 'One';
            XYZ.Probe.Kinds."NQ Probe Kind"::Two:
                Branch := 'Two';
            else
                Branch := 'else';
        end;
        Observer.Observe('branch', Branch);
        Observer.Expect('branch', 'Two');
        Observer.Verify();
    end;

    [Test]
    procedure QualifiedReceiver_NoUsing_AssignToVariable()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum XYZ.Probe.Kinds."NQ Probe Kind";
    begin
        K := XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(3);
        Observer.Observe('asInteger', Format(K.AsInteger()));
        Observer.Observe('format', Format(K));
        Observer.Observe('inlineFormat', Format(XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(1)));
        Observer.Expect('asInteger', '3');
        Observer.Expect('format', 'Three');
        Observer.Expect('inlineFormat', 'One');
        Observer.Verify();
    end;
}
