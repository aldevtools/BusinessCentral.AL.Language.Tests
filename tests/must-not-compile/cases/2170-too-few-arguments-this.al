// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Take(Integer, Integer)'
// this.Take(1) with too few arguments.
codeunit 50002 "MNC SH Caller"
{
    procedure Take(A: Integer; B: Integer)
    begin
    end;

    procedure Run1()
    begin
        this.Take(1);
    end;
}
