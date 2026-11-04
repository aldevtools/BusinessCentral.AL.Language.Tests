// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y XP State (75568); own tables 75550-75551, xmlports 75552-75567 and 88570-88571, codeunits 75513 (import runner) and 75514 (tests)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: XmlPort properties FileName, InlineSchema, UseLax, XmlVersionNo, InherentEntitlements, InherentPermissions; field/text node properties XmlName, NamespacePrefix, Unbound, AutoCalcField, Width;
// table element properties RequestFilterHeading(ML), Unbound, Width. Width out of Integer range, an invalid XmlName and RequestFilterHeading with RequestFilterHeadingML are must-not-compile cases 0814-0825.
// BC versions: 27-29

table 75550 "LT Y Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y Item Line" where(ItemId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75551 "LT Y Item Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 75552 "LT Y XP Inline"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75553 "LT Y XP Lax"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseLax = true;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75554 "LT Y XP Strict"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75555 "LT Y XP V10"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V10;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75556 "LT Y XP V11"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V11;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75557 "LT Y XP FileName"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    FileName = 'lt-y-export.xml';
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75558 "LT Y XP FileName Empty"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    FileName = '';
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75559 "LT Y XP Permissions"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75560 "LT Y XP Attr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = p = 'urn:lt-y';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id)
                {
                    XmlName = 'Ident';
                    NamespacePrefix = 'p';
                }
                fieldattribute(Total; Rw.Total)
                {
                    AutoCalcField = true;
                }
                textattribute(Note)
                {
                    NamespacePrefix = 'p';
                    Width = 10;
                }
                fieldelement(Name; Rw.Name)
                {
                    XmlName = 'Label';
                    NamespacePrefix = 'p';
                    Width = 20;
                }
                fieldelement(Count; Rw.Total)
                {
                    XmlName = 'Lines';
                    AutoCalcField = true;
                }
            }
        }
    }
}

xmlport 75561 "LT Y XP NoCalc"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Total; Rw.Total)
                {
                    AutoCalcField = false;
                }
                fieldelement(Count; Rw.Total)
                {
                    AutoCalcField = false;
                }
            }
        }
    }
}

xmlport 75562 "LT Y XP Unbound Attr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldattribute(Free; Rw.Name)
                {
                    Unbound = true;
                }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75566 "LT Y XP Unbound Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                textattribute(Tag)
                {
                    Unbound = true;
                }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 75567 "LT Y XP Unbound Elem"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { }
                fieldelement(Extra; Rw.Qty)
                {
                    Unbound = true;
                }
            }
        }
    }
}

xmlport 75563 "LT Y XP Table Unbound"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                Unbound = true;
                Width = 12;
                fieldelement(Id; Rw.Id) { }
            }
            textelement(Plain)
            {
                Width = 6;
            }
        }
    }
}

xmlport 75564 "LT Y XP Heading"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id;
                RequestFilterHeading = 'Item rows';
                fieldelement(Id; Rw.Id) { }
            }
        }
    }
}

xmlport 75565 "LT Y XP Heading ML"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id;
                RequestFilterHeadingML = ENU = 'English rows', DEU = 'Deutsche Zeilen';
                fieldelement(Id; Rw.Id) { }
            }
        }
    }
}

// al-runner issue 5756: the Rec of an xmlport request page that declares SourceTable is a record of that table. It compiles in the request page
// triggers, in the xmlport triggers and in xmlport procedures (without a request page SourceTable there is no Rec: must-not-compile cases 2111 and 2112).
// At run time (Export and Import, no request page shown) Rec in OnPreXmlPort is an unfiltered, unpositioned, non-temporary record of the table; Modify returns false,
// Insert writes the row before the export reads the table (the export lists it), and OnPostXmlPort sees the same Rec. The request page OnOpenPage does not run.
// With SourceTableTemporary = true Rec is temporary and the export does not see its rows.
xmlport 88570 "LT RS XP Rec"
{
    Format = Xml;
    Direction = Both;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                MinOccurs = Zero;
                fieldelement(Id; Rw.Id) { }
            }
        }
    }

    requestpage
    {
        SourceTable = "LT Y Item";

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y XP State";
        begin
            Seen.Put('xp_open', 'reached');
            Rec.Modify();
        end;
    }

    trigger OnPreXmlPort()
    var
        Seen: Codeunit "LT Y XP State";
    begin
        Seen.Put('xp_pre_rec', RecText() + ' filters=[' + Rec.GetFilters() + '] count=' + Format(Rec.Count()) + ' temporary=' + Format(Rec.IsTemporary()) + ' table=' + Rec.TableName());
        // The returning form: a TryFunction may not write (TryFunctionWrite), and a Codeunit.Run after it fails with DB:Ok (write transaction).
        Seen.Put('xp_modify_bool', Format(Rec.Modify()));
        Rec.Init();
        Rec.Id := 50;
        Rec.Name := 'xp';
        Seen.Put('xp_insert', Format(Rec.Insert()));
    end;

    trigger OnPostXmlPort()
    var
        Seen: Codeunit "LT Y XP State";
    begin
        Seen.Put('xp_post_rec', RecText() + ' count=' + Format(Rec.Count()));
    end;

    procedure RecText(): Text
    begin
        exit('[' + Format(Rec.Id) + '/' + Rec.Name + ']');
    end;
}

