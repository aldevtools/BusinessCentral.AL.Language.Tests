// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own object 75262 (OVN Element Stores Tests)
// local object: a memberless Option array element that holds a value of an array with members is what is under test.
// Probe (al-runner issues 7994 and 8291, review of al-runner PR 8299; follow-up of OptionVarMemberlessWrites.al):
//   Cells: element stores into a by-value memberless array parameter (the caller's array has members First,Second,Third), a
//   local memberless array and a global memberless array filled by CopyArray from an array with those members, and a var
//   memberless array parameter. Store kinds: none (read), Evaluate(A[1], 'Third') with the result used, Clear(A[1]), Clear then
//   A[1] := 1, A[1] := an Option P,Q,R (R), A[1] := a memberless Option (2), A[1] := an Option with the caller's members
//   (Third), A[1] := 2, A[1] := A[2], A[2] := A[2] (A[2] holds Third). The var array only for A[1] := A[2] and A[2] := A[2];
//   the other store kinds into a var array are in OptionVarMemberlessWrites.al.
// Facts: Values are Format|ordinal. By-value memberless array: read Second|1; Evaluate('Third') Yes|Third|2; Clear First|0;
//   Clear then 1 Second|1; store of R (P,Q,R) Third|2; store of a memberless Option 2|2; store of Third Third|2; A[1] := 2
//   Third|2; A[1] := A[2] Third|2; A[2] := A[2] Third|2; the caller's array stays Second|1 and Third|2. Local and global
//   memberless arrays filled by CopyArray: the same, except Clear gives 0|0 and Clear then 1 gives 1|1 (the element loses the
//   names after Clear). Var memberless array: A[1] := A[2] Third|2, and the caller shows Third|2 and Third|2; A[2] := A[2]
//   Third|2, and the caller shows Second|1 and Third|2.
// BC versions: measured on 29.0 (local Windows BC tier). The local 27.5 and 28.5 legs did not run (host lock timeout on 28.5,
//   service unavailable on 27.5); the corpus CI run of the pull request measures them.
codeunit 75262 "OVN Element Stores Tests"
{
    Subtype = Test;

    var
        GlobalArr0: array[2] of Option;

    [Test]
    procedure ByValueMemberlessArray_ElementStores()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('read', ByValueStore(Arr, 0));
        Observer.Observe('evaluate Third', ByValueStore(Arr, 1));
        Observer.Observe('clear', ByValueStore(Arr, 2));
        Observer.Observe('clear then 1', ByValueStore(Arr, 3));
        Observer.Observe('store Option P,Q,R', ByValueStore(Arr, 4));
        Observer.Observe('store memberless Option', ByValueStore(Arr, 5));
        Observer.Observe('store same members', ByValueStore(Arr, 6));
        Observer.Observe('store integer 2', ByValueStore(Arr, 7));
        Observer.Observe('store A[2] into A[1]', ByValueStore(Arr, 8));
        Observer.Observe('store A[2] into itself', ByValueStore(Arr, 9));
        Observer.Observe('caller after', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('read', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('clear', 'First|0');
        Observer.Expect('clear then 1', 'Second|1');
        Observer.Expect('store Option P,Q,R', 'Third|2');
        Observer.Expect('store memberless Option', '2|2');
        Observer.Expect('store same members', 'Third|2');
        Observer.Expect('store integer 2', 'Third|2');
        Observer.Expect('store A[2] into A[1]', 'Third|2');
        Observer.Expect('store A[2] into itself', 'Third|2');
        Observer.Expect('caller after', 'Second|1#Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure LocalCopyArrayFilled_ElementStores()
    var
        Observer: Codeunit "Probe Observer";

    begin
        Observer.Observe('read', LocalCopyStore(0));
        Observer.Observe('evaluate Third', LocalCopyStore(1));
        Observer.Observe('clear', LocalCopyStore(2));
        Observer.Observe('clear then 1', LocalCopyStore(3));
        Observer.Observe('store Option P,Q,R', LocalCopyStore(4));
        Observer.Observe('store memberless Option', LocalCopyStore(5));
        Observer.Observe('store same members', LocalCopyStore(6));
        Observer.Observe('store integer 2', LocalCopyStore(7));
        Observer.Observe('store A[2] into A[1]', LocalCopyStore(8));
        Observer.Observe('store A[2] into itself', LocalCopyStore(9));
        Observer.Expect('read', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('clear', '0|0');
        Observer.Expect('clear then 1', '1|1');
        Observer.Expect('store Option P,Q,R', 'Third|2');
        Observer.Expect('store memberless Option', '2|2');
        Observer.Expect('store same members', 'Third|2');
        Observer.Expect('store integer 2', 'Third|2');
        Observer.Expect('store A[2] into A[1]', 'Third|2');
        Observer.Expect('store A[2] into itself', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalCopyArrayFilled_ElementStores()
    var
        Observer: Codeunit "Probe Observer";

    begin
        Observer.Observe('read', GlobalCopyStore(0));
        Observer.Observe('evaluate Third', GlobalCopyStore(1));
        Observer.Observe('clear', GlobalCopyStore(2));
        Observer.Observe('clear then 1', GlobalCopyStore(3));
        Observer.Observe('store Option P,Q,R', GlobalCopyStore(4));
        Observer.Observe('store memberless Option', GlobalCopyStore(5));
        Observer.Observe('store same members', GlobalCopyStore(6));
        Observer.Observe('store integer 2', GlobalCopyStore(7));
        Observer.Observe('store A[2] into A[1]', GlobalCopyStore(8));
        Observer.Observe('store A[2] into itself', GlobalCopyStore(9));
        Observer.Expect('read', 'Second|1');
        Observer.Expect('evaluate Third', 'Yes|Third|2');
        Observer.Expect('clear', '0|0');
        Observer.Expect('clear then 1', '1|1');
        Observer.Expect('store Option P,Q,R', 'Third|2');
        Observer.Expect('store memberless Option', '2|2');
        Observer.Expect('store same members', 'Third|2');
        Observer.Expect('store integer 2', 'Third|2');
        Observer.Expect('store A[2] into A[1]', 'Third|2');
        Observer.Expect('store A[2] into itself', 'Third|2');
        Observer.Verify();
    end;

    [Test]
    procedure VarMemberlessArray_ElementFromElement()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[2] of Option First,Second,Third;
    begin
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('store A[2] into A[1]', VarStore(Arr, 8));
        Observer.Observe('caller after A[1] := A[2]', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Arr[1] := Arr[1]::Second;
        Arr[2] := Arr[2]::Third;
        Observer.Observe('store A[2] into itself', VarStore(Arr, 9));
        Observer.Observe('caller after A[2] := A[2]', Format(Arr[1]) + '|' + Format(Arr[1], 0, 2) + '#' + Format(Arr[2]) + '|' + Format(Arr[2], 0, 2));
        Observer.Expect('store A[2] into A[1]', 'Third|2');
        Observer.Expect('caller after A[1] := A[2]', 'Third|2#Third|2');
        Observer.Expect('store A[2] into itself', 'Third|2');
        Observer.Expect('caller after A[2] := A[2]', 'Second|1#Third|2');
        Observer.Verify();
    end;

    local procedure ByValueStore(A: array[2] of Option; Kind: Integer): Text
    var
        Ok: Boolean;
        Prefix: Text;
        Idx: Integer;
        O: Option P,Q,R;
        M: Option;
        V: Option First,Second,Third;
    begin
        Idx := 1;
        case Kind of
            0:
                ;
            1:
                begin
                    Ok := Evaluate(A[1], 'Third');
                    Prefix := Format(Ok) + '|';
                end;
            2:
                begin
                    Clear(A[1]);
                end;
            3:
                begin
                    Clear(A[1]);
                    A[1] := 1;
                end;
            4:
                begin
                    O := O::R;
                    A[1] := O;
                end;
            5:
                begin
                    M := 2;
                    A[1] := M;
                end;
            6:
                begin
                    V := V::Third;
                    A[1] := V;
                end;
            7:
                begin
                    A[1] := 2;
                end;
            8:
                begin
                    A[1] := A[2];
                end;
            9:
                begin
                    A[2] := A[2];
                    Idx := 2;
                end;
        end;
        exit(Prefix + Format(A[Idx]) + '|' + Format(A[Idx], 0, 2));
    end;

    local procedure LocalCopyStore(Kind: Integer): Text
    var
        Src: array[2] of Option First,Second,Third;
        A: array[2] of Option;
        Ok: Boolean;
        Prefix: Text;
        Idx: Integer;
        O: Option P,Q,R;
        M: Option;
        V: Option First,Second,Third;
    begin
        Src[1] := Src[1]::Second;
        Src[2] := Src[2]::Third;
        CopyArray(A, Src, 1);
        Idx := 1;
        case Kind of
            0:
                ;
            1:
                begin
                    Ok := Evaluate(A[1], 'Third');
                    Prefix := Format(Ok) + '|';
                end;
            2:
                begin
                    Clear(A[1]);
                end;
            3:
                begin
                    Clear(A[1]);
                    A[1] := 1;
                end;
            4:
                begin
                    O := O::R;
                    A[1] := O;
                end;
            5:
                begin
                    M := 2;
                    A[1] := M;
                end;
            6:
                begin
                    V := V::Third;
                    A[1] := V;
                end;
            7:
                begin
                    A[1] := 2;
                end;
            8:
                begin
                    A[1] := A[2];
                end;
            9:
                begin
                    A[2] := A[2];
                    Idx := 2;
                end;
        end;
        exit(Prefix + Format(A[Idx]) + '|' + Format(A[Idx], 0, 2));
    end;

    local procedure GlobalCopyStore(Kind: Integer): Text
    var
        Src: array[2] of Option First,Second,Third;
        Ok: Boolean;
        Prefix: Text;
        Idx: Integer;
        O: Option P,Q,R;
        M: Option;
        V: Option First,Second,Third;
    begin
        Src[1] := Src[1]::Second;
        Src[2] := Src[2]::Third;
        Clear(GlobalArr0);
        CopyArray(GlobalArr0, Src, 1);
        Idx := 1;
        case Kind of
            0:
                ;
            1:
                begin
                    Ok := Evaluate(GlobalArr0[1], 'Third');
                    Prefix := Format(Ok) + '|';
                end;
            2:
                begin
                    Clear(GlobalArr0[1]);
                end;
            3:
                begin
                    Clear(GlobalArr0[1]);
                    GlobalArr0[1] := 1;
                end;
            4:
                begin
                    O := O::R;
                    GlobalArr0[1] := O;
                end;
            5:
                begin
                    M := 2;
                    GlobalArr0[1] := M;
                end;
            6:
                begin
                    V := V::Third;
                    GlobalArr0[1] := V;
                end;
            7:
                begin
                    GlobalArr0[1] := 2;
                end;
            8:
                begin
                    GlobalArr0[1] := GlobalArr0[2];
                end;
            9:
                begin
                    GlobalArr0[2] := GlobalArr0[2];
                    Idx := 2;
                end;
        end;
        exit(Prefix + Format(GlobalArr0[Idx]) + '|' + Format(GlobalArr0[Idx], 0, 2));
    end;

    local procedure VarStore(var A: array[2] of Option; Kind: Integer): Text
    var
        Prefix: Text;
        Idx: Integer;
    begin
        Idx := 1;
        case Kind of
            8:
                begin
                    A[1] := A[2];
                end;
            9:
                begin
                    A[2] := A[2];
                    Idx := 2;
                end;
        end;
        exit(Prefix + Format(A[Idx]) + '|' + Format(A[Idx], 0, 2));
    end;
}
