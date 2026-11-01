// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160); own test codeunit 99392 (writer Y51, gap cycle 5 spec G5-24)
// Probe: System.Collections.Generic.Dictionary`2 made with the parameterless constructor (the Edit in Excel filter shape): Text keys
//        (ContainsKey in other casing and with a trailing space, Item, a duplicate Add), DotNet object values (StringBuilder) with
//        TryGetValue into a DotNet variable, Remove twice and a walk of .Values, Integer keys on a parameterless dictionary, and a
//        dictionary handed out through a var parameter. Each member call that may fail runs in a TryFunction.
//        Already pinned nearby: lt-y17-dotnet-dictionary/Y17DotNetDictionary.al (capacity constructor, Integer keys, Text values),
//        lt-qx-dotnet/QxDotNetDemoShapes.al (parameterless constructor, never filled).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Collections.Generic.Dictionary`2"; LtY51DnDict) { }
        type("System.Collections.Generic.KeyValuePair`2"; LtY51DnKvp) { }
        type("System.Text.StringBuilder"; LtY51DnSb) { }
    }
}

codeunit 99392 "LT Y51 DotNet Dict NoCap"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryAddText(var D: DotNet LtY51DnDict; K: Text; V: Text)
    begin
        D.Add(K, V);
    end;

    [TryFunction]
    local procedure TryItemText(var D: DotNet LtY51DnDict; K: Text; var Result: Text)
    begin
        Result := Format(D.Item(K));
    end;

    [TryFunction]
    local procedure TryContains(var D: DotNet LtY51DnDict; K: Text; var Result: Boolean)
    begin
        Result := D.ContainsKey(K);
    end;

    local procedure Contains(Name: Text; var D: DotNet LtY51DnDict; K: Text)
    var
        Result: Boolean;
    begin
        if TryContains(D, K, Result) then
            Observer.Observe(Name, Format(Result))
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure DnDictNoCap_TextKeys_ContainsAdd()
    var
        D: DotNet LtY51DnDict;
        Item: Text;
    begin
        Observer.Observe('isnull_before', Format(IsNull(D)));
        D := D.Dictionary();
        Observer.Observe('isnull_after', Format(IsNull(D)));
        Contains('contains_empty', D, 'Name');
        if TryAddText(D, 'Name', 'v1') then
            Observer.Observe('add_1', 'ok')
        else
            Observer.ObserveError('add_1');
        Contains('contains_name', D, 'Name');
        Contains('contains_NAME', D, 'NAME');
        Contains('contains_name_space', D, 'Name ');
        Observer.Observe('count_1', Format(D.Count));
        if TryItemText(D, 'Name', Item) then
            Observer.Observe('item_name', Item)
        else
            Observer.ObserveError('item_name');
        if TryItemText(D, 'NAME', Item) then
            Observer.Observe('item_NAME', Item)
        else
            Observer.ObserveError('item_NAME');
        if TryAddText(D, 'Name', 'v2') then
            Observer.Observe('dup_add', 'ok')
        else
            Observer.ObserveError('dup_add');
        Observer.Observe('count_after_dup', Format(D.Count));
        Observer.Expect('isnull_before', 'Yes');
        Observer.Expect('isnull_after', 'No');
        Observer.Expect('contains_empty', 'No');
        Observer.Expect('add_1', 'ok');
        Observer.Expect('contains_name', 'Yes');
        Observer.Expect('contains_NAME', 'No');
        Observer.Expect('contains_name_space', 'No');
        Observer.Expect('count_1', '1');
        Observer.Expect('item_name', 'v1');
        Observer.Expect('item_NAME|text', 'A call to System.Collections.Generic.Dictionary`2[System.Object,System.Object].Item failed with this message: The given key ''NAME'' was not present in the dictionary.');
        Observer.Expect('item_NAME|code', 'DotNetInvoke:KeyNotFound');
        Observer.Expect('dup_add|text', 'A call to System.Collections.Generic.Dictionary`2[System.Object,System.Object].Add failed with this message: An item with the same key has already been added. Key: Name');
        Observer.Expect('dup_add|code', 'DotNetInvoke:Argument');
        Observer.Expect('count_after_dup', '1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddSb(var D: DotNet LtY51DnDict; K: Text; V: DotNet LtY51DnSb)
    begin
        D.Add(K, V);
    end;

    [TryFunction]
    local procedure TryGet(var D: DotNet LtY51DnDict; K: Text; var Out: DotNet LtY51DnSb; var Found: Boolean)
    begin
        Found := D.TryGetValue(K, Out);
    end;

    [TryFunction]
    local procedure TryRemove(var D: DotNet LtY51DnDict; K: Text; var Removed: Boolean)
    begin
        Removed := D.Remove(K);
    end;

    [TryFunction]
    local procedure TryValues(var D: DotNet LtY51DnDict; var Walk: Text)
    var
        V: DotNet LtY51DnSb;
    begin
        foreach V in D.Values do
            Walk += V.ToString() + ';';
    end;

    [Test]
    procedure DnDictNoCap_ObjectValues()
    var
        D: DotNet LtY51DnDict;
        SB: DotNet LtY51DnSb;
        SB2: DotNet LtY51DnSb;
        Out: DotNet LtY51DnSb;
        Found: Boolean;
        Removed: Boolean;
        Walk: Text;
    begin
        D := D.Dictionary();
        SB := SB.StringBuilder('node1');
        SB2 := SB2.StringBuilder('node2');
        if TryAddSb(D, 'B', SB2) then
            Observer.Observe('add_b', 'ok')
        else
            Observer.ObserveError('add_b');
        if TryAddSb(D, 'A', SB) then
            Observer.Observe('add_a', 'ok')
        else
            Observer.ObserveError('add_a');
        if TryGet(D, 'A', Out, Found) then begin
            Observer.Observe('tryget_a', Format(Found));
            Observer.Observe('tryget_a_value', Out.ToString());
        end else
            Observer.ObserveError('tryget_a');
        SB.Append('+');
        Observer.Observe('tryget_a_value_after_append', Out.ToString());
        if TryGet(D, 'Z', Out, Found) then begin
            Observer.Observe('tryget_z', Format(Found));
            Observer.Observe('tryget_z_isnull', Format(IsNull(Out)));
        end else
            Observer.ObserveError('tryget_z');
        if TryValues(D, Walk) then
            Observer.Observe('values_walk', Walk)
        else
            Observer.ObserveError('values_walk');
        if TryRemove(D, 'A', Removed) then
            Observer.Observe('remove_a_1', Format(Removed))
        else
            Observer.ObserveError('remove_a_1');
        if TryRemove(D, 'A', Removed) then
            Observer.Observe('remove_a_2', Format(Removed))
        else
            Observer.ObserveError('remove_a_2');
        Observer.Observe('count_end', Format(D.Count));
        Observer.Expect('add_b', 'ok');
        Observer.Expect('add_a', 'ok');
        Observer.Expect('tryget_a', 'Yes');
        Observer.Expect('tryget_a_value', 'node1');
        Observer.Expect('tryget_a_value_after_append', 'node1+');
        Observer.Expect('tryget_z', 'No');
        Observer.Expect('tryget_z_isnull', 'Yes');
        Observer.Expect('values_walk', 'node2;node1+;');
        Observer.Expect('remove_a_1', 'Yes');
        Observer.Expect('remove_a_2', 'No');
        Observer.Expect('count_end', '1');
        Observer.Verify();
    end;

    [Test]
    procedure DnDictNoCap_IntegerKeys()
    var
        D: DotNet LtY51DnDict;
        Kvp: DotNet LtY51DnKvp;
        Walk: Text;
    begin
        D := D.Dictionary();
        if not D.ContainsKey(18) then
            D.Add(18, 'view18');
        if not D.ContainsKey(5) then
            D.Add(5, 'view5');
        if not D.ContainsKey(18) then
            D.Add(18, 'again');
        Observer.Observe('count', Format(D.Count));
        Observer.Observe('item_5', Format(D.Item(5)));
        foreach Kvp in D do
            Walk += Format(Kvp.Key) + '=' + Format(Kvp.Value) + ';';
        Observer.Observe('walk', Walk);
        Observer.Expect('count', '2');
        Observer.Expect('item_5', 'view5');
        Observer.Expect('walk', '18=view18;5=view5;');
        Observer.Verify();
    end;

    local procedure GetDict(var Out: DotNet LtY51DnDict; D: DotNet LtY51DnDict)
    begin
        Out := D;
    end;

    [Test]
    procedure DnDictNoCap_PassedByVar()
    var
        D: DotNet LtY51DnDict;
        Out: DotNet LtY51DnDict;
    begin
        D := D.Dictionary();
        D.Add('k1', 'v1');
        GetDict(Out, D);
        Out.Add('k2', 'v2');
        Observer.Observe('byvar_count', Format(D.Count));
        Observer.Observe('byvar_out_count', Format(Out.Count));
        Observer.Observe('byvar_contains_k2', Format(D.ContainsKey('k2')));
        Observer.Expect('byvar_count', '2');
        Observer.Expect('byvar_out_count', '2');
        Observer.Expect('byvar_contains_k2', 'Yes');
        Observer.Verify();
    end;
}
