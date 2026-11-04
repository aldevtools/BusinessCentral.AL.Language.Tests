// Batch 7 probes: tables and xmlports for the xmlport probes. Not tests.
table 68514 "W7 XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 68515 "W7 XP Container"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Cont)
            {
                textelement(Leaf)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log += 'Leaf.BeforePass;';
                        Leaf := 'leafvalue';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'Leaf.AfterAssign=' + Leaf + ';';
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log += 'Cont.BeforePass;';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Cont.AfterAssign=' + Cont + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPreXmlPort()
    begin
        Log += 'Pre;';
    end;

    trigger OnPostXmlPort()
    begin
        Log += 'Post;';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 68516 "W7 XP Occurrence"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Req)
            {
                trigger OnAfterAssignVariable()
                begin
                    Log += 'Req=' + Req + ';';
                end;
            }
            textelement(Opt)
            {
                MinOccurs = Zero;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Opt=' + Opt + ';';
                end;
            }
            textelement(Once)
            {
                MaxOccurs = Once;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Once=' + Once + ';';
                end;
            }
            textelement(Many)
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'Many=' + Many + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'Post;';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 68517 "W7 XP Rows"
{
    Format = Xml;
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68518 "W7 XP Occ Rows"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68519 "W7 XP Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68521 "W7 XP Enc Utf8"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            textelement(Item)
            {
                trigger OnBeforePassVariable()
                begin
                    Item := 'x';
                end;
            }
        }
    }
}

xmlport 68522 "W7 XP Enc Utf16"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;
    Encoding = UTF16;

    schema
    {
        textelement(Root)
        {
            textelement(Item)
            {
                trigger OnBeforePassVariable()
                begin
                    Item := 'x';
                end;
            }
        }
    }
}

xmlport 68523 "W7 XP Enc Vt Msdos"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = MSDOS;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68524 "W7 XP Enc Vt Windows"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = Windows;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68525 "W7 XP Enc Vt Utf8"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68526 "W7 XP Enc Vt Utf16"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;
    TextEncoding = UTF16;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}

xmlport 68527 "W7 XP Enc Vt None"
{
    Format = VariableText;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "W7 XP Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }
            }
        }
    }
}
