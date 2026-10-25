// @expect AL0126 | No overload for method 'Pick' takes 0 arguments. Candidates: 'Pick(Integer, Integer)' defined in Codeunit 'MNC SH Lib' by the extension Must Not Compile by AL Language (1.0.0.0), 'Pick(Text, Text, Text)' defined in Codeunit 'MNC SH Lib' by the extension Must Not Compile by AL Language (1.0.0.0)
// An overloaded procedure called through a variable with no arguments: AL0126.
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Take(A: Integer; B: Integer)
    begin
    end;
}

enum 50000 "MNC SH Enum"
{
    value(0; None) { }
}

codeunit 50001 "MNC SH Lib"
{
    procedure Add(A: Integer; B: Integer): Integer
    begin
        exit(A + B);
    end;

    procedure Pick(A: Integer; B: Integer)
    begin
    end;

    procedure Pick(A: Text; B: Text; C: Text)
    begin
    end;
}

codeunit 50002 "MNC SH Caller"
{
    procedure Run1()
    var
        Lib: Codeunit "MNC SH Lib";
    begin
        Lib.Pick();
    end;
}
