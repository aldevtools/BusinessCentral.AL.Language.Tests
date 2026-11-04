// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-canloadtype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61404
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: CanLoadType(DotNet) for an assigned DotNet variable, an unassigned one, and a DotNet variable of a type that is not an object type.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; LtOType) { }
        type("System.Text.StringBuilder"; LtOBuilder) { }
    }
}

codeunit 61404 "LT O CanLoadType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCan(var T: DotNet LtOType; var Result: Boolean)
    begin
        Result := CanLoadType(T);
    end;

    [TryFunction]
    local procedure TryCanBuilder(var B: DotNet LtOBuilder; var Result: Boolean)
    begin
        Result := CanLoadType(B);
    end;

    [Test]
    procedure O_CanLoadType()
    var
        Observer: Codeunit "Probe Observer";
        Unassigned: DotNet LtOType;
        Assigned: DotNet LtOType;
        Builder: DotNet LtOBuilder;
        Empty: DotNet LtOBuilder;
        Result: Boolean;
    begin
        Assigned := GetDotNetType(Builder);
        if TryCan(Unassigned, Result) then
            Observer.Observe('unassigned type|return', Format(Result))
        else
            Observer.ObserveError('unassigned type');
        if TryCan(Assigned, Result) then
            Observer.Observe('assigned type|return', Format(Result))
        else
            Observer.ObserveError('assigned type');
        Builder := Builder.StringBuilder();
        if TryCanBuilder(Builder, Result) then
            Observer.Observe('builder|return', Format(Result))
        else
            Observer.ObserveError('builder');
        if TryCanBuilder(Empty, Result) then
            Observer.Observe('unassigned builder|return', Format(Result))
        else
            Observer.ObserveError('unassigned builder');
        Observer.Expect('unassigned type|return', 'Yes');
        Observer.Expect('assigned type|return', 'Yes');
        Observer.Expect('builder|return', 'Yes');
        Observer.Expect('unassigned builder|return', 'Yes');
        Observer.Verify();
    end;
}
