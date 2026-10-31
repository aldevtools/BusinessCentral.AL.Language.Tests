// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160); own test codeunit 99480 (writer Y17, gap cycle 1 G4)
// Probe: System.Collections.Generic.Dictionary`2 made with the Int32 capacity constructor, filled with ContainsKey/Add from an ArrayList
//   of Integer and walked with foreach into a KeyValuePair`2 variable (the shape of RequestPageParametersHelper.GetViewFromDynamicRequestPage
//   and ConvertFiltersToParameters): the walk order and how Key and Value format, Count, Item, ContainsKey, and the errors of a duplicate
//   Add, Item of a missing key and a negative capacity.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Collections.Generic.Dictionary`2"; LtY17DnDict) { }
        type("System.Collections.Generic.KeyValuePair`2"; LtY17DnKvp) { }
        type("System.Collections.ArrayList"; LtY17DnArrayList) { }
    }
}

codeunit 99480 "LT Y17 DotNet Dictionary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Dict: DotNet LtY17DnDict)
    var
        List: DotNet LtY17DnArrayList;
        T: Integer;
    begin
        List := List.ArrayList();
        List.Add(18);
        List.Add(36);
        List.Add(18);
        List.Add(5);
        Dict := Dict.Dictionary(List.Count);
        foreach T in List do
            if not Dict.ContainsKey(T) then
                Dict.Add(T, 'view' + Format(T));
    end;

    [TryFunction]
    local procedure TryAdd(var Dict: DotNet LtY17DnDict; DictKey: Integer; Value: Text)
    begin
        Dict.Add(DictKey, Value);
    end;

    [TryFunction]
    local procedure TryItem(var Dict: DotNet LtY17DnDict; DictKey: Integer; var Result: Text)
    begin
        Result := Format(Dict.Item(DictKey));
    end;

    [TryFunction]
    local procedure TryCapacity(var Dict: DotNet LtY17DnDict; Capacity: Integer)
    begin
        Dict := Dict.Dictionary(Capacity);
    end;

    [Test]
    procedure DnDict_Capacity_AddContainsForeach()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
        Kvp: DotNet LtY17DnKvp;
        Out: Text;
        Out2: Text;
    begin
        Fill(Dict);
        foreach Kvp in Dict do begin
            Out += StrSubstNo('Table%1', Kvp.Key) + '=' + Format(Kvp.Value) + ';';
            Out2 += Format(Kvp.Key) + '|' + StrSubstNo('%1', Kvp.Value) + ';';
        end;
        Observer.Observe('walk', Out);
        Observer.Observe('walk format', Out2);
        Observer.Observe('count', Format(Dict.Count));
        Observer.Finish();
    end;

    [Test]
    procedure DnDict_Capacity_Zero_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
        Kvp: DotNet LtY17DnKvp;
        Steps: Integer;
    begin
        Dict := Dict.Dictionary(0);
        foreach Kvp in Dict do
            Steps += 1;
        Observer.Observe('steps', Format(Steps));
        Observer.Observe('count', Format(Dict.Count));
        Observer.Finish();
    end;

    [Test]
    procedure DnDict_Count_Item()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
    begin
        Fill(Dict);
        Observer.Observe('count', Format(Dict.Count));
        Observer.Observe('item 36', Format(Dict.Item(36)));
        Observer.Observe('contains 5', Format(Dict.ContainsKey(5)));
        Observer.Observe('contains 99', Format(Dict.ContainsKey(99)));
        Observer.Finish();
    end;

    [Test]
    procedure DnDict_DuplicateAdd()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
    begin
        Fill(Dict);
        Observer.Observe('add ok', Format(TryAdd(Dict, 18, 'x')));
        Observer.ObserveError('add');
        Observer.Observe('count after', Format(Dict.Count));
        Observer.Observe('item 18 after', Format(Dict.Item(18)));
        Observer.Finish();
    end;

    [Test]
    procedure DnDict_Item_Missing()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
        Result: Text;
    begin
        Fill(Dict);
        Observer.Observe('item ok', Format(TryItem(Dict, 99, Result)));
        Observer.ObserveError('item');
        Observer.Finish();
    end;

    [Test]
    procedure DnDict_Capacity_Negative()
    var
        Observer: Codeunit "Probe Observer";
        Dict: DotNet LtY17DnDict;
    begin
        Observer.Observe('new ok', Format(TryCapacity(Dict, -1)));
        Observer.ObserveError('new');
        Observer.Finish();
    end;
}
