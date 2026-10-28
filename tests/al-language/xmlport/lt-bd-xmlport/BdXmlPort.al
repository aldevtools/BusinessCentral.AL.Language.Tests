// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); from xmlport/lt-y-xmlport-props/YXmlPortProps.al: table LT Y Item (75550), xmlports LT Y XP Lax (75553),
//   LT Y XP Strict (75554), LT Y XP V10 (75555), LT Y XP V11 (75556), LT Y XP Table Unbound (75563);
//   own state 81114 and import runner 81115 (copies of 75568/75513, so no SingleInstance codeunit is shared with another test codeunit);
//   own table 81080, xmlports 81081-81085, tests 81086
// Probe: corpus issue 657. UseLax with an unknown element and an element of another namespace in the middle of a sequence; default namespaces (xmlns="...")
// on the root, on a table element and on a field element; XmlVersionNo = V11 imports of a 1.0 declaration and of no declaration; Unbound = true on a
// table element; a namespace prefix that no node uses; InlineSchema with more field types, attributes, empty values and no rows.
// The export of a port with an unbound field element is not probed: it does not end (YXmlPortProps.al:716).
// Writer SQ (2026-10-28): xmlport 89580 with UseDefaultNamespace = true and no DefaultNamespace: export text and imports by root namespace (SqUseDefaultNamespace_NoDefaultNamespace).
// BC versions: 27-29

table 81080 "BD XP Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
        field(5; B; Boolean) { }
        field(6; Opt; Option) { OptionMembers = Alpha,Beta; }
        field(7; DT; DateTime) { }
        field(8; Cd; Code[10]) { }
        field(9; T; Time) { }
        field(10; Big; BigInteger) { }
        field(11; Dur; Duration) { }
        field(12; G; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 81081 "BD XP Inline Types"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "BD XP Types")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                fieldelement(Amt; Rw.Amt) { }
                fieldelement(D; Rw.D) { }
                fieldelement(B; Rw.B) { }
                fieldelement(Opt; Rw.Opt) { }
                fieldelement(DT; Rw.DT) { }
                fieldelement(Cd; Rw.Cd) { }
                fieldelement(T; Rw.T) { }
                fieldelement(Big; Rw.Big) { }
                fieldelement(Dur; Rw.Dur) { }
                fieldelement(G; Rw.G) { }
            }
        }
    }
}

