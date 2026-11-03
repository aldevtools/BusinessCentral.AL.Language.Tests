// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: self-contained table 74518, report 74519, codeunit 74520
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: a report column with ObsoleteState = Pending (field source, expression source, function source) is written to the dataset like any other column: its Column line, its
// position, and whether the Labels block is affected when IncludeCaption is also true.

table 74518 "LT P138 Obs Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Obs Id cap'; }
        field(2; Name; Text[30]) { Caption = 'Obs Name cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 74519 "LT P138 Col Obsolete"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P138 Obs Row")
        {
            column(IdCol; Id) { }
            column(PendingField; Name)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Probe reason';
                ObsoleteTag = '29.0';
            }
            column(PendingCaption; Id)
            {
                IncludeCaption = true;
                ObsoleteState = Pending;
                ObsoleteReason = 'Probe reason';
                ObsoleteTag = '29.0';
            }
            column(PendingFunction; Fixed())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Probe reason';
                ObsoleteTag = '29.0';
            }
            column(PendingExpression; Format(Id) + '-x')
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Probe reason';
                ObsoleteTag = '29.0';
            }
            column(AfterPending; Name) { }
        }
    }

    local procedure Fixed(): Text
    begin
        exit('fixed value');
    end;
}

codeunit 74520 "LT P138 Col Obsolete Tests"
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
        Report.SaveAs(Report::"LT P138 Col Obsolete", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    local procedure Seed()
    var
        Row: Record "LT P138 Obs Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'N1';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'N2';
        Row.Insert();
    end;

    [Test]
    procedure P138_PendingColumns_AreInTheDataset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', DatasetLines('<Column '));
        Observer.Expect('columns', '[<Column name="IdCol">1</Column>][<Column name="PendingField">N1</Column>][<Column name="PendingCaption">1</Column>][<Column name="PendingFunction">fixed value</Column>][<Column name="PendingExpression">1-x</Column>][<Column name="AfterPending">N1</Column>][<Column name="IdCol">2</Column>][<Column name="PendingField">N2</Column>][<Column name="PendingCaption">2</Column>][<Column name="PendingFunction">fixed value</Column>][<Column name="PendingExpression">2-x</Column>][<Column name="AfterPending">N2</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_PendingColumns_Labels()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', DatasetLines('<Label '));
        Observer.Expect('labels', '[<Label name="PendingCaptionCaption">Obs Id cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_PendingColumns_NoRows()
    var
        Row: Record "LT P138 Obs Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('labels_no_rows', DatasetLines('<Label '));
        Observer.Observe('columns_no_rows', DatasetLines('<Column '));
        Observer.Expect('labels_no_rows', '[<Label name="PendingCaptionCaption">Obs Id cap</Label>]');
        Observer.Expect('columns_no_rows', '');
        Observer.Verify();
    end;
}
