// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained interfaces and codeunits below
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins `is` and `as` on interface variables: `is` answers false (not an error) for an interface the
// instance does not implement and for an unassigned variable; `as` to an interface the instance does not
// implement, or on an unassigned variable, raises "The expression cannot be the target interface." with
// code UnableToCast.
// BC versions: 27.5

interface "Probe IA"
{
    procedure A(): Text;
}

interface "Probe IB"
{
    procedure B(): Text;
}

codeunit 68322 "Probe Impl A" implements "Probe IA"
{
    procedure A(): Text
    begin
        exit('a');
    end;
}

codeunit 68323 "Probe Impl AB" implements "Probe IA", "Probe IB"
{
    procedure A(): Text
    begin
        exit('ab-a');
    end;

    procedure B(): Text
    begin
        exit('ab-b');
    end;
}

codeunit 68324 "Probe Interface Is As"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Is_ReportsWhetherTheInstanceImplementsTheInterface()
    var
        IA: Interface "Probe IA";
        ImplA: Codeunit "Probe Impl A";
        ImplAB: Codeunit "Probe Impl AB";
    begin
        IA := ImplA;
        Assert.IsTrue(IA is "Probe IA", 'ImplA is IA');
        Assert.IsFalse(IA is "Probe IB", 'ImplA is not IB');

        IA := ImplAB;
        Assert.IsTrue(IA is "Probe IB", 'ImplAB is IB');
    end;

    [Test]
    procedure As_ToAnImplementedInterface_Works_ToAnotherOne_Throws()
    var
        IA: Interface "Probe IA";
        IB: Interface "Probe IB";
        ImplA: Codeunit "Probe Impl A";
        ImplAB: Codeunit "Probe Impl AB";
    begin
        IA := ImplAB;
        IB := IA as "Probe IB";
        Assert.AreEqual('ab-b', IB.B(), 'as to an implemented interface');

        IA := ImplA;
        asserterror IB := IA as "Probe IB";
        Assert.AreEqual('The expression cannot be the target interface.', GetLastErrorText(), 'text');
        Assert.AreEqual('UnableToCast', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure UnassignedInterface_Is_IsFalse_As_Throws()
    var
        Unassigned: Interface "Probe IA";
        IA: Interface "Probe IA";
        IB: Interface "Probe IB";
    begin
        Assert.IsFalse(Unassigned is "Probe IA", 'is the interface itself');
        Assert.IsFalse(Unassigned is "Probe IB", 'is another interface');

        asserterror IB := Unassigned as "Probe IB";
        Assert.AreEqual('The expression cannot be the target interface.', GetLastErrorText(), 'as another interface');
        Assert.AreEqual('UnableToCast', GetLastErrorCode(), 'code');

        asserterror IA := Unassigned as "Probe IA";
        Assert.AreEqual('The expression cannot be the target interface.', GetLastErrorText(), 'as the interface itself');
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 7800): a method called directly on an `as` expression, (IA as "Probe IB").B(),
    // without a variable in between, and on `as` to the interface the variable already has.
    [Test]
    procedure As_InlineMethodCallOnTheCast_BP()
    var
        ImplAB: Codeunit "Probe Impl AB";
        IA: Interface "Probe IA";
    begin
        IA := ImplAB;
        Assert.AreEqual('ab-b', (IA as "Probe IB").B(), 'a method called on the as expression runs on the instance');
        Assert.AreEqual('ab-a', (IA as "Probe IA").A(), 'as to the declared interface of the variable');
    end;
}
