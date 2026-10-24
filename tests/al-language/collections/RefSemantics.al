// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74616
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List and Dictionary copy versus reference: assignment, by-value and var parameters, return values, Clear, foreach while modifying.
// BC versions: 29 (27 and 28 by CI)

codeunit 74616 "LT ClT Ref Semantics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddByValue(L: List of [Integer])
    begin
        L.Add(99);
    end;

    local procedure AddByVar(var L: List of [Integer])
    begin
        L.Add(98);
    end;

    local procedure ReplaceByValue(L: List of [Integer])
    var
        Fresh: List of [Integer];
    begin
        Fresh.Add(1);
        L := Fresh;
    end;

    local procedure ReplaceByVar(var L: List of [Integer])
    var
        Fresh: List of [Integer];
    begin
        Fresh.Add(1);
        L := Fresh;
    end;

    local procedure ClearByValue(L: List of [Integer])
    begin
        Clear(L);
    end;

    local procedure ClearByVar(var L: List of [Integer])
    begin
        Clear(L);
    end;

    local procedure Returned(): List of [Integer]
    var
        R: List of [Integer];
    begin
        R.Add(1);
        R.Add(2);
        exit(R);
    end;

    local procedure DictByValue(D: Dictionary of [Text, Integer])
    begin
        D.Add('byvalue', 1);
    end;

    local procedure DictByVar(var D: Dictionary of [Text, Integer])
    begin
        D.Add('byvar', 1);
    end;

    local procedure DictReplaceByValue(D: Dictionary of [Text, Integer])
    var
        Fresh: Dictionary of [Text, Integer];
    begin
        Fresh.Add('fresh', 1);
        D := Fresh;
    end;

    local procedure DictReplaceByVar(var D: Dictionary of [Text, Integer])
    var
        Fresh: Dictionary of [Text, Integer];
    begin
        Fresh.Add('fresh', 1);
        D := Fresh;
    end;

    [Test]
    procedure List_Assignment()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
    begin
        A.Add(1);
        B := A;
        B.Add(2);
        Observer.Observe('a count after b add', Format(A.Count()));
        Observer.Observe('b count', Format(B.Count()));
        A.Add(3);
        Observer.Observe('b count after a add', Format(B.Count()));
        Clear(A);
        Observer.Observe('a count after clear a', Format(A.Count()));
        Observer.Observe('b count after clear a', Format(B.Count()));
        Observer.Expect('a count after b add', '2');
        Observer.Expect('b count', '2');
        Observer.Expect('b count after a add', '3');
        Observer.Expect('a count after clear a', '0');
        Observer.Expect('b count after clear a', '3');
        Observer.Verify();
    end;

    [Test]
    procedure List_AssignmentFromUninitialised()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
    begin
        B := A;
        B.Add(1);
        Observer.Observe('a count after b add', Format(A.Count()));
        A.Add(2);
        Observer.Observe('b count after a add', Format(B.Count()));
        Observer.Expect('a count after b add', '1');
        Observer.Expect('b count after a add', '2');
        Observer.Verify();
    end;

    [Test]
    procedure List_Parameters()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
    begin
        A.Add(1);
        AddByValue(A);
        Observer.Observe('after by value add', Format(A.Count()));
        AddByVar(A);
        Observer.Observe('after var add', Format(A.Count()));
        ReplaceByValue(A);
        Observer.Observe('after by value replace', Format(A.Count()));
        ReplaceByVar(A);
        Observer.Observe('after var replace', Format(A.Count()));
        A.Add(5);
        ClearByValue(A);
        Observer.Observe('after by value clear', Format(A.Count()));
        ClearByVar(A);
        Observer.Observe('after var clear', Format(A.Count()));
        Observer.Expect('after by value add', '2');
        Observer.Expect('after var add', '3');
        Observer.Expect('after by value replace', '3');
        Observer.Expect('after var replace', '1');
        Observer.Expect('after by value clear', '2');
        Observer.Expect('after var clear', '0');
        Observer.Verify();
    end;

    [Test]
    procedure List_ReturnValue()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
    begin
        A := Returned();
        B := Returned();
        A.Add(3);
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b independent', Format(B.Count()));
        Observer.Observe('direct call count', Format(Returned().Count()));
        Observer.Expect('a', '3');
        Observer.Expect('b independent', '2');
        Observer.Expect('direct call count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure List_CopyViaGetRange()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
    begin
        A.Add(1);
        A.Add(2);
        B := A.GetRange(1, A.Count());
        B.Add(3);
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b', Format(B.Count()));
        Observer.Expect('a', '2');
        Observer.Expect('b', '3');
        Observer.Verify();
    end;

    [Test]
    procedure List_CopyViaAddRange()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
    begin
        A.Add(1);
        B.AddRange(A);
        B.Add(3);
        A.Add(4);
        Observer.Observe('a', Format(A.Count()));
        Observer.Observe('b', Format(B.Count()));
        Observer.Expect('a', '2');
        Observer.Expect('b', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_Assignment()
    var
        Observer: Codeunit "Probe Observer";
        A: Dictionary of [Text, Integer];
        B: Dictionary of [Text, Integer];
    begin
        A.Add('a', 1);
        B := A;
        B.Add('b', 2);
        Observer.Observe('a count', Format(A.Count()));
        A.Set('a', 10);
        Observer.Observe('b a value', Format(B.Get('a')));
        Observer.Expect('a count', '2');
        Observer.Expect('b a value', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_Parameters()
    var
        Observer: Codeunit "Probe Observer";
        A: Dictionary of [Text, Integer];
    begin
        DictByValue(A);
        Observer.Observe('after by value add', Format(A.Count()));
        DictByVar(A);
        Observer.Observe('after var add', Format(A.Count()));
        DictReplaceByValue(A);
        Observer.Observe('after by value replace', Format(A.Count()));
        Observer.Observe('has fresh', Format(A.ContainsKey('fresh')));
        DictReplaceByVar(A);
        Observer.Observe('after var replace', Format(A.Count()));
        Observer.Observe('has fresh', Format(A.ContainsKey('fresh')));
        Observer.Expect('after by value add', '1');
        Observer.Expect('after var add', '2');
        Observer.Expect('after by value replace', '2');
        Observer.Expect('has fresh', 'No');
        Observer.Expect('after var replace', '1');
        Observer.Expect('has fresh', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_KeysValuesAreCopies()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        K: List of [Text];
        V: List of [Integer];
    begin
        D.Add('a', 1);
        K := D.Keys();
        V := D.Values();
        K.Add('zzz');
        V.Add(5);
        Observer.Observe('dict count', Format(D.Count()));
        D.Add('b', 2);
        Observer.Observe('keys snapshot count', Format(K.Count()));
        Observer.Observe('values snapshot count', Format(V.Count()));
        Observer.Observe('fresh keys count', Format(D.Keys().Count()));
        Observer.Expect('dict count', '1');
        Observer.Expect('keys snapshot count', '2');
        Observer.Expect('values snapshot count', '2');
        Observer.Expect('fresh keys count', '2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddWhileIterating(var L: List of [Integer]; var Visited: Text)
    var
        X: Integer;
        Guard: Integer;
    begin
        foreach X in L do begin
            Visited += Format(X) + ',';
            Guard += 1;
            if Guard < 10 then
                L.Add(X + 10);
        end;
    end;

    [TryFunction]
    local procedure TryRemoveWhileIterating(var L: List of [Integer]; var Visited: Text)
    var
        X: Integer;
    begin
        foreach X in L do begin
            Visited += Format(X) + ',';
            if L.Count() > 0 then
                L.RemoveAt(1);
        end;
    end;

    [TryFunction]
    local procedure TrySetWhileIterating(var L: List of [Integer]; var Visited: Text)
    var
        X: Integer;
    begin
        foreach X in L do begin
            Visited += Format(X) + ',';
            L.Set(3, 30);
        end;
    end;

    [TryFunction]
    local procedure TryInsertWhileIterating(var L: List of [Integer]; var Visited: Text)
    var
        X: Integer;
        Guard: Integer;
    begin
        foreach X in L do begin
            Visited += Format(X) + ',';
            Guard += 1;
            if Guard < 10 then
                L.Insert(1, 0);
        end;
    end;

    [Test]
    procedure Foreach_ListAddWhileIterating()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Visited: Text;
    begin
        L.Add(1);
        L.Add(2);
        Observer.Observe('ok', Format(TryAddWhileIterating(L, Visited)));
        Observer.ObserveError('add while iterating');
        Observer.Observe('visited', Visited);
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('add while iterating|text', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('add while iterating|code', 'AL:InvalidOperation');
        Observer.Expect('visited', '1,');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ListRemoveWhileIterating()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Visited: Text;
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        Observer.Observe('ok', Format(TryRemoveWhileIterating(L, Visited)));
        Observer.ObserveError('remove while iterating');
        Observer.Observe('visited', Visited);
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('remove while iterating|text', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('remove while iterating|code', 'AL:InvalidOperation');
        Observer.Expect('visited', '1,');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ListSetWhileIterating()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Visited: Text;
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        Observer.Observe('ok', Format(TrySetWhileIterating(L, Visited)));
        Observer.ObserveError('set while iterating');
        Observer.Observe('visited', Visited);
        Observer.Observe('third', Format(L.Get(3)));
        Observer.Expect('ok', 'No');
        Observer.Expect('set while iterating|text', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('set while iterating|code', 'AL:InvalidOperation');
        Observer.Expect('visited', '1,');
        Observer.Expect('third', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ListInsertWhileIterating()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Visited: Text;
    begin
        L.Add(1);
        L.Add(2);
        Observer.Observe('ok', Format(TryInsertWhileIterating(L, Visited)));
        Observer.ObserveError('insert while iterating');
        Observer.Observe('visited', Visited);
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('insert while iterating|text', 'Collection was modified; enumeration operation may not execute.');
        Observer.Expect('insert while iterating|code', 'AL:InvalidOperation');
        Observer.Expect('visited', '1,');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ListLoopVarAssign()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        X: Integer;
        Visited: Text;
    begin
        L.Add(1);
        L.Add(2);
        foreach X in L do begin
            Visited += Format(X) + ',';
            X := 100;
        end;
        Observer.Observe('visited', Visited);
        Observer.Observe('list unchanged', Format(L.Get(1)) + ',' + Format(L.Get(2)));
        Observer.Observe('x after loop', Format(X));
        Observer.Expect('visited', '1,2,');
        Observer.Expect('list unchanged', '1,2');
        Observer.Expect('x after loop', '100');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_EmptyAndOrder()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        T: Text;
        Visited: Text;
    begin
        foreach T in L do
            Visited += 'x';
        Observer.Observe('empty loop', Visited);
        L.Add('b');
        L.Add('a');
        L.Add('c');
        foreach T in L do
            Visited += T;
        Observer.Observe('order', Visited);
        Observer.Observe('t after', T);
        Observer.Expect('empty loop', '');
        Observer.Expect('order', 'bac');
        Observer.Expect('t after', 'c');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_DictionaryModify()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        K: Text;
        Visited: Text;
    begin
        D.Add('a', 1);
        D.Add('b', 2);
        D.Add('c', 3);
        foreach K in D.Keys() do begin
            Visited += K;
            D.Set(K, D.Get(K) * 10);
        end;
        Observer.Observe('keys snapshot allows set', Visited);
        Observer.Observe('b', Format(D.Get('b')));
        Clear(Visited);
        foreach K in D.Keys() do begin
            Visited += K;
            D.Remove(K);
        end;
        Observer.Observe('keys snapshot allows remove', Visited);
        Observer.Observe('count', Format(D.Count()));
        Observer.Expect('keys snapshot allows set', 'abc');
        Observer.Expect('b', '20');
        Observer.Expect('keys snapshot allows remove', 'abc');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_NestedSameList()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        X: Integer;
        Y: Integer;
        Pairs: Integer;
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        foreach X in L do
            foreach Y in L do
                Pairs += 1;
        Observer.Observe('pairs', Format(Pairs));
        Observer.Expect('pairs', '9');
        Observer.Verify();
    end;
    // Writer PW: trust-refusals probe list "read-only List methods other than IndexOf inside foreach" (only IndexOf is pinned there,
    // misc/lt-u-obsolete-pending/UObsoletePending.al:35-36). One method per loop over the list it reads; Set with the same value and
    // Set with another value for comparison.
    [TryFunction]
    local procedure PwTryReadWhileIterating(var L: List of [Integer]; Which: Text; var Visited: Text)
    var
        X: Integer;
        Part: List of [Integer];
        N: Integer;
    begin
        foreach X in L do begin
            Visited += Format(X) + ',';
            case Which of
                'Count':
                    N := L.Count();
                'Get':
                    N := L.Get(1);
                'GetVar':
                    if L.Get(1, N) then;
                'Contains':
                    if L.Contains(2) then;
                'IndexOf':
                    N := L.IndexOf(X);
                'LastIndexOf':
                    N := L.LastIndexOf(X);
                'GetRange':
                    Part := L.GetRange(1, 2);
                'SetSame':
                    L.Set(1, L.Get(1));
                'SetOther':
                    L.Set(3, 99);
            end;
        end;
    end;

    local procedure PwRead(Which: Text): Text
    var
        L: List of [Integer];
        Visited: Text;
        Result: Text;
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        ClearLastError();
        if PwTryReadWhileIterating(L, Which, Visited) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result + ' visited=' + Visited + ' last=' + Format(L.Get(3)));
    end;

    [Test]
    procedure PW_Foreach_ListReadsWhileIterating()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Count', PwRead('Count'));
        Observer.Observe('Get', PwRead('Get'));
        Observer.Observe('GetVar', PwRead('GetVar'));
        Observer.Observe('Contains', PwRead('Contains'));
        Observer.Observe('IndexOf', PwRead('IndexOf'));
        Observer.Observe('LastIndexOf', PwRead('LastIndexOf'));
        Observer.Observe('GetRange', PwRead('GetRange'));
        Observer.Observe('SetSame', PwRead('SetSame'));
        Observer.Observe('SetOther', PwRead('SetOther'));
        Observer.Expect('Count', 'ok visited=1,2,3, last=3');
        Observer.Expect('Get', 'ok visited=1,2,3, last=3');
        Observer.Expect('GetVar', 'ok visited=1,2,3, last=3');
        Observer.Expect('Contains', 'ok visited=1,2,3, last=3');
        Observer.Expect('IndexOf', 'ok visited=1,2,3, last=3');
        Observer.Expect('LastIndexOf', 'ok visited=1,2,3, last=3');
        Observer.Expect('GetRange', 'ok visited=1,2,3, last=3');
        Observer.Expect('SetSame', 'error:Collection was modified; enumeration operation may not execute.|AL:InvalidOperation visited=1, last=3');
        Observer.Expect('SetOther', 'error:Collection was modified; enumeration operation may not execute.|AL:InvalidOperation visited=1, last=99');
        Observer.Verify();
    end;

    // Writer RW (al-runner issue 5810): the reporter's shape. The foreach runs in another codeunit over a by-value List parameter and
    // passes the list by value to a procedure that reads it with Count and Get(i); and the same loop adding through the by-value parameter.
    [Test]
    procedure RW_Foreach_ReadAndAddThroughByValueParam()
    var
        Observer: Codeunit "Probe Observer";
        LoadCheck: Codeunit "LT RW List Load Check";
        Starts: List of [Integer];
        Visited: Text;
    begin
        Starts.Add(10);
        Starts.Add(20);
        Starts.Add(30);
        Observer.Observe('points above capacity', Format(LoadCheck.PointsAboveCapacity(Starts, 1)));
        Observer.Observe('count after read', Format(Starts.Count()));
        ClearLastError();
        Observer.Observe('add ok', Format(LoadCheck.TryAddThroughByValueParam(Starts, Visited)));
        Observer.Observe('add visited', Visited);
        Observer.Observe('add error', GetLastErrorText());
        Observer.Observe('add code', GetLastErrorCode());
        Observer.Observe('count after add', Format(Starts.Count()));
        ClearLastError();
        Observer.Finish();
    end;
}
