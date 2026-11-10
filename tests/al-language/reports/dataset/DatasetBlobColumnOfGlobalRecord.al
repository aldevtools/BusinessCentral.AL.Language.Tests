// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703)
// local object: the Blob and Media fields of the table and the report's columns on them are under test (table 62320, reports 62321 and 62322).
// Area: what the report dataset holds for a column bound to a Blob field of a GLOBAL record variable, by how the record was read
//   (al-runner issue 7399: Company Information read with Get() only, never CalcFields(Picture)).
//   Record states: Get only; Get and CalcFields; never read (Init); FindFirst only; SetLoadFields of another field, then Get;
//   SetAutoCalcFields, then FindFirst; a Blob written in memory and never stored; Get of a row whose Blob is empty; a temporary
//   record; a second variable of the data item's own table; the same for a Media field; Company Information.Picture after Get only
//   and after CalcFields.
//   Next to each Blob column a Boolean column holds HasValue() of the same field at the same moment.
// Already pinned elsewhere: a Blob field of the data item itself without and with CalcFields, and Company Information.Picture after
//   CalcFields (reports/layouts-saveas/BcXmlBlob.al).
// BC versions: 27-29
table 62320 "RPT BlobCol Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Pic; Blob) { Subtype = Bitmap; }
        field(4; Photo; Media) { }
        field(5; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 62321 "RPT BlobCol Global"
{
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Num; One.Number) { }
            column(GetOnly; GetOnlyRow.Data) { }
            column(GetOnlyHas; GetOnlyRow.Data.HasValue()) { }
            column(GetOnlyBitmap; GetOnlyRow.Pic) { }
            column(GetCalc; GetCalcRow.Data) { }
            column(GetCalcHas; GetCalcRow.Data.HasValue()) { }
            column(NeverRead; NeverReadRow.Data) { }
            column(NeverReadHas; NeverReadRow.Data.HasValue()) { }
            column(FindOnly; FindOnlyRow.Data) { }
            column(FindOnlyHas; FindOnlyRow.Data.HasValue()) { }
            column(LoadFields; LoadFieldsRow.Data) { }
            column(LoadFieldsHas; LoadFieldsRow.Data.HasValue()) { }
            column(AutoCalc; AutoCalcRow.Data) { }
            column(AutoCalcHas; AutoCalcRow.Data.HasValue()) { }
            column(InMemory; InMemoryRow.Data) { }
            column(InMemoryHas; InMemoryRow.Data.HasValue()) { }
            column(EmptyGet; EmptyRow.Data) { }
            column(EmptyGetHas; EmptyRow.Data.HasValue()) { }
            column(TempGet; TempRow.Data) { }
            column(TempGetHas; TempRow.Data.HasValue()) { }
            column(MediaGetOnly; GetOnlyRow.Photo) { }
            column(MediaNeverRead; NeverReadRow.Photo) { }
        }
    }

    trigger OnPreReport()
    var
        OutS: OutStream;
    begin
        GetOnlyRow.Get(2);
        GetCalcRow.Get(2);
        GetCalcRow.CalcFields(Data);
        NeverReadRow.Init();
        FindOnlyRow.SetRange(Id, 2);
        FindOnlyRow.FindFirst();
        LoadFieldsRow.SetLoadFields(Note);
        LoadFieldsRow.Get(2);
        AutoCalcRow.SetAutoCalcFields(Data);
        AutoCalcRow.SetRange(Id, 2);
        AutoCalcRow.FindFirst();
        InMemoryRow.Init();
        InMemoryRow.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('In memory');
        EmptyRow.Get(1);
        TempRow.Init();
        TempRow.Id := 1;
        TempRow.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Temp');
        TempRow.Insert();
        TempRow.Init();
        TempRow.Get(1);
    end;

    var
        GetOnlyRow: Record "RPT BlobCol Row";
        GetCalcRow: Record "RPT BlobCol Row";
        NeverReadRow: Record "RPT BlobCol Row";
        FindOnlyRow: Record "RPT BlobCol Row";
        LoadFieldsRow: Record "RPT BlobCol Row";
        AutoCalcRow: Record "RPT BlobCol Row";
        InMemoryRow: Record "RPT BlobCol Row";
        EmptyRow: Record "RPT BlobCol Row";
        TempRow: Record "RPT BlobCol Row" temporary;
}

