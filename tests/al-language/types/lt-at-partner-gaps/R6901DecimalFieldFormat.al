// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 95080; self-contained codeunit 95081
// Probe: observed on the corpus CI matrix and on Windows 27.5 and 28.5; every literal asserted below is what the BC service tier produced.
// Facts: Format(Row.Field, Length, FormatString) of Decimal fields with DecimalPlaces 0:4, 0:2, 1:3, 0:3, 2:4, 0:5, 2:2, 0:0, without DecimalPlaces and
// with AutoFormatType 1, for the fixed-width string of a partner app and the digit codes <Integer,N>, <Decimal,N>, <Filler character,0>; the values
// 0, 1, 12.5, 1.23456, 12345.6789, 0.0001, -3.5, -0.00001 and 99999.99999; a Decimal variable alongside.
// BC versions: 27, 28, 29

table 95080 "LT R6901 Dec Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; P04; Decimal) { DecimalPlaces = 0 : 4; }
        field(3; P02; Decimal) { DecimalPlaces = 0 : 2; }
        field(4; P13; Decimal) { DecimalPlaces = 1 : 3; }
        field(5; P03; Decimal) { DecimalPlaces = 0 : 3; }
        field(6; P24; Decimal) { DecimalPlaces = 2 : 4; }
        field(7; P05; Decimal) { DecimalPlaces = 0 : 5; }
        field(8; P22; Decimal) { DecimalPlaces = 2 : 2; }
        field(9; P00; Decimal) { DecimalPlaces = 0 : 0; }
        field(10; Plain; Decimal) { }
        field(11; Amt; Decimal) { AutoFormatType = 1; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95081 "LT R6901 Dec Field Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One observation per value: P04|P02|P13|P03|P24|P05|P22|P00|Plain|Amt|a Decimal variable.
    local procedure Row(D: Decimal; Len: Integer; Spec: Text): Text
    var
        R: Record "LT R6901 Dec Fmt Row";
        V: Decimal;
    begin
        R.P04 := D;
        R.P02 := D;
        R.P13 := D;
        R.P03 := D;
        R.P24 := D;
        R.P05 := D;
        R.P22 := D;
        R.P00 := D;
        R.Plain := D;
        R.Amt := D;
        V := D;
        exit(Format(R.P04, Len, Spec) + '|' + Format(R.P02, Len, Spec) + '|' + Format(R.P13, Len, Spec) + '|' + Format(R.P03, Len, Spec) + '|' + Format(R.P24, Len, Spec) + '|' + Format(R.P05, Len, Spec) + '|' + Format(R.P22, Len, Spec) + '|' + Format(R.P00, Len, Spec) + '|' + Format(R.Plain, Len, Spec) + '|' + Format(R.Amt, Len, Spec) + '|' + Format(V, Len, Spec));
    end;

    local procedure Values(var Observer: Codeunit "Probe Observer"; Len: Integer; Spec: Text)
    var
        List: List of [Decimal];
        D: Decimal;
        N: Integer;
    begin
        List.Add(0);
        List.Add(1);
        List.Add(12.5);
        List.Add(1.23456);
        List.Add(12345.6789);
        List.Add(0.0001);
        List.Add(-3.5);
        List.Add(-0.00001);
        List.Add(99999.99999);
        foreach D in List do begin
            N += 1;
            Observer.Observe('v' + Format(N), Row(D, Len, Spec));
        end;
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 8, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_Integer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_Integer8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,8>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_IntegerFill4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_Decimal3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,3>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_Decimal4Fill()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,4><Filler character,0>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_IntegerDecimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer><Decimal>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_SignIntegerDecimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Sign><Integer><Decimal>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_IntegerThousandDecimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer Thousand><Decimal>');
        Observer.Finish();
    end;

    [Test]
    procedure R6901_PrecisionControl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Precision,2:4><Integer><Decimal>');
        Observer.Finish();
    end;
}
