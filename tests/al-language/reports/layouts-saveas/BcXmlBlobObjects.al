// Objects for BcXmlBlob.al (corpus issue 659 item 4, from al-runtime-rs #253): report datasets with Blob, Media and MediaSet columns, saved
// with Report.SaveAs(..., ReportFormat::Xml, ...).

table 80975 "BC Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Pic; Media) { }
        field(4; Pics; MediaSet) { }
        field(5; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Blob, Media and MediaSet columns; the Blob is not calculated by the report.
report 80976 "BC Xml Blob Columns"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "BC Blob Row")
        {
            column(Id; Row.Id) { }
            column(BlobCol; Row.Data) { }
            column(MediaCol; Row.Pic) { }
            column(MediaSetCol; Row.Pics) { }
            column(NoteCol; Row.Note) { }
        }
    }
}

// The same Blob column, with CalcFields(Data) in OnAfterGetRecord.
report 80977 "BC Xml Blob CalcFields"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "BC Blob Row")
        {
            column(Id; Row.Id) { }
            column(BlobCol; Row.Data) { }

            trigger OnAfterGetRecord()
            begin
                Row.CalcFields(Data);
            end;
        }
    }
}

// The repro of al-runtime-rs #253: a column on Company Information.Picture of a global record.
report 80978 "BC Xml Company Picture"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Num; One.Number) { }
            column(CompanyPicture; Company.Picture) { }
        }
    }

    trigger OnPreReport()
    begin
        Company.Get();
        Company.CalcFields(Picture);
    end;

    var
        Company: Record "Company Information";
}
