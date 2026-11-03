// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Composite (60001)
// BC versions: 27.0+
//
// CLAIM: outside upgrade/install, BC does not refuse DataTransfer as a whole — it
// discriminates three states and says which one it is:
//
//   * SetTables itself is NOT gated. It validates the pair and stages it, and is accepted
//     in ordinary test code.
//   * A staging or copying call made BEFORE SetTables is refused with
//     "SetTables must first be called before calling other methods on DataTransfer."
//   * A staging or copying call made AFTER SetTables is refused with
//     "DataTransfer is only usable during upgrade and installation code."
//
// Real, provable Cloud behavior. Codeunit 60875 next door already pins that CopyRows throws
// outside upgrade context; it wraps SetTables and CopyRows in ONE asserterror and asserts only
// that the message is non-empty, so it cannot tell which of the two threw, nor which message
// came back. These tests are what makes the distinction observable — which matters, because
// the two messages are the difference between "you forgot SetTables" and "you are in the wrong
// kind of code", and an implementation that answered either one for both cases would satisfy
// 60875 unchanged.
//
// WHY THE FIRST TEST CANNOT PASS AGAINST A NO-OP SetTables. It does not assert that SetTables
// returned; it asserts what the NEXT call reports. A SetTables that did nothing would leave the
// transfer unstaged, and BC would answer "SetTables must first be called ..." — the other
// message, which this test rejects.
codeunit 60992 "Test DataTransfer Contracts"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        OnlyDuringUpgradeErr: Label 'DataTransfer is only usable during upgrade and installation code.', Locked = true;
        SetTablesFirstErr: Label 'SetTables must first be called before calling other methods on DataTransfer.', Locked = true;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure SetTables_OutsideUpgrade_IsAccepted_AndIsObservedByTheNextCall()
    var
        DT: DataTransfer;
    begin
        Initialize();

        // [WHEN] SetTables is called in ordinary test code — no upgrade, no install.
        // [THEN] It is accepted. An error here fails the test on the spot.
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        // [THEN] The next call reports the UPGRADE/INSTALL refusal, not the missing-SetTables
        // one — which is only possible if SetTables actually staged the pair above.
        asserterror DT.AddFieldValue(6, 4);
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;

    [Test]
    procedure AddFieldValue_BeforeSetTables_ReportsThatSetTablesComesFirst()
    var
        DT: DataTransfer;
    begin
        Initialize();

        asserterror DT.AddFieldValue(6, 4);
        Assert.ExpectedError(SetTablesFirstErr);
    end;

    [Test]
    procedure CopyRows_BeforeSetTables_ReportsThatSetTablesComesFirst()
    var
        DT: DataTransfer;
    begin
        Initialize();

        asserterror DT.CopyRows();
        Assert.ExpectedError(SetTablesFirstErr);
    end;

    [Test]
    procedure AddConstantValue_AfterSetTables_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        asserterror DT.AddConstantValue('staged', 4);
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;

    [Test]
    procedure AddSourceFilter_AfterSetTables_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        asserterror DT.AddSourceFilter(3, '=%1', 5);
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;

    [Test]
    procedure AddJoin_AfterSetTables_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        asserterror DT.AddJoin(1, 1);
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;

    [Test]
    procedure CopyFields_AfterSetTables_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        asserterror DT.CopyFields();
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;

    [Test]
    procedure CopyRows_AfterSetTables_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");

        asserterror DT.CopyRows();
        Assert.ExpectedError(OnlyDuringUpgradeErr);
    end;
}
