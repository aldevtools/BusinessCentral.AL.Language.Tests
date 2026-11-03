// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73256 and codeunit 73257
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: reading and writing an AL array element with an index below 1 or above the size (one and two dimensional arrays of Integer, Text, Decimal, Boolean, Code and Record, the index in a variable),
// as a function argument and by reference: whether it raises, the error text and the error code, and that the neighbouring elements are untouched.
// BC versions: 29 (27 and 28 by CI)

table 73256 "LT P129 Arr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73257 "LT P129 Array Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure ReadInt(I: Integer)
    var
        A: array[3] of Integer;
        V: Integer;
    begin
        V := A[I];
    end;

    [TryFunction]
    local procedure WriteInt(I: Integer)
    var
        A: array[3] of Integer;
    begin
        A[I] := 7;
    end;

    [TryFunction]
    local procedure ReadText(I: Integer)
    var
        A: array[3] of Text;
        V: Text;
    begin
        V := A[I];
    end;

    [TryFunction]
    local procedure WriteText(I: Integer)
    var
        A: array[3] of Text[10];
    begin
        A[I] := 'x';
    end;

    [TryFunction]
    local procedure ReadDec(I: Integer)
    var
        A: array[3] of Decimal;
        V: Decimal;
    begin
        V := A[I];
    end;

    [TryFunction]
    local procedure ReadBool(I: Integer)
    var
        A: array[3] of Boolean;
        V: Boolean;
    begin
        V := A[I];
    end;

    [TryFunction]
    local procedure ReadCode(I: Integer)
    var
        A: array[3] of Code[10];
        V: Code[10];
    begin
        V := A[I];
    end;

    [TryFunction]
    local procedure ReadRecord(I: Integer)
    var
        A: array[2] of Record "LT P129 Arr Row";
        V: Integer;
    begin
        V := A[I].Id;
    end;

    [TryFunction]
    local procedure WriteRecord(I: Integer)
    var
        A: array[2] of Record "LT P129 Arr Row";
    begin
        A[I].Id := 5;
    end;

    [TryFunction]
    local procedure Read2D(I: Integer; J: Integer)
    var
        A: array[2, 3] of Integer;
        V: Integer;
    begin
        V := A[I, J];
    end;

    [TryFunction]
    local procedure Write2D(I: Integer; J: Integer)
    var
        A: array[2, 3] of Integer;
    begin
        A[I, J] := 1;
    end;

    [TryFunction]
    local procedure AsArgument(I: Integer)
    var
        A: array[3] of Integer;
    begin
        TakeInt(A[I]);
    end;

    [TryFunction]
    local procedure ByReference(I: Integer)
    var
        A: array[3] of Integer;
    begin
        BumpInt(A[I]);
    end;

    [TryFunction]
    local procedure InFormat(I: Integer; var Result: Text)
    var
        A: array[3] of Integer;
    begin
        Result := Format(A[I]);
    end;

    local procedure TakeInt(V: Integer)
    begin
    end;

    local procedure BumpInt(var V: Integer)
    begin
        V += 1;
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P129_Array_Integer_ReadAndWrite_OutOfBounds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('read 1', Outcome(ReadInt(1)));
        ClearLastError();
        Observer.Observe('read 3', Outcome(ReadInt(3)));
        ClearLastError();
        Observer.Observe('read 0', Outcome(ReadInt(0)));
        ClearLastError();
        Observer.Observe('read 4', Outcome(ReadInt(4)));
        ClearLastError();
        Observer.Observe('read -1', Outcome(ReadInt(-1)));
        ClearLastError();
        Observer.Observe('read 100', Outcome(ReadInt(100)));
        ClearLastError();
        Observer.Observe('read intmax', Outcome(ReadInt(2147483647)));
        ClearLastError();
        Observer.Observe('write 3', Outcome(WriteInt(3)));
        ClearLastError();
        Observer.Observe('write 0', Outcome(WriteInt(0)));
        ClearLastError();
        Observer.Observe('write 4', Outcome(WriteInt(4)));
        ClearLastError();
        Observer.Observe('write -1', Outcome(WriteInt(-1)));
        ClearLastError();
        Observer.Observe('argument 4', Outcome(AsArgument(4)));
        ClearLastError();
        Observer.Observe('argument 2', Outcome(AsArgument(2)));
        ClearLastError();
        Observer.Observe('byref 4', Outcome(ByReference(4)));
        ClearLastError();
        Observer.Observe('byref 0', Outcome(ByReference(0)));
        ClearLastError();
        Observer.Observe('byref 3', Outcome(ByReference(3)));
        Observer.Expect('read 1', 'ok');
        Observer.Expect('read 3', 'ok');
        Observer.Expect('read 0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read -1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 100', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read intmax', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write 3', 'ok');
        Observer.Expect('write 0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write -1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('argument 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('argument 2', 'ok');
        Observer.Expect('byref 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('byref 0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('byref 3', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Array_OtherTypes_OutOfBounds()
    var
        Observer: Codeunit "Probe Observer";
        Formatted: Text;
    begin
        ClearLastError();
        Observer.Observe('text read 4', Outcome(ReadText(4)));
        ClearLastError();
        Observer.Observe('text read 0', Outcome(ReadText(0)));
        ClearLastError();
        Observer.Observe('text write 4', Outcome(WriteText(4)));
        ClearLastError();
        Observer.Observe('text write 3', Outcome(WriteText(3)));
        ClearLastError();
        Observer.Observe('decimal read 4', Outcome(ReadDec(4)));
        ClearLastError();
        Observer.Observe('boolean read 4', Outcome(ReadBool(4)));
        ClearLastError();
        Observer.Observe('code read 4', Outcome(ReadCode(4)));
        ClearLastError();
        Observer.Observe('record read 3', Outcome(ReadRecord(3)));
        ClearLastError();
        Observer.Observe('record read 0', Outcome(ReadRecord(0)));
        ClearLastError();
        Observer.Observe('record read 2', Outcome(ReadRecord(2)));
        ClearLastError();
        Observer.Observe('record write 3', Outcome(WriteRecord(3)));
        ClearLastError();
        Observer.Observe('format 4', Outcome(InFormat(4, Formatted)));
        ClearLastError();
        Observer.Observe('format 2', Outcome(InFormat(2, Formatted)) + '|' + Formatted);
        Observer.Expect('text read 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('text read 0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('text write 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('text write 3', 'ok');
        Observer.Expect('decimal read 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('boolean read 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('code read 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('record read 3', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('record read 0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('record read 2', 'ok');
        Observer.Expect('record write 3', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('format 4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('format 2', 'ok|0');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Array_TwoDimensions_OutOfBounds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('read 2,3', Outcome(Read2D(2, 3)));
        ClearLastError();
        Observer.Observe('read 3,1', Outcome(Read2D(3, 1)));
        ClearLastError();
        Observer.Observe('read 1,4', Outcome(Read2D(1, 4)));
        ClearLastError();
        Observer.Observe('read 0,1', Outcome(Read2D(0, 1)));
        ClearLastError();
        Observer.Observe('read 1,0', Outcome(Read2D(1, 0)));
        ClearLastError();
        Observer.Observe('read 3,4', Outcome(Read2D(3, 4)));
        ClearLastError();
        Observer.Observe('read -1,-1', Outcome(Read2D(-1, -1)));
        ClearLastError();
        Observer.Observe('write 2,3', Outcome(Write2D(2, 3)));
        ClearLastError();
        Observer.Observe('write 3,1', Outcome(Write2D(3, 1)));
        ClearLastError();
        Observer.Observe('write 1,4', Outcome(Write2D(1, 4)));
        ClearLastError();
        Observer.Observe('write 0,0', Outcome(Write2D(0, 0)));
        Observer.Expect('read 2,3', 'ok');
        Observer.Expect('read 3,1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 1,4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 0,1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 1,0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read 3,4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('read -1,-1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write 2,3', 'ok');
        Observer.Expect('write 3,1', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write 1,4', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('write 0,0', 'err|Index out of bounds.|IndexOutOfBounds');
        Observer.Verify();
    end;
}
