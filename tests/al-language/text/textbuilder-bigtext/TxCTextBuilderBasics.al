// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 71000-71003
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// TextBuilder: Append, AppendLine, Clear, Length, ToText, Capacity, MaxCapacity, EnsureCapacity.
// BC versions: 29 (27 and 28 by CI)

codeunit 71000 "LT TxC TB Append"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Append_Basics()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Ch: Char;
    begin
        Observer.Observe('empty', TB.ToText());
        Observer.Observe('emptyLen', Format(TB.Length()));
        TB.Append('abc');
        Observer.Observe('a1', TB.ToText());
        TB.Append('');
        Observer.Observe('a2', TB.ToText());
        TB.Append(' def');
        Observer.Observe('a3', TB.ToText());
        Observer.Observe('len', Format(TB.Length()));
        TB.Append(Format(123));
        Observer.Observe('int', TB.ToText());
        TB.Append(Format(1.5));
        Observer.Observe('dec', TB.ToText());
        TB.Append(Format(true));
        Observer.Observe('bool', TB.ToText());
        Ch := 'Z';
        TB.Append(Ch);
        Observer.Observe('char', TB.ToText());
        TB.Append(Format(0D));
        Observer.Observe('date', TB.ToText());
        Observer.Expect('empty', '');
        Observer.Expect('emptyLen', '0');
        Observer.Expect('a1', 'abc');
        Observer.Expect('a2', 'abc');
        Observer.Expect('a3', 'abc def');
        Observer.Expect('len', '7');
        Observer.Expect('int', 'abc def123');
        Observer.Expect('dec', 'abc def1231.5');
        Observer.Expect('bool', 'abc def1231.5Yes');
        Observer.Expect('char', 'abc def1231.5YesZ');
        Observer.Expect('date', 'abc def1231.5YesZ');
        Observer.Verify();
    end;

    [Test]
    procedure Append_Unicode_Special()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('äöü€');
        Observer.Observe('uni', TB.ToText());
        Observer.Observe('uniLen', Format(TB.Length()));
        TB.Append('😀');
        Observer.Observe('emojiLen', Format(TB.Length()));
        TB.Clear();
        TB.Append('  ');
        Observer.Observe('spaceLen', Format(TB.Length()));
        TB.Append('a' + '''' + 'b');
        Observer.Observe('quote', TB.ToText());
        Observer.Expect('uni', 'äöü€');
        Observer.Expect('uniLen', '4');
        Observer.Expect('emojiLen', '6');
        Observer.Expect('spaceLen', '2');
        Observer.Expect('quote', '  a''b');
        Observer.Verify();
    end;

    [Test]
    procedure Append_Returns_Nothing_Chain()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        I: Integer;
    begin
        for I := 1 to 5 do
            TB.Append(Format(I));
        Observer.Observe('loop', TB.ToText());
        for I := 1 to 1000 do
            TB.Append('x');
        Observer.Observe('len1005', Format(TB.Length()));
        Observer.Observe('capGE', Format(TB.Capacity() >= TB.Length()));
        Observer.Expect('loop', '12345');
        Observer.Expect('len1005', '1005');
        Observer.Expect('capGE', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Append_Long_Text()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Big: Text;
        I: Integer;
    begin
        for I := 1 to 100 do
            Big += '0123456789';
        TB.Append(Big);
        TB.Append(Big);
        Observer.Observe('len', Format(TB.Length()));
        Observer.Observe('text', Format(StrLen(TB.ToText())));
        Observer.Observe('tail', CopyStr(TB.ToText(), 1995, 10));
        Observer.Expect('len', '2000');
        Observer.Expect('text', '2000');
        Observer.Expect('tail', '456789');
        Observer.Verify();
    end;
}

codeunit 71001 "LT TxC TB AppendLine"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(Value: Text): Text
    begin
        exit(Value.Replace('\', '\\').Replace(Format(13), '<CR>').Replace(Format(10), '<LF>'));
    end;

    [Test]
    procedure AppendLine_NoArg()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.AppendLine();
        Observer.Observe('len1', Format(TB.Length()));
        Observer.Observe('t1', Show(TB.ToText()));
        TB.AppendLine();
        Observer.Observe('len2', Format(TB.Length()));
        Observer.Observe('t2', Show(TB.ToText()));
        Observer.Expect('len1', '2');
        Observer.Expect('t1', '\r\n');
        Observer.Expect('len2', '4');
        Observer.Expect('t2', '\r\n\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure AppendLine_WithArg()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.AppendLine('abc');
        Observer.Observe('len1', Format(TB.Length()));
        Observer.Observe('t1', Show(TB.ToText()));
        TB.AppendLine('');
        Observer.Observe('len2', Format(TB.Length()));
        Observer.Observe('t2', Show(TB.ToText()));
        TB.AppendLine('def');
        Observer.Observe('t3', Show(TB.ToText()));
        TB.AppendLine(Format(42));
        Observer.Observe('t4', Show(TB.ToText()));
        Observer.Expect('len1', '5');
        Observer.Expect('t1', 'abc\r\n');
        Observer.Expect('len2', '7');
        Observer.Expect('t2', 'abc\r\n\r\n');
        Observer.Expect('t3', 'abc\r\n\r\ndef\r\n');
        Observer.Expect('t4', 'abc\r\n\r\ndef\r\n42\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure AppendLine_MixedWithAppend()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Lines: List of [Text];
        CRLF: Text;
    begin
        TB.Append('a');
        TB.AppendLine('b');
        TB.Append('c');
        Observer.Observe('t', Show(TB.ToText()));
        Observer.Observe('len', Format(TB.Length()));
        CRLF := Format(13) + Format(10);
        Observer.Observe('hasCRLF', Format(TB.ToText().Contains(CRLF)));
        Lines := TB.ToText().Split(Format(10));
        Observer.Observe('splitLF', Format(Lines.Count()));
        Observer.Expect('t', 'ab\r\nc');
        Observer.Expect('len', '5');
        Observer.Expect('hasCRLF', 'No');
        Observer.Expect('splitLF', '1');
        Observer.Verify();
    end;
}

codeunit 71002 "LT TxC TB Clear Len"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_Basics()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        CapBefore: Integer;
    begin
        TB.Clear();
        Observer.Observe('clearEmpty', Format(TB.Length()));
        TB.Append('hello world');
        CapBefore := TB.Capacity();
        TB.Clear();
        Observer.Observe('len', Format(TB.Length()));
        Observer.Observe('text', TB.ToText());
        Observer.Observe('capKept', Format(TB.Capacity() = CapBefore));
        TB.Append('x');
        Observer.Observe('reuse', TB.ToText());
        Observer.Expect('clearEmpty', '0');
        Observer.Expect('len', '0');
        Observer.Expect('text', '');
        Observer.Expect('capKept', 'Yes');
        Observer.Expect('reuse', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure Length_Getter_Setter()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        Z: Text;
    begin
        TB.Append('abcdef');
        Observer.Observe('len', Format(TB.Length()));
        TB.Length(3);
        Observer.Observe('shrunk', TB.ToText());
        Observer.Observe('shrunkLen', Format(TB.Length()));
        TB.Length(0);
        Observer.Observe('zero', TB.ToText());
        TB.Append('ab');
        TB.Length(5);
        Observer.Observe('grownLen', Format(TB.Length()));
        Z := TB.ToText();
        Observer.Observe('grownCode3', Format(Z[3]));
        Observer.Observe('grownPos1', Format(Z[1]));
        Observer.Expect('len', '6');
        Observer.Expect('shrunk', 'abc');
        Observer.Expect('shrunkLen', '3');
        Observer.Expect('zero', '');
        Observer.Expect('grownLen', '5');
        Observer.Expect('grownCode3', '\u0000');
        Observer.Expect('grownPos1', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure Length_Errors()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abc');
        Observer.Observe('afterNeg', TB.ToText());
        asserterror TB.Length(TB.MaxCapacity() + 1);
        Observer.ObserveError('overMax');
        Observer.Expect('afterNeg', 'abc');
        Observer.Expect('overMax|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('overMax|code', 'AL:Overflow');
        Observer.Verify();
    end;
}

codeunit 71003 "LT TxC TB Capacity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Capacity_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        Observer.Observe('cap', Format(TB.Capacity()));
        Observer.Observe('max', Format(TB.MaxCapacity()));
        TB.Append('abc');
        Observer.Observe('capAfter', Format(TB.Capacity()));
        Observer.Observe('maxAfter', Format(TB.MaxCapacity()));
        TB.Clear();
        Observer.Observe('maxAfterClear', Format(TB.MaxCapacity()));
        Observer.Expect('cap', '16');
        Observer.Expect('max', '2147483647');
        Observer.Expect('capAfter', '16');
        Observer.Expect('maxAfter', '2147483647');
        Observer.Expect('maxAfterClear', '2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure Capacity_Setter()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Capacity(100);
        Observer.Observe('cap100', Format(TB.Capacity()));
        Observer.Observe('len', Format(TB.Length()));
        TB.Append('abcdef');
        TB.Capacity(6);
        Observer.Observe('cap6', Format(TB.Capacity()));
        Observer.Observe('text', TB.ToText());
        Observer.Observe('cap0Attempt', Format(TB.Capacity()));
        Observer.Expect('cap100', '100');
        Observer.Expect('len', '0');
        Observer.Expect('cap6', '6');
        Observer.Expect('text', 'abcdef');
        Observer.Expect('cap0Attempt', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Capacity_GrowsWithAppend()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        I: Integer;
    begin
        TB.Capacity(10);
        for I := 1 to 11 do
            TB.Append('x');
        Observer.Observe('capGE11', Format(TB.Capacity() >= 11));
        Observer.Observe('len', Format(TB.Length()));
        Observer.Expect('capGE11', 'Yes');
        Observer.Expect('len', '11');
        Observer.Verify();
    end;

    [Test]
    procedure EnsureCapacity_Basics()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        B: Boolean;
    begin
        B := TB.EnsureCapacity(50);
        Observer.Observe('ret50', Format(B));
        Observer.Observe('cap50GE', Format(TB.Capacity() >= 50));
        B := TB.EnsureCapacity(10);
        Observer.Observe('ret10', Format(B));
        Observer.Observe('retEqCap', Format(B));
        B := TB.EnsureCapacity(0);
        Observer.Observe('ret0', Format(B));
        B := TB.EnsureCapacity(-1);
        Observer.Observe('negative', 'no error');
        asserterror B := TB.EnsureCapacity(TB.MaxCapacity() + 1);
        Observer.ObserveError('overMax');
        Observer.Expect('ret50', 'Yes');
        Observer.Expect('cap50GE', 'Yes');
        Observer.Expect('ret10', 'Yes');
        Observer.Expect('retEqCap', 'Yes');
        Observer.Expect('ret0', 'Yes');
        Observer.Expect('negative', 'no error');
        Observer.Expect('overMax|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('overMax|code', 'AL:Overflow');
        Observer.Verify();
    end;
}
