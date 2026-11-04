// Batch 5, md:225 (Clear of a codeunit variable, of a report variable) and the Clear (fixes-7) row (Clear of an array passed by var).
// The counter codeunits are above the test codeunit; the SingleInstance one is used by this test codeunit only.

codeunit 67050 "W5 Clear Counter"
{
    var
        Counter: Integer;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure Value(): Integer
    begin
        exit(Counter);
    end;
}

codeunit 67051 "W5 Clear Counter Single"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure Value(): Integer
    begin
        exit(Counter);
    end;
}

report 67052 "W5 Clear Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    procedure SetMarker(NewMarker: Integer)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Integer
    begin
        exit(Marker);
    end;

    var
        Marker: Integer;
}

codeunit 67053 "W5 Clear Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // md:225: a plain codeunit variable.
    [Test]
    procedure Clear_CodeunitVariable()
    var
        Observer: Codeunit "Probe Observer";
        Counter: Codeunit "W5 Clear Counter";
        Alias: Codeunit "W5 Clear Counter";
    begin
        Counter.Bump();
        Counter.Bump();
        Counter.Bump();
        Observer.Observe('before_clear', Format(Counter.Value()));
        Observer.Observe('alias_other_variable', Format(Alias.Value()));
        Clear(Counter);
        Observer.Observe('after_clear', Format(Counter.Value()));
        Counter.Bump();
        Observer.Observe('after_clear_and_bump', Format(Counter.Value()));
        Observer.Expect('before_clear', '3');
        Observer.Expect('alias_other_variable', '0');
        Observer.Expect('after_clear', '0');
        Observer.Expect('after_clear_and_bump', '1');
        Observer.Verify();
    end;

    // md:225: a SingleInstance codeunit variable: is the shared instance reset, and does a second variable see it?
    [Test]
    procedure Clear_SingleInstanceCodeunitVariable()
    var
        Observer: Codeunit "Probe Observer";
        First: Codeunit "W5 Clear Counter Single";
        Second: Codeunit "W5 Clear Counter Single";
    begin
        First.Bump();
        First.Bump();
        Observer.Observe('second_sees_first', Format(Second.Value()));
        Clear(First);
        Observer.Observe('first_after_clear', Format(First.Value()));
        Observer.Observe('second_after_clear_of_first', Format(Second.Value()));
        Clear(Second);
        Observer.Observe('second_after_own_clear', Format(Second.Value()));
        Observer.Expect('second_sees_first', '2');
        Observer.Expect('first_after_clear', '2');
        Observer.Expect('second_after_clear_of_first', '2');
        Observer.Expect('second_after_own_clear', '2');
        Observer.Verify();
    end;

    // md:225: a report variable that was never run.
    [Test]
    procedure Clear_ReportVariable_NotRun()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "W5 Clear Report";
    begin
        Rep.SetMarker(7);
        Observer.Observe('marker_before_clear', Format(Rep.GetMarker()));
        Clear(Rep);
        Observer.Observe('marker_after_clear', Format(Rep.GetMarker()));
        Observer.Expect('marker_before_clear', '7');
        Observer.Expect('marker_after_clear', '0');
        Observer.Verify();
    end;

    // Clear (fixes-7): an array passed by var is reset element by element in the caller.
    [Test]
    procedure Clear_ArrayPassedByVar()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: array[3] of Integer;
    begin
        Numbers[1] := 11;
        Numbers[2] := 22;
        Numbers[3] := 33;
        ClearByVar(Numbers);
        Observer.Observe('n1', Format(Numbers[1]));
        Observer.Observe('n2', Format(Numbers[2]));
        Observer.Observe('n3', Format(Numbers[3]));
        Observer.Expect('n1', '0');
        Observer.Expect('n2', '0');
        Observer.Expect('n3', '0');
        Observer.Verify();
    end;

    // Clear (fixes-7): an array passed by value is not touched in the caller.
    [Test]
    procedure Clear_ArrayPassedByValue()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: array[3] of Integer;
    begin
        Numbers[1] := 11;
        Numbers[2] := 22;
        Numbers[3] := 33;
        ClearByValue(Numbers);
        Observer.Observe('n1', Format(Numbers[1]));
        Observer.Observe('n2', Format(Numbers[2]));
        Observer.Observe('n3', Format(Numbers[3]));
        Observer.Expect('n1', '11');
        Observer.Expect('n2', '22');
        Observer.Expect('n3', '33');
        Observer.Verify();
    end;

    // Clear (fixes-7): one element, a text array, and a two-dimensional array.
    [Test]
    procedure Clear_ArrayElement_TextArray_Matrix()
    var
        Observer: Codeunit "Probe Observer";
        Names: array[3] of Text;
        Matrix: array[2, 2] of Integer;
        Flags: array[2] of Boolean;
        Dates: array[2] of Date;
    begin
        Names[1] := 'a';
        Names[2] := 'b';
        Names[3] := 'c';
        Clear(Names[2]);
        Observer.Observe('names_after_clear_of_element_2', Names[1] + '|' + Names[2] + '|' + Names[3]);
        Clear(Names);
        Observer.Observe('names_after_clear_all', Names[1] + '|' + Names[2] + '|' + Names[3]);
        Matrix[1, 1] := 1;
        Matrix[1, 2] := 2;
        Matrix[2, 1] := 3;
        Matrix[2, 2] := 4;
        Clear(Matrix);
        Observer.Observe('matrix_after_clear', Format(Matrix[1, 1]) + Format(Matrix[1, 2]) + Format(Matrix[2, 1]) + Format(Matrix[2, 2]));
        Flags[1] := true;
        Flags[2] := true;
        Clear(Flags);
        Observer.Observe('flags_after_clear', Format(Flags[1]) + Format(Flags[2]));
        Dates[1] := 20250101D;
        Clear(Dates);
        Observer.Observe('dates_after_clear', Format(Dates[1] = 0D));
        Observer.Expect('names_after_clear_of_element_2', 'a||c');
        Observer.Expect('names_after_clear_all', '||');
        Observer.Expect('matrix_after_clear', '0000');
        Observer.Expect('flags_after_clear', 'NoNo');
        Observer.Expect('dates_after_clear', 'Yes');
        Observer.Verify();
    end;

    local procedure ClearByVar(var Items: array[3] of Integer)
    begin
        Clear(Items);
    end;

    local procedure ClearByValue(Items: array[3] of Integer)
    begin
        Clear(Items);
    end;
}