xmlport 81082 "BD XP Inline Attrs"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "BD XP Types")
            {
                XmlName = 'Row';
                MinOccurs = Zero;
                fieldattribute(Id; Rw.Id) { }
                fieldattribute(Amt; Rw.Amt) { }
                fieldattribute(B; Rw.B) { Occurrence = Optional; }
                textattribute(Note) { }
                fieldelement(Name; Rw.Name) { }
                textelement(Extra) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81083 "BD XP Unused Prefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = p = 'urn:bd-p', q = 'urn:bd-q';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { NamespacePrefix = 'p'; }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 81084 "BD XP No Prefix Used"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = q = 'urn:bd-q';

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

xmlport 81085 "BD XP Default Ns"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:bd-default';
    UseDefaultNamespace = true;

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

codeunit 81086 "BD XmlPort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Codeunit "BD XP State";

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
        ClearLastError();
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
        ClearLastError();
        if Codeunit.Run(Codeunit::"BD XP Import Runner") then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; XmlPortId: Integer; Xml: Text)
    begin
        Seed();
        Observer.Observe(Name, ImportText(XmlPortId, Xml));
        Observer.Observe(Name + ' rows', Rows());
    end;

    local procedure SeedTypes(WithValues: Boolean)
    var
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        if WithValues then begin
            R.Name := 'Alpha & <b>';
            R.Amt := -1234.5;
            R.D := DMY2Date(5, 3, 2024);
            R.B := true;
            R.Opt := R.Opt::Beta;
            R.DT := CreateDateTime(DMY2Date(5, 3, 2024), 090507T);
            R.Cd := 'CODE1';
            R.T := 143015T;
            R.Big := 9876543210L;
            R.Dur := 90061001;
            R.G := '{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}';
        end;
        R.Insert();
        Commit();
    end;

    [Test]
    procedure BdUseLax_UnknownElementMidSequence()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'lax', 75553, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Import(Observer, 'strict', 75554, '<Root><Item><Id>7</Id><Unknown>x</Unknown><Name>seven</Name></Item></Root>');
        Import(Observer, 'lax first', 75553, '<Root><Item><Unknown>x</Unknown><Id>8</Id><Name>eight</Name></Item></Root>');
        Observer.Expect('lax', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Name'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax rows', '1/one/5;2/two/6;');
        Observer.Expect('strict', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Name''.|XmlPortInvalidXml');
        Observer.Expect('strict rows', '1/one/5;2/two/6;');
        Observer.Expect('lax first', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown''. List of possible elements expected: ''Id'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax first rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;

    [Test]
    procedure BdUseLax_OtherNamespaceMidSequence()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'lax', 75553, '<Root><Item><Id>6</Id><Unknown xmlns="urn:other">x</Unknown><Name>six</Name></Item></Root>');
        Import(Observer, 'strict', 75554, '<Root><Item><Id>6</Id><Unknown xmlns="urn:other">x</Unknown><Name>six</Name></Item></Root>');
        Import(Observer, 'lax between items', 75553, '<Root><Item><Id>9</Id><Name>nine</Name></Item><Other xmlns="urn:other"/><Item><Id>10</Id><Name>ten</Name></Item></Root>');
        Import(Observer, 'lax first', 75553, '<Root><Item><Unknown xmlns="urn:other">x</Unknown><Id>11</Id><Name>eleven</Name></Item></Root>');
        Observer.Expect('lax', 'ok');
        Observer.Expect('lax rows', '1/one/5;2/two/6;6/six/0;');
        Observer.Expect('strict', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Unknown'' in namespace ''urn:other''. List of possible elements expected: ''Name''.|XmlPortInvalidXml');
        Observer.Expect('strict rows', '1/one/5;2/two/6;');
        Observer.Expect('lax between items', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Item''. List of possible elements expected: any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax between items rows', '1/one/5;2/two/6;');
        Observer.Expect('lax first', 'ok');
        Observer.Expect('lax first rows', '1/one/5;2/two/6;11/eleven/0;');
        Observer.Verify();
    end;

    [Test]
    procedure BdDefaultNamespace_OnRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'strict', 75554, '<Root xmlns="urn:x"><Item><Id>4</Id><Name>four</Name></Item></Root>');
        Import(Observer, 'lax', 75553, '<Root xmlns="urn:x"><Item><Id>4</Id><Name>four</Name></Item></Root>');
        Import(Observer, 'strict empty', 75554, '<Root xmlns=""><Item><Id>5</Id><Name>five</Name></Item></Root>');
        Observer.Expect('strict', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('strict rows', '1/one/5;2/two/6;');
        Observer.Expect('lax', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('lax rows', '1/one/5;2/two/6;');
        Observer.Expect('strict empty', 'ok');
        Observer.Expect('strict empty rows', '1/one/5;2/two/6;5/five/0;');
        Observer.Verify();
    end;

    [Test]
    procedure BdDefaultNamespace_InheritedFromParent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'strict item', 75554, '<Root><Item xmlns="urn:x"><Id>3</Id><Name>three</Name></Item></Root>');
        Import(Observer, 'lax item', 75553, '<Root><Item xmlns="urn:x"><Id>3</Id><Name>three</Name></Item></Root>');
        Import(Observer, 'strict field', 75554, '<Root><Item><Id xmlns="urn:x">12</Id><Name>twelve</Name></Item></Root>');
        Import(Observer, 'lax field', 75553, '<Root><Item><Id>13</Id><Name xmlns="urn:x">thirteen</Name></Item></Root>');
        Observer.Expect('strict item', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Item'' in namespace ''urn:x''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('strict item rows', '1/one/5;2/two/6;');
        Observer.Expect('lax item', 'error:Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Item'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax item rows', '1/one/5;2/two/6;');
        Observer.Expect('strict field', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Id'' in namespace ''urn:x''. List of possible elements expected: ''Id''.|XmlPortInvalidXml');
        Observer.Expect('strict field rows', '1/one/5;2/two/6;');
        Observer.Expect('lax field', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Name'' as well as any element in namespace ''##other''.|XmlPortInvalidXml');
        Observer.Expect('lax field rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;

    [Test]
    procedure BdDefaultNamespace_PortWithDefaultNamespace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 81085);
        Import(Observer, 'same namespace', 81085, '<Root xmlns="urn:bd-default"><Item><Id>14</Id><Name>fourteen</Name></Item></Root>');
        Import(Observer, 'no namespace', 81085, '<Root><Item><Id>15</Id><Name>fifteen</Name></Item></Root>');
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns="urn:bd-default">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('same namespace', 'ok');
        Observer.Expect('same namespace rows', '1/one/5;2/two/6;14/fourteen/0;');
        Observer.Expect('no namespace', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('no namespace rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;

    [Test]
    procedure BdXmlVersionNo_V11_ImportOtherDeclarations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'v11 decl 1.0', 75556, '<?xml version="1.0" encoding="utf-8"?><Root><Item><Id>7</Id><Name>seven</Name></Item></Root>');
        Import(Observer, 'v11 no decl', 75556, '<Root><Item><Id>8</Id><Name>eight</Name></Item></Root>');
        Import(Observer, 'v10 no decl', 75555, '<Root><Item><Id>9</Id><Name>nine</Name></Item></Root>');
        Import(Observer, 'v10 decl 1.1', 75555, '<?xml version="1.1" encoding="utf-8"?><Root><Item><Id>10</Id><Name>ten</Name></Item></Root>');
        Observer.Expect('v11 decl 1.0', 'ok');
        Observer.Expect('v11 decl 1.0 rows', '1/one/5;2/two/6;7/seven/0;');
        Observer.Expect('v11 no decl', 'ok');
        Observer.Expect('v11 no decl rows', '1/one/5;2/two/6;8/eight/0;');
        Observer.Expect('v10 no decl', 'ok');
        Observer.Expect('v10 no decl rows', '1/one/5;2/two/6;9/nine/0;');
        Observer.Expect('v10 decl 1.1', 'error:Version number ''1.1'' is invalid. Line 1, position 16.|XmlPortImport:Xml');
        Observer.Expect('v10 decl 1.1 rows', '1/one/5;2/two/6;');
        Observer.Verify();
    end;

    [Test]
    procedure BdUnbound_TableElement_ExportAndImport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 75563);
        Import(Observer, 'import', 75563, '<Root><Item><Id>31</Id></Item><Plain>p</Plain></Root>');
        Import(Observer, 'import two', 75563, '<Root><Item><Id>32</Id></Item><Item><Id>33</Id></Item><Plain>p</Plain></Root>');
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|  </Item>|  <Item>|    <Id>2</Id>|  </Item>|  <Plain />|</Root>|');
        Observer.Expect('import', 'ok');
        Observer.Expect('import rows', '1/one/5;2/two/6;31//0;');
        Observer.Expect('import two', 'ok');
        Observer.Expect('import two rows', '1/one/5;2/two/6;32//0;33//0;');
        Observer.Verify();
    end;

    [Test]
    procedure BdNamespaces_PrefixNoNodeUses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'one unused', 81083);
        Export(Observer, 'all unused', 81084);
        Import(Observer, 'import one unused', 81083, '<Root xmlns:p="urn:bd-p"><Item><p:Id>16</p:Id><Name>sixteen</Name></Item></Root>');
        Import(Observer, 'import all unused', 81084, '<Root><Item><Id>17</Id><Name>seventeen</Name></Item></Root>');
        Observer.Expect('one unused', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:bd-p" xmlns:q="urn:bd-q">|  <Item>|    <p:Id>1</p:Id>|    <Name>one</Name>|  </Item>|  <Item>|    <p:Id>2</p:Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('all unused', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:q="urn:bd-q">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>two</Name>|  </Item>|</Root>|');
        Observer.Expect('import one unused', 'ok');
        Observer.Expect('import one unused rows', '1/one/5;2/two/6;16/sixteen/0;');
        Observer.Expect('import all unused', 'ok');
        Observer.Expect('import all unused rows', '1/one/5;2/two/6;17/seventeen/0;');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_FieldTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(true);
        Export(Observer, 'values', 81081);
        Observer.Expect('values', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Amt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="D" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="B" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Opt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="DT" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Cd" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="T" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Big" type="xs:long" />|      <xs:element minOccurs="1" maxOccurs="1" name="Dur" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="G" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Row><Id>1</Id><Name>Alpha &amp; &lt;b&gt;</Name><Amt>-1,234.50</Amt><D>03/05/24</D><B>Yes</B><Opt>Beta</Opt><DT>03/05/24 09:05 AM</DT><Cd>CODE1</Cd><T> 2:30:15 PM</T><Big>9876543210</Big><Dur>1 day 1 hour 1 minute 1 second 1 millisecond</Dur><G>{5A2F6C9E-1B3D-4E8F-9A0B-1C2D3E4F5A6B}</G></Row></Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_FieldTypesEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(false);
        Export(Observer, 'empty', 81081);
        Observer.Expect('empty', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Amt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="D" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="B" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Opt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="DT" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Cd" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="T" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Big" type="xs:long" />|      <xs:element minOccurs="1" maxOccurs="1" name="Dur" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="G" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Row><Id>1</Id><Name /><Amt>0.00</Amt><D /><B>No</B><Opt>Alpha</Opt><DT /><Cd /><T /><Big>0</Big><Dur /><G>{00000000-0000-0000-0000-000000000000}</G></Row></Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        Commit();
        Export(Observer, 'types', 81081);
        Observer.Expect('types', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Amt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="D" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="B" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Opt" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="DT" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Cd" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="T" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Big" type="xs:long" />|      <xs:element minOccurs="1" maxOccurs="1" name="Dur" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="G" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Row><Id>0</Id><Name /><Amt>0.00</Amt><D /><B>No</B><Opt>Alpha</Opt><DT /><Cd /><T /><Big>0</Big><Dur /><G>{00000000-0000-0000-0000-000000000000}</G></Row></Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_NoRowsAttributes()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "BD XP Types";
    begin
        R.DeleteAll();
        Commit();
        Export(Observer, 'attrs', 81082);
        Observer.Expect('attrs', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Extra" type="xs:string" />|    </xs:sequence>|    <xs:attribute name="Id" type="xs:string" use="required" />|    <xs:attribute name="Amt" type="xs:string" use="required" />|    <xs:attribute name="B" type="xs:string" use="optional" />|    <xs:attribute name="Note" type="xs:string" use="required" />|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema></Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_Attributes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(true);
        Export(Observer, 'values', 81082);
        Observer.Expect('values', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Extra" type="xs:string" />|    </xs:sequence>|    <xs:attribute name="Id" type="xs:string" use="required" />|    <xs:attribute name="Amt" type="xs:string" use="required" />|    <xs:attribute name="B" type="xs:string" use="optional" />|    <xs:attribute name="Note" type="xs:string" use="required" />|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Row Id="1" Amt="-1,234.50" B="Yes" Note=""><Name>Alpha &amp; &lt;b&gt;</Name><Extra /></Row></Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure BdInlineSchema_AttributesEmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedTypes(false);
        Export(Observer, 'empty', 81082);
        Observer.Expect('empty', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Row">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Extra" type="xs:string" />|    </xs:sequence>|    <xs:attribute name="Id" type="xs:string" use="required" />|    <xs:attribute name="Amt" type="xs:string" use="required" />|    <xs:attribute name="B" type="xs:string" use="optional" />|    <xs:attribute name="Note" type="xs:string" use="required" />|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="0" maxOccurs="unbounded" name="Row" type="Row" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Row Id="1" Amt="0.00" B="No" Note=""><Name /><Extra /></Row></Root>|');
        Observer.Verify();
    end;

    // Writer SQ (NP lane 2026-10-28): UseDefaultNamespace = true and no DefaultNamespace (xmlport 89580). The export writes BC's own namespace
    // urn:microsoft-dynamics-nav/xmlports/x<id>; the imports put the root in that namespace, in another one, in none, behind a prefix, and in that
    // namespace with children reset to no namespace.
    [Test]
    procedure SqUseDefaultNamespace_NoDefaultNamespace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Export(Observer, 'export', 89580);
        Import(Observer, 'bc namespace', 89580, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89580"><Item><Id>14</Id><Name>fourteen</Name></Item></Root>');
        Import(Observer, 'other namespace', 89580, '<Root xmlns="urn:other"><Item><Id>15</Id><Name>fifteen</Name></Item></Root>');
        Import(Observer, 'no namespace', 89580, '<Root><Item><Id>16</Id><Name>sixteen</Name></Item></Root>');
        Import(Observer, 'bc namespace prefixed', 89580, '<p:Root xmlns:p="urn:microsoft-dynamics-nav/xmlports/x89580"><p:Item><p:Id>17</p:Id><p:Name>seventeen</p:Name></p:Item></p:Root>');
        Import(Observer, 'bc namespace children none', 89580, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x89580"><Item xmlns=""><Id>18</Id><Name>eighteen</Name></Item></Root>');
        Import(Observer, 'other port namespace', 89580, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x81085"><Item><Id>19</Id><Name>nineteen</Name></Item></Root>');
        Observer.Finish();
    end;
}

codeunit 81114 "BD XP State"
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

codeunit 81115 "BD XP Import Runner"
{
    trigger OnRun()
    var
        Seen: Codeunit "BD XP State";
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


// Writer SQ (NP lane 2026-10-28): UseDefaultNamespace = true without DefaultNamespace and without Namespaces.
xmlport 89580 "LT SQ XP Use Default Ns"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;

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
