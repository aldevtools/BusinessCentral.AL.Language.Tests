// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: self-contained tables 74510, 74511, report 74512, codeunit 74513; writer QS: tables 87350, 87351, report 87352 (tests QS_*)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: Report.SaveAs(Xml): the Labels block and the Column lines of columns with IncludeCaption = true whose source is a field written with its data item name
// (the own item, the parent item from a nested item); the label name, the caption text, the column value.

table 74510 "LT P138 Col Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Parent Id cap'; }
        field(2; Name; Text[30]) { Caption = 'Parent Name cap'; }
        field(3; Qty; Decimal) { Caption = 'Parent Qty cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74511 "LT P138 Col Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Child Id cap'; }
        field(2; ParentId; Integer) { Caption = 'Child ParentId cap'; }
        field(3; Note; Text[30]) { Caption = 'Child Note cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 74512 "LT P138 Col Qualified"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT P138 Col Parent")
        {
            column(POwn; Name) { IncludeCaption = true; }
            column(PQual; Parent.Name) { IncludeCaption = true; }
            column(PQualQty; Parent.Qty) { IncludeCaption = true; }

            dataitem(Child; "LT P138 Col Child")
            {
                DataItemLink = ParentId = field(Id);

                column(COwn; Note) { IncludeCaption = true; }
                column(CQual; Child.Note) { IncludeCaption = true; }
                column(CFromParent; Parent.Name) { IncludeCaption = true; }
                column(CFromParentId; Parent.Id) { IncludeCaption = true; }
            }
        }
    }
}

table 87350 "LT QS Cap Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { Caption = 'QS Row No cap'; }
        field(2; Name; Text[30]) { Caption = 'QS Row Name cap'; }
        field(3; Kind; Option) { Caption = 'QS Row Kind cap'; OptionMembers = None,Quantity,Amount; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 87351 "LT QS Cap Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'QS Other Id cap'; }
        field(2; RowNo; Code[10]) { Caption = 'QS Other RowNo cap'; }
        field(3; Note; Text[30]) { Caption = 'QS Other Note cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Writer QS: a data item named like its table and columns that read a field written with that name, a field of the child data item
// written in the parent, a parent field written in the child, and a field of an earlier sibling data item written in the later one.
report 87352 "LT QS Cap Same Name"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem("LT QS Cap Row"; "LT QS Cap Row")
        {
            column(No_Row; "LT QS Cap Row"."No.") { IncludeCaption = true; }
            column(Name_Row; Name) { IncludeCaption = true; }
            column(Kind_Row; "LT QS Cap Row".Kind) { IncludeCaption = true; }
            column(FromChild; Child.Note) { IncludeCaption = true; }

            dataitem(Child; "LT QS Cap Other")
            {
                DataItemLink = RowNo = field("No.");

                column(Note_Child; Child.Note) { IncludeCaption = true; }
                column(No_FromParent; "LT QS Cap Row"."No.") { IncludeCaption = true; }
            }
        }
        dataitem(Sibling; "LT QS Cap Other")
        {
            DataItemTableView = where(RowNo = const(''));

            column(Id_Sibling; Sibling.Id) { IncludeCaption = true; }
            column(Name_FromSibling; "LT QS Cap Row".Name) { IncludeCaption = true; }
        }
    }
}

