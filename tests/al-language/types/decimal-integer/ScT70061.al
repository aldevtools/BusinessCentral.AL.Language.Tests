// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-round-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70061
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Char arithmetic, Char from Integer, comparison
// BC versions: 29 (27 and 28 by CI)

codeunit 70061 "LT ScT Char"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Char_FromInteger()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        I: Integer;
    begin
        I := 65;
        C := I;
        Observer.Observe('65', Format(C));
        I := 0;
        C := I;
        Observer.Observe('0_ord', Format(C, 0, 2));
        I := 255;
        C := I;
        Observer.Observe('255', Format(C));
        I := 256;
        C := I;
        Observer.Observe('256_ord', Format(C, 0, 2));
        I := 65535;
        C := I;
        Observer.Observe('65535_ord', Format(C, 0, 2));
        I := 65536;
        asserterror C := I;
        Observer.ObserveError('65536');
        I := -1;
        asserterror C := I;
        Observer.ObserveError('neg1');
        I := 8364;
        C := I;
        Observer.Observe('euro', Format(C));
        Observer.Expect('65', 'A');
        Observer.Expect('0_ord', '\u0000');
        Observer.Expect('255', 'ÿ');
        Observer.Expect('256_ord', 'Ā');
        Observer.Expect('65535_ord', '\uFFFF');
        Observer.Expect('65536|text', 'Overflow under conversion of System.Int32 value 65536 to System.Char.');
        Observer.Expect('65536|code', 'ConversionCast');
        Observer.Expect('neg1|text', 'Overflow under conversion of System.Int32 value -1 to System.Char.');
        Observer.Expect('neg1|code', 'ConversionCast');
        Observer.Expect('euro', '€');
        Observer.Verify();
    end;

    [Test]
    procedure Char_ToInteger()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        I: Integer;
    begin
        C := 'A';
        I := C;
        Observer.Observe('A', Format(I));
        C := 'z';
        I := C;
        Observer.Observe('z', Format(I));
        C := ' ';
        I := C;
        Observer.Observe('space', Format(I));
        C := '0';
        I := C;
        Observer.Observe('zero_digit', Format(I));
        Observer.Observe('plus_one', Format(C + 1));
        Observer.Observe('default', Format(Dflt()));
        Observer.Expect('A', '65');
        Observer.Expect('z', '122');
        Observer.Expect('space', '32');
        Observer.Expect('zero_digit', '48');
        Observer.Expect('plus_one', '49');
        Observer.Expect('default', '0');
        Observer.Verify();
    end;

    local procedure Dflt(): Integer
    var
        C: Char;
    begin
        exit(C);
    end;

    [Test]
    procedure Char_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        D: Char;
        I: Integer;
    begin
        C := 'A';
        I := C + 2;
        D := I;
        Observer.Observe('A_plus_2', Format(D));
        C := 65;
        D := C + 25;
        Observer.Observe('A_plus_25', Format(D));
        C := 'a';
        Observer.Observe('lt', Format(C < 'b'));
        Observer.Observe('gt', Format(C > 'A'));
        Observer.Observe('eq', Format(C = 'a'));
        Observer.Observe('eq_int', Format(C = 97));
        Observer.Observe('ne', Format(C <> 'A'));
        Observer.Observe('mul', Format(C * 2));
        Observer.Observe('div', Format(C div 2));
        Observer.Observe('mod', Format(C mod 10));
        C := 0;
        asserterror C := C - 1;
        Observer.ObserveError('below_zero');
        C := 65535;
        asserterror C := C + 1;
        Observer.ObserveError('above_max');
        Observer.Expect('A_plus_2', 'C');
        Observer.Expect('A_plus_25', 'Z');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'Yes');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('eq_int', 'Yes');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('mul', '194');
        Observer.Expect('div', '48');
        Observer.Expect('mod', '7');
        Observer.Expect('below_zero|text', 'Overflow under conversion of System.Int32 value -1 to System.Char.');
        Observer.Expect('below_zero|code', 'ConversionCast');
        Observer.Expect('above_max|text', 'Overflow under conversion of System.Int32 value 65536 to System.Char.');
        Observer.Expect('above_max|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Char_TextIndex()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        C: Char;
    begin
        T := 'Hello';
        C := T[1];
        Observer.Observe('first', Format(C));
        Observer.Observe('first_ord', Format(C, 0, 2));
        Observer.Observe('last', Format(T[5]));
        C := T[6];
        Observer.Observe('out_of_range', 'no error');
        asserterror C := T[0];
        Observer.ObserveError('zero');
        T[1] := 'J';
        Observer.Observe('set', T);
        asserterror T[8] := 'x';
        Observer.ObserveError('af129');
        Observer.Observe('extend_len', Format(StrLen(T)));
        Observer.Observe('extend_char_7', Format(T[7], 0, 2));
        Observer.Expect('first', 'H');
        Observer.Expect('first_ord', 'H');
        Observer.Expect('last', 'o');
        Observer.Expect('out_of_range', 'no error');
        Observer.Expect('zero|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('zero|code', 'OutsidePermittedRange');
        Observer.Expect('set', 'Jello');
        Observer.Expect('af129|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 8. The permitted range is: from 1 to 5.');
        Observer.Expect('af129|code', 'OutsidePermittedRange');
        Observer.Expect('extend_len', '5');
        Observer.Expect('extend_char_7', '\u0000');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Conversions()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        T: Text;
        Cd: Code[10];
        B: Byte;
    begin
        C := 'q';
        T := C;
        Observer.Observe('to_text', T);
        Cd := C;
        Observer.Observe('to_code', Cd);
        T := 'ab';
        Observer.Observe('text_eq_char', Format(T = 'ab'));
        B := C;
        Observer.Observe('to_byte', Format(B));
        C := B;
        Observer.Observe('back', Format(C));
        Observer.Observe('lower_upper', UpperCase(Format(C)));
        Observer.Observe('str_len', Format(StrLen(Format(C))));
        Observer.Expect('to_text', 'q');
        Observer.Expect('to_code', 'Q');
        Observer.Expect('text_eq_char', 'Yes');
        Observer.Expect('to_byte', 'q');
        Observer.Expect('back', 'q');
        Observer.Expect('lower_upper', 'Q');
        Observer.Expect('str_len', '1');
        Observer.Verify();
    end;
}
