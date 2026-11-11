// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 50001 "ALT Shape 01"; Temp Blob (System Application); own table 96690,
//   xmlports 96691-96693, codeunit 96695.
// Probe: from the trial report al-runner 6924: a VariableText port whose table element holds more than field elements, and
//   MinOccurs = Once on a table element nested below another table element (export). Generic shapes, not the reporter's ports.
//   Observation form: every test ends in Observer.Finish(), so its failure message holds BC's values.
// Area:
//   - VariableText: a table element with a field element and a text element (no children) that OnBeforePassVariable fills, and one with a
//     field attribute before a field element; export of two rows and import of two lines (the rows made, the text element's value);
//   - Xml: a table element H with a nested table element C (MinOccurs = Once, LinkTable = H); export with a child row for each parent, with
//     a parent that has no child row, and import of a document with a parent that has no child element.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96690 "LT XTM Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 96691 "XP XTM Text Elem"
{
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = ',';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldelement(Id; Row.Id) { }
                textelement(Extra)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Extra := 'x' + Format(Row.Id);
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Imported += '[' + Extra + ']';
                    end;
                }
            }
        }
    }

    var
        Imported: Text;

    procedure GetImported(): Text
    begin
        exit(Imported);
    end;
}

xmlport 96692 "XP XTM Field Attr"
{
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldDelimiter = '<None>';
    FieldSeparator = ',';

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                fieldattribute(Name; Row.Name) { }
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

xmlport 96693 "XP XTM Nested Min Once"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(H; "ALT Shape 01")
            {
                fieldelement(Id; H.Id) { }
                tableelement(C; "LT XTM Child")
                {
                    LinkTable = H;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Once;
                    fieldelement(ChildId; C.Id) { }
                    fieldelement(Note; C.Note) { }
                }
            }
        }
    }
}

