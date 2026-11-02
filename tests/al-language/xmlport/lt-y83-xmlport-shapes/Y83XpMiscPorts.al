// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Probe: ports of Y83XpMiscTests.al (UseLax in nested table elements, XML 1.0 and 1.1 control characters, decimals, VariableText and FixedText shapes,
// Boolean and Date text, TableFilter field, RequestFilterFields, triggers of container text elements)
// BC versions: 27-29

xmlport 94362 "LT Y83 Lax Nested"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    UseLax = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                tableelement(Ch; "LT Y83 Child")
                {
                    XmlName = 'Child';
                    LinkTable = Rw;
                    LinkFields = ItemId = field(Id);
                    fieldelement(Txt; Ch.Txt) { }
                }
            }
        }
    }
}

xmlport 94363 "LT Y83 Strict Nested"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                tableelement(Ch; "LT Y83 Child")
                {
                    XmlName = 'Child';
                    LinkTable = Rw;
                    LinkFields = ItemId = field(Id);
                    fieldelement(Txt; Ch.Txt) { }
                }
            }
        }
    }
}

xmlport 94364 "LT Y83 V10"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V10;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
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

xmlport 94365 "LT Y83 V11"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    XmlVersionNo = V11;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
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

xmlport 94366 "LT Y83 Dec Xml"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(AmtA; Rw.Amt) { }
                fieldelement(Id; Rw.Id) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94367 "LT Y83 Dec Legacy"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldattribute(AmtA; Rw.Amt) { }
                fieldelement(Id; Rw.Id) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94368 "LT Y83 VT Plain"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94369 "LT Y83 Fixed Export"
{
    Format = FixedText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { Width = 4; }
                fieldelement(Name; Rw.Name) { Width = 10; }
                fieldelement(Amt; Rw.Amt) { Width = 12; }
            }
        }
    }
}

xmlport 94370 "LT Y83 VT Nested"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                tableelement(Ch; "LT Y83 Child")
                {
                    XmlName = 'Child';
                    LinkTable = Rw;
                    LinkFields = ItemId = field(Id);
                    fieldelement(Txt; Ch.Txt) { }
                }
            }
        }
    }
}

xmlport 94371 "LT Y83 VT Two Tables"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;
    TableSeparator = '#';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
            tableelement(Ch; "LT Y83 Child")
            {
                XmlName = 'Child';
                fieldelement(Id; Ch.Id) { }
                fieldelement(Txt; Ch.Txt) { }
            }
        }
    }
}

xmlport 94372 "LT Y83 VT NewLine"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;
    FieldSeparator = '<NewLine>';
    RecordSeparator = '<LF>';

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94373 "LT Y83 VT Bool Date"
{
    Format = VariableText;
    Direction = Import;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Flag; Rw.Flag) { }
                fieldelement(D; Rw.D) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94374 "LT Y83 Xml Bool Date"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Flag; Rw.Flag) { }
                fieldelement(D; Rw.D) { }
                fieldelement(Amt; Rw.Amt) { }
            }
        }
    }
}

xmlport 94375 "LT Y83 Table Filter"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Filter Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Tf; Rw.Tf) { }
            }
        }
    }
}

xmlport 94376 "LT Y83 Request Filter"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id, Name;
                RequestFilterHeading = 'Items';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
                tableelement(Ch; "LT Y83 Child")
                {
                    XmlName = 'Child';
                    LinkTable = Rw;
                    LinkFields = ItemId = field(Id);
                    RequestFilterFields = Txt;
                    fieldelement(Txt; Ch.Txt) { }
                }
            }
        }
    }
}

xmlport 94377 "LT Y83 Request Filter Page"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                RequestFilterFields = Id, Name;
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }
            }
        }
    }
}

xmlport 94378 "LT Y83 Container Triggers"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            trigger OnBeforePassVariable()
            begin
                Log += 'root-bpv;';
            end;

            trigger OnAfterAssignVariable()
            begin
                Log += 'root-aav;';
            end;

            textelement(Hdr)
            {
                trigger OnBeforePassVariable()
                begin
                    Log += 'hdr-bpv;';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'hdr-aav;';
                end;

                textattribute(HAttr)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'hattr-bpv;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'hattr-aav(' + HAttr + ');';
                    end;
                }
                textelement(HCode)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'hcode-bpv;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'hcode-aav(' + HCode + ');';
                    end;
                }
                textelement(Inner)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'inner-bpv;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'inner-aav;';
                    end;

                    textelement(InnerVal)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'innerval-bpv;';
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'innerval-aav(' + InnerVal + ');';
                        end;
                    }
                }
            }
            tableelement(Rw; "LT Y83 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                begin
                    Log += 'rw-agr(' + Format(Rw.Id) + ');';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPreXmlPort()
    begin
        HAttr := 'ha';
        HCode := 'hc';
        InnerVal := 'iv';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94379 "LT Y83 Attr Only Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Endpoint)
            {
                trigger OnBeforePassVariable()
                begin
                    Log += 'ep-bpv;';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'ep-aav(' + Endpoint + ');';
                end;

                textattribute(SchemeId)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'scheme-bpv;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'scheme-aav(' + SchemeId + ');';
                    end;
                }
            }
            textelement(Party)
            {
                trigger OnBeforePassVariable()
                begin
                    Log += 'party-bpv;';
                end;

                textattribute(PartyId)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'partyid-bpv;';
                    end;
                }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Endpoint := '0088';
        SchemeId := 'GLN';
        PartyId := 'p1';
    end;

    var
        Log: Text;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}
