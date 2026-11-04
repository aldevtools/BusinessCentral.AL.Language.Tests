// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tableseparator-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 70940-70941, xmlports 70942-70944, codeunit 70945
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a one-table VariableText export with TableSeparator '#', '<None>', default and set on the instance, written into an INSERTED record's Blob and read back after Modify; two and zero rows
// BC versions: 29 (27 and 28 by CI)

table 70940 "LT P170 Sep Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70941 "LT P170 Sep Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 70942 "LT P170 Sep Hash"
{
    Format = VariableText;
    Direction = Export;
    FieldSeparator = ';';
    RecordSeparator = '<NewLine>';
    TableSeparator = '#';
    UseRequestPage = false;

    schema
    {
        tableelement(ItemRow; "LT P170 Sep Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
        }
    }
}

xmlport 70943 "LT P170 Sep None"
{
    Format = VariableText;
    Direction = Export;
    FieldSeparator = ';';
    RecordSeparator = '<NewLine>';
    TableSeparator = '<None>';
    UseRequestPage = false;

    schema
    {
        tableelement(ItemRow; "LT P170 Sep Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
        }
    }
}

xmlport 70944 "LT P170 Sep Default"
{
    Format = VariableText;
    Direction = Export;
    FieldSeparator = ';';
    RecordSeparator = '<NewLine>';
    UseRequestPage = false;

    schema
    {
        tableelement(ItemRow; "LT P170 Sep Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
        }
    }
}

codeunit 70945 "LT P170 Sep Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Item: Record "LT P170 Sep Item";
        i: Integer;
    begin
        Item.DeleteAll();
        for i := 1 to Rows do begin
            Item.Id := i;
            Item.Name := 'n' + Format(i);
            Item.Insert();
        end;
    end;

    local procedure NewBlob(var Row: Record "LT P170 Sep Blob")
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
    end;

    local procedure ReadBack(var Row: Record "LT P170 Sep Blob"): Text
    var
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        Row.Modify();
        Row.Get(1);
        Row.CalcFields(Data);
        if not Row.Data.HasValue() then
            exit('<no value>');
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
        Big.Read(InS);
        if Big.Length() = 0 then
            exit('<empty>');
        Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;

    [Test]
    procedure P170_TableSeparator_Hash_OneTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Sep Blob";
        Xp: XmlPort "LT P170 Sep Hash";
        OutS: OutStream;
    begin
        Seed(2);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Xp.Export();
        Observer.Observe('text', ReadBack(Row));
        Observer.Expect('getter', '[#]');
        Observer.Expect('text', '"1";"n1"\r\n"2";"n2"');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TableSeparator_None_OneTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Sep Blob";
        Xp: XmlPort "LT P170 Sep None";
        OutS: OutStream;
    begin
        Seed(2);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Xp.Export();
        Observer.Observe('text', ReadBack(Row));
        Observer.Expect('getter', '[]');
        Observer.Expect('text', '"1";"n1"\r\n"2";"n2"');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TableSeparator_Default_OneTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Sep Blob";
        Xp: XmlPort "LT P170 Sep Default";
        OutS: OutStream;
    begin
        Seed(2);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Xp.Export();
        Observer.Observe('text', ReadBack(Row));
        Observer.Expect('getter', '[\r\n\r\n]');
        Observer.Expect('text', '"1";"n1"\r\n"2";"n2"');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TableSeparator_SetOnInstance_OneTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Sep Blob";
        Xp: XmlPort "LT P170 Sep Default";
        OutS: OutStream;
    begin
        Seed(2);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.TableSeparator('@@');
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Xp.Export();
        Observer.Observe('text', ReadBack(Row));
        Observer.Expect('getter', '[@@]');
        Observer.Expect('text', '"1";"n1"\r\n"2";"n2"');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TableSeparator_Hash_RowCounts()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Sep Blob";
        Xp: XmlPort "LT P170 Sep Hash";
        OutS: OutStream;
    begin
        Seed(0);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('no_rows', ReadBack(Row));
        Clear(Xp);
        Seed(1);
        NewBlob(Row);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('one_row', ReadBack(Row));
        Observer.Expect('no_rows', '<no value>');
        Observer.Expect('one_row', '"1";"n1"');
        Observer.Verify();
    end;
}
