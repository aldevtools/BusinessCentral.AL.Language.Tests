// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Probe: writer Y91. Ports of the XmlPort probes in this folder: empty element forms on import, root text element triggers with Skip and Break (Xml, VariableText, FixedText),
// negative Decimal export, Width on text elements in an Xml port, Xmlport.Run without a stream. Tests are in Y91XpTests.al.
// BC versions: 27-29

xmlport 94833 "LT Y91 Empty Forms"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(A)
            {
                trigger OnAfterAssignVariable()
                begin
                    Log += 'A(' + A + ');';
                end;
            }
            textelement(B)
            {
                textattribute(Att)
                {
                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'Att(' + Att + ');';
                    end;
                }

                trigger OnAfterAssignVariable()
                begin
                    Log += 'B(' + B + ');';
                end;
            }
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterInitRecord()
                begin
                    Rw.Name := 'init';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPreXmlPort()
    begin
        A := 'oldA';
        B := 'oldB';
        Att := 'oldAtt';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post A=[' + A + '] B=[' + B + '] Att=[' + Att + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94834 "LT Y91 Empty Forms Preserve"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            textelement(A)
            {
                trigger OnAfterAssignVariable()
                begin
                    Log += 'A(' + A + ');';
                end;
            }
            textelement(B)
            {
                textattribute(Att)
                {
                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'Att(' + Att + ');';
                    end;
                }

                trigger OnAfterAssignVariable()
                begin
                    Log += 'B(' + B + ');';
                end;
            }
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterInitRecord()
                begin
                    Rw.Name := 'init';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPreXmlPort()
    begin
        A := 'oldA';
        B := 'oldB';
        Att := 'oldAtt';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post A=[' + A + '] B=[' + B + '] Att=[' + Att + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94836 "LT Y91 Root Xml"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                begin
                    Log += 'agr(' + Format(Rw.Id) + ');';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'bir(' + Format(Rw.Id) + ');';
                end;
            }

            trigger OnBeforePassVariable()
            begin
                Log += 'root-bpv;';
                case Mode of
                    1:
                        currXMLport.Skip();
                    2:
                        currXMLport.Break();
                end;
            end;

            trigger OnAfterAssignVariable()
            begin
                Log += 'root-aav;';
                case Mode of
                    3:
                        currXMLport.Skip();
                    4:
                        currXMLport.Break();
                end;
            end;
        }
    }

    var
        Log: Text;
        Mode: Integer;

    trigger OnPreXmlPort()
    begin
        Log += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post;';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94837 "LT Y91 Root VT"
{
    Format = VariableText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                begin
                    Log += 'agr(' + Format(Rw.Id) + ');';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'bir(' + Format(Rw.Id) + ');';
                end;
            }

            trigger OnBeforePassVariable()
            begin
                Log += 'root-bpv;';
                case Mode of
                    1:
                        currXMLport.Skip();
                    2:
                        currXMLport.Break();
                end;
            end;

            trigger OnAfterAssignVariable()
            begin
                Log += 'root-aav;';
                case Mode of
                    3:
                        currXMLport.Skip();
                    4:
                        currXMLport.Break();
                end;
            end;
        }
    }

    var
        Log: Text;
        Mode: Integer;

    trigger OnPreXmlPort()
    begin
        Log += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post;';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94838 "LT Y91 Root Fixed"
{
    Format = FixedText;
    Direction = Both;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { Width = 4; }
                fieldelement(Name; Rw.Name) { Width = 6; }

                trigger OnAfterGetRecord()
                begin
                    Log += 'agr(' + Format(Rw.Id) + ');';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'bir(' + Format(Rw.Id) + ');';
                end;
            }

            trigger OnBeforePassVariable()
            begin
                Log += 'root-bpv;';
                case Mode of
                    1:
                        currXMLport.Skip();
                    2:
                        currXMLport.Break();
                end;
            end;

            trigger OnAfterAssignVariable()
            begin
                Log += 'root-aav;';
                case Mode of
                    3:
                        currXMLport.Skip();
                    4:
                        currXMLport.Break();
                end;
            end;
        }
    }

    var
        Log: Text;
        Mode: Integer;

    trigger OnPreXmlPort()
    begin
        Log += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post;';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94839 "LT Y91 Dec Xml"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Amt; Rw.Amt) { }
                fieldelement(Amt5; Rw.Amt5) { }
            }
        }
    }
}

xmlport 94840 "LT Y91 Dec VT"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Amt; Rw.Amt) { }
                fieldelement(Amt5; Rw.Amt5) { }
            }
        }
    }
}

xmlport 94841 "LT Y91 Dec Fixed"
{
    Format = FixedText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { Width = 4; }
                fieldelement(Amt; Rw.Amt) { Width = 12; }
                fieldelement(Amt5; Rw.Amt5) { Width = 12; }
            }
        }
    }
}

xmlport 94842 "LT Y91 Dec Legacy"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Amt; Rw.Amt) { }
                fieldelement(Amt5; Rw.Amt5) { }
            }
        }
    }
}

xmlport 94843 "LT Y91 Width Text"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(T3)
            {
                Width = 3;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'T3(' + T3 + ');';
                end;
            }
            textelement(T0)
            {
                trigger OnAfterAssignVariable()
                begin
                    Log += 'T0(' + T0 + ');';
                end;
            }
            textelement(T5)
            {
                Width = 5;

                textattribute(At4)
                {
                    Width = 4;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'At4(' + At4 + ');';
                    end;
                }

                trigger OnAfterAssignVariable()
                begin
                    Log += 'T5(' + T5 + ');';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPreXmlPort()
    begin
        T3 := 'abcdefg';
        T0 := 'abcdefg';
        T5 := 'ab';
        At4 := 'abcdefg';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'post T3=[' + T3 + '] T0=[' + T0 + '] T5=[' + T5 + '] At4=[' + At4 + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94844 "LT Y91 Width Unbound"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Free)
            {
                MinOccurs = Zero;
                Unbound = true;
                Width = 3;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Free(' + Free + ');';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post Free=[' + Free + '];';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 94845 "LT Y91 Run Both"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT Y91 Run Log";
                begin
                    Log.Add('Both agr ' + Format(Rw.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Log: Codeunit "LT Y91 Run Log";
    begin
        Log.Add('Both pre');
    end;
}

xmlport 94846 "LT Y91 Run Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT Y91 Run Log";
                begin
                    Log.Add('Export agr ' + Format(Rw.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Log: Codeunit "LT Y91 Run Log";
    begin
        Log.Add('Export pre');
    end;
}

xmlport 94847 "LT Y91 Run Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Rw; "LT Y91 Item")
            {
                XmlName = 'Item';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT Y91 Run Log";
                begin
                    Log.Add('Import agr ' + Format(Rw.Id));
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Log: Codeunit "LT Y91 Run Log";
    begin
        Log.Add('Import pre');
    end;
}

