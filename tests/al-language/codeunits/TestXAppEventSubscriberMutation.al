// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: "ALT XApp Mut Probe" (table 61090, in the AL Internals Test Fixture app),
// "ALT XApp Mut Subscriber" (67460)
// Note: cross-app version of TestCodeunitEventSubscriberMutation. The publisher table is
// defined in a dependency app and the subscriber that mutates var Rec is in the dependent app.
// BC versions: 24+

codeunit 67461 "Test XApp Ev Sub Mutation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Validate_CrossAppSubscriberMutation_Propagates()
    var
        Rec: Record "ALT XApp Mut Probe";
    begin
        Initialize();
        Rec.Init();
        Rec."No." := 'X1';
        Rec."Target Field" := '';

        Rec.Validate("Trigger Field", 'X');

        Assert.AreEqual('MUTATED:X', Rec."Target Field",
            'A subscriber in a dependent app must see its var Rec write propagate to the validated record');
    end;

    [Test]
    procedure Validate_CrossApp_FieldWithoutSubscriber_LeavesTargetUntouched()
    var
        Rec: Record "ALT XApp Mut Probe";
    begin
        Initialize();
        Rec.Init();
        Rec."No." := 'X2';
        Rec."Target Field" := 'KEEP';

        Rec.Validate("No.", 'X2');

        Assert.AreEqual('KEEP', Rec."Target Field",
            'Validating a field with no subscriber must leave Target Field unchanged');
    end;

    local procedure Initialize()
    var
        Rec: Record "ALT XApp Mut Probe";
    begin
        Rec.DeleteAll();
    end;
}
