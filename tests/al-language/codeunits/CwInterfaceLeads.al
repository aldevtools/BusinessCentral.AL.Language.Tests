// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-procedure-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enums 85420, 85424, 85427, codeunits 85421-85423, 85425, 85426, 85428,
//   test codeunit 85429
// Probe: corpus #670 items 61, 63, 64, 65, 67 (writer CW). Facts:
//   - overloads P(Option) and P(Enum): which one an integer literal, an Integer, an Option and an Enum argument select (it compiles);
//   - an enum with DefaultImplementation = I = A and a value with Implementation = I = B: which codeunit runs (it compiles; listing the
//     same interface twice in one property is AL0675, must-not-compile cases 1777 and 1778);
//   - an interface member with an Option parameter and an Option return value (it compiles; old report AL0582);
//   - two overloads SelectInterface(var A: Interface One) and SelectInterface(var B: Interface Two), both interfaces implemented by
//     one enum (old report: a C# name clash at publish);
//   - Enum against Option and Integer: =, <, >, in.
// Results: an integer literal and an Integer select the Option overload (no ambiguity); the value's Implementation wins over
//   DefaultImplementation, a value without one gets the default; an undeclared ordinal does NOT get the default: the cast fails with
//   'Enum does not contain value 7.' / ArgumentOutOfRange; Option parameters and returns pass through the interface; both
//   SelectInterface overloads publish and run; Enum compares with Option and Integer by ordinal (=, <, >, in).
// BC versions: 27, 28, 29

enum 85420 "LT CW Kind"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
}

codeunit 85421 "LT CW Overloads"
{
    procedure P(O: Option A,B,C): Text
    begin
        exit('option ' + Format(O, 0, 2));
    end;

    procedure P(E: Enum "LT CW Kind"): Text
    begin
        exit('enum ' + Format(E.AsInteger()));
    end;
}

interface "LT CW I63"
{
    procedure Work(): Text;
}

codeunit 85422 "LT CW Impl A" implements "LT CW I63"
{
    procedure Work(): Text
    begin
        exit('A');
    end;
}

codeunit 85423 "LT CW Impl B" implements "LT CW I63"
{
    procedure Work(): Text
    begin
        exit('B');
    end;
}

enum 85424 "LT CW E63" implements "LT CW I63"
{
    Extensible = true;
    DefaultImplementation = "LT CW I63" = "LT CW Impl A";

    value(0; WithOwn) { Implementation = "LT CW I63" = "LT CW Impl B"; }
    value(1; WithDefault) { }
}

interface "LT CW I64"
{
    procedure Take(MyParam: Option): Text;
    procedure GetOptionValue(): Option;
    procedure Named(P: Option A,B,C): Option X,Y,Z;
}

codeunit 85425 "LT CW Impl 64" implements "LT CW I64"
{
    procedure Take(MyParam: Option): Text
    begin
        exit(Format(MyParam) + '|' + Format(MyParam, 0, 2));
    end;

    procedure GetOptionValue(): Option
    begin
        exit(2);
    end;

    procedure Named(P: Option A,B,C): Option X,Y,Z
    begin
        exit(P);
    end;
}

interface "LT CW I65 One"
{
    procedure A(): Text;
}

interface "LT CW I65 Two"
{
    procedure B(): Text;
}

codeunit 85426 "LT CW Impl 65" implements "LT CW I65 One", "LT CW I65 Two"
{
    procedure A(): Text
    begin
        exit('A');
    end;

    procedure B(): Text
    begin
        exit('B');
    end;
}

enum 85427 "LT CW E65" implements "LT CW I65 One", "LT CW I65 Two"
{
    Extensible = true;
    value(0; Both) { Implementation = "LT CW I65 One" = "LT CW Impl 65", "LT CW I65 Two" = "LT CW Impl 65"; }
}

codeunit 85428 "LT CW Select"
{
    procedure SelectInterface(var A: Interface "LT CW I65 One"): Text
    begin
        exit('one ' + A.A());
    end;

    procedure SelectInterface(var B: Interface "LT CW I65 Two"): Text
    begin
        exit('two ' + B.B());
    end;
}

