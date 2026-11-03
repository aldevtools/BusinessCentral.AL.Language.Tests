// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71503 "LT RcA SetRange"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    local procedure Nos(var R: Record "LT RcA Main"): Text
    var
        Log: Text;
    begin
        if R.FindSet() then
            repeat
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        exit(Log);
    end;

    [Test]
    procedure SetRange_Single_And_FromTo()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 30);
        Observer.Observe('single', Nos(R));
        Observer.Observe('getFilter', R.GetFilter(No));
        R.SetRange(No, 30, 50);
        Observer.Observe('fromTo', Nos(R));
        Observer.Observe('getFilterFromTo', R.GetFilter(No));
        R.SetRange(No, 50, 30);
        Observer.Observe('reversed', Nos(R));
        Observer.Observe('getFilterReversed', R.GetFilter(No));
        R.SetRange(No, 30, 30);
        Observer.Observe('sameFromTo', Nos(R));
        Observer.Observe('getFilterSame', R.GetFilter(No));
        R.SetRange(No, 31, 39);
        Observer.Observe('emptyRange', Nos(R));
        Observer.Expect('single', '30,');
        Observer.Expect('getFilter', '30');
        Observer.Expect('fromTo', '30,40,50,');
        Observer.Expect('getFilterFromTo', '30..50');
        Observer.Expect('reversed', '');
        Observer.Expect('getFilterReversed', '50..30');
        Observer.Expect('sameFromTo', '30,');
        Observer.Expect('getFilterSame', '30');
        Observer.Expect('emptyRange', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Blank_Clears_Filter()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 30);
        R.SetRange(No);
        Observer.Observe('cleared', Format(R.Count()));
        Observer.Observe('getFilter', R.GetFilter(No));
        Observer.Observe('hasFilter', Format(R.HasFilter()));
        R.SetRange(Name, '');
        Observer.Observe('blankText', Format(R.Count()));
        Observer.Observe('blankTextFilter', R.GetFilter(Name));
        Observer.Observe('blankTextHas', Format(R.HasFilter()));
        R.SetRange(Dt, 0D);
        Observer.Observe('blankDate', Format(R.Count()));
        Observer.Observe('blankDateFilter', R.GetFilter(Dt));
        Observer.Expect('cleared', '10');
        Observer.Expect('getFilter', '');
        Observer.Expect('hasFilter', 'No');
        Observer.Expect('blankText', '0');
        Observer.Expect('blankTextFilter', '''''');
        Observer.Expect('blankTextHas', 'Yes');
        Observer.Expect('blankDate', '0');
        Observer.Expect('blankDateFilter', '''''');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Every_Field_Type()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(Cd, 'C1');
        Observer.Observe('code', Format(R.Count()));
        Observer.Observe('codeFilter', R.GetFilter(Cd));
        R.Reset();
        R.SetRange(Cd, 'c1');
        Observer.Observe('codeLower', Format(R.Count()));
        Observer.Observe('codeLowerFilter', R.GetFilter(Cd));
        R.Reset();
        R.SetRange(Amt, 3);
        Observer.Observe('dec', Format(R.Count()));
        Observer.Observe('decFilter', R.GetFilter(Amt));
        R.SetRange(Amt, 1.5, 4.5);
        Observer.Observe('decRange', Format(R.Count()));
        Observer.Observe('decRangeFilter', R.GetFilter(Amt));
        R.Reset();
        R.SetRange(Dt, DMY2Date(3, 1, 2020));
        Observer.Observe('date', Format(R.Count()));
        Observer.Observe('dateFilter', R.GetFilter(Dt));
        R.SetRange(Dt, DMY2Date(3, 1, 2020), DMY2Date(5, 1, 2020));
        Observer.Observe('dateRange', Format(R.Count()));
        Observer.Observe('dateRangeFilter', R.GetFilter(Dt));
        R.Reset();
        R.SetRange(Flag, true);
        Observer.Observe('bool', Format(R.Count()));
        Observer.Observe('boolFilter', R.GetFilter(Flag));
        R.SetRange(Flag, false);
        Observer.Observe('boolFalse', Format(R.Count()));
        Observer.Observe('boolFalseFilter', R.GetFilter(Flag));
        R.Reset();
        R.SetRange(Opt, R.Opt::Beta);
        Observer.Observe('opt', Format(R.Count()));
        Observer.Observe('optFilter', R.GetFilter(Opt));
        R.SetRange(Opt, R.Opt::Alpha, R.Opt::Beta);
        Observer.Observe('optRange', Format(R.Count()));
        Observer.Observe('optRangeFilter', R.GetFilter(Opt));
        R.Reset();
        R.SetRange(En, R.En::Five);
        Observer.Observe('enum', Format(R.Count()));
        Observer.Observe('enumFilter', R.GetFilter(En));
        R.SetRange(En, R.En::Zero, R.En::Five);
        Observer.Observe('enumRange', Format(R.Count()));
        Observer.Observe('enumRangeFilter', R.GetFilter(En));
        Observer.Expect('code', '4');
        Observer.Expect('codeFilter', 'C1');
        Observer.Expect('codeLower', '4');
        Observer.Expect('codeLowerFilter', 'C1');
        Observer.Expect('dec', '1');
        Observer.Expect('decFilter', '3');
        Observer.Expect('decRange', '3');
        Observer.Expect('decRangeFilter', '1.5..4.5');
        Observer.Expect('date', '1');
        Observer.Expect('dateFilter', '01/03/20');
        Observer.Expect('dateRange', '3');
        Observer.Expect('dateRangeFilter', '01/03/20..01/05/20');
        Observer.Expect('bool', '5');
        Observer.Expect('boolFilter', 'Yes');
        Observer.Expect('boolFalse', '5');
        Observer.Expect('boolFalseFilter', 'No');
        Observer.Expect('opt', '4');
        Observer.Expect('optFilter', 'Beta');
        Observer.Expect('optRange', '7');
        Observer.Expect('optRangeFilter', 'Alpha..Beta');
        Observer.Expect('enum', '5');
        Observer.Expect('enumFilter', 'Five');
        Observer.Expect('enumRange', '10');
        Observer.Expect('enumRangeFilter', 'Zero..Five');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Replaces_Previous_Filter_On_Same_Field()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(No, '10|20|30');
        R.SetRange(No, 40, 50);
        Observer.Observe('replaced', Nos(R));
        Observer.Observe('filter', R.GetFilter(No));
        R.SetRange(Cd, 'C1');
        Observer.Observe('both', Nos(R));
        Observer.Observe('filters', R.GetFilters());
        Observer.Expect('replaced', '40,50,');
        Observer.Expect('filter', '40..50');
        Observer.Expect('both', '40,');
        Observer.Expect('filters', 'No: 40..50, Cd: C1');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Text_Special_Characters_Are_Literal()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Texts();
        R.SetRange(Tx, 'a&b');
        Observer.Observe('amp', Format(R.Count()));
        Observer.Observe('ampFilter', R.GetFilter(Tx));
        R.SetRange(Tx, 'x|y');
        Observer.Observe('pipe', Format(R.Count()));
        Observer.Observe('pipeFilter', R.GetFilter(Tx));
        R.SetRange(Tx, 'it''s');
        Observer.Observe('quote', Format(R.Count()));
        Observer.Observe('quoteFilter', R.GetFilter(Tx));
        R.SetRange(Tx, 'a.b');
        Observer.Observe('dot', Format(R.Count()));
        Observer.Observe('dotFilter', R.GetFilter(Tx));
        R.SetRange(Tx, 'a*');
        Observer.Observe('star', Format(R.Count()));
        Observer.Observe('starFilter', R.GetFilter(Tx));
        R.SetRange(Tx, 'APPLE');
        Observer.Observe('caseInsens', Format(R.Count()));
        Observer.Observe('caseFilter', R.GetFilter(Tx));
        R.SetRange(Tx, '50%');
        Observer.Observe('percent', Format(R.Count()));
        Observer.Observe('percentFilter', R.GetFilter(Tx));
        R.SetRange(Tx, '<>apple');
        Observer.Observe('ltgt', Format(R.Count()));
        Observer.Observe('ltgtFilter', R.GetFilter(Tx));
        Observer.Expect('amp', '1');
        Observer.Expect('ampFilter', '''a&b''');
        Observer.Expect('pipe', '1');
        Observer.Expect('pipeFilter', '''x|y''');
        Observer.Expect('quote', '1');
        Observer.Expect('quoteFilter', 'it''s');
        Observer.Expect('dot', '1');
        Observer.Expect('dotFilter', 'a.b');
        Observer.Expect('star', '0');
        Observer.Expect('starFilter', '=''a*''');
        Observer.Expect('caseInsens', '0');
        Observer.Expect('caseFilter', 'APPLE');
        Observer.Expect('percent', '1');
        Observer.Expect('percentFilter', '50%');
        Observer.Expect('ltgt', '0');
        Observer.Expect('ltgtFilter', '''<>apple''');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Conversions()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 20.0);
        Observer.Observe('intFromDec', R.GetFilter(No));
        R.SetRange(Name, 'N5', 'N1');
        Observer.Observe('textReversed', R.GetFilter(Name));
        Observer.Observe('textReversedCount', Format(R.Count()));
        Observer.Expect('intFromDec', '20');
        Observer.Expect('textReversed', 'N5..N1');
        Observer.Expect('textReversedCount', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Text_Field_Too_Long_Value()
    var
        R: Record "LT RcA CodeKey";
    begin
        Seed.Keys();
        asserterror R.SetRange(Cd, 'abcdefghijklmnopqrstuvwxyz');
        Observer.ObserveError('af191');
        Observer.Observe('filter', R.GetFilter(Cd));
        Observer.Observe('count', Format(R.Count()));
        R.SetRange(Cd, '');
        Observer.Observe('blankFilter', R.GetFilter(Cd));
        Observer.Expect('af191|text', 'The length of the string is 26, but it must be less than or equal to 10 characters. Value: abcdefghijklmnopqrstuvwxyz');
        Observer.Expect('af191|code', 'StringLengthExceeded');
        Observer.Expect('filter', '');
        Observer.Expect('count', '0');
        Observer.Expect('blankFilter', '''''');
        Observer.Verify();
    end;
}

