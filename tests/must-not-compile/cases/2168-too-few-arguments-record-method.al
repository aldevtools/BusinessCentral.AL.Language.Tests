// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Take(Integer, Integer)'
// A call of a table procedure through a record variable with too few arguments.
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


codeunit 50002 "MNC SH Caller"
{
    procedure Run1()
    var
        R: Record "MNC SH Table";
    begin
        R.Take(1);
    end;
}
