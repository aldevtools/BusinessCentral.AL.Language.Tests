// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Probe: generated ports, see Y83XpNsTests.al

xmlport 94340 "LT Y83 NS dn_only"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94341 "LT Y83 NS dn_false_utf8"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    UseDefaultNamespace = false;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94342 "LT Y83 NS dn_nsprefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    Namespaces = p = 'urn:y83-p';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94343 "LT Y83 NS dn_nsprefix_utf8"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    Namespaces = p = 'urn:y83-p';
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94344 "LT Y83 NS dn_lax"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    UseLax = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94345 "LT Y83 NS dn_pws"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94346 "LT Y83 NS dn_inline"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94347 "LT Y83 NS dn_v11"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y83';
    XmlVersionNo = V11;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94348 "LT Y83 NS pws"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94349 "LT Y83 NS pws_prefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;
    Namespaces = p = 'urn:y83-p';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94350 "LT Y83 NS pws_udn_dn"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;
    UseDefaultNamespace = true;
    DefaultNamespace = 'urn:y83';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94351 "LT Y83 NS pws_utf8_prefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;
    Encoding = UTF8;
    Namespaces = p = 'urn:y83-p';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94352 "LT Y83 NS pws_utf8_lax"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;
    Encoding = UTF8;
    UseLax = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94353 "LT Y83 NS pws_vt"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    PreserveWhiteSpace = true;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94354 "LT Y83 NS udn_prefix"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    Namespaces = p = 'urn:y83-p';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94355 "LT Y83 NS udn_dn_prefix_utf8"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    DefaultNamespace = 'urn:y83';
    Namespaces = p = 'urn:y83-p';
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) { NamespacePrefix = 'p'; }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94356 "LT Y83 NS udn_dn_eprefix_utf8"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    DefaultNamespace = 'urn:y83';
    Namespaces = "" = 'urn:y83-e';
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94357 "LT Y83 NS udn_lax"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    UseLax = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94358 "LT Y83 NS udn_inline"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    InlineSchema = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94359 "LT Y83 NS udn_v11"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;
    XmlVersionNo = V11;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

xmlport 94360 "LT Y83 NS udn_tattr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseDefaultNamespace = true;

    schema
    {
        textelement(Root)
        {
            textattribute(Ver) { }
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) {  }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Ver := 'v1';
    end;}

xmlport 94361 "LT Y83 NS prefix_attr_only"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    Namespaces = p = 'urn:y83-p';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; Rw.Id) { NamespacePrefix = 'p'; }
                fieldelement(Name; Rw.Name) {  }
                fieldelement(Amt; Rw.Amt) {  }
            }
        }
    }
}

