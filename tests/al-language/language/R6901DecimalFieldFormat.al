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

    // One observation per value: P04|P02|P13|P03|P24|P05|P22|P00|Plain|a Decimal variable; the amount field (AutoFormatType 1) is observed apart.
    local procedure Row(D: Decimal; Len: Integer; Spec: Text; Amount: Boolean): Text
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
        if Amount then
            exit(Format(R.Amt, Len, Spec));
        exit(Format(R.P04, Len, Spec) + '|' + Format(R.P02, Len, Spec) + '|' + Format(R.P13, Len, Spec) + '|' + Format(R.P03, Len, Spec) + '|' + Format(R.P24, Len, Spec) + '|' + Format(R.P05, Len, Spec) + '|' + Format(R.P22, Len, Spec) + '|' + Format(R.P00, Len, Spec) + '|' + Format(R.Plain, Len, Spec) + '|' + Format(V, Len, Spec));
    end;

    local procedure Values(var Observer: Codeunit "Probe Observer"; Len: Integer; Spec: Text; First: Integer; Last: Integer)
    var
        List: List of [Decimal];
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
        for N := First to Last do begin
            Observer.Observe('v' + Format(N), Row(List.Get(N), Len, Spec, false));
            Observer.Observe('v' + Format(N) + ' Amt', Row(List.Get(N), Len, Spec, true));
        end;
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len8_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 8, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 1, 3);
        Observer.Expect('v1', '0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000');
        Observer.Expect('v1 Amt', '0000.000');
        Observer.Expect('v2', '0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000');
        Observer.Expect('v2 Amt', '0001.000');
        Observer.Expect('v3', '0012.500|0012.500|0012.500|0012.500|0012.500|0012.500|0012.500|0013.000|0012.500|0012.500');
        Observer.Expect('v3 Amt', '0012.500');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len8_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 8, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 4, 6);
        Observer.Expect('v4', '0001****|0001.230|0001.235|0001.235|0001****|0001****|0001.230|0001.000|0001****|0001****');
#if BC28PLUS
        Observer.Expect('v4 Amt', '0001.230');
#else
        Observer.Expect('v4 Amt', '0001****');
#endif
        Observer.Expect('v5', '********|****.680|****.679|****.679|********|********|****.680|****.000|********|********');
#if BC28PLUS
        Observer.Expect('v5 Amt', '****.680');
#else
        Observer.Expect('v5 Amt', '********');
#endif
        Observer.Expect('v6', '0000****|0000.000|0000.000|0000.000|0000****|0000****|0000.000|0000.000|0000****|0000****');
#if BC28PLUS
        Observer.Expect('v6 Amt', '0000.000');
#else
        Observer.Expect('v6 Amt', '0000****');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len8_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 8, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 7, 9);
        Observer.Expect('v7', '0003.500|0003.500|0003.500|0003.500|0003.500|0003.500|0003.500|0004.000|0003.500|0003.500');
        Observer.Expect('v7 Amt', '0003.500');
        Observer.Expect('v8', '0000.000|0000.000|0000.000|0000.000|0000.000|0000****|0000.000|0000.000|0000****|0000****');
#if BC28PLUS
        Observer.Expect('v8 Amt', '0000.000');
#else
        Observer.Expect('v8 Amt', '0000****');
#endif
        Observer.Expect('v9', '****.000|****.000|****.000|****.000|****.000|********|****.000|****.000|********|********');
#if BC28PLUS
        Observer.Expect('v9 Amt', '****.000');
#else
        Observer.Expect('v9 Amt', '********');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len0_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 1, 3);
        Observer.Expect('v1', '0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000|0000.000');
        Observer.Expect('v1 Amt', '0000.000');
        Observer.Expect('v2', '0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000|0001.000');
        Observer.Expect('v2 Amt', '0001.000');
        Observer.Expect('v3', '0012.500|0012.500|0012.500|0012.500|0012.500|0012.500|0012.500|0013.000|0012.500|0012.500');
        Observer.Expect('v3 Amt', '0012.500');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len0_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 4, 6);
        Observer.Expect('v4', '0001****|0001.230|0001.235|0001.235|0001****|0001****|0001.230|0001.000|0001****|0001****');
#if BC28PLUS
        Observer.Expect('v4 Amt', '0001.230');
#else
        Observer.Expect('v4 Amt', '0001****');
#endif
        Observer.Expect('v5', '********|****.680|****.679|****.679|********|********|****.680|****.000|********|********');
