// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: own tables of Fixtures.al (73406-73409)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort fixtures (tag XpT), not test codeunits.
// BC versions: 29 (27 and 28 by CI)

xmlport 73410 "LT XpT Xml Items"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
                fieldelement(Amount; ItemRow.Amount) { }
                fieldelement(Active; ItemRow.Active) { }
                fieldelement(Category; ItemRow.Category) { }
                fieldelement(StampDate; ItemRow.StampDate) { }
            }
        }
    }
}

xmlport 73411 "LT XpT Xml Attr"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldattribute(Id; ItemRow.Id) { }
                fieldattribute(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
            }
        }
    }
}

xmlport 73412 "LT XpT Xml Link"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                tableelement(LineRow; "LT XpT Line")
                {
                    XmlName = 'Line';
                    LinkFields = ItemId = field(Id);
                    LinkTable = ItemRow;
                    fieldelement(LineId; LineRow.Id) { }
                    fieldelement(Descr; LineRow.Descr) { }
                }
            }
        }
    }
}

xmlport 73413 "LT XpT Csv"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '"';
    FieldSeparator = ',';
    RecordSeparator = '<NewLine>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

xmlport 73414 "LT XpT Csv Semi"
{
    Format = VariableText;
    Direction = Both;
    FieldDelimiter = '<None>';
    FieldSeparator = ';';
    RecordSeparator = '<LF>';
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

xmlport 73415 "LT XpT Export Only"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73416 "LT XpT Import Only"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73417 "LT XpT Xml Ns Prefix"
{
    Format = Xml;
    Direction = Both;
    Namespaces = ns1 = 'urn:lt:xpt';
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            NamespacePrefix = 'ns1';
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                NamespacePrefix = 'ns1';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73418 "LT XpT Xml Ns Default"
{
    Format = Xml;
    Direction = Both;
    DefaultNamespace = 'urn:lt:xpt';
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73419 "LT XpT Xml Opt"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Qty; ItemRow.Qty) { }
                fieldelement(Category; ItemRow.Category)
                {
                    MinOccurs = Zero;
                }
            }
        }
    }
}

xmlport 73420 "LT XpT Xml Utf16"
{
    Format = Xml;
    Direction = Both;
    Encoding = UTF16;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73421 "LT XpT Xml Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Doc)
        {
            textattribute(Ver) { }
            textelement(Title) { }
        }
    }

    trigger OnPreXmlPort()
    begin
        if not currXMLport.ImportFile() then begin
            Ver := 'v1';
            Title := 'Hello & <World> "q" ''s'' ü €';
        end;
    end;

    trigger OnPostXmlPort()
    var
        Hold: Record "LT XpT Item";
    begin
        if currXMLport.ImportFile() then begin
            Hold.Id := 9999;
            Hold.Name := CopyStr(Title + '|' + Ver, 1, MaxStrLen(Hold.Name));
            Hold.Insert();
        end;
    end;
}

xmlport 73422 "LT XpT Xml Active"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                SourceTableView = sorting(Qty) order(descending) where(Active = const(true));
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
            }
        }
    }
}

xmlport 73424 "LT XpT Xml Skip"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
                trigger OnAfterGetRecord()
                begin
                    if ItemRow.Qty = 20 then
                        currXMLport.Skip();
                end;
            }
        }
    }
}

xmlport 73425 "LT XpT Xml Break"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
                trigger OnAfterGetRecord()
                begin
                    if ItemRow.Id = 2 then
                        currXMLport.Break();
                end;
            }
        }
    }
}

xmlport 73426 "LT XpT Xml AutoRep"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                AutoReplace = true;
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
            }
        }
    }
}

xmlport 73427 "LT XpT Xml AutoUpd"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                AutoUpdate = true;
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
            }
        }
    }
}

xmlport 73428 "LT XpT Xml NoSave"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                AutoSave = false;
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
            }
        }
    }
}

xmlport 73431 "LT XpT Xml FmtXml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
                fieldelement(Amount; ItemRow.Amount) { }
                fieldelement(Active; ItemRow.Active) { }
                fieldelement(Category; ItemRow.Category) { }
                fieldelement(StampDate; ItemRow.StampDate) { }
            }
        }
    }
}

xmlport 73432 "LT XpT Xml FmtLegacy"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Legacy;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
                fieldelement(Qty; ItemRow.Qty) { }
                fieldelement(Amount; ItemRow.Amount) { }
                fieldelement(Active; ItemRow.Active) { }
                fieldelement(Category; ItemRow.Category) { }
                fieldelement(StampDate; ItemRow.StampDate) { }
            }
        }
    }
}

xmlport 73433 "LT XpT Csv Win"
{
    Format = VariableText;
    Direction = Both;
    FieldSeparator = ',';
    TextEncoding = WINDOWS;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

xmlport 73434 "LT XpT Csv Utf16"
{
    Format = VariableText;
    Direction = Both;
    FieldSeparator = ',';
    TextEncoding = UTF16;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

xmlport 73435 "LT XpT Xml Preserve"
{
    Format = Xml;
    Direction = Both;
    PreserveWhiteSpace = true;
    UseRequestPage = false;
    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT XpT Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }
            }
        }
    }
}

xmlport 73436 "LT XpT Csv Hdr"
{
    Format = VariableText;
    Direction = Both;
    FieldSeparator = ',';
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

xmlport 73437 "LT XpT Csv MSDos"
{
    Format = VariableText;
    Direction = Both;
    FieldSeparator = ',';
    TextEncoding = MSDOS;
    UseRequestPage = false;
    schema
    {
        tableelement(ItemRow; "LT XpT Item")
        {
            fieldelement(Id; ItemRow.Id) { }
            fieldelement(Name; ItemRow.Name) { }
            fieldelement(Qty; ItemRow.Qty) { }
            fieldelement(Amount; ItemRow.Amount) { }
            fieldelement(Active; ItemRow.Active) { }
        }
    }
}

