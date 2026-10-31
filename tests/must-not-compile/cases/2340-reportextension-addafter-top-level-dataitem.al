// @expect AL0680 | Cannot use addBefore or addAfter on a top-level data item. The anchor Req is a top level data item.
// A reportextension cannot add a data item next to a top-level data item (addafter/addbefore of a top-level anchor), so an extension cannot add
// a top-level data item. Added items nest under an existing item: tests/al-language/report/lt-y17-ext-settableview/. Gap cycle 1 G10, writer Y17.
// Recorded with AL 30.0.44.47290.
table 50000 "MNC Y17 Ext Row"
{
    fields { field(1; Id; Integer) { } }
}

report 50001 "MNC Y17 Ext Base"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Req; "MNC Y17 Ext Row") { }
    }
}

reportextension 50002 "MNC Y17 Ext Top" extends "MNC Y17 Ext Base"
{
    dataset
    {
        addafter(Req)
        {
            dataitem(Added; "MNC Y17 Ext Row") { }
        }
    }
}
