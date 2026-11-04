// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-code-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: comparison of two Code literals as constant expressions (own file: a compiler constant fold could reject or fold it)
// BC versions: 29 (final facts are added after the measurement)

codeunit 74903 "LT P145 Code Literals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P145_LiteralVsLiteral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('109002>1010999', Format('109002' > '1010999'));
        Observer.Observe('109002<1010999', Format('109002' < '1010999'));
        Observer.Observe('9<10', Format('9' < '10'));
        Observer.Observe('9>10', Format('9' > '10'));
        Observer.Observe('A9<A10', Format('A9' < 'A10'));
        Observer.Observe('A9>A10', Format('A9' > 'A10'));
        Observer.Observe('0010=10', Format('0010' = '10'));
        Observer.Observe('010=10', Format('010' = '10'));
        Observer.Observe('010<10', Format('010' < '10'));
        Observer.Observe('010>10', Format('010' > '10'));
        Observer.Observe('a9=A9', Format('a9' = 'A9'));
        Observer.Observe('2<10', Format('2' < '10'));
        Observer.Expect('109002>1010999', 'Yes');
        Observer.Expect('109002<1010999', 'No');
        Observer.Expect('9<10', 'No');
        Observer.Expect('9>10', 'Yes');
        Observer.Expect('A9<A10', 'No');
        Observer.Expect('A9>A10', 'Yes');
        Observer.Expect('0010=10', 'No');
        Observer.Expect('010=10', 'No');
        Observer.Expect('010<10', 'Yes');
        Observer.Expect('010>10', 'No');
        Observer.Expect('a9=A9', 'No');
        Observer.Expect('2<10', 'No');
        Observer.Verify();
    end;
}