codeunit 71504 "LT RcA SetFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    local procedure NoFilter(FilterText: Text): Text
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        R.SetFilter(No, FilterText);
        if R.FindSet() then
            repeat
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        exit(Log + '|' + R.GetFilter(No));
    end;

    [Test]
    procedure SetFilter_Integer_Operators()
    begin
        Seed.Main();
        Observer.Observe('eq', NoFilter('30'));
        Observer.Observe('eqSign', NoFilter('=30'));
        Observer.Observe('gt', NoFilter('>80'));
        Observer.Observe('lt', NoFilter('<30'));
        Observer.Observe('ge', NoFilter('>=80'));
        Observer.Observe('le', NoFilter('<=30'));
        Observer.Observe('ne', NoFilter('<>30'));
        Observer.Observe('range', NoFilter('30..50'));
        Observer.Observe('openLow', NoFilter('..30'));
        Observer.Observe('openHigh', NoFilter('80..'));
        Observer.Observe('or', NoFilter('10|30|50'));
        Observer.Observe('and', NoFilter('>=30&<=50'));
        Observer.Observe('andOr', NoFilter('>=30&<=50|90'));
        Observer.Observe('neAnd', NoFilter('<>30&<>40'));
        Observer.Observe('rangeOr', NoFilter('10..20|80..90'));
        Observer.Observe('blank', NoFilter(''));
        Observer.Observe('negative', NoFilter('-5..25'));
        Observer.Expect('eq', '30,|30');
        Observer.Expect('eqSign', '30,|30');
        Observer.Expect('gt', '90,100,|>80');
        Observer.Expect('lt', '10,20,|<30');
        Observer.Expect('ge', '80,90,100,|>=80');
        Observer.Expect('le', '10,20,30,|<=30');
        Observer.Expect('ne', '10,20,40,50,60,70,80,90,100,|<>30');
        Observer.Expect('range', '30,40,50,|30..50');
        Observer.Expect('openLow', '10,20,30,|..30');
        Observer.Expect('openHigh', '80,90,100,|80..');
        Observer.Expect('or', '10,30,50,|10|30|50');
        Observer.Expect('and', '30,40,50,|>=30&<=50');
        Observer.Expect('andOr', '30,40,50,90,|>=30&<=50|90');
        Observer.Expect('neAnd', '10,20,50,60,70,80,90,100,|<>30&<>40');
        Observer.Expect('rangeOr', '10,20,80,90,|10..20|80..90');
        Observer.Expect('blank', '10,20,30,40,50,60,70,80,90,100,|');
        Observer.Expect('negative', '10,20,|-5..25');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Integer_Whitespace_And_Case()
    begin
        Seed.Main();
        Observer.Observe('spaces', NoFilter(' 30 '));
        Observer.Observe('spacesRange', NoFilter('30 .. 50'));
        Observer.Observe('spacesOr', NoFilter('10 | 20'));
        Observer.Observe('spacesOp', NoFilter('> 80'));
        Observer.Observe('dupOr', NoFilter('10|10'));
        Observer.Observe('order', NoFilter('50|10'));
        Observer.Observe('overlap', NoFilter('10..40|30..50'));
        Observer.Observe('reversedRange', NoFilter('50..30'));
        Observer.Observe('gtlt', NoFilter('>30&<50'));
        Observer.Observe('impossible', NoFilter('>50&<30'));
        Observer.Expect('spaces', '30,|30');
        Observer.Expect('spacesRange', '30,40,50,|30..50');
        Observer.Expect('spacesOr', '10,20,|10|20');
        Observer.Expect('spacesOp', '90,100,|>80');
        Observer.Expect('dupOr', '10,|10|10');
        Observer.Expect('order', '10,50,|50|10');
        Observer.Expect('overlap', '10,20,30,40,50,|10..40|30..50');
        Observer.Expect('reversedRange', '|50..30');
        Observer.Expect('gtlt', '40,|>30&<50');
        Observer.Expect('impossible', '|>50&<30');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Integer_Invalid()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        asserterror R.SetFilter(No, 'abc');
        Observer.ObserveError('abc');
        asserterror R.SetFilter(No, '1..x');
        Observer.ObserveError('rangeBad');
        asserterror R.SetFilter(No, '>');
        Observer.ObserveError('opOnly');
        asserterror R.SetFilter(No, '1.5');
        Observer.ObserveError('decimal');
        asserterror R.SetFilter(No, '10&');
        Observer.ObserveError('trailingAnd');
        asserterror R.SetFilter(No, '|10');
        Observer.ObserveError('leadingOr');
        asserterror R.SetFilter(No, '10|');
        Observer.ObserveError('trailingOr');
        R.SetFilter(No, '(10)');
        Observer.Observe('parens', 'no error');
        asserterror R.SetFilter(No, '10...20');
        Observer.ObserveError('threeDots');
        asserterror R.SetFilter(No, '*');
        Observer.ObserveError('star');
        asserterror R.SetFilter(No, '@10');
        Observer.ObserveError('at');
        asserterror R.SetFilter(No, '3000000000');
        Observer.ObserveError('overflow');
        asserterror R.SetFilter(No, '><10');
        Observer.ObserveError('twoOps');
        Observer.Expect('abc|text', 'The filter "abc" is not valid for the No field on the LT RcA Main table. The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('abc|code', 'Filter:CSide');
        Observer.Expect('rangeBad|text', 'The filter "1..x" is not valid for the No field on the LT RcA Main table. The value "x" can''t be evaluated into type Integer.');
        Observer.Expect('rangeBad|code', 'Filter:CSide');
        Observer.Expect('opOnly|text', 'The filter ">" is not valid for the No field on the LT RcA Main table. A value is expected after the ''>''.');
        Observer.Expect('opOnly|code', 'Filter:CSide');
        Observer.Expect('decimal|text', 'The filter "1.5" is not valid for the No field on the LT RcA Main table. The value "1.5" can''t be evaluated into type Integer.');
        Observer.Expect('decimal|code', 'Filter:CSide');
        Observer.Expect('trailingAnd|text', 'The filter "10&" is not valid for the No field on the LT RcA Main table. The right side of ''&'' operators cannot be empty.');
        Observer.Expect('trailingAnd|code', 'Filter:CSide');
        Observer.Expect('leadingOr|text', 'The filter "|10" is not valid for the No field on the LT RcA Main table. The left side of ''|'' operators cannot be empty.');
        Observer.Expect('leadingOr|code', 'Filter:CSide');
        Observer.Expect('trailingOr|text', 'The filter "10|" is not valid for the No field on the LT RcA Main table. The right side of ''|'' operators cannot be empty.');
        Observer.Expect('trailingOr|code', 'Filter:CSide');
        Observer.Expect('parens', 'no error');
        Observer.Expect('threeDots|text', 'The filter "10...20" is not valid for the No field on the LT RcA Main table. The value ".20" can''t be evaluated into type Integer.');
        Observer.Expect('threeDots|code', 'Filter:CSide');
        Observer.Expect('star|text', 'The filter "*" is not valid for the No field on the LT RcA Main table. The value "*" can''t be evaluated into type Integer.');
        Observer.Expect('star|code', 'Filter:CSide');
        Observer.Expect('at|text', 'The filter "@10" is not valid for the No field on the LT RcA Main table. The value "@10" can''t be evaluated into type Integer.');
        Observer.Expect('at|code', 'Filter:CSide');
        Observer.Expect('overflow|text', 'The filter "3000000000" is not valid for the No field on the LT RcA Main table. The value "3000000000" can''t be evaluated into type Integer.');
        Observer.Expect('overflow|code', 'Filter:CSide');
        Observer.Expect('twoOps|text', 'The filter "><10" is not valid for the No field on the LT RcA Main table. A value is expected after the ''>''.');
        Observer.Expect('twoOps|code', 'Filter:CSide');
        Observer.Verify();
    end;





    [Test]
    procedure SetFilter_Placeholders()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetFilter(No, '%1', 30);
        Observer.Observe('one', R.GetFilter(No));
        R.SetFilter(No, '%1..%2', 30, 50);
        Observer.Observe('two', R.GetFilter(No));
        R.SetFilter(No, '%1|%2|%1', 30, 50);
        Observer.Observe('reuse', R.GetFilter(No));
        R.SetFilter(No, '>%1&<%2', 30, 70);
        Observer.Observe('ops', R.GetFilter(No));
        Observer.Observe('opsCount', Format(R.Count()));
        R.SetFilter(No, '%2', 30, 50);
        Observer.Observe('onlySecond', R.GetFilter(No));
        R.SetFilter(No, '<>%1', 30);
        Observer.Observe('ne', R.GetFilter(No));
        R.SetFilter(No, '%1', 20.0);
        Observer.Observe('decArg', R.GetFilter(No));
        asserterror R.SetFilter(No, '%1');
        Observer.ObserveError('missingArg');
        asserterror R.SetFilter(No, '%3', 1, 2);
        Observer.ObserveError('thirdOfTwo');
        R.SetFilter(No, '10', 30);
        Observer.Observe('unusedArg', R.GetFilter(No));
        asserterror R.SetFilter(No, '%0', 1);
        Observer.ObserveError('zero');
        R.SetFilter(No, '%1', 0);
        Observer.Observe('zeroValue', R.GetFilter(No));
        Observer.Expect('one', '30');
        Observer.Expect('two', '30..50');
        Observer.Expect('reuse', '30|50|30');
        Observer.Expect('ops', '>30&<70');
        Observer.Expect('opsCount', '3');
        Observer.Expect('onlySecond', '50');
        Observer.Expect('ne', '<>30');
        Observer.Expect('decArg', '20');
        Observer.Expect('missingArg|text', 'The filter "%1" is not valid for the No field on the LT RcA Main table. The variable "%1" was not understood.');
        Observer.Expect('missingArg|code', 'Filter:CSide');
        Observer.Expect('thirdOfTwo|text', 'The filter "%3" is not valid for the No field on the LT RcA Main table. The variable "%3" was not understood.');
        Observer.Expect('thirdOfTwo|code', 'Filter:CSide');
        Observer.Expect('unusedArg', '10');
        Observer.Expect('zero|text', 'The filter "%0" is not valid for the No field on the LT RcA Main table. The variable "%0" was not understood.');
        Observer.Expect('zero|code', 'Filter:CSide');
        Observer.Expect('zeroValue', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Placeholders_Other_Types()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(Dt, '%1', DMY2Date(3, 1, 2020));
        Observer.Observe('date', R.GetFilter(Dt));
        Observer.Observe('dateCount', Format(R.Count()));
        R.SetFilter(Dt, '%1..%2', DMY2Date(3, 1, 2020), DMY2Date(5, 1, 2020));
        Observer.Observe('dateRange', R.GetFilter(Dt));
        R.SetFilter(Dt, '%1', 0D);
        Observer.Observe('dateBlank', R.GetFilter(Dt));
        R.Reset();
        R.SetFilter(Amt, '%1', 4.5);
        Observer.Observe('dec', R.GetFilter(Amt));
        Observer.Observe('decCount', Format(R.Count()));
        R.Reset();
        R.SetFilter(Flag, '%1', true);
        Observer.Observe('bool', R.GetFilter(Flag));
        Observer.Observe('boolCount', Format(R.Count()));
        R.Reset();
        R.SetFilter(Opt, '%1', R.Opt::Gamma);
        Observer.Observe('opt', R.GetFilter(Opt));
        Observer.Observe('optCount', Format(R.Count()));
        R.Reset();
        R.SetFilter(En, '%1', R.En::Five);
        Observer.Observe('enum', R.GetFilter(En));
        Observer.Observe('enumCount', Format(R.Count()));
        R.Reset();
        R.SetFilter(Cd, '%1', 'C1');
        Observer.Observe('code', R.GetFilter(Cd));
        Observer.Observe('codeCount', Format(R.Count()));
        R.Reset();
        R.SetFilter(Tx, '%1', 'Item 3');
        Observer.Observe('text', R.GetFilter(Tx));
        Observer.Observe('textCount', Format(R.Count()));
        Observer.Expect('date', '01/03/20');
        Observer.Expect('dateCount', '1');
        Observer.Expect('dateRange', '01/03/20..01/05/20');
        Observer.Expect('dateBlank', '''''');
        Observer.Expect('dec', '4.5');
        Observer.Expect('decCount', '1');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('boolCount', '5');
        Observer.Expect('opt', 'Gamma');
        Observer.Expect('optCount', '3');
        Observer.Expect('enum', 'Five');
        Observer.Expect('enumCount', '5');
        Observer.Expect('code', 'C1');
        Observer.Expect('codeCount', '4');
        Observer.Expect('text', 'Item 3');
        Observer.Expect('textCount', '1');
        Observer.Verify();
    end;

    local procedure TxFilter(FilterText: Text): Text
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        R.SetFilter(Tx, FilterText);
        if R.FindSet() then
            repeat
                Log += R.Tx + ';';
            until R.Next() = 0;
        exit(Log + '|' + R.GetFilter(Tx));
    end;

    [Test]
    procedure SetFilter_Text_Wildcards_And_Case()
    begin
        Seed.Texts();
        Observer.Observe('exact', TxFilter('apple'));
        Observer.Observe('upper', TxFilter('APPLE'));
        Observer.Observe('caseInsensitiveAt', TxFilter('@APPLE'));
        Observer.Observe('starEnd', TxFilter('a*'));
        Observer.Observe('starEndAt', TxFilter('@a*'));
        Observer.Observe('starStart', TxFilter('*e'));
        Observer.Observe('starBoth', TxFilter('*an*'));
        Observer.Observe('question', TxFilter('?pple'));
        Observer.Observe('questionTwo', TxFilter('??ple'));
        Observer.Observe('questionAt', TxFilter('@?pple'));
        Observer.Observe('onlyStar', TxFilter('*'));
        Observer.Observe('onlyQuestion', TxFilter('?'));
        Observer.Observe('blank', TxFilter(''));
        Observer.Observe('emptyQuotes', TxFilter(''''''));
        Observer.Observe('ne', TxFilter('<>apple'));
        Observer.Observe('neStar', TxFilter('<>a*'));
        Observer.Observe('gt', TxFilter('>banana'));
        Observer.Observe('le', TxFilter('<=apple'));
        Observer.Observe('range', TxFilter('a..b'));
        asserterror Observer.Observe('rangeAt', TxFilter('@a..b'));
        Observer.ObserveError('af410');
        Observer.Observe('or', TxFilter('apple|banana'));
        Observer.Observe('and', TxFilter('a*&*e'));
        Observer.Expect('exact', 'apple;|apple');
        Observer.Expect('upper', '|APPLE');
        Observer.Expect('caseInsensitiveAt', 'apple;|@APPLE');
        Observer.Expect('starEnd', 'apple;a&b;a.b;|a*');
        Observer.Expect('starEndAt', 'apple;Apple pie;a&b;a.b;|@a*');
        Observer.Expect('starStart', 'apple;Apple pie;|*e');
        Observer.Expect('starBoth', 'banana;|*an*');
        Observer.Expect('question', 'apple;|?pple');
        Observer.Expect('questionTwo', 'apple;|??ple');
        Observer.Expect('questionAt', 'apple;|@?pple');
        Observer.Expect('onlyStar', 'apple;Apple pie;banana;it''s;a&b;x|y;50%;;a.b;Zed;|*');
        Observer.Expect('onlyQuestion', '|?');
        Observer.Expect('blank', 'apple;Apple pie;banana;it''s;a&b;x|y;50%;;a.b;Zed;|');
        Observer.Expect('emptyQuotes', ';|''''');
        Observer.Expect('ne', 'Apple pie;banana;it''s;a&b;x|y;50%;;a.b;Zed;|<>apple');
        Observer.Expect('neStar', 'Apple pie;banana;it''s;x|y;50%;;Zed;|<>a*');
        Observer.Expect('gt', 'it''s;x|y;Zed;|>banana');
        Observer.Expect('le', 'apple;a&b;50%;;a.b;|<=apple');
        Observer.Expect('range', 'apple;Apple pie;a&b;a.b;|a..b');
        Observer.Expect('af410|text', 'The filter "@a..b" is not valid for the Tx field on the LT RcA Main table. The value ''@a'' contains wildcard characters. Wildcards cannot be used with operators =, .., >, <, >=, and <=. If the value ''@a'' was intended to be a wildcard, enclose the value in single quotes.');
        Observer.Expect('af410|code', 'Filter:CSide');
        Observer.Expect('or', '|apple|banana');
        Observer.Expect('and', '|a*&*e');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Text_Special_Character_Quoting()
    begin
        Seed.Texts();
        Observer.Observe('ampBare', TxFilter('a&b'));
        Observer.Observe('ampQuoted', TxFilter('''a&b'''));
        Observer.Observe('pipeQuoted', TxFilter('''x|y'''));
        Observer.Observe('pipeBare', TxFilter('x|y'));
        Observer.Observe('apostrophe', TxFilter('''it''''s'''));
        Observer.Observe('apostropheBare', TxFilter('it''s'));
        Observer.Observe('percentQuoted', TxFilter('''50%'''));
        Observer.Observe('dotQuoted', TxFilter('''a.b'''));
        Observer.Observe('dotBare', TxFilter('a.b'));
        Observer.Observe('twoDotsQuoted', TxFilter('''a..b'''));
        Observer.Observe('starQuoted', TxFilter('''a*'''));
        Observer.Observe('questionQuoted', TxFilter('''?pple'''));
        Observer.Observe('quotedEmptyOr', TxFilter('''''|apple'));
        asserterror Observer.Observe('unterminated', TxFilter('''apple'));
        Observer.ObserveError('af434');
        Observer.Expect('ampBare', '|a&b');
        Observer.Expect('ampQuoted', 'a&b;|''a&b''');
        Observer.Expect('pipeQuoted', 'x|y;|''x|y''');
        Observer.Expect('pipeBare', '|x|y');
        Observer.Expect('apostrophe', 'it''s;|it''s');
        Observer.Expect('apostropheBare', 'it''s;|it''s');
        Observer.Expect('percentQuoted', '50%;|50%');
        Observer.Expect('dotQuoted', 'a.b;|a.b');
        Observer.Expect('dotBare', 'a.b;|a.b');
        Observer.Expect('twoDotsQuoted', '|''a..b''');
        Observer.Expect('starQuoted', 'apple;a&b;a.b;|a*');
        Observer.Expect('questionQuoted', 'apple;|?pple');
        Observer.Expect('quotedEmptyOr', 'apple;;|''''|apple');
        Observer.Expect('af434|text', 'The filter "''apple" is not valid for the Tx field on the LT RcA Main table. An single quote ('') is missing.');
        Observer.Expect('af434|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Text_Invalid()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Texts();
        asserterror R.SetFilter(Tx, '''abc');
        Observer.ObserveError('openQuote');
        asserterror R.SetFilter(Tx, 'a&');
        Observer.ObserveError('trailingAnd');
        asserterror R.SetFilter(Tx, '>');
        Observer.ObserveError('opOnly');
        asserterror R.SetFilter(Tx, '..');
        Observer.ObserveError('dotsOnly');
        asserterror R.SetFilter(Tx, '||');
        Observer.ObserveError('twoPipes');
        R.SetFilter(Tx, '(a)');
        Observer.Observe('parens', 'no error');
        Observer.Expect('openQuote|text', 'The filter "''abc" is not valid for the Tx field on the LT RcA Main table. An single quote ('') is missing.');
        Observer.Expect('openQuote|code', 'Filter:CSide');
        Observer.Expect('trailingAnd|text', 'The filter "a&" is not valid for the Tx field on the LT RcA Main table. The right side of ''&'' operators cannot be empty.');
        Observer.Expect('trailingAnd|code', 'Filter:CSide');
        Observer.Expect('opOnly|text', 'The filter ">" is not valid for the Tx field on the LT RcA Main table. A value is expected after the ''>''.');
        Observer.Expect('opOnly|code', 'Filter:CSide');
        Observer.Expect('dotsOnly|text', 'The filter ".." is not valid for the Tx field on the LT RcA Main table. Both sides of the range (''..'') cannot be empty.');
        Observer.Expect('dotsOnly|code', 'Filter:CSide');
        Observer.Expect('twoPipes|text', 'The filter "||" is not valid for the Tx field on the LT RcA Main table. The left side of ''|'' operators cannot be empty.');
        Observer.Expect('twoPipes|code', 'Filter:CSide');
        Observer.Expect('parens', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Decimal_Date_Boolean_Option_Enum()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(Amt, '1.5..4.5');
        Observer.Observe('decRange', Format(R.Count()) + '|' + R.GetFilter(Amt));
        R.SetFilter(Amt, '>=12');
        Observer.Observe('decGe', Format(R.Count()) + '|' + R.GetFilter(Amt));
        R.SetFilter(Amt, '3|4.5|6');
        Observer.Observe('decOr', Format(R.Count()) + '|' + R.GetFilter(Amt));
        R.SetFilter(Amt, '1,5');
        Observer.Observe('decComma', Format(R.Count()) + '|' + R.GetFilter(Amt));
        R.SetFilter(Amt, '3.00');
        Observer.Observe('decTrailing', Format(R.Count()) + '|' + R.GetFilter(Amt));
        R.Reset();
        R.SetFilter(Dt, '030120..050120');
        Observer.Observe('dateRange', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.SetFilter(Dt, '030120|050120');
        Observer.Observe('dateOr', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.SetFilter(Dt, '>=080120');
        Observer.Observe('dateGe', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.SetFilter(Dt, '03.01.2020');
        Observer.Observe('dateDotted', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.SetFilter(Dt, '2020-01-03');
        Observer.Observe('dateIso', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.SetFilter(Dt, '''''');
        Observer.Observe('dateBlankQuotes', Format(R.Count()) + '|' + R.GetFilter(Dt));
        R.Reset();
        R.SetFilter(Flag, 'Yes');
        Observer.Observe('boolYes', Format(R.Count()) + '|' + R.GetFilter(Flag));
        R.SetFilter(Flag, 'No');
        Observer.Observe('boolNo', Format(R.Count()) + '|' + R.GetFilter(Flag));
        R.SetFilter(Flag, 'true');
        Observer.Observe('boolTrue', Format(R.Count()) + '|' + R.GetFilter(Flag));
        R.SetFilter(Flag, '1');
        Observer.Observe('boolOne', Format(R.Count()) + '|' + R.GetFilter(Flag));
        R.SetFilter(Flag, '0');
        Observer.Observe('boolZero', Format(R.Count()) + '|' + R.GetFilter(Flag));
        R.Reset();
        R.SetFilter(Opt, 'Beta');
        Observer.Observe('optName', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.SetFilter(Opt, 'beta');
        Observer.Observe('optNameLower', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.SetFilter(Opt, '1');
        Observer.Observe('optInt', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.SetFilter(Opt, 'Alpha|Gamma');
        Observer.Observe('optOr', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.SetFilter(Opt, '<>Beta');
        Observer.Observe('optNe', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.SetFilter(Opt, 'Alpha..Beta');
        Observer.Observe('optRange', Format(R.Count()) + '|' + R.GetFilter(Opt));
        R.Reset();
        R.SetFilter(En, 'Five');
        Observer.Observe('enumName', Format(R.Count()) + '|' + R.GetFilter(En));
        R.SetFilter(En, '5');
        Observer.Observe('enumInt', Format(R.Count()) + '|' + R.GetFilter(En));
        R.SetFilter(En, 'Zero|Five');
        Observer.Observe('enumOr', Format(R.Count()) + '|' + R.GetFilter(En));
        R.SetFilter(En, '<>Zero');
        Observer.Observe('enumNe', Format(R.Count()) + '|' + R.GetFilter(En));
        Observer.Expect('decRange', '3|1.5..4.5');
        Observer.Expect('decGe', '3|>=12');
        Observer.Expect('decOr', '3|3|4.5|6');
        Observer.Expect('decComma', '1|15');
        Observer.Expect('decTrailing', '1|3');
        Observer.Expect('dateRange', '0|03/01/20..05/01/20');
        Observer.Expect('dateOr', '0|03/01/20|05/01/20');
        Observer.Expect('dateGe', '0|>=08/01/20');
        Observer.Expect('dateDotted', '0|03/01/20');
        Observer.Expect('dateIso', '1|01/03/20');
        Observer.Expect('dateBlankQuotes', '0|''''');
        Observer.Expect('boolYes', '5|Yes');
        Observer.Expect('boolNo', '5|No');
        Observer.Expect('boolTrue', '5|Yes');
        Observer.Expect('boolOne', '5|Yes');
        Observer.Expect('boolZero', '5|No');
        Observer.Expect('optName', '4|Beta');
        Observer.Expect('optNameLower', '4|Beta');
        Observer.Expect('optInt', '4|Beta');
        Observer.Expect('optOr', '6|Alpha|Gamma');
        Observer.Expect('optNe', '6|<>Beta');
        Observer.Expect('optRange', '7|Alpha..Beta');
        Observer.Expect('enumName', '5|Five');
        Observer.Expect('enumInt', '5|Five');
        Observer.Expect('enumOr', '10|Zero|Five');
        Observer.Expect('enumNe', '5|<>Zero');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Blank_Expression_Clears()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(No, '>50');
        R.SetFilter(No, '');
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('has', Format(R.HasFilter()));
        Observer.Observe('filter', R.GetFilter(No));
        R.SetFilter(No, '>50');
        Observer.Expect('count', '10');
        Observer.Expect('has', 'No');
        Observer.Expect('filter', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Replaces_Existing_And_Is_ANDed_Across_Fields()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(No, '<50');
        R.SetFilter(No, '>30');
        Observer.Observe('replaced', R.GetFilter(No) + '|' + Format(R.Count()));
        R.SetFilter(Cd, 'C1|C2');
        Observer.Observe('twoFields', R.GetFilters() + '|' + Format(R.Count()));
        Observer.Expect('replaced', '>30|7');
        Observer.Expect('twoFields', 'No: >30, Cd: C1|C2|5');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Long_Filter_Strings()
    var
        R: Record "LT RcA Main";
        F: Text;
        i: Integer;
    begin
        Seed.Main();
        for i := 1 to 60 do
            F += Format(i * 10) + '|';
        F := F.TrimEnd('|');
        R.SetFilter(No, F);
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('filterLength', Format(StrLen(R.GetFilter(No))));
        Observer.Expect('count', '10');
        Observer.Expect('filterLength', '230');
        Observer.Verify();
    end;

    // Corpus issue 668 items 1-3 (writer BQ). Fixtures: record/lt-bq-odd-leads/BqObjects.al.
    [TryFunction]
    local procedure BqTrySetFilter(var R: Record "LT BQ Flt Row"; FieldNo: Integer; FilterText: Text)
    begin
        case FieldNo of
            2:
                R.SetFilter(G, FilterText);
            3:
                R.SetFilter(Txt, FilterText);
            4:
                R.SetFilter(Cd, FilterText);
            5:
                R.SetFilter(Num, FilterText);
        end;
    end;

    local procedure BqTokenOutcome(FieldNo: Integer; FilterText: Text): Text
    var
        R: Record "LT BQ Flt Row";
        Log: Codeunit "LT BQ Token Log";
        BqSeed: Codeunit "LT BQ Seed";
        Result: Text;
    begin
        Log.Take();
        if BqTrySetFilter(R, FieldNo, FilterText) then
            Result := 'filter=[' + R.GetFilters() + '] ids=' + BqSeed.Ids(R)
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result + ' log=' + Log.Take());
    end;

    // A custom filter token whose subscriber of Filter Tokens.OnResolveTextFilterToken returns a Guid text (microsoft/AL issue 7728), in
    // SetFilter on a Guid, Text, Code and Integer field; a token that returns 5; an unknown token; the token without the subscriber bound.
    [Test]
    procedure SetFilter_Custom_Filter_Token_BQ()
    var
        TokenSub: Codeunit "LT BQ Token Sub";
        BqSeed: Codeunit "LT BQ Seed";
    begin
        BqSeed.FltRows();
        Observer.Observe('guidUnbound', BqTokenOutcome(2, '%BQGUID'));
        BindSubscription(TokenSub);
        Observer.Observe('guid', BqTokenOutcome(2, '%BQGUID'));
        Observer.Observe('guidLower', BqTokenOutcome(2, '%bqguid'));
        Observer.Observe('text', BqTokenOutcome(3, '%BQGUID'));
        Observer.Observe('code', BqTokenOutcome(4, '%BQGUID'));
        Observer.Observe('integer', BqTokenOutcome(5, '%BQGUID'));
        Observer.Observe('textFive', BqTokenOutcome(3, '%BQFIVE'));
        Observer.Observe('codeFive', BqTokenOutcome(4, '%BQFIVE'));
        Observer.Observe('integerFive', BqTokenOutcome(5, '%BQFIVE'));
        Observer.Observe('integerFiveOr', BqTokenOutcome(5, '%BQFIVE|7'));
        UnbindSubscription(TokenSub);
        Observer.Expect('guidUnbound', 'error:The filter "%BQGUID" is not valid for the G field on the LT BQ Flt Row table. The variable "%BQGUID" was not understood.|Filter:CSide log=');
        Observer.Expect('guid', 'error:The filter "%BQGUID" is not valid for the G field on the LT BQ Flt Row table. The variable "%BQGUID" was not understood.|Filter:CSide log=');
        Observer.Expect('guidLower', 'error:The filter "%bqguid" is not valid for the G field on the LT BQ Flt Row table. The variable "%bqguid" was not understood.|Filter:CSide log=');
        Observer.Expect('text', 'error:The filter "%BQGUID" is not valid for the Txt field on the LT BQ Flt Row table. Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavInvalidFilterExpressionException'' was thrown.|Filter:CSide log=token:BQGUID');
        Observer.Expect('code', 'error:The filter "%BQGUID" is not valid for the Cd field on the LT BQ Flt Row table. Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavInvalidFilterExpressionException'' was thrown.|Filter:CSide log=token:BQGUID');
        Observer.Expect('integer', 'error:The filter "%BQGUID" is not valid for the Num field on the LT BQ Flt Row table. The variable "%BQGUID" was not understood.|Filter:CSide log=');
        Observer.Expect('textFive', 'filter=[Txt: 5] ids=2  log=token:BQFIVE');
        Observer.Expect('codeFive', 'filter=[Cd: 5] ids=2  log=token:BQFIVE');
        Observer.Expect('integerFive', 'error:The filter "%BQFIVE" is not valid for the Num field on the LT BQ Flt Row table. The variable "%BQFIVE" was not understood.|Filter:CSide log=');
        Observer.Expect('integerFiveOr', 'error:The filter "%BQFIVE|7" is not valid for the Num field on the LT BQ Flt Row table. The variable "%BQFIVE" was not understood.|Filter:CSide log=');
        Observer.Verify();
    end;

    // A token the subscriber does not handle (split from the test above: a failure message keeps about 2000 characters).
    [Test]
    procedure SetFilter_Custom_Filter_Token_Unknown_BQ()
    var
        TokenSub: Codeunit "LT BQ Token Sub";
        BqSeed: Codeunit "LT BQ Seed";
    begin
        BqSeed.FltRows();
        BindSubscription(TokenSub);
        Observer.Observe('guidUnknown', BqTokenOutcome(2, '%BQNONE'));
        Observer.Observe('textUnknown', BqTokenOutcome(3, '%BQNONE'));
        UnbindSubscription(TokenSub);
        Observer.Expect('guidUnknown', 'error:The filter "%BQNONE" is not valid for the G field on the LT BQ Flt Row table. The variable "%BQNONE" was not understood.|Filter:CSide log=');
        Observer.Expect('textUnknown', 'error:The filter "%BQNONE" is not valid for the Txt field on the LT BQ Flt Row table. The variable "%BQNONE" was not understood.|Filter:CSide log=token:BQNONE');
        Observer.Verify();
    end;

    // SetRange on a DateTime field with an upper bound of 23:59:59.999/.998/.997 the day before a value stored at midnight (microsoft/AL
    // issue 7325), the same comparison in plain AL, and the value a DateTime with .999/.998/.997 milliseconds has after it is stored.
    [Test]
    procedure SetRange_DateTime_Millisecond_Bounds_BQ()
    var
        R: Record "LT BQ Flt Row";
        Midnight: DateTime;
    begin
        R.DeleteAll();
        Midnight := CreateDateTime(20240325D, 000000T);
        R.Init();
        R.Id := 1;
        R.DT := Midnight;
        R.Insert();
        R.SetRange(DT, 0DT, CreateDateTime(20240324D, 235959.999T));
        Observer.Observe('to999', Format(R.Count()) + '|' + R.GetFilter(DT));
        R.SetRange(DT, 0DT, CreateDateTime(20240324D, 235959.998T));
        Observer.Observe('to998', Format(R.Count()) + '|' + R.GetFilter(DT));
        R.SetRange(DT, 0DT, CreateDateTime(20240324D, 235959.997T));
        Observer.Observe('to997', Format(R.Count()) + '|' + R.GetFilter(DT));
        R.SetRange(DT, CreateDateTime(20240325D, 000000.001T), CreateDateTime(20240326D, 000000T));
        Observer.Observe('from001', Format(R.Count()) + '|' + R.GetFilter(DT));
        R.SetFilter(DT, '<%1', CreateDateTime(20240325D, 000000.001T));
        Observer.Observe('lt001', Format(R.Count()));
        Observer.Observe('plain999GeMidnight', Format(CreateDateTime(20240324D, 235959.999T) >= Midnight));
        Observer.Observe('plain999LtMidnight', Format(CreateDateTime(20240324D, 235959.999T) < Midnight));
        R.Reset();
        R.Init();
        R.Id := 2;
        R.DT := CreateDateTime(20240324D, 235959.999T);
        R.Insert();
        R.Init();
        R.Id := 3;
        R.DT := CreateDateTime(20240324D, 235959.998T);
        R.Insert();
        R.Init();
        R.Id := 4;
        R.DT := CreateDateTime(20240324D, 235959.997T);
        R.Insert();
        Observer.Observe('memory997', Format(R.DT, 0, 9));
        R.Get(2);
        Observer.Observe('stored999', Format(R.DT, 0, 9));
        R.Get(3);
        Observer.Observe('stored998', Format(R.DT, 0, 9));
        R.Get(4);
        Observer.Observe('stored997', Format(R.DT, 0, 9));
        R.Reset();
        R.SetRange(DT, Midnight);
        Observer.Observe('eqMidnightCount', Format(R.Count()));
        Observer.Expect('to999', '1|''''..03/24/24 11:59:59.999 PM');
        Observer.Expect('to998', '0|''''..03/24/24 11:59:59.998 PM');
        Observer.Expect('to997', '0|''''..03/24/24 11:59:59.997 PM');
        Observer.Expect('from001', '1|03/25/24 12:00:00.001 AM..03/26/24 12:00 AM');
        Observer.Expect('lt001', '0');
        Observer.Expect('plain999GeMidnight', 'No');
        Observer.Expect('plain999LtMidnight', 'Yes');
        Observer.Expect('memory997', '2024-03-24T23:59:59.997Z');
        Observer.Expect('stored999', '2024-03-25T00:00:00Z');
        Observer.Expect('stored998', '2024-03-24T23:59:59.997Z');
        Observer.Expect('stored997', '2024-03-24T23:59:59.997Z');
        Observer.Expect('eqMidnightCount', '2');
        Observer.Verify();
    end;

    // '&' between two plain values on an Integer field, and '@' with '*' and '?' together on a Text field (docs: entering criteria in filters).
    [Test]
    procedure SetFilter_Ampersand_Values_And_At_Wildcards_BQ()
    begin
        Seed.Main();
        Observer.Observe('eqAndEq', NoFilter('30&50'));
        Observer.Observe('eqAndSame', NoFilter('30&30'));
        Observer.Observe('eqAndRange', NoFilter('30&20..40'));
        Seed.Texts();
        Observer.Observe('atStarPQStar', TxFilter('@*P?*'));
        Observer.Observe('atStarEQ', TxFilter('@*E?'));
        Observer.Observe('atQPStar', TxFilter('@?P*'));
        Observer.Observe('starPQStar', TxFilter('*P?*'));
        Observer.Expect('eqAndEq', '|30&50');
        Observer.Expect('eqAndSame', '30,|30&30');
        Observer.Expect('eqAndRange', '30,|30&20..40');
        Observer.Expect('atStarPQStar', 'apple;Apple pie;|@*P?*');
        Observer.Expect('atStarEQ', 'Zed;|@*E?');
        Observer.Expect('atQPStar', 'apple;Apple pie;|@?P*');
        Observer.Expect('starPQStar', '|*P?*');
        Observer.Verify();
    end;
}
