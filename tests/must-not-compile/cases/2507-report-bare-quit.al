// @expect AL0161 | 'Quit()' is inaccessible due to its protection level
// A bare Quit() in a report procedure is refused: only CurrReport.Quit() is accessible. (gap cycle 3 C3-07; writer Y36)
report 50000 "MNC C2507"
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
        Quit();
    end;
}

table 50001 "MNC Y36 Rpt Row"
{
    fields { field(1; Id; Integer) { } }
}
