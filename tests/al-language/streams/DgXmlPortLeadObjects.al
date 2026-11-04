// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: none (own tables 86020-86022, xmlports 86023-86029 and 86031-86033)
// Shared objects of DgXmlPortLeads.al (corpus issue 671, items 106 to 111): not a test codeunit.
// BC versions: 27, 28, 29

table 86020 "LT DG Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Flag; Boolean) { }
        field(4; Long; Text[2048]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86021 "LT DG Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86022 "LT DG Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Item 106: two root tables, no separator property declared.
xmlport 86023 "LT DG Csv Two Default"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
            tableelement(LineRow; "LT DG Line")
            {
                fieldelement(Id; LineRow.Id) { }
                fieldelement(Note; LineRow.Note) { }
            }
        }
    }
}

// Item 106: two root tables, TableSeparator = '<NewLine>' declared (the value the old docs called the default).
xmlport 86024 "LT DG Csv Two NewLine"
{
    Format = VariableText;
    Direction = Export;
    TableSeparator = '<NewLine>';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
            tableelement(LineRow; "LT DG Line")
            {
                fieldelement(Id; LineRow.Id) { }
                fieldelement(Note; LineRow.Note) { }
            }
        }
    }
}

// Item 107: a Boolean field in an Xml xmlport with FormatEvaluate = Legacy (the format microsoft/AL issue 7243 describes).
xmlport 86025 "LT DG Xml Bool Legacy"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Legacy;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Flag; ItemRow.Flag) { }
            }
        }
    }
}

// Item 107: the same with FormatEvaluate = Xml.
xmlport 86026 "LT DG Xml Bool Xml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Flag; ItemRow.Flag) { }
            }
        }
    }
}

// Item 107: a Boolean field in a VariableText xmlport (no FormatEvaluate declared).
xmlport 86027 "LT DG Csv Bool"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Flag; ItemRow.Flag) { }
            }
        }
    }
}

// Item 109: the xmlport of microsoft/AL issue 246 (SOAP envelope with prefixed text elements, DefaultNamespace and UseDefaultNamespace).
xmlport 86028 "LT DG Soap"
{
    Format = Xml;
    Direction = Export;
    DefaultNamespace = 'http://tempuri.org/';
    Encoding = UTF8;
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', xsd = 'http://www.w3.org/2001/XMLSchema', xsi = 'http://www.w3.org/2001/XMLSchema-instance';
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(Envelope)
        {
            NamespacePrefix = 'soap';
            textelement(Body)
            {
                NamespacePrefix = 'soap';
                tableelement(ValidateLicense; "LT DG Item")
                {
                    fieldelement(session; ValidateLicense.Name) { }
                    fieldelement(instance; ValidateLicense.Id) { }
                }
            }
        }
    }
}

// Item 110: a long value imported into a text element (a Text variable without a length) and into a Text[2048] field.
xmlport 86029 "LT DG Long Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Txt)
            {
                MinOccurs = Zero;
            }
            tableelement(ItemRow; "LT DG Item")
            {
                MinOccurs = Zero;
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Long; ItemRow.Long) { }
            }
        }
    }

    procedure TxtLength(): Integer
    begin
        exit(StrLen(Txt));
    end;
}

// Item 108: an empty prefix (quoted identifier "") in Namespaces together with UseDefaultNamespace = true. It compiles (the unquoted '' does not: case 1856).
xmlport 86031 "LT DG Ns Empty Prefix"
{
    Format = Xml;
    Direction = Export;
    Namespaces = "" = 'urn:lt-dg-empty';
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
            }
        }
    }
}

// Item 108: a NamespacePrefix that Namespaces does not declare. It compiles.
xmlport 86032 "LT DG Ns Undeclared"
{
    Format = Xml;
    Direction = Export;
    Namespaces = p = 'urn:lt-dg-p';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            NamespacePrefix = 'q';
            tableelement(ItemRow; "LT DG Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
            }
        }
    }
}

// Item 108: a NamespacePrefix on an xmlport without a Namespaces property. It compiles.
xmlport 86033 "LT DG Ns No Namespaces"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT DG Item")
            {
                XmlName = 'Item';
                NamespacePrefix = 'p';
                fieldelement(Id; ItemRow.Id) { }
            }
        }
    }
}