xmlport 88571 "LT RS XP Temp Rec"
{
    Format = Xml;
    Direction = Export;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                MinOccurs = Zero;
                fieldelement(Id; Rw.Id) { }
            }
        }
    }

    requestpage
    {
        SourceTable = "LT Y Item";
        SourceTableTemporary = true;
    }

    trigger OnPreXmlPort()
    var
        Seen: Codeunit "LT Y XP State";
    begin
        Rec.Init();
        Rec.Id := 51;
        Rec.Name := 'temp';
        Seen.Put('xp_insert', Format(Rec.Insert()));
        Seen.Put('xp_pre_rec', '[' + Format(Rec.Id) + '/' + Rec.Name + '] count=' + Format(Rec.Count()) + ' temporary=' + Format(Rec.IsTemporary()));
    end;
}

codeunit 75568 "LT Y XP State"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Name: Text; Value: Text)
    begin
        if Entries.ContainsKey(Name) then
            Entries.Set(Name, Value)
        else
            Entries.Add(Name, Value);
    end;

    procedure Get(Name: Text): Text
    begin
        if Entries.ContainsKey(Name) then
            exit(Entries.Get(Name));
        exit('<none>');
    end;
}

codeunit 75513 "LT Y XP Import Runner"
{
    trigger OnRun()
    var
        Seen: Codeunit "LT Y XP State";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        if Seen.Get('import_text').Contains('encoding="UTF-16"') then
            TempBlob.CreateOutStream(OutS, TextEncoding::UTF16)
        else
            TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Seen.Get('import_text'));
        if Seen.Get('import_text').Contains('encoding="UTF-16"') then
            TempBlob.CreateInStream(InS, TextEncoding::UTF16)
        else
            TempBlob.CreateInStream(InS);
        Xmlport.Import(GetId(Seen.Get('import_id')), InS);
    end;

    local procedure GetId(Text: Text): Integer
    var
        Id: Integer;
    begin
        Evaluate(Id, Text);
        exit(Id);
    end;
}

