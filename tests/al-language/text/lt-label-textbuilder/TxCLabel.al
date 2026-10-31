// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-label-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunits 71020-71025
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Label: Text methods on labels and constants, Locked, Comment, %1 placeholders, MaxLength, Label as parameter, Format, assignment.
// BC versions: 29 (27 and 28 by CI)

codeunit 71020 "LT TxC Label Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Hello: Label 'Hello, World';
        Mixed: Label 'Alpha Beta Gamma', Locked = true;
        Empty: Label '';
        Spaces: Label '  padded  ', Locked = true;
        Uni: Label 'Grüße €', Locked = true;
        Csv: Label 'a,b,,c', Locked = true;
        // al-runner issue 6436 (writer Y12): a trailing comma right after the label text compiles. After a property it does not
        // (tests/must-not-compile/cases/2330-label-trailing-comma-after-property.al).
        TrailingCommaLbl: Label 'Document Setup',;

    [Test]
    procedure Label_Instance_Methods()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('contains', Format(Hello.Contains('World')));
        Observer.Observe('containsCase', Format(Hello.Contains('world')));
        Observer.Observe('startsWith', Format(Hello.StartsWith('Hello')));
        Observer.Observe('endsWith', Format(Hello.EndsWith('World')));
        Observer.Observe('indexOf', Format(Hello.IndexOf('World')));
        Observer.Observe('indexOfStart', Format(Hello.IndexOf('o', 6)));
        Observer.Observe('lastIndexOf', Format(Hello.LastIndexOf('o')));
        Observer.Observe('toUpper', Hello.ToUpper());
        Observer.Observe('toLower', Hello.ToLower());
        Observer.Observe('replace', Hello.Replace('World', 'There'));
        Observer.Observe('substring2', Hello.Substring(8));
        Observer.Observe('substring3', Hello.Substring(1, 5));
        Observer.Observe('trim', Spaces.Trim());
        Observer.Observe('trimStart', Spaces.TrimStart(' '));
        Observer.Observe('trimEnd', Spaces.TrimEnd(' '));
        Observer.Observe('padLeft', Hello.PadLeft(15, '*'));
        Observer.Observe('padRight', Hello.PadRight(15, '*'));
        Observer.Observe('remove', Hello.Remove(5));
        asserterror Observer.Observe('remove2', Hello.Remove(0, 5));
        Observer.ObserveError('af44');
        Observer.Observe('splitCount', Format(Csv.Split(',').Count()));
        Observer.Observe('len', Format(StrLen(Hello)));
        Observer.Expect('contains', 'Yes');
        Observer.Expect('containsCase', 'No');
        Observer.Expect('startsWith', 'Yes');
        Observer.Expect('endsWith', 'Yes');
        Observer.Expect('indexOf', '8');
        Observer.Expect('indexOfStart', '9');
        Observer.Expect('lastIndexOf', '9');
        Observer.Expect('toUpper', 'HELLO, WORLD');
        Observer.Expect('toLower', 'hello, world');
        Observer.Expect('replace', 'Hello, There');
        Observer.Expect('substring2', 'World');
        Observer.Expect('substring3', 'Hello');
        Observer.Expect('trim', 'padded');
        Observer.Expect('trimStart', 'padded  ');
        Observer.Expect('trimEnd', '  padded');
        Observer.Expect('padLeft', '***Hello, World');
        Observer.Expect('padRight', 'Hello, World***');
        Observer.Expect('remove', 'Hell');
        Observer.Expect('af44|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('af44|code', 'ArgumentOutOfRange');
        Observer.Expect('splitCount', '4');
        Observer.Expect('len', '12');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Instance_Methods_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('len', Format(StrLen(Empty)));
        Observer.Observe('contains', Format(Empty.Contains('')));
        Observer.Observe('startsWith', Format(Empty.StartsWith('')));
        Observer.Observe('endsWith', Format(Empty.EndsWith('')));
        Observer.Observe('indexOf', Format(Empty.IndexOf('a')));
        Observer.Observe('upper', Empty.ToUpper());
        Observer.Observe('split', Format(Empty.Split(',').Count()));
        Observer.Observe('padLeft', Empty.PadLeft(3, '-'));
        Observer.Observe('sub', Empty.Substring(1));
        Observer.Observe('substring', 'no error');
        Observer.Expect('len', '0');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('startsWith', 'Yes');
        Observer.Expect('endsWith', 'Yes');
        Observer.Expect('indexOf', '0');
        Observer.Expect('upper', '');
        Observer.Expect('split', '1');
        Observer.Expect('padLeft', '---');
        Observer.Expect('sub', '');
        Observer.Expect('substring', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Instance_Methods_Unicode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('len', Format(StrLen(Uni)));
        Observer.Observe('upper', Uni.ToUpper());
        Observer.Observe('lower', Uni.ToLower());
        Observer.Observe('indexEuro', Format(Uni.IndexOf('€')));
        Observer.Observe('sub', Uni.Substring(1, 3));
        Observer.Expect('len', '7');
        Observer.Expect('upper', 'GRÜßE €');
        Observer.Expect('lower', 'grüße €');
        Observer.Expect('indexEuro', '7');
        Observer.Expect('sub', 'Grü');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Constant_Methods()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('constLen', Format(StrLen('literal')));
        Observer.Observe('constUpper', 'literal'.ToUpper());
        Observer.Observe('constContains', Format('literal'.Contains('ter')));
        Observer.Observe('constSub', 'literal'.Substring(2, 3));
        Observer.Observe('constReplace', 'a-b-c'.Replace('-', '+'));
        Observer.Observe('constSplit', Format('a;b;c'.Split(';').Count()));
        Observer.Observe('constIndex', Format('abcabc'.LastIndexOf('b')));
        Observer.Observe('constEmpty', Format(StrLen('')));
        Observer.Observe('constChain', 'abc'.ToUpper().PadLeft(5, '.').Replace('.', '_'));
        Observer.Expect('constLen', '7');
        Observer.Expect('constUpper', 'LITERAL');
        Observer.Expect('constContains', 'Yes');
        Observer.Expect('constSub', 'ite');
        Observer.Expect('constReplace', 'a+b+c');
        Observer.Expect('constSplit', '3');
        Observer.Expect('constIndex', '5');
        Observer.Expect('constEmpty', '0');
        Observer.Expect('constChain', '__ABC');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Substring_Errors()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        asserterror T := Hello.Substring(0);
        Observer.ObserveError('zero');
        asserterror T := Hello.Substring(100);
        Observer.ObserveError('far');
        T := Hello.Substring(1, 100);
        Observer.Observe('longCount', 'no error');
        asserterror T := Hello.Substring(1, -1);
        Observer.ObserveError('negCount');
        asserterror T := Hello.Remove(100);
        Observer.ObserveError('removeFar');
        Observer.Expect('zero|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('zero|code', 'ArgumentOutOfRange');
        Observer.Expect('far|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('far|code', 'ArgumentOutOfRange');
        Observer.Expect('longCount', 'no error');
        Observer.Expect('negCount|text', 'length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.');
        Observer.Expect('negCount|code', 'ArgumentOutOfRange');
        Observer.Expect('removeFar|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('removeFar|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_Label_TrailingComma()
    var
        LocalLbl: Label 'Local Text' ,;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('global', TrailingCommaLbl);
        Observer.Observe('global_len', Format(StrLen(TrailingCommaLbl)));
        Observer.Observe('local', LocalLbl);
        Observer.Observe('local_len', Format(StrLen(LocalLbl)));
        Observer.Expect('global', 'Document Setup');
        Observer.Expect('global_len', '14');
        Observer.Expect('local', 'Local Text');
        Observer.Expect('local_len', '10');
        Observer.Verify();
    end;
}

codeunit 71021 "LT TxC Label Attributes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Plain: Label 'Plain text';
        LockedLbl: Label 'Locked text', Locked = true;
        WithComment: Label 'Value %1 of %2', Comment = '%1 = value, %2 = total';
        Both: Label 'Both %1', Comment = 'a comment', Locked = true;
        MaxLbl: Label 'abcdef', MaxLength = 3;
        Two: Label 'Two: %1 and %2';
        Three: Label '%1-%2-%3', Locked = true;
        Quote: Label 'It''s here', Locked = true;
        Pct: Label '100%', Locked = true;
        PctOnly: Label '%1', Locked = true;
        Gap: Label 'only %2', Locked = true;
        Multi: Label 'line1\line2', Locked = true;

    [Test]
    procedure Label_Value_And_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plain', Plain);
        Observer.Observe('locked', LockedLbl);
        Observer.Observe('formatPlain', Format(Plain));
        Observer.Observe('formatLocked', Format(LockedLbl));
        Observer.Observe('withComment', WithComment);
        Observer.Observe('both', Both);
        Observer.Observe('quote', Quote);
        Observer.Observe('pct', Pct);
        Observer.Observe('multi', Multi);
        Observer.Observe('len', Format(StrLen(Plain)));
        Observer.Observe('format2', Format(Plain, 5));
        Observer.Observe('format0Bang', Format(Plain, 0, 0));
        Observer.Expect('plain', 'Plain text');
        Observer.Expect('locked', 'Locked text');
        Observer.Expect('formatPlain', 'Plain text');
        Observer.Expect('formatLocked', 'Locked text');
        Observer.Expect('withComment', 'Value %1 of %2');
        Observer.Expect('both', 'Both %1');
        Observer.Expect('quote', 'It''s here');
        Observer.Expect('pct', '100%');
        Observer.Expect('multi', 'line1\line2');
        Observer.Expect('len', '10');
        Observer.Expect('format2', 'Plain');
        Observer.Expect('format0Bang', 'Plain text');
        Observer.Verify();
    end;

    [Test]
    procedure Label_StrSubstNo_Placeholders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two', StrSubstNo(Two, 'X', 'Y'));
        Observer.Observe('twoInt', StrSubstNo(Two, 1, 2.5));
        Observer.Observe('twoMissing', StrSubstNo(Two, 'X'));
        Observer.Observe('twoNone', StrSubstNo(Two));
        Observer.Observe('three', StrSubstNo(Three, 'a', 'b', 'c'));
        Observer.Observe('withComment', StrSubstNo(WithComment, 3, 10));
        Observer.Observe('both', StrSubstNo(Both, true));
        Observer.Observe('pctOnly', StrSubstNo(PctOnly, 'v'));
        Observer.Observe('gap', StrSubstNo(Gap, 'a', 'b'));
        Observer.Observe('noPlaceholder', StrSubstNo(Plain, 'ignored'));
        Observer.Observe('pctLiteral', StrSubstNo(Pct, 'ignored'));
        Observer.Observe('extraArg', StrSubstNo(Two, 'A', 'B', 'C'));
        Observer.Observe('dateArg', StrSubstNo(PctOnly, 0D));
        Observer.Observe('labelArg', StrSubstNo(PctOnly, Plain));
        Observer.Expect('two', 'Two: X and Y');
        Observer.Expect('twoInt', 'Two: 1 and 2.5');
        Observer.Expect('twoMissing', 'Two: X and %2');
        Observer.Expect('twoNone', 'Two: %1 and %2');
        Observer.Expect('three', 'a-b-c');
        Observer.Expect('withComment', 'Value 3 of 10');
        Observer.Expect('both', 'Both Yes');
        Observer.Expect('pctOnly', 'v');
        Observer.Expect('gap', 'only b');
        Observer.Expect('noPlaceholder', 'Plain text');
        Observer.Expect('pctLiteral', '100%');
        Observer.Expect('extraArg', 'Two: A and B');
        Observer.Expect('dateArg', '');
        Observer.Expect('labelArg', 'Plain text');
        Observer.Verify();
    end;

    [Test]
    procedure Label_MaxLength()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Short: Text[3];
        Code2: Code[2];
    begin
        Observer.Observe('maxLbl', MaxLbl);
        Observer.Observe('maxLblLen', Format(StrLen(MaxLbl)));
        Observer.Observe('maxStrLenPlain', Format(MaxStrLen(Plain)));
        Observer.Observe('maxStrLenMax', Format(MaxStrLen(MaxLbl)));
        Observer.Observe('maxStrLenLocked', Format(MaxStrLen(LockedLbl)));
        Txt := MaxLbl;
        Observer.Observe('toText', Txt);
        asserterror Short := Plain;
        Observer.ObserveError('toText3');
        Short := CopyStr(Plain, 1, 3);
        Observer.Observe('copyStr', Short);
        asserterror Code2 := Plain;
        Observer.ObserveError('toCode2');
        Observer.Expect('maxLbl', 'abc');
        Observer.Expect('maxLblLen', '3');
        Observer.Expect('maxStrLenPlain', '2048');
        Observer.Expect('maxStrLenMax', '2048');
        Observer.Expect('maxStrLenLocked', '2048');
        Observer.Expect('toText', 'abc');
        Observer.Expect('toText3|text', 'The length of the string is 10, but it must be less than or equal to 3 characters. Value: Plain text');
        Observer.Expect('toText3|code', 'StringLengthExceeded');
        Observer.Expect('copyStr', 'Pla');
        Observer.Expect('toCode2|text', 'The length of the string is 10, but it must be less than or equal to 2 characters. Value: Plain text');
        Observer.Expect('toCode2|code', 'StringLengthExceeded');
        Observer.Verify();
    end;
}

codeunit 71022 "LT TxC Label Params"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Lbl: Label 'label value';
        LblUp: Label 'MiXeD', Locked = true;
        LongLbl: Label 'this label is longer than twenty characters', Locked = true;

    local procedure TakeText(T: Text): Text
    begin
        exit('[' + T + ']');
    end;

    local procedure TakeText10(T: Text[10]): Text
    begin
        exit('[' + T + ']');
    end;

    local procedure TakeCode(C: Code[20]): Text
    begin
        exit('[' + C + ']');
    end;

    local procedure TakeCode5(C: Code[5]): Text
    begin
        exit('[' + C + ']');
    end;

    local procedure TakeVarText(var T: Text): Text
    begin
        T := T + '+';
        exit(T);
    end;

    local procedure TakeLabel(L: Text): Text
    begin
        exit(L.ToUpper());
    end;

    local procedure ReturnLabel(): Text
    begin
        exit(Lbl);
    end;

    local procedure ReturnLabelCode(): Code[20]
    begin
        exit(LblUp);
    end;

    [Test]
    procedure Label_To_Text_Param()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text', TakeText(Lbl));
        asserterror Observer.Observe('text10', TakeText10(Lbl));
        Observer.ObserveError('af262');
        Observer.Observe('code', TakeCode(Lbl));
        Observer.Observe('codeUp', TakeCode(LblUp));
        Observer.Observe('upper', TakeLabel(Lbl));
        Observer.Observe('return', ReturnLabel());
        Observer.Observe('returnCode', ReturnLabelCode());
        Observer.Observe('literal', TakeCode('abc'));
        Observer.Expect('text', '[label value]');
        Observer.Expect('af262|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: label value');
        Observer.Expect('af262|code', 'StringLengthExceeded');
        Observer.Expect('code', '[LABEL VALUE]');
        Observer.Expect('codeUp', '[MIXED]');
        Observer.Expect('upper', 'LABEL VALUE');
        Observer.Expect('return', 'label value');
        Observer.Expect('returnCode', 'MIXED');
        Observer.Expect('literal', '[ABC]');
        Observer.Verify();
    end;

    [Test]
    procedure Label_To_Short_Param_Errors()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
    begin
        asserterror S := TakeText10(LongLbl);
        Observer.ObserveError('text10');
        asserterror S := TakeCode(LongLbl);
        Observer.ObserveError('code20');
        asserterror S := TakeCode5(Lbl);
        Observer.ObserveError('code5');
        S := TakeCode5(LblUp);
        Observer.Observe('code5mixed', 'no error');
        Observer.Expect('text10|text', 'The length of the string is 43, but it must be less than or equal to 10 characters. Value: this label is longer than twenty characters');
        Observer.Expect('text10|code', 'StringLengthExceeded');
        Observer.Expect('code20|text', 'The length of the string is 43, but it must be less than or equal to 20 characters. Value: this label is longer than twenty characters');
        Observer.Expect('code20|code', 'StringLengthExceeded');
        Observer.Expect('code5|text', 'The length of the string is 11, but it must be less than or equal to 5 characters. Value: label value');
        Observer.Expect('code5|code', 'StringLengthExceeded');
        Observer.Expect('code5mixed', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Assignment_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Cde: Code[20];
        Txt50: Text[50];
        Lst: List of [Text];
        Dict: Dictionary of [Text, Text];
    begin
        Txt := Lbl;
        Observer.Observe('toText', Txt);
        Txt50 := Lbl;
        Observer.Observe('toText50', Txt50);
        Cde := LblUp;
        Observer.Observe('toCode', Cde);
        Txt += Lbl;
        Observer.Observe('concat', Txt);
        Txt := Lbl + '/' + LblUp;
        Observer.Observe('plus', Txt);
        Lst.Add(Lbl);
        Observer.Observe('list', Lst.Get(1));
        Dict.Add(LblUp, Lbl);
        Observer.Observe('dict', Dict.Get(LblUp));
        Observer.Observe('varParam', TakeVarText(Txt));
        Observer.Observe('eq', Format(Lbl = 'label value'));
        Observer.Observe('eqCase', Format(LblUp = 'mixed'));
        Observer.Observe('ne', Format(Lbl <> LblUp));
        Observer.Observe('lt', Format(Lbl < LblUp));
        Observer.Observe('inStr', Format(Lbl in ['label value', 'x']));
        Observer.Observe('ifBranch', Format(Lbl = ''));
        Observer.Expect('toText', 'label value');
        Observer.Expect('toText50', 'label value');
        Observer.Expect('toCode', 'MIXED');
        Observer.Expect('concat', 'label valuelabel value');
        Observer.Expect('plus', 'label value/MiXeD');
        Observer.Expect('list', 'label value');
        Observer.Expect('dict', 'label value');
        Observer.Expect('varParam', 'label value/MiXeD+');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('eqCase', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('inStr', 'Yes');
        Observer.Expect('ifBranch', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Label_In_Builtins()
    var
        Observer: Codeunit "Probe Observer";
        Dec: Decimal;
        Int: Integer;
        Num: Label '42', Locked = true;
        DecLbl: Label '3.5', Locked = true;
    begin
        Observer.Observe('strlen', Format(StrLen(Lbl)));
        Observer.Observe('copystr', CopyStr(Lbl, 1, 5));
        Observer.Observe('strpos', Format(StrPos(Lbl, 'v')));
        Observer.Observe('upper', UpperCase(Lbl));
        Observer.Observe('lower', LowerCase(LblUp));
        Observer.Observe('delchr', DelChr(Lbl, '=', 'l'));
        Observer.Observe('convertstr', ConvertStr(Lbl, 'l', 'L'));
        Observer.Observe('padstr', PadStr(Lbl, 15, '.'));
        Observer.Observe('selectstr', SelectStr(1, 'a,b'));
        Observer.Observe('incstr', IncStr(Num));
        Observer.Observe('evaluateInt', Format(Evaluate(Int, Num)));
        Observer.Observe('int', Format(Int));
        Observer.Observe('evaluateDec', Format(Evaluate(Dec, DecLbl)));
        Observer.Observe('dec', Format(Dec));
        Observer.Observe('evaluateBad', Format(Evaluate(Int, Lbl)));
        Observer.Expect('strlen', '11');
        Observer.Expect('copystr', 'label');
        Observer.Expect('strpos', '7');
        Observer.Expect('upper', 'LABEL VALUE');
        Observer.Expect('lower', 'mixed');
        Observer.Expect('delchr', 'abe vaue');
        Observer.Expect('convertstr', 'LabeL vaLue');
        Observer.Expect('padstr', 'label value....');
        Observer.Expect('selectstr', 'a');
        Observer.Expect('incstr', '43');
        Observer.Expect('evaluateInt', 'Yes');
        Observer.Expect('int', '42');
        Observer.Expect('evaluateDec', 'Yes');
        Observer.Expect('dec', '3.5');
        Observer.Expect('evaluateBad', 'No');
        Observer.Verify();
    end;
}

codeunit 71023 "LT TxC Label Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ErrLbl: Label 'Label error %1';
        ErrLocked: Label 'Locked error', Locked = true;
        MsgLbl: Label 'Value is %1 for %2';

    [Test]
    procedure Label_In_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(ErrLbl, 'X');
        Observer.ObserveError('errorPlaceholder');
        asserterror Error(ErrLocked);
        Observer.ObserveError('errorLocked');
        asserterror Error(MsgLbl, 1, 'two');
        Observer.ObserveError('errorTwo');
        asserterror Error(ErrLbl);
        Observer.ObserveError('errorNoArg');
        asserterror Error(ErrorInfo.Create(ErrLocked));
        Observer.ObserveError('errorInfo');
        Observer.Expect('errorPlaceholder|text', 'Label error X');
        Observer.Expect('errorPlaceholder|code', 'Dialog');
        Observer.Expect('errorLocked|text', 'Locked error');
        Observer.Expect('errorLocked|code', 'Dialog');
        Observer.Expect('errorTwo|text', 'Value is 1 for two');
        Observer.Expect('errorTwo|code', 'Dialog');
        Observer.Expect('errorNoArg|text', 'Label error %1');
        Observer.Expect('errorNoArg|code', 'Dialog');
        Observer.Expect('errorInfo|text', 'Locked error');
        Observer.Expect('errorInfo|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Label_In_ErrorInfo_Fields()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
    begin
        Info.Message := ErrLocked;
        Info.Title := ErrLbl;
        Info.DetailedMessage := MsgLbl;
        Observer.Observe('message', Info.Message);
        Observer.Observe('title', Info.Title);
        Observer.Observe('detail', Info.DetailedMessage);
        Observer.Expect('message', 'Locked error');
        Observer.Expect('title', 'Label error %1');
        Observer.Expect('detail', 'Value is %1 for %2');
        Observer.Verify();
    end;

    [Test]
    procedure Label_TestField_Like()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('subst', StrSubstNo(ErrLbl, ErrLocked));
        Observer.Observe('nested', StrSubstNo(MsgLbl, StrSubstNo(ErrLbl, 1), 2));
        Observer.Observe('fmtBool', StrSubstNo(MsgLbl, true, false));
        Observer.Observe('fmtDec', StrSubstNo(MsgLbl, 1.50, 0));
        Observer.Expect('subst', 'Label error Locked error');
        Observer.Expect('nested', 'Value is Label error 1 for 2');
        Observer.Expect('fmtBool', 'Value is Yes for No');
        Observer.Expect('fmtDec', 'Value is 1.5 for 0');
        Observer.Verify();
    end;
}

codeunit 71024 "LT TxC Label Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ProcLabel(): Text
    var
        L: Label 'inside proc';
    begin
        exit(L);
    end;

    local procedure ProcLabelLocked(): Text
    var
        L: Label 'inside locked', Locked = true;
    begin
        exit(L.ToUpper());
    end;

    [Test]
    procedure Label_Local_Variable()
    var
        Observer: Codeunit "Probe Observer";
        L1: Label 'first';
        L2: Label 'second %1', Comment = '%1 = x';
    begin
        Observer.Observe('l1', L1);
        Observer.Observe('l2', StrSubstNo(L2, 7));
        Observer.Observe('proc', ProcLabel());
        Observer.Observe('procLocked', ProcLabelLocked());
        Observer.Observe('maxStrLen', Format(MaxStrLen(L1)));
        Observer.Observe('len', Format(StrLen(L1)));
        Observer.Observe('same', Format(L1 = L1));
        Observer.Expect('l1', 'first');
        Observer.Expect('l2', 'second 7');
        Observer.Expect('proc', 'inside proc');
        Observer.Expect('procLocked', 'INSIDE LOCKED');
        Observer.Expect('maxStrLen', '2048');
        Observer.Expect('len', '5');
        Observer.Expect('same', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Assign_To_Label_Not_Allowed_Observation()
    var
        Observer: Codeunit "Probe Observer";
        L1: Label 'abc';
        T: Text;
    begin
        T := L1;
        T := T.ToUpper();
        Observer.Observe('copy', T);
        Observer.Observe('orig', L1);
        Observer.Expect('copy', 'ABC');
        Observer.Expect('orig', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Format_Variants()
    var
        Observer: Codeunit "Probe Observer";
        L1: Label 'Mixed Case 123', Locked = true;
    begin
        Observer.Observe('f0', Format(L1));
        Observer.Observe('f1', Format(L1, 0, 0));
        Observer.Observe('f2', Format(L1, 6));
        Observer.Observe('f3', Format(L1, 20));
        Observer.Observe('f4', Format(L1, -5));
        Observer.Observe('f5', Format(L1, 0, '<Text>'));
        Observer.Observe('f6', Format(L1, 0, 9));
        Observer.Expect('f0', 'Mixed Case 123');
        Observer.Expect('f1', 'Mixed Case 123');
        Observer.Expect('f2', 'Mixed ');
        Observer.Expect('f3', 'Mixed Case 123      ');
        Observer.Expect('f4', 'Mixed');
        Observer.Expect('f5', 'Mixed Case 123');
        Observer.Expect('f6', 'Mixed Case 123');
        Observer.Verify();
    end;
}

codeunit 71025 "LT TxC Label Text Methods2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Sep: Label ';', Locked = true;
        Data: Label 'one;two;;four', Locked = true;
        Padded: Label '--x--', Locked = true;
        Long: Label 'The quick brown fox', Locked = true;

    [Test]
    procedure Label_Split_And_Trim()
    var
        Observer: Codeunit "Probe Observer";
        Parts: List of [Text];
        P: Text;
        N: Integer;
    begin
        Parts := Data.Split(Sep);
        Observer.Observe('count', Format(Parts.Count()));
        foreach P in Parts do begin
            N += 1;
            Observer.Observe('part' + Format(N), P);
        end;
        Observer.Observe('splitTwo', Format(Data.Split(';', ',').Count()));
        Observer.Observe('trimChars', Padded.TrimStart('-').TrimEnd('-'));
        Observer.Observe('trimStart', Padded.TrimStart('-'));
        Observer.Observe('trimEnd', Padded.TrimEnd('-'));
        Observer.Observe('trimNoMatch', Padded.Trim());
        Observer.Expect('count', '4');
        Observer.Expect('part1', 'one');
        Observer.Expect('part2', 'two');
        Observer.Expect('part3', '');
        Observer.Expect('part4', 'four');
        Observer.Expect('splitTwo', '4');
        Observer.Expect('trimChars', 'x');
        Observer.Expect('trimStart', 'x--');
        Observer.Expect('trimEnd', '--x');
        Observer.Expect('trimNoMatch', '--x--');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Search_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('containsLabel', Format(Long.Contains(Sep)));
        Observer.Observe('startsWithCase', Format(Long.StartsWith('the')));
        Observer.Observe('endsWithEmpty', Format(Long.EndsWith('')));
        Observer.Observe('indexOfMissing', Format(Long.IndexOf('zzz')));
        Observer.Observe('indexOfStartPast', Format(Long.IndexOf('quick', 10)));
        Observer.Observe('indexOfEmpty', Format(Long.IndexOf('')));
        Observer.Observe('lastIndexOfStart', Format(Long.LastIndexOf('o', 12)));
        Observer.Observe('lastIndexOfMissing', Format(Long.LastIndexOf('z')));
        Observer.Observe('replaceEmptyNew', Long.Replace(' ', ''));
        Observer.Observe('replaceCaseSens', Long.Replace('THE', 'A'));
        Observer.Observe('padLeftShort', Long.PadLeft(3));
        Observer.Observe('padRightSpace', Format(StrLen(Long.PadRight(25))));
        Observer.Expect('containsLabel', 'No');
        Observer.Expect('startsWithCase', 'No');
        Observer.Expect('endsWithEmpty', 'Yes');
        Observer.Expect('indexOfMissing', '0');
        Observer.Expect('indexOfStartPast', '0');
        Observer.Expect('indexOfEmpty', '1');
        Observer.Expect('lastIndexOfStart', '0');
        Observer.Expect('lastIndexOfMissing', '0');
        Observer.Expect('replaceEmptyNew', 'Thequickbrownfox');
        Observer.Expect('replaceCaseSens', 'The quick brown fox');
        Observer.Expect('padLeftShort', 'The quick brown fox');
        Observer.Expect('padRightSpace', '25');
        Observer.Verify();
    end;
}
