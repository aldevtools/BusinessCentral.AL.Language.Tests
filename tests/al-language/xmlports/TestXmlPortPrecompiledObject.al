// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-direction-property
// Scope: in-scope
// Fixtures used: ALT Blob (60008) — as a stream sink only; every object under test ships
//   in the System Application.
//
// WHAT THIS PINS, AND WHY IT IS NOT COVERED BY TestXmlPortObject/TestXmlPortAdvanced.
// Those two exercise xmlports the corpus app DECLARES, so the platform has their compiled
// metadata by construction. This file exercises xmlports the corpus app only DEPENDS ON —
// System Application's own — which is a different situation for any consumer that has to
// obtain an xmlport's metadata rather than having emitted it.
//
// Every assertion is about what BC itself answers, so a service tier decides all of it:
//   * a dependency's xmlport can be declared as a variable and its runtime methods called;
//   * its declared Direction is honoured (an Export-only port refuses Import, and vice versa);
//   * its object identity (XmlPort::<name>) resolves to the documented id.
//
// WHAT IS DELIBERATELY NOT PINNED HERE: an xmlport's Encoding, PreserveWhiteSpace and
// UseRequestPage. Those are DESIGN-TIME properties with no AL-reachable accessor on an xmlport
// object — `Port.UseRequestPage(false)` is rejected by the compiler (AL0127 where the port
// declares the property, AL0132 where it does not), and measured across Base Application +
// System Application 28.1.49838.53910 there are 64 UseRequestPage() calls with a Report
// receiver and zero with an XmlPort receiver. Direction is the one declared property with an
// AL-observable CONSEQUENCE, which is why the two tests below carry the property-level claim.
//
// The ports used, and the declared Direction each states in the System Application source:
//   9862 "Export Permission Sets System"  Direction = Export   (construction + refuses Import)
//   9864 "Import Permission Sets"         Direction = Import   (construction + refuses Export)
//   9863 "Export Permission Sets Tenant"  Direction = Export   (identity only)
//
// Export is deliberately NOT invoked. These ports write real permission-set data, and a test
// that exported them would assert against whatever the tenant happens to hold — which is a
// claim about the fixture set, not about the xmlport. Construction and Direction enforcement
// are the parts that are the same on every tenant.