// The data item is over the table itself; the columns are on a second variable of that table and on Company Information.
report 62322 "RPT BlobCol Other Var"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "RPT BlobCol Row")
        {
            DataItemTableView = sorting(Id);

            column(Id; Row.Id) { }
            column(OwnData; Row.Data) { }
            column(OtherData; Other.Data) { }
            column(OtherHas; Other.Data.HasValue()) { }
            column(CompanyGetOnly; CompanyGetOnly.Picture) { }
            column(CompanyGetOnlyHas; CompanyGetOnly.Picture.HasValue()) { }
            column(CompanyCalc; CompanyCalc.Picture) { }
            column(CompanyCalcHas; CompanyCalc.Picture.HasValue()) { }

            trigger OnAfterGetRecord()
            begin
                // Another variable of the data item's table, read with Get in every row, never calculated.
                Other.Get(Row.Id);
            end;
        }
    }

    trigger OnPreReport()
    begin
        CompanyGetOnly.Get();
        CompanyCalc.Get();
        CompanyCalc.CalcFields(Picture);
    end;

    var
        Other: Record "RPT BlobCol Row";
        CompanyGetOnly: Record "Company Information";
        CompanyCalc: Record "Company Information";
}

codeunit 62323 "RPT BlobCol Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Row 1 has an empty Blob, row 2 holds the text 'Hello BC' in Data and three bytes in Pic.
    local procedure Seed()
    var
        Row: Record "RPT BlobCol Row";
        OutS: OutStream;
        B: Byte;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Note := 'empty';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Note := 'text';
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Hello BC');
        Row.Pic.CreateOutStream(OutS);
        B := 1;
        OutS.Write(B);
        B := 2;
        OutS.Write(B);
        B := 3;
        OutS.Write(B);
        Row.Insert();
    end;

    // Replaces the company picture (it depends on the database) by a fixed word: 'empty', 'picture' (the Base64 text of the
    // calculated picture) or 'other'.
    local procedure ClassifyCompany(Lines: Text; ColumnName: Text): Text
    var
        Company: Record "Company Information";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        Picture: Text;
    begin
        if Lines.Contains('<Column name="' + ColumnName + '"></Column>') or Lines.Contains('<Column name="' + ColumnName + '" />') then
            exit('empty');
        Company.Get();
        Company.CalcFields(Picture);
        if Company.Picture.HasValue() then begin
            Company.Picture.CreateInStream(InS);
            Picture := Base64.ToBase64(InS);
            if Lines.Contains('<Column name="' + ColumnName + '">' + Picture + '</Column>') then
                exit('picture');
        end;
        exit('other');
    end;

    local procedure WithoutCompany(Lines: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines.Split('|') do
            if (Line <> '') and not Line.StartsWith('<Column name="CompanyGetOnly">') and not Line.StartsWith('<Column name="CompanyCalc">') then
                Result += Line + '|';
        exit(Result);
    end;

    [Test]
    procedure Dataset_BlobOfGlobalRecord_ByHowTheRecordWasRead()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Dataset.Save(Report::"RPT BlobCol Global", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('columns', '<Column name="Num">1</Column>|<Column name="GetOnly"></Column>|<Column name="GetOnlyHas">True</Column>|<Column name="GetOnlyBitmap"></Column>|<Column name="GetCalc">SGVsbG8gQkM=</Column>|<Column name="GetCalcHas">True</Column>|<Column name="NeverRead"></Column>|<Column name="NeverReadHas">False</Column>|<Column name="FindOnly"></Column>|<Column name="FindOnlyHas">True</Column>|<Column name="LoadFields"></Column>|<Column name="LoadFieldsHas">True</Column>|<Column name="AutoCalc">SGVsbG8gQkM=</Column>|<Column name="AutoCalcHas">True</Column>|<Column name="InMemory">SW4gbWVtb3J5</Column>|<Column name="InMemoryHas">True</Column>|<Column name="EmptyGet"></Column>|<Column name="EmptyGetHas">False</Column>|<Column name="TempGet"></Column>|<Column name="TempGetHas">True</Column>|<Column name="MediaGetOnly"></Column>|<Column name="MediaNeverRead"></Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_BlobOfSecondVariableOfTheDataItemTable()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Dataset.Save(Report::"RPT BlobCol Other Var", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('columns', WithoutCompany(Dataset.ColumnLines(Xml)));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="OwnData"></Column>|<Column name="OtherData"></Column>|<Column name="OtherHas">False</Column>|<Column name="CompanyGetOnlyHas">True</Column>|<Column name="CompanyCalcHas">True</Column>|<Column name="Id">2</Column>|<Column name="OwnData">SGVsbG8gQkM=</Column>|<Column name="OtherData"></Column>|<Column name="OtherHas">True</Column>|<Column name="CompanyGetOnlyHas">True</Column>|<Column name="CompanyCalcHas">True</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure Dataset_CompanyPicture_GetOnlyAndCalculated()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Company: Record "Company Information";
        Xml: Text;
        Lines: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Dataset.Save(Report::"RPT BlobCol Other Var", '', Xml);
        Lines := Dataset.ColumnLines(Xml);
        Company.Get();
        Company.CalcFields(Picture);
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('company has a picture', Format(Company.Picture.HasValue()));
        Observer.Observe('Get only', ClassifyCompany(Lines, 'CompanyGetOnly'));
        Observer.Observe('Get only HasValue column', Format(Lines.Contains('<Column name="CompanyGetOnlyHas">true</Column>')));
        Observer.Observe('Get and CalcFields', ClassifyCompany(Lines, 'CompanyCalc'));
        Observer.Observe('Get and CalcFields HasValue column', Format(Lines.Contains('<Column name="CompanyCalcHas">true</Column>')));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('company has a picture', 'Yes');
        Observer.Expect('Get only', 'empty');
        Observer.Expect('Get only HasValue column', 'No');
        Observer.Expect('Get and CalcFields', 'picture');
        Observer.Expect('Get and CalcFields HasValue column', 'No');
        Observer.Verify();
    end;

    // The company picture is empty on some databases, so the same question with a picture the test stores first.
    [Test]
    procedure Dataset_CompanyPicture_StoredByTheTest_GetOnlyAndCalculated()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Company: Record "Company Information";
        OutS: OutStream;
        Xml: Text;
        Lines: Text;
        Ok: Boolean;
    begin
        Seed();
        Company.Get();
        Clear(Company.Picture);
        Company.Picture.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Probe picture');
        Company.Modify();
        Ok := Dataset.Save(Report::"RPT BlobCol Other Var", '', Xml);
        Lines := Dataset.ColumnLines(Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('Get only', ClassifyCompany(Lines, 'CompanyGetOnly'));
        Observer.Observe('Get only HasValue column', Format(Lines.Contains('<Column name="CompanyGetOnlyHas">true</Column>')));
        Observer.Observe('Get and CalcFields', ClassifyCompany(Lines, 'CompanyCalc'));
        Observer.Observe('Get and CalcFields HasValue column', Format(Lines.Contains('<Column name="CompanyCalcHas">true</Column>')));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('Get only', 'empty');
        Observer.Expect('Get only HasValue column', 'No');
        Observer.Expect('Get and CalcFields', 'picture');
        Observer.Expect('Get and CalcFields HasValue column', 'No');
        Observer.Verify();
    end;
}
