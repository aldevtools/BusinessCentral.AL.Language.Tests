// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72523, table 72524
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: "SetFilter %1 - A text with `>` or `\"`, or with a wildcard together with ..." (Probe round 6, types and JSON),
// "A text filter on a DateFormula field - SetFilter(DateFormulaField, '<>''''')" (NP Retail blockers)
// Facts: SetFilter with %1 texts holding operators and wildcards, GetFilter; SetFilter/SetRange on a DateFormula field
// BC versions: 29 (27 and 28 by CI)

table 72524 "LT PnE Filter Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Formula; DateFormula) { }
        field(4; Code20; Code[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72523 "LT PnE Filter Percent1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FilterOf(Txt: Text): Text
    var
        Rec: Record "LT PnE Filter Rec";
    begin
        Rec.SetFilter(Name, '%1', Txt);
        exit(Rec.GetFilter(Name));
    end;

    [Test]
    procedure Percent1_WithOperators()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Filter Rec";
    begin
        Rec.SetFilter(Name, '%1', 'a>b');
        Observer.Observe('gt', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a"b');
        Observer.Observe('quote', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a&b');
        Observer.Observe('amp', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a|b');
        Observer.Observe('pipe', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a(b)');
        Observer.Observe('paren', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a<b');
        Observer.Observe('lt', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a=b');
        Observer.Observe('eq', Rec.GetFilter(Name));
        Rec.SetFilter(Name, '%1', 'a..b');
        Observer.Observe('dotdot', Rec.GetFilter(Name));
        Observer.Expect('gt', '''a>b''');
        Observer.Expect('quote', 'a"b');
        Observer.Expect('amp', '''a&b''');
        Observer.Expect('pipe', '''a|b''');
        Observer.Expect('paren', '''a(b)''');
        Observer.Expect('lt', '''a<b''');
        Observer.Expect('eq', '''a=b''');
        Observer.Expect('dotdot', '''a..b''');
        Observer.Verify();
    end;

    [Test]
    procedure Percent1_WithWildcardAndOperators()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('starAmp', FilterOf('a*&b'));
        Observer.Observe('starPipe', FilterOf('a*|b'));
        Observer.Observe('starParen', FilterOf('a*(b)'));
        Observer.Observe('starLt', FilterOf('a*<b'));
        Observer.Observe('starEq', FilterOf('a*=b'));
        Observer.Observe('starDotDot', FilterOf('a*..b'));
        Observer.Observe('questionPipe', FilterOf('a?|b'));
        Observer.Observe('atDotDot', FilterOf('@a..b'));
        Observer.Observe('starGt', FilterOf('a*>b'));
        Observer.Observe('starQuote', FilterOf('a*"b'));
        Observer.Observe('starOnly', FilterOf('a*b'));
        Observer.Expect('starAmp', '''a*&b''');
        Observer.Expect('starPipe', '''a*|b''');
        Observer.Expect('starParen', '''a*(b)''');
        Observer.Expect('starLt', '''a*<b''');
        Observer.Expect('starEq', '''a*=b''');
        Observer.Expect('starDotDot', '''a*..b''');
        Observer.Expect('questionPipe', '''a?|b''');
        Observer.Expect('atDotDot', '''@a..b''');
        Observer.Expect('starGt', '''a*>b''');
        Observer.Expect('starQuote', 'a*"b');
        Observer.Expect('starOnly', 'a*b');
        Observer.Verify();
    end;

    [Test]
    procedure Percent1_ThenFindUsesText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Filter Rec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Name := 'a>b';
        Rec.Insert();
        Rec.Id := 2;
        Rec.Name := 'a"b';
        Rec.Insert();
        Rec.Id := 3;
        Rec.Name := 'a|b';
        Rec.Insert();
        Rec.SetFilter(Name, '%1', 'a>b');
        Observer.Observe('gtCount', Format(Rec.Count()));
        Rec.SetFilter(Name, '%1', 'a"b');
        Observer.Observe('quoteCount', Format(Rec.Count()));
        Rec.SetFilter(Name, '%1', 'a|b');
        Observer.Observe('pipeCount', Format(Rec.Count()));
        Rec.SetFilter(Name, '%1', 'a*b');
        Observer.Observe('starCount', Format(Rec.Count()));
        Rec.DeleteAll();
        Observer.Expect('gtCount', '1');
        Observer.Expect('quoteCount', '1');
        Observer.Expect('pipeCount', '1');
        Observer.Expect('starCount', '3');
        Observer.Verify();
    end;

    local procedure SetupFormulaRows(var Rec: Record "LT PnE Filter Rec")
    var
        F: DateFormula;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Id := 2;
        Evaluate(F, '1M');
        Rec.Formula := F;
        Rec.Insert();
        Rec.Id := 3;
        Evaluate(F, 'CM');
        Rec.Formula := F;
        Rec.Insert();
        Rec.Id := 4;
        Evaluate(F, '<1M+1D>');
        Rec.Formula := F;
        Rec.Insert();
    end;

    local procedure CountFormula(Txt: Text): Text
    var
        Rec: Record "LT PnE Filter Rec";
    begin
        SetupFormulaRows(Rec);
        Rec.SetFilter(Formula, Txt);
        exit(Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
    end;

    [Test]
    procedure DateFormula_SetFilterTexts()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Filter Rec";
    begin
        SetupFormulaRows(Rec);
        Rec.SetFilter(Formula, '''''');
        Observer.Observe('empty', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.SetFilter(Formula, '<>''''');
        Observer.Observe('notEmpty', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.SetFilter(Formula, '1M');
        Observer.Observe('1M', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        asserterror Rec.SetFilter(Formula, '<1M>');
        Observer.ObserveError('af156');
        Observer.Observe('<1M>', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.SetFilter(Formula, 'CM');
        Observer.Observe('CM', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        asserterror Rec.SetFilter(Formula, '<1M+1D>');
        Observer.ObserveError('af161');
        Observer.Observe('1M+1D', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.SetFilter(Formula, '1M|CM');
        Observer.Observe('1M|CM', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.SetFilter(Formula, '');
        Observer.Observe('blankFilter', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.DeleteAll();
        Observer.Expect('empty', '1|''''');
        Observer.Expect('notEmpty', '3|<>''''');
        Observer.Expect('1M', '1|1M');
        Observer.Expect('af156|text', 'The filter "<1M>" is not valid for the Formula field on the LT PnE Filter Rec table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('af156|code', 'Filter:CSide');
        Observer.Expect('<1M>', '0|1M');
        Observer.Expect('CM', '0|CM');
        Observer.Expect('af161|text', 'The filter "<1M+1D>" is not valid for the Formula field on the LT PnE Filter Rec table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('af161|code', 'Filter:CSide');
        Observer.Expect('1M+1D', '0|CM');
        Observer.Expect('1M|CM', '0|1M|CM');
        Observer.Expect('blankFilter', '0|');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_SetFilterErrors()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Filter Rec";
    begin
        SetupFormulaRows(Rec);
        asserterror Rec.SetFilter(Formula, 'xyz');
        Observer.ObserveError('xyz');
        Rec.SetFilter(Formula, '1M..CM');
        Observer.Observe('range', 'no error');
        Rec.SetFilter(Formula, '>1M');
        Observer.Observe('greater', 'no error');
        Rec.DeleteAll();
        Observer.Expect('xyz|text', 'The filter "xyz" is not valid for the Formula field on the LT PnE Filter Rec table. The date formula ''XYZ'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('xyz|code', 'Filter:CSide');
        Observer.Expect('range', 'no error');
        Observer.Expect('greater', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_SetRange()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Filter Rec";
        F: DateFormula;
        Empty: DateFormula;
    begin
        SetupFormulaRows(Rec);
        Rec.SetRange(Formula, Empty);
        Observer.Observe('rangeEmpty', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Evaluate(F, '1M');
        Rec.SetRange(Formula, F);
        Observer.Observe('range1M', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Evaluate(F, 'CM');
        Rec.SetRange(Formula, F);
        Observer.Observe('rangeCM', Format(Rec.Count()) + '|' + Rec.GetFilter(Formula));
        Rec.DeleteAll();
        Observer.Expect('rangeEmpty', '1|''''');
        Observer.Expect('range1M', '1|1M');
        Observer.Expect('rangeCM', '1|CM');
        Observer.Verify();
    end;
}
