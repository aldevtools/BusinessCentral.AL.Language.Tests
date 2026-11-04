// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Assert (60021), Test Rpt Meta Cols Fixture (60360), Test Rpt Meta Cols Sample (60359)
//
// What Report Metadata (2000000139) and Report Data Items (2000000203) answer for a
// source-compiled report, per column. These are the documented tables AL uses to discover a
// report's shape without running it, and every value below is one the platform computes from
// the report's own compiled metadata.
//
// Each assertion is chosen so that the platform default is the WRONG answer:
//
//   ProcessingOnly      the fixture declares false; "true" is what a stubbed report answers
//   WordMergeDataItem   the fixture declares Src; "" is what an unread property answers
//   Data Item Table View  the fixture sorts DESCENDING; an ascending or empty view is wrong
//                       (the sorted field's spelling inside SORTING(...) is not pinned)
//   Related Table ID    a real table id; 0 is what an unresolved name answers
//   Indentation Level   the fixture nests one data item; a flat list answers 0 for both
//   Sorting Fields      the sorted key is not the primary key and not in field order
//   Request Filter Fields  the filtered fields are not field 1 and not the sorted ones
//
// The data item's own ID is deliberately NOT asserted as a literal. The platform assigns it
// from the report's compiled metadata rather than from declaration order, so its value is not
// something AL source can predict — what IS assertable, and is asserted below, is that the two
// data items get DIFFERENT ids and that filtering the table by one of them selects one row.

