// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: self-contained tables 74514, 74515, report 74516, codeunit 74517
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: IncludeCaption = true on a column that reads a field of a global Record variable (not a data item): the Labels block and the Column line.

table 74514 "LT P138 Glob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Glob Id cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74515 "LT P138 Glob Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { Caption = 'Glob Other Note cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 74516 "LT P138 Col Global Rec"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P138 Glob Row")
        {
            column(IdCol; Id) { }
            column(OtherNote; OtherRec.Note) { IncludeCaption = true; }

            trigger OnAfterGetRecord()
            begin
                OtherRec.Get(1);
            end;
        }
    }

    var
        OtherRec: Record "LT P138 Glob Other";
}

codeunit 74517 "LT P138 Col Global Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DatasetLines(Keep: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT P138 Col Global Rec", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure P138_GlobalRecordColumn_Caption()
    var
        Row: Record "LT P138 Glob Row";
        Other: Record "LT P138 Glob Other";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Other.Id := 1;
        Other.Note := 'other note';
        Other.Insert();
        Observer.Observe('labels', DatasetLines('<Label '));
        Observer.Observe('columns', DatasetLines('<Column '));
        Observer.Expect('labels', '[<Label name="OtherNoteCaption">Glob Other Note cap</Label>]');
        Observer.Expect('columns', '[<Column name="IdCol">1</Column>][<Column name="OtherNote">other note</Column>]');
        Observer.Verify();
    end;
}
