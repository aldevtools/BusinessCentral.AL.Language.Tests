// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), interfaces and codeunits of this file, self-contained test codeunit 71054
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Interface in List and Dictionary, is/as operators, interface extends, default interface implementation
// BC versions: 29 (27 and 28 by CI)

interface "LT OjT IBase"
{
    procedure Id(): Text;
}

interface "LT OjT IDerived" extends "LT OjT IBase"
{
    procedure Extra(): Text;
}

codeunit 71052 "LT OjT Impl Base" implements "LT OjT IBase"
{
    procedure Id(): Text
    begin
        exit('base');
    end;
}

codeunit 71053 "LT OjT Impl Derived" implements "LT OjT IDerived"
{
    var
        Calls: Integer;

    procedure Id(): Text
    begin
        Calls += 1;
        exit('derived#' + Format(Calls));
    end;

    procedure Extra(): Text
    begin
        exit('extra');
    end;
}

#if BC29PLUS
codeunit 71054 "LT OjT Interface Coll"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure List_OfInterface()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Interface "LT OjT IBase"];
        B: Codeunit "LT OjT Impl Base";
        D: Codeunit "LT OjT Impl Derived";
        Item: Interface "LT OjT IBase";
        i: Integer;
    begin
        L.Add(B);
        L.Add(D);
        L.Add(D);
        Observer.Observe('count', Format(L.Count()));
        for i := 1 to L.Count() do begin
            Item := L.Get(i);
            Observer.Observe('item' + Format(i), Item.Id());
        end;
        foreach Item in L do begin
            Observer.Observe('each', Item.Id());
        end;
        Observer.Expect('count', '3');
        Observer.Expect('item1', 'base');
        Observer.Expect('item2', 'derived#1');
        Observer.Expect('item3', 'derived#2');
        Observer.Expect('each', 'base');
        Observer.Expect('each', 'derived#3');
        Observer.Expect('each', 'derived#4');
        Observer.Verify();
    end;

    [Test]
    procedure Dictionary_OfInterface()
    var
        Observer: Codeunit "Probe Observer";
        Map: Dictionary of [Text, Interface "LT OjT IBase"];
        B: Codeunit "LT OjT Impl Base";
        D: Codeunit "LT OjT Impl Derived";
        Item: Interface "LT OjT IBase";
        Ok: Boolean;
    begin
        Map.Add('b', B);
        Map.Add('d', D);
        Observer.Observe('count', Format(Map.Count()));
        Item := Map.Get('b');
        Observer.Observe('b', Item.Id());
        Item := Map.Get('d');
        Observer.Observe('d1', Item.Id());
        Observer.Observe('d2', Item.Id());
        Ok := Map.Get('missing', Item);
        Observer.Observe('missing', Format(Ok));
        Observer.Observe('hasB', Format(Map.ContainsKey('b')));
        asserterror Map.Add('b', D);
        Observer.ObserveError('duplicateKey');
        Observer.Expect('count', '2');
        Observer.Expect('b', 'base');
        Observer.Expect('d1', 'derived#1');
        Observer.Expect('d2', 'derived#2');
        Observer.Expect('missing', 'No');
        Observer.Expect('hasB', 'Yes');
        Observer.Expect('duplicateKey|text', 'An item with the same key has already been added.');
        Observer.Expect('duplicateKey|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Extends_AssignDerivedToBase()
    var
        Observer: Codeunit "Probe Observer";
        D: Codeunit "LT OjT Impl Derived";
        Derived: Interface "LT OjT IDerived";
        Base: Interface "LT OjT IBase";
    begin
        Derived := D;
        Base := Derived;
        Observer.Observe('derivedId', Derived.Id());
        Observer.Observe('extra', Derived.Extra());
        Observer.Observe('baseId', Base.Id());
        Observer.Expect('derivedId', 'derived#1');
        Observer.Expect('extra', 'extra');
        Observer.Expect('baseId', 'derived#2');
        Observer.Verify();
    end;

    [Test]
    procedure IsOperator()
    var
        Observer: Codeunit "Probe Observer";
        B: Codeunit "LT OjT Impl Base";
        D: Codeunit "LT OjT Impl Derived";
        Base: Interface "LT OjT IBase";
    begin
        Base := D;
        Observer.Observe('derivedIsDerived', Format(Base is "LT OjT IDerived"));
        Observer.Observe('derivedIsBase', Format(Base is "LT OjT IBase"));
        Base := B;
        Observer.Observe('baseIsDerived', Format(Base is "LT OjT IDerived"));
        Observer.Observe('baseIsBase', Format(Base is "LT OjT IBase"));
        Observer.Expect('derivedIsDerived', 'Yes');
        Observer.Expect('derivedIsBase', 'Yes');
        Observer.Expect('baseIsDerived', 'No');
        Observer.Expect('baseIsBase', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AsOperator()
    var
        Observer: Codeunit "Probe Observer";
        B: Codeunit "LT OjT Impl Base";
        D: Codeunit "LT OjT Impl Derived";
        Base: Interface "LT OjT IBase";
        Derived: Interface "LT OjT IDerived";
    begin
        Base := D;
        Derived := Base as "LT OjT IDerived";
        Observer.Observe('extra', Derived.Extra());
        Base := B;
        asserterror Derived := Base as "LT OjT IDerived";
        Observer.ObserveError('invalidCast');
        Observer.Expect('extra', 'extra');
        Observer.Expect('invalidCast|text', 'The expression cannot be the target interface.');
        Observer.Expect('invalidCast|code', 'UnableToCast');
        Observer.Verify();
    end;
}
#endif
