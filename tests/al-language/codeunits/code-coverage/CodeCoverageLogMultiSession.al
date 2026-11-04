// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none
//
// CodeCoverageLog(Enable, MultiSession): the result for each combination, the value of the
// argument-less form after each call, and that the MultiSession flag changes nothing observable.
// Every test switches the log off again at the end.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72718 "LT P161 Code Coverage Multi"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P161_CodeCoverageLog_MultiSessionCombinations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeCoverageLog(false, false);
        Observer.Observe('off.single', Format(CodeCoverageLog()));
        Observer.Observe('on.multi', Format(CodeCoverageLog(true, true)));
        Observer.Observe('on.multi.state', Format(CodeCoverageLog()));
        Observer.Observe('off.multi', Format(CodeCoverageLog(false, true)));
        Observer.Observe('off.multi.state', Format(CodeCoverageLog()));
        Observer.Observe('on.single', Format(CodeCoverageLog(true, false)));
        Observer.Observe('on.single.state', Format(CodeCoverageLog()));
        Observer.Observe('on.again.multi', Format(CodeCoverageLog(true, true)));
        Observer.Observe('on.again.state', Format(CodeCoverageLog()));
        Observer.Observe('off.single2', Format(CodeCoverageLog(false, false)));
        Observer.Observe('off.single2.state', Format(CodeCoverageLog()));
        Observer.Expect('off.single', 'No');
        Observer.Expect('on.multi', 'Yes');
        Observer.Expect('on.multi.state', 'Yes');
        Observer.Expect('off.multi', 'No');
        Observer.Expect('off.multi.state', 'No');
        Observer.Expect('on.single', 'Yes');
        Observer.Expect('on.single.state', 'Yes');
        Observer.Expect('on.again.multi', 'Yes');
        Observer.Expect('on.again.state', 'Yes');
        Observer.Expect('off.single2', 'No');
        Observer.Expect('off.single2.state', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P161_CodeCoverageLog_EnableOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeCoverageLog(false, false);
        Observer.Observe('enable', Format(CodeCoverageLog(true)));
        Observer.Observe('enable.state', Format(CodeCoverageLog()));
        Observer.Observe('disable', Format(CodeCoverageLog(false)));
        Observer.Observe('disable.state', Format(CodeCoverageLog()));
        Observer.Expect('enable', 'Yes');
        Observer.Expect('enable.state', 'Yes');
        Observer.Expect('disable', 'No');
        Observer.Expect('disable.state', 'No');
        Observer.Verify();
    end;
}
