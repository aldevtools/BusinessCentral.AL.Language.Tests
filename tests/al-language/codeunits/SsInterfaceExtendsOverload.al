// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: none
// Probe: an interface that extends another and both declare SetValue with different parameter lists. Facts: calling the base
// interface's overload through a variable of the derived interface and through a function return of the derived interface compiles and
// dispatches to the implementation's base overload; the derived overload dispatches to its own.

interface "LT SS IE Base"
{
    procedure SetValue(Value: Text; Count: Integer)
    procedure GetValue(): Text
}

interface "LT SS IE Derived" extends "LT SS IE Base"
{
    procedure SetValue(Value: Text; Extra: Text; Count: Integer)
}

interface "LT SS IE Factory"
{
    procedure GetSetup(): Interface "LT SS IE Derived"
}

codeunit 99820 "LT SS IE Impl" implements "LT SS IE Derived", "LT SS IE Factory"
{
    SingleInstance = true;

    var
        Stored: Text;

    procedure SetValue(Value: Text; Count: Integer)
    begin
        Stored := 'base:' + Value + ':' + Format(Count);
    end;

    procedure SetValue(Value: Text; Extra: Text; Count: Integer)
    begin
        Stored := 'derived:' + Value + Extra + ':' + Format(Count);
    end;

    procedure GetValue(): Text
    begin
        exit(Stored);
    end;

    procedure GetSetup(): Interface "LT SS IE Derived"
    var
        Self: Codeunit "LT SS IE Impl";
    begin
        exit(Self);
    end;
}

codeunit 99821 "LT SS IE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BaseOverload_ThroughDerivedVariable_DispatchesToBase()
    var
        Impl: Codeunit "LT SS IE Impl";
        Derived: Interface "LT SS IE Derived";
    begin
        Derived := Impl;
        Derived.SetValue('a', 1);
        if Derived.GetValue() <> 'base:a:1' then
            Error('expected base:a:1 but was %1', Derived.GetValue());
    end;

    [Test]
    procedure DerivedOverload_ThroughDerivedVariable_DispatchesToDerived()
    var
        Impl: Codeunit "LT SS IE Impl";
        Derived: Interface "LT SS IE Derived";
    begin
        Derived := Impl;
        Derived.SetValue('a', 'b', 2);
        if Derived.GetValue() <> 'derived:ab:2' then
            Error('expected derived:ab:2 but was %1', Derived.GetValue());
    end;

    [Test]
    procedure BaseOverload_ThroughFunctionReturn_DispatchesToBase()
    var
        Impl: Codeunit "LT SS IE Impl";
        Factory: Interface "LT SS IE Factory";
    begin
        Factory := Impl;
        Factory.GetSetup().SetValue('f', 3);
        if Factory.GetSetup().GetValue() <> 'base:f:3' then
            Error('expected base:f:3 but was %1', Factory.GetSetup().GetValue());
        Factory.GetSetup().SetValue('f', 'g', 4);
        if Factory.GetSetup().GetValue() <> 'derived:fg:4' then
            Error('expected derived:fg:4 but was %1', Factory.GetSetup().GetValue());
    end;

    [Test]
    procedure BaseInterfaceVariable_Assigned_FromDerived_CallsBase()
    var
        Impl: Codeunit "LT SS IE Impl";
        Derived: Interface "LT SS IE Derived";
        Base: Interface "LT SS IE Base";
    begin
        Derived := Impl;
        Base := Derived;
        Base.SetValue('x', 5);
        if Base.GetValue() <> 'base:x:5' then
            Error('expected base:x:5 but was %1', Base.GetValue());
    end;
}
