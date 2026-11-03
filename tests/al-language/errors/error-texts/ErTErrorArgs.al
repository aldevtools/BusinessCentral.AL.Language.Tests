// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), none
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Error argument forms
// BC versions: 29 (27 and 28 by CI)

codeunit 70071 "LT ErT Error Args"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LblPlain: Label 'Label plain';
        LblArgs: Label 'Label %1 and %2';
        LblStr: Label 'Label with %1';

    [Test]
    procedure ErrorPlainAndPlaceholders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('plain');
        Observer.ObserveError('plain');
        asserterror Error('one %1', 'a');
        Observer.ObserveError('one');
        asserterror Error('%1 + %2 = %3', 1, 2, 3);
        Observer.ObserveError('three');
        asserterror Error('%2 before %1', 'x', 'y');
        Observer.ObserveError('swapped');
        asserterror Error('%1 %1 %1', 'rep');
        Observer.ObserveError('repeated');
        asserterror Error('no placeholder', 'unused');
        Observer.ObserveError('unusedArg');
        asserterror Error('missing %1 and %2', 'only');
        Observer.ObserveError('missingArg');
        asserterror Error('percent 100%');
        Observer.ObserveError('percent');
        asserterror Error('%%1 literal', 'a');
        Observer.ObserveError('doublePercent');
        asserterror Error('%10 ten', 'a');
        Observer.ObserveError('ten');
        Observer.Expect('plain|text', 'plain');
        Observer.Expect('plain|code', 'Dialog');
        Observer.Expect('one|text', 'one a');
        Observer.Expect('one|code', 'Dialog');
        Observer.Expect('three|text', '1 + 2 = 3');
        Observer.Expect('three|code', 'Dialog');
        Observer.Expect('swapped|text', 'y before x');
        Observer.Expect('swapped|code', 'Dialog');
        Observer.Expect('repeated|text', 'rep rep rep');
        Observer.Expect('repeated|code', 'Dialog');
        Observer.Expect('unusedArg|text', 'no placeholder');
        Observer.Expect('unusedArg|code', 'Dialog');
        Observer.Expect('missingArg|text', 'missing only and %2');
        Observer.Expect('missingArg|code', 'Dialog');
        Observer.Expect('percent|text', 'percent 100%');
        Observer.Expect('percent|code', 'Dialog');
        Observer.Expect('doublePercent|text', '%a literal');
        Observer.Expect('doublePercent|code', 'Dialog');
        Observer.Expect('ten|text', '%10 ten');
        Observer.Expect('ten|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorLabelForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(LblPlain);
        Observer.ObserveError('labelPlain');
        asserterror Error(LblArgs, 7, 'seven');
        Observer.ObserveError('labelArgs');
        asserterror Error(LblStr, LblPlain);
        Observer.ObserveError('labelAsArg');
        asserterror Error(StrSubstNo(LblArgs, 1, 2));
        Observer.ObserveError('substNo');
        Observer.Expect('labelPlain|text', 'Label plain');
        Observer.Expect('labelPlain|code', 'Dialog');
        Observer.Expect('labelArgs|text', 'Label 7 and seven');
        Observer.Expect('labelArgs|code', 'Dialog');
        Observer.Expect('labelAsArg|text', 'Label with Label plain');
        Observer.Expect('labelAsArg|code', 'Dialog');
        Observer.Expect('substNo|text', 'Label 1 and 2');
        Observer.Expect('substNo|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorArgumentTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('dec %1', 1.5);
        Observer.ObserveError('decimal');
        asserterror Error('bool %1', true);
        Observer.ObserveError('boolean');
        asserterror Error('date %1', 20240131D);
        Observer.ObserveError('date');
        asserterror Error('time %1', 123456T);
        Observer.ObserveError('time');
        asserterror Error('neg %1', -42);
        Observer.ObserveError('negative');
        asserterror Error('char %1', 'A');
        Observer.ObserveError('char');
        asserterror Error('big %1', 123456789012L);
        Observer.ObserveError('biginteger');
        asserterror Error('code %1', CopyStr('abc', 1, 2));
        Observer.ObserveError('copystr');
        Observer.Expect('decimal|text', 'dec 1.5');
        Observer.Expect('decimal|code', 'Dialog');
        Observer.Expect('boolean|text', 'bool Yes');
        Observer.Expect('boolean|code', 'Dialog');
        Observer.Expect('date|text', 'date 01/31/24');
        Observer.Expect('date|code', 'Dialog');
        Observer.Expect('time|text', 'time 12:34:56 PM');
        Observer.Expect('time|code', 'Dialog');
        Observer.Expect('negative|text', 'neg -42');
        Observer.Expect('negative|code', 'Dialog');
        Observer.Expect('char|text', 'char A');
        Observer.Expect('char|code', 'Dialog');
        Observer.Expect('biginteger|text', 'big 123456789012');
        Observer.Expect('biginteger|code', 'Dialog');
        Observer.Expect('copystr|text', 'code ab');
        Observer.Expect('copystr|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorSpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Nl: Text[1];
    begin
        Nl[1] := 10;
        asserterror Error('quote '' apostrophe');
        Observer.ObserveError('apostrophe');
        asserterror Error('double " quote');
        Observer.ObserveError('doubleQuote');
        asserterror Error('line1' + Nl + 'line2');
        Observer.ObserveError('newline');
        asserterror Error('umlaut äöüß €');
        Observer.ObserveError('umlaut');
        asserterror Error('emoji 😀');
        Observer.ObserveError('emoji');
        asserterror Error('{braces} [brackets] <angle>');
        Observer.ObserveError('brackets');
        asserterror Error('trailing space ');
        Observer.ObserveError('trailingSpace');
        asserterror Error('  leading space');
        Observer.ObserveError('leadingSpace');
        asserterror Error('tab' + Format(9) + 'x');
        Observer.ObserveError('digitsOnly');
        Observer.Expect('apostrophe|text', 'quote '' apostrophe');
        Observer.Expect('apostrophe|code', 'Dialog');
        Observer.Expect('doubleQuote|text', 'double " quote');
        Observer.Expect('doubleQuote|code', 'Dialog');
        Observer.Expect('newline|text', 'line1\nline2');
        Observer.Expect('newline|code', 'Dialog');
        Observer.Expect('umlaut|text', 'umlaut äöüß €');
        Observer.Expect('umlaut|code', 'Dialog');
        Observer.Expect('emoji|text', 'emoji \uD83D\uDE00');
        Observer.Expect('emoji|code', 'Dialog');
        Observer.Expect('brackets|text', '{braces} [brackets] <angle>');
        Observer.Expect('brackets|code', 'Dialog');
        Observer.Expect('trailingSpace|text', 'trailing space ');
        Observer.Expect('trailingSpace|code', 'Dialog');
        Observer.Expect('leadingSpace|text', '  leading space');
        Observer.Expect('leadingSpace|code', 'Dialog');
        Observer.Expect('digitsOnly|text', 'tab9x');
        Observer.Expect('digitsOnly|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorLongTexts()
    var
        Observer: Codeunit "Probe Observer";
        Long: Text;
        i: Integer;
    begin
        for i := 1 to 100 do begin
            Long += '0123456789';
        end;
        asserterror Error(Long);
        Observer.ObserveError('len1000');
        Observer.Observe('len1000Length', Format(StrLen(GetLastErrorText())));
        Long := '';
        for i := 1 to 600 do begin
            Long += '0123456789';
        end;
        asserterror Error(Long);
        Observer.Observe('len6000Length', Format(StrLen(GetLastErrorText())));
        Observer.Observe('len6000Code', GetLastErrorCode());
        asserterror Error('%1', Long);
        Observer.Observe('len6000ArgLength', Format(StrLen(GetLastErrorText())));
        Observer.Expect('len1000|text', '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789');
        Observer.Expect('len1000|code', 'Dialog');
        Observer.Expect('len1000Length', '0');
        Observer.Expect('len6000Length', '6000');
        Observer.Expect('len6000Code', 'Dialog');
        Observer.Expect('len6000ArgLength', '6000');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfoForms()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('from errorinfo');
        asserterror Error(ErrInfo);
        Observer.ObserveError('errorInfoCreate');
        ErrInfo.Message := 'set message';
        asserterror Error(ErrInfo);
        Observer.ObserveError('errorInfoMessage');
        ErrInfo.ErrorType := ErrorType::Client;
        ErrInfo.Verbosity := Verbosity::Warning;
        ErrInfo.Title := 'the title';
        asserterror Error(ErrInfo);
        Observer.ObserveError('errorInfoFull');
        Observer.Observe('title', ErrInfo.Title);
        Observer.Observe('message', ErrInfo.Message);
        Observer.Observe('errorType', Format(ErrInfo.ErrorType));
        Observer.Observe('verbosity', Format(ErrInfo.Verbosity));
        Observer.Observe('collectible', Format(ErrInfo.Collectible));
        Observer.Expect('errorInfoCreate|text', 'from errorinfo');
        Observer.Expect('errorInfoCreate|code', 'Dialog');
        Observer.Expect('errorInfoMessage|text', 'set message');
        Observer.Expect('errorInfoMessage|code', 'Dialog');
        Observer.Expect('errorInfoFull|text', 'set message');
        Observer.Expect('errorInfoFull|code', 'Dialog');
        Observer.Expect('title', 'the title');
        Observer.Expect('message', 'set message');
        Observer.Expect('errorType', 'Client');
        Observer.Expect('verbosity', 'Warning');
        Observer.Expect('collectible', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorEmptyAndBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('');
        Observer.ObserveError('empty');
        asserterror Error(' ');
        Observer.ObserveError('blank');
        asserterror Error('%1', '');
        Observer.ObserveError('emptyArg');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', 'Dialog');
        Observer.Expect('blank|text', ' ');
        Observer.Expect('blank|code', 'Dialog');
        Observer.Expect('emptyArg|text', '');
        Observer.Expect('emptyArg|code', 'Dialog');
        Observer.Verify();
    end;
}
