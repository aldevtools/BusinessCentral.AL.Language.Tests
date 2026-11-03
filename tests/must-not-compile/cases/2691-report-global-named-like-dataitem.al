// @expect AL0155 | A member of type GlobalVariable with name 'DI' is already defined in Report 'MNC Y71 Gate Report' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type ReportDataItem with name 'DI' is already defined in Report 'MNC Y71 Gate Report' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A report global variable with the name of one of the report's data items is refused (AL0155, one diagnostic for the variable and one for the data item). A global variable
// with the name of a FIELD of the data item's table compiles, as does a table global with the name of one of its own fields and a page global with the name of a control:
// tests/al-language/types/lt-y71-value-conversions/Y71ValueConversions.al.
table 52691 "MNC Y71 Gate"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Gateway; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 52691 "MNC Y71 Gate Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(DI; "MNC Y71 Gate")
        {
        }
    }

    var
        DI: Integer;
}
