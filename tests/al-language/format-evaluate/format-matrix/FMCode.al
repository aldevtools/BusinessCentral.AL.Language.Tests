// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on Boolean, Enum, Option, Guid, Char, Text and Code. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72856 "LT FM Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryN(V: Code[20]; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    [TryFunction]
    local procedure TryS(V: Code[20]; S: Text; var R: Text)
    begin
        R := Format(V, 0, S);
    end;

    local procedure CellN(var O: Codeunit "Probe Observer"; Name: Text; V: Code[20]; N: Integer)
    var
        R: Text;
    begin
        ClearLastError();
        if TryN(V, N, R) then
            O.Observe(Name, 'ok:' + R)
        else
            O.Observe(Name, 'err:' + GetLastErrorCode());
    end;

    local procedure CellS(var O: Codeunit "Probe Observer"; Name: Text; V: Code[20]; S: Text)
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
    procedure Format_Code_empty_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
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
    procedure Format_Code_empty_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
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
    procedure Format_Code_ABC_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'ABC';
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
        O.Expect('n0', 'ok:ABC');
        O.Expect('n1', 'ok:ABC');
        O.Expect('n2', 'ok:ABC');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:ABC');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:ABC');
        O.Expect('<Text,10>', 'ok:       ABC');
        O.Expect('<Text,3>', 'ok:ABC');
        O.Expect('<Filler Character,x><Text,10>', 'ok:xxxxxxxABC');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:ABC');
        O.Expect('<Standard Format,1>', 'ok:ABC');
        O.Expect('<Standard Format,2>', 'ok:ABC');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Code_ABC_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        V := 'ABC';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:ABC');
        O.Expect('x<Text>y', 'ok:xABCy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Code_abc_lower_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
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
        O.Expect('n0', 'ok:ABC');
        O.Expect('n1', 'ok:ABC');
        O.Expect('n2', 'ok:ABC');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:ABC');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:ABC');
        O.Expect('<Text,10>', 'ok:       ABC');
        O.Expect('<Text,3>', 'ok:ABC');
        O.Expect('<Filler Character,x><Text,10>', 'ok:xxxxxxxABC');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:ABC');
        O.Expect('<Standard Format,1>', 'ok:ABC');
        O.Expect('<Standard Format,2>', 'ok:ABC');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Code_abc_lower_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
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
        O.Expect('<Standard Format,9>', 'ok:ABC');
        O.Expect('x<Text>y', 'ok:xABCy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;

    [Test]
    procedure Format_Code_ABC_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 'ABC';
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
        O.Expect('n0', 'ok:ABC');
        O.Expect('n1', 'ok:ABC');
        O.Expect('n2', 'ok:ABC');
        O.Expect('n3', 'err:InvalidStandardFormat');
        O.Expect('n4', 'err:InvalidStandardFormat');
        O.Expect('n5', 'err:InvalidStandardFormat');
        O.Expect('n6', 'err:InvalidStandardFormat');
        O.Expect('n7', 'err:InvalidStandardFormat');
        O.Expect('n8', 'err:InvalidStandardFormat');
        O.Expect('n9', 'ok:ABC');
        O.Expect('n10', 'err:InvalidStandardFormat');
        O.Expect('<Text>', 'ok:ABC');
        O.Expect('<Text,10>', 'ok:       ABC');
        O.Expect('<Text,3>', 'ok:ABC');
        O.Expect('<Filler Character,x><Text,10>', 'ok:xxxxxxxABC');
        O.Expect('<Integer>', 'err:InvalidFormatString');
        O.Expect('<Integer,5>', 'err:InvalidFormatString');
        O.Expect('<Sign>', 'err:InvalidFormatString');
        O.Expect('<Decimals>', 'err:InvalidFormatString');
        O.Expect('<Day>', 'err:InvalidFormatString');
        O.Expect('<Hours24>', 'err:InvalidFormatString');
        O.Expect('<Standard Format,0>', 'ok:ABC');
        O.Expect('<Standard Format,1>', 'ok:ABC');
        O.Expect('<Standard Format,2>', 'ok:ABC');
        O.Expect('<Standard Format,3>', 'err:InvalidStandardFormat');
        O.Expect('<Standard Format,4>', 'err:InvalidStandardFormat');
        O.Verify();
    end;

    [Test]
    procedure Format_Code_ABC_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
        V: Code[20];
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        V := 'ABC';
        CellS(O, '<Standard Format,9>', V, '<Standard Format,9>');
        CellS(O, 'x<Text>y', V, 'x<Text>y');
        CellS(O, 'literal', V, 'literal');
        CellS(O, '', V, '');
        CellS(O, '<Precision,2:2>', V, '<Precision,2:2>');
        GlobalLanguage(Saved);
        O.Expect('<Standard Format,9>', 'ok:ABC');
        O.Expect('x<Text>y', 'ok:xABCy');
        O.Expect('literal', 'ok:literal');
        O.Expect('', 'ok:');
        O.Expect('<Precision,2:2>', 'ok:');
        O.Verify();
    end;
}
