// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Take(Integer, Integer)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Take(Integer, Integer)'
// Inside the table: Rec.Take(1) and the bare Take(1) are both reported.
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Take(A: Integer; B: Integer)
    begin
    end;

    procedure Run1()
    begin
        Rec.Take(1);
        Take(1);
    end;
}