codeunit 85429 "LT CW Interface Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CW_Overload_OptionVsEnum()
    var
        Observer: Codeunit "Probe Observer";
        Ov: Codeunit "LT CW Overloads";
        O: Option A,B,C;
        E: Enum "LT CW Kind";
        I: Integer;
    begin
        O := O::B;
        E := E::Two;
        I := 2;
        Observer.Observe('literal', Ov.P(1));
        Observer.Observe('integer', Ov.P(I));
        Observer.Observe('option', Ov.P(O));
        Observer.Observe('option literal', Ov.P(O::C));
        Observer.Observe('enum', Ov.P(E));
        Observer.Observe('enum literal', Ov.P(E::One));
        Observer.Expect('literal', 'option 1');
        Observer.Expect('integer', 'option 2');
        Observer.Expect('option', 'option 1');
        Observer.Expect('option literal', 'option 2');
        Observer.Expect('enum', 'enum 2');
        Observer.Expect('enum literal', 'enum 1');
        Observer.Verify();
    end;

    [Test]
    procedure CW_EnumDefaultAndValueImplementation()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT CW E63";
        I: Interface "LT CW I63";
    begin
        E := E::WithOwn;
        I := E;
        Observer.Observe('value with own', I.Work());
        E := E::WithDefault;
        I := E;
        Observer.Observe('value without own', I.Work());
        E := Enum::"LT CW E63".FromInteger(7);
        Observer.Observe('undeclared ordinal', Format(E.AsInteger()));
        asserterror I := E;
        Observer.ObserveError('undeclared ordinal to interface');
        Observer.Expect('value with own', 'B');
        Observer.Expect('value without own', 'A');
        Observer.Expect('undeclared ordinal', '7');
        Observer.Expect('undeclared ordinal to interface|text', 'Enum does not contain value 7.');
        Observer.Expect('undeclared ordinal to interface|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure CW_InterfaceOptionParameterAndReturn()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "LT CW Impl 64";
        I: Interface "LT CW I64";
        O: Option A,B,C;
        R: Option X,Y,Z;
        N: Integer;
    begin
        I := Impl;
        O := O::C;
        Observer.Observe('take option', I.Take(O));
        Observer.Observe('take integer', I.Take(1));
        N := I.GetOptionValue();
        Observer.Observe('return option', Format(N));
        R := I.Named(O::B);
        Observer.Observe('named', Format(R) + '|' + Format(R, 0, 2));
        Observer.Expect('take option', '2|2');
        Observer.Expect('take integer', '1|1');
        Observer.Expect('return option', '2');
        Observer.Expect('named', 'Y|1');
        Observer.Verify();
    end;

    [Test]
    procedure CW_InterfaceOverloadsSameEnum()
    var
        Observer: Codeunit "Probe Observer";
        Sel: Codeunit "LT CW Select";
        One: Interface "LT CW I65 One";
        Two: Interface "LT CW I65 Two";
        E: Enum "LT CW E65";
    begin
        One := E;
        Two := E;
        Observer.Observe('one', Sel.SelectInterface(One));
        Observer.Observe('two', Sel.SelectInterface(Two));
        Observer.Expect('one', 'one A');
        Observer.Expect('two', 'two B');
        Observer.Verify();
    end;

    [Test]
    procedure CW_EnumAgainstOptionAndInteger()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT CW Kind";
        O: Option Zero,One,Two;
        I: Integer;
    begin
        E := E::One;
        O := O::One;
        I := 1;
        Observer.Observe('E = O', Format(E = O));
        Observer.Observe('O = E', Format(O = E));
        Observer.Observe('E = I', Format(E = I));
        Observer.Observe('I = E', Format(I = E));
        O := O::Two;
        I := 2;
        Observer.Observe('E < O', Format(E < O));
        Observer.Observe('O > E', Format(O > E));
        Observer.Observe('E < I', Format(E < I));
        Observer.Observe('I > E', Format(I > E));
        Observer.Observe('E in [O, I]', Format(E in [O, I]));
        Observer.Observe('E in [O, 1]', Format(E in [O, 1]));
        Observer.Expect('E = O', 'Yes');
        Observer.Expect('O = E', 'Yes');
        Observer.Expect('E = I', 'Yes');
        Observer.Expect('I = E', 'Yes');
        Observer.Expect('E < O', 'Yes');
        Observer.Expect('O > E', 'Yes');
        Observer.Expect('E < I', 'Yes');
        Observer.Expect('I > E', 'Yes');
        Observer.Expect('E in [O, I]', 'No');
        Observer.Expect('E in [O, 1]', 'Yes');
        Observer.Verify();
    end;
}
