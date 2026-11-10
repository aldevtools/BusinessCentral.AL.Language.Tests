// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on Boolean, Enum, Option, Guid, Char, Text and Code. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72855 "LT FM Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryN(V: Text; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    [TryFunction]
    local procedure TryS(V: Text; S: Text; var R: Text)
    begin
        R := Format(V, 0, S);
    end;

    local procedure CellN(var O: Codeunit "Probe Observer"; Name: Text; V: Text; N: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryN(V, N, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure CellS(var O: Codeunit "Probe Observer"; Name: Text; V: Text; S: Text)
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
    procedure Format_Text_empty_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := '';
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
        O.Expect('n0', 'ok:');
        O.Expect('n1', 'ok:');
        O.Expect('n2', 'ok:');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:');
        O.Expect('<Text,10>', 'ok:          ');
        O.Expect('<Text,3>', 'ok:   ');
        O.Expect('<Filler Character,x><Text,10>', 'ok:xxxxxxxxxx');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:');
        O.Expect('<Standard Format,1>', 'ok:');
        O.Expect('<Standard Format,2>', 'ok:');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_empty_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := '';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:');
        O.Expect('x<Text>y', 'ok:xy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_abc_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'abc';
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
        O.Expect('n0', 'ok:abc');
        O.Expect('n1', 'ok:abc');
        O.Expect('n2', 'ok:abc');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:abc');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:abc');
        O.Expect('<Text,10>', 'ok:abc       ');
        O.Expect('<Text,3>', 'ok:abc');
        O.Expect('<Filler Character,x><Text,10>', 'ok:abcxxxxxxx');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:abc');
        O.Expect('<Standard Format,1>', 'ok:abc');
        O.Expect('<Standard Format,2>', 'ok:abc');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_abc_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'abc';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:abc');
        O.Expect('x<Text>y', 'ok:xabcy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_Hello_World_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'Hello World';
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
        O.Expect('n0', 'ok:Hello World');
        O.Expect('n1', 'ok:Hello World');
        O.Expect('n2', 'ok:Hello World');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:Hello World');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:Hello World');
        O.Expect('<Text,10>', 'ok:Hello Worl');
        O.Expect('<Text,3>', 'ok:Hel');
        O.Expect('<Filler Character,x><Text,10>', 'ok:Hello Worl');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:Hello World');
        O.Expect('<Standard Format,1>', 'ok:Hello World');
        O.Expect('<Standard Format,2>', 'ok:Hello World');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_Hello_World_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'Hello World';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:Hello World');
        O.Expect('x<Text>y', 'ok:xHello Worldy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_umlaut_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'Ärger';
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
        O.Expect('n0', 'ok:Ärger');
        O.Expect('n1', 'ok:Ärger');
        O.Expect('n2', 'ok:Ärger');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:Ärger');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:Ärger');
        O.Expect('<Text,10>', 'ok:Ärger     ');
        O.Expect('<Text,3>', 'ok:Ärg');
        O.Expect('<Filler Character,x><Text,10>', 'ok:Ärgerxxxxx');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:Ärger');
        O.Expect('<Standard Format,1>', 'ok:Ärger');
        O.Expect('<Standard Format,2>', 'ok:Ärger');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_umlaut_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'Ärger';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:Ärger');
        O.Expect('x<Text>y', 'ok:xÄrgery');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_long30_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := '123456789012345678901234567890';
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
        O.Expect('n0', 'ok:123456789012345678901234567890');
        O.Expect('n1', 'ok:123456789012345678901234567890');
        O.Expect('n2', 'ok:123456789012345678901234567890');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:123456789012345678901234567890');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:123456789012345678901234567890');
        O.Expect('<Text,10>', 'ok:1234567890');
        O.Expect('<Text,3>', 'ok:123');
        O.Expect('<Filler Character,x><Text,10>', 'ok:1234567890');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:123456789012345678901234567890');
        O.Expect('<Standard Format,1>', 'ok:123456789012345678901234567890');
        O.Expect('<Standard Format,2>', 'ok:123456789012345678901234567890');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_long30_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := '123456789012345678901234567890';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:123456789012345678901234567890');
        O.Expect('x<Text>y', 'ok:x123456789012345678901234567890y');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_abc_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 'abc';
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
        O.Expect('n0', 'ok:abc');
        O.Expect('n1', 'ok:abc');
        O.Expect('n2', 'ok:abc');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:abc');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:abc');
        O.Expect('<Text,10>', 'ok:abc       ');
        O.Expect('<Text,3>', 'ok:abc');
        O.Expect('<Filler Character,x><Text,10>', 'ok:abcxxxxxxx');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:abc');
        O.Expect('<Standard Format,1>', 'ok:abc');
        O.Expect('<Standard Format,2>', 'ok:abc');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Text_abc_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Text;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 'abc';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:abc');
        O.Expect('x<Text>y', 'ok:xabcy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;
}
