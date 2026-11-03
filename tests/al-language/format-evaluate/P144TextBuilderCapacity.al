// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: TextBuilder.Capacity after appends beyond it, EnsureCapacity between length and capacity, Capacity(N) below the length, Capacity after Clear
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70234 "LT P144 TB Capacity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Chars(Count: Integer): Text
    begin
        exit(PadStr('', Count, 'a'));
    end;

    [Test]
    procedure P144_Growth_ByAppend()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        Observer.Observe('cap_new', Format(TB.Capacity()));
        TB.Append(Chars(16));
        Observer.Observe('len16_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append('b');
        Observer.Observe('len17_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append(Chars(15));
        Observer.Observe('len32_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append('c');
        Observer.Observe('len33_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append(Chars(31));
        Observer.Observe('len64_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append('d');
        Observer.Observe('len65_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append(Chars(35));
        Observer.Observe('len100_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append(Chars(900));
        Observer.Observe('len1000_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        Observer.Expect('cap_new', '16');
        Observer.Expect('len16_cap', '16/16');
        Observer.Expect('len17_cap', '17/32');
        Observer.Expect('len32_cap', '32/32');
        Observer.Expect('len33_cap', '33/64');
        Observer.Expect('len64_cap', '64/64');
        Observer.Expect('len65_cap', '65/128');
        Observer.Expect('len100_cap', '100/128');
        Observer.Expect('len1000_cap', '1000/1000');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Growth_BigAppendAtOnce()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        TB2: TextBuilder;
        TB3: TextBuilder;
    begin
        TB.Append(Chars(17));
        Observer.Observe('append17_cap', Format(TB.Capacity()));
        TB2.Append(Chars(40));
        Observer.Observe('append40_cap', Format(TB2.Capacity()));
        TB3.Append(Chars(500));
        Observer.Observe('append500_cap', Format(TB3.Capacity()));
        TB3.AppendLine('x');
        Observer.Observe('appendline_cap', Format(TB3.Length()) + '/' + Format(TB3.Capacity()));
        Observer.Expect('append17_cap', '32');
        Observer.Expect('append40_cap', '40');
        Observer.Expect('append500_cap', '500');
        Observer.Expect('appendline_cap', '503/1000');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Growth_FromSetCapacity()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        TB2: TextBuilder;
    begin
        TB.Capacity(10);
        Observer.Observe('set10', Format(TB.Capacity()));
        TB.Append(Chars(10));
        Observer.Observe('len10_cap', Format(TB.Capacity()));
        TB.Append('b');
        Observer.Observe('len11_cap', Format(TB.Capacity()));
        TB2.Capacity(4);
        Observer.Observe('set4_empty', Format(TB2.Capacity()));
        TB2.Append(Chars(5));
        Observer.Observe('set4_append5_cap', Format(TB2.Capacity()));
        Observer.Expect('set10', '10');
        Observer.Expect('len10_cap', '10');
        Observer.Expect('len11_cap', '20');
        Observer.Expect('set4_empty', '4');
        Observer.Expect('set4_append5_cap', '8');
        Observer.Verify();
    end;

    [Test]
    procedure P144_EnsureCapacity_BetweenLengthAndCapacity()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append(Chars(10));
        TB.EnsureCapacity(12);
        Observer.Observe('ensure12', Format(TB.Capacity()));
        TB.EnsureCapacity(10);
        Observer.Observe('ensure10_equals_len', Format(TB.Capacity()));
        TB.EnsureCapacity(0);
        Observer.Observe('ensure0', Format(TB.Capacity()));
        TB.EnsureCapacity(16);
        Observer.Observe('ensure16', Format(TB.Capacity()));
        TB.EnsureCapacity(17);
        Observer.Observe('ensure17', Format(TB.Capacity()));
        TB.EnsureCapacity(100);
        Observer.Observe('ensure100', Format(TB.Capacity()));
        TB.EnsureCapacity(50);
        Observer.Observe('ensure50_after_100', Format(TB.Capacity()));
        Observer.Observe('len_unchanged', Format(TB.Length()));
        Observer.Observe('text_unchanged', Format(TB.ToText() = Chars(10)));
        Observer.Expect('ensure12', '16');
        Observer.Expect('ensure10_equals_len', '16');
        Observer.Expect('ensure0', '16');
        Observer.Expect('ensure16', '16');
        Observer.Expect('ensure17', '17');
        Observer.Expect('ensure100', '100');
        Observer.Expect('ensure50_after_100', '100');
        Observer.Expect('len_unchanged', '10');
        Observer.Expect('text_unchanged', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P144_EnsureCapacity_OnEmptyAndAfterSet()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        TB2: TextBuilder;
    begin
        TB.EnsureCapacity(5);
        Observer.Observe('empty_ensure5', Format(TB.Capacity()));
        TB.EnsureCapacity(33);
        Observer.Observe('empty_ensure33', Format(TB.Capacity()));
        TB2.Capacity(50);
        TB2.EnsureCapacity(40);
        Observer.Observe('set50_ensure40', Format(TB2.Capacity()));
        TB2.EnsureCapacity(51);
        Observer.Observe('set50_ensure51', Format(TB2.Capacity()));
        Observer.Expect('empty_ensure5', '16');
        Observer.Expect('empty_ensure33', '33');
        Observer.Expect('set50_ensure40', '50');
        Observer.Expect('set50_ensure51', '51');
        Observer.Verify();
    end;

    [Test]
    procedure P144_EnsureCapacity_Negative()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append('abc');
        asserterror TB.EnsureCapacity(-1);
        Observer.ObserveError('ensure_minus1');
        Observer.Observe('cap_after', Format(TB.Capacity()));
        Observer.Expect('ensure_minus1|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('ensure_minus1|code', 'ArgumentOutOfRange');
        Observer.Expect('cap_after', '16');
        Observer.Verify();
    end;

    [Test]
    procedure P144_SetCapacity_EqualAndAboveLength()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Append(Chars(20));
        TB.Capacity(20);
        Observer.Observe('cap20_len20', Format(TB.Capacity()));
        TB.Capacity(21);
        Observer.Observe('cap21', Format(TB.Capacity()));
        TB.Append(Chars(1));
        Observer.Observe('len21_cap', Format(TB.Capacity()));
        TB.Append(Chars(1));
        Observer.Observe('len22_cap', Format(TB.Capacity()));
        TB.Capacity(1000);
        Observer.Observe('cap1000', Format(TB.Capacity()));
        TB.Capacity(30);
        Observer.Observe('cap30_shrink', Format(TB.Capacity()));
        Observer.Expect('cap20_len20', '20');
        Observer.Expect('cap21', '21');
        Observer.Expect('len21_cap', '21');
        Observer.Expect('len22_cap', '42');
        Observer.Expect('cap1000', '1000');
        Observer.Expect('cap30_shrink', '30');
        Observer.Verify();
    end;

    [Test]
    procedure P144_SetCapacity_OnEmpty()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        TB.Capacity(0);
        Observer.Observe('cap0_empty', Format(TB.Capacity()));
        TB.Append('x');
        Observer.Observe('append1_cap', Format(TB.Capacity()));
        Observer.Expect('cap0_empty', '0');
        Observer.Expect('append1_cap', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P144_SetCapacity_NegativeOnEmpty()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
    begin
        Observer.Observe('cap_after', Format(TB.Capacity()));
        Observer.Expect('cap_after', '16');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Capacity_AfterClear()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        TB2: TextBuilder;
    begin
        TB.Append(Chars(100));
        Observer.Observe('grown', Format(TB.Capacity()));
        TB.Clear();
        Observer.Observe('cleared_len_cap', Format(TB.Length()) + '/' + Format(TB.Capacity()));
        TB.Append('x');
        Observer.Observe('append_after_clear_cap', Format(TB.Capacity()));
        TB2.Capacity(1000);
        TB2.Append('abc');
        TB2.Clear();
        Observer.Observe('set1000_cleared', Format(TB2.Capacity()));
        TB2.Capacity(5);
        Observer.Observe('set5_after_clear', Format(TB2.Capacity()));
        Observer.Expect('grown', '100');
        Observer.Expect('cleared_len_cap', '0/100');
        Observer.Expect('append_after_clear_cap', '100');
        Observer.Expect('set1000_cleared', '1000');
        Observer.Expect('set5_after_clear', '5');
        Observer.Verify();
    end;
}
