// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Assert (60021); own objects below
// Facts: the last error that one [Test] method trapped does not reach the next [Test] method. A traps an error; B, declared next in
// the same codeunit, reads GetLastErrorText, GetLastErrorCode and GetLastErrorCallStack as its first statements and gets ''. The
// cross-codeunit form is "LT BH Last Error Next Codeunit" (81451): its only test reads the last error first, after the last test
// of this codeunit (C) trapped one, and gets ''.
// Measured: every assertion below holds on corpus CI BC 27.5, 28.5 and 29.0 (Linux, 2026-10-19) and on the Windows BC 28.4
// container (CI run 36806781933): the last error is cleared between test methods and between test codeunits.
// BC versions: 27.0 and later

codeunit 81450 "LT BH Last Error Across Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure A_TrapsAnError_LastErrorIsSetInsideTheTest()
    begin
        asserterror Error('LT BH carry A');
        Assert.AreEqual('LT BH carry A', GetLastErrorText(), 'the trapped error is the last error inside the test that trapped it');
    end;

    [Test]
    procedure B_NextTest_LastErrorIsEmpty()
    var
        LastText: Text;
        LastCode: Text;
        LastCallStack: Text;
    begin
        // Read first: nothing of this test may set or clear the last error before.
        LastText := GetLastErrorText();
        LastCode := GetLastErrorCode();
        LastCallStack := GetLastErrorCallStack();
        Assert.AreEqual('', LastText, 'GetLastErrorText at the start of the next test method');
        Assert.AreEqual('', LastCode, 'GetLastErrorCode at the start of the next test method');
        Assert.AreEqual('', LastCallStack, 'GetLastErrorCallStack at the start of the next test method');
    end;

    [Test]
    procedure C_TrapsAnErrorForTheNextCodeunit()
    begin
        asserterror Error('LT BH carry C');
        Assert.AreEqual('LT BH carry C', GetLastErrorText(), 'the trapped error is the last error inside the test that trapped it');
    end;
}

codeunit 81451 "LT BH Last Error Next Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FirstTest_LastErrorIsEmpty()
    var
        LastText: Text;
        LastCode: Text;
    begin
        // Read first: runs after C_TrapsAnErrorForTheNextCodeunit of codeunit 81450.
        LastText := GetLastErrorText();
        LastCode := GetLastErrorCode();
        Assert.AreEqual('', LastText, 'GetLastErrorText at the start of the first test method of the next codeunit');
        Assert.AreEqual('', LastCode, 'GetLastErrorCode at the start of the first test method of the next codeunit');
    end;
}
