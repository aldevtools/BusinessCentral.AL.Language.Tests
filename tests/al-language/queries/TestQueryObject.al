// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Universal Query (60022), ALT Blob (60008)

codeunit 60205 "Test Query Object"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Query_Open_Read_ReturnsInsertedRows()
    var
        RowCount: Integer;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.Open();
        RowCount := 0;

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the first inserted row');
        RowCount += 1;
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'First query row must be entry 1');
        Assert.AreEqual(10, UniversalQuery.IntegerValue, 'First query row must expose the integer field value');
        Assert.AreEqual('First', UniversalQuery.TextValue, 'First query row must expose the text field value');

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the second inserted row');
        RowCount += 1;
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Second query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Second query row must expose the integer field value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Second query row must expose the text field value');

        Assert.IsFalse(UniversalQuery.Read(), 'Query must stop after the inserted rows');
        UniversalQuery.Close();

        Assert.AreEqual(2, RowCount, 'Query must return both inserted rows');
    end;

    [Test]
    procedure Query_Close_Reopen_RestartsDatasetFromFirstRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.Open();
        Assert.IsTrue(UniversalQuery.Read(), 'Initial query open must return the first row');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'Initial query open must start at entry 1');

        UniversalQuery.Close();
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Reopened query must return rows again from the beginning');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'Reopened query must restart at the first row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetRange_FiltersToMatchingRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Filtered query must return the matching row');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Filtered query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Filtered query row must keep its integer value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Filtered query row must keep its text value');
        Assert.IsFalse(UniversalQuery.Read(), 'Filtered query must only return one row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetFilter_WithPlaceholder_FiltersToMatchingRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '>%1', 10);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'SetFilter must return the row that matches the placeholder expression');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'SetFilter must keep only the row whose integer value is greater than 10');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'SetFilter must preserve the matching integer value');
        Assert.IsFalse(UniversalQuery.Read(), 'SetFilter must exclude rows that do not match the placeholder expression');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetFilter_WithWildcard_FiltersToMatchingRow()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(TextValue, 'S*');
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'SetFilter with a wildcard pattern must return the matching row');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Wildcard SetFilter must keep only the row whose text value starts with S');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Wildcard SetFilter must preserve the matching text value');
        Assert.IsFalse(UniversalQuery.Read(), 'Wildcard SetFilter must exclude rows that do not match the pattern');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SetFilter_WithWildcard_NoMatch_ReturnsNoRows()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(TextValue, 'Z*');
        UniversalQuery.Open();

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(0, RowCount, 'Wildcard SetFilter with no matching rows must return zero rows, not fail');
    end;

    [Test]
    procedure Query_SetFilter_WithInclusiveRange_KeepsOnlyRowsInsideRange()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] A two-sided range filter (low..high) on a query column keeps exactly the
        // rows whose column value falls inside the range, inclusive at both ends. Rows are
        // (Entry 1, Integer 10) and (Entry 2, Integer 20), so '15..25' must keep only entry 2.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..%2', 15, 25);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'A range SetFilter must return the row inside the range');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'A range SetFilter must keep only the row whose integer value is inside 15..25');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'A range SetFilter must preserve the matching integer value');
        RowCount := 1;

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(1, RowCount, 'A range SetFilter must exclude the row whose integer value is below the range');
    end;

    [Test]
    procedure Query_SetFilter_WithInclusiveRange_IncludesBothEndpoints()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] The range endpoints themselves are INSIDE the range: '10..20' spans both
        // rows exactly, so it must return both rather than dropping either endpoint. This is the
        // arm that distinguishes an inclusive range from an exclusive one.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..%2', 10, 20);
        UniversalQuery.Open();

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(2, RowCount, 'An inclusive range SetFilter spanning both values must return both rows');
    end;

    [Test]
    procedure Query_SetFilter_WithOpenEndedFromRange_KeepsRowsAtOrAboveLowValue()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] An open-ended '20..' range keeps every row at or above the low value. Only
        // entry 2 (Integer 20) qualifies, and it qualifies because the low end is inclusive.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..', 20);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'An open-ended from-range must return the row at the low value');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'An open-ended from-range must keep the row whose integer value equals the low value');
        RowCount := 1;

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(1, RowCount, 'An open-ended from-range must exclude the row below the low value');
    end;

    [Test]
    procedure Query_SetFilter_WithOpenEndedToRange_KeepsRowsAtOrBelowHighValue()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] The mirror of the from-range: '..10' keeps every row at or below the high
        // value, so only entry 1 (Integer 10) qualifies.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '..%1', 10);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'An open-ended to-range must return the row at the high value');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'An open-ended to-range must keep the row whose integer value equals the high value');
        RowCount := 1;

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(1, RowCount, 'An open-ended to-range must exclude the row above the high value');
    end;

    [Test]
    procedure Query_SetFilter_WithRange_NoMatch_ReturnsNoRows()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] The negative arm: a range that no row falls inside returns zero rows rather
        // than failing or returning the unfiltered set.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..%2', 30, 40);
        UniversalQuery.Open();

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(0, RowCount, 'A range SetFilter matching no row must return zero rows, not fail');
    end;

    [Test]
    procedure Query_SetFilter_WithAlternatedRanges_KeepsRowsInEitherRange()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] Two ranges alternated with '|' form an OR over two range conditions, so a
        // row qualifies when it falls inside EITHER. '5..12|18..25' spans entry 1 through its
        // first range and entry 2 through its second, so both come back.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..%2|%3..%4', 5, 12, 18, 25);
        UniversalQuery.Open();

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(2, RowCount, 'Alternated ranges must return the rows matching either range');
    end;

    [Test]
    procedure Query_SetFilter_WithAlternatedRanges_ExcludesRowBetweenTheRanges()
    var
        UniversalQuery: Query "ALT Universal Query";
        RowCount: Integer;
    begin
        // [SCENARIO] The discriminating arm for the alternation: a gap BETWEEN the two ranges
        // must exclude the row sitting in it. '5..12|30..40' keeps entry 1 (Integer 10) and drops
        // entry 2 (Integer 20), which falls between the two ranges. Without this arm the
        // alternation test above would also pass against an implementation that ignored the
        // filter entirely and returned both rows.
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetFilter(IntegerValue, '%1..%2|%3..%4', 5, 12, 30, 40);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Alternated ranges must return the row inside the first range');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'Alternated ranges must keep the row inside the first range');
        RowCount := 1;

        while UniversalQuery.Read() do
            RowCount += 1;
        UniversalQuery.Close();

        Assert.AreEqual(1, RowCount, 'Alternated ranges must exclude the row falling between the two ranges');
    end;

    [Test]
    procedure Query_GetFilter_AfterSetRange_ReturnsFilterText()
    var
        FilterText: Text;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        FilterText := UniversalQuery.GetFilter(EntryNo);

        Assert.AreEqual('2', FilterText, 'Query.GetFilter must return the value applied by SetRange');
    end;

    [Test]
    procedure Query_GetFilters_AfterMultipleFilters_ReturnsCombinedText()
    var
        FiltersText: Text;
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        UniversalQuery.SetFilter(TextValue, 'S*');
        FiltersText := UniversalQuery.GetFilters();

        Assert.IsTrue(FiltersText <> '', 'Query.GetFilters must return text when filters are applied');
        Assert.IsTrue(FiltersText.Contains('2'), 'Query.GetFilters must include the SetRange filter value');
        Assert.IsTrue(FiltersText.Contains('S*'), 'Query.GetFilters must include the SetFilter expression');
    end;

    [Test]
    procedure Query_ColumnMetadata_ReturnsConfiguredNamesCaptionsAndNumbers()
    var
        UniversalQuery: Query "ALT Universal Query";
        EntryNoColumnNo: Integer;
        IntegerValueColumnNo: Integer;
    begin
        Initialize();

        Assert.AreEqual('EntryNo', UniversalQuery.ColumnName(EntryNo), 'Query.ColumnName must return the column name from the query definition');
        Assert.AreEqual('Entry No.', UniversalQuery.ColumnCaption(EntryNo), 'Query.ColumnCaption must return the configured caption');
        Assert.AreEqual('Text Value', UniversalQuery.ColumnCaption(TextValue), 'Query.ColumnCaption must return the configured caption for each column');

        EntryNoColumnNo := UniversalQuery.ColumnNo(EntryNo);
        IntegerValueColumnNo := UniversalQuery.ColumnNo(IntegerValue);

        Assert.IsTrue(EntryNoColumnNo > 0, 'Query.ColumnNo must return a non-zero query column number');
        Assert.IsTrue(IntegerValueColumnNo > 0, 'Query.ColumnNo must return a non-zero query column number for each column');
        Assert.AreNotEqual(EntryNoColumnNo, IntegerValueColumnNo, 'Query.ColumnNo must distinguish different query columns');
    end;

    [Test]
    procedure Query_TopNumberOfRows_LimitsResultSet()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.TopNumberOfRows(1);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'TopNumberOfRows(1) must still return the first row');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'TopNumberOfRows(1) must keep the first row only');
        Assert.IsFalse(UniversalQuery.Read(), 'TopNumberOfRows(1) must limit the dataset to one row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_SecurityFiltering_SetIgnored_GetIgnored()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        UniversalQuery.SecurityFiltering(SecurityFilter::Ignored);

        Assert.AreEqual(SecurityFilter::Ignored, UniversalQuery.SecurityFiltering(), 'Query.SecurityFiltering must return Ignored after setting Ignored');
    end;

    [Test]
    procedure Query_SecurityFiltering_SetFiltered_GetFiltered()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        UniversalQuery.SecurityFiltering(SecurityFilter::Ignored);
        UniversalQuery.SecurityFiltering(SecurityFilter::Filtered);

        Assert.AreEqual(SecurityFilter::Filtered, UniversalQuery.SecurityFiltering(), 'Query.SecurityFiltering must return Filtered after setting Filtered');
    end;

    [Test]
    procedure Query_SecurityFiltering_Validated_Throws()
    var
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        asserterror UniversalQuery.SecurityFiltering(SecurityFilter::Validated);
        Assert.IsTrue(GetLastErrorText() <> '', 'Query.SecurityFiltering(Validated) must throw because Validated is not allowed for queries');
    end;

    [Test]
    procedure Query_SaveAsCsv_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QCSV1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsCsv(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QCSV1');

        Assert.IsTrue(Ok, 'Query.SaveAsCsv(OutStream) must report success for a valid export stream');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsCsv(OutStream) must export the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsCsv(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsJson_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        ExportRows: JsonArray;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QJSON1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsJson(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QJSON1');
        ExportRows.ReadFrom(ExportText);

        Assert.IsTrue(Ok, 'Query.SaveAsJson(OutStream) must report success for a valid export stream');
        Assert.AreEqual(1, ExportRows.Count(), 'Query.SaveAsJson(OutStream) must export only the filtered row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsJson(OutStream) must include the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsJson(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsXml_OutStream_ExportsFilteredDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        UniversalQuery: Query "ALT Universal Query";
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        PrepareBlobOutStream('QXML1', BlobRec, OutStr);
        Ok := UniversalQuery.SaveAsXml(OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QXML1');

        Assert.IsTrue(Ok, 'Query.SaveAsXml(OutStream) must report success for a valid export stream');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsXml(OutStream) must include the filtered row values');
        Assert.IsFalse(ExportText.Contains('First'), 'Query.SaveAsXml(OutStream) must respect instance filters during export');
    end;

    [Test]
    procedure Query_SaveAsCsv_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QCSV2', BlobRec, OutStr);
        Ok := Query.SaveAsCsv(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QCSV2');

        Assert.IsTrue(Ok, 'Query.SaveAsCsv(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsCsv(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsCsv(Integer, OutStream) must export the second inserted row');
    end;

    [Test]
    procedure Query_SaveAsJson_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        ExportRows: JsonArray;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QJSON2', BlobRec, OutStr);
        Ok := Query.SaveAsJson(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QJSON2');
        ExportRows.ReadFrom(ExportText);

        Assert.IsTrue(Ok, 'Query.SaveAsJson(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.AreEqual(2, ExportRows.Count(), 'Query.SaveAsJson(Integer, OutStream) must export all query rows');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsJson(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsJson(Integer, OutStream) must export the second inserted row');
    end;

    [Test]
    procedure Query_SaveAsXml_StaticOutStream_ExportsDataset()
    var
        BlobRec: Record "ALT Blob";
        ExportText: Text;
        OutStr: OutStream;
        Ok: Boolean;
    begin
        Initialize();
        InsertQueryRows();

        PrepareBlobOutStream('QXML2', BlobRec, OutStr);
        Ok := Query.SaveAsXml(60022, OutStr);
        BlobRec.Modify();
        ExportText := ReadBlobText('QXML2');

        Assert.IsTrue(Ok, 'Query.SaveAsXml(Integer, OutStream) must report success for a valid query ID and stream');
        Assert.IsTrue(ExportText.Contains('First'), 'Query.SaveAsXml(Integer, OutStream) must export the first inserted row');
        Assert.IsTrue(ExportText.Contains('Second'), 'Query.SaveAsXml(Integer, OutStream) must export the second inserted row');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertQueryRows()
    var
        Rec: Record "ALT Universal";
    begin
        InsertQueryRow(Rec, 1, 10, 'First');
        InsertQueryRow(Rec, 2, 20, 'Second');
    end;

    local procedure InsertQueryRow(var Rec: Record "ALT Universal"; EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntegerValue;
        Rec."Text Field" := TextValue;
        Rec.Insert();
    end;

    local procedure PrepareBlobOutStream(BlobCode: Code[20]; var BlobRec: Record "ALT Blob"; var OutStr: OutStream)
    begin
        BlobRec.Init();
        BlobRec.Code := BlobCode;
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
    end;

    local procedure ReadBlobText(BlobCode: Code[20]): Text
    var
        BlobRec: Record "ALT Blob";
        InStr: InStream;
        Segment: Text;
        AllText: Text;
    begin
        BlobRec.Get(BlobCode);
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        while not InStr.EOS() do begin
            InStr.ReadText(Segment);
            AllText += Segment;
        end;

        exit(AllText);
    end;
}
