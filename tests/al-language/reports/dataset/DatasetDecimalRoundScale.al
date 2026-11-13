// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703)
// local object: the report columns over Round results are under test (reports 62339 and 62344, table 62345).
// Area: the scale (the trailing zeros) of a Round result, which the report dataset writes as the value holds it for an
//   expression column (`V * 1`; reports/dataset/DatasetDecimalPlacesValueOrigins.al). Rows: the number has no decimals, fewer
//   decimals than the precision, as many, more; the precision is a power of ten, a quarter, 1, written with a trailing zero;
//   the directions '>' and '<'; a negative number. Also a variable set from the literal 2.50, and a temporary data item's
//   field set from that literal (by name and times one). al-runner issue 7440.
// Already pinned elsewhere: Round(1, 0.00001) and Round(1.234567, 0.00001) in the dataset
//   (reports/dataset/DatasetDecimalPlacesValueOrigins.al), the Round values themselves (types/decimal-integer/Round.al).
// BC versions: 27-29
codeunit 62338 "RPT DecRound Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ScaleValue(ColumnName: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        if not Dataset.Save(Report::"RPT DecRound Scale", '', Xml) then
            exit('not saved: ' + GetLastErrorText());
        exit(Dataset.ColumnValues(Xml, ColumnName));
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumber_PowerOfTen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R1: Round(1, 0.00001), times one.
        Observer.Observe('value', ScaleValue('R1'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_FewerDecimalsThanPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R2: Round(2.5, 0.01), times one.
        Observer.Observe('value', ScaleValue('R2'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_SameDecimalsAsPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R3: Round(2.50, 0.01), times one.
        Observer.Observe('value', ScaleValue('R3'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_MoreDecimalsThanPrecision_ZeroDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R4: Round(2.500, 0.01), times one.
        Observer.Observe('value', ScaleValue('R4'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_MoreDecimalsThanPrecision_TrailingZeroResult()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R5: Round(1.200001, 0.00001), times one.
        Observer.Observe('value', ScaleValue('R5'));
        Observer.Expect('value', '1.20000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumber_QuarterPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R6: Round(3, 0.25), times one.
        Observer.Observe('value', ScaleValue('R6'));
        Observer.Expect('value', '3.00,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_OneDecimal_QuarterPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R7: Round(3.5, 0.25), times one.
        Observer.Observe('value', ScaleValue('R7'));
        Observer.Expect('value', '3.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_OneDecimal_PrecisionOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R8: Round(2.5, 1), times one.
        Observer.Observe('value', ScaleValue('R8'));
        Observer.Expect('value', '3,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_WholeNumber_PrecisionWrittenWithZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R9: Round(1, 0.10), times one.
        Observer.Observe('value', ScaleValue('R9'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_TwoDecimals_OneDecimalPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R10: Round(2.25, 0.1), times one.
        Observer.Observe('value', ScaleValue('R10'));
        Observer.Expect('value', '2.3,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_FewerDecimalsThanPrecision_Up()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R11: Round(2.5, 0.01, '>'), times one.
        Observer.Observe('value', ScaleValue('R11'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_FewerDecimalsThanPrecision_Down()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R12: Round(2.5, 0.01, '<'), times one.
        Observer.Observe('value', ScaleValue('R12'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_NegativeFewerDecimalsThanPrecision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column R13: Round(-2.5, 0.01), times one.
        Observer.Observe('value', ScaleValue('R13'));
        Observer.Expect('value', '-2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_LiteralWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Column L1: 2.50, times one.
        Observer.Observe('value', ScaleValue('L1'));
        Observer.Expect('value', '2.50,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_RoundScale_TemporaryFieldFromLiteral()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        Ok := Dataset.Save(Report::"RPT DecRound Temp", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('field', Dataset.ColumnValues(Xml, 'TmpName'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'TmpTimes1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('field', '2.50,');
        Observer.Expect('times one', '2.50,');
        Observer.Verify();
    end;
}

// local object: the column source expressions over Round results are under test.
report 62339 "RPT DecRound Scale"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(R1; V[1] * 1) { }
            column(R2; V[2] * 1) { }
            column(R3; V[3] * 1) { }
            column(R4; V[4] * 1) { }
            column(R5; V[5] * 1) { }
            column(R6; V[6] * 1) { }
            column(R7; V[7] * 1) { }
            column(R8; V[8] * 1) { }
            column(R9; V[9] * 1) { }
            column(R10; V[10] * 1) { }
            column(R11; V[11] * 1) { }
            column(R12; V[12] * 1) { }
            column(R13; V[13] * 1) { }
            column(L1; V[14] * 1) { }

            trigger OnAfterGetRecord()
            begin
                V[1] := Round(1, 0.00001);
                V[2] := Round(2.5, 0.01);
                V[3] := Round(2.50, 0.01);
                V[4] := Round(2.500, 0.01);
                V[5] := Round(1.200001, 0.00001);
                V[6] := Round(3, 0.25);
                V[7] := Round(3.5, 0.25);
                V[8] := Round(2.5, 1);
                V[9] := Round(1, 0.10);
                V[10] := Round(2.25, 0.1);
                V[11] := Round(2.5, 0.01, '>');
                V[12] := Round(2.5, 0.01, '<');
                V[13] := Round(-2.5, 0.01);
                V[14] := 2.50;
            end;
        }
    }

    var
        V: array[14] of Decimal;
}

// local object: a temporary data item whose field is set from a literal with a trailing zero.
report 62344 "RPT DecRound Temp"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Tmp; "RPT DecRound Row")
        {
            UseTemporary = true;

            column(TmpName; D) { }
            column(TmpTimes1; D * 1) { }
        }
    }

    trigger OnPreReport()
    begin
        Tmp.Id := 1;
        Tmp.D := 2.50;
        Tmp.Insert();
    end;
}

// local object: the DecimalPlaces of the field is under test (0 : 5, as in al-runner issue 7440).
table 62345 "RPT DecRound Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Decimal) { DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
