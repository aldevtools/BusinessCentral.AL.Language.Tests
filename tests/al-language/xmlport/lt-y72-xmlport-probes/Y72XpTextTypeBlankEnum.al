// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-texttype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 93867-93869, enum 93850, xmlports 93853-93859, codeunits 93862-93864
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: (a) TextType = Text and TextType = BigText on a text attribute of a root text element and of a table element, on export and
//   import (the Export Permission Sets shape: root textattribute Version { TextType = Text; Description = 'Version'; } then a table
//   element); (b) a blank field attribute (and a field element) imported into an Enum field with OnValidate, with no TableRelation: the
//   export text of the member 0 whose caption is a blank, which OnValidate runs on import with FieldValidate = Yes, with
//   DefaultFieldsValidation = false, an Option field, and hand-written texts with an empty and a one-blank attribute.
//   Imports run in Codeunit.Run (a failed import must not end the test, and writes are not allowed inside a TryFunction).
// Neighbours: xmlport/lt-xmlport-bigtext/XmlPortBigText.al, report/lt-u-report-props/UPropertyTests.al:311-330,
//   BjXmlPortDefaultValidation.al (default validation of fields, a blank attribute with a TableRelation).
// BC versions: all (CI)

enum 93850 "LT Y72 XP E"
{
    Extensible = true;

    value(0; "None") { Caption = ' '; }
    value(1; One) { Caption = 'One'; }
    value(2; Two) { Caption = 'Two'; }
}

table 93867 "LT Y72 XP P"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 93868 "LT Y72 XP E"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Res; Enum "LT Y72 XP E")
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y72 XP2 Log";
            begin
                Log.Add('validate Res ' + Format(Res.AsInteger()));
            end;
        }
        field(3; Plain; Enum "LT Y72 XP E") { }
        field(4; Opt; Option)
        {
            OptionMembers = " ",A,B;

            trigger OnValidate()
            var
                Log: Codeunit "LT Y72 XP2 Log";
            begin
                Log.Add('validate Opt ' + Format(Opt));
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93862 "LT Y72 XP2 Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ImportText: Text;
        PortNo: Integer;

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

    procedure SetImport(NewPortNo: Integer; NewText: Text)
    begin
        PortNo := NewPortNo;
        ImportText := NewText;
    end;

    procedure GetPortNo(): Integer
    begin
        exit(PortNo);
    end;

    procedure GetImportText(): Text
    begin
        exit(ImportText);
    end;
}

xmlport 93853 "LT Y72 XP TextType"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(Version)
            {
                TextType = Text;
                Description = 'Version';

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('version[' + Version + ']');
                end;
            }
            tableelement(p; "LT Y72 XP P")
            {
                MinOccurs = Zero;
                fieldattribute(Id; p.Id) { }
                textattribute(Note)
                {
                    TextType = Text;
                }
                textattribute(BigNote)
                {
                    TextType = BigText;
                }

                trigger OnAfterGetRecord()
                begin
                    Note := 'n-' + p.Id;
                    Clear(BigNote);
                    BigNote.AddText('b-' + p.Id);
                end;

                trigger OnAfterInitRecord()
                begin
                    Clear(BigNote);
                    Note := '';
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('ins ' + p.Id + ' note[' + Note + '] big[' + Format(BigNote.Length) + ']');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";

    trigger OnPreXmlPort()
    begin
        if currXMLport.ImportFile() then
            exit;
        Version := '2.0';
    end;
}

xmlport 93854 "LT Y72 XP TextType Box"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Box)
            {
                TextType = Text;
                textattribute(k) { }
                textelement(Leaf) { }

                trigger OnBeforePassVariable()
                begin
                    Box := '';
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        k := 'kv';
        Leaf := 'lv';
    end;
}

xmlport 93855 "LT Y72 XP BigRoot"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(Version)
            {
                TextType = BigText;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('version length ' + Format(Version.Length));
                end;
            }
            textelement(Leaf) { }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";
        Fill: Integer;

    procedure SetFill(NewFill: Integer)
    var
        i: Integer;
    begin
        Fill := NewFill;
        Clear(Version);
        for i := 1 to NewFill do
            Version.AddText('v');
    end;
}

