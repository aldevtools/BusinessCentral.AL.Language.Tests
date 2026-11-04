// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained interfaces, codeunits and an enum below
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Interface variables hold a reference to the codeunit instance: passing one by value, returning
// one, and storing one in a List, a Dictionary or an array all share the instance. A call on an
// interface variable that was never assigned raises "Interface not initialized" (code
// InvalidOperation). Casting an enum ordinal that the enum does not declare, when the enum has no
// UnknownValueImplementation, raises "Enum does not contain value N." (code ArgumentOutOfRange).
// BC versions: 27.5

interface "Probe IFoo"
{
    procedure Bump(): Integer;
}

interface "Probe IBar" extends "Probe IFoo"
{
    procedure Name(): Text;
}

codeunit 68104 "Probe Foo Impl" implements "Probe IFoo"
{
    var
        Counter: Integer;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;
}

codeunit 68105 "Probe Bar Impl" implements "Probe IBar"
{
    var
        Counter: Integer;

    procedure Bump(): Integer
    begin
        Counter += 10;
        exit(Counter);
    end;

    procedure Name(): Text
    begin
        exit('bar');
    end;
}

enum 68106 "Probe No Default Impl" implements "Probe IFoo"
{
    Extensible = false;

    value(0; A) { Implementation = "Probe IFoo" = "Probe Foo Impl"; }
    value(1; B) { Implementation = "Probe IFoo" = "Probe Foo Impl"; }
}

codeunit 68107 "Probe Interface Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure Interface_CallOnUnassignedVariable_Throws_InterfaceNotInitialized()
    var
        Foo: Interface "Probe IFoo";
        Result: Integer;
    begin
        Initialize();

        asserterror Result := Foo.Bump();

        Assert.AreEqual('Interface not initialized', GetLastErrorText(), 'full text');
        Assert.AreEqual('InvalidOperation', GetLastErrorCode(), 'error code');
    end;

    [Test]
    procedure Interface_CastUndeclaredEnumOrdinalWithoutUnknownImplementation_Throws()
    var
        Kind: Enum "Probe No Default Impl";
        Foo: Interface "Probe IFoo";
        Result: Integer;
    begin
        Initialize();

        Kind := "Probe No Default Impl".FromInteger(99);
        Assert.AreEqual(99, Kind.AsInteger(), 'FromInteger carries the undeclared ordinal through');

        asserterror Foo := Kind;

        Assert.AreEqual('Enum does not contain value 99.', GetLastErrorText(), 'full text of the failed cast');
        Assert.AreEqual('ArgumentOutOfRange', GetLastErrorCode(), 'error code of the failed cast');

        asserterror Result := Foo.Bump();

        Assert.AreEqual('Interface not initialized', GetLastErrorText(), 'the variable stays unassigned after the failed cast');
    end;

    [Test]
    procedure Interface_PassedByValue_SharesTheInstance()
    var
        Impl: Codeunit "Probe Foo Impl";
        Foo: Interface "Probe IFoo";
    begin
        Initialize();

        Foo := Impl;
        Assert.AreEqual(1, Foo.Bump(), 'first bump through the variable');
        Assert.AreEqual(2, BumpIn(Foo), 'a by-value parameter calls the same instance');
        Assert.AreEqual(3, Foo.Bump(), 'the caller''s variable sees the parameter''s bump');
        Assert.AreEqual(4, Impl.Bump(), 'so does the codeunit variable it was assigned from');
    end;

    local procedure BumpIn(Foo: Interface "Probe IFoo"): Integer
    begin
        exit(Foo.Bump());
    end;

    [Test]
    procedure Interface_VarParameterAndReturnValue_CarryTheReference()
    var
        Foo: Interface "Probe IFoo";
        Other: Interface "Probe IFoo";
    begin
        Initialize();

        AssignAndBump(Foo);
        Assert.AreEqual(2, Foo.Bump(), 'a var parameter hands the assigned instance (already bumped once) back');

        Other := MakeFoo();
        Assert.AreEqual(1, Other.Bump(), 'a returned interface is usable');
        Assert.AreEqual(2, Other.Bump(), 'and keeps its state');
    end;

    local procedure AssignAndBump(var Foo: Interface "Probe IFoo")
    var
        Impl: Codeunit "Probe Foo Impl";
    begin
        Foo := Impl;
        Foo.Bump();
    end;

    local procedure MakeFoo(): Interface "Probe IFoo"
    var
        Impl: Codeunit "Probe Foo Impl";
    begin
        exit(Impl);
    end;

    [Test]
    procedure Interface_InListDictionaryAndArray_ShareTheInstance()
    var
        Impl: Codeunit "Probe Foo Impl";
        Foo: Interface "Probe IFoo";
        FooList: List of [Interface "Probe IFoo"];
        FooMap: Dictionary of [Text, Interface "Probe IFoo"];
        FooArray: array[2] of Interface "Probe IFoo";
    begin
        Initialize();

        Foo := Impl;
        FooList.Add(Foo);
        FooMap.Add('key', Foo);
        FooArray[1] := Foo;

        Assert.AreEqual(1, FooList.Get(1).Bump(), 'list element calls the instance');
        Assert.AreEqual(2, FooMap.Get('key').Bump(), 'dictionary value shares it');
        Assert.AreEqual(3, FooArray[1].Bump(), 'array element shares it');
        Assert.AreEqual(4, Foo.Bump(), 'and so does the variable the elements were copied from');
    end;

    [Test]
    procedure Interface_ExtendedInterface_IsAndAs()
    var
        Impl: Codeunit "Probe Bar Impl";
        Bar: Interface "Probe IBar";
        Foo: Interface "Probe IFoo";
    begin
        Initialize();

        Bar := Impl;
        Foo := Bar;

        Assert.AreEqual(10, Foo.Bump(), 'the extended interface converts to its base and calls the same instance');
        Assert.IsTrue(Foo is "Probe IBar", 'is the extending interface');
        Assert.IsTrue(Foo is "Probe IFoo", 'is the base interface');

        Bar := Foo as "Probe IBar";

        Assert.AreEqual('bar', Bar.Name(), 'as gives back the extending interface');
    end;
}
