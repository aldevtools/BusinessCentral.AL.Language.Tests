// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 85430-85434, enum 85435, test codeunit 85436
// Probe: corpus #670 item 68 (writer CW). Default interface methods (an interface member with a body) exist from runtime 18.0 (BC 29);
//   runtime 17.1 and earlier refuse the body (must-not-compile case 0325), so the whole file is BC29PLUS. Facts:
//   - a codeunit that does not declare the member gets the default body; one that declares it runs its own;
//   - an internal procedure of the same name gives warning AL0920 ("cannot be used as the implementation ... because it is not
//     public"): which body runs. A local one gives no diagnostic; calling the member through the interface then failed on the Linux
//     tier with "Function ID -18053879 was called. The object with ID 85433 does not have a member with that ID." (not asserted: queued
//     for the Windows check, see ~/.cache/al-runtime/orchestration/windows-queue.md); here only the codeunit's own call is asserted;
//   - an internal procedure that implements a required member (AL0920 warning only): what runs;
//   - a default body that calls another member of the interface;
//   - the default reached through an enum's Implementation.
//   Compile errors: Scope attribute on an interface member (AL0187 + AL0919, case 1779), calling an inherited default on a codeunit
//   variable (AL0132, case 1780), OnPrem-scope override of a default member (AL0922, case 1781).
// Results: the default body runs when the codeunit does not declare the member, and a default body calls the implementor's Req;
//   internal procedures (AL0920 warning) still run as the implementation, for a default member and for a required one.
// BC versions: 29
#if BC29PLUS

interface "LT CW I68"
{
    procedure Req(): Text;

    procedure Opt(): Text
    begin
        exit('default');
    end;

    procedure Chain(): Text
    begin
        exit('default chain of ' + Req());
    end;
}

interface "LT CW I68 Req"
{
    procedure Req(): Text;
}

codeunit 85430 "LT CW Impl68 Inherit" implements "LT CW I68"
{
    procedure Req(): Text
    begin
        exit('inherit req');
    end;
}

codeunit 85431 "LT CW Impl68 Override" implements "LT CW I68"
{
    procedure Req(): Text
    begin
        exit('override req');
    end;

    procedure Opt(): Text
    begin
        exit('override opt');
    end;

    procedure Chain(): Text
    begin
        exit('override chain');
    end;
}

codeunit 85432 "LT CW Impl68 Internal" implements "LT CW I68", "LT CW I68 Req"
{
    // AL0920 warning on both procedures (not public).
    internal procedure Req(): Text
    begin
        exit('internal req');
    end;

    internal procedure Opt(): Text
    begin
        exit('internal opt');
    end;
}

codeunit 85433 "LT CW Impl68 Local" implements "LT CW I68"
{
    procedure Req(): Text
    begin
        exit('local req');
    end;

    local procedure Opt(): Text
    begin
        exit('local opt');
    end;

    procedure CallOwnOpt(): Text
    begin
        exit(Opt());
    end;
}

enum 85435 "LT CW E68" implements "LT CW I68"
{
    Extensible = true;
    value(0; Inherit) { Implementation = "LT CW I68" = "LT CW Impl68 Inherit"; }
    value(1; Override) { Implementation = "LT CW I68" = "LT CW Impl68 Override"; }
}

codeunit 85436 "LT CW Default Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CW_Default_InheritAndOverride()
    var
        Observer: Codeunit "Probe Observer";
        Inh: Codeunit "LT CW Impl68 Inherit";
        Ovr: Codeunit "LT CW Impl68 Override";
        I: Interface "LT CW I68";
    begin
        I := Inh;
        Observer.Observe('inherit opt', I.Opt());
        Observer.Observe('inherit chain', I.Chain());
        I := Ovr;
        Observer.Observe('override opt', I.Opt());
        Observer.Observe('override chain', I.Chain());
        Observer.Observe('override direct', Ovr.Opt());
        Observer.Expect('inherit opt', 'default');
        Observer.Expect('inherit chain', 'default chain of inherit req');
        Observer.Expect('override opt', 'override opt');
        Observer.Expect('override chain', 'override chain');
        Observer.Expect('override direct', 'override opt');
        Observer.Verify();
    end;

    [Test]
    procedure CW_Default_NonPublicImplementations()
    var
        Observer: Codeunit "Probe Observer";
        Intl: Codeunit "LT CW Impl68 Internal";
        Loc: Codeunit "LT CW Impl68 Local";
        I: Interface "LT CW I68";
        R: Interface "LT CW I68 Req";
    begin
        I := Intl;
        Observer.Observe('internal req', I.Req());
        Observer.Observe('internal opt', I.Opt());
        Observer.Observe('internal chain', I.Chain());
        R := Intl;
        Observer.Observe('internal req only', R.Req());
        Observer.Observe('local own call', Loc.CallOwnOpt());
        Observer.Expect('internal req', 'internal req');
        Observer.Expect('internal opt', 'internal opt');
        Observer.Expect('internal chain', 'default chain of internal req');
        Observer.Expect('internal req only', 'internal req');
        Observer.Expect('local own call', 'local opt');
        Observer.Verify();
    end;

    [Test]
    procedure CW_Default_ThroughEnum()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT CW E68";
        I: Interface "LT CW I68";
    begin
        E := E::Inherit;
        I := E;
        Observer.Observe('enum inherit', I.Opt() + '|' + I.Chain());
        E := E::Override;
        I := E;
        Observer.Observe('enum override', I.Opt() + '|' + I.Chain());
        Observer.Observe('is', Format(I is "LT CW I68"));
        Observer.Expect('enum inherit', 'default|default chain of inherit req');
        Observer.Expect('enum override', 'override opt|override chain');
        Observer.Expect('is', 'Yes');
        Observer.Verify();
    end;
}
#endif
