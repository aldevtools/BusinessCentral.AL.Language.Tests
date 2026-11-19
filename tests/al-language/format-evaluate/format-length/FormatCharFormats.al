// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al)
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Char, Length, FormatString) and Format(Char, Length, FormatNumber) for the Chars 'a', ' ', 0, 255 and 8364, and the same for a Byte 97:
//   the format codes <Number>, <Integer>, <Text>, <Standard Format,0|9>, <Sign>, <Integer Thousand>, <Filler Character,0>, <Decimals>, a literal, standard
//   formats 0, 1, 2, 9 and lengths 5 and -5.
// Results (BC 27.5): Format(Char, 0, '<Number>') is the character code (97 for 'a', 0, 32, 255, 8364); '<Number,5>' pads it on the right to 5. The codes
//   <Integer>, <Text>, <Sign>, <Integer Thousand> and <Decimals> raise "An invalid field or attribute has been specified for the 'Format' property.\<code>"
//   (InvalidFormatString); <Standard Format,0|9> and the standard formats 0, 1, 2 and 9 give the character itself; '<Filler Character,0>' gives ''. A Byte
//   behaves like a Char.
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

codeunit 96386 "FLN Char Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Char_a_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 'a';
        Observer.Observe('char 97 plain', '[' + Format(V) + ']');
        Observer.Observe('char 97 S=<Number>', F.CharS(V, 0, '<Number>'));
        Observer.Observe('char 97 S=<Integer>', F.CharS(V, 0, '<Integer>'));
        Observer.Observe('char 97 S=<Text>', F.CharS(V, 0, '<Text>'));
        Observer.Observe('char 97 S=<Standard Format,0>', F.CharS(V, 0, '<Standard Format,0>'));
        Observer.Observe('char 97 S=<Standard Format,9>', F.CharS(V, 0, '<Standard Format,9>'));
        Observer.Observe('char 97 S=<Sign>', F.CharS(V, 0, '<Sign>'));
        Observer.Observe('char 97 S=<Integer Thousand>', F.CharS(V, 0, '<Integer Thousand>'));
        Observer.Observe('char 97 S=<Filler Character,0>', F.CharS(V, 0, '<Filler Character,0>'));
        Observer.Observe('char 97 S=x', F.CharS(V, 0, 'x'));
        Observer.Observe('char 97 S=<Number,5>', F.CharS(V, 0, '<Number,5>'));
        Observer.Observe('char 97 S=<Integer,5><Filler Character,0>', F.CharS(V, 0, '<Integer,5><Filler Character,0>'));
        Observer.Observe('char 97 S=<Decimals>', F.CharS(V, 0, '<Decimals>'));
        Observer.Observe('char 97 N=0', F.Char(V, 0, 0));
        Observer.Observe('char 97 N=1', F.Char(V, 0, 1));
        Observer.Observe('char 97 N=2', F.Char(V, 0, 2));
        Observer.Observe('char 97 N=9', F.Char(V, 0, 9));
        Observer.Observe('char 97 L=5', F.Char(V, 5, -1));
        Observer.Observe('char 97 L=-5', F.Char(V, -5, -1));
        Observer.Observe('char 97 L=5 S=<Number>', F.CharS(V, 5, '<Number>'));
        Observer.Observe('char 97 L=-5 S=<Number>', F.CharS(V, -5, '<Number>'));
        Observer.Expect('char 97 plain', '[a]');
        Observer.Expect('char 97 S=<Number>', '[97]');
        Observer.Expect('char 97 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('char 97 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('char 97 S=<Standard Format,0>', '[a]');
        Observer.Expect('char 97 S=<Standard Format,9>', '[a]');
        Observer.Expect('char 97 S=<Sign>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Sign> | InvalidFormatString');
        Observer.Expect('char 97 S=<Integer Thousand>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand> | InvalidFormatString');
        Observer.Expect('char 97 S=<Filler Character,0>', '[]');
        Observer.Expect('char 97 S=x', '[x]');
        Observer.Expect('char 97 S=<Number,5>', '[97   ]');
        Observer.Expect('char 97 S=<Integer,5><Filler Character,0>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer,5><Filler Character,0> | InvalidFormatString');
        Observer.Expect('char 97 S=<Decimals>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Decimals> | InvalidFormatString');
        Observer.Expect('char 97 N=0', '[a]');
        Observer.Expect('char 97 N=1', '[a]');
        Observer.Expect('char 97 N=2', '[a]');
        Observer.Expect('char 97 N=9', '[a]');
        Observer.Expect('char 97 L=5', '[a    ]');
        Observer.Expect('char 97 L=-5', '[a]');
        Observer.Expect('char 97 L=5 S=<Number>', '[97   ]');
        Observer.Expect('char 97 L=-5 S=<Number>', '[97]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Space_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := ' ';
        Observer.Observe('char 32 plain', '[' + Format(V) + ']');
        Observer.Observe('char 32 S=<Number>', F.CharS(V, 0, '<Number>'));
        Observer.Observe('char 32 S=<Integer>', F.CharS(V, 0, '<Integer>'));
        Observer.Observe('char 32 S=<Text>', F.CharS(V, 0, '<Text>'));
        Observer.Observe('char 32 S=<Standard Format,9>', F.CharS(V, 0, '<Standard Format,9>'));
        Observer.Observe('char 32 N=0', F.Char(V, 0, 0));
        Observer.Observe('char 32 N=1', F.Char(V, 0, 1));
        Observer.Observe('char 32 N=2', F.Char(V, 0, 2));
        Observer.Observe('char 32 N=9', F.Char(V, 0, 9));
        Observer.Observe('char 32 L=5', F.Char(V, 5, -1));
        Observer.Observe('char 32 L=-5', F.Char(V, -5, -1));
        Observer.Observe('char 32 L=5 S=<Number>', F.CharS(V, 5, '<Number>'));
        Observer.Observe('char 32 L=-5 S=<Number>', F.CharS(V, -5, '<Number>'));
        Observer.Expect('char 32 plain', '[ ]');
        Observer.Expect('char 32 S=<Number>', '[32]');
        Observer.Expect('char 32 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('char 32 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('char 32 S=<Standard Format,9>', '[ ]');
        Observer.Expect('char 32 N=0', '[ ]');
        Observer.Expect('char 32 N=1', '[ ]');
        Observer.Expect('char 32 N=2', '[ ]');
        Observer.Expect('char 32 N=9', '[ ]');
        Observer.Expect('char 32 L=5', '[     ]');
        Observer.Expect('char 32 L=-5', '[ ]');
        Observer.Expect('char 32 L=5 S=<Number>', '[32   ]');
        Observer.Expect('char 32 L=-5 S=<Number>', '[32]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Zero_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 0;
        Observer.Observe('char 0 plain', '[' + Format(V) + ']');
        Observer.Observe('char 0 S=<Number>', F.CharS(V, 0, '<Number>'));
        Observer.Observe('char 0 S=<Integer>', F.CharS(V, 0, '<Integer>'));
        Observer.Observe('char 0 S=<Text>', F.CharS(V, 0, '<Text>'));
        Observer.Observe('char 0 S=<Standard Format,9>', F.CharS(V, 0, '<Standard Format,9>'));
        Observer.Observe('char 0 N=0', F.Char(V, 0, 0));
        Observer.Observe('char 0 N=1', F.Char(V, 0, 1));
        Observer.Observe('char 0 N=2', F.Char(V, 0, 2));
        Observer.Observe('char 0 N=9', F.Char(V, 0, 9));
        Observer.Observe('char 0 L=5', F.Char(V, 5, -1));
        Observer.Observe('char 0 L=-5', F.Char(V, -5, -1));
        Observer.Observe('char 0 L=5 S=<Number>', F.CharS(V, 5, '<Number>'));
        Observer.Observe('char 0 L=-5 S=<Number>', F.CharS(V, -5, '<Number>'));
        Observer.Expect('char 0 plain', '[\u0000]');
        Observer.Expect('char 0 S=<Number>', '[0]');
        Observer.Expect('char 0 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('char 0 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('char 0 S=<Standard Format,9>', '[\u0000]');
        Observer.Expect('char 0 N=0', '[\u0000]');
        Observer.Expect('char 0 N=1', '[\u0000]');
        Observer.Expect('char 0 N=2', '[\u0000]');
        Observer.Expect('char 0 N=9', '[\u0000]');
        Observer.Expect('char 0 L=5', '[\u0000    ]');
        Observer.Expect('char 0 L=-5', '[\u0000]');
        Observer.Expect('char 0 L=5 S=<Number>', '[0    ]');
        Observer.Expect('char 0 L=-5 S=<Number>', '[0]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_255_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 255;
        Observer.Observe('char 255 plain', '[' + Format(V) + ']');
        Observer.Observe('char 255 S=<Number>', F.CharS(V, 0, '<Number>'));
        Observer.Observe('char 255 S=<Integer>', F.CharS(V, 0, '<Integer>'));
        Observer.Observe('char 255 S=<Text>', F.CharS(V, 0, '<Text>'));
        Observer.Observe('char 255 S=<Standard Format,9>', F.CharS(V, 0, '<Standard Format,9>'));
        Observer.Observe('char 255 N=0', F.Char(V, 0, 0));
        Observer.Observe('char 255 N=1', F.Char(V, 0, 1));
        Observer.Observe('char 255 N=2', F.Char(V, 0, 2));
        Observer.Observe('char 255 N=9', F.Char(V, 0, 9));
        Observer.Observe('char 255 L=5', F.Char(V, 5, -1));
        Observer.Observe('char 255 L=-5', F.Char(V, -5, -1));
        Observer.Observe('char 255 L=5 S=<Number>', F.CharS(V, 5, '<Number>'));
        Observer.Observe('char 255 L=-5 S=<Number>', F.CharS(V, -5, '<Number>'));
        Observer.Expect('char 255 plain', '[ÿ]');
        Observer.Expect('char 255 S=<Number>', '[255]');
        Observer.Expect('char 255 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('char 255 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('char 255 S=<Standard Format,9>', '[ÿ]');
        Observer.Expect('char 255 N=0', '[ÿ]');
        Observer.Expect('char 255 N=1', '[ÿ]');
        Observer.Expect('char 255 N=2', '[ÿ]');
        Observer.Expect('char 255 N=9', '[ÿ]');
        Observer.Expect('char 255 L=5', '[ÿ    ]');
        Observer.Expect('char 255 L=-5', '[ÿ]');
        Observer.Expect('char 255 L=5 S=<Number>', '[255  ]');
        Observer.Expect('char 255 L=-5 S=<Number>', '[255]');
        Observer.Verify();
    end;

    [Test]
    procedure Char_8364_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Char;
    begin
        V := 8364;
        Observer.Observe('char 8364 plain', '[' + Format(V) + ']');
        Observer.Observe('char 8364 S=<Number>', F.CharS(V, 0, '<Number>'));
        Observer.Observe('char 8364 S=<Integer>', F.CharS(V, 0, '<Integer>'));
        Observer.Observe('char 8364 S=<Text>', F.CharS(V, 0, '<Text>'));
        Observer.Observe('char 8364 S=<Standard Format,9>', F.CharS(V, 0, '<Standard Format,9>'));
        Observer.Observe('char 8364 N=0', F.Char(V, 0, 0));
        Observer.Observe('char 8364 N=1', F.Char(V, 0, 1));
        Observer.Observe('char 8364 N=2', F.Char(V, 0, 2));
        Observer.Observe('char 8364 N=9', F.Char(V, 0, 9));
        Observer.Observe('char 8364 L=5', F.Char(V, 5, -1));
        Observer.Observe('char 8364 L=-5', F.Char(V, -5, -1));
        Observer.Observe('char 8364 L=5 S=<Number>', F.CharS(V, 5, '<Number>'));
        Observer.Observe('char 8364 L=-5 S=<Number>', F.CharS(V, -5, '<Number>'));
        Observer.Expect('char 8364 plain', '[€]');
        Observer.Expect('char 8364 S=<Number>', '[8364]');
        Observer.Expect('char 8364 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('char 8364 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('char 8364 S=<Standard Format,9>', '[€]');
        Observer.Expect('char 8364 N=0', '[€]');
        Observer.Expect('char 8364 N=1', '[€]');
        Observer.Expect('char 8364 N=2', '[€]');
        Observer.Expect('char 8364 N=9', '[€]');
        Observer.Expect('char 8364 L=5', '[€    ]');
        Observer.Expect('char 8364 L=-5', '[€]');
        Observer.Expect('char 8364 L=5 S=<Number>', '[8364 ]');
        Observer.Expect('char 8364 L=-5 S=<Number>', '[8364]');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_97_Formats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Byte;
    begin
        V := 97;
        Observer.Observe('byte 97 plain', '[' + Format(V) + ']');
        Observer.Observe('byte 97 S=<Number>', F.ByteS(V, 0, '<Number>'));
        Observer.Observe('byte 97 S=<Integer>', F.ByteS(V, 0, '<Integer>'));
        Observer.Observe('byte 97 S=<Text>', F.ByteS(V, 0, '<Text>'));
        Observer.Observe('byte 97 S=<Standard Format,9>', F.ByteS(V, 0, '<Standard Format,9>'));
        Observer.Observe('byte 97 N=0', F.Byte(V, 0, 0));
        Observer.Observe('byte 97 N=9', F.Byte(V, 0, 9));
        Observer.Observe('byte 97 L=5', F.Byte(V, 5, -1));
        Observer.Observe('byte 97 L=-5', F.Byte(V, -5, -1));
        Observer.Observe('byte 97 L=5 S=<Number>', F.ByteS(V, 5, '<Number>'));
        Observer.Observe('byte 97 L=-5 S=<Number>', F.ByteS(V, -5, '<Number>'));
        Observer.Expect('byte 97 plain', '[a]');
        Observer.Expect('byte 97 S=<Number>', '[97]');
        Observer.Expect('byte 97 S=<Integer>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Integer> | InvalidFormatString');
        Observer.Expect('byte 97 S=<Text>', 'ERR An invalid field or attribute has been specified for the ''Format'' property.\\<Text> | InvalidFormatString');
        Observer.Expect('byte 97 S=<Standard Format,9>', '[a]');
        Observer.Expect('byte 97 N=0', '[a]');
        Observer.Expect('byte 97 N=9', '[a]');
        Observer.Expect('byte 97 L=5', '[a    ]');
        Observer.Expect('byte 97 L=-5', '[a]');
        Observer.Expect('byte 97 L=5 S=<Number>', '[97   ]');
        Observer.Expect('byte 97 L=-5 S=<Number>', '[97]');
        Observer.Verify();
    end;
}
