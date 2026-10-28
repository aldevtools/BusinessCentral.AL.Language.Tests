// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: own tables 98060, 98061, reports 98062 (a parent with a nested linked child) and 98063 (two sibling data items) (writer TO);
//   tests TO_* in codeunit 61243 (TestRequestPageSaveAsXmlContracts.al)
// Probe: observed on the corpus CI matrix; every literal asserted in the TO_* tests is what the BC service tier produced.
// Objects: the report data file that TestRequestPage.SaveAsXml writes for a report that is not one flat data item: columns of type
//   Integer, Text and Decimal, an empty Text value, a parent row without child rows.
// Facts (BC 29 corpus CI): the data file stays one flat DataSet table Result. Nested: one Result per child row with the parent's columns
//   repeated, a parent without child rows gives one Result with only its own columns. Siblings: the parent rows, then the child rows, each
//   Result with only its own item's columns. A Decimal column adds a <Name>Format</Name> column (#,##0.00); an empty Text is <PName />.
// BC versions: 27, 28, 29

table 98060 "LT TO RP Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 98061 "LT TO RP Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ParentId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; ParentId, LineNo) { Clustered = true; }
    }
}

report 98062 "LT TO RP Nested"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Parent; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
            dataitem(Child; "LT TO RP Child")
            {
                DataItemLink = ParentId = field(Id);
                column(CLine; LineNo) { }
                column(CQty; Qty) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}

report 98063 "LT TO RP Siblings"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Parent; "LT TO RP Parent")
        {
            column(PId; Id) { }
            column(PName; Name) { }
        }
        dataitem(Child; "LT TO RP Child")
        {
            column(CParent; ParentId) { }
            column(CLine; LineNo) { }
            column(CQty; Qty) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(MarkField; Mark) { ApplicationArea = All; }
            }
        }
    }

    var
        Mark: Integer;
}
