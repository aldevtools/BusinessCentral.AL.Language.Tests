// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usedefaultnamespace-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Item and LT Y83 Helper (Y83XpFixtures.al); xmlports 95890-95896, test codeunit 95897
// Probe: an Xml port with Namespaces (soap, tem) and UseDefaultNamespace = true but no DefaultNamespace (al-runner issue 7091). The
//   reporter's shape: the root has NamespacePrefix soap (the first namespace declared), the elements below it have prefixes too. Neighbours:
//   a text element root, a root with the prefix of the second namespace, a root without a prefix, the default encoding (UTF-16), a prefix on
//   the root only, and a prefix on the table element. Each port: the exact text the export writes (two items, 1 one and 2 "  two  "), and
//   imports of three documents: the root without a prefix and xmlns set to the uri of the root's prefix (the reporter's BC export), every
//   element with its prefix, and no namespaces at all; the rows after each import.
// BC versions: 27, 28, 29

// The reporter's shape: the root is a table element (MaxOccurs = Once) with the prefix of the first namespace.
xmlport 95890 "LT XUD Table Root"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
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

// The root is a text element with the prefix of the first namespace; the table element has no prefix.
xmlport 95891 "LT XUD Text Root"
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
xmlport 95892 "LT XUD Root Second"
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

// The root has no prefix; the elements below it do.
xmlport 95893 "LT XUD Root Plain"
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

// As LT XUD Text Root, with the default encoding (UTF-16).
xmlport 95894 "LT XUD Text Root Utf16"
{
    Direction = Both;
    Format = Xml;
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

// Only the root has a prefix.
xmlport 95895 "LT XUD Root Only"
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
                tableelement(Rw; "LT Y83 Item")
                {
                    XmlName = 'Item';
                    fieldelement(Id; Rw.Id) { }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// The root has the prefix of the first namespace, the table element the prefix of the second.
xmlport 95896 "LT XUD Item Prefix"
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
                tableelement(Rw; "LT Y83 Item")
                {
                    XmlName = 'Item';
                    NamespacePrefix = 'tem';
                    fieldelement(Id; Rw.Id) { }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

codeunit 95897 "LT XUD Namespace Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    [Test]
    procedure XUD_TableRoot_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95890, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_TableRoot_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95890, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:Id>7</tem:Id><Name>n7</Name></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95890, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><tem:Id>8</tem:Id><Name>n8</Name></soap:Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95890, '<Envelope><Body><Id>9</Id><Name>n9</Name></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_TextRoot_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95891, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_TextRoot_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95891, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Item><tem:Id>7</tem:Id><Name>n7</Name></Item></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95891, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><Item><tem:Id>8</tem:Id><Name>n8</Name></Item></soap:Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95891, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootSecond_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95892, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootSecond_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95892, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://tempuri.org/"><soap:Body><Item><tem:Id>7</tem:Id><Name>n7</Name></Item></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95892, '<tem:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><Item><tem:Id>8</tem:Id><Name>n8</Name></Item></soap:Body></tem:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95892, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootPlain_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95893, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootPlain_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95893, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><Item><tem:Id>7</tem:Id><Name>n7</Name></Item></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95893, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><Item><tem:Id>8</tem:Id><Name>n8</Name></Item></soap:Body></Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95893, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_TextRootUtf16_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95894, TextEncoding::UTF16));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_TextRootUtf16_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95894, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Item><tem:Id>7</tem:Id><Name>n7</Name></Item></soap:Body></Envelope>', true));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95894, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><Item><tem:Id>8</tem:Id><Name>n8</Name></Item></soap:Body></soap:Envelope>', true));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95894, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', true));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootOnly_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95895, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_RootOnly_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95895, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><Item><Id>7</Id><Name>n7</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95895, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><Body><Item><Id>8</Id><Name>n8</Name></Item></Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95895, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;

    [Test]
    procedure XUD_ItemPrefix_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(95896, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XUD_ItemPrefix_Import()
    begin
        Helper.Seed();
        Observer.Observe('import default', Helper.TryImport(95896, '<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><tem:Item><Id>7</Id><Name>n7</Name></tem:Item></soap:Body></Envelope>', false));
        Observer.Observe('rows after default', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import prefixed', Helper.TryImport(95896, '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soap:Body><tem:Item><Id>8</Id><Name>n8</Name></tem:Item></soap:Body></soap:Envelope>', false));
        Observer.Observe('rows after prefixed', Helper.Rows());
        Helper.Seed();
        Observer.Observe('import plain', Helper.TryImport(95896, '<Envelope><Body><Item><Id>9</Id><Name>n9</Name></Item></Body></Envelope>', false));
        Observer.Observe('rows after plain', Helper.Rows());
        Helper.Seed();
        Observer.Finish();
    end;
}
