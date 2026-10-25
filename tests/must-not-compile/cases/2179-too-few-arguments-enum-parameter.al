// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'E' of 'Sig(Integer, Enum "MNC SH Enum")'
// The signature text for an Enum parameter: Enum "<name>".
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
    procedure Sig(X: Integer; E: Enum "MNC SH Enum")
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
