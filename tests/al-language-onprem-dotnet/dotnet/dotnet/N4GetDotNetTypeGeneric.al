// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99009
// Probe: from al-runner issue 7833 (GetDotNetType of an unassigned DotNet variable declared as System.Collections.Generic.Dictionary`2;
//   Microsoft's MLPredictionManagement.CreateLabelDictionary calls Type.MakeGenericType on that result).
// Area: GetDotNetType of an unassigned DotNet variable declared as an open generic type (Dictionary`2, List`1, KeyValuePair`2), and of an
//   assigned Dictionary`2: Type.FullName, Type.Name, Format(Type), Type.IsGenericTypeDefinition, and MakeGenericType with String and Int32
//   followed by Activator.CreateInstance (the Microsoft pattern), or the error text and code.
// Already pinned elsewhere, not repeated: unassigned String, Char, Byte, Int32, StringBuilder, Type, Object, Exception and two enums
//   (BbGetDotNetType.al).
// Facts (measured by the corpus CI on 27.5, 28.5 and 29.0; the same on all three except where guarded):
//   - GetDotNetType of an unassigned Dictionary`2, List`1 or KeyValuePair`2 variable is the open generic type definition: FullName
//     'System.Collections.Generic.Dictionary`2', Name 'Dictionary`2', Format 'System.Collections.Generic.Dictionary`2[TKey,TValue]',
//     IsGenericTypeDefinition Yes. An assigned Dictionary`2 variable gives the same values.
//   - The Microsoft pattern runs: GetDotNetType of an unassigned DotNet String variable is System.Object here, so MakeGenericType builds
//     Dictionary`2[System.Object,System.Int32]; its FullName names System.Private.CoreLib Version=8.0.0.0 on 27.5 and 28.5 and
//     Version=10.0.0.0 on 29.0 (#if BC29PLUS).
// BC versions: 27.5, 28.5, 29.0
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; N4GnType) { }
        type("System.Collections.Generic.Dictionary`2"; N4GnDict) { }
        type("System.Collections.Generic.List`1"; N4GnList) { }
        type("System.Collections.Generic.KeyValuePair`2"; N4GnKvp) { }
        type("System.Array"; N4GnArray) { }
        type("System.Activator"; N4GnActivator) { }
        type("System.String"; N4GnString) { }
    }
}

codeunit 99009 "N4 GetDotNetType Generic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Show(T: DotNet N4GnType): Text
    begin
        exit(T.FullName() + '|' + T.Name() + '|' + Format(T) + '|' + Format(T.IsGenericTypeDefinition()));
    end;

    [TryFunction]
    local procedure TryUnassignedDictionary(var Shown: Text)
    var
        T: DotNet N4GnType;
        D: DotNet N4GnDict;
    begin
        T := GetDotNetType(D);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedList(var Shown: Text)
    var
        T: DotNet N4GnType;
        L: DotNet N4GnList;
    begin
        T := GetDotNetType(L);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryUnassignedKvp(var Shown: Text)
    var
        T: DotNet N4GnType;
        K: DotNet N4GnKvp;
    begin
        T := GetDotNetType(K);
        Shown := Show(T);
    end;

    [TryFunction]
    local procedure TryMakeGeneric(var Shown: Text)
    var
        T: DotNet N4GnType;
        Arr: DotNet N4GnArray;
        Activator: DotNet N4GnActivator;
        DummyString: DotNet N4GnString;
        DummyInt: Integer;
        D: DotNet N4GnDict;
        Count: Integer;
    begin
        Arr := Arr.CreateInstance(GetDotNetType(T), 2);
        Arr.SetValue(GetDotNetType(DummyString), 0);
        Arr.SetValue(GetDotNetType(DummyInt), 1);
        T := GetDotNetType(D);
        T := T.MakeGenericType(Arr);
        D := Activator.CreateInstance(T);
        D.Add('a', 1);
        D.Add('b', 2);
        Count := D.Count();
        Shown := Show(T) + '|count=' + Format(Count);
    end;

    [TryFunction]
    local procedure TryAssignedDictionary(var Shown: Text)
    var
        T: DotNet N4GnType;
        D: DotNet N4GnDict;
    begin
        D := D.Dictionary();
        T := GetDotNetType(D);
        Shown := Show(T);
    end;

    local procedure Run(Name: Text; Ok: Boolean; Shown: Text)
    begin
        if Ok then
            Observer.Observe(Name, Shown)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure N4_GetDotNetType_UnassignedOpenGenerics()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('dictionary', TryUnassignedDictionary(Shown), Shown);
        Shown := '';
        ClearLastError();
        Run('list', TryUnassignedList(Shown), Shown);
        Shown := '';
        ClearLastError();
        Run('keyvaluepair', TryUnassignedKvp(Shown), Shown);
        Observer.Expect('dictionary', 'System.Collections.Generic.Dictionary`2|Dictionary`2|System.Collections.Generic.Dictionary`2[TKey,TValue]|Yes');
        Observer.Expect('list', 'System.Collections.Generic.List`1|List`1|System.Collections.Generic.List`1[T]|Yes');
        Observer.Expect('keyvaluepair', 'System.Collections.Generic.KeyValuePair`2|KeyValuePair`2|System.Collections.Generic.KeyValuePair`2[TKey,TValue]|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure N4_GetDotNetType_MakeGenericType_MicrosoftPattern()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('make_generic', TryMakeGeneric(Shown), Shown);
#if BC29PLUS
        Observer.Expect('make_generic', 'System.Collections.Generic.Dictionary`2[[System.Object, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Int32, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]|Dictionary`2|System.Collections.Generic.Dictionary`2[System.Object,System.Int32]|No|count=2');
#else
        Observer.Expect('make_generic', 'System.Collections.Generic.Dictionary`2[[System.Object, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e],[System.Int32, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]|Dictionary`2|System.Collections.Generic.Dictionary`2[System.Object,System.Int32]|No|count=2');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure N4_GetDotNetType_AssignedDictionary()
    var
        Shown: Text;
    begin
        ClearLastError();
        Run('assigned', TryAssignedDictionary(Shown), Shown);
        Observer.Expect('assigned', 'System.Collections.Generic.Dictionary`2|Dictionary`2|System.Collections.Generic.Dictionary`2[TKey,TValue]|Yes');
        Observer.Verify();
    end;
}
