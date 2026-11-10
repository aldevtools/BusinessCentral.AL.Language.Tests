// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-applicationarea-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 93460 - 93461
// Probe: al-runner issue 7597. The assignment form of the ApplicationArea setter (`ApplicationArea := <text>`) next to the call form
//   (`ApplicationArea(<text>)`), each read back with ApplicationArea(): a literal, the append form, the call form, blank text, the
//   reporter's if/else shape, and the assignment in a procedure of another codeunit (the shape of a login subscriber's body). Each test
//   clears the application area at its end with the call form.
// Facts: the text ApplicationArea() returns after each form.
// Measured on BC 27.5, 28.5 and 29.0 (corpus CI runs 42852007063, 42852095520, 42852195813; identical): `ApplicationArea := <text>` sets
//   the application area exactly as `ApplicationArea(<text>)` does. ApplicationArea() reads back the assigned text unchanged ('#All,#Basic'
//   for the literal, the append and the call form), a blank assignment clears it, and the assignment in a procedure of another codeunit
//   changes the session's value the test reads.
// BC versions: 27, 28, 29
codeunit 93460 "LT AA Assign Setter"
{
    procedure AssignAreas(Areas: Text)
    begin
        ApplicationArea := Areas;
    end;

    procedure AddAreas(Areas: Text)
    begin
        if ApplicationArea() = '' then
            ApplicationArea := Areas
        else
            ApplicationArea := ApplicationArea() + ',' + Areas;
    end;
}

codeunit 93461 "LT AA Assign Form"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AA_Assign_Literal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ApplicationArea('');
        ApplicationArea := '#All,#Basic';
        Observer.Observe('literal', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('literal', '#All,#Basic');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Assign_Append()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ApplicationArea('#All');
        ApplicationArea := ApplicationArea() + ',#Basic';
        Observer.Observe('append', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('append', '#All,#Basic');
        Observer.Verify();
    end;

    [Test]
    procedure AA_CallForm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ApplicationArea('');
        ApplicationArea('#All,#Basic');
        Observer.Observe('call', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('call', '#All,#Basic');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Assign_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ApplicationArea('#All,#Basic');
        ApplicationArea := '';
        Observer.Observe('blank', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('blank', '');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Assign_InOtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Setter: Codeunit "LT AA Assign Setter";
    begin
        ApplicationArea('');
        Setter.AssignAreas('#Suite');
        Observer.Observe('other codeunit', ApplicationArea());
        ApplicationArea('');
        Setter.AddAreas('#All,#Basic,#Suite');
        Observer.Observe('add to blank', ApplicationArea());
        Setter.AddAreas('#Service');
        Observer.Observe('add to set', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('other codeunit', '#Suite');
        Observer.Expect('add to blank', '#All,#Basic,#Suite');
        Observer.Expect('add to set', '#All,#Basic,#Suite,#Service');
        Observer.Verify();
    end;
}
