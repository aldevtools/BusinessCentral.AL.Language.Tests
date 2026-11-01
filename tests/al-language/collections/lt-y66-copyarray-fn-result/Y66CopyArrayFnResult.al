// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-copyarray-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own interface 93400, codeunits 93400 to 93402
// Probe (al-runner issue 6658, writer Y66): CopyArray whose source is the result of a procedure returning an array (codeunit method, named
// return value, local procedure, interface method, Text[10] array), with and without Length, into a longer and a shorter target; and
// the shapes that also compile but write into a function result: CopyArray with a function result as TARGET, CompressArray(P.GetGaps()) and
// P.Get()[1] := x (does the provider's array change?). ArrayLen and an element read of a function result.
// Does not compile: Clear(P.Get()) (AL0130, tests/must-not-compile/cases/2640), T := P.Get() (AL0145, case 2641).
// BC versions: 27, 28, 29

interface "LT Y66 CA Source"
{
    procedure Values(): array[2] of Integer;
}

codeunit 93400 "LT Y66 CA Provider"
{
    var
        Guids: array[2] of Guid;
        Ints: array[3] of Integer;
        Texts: array[2] of Text[10];
        Gaps: array[3] of Text[10];

    procedure Seed()
    begin
        Evaluate(Guids[1], '{11111111-1111-1111-1111-111111111111}');
        Evaluate(Guids[2], '{22222222-2222-2222-2222-222222222222}');
        Ints[1] := 0;
        Ints[2] := 7;
        Ints[3] := 0;
        Texts[1] := 'ab';
        Texts[2] := 'cdefghij';
        Gaps[1] := '';
        Gaps[2] := 'x';
        Gaps[3] := '';
    end;

    procedure GetMyGuids(): array[2] of Guid
    begin
        exit(Guids);
    end;

    procedure GetInts() Result: array[3] of Integer
    begin
        CopyArray(Result, Ints, 1);
    end;

    procedure GetTexts(): array[2] of Text[10]
    begin
        exit(Texts);
    end;

    procedure GetGaps(): array[3] of Text[10]
    begin
        exit(Gaps);
    end;

    procedure GetGrid(): array[2, 3] of Integer
    begin
    end;
}

codeunit 93401 "LT Y66 CA Source Impl" implements "LT Y66 CA Source"
{
    procedure Values() R: array[2] of Integer
    begin
        R[1] := 41;
        R[2] := 42;
    end;
}

