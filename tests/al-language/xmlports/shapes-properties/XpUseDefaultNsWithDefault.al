// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usedefaultnamespace-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-defaultnamespace-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Item and LT Y83 Helper (Y83XpFixtures.al); xmlports 96030-96035, test codeunit 96036
// Probe: an Xml port with Namespaces (soap, tem), DefaultNamespace and UseDefaultNamespace = true (al-runner issue 7131). The reporter's
//   shape: Envelope (soap) > Body (soap) > ReceiveMessage (tem) > InputMsg (no prefix) > a leaf text element Value (no prefix).
//   Neighbours: a table element without a prefix below InputMsg (a field element with a prefix, one without), a root without a prefix,
//   a root with the prefix of the second namespace, a table element root (MaxOccurs = Once), and the default encoding (UTF-16). Each
//   port: the exact text the export writes (two items, 1 one and 2 "  two  "); for three ports the imports of three documents (as the
//   export writes it, every element with its prefix, no namespaces) and the rows after each import.
// Result (BC 27.5, 28.5 and 29.0 alike; corpus CI runs 42111762161, 42111802269, 42111843665): as without DefaultNamespace
//   (XpUseDefaultNsPrefixes.al) with the DefaultNamespace in place of BC's namespace of the port. The root loses its prefix and declares
//   xmlns as the uri of that prefix after the named namespaces (the DefaultNamespace for a root without a prefix); an element without a
//   prefix declares xmlns="<DefaultNamespace>" where the namespace in scope differs, its children inherit it; prefixed elements keep
//   their prefix. UTF-16 writes the same text. Every import fails with "The prefix  is not defined in the Namespaces property of the
//   XMLPort." (XmlPortNodeProcess), whatever the document, and the rows stay.
// BC versions: 27, 28, 29
// Follow-up (al-runner issues 7131, 7091 and 7192; xmlports 96042-96044, tests XDN_AttrDefault_Export to XDN_AttrPrefixed_Export; corpus CI
//   run 42246543615 for BC 27.5, 28.5 and 29.0, all alike): a field attribute on a table element does not change the namespaces. The root
//   loses its prefix and declares xmlns as the soap uri, InputMsg declares the DefaultNamespace (or the namespace of the port,
//   urn:microsoft-dynamics-nav/xmlports/x96043, without one), the attribute is written as `Type="1"` without a namespace, and so are
//   attributes written with NamespacePrefix = 'soap' or a text attribute (`Ver="v1"`). Every import of these ports is refused with
//   "The prefix  is not defined in the Namespaces property of the XMLPort." (XmlPortNodeProcess), as for the ports without an attribute.

// The reporter's shape.
xmlport 96030 "LT XDN Text Leaf"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    textelement(InputMsg)
                    {
                        textelement(Value)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Value := 'V1';
                            end;
                        }
                    }
                }
            }
        }
    }
}

// A table element without a prefix below InputMsg.
xmlport 96031 "LT XDN Item"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    textelement(InputMsg)
                    {
                        tableelement(Rw; "LT Y83 Item")
                        {
                            XmlName = 'Item';
                            fieldelement(Id; Rw.Id) { NamespacePrefix = 'tem'; }
                            fieldelement(Name; Rw.Name) { }
                        }
                    }
                }
            }
        }
    }
}

// The root has no prefix.
xmlport 96032 "LT XDN Root Plain"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                tableelement(Rw; "LT Y83 Item")
                {
                    XmlName = 'Item';
                    fieldelement(Id; Rw.Id) { NamespacePrefix = 'tem'; }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// The root has the prefix of the second namespace.
xmlport 96033 "LT XDN Root Second"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'tem';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                tableelement(Rw; "LT Y83 Item")
                {
                    XmlName = 'Item';
                    fieldelement(Id; Rw.Id) { NamespacePrefix = 'tem'; }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// A table element root (MaxOccurs = Once) with the prefix of the first namespace.
xmlport 96034 "LT XDN Table Root"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            NamespacePrefix = 'soap';
            XmlName = 'Envelope';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                fieldelement(Id; Rw.Id) { NamespacePrefix = 'tem'; }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

// The shape of 96031 with the default encoding (UTF-16).
xmlport 96035 "LT XDN Item Utf16"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    textelement(InputMsg)
                    {
                        tableelement(Rw; "LT Y83 Item")
                        {
                            XmlName = 'Item';
                            fieldelement(Id; Rw.Id) { NamespacePrefix = 'tem'; }
                            fieldelement(Name; Rw.Name) { }
                        }
                    }
                }
            }
        }
    }
}

