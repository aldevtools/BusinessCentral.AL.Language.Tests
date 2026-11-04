// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 80004; writer QS: table 87356 (tests QS_*); writer RO: table 88442 (tests RO_*)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Format(D, 0, '<Precision,2:2><Standard Format,2>') for a Decimal D: 0, 1234.5, -1, and the rounding and grouping edges 1234.567,
// 0.005, 1234567.1 and -0.5.
// BC versions: 27, 28, 29

// Writer QS: Decimal fields with AutoFormatType 1 (amount), 2 (unit amount), 10 with an AutoFormatExpression, and DecimalPlaces 0:5.
table 87356 "LT QS Std Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal) { AutoFormatType = 1; }
        field(3; UnitAmt; Decimal) { AutoFormatType = 2; }
        field(4; Custom; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,1:1><Standard Format,0>'; }
        field(5; Dec5; Decimal) { DecimalPlaces = 0 : 5; }
        field(6; Plain; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 80004 "LT AT Precision Std Format 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure F(D: Decimal): Text
    begin
        exit(Format(D, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    [Test]
    procedure AT_Precision22_StandardFormat2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', F(0));
        Observer.Observe('1234.5', F(1234.5));
        Observer.Observe('-1', F(-1));
        Observer.Observe('1234.567', F(1234.567));
        Observer.Observe('0.005', F(0.005));
        Observer.Observe('1234567.1', F(1234567.1));
        Observer.Observe('-0.5', F(-0.5));
        Observer.Expect('0', '0.00');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('1234.567', '1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('1234567.1', '1234567.10');
        Observer.Expect('-0.5', '-0.50');
        Observer.Verify();
    end;

    local procedure QsObserveValues(var Observer: Codeunit "Probe Observer"; Spec: Text)
    var
        D: Decimal;
    begin
        D := 0;
        Observer.Observe('0', Format(D, 0, Spec));
        D := 1;
        Observer.Observe('1', Format(D, 0, Spec));
        D := -1;
        Observer.Observe('-1', Format(D, 0, Spec));
        D := 10;
        Observer.Observe('10', Format(D, 0, Spec));
        D := 10.00000;
        Observer.Observe('10.00000', Format(D, 0, Spec));
        D := 0.1;
        Observer.Observe('0.1', Format(D, 0, Spec));
        D := 1234.5;
        Observer.Observe('1234.5', Format(D, 0, Spec));
        D := -1234.567;
        Observer.Observe('-1234.567', Format(D, 0, Spec));
        D := 0.005;
        Observer.Observe('0.005', Format(D, 0, Spec));
        D := 0.015;
        Observer.Observe('0.015', Format(D, 0, Spec));
        D := 0.025;
        Observer.Observe('0.025', Format(D, 0, Spec));
        D := -0.005;
        Observer.Observe('-0.005', Format(D, 0, Spec));
        D := 0.004999;
        Observer.Observe('0.004999', Format(D, 0, Spec));
        D := 999999.995;
        Observer.Observe('999999.995', Format(D, 0, Spec));
        D := 123456789012.345;
        Observer.Observe('123456789012.345', Format(D, 0, Spec));
        D := -99999999999999.99;
        Observer.Observe('-99999999999999.99', Format(D, 0, Spec));
        Evaluate(D, '10.00000', 9);
        Observer.Observe('evaluated 10.00000', Format(D, 0, Spec));
        D := 1 / 3;
        Observer.Observe('1/3', Format(D, 0, Spec));
    end;

    [Test]
    procedure QS_P22S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0');
        Observer.Expect('1', '1');
        Observer.Expect('-1', '-1');
        Observer.Expect('10', '10');
        Observer.Expect('10.00000', '10');
        Observer.Expect('0.1', '0.1');
        Observer.Expect('1234.5', '1234.5');
        Observer.Expect('-1234.567', '-1234.567');
        Observer.Expect('0.005', '0.005');
        Observer.Expect('0.015', '0.015');
        Observer.Expect('0.025', '0.025');
        Observer.Expect('-0.005', '-0.005');
        Observer.Expect('0.004999', '0.004999');
        Observer.Expect('999999.995', '999999.995');
        Observer.Expect('123456789012.345', '123456789012.345');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10');
        Observer.Expect('1/3', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S0_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S0_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S1_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S1_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S9_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S9_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0');
        Observer.Expect('1', '1');
        Observer.Expect('-1', '-1');
        Observer.Expect('10', '10');
        Observer.Expect('10.00000', '10');
        Observer.Expect('0.1', '0.1');
        Observer.Expect('1234.5', '1234.5');
        Observer.Expect('-1234.567', '-1234.567');
        Observer.Expect('0.005', '0.005');
        Observer.Expect('0.015', '0.015');
        Observer.Expect('0.025', '0.025');
        Observer.Expect('-0.005', '-0.005');
        Observer.Expect('0.004999', '0.004999');
        Observer.Expect('999999.995', '999999.995');
        Observer.Expect('123456789012.345', '123456789012.345');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10');
        Observer.Expect('1/3', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S0_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S0_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S1_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S1_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S9_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S9_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_AutoFormatFields_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Std Fmt Row";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        Row.Amt := 1234.5678;
        Row.UnitAmt := 1234.5678;
        Row.Custom := 1234.5678;
        Row.Dec5 := 1234.5678;
        Row.Plain := 1234.5678;
        QsObserveRow(Observer, 'a', Row);
        Row.Amt := -0.005;
        Row.UnitAmt := -0.005;
        Row.Custom := -0.005;
        Row.Dec5 := -0.005;
        Row.Plain := -0.005;
        QsObserveRow(Observer, 'b', Row);
        GlobalLanguage(Orig);
#if BC29PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#elif BC28PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#else
        Observer.Expect('a default', '1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.005|-0.005|-0.0|-0.005|-0.005');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure QS_AutoFormatFields_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Std Fmt Row";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        Row.Amt := 1234.5678;
        Row.UnitAmt := 1234.5678;
        Row.Custom := 1234.5678;
        Row.Dec5 := 1234.5678;
        Row.Plain := 1234.5678;
        QsObserveRow(Observer, 'a', Row);
        Row.Amt := -0.005;
        Row.UnitAmt := -0.005;
        Row.Custom := -0.005;
        Row.Dec5 := -0.005;
        Row.Plain := -0.005;
        QsObserveRow(Observer, 'b', Row);
        GlobalLanguage(Orig);
#if BC29PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#elif BC28PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#else
        Observer.Expect('a default', '1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.005|-0.005|-0.0|-0.005|-0.005');
#endif
        Observer.Verify();
    end;

    local procedure QsObserveRow(var Observer: Codeunit "Probe Observer"; Prefix: Text; Row: Record "LT QS Std Fmt Row")
    begin
        Observer.Observe(Prefix + ' default', Format(Row.Amt) + '|' + Format(Row.UnitAmt) + '|' + Format(Row.Custom) + '|' + Format(Row.Dec5) + '|' + Format(Row.Plain));
        Observer.Observe(Prefix + ' P22S2', Format(Row.Amt, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Precision,2:2><Standard Format,2>'));
        Observer.Observe(Prefix + ' P2S2', Format(Row.Amt, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Precision,2><Standard Format,2>'));
        Observer.Observe(Prefix + ' S2', Format(Row.Amt, 0, '<Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Standard Format,2>'));
        Observer.Observe(Prefix + ' number 2', Format(Row.Amt, 0, 2) + '|' + Format(Row.UnitAmt, 0, 2) + '|' + Format(Row.Custom, 0, 2) + '|' + Format(Row.Dec5, 0, 2) + '|' + Format(Row.Plain, 0, 2));
        Observer.Observe(Prefix + ' number 9', Format(Row.Amt, 0, 9) + '|' + Format(Row.UnitAmt, 0, 9) + '|' + Format(Row.Custom, 0, 9) + '|' + Format(Row.Dec5, 0, 9) + '|' + Format(Row.Plain, 0, 9));
    end;

    // Writer RO (al-runner issue 5737): Format(Rec.Field, 0, '<format string>') of Decimal fields that declare their places
    // (DecimalPlaces, AutoFormatType) with format strings other than <Precision,..> and <Standard Format,2>.
    [Test]
    procedure RO_IntegerOfDecimalPlacesField_Repro()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Std Fmt Row";
        Actual: Text;
    begin
        Row.Dec5 := 5;
        Actual := Format(Row.Dec5, 0, '<Integer>');
        Row.Dec5 := 1234;
        Actual += '|' + Format(Row.Dec5, 0, '<Integer>');
        Observer.Observe('Dec5 5|1234', Actual);
        Observer.Expect('Dec5 5|1234', '5|1234');
        Observer.Verify();
    end;

    local procedure RoQsRow(Row: Record "LT QS Std Fmt Row"; Spec: Text): Text
    begin
        exit(Format(Row.Amt, 0, Spec) + '|' + Format(Row.UnitAmt, 0, Spec) + '|' + Format(Row.Custom, 0, Spec) + '|' + Format(Row.Dec5, 0, Spec) + '|' + Format(Row.Plain, 0, Spec));
    end;

    local procedure RoRoRow(Row: Record "LT RO Fmt Row"; Spec: Text): Text
    begin
        exit(Format(Row.DP22, 0, Spec) + '|' + Format(Row.DP00, 0, Spec) + '|' + Format(Row.DP35, 0, Spec) + '|' + Format(Row.DP05, 0, Spec));
    end;

    // Each observation: the values 5 ; 1234 ; 1234.5678 ; -0.5 ; 0 ; -1234567.25, each as Amt|UnitAmt|Custom|Dec5|Plain.
    local procedure RoQsValues(var Observer: Codeunit "Probe Observer"; Spec: Text)
    var
        Row: Record "LT QS Std Fmt Row";
        Values: List of [Decimal];
        D: Decimal;
        Line: Text;
    begin
        Values.Add(5);
        Values.Add(1234);
        Values.Add(1234.5678);
        Values.Add(-0.5);
        Values.Add(0);
        Values.Add(-1234567.25);
        foreach D in Values do begin
            Row.Amt := D;
            Row.UnitAmt := D;
            Row.Custom := D;
            Row.Dec5 := D;
            Row.Plain := D;
            if Line <> '' then
                Line += ' ; ';
            Line += RoQsRow(Row, Spec);
        end;
        Observer.Observe(Spec, Line);
    end;

    // Each observation: the same values, each as DP22|DP00|DP35|DP05.
    local procedure RoRoValues(var Observer: Codeunit "Probe Observer"; Spec: Text)
    var
        Row: Record "LT RO Fmt Row";
        Values: List of [Decimal];
        D: Decimal;
        Line: Text;
    begin
        Values.Add(5);
        Values.Add(1234);
        Values.Add(1234.5678);
        Values.Add(-0.5);
        Values.Add(0);
        Values.Add(-1234567.25);
        foreach D in Values do begin
            Row.DP22 := D;
            Row.DP00 := D;
            Row.DP35 := D;
            Row.DP05 := D;
            if Line <> '' then
                Line += ' ; ';
            Line += RoRoRow(Row, Spec);
        end;
        Observer.Observe(Spec, Line);
    end;

    [Test]
    procedure RO_FieldFormatStrings_AutoFormatFields_EnUs_1()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoQsValues(Observer, '<Integer>');
        RoQsValues(Observer, '<Integer Thousand>');
        GlobalLanguage(Orig);
        Observer.Expect('<Integer>', '5|5|5|5|5 ; 1234|1234|1234|1234|1234 ; 1234|1234|1234|1234|1234 ; 0|0|0|0|0 ; 0|0|0|0|0 ; 1234567|1234567|1234567|1234567|1234567');
        Observer.Expect('<Integer Thousand>', '5|5|5|5|5 ; 1,234|1,234|1,234|1,234|1,234 ; 1,234|1,234|1,234|1,234|1,234 ; 0|0|0|0|0 ; 0|0|0|0|0 ; 1,234,567|1,234,567|1,234,567|1,234,567|1,234,567');
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_AutoFormatFields_EnUs_2()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoQsValues(Observer, '<Decimals>');
        RoQsValues(Observer, '<Integer><Decimals>');
        GlobalLanguage(Orig);
#if BC28PLUS
        Observer.Expect('<Decimals>', '.00|.00|.0|| ; .00|.00|.0|| ; .57|.5678|.6|.5678|.5678 ; .50|.50|.5|.5|.5 ; .00|.00|.0|| ; .25|.25|.3|.25|.25');
        Observer.Expect('<Integer><Decimals>', '5.00|5.00|5.0|5|5 ; 1234.00|1234.00|1234.0|1234|1234 ; 1234.57|1234.5678|1234.6|1234.5678|1234.5678 ; 0.50|0.50|0.5|0.5|0.5 ; 0.00|0.00|0.0|0|0 ; 1234567.25|1234567.25|1234567.3|1234567.25|1234567.25');
#else
        Observer.Expect('<Decimals>', '|.00|.0|| ; |.00|.0|| ; .5678|.5678|.6|.5678|.5678 ; .5|.50|.5|.5|.5 ; |.00|.0|| ; .25|.25|.3|.25|.25');
        Observer.Expect('<Integer><Decimals>', '5|5.00|5.0|5|5 ; 1234|1234.00|1234.0|1234|1234 ; 1234.5678|1234.5678|1234.6|1234.5678|1234.5678 ; 0.5|0.50|0.5|0.5|0.5 ; 0|0.00|0.0|0|0 ; 1234567.25|1234567.25|1234567.3|1234567.25|1234567.25');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_AutoFormatFields_EnUs_3()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoQsValues(Observer, '<Sign><Integer Thousand><Decimals>');
        RoQsValues(Observer, '<Standard Format,0>');
        GlobalLanguage(Orig);
#if BC28PLUS
        Observer.Expect('<Sign><Integer Thousand><Decimals>', '5.00|5.00|5.0|5|5 ; 1,234.00|1,234.00|1,234.0|1,234|1,234 ; 1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678 ; -0.50|-0.50|-0.5|-0.5|-0.5 ; 0.00|0.00|0.0|0|0 ; -1,234,567.25|-1,234,567.25|-1,234,567.3|-1,234,567.25|-1,234,567.25');
        Observer.Expect('<Standard Format,0>', '5.00|5.00|5.0|5|5 ; 1,234.00|1,234.00|1,234.0|1,234|1,234 ; 1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678 ; -0.50|-0.50|-0.5|-0.5|-0.5 ; 0.00|0.00|0.0|0|0 ; -1,234,567.25|-1,234,567.25|-1,234,567.3|-1,234,567.25|-1,234,567.25');
#else
        Observer.Expect('<Sign><Integer Thousand><Decimals>', '5|5.00|5.0|5|5 ; 1,234|1,234.00|1,234.0|1,234|1,234 ; 1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678 ; -0.5|-0.50|-0.5|-0.5|-0.5 ; 0|0.00|0.0|0|0 ; -1,234,567.25|-1,234,567.25|-1,234,567.3|-1,234,567.25|-1,234,567.25');
        Observer.Expect('<Standard Format,0>', '5|5.00|5.0|5|5 ; 1,234|1,234.00|1,234.0|1,234|1,234 ; 1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678 ; -0.5|-0.50|-0.5|-0.5|-0.5 ; 0|0.00|0.0|0|0 ; -1,234,567.25|-1,234,567.25|-1,234,567.3|-1,234,567.25|-1,234,567.25');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_AutoFormatFields_EnUs_4()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoQsValues(Observer, '<Standard Format,1>');
        RoQsValues(Observer, '<Standard Format,9>');
        GlobalLanguage(Orig);
#if BC28PLUS
        Observer.Expect('<Standard Format,1>', '5.00|5.00|5.0|5|5 ; 1234.00|1234.00|1234.0|1234|1234 ; 1234.57|1234.5678|1234.6|1234.5678|1234.5678 ; -0.50|-0.50|-0.5|-0.5|-0.5 ; 0.00|0.00|0.0|0|0 ; -1234567.25|-1234567.25|-1234567.3|-1234567.25|-1234567.25');
        Observer.Expect('<Standard Format,9>', '5.00|5.00|5.0|5|5 ; 1234.00|1234.00|1234.0|1234|1234 ; 1234.57|1234.5678|1234.6|1234.5678|1234.5678 ; -0.50|-0.50|-0.5|-0.5|-0.5 ; 0.00|0.00|0.0|0|0 ; -1234567.25|-1234567.25|-1234567.3|-1234567.25|-1234567.25');
#else
        Observer.Expect('<Standard Format,1>', '5|5.00|5.0|5|5 ; 1234|1234.00|1234.0|1234|1234 ; 1234.5678|1234.5678|1234.6|1234.5678|1234.5678 ; -0.5|-0.50|-0.5|-0.5|-0.5 ; 0|0.00|0.0|0|0 ; -1234567.25|-1234567.25|-1234567.3|-1234567.25|-1234567.25');
        Observer.Expect('<Standard Format,9>', '5|5.00|5.0|5|5 ; 1234|1234.00|1234.0|1234|1234 ; 1234.5678|1234.5678|1234.6|1234.5678|1234.5678 ; -0.5|-0.50|-0.5|-0.5|-0.5 ; 0|0.00|0.0|0|0 ; -1234567.25|-1234567.25|-1234567.3|-1234567.25|-1234567.25');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_DecimalPlacesFields_EnUs_1()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoRoValues(Observer, '<Integer>');
        RoRoValues(Observer, '<Integer Thousand>');
        RoRoValues(Observer, '<Decimals>');
        GlobalLanguage(Orig);
        Observer.Expect('<Integer>', '5|5|5|5 ; 1234|1234|1234|1234 ; 1234|1235|1234|1234 ; 0|1|0|0 ; 0|0|0|0 ; 1234567|1234567|1234567|1234567');
        Observer.Expect('<Integer Thousand>', '5|5|5|5 ; 1,234|1,234|1,234|1,234 ; 1,234|1,235|1,234|1,234 ; 0|1|0|0 ; 0|0|0|0 ; 1,234,567|1,234,567|1,234,567|1,234,567');
        Observer.Expect('<Decimals>', '.00||.000| ; .00||.000| ; .57||.5678|.5678 ; .50||.500|.5 ; .00||.000| ; .25||.250|.25');
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_DecimalPlacesFields_EnUs_2()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoRoValues(Observer, '<Integer><Decimals>');
        RoRoValues(Observer, '<Sign><Integer Thousand><Decimals>');
        RoRoValues(Observer, '<Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('<Integer><Decimals>', '5.00|5|5.000|5 ; 1234.00|1234|1234.000|1234 ; 1234.57|1235|1234.5678|1234.5678 ; 0.50|1|0.500|0.5 ; 0.00|0|0.000|0 ; 1234567.25|1234567|1234567.250|1234567.25');
        Observer.Expect('<Sign><Integer Thousand><Decimals>', '5.00|5|5.000|5 ; 1,234.00|1,234|1,234.000|1,234 ; 1,234.57|1,235|1,234.5678|1,234.5678 ; -0.50|-1|-0.500|-0.5 ; 0.00|0|0.000|0 ; -1,234,567.25|-1,234,567|-1,234,567.250|-1,234,567.25');
        Observer.Expect('<Standard Format,0>', '5.00|5|5.000|5 ; 1,234.00|1,234|1,234.000|1,234 ; 1,234.57|1,235|1,234.5678|1,234.5678 ; -0.50|-1|-0.500|-0.5 ; 0.00|0|0.000|0 ; -1,234,567.25|-1,234,567|-1,234,567.250|-1,234,567.25');
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_DecimalPlacesFields_EnUs_3()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoRoValues(Observer, '<Standard Format,1>');
        RoRoValues(Observer, '<Standard Format,9>');
        RoRoValues(Observer, '<Integer Thousand><Decimals,3>');
        GlobalLanguage(Orig);
        Observer.Expect('<Standard Format,1>', '5.00|5|5.000|5 ; 1234.00|1234|1234.000|1234 ; 1234.57|1235|1234.5678|1234.5678 ; -0.50|-1|-0.500|-0.5 ; 0.00|0|0.000|0 ; -1234567.25|-1234567|-1234567.250|-1234567.25');
        Observer.Expect('<Standard Format,9>', '5.00|5|5.000|5 ; 1234.00|1234|1234.000|1234 ; 1234.57|1235|1234.5678|1234.5678 ; -0.50|-1|-0.500|-0.5 ; 0.00|0|0.000|0 ; -1234567.25|-1234567|-1234567.250|-1234567.25');
        Observer.Expect('<Integer Thousand><Decimals,3>', '5.00|5.00|5.00|5.00 ; 1,234.00|1,234.00|1,234.00|1,234.00 ; 1,234.57|1,235.00|1,234***|1,234*** ; 0.50|1.00|0.50|0.50 ; 0.00|0.00|0.00|0.00 ; 1,234,567.25|1,234,567.00|1,234,567.25|1,234,567.25');
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_DecimalPlacesFields_EnUs_4()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        RoRoValues(Observer, '<Integer>.<Decimals>');
        GlobalLanguage(Orig);
        Observer.Expect('<Integer>.<Decimals>', '5..00|5.|5..000|5. ; 1234..00|1234.|1234..000|1234. ; 1234..57|1235.|1234..5678|1234..5678 ; 0..50|1.|0..500|0..5 ; 0..00|0.|0..000|0. ; 1234567..25|1234567.|1234567..250|1234567..25');
        Observer.Verify();
    end;

    [Test]
    procedure RO_FieldFormatStrings_DecimalPlacesFields_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        RoRoValues(Observer, '<Integer Thousand>');
        RoRoValues(Observer, '<Integer><Decimals>');
        RoRoValues(Observer, '<Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('<Integer Thousand>', '5|5|5|5 ; 1,234|1,234|1,234|1,234 ; 1,234|1,235|1,234|1,234 ; 0|1|0|0 ; 0|0|0|0 ; 1,234,567|1,234,567|1,234,567|1,234,567');
        Observer.Expect('<Integer><Decimals>', '5.00|5|5.000|5 ; 1234.00|1234|1234.000|1234 ; 1234.57|1235|1234.5678|1234.5678 ; 0.50|1|0.500|0.5 ; 0.00|0|0.000|0 ; 1234567.25|1234567|1234567.250|1234567.25');
        Observer.Expect('<Standard Format,0>', '5.00|5|5.000|5 ; 1,234.00|1,234|1,234.000|1,234 ; 1,234.57|1,235|1,234.5678|1,234.5678 ; -0.50|-1|-0.500|-0.5 ; 0.00|0|0.000|0 ; -1,234,567.25|-1,234,567|-1,234,567.250|-1,234,567.25');
        Observer.Verify();
    end;
}

// Writer RO: Decimal fields with DecimalPlaces 2:2, 0:0, 3:5 and 0:5 (al-runner issue 5737).
table 88442 "LT RO Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DP22; Decimal) { DecimalPlaces = 2 : 2; }
        field(3; DP00; Decimal) { DecimalPlaces = 0 : 0; }
        field(4; DP35; Decimal) { DecimalPlaces = 3 : 5; }
        field(5; DP05; Decimal) { DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
