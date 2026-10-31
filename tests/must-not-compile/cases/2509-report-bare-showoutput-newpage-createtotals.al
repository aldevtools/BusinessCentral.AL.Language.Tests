// @expect AL0161 | 'CreateTotals(var Decimal, var [Decimal])' is inaccessible due to its protection level
// @expect AL0161 | 'NewPage()' is inaccessible due to its protection level
// @expect AL0161 | 'ShowOutput()' is inaccessible due to its protection level
// Bare ShowOutput(), NewPage() and CreateTotals() in a report procedure are refused (CurrReport members). (gap cycle 3 C3-07; writer Y36)
report 50000 "MNC C2509"
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
        ShowOutput();
        NewPage();
        CreateTotals(D);
    end;
}

table 50001 "MNC Y36 Rpt Row"
{
    fields { field(1; Id; Integer) { } }
}
