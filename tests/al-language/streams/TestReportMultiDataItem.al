// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-dataset
// Scope: in-scope
// Fixtures used: Test Report MultiDI Single (60539), Test Report MultiDI Siblings (60537),
//                 Test Report MultiDI Nested (60538)
//
// A report's dataset must contain rows for EVERY data item, not just the first.
//
// `dataitem(X; Integer)` with a DataItemTableView filter is the standard idiom for a
// synthetic report dataset. A report with one such data item can render fine while reports
// with sibling or nested data items produce an empty dataset. That reads as success to the
// caller, because Report.SaveAs can catch the failure and return false, so the AL sees an
// empty document rather than an error — a silent-wrong-answer shape worth guarding against.
//
// Asserted through SaveAs(Xml), which serialises the dataset itself, so these tests fail on
// a missing ROW rather than on anything about rendering.

codeunit 60540 "Test Report Multi Data Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    begin
        // No tables are used by this codeunit; the data items are synthetic (Integer).
    end;

    local procedure RenderXml(ReportId: Integer) Xml: Text
    var
        TempBlob: Codeunit "Temp Blob";
        DataOut: OutStream;
        DataIn: InStream;
        Line: Text;
    begin
        TempBlob.CreateOutStream(DataOut);
        if not Report.SaveAs(ReportId, '', ReportFormat::Xml, DataOut) then
            Error('Report.SaveAs(%1, Xml) returned false.', ReportId);
        TempBlob.CreateInStream(DataIn);
        while not DataIn.EOS() do begin
            DataIn.ReadText(Line);
            Xml += Line;
        end;
    end;

    local procedure CountOccurrences(Haystack: Text; Needle: Text) Total: Integer
    var
        Pos: Integer;
    begin
        Pos := StrPos(Haystack, Needle);
        while Pos > 0 do begin
            Total += 1;
            Haystack := CopyStr(Haystack, Pos + StrLen(Needle));
            Pos := StrPos(Haystack, Needle);
        end;
    end;

    [Test]
    procedure TestReport_SingleDataItem_EmitsItsRows()
    var
        Xml: Text;
    begin
        // Control: the case that already works. If this ever breaks, the two tests below
        // would break too and their message would point at the wrong thing.
        Initialize();
        Xml := RenderXml(Report::"Test Report MultiDI Single");
        if CountOccurrences(Xml, 'ONLY-') <> 3 then
            Error('Expected 3 rows from the single data item, got %1.', CountOccurrences(Xml, 'ONLY-'));
    end;

    [Test]
    procedure TestReport_SiblingDataItems_BothEmitTheirRows()
    var
        Xml: Text;
    begin
        Initialize();
        Xml := RenderXml(Report::"Test Report MultiDI Siblings");

        // The first data item alone is not enough: the failure mode was an entirely empty
        // dataset, so assert BOTH counts exactly rather than "contains something".
        if CountOccurrences(Xml, 'FIRST-') <> 3 then
            Error('Expected 3 rows from the first data item, got %1.', CountOccurrences(Xml, 'FIRST-'));
        if CountOccurrences(Xml, 'SECOND-') <> 2 then
            Error('Expected 2 rows from the second data item, got %1.', CountOccurrences(Xml, 'SECOND-'));
    end;

    [Test]
    procedure TestReport_NestedDataItem_ReIteratesForEveryOuterRow()
    var
        Xml: Text;
    begin
        Initialize();
        Xml := RenderXml(Report::"Test Report MultiDI Nested");

        if CountOccurrences(Xml, 'OUTER-') <> 2 then
            Error('Expected 2 outer rows, got %1.', CountOccurrences(Xml, 'OUTER-'));
        // 3 inner rows per outer row. Asserting 6 rather than "> 0" is what makes this test
        // prove re-iteration instead of a single pass through the inner data item.
        if CountOccurrences(Xml, 'INNER-') <> 6 then
            Error('Expected 6 inner rows (3 per outer row), got %1.', CountOccurrences(Xml, 'INNER-'));
    end;
}
