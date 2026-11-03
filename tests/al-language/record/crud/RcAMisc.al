// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71506 "LT RcA CountMark"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Count_IsEmpty_CountApprox()
    var
        R: Record "LT RcA Main";
    begin
        R.DeleteAll();
        Observer.Observe('emptyCount', Format(R.Count()));
        Observer.Observe('emptyIsEmpty', Format(R.IsEmpty()));
        Observer.Observe('emptyApprox', Format(R.CountApprox()));
        Seed.Main();
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('isEmpty', Format(R.IsEmpty()));
        Observer.Observe('approxIsPositive', Format(R.CountApprox() > 0));
        R.SetRange(No, 20, 40);
        Observer.Observe('countFiltered', Format(R.Count()));
        Observer.Observe('isEmptyFiltered', Format(R.IsEmpty()));
        R.SetRange(No, 1000);
        Observer.Observe('countNone', Format(R.Count()));
        Observer.Observe('isEmptyNone', Format(R.IsEmpty()));
        Observer.Expect('emptyCount', '0');
        Observer.Expect('emptyIsEmpty', 'Yes');
        Observer.Expect('emptyApprox', '0');
        Observer.Expect('count', '10');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('approxIsPositive', 'Yes');
        Observer.Expect('countFiltered', '3');
        Observer.Expect('isEmptyFiltered', 'No');
        Observer.Expect('countNone', '0');
        Observer.Expect('isEmptyNone', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Does_Not_Move_Current_Record()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(30);
        R.SetFilter(No, '<>30');
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('noAfterCount', Format(R.No));
        Observer.Observe('isEmpty', Format(R.IsEmpty()));
        Observer.Observe('noAfterIsEmpty', Format(R.No));
        Observer.Expect('count', '9');
        Observer.Expect('noAfterCount', '30');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('noAfterIsEmpty', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Count_With_Marks_And_Filter_Groups()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        R.Mark(true);
        R.Get(40);
        R.Mark(true);
        R.MarkedOnly(true);
        Observer.Observe('markedCount', Format(R.Count()));
        R.SetRange(No, 20);
        Observer.Observe('markedAndFiltered', Format(R.Count()));
        Observer.Observe('isEmptyMarked', Format(R.IsEmpty()));
        R.SetRange(No, 30);
        Observer.Observe('markedAndFilteredOut', Format(R.Count()));
        Observer.Observe('isEmptyMarkedOut', Format(R.IsEmpty()));
        Observer.Expect('markedCount', '2');
        Observer.Expect('markedAndFiltered', '1');
        Observer.Expect('isEmptyMarked', 'No');
        Observer.Expect('markedAndFilteredOut', '0');
        Observer.Expect('isEmptyMarkedOut', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Mark_Basics()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        Observer.Observe('notMarked', Format(R.Mark()));
        Observer.Observe('setMark', Format(R.Mark(true)));
        Observer.Observe('isMarked', Format(R.Mark()));
        Observer.Observe('setMarkAgain', Format(R.Mark(true)));
        R.Get(30);
        Observer.Observe('otherNotMarked', Format(R.Mark()));
        R.Get(20);
        Observer.Observe('markedAfterGet', Format(R.Mark()));
        Observer.Observe('unmark', Format(R.Mark(false)));
        Observer.Observe('afterUnmark', Format(R.Mark()));
        Observer.Observe('unmarkAgain', Format(R.Mark(false)));
        Observer.Expect('notMarked', 'No');
        Observer.Expect('setMark', 'Yes');
        Observer.Expect('isMarked', 'Yes');
        Observer.Expect('setMarkAgain', 'Yes');
        Observer.Expect('otherNotMarked', 'No');
        Observer.Expect('markedAfterGet', 'Yes');
        Observer.Expect('unmark', 'No');
        Observer.Expect('afterUnmark', 'No');
        Observer.Expect('unmarkAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_Iteration()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.Get(70);
        R.Mark(true);
        R.Get(20);
        R.Mark(true);
        R.Get(50);
        R.Mark(true);
        Observer.Observe('markedOnlyDefault', Format(R.MarkedOnly()));
        R.MarkedOnly(true);
        Observer.Observe('markedOnly', Format(R.MarkedOnly()));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('hasFilter', Format(R.HasFilter()));
        if R.FindSet() then
            repeat
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('iterated', Log);
        Observer.Observe('first', Format(R.FindFirst()));
        Observer.Observe('firstNo', Format(R.No));
        Observer.Observe('last', Format(R.FindLast()));
        Observer.Observe('lastNo', Format(R.No));
        R.MarkedOnly(false);
        Observer.Observe('allAgain', Format(R.Count()));
        Observer.Expect('markedOnlyDefault', 'No');
        Observer.Expect('markedOnly', 'Yes');
        Observer.Expect('count', '3');
        Observer.Expect('hasFilter', 'No');
        Observer.Expect('iterated', '20,50,70,');
        Observer.Expect('first', 'Yes');
        Observer.Expect('firstNo', '20');
        Observer.Expect('last', 'Yes');
        Observer.Expect('lastNo', '70');
        Observer.Expect('allAgain', '10');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_With_Find_Get_And_Order()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        R.Mark(true);
        R.Get(60);
        R.Mark(true);
        R.MarkedOnly(true);
        Observer.Observe('getOutsideMarked', Format(R.Get(30)));
        R.No := 30;
        Observer.Observe('findOutside', Format(R.Find('=')));
        R.No := 30;
        Observer.Observe('findGe', Format(R.Find('>=')));
        Observer.Observe('findGeNo', Format(R.No));
        R.No := 30;
        Observer.Observe('findLe', Format(R.Find('<=')));
        Observer.Observe('findLeNo', Format(R.No));
        R.SetCurrentKey(Name);
        R.FindFirst();
        Observer.Observe('firstByName', Format(R.No));
        Observer.Expect('getOutsideMarked', 'Yes');
        Observer.Expect('findOutside', 'No');
        Observer.Expect('findGe', 'Yes');
        Observer.Expect('findGeNo', '60');
        Observer.Expect('findLe', 'Yes');
        Observer.Expect('findLeNo', '20');
        Observer.Expect('firstByName', '60');
        Observer.Verify();
    end;

    [Test]
    procedure ClearMarks_And_Reset()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(20);
        R.Mark(true);
        R.Get(40);
        R.Mark(true);
        R.ClearMarks();
        Observer.Observe('afterClear', Format(R.Mark()));
        R.Get(20);
        Observer.Observe('afterClear20', Format(R.Mark()));
        R.Mark(true);
        R.MarkedOnly(true);
        R.ClearMarks();
        Observer.Observe('markedOnlyKept', Format(R.MarkedOnly()));
        Observer.Observe('countAfterClear', Format(R.Count()));
        R.MarkedOnly(false);
        R.Mark(true);
        R.Reset();
        Observer.Observe('markAfterReset', Format(R.Mark()));
        R.MarkedOnly(true);
        Observer.Observe('countAfterReset', Format(R.Count()));
        Observer.Expect('afterClear', 'No');
        Observer.Expect('afterClear20', 'No');
        Observer.Expect('markedOnlyKept', 'Yes');
        Observer.Expect('countAfterClear', '0');
        Observer.Expect('markAfterReset', 'No');
        Observer.Expect('countAfterReset', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Mark_Uses_Primary_Key_Of_Current_Values()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.No := 30;
        Observer.Observe('markByKeyOnly', Format(R.Mark(true)));
        R.Init();
        R.No := 30;
        Observer.Observe('stillMarked', Format(R.Mark()));
        R.No := 31;
        Observer.Observe('markNonexistent', Format(R.Mark(true)));
        R.MarkedOnly(true);
        Observer.Observe('count', Format(R.Count()));
        Observer.Expect('markByKeyOnly', 'Yes');
        Observer.Expect('stillMarked', 'Yes');
        Observer.Expect('markNonexistent', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Mark_Separate_Variables_Do_Not_Share()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.Get(20);
        A.Mark(true);
        B.Get(20);
        Observer.Observe('otherVar', Format(B.Mark()));
        B := A;
        Observer.Observe('assigned', Format(B.Mark()));
        B.Copy(A);
        Observer.Observe('copied', Format(B.Mark()));
        Observer.Expect('otherVar', 'No');
        Observer.Expect('assigned', 'No');
        Observer.Expect('copied', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Record_With_Filters_ShareTable()
    var
        A: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        A.SetRange(No, 20, 40);
        A.SetCurrentKey(Name);
        A.MarkedOnly(false);
        B.Copy(A);
        Observer.Observe('copyFilters', B.GetFilters());
        Observer.Observe('copyKey', B.CurrentKey());
        B.Reset();
        B := A;
        Observer.Observe('assignFilters', B.GetFilters());
        Observer.Expect('copyFilters', 'No: 20..40');
        Observer.Expect('copyKey', 'Name');
        Observer.Expect('assignFilters', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_Primary_Key()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(30);
        R.SetRecFilter();
        Observer.Observe('filter', R.GetFilter(No));
        Observer.Observe('filters', R.GetFilters());
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('otherFieldFilter', R.GetFilter(Name));
        R.Get(40);
        R.SetRecFilter();
        Observer.Observe('replaced', R.GetFilter(No));
        Observer.Expect('filter', '30');
        Observer.Expect('filters', 'No: 30');
        Observer.Expect('count', '1');
        Observer.Expect('otherFieldFilter', '');
        Observer.Expect('replaced', '40');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_Composite_And_Text_Keys()
    var
        M: Record "LT RcA Multi";
        T: Record "LT RcA TextKey";
        C: Record "LT RcA CodeKey";
        D: Record "LT RcA DateKey";
        B: Record "LT RcA BoolKey";
        E: Record "LT RcA EnumKey";
        O: Record "LT RcA OptKey";
        X: Record "LT RcA DecKey";
    begin
        Seed.Keys();
        M.Get('A', 2, DMY2Date(1, 1, 2020));
        M.SetRecFilter();
        Observer.Observe('multi', M.GetFilters());
        Observer.Observe('multiCount', Format(M.Count()));
        T.Get('abc ');
        T.SetRecFilter();
        Observer.Observe('text', T.GetFilters());
        Observer.Observe('textCount', Format(T.Count()));
        C.Get('abc');
        C.SetRecFilter();
        Observer.Observe('code', C.GetFilters());
        D.Get(0D);
        D.SetRecFilter();
        Observer.Observe('dateBlank', D.GetFilters());
        Observer.Observe('dateBlankCount', Format(D.Count()));
        B.Get(true);
        B.SetRecFilter();
        Observer.Observe('bool', B.GetFilters());
        E.Get(E.En::Five);
        E.SetRecFilter();
        Observer.Observe('enum', E.GetFilters());
        O.Get(O.Op::Gamma);
        O.SetRecFilter();
        Observer.Observe('option', O.GetFilters());
        X.Get(-2);
        X.SetRecFilter();
        Observer.Observe('decimal', X.GetFilters());
        Observer.Expect('multi', 'A: A, B: 2, C: 01/01/20');
        Observer.Expect('multiCount', '1');
        Observer.Expect('text', 'Tx: abc');
        Observer.Expect('textCount', '1');
        Observer.Expect('code', 'Cd: ABC');
        Observer.Expect('dateBlank', 'Dt: ''''');
        Observer.Expect('dateBlankCount', '1');
        Observer.Expect('bool', 'Bl: Yes');
        Observer.Expect('enum', 'En: Five');
        Observer.Expect('option', 'Op: Gamma');
        Observer.Expect('decimal', 'Dc: -2');
        Observer.Verify();
    end;

    [Test]
    procedure SetRecFilter_On_Uninitialized_Record_And_Keeps_Other_Filters()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRecFilter();
        Observer.Observe('uninit', R.GetFilters());
        Observer.Observe('uninitCount', Format(R.Count()));
        R.Reset();
        R.SetRange(Cd, 'C1');
        R.Get(10);
        R.SetRecFilter();
        Observer.Observe('otherFiltersAfter', R.GetFilters());
        Observer.Expect('uninit', 'No: 0');
        Observer.Expect('uninitCount', '0');
        Observer.Expect('otherFiltersAfter', 'No: 10, Cd: C1');
        Observer.Verify();
    end;
}

codeunit 71507 "LT RcA Position View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure GetPosition_Primary_Key()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.Get(30);
        Observer.Observe('pos', R.GetPosition());
        Observer.Observe('posNoFields', R.GetPosition(false));
        Observer.Observe('posFields', R.GetPosition(true));
        R.SetCurrentKey(Name);
        Observer.Observe('posKeyName', R.GetPosition());
        R.Init();
        Observer.Observe('posInit', R.GetPosition());
        Observer.Expect('pos', 'No=CONST(30)');
        Observer.Expect('posNoFields', 'Field1=0(30)');
        Observer.Expect('posFields', 'No=CONST(30)');
        Observer.Expect('posKeyName', 'No=CONST(30)');
        Observer.Expect('posInit', 'No=CONST(30)');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_Key_Shapes()
    var
        M: Record "LT RcA Multi";
        T: Record "LT RcA TextKey";
        C: Record "LT RcA CodeKey";
        D: Record "LT RcA DateKey";
        B: Record "LT RcA BoolKey";
        E: Record "LT RcA EnumKey";
        O: Record "LT RcA OptKey";
        X: Record "LT RcA DecKey";
    begin
        Seed.Keys();
        M.Get('A', 2, DMY2Date(1, 1, 2020));
        Observer.Observe('multi', M.GetPosition());
        T.Get('abc');
        Observer.Observe('text', T.GetPosition());
        T.Get('abc ');
        Observer.Observe('textTrailing', T.GetPosition());
        C.Get('X1');
        Observer.Observe('code', C.GetPosition());
        D.Get(DMY2Date(1, 2, 2021));
        Observer.Observe('date', D.GetPosition());
        D.Get(0D);
        Observer.Observe('dateBlank', D.GetPosition());
        B.Get(true);
        Observer.Observe('bool', B.GetPosition());
        E.Get(E.En::Nine);
        Observer.Observe('enum', E.GetPosition());
        O.Get(O.Op::Beta);
        Observer.Observe('option', O.GetPosition());
        X.Get(1.5);
        Observer.Observe('decimal', X.GetPosition());
        X.Get(-2);
        Observer.Observe('decimalNeg', X.GetPosition());
        Observer.Expect('multi', 'A=CONST(A),B=CONST(2),C=CONST(01/01/20)');
        Observer.Expect('text', 'Tx=CONST(abc)');
        Observer.Expect('textTrailing', 'Tx=CONST(abc)');
        Observer.Expect('code', 'Cd=CONST(X1)');
        Observer.Expect('date', 'Dt=CONST(02/01/21)');
        Observer.Expect('dateBlank', 'Dt=CONST()');
        Observer.Expect('bool', 'Bl=CONST(Yes)');
        Observer.Expect('enum', 'En=CONST(Nine)');
        Observer.Expect('option', 'Op=CONST(Beta)');
        Observer.Expect('decimal', 'Dc=CONST(1.5)');
        Observer.Expect('decimalNeg', 'Dc=CONST(-2)');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_Text_With_Special_Characters()
    var
        T: Record "LT RcA TextKey";
    begin
        T.DeleteAll();
        T.Tx := 'a,b';
        T.Insert();
        Observer.Observe('comma', T.GetPosition());
        T.Tx := 'a"b';
        T.Insert();
        Observer.Observe('quote', T.GetPosition());
        T.Tx := 'a(1)';
        T.Insert();
        Observer.Observe('paren', T.GetPosition());
        T.Tx := 'a(1),b';
        T.Insert();
        Observer.Observe('both', T.GetPosition());
        T.Tx := '';
        T.Insert();
        Observer.Observe('blank', T.GetPosition());
        Observer.Expect('comma', 'Tx=CONST(a,b)');
        Observer.Expect('quote', 'Tx=CONST(a"b)');
        Observer.Expect('paren', 'Tx=CONST("a(1)")');
        Observer.Expect('both', 'Tx=CONST("a(1),b")');
        Observer.Expect('blank', 'Tx=CONST()');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_Roundtrip()
    var
        R: Record "LT RcA Main";
        Other: Record "LT RcA Main";
        Pos: Text;
    begin
        Seed.Main();
        R.Get(40);
        Pos := R.GetPosition();
        Other.SetPosition(Pos);
        Observer.Observe('no', Format(Other.No));
        Observer.Observe('nameNotLoaded', Other.Name);
        Observer.Observe('find', Format(Other.Find()));
        Observer.Observe('nameAfterFind', Other.Name);
        Other.Init();
        Other.SetPosition(Pos);
        Observer.Observe('get', Format(Other.Get(Other.No)));
        Observer.Expect('no', '40');
        Observer.Expect('nameNotLoaded', '');
        Observer.Expect('find', 'Yes');
        Observer.Expect('nameAfterFind', 'N7');
        Observer.Expect('get', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_Different_Key_And_Invalid()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        R.Get(40);
        R.SetCurrentKey(Name);
        R.SetPosition(R.GetPosition());
        Observer.Observe('byName', Format(R.No) + '/' + R.Name);
        asserterror R.SetPosition('garbage');
        Observer.ObserveError('garbage');
        asserterror R.SetPosition('');
        Observer.ObserveError('empty');
        asserterror R.SetPosition('No=CONST(abc)');
        Observer.ObserveError('badValue');
        Observer.Expect('byName', '40/N7');
        Observer.Expect('garbage|text', 'Invalid expression of type: position.\garbage');
        Observer.Expect('garbage|code', 'DB:Ok');
        Observer.Expect('empty|text', ''''' is not a valid position specification for the LT RcA Main table. The position must contain all the primary key fields, in order, and only primary key fields.');
        Observer.Expect('empty|code', 'DB:Ok');
        Observer.Expect('badValue|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('badValue|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure SetPosition_Then_Next_And_Find()
    var
        R: Record "LT RcA Main";
        Pos: Text;
    begin
        Seed.Main();
        R.Get(40);
        Pos := R.GetPosition();
        R.Init();
        R.SetPosition(Pos);
        Observer.Observe('next', Format(R.Next()));
        Observer.Observe('nextNo', Format(R.No));
        R.SetPosition(Pos);
        Observer.Observe('prev', Format(R.Next(-1)));
        Observer.Observe('prevNo', Format(R.No));
        Observer.Expect('next', '1');
        Observer.Expect('nextNo', '50');
        Observer.Expect('prev', '-1');
        Observer.Expect('prevNo', '30');
        Observer.Verify();
    end;

    [Test]
    procedure GetView_SetView_Basics()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('none', R.GetView());
        Observer.Observe('noneNoFields', R.GetView(false));
        R.SetRange(No, 20, 40);
        Observer.Observe('range', R.GetView());
        Observer.Observe('rangeNoFields', R.GetView(false));
        R.SetCurrentKey(Name);
        R.Ascending(false);
        Observer.Observe('keyDesc', R.GetView());
        Observer.Observe('keyDescNoFields', R.GetView(false));
        R.SetFilter(Tx, 'Item*');
        Observer.Observe('twoFilters', R.GetView());
        R.Reset();
        R.SetCurrentKey(Cd, No);
        Observer.Observe('keyOnly', R.GetView());
        Observer.Expect('none', 'VERSION(1) SORTING(No)');
        Observer.Expect('noneNoFields', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('range', 'VERSION(1) SORTING(No) WHERE(No=FILTER(20..40))');
        Observer.Expect('rangeNoFields', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(20..40))');
        Observer.Expect('keyDesc', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(No=FILTER(20..40))');
        Observer.Expect('keyDescNoFields', 'VERSION(1) SORTING(Field2) ORDER(1) WHERE(Field1=1(20..40))');
        Observer.Expect('twoFilters', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(No=FILTER(20..40),Tx=FILTER(Item*))');
        Observer.Expect('keyOnly', 'VERSION(1) SORTING(Cd,No)');
        Observer.Verify();
    end;

    [Test]
    procedure GetView_Field_Types()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetRange(Amt, 1.5, 3);
        Observer.Observe('dec', R.GetView());
        R.Reset();
        R.SetRange(Dt, DMY2Date(1, 1, 2020));
        Observer.Observe('date', R.GetView());
        R.Reset();
        R.SetRange(Flag, true);
        Observer.Observe('bool', R.GetView());
        R.Reset();
        R.SetRange(Opt, R.Opt::Gamma);
        Observer.Observe('option', R.GetView());
        R.Reset();
        R.SetRange(En, R.En::Nine);
        Observer.Observe('enum', R.GetView());
        R.Reset();
        R.SetFilter(Cd, 'C1|C2');
        Observer.Observe('code', R.GetView());
        R.Reset();
        R.SetFilter(Tx, 'it''s');
        Observer.Observe('quote', R.GetView());
        R.Reset();
        R.SetRange(Tx, '');
        Observer.Observe('blank', R.GetView());
        Observer.Expect('dec', 'VERSION(1) SORTING(No) WHERE(Amt=FILTER(1.5..3))');
        Observer.Expect('date', 'VERSION(1) SORTING(No) WHERE(Dt=FILTER(2020-01-01))');
        Observer.Expect('bool', 'VERSION(1) SORTING(No) WHERE(Flag=FILTER(true))');
        Observer.Expect('option', 'VERSION(1) SORTING(No) WHERE(Opt=FILTER(Gamma))');
        Observer.Expect('enum', 'VERSION(1) SORTING(No) WHERE(En=FILTER(Nine))');
        Observer.Expect('code', 'VERSION(1) SORTING(No) WHERE(Cd=FILTER(C1|C2))');
        Observer.Expect('quote', 'VERSION(1) SORTING(No) WHERE(Tx=FILTER(it''s))');
        Observer.Expect('blank', 'VERSION(1) SORTING(No) WHERE(Tx=FILTER(''''))');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Roundtrip_And_Literal()
    var
        R: Record "LT RcA Main";
        Other: Record "LT RcA Main";
        V: Text;
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        R.Ascending(false);
        R.SetFilter(No, '20..60');
        R.SetRange(Cd, 'C1');
        V := R.GetView();
        Other.SetView(V);
        Observer.Observe('filters', Other.GetFilters());
        Observer.Observe('key', Other.CurrentKey());
        Observer.Observe('asc', Format(Other.Ascending()));
        Observer.Observe('count', Format(Other.Count()));
        Other.Reset();
        Other.SetView('SORTING(No) WHERE(No=FILTER(30..50))');
        Observer.Observe('literal', Other.GetFilters() + '|' + Other.CurrentKey());
        Observer.Observe('literalCount', Format(Other.Count()));
        Other.SetView('WHERE(Name=CONST(N5))');
        Observer.Observe('replaces', Other.GetFilters());
        Other.SetView('');
        Observer.Observe('emptyView', Other.GetFilters() + '|' + Format(Other.Count()));
        Other.SetView('SORTING(Amt) ORDER(Descending)');
        Observer.Observe('order', Other.CurrentKey() + '|' + Format(Other.Ascending()));
        Observer.Expect('filters', 'No: 20..60, Cd: C1');
        Observer.Expect('key', 'Name');
        Observer.Expect('asc', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('literal', 'No: 30..50|No');
        Observer.Expect('literalCount', '3');
        Observer.Expect('replaces', 'Name: N5');
        Observer.Expect('emptyView', '|10');
        Observer.Expect('order', 'Amt|No');
        Observer.Verify();
    end;

    // Corpus issue 668 item 11 (writer BQ): SetView('') after SetCurrentKey, Ascending(false) and filters in groups 0 and 2.
    [Test]
    procedure SetView_Empty_Key_Order_And_Filter_Groups_BQ()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        R.Ascending(false);
        R.SetRange(No, 20, 60);
        R.FilterGroup(2);
        R.SetRange(Cd, 'C1');
        R.FilterGroup(0);
        R.SetView('');
        Observer.Observe('key', R.CurrentKey());
        Observer.Observe('ascending', Format(R.Ascending()));
        Observer.Observe('group', Format(R.FilterGroup()));
        Observer.Observe('filters', R.GetFilters());
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('view', R.GetView());
        R.FilterGroup(2);
        Observer.Observe('group2Filter', R.GetFilter(Cd));
        R.FilterGroup(0);
        Observer.Expect('key', 'No');
        Observer.Expect('ascending', 'No');
        Observer.Expect('group', '0');
        Observer.Expect('filters', '');
        Observer.Expect('count', '4');
        Observer.Expect('view', 'VERSION(1) SORTING(No) ORDER(Descending)');
        Observer.Expect('group2Filter', 'C1');
        Observer.Verify();
    end;

    // Corpus issue 668 item 34 (writer BQ): GetPosition and GetView, a filtered loop, SetView and SetPosition again (microsoft/AL issue 5621:
    // "You cannot change the value of the SystemId field"), with the primary key, with a key that holds SystemId, and on a var parameter.
    // Rows of LT BQ Pos Row: 1..4, Grp 1, 1, 2, 2.
    local procedure BqSeedPos()
    var
        P: Record "LT BQ Pos Row";
        i: Integer;
    begin
        P.DeleteAll();
        for i := 1 to 4 do begin
            P.Init();
            P.Id := i;
            P.Grp := (i + 1) div 2;
            P.Name := 'p' + Format(i);
            // fixed SystemIds in Id order, so a sort on SystemId is deterministic (only the last byte differs)
            Evaluate(P.SystemId, '{00000000-0000-0000-0000-00000000000' + Format(i) + '}');
            P.Insert();
        end;
    end;

    [TryFunction]
    local procedure BqTryRestore(var P: Record "LT BQ Pos Row"; Pos: Text; View: Text)
    begin
        P.SetView(View);
        P.SetPosition(Pos);
    end;

    local procedure BqLoopAndRestore(var P: Record "LT BQ Pos Row"): Text
    var
        Pos: Text;
        View: Text;
        Result: Text;
    begin
        Pos := P.GetPosition();
        View := P.GetView();
        P.SetRange(Grp, 2);
        if P.FindSet() then
            repeat
            until P.Next() = 0;
        P.SetRange(Grp);
        if BqTryRestore(P, Pos, View) then begin
            Result := 'ok id=' + Format(P.Id) + ' filters=' + P.GetFilters() + ' key=' + P.CurrentKey();
            Result += ' find=' + Format(P.Find('=')) + ' name=' + P.Name;
        end else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // With a key that holds SystemId, which row Find('=') finds after SetPosition (and so the id and name) differed between runs: only
    // the outcome, the filters and the key are kept.
    local procedure BqNoFindPart(Result: Text): Text
    begin
        if (CopyStr(Result, 1, 3) <> 'ok ') or (StrPos(Result, ' find=') = 0) then
            exit(Result);
        exit('ok' + CopyStr(Result, StrPos(Result, ' filters='), StrPos(Result, ' find=') - StrPos(Result, ' filters=')));
    end;

    [Test]
    procedure SetPosition_After_Loop_And_SetView_BQ()
    var
        P: Record "LT BQ Pos Row";
    begin
        BqSeedPos();
        P.Get(2);
        Observer.Observe('primaryKey', BqLoopAndRestore(P));
        P.Reset();
        P.SetCurrentKey(Grp, SystemId);
        P.Get(3);
        Observer.Observe('position', P.GetPosition());
        Observer.Observe('systemIdKey', BqNoFindPart(BqLoopAndRestore(P)));
        P.Reset();
        P.SetCurrentKey(Grp, SystemId);
        P.SetRange(Grp, 1);
        P.FindFirst();
        Observer.Observe('systemIdKeyFiltered', BqNoFindPart(BqLoopAndRestore(P)));
        Observer.Expect('primaryKey', 'ok id=2 filters= key=Id find=Yes name=p2');
        Observer.Expect('position', 'Id=CONST(3)');
        Observer.Expect('systemIdKey', 'ok filters= key=Grp,System ID');
        Observer.Expect('systemIdKeyFiltered', 'ok filters=Grp: 1 key=Grp,System ID');
        Observer.Verify();
    end;
}

codeunit 71508 "LT RcA LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure AreFieldsLoaded_Default()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('freshName', Format(R.AreFieldsLoaded(Name)));
        R.Get(20);
        Observer.Observe('afterGetName', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('afterGetAll', Format(R.AreFieldsLoaded(No, Name, Cd, Amt, Dt, Flag, Opt, En, Tx, Big)));
        Observer.Expect('freshName', 'No');
        Observer.Expect('afterGetName', 'Yes');
        Observer.Expect('afterGetAll', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Limits_Loaded()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Name);
        R.Get(20);
        Observer.Observe('name', R.Name);
        Observer.Observe('nameLoaded', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('amtLoaded', Format(R.AreFieldsLoaded(Amt)));
        Observer.Observe('pkLoaded', Format(R.AreFieldsLoaded(No)));
        Observer.Observe('both', Format(R.AreFieldsLoaded(Name, Amt)));
        Observer.Observe('amtValue', Format(R.Amt));
        Observer.Observe('amtLoadedAfterRead', Format(R.AreFieldsLoaded(Amt)));
        Observer.Expect('name', 'N9');
        Observer.Expect('nameLoaded', 'Yes');
        Observer.Expect('amtLoaded', 'No');
        Observer.Expect('pkLoaded', 'Yes');
        Observer.Expect('both', 'No');
        Observer.Expect('amtValue', '3');
        Observer.Expect('amtLoadedAfterRead', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_With_FindSet_And_Next()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetLoadFields(Cd);
        R.SetRange(No, 20, 40);
        if R.FindSet() then
            repeat
                Log += R.Cd + '/' + Format(R.AreFieldsLoaded(Cd)) + '/' + Format(R.AreFieldsLoaded(Name)) + ',';
            until R.Next() = 0;
        Observer.Observe('iter', Log);
        R.FindFirst();
        Observer.Observe('firstLoadedCd', Format(R.AreFieldsLoaded(Cd)));
        Observer.Observe('firstLoadedTx', Format(R.AreFieldsLoaded(Tx)));
        R.FindLast();
        Observer.Observe('lastLoadedTx', Format(R.AreFieldsLoaded(Tx)));
        Observer.Expect('iter', 'C2/Yes/No,C0/Yes/No,C1/Yes/No,');
        Observer.Expect('firstLoadedCd', 'Yes');
        Observer.Expect('firstLoadedTx', 'No');
        Observer.Expect('lastLoadedTx', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AddLoadFields_Extends()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Name);
        R.AddLoadFields(Amt);
        R.Get(20);
        Observer.Observe('name', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('amt', Format(R.AreFieldsLoaded(Amt)));
        Observer.Observe('dt', Format(R.AreFieldsLoaded(Dt)));
        R.AddLoadFields(Dt);
        R.Get(20);
        Observer.Observe('dtAfterAdd', Format(R.AreFieldsLoaded(Dt)));
        Observer.Expect('name', 'Yes');
        Observer.Expect('amt', 'Yes');
        Observer.Expect('dt', 'No');
        Observer.Expect('dtAfterAdd', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AddLoadFields_Without_SetLoadFields()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.AddLoadFields(Name);
        R.Get(20);
        Observer.Observe('name', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('amt', Format(R.AreFieldsLoaded(Amt)));
        Observer.Observe('pk', Format(R.AreFieldsLoaded(No)));
        Observer.Expect('name', 'Yes');
        Observer.Expect('amt', 'Yes');
        Observer.Expect('pk', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Blank_Resets_To_All()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Name);
        R.SetLoadFields();
        R.Get(20);
        Observer.Observe('all', Format(R.AreFieldsLoaded(Amt, Name, Dt)));
        R.SetLoadFields(Name);
        R.Reset();
        R.Get(20);
        Observer.Observe('afterReset', Format(R.AreFieldsLoaded(Amt)));
        R.SetLoadFields(Name);
        R.Init();
        R.Get(20);
        Observer.Observe('afterInit', Format(R.AreFieldsLoaded(Amt)));
        R.SetLoadFields(Name);
        Clear(R);
        R.Get(20);
        Observer.Observe('afterClear', Format(R.AreFieldsLoaded(Amt)));
        Observer.Expect('all', 'Yes');
        Observer.Expect('afterReset', 'Yes');
        Observer.Expect('afterInit', 'Yes');
        Observer.Expect('afterClear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Value_Of_Unloaded_Field_And_Modify()
    var
        R: Record "LT RcA Main";
        V: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Name);
        R.Get(20);
        Observer.Observe('unloadedAmt', Format(R.Amt));
        R.Name := 'changed';
        R.Modify();
        V.Get(20);
        Observer.Observe('modifiedName', V.Name);
        Observer.Observe('amtPreserved', Format(V.Amt));
        Observer.Observe('txPreserved', V.Tx);
        Observer.Expect('unloadedAmt', '3');
        Observer.Expect('modifiedName', 'changed');
        Observer.Expect('amtPreserved', '3');
        Observer.Expect('txPreserved', 'Item 2');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Copy_And_Assignment()
    var
        R: Record "LT RcA Main";
        B: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Name);
        B.Copy(R);
        B.Get(20);
        Observer.Observe('copyLoadsOnlyName', Format(B.AreFieldsLoaded(Amt)));
        R.Get(20);
        B := R;
        Observer.Observe('assigned', Format(B.AreFieldsLoaded(Amt)));
        Observer.Observe('assignedName', Format(B.AreFieldsLoaded(Name)));
        Observer.Expect('copyLoadsOnlyName', 'No');
        Observer.Expect('assigned', 'No');
        Observer.Expect('assignedName', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Find_Variants()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetLoadFields(Tx);
        R.No := 30;
        R.Find();
        Observer.Observe('find', Format(R.AreFieldsLoaded(Tx)) + '/' + Format(R.AreFieldsLoaded(Amt)));
        R.No := 35;
        R.Find('>=');
        Observer.Observe('findGe', Format(R.AreFieldsLoaded(Tx)) + '/' + Format(R.AreFieldsLoaded(Amt)));
        Observer.Observe('txGe', R.Tx);
        R.Next();
        Observer.Observe('next', Format(R.AreFieldsLoaded(Tx)) + '/' + Format(R.AreFieldsLoaded(Amt)));
        Observer.Expect('find', 'Yes/No');
        Observer.Expect('findGe', 'Yes/No');
        Observer.Expect('txGe', 'Item 4');
        Observer.Expect('next', 'Yes/No');
        Observer.Verify();
    end;
}