codeunit 96695 "XP XTM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedShapes()
    var
        Shape: Record "ALT Shape 01";
    begin
        Shape.DeleteAll();
        Shape.Id := 1;
        Shape.Name := 'Alpha';
        Shape.Insert();
        Shape.Id := 2;
        Shape.Name := 'Beta';
        Shape.Insert();
    end;

    local procedure ShapesText(): Text
    var
        Shape: Record "ALT Shape 01";
        Result: Text;
    begin
        if Shape.FindSet() then
            repeat
                Result += '[' + Format(Shape.Id) + ' ' + Shape.Name + ']';
            until Shape.Next() = 0;
        exit(Result);
    end;

    local procedure ChildrenText(): Text
    var
        Child: Record "LT XTM Child";
        Result: Text;
    begin
        if Child.FindSet() then
            repeat
                Result += '[' + Format(Child.Id) + ' ' + Format(Child.ParentId) + ' ' + Child.Note + ']';
            until Child.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExport(PortId: Integer; var Data: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(PortId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Data);
    end;

    [TryFunction]
    local procedure TryImportTextElem(Data: Text; var Imported: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP XTM Text Elem";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Data);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Port.SetSource(InS);
        Port.Import();
        Imported := Port.GetImported();
    end;

    [TryFunction]
    local procedure TryImport(PortId: Integer; Data: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Data);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(PortId, InS);
    end;

    [Test]
    procedure XTM_VariableText_TextElementInTableElement()
    var
        Shape: Record "ALT Shape 01";
        Observer: Codeunit "Probe Observer";
        Data: Text;
        Imported: Text;
        Crlf: Text[2];
    begin
        Crlf[1] := 13;
        Crlf[2] := 10;
        SeedShapes();
        Observer.Observe('export', Format(TryExport(Xmlport::"XP XTM Text Elem", Data)));
        Observer.ObserveError('export');
        Observer.Observe('export data', Data);
        Shape.DeleteAll();
        Observer.Observe('import', Format(TryImportTextElem('5,e5' + Crlf + '6,e6', Imported)));
        Observer.ObserveError('import');
        Observer.Observe('import rows', ShapesText());
        Observer.Observe('import extra', Imported);
        Observer.Expect('export', 'Yes');
        Observer.Expect('export|text', '');
        Observer.Expect('export|code', '');
        Observer.Expect('export data', '1,x1\r\n2,x2');
        Observer.Expect('import', 'Yes');
        Observer.Expect('import|text', '');
        Observer.Expect('import|code', '');
        Observer.Expect('import rows', '[5 ][6 ]');
        Observer.Expect('import extra', '[e5][e6]');
        Observer.Verify();
    end;

    [Test]
    procedure XTM_VariableText_FieldAttributeInTableElement()
    var
        Shape: Record "ALT Shape 01";
        Observer: Codeunit "Probe Observer";
        Data: Text;
    begin
        SeedShapes();
        Observer.Observe('export', Format(TryExport(Xmlport::"XP XTM Field Attr", Data)));
        Observer.ObserveError('export');
        Observer.Observe('export data', Data);
        Shape.DeleteAll();
        Observer.Observe('import', Format(TryImport(Xmlport::"XP XTM Field Attr", 'Gamma,7')));
        Observer.ObserveError('import');
        Observer.Observe('import rows', ShapesText());
        Observer.Expect('export', 'Yes');
        Observer.Expect('export|text', '');
        Observer.Expect('export|code', '');
        Observer.Expect('export data', 'Alpha,1\r\nBeta,2');
        Observer.Expect('import', 'Yes');
        Observer.Expect('import|text', '');
        Observer.Expect('import|code', '');
        Observer.Expect('import rows', '[7 Gamma]');
        Observer.Verify();
    end;

    [Test]
    procedure XTM_Xml_NestedTableElementMinOccursOnce()
    var
        Shape: Record "ALT Shape 01";
        Child: Record "LT XTM Child";
        Observer: Codeunit "Probe Observer";
        Data: Text;
    begin
        SeedShapes();
        Child.DeleteAll();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Note := 'one';
        Child.Insert();
        Observer.Observe('export parent 2 without child', Format(TryExport(Xmlport::"XP XTM Nested Min Once", Data)));
        Observer.ObserveError('export parent 2 without child');
        Observer.Observe('export data 1', Data);
        Child.Id := 20;
        Child.ParentId := 2;
        Child.Note := 'two';
        Child.Insert();
        Data := '';
        Observer.Observe('export every parent with child', Format(TryExport(Xmlport::"XP XTM Nested Min Once", Data)));
        Observer.ObserveError('export every parent with child');
        Observer.Observe('export data 2', Data);
        Shape.DeleteAll();
        Child.DeleteAll();
        Observer.Observe('import parent without child', Format(TryImport(Xmlport::"XP XTM Nested Min Once",
            '<?xml version="1.0" encoding="UTF-8"?><Root><H><Id>3</Id><C><ChildId>30</ChildId><Note>three</Note></C></H><H><Id>4</Id></H></Root>')));
        Observer.ObserveError('import parent without child');
        Observer.Observe('import rows', ShapesText() + ' / ' + ChildrenText());
        Observer.Expect('export parent 2 without child', 'No');
        Observer.Expect('export parent 2 without child|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('export parent 2 without child|code', 'InvalidStreamData');
        Observer.Expect('export data 1', '');
        Observer.Expect('export every parent with child', 'No');
        Observer.Expect('export every parent with child|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('export every parent with child|code', 'InvalidStreamData');
        Observer.Expect('export data 2', '');
        Observer.Expect('import parent without child', 'No');
        Observer.Expect('import parent without child|text', 'Imported XML cannot validate with the schema: The element ''H'' has incomplete content. List of possible elements expected: ''C''.');
        Observer.Expect('import parent without child|code', 'XmlPortInvalidXml');
        Observer.Expect('import rows', '[3 ] / [30 3 three]');
        Observer.Verify();
    end;
}