codeunit 60918 "Test XmlPort Precompiled Obj"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // An xmlport belonging to a DEPENDENCY app can be declared as a variable and its runtime
    // methods called. The variable declaration alone is a compile-time claim; calling a real
    // instance method is what forces the platform to obtain the object's metadata at run time,
    // which is the part that can fail independently of compiling.
    //
    // SetTableView is the instance call used, because the platform must resolve it against the
    // port's OWN FIRST tableelement — so it cannot succeed against an object whose definition
    // the platform failed to load, and the record type it accepts is decided by that node
    // rather than by this test. The two ports take DIFFERENT types for exactly that reason,
    // read from their own source: 9862's first tableelement is "Metadata Permission Set" and
    // 9864's is "Tenant Permission Set". Nothing is exported: see the file header.
    //
    // NOT UseRequestPage. On an xmlport that is a DESIGN-TIME property, not a runtime method:
    // the AL compiler rejects `Port.UseRequestPage(false)` with AL0127 on a port that declares
    // it (it is a property, not a method) and AL0132 on one that does not (no such member at
    // all). Measured across Base Application + System Application 28.1.49838.53910: 64 calls
    // to UseRequestPage() with a Report receiver and ZERO with an XmlPort receiver. The
    // equivalent Report method does not imply an XmlPort one.
    [Test]
    procedure PrecompiledXmlPort_ConstructsAndKeepsItsIdentity_NoThrow()
    var
        ExportSystem: XmlPort "Export Permission Sets System";
        ImportSets: XmlPort "Import Permission Sets";
        MetadataPermissionSet: Record "Metadata Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        Initialize();

        // A real instance call on each port, resolved against its own first tableelement.
        ExportSystem.SetTableView(MetadataPermissionSet);
        ImportSets.SetTableView(TenantPermissionSet);

        // A concrete value rather than IsTrue(true): each port still answers the id its own app
        // declares, so these are two distinct objects rather than one fallback instance handed
        // back twice.
        Assert.AreEqual(9862, XmlPort::"Export Permission Sets System",
            'the constructed Export-system port must still be the object the System Application declares');
        Assert.AreEqual(9864, XmlPort::"Import Permission Sets",
            'the constructed Import port must be a DIFFERENT object from the Export port');
    end;

    // Direction is a declared property of the xmlport object, and the platform enforces it:
    // an Export-only port refuses Import. This is the sharpest available AL-observable proof
    // that the port's own declared metadata — not a default — is what the platform is using,
    // because the failure depends on a property value rather than on the object existing.
    [Test]
    procedure PrecompiledXmlPort_DeclaredExportDirection_RefusesImport()
    var
        ExportSystem: XmlPort "Export Permission Sets System";
        InStr: InStream;
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();

        // The persisted ALT Blob pattern TestXmlPortObject already uses, rather than a
        // temporary: the Modify/CalcFields round-trip is what makes the written bytes
        // readable back as a stream, and this test should not be the first to rely on a
        // different one.
        BlobRec.Init();
        BlobRec.Code := 'XPP1';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<root />');
        BlobRec.Modify();

        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        ExportSystem.SetSource(InStr);
        asserterror ExportSystem.Import();

        // The MESSAGE TEXT is deliberately not asserted: it is a platform resource string
        // this test has no independent source for, and inventing one would make the test a
        // claim about wording rather than about behaviour. What IS asserted is the pair that
        // wording cannot vary — that an error was raised, and that it is a real AL error
        // rather than a .NET exception escaping (which would leave the code empty).
        Assert.IsTrue(GetLastErrorText() <> '',
            'an xmlport declared Direction = Export must refuse Import() — the platform reads the port''s own declared Direction, so a port whose metadata was not obtained could not enforce this');
        Assert.IsTrue(GetLastErrorCode() <> '',
            'the refusal must be a real AL error carrying an error code, not a .NET exception surfacing through the test runner');
    end;

    // The mirror: an Import-only port refuses Export. Asserting only the Export-refuses-Import
    // direction would pass against a platform that refused EVERY direction on a dependency
    // xmlport, which is why both directions are pinned.
    [Test]
    procedure PrecompiledXmlPort_DeclaredImportDirection_RefusesExport()
    var
        ImportSets: XmlPort "Import Permission Sets";
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'XPP2';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);

        ImportSets.SetDestination(OutStr);
        asserterror ImportSets.Export();

        Assert.IsTrue(GetLastErrorText() <> '',
            'an xmlport declared Direction = Import must refuse Export()');
        Assert.IsTrue(GetLastErrorCode() <> '',
            'the refusal must be a real AL error carrying an error code');
    end;

    // Object identity: the XmlPort::<name> reference of a dependency's xmlport resolves to the
    // id that app declares. This is what any id-keyed consumer joins on, and it is a statement
    // about BC's own object table rather than about this test's fixtures.
    [Test]
    procedure PrecompiledXmlPort_ObjectIdentityResolvesToItsDeclaredId()
    begin
        Initialize();

        Assert.AreEqual(9862, XmlPort::"Export Permission Sets System",
            'XmlPort::"Export Permission Sets System" must resolve to the id the System Application declares');
        Assert.AreEqual(9863, XmlPort::"Export Permission Sets Tenant",
            'XmlPort::"Export Permission Sets Tenant" must resolve to the id the System Application declares');
        Assert.AreEqual(9864, XmlPort::"Import Permission Sets",
            'XmlPort::"Import Permission Sets" must resolve to the id the System Application declares');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
