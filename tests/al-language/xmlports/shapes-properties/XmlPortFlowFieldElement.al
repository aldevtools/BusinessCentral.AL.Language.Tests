// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-field-element
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 71440 and 71441, log 71442, xmlports 71443-71445, runner 71446 (codeunit), test codeunit 71447
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XML text exported for a field element bound to a FlowField (CalcFields done by the XmlPort or not), the Cnt of rows whose FlowField was calculated before SetTableView; import of a value into a FlowField element without AutoSave (the value assigned) and with AutoSave (error text and code, or the row saved and its Cnt after CalcFields).
// BC versions: 29 (27 and 28 by CI)

table 71440 "LT XpFlow Parent Field"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("LT XpFlow Child Field" where(ParentId = field(Id)));
        }

    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71441 "LT XpFlow Child Field"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Seq; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71442 "LT XpFlow Log Field"
{
    SingleInstance = true;

    var
        Entries: Text;
        Xml: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetXml(NewXml: Text)
    begin
        Xml := NewXml;
    end;

    procedure GetXml(): Text
    begin
        exit(Xml);
    end;
}

xmlport 71443 "LT XpFlow Export Field"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Field")
            {
                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt) { }

            }
        }
    }
}

xmlport 71444 "LT XpFlow Import Field"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Field")
            {
                AutoSave = false;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt)
                {
                    trigger OnAfterAssignField()
                    begin
                        L.Add('Cnt=' + Format(Parent.Cnt));
                    end;
                }

            }
        }
    }

    var
        L: Codeunit "LT XpFlow Log Field";
}

xmlport 71445 "LT XpFlow ImportSave Field"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Parent; "LT XpFlow Parent Field")
            {
                AutoSave = true;

                fieldelement(Id; Parent.Id) { }
                fieldelement(Name; Parent.Name) { }
                fieldelement(Cnt; Parent.Cnt) { }
            }
        }
    }
}

codeunit 71446 "LT XpFlow Runner Field"
{
    trigger OnRun()
    var
        L: Codeunit "LT XpFlow Log Field";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(L.GetXml());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT XpFlow ImportSave Field", InS);
    end;
}

