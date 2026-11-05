// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 95320-95321, test codeunit 95322
// Probe: al-runner issue 6924 (Microsoft's PEPPOL Tax Info Provider, BC 29, calls `this.GetTaxExemptionReason(..)` in a
//   default body). Default interface methods exist from runtime 18.0 (BC 29), so the whole file is BC29PLUS. Facts:
//   - `this.Member()` in a default body calls the member of the implementing codeunit the body runs on;
//   - `this.Member()` that names another default member runs the codeunit's own override when it has one, else the default;
//   - `this.Overload(..)` picks the overload by its arguments (a default overload that hands on to the required one).
// Results: asserted values are what the implementing codeunits return; checked by the corpus CI on BC 29.
// BC versions: 29
#if BC29PLUS

interface "LT R6924d I"
{
    procedure Req(): Text;

    procedure Twice(): Text
    begin
        exit(this.Req() + '+' + this.Req());
    end;

    procedure Chain(): Text
    begin
        exit('chain ' + this.Twice());
    end;

    procedure Get(A: Text): Text;

    procedure Get(A: Text; B: Text): Text
    begin
        exit(this.Get(A + B));
    end;
}

codeunit 95320 "LT R6924d Inherit" implements "LT R6924d I"
{
    procedure Req(): Text
    begin
        exit('inh');
    end;

    procedure Get(A: Text): Text
    begin
        exit('inh get ' + A);
    end;
}

codeunit 95321 "LT R6924d Override" implements "LT R6924d I"
{
    procedure Req(): Text
    begin
        exit('ovr');
    end;

    procedure Twice(): Text
    begin
        exit('ovr twice');
    end;

    procedure Get(A: Text): Text
    begin
        exit('ovr get ' + A);
    end;
}

codeunit 95322 "LT R6924d This Default"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R6924d_This_CallsImplementor()
    var
        Observer: Codeunit "Probe Observer";
        Inh: Codeunit "LT R6924d Inherit";
        Ovr: Codeunit "LT R6924d Override";
        I: Interface "LT R6924d I";
    begin
        I := Inh;
        Observer.Observe('inherit twice', I.Twice());
        Observer.Observe('inherit chain', I.Chain());
        I := Ovr;
        Observer.Observe('override twice', I.Twice());
        Observer.Observe('override chain', I.Chain());
        Observer.Expect('inherit twice', 'inh+inh');
        Observer.Expect('inherit chain', 'chain inh+inh');
        Observer.Expect('override twice', 'ovr twice');
        Observer.Expect('override chain', 'chain ovr twice');
        Observer.Verify();
    end;

    [Test]
    procedure R6924d_This_Overload()
    var
        Observer: Codeunit "Probe Observer";
        Inh: Codeunit "LT R6924d Inherit";
        Ovr: Codeunit "LT R6924d Override";
        I: Interface "LT R6924d I";
    begin
        I := Inh;
        Observer.Observe('inherit two args', I.Get('a', 'b'));
        Observer.Observe('inherit one arg', I.Get('c'));
        I := Ovr;
        Observer.Observe('override two args', I.Get('a', 'b'));
        Observer.Expect('inherit two args', 'inh get ab');
        Observer.Expect('inherit one arg', 'inh get c');
        Observer.Expect('override two args', 'ovr get ab');
        Observer.Verify();
    end;
}
#endif
