// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-first-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT List Page (60016)

codeunit 60115 "Test Page Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── TestPage ───────────────────────────────────────────────────────

    [Test]
    procedure Page_TestPage_Open_FindsFirstRecord()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 99;
        Rec.Insert();
        ListPage.OpenView();
        Assert.IsTrue(ListPage.First(), 'TestPage must navigate to first record');
        Assert.AreEqual('1', ListPage."Entry No.".Value(), 'First record must be entry 1');
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestPage_First_ReturnsTrue_WhenRecordsExist()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 50;
        Rec.Insert();
        ListPage.OpenView();
        Assert.IsTrue(ListPage.First(), 'TestPage.First() must return true when records exist');
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestPage_Next_AdvancesToSecond()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 20;
        Rec.Insert();
        ListPage.OpenView();
        ListPage.First();
        ListPage.Next();
        Assert.AreEqual('2', ListPage."Entry No.".Value(), 'After Next(), current record must be entry 2');
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestPage_Last_ReturnsLastRecord()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 20;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 30;
        Rec.Insert();
        ListPage.OpenView();
        ListPage.Last();
        Assert.AreEqual('3', ListPage."Entry No.".Value(), 'After Last(), current record must be entry 3');
        ListPage.Close();
    end;

    [Test]
    procedure Page_TestPage_Close_DoesNotThrow()
    var
        ListPage: TestPage "ALT List Page";
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 5;
        Rec.Insert();
        ListPage.OpenView();
        ListPage.Close();
        Assert.IsTrue(true, 'TestPage.Close() must not throw');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
