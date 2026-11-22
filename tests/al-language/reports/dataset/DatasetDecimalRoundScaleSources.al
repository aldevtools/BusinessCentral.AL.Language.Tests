// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703)
// local object: the report columns over Round results and over global Decimal variables are under test (reports 62346, 62347, 62349 and 62358).
// Area: the scale (the trailing zeros) of a Decimal in the report dataset, by the shape of the value and of the column
//   (al-runner issue 7958). Rows: Round of a whole number written with decimals (2.0, 2.000, 3.0); Round of a number with
//   decimals to a precision written with a trailing zero (0.50, 0.10); Round(2.50 * 1, 0.01); each as an expression column
//   (`W * 1`). A global Decimal variable as the column source by name, with and without the column's own
//   DecimalPlaces = 0 : 5, set in OnAfterGetRecord or in OnPreReport, from Round(2.5, 0.01), Round(3, 0.25) and the literals
//   2.50 and 1.00000. The repro of issue 7958 as reported: four rows of a Price column (DecimalPlaces = 0 : 5) over a variable
//   set from Round in OnAfterGetRecord. Third round: where the zeros of a whole value go: a literal (1.00000, 2.0, 0.50), a sum
//   and a product of Decimal variables, a product with an Integer literal, Evaluate, and Round of a variable set from 2.0, each
//   read as the variable by name, as V * 1 and, for the sums and products, as the expression itself. Fourth round: values equal
//   to one, minus one and zero (Round, literals, a difference), against Round(2, 0.01) and the literals 10.0 and 2.00.
// Already pinned elsewhere: a variable set to 1.00000 in OnPreReport, by name without own DecimalPlaces, writes 1
//   (reports/dataset/DatasetDecimalPlacesValueOrigins.al:397); the other Round shapes are measured by
//   reports/dataset/DatasetDecimalRoundScale.al (open pull request 1337).
// BC versions: 27-29
codeunit 62348 "RPT DecRound Source Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure VarReportValue(ColumnName: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        if not Dataset.Save(Report::"RPT DecRound Var", '', Xml) then
            exit('not saved: ' + GetLastErrorText());
        exit(Dataset.ColumnValues(Xml, ColumnName));
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumberWithOneDecimal_PowerOfTen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W1: Round(2.0, 0.01), times one.
        Observer.Observe('value', VarReportValue('W1'));
        Observer.Expect('value', '2.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumberWithMoreDecimals_PowerOfTen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W2: Round(2.000, 0.01), times one.
        Observer.Observe('value', VarReportValue('W2'));
        Observer.Expect('value', '2.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumberWithOneDecimal_QuarterPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W3: Round(3.0, 0.25), times one.
        Observer.Observe('value', VarReportValue('W3'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_OneDecimal_HalfPrecisionWrittenWithZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W4: Round(1.4, 0.50), times one.
        Observer.Observe('value', VarReportValue('W4'));
        Observer.Expect('value', '1.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_OneDecimal_PrecisionWrittenWithZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W5: Round(2.5, 0.10), times one.
        Observer.Observe('value', VarReportValue('W5'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_ProductOfLiteralWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column W6: Round(2.50 * 1, 0.01), times one.
        Observer.Observe('value', VarReportValue('W6'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Round_AfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarRound: a global variable set to Round(2.5, 0.01) in OnAfterGetRecord, by name.
        Observer.Observe('value', VarReportValue('VarRound'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Round_AfterGetRecord_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarRoundPlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('VarRoundPlaces'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_RoundWhole_AfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarRoundWhole: a global variable set to Round(3, 0.25) in OnAfterGetRecord, by name.
        Observer.Observe('value', VarReportValue('VarRoundWhole'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_RoundWhole_AfterGetRecord_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarRoundWholePlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('VarRoundWholePlaces'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Literal_AfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarLit: a global variable set to the literal 2.50 in OnAfterGetRecord, by name.
        Observer.Observe('value', VarReportValue('VarLit'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Literal_AfterGetRecord_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarLitPlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('VarLitPlaces'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_LiteralWhole_AfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarLitWhole: a global variable set to the literal 1.00000 in OnAfterGetRecord, by name.
        Observer.Observe('value', VarReportValue('VarLitWhole'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_LiteralWhole_AfterGetRecord_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column VarLitWholePlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('VarLitWholePlaces'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Literal_PreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreLit: a global variable set to the literal 2.50 in OnPreReport, by name.
        Observer.Observe('value', VarReportValue('PreLit'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_Literal_PreReport_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreLitPlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('PreLitPlaces'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_RoundWhole_PreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreRoundWhole: a global variable set to Round(3, 0.25) in OnPreReport, by name.
        Observer.Observe('value', VarReportValue('PreRoundWhole'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_RoundWhole_PreReport_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreRoundWholePlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('PreRoundWholePlaces'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_LiteralWhole_PreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreLitWhole: a global variable set to the literal 1.00000 in OnPreReport, by name.
        Observer.Observe('value', VarReportValue('PreLitWhole'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Variable_LiteralWhole_PreReport_OwnDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column PreLitWholePlaces: the same variable, the column with DecimalPlaces = 0 : 5.
        Observer.Observe('value', VarReportValue('PreLitWholePlaces'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_VariableColumnWithDecimalPlaces_FourRows()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        // al-runner issue 7958 as reported: a Price column (DecimalPlaces = 0 : 5) over a global variable set in OnAfterGetRecord
        // to Round(2.5, 0.01), Round(3, 0.25), Round(2.50 * 1, 0.01) and Round(1.200001, 0.00001), one per row.
        Ok := Dataset.Save(Report::"RPT DecRound Price", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('price', Dataset.ColumnValues(Xml, 'Price'));
        Observer.Observe('format', Format(Round(2.5, 0.01), 0, 9) + '|' + Format(Round(3, 0.25), 0, 9) + '|' +
          Format(Round(2.50 * 1, 0.01), 0, 9) + '|' + Format(Round(1.200001, 0.00001), 0, 9));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('price', '2.50,3.00,2.50,1.20000,');
        Observer.Expect('format', '2.5|3|2.5|1.2');
        Observer.Verify();
    end;
    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_LiteralWholeWithDecimals()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 1.00000: the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitWholeVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'LitWholeT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('times one', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_LiteralWholeWithOneDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 2.0: the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitOneDecVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'LitOneDecT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '2.0,');
        Observer.Expect('times one', '2.0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_LiteralWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 0.50: the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitHalfVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'LitHalfT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '0.50,');
        Observer.Expect('times one', '0.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_SumWhole()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := Half + Half (Decimal variables 0.5): the variable by name, V * 1, and the column Half + Half.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'SumWholeVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'SumWholeT1'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'SumWholeExpr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('times one', '1,');
        Observer.Expect('expression', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_ProductWhole()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := Half * Two (Decimal variables 0.5 and 2): the variable by name, V * 1, and the column Half * Two.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'ProdWholeVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'ProdWholeT1'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'ProdWholeExpr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('times one', '1,');
        Observer.Expect('expression', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_SumWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := Quarter + Quarter (Decimal variables 0.25): the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'SumHalfVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'SumHalfT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '0.50,');
        Observer.Expect('times one', '0.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_ProductOfDecimalVariables()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := OneFive * Two (Decimal variables 1.5 and 2): the variable by name, V * 1, and the column OneFive * Two.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'ProdDecVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'ProdDecT1'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'ProdDecExpr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '3.0,');
        Observer.Expect('times one', '3.0,');
        Observer.Expect('expression', '3.0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_ProductWithIntegerLiteral()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := OneFive * 2 (Decimal variable 1.5, Integer literal 2): the variable by name, V * 1, and the column OneFive * 2.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'ProdIntVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'ProdIntT1'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'ProdIntExpr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '3.0,');
        Observer.Expect('times one', '3.0,');
        Observer.Expect('expression', '3.0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_EvaluateWhole()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Evaluate(V, '1.00000', 9): the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'EvWholeVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'EvWholeT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('times one', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_EvaluateWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Evaluate(V, '2.50', 9): the variable by name, and V * 1.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'EvHalfVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'EvHalfT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '2.50,');
        Observer.Expect('times one', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_Origin_RoundOfVariableSetFromLiteral()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 2.0; R := Round(V, 0.01): R by name, and R * 1 (Round(2.0, 0.01) written directly is 2.00, see W1).
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound Origin", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'RoundOfVarVar'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'RoundOfVarT1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '2.00,');
        Observer.Expect('times one', '2.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_RoundOfWholeNumberToHundredths()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Round(2, 0.01): the variable by name, and the expression itself.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'R2Var'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'R2Expr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '2.00,');
        Observer.Expect('expression', '2.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_RoundWithDecimalsToOne()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Round(1.004, 0.01), a number with decimals whose result is one: the variable by name, and the expression itself.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'R1Var'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'R1Expr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('expression', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_RoundToMinusOne()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Round(-1, 0.01) and Round(-1.004, 0.01): the variables by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('whole', Dataset.ColumnValues(Xml, 'RNegVar'));
        Observer.Observe('with decimals', Dataset.ColumnValues(Xml, 'RNegDecVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('whole', '-1,');
        Observer.Expect('with decimals', '-1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_RoundToZero()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // Round(0.001, 0.01): the variable by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'RZeroVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_LiteralOneWithOneDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 1.0: the variable by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitOneVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_LiteralMinusOne()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := -1.00: the variable by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitNegVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '-1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_LiteralZero()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 0.00: the variable by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'LitZeroVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_LiteralTen()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := 10.0 and V := 2.00: the variables by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('ten', Dataset.ColumnValues(Xml, 'LitTenVar'));
        Observer.Observe('two', Dataset.ColumnValues(Xml, 'LitTwoVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ten', '10.0,');
        Observer.Expect('two', '2.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_DifferenceIsOne()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := OneFive - Half (Decimal variables 1.50 and 0.50): the variable by name, and the expression itself.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'DiffVar'));
        Observer.Observe('expression', Dataset.ColumnValues(Xml, 'DiffExpr'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '1,');
        Observer.Expect('expression', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_One_ProductIsOneThenTimesDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        // V := Half * Two (one), W := V * 2.50: W by name.
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT DecRound One", '', Xml)));
        Observer.Observe('variable', Dataset.ColumnValues(Xml, 'ThenVar'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('variable', '2.5000,');
        Observer.Verify();
    end;

}

// local object: the column sources over Round results and over global Decimal variables are under test.
report 62346 "RPT DecRound Var"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(W1; W[1] * 1) { }
            column(W2; W[2] * 1) { }
            column(W3; W[3] * 1) { }
            column(W4; W[4] * 1) { }
            column(W5; W[5] * 1) { }
            column(W6; W[6] * 1) { }
            column(VarRound; VarRound) { }
            column(VarRoundPlaces; VarRound) { DecimalPlaces = 0 : 5; }
            column(VarRoundWhole; VarRoundWhole) { }
            column(VarRoundWholePlaces; VarRoundWhole) { DecimalPlaces = 0 : 5; }
            column(VarLit; VarLit) { }
            column(VarLitPlaces; VarLit) { DecimalPlaces = 0 : 5; }
            column(VarLitWhole; VarLitWhole) { }
            column(VarLitWholePlaces; VarLitWhole) { DecimalPlaces = 0 : 5; }
            column(PreLit; PreLit) { }
            column(PreLitPlaces; PreLit) { DecimalPlaces = 0 : 5; }
            column(PreRoundWhole; PreRoundWhole) { }
            column(PreRoundWholePlaces; PreRoundWhole) { DecimalPlaces = 0 : 5; }
            column(PreLitWhole; PreLitWhole) { }
            column(PreLitWholePlaces; PreLitWhole) { DecimalPlaces = 0 : 5; }

            trigger OnAfterGetRecord()
            begin
                W[1] := Round(2.0, 0.01);
                W[2] := Round(2.000, 0.01);
                W[3] := Round(3.0, 0.25);
                W[4] := Round(1.4, 0.50);
                W[5] := Round(2.5, 0.10);
                W[6] := Round(2.50 * 1, 0.01);
                VarRound := Round(2.5, 0.01);
                VarRoundWhole := Round(3, 0.25);
                VarLit := 2.50;
                VarLitWhole := 1.00000;
            end;
        }
    }

    trigger OnPreReport()
    begin
        PreLit := 2.50;
        PreRoundWhole := Round(3, 0.25);
        PreLitWhole := 1.00000;
    end;

    var
        W: array[6] of Decimal;
        VarRound: Decimal;
        VarRoundWhole: Decimal;
        VarLit: Decimal;
        VarLitWhole: Decimal;
        PreLit: Decimal;
        PreRoundWhole: Decimal;
        PreLitWhole: Decimal;
}

// local object: the repro of al-runner issue 7958, a Price column with DecimalPlaces = 0 : 5 over a variable.
report 62347 "RPT DecRound Price"
{
    UsageCategory = None;

    dataset
    {
        dataitem(PriceItem; Integer)
        {
            DataItemTableView = where(Number = filter(1 .. 4));

            column(Number; Number) { }
            column(Price; PriceValue) { DecimalPlaces = 0 : 5; }

            trigger OnAfterGetRecord()
            begin
                case Number of
                    1:
                        PriceValue := Round(2.5, 0.01);
                    2:
                        PriceValue := Round(3, 0.25);
                    3:
                        PriceValue := Round(2.50 * 1, 0.01);
                    4:
                        PriceValue := Round(1.200001, 0.00001);
                end;
            end;
        }
    }

    var
        PriceValue: Decimal;
}

// local object: the column sources over Decimal values made by literals, sums, products, Evaluate and Round are under test.
report 62349 "RPT DecRound Origin"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(LitWholeVar; LitWhole) { }
            column(LitWholeT1; LitWhole * 1) { }
            column(LitOneDecVar; LitOneDec) { }
            column(LitOneDecT1; LitOneDec * 1) { }
            column(LitHalfVar; LitHalf) { }
            column(LitHalfT1; LitHalf * 1) { }
            column(SumWholeVar; SumWhole) { }
            column(SumWholeT1; SumWhole * 1) { }
            column(SumWholeExpr; Half + Half) { }
            column(ProdWholeVar; ProdWhole) { }
            column(ProdWholeT1; ProdWhole * 1) { }
            column(ProdWholeExpr; Half * Two) { }
            column(SumHalfVar; SumHalf) { }
            column(SumHalfT1; SumHalf * 1) { }
            column(ProdDecVar; ProdDec) { }
            column(ProdDecT1; ProdDec * 1) { }
            column(ProdDecExpr; OneFive * Two) { }
            column(ProdIntVar; ProdInt) { }
            column(ProdIntT1; ProdInt * 1) { }
            column(ProdIntExpr; OneFive * 2) { }
            column(EvWholeVar; EvWhole) { }
            column(EvWholeT1; EvWhole * 1) { }
            column(EvHalfVar; EvHalf) { }
            column(EvHalfT1; EvHalf * 1) { }
            column(RoundOfVarVar; RoundOfVar) { }
            column(RoundOfVarT1; RoundOfVar * 1) { }

            trigger OnAfterGetRecord()
            begin
                Half := 0.5;
                Two := 2;
                Quarter := 0.25;
                OneFive := 1.5;
                LitWhole := 1.00000;
                LitOneDec := 2.0;
                LitHalf := 0.50;
                SumWhole := Half + Half;
                ProdWhole := Half * Two;
                SumHalf := Quarter + Quarter;
                ProdDec := OneFive * Two;
                ProdInt := OneFive * 2;
                Evaluate(EvWhole, '1.00000', 9);
                Evaluate(EvHalf, '2.50', 9);
                RoundOfVar := Round(LitOneDec, 0.01);
            end;
        }
    }

    var
        Half: Decimal;
        Two: Decimal;
        Quarter: Decimal;
        OneFive: Decimal;
        LitWhole: Decimal;
        LitOneDec: Decimal;
        LitHalf: Decimal;
        SumWhole: Decimal;
        ProdWhole: Decimal;
        SumHalf: Decimal;
        ProdDec: Decimal;
        ProdInt: Decimal;
        EvWhole: Decimal;
        EvHalf: Decimal;
        RoundOfVar: Decimal;
}

// local object: the column sources over Decimal values equal to one, minus one and zero are under test.
report 62358 "RPT DecRound One"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(R2Var; R2) { }
            column(R2Expr; Round(2, 0.01)) { }
            column(R1Var; R1) { }
            column(R1Expr; Round(1.004, 0.01)) { }
            column(RNegVar; RNeg) { }
            column(RNegDecVar; RNegDec) { }
            column(RZeroVar; RZero) { }
            column(LitOneVar; LitOne) { }
            column(LitNegVar; LitNeg) { }
            column(LitZeroVar; LitZero) { }
            column(LitTenVar; LitTen) { }
            column(LitTwoVar; LitTwo) { }
            column(DiffVar; Diff) { }
            column(DiffExpr; OneFive - Half) { }
            column(ThenVar; Afterwards) { }

            trigger OnAfterGetRecord()
            begin
                Half := 0.50;
                Two := 2;
                OneFive := 1.50;
                R2 := Round(2, 0.01);
                R1 := Round(1.004, 0.01);
                RNeg := Round(-1, 0.01);
                RNegDec := Round(-1.004, 0.01);
                RZero := Round(0.001, 0.01);
                LitOne := 1.0;
                LitNeg := -1.00;
                LitZero := 0.00;
                LitTen := 10.0;
                LitTwo := 2.00;
                Diff := OneFive - Half;
                Afterwards := Half * Two;
                Afterwards := Afterwards * 2.50;
            end;
        }
    }

    var
        Half: Decimal;
        Two: Decimal;
        OneFive: Decimal;
        R2: Decimal;
        R1: Decimal;
        RNeg: Decimal;
        RNegDec: Decimal;
        RZero: Decimal;
        LitOne: Decimal;
        LitNeg: Decimal;
        LitZero: Decimal;
        LitTen: Decimal;
        LitTwo: Decimal;
        Diff: Decimal;
        Afterwards: Decimal;
}
