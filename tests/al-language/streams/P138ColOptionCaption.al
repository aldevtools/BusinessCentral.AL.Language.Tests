// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: self-contained table 74524, report 74525, codeunit 74526
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: a report column that states OptionCaption: the text written for a global Option variable and for an Option field of the item, with and without the column's own
// OptionCaption, and the variable's own caption (the declared OptionCaption property of the variable is not available in AL, so only member names are used there).

table 74524 "LT P138 Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Level; Option)
        {
            OptionMembers = Low,Mid,High;
            OptionCaption = 'Field low,Field mid,Field high';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 74525 "LT P138 Col OptionCap"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P138 Opt Row")
        {
            column(VarPlain; ShowLevelAs) { }
            column(VarCaption; ShowLevelAs) { OptionCaption = 'Column one,Column two'; }
            column(FieldPlain; Level) { }
            column(FieldCaption; Level) { OptionCaption = 'Col low,Col mid,Col high'; }
            column(VarIndex; Format(ShowLevelAs, 0, 2)) { }

            trigger OnPreDataItem()
            begin
                ShowLevelAs := ShowLevelAs::Item;
            end;
        }
    }

    var
        ShowLevelAs: Option Level,Item;
}

codeunit 74526 "LT P138 Col OptionCap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P138_ColumnOptionCaption_Dataset()
    var
        Row: Record "LT P138 Opt Row";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Level := Row.Level::Mid;
        Row.Insert();
        Row.Id := 2;
        Row.Level := Row.Level::High;
        Row.Insert();
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT P138 Col OptionCap", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith('<Column ') then
                Result += '[' + Line.Trim() + ']';
        end;
        Observer.Observe('columns', Result);
        Observer.Expect('columns', '[<Column name="VarPlain">Item</Column>][<Column name="VarCaption">Column two</Column>][<Column name="FieldPlain">Field mid</Column>][<Column name="FieldCaption">Col mid</Column>][<Column name="VarIndex">1</Column>][<Column name="VarPlain">Item</Column>][<Column name="VarCaption">Column two</Column>][<Column name="FieldPlain">Field high</Column>][<Column name="FieldCaption">Col high</Column>][<Column name="VarIndex">1</Column>]');
        Observer.Verify();
    end;
}
