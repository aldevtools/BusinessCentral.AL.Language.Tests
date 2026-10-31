// @expect AL0270 | The control 'Content' is not found in the target 'RequestOptionsPage'
// A reportextension does addlast(Content) on the request page of a report IN THE SAME APP whose request page declares an empty
// `layout { }` (no Content area). The same extension compiles when the report comes from another app (the E-Document
// "Remittance Advice - Journal" shape; positive test: tests/al-language/report/lt-y42-reportext-request-page/). (gap cycle 4
// G4-10; writer Y42)
report 50000 "MNC Y42 Empty Rp"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer) { DataItemTableView = where(Number = const(1)); }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}

reportextension 50001 "MNC Y42 Empty Rp Ext" extends "MNC Y42 Empty Rp"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                group(G) { field(FlagCtl; Flag) { ApplicationArea = All; } }
            }
        }
    }

    var
        Flag: Boolean;
}