xmlport 93856 "LT Y72 XP Enum"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(e; "LT Y72 XP E")
            {
                MinOccurs = Zero;
                fieldattribute(Id; e.Id) { }
                fieldattribute(Res; e.Res) { }
                fieldattribute(Plain; e.Plain) { }
                fieldattribute(Opt; e.Opt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('ins ' + Format(e.Id) + ' res=' + Format(e.Res.AsInteger()) + ' plain=' + Format(e.Plain.AsInteger()) + ' opt=' + Format(e.Opt, 0, 2));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";
}

xmlport 93857 "LT Y72 XP Enum Validate"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(e; "LT Y72 XP E")
            {
                MinOccurs = Zero;
                fieldattribute(Id; e.Id) { }
                fieldattribute(Res; e.Res)
                {
                    FieldValidate = Yes;
                }
                fieldattribute(Plain; e.Plain) { }
                fieldattribute(Opt; e.Opt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('ins ' + Format(e.Id) + ' res=' + Format(e.Res.AsInteger()) + ' plain=' + Format(e.Plain.AsInteger()) + ' opt=' + Format(e.Opt, 0, 2));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";
}

xmlport 93858 "LT Y72 XP Enum NoDefault"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultFieldsValidation = false;

    schema
    {
        textelement(Root)
        {
            tableelement(e; "LT Y72 XP E")
            {
                MinOccurs = Zero;
                fieldattribute(Id; e.Id) { }
                fieldattribute(Res; e.Res) { }
                fieldattribute(Plain; e.Plain) { }
                fieldattribute(Opt; e.Opt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('ins ' + Format(e.Id) + ' res=' + Format(e.Res.AsInteger()) + ' plain=' + Format(e.Plain.AsInteger()) + ' opt=' + Format(e.Opt, 0, 2));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";
}

xmlport 93859 "LT Y72 XP Enum Element"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(e; "LT Y72 XP E")
            {
                MinOccurs = Zero;
                fieldelement(Id; e.Id) { }
                fieldelement(Res; e.Res) { }
                fieldelement(Opt; e.Opt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log.Add('ins ' + Format(e.Id) + ' res=' + Format(e.Res.AsInteger()) + ' opt=' + Format(e.Opt, 0, 2));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP2 Log";
}

codeunit 93863 "LT Y72 XP Import Run"
{
    trigger OnRun()
    var
        Log: Codeunit "LT Y72 XP2 Log";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Port1: XmlPort "LT Y72 XP TextType";
        Port2: XmlPort "LT Y72 XP BigRoot";
        Port3: XmlPort "LT Y72 XP Enum";
        Port4: XmlPort "LT Y72 XP Enum Validate";
        Port5: XmlPort "LT Y72 XP Enum NoDefault";
        Port6: XmlPort "LT Y72 XP Enum Element";
        Port7: XmlPort "LT Y72 XP TextType Box";
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Log.GetImportText());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        case Log.GetPortNo() of
            1:
                begin
                    Port1.SetSource(InS);
                    Port1.Import();
                end;
            2:
                begin
                    Port2.SetSource(InS);
                    Port2.Import();
                end;
            3:
                begin
                    Port3.SetSource(InS);
                    Port3.Import();
                end;
            4:
                begin
                    Port4.SetSource(InS);
                    Port4.Import();
                end;
            5:
                begin
                    Port5.SetSource(InS);
                    Port5.Import();
                end;
            6:
                begin
                    Port6.SetSource(InS);
                    Port6.Import();
                end;
            7:
                begin
                    Port7.SetSource(InS);
                    Port7.Import();
                end;
        end;
    end;
}

codeunit 93864 "LT Y72 XP TextType Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y72 XP2 Log";

    local procedure Start()
    var
        P: Record "LT Y72 XP P";
        E: Record "LT Y72 XP E";
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
        P.DeleteAll();
        E.DeleteAll();
    end;

    local procedure ReadLines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        exit(Result);
    end;

    local procedure DoImport(Name: Text; PortNo: Integer; Content: Text)
    begin
        Log.Take();
        ClearLastError();
        Log.SetImport(PortNo, Content);
        Observer.Observe(Name + ' import ok', Format(Codeunit.Run(Codeunit::"LT Y72 XP Import Run")));
        if GetLastErrorText() <> '' then
            Observer.ObserveError(Name + ' import');
        Observer.Observe(Name + ' import log', Log.Take());
    end;

    local procedure EnumRows(): Text
    var
        E: Record "LT Y72 XP E";
        Result: Text;
    begin
        if E.FindSet() then
            repeat
                Result += Format(E.Id) + ':' + Format(E.Res.AsInteger()) + '/' + Format(E.Plain.AsInteger()) + '/' + Format(E.Opt, 0, 2) + ';';
            until E.Next() = 0;
        exit(Result);
    end;

    local procedure InsertEnumRows()
    var
        E: Record "LT Y72 XP E";
    begin
        E.Id := 1;
        E.Res := E.Res::None;
        E.Plain := E.Plain::None;
        E.Opt := E.Opt::" ";
        E.Insert();
        E.Id := 2;
        E.Res := E.Res::One;
        E.Plain := E.Plain::One;
        E.Opt := E.Opt::A;
        E.Insert();
        E.Id := 3;
        E.Res := E.Res::Two;
        E.Plain := E.Plain::Two;
        E.Opt := E.Opt::B;
        E.Insert();
    end;

    local procedure ExportEnum(PortNo: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Port3: XmlPort "LT Y72 XP Enum";
        Port4: XmlPort "LT Y72 XP Enum Validate";
        Port5: XmlPort "LT Y72 XP Enum NoDefault";
        Port6: XmlPort "LT Y72 XP Enum Element";
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        case PortNo of
            3:
                begin
                    Port3.SetDestination(OutS);
                    Port3.Export();
                end;
            4:
                begin
                    Port4.SetDestination(OutS);
                    Port4.Export();
                end;
            5:
                begin
                    Port5.SetDestination(OutS);
                    Port5.Export();
                end;
            6:
                begin
                    Port6.SetDestination(OutS);
                    Port6.Export();
                end;
        end;
        exit(ReadAll(TempBlob));
    end;

    [Test]
    procedure TextTypeText_OnTextAttribute_ExportImport()
    var
        P: Record "LT Y72 XP P";
        Port: XmlPort "LT Y72 XP TextType";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Start();
        P.Id := 'P1';
        P.Insert();
        P.Id := 'P2';
        P.Insert();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Xml := ReadAll(TempBlob);
        Observer.Observe('export xml', Xml);
        P.DeleteAll();
        DoImport('text', 1, Xml);
        Observer.Observe('rows', Format(P.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure TextTypeText_OnTextAttribute_ExportImport_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextTypeText_OnTextAttribute_ExportImport_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextTypeText_OnTextAttribute_ExportImport_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextTypeBigText_RootAttribute()
    var
        Port: XmlPort "LT Y72 XP BigRoot";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Start();
        Port.SetFill(300);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Xml := ReadAll(TempBlob);
        Observer.Observe('export length', Format(StrLen(Xml)));
        Observer.Observe('export prefix', CopyStr(Xml, 1, 80));
        DoImport('big', 2, Xml);
        Observer.Finish();
    end;

    [Test]
    procedure TextTypeBigText_RootAttribute_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextTypeBigText_RootAttribute_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextTypeBigText_RootAttribute_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextType_OnContainerTextElement()
    var
        Port: XmlPort "LT Y72 XP TextType Box";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Xml: Text;
    begin
        Start();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.SetDestination(OutS);
        Port.Export();
        Xml := ReadLines(TempBlob);
        Observer.Observe('export xml', Xml);
        DoImport('box', 7, '<Root><Box k="kv"><Leaf>lv</Leaf></Box></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure TextType_OnContainerTextElement_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextType_OnContainerTextElement_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TextType_OnContainerTextElement_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ExportImport()
    var
        Xml: Text;
    begin
        Start();
        InsertEnumRows();
        Xml := ExportEnum(3);
        Observer.Observe('export xml', Xml);
        Observer.Observe('stored before', EnumRows());
        DoImport('import over rows', 3, Xml);
        Observer.Observe('rows after duplicate import', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ExportImport_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ExportImport_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ExportImport_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ImportIntoEmpty()
    var
        E: Record "LT Y72 XP E";
        Xml: Text;
    begin
        Start();
        InsertEnumRows();
        Xml := ExportEnum(3);
        E.DeleteAll();
        DoImport('default validation', 3, Xml);
        Observer.Observe('rows', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ImportIntoEmpty_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ImportIntoEmpty_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_CaptionBlank_ImportIntoEmpty_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_FieldValidateYes()
    var
        E: Record "LT Y72 XP E";
        Xml: Text;
    begin
        Start();
        InsertEnumRows();
        Xml := ExportEnum(4);
        Observer.Observe('export xml', Xml);
        E.DeleteAll();
        DoImport('field validate yes', 4, Xml);
        Observer.Observe('rows', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankEnumAttribute_FieldValidateYes_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_FieldValidateYes_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_FieldValidateYes_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_DefaultValidationOff()
    var
        E: Record "LT Y72 XP E";
        Xml: Text;
    begin
        Start();
        InsertEnumRows();
        Xml := ExportEnum(5);
        Observer.Observe('export xml', Xml);
        E.DeleteAll();
        DoImport('default off', 5, Xml);
        Observer.Observe('rows', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankEnumAttribute_DefaultValidationOff_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_DefaultValidationOff_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumAttribute_DefaultValidationOff_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumElement_ExportImport()
    var
        E: Record "LT Y72 XP E";
        Xml: Text;
    begin
        Start();
        InsertEnumRows();
        Xml := ExportEnum(6);
        Observer.Observe('export xml', Xml);
        E.DeleteAll();
        DoImport('element', 6, Xml);
        Observer.Observe('rows', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankEnumElement_ExportImport_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumElement_ExportImport_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankEnumElement_ExportImport_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal()
    var
        E: Record "LT Y72 XP E";
    begin
        Start();
        DoImport('empty attributes', 3, '<Root><e Id="5" Res="" Plain="" Opt="" /></Root>');
        Observer.Observe('rows empty', EnumRows());
        E.DeleteAll();
        DoImport('one blank attributes', 3, '<Root><e Id="6" Res=" " Plain=" " Opt=" " /></Root>');
        Observer.Observe('rows one blank', EnumRows());
        E.DeleteAll();
        DoImport('names', 3, '<Root><e Id="7" Res="None" Plain="None" Opt="A" /></Root>');
        Observer.Observe('rows names', EnumRows());
        E.DeleteAll();
        DoImport('missing attributes', 3, '<Root><e Id="8" /></Root>');
        Observer.Observe('rows missing', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_ValidateYes_And_Off()
    var
        E: Record "LT Y72 XP E";
    begin
        Start();
        DoImport('validate yes empty', 4, '<Root><e Id="5" Res="" Plain="" Opt="" /></Root>');
        Observer.Observe('rows validate yes empty', EnumRows());
        E.DeleteAll();
        DoImport('validate yes names', 4, '<Root><e Id="6" Res="Two" Plain="One" Opt="B" /></Root>');
        Observer.Observe('rows validate yes names', EnumRows());
        E.DeleteAll();
        DoImport('default off empty', 5, '<Root><e Id="5" Res="" Plain="" Opt="" /></Root>');
        Observer.Observe('rows default off empty', EnumRows());
        E.DeleteAll();
        DoImport('default off names', 5, '<Root><e Id="6" Res="Two" Plain="One" Opt="B" /></Root>');
        Observer.Observe('rows default off names', EnumRows());
        Observer.Finish();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_ValidateYes_And_Off_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_ValidateYes_And_Off_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure BlankAttribute_Import_Literal_ValidateYes_And_Off_More3()
    begin
        Observer.More();
    end;
}
