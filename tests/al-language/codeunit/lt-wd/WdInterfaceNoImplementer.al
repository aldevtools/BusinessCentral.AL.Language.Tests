// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90710-90719
// Probe: written against al-runner issue 6299 (a procedure holding a call on an interface that no codeunit implements); every value asserted below is what the BC service tier produced.
// Facts: (1) an extending interface with no implementing codeunit: "Step is Ext" is false, the call behind the guard never runs, the rest of the procedure runs.
//        (2) an extensible enum that implements an interface and has no values: Ordinals() and Names() are empty, a foreach over them never runs the interface call.
// BC versions: 27, 28, 29

interface "LT WD IStep"
{
    procedure Name(): Text
}

// Optional capability: no codeunit implements it.
interface "LT WD IStepValidation" extends "LT WD IStep"
{
    procedure Validate(): Boolean
}

enum 90712 "LT WD Step Kind" implements "LT WD IStep"
{
    Extensible = false;

    value(0; Plain) { Implementation = "LT WD IStep" = "LT WD Plain Step"; }
}

codeunit 90713 "LT WD Plain Step" implements "LT WD IStep"
{
    procedure Name(): Text
    begin
        exit('plain');
    end;
}

interface "LT WD IScenario"
{
    procedure Description(): Text
}

// Values would come from enumextensions in other apps; none exists here.
enum 90715 "LT WD Scenario" implements "LT WD IScenario"
{
    Extensible = true;
}

codeunit 90716 "LT WD Interface Runner"
{
    procedure RunStep(Kind: Enum "LT WD Step Kind"; var IsValidation: Boolean): Text
    var
        Step: Interface "LT WD IStep";
        Validation: Interface "LT WD IStepValidation";
    begin
        Step := Kind;
        IsValidation := Step is "LT WD IStepValidation";
        if Step is "LT WD IStepValidation" then begin
            Validation := Step as "LT WD IStepValidation";
            Validation.Validate();
        end;
        exit(Step.Name());
    end;

    procedure CountScenarios(): Integer
    var
        Scenario: Enum "LT WD Scenario";
        Provider: Interface "LT WD IScenario";
        Descriptions: List of [Text];
    begin
        foreach Scenario in Enum::"LT WD Scenario".Ordinals() do begin
            Provider := Scenario;
            Descriptions.Add(Provider.Description());
        end;
        exit(Descriptions.Count());
    end;
}

codeunit 90717 "LT WD Interface No Impl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_Interface_IsGuardWithoutImplementer()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT WD Interface Runner";
        Kind: Enum "LT WD Step Kind";
        IsValidation: Boolean;
    begin
        Observer.Observe('RunStep', Runner.RunStep(Kind::Plain, IsValidation));
        Observer.Observe('is validation', Format(IsValidation));
        Observer.Finish();
    end;

    [Test]
    procedure WD_Interface_EmptyExtensibleEnum()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT WD Interface Runner";
        Scenario: Enum "LT WD Scenario";
    begin
        Observer.Observe('CountScenarios', Format(Runner.CountScenarios()));
        Observer.Observe('Ordinals count', Format(Scenario.Ordinals().Count()));
        Observer.Observe('Names count', Format(Scenario.Names().Count()));
        Observer.Finish();
    end;
}
