// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Item, LT Y83 Child and LT Y83 Helper (Y83XpFixtures.al); xmlports 96020-96027, test codeunit 96028
// Probe: an Xml port whose root is a table element with text elements below it that hold content (al-runner issue 7130). The
//   reporter's shape: the root table element (MaxOccurs = Once, XmlName Envelope) holds an empty leaf text element and a text element
//   that holds text elements nested in each other, down to a table element. Neighbours: a text element holding field elements, a text
//   element holding a table element, two text levels holding field elements, a field element of the root before a nested text element,
//   a root table element without MaxOccurs (two rows), and with Namespaces and UseDefaultNamespace = true (prefixes on the elements).
//   Each port: the exact text the export writes with the seeded rows; some with an empty field value, no root rows or no inner rows;
//   the imports of the shapes without namespaces and the rows after them.
// Result: observed, see the assertions.
// BC versions: 27, 28, 29

// A text element below the root table element holds field elements.
xmlport 96020 "LT XNT Txt Field"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            textelement(Body)
            {
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

// A text element below the root table element holds a table element (not linked).
xmlport 96021 "LT XNT Txt Tbl"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            textelement(Body)
            {
                tableelement(Ch; "LT Y83 Child")
                {
                    XmlName = 'Line';
                    fieldelement(Id; Ch.Id) { }
                    fieldelement(Txt; Ch.Txt) { }
                }
            }
        }
    }
}

// Two text levels below the root table element hold field elements.
xmlport 96022 "LT XNT Txt Txt Field"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            textelement(Body)
            {
                textelement(Inner)
                {
                    fieldelement(Id; Rw.Id) { }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// The reporter's shape without namespaces: an empty leaf text element, then three text levels down to a table element.
xmlport 96023 "LT XNT Txt Txt Tbl"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            textelement(Header) { }
            textelement(Body)
            {
                textelement(Msg)
                {
                    textelement(Refs)
                    {
                        tableelement(Ch; "LT Y83 Child")
                        {
                            XmlName = 'Line';
                            fieldelement(Id; Ch.Id) { }
                            fieldelement(Txt; Ch.Txt) { }
                        }
                    }
                }
            }
        }
    }
}

// A field element of the root table element before a nested text element.
xmlport 96024 "LT XNT Field Txt"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            fieldelement(Id; Rw.Id) { }
            textelement(Body)
            {
                textelement(Inner)
                {
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// The root table element without MaxOccurs: one root per row.
xmlport 96025 "LT XNT Rows"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            XmlName = 'Envelope';
            textelement(Body)
            {
                textelement(Inner)
                {
                    fieldelement(Id; Rw.Id) { }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// With Namespaces and UseDefaultNamespace = true: Body > ReceiveMessage > field elements (one without a prefix).
xmlport 96026 "LT XNT Ns Txt Field"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/', msg = 'urn:lt:xnt:msg';
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
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    fieldelement(Id; Rw.Id) { NamespacePrefix = 'msg'; }
                    fieldelement(Name; Rw.Name) { }
                }
            }
        }
    }
}

// The reporter's shape with Namespaces and UseDefaultNamespace = true: Header, then Body > ReceiveMessage > a table element.
xmlport 96027 "LT XNT Ns Txt Tbl"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/', msg = 'urn:lt:xnt:msg';
    UseDefaultNamespace = true;

    schema
    {
        tableelement(Rw; "LT Y83 Item")
        {
            MaxOccurs = Once;
            NamespacePrefix = 'soap';
            XmlName = 'Envelope';
            textelement(Header) { NamespacePrefix = 'soap'; }
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                textelement(ReceiveMessage)
                {
                    NamespacePrefix = 'tem';
                    tableelement(Ch; "LT Y83 Child")
                    {
                        NamespacePrefix = 'tem';
                        XmlName = 'Line';
                        fieldelement(Id; Ch.Id) { NamespacePrefix = 'msg'; }
                        fieldelement(Txt; Ch.Txt) { }
                    }
                }
            }
        }
    }
}

codeunit 96028 "LT XNT Table Root Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    local procedure EmptyName()
    var
        Item: Record "LT Y83 Item";
    begin
        Item.Get(1);
        Item.Name := '';
        Item.Modify();
        Commit();
    end;

    local procedure NoItems()
    var
        Item: Record "LT Y83 Item";
    begin
        Item.DeleteAll();
        Commit();
    end;

    local procedure NoChildren()
    var
        Child: Record "LT Y83 Child";
    begin
        Child.DeleteAll();
        Commit();
    end;

    [Test]
    procedure XNT_TxtField_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96020, TextEncoding::UTF8));
        EmptyName();
        Observer.Observe('export empty name', Helper.TryExportRaw(96020, TextEncoding::UTF8));
        NoItems();
        Observer.Observe('export no rows', Helper.TryExportRaw(96020, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtField_Import()
    begin
        Helper.Seed();
        Observer.Observe('import', Helper.TryImport(96020, '<Envelope><Body><Id>7</Id><Name>n7</Name></Body></Envelope>', false));
        Observer.Observe('rows after import', Helper.Rows());
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTbl_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96021, TextEncoding::UTF8));
        NoChildren();
        Observer.Observe('export no lines', Helper.TryExportRaw(96021, TextEncoding::UTF8));
        NoItems();
        Observer.Observe('export no rows', Helper.TryExportRaw(96021, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTbl_Import()
    begin
        Helper.Seed();
        Observer.Observe('import', Helper.TryImport(96021, '<Envelope><Body><Line><Id>7</Id><Txt>t7</Txt></Line><Line><Id>8</Id><Txt>t8</Txt></Line></Body></Envelope>', false));
        Observer.Observe('rows after import', Helper.Rows());
        Observer.Observe('children after import', Helper.ChildRows());
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTxtField_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96022, TextEncoding::UTF8));
        EmptyName();
        Observer.Observe('export empty name', Helper.TryExportRaw(96022, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTxtField_Import()
    begin
        Helper.Seed();
        Observer.Observe('import', Helper.TryImport(96022, '<Envelope><Body><Inner><Id>7</Id><Name>n7</Name></Inner></Body></Envelope>', false));
        Observer.Observe('rows after import', Helper.Rows());
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTxtTbl_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96023, TextEncoding::UTF8));
        NoChildren();
        Observer.Observe('export no lines', Helper.TryExportRaw(96023, TextEncoding::UTF8));
        NoItems();
        Observer.Observe('export no rows', Helper.TryExportRaw(96023, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_TxtTxtTbl_Import()
    begin
        Helper.Seed();
        Observer.Observe('import', Helper.TryImport(96023, '<Envelope><Header /><Body><Msg><Refs><Line><Id>7</Id><Txt>t7</Txt></Line></Refs></Msg></Body></Envelope>', false));
        Observer.Observe('rows after import', Helper.Rows());
        Observer.Observe('children after import', Helper.ChildRows());
        Observer.Finish();
    end;

    [Test]
    procedure XNT_FieldTxt_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96024, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_Rows_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96025, TextEncoding::UTF8));
        NoItems();
        Observer.Observe('export no rows', Helper.TryExportRaw(96025, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_NsTxtField_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96026, TextEncoding::UTF8));
        EmptyName();
        Observer.Observe('export empty name', Helper.TryExportRaw(96026, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XNT_NsTxtTbl_Export()
    begin
        Helper.Seed();
        Observer.Observe('export', Helper.TryExportRaw(96027, TextEncoding::UTF8));
        NoChildren();
        Observer.Observe('export no lines', Helper.TryExportRaw(96027, TextEncoding::UTF8));
        Observer.Finish();
    end;
}
