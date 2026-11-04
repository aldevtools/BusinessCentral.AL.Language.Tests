// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Filters "A filter value that is only blank space is written in single quotes in GetFilters / GetView"
// BC versions: 29 (27 and 28 by CI)

codeunit 71100 "LT PnC Filter Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var R: Record "LT PnC Rec"; Label: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Label + '.filters', R.GetFilters());
        Observer.Observe(Label + '.view', R.GetView());
    end;

    [Test]
    procedure BlankSpace_Range()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R.SetRange(Name, ' ');
        Show(R, 'oneSpace', Observer);
        R.Reset();
        R.SetRange(Name, '  ');
        Show(R, 'twoSpaces', Observer);
        R.Reset();
        R.SetRange(Name, '');
        Show(R, 'empty', Observer);
        R.Reset();
        R.SetRange("Code Value", ' ');
        Show(R, 'codeSpace', Observer);
        R.Reset();
        R.SetRange(Name, ' ', 'B');
        Show(R, 'spaceToB', Observer);
        R.Reset();
        R.SetRange(Name, 'A', ' ');
        Show(R, 'aToSpace', Observer);
        Observer.Expect('oneSpace.filters', 'Name: '' ''');
        Observer.Expect('oneSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER('' ''))');
        Observer.Expect('twoSpaces.filters', 'Name: ''  ''');
        Observer.Expect('twoSpaces.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''  ''))');
        Observer.Expect('empty.filters', 'Name: ''''');
        Observer.Expect('empty.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''''))');
        Observer.Expect('codeSpace.filters', 'Code Value: ''''');
        Observer.Expect('codeSpace.view', 'VERSION(1) SORTING(No.) WHERE(Code Value=FILTER(''''))');
        Observer.Expect('spaceToB.filters', 'Name: '' ''..B');
        Observer.Expect('spaceToB.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER('' ''..B))');
        Observer.Expect('aToSpace.filters', 'Name: A..'' ''');
        Observer.Expect('aToSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(A..'' ''))');
        Observer.Verify();
    end;

    [Test]
    procedure BlankSpace_SetFilter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R.SetFilter(Name, '<>%1', ' ');
        Show(R, 'notSpace', Observer);
        R.Reset();
        R.SetFilter(Name, '<>%1', '');
        Show(R, 'notEmpty', Observer);
        R.Reset();
        R.SetFilter(Name, '%1|%2', ' ', 'A');
        Show(R, 'spaceOrA', Observer);
        R.Reset();
        R.SetFilter(Name, '%1', ' ');
        Show(R, 'spaceFilter', Observer);
        R.Reset();
        R.SetFilter(Name, '>%1', ' ');
        Show(R, 'gtSpace', Observer);
        R.Reset();
        R.SetFilter(Name, '<%1', ' ');
        Show(R, 'ltSpace', Observer);
        Observer.Expect('notSpace.filters', 'Name: <>'' ''');
        Observer.Expect('notSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(<>'' ''))');
        Observer.Expect('notEmpty.filters', 'Name: <>''''');
        Observer.Expect('notEmpty.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(<>''''))');
        Observer.Expect('spaceOrA.filters', 'Name: '' ''|A');
        Observer.Expect('spaceOrA.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER('' ''|A))');
        Observer.Expect('spaceFilter.filters', 'Name: '' ''');
        Observer.Expect('spaceFilter.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER('' ''))');
        Observer.Expect('gtSpace.filters', 'Name: >'' ''');
        Observer.Expect('gtSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(>'' ''))');
        Observer.Expect('ltSpace.filters', 'Name: <'' ''');
        Observer.Expect('ltSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(<'' ''))');
        Observer.Verify();
    end;

    [Test]
    procedure ValuesNeedingQuotes_Range()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R.SetRange(Name, 'A B');
        Show(R, 'innerSpace', Observer);
        R.Reset();
        R.SetRange(Name, 'A|B');
        Show(R, 'pipe', Observer);
        R.Reset();
        R.SetRange(Name, 'A&B');
        Show(R, 'amp', Observer);
        R.Reset();
        R.SetRange(Name, '(X)');
        Show(R, 'parens', Observer);
        R.Reset();
        R.SetRange(Name, 'A''B');
        Show(R, 'apostrophe', Observer);
        R.Reset();
        R.SetRange(Name, '*');
        Show(R, 'star', Observer);
        R.Reset();
        R.SetRange(Name, '@x');
        Show(R, 'at', Observer);
        R.Reset();
        R.SetRange(Name, '..');
        Show(R, 'dots', Observer);
        R.Reset();
        R.SetRange(Name, '<A');
        Show(R, 'lessThanSign', Observer);
        R.Reset();
        R.SetRange(Name, ' A');
        Show(R, 'leadingSpace', Observer);
        R.Reset();
        R.SetRange(Name, 'A ');
        Show(R, 'trailingSpace', Observer);
        Observer.Expect('innerSpace.filters', 'Name: A B');
        Observer.Expect('innerSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(A B))');
        Observer.Expect('pipe.filters', 'Name: ''A|B''');
        Observer.Expect('pipe.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''A|B''))');
        Observer.Expect('amp.filters', 'Name: ''A&B''');
        Observer.Expect('amp.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''A&B''))');
        Observer.Expect('parens.filters', 'Name: ''(X)''');
        Observer.Expect('parens.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''(X)''))');
        Observer.Expect('apostrophe.filters', 'Name: A''B');
        Observer.Expect('apostrophe.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(A''B))');
        Observer.Expect('star.filters', 'Name: =''*''');
        Observer.Expect('star.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(=''*''))');
        Observer.Expect('at.filters', 'Name: ''@x''');
        Observer.Expect('at.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''@x''))');
        Observer.Expect('dots.filters', 'Name: ''..''');
        Observer.Expect('dots.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''..''))');
        Observer.Expect('lessThanSign.filters', 'Name: ''<A''');
        Observer.Expect('lessThanSign.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''<A''))');
        Observer.Expect('leadingSpace.filters', 'Name: '' A''');
        Observer.Expect('leadingSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER('' A''))');
        Observer.Expect('trailingSpace.filters', 'Name: ''A ''');
        Observer.Expect('trailingSpace.view', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(''A ''))');
        Observer.Verify();
    end;

    [Test]
    procedure ValuesNeedingQuotes_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R.SetRange(Amount, -1.5);
        Show(R, 'negDecimal', Observer);
        R.Reset();
        R.SetRange(Amount, 1000000);
        Show(R, 'million', Observer);
        R.Reset();
        R.SetRange(Status, 1);
        Show(R, 'option', Observer);
        R.Reset();
        R.SetFilter(Status, 'Open|Closed');
        Show(R, 'optionNames', Observer);
        R.Reset();
        R.SetRange("No.", 1, 5);
        R.SetRange(Name, 'N 1');
        Show(R, 'two', Observer);
        Observer.Expect('negDecimal.filters', 'Amount: -1.5');
        Observer.Expect('negDecimal.view', 'VERSION(1) SORTING(No.) WHERE(Amount=FILTER(-1.5))');
        Observer.Expect('million.filters', 'Amount: 1,000,000');
        Observer.Expect('million.view', 'VERSION(1) SORTING(No.) WHERE(Amount=FILTER(1000000))');
        Observer.Expect('option.filters', 'Status: Released');
        Observer.Expect('option.view', 'VERSION(1) SORTING(No.) WHERE(Status=FILTER(Released))');
        Observer.Expect('optionNames.filters', 'Status: Open|Closed');
        Observer.Expect('optionNames.view', 'VERSION(1) SORTING(No.) WHERE(Status=FILTER(Open|Closed))');
        Observer.Expect('two.filters', 'No.: 1..5, Name: N 1');
        Observer.Expect('two.view', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(1..5),Name=FILTER(N 1))');
        Observer.Verify();
    end;
}