codeunit 75514 "LT Y XmlPort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Codeunit "LT Y XP State";

    local procedure Seed()
    var
        Item: Record "LT Y Item";
        Line: Record "LT Y Item Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Item.Init();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Qty := 5;
        Item.Insert();
        Item.Init();
        Item.Id := 2;
        Item.Name := 'two';
        Item.Qty := 6;
        Item.Insert();
        Line.Id := 1;
        Line.ItemId := 1;
        Line.Insert();
        Line.Id := 2;
        Line.ItemId := 1;
        Line.Insert();
        Line.Id := 3;
        Line.ItemId := 2;
        Line.Insert();
        Commit();
    end;

    local procedure Rows(): Text
    var
        Item: Record "LT Y Item";
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Format(Item.Id) + '/' + Item.Name + '/' + Format(Item.Qty) + ';';
            until Item.Next() = 0;
        exit(Result);
    end;

    local procedure ExportText(XmlPortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryExport(XmlPortId: Integer; var Result: Text)
    begin
        Result := ExportText(XmlPortId);
    end;

    local procedure Export(var Observer: Codeunit "Probe Observer"; Name: Text; XmlPortId: Integer)
    var
        Result: Text;
    begin
        if TryExport(XmlPortId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ImportText(XmlPortId: Integer; Xml: Text): Text
    begin
        Seen.Put('import_text', Xml);
        Seen.Put('import_id', Format(XmlPortId));
        Commit();
        if Codeunit.Run(Codeunit::"LT Y XP Import Runner") then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure InlineSchema_Export_ContainsSchema()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        Seed();
        Text1 := ExportText(75552);
        Observer.Observe('export', Text1);
        Observer.Observe('plain', ExportText(75554));
        Observer.Observe('import_back', ImportText(75552, Text1));
        Observer.Observe('rows', Rows());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Item">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Item" type="Item" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Item><Id>1</Id><Name>one</Name></Item><Item><Id>2</Id><Name>two</Name></Item></Root>|');
        Observer.Expect('plain', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('import_back', 'error:Data at the root level is invalid. Line 1, position 56.|XmlPortImport:Xml');
        Observer.Expect('rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;

    [Test]
    procedure UseLax_Import_AcceptsUnknownElements()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('lax', ImportText(75553, '<Root><Item><Id>7</Id><Name>seven</Name><Unknown>x</Unknown></Item><Other/></Root>'));
        Observer.Observe('rows_lax', Rows());
        Observer.Observe('lax_other_namespace', ImportText(75553, '<Root><Item><Id>6</Id><Name>six</Name><Unknown xmlns="urn:other">x</Unknown></Item></Root>'));
        Observer.Observe('rows_lax_ns', Rows());
        Observer.Observe('strict_other_namespace', ImportText(75554, '<Root><Item><Id>5</Id><Name>five</Name><Unknown xmlns="urn:other">x</Unknown></Item></Root>'));
        Observer.Observe('strict', ImportText(75554, '<Root><Item><Id>8</Id><Name>eight</Name><Unknown>x</Unknown></Item></Root>'));
        Observer.Observe('strict_root', ImportText(75554, '<Root><Item><Id>9</Id><Name>nine</Name></Item><Other/></Root>'));
        Observer.Observe('rows_strict', Rows());
        Observer.Expect('lax', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('rows_lax', '1/one/5;2/two/6;');
        Observer.Expect('lax_other_namespace', 'ok');
        Observer.Expect('rows_lax_ns', '1/one/5;2/two/6;6/six/0;');
        Observer.Expect('strict_other_namespace', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown'' in namespace ''urn:other''.|XmlPortInvalidXml');
        Observer.Expect('strict', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''.|XmlPortInvalidXml');
        Observer.Expect('strict_root', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Other''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('rows_strict', '1/one/5;2/two/6;6/six/0;');
        Observer.Verify();
    end;

    [Test]
    procedure XmlVersionNo_Export_Declaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'v10', 75555);
        Export(Observer, 'v11', 75556);
        Export(Observer, 'default', 75554);
        Observer.Observe('import_v11', ImportText(75556, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>7</Id><Name>seven</Name></Item></Root>'));
        Observer.Observe('import_v10', ImportText(75555, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>8</Id><Name>eight</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('v10', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('v11', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('default', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('import_v11', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('import_v10', 'ok');
        Observer.Expect('rows', '1/one/5;2/two/6;8/eight/0;');
        Observer.Verify();
    end;

    [Test]
    procedure FileName_Export_Output()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'named', 75557);
        Export(Observer, 'empty', 75558);
        Observer.Expect('named', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('empty', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure InherentPermissions_Export_WithoutExplicitPermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75559);
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeProperties_Export_NamesPrefixesAutoCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'attr', 75560);
        Export(Observer, 'nocalc', 75561);
        Observer.Expect('attr', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:lt-y">|  <Item Ident="1" Total="2" Note="">|    <p:Label>one</p:Label>|    <Lines>2</Lines>|  </Item>|  <Item Ident="2" Total="1" Note="">|    <p:Label>two</p:Label>|    <Lines>1</Lines>|  </Item>|</Root>|');
        Observer.Expect('nocalc', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item Total="0">|    <Count>0</Count>|  </Item>|  <Item Total="0">|    <Count>0</Count>|  </Item>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeProperties_Import_NamesPrefixes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('import', ImportText(75560, '<Root xmlns:p="urn:lt-y"><Item Ident="11" Total="0" Note="n"><p:Label>eleven</p:Label><Lines>0</Lines></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Observe('import_no_prefix', ImportText(75560, '<Root><Item Ident="12" Total="0" Note=""><Label>twelve</Label><Lines>0</Lines></Item></Root>'));
        Observer.Observe('rows2', Rows());
        Observer.Expect('import', 'ok');
        Observer.Expect('rows', '1/one/5;2/two/6;11/eleven/0;');
        Observer.Expect('import_no_prefix', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Label''. List of possible elements expected: ''Label'' in namespace ''urn:lt-y''.|XmlPortInvalidXml');
        Observer.Expect('rows2', '1/one/5;2/two/6;11/eleven/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Unbound_FieldAttribute_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75562);
        Observer.Observe('import', ImportText(75562, '<Root><Item Id="21" Free="f"><Name>twentyone</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item Id="1" Free="one">|    <Name>one</Name>|  </Item>|  <Item Id="2" Free="two">|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('import', 'ok');
        Observer.Expect('rows', '1/one/5;2/two/6;21/twentyone/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Unbound_TextAttribute_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75566);
        Observer.Observe('import', ImportText(75566, '<Root><Item Id="22" Tag="t"><Name>twentytwo</Name></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item Id="1" Tag="">|    <Name>one</Name>|  </Item>|  <Item Id="2" Tag="">|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('import', 'ok');
        Observer.Expect('rows', '1/one/5;2/two/6;22/twentytwo/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Unbound_FieldElement_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        // Exporting this xmlport does not end (the export grows until the blob capacity is exceeded), so only the import is observed.
        Observer.Observe('import', ImportText(75567, '<Root><Item Id="23"><Extra>99</Extra></Item></Root>'));
        Observer.Observe('rows', Rows());
        Observer.Expect('import', 'ok');
        Observer.Expect('rows', '1/one/5;2/two/6;23//99;');
        Observer.Verify();
    end;

    [Test]
    procedure RequestFilterHeading_XmlPort_Metadata()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y Helper";
    begin
        Observer.Observe('plain', Helper.Facts(2000000280, 1, 75564, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('ml', Helper.Facts(2000000280, 1, 75565, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('inline', Helper.Facts(2000000280, 1, 75552, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('v11', Helper.Facts(2000000280, 1, 75556, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Observe('perm', Helper.Facts(2000000280, 1, 75559, 'UseRequestPage,Direction,Format,InherentPermissions,InherentEntitlements'));
        Observer.Expect('plain', 'UseRequestPage=Yes;Direction=Both;Format=Xml;InherentPermissions=;InherentEntitlements=;');
        Observer.Expect('ml', 'UseRequestPage=Yes;Direction=Both;Format=Xml;InherentPermissions=;InherentEntitlements=;');
        Observer.Expect('inline', 'UseRequestPage=No;Direction=Both;Format=Xml;InherentPermissions=;InherentEntitlements=;');
        Observer.Expect('v11', 'UseRequestPage=No;Direction=Both;Format=Xml;InherentPermissions=;InherentEntitlements=;');
        Observer.Expect('perm', 'UseRequestPage=No;Direction=Both;Format=Xml;InherentPermissions=X;InherentEntitlements=X;');
        Observer.Verify();
    end;

    // ---- Rec of an xmlport request page with SourceTable, read and written in the xmlport triggers (xmlports 88570, 88571; al-runner issue 5756)

    local procedure ClearRsState()
    begin
        Seen.Put('xp_open', '-');
        Seen.Put('xp_pre_rec', '-');
        Seen.Put('xp_modify_bool', '-');
        Seen.Put('xp_insert', '-');
        Seen.Put('xp_post_rec', '-');
    end;

    local procedure ObserveRsState(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('xp_open', Seen.Get('xp_open'));
        Observer.Observe('xp_pre_rec', Seen.Get('xp_pre_rec'));
        Observer.Observe('xp_modify_bool', Seen.Get('xp_modify_bool'));
        Observer.Observe('xp_insert', Seen.Get('xp_insert'));
        Observer.Observe('xp_post_rec', Seen.Get('xp_post_rec'));
    end;

    [Test]
    procedure RS_XmlPortRequestPageRec_Export()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        ClearRsState();
        if TryExport(88570, Result) then
            Observer.Observe('export', Result)
        else
            Observer.Observe('export', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ObserveRsState(Observer);
        Observer.Observe('rows', Rows());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Rw>|    <Id>1</Id>|  </Rw>|  <Rw>|    <Id>2</Id>|  </Rw>|  <Rw>|    <Id>50</Id>|  </Rw>|</Root>|');
        Observer.Expect('xp_open', '-');
        Observer.Expect('xp_pre_rec', '[0/] filters=[] count=2 temporary=No table=LT Y Item');
        Observer.Expect('xp_modify_bool', 'No');
        Observer.Expect('xp_insert', 'Yes');
        Observer.Expect('xp_post_rec', '[50/xp] count=3');
        Observer.Expect('rows', '1/one/5;2/two/6;50/xp/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RS_XmlPortRequestPageRec_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearRsState();
        Observer.Observe('import', ImportText(88570, '<Root><Rw><Id>7</Id></Rw></Root>'));
        ObserveRsState(Observer);
        Observer.Observe('rows', Rows());
        Observer.Expect('import', 'ok');
        Observer.Expect('xp_open', '-');
        Observer.Expect('xp_pre_rec', '[0/] filters=[] count=2 temporary=No table=LT Y Item');
        Observer.Expect('xp_modify_bool', 'No');
        Observer.Expect('xp_insert', 'Yes');
        Observer.Expect('xp_post_rec', '[50/xp] count=4');
        Observer.Expect('rows', '1/one/5;2/two/6;7//0;50/xp/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RS_XmlPortTemporaryRequestPageRec_Export()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        ClearRsState();
        if TryExport(88571, Result) then
            Observer.Observe('export', Result)
        else
            Observer.Observe('export', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('xp_insert', Seen.Get('xp_insert'));
        Observer.Observe('xp_pre_rec', Seen.Get('xp_pre_rec'));
        Observer.Observe('rows', Rows());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Rw>|    <Id>1</Id>|  </Rw>|  <Rw>|    <Id>2</Id>|  </Rw>|</Root>|');
        Observer.Expect('xp_insert', 'Yes');
        Observer.Expect('xp_pre_rec', '[51/temp] count=1 temporary=Yes');
        Observer.Expect('rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;
}
