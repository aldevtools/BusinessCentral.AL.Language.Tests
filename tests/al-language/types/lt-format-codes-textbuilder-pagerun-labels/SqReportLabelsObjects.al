// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-labels
// Scope: in-scope
// Fixtures used: none; objects for the writer SQ tests in P144ReportLabelsCaption.al (codeunit 70236)
// Facts: reports with more than one data item (a nested one and a second top-level one), IncludeCaption columns in each, declared labels,
// and a report extension that adds labels and an IncludeCaption column: the order of the Label lines in Report.SaveAs Xml.
// BC versions: 27-29

table 89581 "LT SQ Rpt Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Head Id'; }
        field(2; Name; Text[30]) { Caption = 'Head Name'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 89582 "LT SQ Rpt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { Caption = 'Line Head'; }
        field(2; LineNo; Integer) { Caption = 'Line No'; }
        field(3; Descr; Text[30]) { Caption = 'Line Descr'; }
        field(4; Qty; Decimal) { Caption = 'Line Qty'; }
    }

    keys { key(PK; HeadId, LineNo) { Clustered = true; } }
}

// Head (top level) > Line (nested), then Tail (second top level); labels after the dataset. Extended by 89584.
report 89583 "LT SQ Labels Two Items Ext"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Head; "LT SQ Rpt Head")
        {
            column(HeadIdC; Id) { IncludeCaption = true; }
            column(HeadNameC; Name) { IncludeCaption = true; }
            dataitem(Line; "LT SQ Rpt Line")
            {
                DataItemLink = HeadId = field(Id);
                column(LineNoC; LineNo) { IncludeCaption = true; }
                column(LineDescrC; Descr) { IncludeCaption = true; }
                column(LinePlain; Qty) { }
            }
        }
        dataitem(Tail; "LT SQ Rpt Line")
        {
            column(TailDescrC; Descr) { IncludeCaption = true; }
        }
    }

    labels
    {
        BaseFirstLbl = 'Base first';
        BaseSecondLbl = 'Base second';
    }
}

reportextension 89584 "LT SQ Labels Extension" extends "LT SQ Labels Two Items Ext"
{
    dataset
    {
        add(Line)
        {
            column(ExtQtyC; Qty) { IncludeCaption = true; }
        }
        add(Head)
        {
            column(ExtHeadNameC; Name) { IncludeCaption = true; }
        }
    }

    labels
    {
        ExtFirstLbl = 'Ext first';
        ExtSecondLbl = 'Ext second';
    }
}

// The same dataset and labels without an extension.
report 89585 "LT SQ Labels Two Items"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Head; "LT SQ Rpt Head")
        {
            column(HeadIdC; Id) { IncludeCaption = true; }
            column(HeadNameC; Name) { IncludeCaption = true; }
            dataitem(Line; "LT SQ Rpt Line")
            {
                DataItemLink = HeadId = field(Id);
                column(LineNoC; LineNo) { IncludeCaption = true; }
                column(LineDescrC; Descr) { IncludeCaption = true; }
                column(LinePlain; Qty) { }
            }
        }
        dataitem(Tail; "LT SQ Rpt Line")
        {
            column(TailDescrC; Descr) { IncludeCaption = true; }
        }
    }

    labels
    {
        BaseFirstLbl = 'Base first';
        BaseSecondLbl = 'Base second';
    }
}
