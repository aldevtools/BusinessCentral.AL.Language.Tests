// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/interface/interface-data-type
// Scope: in-scope
// Fixtures used: "ALT Shape 04" (50004), "Interface State Kind" (60370), "Interface Impl Vendor" (60371)
//
/// <summary>
/// Regression proof: a codeunit obtained via an interface enum cast keeps its instance
/// var-record field alive for a later interface method call — the codeunit instance
/// backing the interface must not be torn down between the cast and the dispatch.
/// </summary>
codeunit 60372 "Test Interface CU StateField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure InterfaceMethod_ReadsInstanceVarRecordField_NoNre()
    var
        Provider: Interface "IInterface State Provider";
        Kind: Enum "Interface State Kind";
        Result: Text;
    begin
        Initialize();

        // [GIVEN] an enum value whose implementation owns an instance var-record field
        Kind := Kind::Vendor;

        // [WHEN] the enum is cast to the interface
        Provider := Kind;

        // [THEN] calling an interface method that touches that field does not NRE, and
        // returns the concrete value written to the surviving record field
        Result := Provider.GetProbedName();
        Assert.AreEqual('alive', Result,
            'Interface impl instance var-record field must survive the interface cast');
    end;

    [Test]
    procedure InterfaceMethod_WrongExpectation_Errors()
    var
        Provider: Interface "IInterface State Provider";
        Kind: Enum "Interface State Kind";
        Result: Text;
    begin
        Initialize();

        // [GIVEN] the same interface dispatch
        Kind := Kind::Vendor;
        Provider := Kind;
        Result := Provider.GetProbedName();

        // [WHEN] asserting a deliberately wrong value
        // [THEN] the assertion fails with a specific message (proves the assert is real)
        asserterror Assert.AreEqual('disposed', Result, 'forced mismatch');
        Assert.ExpectedError('Assert.AreEqual failed. Expected:<disposed>');
    end;

    local procedure Initialize()
    var
        StateRec: Record "ALT Shape 04";
    begin
        StateRec.DeleteAll();
    end;
}
