// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-error-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Error with every argument form; Message, Confirm, StrMenu with their handlers.
// BC versions: 29 (27 and 28 by CI)

codeunit 72512 "LT SyT Error Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HelloLbl: Label 'Hello %1 and %2';
        PlainLbl: Label 'A plain label';

    [Test]
    procedure Error_TextForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('plain');
        Observer.ObserveError('plain');
        asserterror Error('with %1', 'one');
        Observer.ObserveError('one placeholder');
        asserterror Error('%1 and %2', 1, 'two');
        Observer.ObserveError('two placeholders');
        asserterror Error('%2 then %1', 'a', 'b');
        Observer.ObserveError('reversed');
        asserterror Error('%1 %1', 'twice');
        Observer.ObserveError('same twice');
        asserterror Error('missing %1 %2', 'only one');
        Observer.ObserveError('missing arg');
        asserterror Error('extra', 'unused');
        Observer.ObserveError('extra arg');
        asserterror Error('percent 100%');
        Observer.ObserveError('literal percent');
        asserterror Error('%1', 1.5);
        Observer.ObserveError('decimal arg');
        asserterror Error('%1', true);
        Observer.ObserveError('bool arg');
        asserterror Error('%1', 0D);
        Observer.ObserveError('date arg');
        asserterror Error('%1', '');
        Observer.ObserveError('empty arg');
        asserterror Error('%1', CreateGuid() = CreateGuid());
        Observer.ObserveError('bool from compare');
        asserterror Error('%10', 'x');
        Observer.ObserveError('%10');
        asserterror Error('%0', 'x');
        Observer.ObserveError('%0');
        asserterror Error('%a', 'x');
        Observer.ObserveError('%a');
        Observer.Expect('plain|text', 'plain');
        Observer.Expect('plain|code', 'Dialog');
        Observer.Expect('one placeholder|text', 'with one');
        Observer.Expect('one placeholder|code', 'Dialog');
        Observer.Expect('two placeholders|text', '1 and two');
        Observer.Expect('two placeholders|code', 'Dialog');
        Observer.Expect('reversed|text', 'b then a');
        Observer.Expect('reversed|code', 'Dialog');
        Observer.Expect('same twice|text', 'twice twice');
        Observer.Expect('same twice|code', 'Dialog');
        Observer.Expect('missing arg|text', 'missing only one %2');
        Observer.Expect('missing arg|code', 'Dialog');
        Observer.Expect('extra arg|text', 'extra');
        Observer.Expect('extra arg|code', 'Dialog');
        Observer.Expect('literal percent|text', 'percent 100%');
        Observer.Expect('literal percent|code', 'Dialog');
        Observer.Expect('decimal arg|text', '1.5');
        Observer.Expect('decimal arg|code', 'Dialog');
        Observer.Expect('bool arg|text', 'Yes');
        Observer.Expect('bool arg|code', 'Dialog');
        Observer.Expect('date arg|text', '');
        Observer.Expect('date arg|code', 'Dialog');
        Observer.Expect('empty arg|text', '');
        Observer.Expect('empty arg|code', 'Dialog');
        Observer.Expect('bool from compare|text', 'No');
        Observer.Expect('bool from compare|code', 'Dialog');
        Observer.Expect('%10|text', '%10');
        Observer.Expect('%10|code', 'Dialog');
        Observer.Expect('%0|text', '%0');
        Observer.Expect('%0|code', 'Dialog');
        Observer.Expect('%a|text', '%a');
        Observer.Expect('%a|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_EmptyAndSpecial()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('');
        Observer.ObserveError('empty');
        asserterror Error(' ');
        Observer.ObserveError('space');
        asserterror Error('line1\line2');
        Observer.ObserveError('backslash');
        asserterror Error('tab' + Format(9) + 'x');
        Observer.ObserveError('digits');
        asserterror Error('äöü€ 日本語');
        Observer.ObserveError('unicode');
        asserterror Error('"quoted" ''single''');
        Observer.ObserveError('quotes');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', 'Dialog');
        Observer.Expect('space|text', ' ');
        Observer.Expect('space|code', 'Dialog');
        Observer.Expect('backslash|text', 'line1\line2');
        Observer.Expect('backslash|code', 'Dialog');
        Observer.Expect('digits|text', 'tab9x');
        Observer.Expect('digits|code', 'Dialog');
        Observer.Expect('unicode|text', 'äöü€ 日本語');
        Observer.Expect('unicode|code', 'Dialog');
        Observer.Expect('quotes|text', '"quoted" ''single''');
        Observer.Expect('quotes|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_LongText()
    var
        Observer: Codeunit "Probe Observer";
        Long: Text;
        i: Integer;
    begin
        for i := 1 to 100 do
            Long += '0123456789';
        asserterror Error(Long);
        Observer.Observe('1000 length', Format(StrLen(GetLastErrorText())));
        Observer.Observe('1000 equals', Format(GetLastErrorText() = Long));
        ClearLastError();
        Long := '';
        for i := 1 to 500 do
            Long += '0123456789';
        asserterror Error(Long);
        Observer.Observe('5000 length', Format(StrLen(GetLastErrorText())));
        Observer.Observe('5000 equals', Format(GetLastErrorText() = Long));
        ClearLastError();
        asserterror Error('%1', Long);
        Observer.Observe('5000 arg length', Format(StrLen(GetLastErrorText())));
        Observer.Expect('1000 length', '1000');
        Observer.Expect('1000 equals', 'Yes');
        Observer.Expect('5000 length', '5000');
        Observer.Expect('5000 equals', 'Yes');
        Observer.Expect('5000 arg length', '5000');
        Observer.Verify();
    end;

    [Test]
    procedure Error_Label()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(PlainLbl);
        Observer.ObserveError('plain label');
        asserterror Error(HelloLbl, 'x', 2);
        Observer.ObserveError('label two args');
        asserterror Error(HelloLbl, 'x');
        Observer.ObserveError('label one arg');
        asserterror Error(HelloLbl);
        Observer.ObserveError('label no args');
        Observer.Expect('plain label|text', 'A plain label');
        Observer.Expect('plain label|code', 'Dialog');
        Observer.Expect('label two args|text', 'Hello x and 2');
        Observer.Expect('label two args|code', 'Dialog');
        Observer.Expect('label one arg|text', 'Hello x and %2');
        Observer.Expect('label one arg|code', 'Dialog');
        Observer.Expect('label no args|text', 'Hello %1 and %2');
        Observer.Expect('label no args|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('from create');
        asserterror Error(Info);
        Observer.ObserveError('create');
        Clear(Info);
        Info.Message := 'message prop';
        asserterror Error(Info);
        Observer.ObserveError('message');
        Clear(Info);
        asserterror Error(Info);
        Observer.ObserveError('default errorinfo');
        Clear(Info);
        Info.Message := 'msg';
        Info.Title := 'the title';
        Info.DetailedMessage := 'details';
        Info.Verbosity := Verbosity::Error;
        Info.ErrorType := ErrorType::Client;
        asserterror Error(Info);
        Observer.ObserveError('all props');
        Observer.Expect('create|text', 'from create');
        Observer.Expect('create|code', 'Dialog');
        Observer.Expect('message|text', 'message prop');
        Observer.Expect('message|code', 'Dialog');
        Observer.Expect('default errorinfo|text', '');
        Observer.Expect('default errorinfo|code', 'Dialog');
        Observer.Expect('all props|text', 'msg');
        Observer.Expect('all props|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_Properties()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
    begin
        Observer.Observe('message default', Info.Message);
        Observer.Observe('title default', Info.Title);
        Observer.Observe('detailed default', Info.DetailedMessage);
        Observer.Observe('verbosity default', Format(Info.Verbosity));
        Observer.Observe('errortype default', Format(Info.ErrorType));
        Observer.Observe('collectible default', Format(Info.Collectible));
        Observer.Observe('systemid empty', Format(IsNullGuid(Info.SystemId)));
        Observer.Observe('recordid default', Format(Info.RecordId));
        Observer.Observe('fieldno default', Format(Info.FieldNo));
        Observer.Observe('customdims count', Format(Info.CustomDimensions.Count()));
        Info.CustomDimensions.Add('k', 'v');
        Observer.Observe('customdims after add', Format(Info.CustomDimensions.Count()));
        Info := ErrorInfo.Create('created');
        Observer.Observe('message created', Info.Message);
        Observer.Observe('collectible created', Format(Info.Collectible));
        Observer.Expect('message default', '');
        Observer.Expect('title default', '');
        Observer.Expect('detailed default', '');
        Observer.Expect('verbosity default', 'Error');
        Observer.Expect('errortype default', 'Client');
        Observer.Expect('collectible default', 'No');
        Observer.Expect('systemid empty', 'Yes');
        Observer.Expect('recordid default', '');
        Observer.Expect('fieldno default', '0');
        Observer.Expect('customdims count', '0');
        Observer.Expect('customdims after add', '1');
        Observer.Expect('message created', 'created');
        Observer.Expect('collectible created', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Error_CodeAndTry()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('x');
        Observer.Observe('code text error', GetLastErrorCode());
        ClearLastError();
        asserterror Error(PlainLbl);
        Observer.Observe('code label error', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('try', Format(TryRaise('a %1', 'b')));
        Observer.Observe('try text', GetLastErrorText());
        Observer.Observe('try code', GetLastErrorCode());
        Observer.Expect('code text error', 'Dialog');
        Observer.Expect('code label error', 'Dialog');
        Observer.Expect('try', 'No');
        Observer.Expect('try text', 'a b');
        Observer.Expect('try code', 'Dialog');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRaise(Msg: Text; Arg: Text)
    begin
        Error(Msg, Arg);
    end;
}

codeunit 72513 "LT SyT Message"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        SomeLbl: Label 'Label %1';

    [MessageHandler]
    procedure Seen(Msg: Text[1024])
    begin
        Observer.Observe('message', Msg);
    end;

    [Test]
    [HandlerFunctions('Seen')]
    procedure Message_Text_Forms()
    begin
        Message('plain');
        Message('one %1', 'x');
        Message('two %1 %2', 1, 2.5);
        Message('bool %1 date %2', true, 0D);
        Message('');
        Message(' ');
        Message(SomeLbl, 'lbl');
        Message('missing %1 %2', 'a');
        Message('extra', 'a');
        Message('äö€');
        Message('100%');
        Observer.Expect('message', 'plain');
        Observer.Expect('message', 'one x');
        Observer.Expect('message', 'two 1 2.5');
        Observer.Expect('message', 'bool Yes date ');
        Observer.Expect('message', '');
        Observer.Expect('message', ' ');
        Observer.Expect('message', 'Label lbl');
        Observer.Expect('message', 'missing a %2');
        Observer.Expect('message', 'extra');
        Observer.Expect('message', 'äö€');
        Observer.Expect('message', '100%');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Seen')]
    procedure Message_Long()
    var
        Long: Text;
        i: Integer;
    begin
        for i := 1 to 120 do
            Long += '0123456789';
        asserterror Message(Long);
        Observer.ObserveError('af235');
        Observer.Expect('af235|text', 'The length of the string is 1200, but it must be less than or equal to 1024 characters. Value: 01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789...');
        Observer.Expect('af235|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure SeenLen(Msg: Text[1024])
    begin
        Observer.Observe('len', Format(StrLen(Msg)));
    end;

    [Test]
    [HandlerFunctions('SeenLen')]
    procedure Message_Length()
    var
        Long: Text;
        i: Integer;
    begin
        for i := 1 to 120 do
            Long += '0123456789';
        asserterror Message(Long);
        Observer.ObserveError('af255');
        Message(CopyStr(Long, 1, 1024));
        asserterror Message(CopyStr(Long, 1, 1025));
        Observer.ObserveError('af258');
        asserterror Message('%1', Long);
        Observer.ObserveError('af260');
        Observer.Expect('af255|text', 'The length of the string is 1200, but it must be less than or equal to 1024 characters. Value: 01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789...');
        Observer.Expect('af255|code', 'StringLengthExceeded');
        Observer.Expect('len', '1024');
        Observer.Expect('af258|text', 'The length of the string is 1025, but it must be less than or equal to 1024 characters. Value: 01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789...');
        Observer.Expect('af258|code', 'StringLengthExceeded');
        Observer.Expect('af260|text', 'The length of the string is 1200, but it must be less than or equal to 1024 characters. Value: 01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789...');
        Observer.Expect('af260|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Seen')]
    procedure Message_ErrorAfterMessage()
    begin
        Message('before error');
        asserterror Error('err');
        Observer.ObserveError('after');
        Message('after error');
        Observer.Expect('message', 'before error');
        Observer.Expect('after|text', 'err');
        Observer.Expect('after|code', 'Dialog');
        Observer.Expect('message', 'after error');
        Observer.Verify();
    end;

    [ConfirmHandler]
    procedure AnswerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Observer.Observe('question', Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure AnswerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Observer.Observe('question', Question);
        Reply := false;
    end;

    [ConfirmHandler]
    procedure KeepDefault(Question: Text[1024]; var Reply: Boolean)
    begin
        Observer.Observe('question', Question);
        Observer.Observe('reply initial', Format(Reply));
    end;

    [Test]
    [HandlerFunctions('AnswerYes')]
    procedure Confirm_Yes()
    begin
        Observer.Observe('plain', Format(Confirm('Sure?')));
        Observer.Observe('default true', Format(Confirm('Sure?', true)));
        Observer.Observe('default false', Format(Confirm('Sure?', false)));
        Observer.Observe('placeholder', Format(Confirm('Hi %1 %2', true, 'a', 2)));
        Observer.Observe('placeholder default', Format(Confirm('Hi %1', false, 'b')));
        Observer.Observe('empty', Format(Confirm('')));
        Observer.Observe('label', Format(Confirm(SomeLbl, true, 'c')));
        Observer.Expect('question', 'Sure?');
        Observer.Expect('plain', 'Yes');
        Observer.Expect('question', 'Sure?');
        Observer.Expect('default true', 'Yes');
        Observer.Expect('question', 'Sure?');
        Observer.Expect('default false', 'Yes');
        Observer.Expect('question', 'Hi %1 %2');
        Observer.Expect('placeholder', 'Yes');
        Observer.Expect('question', 'Hi %1');
        Observer.Expect('placeholder default', 'Yes');
        Observer.Expect('question', '');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('question', 'Label %1');
        Observer.Expect('label', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_No()
    begin
        Observer.Observe('plain', Format(Confirm('Sure?')));
        Observer.Observe('default true', Format(Confirm('Sure?', true)));
        Observer.Observe('default false', Format(Confirm('Sure?', false)));
        Observer.Expect('question', 'Sure?');
        Observer.Expect('plain', 'No');
        Observer.Expect('question', 'Sure?');
        Observer.Expect('default true', 'No');
        Observer.Expect('question', 'Sure?');
        Observer.Expect('default false', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('KeepDefault')]
    procedure Confirm_ReplyUntouched()
    begin
        Observer.Observe('default true result', Format(Confirm('Q1', true)));
        Observer.Observe('default false result', Format(Confirm('Q2', false)));
        Observer.Observe('no default result', Format(Confirm('Q3')));
        Observer.Expect('question', 'Q1');
        Observer.Expect('reply initial', 'Yes');
        Observer.Expect('default true result', 'Yes');
        Observer.Expect('question', 'Q2');
        Observer.Expect('reply initial', 'No');
        Observer.Expect('default false result', 'No');
        Observer.Expect('question', 'Q3');
        Observer.Expect('reply initial', 'No');
        Observer.Expect('no default result', 'No');
        Observer.Verify();
    end;

    [StrMenuHandler]
    procedure PickTwo(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Observer.Observe('options', Options);
        Observer.Observe('choice initial', Format(Choice));
        Observer.Observe('instruction', Instruction);
        Choice := 2;
    end;

    [StrMenuHandler]
    procedure PickNone(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 0;
    end;

    [StrMenuHandler]
    procedure PickHuge(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 99;
    end;

    [StrMenuHandler]
    procedure PickNegative(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := -1;
    end;

    [Test]
    [HandlerFunctions('PickTwo')]
    procedure StrMenu_Parameters()
    begin
        Observer.Observe('options only', Format(StrMenu('A,B,C')));
        Observer.Observe('with default 3', Format(StrMenu('A,B,C', 3)));
        Observer.Observe('with default 0', Format(StrMenu('A,B,C', 0)));
        Observer.Observe('with instruction', Format(StrMenu('A,B,C', 1, 'Pick one')));
        Observer.Observe('empty options', Format(StrMenu('')));
        Observer.Observe('one option', Format(StrMenu('Only')));
        Observer.Observe('empty items', Format(StrMenu(',,')));
        Observer.Observe('default beyond', Format(StrMenu('A,B', 5)));
        Observer.Observe('default negative', Format(StrMenu('A,B', -1)));
        Observer.Observe('ampersand', Format(StrMenu('&A,B&C')));
        Observer.Expect('options', 'A,B,C');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', '');
        Observer.Expect('options only', '2');
        Observer.Expect('options', 'A,B,C');
        Observer.Expect('choice initial', '3');
        Observer.Expect('instruction', '');
        Observer.Expect('with default 3', '2');
        Observer.Expect('options', 'A,B,C');
        Observer.Expect('choice initial', '0');
        Observer.Expect('instruction', '');
        Observer.Expect('with default 0', '2');
        Observer.Expect('options', 'A,B,C');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', 'Pick one');
        Observer.Expect('with instruction', '2');
        Observer.Expect('options', '');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', '');
        Observer.Expect('empty options', '2');
        Observer.Expect('options', 'Only');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', '');
        Observer.Expect('one option', '2');
        Observer.Expect('options', ',,');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', '');
        Observer.Expect('empty items', '2');
        Observer.Expect('options', 'A,B');
        Observer.Expect('choice initial', '5');
        Observer.Expect('instruction', '');
        Observer.Expect('default beyond', '2');
        Observer.Expect('options', 'A,B');
        Observer.Expect('choice initial', '-1');
        Observer.Expect('instruction', '');
        Observer.Expect('default negative', '2');
        Observer.Expect('options', '&A,B&C');
        Observer.Expect('choice initial', '1');
        Observer.Expect('instruction', '');
        Observer.Expect('ampersand', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickNone')]
    procedure StrMenu_Cancel()
    begin
        Observer.Observe('cancel', Format(StrMenu('A,B,C')));
        Observer.Observe('cancel default 2', Format(StrMenu('A,B,C', 2)));
        Observer.Expect('cancel', '0');
        Observer.Expect('cancel default 2', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickHuge')]
    procedure StrMenu_ChoiceBeyondOptions()
    begin
        Observer.Observe('99 of 3', Format(StrMenu('A,B,C')));
        Observer.Expect('99 of 3', '99');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickNegative')]
    procedure StrMenu_NegativeChoice()
    begin
        Observer.Observe('-1 of 3', Format(StrMenu('A,B,C')));
        Observer.Expect('-1 of 3', '-1');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 46: a backslash in a Message text with placeholders, and
    // TextBuilder.AppendLine text passed to Message and Error. The Probe Observer writes CR and LF as \r and \n.
    [MessageHandler]
    procedure LT_BU_SeenRaw(Msg: Text[1024])
    begin
        Observer.Observe('message', Msg);
    end;

    [Test]
    [HandlerFunctions('LT_BU_SeenRaw')]
    procedure LT_BU_Message_BackslashAndAppendLine()
    var
        TB: TextBuilder;
        n: Integer;
        t: Text;
    begin
        n := 5;
        t := 'x';
        Message('A: \' + 'B:%1\' + 'C:%2', n, t);
        Message('one\two');
        Message('%1', 'arg\with\backslash');
        TB.AppendLine('line1');
        TB.AppendLine('line2');
        TB.Append('line3');
        Message(TB.ToText());
        Message('%1', TB.ToText());
        asserterror Error(TB.ToText());
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error text length', Format(StrLen(GetLastErrorText())));
        asserterror Error('A: \' + 'B:%1\' + 'C:%2', n, t);
        Observer.Observe('error backslash args', GetLastErrorText());
        Observer.Observe('appendline length', Format(StrLen(TB.ToText())));
        Observer.Expect('message', 'A: \B:5\C:x');
        Observer.Expect('message', 'one\two');
        Observer.Expect('message', 'arg\with\backslash');
        Observer.Expect('message', 'line1\line2\line3');
        Observer.Expect('message', 'line1\line2\line3');
        Observer.Expect('error text', 'line1\line2\line3');
        Observer.Expect('error text length', '17');
        Observer.Expect('error backslash args', 'A: \B:5\C:x');
        Observer.Expect('appendline length', '19');
        Observer.Verify();
    end;
    // Writer PY-C (al-runtime-rs PR 341, probes-needed "CR LF in Error with arguments"): Error('%1', Text with CR LF), a lone CR and a lone LF in
    // Message and Error, from the text and from an argument. Each value is shown as its text and as the codes of its characters below 32 and of
    // the backslash (<13>, <10>, <92>).
    local procedure PYC_Codes(Value: Text): Text
    var
        i: Integer;
        N: Integer;
        R: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            N := Value[i];
            if (N < 32) or (N = 92) then
                R += '<' + Format(N) + '>'
            else
                R += Format(Value[i]);
        end;
        exit(R);
    end;

    local procedure PYC_Texts(var CrLf: Text; var Cr: Text; var Lf: Text)
    var
        C13: Char;
        C10: Char;
    begin
        C13 := 13;
        C10 := 10;
        CrLf := 'a' + Format(C13) + Format(C10) + 'b';
        Cr := 'a' + Format(C13) + 'b';
        Lf := 'a' + Format(C10) + 'b';
    end;

    [MessageHandler]
    procedure PYC_SeenCodes(Msg: Text[1024])
    begin
        Observer.Observe('message', PYC_Codes(Msg));
    end;

    [Test]
    [HandlerFunctions('PYC_SeenCodes')]
    procedure PYC_Message_LoneCrAndLf()
    var
        CrLf: Text;
        Cr: Text;
        Lf: Text;
    begin
        PYC_Texts(CrLf, Cr, Lf);
        Message(Cr);
        Message(Lf);
        Message('%1', Cr);
        Message('%1', Lf);
        Message('%1', CrLf);
        Message('x%1y', Lf);
        Observer.Expect('message', 'a<13>b');
        Observer.Expect('message', 'a<10>b');
        Observer.Expect('message', 'a<13>b');
        Observer.Expect('message', 'a<10>b');
        Observer.Expect('message', 'a<92>b');
        Observer.Expect('message', 'xa<10>by');
        Observer.Verify();
    end;

    [Test]
    procedure PYC_Error_CrLfAndLoneCrLf()
    var
        CrLf: Text;
        Cr: Text;
        Lf: Text;
    begin
        PYC_Texts(CrLf, Cr, Lf);
        asserterror Error('%1', CrLf);
        Observer.Observe('error arg crlf', PYC_Codes(GetLastErrorText()));
        asserterror Error('x%1y', CrLf);
        Observer.Observe('error arg crlf in text', PYC_Codes(GetLastErrorText()));
        asserterror Error(Cr);
        Observer.Observe('error text cr', PYC_Codes(GetLastErrorText()));
        asserterror Error(Lf);
        Observer.Observe('error text lf', PYC_Codes(GetLastErrorText()));
        asserterror Error('%1', Cr);
        Observer.Observe('error arg cr', PYC_Codes(GetLastErrorText()));
        asserterror Error('%1', Lf);
        Observer.Observe('error arg lf', PYC_Codes(GetLastErrorText()));
        asserterror Error(CrLf);
        Observer.Observe('error text crlf', PYC_Codes(GetLastErrorText()));
        asserterror Error('p\q %1', CrLf);
        Observer.Observe('error backslash text and crlf arg', PYC_Codes(GetLastErrorText()));
        Observer.Expect('error arg crlf', 'a<92>b');
        Observer.Expect('error arg crlf in text', 'xa<92>by');
        Observer.Expect('error text cr', 'a<13>b');
        Observer.Expect('error text lf', 'a<10>b');
        Observer.Expect('error arg cr', 'a<13>b');
        Observer.Expect('error arg lf', 'a<10>b');
        Observer.Expect('error text crlf', 'a<92>b');
        Observer.Expect('error backslash text and crlf arg', 'p<92>q a<92>b');
        Observer.Verify();
    end;
}
