// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71500 "LT RcA GetFind"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Get_Integer_Key()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('get20', Format(R.Get(20)));
        Observer.Observe('name', R.Name);
        Observer.Observe('get15', Format(R.Get(15)));
        Observer.Observe('afterMiss.no', Format(R.No));
        Observer.Observe('afterMiss.name', R.Name);
        Observer.Observe('get0', Format(R.Get(0)));
        Observer.Observe('getNeg', Format(R.Get(-5)));
        Observer.Observe('get100', Format(R.Get(100)));
        asserterror R.Get(15);
        Observer.ObserveError('getMissErr');
        asserterror R.Get(0);
        Observer.ObserveError('getZeroErr');
        R.No := 30;
        Observer.Observe('getByFieldValue', Format(R.Find()));
        Observer.Observe('getAfterFind', R.Name);
        Observer.Expect('get20', 'Yes');
        Observer.Expect('name', 'N9');
        Observer.Expect('get15', 'No');
        Observer.Expect('afterMiss.no', '20');
        Observer.Expect('afterMiss.name', 'N9');
        Observer.Expect('get0', 'No');
        Observer.Expect('getNeg', 'No');
        Observer.Expect('get100', 'Yes');
        Observer.Expect('getMissErr|text', 'The LT RcA Main does not exist. Identification fields and values: No=''15''');
        Observer.Expect('getMissErr|code', 'DB:RecordNotFound');
        Observer.Expect('getZeroErr|text', 'The LT RcA Main does not exist. Identification fields and values: No=''0''');
        Observer.Expect('getZeroErr|code', 'DB:RecordNotFound');
        Observer.Expect('getByFieldValue', 'No');
        Observer.Expect('getAfterFind', 'N1');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Code_Key_CaseAndBlank()
    var
        R: Record "LT RcA CodeKey";
    begin
        Seed.Keys();
        Observer.Observe('abc', Format(R.Get('abc')));
        Observer.Observe('abcInfo', R.Info);
        Observer.Observe('ABC', Format(R.Get('ABC')));
        Observer.Observe('ABCInfo', R.Info);
        Observer.Observe('keyAfter', R.Cd);
        Observer.Observe('Abd', Format(R.Get('abd')));
        Observer.Observe('blank', Format(R.Get('')));
        Observer.Observe('trailing', Format(R.Get('abc ')));
        Observer.Observe('leading', Format(R.Get(' abc')));
        Observer.Observe('wildcard', Format(R.Get('a*')));
        asserterror Observer.Observe('tooLong', Format(R.Get('abcdefghijklmnop')));
        Observer.ObserveError('af56');
        asserterror R.Get('zzz');
        Observer.ObserveError('missErr');
        Observer.Expect('abc', 'Yes');
        Observer.Expect('abcInfo', 'lower');
        Observer.Expect('ABC', 'Yes');
        Observer.Expect('ABCInfo', 'lower');
        Observer.Expect('keyAfter', 'ABC');
        Observer.Expect('Abd', 'Yes');
        Observer.Expect('blank', 'No');
        Observer.Expect('trailing', 'Yes');
        Observer.Expect('leading', 'Yes');
        Observer.Expect('wildcard', 'No');
        Observer.Expect('af56|text', 'The length of the string is 16, but it must be less than or equal to 10 characters. Value: abcdefghijklmnop');
        Observer.Expect('af56|code', 'StringLengthExceeded');
        Observer.Expect('missErr|text', 'The LT RcA CodeKey does not exist. Identification fields and values: Cd=''ZZZ''');
        Observer.Expect('missErr|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Text_Key()
    var
        R: Record "LT RcA TextKey";
    begin
        Seed.Keys();
        Observer.Observe('abc', Format(R.Get('abc')));
        Observer.Observe('abcInfo', R.Info);
        Observer.Observe('ABC', Format(R.Get('ABC')));
        Observer.Observe('ABCInfo', R.Info);
        Observer.Observe('abcSpace', Format(R.Get('abc ')));
        Observer.Observe('abcSpaceInfo', R.Info);
        Observer.Observe('abcSpace2', Format(R.Get('abc  ')));
        Observer.Observe('blank', Format(R.Get('')));
        Observer.Observe('missing', Format(R.Get('nope')));
        Observer.Expect('abc', 'Yes');
        Observer.Expect('abcInfo', 'lower');
        Observer.Expect('ABC', 'No');
        Observer.Expect('ABCInfo', 'lower');
        Observer.Expect('abcSpace', 'Yes');
        Observer.Expect('abcSpaceInfo', 'lower');
        Observer.Expect('abcSpace2', 'Yes');
        Observer.Expect('blank', 'No');
        Observer.Expect('missing', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Decimal_Date_Bool_Option_Enum_Keys()
    var
        DK: Record "LT RcA DecKey";
        DtK: Record "LT RcA DateKey";
        BK: Record "LT RcA BoolKey";
        OK: Record "LT RcA OptKey";
        EK: Record "LT RcA EnumKey";
    begin
        Seed.Keys();
        Observer.Observe('dec1.5', Format(DK.Get(1.5)));
        Observer.Observe('dec1.50', Format(DK.Get(1.50)));
        Observer.Observe('dec-2', Format(DK.Get(-2)));
        Observer.Observe('dec0', Format(DK.Get(0)));
        Observer.Observe('dec1.51', Format(DK.Get(1.51)));
        Observer.Observe('dateBlank', Format(DtK.Get(0D)));
        Observer.Observe('dateFeb', Format(DtK.Get(DMY2Date(1, 2, 2021))));
        Observer.Observe('dateMiss', Format(DtK.Get(DMY2Date(2, 2, 2021))));
        Observer.Observe('boolF', Format(BK.Get(false)));
        Observer.Observe('boolFInfo', BK.Info);
        Observer.Observe('boolT', Format(BK.Get(true)));
        Observer.Observe('boolTInfo', BK.Info);
        Observer.Observe('opt0', Format(OK.Get(OK.Op::Alpha)));
        Observer.Observe('opt2', Format(OK.Get(OK.Op::Gamma)));
        Observer.Observe('opt2Info', OK.Info);
        Observer.Observe('optInt1', Format(OK.Get(1)));
        Observer.Observe('optInt1Info', OK.Info);
        Observer.Observe('enumFive', Format(EK.Get(EK.En::Five)));
        Observer.Observe('enumFiveInfo', EK.Info);
        Observer.Observe('enumOne', Format(EK.Get(EK.En::One)));
        Observer.Observe('enumZero', Format(EK.Get(EK.En::Zero)));
        Observer.Observe('enumFromInt9', Format(EK.Get(Enum::"LT RcA Enum".FromInteger(9))));
        Observer.Expect('dec1.5', 'Yes');
        Observer.Expect('dec1.50', 'Yes');
        Observer.Expect('dec-2', 'Yes');
        Observer.Expect('dec0', 'Yes');
        Observer.Expect('dec1.51', 'No');
        Observer.Expect('dateBlank', 'Yes');
        Observer.Expect('dateFeb', 'Yes');
        Observer.Expect('dateMiss', 'No');
        Observer.Expect('boolF', 'Yes');
        Observer.Expect('boolFInfo', 'f');
        Observer.Expect('boolT', 'Yes');
        Observer.Expect('boolTInfo', 't');
        Observer.Expect('opt0', 'Yes');
        Observer.Expect('opt2', 'Yes');
        Observer.Expect('opt2Info', 'o2');
        Observer.Expect('optInt1', 'Yes');
        Observer.Expect('optInt1Info', 'o1');
        Observer.Expect('enumFive', 'Yes');
        Observer.Expect('enumFiveInfo', 'f');
        Observer.Expect('enumOne', 'No');
        Observer.Expect('enumZero', 'Yes');
        Observer.Expect('enumFromInt9', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Composite_Key()
    var
        R: Record "LT RcA Multi";
    begin
        Seed.Keys();
        Observer.Observe('full', Format(R.Get('A', 1, DMY2Date(1, 1, 2020))));
        Observer.Observe('fullInfo', R.Info);
        Observer.Observe('miss', Format(R.Get('A', 3, DMY2Date(1, 1, 2020))));
        Observer.Observe('missDate', Format(R.Get('A', 1, DMY2Date(2, 1, 2020))));
        Observer.Observe('b1', Format(R.Get('B', 1, DMY2Date(2, 1, 2020))));
        Observer.Observe('b1Info', R.Info);
        asserterror R.Get('A', 9, 0D);
        Observer.ObserveError('missErr');
        Observer.Expect('full', 'Yes');
        Observer.Expect('fullInfo', 'a1');
        Observer.Expect('miss', 'No');
        Observer.Expect('missDate', 'No');
        Observer.Expect('b1', 'Yes');
        Observer.Expect('b1Info', 'b1');
        Observer.Expect('missErr|text', 'The LT RcA Multi does not exist. Identification fields and values: A=''A'',B=''9'',C=''''');
        Observer.Expect('missErr|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Get_Variant_And_Wrong_Arg_Count_Runtime()
    var
        R: Record "LT RcA Main";
        V: Variant;
    begin
        Seed.Main();
        V := 20;
        Observer.Observe('variantInt', Format(R.Get(V)));
        V := '20';
        Observer.Observe('variantText', Format(R.Get(V)));
        V := 20.0;
        Observer.Observe('variantDec', Format(R.Get(V)));
        V := 'abc';
        asserterror R.Get(V);
        Observer.Observe('variantBadText|raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        V := true;
        Observer.Observe('variantBool', Format(R.Get(V)));
        Observer.Expect('variantInt', 'Yes');
        Observer.Expect('variantText', 'Yes');
        Observer.Expect('variantDec', 'Yes');
        Observer.Expect('variantBadText|raised', 'Yes');
        Observer.Expect('variantBool', 'No');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Get_Uses_Primary_Key_Not_Current_Key()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        Observer.Observe('get', Format(R.Get(40)));
        Observer.Observe('currentKeyAfterGet', R.CurrentKey());
        R.SetRange(Amt, 1000);
        Observer.Observe('getWithFilterOutside', Format(R.Get(40)));
        Observer.Observe('filterStill', R.GetFilter(Amt));
        Observer.Expect('get', 'Yes');
        Observer.Expect('currentKeyAfterGet', 'Name');
        Observer.Expect('getWithFilterOutside', 'Yes');
        Observer.Expect('filterStill', '1,000');
        Observer.Verify();
    end;

    [Test]
    procedure Find_SearchStrings_Equal()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 30;
        Observer.Observe('eq', Format(R.Find('=')));
        Observer.Observe('eqNo', Format(R.No));
        R.No := 35;
        Observer.Observe('eqMiss', Format(R.Find('=')));
        Observer.Observe('eqMissNo', Format(R.No));
        R.No := 35;
        Observer.Observe('default', Format(R.Find()));
        Observer.Observe('defaultNo', Format(R.No));
        Observer.Expect('eq', 'Yes');
        Observer.Expect('eqNo', '30');
        Observer.Expect('eqMiss', 'No');
        Observer.Expect('eqMissNo', '35');
        Observer.Expect('default', 'No');
        Observer.Expect('defaultNo', '35');
        Observer.Verify();
    end;

    [Test]
    procedure Find_SearchStrings_Neighbours()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 35;
        Observer.Observe('ge', Format(R.Find('>=')));
        Observer.Observe('geNo', Format(R.No));
        R.No := 40;
        Observer.Observe('geExact', Format(R.Find('>=')));
        Observer.Observe('geExactNo', Format(R.No));
        R.No := 35;
        Observer.Observe('le', Format(R.Find('<=')));
        Observer.Observe('leNo', Format(R.No));
        R.No := 40;
        Observer.Observe('leExact', Format(R.Find('<=')));
        Observer.Observe('leExactNo', Format(R.No));
        R.No := 40;
        Observer.Observe('gt', Format(R.Find('>')));
        Observer.Observe('gtNo', Format(R.No));
        R.No := 40;
        Observer.Observe('lt', Format(R.Find('<')));
        Observer.Observe('ltNo', Format(R.No));
        Observer.Expect('ge', 'Yes');
        Observer.Expect('geNo', '40');
        Observer.Expect('geExact', 'Yes');
        Observer.Expect('geExactNo', '50');
        Observer.Expect('le', 'Yes');
        Observer.Expect('leNo', '30');
        Observer.Expect('leExact', 'Yes');
        Observer.Expect('leExactNo', '30');
        Observer.Expect('gt', 'Yes');
        Observer.Expect('gtNo', '50');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('ltNo', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Find_SearchStrings_FirstLast()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 55;
        Observer.Observe('minus', Format(R.Find('-')));
        Observer.Observe('minusNo', Format(R.No));
        R.No := 55;
        Observer.Observe('plus', Format(R.Find('+')));
        Observer.Observe('plusNo', Format(R.No));
        R.Reset();
        R.SetFilter(No, '>=30&<=70');
        R.No := 5;
        Observer.Observe('filtMinus', Format(R.Find('-')));
        Observer.Observe('filtMinusNo', Format(R.No));
        Observer.Observe('filtPlus', Format(R.Find('+')));
        Observer.Observe('filtPlusNo', Format(R.No));
        Observer.Expect('minus', 'Yes');
        Observer.Expect('minusNo', '10');
        Observer.Expect('plus', 'Yes');
        Observer.Expect('plusNo', '100');
        Observer.Expect('filtMinus', 'Yes');
        Observer.Expect('filtMinusNo', '30');
        Observer.Expect('filtPlus', 'Yes');
        Observer.Expect('filtPlusNo', '70');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Edges_Past_Ends()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 200;
        Observer.Observe('geBeyond', Format(R.Find('>=')));
        Observer.Observe('geBeyondNo', Format(R.No));
        R.No := 100;
        Observer.Observe('gtLast', Format(R.Find('>')));
        R.No := 10;
        Observer.Observe('ltFirst', Format(R.Find('<')));
        R.No := 1;
        Observer.Observe('leBelow', Format(R.Find('<=')));
        R.No := 1;
        Observer.Observe('geBelow', Format(R.Find('>=')));
        Observer.Observe('geBelowNo', Format(R.No));
        Observer.Expect('geBeyond', 'No');
        Observer.Expect('geBeyondNo', '200');
        Observer.Expect('gtLast', 'No');
        Observer.Expect('ltFirst', 'No');
        Observer.Expect('leBelow', 'No');
        Observer.Expect('geBelow', 'Yes');
        Observer.Expect('geBelowNo', '10');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure DoFind(var R: Record "LT RcA Main"; SearchText: Text)
    begin
        R.Find(SearchText);
    end;

    local procedure TryFind(var R: Record "LT RcA Main"; SearchText: Text): Text
    begin
        ClearLastError();
        if DoFind(R, SearchText) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Find_Invalid_SearchStrings()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 30;
        Observer.Observe('x', TryFind(R, 'x'));
        Observer.Observe('doubleEq', TryFind(R, '=='));
        Observer.Observe('empty', TryFind(R, ''));
        Observer.Observe('gtgt', TryFind(R, '>>'));
        Observer.Observe('eqgt', TryFind(R, '=>'));
        Observer.Observe('space', TryFind(R, ' '));
        Observer.Observe('minusPlus', TryFind(R, '-+'));
        Observer.Expect('x', 'There is an invalid character in the Find expression ''x''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('doubleEq', 'There is an invalid character in the Find expression ''==''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('empty', 'There is an invalid character in the Find expression ''''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('gtgt', 'There is an invalid character in the Find expression ''>>''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('eqgt', 'ok');
        Observer.Expect('space', 'There is an invalid character in the Find expression '' ''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('minusPlus', 'There is an invalid character in the Find expression ''-+''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Empty_Table_And_Filtered_Out()
    var
        R: Record "LT RcA Main";
    begin
        R.DeleteAll();
        Observer.Observe('emptyMinus', Format(R.Find('-')));
        Observer.Observe('emptyPlus', Format(R.Find('+')));
        Observer.Observe('emptyEq', Format(R.Find('=')));
        Observer.Observe('emptyGe', Format(R.Find('>=')));
        Seed.Main();
        R.SetRange(No, 500);
        R.No := 30;
        Observer.Observe('filteredEq', Format(R.Find('=')));
        Observer.Observe('filteredMinus', Format(R.Find('-')));
        Observer.Expect('emptyMinus', 'No');
        Observer.Expect('emptyPlus', 'No');
        Observer.Expect('emptyEq', 'No');
        Observer.Expect('emptyGe', 'No');
        Observer.Expect('filteredEq', 'No');
        Observer.Expect('filteredMinus', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Respects_CurrentKey_Order()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        Observer.Observe('first', Format(R.Find('-')));
        Observer.Observe('firstName', R.Name);
        Observer.Observe('firstNo', Format(R.No));
        Observer.Observe('last', Format(R.Find('+')));
        Observer.Observe('lastName', R.Name);
        R.Name := 'N5';
        Observer.Observe('geName', Format(R.Find('>=')));
        Observer.Observe('geNameVal', R.Name);
        Observer.Observe('geNameNo', Format(R.No));
        Observer.Expect('first', 'Yes');
        Observer.Expect('firstName', 'N1');
        Observer.Expect('firstNo', '100');
        Observer.Expect('last', 'Yes');
        Observer.Expect('lastName', 'N9');
        Observer.Expect('geName', 'Yes');
        Observer.Expect('geNameVal', 'N5');
        Observer.Expect('geNameNo', '60');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Uses_Key_Fields_Only_Not_Other_Fields()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 30;
        R.Name := 'does not matter';
        Observer.Observe('find', Format(R.Find()));
        Observer.Observe('nameAfter', R.Name);
        Observer.Expect('find', 'Yes');
        Observer.Expect('nameAfter', 'N8');
        Observer.Verify();
    end;

    [Test]
    procedure Find_Text_Key_Case_Insensitive()
    var
        R: Record "LT RcA TextKey";
    begin
        Seed.Keys();
        R.Tx := 'ABC';
        Observer.Observe('find', Format(R.Find()));
        Observer.Observe('txAfter', R.Tx);
        Observer.Observe('infoAfter', R.Info);
        R.Tx := 'abd';
        Observer.Observe('ge', Format(R.Find('>=')));
        Observer.Observe('geTx', R.Tx);
        R.Tx := 'b';
        Observer.Observe('le', Format(R.Find('<=')));
        Observer.Observe('leTx', R.Tx);
        Observer.Expect('find', 'No');
        Observer.Expect('txAfter', 'ABC');
        Observer.Expect('infoAfter', '');
        Observer.Expect('ge', 'Yes');
        Observer.Expect('geTx', 'ABD');
        Observer.Expect('le', 'Yes');
        Observer.Expect('leTx', 'ABD');
        Observer.Verify();
    end;

    // Corpus issue 668 items 20, 24, 28, 29 (writer BQ). Fixtures: record/lt-bq-odd-leads/BqObjects.al.
    [TryFunction]
    local procedure BqTryGetMulti(var M: Record "LT RcA Multi"; Shape: Integer; var Found: Boolean)
    begin
        case Shape of
            1:
                Found := M.Get('Q');
            2:
                Found := M.Get('Q', 1);
            3:
                Found := M.Get('R');
            4:
                Found := M.Get('Q', 2);
            5:
                Found := M.Get();
        end;
    end;

    local procedure BqMultiOutcome(var M: Record "LT RcA Multi"; Shape: Integer): Text
    var
        Found: Boolean;
        Result: Text;
    begin
        Clear(M);
        if BqTryGetMulti(M, Shape, Found) then
            exit(Format(Found) + ' ' + M.A + '/' + Format(M.B) + '/' + Format(M.C, 0, 9) + ' ' + M.Info);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // Get with fewer values than the three key fields of LT RcA Multi (A Code, B Integer, C Date); rows Q/0/0D, Q/1/0D, Q/1/2020-01-01.
    [Test]
    procedure Get_Fewer_Values_Than_Key_Fields_BQ()
    var
        M: Record "LT RcA Multi";
        Filtered: Record "LT RcA Multi";
    begin
        Seed.Keys();
        M.Init();
        M.A := 'Q';
        M.Info := 'q00';
        M.Insert();
        M.Init();
        M.A := 'Q';
        M.B := 1;
        M.Info := 'q10';
        M.Insert();
        M.Init();
        M.A := 'Q';
        M.B := 1;
        M.C := DMY2Date(1, 1, 2020);
        M.Info := 'q1d';
        M.Insert();
        Observer.Observe('oneValue', BqMultiOutcome(M, 1));
        Observer.Observe('twoValues', BqMultiOutcome(M, 2));
        Observer.Observe('oneValueMissing', BqMultiOutcome(M, 3));
        Observer.Observe('twoValuesMissing', BqMultiOutcome(M, 4));
        Observer.Observe('noValues', BqMultiOutcome(M, 5));
        asserterror M.Get('R');
        Observer.ObserveError('oneValueMissingError');
        Filtered.SetRange(Info, 'zzz');
        Filtered.SetCurrentKey(Info);
        Observer.Observe('filteredGet', Format(Filtered.Get('Q', 1)) + ' ' + Filtered.Info);
        Observer.Observe('filtersAfterGet', Filtered.GetFilters());
        Observer.Observe('keyAfterGet', Filtered.CurrentKey());
        Observer.Observe('countAfterGet', Format(Filtered.Count()));
        Observer.Expect('oneValue', 'Yes Q/0/ q00');
        Observer.Expect('twoValues', 'Yes Q/1/ q10');
        Observer.Expect('oneValueMissing', 'No /0/ ');
        Observer.Expect('twoValuesMissing', 'No /0/ ');
        Observer.Expect('noValues', 'No /0/ ');
        Observer.Expect('oneValueMissingError|text', 'The LT RcA Multi does not exist. Identification fields and values: A=''R'',B=''0'',C=''''');
        Observer.Expect('oneValueMissingError|code', 'DB:RecordNotFound');
        Observer.Expect('filteredGet', 'No ');
        Observer.Expect('filtersAfterGet', 'Info: zzz');
        Observer.Expect('keyAfterGet', 'Info');
        Observer.Expect('countAfterGet', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BqTryGetByRecord(var R: Record "LT RcA Main"; Shape: Integer; var Found: Boolean)
    var
        Other: Record "LT RcA Main";
        CodeKey: Record "LT RcA CodeKey";
    begin
        case Shape of
            1:
                begin
                    Other.Get(30);
                    Found := R.Get(Other);
                end;
            2:
                begin
                    R.No := 40;
                    Found := R.Get(R);
                end;
            3:
                begin
                    CodeKey.FindFirst();
                    Found := R.Get(CodeKey);
                end;
            4:
                begin
                    Other.Init();
                    Found := R.Get(Other);
                end;
        end;
    end;

    local procedure BqGetByRecordOutcome(Shape: Integer): Text
    var
        R: Record "LT RcA Main";
        Found: Boolean;
        Result: Text;
    begin
        if BqTryGetByRecord(R, Shape, Found) then
            exit(Format(Found) + ' no=' + Format(R.No));
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // Record.Get with a Record as its argument compiles (Get takes Any; microsoft/AL issue 6769): what it does at run time.
    [Test]
    procedure Get_With_A_Record_Argument_BQ()
    begin
        Seed.Main();
        Seed.Keys();
        Observer.Observe('sameTable', BqGetByRecordOutcome(1));
        Observer.Observe('itself', BqGetByRecordOutcome(2));
        Observer.Observe('otherTable', BqGetByRecordOutcome(3));
        Observer.Observe('initRecord', BqGetByRecordOutcome(4));
#if BC28PLUS
        Observer.Expect('sameTable', 'error:The value "30\tN8\tC0\t4.5\t01/03/20\tNo\tAlpha\tFive\tItem 3\t" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('sameTable', 'error:Unable to convert from Microsoft.Dynamics.Nav.BusinessApplication.Record71500 to System.Int32.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('itself', 'error:The value "40\t\t\t0\t\tNo\tAlpha\tZero\t\t" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('itself', 'error:Unable to convert from Microsoft.Dynamics.Nav.BusinessApplication.Record71500 to System.Int32.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('otherTable', 'error:The value "ABC\tlower" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('otherTable', 'error:Unable to convert from Microsoft.Dynamics.Nav.BusinessApplication.Record71501 to System.Int32.|Conversion');
#endif
#if BC28PLUS
        Observer.Expect('initRecord', 'error:The value "0\t\t\t0\t\tNo\tAlpha\tZero\t\t" can''t be evaluated into type Integer.|Evaluate:Conversion');
#else
        Observer.Expect('initRecord', 'error:Unable to convert from Microsoft.Dynamics.Nav.BusinessApplication.Record71500 to System.Int32.|Conversion');
#endif
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BqTryRidStep(Step: Integer; var Rid: RecordId; var Result: Text)
    var
        K: Record "LT BQ Rid Key";
    begin
        case Step of
            2:
                Result := Format(K.Get(Rid)) + ' ' + K.Name;
            3:
                begin
                    K.SetRange(Ref, Rid);
                    Result := Format(K.FindFirst()) + ' ' + K.Name + ' count=' + Format(K.Count());
                end;
            4:
                Result := 'count=' + Format(K.Count());
        end;
    end;

    local procedure BqRidOutcome(Step: Integer; var Rid: RecordId): Text
    var
        Result: Text;
    begin
        if BqTryRidStep(Step, Rid, Result) then
            exit(Result);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // A table whose only key field is a RecordId (docs: Record.Get): Insert, Get(RecordId), SetRange plus FindFirst, and Get of a RecordId that
    // has no row.
    [Test]
    procedure Get_On_A_RecordId_Primary_Key_BQ()
    var
        R: Record "LT RcA Main";
        K: Record "LT BQ Rid Key";
        Rid: RecordId;
        Missing: RecordId;
    begin
        Seed.Main();
        K.DeleteAll();
        R.Get(20);
        Rid := R.RecordId();
        R.Get(30);
        Missing := R.RecordId();
        K.Init();
        K.Ref := Rid;
        K.Name := 'main 20';
        K.Insert();
        Observer.Observe('insert', 'no error');
        Observer.Observe('get', BqRidOutcome(2, Rid));
        Observer.Observe('setRange', BqRidOutcome(3, Rid));
        Observer.Observe('getMissing', BqRidOutcome(2, Missing));
        Observer.Observe('count', BqRidOutcome(4, Rid));
        Observer.Expect('insert', 'no error');
        Observer.Expect('get', 'No ');
        Observer.Expect('setRange', 'Yes main 20 count=1');
        Observer.Expect('getMissing', 'No ');
        Observer.Expect('count', 'count=1');
        Observer.Verify();
    end;
}
