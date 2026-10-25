// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'R' of 'Sig(Integer, var Record "MNC SH Table")'
// The signature text for a var Record parameter: var Record "<name>".
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
    procedure Sig(X: Integer; var R: Record "MNC SH Table")
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
