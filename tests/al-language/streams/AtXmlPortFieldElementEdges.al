// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); own table 80008, xmlports 80009 and 80010, test codeunit 80011
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: XmlPort field element edges. Export of a fieldelement with an empty value that has a child textelement (with and without a child value);
// import of a document whose field element lacks the attribute of its fieldattribute (and export of an empty fieldattribute field).
// The non-empty forms are in xmlport/lt-af-xmlport/AfXmlPortAttrChildren.al.
// BC versions: 27, 28, 29

table 80008 "LT AT XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Lang; Text[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

xmlport 80009 "LT AT XP Empty Child"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AT XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name)
                {
                    textelement(Child)
                    {
                    }
                }
            }
        }
    }

    procedure SetChild(NewChild: Text)
    begin
        Child := NewChild;
    end;
}

xmlport 80010 "LT AT XP Field Attr"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AT XP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name)
                {
                    fieldattribute(Lang; Row.Lang) { }
                }
            }
        }
    }
}

codeunit 80011 "LT AT XmlPort FieldElem Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Name: Text[30]; Lang: Text[10])
    var
        Row: Record "LT AT XP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := Name;
        Row.Lang := Lang;
        Row.Insert();
    end;

    // The export text after the XML declaration, so the observed value stays short.
    local procedure Body(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        if Result.StartsWith('<?xml') then
            Result := CopyStr(Result, Result.IndexOf('?>') + 2);
        exit(Result);
    end;

    local procedure PutText(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
    end;

    [TryFunction]
    local procedure TryExportEmptyChild(var TempBlob: Codeunit "Temp Blob"; ChildValue: Text)
    var
        Xp: XmlPort "LT AT XP Empty Child";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetChild(ChildValue);
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryExportAttr(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AT XP Field Attr";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryImportAttr(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AT XP Field Attr";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure RowState(Id: Integer): Text
    var
        Row: Record "LT AT XP Row";
    begin
        if not Row.Get(Id) then
            exit('absent');
        exit(Row.Name + '|' + Row.Lang);
    end;

    [Test]
    procedure AT_EmptyFieldElement_ChildText_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Seed('', '');
        ClearLastError();
        if TryExportEmptyChild(TempBlob, 'c1') then
            Observer.Observe('export', Body(TempBlob))
        else
            Observer.ObserveError('export');
        Observer.Expect('export', '<Root>  <Row>    <Id>1</Id>    <Name>      <Child>c1</Child>    </Name>  </Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure AT_EmptyFieldElement_EmptyChild_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Seed('', '');
        ClearLastError();
        if TryExportEmptyChild(TempBlob, '') then
            Observer.Observe('export', Body(TempBlob))
        else
            Observer.ObserveError('export');
        Observer.Expect('export', '<Root>  <Row>    <Id>1</Id>    <Name>      <Child />    </Name>  </Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure AT_FieldAttribute_EmptyField_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Seed('Alpha', '');
        ClearLastError();
        if TryExportAttr(TempBlob) then
            Observer.Observe('export', Body(TempBlob))
        else
            Observer.ObserveError('export');
        Observer.Expect('export', '<Root>  <Row>    <Id>1</Id>    <Name Lang="">Alpha</Name>  </Row></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure AT_FieldAttribute_Missing_Import()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Row: Record "LT AT XP Row";
    begin
        Row.DeleteAll();
        PutText(TempBlob, '<?xml version="1.0" encoding="utf-8"?><Root><Row><Id>2</Id><Name>Beta</Name></Row></Root>');
        ClearLastError();
        if TryImportAttr(TempBlob) then
            Observer.Observe('import', 'ok')
        else
            Observer.ObserveError('import');
        Observer.Observe('row 2', RowState(2));
        Observer.Expect('import|text', 'Imported XML cannot validate with the schema: The required attribute ''Lang'' is missing.');
        Observer.Expect('import|code', 'XmlPortInvalidXml');
        Observer.Expect('row 2', 'absent');
        Observer.Verify();
    end;
}