codeunit 60361 "Test Report Metadata Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    begin
        // Both tables are virtual: their rows are computed from report metadata, so there is
        // nothing to delete or seed.
    end;

    // Positive: the report declares ProcessingOnly = false, and the column must say so.
    // A report whose metadata is not really read answers the platform's own stub value.
    [Test]
    procedure TestReportMetadata_ProcessingOnly_ReportsTheDeclaredValue()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        Initialize();

        Assert.IsTrue(ReportMetadata.Get(60360), 'Report Metadata has a row for report 60360');

        Assert.AreEqual(false, ReportMetadata.ProcessingOnly, 'ProcessingOnly');
    end;

    // Positive: WordMergeDataItem names the data item the Word merge iterates. The fixture
    // declares Src, so an empty answer means the property was never read.
    [Test]
    procedure TestReportMetadata_WordMergeDataItem_ReportsTheDeclaredDataItemName()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        Initialize();

        Assert.IsTrue(ReportMetadata.Get(60360), 'Report Metadata has a row for report 60360');

        Assert.AreEqual('Src', ReportMetadata.WordMergeDataItem, 'WordMergeDataItem');
    end;

    // Positive: UseRequestPage defaults to true in AL and the fixture does not turn it off.
    [Test]
    procedure TestReportMetadata_UseRequestPage_ReportsTrueForAReportWithARequestPage()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        Initialize();

        Assert.IsTrue(ReportMetadata.Get(60360), 'Report Metadata has a row for report 60360');

        Assert.AreEqual(true, ReportMetadata.UseRequestPage, 'UseRequestPage');
    end;

    // Positive: the root data item's table, as an id. 0 is the value a caller reads as
    // "this report has no dataset", so a report that plainly has one must never answer it.
    [Test]
    procedure TestReportMetadata_FirstDataItemTableID_ReportsTheRootDataItemTable()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        Initialize();

        Assert.IsTrue(ReportMetadata.Get(60360), 'Report Metadata has a row for report 60360');

        Assert.AreEqual(60359, ReportMetadata.FirstDataItemTableID, 'FirstDataItemTableID');
    end;

    // Negative: a report id nothing declares has no row. Proves the table is not answering
    // a fabricated row for every id it is asked about.
    [Test]
    procedure TestReportMetadata_UnknownReportId_HasNoRow()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        Initialize();

        Assert.IsFalse(ReportMetadata.Get(99999997), 'an undeclared report id has no metadata row');
    end;

    // Positive: the root data item's table view, in the platform's own normal form. The
    // fixture sorts DESCENDING, so the direction is carried in the value and an implementation
    // that drops the order() clause cannot pass.
    [Test]
    procedure TestReportDataItems_DataItemTableView_CarriesTheSortDirection()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Src');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the root data item has a row');

        // The platform reports the view it COMPILED, not the AL source text. Two things
        // are asserted and a third deliberately is not:
        //   * the view is non-empty — a data item that declares one must not report none;
        //   * ORDER(1) — descending. The fixture sorts descending, so an implementation
        //     that drops the order() clause, or defaults it to ascending, cannot pass.
        // How the platform spells the sorted FIELD inside SORTING(...) is not pinned: that
        // is an encoding detail of the compiled view, and pinning it here would make this
        // test about the encoding rather than about the property being reported at all.
        Assert.AreNotEqual('', ReportDataItems."Data Item Table View", 'the data item reports its table view');
        Assert.IsSubstring(ReportDataItems."Data Item Table View", 'ORDER(1)');
    end;

    // Positive: the root data item resolves to the fixture table by id, not by name.
    [Test]
    procedure TestReportDataItems_RelatedTableID_ResolvesToTheDataItemTable()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Src');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the root data item has a row');

        Assert.AreEqual(60359, ReportDataItems."Related Table ID", 'Related Table ID');
        Assert.AreEqual(0, ReportDataItems."Indentation Level", 'the root data item is not nested');
    end;

    // Positive: nesting is real. The fixture declares Child inside Src, so the two rows must
    // report different indentation levels — a flat list would answer 0 for both.
    [Test]
    procedure TestReportDataItems_IndentationLevel_ReportsNestingDepth()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange("Indentation Level", 1);
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the nested data item has a row of its own');

        Assert.AreEqual('Child', ReportDataItems.Name, 'the nested data item name');
        Assert.AreEqual(60359, ReportDataItems."Related Table ID", 'the nested data item table');
    end;

    // Positive: the report has exactly the four data items it declares — no more, no fewer.
    [Test]
    procedure TestReportDataItems_Count_MatchesTheDeclaredDataItems()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);

        Assert.AreEqual(4, ReportDataItems.Count(), 'data items declared by report 60360');
    end;

    // Positive: the two data items are distinguishable by their own ID, and that ID selects
    // exactly one row. This is what makes the ID usable as a key, which is the property a
    // declaration-order stand-in would break the moment a caller filtered on it.
    [Test]
    procedure TestReportDataItems_DataItemID_IsDistinctPerDataItemAndSelectsOneRow()
    var
        ReportDataItems: Record "Report Data Items";
        RootId: Integer;
        ChildId: Integer;
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Src');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the root data item has a row');
        RootId := ReportDataItems."Data Item ID";

        ReportDataItems.Reset();
        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange("Indentation Level", 1);
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the nested data item has a row');
        ChildId := ReportDataItems."Data Item ID";

        Assert.IsFalse(RootId = ChildId, 'the two data items have different IDs');

        // The platform assigns these from the report's compiled metadata, NOT from
        // declaration order — so neither is 1. Asserting that rules out the obvious
        // stand-in (a 1-based ordinal), which would otherwise satisfy every other
        // assertion in this test while being a different number from the one the
        // platform actually keys the row on.
        Assert.AreNotEqual(1, RootId, 'the root data item ID is not a declaration ordinal');
        Assert.AreNotEqual(2, ChildId, 'the nested data item ID is not a declaration ordinal');

        ReportDataItems.Reset();
        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange("Data Item ID", RootId);
        Assert.AreEqual(1, ReportDataItems.Count(), 'the root data item ID selects exactly one row');
    end;

    // Negative: filtering by a report id nothing declares selects nothing, so the data-item
    // table is not answering rows for reports that do not exist.
    [Test]
    procedure TestReportDataItems_UnknownReportId_SelectsNoRows()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 99999997);

        Assert.AreEqual(0, ReportDataItems.Count(), 'an undeclared report has no data-item rows');
    end;

    // Positive: Request Filter Fields reports FIELD NUMBERS, not the names AL wrote. The
    // fixture's Filtered data item declares `RequestFilterFields = Description, "Alt Code"`,
    // which are fields 2 and 5 — so every plausible wrong answer is excluded at once:
    //   'Description, "Alt Code"'  the AL source text
    //   '1'                        the first field
    //   '5,2'                      the sorted key's fields, in the sorted key's order
    //   ''                         the property not read at all
    [Test]
    procedure TestReportDataItems_RequestFilterFields_ReportsFieldNumbersInDeclarationOrder()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Filtered');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the Filtered data item has a row');

        Assert.AreEqual('2,5', ReportDataItems."Request Filter Fields", 'Request Filter Fields');
    end;

    // Positive: Sorting Fields reports the field numbers of the sorted key, in the KEY's own
    // order. The fixture sorts on key Alt = ("Alt Code", Description) = fields 5 then 2, so:
    //   '1'    the primary key
    //   '2,5'  ascending field order, and also what Request Filter Fields says
    //   ''     the property not read at all
    // are each excluded, and so is any answer carrying a field NAME.
    [Test]
    procedure TestReportDataItems_SortingFields_ReportsTheSortedKeysFieldNumbersInKeyOrder()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Filtered');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the Filtered data item has a row');

        Assert.AreEqual('5,2', ReportDataItems."Sorting Fields", 'Sorting Fields');
    end;

    // Negative, and the assertion that gives the two above their meaning: a data item that
    // declares NEITHER property reports empty for both. Without this, an implementation that
    // answered '2,5' and '5,2' for every data item in the report would pass both tests above.
    [Test]
    procedure TestReportDataItems_ADataItemDeclaringNeitherProperty_ReportsBothColumnsEmpty()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Plain');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the Plain data item has a row');

        Assert.AreEqual('', ReportDataItems."Request Filter Fields",
          'a data item declaring no RequestFilterFields reports none');
        Assert.AreEqual('', ReportDataItems."Sorting Fields",
          'a data item declaring no DataItemTableView reports no sorting fields');
    end;

    // Negative: the two columns are independent of each other, and this is the row that shows
    // it — the root data item sorts on the PRIMARY key ("Entry No.", field 1) while filtering
    // on Description (field 2), so the two columns hold DIFFERENT values on the same row. An
    // implementation deriving one from the other, or filling both from one source, cannot pass
    // this together with the Filtered assertions above, where the two differ again and in the
    // other direction.
    [Test]
    procedure TestReportDataItems_SortingFieldsAndRequestFilterFields_AreIndependentColumns()
    var
        ReportDataItems: Record "Report Data Items";
    begin
        Initialize();

        ReportDataItems.SetRange("Report ID", 60360);
        ReportDataItems.SetRange(Name, 'Src');
        Assert.IsTrue(ReportDataItems.FindFirst(), 'the root data item has a row');

        Assert.AreEqual('1', ReportDataItems."Sorting Fields",
          'the root data item sorts on the primary key, field 1');
        Assert.AreEqual('2', ReportDataItems."Request Filter Fields",
          'the root data item filters on Description, field 2');

        // The sorted field is not the filtered field, on this row. Stated as its own
        // assertion so the claim survives a future edit to either literal above.
        Assert.AreNotEqual(ReportDataItems."Sorting Fields", ReportDataItems."Request Filter Fields",
          'the two columns report different things about the same data item');
    end;
}
