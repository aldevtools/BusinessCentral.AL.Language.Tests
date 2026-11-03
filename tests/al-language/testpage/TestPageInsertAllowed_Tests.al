// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page Insert Allowed Row (60698), Test Page Insertable (60699),
//   Test Page Insert ReadOnly (60700), Assert (60021)
//
// TestPage.New()'s Creatable must reflect the page's actual InsertAllowed property (defaulting
// to true when the property is absent, as AL does) — not a hardcoded answer either way.

codeunit 60701 "Test Page Insert Allowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Insert Allowed Row";
    begin
        Row.DeleteAll();
    end;

    // Positive: New() must actually persist a row, not merely "not throw".
    // Asserting the stored field values proves the insert reached the table.
    [Test]
    procedure New_OnInsertablePage_InsertsRow()
    var
        Row: Record "Test Page Insert Allowed Row";
        Insertable: TestPage "Test Page Insertable";
    begin
        Initialize();

        Insertable.OpenEdit();
        Insertable.New();
        Insertable."No.".SetValue('N1');
        Insertable.Descr.SetValue('Inserted via TestPage');
        Insertable.Close();

        Assert.AreEqual(1, Row.Count(), 'TestPage.New() must insert exactly one row');
        Row.Get('N1');
        Assert.AreEqual('Inserted via TestPage', Row.Descr,
            'The value typed into the TestPage must reach the backing table');
    end;

    // Positive: two successive New() calls must yield two distinct rows — guards
    // against an implementation where New() silently reuses one buffer.
    [Test]
    procedure New_Twice_InsertsTwoDistinctRows()
    var
        Row: Record "Test Page Insert Allowed Row";
        Insertable: TestPage "Test Page Insertable";
    begin
        Initialize();

        Insertable.OpenEdit();
        Insertable.New();
        Insertable."No.".SetValue('N1');
        Insertable.New();
        Insertable."No.".SetValue('N2');
        Insertable.Close();

        Assert.AreEqual(2, Row.Count(), 'Two New() calls must insert two rows');
    end;

    // Negative: a page that genuinely declares InsertAllowed = false must STILL
    // refuse. This pins the fix to "honour the declared property" rather than
    // "always allow" — the same silent fake in the opposite direction.
    [Test]
    procedure New_OnInsertAllowedFalsePage_IsDenied()
    var
        Row: Record "Test Page Insert Allowed Row";
        ReadOnlyPage: TestPage "Test Page Insert ReadOnly";
    begin
        Initialize();
        // This codeunit does not declare TestIsolation = Function, so BC's default
        // (TestIsolation = Codeunit) keeps every [Test] method in one shared transaction.
        // asserterror below suppresses the test failure but not the rollback the error still
        // triggers — without this Commit, that rollback also undoes Initialize()'s DeleteAll,
        // reverting to whatever rows an earlier test in this codeunit left behind.
        Commit();

        ReadOnlyPage.OpenEdit();
        asserterror ReadOnlyPage.New();
        Assert.AreEqual('New method failed because Insert is not allowed.',
            CopyStr(GetLastErrorText(), 1, StrLen('New method failed because Insert is not allowed.')),
            'A page declaring InsertAllowed = false must still refuse TestPage.New()');

        Assert.AreEqual(0, Row.Count(), 'A denied New() must not insert a row');
    end;
}
