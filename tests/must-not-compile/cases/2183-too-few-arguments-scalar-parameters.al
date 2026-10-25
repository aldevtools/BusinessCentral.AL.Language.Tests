// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'SigBoolean(Integer, Boolean)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'T' of 'SigTime(Integer, Time)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'T' of 'SigDateTime(Integer, DateTime)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'G' of 'SigGuid(Integer, Guid)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'SigBigInteger(Integer, BigInteger)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'C' of 'SigChar(Integer, Char)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'T' of 'SigText(Integer, Text[30])'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'D' of 'SigDuration(Integer, Duration)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'D' of 'SigDateFormula(Integer, DateFormula)'
// The signature texts for Boolean, Time, DateTime, Guid, BigInteger, Char, Text[30], Duration and DateFormula parameters (one call each).
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC SH Lib"
{
    procedure SigBoolean(X: Integer; B: Boolean)
    begin
    end;

    procedure SigTime(X: Integer; T: Time)
    begin
    end;

    procedure SigDateTime(X: Integer; T: DateTime)
    begin
    end;

    procedure SigGuid(X: Integer; G: Guid)
    begin
    end;

    procedure SigBigInteger(X: Integer; B: BigInteger)
    begin
    end;

    procedure SigChar(X: Integer; C: Char)
    begin
    end;

    procedure SigText(X: Integer; T: Text[30])
    begin
    end;

    procedure SigDuration(X: Integer; D: Duration)
    begin
    end;

    procedure SigDateFormula(X: Integer; D: DateFormula)
    begin
    end;
}

codeunit 50002 "MNC SH Caller"
{
    procedure Run1()
    var
        Lib: Codeunit "MNC SH Lib";
    begin
        Lib.SigBoolean(1);
        Lib.SigTime(1);
        Lib.SigDateTime(1);
        Lib.SigGuid(1);
        Lib.SigBigInteger(1);
        Lib.SigChar(1);
        Lib.SigText(1);
        Lib.SigDuration(1);
        Lib.SigDateFormula(1);
    end;
}
