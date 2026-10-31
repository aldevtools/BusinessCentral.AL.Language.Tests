// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-namespaces-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: gap cycle 1, G15 (corpus writer Y17). XmlPort export with Namespaces = "" = 'uri', a = .., b = .., u = .. and no UseDefaultNamespace
// (the shape of the PEPPOL BIS 3.0 ports): which xmlns declarations the root gets and in which order, which namespace an element without
// NamespacePrefix is in, the "" entry listed last, the same with UseDefaultNamespace + DefaultNamespace, prefixed entries only, and import of the
// exported text. Neighbours already pinned: xmlport/lt-bd-xmlport/BdXmlPort.al:407 (prefixed entries only), xmlport/lt-dg-xmlport-leads/DgXmlPortLeads.al:280, :310.
// BC versions: 27-29

table 91830 "LT Y17 Ns Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 91831 "LT Y17 Ns Empty First"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "" = 'urn:lt-d', a = 'urn:lt-a', b = 'urn:lt-b', u = 'urn:lt-unused';

    schema
    {
        tableelement(Hdr; Integer)
        {
            XmlName = 'Doc';
            MaxOccurs = Once;
            SourceTableView = where(Number = filter(1 ..));
            textelement(DocId)
            {
                NamespacePrefix = 'b';
            }
            textelement(Opt)
            {
                NamespacePrefix = 'b';

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement(Party)
            {
                NamespacePrefix = 'a';
                textelement(EndpointID)
                {
                    NamespacePrefix = 'b';
                    textattribute(schemeID)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            schemeID := '0088';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        EndpointID := 'E1';
                    end;
                }
                textelement(Plain)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Plain := 'p';
                    end;
                }
            }
            tableelement(Line; "LT Y17 Ns Row")
            {
                NamespacePrefix = 'a';
                XmlName = 'Line';
                fieldelement(Id; Line.Id) { NamespacePrefix = 'b'; }
                fieldelement(Amount; Line.Amount) { NamespacePrefix = 'b'; }
                fieldelement(Name; Line.Name) { }
            }

            trigger OnAfterGetRecord()
            begin
                DocId := 'D1';
            end;
        }
    }
}

xmlport 91832 "LT Y17 Ns Empty Last"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = a = 'urn:lt-a', b = 'urn:lt-b', u = 'urn:lt-unused', "" = 'urn:lt-d';

    schema
    {
        tableelement(Hdr; Integer)
        {
            XmlName = 'Doc';
            MaxOccurs = Once;
            SourceTableView = where(Number = filter(1 ..));
            textelement(DocId)
            {
                NamespacePrefix = 'b';
            }
            textelement(Opt)
            {
                NamespacePrefix = 'b';

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement(Party)
            {
                NamespacePrefix = 'a';
                textelement(EndpointID)
                {
                    NamespacePrefix = 'b';
                    textattribute(schemeID)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            schemeID := '0088';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        EndpointID := 'E1';
                    end;
                }
                textelement(Plain)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Plain := 'p';
                    end;
                }
            }
            tableelement(Line; "LT Y17 Ns Row")
            {
                NamespacePrefix = 'a';
                XmlName = 'Line';
                fieldelement(Id; Line.Id) { NamespacePrefix = 'b'; }
                fieldelement(Amount; Line.Amount) { NamespacePrefix = 'b'; }
                fieldelement(Name; Line.Name) { }
            }

            trigger OnAfterGetRecord()
            begin
                DocId := 'D1';
            end;
        }
    }
}