#if BC28PLUS
        Observer.Expect('v5 Amt', '****.680');
#else
        Observer.Expect('v5 Amt', '********');
#endif
        Observer.Expect('v6', '0000****|0000.000|0000.000|0000.000|0000****|0000****|0000.000|0000.000|0000****|0000****');
#if BC28PLUS
        Observer.Expect('v6 Amt', '0000.000');
#else
        Observer.Expect('v6 Amt', '0000****');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntFill4Dec4Len0_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0><Decimal,4><Filler character,0>', 7, 9);
        Observer.Expect('v7', '0003.500|0003.500|0003.500|0003.500|0003.500|0003.500|0003.500|0004.000|0003.500|0003.500');
        Observer.Expect('v7 Amt', '0003.500');
        Observer.Expect('v8', '0000.000|0000.000|0000.000|0000.000|0000.000|0000****|0000.000|0000.000|0000****|0000****');
#if BC28PLUS
        Observer.Expect('v8 Amt', '0000.000');
#else
        Observer.Expect('v8 Amt', '0000****');
#endif
        Observer.Expect('v9', '****.000|****.000|****.000|****.000|****.000|********|****.000|****.000|********|********');
#if BC28PLUS
        Observer.Expect('v9 Amt', '****.000');
#else
        Observer.Expect('v9 Amt', '********');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer>', 1, 3);
        Observer.Expect('v1', '0|0|0|0|0|0|0|0|0|0');
        Observer.Expect('v1 Amt', '0');
        Observer.Expect('v2', '1|1|1|1|1|1|1|1|1|1');
        Observer.Expect('v2 Amt', '1');
        Observer.Expect('v3', '12|12|12|12|12|12|12|13|12|12');
        Observer.Expect('v3 Amt', '12');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer>', 4, 6);
        Observer.Expect('v4', '1|1|1|1|1|1|1|1|1|1');
        Observer.Expect('v4 Amt', '1');
        Observer.Expect('v5', '12345|12345|12345|12345|12345|12345|12345|12346|12345|12345');
        Observer.Expect('v5 Amt', '12345');
        Observer.Expect('v6', '0|0|0|0|0|0|0|0|0|0');
        Observer.Expect('v6 Amt', '0');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer>', 7, 9);
        Observer.Expect('v7', '3|3|3|3|3|3|3|4|3|3');
        Observer.Expect('v7 Amt', '3');
        Observer.Expect('v8', '0|0|0|0|0|0|0|0|0|0');
        Observer.Expect('v8 Amt', '0');
        Observer.Expect('v9', '100000|100000|100000|100000|100000|99999|100000|100000|99999|99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '100000');
#else
        Observer.Expect('v9 Amt', '99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer8_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,8>', 1, 3);
        Observer.Expect('v1', '       0|       0|       0|       0|       0|       0|       0|       0|       0|       0');
        Observer.Expect('v1 Amt', '       0');
        Observer.Expect('v2', '       1|       1|       1|       1|       1|       1|       1|       1|       1|       1');
        Observer.Expect('v2 Amt', '       1');
        Observer.Expect('v3', '      12|      12|      12|      12|      12|      12|      12|      13|      12|      12');
        Observer.Expect('v3 Amt', '      12');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer8_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,8>', 4, 6);
        Observer.Expect('v4', '       1|       1|       1|       1|       1|       1|       1|       1|       1|       1');
        Observer.Expect('v4 Amt', '       1');
        Observer.Expect('v5', '   12345|   12345|   12345|   12345|   12345|   12345|   12345|   12346|   12345|   12345');
        Observer.Expect('v5 Amt', '   12345');
        Observer.Expect('v6', '       0|       0|       0|       0|       0|       0|       0|       0|       0|       0');
        Observer.Expect('v6 Amt', '       0');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Integer8_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,8>', 7, 9);
        Observer.Expect('v7', '       3|       3|       3|       3|       3|       3|       3|       4|       3|       3');
        Observer.Expect('v7 Amt', '       3');
        Observer.Expect('v8', '       0|       0|       0|       0|       0|       0|       0|       0|       0|       0');
        Observer.Expect('v8 Amt', '       0');
        Observer.Expect('v9', '  100000|  100000|  100000|  100000|  100000|   99999|  100000|  100000|   99999|   99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '  100000');
#else
        Observer.Expect('v9 Amt', '   99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerFill4_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0>', 1, 3);
        Observer.Expect('v1', '0000|0000|0000|0000|0000|0000|0000|0000|0000|0000');
        Observer.Expect('v1 Amt', '0000');
        Observer.Expect('v2', '0001|0001|0001|0001|0001|0001|0001|0001|0001|0001');
        Observer.Expect('v2 Amt', '0001');
        Observer.Expect('v3', '0012|0012|0012|0012|0012|0012|0012|0013|0012|0012');
        Observer.Expect('v3 Amt', '0012');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerFill4_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0>', 4, 6);
        Observer.Expect('v4', '0001|0001|0001|0001|0001|0001|0001|0001|0001|0001');
        Observer.Expect('v4 Amt', '0001');
        Observer.Expect('v5', '****|****|****|****|****|****|****|****|****|****');
        Observer.Expect('v5 Amt', '****');
        Observer.Expect('v6', '0000|0000|0000|0000|0000|0000|0000|0000|0000|0000');
        Observer.Expect('v6 Amt', '0000');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerFill4_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer,4><Filler character,0>', 7, 9);
        Observer.Expect('v7', '0003|0003|0003|0003|0003|0003|0003|0004|0003|0003');
        Observer.Expect('v7 Amt', '0003');
        Observer.Expect('v8', '0000|0000|0000|0000|0000|0000|0000|0000|0000|0000');
        Observer.Expect('v8 Amt', '0000');
        Observer.Expect('v9', '****|****|****|****|****|****|****|****|****|****');
        Observer.Expect('v9 Amt', '****');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal>', 1, 3);
        Observer.Expect('v1', '||.0||.00||.00|||');
#if BC28PLUS
        Observer.Expect('v1 Amt', '.00');
#else
        Observer.Expect('v1 Amt', '');
#endif
        Observer.Expect('v2', '||.0||.00||.00|||');
#if BC28PLUS
        Observer.Expect('v2 Amt', '.00');
#else
        Observer.Expect('v2 Amt', '');
#endif
        Observer.Expect('v3', '.5|.5|.5|.5|.50|.5|.50||.5|.5');
#if BC28PLUS
        Observer.Expect('v3 Amt', '.50');
#else
        Observer.Expect('v3 Amt', '.5');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal>', 4, 6);
        Observer.Expect('v4', '.2346|.23|.235|.235|.2346|.23456|.23||.23456|.23456');
#if BC28PLUS
        Observer.Expect('v4 Amt', '.23');
#else
        Observer.Expect('v4 Amt', '.23456');
#endif
        Observer.Expect('v5', '.6789|.68|.679|.679|.6789|.6789|.68||.6789|.6789');
#if BC28PLUS
        Observer.Expect('v5 Amt', '.68');
#else
        Observer.Expect('v5 Amt', '.6789');
#endif
        Observer.Expect('v6', '.0001||.0||.0001|.0001|.00||.0001|.0001');
#if BC28PLUS
        Observer.Expect('v6 Amt', '.00');
#else
        Observer.Expect('v6 Amt', '.0001');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal>', 7, 9);
        Observer.Expect('v7', '.5|.5|.5|.5|.50|.5|.50||.5|.5');
#if BC28PLUS
        Observer.Expect('v7 Amt', '.50');
#else
        Observer.Expect('v7 Amt', '.5');
#endif
        Observer.Expect('v8', '||.0||.00|.00001|.00||.00001|.00001');
#if BC28PLUS
        Observer.Expect('v8 Amt', '.00');
#else
        Observer.Expect('v8 Amt', '.00001');
#endif
        Observer.Expect('v9', '||.0||.00|.99999|.00||.99999|.99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '.00');
#else
        Observer.Expect('v9 Amt', '.99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal3_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,3>', 1, 3);
        Observer.Expect('v1', '.00|.00|.00|.00|.00|.00|.00|.00|.00|.00');
        Observer.Expect('v1 Amt', '.00');
        Observer.Expect('v2', '.00|.00|.00|.00|.00|.00|.00|.00|.00|.00');
        Observer.Expect('v2 Amt', '.00');
        Observer.Expect('v3', '.50|.50|.50|.50|.50|.50|.50|.00|.50|.50');
        Observer.Expect('v3 Amt', '.50');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal3_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,3>', 4, 6);
        Observer.Expect('v4', '***|.23|***|***|***|***|.23|.00|***|***');
#if BC28PLUS
        Observer.Expect('v4 Amt', '.23');
#else
        Observer.Expect('v4 Amt', '***');
#endif
        Observer.Expect('v5', '***|.68|***|***|***|***|.68|.00|***|***');
#if BC28PLUS
        Observer.Expect('v5 Amt', '.68');
#else
        Observer.Expect('v5 Amt', '***');
#endif
        Observer.Expect('v6', '***|.00|.00|.00|***|***|.00|.00|***|***');
#if BC28PLUS
        Observer.Expect('v6 Amt', '.00');
#else
        Observer.Expect('v6 Amt', '***');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal3_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,3>', 7, 9);
        Observer.Expect('v7', '.50|.50|.50|.50|.50|.50|.50|.00|.50|.50');
        Observer.Expect('v7 Amt', '.50');
        Observer.Expect('v8', '.00|.00|.00|.00|.00|***|.00|.00|***|***');
#if BC28PLUS
        Observer.Expect('v8 Amt', '.00');
#else
        Observer.Expect('v8 Amt', '***');
#endif
        Observer.Expect('v9', '.00|.00|.00|.00|.00|***|.00|.00|***|***');
#if BC28PLUS
        Observer.Expect('v9 Amt', '.00');
#else
        Observer.Expect('v9 Amt', '***');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal4Fill_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,4><Filler character,0>', 1, 3);
        Observer.Expect('v1', '.000|.000|.000|.000|.000|.000|.000|.000|.000|.000');
        Observer.Expect('v1 Amt', '.000');
        Observer.Expect('v2', '.000|.000|.000|.000|.000|.000|.000|.000|.000|.000');
        Observer.Expect('v2 Amt', '.000');
        Observer.Expect('v3', '.500|.500|.500|.500|.500|.500|.500|.000|.500|.500');
        Observer.Expect('v3 Amt', '.500');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal4Fill_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,4><Filler character,0>', 4, 6);
        Observer.Expect('v4', '****|.230|.235|.235|****|****|.230|.000|****|****');
#if BC28PLUS
        Observer.Expect('v4 Amt', '.230');
#else
        Observer.Expect('v4 Amt', '****');
#endif
        Observer.Expect('v5', '****|.680|.679|.679|****|****|.680|.000|****|****');
#if BC28PLUS
        Observer.Expect('v5 Amt', '.680');
#else
        Observer.Expect('v5 Amt', '****');
#endif
        Observer.Expect('v6', '****|.000|.000|.000|****|****|.000|.000|****|****');
#if BC28PLUS
        Observer.Expect('v6 Amt', '.000');
#else
        Observer.Expect('v6 Amt', '****');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_Decimal4Fill_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Decimal,4><Filler character,0>', 7, 9);
        Observer.Expect('v7', '.500|.500|.500|.500|.500|.500|.500|.000|.500|.500');
        Observer.Expect('v7 Amt', '.500');
        Observer.Expect('v8', '.000|.000|.000|.000|.000|****|.000|.000|****|****');
#if BC28PLUS
        Observer.Expect('v8 Amt', '.000');
#else
        Observer.Expect('v8 Amt', '****');
#endif
        Observer.Expect('v9', '.000|.000|.000|.000|.000|****|.000|.000|****|****');
#if BC28PLUS
        Observer.Expect('v9 Amt', '.000');
#else
        Observer.Expect('v9 Amt', '****');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerDecimal_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer><Decimal>', 1, 3);
        Observer.Expect('v1', '0|0|0.0|0|0.00|0|0.00|0|0|0');
#if BC28PLUS
        Observer.Expect('v1 Amt', '0.00');
#else
        Observer.Expect('v1 Amt', '0');
#endif
        Observer.Expect('v2', '1|1|1.0|1|1.00|1|1.00|1|1|1');
#if BC28PLUS
        Observer.Expect('v2 Amt', '1.00');
#else
        Observer.Expect('v2 Amt', '1');
#endif
        Observer.Expect('v3', '12.5|12.5|12.5|12.5|12.50|12.5|12.50|13|12.5|12.5');
#if BC28PLUS
        Observer.Expect('v3 Amt', '12.50');
#else
        Observer.Expect('v3 Amt', '12.5');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerDecimal_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer><Decimal>', 4, 6);
        Observer.Expect('v4', '1.2346|1.23|1.235|1.235|1.2346|1.23456|1.23|1|1.23456|1.23456');
#if BC28PLUS
        Observer.Expect('v4 Amt', '1.23');
#else
        Observer.Expect('v4 Amt', '1.23456');
#endif
        Observer.Expect('v5', '12345.6789|12345.68|12345.679|12345.679|12345.6789|12345.6789|12345.68|12346|12345.6789|12345.6789');
#if BC28PLUS
        Observer.Expect('v5 Amt', '12345.68');
#else
        Observer.Expect('v5 Amt', '12345.6789');
#endif
        Observer.Expect('v6', '0.0001|0|0.0|0|0.0001|0.0001|0.00|0|0.0001|0.0001');
#if BC28PLUS
        Observer.Expect('v6 Amt', '0.00');
#else
        Observer.Expect('v6 Amt', '0.0001');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerDecimal_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer><Decimal>', 7, 9);
        Observer.Expect('v7', '3.5|3.5|3.5|3.5|3.50|3.5|3.50|4|3.5|3.5');
#if BC28PLUS
        Observer.Expect('v7 Amt', '3.50');
#else
        Observer.Expect('v7 Amt', '3.5');
#endif
        Observer.Expect('v8', '0|0|0.0|0|0.00|0.00001|0.00|0|0.00001|0.00001');
#if BC28PLUS
        Observer.Expect('v8 Amt', '0.00');
#else
        Observer.Expect('v8 Amt', '0.00001');
#endif
        Observer.Expect('v9', '100000|100000|100000.0|100000|100000.00|99999.99999|100000.00|100000|99999.99999|99999.99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '100000.00');
#else
        Observer.Expect('v9 Amt', '99999.99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_SignIntegerDecimal_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Sign><Integer><Decimal>', 1, 3);
        Observer.Expect('v1', '0|0|0.0|0|0.00|0|0.00|0|0|0');
#if BC28PLUS
        Observer.Expect('v1 Amt', '0.00');
#else
        Observer.Expect('v1 Amt', '0');
#endif
        Observer.Expect('v2', '1|1|1.0|1|1.00|1|1.00|1|1|1');
#if BC28PLUS
        Observer.Expect('v2 Amt', '1.00');
#else
        Observer.Expect('v2 Amt', '1');
#endif
        Observer.Expect('v3', '12.5|12.5|12.5|12.5|12.50|12.5|12.50|13|12.5|12.5');
#if BC28PLUS
        Observer.Expect('v3 Amt', '12.50');
#else
        Observer.Expect('v3 Amt', '12.5');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_SignIntegerDecimal_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Sign><Integer><Decimal>', 4, 6);
        Observer.Expect('v4', '1.2346|1.23|1.235|1.235|1.2346|1.23456|1.23|1|1.23456|1.23456');
#if BC28PLUS
        Observer.Expect('v4 Amt', '1.23');
#else
        Observer.Expect('v4 Amt', '1.23456');
#endif
        Observer.Expect('v5', '12345.6789|12345.68|12345.679|12345.679|12345.6789|12345.6789|12345.68|12346|12345.6789|12345.6789');
#if BC28PLUS
        Observer.Expect('v5 Amt', '12345.68');
#else
        Observer.Expect('v5 Amt', '12345.6789');
#endif
        Observer.Expect('v6', '0.0001|0|0.0|0|0.0001|0.0001|0.00|0|0.0001|0.0001');
#if BC28PLUS
        Observer.Expect('v6 Amt', '0.00');
#else
        Observer.Expect('v6 Amt', '0.0001');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_SignIntegerDecimal_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Sign><Integer><Decimal>', 7, 9);
        Observer.Expect('v7', '-3.5|-3.5|-3.5|-3.5|-3.50|-3.5|-3.50|-4|-3.5|-3.5');
#if BC28PLUS
        Observer.Expect('v7 Amt', '-3.50');
#else
        Observer.Expect('v7 Amt', '-3.5');
#endif
        Observer.Expect('v8', '-0|-0|-0.0|-0|-0.00|-0.00001|-0.00|-0|-0.00001|-0.00001');
#if BC28PLUS
        Observer.Expect('v8 Amt', '-0.00');
#else
        Observer.Expect('v8 Amt', '-0.00001');
#endif
        Observer.Expect('v9', '100000|100000|100000.0|100000|100000.00|99999.99999|100000.00|100000|99999.99999|99999.99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '100000.00');
#else
        Observer.Expect('v9 Amt', '99999.99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerThousandDecimal_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer Thousand><Decimal>', 1, 3);
        Observer.Expect('v1', '0|0|0.0|0|0.00|0|0.00|0|0|0');
#if BC28PLUS
        Observer.Expect('v1 Amt', '0.00');
#else
        Observer.Expect('v1 Amt', '0');
#endif
        Observer.Expect('v2', '1|1|1.0|1|1.00|1|1.00|1|1|1');
#if BC28PLUS
        Observer.Expect('v2 Amt', '1.00');
#else
        Observer.Expect('v2 Amt', '1');
#endif
        Observer.Expect('v3', '12.5|12.5|12.5|12.5|12.50|12.5|12.50|13|12.5|12.5');
#if BC28PLUS
        Observer.Expect('v3 Amt', '12.50');
#else
        Observer.Expect('v3 Amt', '12.5');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerThousandDecimal_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer Thousand><Decimal>', 4, 6);
        Observer.Expect('v4', '1.2346|1.23|1.235|1.235|1.2346|1.23456|1.23|1|1.23456|1.23456');
#if BC28PLUS
        Observer.Expect('v4 Amt', '1.23');
#else
        Observer.Expect('v4 Amt', '1.23456');
#endif
        Observer.Expect('v5', '12,345.6789|12,345.68|12,345.679|12,345.679|12,345.6789|12,345.6789|12,345.68|12,346|12,345.6789|12,345.6789');
#if BC28PLUS
        Observer.Expect('v5 Amt', '12,345.68');
#else
        Observer.Expect('v5 Amt', '12,345.6789');
#endif
        Observer.Expect('v6', '0.0001|0|0.0|0|0.0001|0.0001|0.00|0|0.0001|0.0001');
#if BC28PLUS
        Observer.Expect('v6 Amt', '0.00');
#else
        Observer.Expect('v6 Amt', '0.0001');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_IntegerThousandDecimal_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Integer Thousand><Decimal>', 7, 9);
        Observer.Expect('v7', '3.5|3.5|3.5|3.5|3.50|3.5|3.50|4|3.5|3.5');
#if BC28PLUS
        Observer.Expect('v7 Amt', '3.50');
#else
        Observer.Expect('v7 Amt', '3.5');
#endif
        Observer.Expect('v8', '0|0|0.0|0|0.00|0.00001|0.00|0|0.00001|0.00001');
#if BC28PLUS
        Observer.Expect('v8 Amt', '0.00');
#else
        Observer.Expect('v8 Amt', '0.00001');
#endif
        Observer.Expect('v9', '100,000|100,000|100,000.0|100,000|100,000.00|99,999.99999|100,000.00|100,000|99,999.99999|99,999.99999');
#if BC28PLUS
        Observer.Expect('v9 Amt', '100,000.00');
#else
        Observer.Expect('v9 Amt', '99,999.99999');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure R6901_PrecisionControl_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Precision,2:4><Integer><Decimal>', 1, 3);
        Observer.Expect('v1', '0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00');
        Observer.Expect('v1 Amt', '0.00');
        Observer.Expect('v2', '1.00|1.00|1.00|1.00|1.00|1.00|1.00|1.00|1.00|1.00');
        Observer.Expect('v2 Amt', '1.00');
        Observer.Expect('v3', '12.50|12.50|12.50|12.50|12.50|12.50|12.50|12.50|12.50|12.50');
        Observer.Expect('v3 Amt', '12.50');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_PrecisionControl_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Precision,2:4><Integer><Decimal>', 4, 6);
        Observer.Expect('v4', '1.2346|1.2346|1.2346|1.2346|1.2346|1.2346|1.2346|1.2346|1.2346|1.2346');
        Observer.Expect('v4 Amt', '1.2346');
        Observer.Expect('v5', '12345.6789|12345.6789|12345.6789|12345.6789|12345.6789|12345.6789|12345.6789|12345.6789|12345.6789|12345.6789');
        Observer.Expect('v5 Amt', '12345.6789');
        Observer.Expect('v6', '0.0001|0.0001|0.0001|0.0001|0.0001|0.0001|0.0001|0.0001|0.0001|0.0001');
        Observer.Expect('v6 Amt', '0.0001');
        Observer.Verify();
    end;

    [Test]
    procedure R6901_PrecisionControl_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, 0, '<Precision,2:4><Integer><Decimal>', 7, 9);
        Observer.Expect('v7', '3.50|3.50|3.50|3.50|3.50|3.50|3.50|3.50|3.50|3.50');
        Observer.Expect('v7 Amt', '3.50');
        Observer.Expect('v8', '0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00|0.00');
        Observer.Expect('v8 Amt', '0.00');
        Observer.Expect('v9', '100000.00|100000.00|100000.00|100000.00|100000.00|100000.00|100000.00|100000.00|100000.00|100000.00');
        Observer.Expect('v9 Amt', '100000.00');
        Observer.Verify();
    end;
}