codeunit 71101 "LT PnC Find Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 6 do begin
            R.Init();
            R."No." := i;
            R.Name := 'N' + Format(7 - i);
            R."Code Value" := 'C' + Format(i mod 3);
            R.Other := i * 10;
            R.Insert();
        end;
    end;

    [Test]
    procedure FindEqual_OutsideFilter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.Get(2);
        R.SetRange("No.", 4, 6);
        Observer.Observe('findEq.afterGet', Format(R.Find('=')));
        Observer.Observe('findEq.no', Format(R."No."));
        R.Reset();
        R.SetRange("No.", 4, 6);
        R."No." := 2;
        Observer.Observe('findEq.fresh', Format(R.Find('=')));
        R."No." := 5;
        Observer.Observe('findEq.inside', Format(R.Find('=')));
        R.Get(2);
        R.FindFirst();
        R."No." := 2;
        Observer.Observe('findEq.afterFindFirst', Format(R.Find('=')));
        R.Get(2);
        R.Get(3);
        R."No." := 2;
        Observer.Observe('findEq.afterOtherGet', Format(R.Find('=')));
        Observer.Expect('findEq.afterGet', 'No');
        Observer.Expect('findEq.no', '2');
        Observer.Expect('findEq.fresh', 'No');
        Observer.Expect('findEq.inside', 'Yes');
        Observer.Expect('findEq.afterFindFirst', 'No');
        Observer.Expect('findEq.afterOtherGet', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FindGreaterAndLess_HonourFilters()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.SetRange("No.", 3, 5);
        R."No." := 1;
        Observer.Observe('ge.below', Format(R.Find('>=')));
        Observer.Observe('ge.below.no', Format(R."No."));
        R."No." := 4;
        Observer.Observe('ge.inside', Format(R.Find('>=')));
        Observer.Observe('ge.inside.no', Format(R."No."));
        R."No." := 6;
        Observer.Observe('ge.above', Format(R.Find('>=')));
        R."No." := 6;
        Observer.Observe('le.above', Format(R.Find('<=')));
        Observer.Observe('le.above.no', Format(R."No."));
        R."No." := 1;
        Observer.Observe('le.below', Format(R.Find('<=')));
        R."No." := 4;
        Observer.Observe('le.inside', Format(R.Find('<=')));
        Observer.Observe('le.inside.no', Format(R."No."));
        Observer.Expect('ge.below', 'Yes');
        Observer.Expect('ge.below.no', '3');
        Observer.Expect('ge.inside', 'Yes');
        Observer.Expect('ge.inside.no', '5');
        Observer.Expect('ge.above', 'No');
        Observer.Expect('le.above', 'Yes');
        Observer.Expect('le.above.no', '5');
        Observer.Expect('le.below', 'No');
        Observer.Expect('le.inside', 'Yes');
        Observer.Expect('le.inside.no', '3');
        Observer.Verify();
    end;

    [Test]
    procedure FindNeighbour_Forms()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R."No." := 3;
        Observer.Observe('nb.exact', Format(R.Find('=><')));
        Observer.Observe('nb.exact.no', Format(R."No."));
        R.Delete();
        R."No." := 3;
        Observer.Observe('nb.gap', Format(R.Find('=><')));
        Observer.Observe('nb.gap.no', Format(R."No."));
        R.Reset();
        R."No." := 100;
        Observer.Observe('nb.past', Format(R.Find('=><')));
        Observer.Observe('nb.past.no', Format(R."No."));
        R."No." := -5;
        Observer.Observe('nb.before', Format(R.Find('=><')));
        Observer.Observe('nb.before.no', Format(R."No."));
        R.SetRange("No.", 5, 6);
        R."No." := 3;
        Observer.Observe('nb.filtered', Format(R.Find('=><')));
        Observer.Observe('nb.filtered.no', Format(R."No."));
        Observer.Expect('nb.exact', 'Yes');
        Observer.Expect('nb.exact.no', '3');
        Observer.Expect('nb.gap', 'Yes');
        Observer.Expect('nb.gap.no', '4');
        Observer.Expect('nb.past', 'Yes');
        Observer.Expect('nb.past.no', '6');
        Observer.Expect('nb.before', 'Yes');
        Observer.Expect('nb.before.no', '1');
        Observer.Expect('nb.filtered', 'Yes');
        Observer.Expect('nb.filtered.no', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Find_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.SetCurrentKey(Name);
        R.Name := 'N3';
        Observer.Observe('k.eq', Format(R.Find('=')));
        Observer.Observe('k.eq.no', Format(R."No."));
        R.Name := 'N0';
        Observer.Observe('k.ge', Format(R.Find('>=')));
        Observer.Observe('k.ge.no', Format(R."No."));
        R.Name := 'N9';
        Observer.Observe('k.le', Format(R.Find('<=')));
        Observer.Observe('k.le.no', Format(R."No."));
        R.Name := 'N3';
        Observer.Observe('k.nb', Format(R.Find('=><')));
        Observer.Observe('k.nb.no', Format(R."No."));
        Observer.Expect('k.eq', 'No');
        Observer.Expect('k.eq.no', '0');
        Observer.Expect('k.ge', 'Yes');
        Observer.Expect('k.ge.no', '6');
        Observer.Expect('k.le', 'Yes');
        Observer.Expect('k.le.no', '1');
        Observer.Expect('k.nb', 'Yes');
        Observer.Expect('k.nb.no', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Find_InvalidSearchText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
        b: Boolean;
    begin
        Seed();
        asserterror b := R.Find('x');
        Observer.ObserveError('invalid');
        asserterror b := R.Find('');
        Observer.ObserveError('empty');
        asserterror b := R.Find('==');
        Observer.ObserveError('double');
        Observer.Expect('invalid|text', 'There is an invalid character in the Find expression ''x''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('invalid|code', 'DB:BadSearchMethod');
        Observer.Expect('empty|text', 'There is an invalid character in the Find expression ''''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('empty|code', 'DB:BadSearchMethod');
        Observer.Expect('double|text', 'There is an invalid character in the Find expression ''==''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.');
        Observer.Expect('double|code', 'DB:BadSearchMethod');
        Observer.Verify();
    end;
}

codeunit 71102 "LT PnC SetCurrentKey Free"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 5 do begin
            R.Init();
            R."No." := i;
            R.Name := 'N' + Format(i);
            R."Code Value" := 'C' + Format(i mod 2);
            R.Other := (7 - i) mod 3;
            R.Amount := i;
            R.Insert();
        end;
    end;

    local procedure Nos(var R: Record "LT PnC Rec"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R."No.") + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure FieldsNoKeyStartsWith()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.SetCurrentKey(Other);
        Observer.Observe('other.currentKey', R.CurrentKey());
        Observer.Observe('other.order', Nos(R));
        R.Ascending(false);
        Observer.Observe('other.desc.order', Nos(R));
        R.Reset();
        R.SetCurrentKey(Other, Amount);
        Observer.Observe('otherAmount.currentKey', R.CurrentKey());
        Observer.Observe('otherAmount.order', Nos(R));
        R.Reset();
        R.SetCurrentKey(Amount, Other);
        Observer.Observe('amountOther.currentKey', R.CurrentKey());
        Observer.Observe('amountOther.order', Nos(R));
        R.Reset();
        R.SetCurrentKey("Code Value");
        Observer.Observe('code.currentKey', R.CurrentKey());
        Observer.Observe('code.order', Nos(R));
        R.Reset();
        R.SetCurrentKey(Status);
        Observer.Observe('status.currentKey', R.CurrentKey());
        Observer.Observe('status.order', Nos(R));
        R.SetCurrentKey("Code Value", Name);
        Observer.Observe('codeName.currentKey', R.CurrentKey());
        Observer.Observe('codeName.order', Nos(R));
        Observer.Expect('other.currentKey', 'Other');
        Observer.Expect('other.order', '1,4,3,2,5,');
        Observer.Expect('other.desc.order', '5,2,3,4,1,');
        Observer.Expect('otherAmount.currentKey', 'Other,Amount');
        Observer.Expect('otherAmount.order', '1,4,3,2,5,');
        Observer.Expect('amountOther.currentKey', 'Amount,Other');
        Observer.Expect('amountOther.order', '1,2,3,4,5,');
        Observer.Expect('code.currentKey', 'Code Value,Amount');
        Observer.Expect('code.order', '2,4,1,3,5,');
        Observer.Expect('status.currentKey', 'Status');
        Observer.Expect('status.order', '1,2,3,4,5,');
        Observer.Expect('codeName.currentKey', 'Code Value,Name');
        Observer.Expect('codeName.order', '2,4,1,3,5,');
        Observer.Verify();
    end;

    [Test]
    procedure KeyAndFilter_Combine()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.SetCurrentKey(Other);
        R.SetFilter("No.", '>1');
        Observer.Observe('filtered.order', Nos(R));
        R.Ascending(false);
        Observer.Observe('filtered.desc', Nos(R));
        R.Ascending(true);
        R.FindFirst();
        Observer.Observe('first', Format(R."No."));
        R.FindLast();
        Observer.Observe('last', Format(R."No."));
        R.Reset();
        Observer.Observe('reset.currentKey', R.CurrentKey());
        Observer.Observe('reset.order', Nos(R));
        Observer.Expect('filtered.order', '4,3,2,5,');
        Observer.Expect('filtered.desc', '5,2,3,4,');
        Observer.Expect('first', '4');
        Observer.Expect('last', '5');
        Observer.Expect('reset.currentKey', 'No.');
        Observer.Expect('reset.order', '1,2,3,4,5,');
        Observer.Verify();
    end;

    [Test]
    procedure NotStoredFields()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        Seed();
        R.SetCurrentKey("Child Count");
        Observer.Observe('flowField', 'no error');
        asserterror R.SetCurrentKey("Flow Flt");
        Observer.ObserveError('flowFilter');
        asserterror R.SetCurrentKey(Note);
        Observer.ObserveError('blob');
        R.SetCurrentKey(Other, "Child Count");
        Observer.Observe('storedThenFlowField', 'no error');
        Observer.Observe('afterErrors.currentKey', R.CurrentKey());
        Observer.Expect('flowField', 'no error');
        Observer.Expect('flowFilter|text', 'Sorting cannot be done based on the Flow Flt field(s) in the LT PnC Rec table.');
        Observer.Expect('flowFilter|code', 'DB:Ok');
        Observer.Expect('blob|text', 'Sorting cannot be done based on the Note field(s) in the LT PnC Rec table.');
        Observer.Expect('blob|code', 'DB:Ok');
        Observer.Expect('storedThenFlowField', 'no error');
        Observer.Expect('afterErrors.currentKey', 'Other,Child Count');
        Observer.Verify();
    end;
}