codeunit 93402 "LT Y66 CopyArray Fn Result"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Y66_CopyArray_ReporterShape()
    var
        MyProvider: Codeunit "LT Y66 CA Provider";
        Target: array[2] of Guid;
    begin
        MyProvider.Seed();
        CopyArray(Target, MyProvider.GetMyGuids(), 1);
        Observer.Observe('target', Format(Target[1]) + '|' + Format(Target[2]));
        Target[1] := CreateGuid();
        Observer.Observe('provider after target change', Format(MyProvider.GetMyGuids()[1]));
        Observer.Finish();
    end;

    [Test]
    procedure Y66_CopyArray_FnResult_StartAndLength()
    var
        MyProvider: Codeunit "LT Y66 CA Provider";
        Target: array[2] of Guid;
        Ints: array[5] of Integer;
        Short: array[1] of Integer;
        I: Integer;
        R: Text;
    begin
        MyProvider.Seed();
        CopyArray(Target, MyProvider.GetMyGuids(), 2);
        Observer.Observe('guids from 2', Format(Target[1]) + '|' + Format(Target[2]));
        Clear(Target);
        CopyArray(Target, MyProvider.GetMyGuids(), 1, 1);
        Observer.Observe('guids 1 len 1', Format(Target[1]) + '|' + Format(Target[2]));
        for I := 1 to 5 do
            Ints[I] := -I;
        CopyArray(Ints, MyProvider.GetInts(), 1);
        R := '';
        for I := 1 to 5 do
            R += Format(Ints[I]) + ';';
        Observer.Observe('3 into 5', R);
        CopyArray(Short, MyProvider.GetInts(), 2, 1);
        Observer.Observe('one into 1', Format(Short[1]));
        Observer.Observe('3 into 1', TryShort(MyProvider));
        Observer.Observe('start past end', TryStart(MyProvider, 4));
        Observer.Observe('start 0', TryStart(MyProvider, 0));
        Observer.Finish();
    end;

    [Test]
    procedure Y66_CopyArray_FnResult_SourceKinds()
    var
        MyProvider: Codeunit "LT Y66 CA Provider";
        Impl: Codeunit "LT Y66 CA Source Impl";
        Src: Interface "LT Y66 CA Source";
        Ints: array[2] of Integer;
        Texts: array[2] of Text[10];
        Short: array[2] of Text[3];
    begin
        MyProvider.Seed();
        Src := Impl;
        CopyArray(Ints, Src.Values(), 1);
        Observer.Observe('interface', Format(Ints[1]) + '|' + Format(Ints[2]));
        CopyArray(Ints, LocalInts(), 1);
        Observer.Observe('local', Format(Ints[1]) + '|' + Format(Ints[2]));
        CopyArray(Texts, MyProvider.GetTexts(), 1);
        Observer.Observe('texts', Texts[1] + '|' + Texts[2]);
        Observer.Observe('texts into Text[3]', TryShortTexts(MyProvider, Short) + '|' + Short[1] + '|' + Short[2]);
        Observer.Observe('arraylen', Format(ArrayLen(MyProvider.GetMyGuids())));
        Observer.Observe('arraylen grid 1', Format(ArrayLen(MyProvider.GetGrid(), 1)));
        Observer.Observe('arraylen grid 2', Format(ArrayLen(MyProvider.GetGrid(), 2)));
        Observer.Observe('element read', Format(MyProvider.GetInts()[2]));
        Observer.Finish();
    end;

    [Test]
    procedure Y66_CopyArray_FnResultAsTarget()
    var
        MyProvider: Codeunit "LT Y66 CA Provider";
        Src: array[2] of Guid;
        N: Integer;
    begin
        MyProvider.Seed();
        Evaluate(Src[1], '{33333333-3333-3333-3333-333333333333}');
        Evaluate(Src[2], '{44444444-4444-4444-4444-444444444444}');
        CopyArray(MyProvider.GetMyGuids(), Src, 1);
        Observer.Observe('provider after copy into result', Format(MyProvider.GetMyGuids()[1]));
        N := CompressArray(MyProvider.GetGaps());
        Observer.Observe('compress result', Format(N));
        Observer.Observe('provider after compress', MyProvider.GetGaps()[1] + '|' + MyProvider.GetGaps()[2]);
        MyProvider.GetInts()[2] := 99;
        Observer.Observe('provider after element assign', Format(MyProvider.GetInts()[2]));
        Observer.Finish();
    end;

    local procedure LocalInts(): array[2] of Integer
    var
        R: array[2] of Integer;
    begin
        R[1] := 5;
        R[2] := 6;
        exit(R);
    end;

    local procedure TryShort(var MyProvider: Codeunit "LT Y66 CA Provider"): Text
    begin
        ClearLastError();
        if CopyShort(MyProvider) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure CopyShort(var MyProvider: Codeunit "LT Y66 CA Provider")
    var
        Short: array[1] of Integer;
    begin
        CopyArray(Short, MyProvider.GetInts(), 1);
    end;

    local procedure TryStart(var MyProvider: Codeunit "LT Y66 CA Provider"; Start: Integer): Text
    begin
        ClearLastError();
        if CopyFrom(MyProvider, Start) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure CopyFrom(var MyProvider: Codeunit "LT Y66 CA Provider"; Start: Integer)
    var
        Ints: array[5] of Integer;
    begin
        CopyArray(Ints, MyProvider.GetInts(), Start);
    end;

    local procedure TryShortTexts(var MyProvider: Codeunit "LT Y66 CA Provider"; var Short: array[2] of Text[3]): Text
    begin
        ClearLastError();
        if CopyTexts(MyProvider, Short) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure CopyTexts(var MyProvider: Codeunit "LT Y66 CA Provider"; var Short: array[2] of Text[3])
    begin
        CopyArray(Short, MyProvider.GetTexts(), 1);
    end;
}
