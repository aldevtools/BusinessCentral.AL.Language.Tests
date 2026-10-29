// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99492
// Probe: observation form (Finish), values to be converted to Expect after a real-BC run
// Facts: Clear(x) on DotNet variables (StringBuilder, Dictionary): IsNull afterwards, a member call afterwards, a second variable assigned before the Clear
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; LtULBuilder) { }
    }
    assembly("mscorlib")
    {
        type("System.Collections.Generic.Dictionary`2[[System.String, mscorlib],[System.String, mscorlib]]"; LtULDict) { }
    }
}

codeunit 99492 "LT UL DotNet Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLength(var B: DotNet LtULBuilder; var Result: Integer)
    begin
        Result := B.Length;
    end;

    [TryFunction]
    local procedure TryAppend(var B: DotNet LtULBuilder)
    begin
        B.Append('x');
    end;

    [TryFunction]
    local procedure TryCount(var D: DotNet LtULDict; var Result: Integer)
    begin
        Result := D.Count;
    end;

    [Test]
    procedure ClearStringBuilder_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        B: DotNet LtULBuilder;
        Alias: DotNet LtULBuilder;
        Len: Integer;
    begin
        B := B.StringBuilder();
        B.Append('abc');
        Alias := B;
        Observer.Observe('before|is null', Format(IsNull(B)));
        Clear(B);
        Observer.Observe('cleared|is null', Format(IsNull(B)));
        Observer.Observe('alias|is null', Format(IsNull(Alias)));
        if TryLength(B, Len) then
            Observer.Observe('cleared|length', Format(Len))
        else
            Observer.ObserveError('cleared|length');
        if TryAppend(B) then
            Observer.Observe('cleared|append', 'ok')
        else
            Observer.ObserveError('cleared|append');
        Observer.Observe('alias|length', Format(Alias.Length));
        Observer.Observe('alias|text', Alias.ToString());
        B := B.StringBuilder();
        B.Append('zz');
        Observer.Observe('reassigned|text', B.ToString());
        Observer.Observe('alias after reassign|text', Alias.ToString());
        Observer.Finish();
    end;

    [Test]
    procedure ClearStringBuilder_NeverAssigned()
    var
        Observer: Codeunit "Probe Observer";
        B: DotNet LtULBuilder;
        Len: Integer;
    begin
        Observer.Observe('never assigned|is null', Format(IsNull(B)));
        Clear(B);
        Observer.Observe('cleared never assigned|is null', Format(IsNull(B)));
        if TryLength(B, Len) then
            Observer.Observe('cleared never assigned|length', Format(Len))
        else
            Observer.ObserveError('cleared never assigned|length');
        Observer.Finish();
    end;

    [Test]
    procedure ClearDictionary_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        D: DotNet LtULDict;
        Alias: DotNet LtULDict;
        Cnt: Integer;
    begin
        D := D.Dictionary();
        D.Add('a', 'b');
        Alias := D;
        Clear(D);
        Observer.Observe('cleared|is null', Format(IsNull(D)));
        Observer.Observe('alias|is null', Format(IsNull(Alias)));
        if TryCount(D, Cnt) then
            Observer.Observe('cleared|count', Format(Cnt))
        else
            Observer.ObserveError('cleared|count');
        Observer.Observe('alias|count', Format(Alias.Count));
        Observer.Observe('alias|contains a', Format(Alias.ContainsKey('a')));
        Alias.Add('c', 'd');
        Observer.Observe('alias after add|count', Format(Alias.Count));
        Observer.Finish();
    end;
}
