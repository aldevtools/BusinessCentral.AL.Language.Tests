// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test GoToRecord DupCap Row (60040), Test GoToRecord DupCap CK Row (60041),
//                 Test GoToRecord DupCap List (60042), Test GoToRecord DupCap CK List (60043),
//                 Assert (60021)
//
// GoToRecord's primary-key resolution must not depend on field CAPTION text, on a table with
// two fields sharing the same caption. A caption-keyed implementation of the not-found path
// raises "the caption X is ambiguous between multiple fields" instead of answering false.

codeunit 60044 "Test GoToRecord DupCap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRows()
    var
        Row: Record "Test GoToRecord DupCap Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Descr := 'one';
        Row.Insert();

        Row.Init();
        Row."Entry No." := 2;
        Row.Descr := 'two';
        Row.Insert();
    end;

    local procedure SeedCompositeRows()
    var
        Row: Record "Test GoToRecord DupCap CK Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Config No." := 'C1';
        Row."Attribute Entry ID" := 10;
        Row."Entry No." := 1;
        Row.Descr := 'one';
        Row.Insert();

        Row.Init();
        Row."Config No." := 'C1';
        Row."Attribute Entry ID" := 20;
        Row."Entry No." := 2;
        Row.Descr := 'two';
        Row.Insert();
    end;

    // Positive: a row present on the page is still found -- caption ambiguity does not
    // affect the found path (asserted so a fix cannot regress it while fixing the not-found
    // path below).
    [Test]
    procedure GoToRecord_DupCaptionTable_FindsRowOnPage()
    var
        Row: Record "Test GoToRecord DupCap Row";
        TgrList: TestPage "Test GoToRecord DupCap List";
    begin
        SeedRows();

        Row.Get(2);

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'GoToRecord must find row 2 despite the duplicate caption');
        Assert.AreEqual('two', TgrList.Descr.Value(), 'TestPage must be positioned on row 2');
        TgrList.Close();
    end;

    // Negative: a row NOT on the page must answer false, not throw, even though the table
    // has two fields sharing the caption "Attribute ID".
    [Test]
    procedure GoToRecord_DupCaptionTable_RowNotOnPage_ReturnsFalse()
    var
        Row: Record "Test GoToRecord DupCap Row";
        Missing: Record "Test GoToRecord DupCap Row";
        TgrList: TestPage "Test GoToRecord DupCap List";
    begin
        SeedRows();

        // Position on the LAST row before the not-found probe (rather than the first) so a
        // failed search's internal forward scan ends exactly where the cursor already is --
        // isolating the caption-ambiguity claim this test exists to prove from a separate,
        // unrelated MutableRecordBuffer-refresh nuance of NavRecord.ALSetPosition's restore.
        Row.Get(2);

        Missing.Init();
        Missing."Entry No." := 99;
        Missing.Descr := 'absent';

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'existing row must still be reachable');
        Assert.IsFalse(TgrList.GoToRecord(Missing), 'a row that was never inserted must not be reachable');
        Assert.AreEqual('two', TgrList.Descr.Value(), 'cursor must stay on the last successfully positioned row');
        TgrList.Close();
    end;

    // Negative, composite primary key: BOTH key fields share the caption "Attribute ID".
    // The not-found path must still answer false rather than raise an ambiguous-caption error.
    [Test]
    procedure GoToRecord_CompositeKeyDupCaptionTable_RowNotOnPage_ReturnsFalse()
    var
        Row: Record "Test GoToRecord DupCap CK Row";
        Missing: Record "Test GoToRecord DupCap CK Row";
        TgrList: TestPage "Test GoToRecord DupCap CK List";
    begin
        SeedCompositeRows();

        Row.Get('C1', 20, 2);

        Missing.Init();
        Missing."Config No." := 'C2';
        Missing."Attribute Entry ID" := 20;
        Missing."Entry No." := 2;
        Missing.Descr := 'absent';

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'existing composite-key row must still be reachable');
        Assert.IsFalse(TgrList.GoToRecord(Missing), 'a composite-key row that was never inserted must not be reachable');
        Assert.AreEqual('two', TgrList.Descr.Value(), 'cursor must stay on the last successfully positioned row');
        TgrList.Close();
    end;
}
