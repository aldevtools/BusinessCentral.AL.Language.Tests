// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// The exact lines of the SaveAs Xml dataset (only the lines of the Labels block and the DataItems elements are kept):
// - a report with NO row at all: the Labels block holds one <Label name="<column>Caption"> per IncludeCaption column of every data item, nested ones too
//   (ParentIdColCaption and ChildIdColCaption), and the data items are ONE line `  <DataItems />` (two spaces, a space before the slash);
// - a parent row with no child row: `  <DataItems>` ... `      <DataItems />` ... `  </DataItems>` (the empty child element is the self-closing form);
// - the child row too: the inner `<DataItems>` / `</DataItems>` pair on separate lines.
// Fixtures used: self-contained tables 69334 and 69335, report 69334, codeunit 69334
// BC versions: 27.5, 29.0
table 69334 "PT Parent"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Parent Id'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 69335 "PT Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Child Id'; }
        field(2; ParentId; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 69334 "PT Nested Report"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Parent; "PT Parent")
        {
            column(ParentIdCol; Id) { IncludeCaption = true; }

            dataitem(Child; "PT Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChildIdCol; Id) { IncludeCaption = true; }
            }
        }
    }
}

codeunit 69334 "PT SaveAs Empty Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Lines(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"PT Nested Report", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith('<DataItems') or Line.Trim().StartsWith('</DataItems') or Line.Trim().StartsWith('<Labels') or Line.Trim().StartsWith('</Labels') or Line.Trim().StartsWith('<Label ') then
                Result += '[' + Line + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure SaveAs_NoRowAtAll_ExactLines()
    var
        Parent: Record "PT Parent";
        Child: Record "PT Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Observer.Observe('no_rows', Lines());
        Observer.Expect('no_rows', '[  <Labels>][    <Label name="ParentIdColCaption">Parent Id</Label>][    <Label name="ChildIdColCaption">Child Id</Label>][  </Labels>][  <DataItems />]');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_ParentRowButNoChildRow_ExactLines()
    var
        Parent: Record "PT Parent";
        Child: Record "PT Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.Insert();
        Observer.Observe('parent_only', Lines());
        Child.Id := 5;
        Child.ParentId := 1;
        Child.Insert();
        Observer.Observe('parent_and_child', Lines());
        Observer.Expect('parent_only', '[  <Labels>][    <Label name="ParentIdColCaption">Parent Id</Label>][    <Label name="ChildIdColCaption">Child Id</Label>][  </Labels>][  <DataItems>][      <DataItems />][  </DataItems>]');
        Observer.Expect('parent_and_child', '[  <Labels>][    <Label name="ParentIdColCaption">Parent Id</Label>][    <Label name="ChildIdColCaption">Child Id</Label>][  </Labels>][  <DataItems>][      <DataItems>][      </DataItems>][  </DataItems>]');
        Observer.Verify();
    end;
}
