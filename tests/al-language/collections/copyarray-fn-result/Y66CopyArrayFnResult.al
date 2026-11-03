// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-copyarray-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own interface 93500, codeunits 93500 to 93502
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

codeunit 93500 "LT Y66 CA Provider"
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

codeunit 93501 "LT Y66 CA Source Impl" implements "LT Y66 CA Source"
{
    procedure Values() R: array[2] of Integer
    begin
        R[1] := 41;
        R[2] := 42;
    end;
}

codeunit 93502 "LT Y66 CopyArray Fn Result"
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
        Observer.Expect('target', '{11111111-1111-1111-1111-111111111111}|{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('provider after target change', '{11111111-1111-1111-1111-111111111111}');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_CopyArray_FnResult_StartAndLength()
    var
        Mode: Integer;
        R: Text;
    begin
        for Mode := 1 to 8 do begin
            ClearLastError();
            if CopyMode(Mode, R) then
                Observer.Observe(Format(Mode) + ' ' + ModeName(Mode), R)
            else
                Observer.Observe(Format(Mode) + ' ' + ModeName(Mode), 'E ' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R);
        end;
        Observer.Expect('1 guids into 2 from 2', 'E CopyArray: The length parameter 1 does not match the length of the destination array 2.|ArrayLengthMismatch|before');
        Observer.Expect('2 guids into 2 from 1 len 1', 'E CopyArray: The length parameter 1 does not match the length of the destination array 2.|ArrayLengthMismatch|before');
        Observer.Expect('3 guids into 2 from 1 len 2', '{11111111-1111-1111-1111-111111111111}|{22222222-2222-2222-2222-222222222222}');
        Observer.Expect('4 ints 3 into 5 from 1', 'E CopyArray: The length parameter 3 does not match the length of the destination array 5.|ArrayLengthMismatch|before');
        Observer.Expect('5 ints into 1 from 2 len 1', '7');
        Observer.Expect('6 ints 3 into 1 from 1', 'E CopyArray: The length parameter 3 does not match the length of the destination array 1.|ArrayLengthMismatch|before');
        Observer.Expect('7 ints into 5 from 4', 'E CopyArray: The length parameter 0 does not match the length of the destination array 5.|ArrayLengthMismatch|before');
        Observer.Expect('8 ints into 5 from 0', 'E CopyArray: The length parameter 4 does not match the length of the destination array 5.|ArrayLengthMismatch|before');
        Observer.Verify();
    end;

    local procedure ModeName(Mode: Integer): Text
    begin
        case Mode of
            1:
                exit('guids into 2 from 2');
            2:
                exit('guids into 2 from 1 len 1');
            3:
                exit('guids into 2 from 1 len 2');
            4:
                exit('ints 3 into 5 from 1');
            5:
                exit('ints into 1 from 2 len 1');
            6:
                exit('ints 3 into 1 from 1');
            7:
                exit('ints into 5 from 4');
            8:
                exit('ints into 5 from 0');
        end;
    end;

    [TryFunction]
    local procedure CopyMode(Mode: Integer; var R: Text)
    var
        MyProvider: Codeunit "LT Y66 CA Provider";
        Target: array[2] of Guid;
        Ints: array[5] of Integer;
        Short: array[1] of Integer;
        I: Integer;
    begin
        MyProvider.Seed();
        for I := 1 to 5 do
            Ints[I] := -I;
        R := 'before';
        case Mode of
            1:
                CopyArray(Target, MyProvider.GetMyGuids(), 2);
            2:
                CopyArray(Target, MyProvider.GetMyGuids(), 1, 1);
            3:
                CopyArray(Target, MyProvider.GetMyGuids(), 1, 2);
            4:
                CopyArray(Ints, MyProvider.GetInts(), 1);
            5:
                CopyArray(Short, MyProvider.GetInts(), 2, 1);
            6:
                CopyArray(Short, MyProvider.GetInts(), 1);
            7:
                CopyArray(Ints, MyProvider.GetInts(), 4);
            8:
                CopyArray(Ints, MyProvider.GetInts(), 0);
        end;
        if Mode <= 3 then
            R := Format(Target[1]) + '|' + Format(Target[2])
        else
            if Mode in [5, 6] then
                R := Format(Short[1])
            else begin
                R := '';
                for I := 1 to 5 do
                    R += Format(Ints[I]) + ';';
            end;
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
        Observer.Expect('interface', '41|42');
        Observer.Expect('local', '5|6');
        Observer.Expect('texts', 'ab|cdefghij');
        Observer.Expect('texts into Text[3]', 'ok|ab|cdefghij');
        Observer.Expect('arraylen', '2');
        Observer.Expect('arraylen grid 1', '2');
        Observer.Expect('arraylen grid 2', '3');
        Observer.Expect('element read', '7');
        Observer.Verify();
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
        Observer.Expect('provider after copy into result', '{33333333-3333-3333-3333-333333333333}');
        Observer.Expect('compress result', '1');
        Observer.Expect('provider after compress', 'x|');
        Observer.Expect('provider after element assign', '7');
        Observer.Verify();
    end;

    local procedure LocalInts(): array[2] of Integer
    var
        R: array[2] of Integer;
    begin
        R[1] := 5;
        R[2] := 6;
        exit(R);
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
