// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'C' of 'Sig(Integer, Code[20])'
// The signature text for a Code[20] parameter.
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
    procedure Sig(X: Integer; C: Code[20])
    begin
    end;
}

codeunit 50002 "MNC SH Caller"
{
    procedure Run1()
    var
        Lib: Codeunit "MNC SH Lib";
    begin
        Lib.Sig(1);
    end;
}
