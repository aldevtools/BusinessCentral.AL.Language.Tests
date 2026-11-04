// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: LT RcA tables and seed codeunit in RcAObjects.al, Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71501 "LT RcA Iterate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seed: Codeunit "LT RcA Seed";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure FindFirst_FindLast_Basic()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('first', Format(R.FindFirst()));
        Observer.Observe('firstNo', Format(R.No));
        Observer.Observe('last', Format(R.FindLast()));
        Observer.Observe('lastNo', Format(R.No));
        R.SetRange(No, 25, 65);
        Observer.Observe('rangeFirst', Format(R.FindFirst()));
        Observer.Observe('rangeFirstNo', Format(R.No));
        Observer.Observe('rangeLast', Format(R.FindLast()));
        Observer.Observe('rangeLastNo', Format(R.No));
        R.SetRange(No, 1000);
        Observer.Observe('noneFirst', Format(R.FindFirst()));
        Observer.Observe('noneLast', Format(R.FindLast()));
        Observer.Observe('noneFirstNo', Format(R.No));
        Observer.Expect('first', 'Yes');
        Observer.Expect('firstNo', '10');
        Observer.Expect('last', 'Yes');
        Observer.Expect('lastNo', '100');
        Observer.Expect('rangeFirst', 'Yes');
        Observer.Expect('rangeFirstNo', '30');
        Observer.Expect('rangeLast', 'Yes');
        Observer.Expect('rangeLastNo', '60');
        Observer.Expect('noneFirst', 'No');
        Observer.Expect('noneLast', 'No');
        Observer.Expect('noneFirstNo', '60');
        Observer.Verify();
    end;

    [Test]
    procedure FindFirst_Empty_Table_Error_Text()
    var
        R: Record "LT RcA Main";
    begin
        R.DeleteAll();
        Observer.Observe('first', Format(R.FindFirst()));
        Observer.Observe('last', Format(R.FindLast()));
        Observer.Observe('set', Format(R.FindSet()));
        Observer.Observe('setUpdate', Format(R.FindSet(true)));
        Observer.Observe('find', Format(R.Find('-')));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('isEmpty', Format(R.IsEmpty()));
        Observer.Expect('first', 'No');
        Observer.Expect('last', 'No');
        Observer.Expect('set', 'No');
        Observer.Expect('setUpdate', 'No');
        Observer.Expect('find', 'No');
        Observer.Expect('count', '0');
        Observer.Expect('isEmpty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FindFirst_Respects_Key_And_Filter()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        Observer.Observe('firstByName', Format(R.FindFirst()));
        Observer.Observe('firstByNameNo', Format(R.No));
        Observer.Observe('firstByNameName', R.Name);
        Observer.Observe('lastByName', Format(R.FindLast()));
        Observer.Observe('lastByNameName', R.Name);
        R.SetCurrentKey(Amt);
        R.Ascending(false);
        Observer.Observe('firstDesc', Format(R.FindFirst()));
        Observer.Observe('firstDescNo', Format(R.No));
        Observer.Observe('lastDesc', Format(R.FindLast()));
        Observer.Observe('lastDescNo', Format(R.No));
        Observer.Expect('firstByName', 'Yes');
        Observer.Expect('firstByNameNo', '100');
        Observer.Expect('firstByNameName', 'N1');
        Observer.Expect('lastByName', 'Yes');
        Observer.Expect('lastByNameName', 'N9');
        Observer.Expect('firstDesc', 'Yes');
        Observer.Expect('firstDescNo', '100');
        Observer.Expect('lastDesc', 'Yes');
        Observer.Expect('lastDescNo', '10');
        Observer.Verify();
    end;

    [Test]
    procedure FindSet_Iteration()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        if R.FindSet() then
            repeat
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('all', Log);
        Observer.Observe('nextAtEnd', Format(R.Next()));
        Observer.Observe('noAtEnd', Format(R.No));
        Observer.Observe('nextAtEndAgain', Format(R.Next()));
        Observer.Expect('all', '10,20,30,40,50,60,70,80,90,100,');
        Observer.Expect('nextAtEnd', '0');
        Observer.Expect('noAtEnd', '100');
        Observer.Expect('nextAtEndAgain', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FindSet_ForUpdate_Modify_While_Iterating()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetRange(No, 20, 60);
        if R.FindSet(true) then
            repeat
                R.Amt := R.No;
                R.Modify();
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('iterated', Log);
        R.Reset();
        R.SetRange(Amt, 20, 60);
        Observer.Observe('modifiedCount', Format(R.Count()));
        Observer.Expect('iterated', '20,30,40,50,60,');
        Observer.Expect('modifiedCount', '5');
        Observer.Verify();
    end;

    [Test]
    procedure FindSet_ForUpdate_Changing_Key_Field_Of_Filtered_Set()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetRange(Name, 'N1', 'N5');
        if R.FindSet(true) then
            repeat
                Log += R.Name + ',';
                R.Tx := 'seen';
                R.Modify();
            until R.Next() = 0;
        Observer.Observe('iterated', Log);
        R.Reset();
        R.SetRange(Tx, 'seen');
        Observer.Observe('seen', Format(R.Count()));
        Observer.Expect('iterated', 'N10,N5,N4,N3,N2,N1,');
        Observer.Expect('seen', '6');
        Observer.Verify();
    end;

    [Test]
    procedure FindSet_Both_Args()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('set', Format(R.FindSet()));
        Observer.Observe('setNo', Format(R.No));
        Observer.Observe('setTrue', Format(R.FindSet(true)));
        Observer.Observe('setTrueNo', Format(R.No));
        Observer.Observe('setFalse', Format(R.FindSet(false)));
        Observer.Observe('setFalseNo', Format(R.No));
        Observer.Expect('set', 'Yes');
        Observer.Expect('setNo', '10');
        Observer.Expect('setTrue', 'Yes');
        Observer.Expect('setTrueNo', '10');
        Observer.Expect('setFalse', 'Yes');
        Observer.Expect('setFalseNo', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Steps_Positive()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.FindFirst();
        Observer.Observe('next1', Format(R.Next()));
        Observer.Observe('next1No', Format(R.No));
        Observer.Observe('next2', Format(R.Next(2)));
        Observer.Observe('next2No', Format(R.No));
        Observer.Observe('next0', Format(R.Next(0)));
        Observer.Observe('next0No', Format(R.No));
        Observer.Observe('next3', Format(R.Next(3)));
        Observer.Observe('next3No', Format(R.No));
        Observer.Observe('nextTooMany', Format(R.Next(10)));
        Observer.Observe('nextTooManyNo', Format(R.No));
        Observer.Observe('nextAtEnd', Format(R.Next(1)));
        Observer.Observe('nextAtEndNo', Format(R.No));
        Observer.Expect('next1', '1');
        Observer.Expect('next1No', '20');
        Observer.Expect('next2', '2');
        Observer.Expect('next2No', '40');
        Observer.Expect('next0', '0');
        Observer.Expect('next0No', '40');
        Observer.Expect('next3', '3');
        Observer.Expect('next3No', '70');
        Observer.Expect('nextTooMany', '3');
        Observer.Expect('nextTooManyNo', '100');
        Observer.Expect('nextAtEnd', '0');
        Observer.Expect('nextAtEndNo', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Steps_Negative()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.FindLast();
        Observer.Observe('prev1', Format(R.Next(-1)));
        Observer.Observe('prev1No', Format(R.No));
        Observer.Observe('prev3', Format(R.Next(-3)));
        Observer.Observe('prev3No', Format(R.No));
        Observer.Observe('prevTooMany', Format(R.Next(-20)));
        Observer.Observe('prevTooManyNo', Format(R.No));
        R.FindFirst();
        Observer.Observe('prevAtStart', Format(R.Next(-1)));
        Observer.Observe('prevAtStartNo', Format(R.No));
        Observer.Expect('prev1', '-1');
        Observer.Expect('prev1No', '90');
        Observer.Expect('prev3', '-3');
        Observer.Expect('prev3No', '60');
        Observer.Expect('prevTooMany', '-5');
        Observer.Expect('prevTooManyNo', '10');
        Observer.Expect('prevAtStart', '0');
        Observer.Expect('prevAtStartNo', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Without_Current_Record()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        Observer.Observe('freshNext', Format(R.Next()));
        Observer.Observe('freshNo', Format(R.No));
        R.No := 35;
        Observer.Observe('keyedNext', Format(R.Next()));
        Observer.Observe('keyedNo', Format(R.No));
        R.No := 35;
        Observer.Observe('keyedPrev', Format(R.Next(-1)));
        Observer.Observe('keyedPrevNo', Format(R.No));
        Observer.Expect('freshNext', '1');
        Observer.Expect('freshNo', '10');
        Observer.Expect('keyedNext', '1');
        Observer.Expect('keyedNo', '40');
        Observer.Expect('keyedPrev', '-1');
        Observer.Expect('keyedPrevNo', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Next_After_Filtered_FindFirst()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.SetFilter(No, '30|50|70');
        R.FindFirst();
        Observer.Observe('n1', Format(R.Next()));
        Observer.Observe('n1No', Format(R.No));
        Observer.Observe('n2', Format(R.Next()));
        Observer.Observe('n2No', Format(R.No));
        Observer.Observe('n3', Format(R.Next()));
        Observer.Observe('n3No', Format(R.No));
        Observer.Observe('p1', Format(R.Next(-1)));
        Observer.Observe('p1No', Format(R.No));
        Observer.Expect('n1', '1');
        Observer.Expect('n1No', '50');
        Observer.Expect('n2', '1');
        Observer.Expect('n2No', '70');
        Observer.Expect('n3', '0');
        Observer.Expect('n3No', '70');
        Observer.Expect('p1', '-1');
        Observer.Expect('p1No', '50');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Descending()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.Ascending(false);
        Observer.Observe('isAsc', Format(R.Ascending()));
        if R.FindSet() then
            repeat
                Log += Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('descIter', Log);
        R.FindFirst();
        Observer.Observe('firstNo', Format(R.No));
        Observer.Observe('prev', Format(R.Next(-1)));
        Observer.Observe('prevNo', Format(R.No));
        Observer.Expect('isAsc', 'No');
        Observer.Expect('descIter', '100,90,80,70,60,50,40,30,20,10,');
        Observer.Expect('firstNo', '100');
        Observer.Expect('prev', '0');
        Observer.Expect('prevNo', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Record_Modified_Or_Deleted_Underneath()
    var
        R: Record "LT RcA Main";
        Other: Record "LT RcA Main";
    begin
        Seed.Main();
        R.FindFirst();
        Other.Get(20);
        Other.Delete();
        Observer.Observe('nextSkipsDeleted', Format(R.Next()));
        Observer.Observe('nextNo', Format(R.No));
        R.Get(30);
        Other.Get(30);
        Other.Delete();
        Observer.Observe('nextAfterOwnDeleted', Format(R.Next()));
        Observer.Observe('nextAfterNo', Format(R.No));
        Observer.Expect('nextSkipsDeleted', '1');
        Observer.Expect('nextNo', '30');
        Observer.Expect('nextAfterOwnDeleted', '1');
        Observer.Expect('nextAfterNo', '40');
        Observer.Verify();
    end;

    [Test]
    procedure Next_With_Different_CurrentKey()
    var
        R: Record "LT RcA Main";
        Log: Text;
    begin
        Seed.Main();
        R.SetCurrentKey(Name);
        R.SetRange(Name, 'N1', 'N4');
        if R.FindSet() then
            repeat
                Log += R.Name + '/' + Format(R.No) + ',';
            until R.Next() = 0;
        Observer.Observe('byName', Log);
        Observer.Expect('byName', 'N1/100,N10/10,N2/90,N3/80,N4/70,');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Large_Steps_And_Min_Max()
    var
        R: Record "LT RcA Main";
    begin
        Seed.Main();
        R.FindFirst();
        Observer.Observe('big', Format(R.Next(2147483647)));
        Observer.Observe('bigNo', Format(R.No));
        R.FindLast();
        Observer.Observe('small', Format(R.Next(-2147483647)));
        Observer.Observe('smallNo', Format(R.No));
        Observer.Expect('big', '9');
        Observer.Expect('bigNo', '100');
        Observer.Expect('small', '-9');
        Observer.Expect('smallNo', '10');
        Observer.Verify();
    end;

    // Corpus issue 668 item 27 (writer BQ): rows inserted inside a running loop (docs: Find uses paging, FindSet reads the rows at once).
    // LT RcA Main holds No 10..100; the loop inserts No + 5 for every row it reads, starting at the first row, until it has read 30 rows.
    local procedure BqInsertWhileLooping(Mode: Integer): Text
    var
        R: Record "LT RcA Main";
        Added: Record "LT RcA Main";
        Seen: Text;
        Reads: Integer;
        Found: Boolean;
    begin
        Seed.Main();
        case Mode of
            1:
                Found := R.FindSet();
            2:
                Found := R.FindSet(true);
            3:
                Found := R.Find('-');
            4:
                Found := R.FindFirst();
        end;
        if Found then
            repeat
                Reads += 1;
                Seen += Format(R.No) + ' ';
                if R.No mod 10 = 0 then begin
                    Added.Init();
                    Added.No := R.No + 5;
                    Added.Insert();
                end;
            until (R.Next() = 0) or (Reads >= 30);
        exit(Seen + '| reads=' + Format(Reads));
    end;

    [Test]
    procedure Rows_Inserted_Inside_The_Loop_BQ()
    begin
        Observer.Observe('findSet', BqInsertWhileLooping(1));
        Observer.Observe('findSetForUpdate', BqInsertWhileLooping(2));
        Observer.Observe('findMinus', BqInsertWhileLooping(3));
        Observer.Observe('findFirst', BqInsertWhileLooping(4));
        Observer.Expect('findSet', '10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 | reads=20');
        Observer.Expect('findSetForUpdate', '10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 | reads=20');
        Observer.Expect('findMinus', '10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 | reads=20');
        Observer.Expect('findFirst', '10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 | reads=20');
        Observer.Verify();
    end;
}
