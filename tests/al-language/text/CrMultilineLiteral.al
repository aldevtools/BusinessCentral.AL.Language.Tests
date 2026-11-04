// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: corpus issue #672 item 47 (multiline text literals with the @ prefix). Not pinned before (the corpus used @ only in dialog masks).
// The literals below are stored with LF line endings, except the one in MultilineLiteral_Crlf, whose line ends with CR LF bytes in this
// file (keep them: the test asks whether the compiler keeps CR LF or turns it into LF). Every literal asserted is what BC produced.
// BC versions: 27, 28, 29

codeunit 85122 "LT CR Multiline Literal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MultilineLiteral_Lf()
    var
        Obs: Codeunit "Probe Observer";
        T: Text;
    begin
        T := @'a
b';
        Obs.Observe('two_lines', T);
        Obs.Observe('two_lines_len', Format(StrLen(T)));
        T := @'first
    indented
	tab
last';
        Obs.Observe('indent', T);
        T := @'it''s
here';
        Obs.Observe('quote', T);
        T := @'one line';
        Obs.Observe('single', T);
        T := @'';
        Obs.Observe('empty_len', Format(StrLen(T)));
        T := @'trailing
';
        Obs.Observe('trailing_newline', T);
        T := @'back\nslash';
        Obs.Observe('backslash_len', Format(StrLen(T)));
        Obs.Observe('backslash_has', Format(T.Contains('\')));
        T := @'x
y' + 'z';
        Obs.Observe('concat', T);
        Obs.Observe('split_count', Format(@'p
q
r'.Split(@'
').Count()));
        Obs.Expect('two_lines', 'a\nb');
        Obs.Expect('two_lines_len', '3');
        Obs.Expect('indent', 'first\n    indented\n\ttab\nlast');
        Obs.Expect('quote', 'it''s\nhere');
        Obs.Expect('single', 'one line');
        Obs.Expect('empty_len', '0');
        Obs.Expect('trailing_newline', 'trailing\n');
        Obs.Expect('backslash_len', '11');
        Obs.Expect('backslash_has', 'Yes');
        Obs.Expect('concat', 'x\nyz');
        Obs.Expect('split_count', '3');
        Obs.Verify();
    end;

    [Test]
    procedure MultilineLiteral_Crlf()
    var
        Obs: Codeunit "Probe Observer";
        T: Text;
    begin
        T := @'c
d';
        Obs.Observe('crlf', T);
        Obs.Observe('crlf_len', Format(StrLen(T)));
        Obs.Expect('crlf', 'c\r\nd');
        Obs.Expect('crlf_len', '4');
        Obs.Verify();
    end;
}
