// @expect AL0161 | 'PageNo([Integer])' is inaccessible due to its protection level
// @expect AL0161 | 'TotalsCausedBy()' is inaccessible due to its protection level
// Bare PageNo() and TotalsCausedBy() in a report procedure are refused (CurrReport members). (gap cycle 3 C3-07; writer Y36)
report 50000 "MNC C2508"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC Y36 Rpt Row") { }
    }

    procedure Run1()
    var
        B: Boolean;
        I: Integer;
        D: Decimal;
    begin
        I := PageNo();
        I := TotalsCausedBy();
    end;
}

table 50001 "MNC Y36 Rpt Row"
{
    fields { field(1; Id; Integer) { } }
}
