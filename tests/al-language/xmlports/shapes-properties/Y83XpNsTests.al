// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT Y83 helpers (Y83XpFixtures.al); ports in Y83XpNsPorts.al
// Probe: corpus issue (Y83). Xml and VariableText ports with DefaultNamespace, UseDefaultNamespace, Namespaces, NamespacePrefix, PreserveWhiteSpace, UseLax, XmlVersionNo and InlineSchema in combination: what the export writes and what an import reads.
// BC versions: 27-29

codeunit 94334 "LT Y83 Namespace Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    [Test]
    procedure Ns_DnOnly()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94340, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94340, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94340, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnFalseUtf8()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94341, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94341, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94341, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnNsprefix()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94342, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94342, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94342, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94342, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:y83-p">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'ok');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;10/ten/10.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnNsprefixUtf8()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94343, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94343, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94343, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94343, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns:p="urn:y83-p">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'ok');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;10/ten/10.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnLax()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94344, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94344, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94344, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnPws()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94345, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94345, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94345, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/  seven  /7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnInline()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94346, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94346, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94346, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Item">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Amt" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Item" type="Item" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="Root" />|</xs:schema><Item><Id>1</Id><Name>one</Name><Amt>1.50</Amt></Item><Item><Id>2</Id><Name>  two  </Name><Amt>2.01</Amt></Item></Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_DnV11()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94347, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94347, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94347, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_Pws()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94348, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94348, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94348, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/  seven  /7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PwsPrefix()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94349, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94349, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94349, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94349, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:y83-p">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'ok');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;10/  ten  /10.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PwsUdnDn()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94350, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94350, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94350, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns="urn:y83">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'ok');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;8/  eight  /8.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PwsUtf8Prefix()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94351, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94351, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94351, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94351, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns:p="urn:y83-p">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Name''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'ok');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;10/  ten  /10.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PwsUtf8Lax()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94352, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94352, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94352, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/  seven  /7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PwsVt()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94353, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94353, '7,"  seven  ",7.25' + CrLf(), false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '"1","one","1.50"|"2","  two  ","2.01"|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/  seven  /7.25/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnPrefix()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94354, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94354, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94354, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import own ns', Helper.TryImport(94354, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94354"><Item><Id>9</Id><Name>  nine  </Name><Amt>9.5</Amt></Item></Root>', false));
        Observer.Observe('rows after own ns', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94354, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:y83-p" xmlns="urn:microsoft-dynamics-nav/xmlports/x94354">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import own ns', 'error:Imported XML cannot validate with the schema: The element ''Item'' in namespace ''urn:microsoft-dynamics-nav/xmlports/x94354'' has invalid child element ''Name'' in namespace ''urn:microsoft-dynamics-nav/xmlports/x94354''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after own ns', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnDnPrefixUtf8()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94355, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94355, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94355, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94355, '<Root xmlns:p="urn:y83-p"><Item><Id>10</Id><p:Name>  ten  </p:Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns:p="urn:y83-p" xmlns="urn:y83">|  <Item>|    <Id>1</Id>|    <p:Name>one</p:Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <p:Name>  two  </p:Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:Imported XML cannot validate with the schema: The element ''Item'' in namespace ''urn:y83'' has invalid child element ''Name'' in namespace ''urn:y83''. List of possible elements expected: ''Name'' in namespace ''urn:y83-p''.|XmlPortInvalidXml');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnDnEprefixUtf8()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94356, TextEncoding::UTF8));
        Observer.Observe('import plain', Helper.TryImport(94356, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94356, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns="urn:y83">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'ok');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;8/eight/8.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnLax()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94357, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94357, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94357, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import own ns', Helper.TryImport(94357, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94357"><Item><Id>9</Id><Name>  nine  </Name><Amt>9.5</Amt></Item></Root>', false));
        Observer.Observe('rows after own ns', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94357">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import own ns', 'ok');
        Observer.Expect('rows after own ns', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;9/nine/9.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnInline()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94358, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94358, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94358, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import own ns', Helper.TryImport(94358, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94358"><Item><Id>9</Id><Name>  nine  </Name><Amt>9.5</Amt></Item></Root>', false));
        Observer.Observe('rows after own ns', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94358">|<xs:schema xmlns:tns="urn:microsoft-dynamics-nav/xmlports/x94358" elementFormDefault="qualified" targetNamespace="urn:microsoft-dynamics-nav/xmlports/x94358" xmlns:xs="http://www.w3.org/2001/XMLSchema">|  <xs:complexType name="Item">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="1" default="0" name="Id" type="xs:int" />|      <xs:element minOccurs="1" maxOccurs="1" name="Name" type="xs:string" />|      <xs:element minOccurs="1" maxOccurs="1" name="Amt" type="xs:string" />|    </xs:sequence>|  </xs:complexType>|  <xs:complexType name="Root" mixed="true">|    <xs:sequence>|      <xs:element minOccurs="1" maxOccurs="unbounded" name="Item" type="tns:Item" />|    </xs:sequence>|  </xs:complexType>|  <xs:element name="Root" type="tns:Root" />|</xs:schema><Item><Id>1</Id><Name>one</Name><Amt>1.50</Amt></Item><Item><Id>2</Id><Name>  two  </Name><Amt>2.01</Amt></Item></Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import own ns', 'ok');
        Observer.Expect('rows after own ns', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;9/nine/9.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnV11()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94359, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94359, '<Root><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94359, '<Root xmlns="urn:y83"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import own ns', Helper.TryImport(94359, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94359"><Item><Id>9</Id><Name>  nine  </Name><Amt>9.5</Amt></Item></Root>', false));
        Observer.Observe('rows after own ns', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94359">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import own ns', 'ok');
        Observer.Expect('rows after own ns', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;9/nine/9.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_UdnTattr()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94360, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94360, '<Root Ver="v9"><Item><Id>7</Id><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94360, '<Root xmlns="urn:y83" Ver="v9"><Item><Id>8</Id><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import own ns', Helper.TryImport(94360, '<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x94360" Ver="v9"><Item><Id>9</Id><Name>  nine  </Name><Amt>9.5</Amt></Item></Root>', false));
        Observer.Observe('rows after own ns', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root Ver="v1" xmlns="urn:microsoft-dynamics-nav/xmlports/x94360">|  <Item>|    <Id>1</Id>|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item>|    <Id>2</Id>|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import own ns', 'ok');
        Observer.Expect('rows after own ns', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;9/nine/9.5/false//0;');
        Observer.Verify();
    end;

    [Test]
    procedure Ns_PrefixAttrOnly()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExport(94361, TextEncoding::UTF16));
        Observer.Observe('import plain', Helper.TryImport(94361, '<Root><Item Id="7"><Name>  seven  </Name><Amt>7.25</Amt></Item></Root>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import dn', Helper.TryImport(94361, '<Root xmlns="urn:y83"><Item Id="8"><Name>  eight  </Name><Amt>8.5</Amt></Item></Root>', false));
        Observer.Observe('rows after dn', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(94361, '<Root xmlns:p="urn:y83-p"><Item p:Id="10"><Name>  ten  </Name><Amt>10.5</Amt></Item></Root>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root xmlns:p="urn:y83-p">|  <Item Id="1">|    <Name>one</Name>|    <Amt>1.50</Amt>|  </Item>|  <Item Id="2">|    <Name>  two  </Name>|    <Amt>2.01</Amt>|  </Item>|</Root>|');
        Observer.Expect('import plain', 'ok');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;7/seven/7.25/false//0;');
        Observer.Expect('import dn', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('rows after dn', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'error:Imported XML cannot validate with the schema: The ''urn:y83-p:Id'' attribute is not declared.|XmlPortInvalidXml');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    local procedure CrLf(): Text
    begin
        exit(Helper.CrLf());
    end;
}
