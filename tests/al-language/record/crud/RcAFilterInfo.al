// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71505 "LT RcA FilterInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure GetFilter_GetFilters_HasFilter()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('hasNone', Format(R.HasFilter()));
        Observer.Observe('getFilterNone', R.GetFilter(No));
        Observer.Observe('getFiltersNone', R.GetFilters());
        R.SetRange(No, 10, 50);
        Observer.Observe('has', Format(R.HasFilter()));
        Observer.Observe('getFilterNo', R.GetFilter(No));
        Observer.Observe('getFilterOther', R.GetFilter(Name));
        Observer.Observe('getFilters1', R.GetFilters());
        R.SetFilter(Name, 'N1|N2');
        R.SetRange(Flag, true);
        R.SetRange(Dt, DMY2Date(1, 1, 2020));
        R.SetRange(Amt, 1.5);
        Observer.Observe('getFilters4', R.GetFilters());
        R.SetFilter(Tx, '@item*');
        R.SetRange(Opt, R.Opt::Beta);
        R.SetRange(En, R.En::One);
        R.SetRange(Cd, 'C1');
        Observer.Observe('getFiltersAll', R.GetFilters());
        Observer.Expect('hasNone', 'No');
        Observer.Expect('getFilterNone', '');
        Observer.Expect('getFiltersNone', '');
        Observer.Expect('has', 'Yes');
        Observer.Expect('getFilterNo', '10..50');
        Observer.Expect('getFilterOther', '');
        Observer.Expect('getFilters1', 'No: 10..50');
        Observer.Expect('getFilters4', 'No: 10..50, Name: N1|N2, Amt: 1.5, Dt: 01/01/20, Flag: Yes');
        Observer.Expect('getFiltersAll', 'No: 10..50, Name: N1|N2, Cd: C1, Amt: 1.5, Dt: 01/01/20, Flag: Yes, Opt: Beta, En: One, Tx: @item*');
        Observer.Verify();
    end;

    [Test]
    procedure GetFilters_Format_With_Caption_And_Quoting()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Texts();
        R.SetFilter(Tx, 'a&b');
        Observer.Observe('amp', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetFilter(Tx, '''a b''');
        Observer.Observe('space', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetFilter(Tx, 'a|b');
        Observer.Observe('pipe', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetRange(Tx, 'it''s');
        Observer.Observe('quote', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetRange(Tx, 'two words');
        Observer.Observe('words', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetRange(Tx, '');
        Observer.Observe('blank', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetFilter(Tx, '<>''''');
        Observer.Observe('notBlank', R.GetFilters() + '|' + R.GetFilter(Tx));
        R.SetFilter(Tx, '*');
        Observer.Observe('star', R.GetFilters() + '|' + R.GetFilter(Tx));
        Observer.Expect('amp', 'Tx: a&b|a&b');
        Observer.Expect('space', 'Tx: a b|a b');
        Observer.Expect('pipe', 'Tx: a|b|a|b');
        Observer.Expect('quote', 'Tx: it''s|it''s');
        Observer.Expect('words', 'Tx: two words|two words');
        Observer.Expect('blank', 'Tx: ''''|''''');
        Observer.Expect('notBlank', 'Tx: <>''''|<>''''');
        Observer.Expect('star', 'Tx: *|*');
        Observer.Verify();
    end;

    [Test]
    procedure HasFilter_Variants()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('fresh', Format(R.HasFilter()));
        R.SetRange(No);
        Observer.Observe('clearedNothing', Format(R.HasFilter()));
        R.SetFilter(Name, '');
        Observer.Observe('blankFilter', Format(R.HasFilter()));
        R.SetRange(Name, '');
        Observer.Observe('blankRange', Format(R.HasFilter()));
        R.SetRange(Name);
        Observer.Observe('afterClear', Format(R.HasFilter()));
        asserterror R.SetFilter(No, '*');
        Observer.ObserveError('af83');
        Observer.Observe('star', Format(R.HasFilter()));
        R.Reset();
        Observer.Observe('afterReset', Format(R.HasFilter()));
        R.FilterGroup(5);
        R.SetRange(No, 10);
        R.FilterGroup(0);
        Observer.Observe('inGroup5', Format(R.HasFilter()));
        Observer.Expect('fresh', 'No');
        Observer.Expect('clearedNothing', 'No');
        Observer.Expect('blankFilter', 'No');
        Observer.Expect('blankRange', 'Yes');
        Observer.Expect('afterClear', 'No');
        Observer.Expect('af83|text', 'The filter "*" is not valid for the No field on the LT RcA Main table. The value "*" can''t be evaluated into type Integer.');
        Observer.Expect('af83|code', 'Filter:CSide');
        Observer.Expect('star', 'No');
        Observer.Expect('afterReset', 'No');
        Observer.Expect('inGroup5', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_Values_And_Isolation()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('initial', Format(R.FilterGroup()));
        R.SetRange(No, 10, 90);
        R.FilterGroup(2);
        Observer.Observe('now', Format(R.FilterGroup()));
        Observer.Observe('g2getFilter', R.GetFilter(No));
        R.SetRange(Cd, 'C1');
        Observer.Observe('g2count', Format(R.Count()));
        Observer.Observe('g2filters', R.GetFilters());
        R.FilterGroup(0);
        Observer.Observe('g0getFilter', R.GetFilter(No));
        Observer.Observe('g0getFilterCd', R.GetFilter(Cd));
        Observer.Observe('g0count', Format(R.Count()));
        Observer.Observe('g0filters', R.GetFilters());
        Observer.Observe('g0hasFilter', Format(R.HasFilter()));
        Observer.Expect('initial', '0');
        Observer.Expect('now', '2');
        Observer.Expect('g2getFilter', '');
        Observer.Expect('g2count', '3');
        Observer.Expect('g2filters', 'Cd: C1');
        Observer.Expect('g0getFilter', '10..90');
        Observer.Expect('g0getFilterCd', '');
        Observer.Expect('g0count', '3');
        Observer.Expect('g0filters', 'No: 10..90');
        Observer.Expect('g0hasFilter', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_Setter_Returns_Previous()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('set2', Format(R.FilterGroup(2)));
        Observer.Observe('set4', Format(R.FilterGroup(4)));
        Observer.Observe('set0', Format(R.FilterGroup(0)));
        Observer.Observe('now', Format(R.FilterGroup()));
        R.FilterGroup(-1);
        Observer.Observe('minus1', Format(R.FilterGroup()));
        R.FilterGroup(0);
        R.FilterGroup(100);
        Observer.Observe('g100', Format(R.FilterGroup()));
        R.FilterGroup(0);
        Observer.Expect('set2', '2');
        Observer.Expect('set4', '4');
        Observer.Expect('set0', '0');
        Observer.Expect('now', '0');
        Observer.Expect('minus1', '-1');
        Observer.Expect('g100', '100');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_Filters_Combine_With_AND_Across_Groups()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(No, 10, 50);
        R.FilterGroup(1);
        R.SetRange(No, 30, 90);
        R.FilterGroup(0);
        Observer.Observe('count', Format(R.Count()));
        R.FindFirst();
        Observer.Observe('first', Format(R.No));
        R.FindLast();
        Observer.Observe('last', Format(R.No));
        R.FilterGroup(1);
        Observer.Observe('g1filter', R.GetFilter(No));
        R.FilterGroup(0);
        Observer.Observe('g0filter', R.GetFilter(No));
        R.FilterGroup(1);
        R.SetRange(No);
        R.FilterGroup(0);
        Observer.Observe('afterClearG1', Format(R.Count()));
        Observer.Expect('count', '3');
        Observer.Expect('first', '30');
        Observer.Expect('last', '50');
        Observer.Expect('g1filter', '30..90');
        Observer.Expect('g0filter', '10..50');
        Observer.Expect('afterClearG1', '5');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_Reset_Clears_All_Groups()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.FilterGroup(3);
        R.SetRange(No, 10);
        R.FilterGroup(0);
        Observer.Observe('before', Format(R.Count()));
        R.Reset();
        Observer.Observe('afterReset', Format(R.Count()));
        Observer.Observe('groupAfterReset', Format(R.FilterGroup()));
        R.FilterGroup(3);
        Observer.Observe('g3filter', R.GetFilter(No));
        R.FilterGroup(0);
        Observer.Expect('before', '1');
        Observer.Expect('afterReset', '10');
        Observer.Expect('groupAfterReset', '0');
        Observer.Expect('g3filter', '');
        Observer.Verify();
    end;

    [Test]
    procedure Reset_Clears_Filters_Key_Order_But_Not_Fields()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(30);
        R.SetRange(Cd, 'C1');
        R.SetCurrentKey(Name);
        R.Ascending(false);
        R.Mark(true);
        R.MarkedOnly(true);
        R.Reset();
        Observer.Observe('hasFilter', Format(R.HasFilter()));
        Observer.Observe('currentKey', R.CurrentKey());
        Observer.Observe('ascending', Format(R.Ascending()));
        Observer.Observe('markedOnly', Format(R.MarkedOnly()));
        Observer.Observe('keepsFields', Format(R.No) + '/' + R.Name);
        Observer.Observe('mark', Format(R.Mark()));
        Observer.Observe('count', Format(R.Count()));
        Observer.Expect('hasFilter', 'No');
        Observer.Expect('currentKey', 'No');
        Observer.Expect('ascending', 'Yes');
        Observer.Expect('markedOnly', 'No');
        Observer.Expect('keepsFields', '30/N8');
        Observer.Expect('mark', 'No');
        Observer.Expect('count', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Reset_Does_Not_Reinitialize_Fields()
    var
        R: Record "LT RcA Main";
    begin
        R.No := 5;
        R.Name := 'abc';
        R.Reset();
        Observer.Observe('no', Format(R.No));
        Observer.Observe('name', R.Name);
        R.Init();
        Observer.Observe('noInit', Format(R.No));
        Observer.Expect('no', '5');
        Observer.Expect('name', 'abc');
        Observer.Expect('noInit', '5');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_Single_Field()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.SetRange(No, 20, 40);
        A.CopyFilter(No, B.No);
        Observer.Observe('copied', B.GetFilter(No));
        Observer.Observe('bCount', Format(B.Count()));
        A.SetFilter(Name, 'N1|N2');
        A.CopyFilter(Name, B.Tx);
        Observer.Observe('crossField', B.GetFilter(Tx));
        A.SetRange(Cd);
        A.CopyFilter(Cd, B.Cd);
        Observer.Observe('copyNone', B.GetFilter(Cd));
        B.SetRange(Cd, 'C1');
        A.CopyFilter(Cd, B.Cd);
        Observer.Observe('copyNoneOverwrites', B.GetFilter(Cd));
        Observer.Expect('copied', '20..40');
        Observer.Expect('bCount', '3');
        Observer.Expect('crossField', 'N1|N2');
        Observer.Expect('copyNone', '');
        Observer.Expect('copyNoneOverwrites', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_Group_And_Types()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.FilterGroup(2);
        A.SetRange(No, 20, 40);
        A.FilterGroup(0);
        A.CopyFilter(No, B.No);
        Observer.Observe('groupNotCopied', B.GetFilter(No));
        A.FilterGroup(2);
        A.CopyFilter(No, B.No);
        Observer.Observe('copiedFromGroup2', B.GetFilter(No));
        B.FilterGroup(0);
        Observer.Observe('stillGroup0', B.GetFilter(No));
        A.Reset();
        A.SetRange(Dt, DMY2Date(1, 1, 2020), DMY2Date(3, 1, 2020));
        A.CopyFilter(Dt, B.Dt);
        Observer.Observe('date', B.GetFilter(Dt));
        A.SetRange(Opt, A.Opt::Beta);
        A.CopyFilter(Opt, B.Opt);
        Observer.Observe('option', B.GetFilter(Opt));
        Observer.Expect('groupNotCopied', '');
        Observer.Expect('copiedFromGroup2', '20..40');
        Observer.Expect('stillGroup0', '20..40');
        Observer.Expect('date', '01/01/20..01/03/20');
        Observer.Expect('option', 'Beta');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilters_Whole_Record()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.SetRange(No, 20, 40);
        A.SetFilter(Name, 'N*');
        A.SetCurrentKey(Name);
        A.Ascending(false);
        B.SetRange(Cd, 'C1');
        B.CopyFilters(A);
        Observer.Observe('filters', B.GetFilters());
        Observer.Observe('overwrote', B.GetFilter(Cd));
        Observer.Observe('count', Format(B.Count()));
        Observer.Observe('key', B.CurrentKey());
        Observer.Observe('ascending', Format(B.Ascending()));
        A.FilterGroup(2);
        A.SetRange(Tx, 'Item 1');
        A.FilterGroup(0);
        B.CopyFilters(A);
        B.FilterGroup(2);
        Observer.Observe('g2copied', B.GetFilter(Tx));
        B.FilterGroup(0);
        A.Reset();
        B.CopyFilters(A);
        Observer.Observe('afterCopyOfNone', Format(B.HasFilter()));
        Observer.Expect('filters', 'No: 20..40, Name: N*');
        Observer.Expect('overwrote', '');
        Observer.Expect('count', '3');
        Observer.Expect('key', 'No');
        Observer.Expect('ascending', 'Yes');
        Observer.Expect('g2copied', 'Item 1');
        Observer.Expect('afterCopyOfNone', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilters_Marks_Not_Copied()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.Get(20);
        A.Mark(true);
        A.MarkedOnly(true);
        B.CopyFilters(A);
        Observer.Observe('markedOnly', Format(B.MarkedOnly()));
        Observer.Observe('count', Format(B.Count()));
        Observer.Expect('markedOnly', 'No');
        Observer.Expect('count', '10');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_CurrentKey_Ascending()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('default', R.CurrentKey());
        R.SetCurrentKey(Name);
        Observer.Observe('byName', R.CurrentKey());
        R.SetCurrentKey(Cd, No);
        Observer.Observe('byCd', R.CurrentKey());
        R.SetCurrentKey(No);
        Observer.Observe('byNo', R.CurrentKey());
        R.SetCurrentKey(Amt);
        Observer.Observe('byAmt', R.CurrentKey());
        Observer.Observe('asc', Format(R.Ascending()));
        R.Ascending(false);
        Observer.Observe('desc', Format(R.Ascending()));
        R.Ascending(true);
        Observer.Observe('ascAgain', Format(R.Ascending()));
        Observer.Expect('default', 'No');
        Observer.Expect('byName', 'Name');
        Observer.Expect('byCd', 'Cd,No');
        Observer.Expect('byNo', 'No');
        Observer.Expect('byAmt', 'Amt');
        Observer.Expect('asc', 'Yes');
        Observer.Expect('desc', 'No');
        Observer.Expect('ascAgain', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_Ad_Hoc_Keys()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Tx);
        Observer.Observe('adHocSingle', R.CurrentKey());
        R.SetCurrentKey(Flag, Opt);
        Observer.Observe('adHocTwo', R.CurrentKey());
        R.SetCurrentKey(Dt, Name, No);
        Observer.Observe('adHocThree', R.CurrentKey());
        R.SetCurrentKey(Name, No);
        Observer.Observe('prefixOfKey', R.CurrentKey());
        R.SetCurrentKey(Cd);
        Observer.Observe('prefixOfByCd', R.CurrentKey());
        Observer.Expect('adHocSingle', 'Tx');
        Observer.Expect('adHocTwo', 'Flag,Opt');
        Observer.Expect('adHocThree', 'Dt,Name,No');
        Observer.Expect('prefixOfKey', 'Name');
        Observer.Expect('prefixOfByCd', 'Cd,No');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_Sorting_Result()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        if R.FindSet() then
            repeat
                Log += R.Name + ',';
            until R.Next() = 0;
        Observer.Observe('byNameText', Log);
        Clear(Log);
        R.SetCurrentKey(Cd, No);
        R.Ascending(false);
        if R.FindSet() then
            repeat
                Log += R.Cd + '/' + Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('byCdDesc', Log);
        Clear(Log);
        R.SetCurrentKey(Flag, No);
        R.Ascending(true);
        if R.FindSet() then
            repeat
                Log += Format(R.Flag) + '/' + Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('byFlagNo', Log);
        Observer.Expect('byNameText', 'N1,N10,N2,N3,N4,N5,N6,N7,N8,N9,');
        Observer.Expect('byCdDesc', 'C2/80,C2/50,C2/20,C1/100,C1/70,C1/40,C1/10,C0/90,C0/60,C0/30,');
        Observer.Expect('byFlagNo', 'No/10,No/30,No/50,No/70,No/90,Yes/20,Yes/40,Yes/60,Yes/80,Yes/100,');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_Does_Not_Filter_And_Persists_Through_Find()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        Observer.Observe('hasFilter', Format(R.HasFilter()));
        R.FindFirst();
        Observer.Observe('keyAfterFind', R.CurrentKey());
        R.Get(10);
        Observer.Observe('keyAfterGet', R.CurrentKey());
        Observer.Expect('hasFilter', 'No');
        Observer.Expect('keyAfterFind', 'Name');
        Observer.Expect('keyAfterGet', 'Name');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_Invalid_Field_Combinations()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Big);
        Observer.Observe('bigField', R.CurrentKey());
        R.FindFirst();
        Observer.Observe('findOnBigKey', 'no error');
        Observer.Expect('bigField', 'Big');
        Observer.Expect('findOnBigKey', 'no error');
        Observer.Verify();
    end;

    // Corpus issue 668 item 4 (writer BQ): FilterGroup numbers past the documented range (docs: "greater numbers will be ignored").
    [TryFunction]
    local procedure BqTryGroup(var R: Record "LT RcA Main"; Group: Integer; var Previous: Integer)
    begin
        Previous := R.FilterGroup(Group);
    end;

    local procedure BqGroupOutcome(var R: Record "LT RcA Main"; Group: Integer): Text
    var
        Previous: Integer;
        Result: Text;
    begin
        if BqTryGroup(R, Group, Previous) then
            exit('ok previous=' + Format(Previous) + ' now=' + Format(R.FilterGroup()));
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' now=' + Format(R.FilterGroup());
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure FilterGroup_Numbers_Past_The_Range_BQ()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('g255', BqGroupOutcome(R, 255));
        R.FilterGroup(0);
        Observer.Observe('g256', BqGroupOutcome(R, 256));
        R.FilterGroup(0);
        Observer.Observe('g1000', BqGroupOutcome(R, 1000));
        R.FilterGroup(0);
        Observer.Observe('gMinus2', BqGroupOutcome(R, -2));
        R.FilterGroup(0);
        Observer.Observe('g300', BqGroupOutcome(R, 300));
        R.SetRange(No, 20, 40);
        Observer.Observe('afterG300Filter', R.GetFilter(No));
        R.FilterGroup(0);
        Observer.Observe('g0Filter', R.GetFilter(No));
        Observer.Observe('g0Filters', R.GetFilters());
        Observer.Observe('count', Format(R.Count()));
        R.FilterGroup(44);
        Observer.Observe('g44Filter', R.GetFilter(No));
        R.FilterGroup(255);
        Observer.Observe('g255Filter', R.GetFilter(No));
        R.FilterGroup(0);
        R.FilterGroup(255);
        R.SetRange(Cd, 'C1');
        R.FilterGroup(0);
        Observer.Observe('g255SetCount', Format(R.Count()));
        Observer.Observe('g255SetFilters', R.GetFilters());
        Observer.Expect('g255', 'ok previous=255 now=255');
        Observer.Expect('g256', 'ok previous=256 now=256');
        Observer.Expect('g1000', 'ok previous=1000 now=1000');
        Observer.Expect('gMinus2', 'ok previous=-2 now=-2');
        Observer.Expect('g300', 'ok previous=300 now=300');
        Observer.Expect('afterG300Filter', '');
        Observer.Expect('g0Filter', '');
        Observer.Expect('g0Filters', '');
        Observer.Expect('count', '10');
        Observer.Expect('g44Filter', '');
        Observer.Expect('g255Filter', '');
        Observer.Expect('g255SetCount', '4');
        Observer.Expect('g255SetFilters', '');
        Observer.Verify();
    end;
}
