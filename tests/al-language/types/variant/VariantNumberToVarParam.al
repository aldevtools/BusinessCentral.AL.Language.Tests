// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74931 "LT VarNum Var Param"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FillText(var T: Text)
    begin
        T := 'filled';
    end;

    [TryFunction]
    local procedure TryFill(var V: Variant)
    begin
        FillText(V);
    end;

    [Test]
    procedure VarTextParam_VariantArgument()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Ok: Boolean;
    begin
        V := 7;
        Ok := TryFill(V);
        Observer.Observe('integer ok', Format(Ok));
        Observer.Observe('integer error', GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Observe('variant after', Format(V));
        V := 'text';
        Ok := TryFill(V);
        Observer.Observe('text ok', Format(Ok));
        Observer.Observe('variant after text', Format(V));
        Observer.Expect('integer ok', 'Yes');
        Observer.Expect('integer error', ':');
        Observer.Expect('variant after', 'filled');
        Observer.Expect('text ok', 'Yes');
        Observer.Expect('variant after text', 'filled');
        Observer.Verify();
    end;
}