xmlport 91833 "LT Y17 Ns Empty UseDefault"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "" = 'urn:lt-d', a = 'urn:lt-a', b = 'urn:lt-b', u = 'urn:lt-unused';
    UseDefaultNamespace = true;
    DefaultNamespace = 'urn:lt-dflt';

    schema
    {
        tableelement(Hdr; Integer)
        {
            XmlName = 'Doc';
            MaxOccurs = Once;
            SourceTableView = where(Number = filter(1 ..));
            textelement(DocId)
            {
                NamespacePrefix = 'b';
            }
            textelement(Opt)
            {
                NamespacePrefix = 'b';

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement(Party)
            {
                NamespacePrefix = 'a';
                textelement(EndpointID)
                {
                    NamespacePrefix = 'b';
                    textattribute(schemeID)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            schemeID := '0088';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        EndpointID := 'E1';
                    end;
                }
                textelement(Plain)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Plain := 'p';
                    end;
                }
            }
            tableelement(Line; "LT Y17 Ns Row")
            {
                NamespacePrefix = 'a';
                XmlName = 'Line';
                fieldelement(Id; Line.Id) { NamespacePrefix = 'b'; }
                fieldelement(Amount; Line.Amount) { NamespacePrefix = 'b'; }
                fieldelement(Name; Line.Name) { }
            }

            trigger OnAfterGetRecord()
            begin
                DocId := 'D1';
            end;
        }
    }
}

xmlport 91834 "LT Y17 Ns Prefixed Only"
{
    Format = Xml;
    Direction = Export;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = a = 'urn:lt-a', b = 'urn:lt-b', u = 'urn:lt-unused';

    schema
    {
        tableelement(Hdr; Integer)
        {
            XmlName = 'Doc';
            MaxOccurs = Once;
            SourceTableView = where(Number = filter(1 ..));
            textelement(DocId)
            {
                NamespacePrefix = 'b';
            }
            textelement(Opt)
            {
                NamespacePrefix = 'b';

                trigger OnBeforePassVariable()
                begin
                    currXMLport.Skip();
                end;
            }
            textelement(Party)
            {
                NamespacePrefix = 'a';
                textelement(EndpointID)
                {
                    NamespacePrefix = 'b';
                    textattribute(schemeID)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            schemeID := '0088';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        EndpointID := 'E1';
                    end;
                }
                textelement(Plain)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Plain := 'p';
                    end;
                }
            }
            tableelement(Line; "LT Y17 Ns Row")
            {
                NamespacePrefix = 'a';
                XmlName = 'Line';
                fieldelement(Id; Line.Id) { NamespacePrefix = 'b'; }
                fieldelement(Amount; Line.Amount) { NamespacePrefix = 'b'; }
                fieldelement(Name; Line.Name) { }
            }

            trigger OnAfterGetRecord()
            begin
                DocId := 'D1';
            end;
        }
    }
}

xmlport 91835 "LT Y17 Ns Empty Import"
{
    Format = Xml;
    Direction = Import;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "" = 'urn:lt-d', a = 'urn:lt-a', b = 'urn:lt-b', u = 'urn:lt-unused';

    schema
    {
        textelement(Doc)
        {
            textelement(DocId)
            {
                NamespacePrefix = 'b';
                MinOccurs = Zero;
            }
            textelement(Opt)
            {
                NamespacePrefix = 'b';
                MinOccurs = Zero;
            }
            textelement(Party)
            {
                NamespacePrefix = 'a';
                MinOccurs = Zero;
                textelement(EndpointID)
                {
                    NamespacePrefix = 'b';
                    MinOccurs = Zero;
                    textattribute(schemeID)
                    {
                        Occurrence = Optional;
                    }
                }
                textelement(Plain)
                {
                    MinOccurs = Zero;
                }
            }
            tableelement(Line; "LT Y17 Ns Row")
            {
                NamespacePrefix = 'a';
                XmlName = 'Line';
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(Id; Line.Id) { NamespacePrefix = 'b'; }
                fieldelement(Amount; Line.Amount) { NamespacePrefix = 'b'; }
                fieldelement(Name; Line.Name) { }
            }
        }
    }

    procedure Got(): Text
    begin
        exit(DocId + '/' + EndpointID + '/' + schemeID + '/' + Plain);
    end;

    procedure Rows() Result: Text
    begin
        if Line.FindSet() then
            repeat
                Result += Format(Line.Id) + '/' + Line.Name + '/' + Format(Line.Amount, 0, 9) + ';';
            until Line.Next() = 0;
    end;
}
