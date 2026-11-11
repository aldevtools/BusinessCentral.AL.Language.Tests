// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-decimalplaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703)
// local object: the DecimalPlaces property of the table fields and of the report columns is under test (table 62330, reports 62331 and 62332).
// Area: the text the report dataset holds for a Decimal column, by where the value came from and by the DecimalPlaces of its
//   source (al-runner issue 7440: a stored field with DecimalPlaces = 0 : 5 and the value 1 must be written as 1, not 1.00000).
//   Sources: a table field with DecimalPlaces 0:5, 2:5, 5:5, 0:0 and the default, read from the database by the data item; the same
//   fields of a global record that was never stored; a global Decimal variable; a column with its own DecimalPlaces.
//   Value origins: the literals 1, 1.5 and 1.00000; Round(1, 0.00001); Round(1.234567, 0.00001); a product (0.5 * 2); a quotient
//   (3 / 3); a sum (0.5 + 0.5); Validate; Evaluate of '1.00000'; a value copied from a field that was read back.
//   Observed: the Column lines of the dataset (value and decimalformatter) and, for comparison, Format() of the same field.
// Already pinned elsewhere: an expression column keeps the scale of the calculation (`12.345678 * 1.5` gives 18.5185170) and the
//   decimalformatter per DecimalPlaces (reports/layouts-saveas/TestReportSaveAsColumnTypesContracts.al).
// BC versions: 27-29
table 62330 "RPT DecCol Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D05; Decimal) { DecimalPlaces = 0 : 5; }
        field(3; D25; Decimal) { DecimalPlaces = 2 : 5; }
        field(4; D55; Decimal) { DecimalPlaces = 5 : 5; }
        field(5; D00; Decimal) { DecimalPlaces = 0 : 0; }
        field(6; DDef; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The data item reads stored rows.
report 62331 "RPT DecCol Stored"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "RPT DecCol Row")
        {
            DataItemTableView = sorting(Id);

            column(Id; Id) { }
            column(D05; D05) { }
            column(D25; D25) { }
            column(D55; D55) { }
            column(D00; D00) { }
            column(DDef; DDef) { }
            column(D05Qualified; Row.D05) { }
            column(D05Times1; D05 * 1) { }
            column(D05OwnPlaces; D05) { DecimalPlaces = 2 : 2; }
            column(D05AsText; Format(D05)) { }
        }
    }
}

// Nothing is stored: the columns are on a global record and on global variables set in OnPreReport.
report 62332 "RPT DecCol Memory"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(RecLiteral; RecLiteral.D05) { }
            column(RecRounded; RecRounded.D05) { }
            column(RecProduct; RecProduct.D05) { }
            column(RecValidated; RecValidated.D05) { }
            column(RecEvaluated; RecEvaluated.D05) { }
            column(RecLiteralZeros; RecLiteralZeros.D05) { }
            column(RecRoundedDefault; RecRounded.DDef) { }
            column(RecRounded55; RecRounded.D55) { }
            column(VarLiteral; VarLiteral) { }
            column(VarRounded; VarRounded) { }
            column(VarRoundedLong; VarRoundedLong) { }
            column(VarProduct; VarProduct) { }
            column(VarQuotient; VarQuotient) { }
            column(VarSum; VarSum) { }
            column(VarEvaluated; VarEvaluated) { }
            column(VarLiteralZeros; VarLiteralZeros) { }
            column(VarRoundedOwnPlaces; VarRounded) { DecimalPlaces = 0 : 5; }
            column(VarLiteralOwnPlaces; VarLiteral) { DecimalPlaces = 5 : 5; }
            column(VarFromStored; VarFromStored) { }
        }
    }

    trigger OnPreReport()
    var
        Stored: Record "RPT DecCol Row";
        Half: Decimal;
        Two: Decimal;
        Three: Decimal;
    begin
        Half := 0.5;
        Two := 2;
        Three := 3;
        RecLiteral.D05 := 1;
        RecRounded.D05 := Round(1, 0.00001);
        RecRounded.DDef := Round(1, 0.00001);
        RecRounded.D55 := Round(1, 0.00001);
        RecProduct.D05 := Half * Two;
        RecValidated.Validate(D05, Round(1, 0.00001));
        Evaluate(RecEvaluated.D05, '1.00000', 9);
        RecLiteralZeros.D05 := 1.00000;
        VarLiteral := 1;
        VarRounded := Round(1, 0.00001);
        VarRoundedLong := Round(1.234567, 0.00001);
        VarProduct := Half * Two;
        VarQuotient := Three / Three;
        VarSum := Half + Half;
        Evaluate(VarEvaluated, '1.00000', 9);
        VarLiteralZeros := 1.00000;
        if Stored.FindFirst() then
            VarFromStored := Stored.D05;
    end;

    var
        RecLiteral: Record "RPT DecCol Row";
        RecRounded: Record "RPT DecCol Row";
        RecProduct: Record "RPT DecCol Row";
        RecValidated: Record "RPT DecCol Row";
        RecEvaluated: Record "RPT DecCol Row";
        RecLiteralZeros: Record "RPT DecCol Row";
        VarLiteral: Decimal;
        VarRounded: Decimal;
        VarRoundedLong: Decimal;
        VarProduct: Decimal;
        VarQuotient: Decimal;
        VarSum: Decimal;
        VarEvaluated: Decimal;
        VarLiteralZeros: Decimal;
        VarFromStored: Decimal;
}

