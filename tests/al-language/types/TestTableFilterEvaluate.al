// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT TableFilter Holder, ALT TF Plain Target;
//   ALTFixtureCleanup and Probe Observer from the shared fixture library.
// BC versions: measured and verified on 27.5, 28.5 and 29.0.
// Builds: 27.5.46862.52969 US; 28.5.54151.57057 W1; 29.0.54011.55816 W1.
// Observation: BC29 with AL18; assertion verification: CI compiler 30.0.43.45776-beta.
// Hosts: disposable BC-on-Linux service tiers; default English sessions.
// Probe: expectations generated from real BC29 observations with corpus-writer/convert.py.
// Facts: numeric field-ID normalization; preservation after invalid option/field; clearing a seeded value.
// Complements the accepted/rejected/statement/storage forms in corpus PR #751.

codeunit 67026 "TableFilter Evaluate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableFilter_Evaluate_NumericIds_NormalizesValue()
    var
        Holder: Record "ALT TableFilter Holder";
        Observer: Codeunit "Probe Observer";
        Succeeded: Boolean;
    begin
        Initialize();
        ClearLastError();
        Succeeded := Evaluate(Holder."Filter Value", '67021: 2=1');
        Observer.Observe('succeeded', Format(Succeeded));
        Observer.Observe('value', Format(Holder."Filter Value"));
        Observer.Observe('xml-value', Format(Holder."Filter Value", 0, 9));
        Observer.ObserveError('last-error');
        Observer.Expect('succeeded', 'Yes');
        Observer.Expect('value', 'ALT TF Plain Target: Report Type=LGDIAM');
        Observer.Expect('xml-value', 'ALT TF Plain Target: Report Type=LGDIAM');
        Observer.Expect('last-error|text', '');
        Observer.Expect('last-error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_InvalidOption_PreservesValue()
    var
        Holder: Record "ALT TableFilter Holder";
        Observer: Codeunit "Probe Observer";
        Succeeded: Boolean;
    begin
        Initialize();
        Evaluate(Holder."Filter Value", 'ALT TF Plain Target: Report Type=DIAM');
        ClearLastError();
        Succeeded := Evaluate(Holder."Filter Value", 'ALT TF Plain Target: Report Type=BOGUS');
        Observer.Observe('succeeded', Format(Succeeded));
        Observer.Observe('value', Format(Holder."Filter Value"));
        Observer.Observe('xml-value', Format(Holder."Filter Value", 0, 9));
        Observer.ObserveError('last-error');
        Observer.Expect('succeeded', 'No');
        Observer.Expect('value', 'ALT TF Plain Target: Report Type=DIAM');
        Observer.Expect('xml-value', 'ALT TF Plain Target: Report Type=DIAM');
        Observer.Expect('last-error|text', 'The value "ALT TF Plain Target: Report Type=BOGUS" can''t be evaluated into type TableFilter. ''BOGUS'' is not an option. The existing options are: DIAM,LGDIAM');
        Observer.Expect('last-error|code', 'Evaluate:InvalidFilterExpression');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_InvalidField_PreservesValue()
    var
        Holder: Record "ALT TableFilter Holder";
        Observer: Codeunit "Probe Observer";
        Succeeded: Boolean;
    begin
        Initialize();
        Evaluate(Holder."Filter Value", 'ALT TF Plain Target: Report Type=DIAM');
        ClearLastError();
        Succeeded := Evaluate(Holder."Filter Value", 'ALT TF Plain Target: Missing=A');
        Observer.Observe('succeeded', Format(Succeeded));
        Observer.Observe('value', Format(Holder."Filter Value"));
        Observer.Observe('xml-value', Format(Holder."Filter Value", 0, 9));
        Observer.ObserveError('last-error');
        Observer.Expect('succeeded', 'No');
        Observer.Expect('value', 'ALT TF Plain Target: Report Type=DIAM');
        Observer.Expect('xml-value', 'ALT TF Plain Target: Report Type=DIAM');
        Observer.Expect('last-error|text', 'The value "ALT TF Plain Target: Missing=A" can''t be evaluated into type TableFilter. The supplied field number ''Missing'' cannot be found in the ''ALT TF Plain Target'' table.');
        Observer.Expect('last-error|code', 'Evaluate:FieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_EmptyInput_ClearsValue()
    var
        Holder: Record "ALT TableFilter Holder";
        Observer: Codeunit "Probe Observer";
        Succeeded: Boolean;
    begin
        Initialize();
        Evaluate(Holder."Filter Value", 'ALT TF Plain Target: Report Type=DIAM');
        ClearLastError();
        Succeeded := Evaluate(Holder."Filter Value", '');
        Observer.Observe('succeeded', Format(Succeeded));
        Observer.Observe('value', Format(Holder."Filter Value"));
        Observer.Observe('xml-value', Format(Holder."Filter Value", 0, 9));
        Observer.ObserveError('last-error');
        Observer.Expect('succeeded', 'Yes');
        Observer.Expect('value', '');
        Observer.Expect('xml-value', '');
        Observer.Expect('last-error|text', '');
        Observer.Expect('last-error|code', '');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    begin
        FixtureCleanup.Initialize();
    end;
}
