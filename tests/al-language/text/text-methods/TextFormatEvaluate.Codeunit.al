// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Format and Evaluate of Text and Code.
// BC versions: 29 (27 and 28 by CI)

codeunit 70514 "LT TxB TextFormatEvaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        T5: Text[5];
        C5: Code[5];
        C10: Code[10];
        I: Integer;
        D: Decimal;
        TLabel: Label 'Hello World', Locked = true;
        CLabel: Label 'abc', Locked = true, MaxLength = 10;

    [Test]
    procedure FormatTextCode()
    begin
        C5 := 'ab';
        T5 := ' x ';
        Obs.Observe('code', Format(Format(C5)));
        Obs.Observe('text', Format(Format(T5)));
        Obs.Observe('textlen', Format(StrLen(Format(T5))));
        Obs.Observe('empty', Format(Format('')));
        Obs.Observe('emptylen', Format(StrLen(Format(''))));
        Obs.Observe('f0', Format(Format('abc',0)));
        Obs.Observe('f5', Format(Format('abc',5)));
        Obs.Observe('f2', Format(Format('abc',2)));
        Obs.Observe('f_5', Format(Format('abc',-5)));
        Obs.Observe('fnine', Format(Format('abc',0,0)));
        Obs.Observe('fcode5', Format(Format(C5,5)));
        Obs.Observe('fcode1', Format(Format(C5,1)));
        Obs.Observe('unicode', Format(Format('äö')));
        Obs.Observe('label', Format(Format(TLabel)));
        Obs.Observe('labelc', Format(Format(CLabel)));
        Obs.Observe('fmt9', Format(Format('a',0,9)));
        Obs.Observe('fmt1', Format(Format('abc',0,1)));
        Obs.Observe('fmtstr', Format(Format('abc',0,'xx')));
        Obs.Observe('fmtq', Format(Format('a b',0,'<Text>')));
        Obs.Expect('code', 'AB');
        Obs.Expect('text', ' x ');
        Obs.Expect('textlen', '3');
        Obs.Expect('empty', '');
        Obs.Expect('emptylen', '0');
        Obs.Expect('f0', 'abc');
        Obs.Expect('f5', 'abc  ');
        Obs.Expect('f2', 'ab');
        Obs.Expect('f_5', 'abc');
        Obs.Expect('fnine', 'abc');
        Obs.Expect('fcode5', 'AB   ');
        Obs.Expect('fcode1', 'A');
        Obs.Expect('unicode', 'äö');
        Obs.Expect('label', 'Hello World');
        Obs.Expect('labelc', 'abc');
        Obs.Expect('fmt9', 'a');
        Obs.Expect('fmt1', 'abc');
        Obs.Expect('fmtstr', 'xx');
        Obs.Expect('fmtq', 'a b');
        Obs.Verify();
    end;

    [Test]
    procedure EvaluateText()
    begin
        T := 'x';
        Obs.Observe('ret', Format(Evaluate(T,'abc')));
        Obs.Observe('val', Format(T));
        Obs.Observe('empty', Format(Evaluate(T,'')));
        Obs.Observe('emptyval', Format(StrLen(T)));
        Obs.Observe('blank', Format(Evaluate(T,'  a  ')));
        Obs.Observe('blankval', Format(T));
        Obs.Observe('blanklen', Format(StrLen(T)));
        Obs.Observe('quote', Format(Evaluate(T,'"abc"')));
        Obs.Observe('quoteval', Format(T));
        Obs.Observe('apos', Format(Evaluate(T,'''abc''')));
        Obs.Observe('aposval', Format(T));
        Obs.Observe('long', Format(Evaluate(T,PadStr('',50,'a'))));
        Obs.Observe('longlen', Format(StrLen(T)));
        Obs.Observe('unicode', Format(Evaluate(T,'äö')));
        Obs.Observe('unicodeval', Format(T));
        Obs.Expect('ret', 'Yes');
        Obs.Expect('val', 'abc');
        Obs.Expect('empty', 'Yes');
        Obs.Expect('emptyval', '0');
        Obs.Expect('blank', 'Yes');
        Obs.Expect('blankval', '  a  ');
        Obs.Expect('blanklen', '5');
        Obs.Expect('quote', 'Yes');
        Obs.Expect('quoteval', '"abc"');
        Obs.Expect('apos', 'Yes');
        Obs.Expect('aposval', '''abc''');
        Obs.Expect('long', 'Yes');
        Obs.Expect('longlen', '50');
        Obs.Expect('unicode', 'Yes');
        Obs.Expect('unicodeval', 'äö');
        Obs.Verify();
    end;

    [Test]
    procedure EvaluateTextN()
    begin
        T5 := 'x';
        Obs.Observe('ok', Format(Evaluate(T5,'abcde')));
        Obs.Observe('okval', Format(T5));
        asserterror Evaluate(T5,'abcdef');
        Obs.ObserveError('over');
        Obs.Observe('keeps', Format(T5));
        Obs.Observe('ret2', Format(Evaluate(T5,'')));
        Obs.Observe('empty', Format(T5));
        Obs.Observe('blanks', Format(Evaluate(T5,'  a  ')));
        Obs.Observe('blanksval', Format(T5));
        Obs.Observe('blankslen', Format(StrLen(T5)));
        asserterror Evaluate(T5,'ab    ');
        Obs.ObserveError('overblank');
        Obs.Observe('quoted', Format(Evaluate(T5,'"ab"')));
        Obs.Observe('quotedval', Format(T5));
        Obs.Expect('ok', 'Yes');
        Obs.Expect('okval', 'abcde');
        Obs.Expect('over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('over|code', 'StringLengthExceeded');
        Obs.Expect('keeps', 'abcde');
        Obs.Expect('ret2', 'Yes');
        Obs.Expect('empty', '');
        Obs.Expect('blanks', 'Yes');
        Obs.Expect('blanksval', '  a  ');
        Obs.Expect('blankslen', '5');
        Obs.Expect('overblank|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: ab    ');
        Obs.Expect('overblank|code', 'StringLengthExceeded');
        Obs.Expect('quoted', 'Yes');
        Obs.Expect('quotedval', '"ab"');
        Obs.Verify();
    end;

    [Test]
    procedure EvaluateCode()
    begin
        C5 := 'X';
        Obs.Observe('ok', Format(Evaluate(C5,'abc')));
        Obs.Observe('okval', Format(C5));
        Obs.Observe('empty', Format(Evaluate(C5,'')));
        Obs.Observe('emptyval', Format(StrLen(C5)));
        Obs.Observe('blank', Format(Evaluate(C5,'  a  ')));
        Obs.Observe('blankval', Format(C5));
        Obs.Observe('blanklen', Format(StrLen(C5)));
        asserterror Evaluate(C5,'abcdef');
        Obs.ObserveError('over');
        Obs.Observe('keeps', Format(C5));
        Obs.Observe('exact', Format(Evaluate(C5,'abcde')));
        Obs.Observe('exactval', Format(C5));
        Obs.Observe('quoted', Format(Evaluate(C5,'"ab"')));
        Obs.Observe('quotedval', Format(C5));
        Obs.Observe('mixed', Format(Evaluate(C5,'aBc')));
        Obs.Observe('mixedval', Format(C5));
        Obs.Observe('unicode', Format(Evaluate(C5,'äö')));
        Obs.Observe('unicodeval', Format(C5));
        Obs.Expect('ok', 'Yes');
        Obs.Expect('okval', 'ABC');
        Obs.Expect('empty', 'Yes');
        Obs.Expect('emptyval', '0');
        Obs.Expect('blank', 'Yes');
        Obs.Expect('blankval', 'A');
        Obs.Expect('blanklen', '1');
        Obs.Expect('over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('over|code', 'StringLengthExceeded');
        Obs.Expect('keeps', 'A');
        Obs.Expect('exact', 'Yes');
        Obs.Expect('exactval', 'ABCDE');
        Obs.Expect('quoted', 'Yes');
        Obs.Expect('quotedval', '"AB"');
        Obs.Expect('mixed', 'Yes');
        Obs.Expect('mixedval', 'ABC');
        Obs.Expect('unicode', 'Yes');
        Obs.Expect('unicodeval', 'ÄÖ');
        Obs.Verify();
    end;

}
