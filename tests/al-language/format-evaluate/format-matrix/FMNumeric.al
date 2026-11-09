// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on Integer, BigInteger and Decimal. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72830 "LT FM Numeric"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryN(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    [TryFunction]
    local procedure TryS(V: Variant; S: Text; var R: Text)
    begin
        R := Format(V, 0, S);
    end;

    local procedure CellN(var O: Codeunit "Probe Observer"; Name: Text; V: Variant; N: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryN(V, N, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure CellS(var O: Codeunit "Probe Observer"; Name: Text; V: Variant; S: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryS(V, S, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    [Test]
    procedure Format_Integer_0_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_0_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_neg1_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_neg1_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1234_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1234_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_max_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 2147483647;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_max_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 2147483647;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_min_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -2147483647-1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_min_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -2147483647-1;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_0_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_0_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_neg1_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_neg1_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_1234567890123_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567890123L;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_1234567890123_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567890123L;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_max_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 9223372036854775807L;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_max_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 9223372036854775807L;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_5_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0.5;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_5_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0.5;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_neg1234_5_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1234.5;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_neg1234_5_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -1234.5;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567_891_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567.891;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567_891_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567.891;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_000001_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0.000001;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_0_000001_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 0.000001;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567890123_45_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567890123.45;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567890123_45_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1234567890123.45;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_neg0_5_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -0.5;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_neg0_5_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := -0.5;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1000_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1000;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1000_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 1000;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1234_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Integer_1234_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_1234567890123_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234567890123L;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_BigInteger_1234567890123_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: BigInteger;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234567890123L;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567_891_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234567.891;
        CellN(O, 'n0', V, 0);
        CellN(O, 'n1', V, 1);
        CellN(O, 'n2', V, 2);
        CellN(O, 'n3', V, 3);
        CellN(O, 'n4', V, 4);
        CellN(O, 'n5', V, 5);
        CellN(O, 'n6', V, 6);
        CellN(O, 'n7', V, 7);
        CellN(O, 'n8', V, 8);
        CellN(O, 'n9', V, 9);
        CellN(O, 'n10', V, 10);
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer Thousand>', V, '<Integer Thousand>');
        CellS(O, '<Integer,6>', V, '<Integer,6>');
        CellS(O, '<Integer,6><Filler Character,0>', V, '<Integer,6><Filler Character,0>');
        CellS(O, '<Sign><Integer>', V, '<Sign><Integer>');
        CellS(O, '<Sign,1><Integer>', V, '<Sign,1><Integer>');
        CellS(O, '<Sign><Integer><Decimals>', V, '<Sign><Integer><Decimals>');
        CellS(O, '<Sign><Integer><Decimals,3>', V, '<Sign><Integer><Decimals,3>');
        CellS(O, '<Integer><Decimals><Comma,,>', V, '<Integer><Decimals><Comma,,>');
        CellS(O, '<Integer><Comma,.><Decimals>', V, '<Integer><Comma,.><Decimals>');
        CellS(O, '<Integer Thousand><Decimals,2>', V, '<Integer Thousand><Decimals,2>');
        CellS(O, '<Integer><1000Character,.>', V, '<Integer><1000Character,.>');
        CellS(O, '<Integer><1000Character,.><Decimals><Comma,,>', V, '<Integer><1000Character,.><Decimals><Comma,,>');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Format_Decimal_1234567_891_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Decimal;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 1234567.891;
        CellS(O, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>', V, '<Sign><Integer><1000Character,.><Decimal,3><Comma,,>');
        CellS(O, '<Integer><1000Character,,><Decimal,3><Comma,.>', V, '<Integer><1000Character,,><Decimal,3><Comma,.>');
        CellS(O, '<Integer><Decimals><Comma>', V, '<Integer><Decimals><Comma>');
        CellS(O, '<Integer Thousand><Comma,.>', V, '<Integer Thousand><Comma,.>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Decimals,2>', V, '<Decimals,2>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Precision,2:2><Standard Format,0>', V, '<Precision,2:2><Standard Format,0>');
        CellS(O, '<Precision,0:3><Standard Format,1>', V, '<Precision,0:3><Standard Format,1>');
        CellS(O, '<Precision,2><Standard Format,2>', V, '<Precision,2><Standard Format,2>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, 'x<Integer>y', V, 'x<Integer>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