codeunit 96036 "LT XDN Namespace Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    [Test]
    procedure XDN_TextLeaf_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96030, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:ReceiveMessage>\r\n      <InputMsg xmlns="urn:lt:xdn:input">\r\n        <Value>V1</Value>\r\n      </InputMsg>\r\n    </tem:ReceiveMessage>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_TextLeaf_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(96030, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:ReceiveMessage><InputMsg xmlns="urn:lt:xdn:input"><Value>V7</Value></InputMsg></tem:ReceiveMessage></soap:Body></Envelope>', false));
        Observer.Observe('import prefixed', Helper.TryImport(96030, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="urn:lt:xdn:input"><soap:Body><tem:ReceiveMessage><InputMsg><Value>V8</Value></InputMsg></tem:ReceiveMessage></soap:Body></soap:Envelope>', false));
        Observer.Observe('import plain', Helper.TryImport(96030, '<Envelope><Body><ReceiveMessage><InputMsg><Value>V9</Value></InputMsg></ReceiveMessage></Body></Envelope>', false));
        Observer.Expect('import default', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('import prefixed', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('import plain', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_Item_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96031, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:ReceiveMessage>\r\n      <InputMsg xmlns="urn:lt:xdn:input">\r\n        <Item>\r\n          <tem:Id>1</tem:Id>\r\n          <Name>one</Name>\r\n        </Item>\r\n        <Item>\r\n          <tem:Id>2</tem:Id>\r\n          <Name>  two  </Name>\r\n        </Item>\r\n      </InputMsg>\r\n    </tem:ReceiveMessage>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_Item_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(96031, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:ReceiveMessage><InputMsg xmlns="urn:lt:xdn:input"><Item><tem:Id>7</tem:Id><Name>n7</Name></Item></InputMsg></tem:ReceiveMessage></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(96031, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="urn:lt:xdn:input"><soap:Body><tem:ReceiveMessage><InputMsg><Item><tem:Id>8</tem:Id><Name>n8</Name></Item></InputMsg></tem:ReceiveMessage></soap:Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(96031, '<Envelope><Body><ReceiveMessage><InputMsg><Item><Id>9</Id><Name>n9</Name></Item></InputMsg></ReceiveMessage></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Expect('import default', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after default', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import plain', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_RootPlain_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96032, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="urn:lt:xdn:input">\r\n  <soap:Body>\r\n    <Item>\r\n      <tem:Id>1</tem:Id>\r\n      <Name>one</Name>\r\n    </Item>\r\n    <Item>\r\n      <tem:Id>2</tem:Id>\r\n      <Name>  two  </Name>\r\n    </Item>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_RootSecond_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96033, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://tempuri.org/">\r\n  <soap:Body>\r\n    <Item xmlns="urn:lt:xdn:input">\r\n      <tem:Id>1</tem:Id>\r\n      <Name>one</Name>\r\n    </Item>\r\n    <Item xmlns="urn:lt:xdn:input">\r\n      <tem:Id>2</tem:Id>\r\n      <Name>  two  </Name>\r\n    </Item>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_TableRoot_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96034, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:Id>1</tem:Id>\r\n    <Name xmlns="urn:lt:xdn:input">one</Name>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_TableRoot_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(96034, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:Id>7</tem:Id><Name xmlns="urn:lt:xdn:input">n7</Name></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(96034, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="urn:lt:xdn:input"><soap:Body><tem:Id>8</tem:Id><Name>n8</Name></soap:Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(96034, '<Envelope><Body><Id>9</Id><Name>n9</Name></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Expect('import default', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after default', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import prefixed', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after prefixed', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import plain', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_ItemUtf16_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96035, TextEncoding::UTF16));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:ReceiveMessage>\r\n      <InputMsg xmlns="urn:lt:xdn:input">\r\n        <Item>\r\n          <tem:Id>1</tem:Id>\r\n          <Name>one</Name>\r\n        </Item>\r\n        <Item>\r\n          <tem:Id>2</tem:Id>\r\n          <Name>  two  </Name>\r\n        </Item>\r\n      </InputMsg>\r\n    </tem:ReceiveMessage>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_AttrDefault_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96042, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:ReceiveMessage>\r\n      <InputMsg xmlns="urn:lt:xdn:input">\r\n        <Remark Type="1">\r\n          <Text>one</Text>\r\n        </Remark>\r\n        <Remark Type="2">\r\n          <Text>  two  </Text>\r\n        </Remark>\r\n      </InputMsg>\r\n    </tem:ReceiveMessage>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_AttrDefault_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(96042, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:ReceiveMessage><InputMsg xmlns="urn:lt:xdn:input"><Remark Type="7"><Text>n7</Text></Remark></InputMsg></tem:ReceiveMessage></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(96042, '<Envelope><Body><ReceiveMessage><InputMsg><Remark Type="8"><Text>n8</Text></Remark></InputMsg></ReceiveMessage></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Observer.Expect('import default', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after default', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import plain', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_AttrNoDefault_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96043, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:ReceiveMessage>\r\n      <InputMsg xmlns="urn:microsoft-dynamics-nav/xmlports/x96043">\r\n        <Remark Type="1">\r\n          <Text>one</Text>\r\n        </Remark>\r\n        <Remark Type="2">\r\n          <Text>  two  </Text>\r\n        </Remark>\r\n      </InputMsg>\r\n    </tem:ReceiveMessage>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_AttrNoDefault_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(96043, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:ReceiveMessage><InputMsg xmlns="urn:microsoft-dynamics-nav/xmlports/x96043"><Remark Type="7"><Text>n7</Text></Remark></InputMsg></tem:ReceiveMessage></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(96043, '<Envelope><Body><ReceiveMessage><InputMsg><Remark Type="8"><Text>n8</Text></Remark></InputMsg></ReceiveMessage></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Observer.Expect('import default', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after default', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Expect('import plain', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('rows after plain', '1/one/1.5/true/2024-03-05/5;2/  two  /2.005/false//6;');
        Observer.Verify();
    end;

    [Test]
    procedure XDN_AttrPrefixed_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96044, TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <tem:InputMsg Ver="v1">\r\n      <Remark Type="1" xmlns="urn:lt:xdn:input">\r\n        <Text>one</Text>\r\n      </Remark>\r\n      <Remark Type="2" xmlns="urn:lt:xdn:input">\r\n        <Text>  two  </Text>\r\n      </Remark>\r\n    </tem:InputMsg>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;
}

// Follow-up to al-runner issue 7131 (and 7091): Namespaces and UseDefaultNamespace = true on a port with a fieldattribute.
// The reporter's shape with a DefaultNamespace: Envelope (soap) > Body (soap) > ReceiveMessage (tem) > InputMsg (no prefix) > a table
// element Remark with a fieldattribute and a field element.
xmlport 96042 "LT XDN Attr Default"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    textelement(InputMsg)
                    {
                        tableelement(Rm; "LT Y83 Item")
                        {
                            XmlName = 'Remark';
                            fieldattribute(Type; Rm.Id) { }
                            fieldelement(Text; Rm.Name) { }
                        }
                    }
                }
            }
        }
    }
}

// The same without a DefaultNamespace (the shape of issue 7091): InputMsg takes the namespace of the port.
xmlport 96043 "LT XDN Attr NoDefault"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    textelement(InputMsg)
                    {
                        tableelement(Rm; "LT Y83 Item")
                        {
                            XmlName = 'Remark';
                            fieldattribute(Type; Rm.Id) { }
                            fieldelement(Text; Rm.Name) { }
                        }
                    }
                }
            }
        }
    }
}

// Neighbour: a text attribute on InputMsg, and a field attribute with a prefix, with a DefaultNamespace.
xmlport 96044 "LT XDN Attr Prefixed"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:lt:xdn:input';
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(InputMsg)
                {
                    NamespacePrefix = 'tem';
                    textattribute(Ver)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Ver := 'v1';
                        end;
                    }
                    tableelement(Rm; "LT Y83 Item")
                    {
                        XmlName = 'Remark';
                        fieldattribute(Type; Rm.Id) { NamespacePrefix = 'soap'; }
                        fieldelement(Text; Rm.Name) { }
                    }
                }
            }
        }
    }
}
