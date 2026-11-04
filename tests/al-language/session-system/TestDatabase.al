// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60112 "Test Database"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Database Record Functions ────────────────────────────────────────────────

    [Test]
    procedure Database_Commit_DoesNotThrow()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();
        Assert.AreEqual(1, Rec.Count(), 'After Commit record must still exist in table');
    end;

    [Test]
    procedure Database_IsEmpty_EmptyTable_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsTrue(Rec.IsEmpty(), 'IsEmpty() must return true for empty table');
    end;

    [Test]
    procedure Database_IsEmpty_NonEmpty_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Assert.IsFalse(Rec.IsEmpty(), 'IsEmpty() must return false when table contains records');
    end;

    [Test]
    procedure Database_Count_AfterInsert_ReturnsOne()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Assert.AreEqual(1, Rec.Count(), 'Count() must return 1 after single insert');
    end;

    [Test]
    procedure Database_LockTable_DoesNotThrow()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.LockTable();
        Assert.IsTrue(true, 'LockTable() must not throw exception');
    end;

    [Test]
    procedure Database_CurrentCompany_MatchesCompanyName()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.AreEqual(CompanyName(), Rec.CurrentCompany(), 'CurrentCompany() must match CompanyName()');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
