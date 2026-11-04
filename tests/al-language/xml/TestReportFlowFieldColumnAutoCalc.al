// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autocalcfield-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); Base Application report 5620 "Insurance - Analysis",
// tables Insurance (5628) and "Ins. Coverage Ledger Entry" (5629).
//
/// <summary>
/// A report column bound to a FlowField of its data item's table is calculated for every row,
/// because a column's AutoCalcField property defaults to true. Nothing else asks for it here:
/// report 5620's Insurance data item declares no CalcFields and its OnAfterGetRecord never
/// calls CalcFields, yet it reads "Total Value Insured" (a sum over "Ins. Coverage Ledger
/// Entry"). So the column value and the OnAfterGetRecord result both depend on the column's
/// own AutoCalcField. The report is a precompiled Base Application object.
/// </summary>
codeunit 60935 "Test Report FlowField Column"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CoveredNoTok: Label 'ALTAC-COVERED', Locked = true;
        EmptyNoTok: Label 'ALTAC-EMPTY', Locked = true;
        FilterTok: Label 'ALTAC-*', Locked = true;

    local procedure Initialize()
    var
        Insurance: Record Insurance;
        CoverageEntry: Record "Ins. Coverage Ledger Entry";
    begin
        Insurance.SetFilter("No.", FilterTok);
        Insurance.DeleteAll(false);
        CoverageEntry.SetFilter("Insurance No.", FilterTok);
        CoverageEntry.DeleteAll(false);
    end;

    local procedure InsertInsurance(No: Code[20]; PolicyCoverage: Decimal)
    var
        Insurance: Record Insurance;
    begin
        Insurance.Init();
        Insurance."No." := No;
        Insurance.Description := No;
        Insurance."Policy Coverage" := PolicyCoverage;
        Insurance.Insert(false);
    end;

    local procedure InsertCoverage(InsuranceNo: Code[20]; Amount: Decimal; DisposedFA: Boolean)
    var
        CoverageEntry: Record "Ins. Coverage Ledger Entry";
        NextEntryNo: Integer;
    begin
        if CoverageEntry.FindLast() then
            NextEntryNo := CoverageEntry."Entry No.";
        NextEntryNo += 1;
        CoverageEntry.Init();
        CoverageEntry."Entry No." := NextEntryNo;
        CoverageEntry."Insurance No." := InsuranceNo;
        CoverageEntry."Posting Date" := WorkDate();
        CoverageEntry.Amount := Amount;
        CoverageEntry."Disposed FA" := DisposedFA;
        CoverageEntry.Insert(false);
    end;

    local procedure RunReportDataset(var Dataset: XmlDocument)
    var
        Insurance: Record Insurance;
        InsuranceAnalysis: Report "Insurance - Analysis";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        Insurance.SetFilter("No.", FilterTok);
        InsuranceAnalysis.SetTableView(Insurance);
        TempBlob.CreateOutStream(OutStr);
        InsuranceAnalysis.SaveAs('', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr);
        Assert.IsTrue(XmlDocument.ReadFrom(InStr, Dataset), 'the report dataset is not well-formed XML');
    end;

    // The value of one column on the Insurance row whose "No." column equals InsuranceNo.
    local procedure ColumnValue(Dataset: XmlDocument; InsuranceNo: Text; ColumnName: Text): Text
    var
        Rows: XmlNodeList;
        Row: XmlNode;
        Node: XmlNode;
    begin
        Dataset.SelectNodes('//DataItem[@name=''Insurance'']', Rows);
        foreach Row in Rows do
            if Row.SelectSingleNode('Columns/Column[@name=''Insurance__No__'']', Node) then
                if Node.AsXmlElement().InnerText() = InsuranceNo then begin
                    Assert.IsTrue(
                        Row.SelectSingleNode(StrSubstNo('Columns/Column[@name=''%1'']', ColumnName), Node),
                        StrSubstNo('the Insurance row %1 has no column %2', InsuranceNo, ColumnName));
                    exit(Node.AsXmlElement().InnerText());
                end;
        Assert.Fail(StrSubstNo('the dataset has %1 Insurance row(s) and none is %2', Rows.Count(), InsuranceNo));
    end;

    local procedure DecimalColumn(Dataset: XmlDocument; InsuranceNo: Text; ColumnName: Text): Decimal
    var
        Value: Decimal;
        ValueText: Text;
    begin
        ValueText := ColumnValue(Dataset, InsuranceNo, ColumnName);
        Assert.IsTrue(Evaluate(Value, ValueText, 9), StrSubstNo('column %1 = "%2" is not a decimal', ColumnName, ValueText));
        exit(Value);
    end;

    [Test]
    procedure FlowFieldColumn_IsCalculatedWithoutCalcFields()
    var
        Dataset: XmlDocument;
    begin
        // Positive: the column carries the FlowField's sum over the two non-disposed entries.
        // The disposed entry is excluded by the field's own CalcFormula, so 1234.25 cannot come
        // from a plain sum over every entry of the insurance (which would be 101233.25).
        Initialize();
        InsertInsurance(CoveredNoTok, 2000);
        InsertCoverage(CoveredNoTok, 700, false);
        InsertCoverage(CoveredNoTok, 534.25, false);
        InsertCoverage(CoveredNoTok, 99999, true);

        RunReportDataset(Dataset);

        Assert.AreEqual(1234.25, DecimalColumn(Dataset, CoveredNoTok, 'Insurance__Total_Value_Insured_'),
            'a FlowField column must be calculated for the row even though nothing calls CalcFields');
    end;

    [Test]
    procedure FlowFieldColumn_IsCalculatedBeforeOnAfterGetRecord()
    var
        Dataset: XmlDocument;
    begin
        // OnAfterGetRecord computes OverUnderInsured := "Policy Coverage" - "Total Value Insured".
        // It reads the record, not the column, so this proves the calculation happened on the
        // record before the trigger ran: 2000 - 1234.25, not 2000 - 0.
        Initialize();
        InsertInsurance(CoveredNoTok, 2000);
        InsertCoverage(CoveredNoTok, 700, false);
        InsertCoverage(CoveredNoTok, 534.25, false);

        RunReportDataset(Dataset);

        Assert.AreEqual(765.75, DecimalColumn(Dataset, CoveredNoTok, 'OverUnderInsured'),
            'OnAfterGetRecord must see the calculated FlowField');
    end;

    [Test]
    procedure FlowFieldColumn_IsPerRow_ZeroWhereNothingSums()
    var
        Dataset: XmlDocument;
    begin
        // Negative: a second insurance with no coverage entries gets 0 in the same run, so the
        // value is calculated per row and not carried over from the previous one.
        Initialize();
        InsertInsurance(CoveredNoTok, 2000);
        InsertInsurance(EmptyNoTok, 500);
        InsertCoverage(CoveredNoTok, 700, false);

        RunReportDataset(Dataset);

        Assert.AreEqual(700.0, DecimalColumn(Dataset, CoveredNoTok, 'Insurance__Total_Value_Insured_'),
            'the covered insurance must carry its own sum');
        Assert.AreEqual(0.0, DecimalColumn(Dataset, EmptyNoTok, 'Insurance__Total_Value_Insured_'),
            'an insurance with no coverage entries must carry 0');
        Assert.AreEqual(500.0, DecimalColumn(Dataset, EmptyNoTok, 'OverUnderInsured'),
            'OnAfterGetRecord for the empty insurance must see 0, not the previous row''s sum');
    end;
}