codeunit 62333 "RPT DecCol Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Stores one row whose five Decimal fields all get the value of the origin, then answers the dataset columns of that row.
    local procedure StoredColumns(Origin: Integer): Text
    var
        Row: Record "RPT DecCol Row";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Value: Decimal;
        Half: Decimal;
        Two: Decimal;
        Three: Decimal;
    begin
        Half := 0.5;
        Two := 2;
        Three := 3;
        Row.DeleteAll();
        Row.Init();
        Row.Id := Origin;
        case Origin of
            1:
                Value := 1;
            2:
                Value := 1.5;
            3:
                Value := 1.00000;
            4:
                Value := Round(1, 0.00001);
            5:
                Value := Round(1.234567, 0.00001);
            6:
                Value := Half * Two;
            7:
                Value := Three / Three;
            8:
                Value := Half + Half;
            9:
                Evaluate(Value, '1.00000', 9);
            10:
                Value := 0;
            11:
                Value := -2.50;
            12:
                Value := 1234.5;
        end;
        if Origin = 20 then begin
            Row.Validate(D05, Round(1, 0.00001));
            Row.Validate(D25, Round(1, 0.00001));
            Row.Validate(D55, Round(1, 0.00001));
            Row.Validate(D00, Round(1, 0.00001));
            Row.Validate(DDef, Round(1, 0.00001));
        end else begin
            Row.D05 := Value;
            Row.D25 := Value;
            Row.D55 := Value;
            Row.D00 := Value;
            Row.DDef := Value;
        end;
        Row.Insert();
        ClearLastError();
        if not Dataset.Save(Report::"RPT DecCol Stored", '', Xml) then
            exit('not saved: ' + GetLastErrorText());
        Row.Get(Origin);
        exit(Dataset.ColumnLines(Xml) + ' Format: ' + Format(Row.D05) + ' / ' + Format(Row.D25) + ' / ' + Format(Row.D55) + ' / ' + Format(Row.D00) + ' / ' + Format(Row.DDef));
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Literal1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(1));
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Literal1Point5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(2));
        Observer.Expect('columns', '<Column name="Id">2</Column>|<Column name="D05" decimalformatter="#,##0.#####">1.5</Column>|<Column name="D25" decimalformatter="#,##0.00###">1.5</Column>|<Column name="D55" decimalformatter="#,##0.00000">1.5</Column>|<Column name="D00" decimalformatter="#,##0">1.5</Column>|<Column name="DDef" decimalformatter="#,##0.00">1.5</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1.5</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1.5</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1.5</Column>|<Column name="D05AsText">1.5</Column>| Format: 1.5 / 1.50 / 1.50000 / 2 / 1.5');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_LiteralWithFiveZeros()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(3));
        Observer.Expect('columns', '<Column name="Id">3</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_RoundOf1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(4));
        Observer.Expect('columns', '<Column name="Id">4</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_RoundOfLongFraction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(5));
        Observer.Expect('columns', '<Column name="Id">5</Column>|<Column name="D05" decimalformatter="#,##0.#####">1.23457</Column>|<Column name="D25" decimalformatter="#,##0.00###">1.23457</Column>|<Column name="D55" decimalformatter="#,##0.00000">1.23457</Column>|<Column name="D00" decimalformatter="#,##0">1.23457</Column>|<Column name="DDef" decimalformatter="#,##0.00">1.23457</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1.23457</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1.23457</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1.23457</Column>|<Column name="D05AsText">1.23457</Column>| Format: 1.23457 / 1.23457 / 1.23457 / 1 / 1.23457');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Product()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(6));
        Observer.Expect('columns', '<Column name="Id">6</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Quotient()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(7));
        Observer.Expect('columns', '<Column name="Id">7</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Sum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(8));
        Observer.Expect('columns', '<Column name="Id">8</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Evaluated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(9));
        Observer.Expect('columns', '<Column name="Id">9</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(10));
        Observer.Expect('columns', '<Column name="Id">10</Column>|<Column name="D05" decimalformatter="#,##0.#####">0</Column>|<Column name="D25" decimalformatter="#,##0.00###">0</Column>|<Column name="D55" decimalformatter="#,##0.00000">0</Column>|<Column name="D00" decimalformatter="#,##0">0</Column>|<Column name="DDef" decimalformatter="#,##0.00">0</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">0</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">0</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">0</Column>|<Column name="D05AsText">0</Column>| Format: 0 / 0.00 / 0.00000 / 0 / 0');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_NegativeWithTrailingZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(11));
        Observer.Expect('columns', '<Column name="Id">11</Column>|<Column name="D05" decimalformatter="#,##0.#####">-2.5</Column>|<Column name="D25" decimalformatter="#,##0.00###">-2.5</Column>|<Column name="D55" decimalformatter="#,##0.00000">-2.5</Column>|<Column name="D00" decimalformatter="#,##0">-2.5</Column>|<Column name="DDef" decimalformatter="#,##0.00">-2.5</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">-2.5</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">-2.5</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">-2.5</Column>|<Column name="D05AsText">-2.5</Column>| Format: -2.5 / -2.50 / -2.50000 / -3 / -2.5');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Thousands()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(12));
        Observer.Expect('columns', '<Column name="Id">12</Column>|<Column name="D05" decimalformatter="#,##0.#####">1234.5</Column>|<Column name="D25" decimalformatter="#,##0.00###">1234.5</Column>|<Column name="D55" decimalformatter="#,##0.00000">1234.5</Column>|<Column name="D00" decimalformatter="#,##0">1234.5</Column>|<Column name="DDef" decimalformatter="#,##0.00">1234.5</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1234.5</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1234.5</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1234.5</Column>|<Column name="D05AsText">1,234.5</Column>| Format: 1,234.5 / 1,234.50 / 1,234.50000 / 1,235 / 1,234.5');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_StoredField_Validated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', StoredColumns(20));
        Observer.Expect('columns', '<Column name="Id">20</Column>|<Column name="D05" decimalformatter="#,##0.#####">1</Column>|<Column name="D25" decimalformatter="#,##0.00###">1</Column>|<Column name="D55" decimalformatter="#,##0.00000">1</Column>|<Column name="D00" decimalformatter="#,##0">1</Column>|<Column name="DDef" decimalformatter="#,##0.00">1</Column>|<Column name="D05Qualified" decimalformatter="#,##0.#####">1</Column>|<Column name="D05Times1" decimalformatter="#,##0.00">1</Column>|<Column name="D05OwnPlaces" decimalformatter="#,##0.00">1</Column>|<Column name="D05AsText">1</Column>| Format: 1 / 1.00 / 1.00000 / 1 / 1');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_NeverStored_GlobalRecordFields()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Row: Record "RPT DecCol Row";
        Xml: Text;
        Lines: Text;
        Line: Text;
        Kept: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Ok := Dataset.Save(Report::"RPT DecCol Memory", '', Xml);
        Lines := Dataset.ColumnLines(Xml);
        foreach Line in Lines.Split('|') do
            if Line.StartsWith('<Column name="Rec') then
                Kept += Line + '|';
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('columns', Kept);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('columns', '<Column name="RecLiteral" decimalformatter="#,##0.#####">1</Column>|<Column name="RecRounded" decimalformatter="#,##0.#####">1</Column>|<Column name="RecProduct" decimalformatter="#,##0.#####">1</Column>|<Column name="RecValidated" decimalformatter="#,##0.#####">1</Column>|<Column name="RecEvaluated" decimalformatter="#,##0.#####">1</Column>|<Column name="RecLiteralZeros" decimalformatter="#,##0.#####">1</Column>|<Column name="RecRoundedDefault" decimalformatter="#,##0.00">1</Column>|<Column name="RecRounded55" decimalformatter="#,##0.00000">1</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_NeverStored_GlobalVariables()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Row: Record "RPT DecCol Row";
        Xml: Text;
        Lines: Text;
        Line: Text;
        Kept: Text;
        Ok: Boolean;
    begin
        // One stored row with Round(1, 0.00001) in D05: the report copies it into a variable after reading it back (VarFromStored).
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.D05 := Round(1, 0.00001);
        Row.Insert();
        Ok := Dataset.Save(Report::"RPT DecCol Memory", '', Xml);
        Lines := Dataset.ColumnLines(Xml);
        foreach Line in Lines.Split('|') do
            if Line.StartsWith('<Column name="Var') then
                Kept += Line + '|';
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('columns', Kept);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('columns', '<Column name="VarLiteral" decimalformatter="#,##0.00">1</Column>|<Column name="VarRounded" decimalformatter="#,##0.00">1</Column>|<Column name="VarRoundedLong" decimalformatter="#,##0.00">1.23457</Column>|<Column name="VarProduct" decimalformatter="#,##0.00">1</Column>|<Column name="VarQuotient" decimalformatter="#,##0.00">1</Column>|<Column name="VarSum" decimalformatter="#,##0.00">1</Column>|<Column name="VarEvaluated" decimalformatter="#,##0.00">1</Column>|<Column name="VarLiteralZeros" decimalformatter="#,##0.00">1</Column>|<Column name="VarRoundedOwnPlaces" decimalformatter="#,##0.#####">1</Column>|<Column name="VarLiteralOwnPlaces" decimalformatter="#,##0.00000">1</Column>|<Column name="VarFromStored" decimalformatter="#,##0.00">1</Column>|');
        Observer.Verify();
    end;

    // The source shapes the tests above do not cover (al-runner issue 7440, second round). One stored row 1 holds Round(1, 0.00001)
    // in D, row 2 holds 1.50; the data item reads row 1, its trigger reads row 2 with Get and sets the variables. Each test
    // observes one column of the same dataset.
    local procedure MatrixValue(ColumnName: Text): Text
    var
        Row: Record "RPT DecCol Matrix Row";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.D := Round(1, 0.00001);
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.D := 1.50;
        Row.Insert();
        if not Dataset.Save(Report::"RPT DecCol Matrix", '', Xml) then
            exit('not saved: ' + GetLastErrorText());
        exit(Dataset.ColumnValues(Xml, ColumnName));
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_VariableTimesOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('VarTimes1'));
        Observer.Expect('value', '1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_ArrayElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('ArrElem'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_UnaryMinus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('Neg'));
        Observer.Expect('value', '-1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_Parentheses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('Paren'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_ProcedureCallWithParentheses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('CallParens'));
        Observer.Expect('value', '1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_ProcedureCallWithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('CallNoParens'));
        Observer.Expect('value', '1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_CodeunitMethodWithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('MemberCall'));
        Observer.Expect('value', '1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_RecordReadByGet_Field()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('GetName'));
        Observer.Expect('value', '1.5,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_RecordReadByGet_FieldTimesTwo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('GetTimes2'));
        Observer.Expect('value', '3.0,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_TriggerAssignedField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('Assigned'));
        Observer.Expect('value', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_TriggerAssignedFieldTimesOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('AssignedTimes1'));
        Observer.Expect('value', '1.00000,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_FlowFieldAfterCalcFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('FlowName'));
        Observer.Expect('value', '2.5,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_FlowFieldAfterCalcFieldsTimesOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('value', MatrixValue('FlowTimes1'));
        Observer.Expect('value', '2.5,');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_Decimal_Matrix_TemporaryDataItem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "RPT DecCol Matrix Row";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Ok := Dataset.Save(Report::"RPT DecCol Matrix Temp", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('field', Dataset.ColumnValues(Xml, 'TmpName'));
        Observer.Observe('times one', Dataset.ColumnValues(Xml, 'TmpTimes1'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('field', '1,');
        Observer.Expect('times one', '1.00000,');
        Observer.Verify();
    end;
}

// local object: the FieldClass and DecimalPlaces of the fields are under test (a FlowField next to stored fields).
table 62334 "RPT DecCol Matrix Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Decimal) { DecimalPlaces = 0 : 5; }
        field(3; D2; Decimal) { DecimalPlaces = 0 : 5; }
        field(4; S; Decimal) { FieldClass = FlowField; CalcFormula = sum("RPT DecCol Matrix Row".D); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// local object: the column source expressions are under test.
report 62335 "RPT DecCol Matrix"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "RPT DecCol Matrix Row")
        {
            DataItemTableView = sorting(Id) where(Id = const(1));

            column(VarTimes1; V * 1) { }
            column(ArrElem; Arr[1]) { }
            column(Neg; -V) { }
            column(Paren; (V)) { }
            column(CallParens; GetV()) { }
            column(CallNoParens; GetV) { }
            column(MemberCall; Helper.GetV) { }
            column(GetName; G.D) { }
            column(GetTimes2; G.D * 2) { }
            column(Assigned; D2) { }
            column(AssignedTimes1; D2 * 1) { }
            column(FlowName; S) { }
            column(FlowTimes1; S * 1) { }

            trigger OnAfterGetRecord()
            begin
                G.Get(2);
                V := Round(1, 0.00001);
                Arr[1] := Round(1, 0.00001);
                D2 := Round(1, 0.00001);
                CalcFields(S);
            end;
        }
    }

    var
        G: Record "RPT DecCol Matrix Row";
        Helper: Codeunit "RPT DecCol Matrix Helper";
        V: Decimal;
        Arr: array[2] of Decimal;

    procedure GetV(): Decimal
    begin
        exit(Round(1, 0.00001));
    end;
}

// local object: a temporary data item filled in OnPreReport is under test.
report 62336 "RPT DecCol Matrix Temp"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Tmp; "RPT DecCol Matrix Row")
        {
            UseTemporary = true;

            column(TmpName; D) { }
            column(TmpTimes1; D * 1) { }
        }
    }

    trigger OnPreReport()
    begin
        Tmp.Id := 1;
        Tmp.D := Round(1, 0.00001);
        Tmp.Insert();
    end;
}

// local object: a codeunit method called without parentheses as a column source.
codeunit 62337 "RPT DecCol Matrix Helper"
{
    procedure GetV(): Decimal
    begin
        exit(Round(1, 0.00001));
    end;
}
