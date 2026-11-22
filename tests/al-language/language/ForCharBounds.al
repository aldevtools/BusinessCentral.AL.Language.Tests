// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-for-statement
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own object 55200 (LT For Char Bounds)
// Probe: from al-runner issue 7872 (a `for` loop over a Char variable with one-character literal bounds, `for c := '0' to '4'`).
// Area: the bounds of a `for` loop whose loop variable is a Char.
//   - one-character literal bounds, to and downto; a literal start with a Char variable end; a Char variable start with a literal end;
//     two Char variables; Integer bounds; one Integer and one literal bound;
//   - an empty range and a one-value range; a non-ASCII literal range;
//   - the Char value after the loop ends, and the loop at the upper edge of Char (65534 to 65535);
//   - an Integer loop variable with one-character literal bounds.
//   Each loop records the iterated characters (Format), their codes (as Integer) and the number of iterations.
// Compile errors (not tests): a multi-character literal bound for a Char loop variable, an empty literal bound for a Char loop
//   variable and a Text loop variable are in tests/must-not-compile/cases (0000-for-char-*).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 55200 "LT For Char Bounds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CodeOf(c: Char): Integer
    begin
        exit(c);
    end;

    [Test]
    procedure Char_LiteralBounds_To()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        s: Text;
        codes: Text;
        n: Integer;
    begin
        for c := '0' to '4' do begin
            s += Format(c);
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Observe('after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_LiteralBounds_DownTo()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        s: Text;
        codes: Text;
        n: Integer;
    begin
        for c := '4' downto '0' do begin
            s += Format(c);
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Observe('after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_LiteralStart_CharVariableEnd()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        last: Char;
        s: Text;
        n: Integer;
    begin
        last := 'c';
        for c := 'a' to last do begin
            s += Format(c);
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('iterations', Format(n));
        Observer.Observe('after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_CharVariableStart_LiteralEnd()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        first: Char;
        s: Text;
        n: Integer;
    begin
        first := 'c';
        for c := first to 'e' do begin
            s += Format(c);
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('iterations', Format(n));
        Observer.Observe('after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_CharVariableBounds()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        first: Char;
        last: Char;
        s: Text;
        n: Integer;
    begin
        first := 'a';
        last := 'c';
        for c := first to last do begin
            s += Format(c);
            n += 1;
        end;
        Observer.Observe('to', s);
        Observer.Observe('to iterations', Format(n));
        s := '';
        n := 0;
        for c := last downto first do begin
            s += Format(c);
            n += 1;
        end;
        Observer.Observe('downto', s);
        Observer.Observe('downto iterations', Format(n));
        Observer.Finish();
    end;

    [Test]
    procedure Char_IntegerBounds()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        s: Text;
        codes: Text;
        n: Integer;
    begin
        for c := 48 to 50 do begin
            s += Format(c);
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Observe('after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_LiteralStart_IntegerEnd()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        s: Text;
        codes: Text;
        n: Integer;
    begin
        for c := '0' to 52 do begin
            s += Format(c);
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Finish();
    end;

    [Test]
    procedure Char_IntegerStart_LiteralEnd()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        s: Text;
        codes: Text;
        n: Integer;
    begin
        for c := 48 to '4' do begin
            s += Format(c);
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('chars', s);
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Finish();
    end;

    [Test]
    procedure Char_EmptyRange_And_OneValue()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        n: Integer;
    begin
        for c := '4' to '0' do
            n += 1;
        Observer.Observe('4 to 0 iterations', Format(n));
        Observer.Observe('4 to 0 after the loop', Format(CodeOf(c)));
        n := 0;
        for c := '0' downto '4' do
            n += 1;
        Observer.Observe('0 downto 4 iterations', Format(n));
        n := 0;
        for c := 'a' to 'a' do
            n += 1;
        Observer.Observe('a to a iterations', Format(n));
        Observer.Observe('a to a after the loop', Format(CodeOf(c)));
        n := 0;
        for c := 'a' downto 'a' do
            n += 1;
        Observer.Observe('a downto a iterations', Format(n));
        Observer.Finish();
    end;

    [Test]
    procedure Char_NonAsciiLiteralBounds()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        codes: Text;
        n: Integer;
    begin
        for c := 'ä' to 'å' do begin
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
        end;
        Observer.Observe('codes', codes);
        Observer.Observe('iterations', Format(n));
        Observer.Finish();
    end;

    [Test]
    procedure Char_UpperEdge_Termination()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
        codes: Text;
        n: Integer;
    begin
        // A loop that does not end is cut after 5 iterations so the test cannot hang.
        for c := 65534 to 65535 do begin
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
            if n >= 5 then
                break;
        end;
        Observer.Observe('to codes', codes);
        Observer.Observe('to iterations', Format(n));
        Observer.Observe('to after the loop', Format(CodeOf(c)));
        codes := '';
        n := 0;
        for c := 1 downto 0 do begin
            codes += Format(CodeOf(c)) + ' ';
            n += 1;
            if n >= 5 then
                break;
        end;
        Observer.Observe('downto codes', codes);
        Observer.Observe('downto iterations', Format(n));
        Observer.Observe('downto after the loop', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Char_LoopVariable_AfterLoop()
    var
        Observer: Codeunit "Probe Observer";
        c: Char;
    begin
        for c := '0' to '4' do
            ;
        Observer.Observe('to', Format(CodeOf(c)));
        for c := '4' downto '0' do
            ;
        Observer.Observe('downto', Format(CodeOf(c)));
        Observer.Finish();
    end;

    [Test]
    procedure Integer_OneCharLiteralBounds()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        s: Text;
        n: Integer;
    begin
        for i := '0' to '4' do begin
            s += Format(i) + ' ';
            n += 1;
        end;
        Observer.Observe('to values', s);
        Observer.Observe('to iterations', Format(n));
        Observer.Observe('to after the loop', Format(i));
        s := '';
        n := 0;
        for i := '4' downto '0' do begin
            s += Format(i) + ' ';
            n += 1;
        end;
        Observer.Observe('downto values', s);
        Observer.Observe('downto iterations', Format(n));
        Observer.Finish();
    end;
}
