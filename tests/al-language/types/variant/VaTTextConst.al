// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-textconst-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71037 "LT VaT TextConst"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Simple: TextConst ENU = 'Hello';
        WithPct: TextConst ENU = 'Value %1 and %2';
        MultiLang: TextConst DEU = 'Hallo', ENU = 'Hello World', FRA = 'Bonjour';
        Empty: TextConst ENU = '';
        Long: TextConst ENU = 'The quick brown fox jumps over the lazy dog';
        WithQuote: TextConst ENU = 'It''s %1';
        Pct3: TextConst ENU = '%1-%2-%3-%4';
        Rep: TextConst ENU = '%1%1%1';
        Pct10: TextConst ENU = '%10 and %1';
        Pct0: TextConst ENU = '%0 and %1';
        Pct5: TextConst ENU = '%5';
        PctEnd: TextConst ENU = 'end%';
        Unicode: TextConst ENU = 'ÄÖÜ äöü ß €';

    [Test]
    procedure TextConst_To_Text_Basics()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        T5: Text[5];
        C: Code[20];
    begin
        T := Simple; Observer.Observe('simple', T);
        Observer.Observe('simple_len', Format(StrLen(Simple)));
        Observer.Observe('empty', Empty);
        Observer.Observe('empty_len', Format(StrLen(Empty)));
        Observer.Observe('multi', MultiLang);
        Observer.Observe('multi_len', Format(StrLen(MultiLang)));
        T5 := Simple; Observer.Observe('to_text5', T5);
        asserterror T5 := Long;
        Observer.ObserveError('long_to_text5');
        C := Simple; Observer.Observe('to_code', C);
        Observer.Observe('unicode', Unicode);
        Observer.Observe('unicode_len', Format(StrLen(Unicode)));
        Observer.Observe('quote', StrSubstNo(WithQuote, 'x'));
        Observer.Observe('uppercase', UpperCase(Simple));
        Observer.Observe('concat', Simple + ' ' + Empty + '!');
        Observer.Expect('simple', 'Hello');
        Observer.Expect('simple_len', '5');
        Observer.Expect('empty', '');
        Observer.Expect('empty_len', '0');
        Observer.Expect('multi', 'Hello World');
        Observer.Expect('multi_len', '11');
        Observer.Expect('to_text5', 'Hello');
        Observer.Expect('long_to_text5|text', 'The length of the string is 43, but it must be less than or equal to 5 characters. Value: The quick brown fox jumps over the lazy dog');
        Observer.Expect('long_to_text5|code', 'StringLengthExceeded');
        Observer.Expect('to_code', 'HELLO');
        Observer.Expect('unicode', 'ÄÖÜ äöü ß €');
        Observer.Expect('unicode_len', '11');
        Observer.Expect('quote', 'It''s x');
        Observer.Expect('uppercase', 'HELLO');
        Observer.Expect('concat', 'Hello !');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_MaxStrLen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('simple_maxstrlen', Format(MaxStrLen(Simple)));
        Observer.Observe('long_maxstrlen', Format(MaxStrLen(Long)));
        Observer.Observe('empty_maxstrlen', Format(MaxStrLen(Empty)));
        Observer.Observe('multi_maxstrlen', Format(MaxStrLen(MultiLang)));
        Observer.Expect('simple_maxstrlen', '2048');
        Observer.Expect('long_maxstrlen', '2048');
        Observer.Expect('empty_maxstrlen', '2048');
        Observer.Expect('multi_maxstrlen', '2048');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_StrSubstNo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two', StrSubstNo(WithPct, 'a', 'b'));
        Observer.Observe('two_int_dec', StrSubstNo(WithPct, 5, 1.5));
        Observer.Observe('two_date_bool', StrSubstNo(WithPct, DMY2Date(1, 2, 2020), true));
        Observer.Observe('one_arg_only', StrSubstNo(WithPct, 'a'));
        Observer.Observe('no_args', StrSubstNo(WithPct));
        Observer.Observe('too_many_args', StrSubstNo(WithPct, 'a', 'b', 'c'));
        Observer.Observe('four', StrSubstNo(Pct3, 'a', 'b', 'c', 'd'));
        Observer.Observe('repeat', StrSubstNo(Rep, 'ab'));
        Observer.Observe('pct10', StrSubstNo(Pct10, 'a'));
        Observer.Observe('pct0', StrSubstNo(Pct0, 'a'));
        Observer.Observe('pct5_not_given', StrSubstNo(Pct5, 'a'));
        Observer.Observe('pct_end', StrSubstNo(PctEnd, 'a'));
        Observer.Observe('no_placeholder', StrSubstNo(Simple, 'a'));
        Observer.Observe('empty_arg', StrSubstNo(WithPct, '', ''));
        Observer.Observe('arg_has_percent', StrSubstNo(WithPct, '%2', 'x'));
        Observer.Observe('variant_args', StrSubstNo(WithPct, VariantArg(5), VariantArg('s')));
        Observer.Expect('two', 'Value a and b');
        Observer.Expect('two_int_dec', 'Value 5 and 1.5');
        Observer.Expect('two_date_bool', 'Value 02/01/20 and Yes');
        Observer.Expect('one_arg_only', 'Value a and %2');
        Observer.Expect('no_args', 'Value %1 and %2');
        Observer.Expect('too_many_args', 'Value a and b');
        Observer.Expect('four', 'a-b-c-d');
        Observer.Expect('repeat', 'ababab');
        Observer.Expect('pct10', '%10 and a');
        Observer.Expect('pct0', '%0 and a');
        Observer.Expect('pct5_not_given', '%5');
        Observer.Expect('pct_end', 'end%');
        Observer.Expect('no_placeholder', 'Hello');
        Observer.Expect('empty_arg', 'Value  and ');
        Observer.Expect('arg_has_percent', 'Value %2 and x');
        Observer.Expect('variant_args', 'Value 5 and s');
        Observer.Verify();
    end;

    local procedure VariantArg(V: Variant): Variant
    begin
        exit(V);
    end;

    [Test]
    procedure TextConst_In_Variant()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        V: Variant;
        T: Text;
    begin
        V := Simple;
        Observer.Observe('flags', Helper.Flags(V));
        Observer.Observe('format', Format(V));
        T := V; Observer.Observe('to_text', T);
        Observer.Observe('eq_text', Format(Format(V) = 'Hello'));
        Observer.Observe('format_const', Format(Simple));
        Observer.Observe('format_const_9', Format(Simple, 0, 9));
        Observer.Expect('flags', '');
        Observer.Expect('format', 'Hello');
        Observer.Expect('to_text', 'Hello');
        Observer.Expect('eq_text', 'Yes');
        Observer.Expect('format_const', 'Hello');
        Observer.Expect('format_const_9', 'Hello');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Compare_And_Functions()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'Hello';
        Observer.Observe('eq', Format(Simple = T));
        Observer.Observe('eq_ci', Format(Simple = 'HELLO'));
        Observer.Observe('ne', Format(Simple <> Long));
        Observer.Observe('copystr', CopyStr(Long, 5, 5));
        Observer.Observe('strpos', Format(StrPos(Long, 'fox')));
        Observer.Observe('selectstr', SelectStr(1, 'a,b'));
        Observer.Observe('contains', Format(Long.Contains('fox')));
        Observer.Observe('replace', Long.Replace('quick', 'slow'));
        Observer.Observe('split_count', Format(Long.Split(' ').Count()));
        Observer.Observe('startswith', Format(Simple.StartsWith('He')));
        Observer.Expect('eq', 'Yes');
        Observer.Expect('eq_ci', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('copystr', 'quick');
        Observer.Expect('strpos', '17');
        Observer.Expect('selectstr', 'a');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('replace', 'The slow brown fox jumps over the lazy dog');
        Observer.Expect('split_count', '9');
        Observer.Expect('startswith', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Message_Error_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(WithPct, 'a', 'b');
        Observer.ObserveError('error_with_args');
        asserterror Error(Simple);
        Observer.ObserveError('error_simple');
        asserterror Error(Pct5, 'q');
        Observer.ObserveError('error_pct5');
        Observer.Expect('error_with_args|text', 'Value a and b');
        Observer.Expect('error_with_args|code', 'Dialog');
        Observer.Expect('error_simple|text', 'Hello');
        Observer.Expect('error_simple|code', 'Dialog');
        Observer.Expect('error_pct5|text', '%5');
        Observer.Expect('error_pct5|code', 'Dialog');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Values and builtins": a TextConst in a Variant answers none of the Is... tests LT VaT Helper.Flags asks
    // (TextConst_In_Variant). The other Is... tests one by one, the Variant compared with a Text, passed to a Text parameter, assigned to a Code
    // variable (comparing a Variant with a Text does not compile: AL0175), after a Variant parameter and a Variant return value; a Label in a Variant for comparison.
    local procedure PwIsFlags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsTextConstant() then R += 'TextConstant,';
        if V.IsTextBuilder() then R += 'TextBuilder,';
        if V.IsWideChar() then R += 'WideChar,';
        if V.IsAction() then R += 'Action,';
        if V.IsTextEncoding() then R += 'TextEncoding,';
        if V.IsReportFormat() then R += 'ReportFormat,';
        if V.IsObjectType() then R += 'ObjectType,';
        if V.IsExecutionMode() then R += 'ExecutionMode,';
        if V.IsClientType() then R += 'ClientType,';
        if V.IsDataClassification() then R += 'DataClassification,';
        if V.IsDataClassificationType() then R += 'DataClassificationType,';
        if V.IsSecurityFiltering() then R += 'SecurityFiltering,';
        if V.IsTestPermissions() then R += 'TestPermissions,';
        if V.IsTransactionType() then R += 'TransactionType,';
        if V.IsTableConnectionType() then R += 'TableConnectionType,';
        if V.IsDefaultLayout() then R += 'DefaultLayout,';
        if V.IsFilterPageBuilder() then R += 'FilterPageBuilder,';
        if V.IsJsonObject() then R += 'JsonObject,';
        if V.IsJsonValue() then R += 'JsonValue,';
        if V.IsFile() then R += 'File,';
        if V.IsBinary() then R += 'Binary,';
        if V.IsPromptMode() then R += 'PromptMode,';
        exit(R);
    end;

    local procedure PwTextParam(T: Text): Text
    begin
        exit('[' + T + ']');
    end;

    [TryFunction]
    local procedure PwTryTextParam(V: Variant; var Result: Text)
    begin
        Result := PwTextParam(V);
    end;

    [TryFunction]
    local procedure PwTryCode(V: Variant; var Result: Code[20])
    begin
        Result := V;
    end;

    local procedure PwShape(V: Variant): Text
    var
        Helper: Codeunit "LT VaT Helper";
        R: Text;
        P: Text;
        C: Code[20];
    begin
        R := 'flags=' + Helper.Flags(V) + ' more=' + PwIsFlags(V);
        R += ' eqFormat=' + Format(Format(V) = 'Hello');
        if PwTryTextParam(V, P) then
            R += ' textParam=' + P
        else
            R += ' textParam=error:' + GetLastErrorCode();
        ClearLastError();
        if PwTryCode(V, C) then
            R += ' code=' + C
        else
            R += ' code=error:' + GetLastErrorCode();
        ClearLastError();
        exit(R);
    end;

    [Test]
    procedure PW_TextConst_In_Variant_OtherIsTests()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Lbl: Label 'Hello';
    begin
        V := Simple;
        Observer.Observe('assigned', PwShape(V));
        Observer.Observe('throughParameterAndReturn', PwShape(VariantArg(Simple)));
        V := Lbl;
        Observer.Observe('label', PwShape(V));
        V := 'Hello';
        Observer.Observe('textLiteral', PwShape(V));
        Observer.Expect('assigned', 'flags= more=TextConstant, eqFormat=Yes textParam=[Hello] code=HELLO');
        Observer.Expect('throughParameterAndReturn', 'flags= more=TextConstant, eqFormat=Yes textParam=[Hello] code=HELLO');
        Observer.Expect('label', 'flags= more=TextConstant, eqFormat=Yes textParam=[Hello] code=HELLO');
        Observer.Expect('textLiteral', 'flags=Text, more= eqFormat=Yes textParam=[Hello] code=HELLO');
        Observer.Verify();
    end;
}
