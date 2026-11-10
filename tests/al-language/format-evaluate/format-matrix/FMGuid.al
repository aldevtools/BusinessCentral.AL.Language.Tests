// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on Boolean, Enum, Option, Guid, Char, Text and Code. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72853 "LT FM Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryN(V: Guid; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    [TryFunction]
    local procedure TryS(V: Guid; S: Text; var R: Text)
    begin
        R := Format(V, 0, S);
    end;

    local procedure CellN(var O: Codeunit "Probe Observer"; Name: Text; V: Guid; N: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryN(V, N, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure CellS(var O: Codeunit "Probe Observer"; Name: Text; V: Guid; S: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryS(V, S, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure EmptyGuid(): Guid
    var
        G: Guid;
    begin
        exit(G);
    end;

    local procedure SomeGuid(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{12345678-1234-5678-9ABC-DEF012345678}');
        exit(G);
    end;

    [Test]
    procedure Format_Guid_empty_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := EmptyGuid();
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
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Text,10>', V, '<Text,10>');
        CellS(O, '<Text,3>', V, '<Text,3>');
        CellS(O, '<Filler Character,x><Text,10>', V, '<Filler Character,x><Text,10>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer,5>', V, '<Integer,5>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('n1', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('n2', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('n3', 'ok:00000000000000000000000000000000');
        O.Expect('n4', 'ok:00000000-0000-0000-0000-000000000000');
        O.Expect('n5', 'ok:(00000000-0000-0000-0000-000000000000)');
        O.Expect('n6', 'ok:{0X00000000,0X0000,0X0000,{0X00,0X00,0X00,0X00,0X00,0X00,0X00,0X00}}');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('<Text,10>', 'err:InvalidFormatString');
        O.Expect('<Text,3>', 'err:InvalidFormatString');
        O.Expect('<Filler Character,x><Text,10>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('<Standard Format,1>', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('<Standard Format,2>', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('<Standard Format,3>', 'ok:00000000000000000000000000000000');
        O.Expect('<Standard Format,4>', 'ok:00000000-0000-0000-0000-000000000000');
        O.Verify();
    end;

    [Test]
    procedure Format_Guid_empty_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := EmptyGuid();
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:{00000000-0000-0000-0000-000000000000}');
        O.Expect('x<Text>y', 'err:InvalidFormatString');
        O.Expect('literal', 'err:InvalidStandardFormat');
        O.Expect('', 'err:InvalidStandardFormat');
        O.Expect('<Precision,2:2>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Guid_value_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := SomeGuid();
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
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Text,10>', V, '<Text,10>');
        CellS(O, '<Text,3>', V, '<Text,3>');
        CellS(O, '<Filler Character,x><Text,10>', V, '<Filler Character,x><Text,10>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer,5>', V, '<Integer,5>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n1', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n2', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n3', 'ok:12345678123456789ABCDEF012345678');
        O.Expect('n4', 'ok:12345678-1234-5678-9ABC-DEF012345678');
        O.Expect('n5', 'ok:(12345678-1234-5678-9ABC-DEF012345678)');
        O.Expect('n6', 'ok:{0X12345678,0X1234,0X5678,{0X9A,0XBC,0XDE,0XF0,0X12,0X34,0X56,0X78}}');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('<Text,10>', 'err:InvalidFormatString');
        O.Expect('<Text,3>', 'err:InvalidFormatString');
        O.Expect('<Filler Character,x><Text,10>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,1>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,2>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,3>', 'ok:12345678123456789ABCDEF012345678');
        O.Expect('<Standard Format,4>', 'ok:12345678-1234-5678-9ABC-DEF012345678');
        O.Verify();
    end;

    [Test]
    procedure Format_Guid_value_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := SomeGuid();
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('x<Text>y', 'err:InvalidFormatString');
        O.Expect('literal', 'err:InvalidStandardFormat');
        O.Expect('', 'err:InvalidStandardFormat');
        O.Expect('<Precision,2:2>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Guid_value_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := SomeGuid();
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
        CellS(O, '<Text>', V, '<Text>');
        CellS(O, '<Text,10>', V, '<Text,10>');
        CellS(O, '<Text,3>', V, '<Text,3>');
        CellS(O, '<Filler Character,x><Text,10>', V, '<Filler Character,x><Text,10>');
        CellS(O, '<Integer>', V, '<Integer>');
        CellS(O, '<Integer,5>', V, '<Integer,5>');
        CellS(O, '<Sign>', V, '<Sign>');
        CellS(O, '<Decimals>', V, '<Decimals>');
        CellS(O, '<Day>', V, '<Day>');
        CellS(O, '<Hours24>', V, '<Hours24>');
        CellS(O, '<Standard Format,0>', V, '<Standard Format,0>');
        CellS(O, '<Standard Format,1>', V, '<Standard Format,1>');
        CellS(O, '<Standard Format,2>', V, '<Standard Format,2>');
        CellS(O, '<Standard Format,3>', V, '<Standard Format,3>');
        CellS(O, '<Standard Format,4>', V, '<Standard Format,4>');
        GlobalLanguage(Saved);
        O.Expect('n0', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n1', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n2', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n3', 'ok:12345678123456789ABCDEF012345678');
        O.Expect('n4', 'ok:12345678-1234-5678-9ABC-DEF012345678');
        O.Expect('n5', 'ok:(12345678-1234-5678-9ABC-DEF012345678)');
        O.Expect('n6', 'ok:{0X12345678,0X1234,0X5678,{0X9A,0XBC,0XDE,0XF0,0X12,0X34,0X56,0X78}}');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'err:InvalidFormatString');
        O.Expect('<Text,10>', 'err:InvalidFormatString');
        O.Expect('<Text,3>', 'err:InvalidFormatString');
        O.Expect('<Filler Character,x><Text,10>', 'err:InvalidFormatString');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,1>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,2>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('<Standard Format,3>', 'ok:12345678123456789ABCDEF012345678');
        O.Expect('<Standard Format,4>', 'ok:12345678-1234-5678-9ABC-DEF012345678');
        O.Verify();
    end;

    [Test]
    procedure Format_Guid_value_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Guid;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := SomeGuid();
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('x<Text>y', 'err:InvalidFormatString');
        O.Expect('literal', 'err:InvalidStandardFormat');
        O.Expect('', 'err:InvalidStandardFormat');
        O.Expect('<Precision,2:2>', 'err:InvalidStandardFormat');
        O.Verify();
    end;
}