codeunit 74513 "LT P138 Col Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P138 Col Parent";
        Child: Record "LT P138 Col Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'P1';
        Parent.Qty := 2.5;
        Parent.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Note := 'C1';
        Child.Insert();
    end;

    local procedure DatasetLines(Keep: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT P138 Col Qualified", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure P138_Labels_OfQualifiedSources()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', DatasetLines('<Label '));
        Observer.Expect('labels', '[<Label name="POwnCaption">Parent Name cap</Label>][<Label name="PQualCaption">Parent Name cap</Label>][<Label name="PQualQtyCaption">Parent Qty cap</Label>][<Label name="COwnCaption">Child Note cap</Label>][<Label name="CQualCaption">Child Note cap</Label>][<Label name="CFromParentCaption">Parent Name cap</Label>][<Label name="CFromParentIdCaption">Parent Id cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Labels_WhenNoRows()
    var
        Parent: Record "LT P138 Col Parent";
        Child: Record "LT P138 Col Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Observer.Observe('labels_no_rows', DatasetLines('<Label '));
        Observer.Expect('labels_no_rows', '[<Label name="POwnCaption">Parent Name cap</Label>][<Label name="PQualCaption">Parent Name cap</Label>][<Label name="PQualQtyCaption">Parent Qty cap</Label>][<Label name="COwnCaption">Child Note cap</Label>][<Label name="CQualCaption">Child Note cap</Label>][<Label name="CFromParentCaption">Parent Name cap</Label>][<Label name="CFromParentIdCaption">Parent Id cap</Label>]');
        Observer.Verify();
    end;

    local procedure QsSeed()
    var
        Row: Record "LT QS Cap Row";
        Other: Record "LT QS Cap Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row."No." := 'R1';
        Row.Name := 'first';
        Row.Kind := Row.Kind::Quantity;
        Row.Insert();
        Row."No." := 'R2';
        Row.Name := 'second';
        Row.Kind := Row.Kind::Amount;
        Row.Insert();
        Other.Id := 1;
        Other.RowNo := 'R1';
        Other.Note := 'child of R1';
        Other.Insert();
        Other.Id := 2;
        Other.RowNo := '';
        Other.Note := 'loose';
        Other.Insert();
    end;

    local procedure QsDatasetLines(Keep: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT QS Cap Same Name", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure QS_Labels_DataItemNamedLikeTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QsSeed();
        Observer.Observe('labels', QsDatasetLines('<Label '));
        Observer.Expect('labels', '[<Label name="No_RowCaption">QS Row No cap</Label>][<Label name="Name_RowCaption">QS Row Name cap</Label>][<Label name="Kind_RowCaption">QS Row Kind cap</Label>][<Label name="FromChildCaption">QS Other Note cap</Label>][<Label name="Note_ChildCaption">QS Other Note cap</Label>][<Label name="No_FromParentCaption">QS Row No cap</Label>][<Label name="Id_SiblingCaption">QS Other Id cap</Label>][<Label name="Name_FromSiblingCaption">QS Row Name cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Columns_DataItemNamedLikeTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QsSeed();
        Observer.Observe('columns', QsDatasetLines('<Column '));
        Observer.Expect('columns', '[<Column name="No_Row">R1</Column>][<Column name="Name_Row">first</Column>][<Column name="Kind_Row">Quantity</Column>][<Column name="FromChild">child of R1</Column>][<Column name="Note_Child">child of R1</Column>][<Column name="No_FromParent">R1</Column>][<Column name="No_Row">R2</Column>][<Column name="Name_Row">second</Column>][<Column name="Kind_Row">Amount</Column>][<Column name="FromChild">child of R1</Column>][<Column name="Id_Sibling">2</Column>][<Column name="Name_FromSibling">second</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Labels_WhenNoRows()
    var
        Row: Record "LT QS Cap Row";
        Other: Record "LT QS Cap Other";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Observer.Observe('labels', QsDatasetLines('<Label '));
        Observer.Observe('columns', QsDatasetLines('<Column '));
        Observer.Expect('labels', '[<Label name="No_RowCaption">QS Row No cap</Label>][<Label name="Name_RowCaption">QS Row Name cap</Label>][<Label name="Kind_RowCaption">QS Row Kind cap</Label>][<Label name="FromChildCaption">QS Other Note cap</Label>][<Label name="Note_ChildCaption">QS Other Note cap</Label>][<Label name="No_FromParentCaption">QS Row No cap</Label>][<Label name="Id_SiblingCaption">QS Other Id cap</Label>][<Label name="Name_FromSiblingCaption">QS Row Name cap</Label>]');
        Observer.Expect('columns', '');
        Observer.Verify();
    end;
}
