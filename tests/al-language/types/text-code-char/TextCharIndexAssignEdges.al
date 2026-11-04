// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Text[i] := c for i = 0, 1, length, length + 1, length + 2, the declared length and past it; c = 0, 65, 55296 (surrogate), 65535, 65536, negative; unbounded Text; Code[i]; reading Text[i] in and out of range
// BC versions: 29 (27 and 28 by CI)

codeunit 72871 "LT TextIdx Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAssign(var T: Text[5]; Idx: Integer; C: Integer)
    begin
        T[Idx] := C;
    end;

    [TryFunction]
    local procedure TryAssignUnbounded(var T: Text; Idx: Integer; C: Integer)
    begin
        T[Idx] := C;
    end;

    [TryFunction]
    local procedure TryAssignCode(var T: Code[5]; Idx: Integer; C: Integer)
    begin
        T[Idx] := C;
    end;

    [TryFunction]
    local procedure TryRead(T: Text[5]; Idx: Integer; var Result: Integer)
    var
        Ch: Char;
    begin
        Ch := T[Idx];
        Result := Ch;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; StartText: Text[5]; Idx: Integer; C: Integer)
    begin
        if TryAssign(StartText, Idx, C) then
            Observer.Observe(Name, 'ok len=' + Format(StrLen(StartText)) + ' text=[' + StartText + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure TextIndex_PositionsAroundTheLength()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'idx0', 'abc', 0, 65);
        Probe(Observer, 'idx1', 'abc', 1, 65);
        Probe(Observer, 'idx3_last', 'abc', 3, 65);
        Probe(Observer, 'idx4_onePast', 'abc', 4, 65);
        Probe(Observer, 'idx5_twoPast_declared', 'abc', 5, 65);
        Probe(Observer, 'idx6_pastDeclared', 'abc', 6, 65);
        Probe(Observer, 'idxNeg1', 'abc', -1, 65);
        Probe(Observer, 'empty_idx1', '', 1, 65);
        Probe(Observer, 'empty_idx2', '', 2, 65);
        Probe(Observer, 'full_idx5', 'abcde', 5, 65);
        Probe(Observer, 'full_idx6', 'abcde', 6, 65);
        Probe(Observer, 'two_idx4', 'ab', 4, 65);
        Observer.Expect('idx0|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 3.');
        Observer.Expect('idx0|code', 'OutsidePermittedRange');
        Observer.Expect('idx1', 'ok len=3 text=[Abc]');
        Observer.Expect('idx3_last', 'ok len=3 text=[abA]');
        Observer.Expect('idx4_onePast', 'ok len=4 text=[abcA]');
        Observer.Expect('idx5_twoPast_declared|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 5. The permitted range is: from 1 to 3.');
        Observer.Expect('idx5_twoPast_declared|code', 'OutsidePermittedRange');
        Observer.Expect('idx6_pastDeclared|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 6. The permitted range is: from 1 to 3.');
        Observer.Expect('idx6_pastDeclared|code', 'OutsidePermittedRange');
        Observer.Expect('idxNeg1|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 3.');
        Observer.Expect('idxNeg1|code', 'OutsidePermittedRange');
        Observer.Expect('empty_idx1', 'ok len=1 text=[A]');
        Observer.Expect('empty_idx2|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 2. The permitted range is: from 1 to 0.');
        Observer.Expect('empty_idx2|code', 'OutsidePermittedRange');
        Observer.Expect('full_idx5', 'ok len=5 text=[abcdA]');
        Observer.Expect('full_idx6|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdeA');
        Observer.Expect('full_idx6|code', 'StringLengthExceeded');
        Observer.Expect('two_idx4|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 4. The permitted range is: from 1 to 2.');
        Observer.Expect('two_idx4|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextIndex_CharacterValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'c0', 'abc', 2, 0);
        Probe(Observer, 'c1', 'abc', 2, 1);
        Probe(Observer, 'c32', 'abc', 2, 32);
        Probe(Observer, 'c126', 'abc', 2, 126);
        Probe(Observer, 'c255', 'abc', 2, 255);
        Probe(Observer, 'c256', 'abc', 2, 256);
        Probe(Observer, 'c8364_euro', 'abc', 2, 8364);
        Probe(Observer, 'c55295', 'abc', 2, 55295);
        Probe(Observer, 'c55296_highSurrogate', 'abc', 2, 55296);
        Probe(Observer, 'c56320_lowSurrogate', 'abc', 2, 56320);
        Probe(Observer, 'c57343', 'abc', 2, 57343);
        Probe(Observer, 'c57344', 'abc', 2, 57344);
        Probe(Observer, 'c65535', 'abc', 2, 65535);
        Probe(Observer, 'c65536', 'abc', 2, 65536);
        Probe(Observer, 'c70000', 'abc', 2, 70000);
        Probe(Observer, 'cNeg1', 'abc', 2, -1);
        Observer.Expect('c0', 'ok len=1 text=[a]');
        Observer.Expect('c1', 'ok len=3 text=[a\u0001c]');
        Observer.Expect('c32', 'ok len=3 text=[a c]');
        Observer.Expect('c126', 'ok len=3 text=[a~c]');
        Observer.Expect('c255', 'ok len=3 text=[aÿc]');
        Observer.Expect('c256', 'ok len=3 text=[aĀc]');
        Observer.Expect('c8364_euro', 'ok len=3 text=[a€c]');
        Observer.Expect('c55295', 'ok len=3 text=[a퟿c]');
        Observer.Expect('c55296_highSurrogate', 'ok len=3 text=[a\uD800c]');
        Observer.Expect('c56320_lowSurrogate', 'ok len=3 text=[a\uDC00c]');
        Observer.Expect('c57343', 'ok len=3 text=[a\uDFFFc]');
        Observer.Expect('c57344', 'ok len=3 text=[ac]');
        Observer.Expect('c65535', 'ok len=3 text=[a\uFFFFc]');
        Observer.Expect('c65536|text', 'Overflow under conversion of System.Int32 value 65536 to System.Char.');
        Observer.Expect('c65536|code', 'ConversionCast');
        Observer.Expect('c70000|text', 'Overflow under conversion of System.Int32 value 70000 to System.Char.');
        Observer.Expect('c70000|code', 'ConversionCast');
        Observer.Expect('cNeg1|text', 'Overflow under conversion of System.Int32 value -1 to System.Char.');
        Observer.Expect('cNeg1|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure TextIndex_UnboundedTextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        C: Code[5];
    begin
        T := 'abc';
        if TryAssignUnbounded(T, 4, 100) then
            Observer.Observe('unb_onePast', 'ok [' + T + ']')
        else
            Observer.ObserveError('unb_onePast');
        T := 'abc';
        if TryAssignUnbounded(T, 6, 100) then
            Observer.Observe('unb_threePast', 'ok [' + T + ']')
        else
            Observer.ObserveError('unb_threePast');
        T := 'abc';
        if TryAssignUnbounded(T, 100, 100) then
            Observer.Observe('unb_far', 'ok [' + T + ']')
        else
            Observer.ObserveError('unb_far');
        T := 'abc';
        if TryAssignUnbounded(T, 2, 55296) then
            Observer.Observe('unb_surrogate', 'ok [' + T + ']')
        else
            Observer.ObserveError('unb_surrogate');
        C := 'abc';
        if TryAssignCode(C, 2, 120) then
            Observer.Observe('code_lower', 'ok [' + C + ']')
        else
            Observer.ObserveError('code_lower');
        C := 'abc';
        if TryAssignCode(C, 4, 100) then
            Observer.Observe('code_onePast', 'ok [' + C + '] len=' + Format(StrLen(C)))
        else
            Observer.ObserveError('code_onePast');
        C := 'abc';
        if TryAssignCode(C, 7, 100) then
            Observer.Observe('code_pastDeclared', 'ok [' + C + ']')
        else
            Observer.ObserveError('code_pastDeclared');
        C := 'abc';
        if TryAssignCode(C, 2, 65536) then
            Observer.Observe('code_65536', 'ok [' + C + ']')
        else
            Observer.ObserveError('code_65536');
        Observer.Expect('unb_onePast', 'ok [abcd]');
        Observer.Expect('unb_threePast|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 6. The permitted range is: from 1 to 3.');
        Observer.Expect('unb_threePast|code', 'OutsidePermittedRange');
        Observer.Expect('unb_far|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 100. The permitted range is: from 1 to 3.');
        Observer.Expect('unb_far|code', 'OutsidePermittedRange');
        Observer.Expect('unb_surrogate', 'ok [a\uD800c]');
        Observer.Expect('code_lower', 'ok [AXC]');
        Observer.Expect('code_onePast', 'ok [ABCD] len=4');
        Observer.Expect('code_pastDeclared|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 7. The permitted range is: from 1 to 3.');
        Observer.Expect('code_pastDeclared|code', 'OutsidePermittedRange');
        Observer.Expect('code_65536|text', 'Overflow under conversion of System.Int32 value 65536 to System.Char.');
        Observer.Expect('code_65536|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure TextIndex_ReadingACharacter()
    var
        Observer: Codeunit "Probe Observer";
        R: Integer;
    begin
        if TryRead('abc', 1, R) then
            Observer.Observe('read1', Format(R))
        else
            Observer.ObserveError('read1');
        if TryRead('abc', 3, R) then
            Observer.Observe('read3', Format(R))
        else
            Observer.ObserveError('read3');
        if TryRead('abc', 4, R) then
            Observer.Observe('read4_onePast', Format(R))
        else
            Observer.ObserveError('read4_onePast');
        if TryRead('abc', 0, R) then
            Observer.Observe('read0', Format(R))
        else
            Observer.ObserveError('read0');
        if TryRead('abc', -1, R) then
            Observer.Observe('readNeg1', Format(R))
        else
            Observer.ObserveError('readNeg1');
        if TryRead('', 1, R) then
            Observer.Observe('readEmpty1', Format(R))
        else
            Observer.ObserveError('readEmpty1');
        if TryRead('abcde', 6, R) then
            Observer.Observe('read6_pastDeclared', Format(R))
        else
            Observer.ObserveError('read6_pastDeclared');
        Observer.Expect('read1', '97');
        Observer.Expect('read3', '99');
        Observer.Expect('read4_onePast', '0');
        Observer.Expect('read0|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('read0|code', 'OutsidePermittedRange');
        Observer.Expect('readNeg1|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('readNeg1|code', 'OutsidePermittedRange');
        Observer.Expect('readEmpty1', '0');
        Observer.Expect('read6_pastDeclared', '0');
        Observer.Verify();
    end;
}
