// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70926, report 70922, reportextension 70923, codeunit 70924
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Report.WordXmlPart(Id, true) and (Id, false) of a report with an added column and an added nested data item
// BC versions: 29 (27 and 28 by CI)

table 70926 "LT P170 Wxp Ext Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Extra; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

report 70922 "LT P170 Wxp Ext Base"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT P170 Wxp Ext Row")
        {
            column(RowNo; "No.") { }
            column(RowName; Name) { }
        }
    }
}

reportextension 70923 "LT P170 Wxp Ext Add" extends "LT P170 Wxp Ext Base"
{
    dataset
    {
        add(Rows)
        {
            column(RowExtra; Extra) { }
        }
    }
}

