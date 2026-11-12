// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-frominteger-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 70021 "NQ Probe Kind" in namespace XYZ.Probe.Kinds (NqEnumDefs.al)
// Probe: al-runner issue 7920. The same calls as NqReceiverNoUsing.al, from a codeunit in another namespace that has a `using` of the
//   enum's namespace: the fully qualified receiver XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(n) still compiles and runs, as a case
//   selector and assigned to a variable declared by the plain name.
// BC versions: 27, 28, 29
namespace XYZ.Probe.CallersUsing;

using XYZ.Probe.Kinds;

codeunit 70023 "NQ Receiver Using"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QualifiedReceiver_Using_CaseSelector()
    var
        Observer: Codeunit "Probe Observer";
        Branch: Text;
    begin
        case XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(1) of
            "NQ Probe Kind"::Zero:
                Branch := 'Zero';
            "NQ Probe Kind"::One:
                Branch := 'One';
            "NQ Probe Kind"::Two:
                Branch := 'Two';
            else
                Branch := 'else';
        end;
        Observer.Observe('branch', Branch);
        Observer.Expect('branch', 'One');
        Observer.Verify();
    end;

    [Test]
    procedure QualifiedReceiver_Using_AssignToVariable()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "NQ Probe Kind";
    begin
        K := XYZ.Probe.Kinds."NQ Probe Kind".FromInteger(2);
        Observer.Observe('asInteger', Format(K.AsInteger()));
        Observer.Observe('format', Format(K));
        Observer.Observe('plainReceiver', Format("NQ Probe Kind".FromInteger(3)));
        Observer.Expect('asInteger', '2');
        Observer.Expect('format', 'Two');
        Observer.Expect('plainReceiver', 'Three');
        Observer.Verify();
    end;
}
