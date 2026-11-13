// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703)
// local object: the report columns over Round results and over global Decimal variables are under test (reports 62346 and 62347).
// Area: the scale (the trailing zeros) of a Decimal in the report dataset, by the shape of the value and of the column
//   (al-runner issue 7958). Rows: Round of a whole number written with decimals (2.0, 2.000, 3.0); Round of a number with
//   decimals to a precision written with a trailing zero (0.50, 0.10); Round(2.50 * 1, 0.01); each as an expression column
//   (`W * 1`). A global Decimal variable as the column source by name, with and without the column's own
//   DecimalPlaces = 0 : 5, set in OnAfterGetRecord or in OnPreReport, from Round(2.5, 0.01), Round(3, 0.25) and the literals
//   2.50 and 1.00000. The repro of issue 7958 as reported: four rows of a Price column (DecimalPlaces = 0 : 5) over a variable
//   set from Round in OnAfterGetRecord.
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
        Observer.Expect('value', '3,');
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
        Observer.Expect('value', '1.00000,');
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
        Observer.Expect('value', '3,');
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
        Observer.Expect('value', '1.00000,');
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
