// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatevaluate-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 60008 "ALT Blob" (temporary, the source stream); own table 75180, xmlports
//   75181-75182, test codeunit 75183.
// local object: the Guid field and the ports' schemas (no FormatEvaluate, so Legacy) are what is under test.
// Probe: al-runner issue 7854. An XmlPort without FormatEvaluate imports text into a Guid field. Microsoft's Permission Import Export
//   Tests import the App ID attributes the Export Permission Sets ports wrote (Format = Xml, no FormatEvaluate). Measured:
//     Round trip   the export of a Guid and of the null Guid, then the import of that file (Xml attribute and element, VariableText)
//     Forms        one document per text: the export form (upper case in braces), lower case in braces, no braces (upper and lower),
//                  parentheses, the 32 digits alone, spaces around, empty, missing, and texts that are no Guid
//   QrXpContainerOccurs.al pins the same forms under FormatEvaluate = Xml.
// BC versions: 27, 28, 29 (observe form; the values come from the measurement run)

table 75180 "XP LGI Row"
{
    // local object: a Guid field next to an Integer key.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Guid) { }
        field(3; Ref2; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 75181 "XP LGI Xml"
{
    // local object: Format = Xml without FormatEvaluate, the Guid as field attribute and as field element.
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP LGI Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(Ref; Row.Ref) { Occurrence = Optional; }
                fieldelement(Ref2; Row.Ref2) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 75182 "XP LGI VarText"
{
    // local object: VariableText without FormatEvaluate.
    Direction = Both;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "XP LGI Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Ref; Row.Ref) { }
            }
        }
    }
}

codeunit 75183 "XP LGI Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "XP LGI Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Ref := '{6F9619FF-8B86-D011-B42D-00C04FC964FF}';
        Row.Ref2 := '{0A1B2C3D-4E5F-6789-ABCD-EF0123456789}';
        Row.Insert();
        Row.Id := 2;
        Clear(Row.Ref);
        Clear(Row.Ref2);
        Row.Insert();
        Commit();
    end;

    local procedure Rows(): Text
    var
        Row: Record "XP LGI Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '/' + Format(Row.Ref) + '/' + Format(Row.Ref2) + ';';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ':' + Result);
    end;

    local procedure ReadAll(var InS: InStream): Text
    var
        Part: Text;
        Result: Text;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        exit(Result);
    end;

    local procedure RoundTrip(XpId: Integer; Enc: TextEncoding)
    var
        Row: Record "XP LGI Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XpId, OutS);
        TempBlob.CreateInStream(InS, Enc);
        Observer.Observe('exported', ReadAll(InS));
        Row.DeleteAll();
        Commit();
        TempBlob.CreateInStream(InS);
        if Xmlport.Import(XpId, InS) then
            Observer.Observe('import', 'true')
        else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('rows after import', Rows());
    end;

    // Imports Doc through port XpId into the emptied table and records the result under Name.
    local procedure ImportText(XpId: Integer; Doc: Text; Name: Text)
    var
        Row: Record "XP LGI Row";
        Src: Record "ALT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Row.DeleteAll();
        Commit();
        Src.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Doc);
        Src.Data.CreateInStream(InS, TextEncoding::UTF8);
        if Xmlport.Import(XpId, InS) then
            Observer.Observe(Name, 'imported=Yes ' + Rows())
        else begin
            Observer.Observe(Name, 'imported=No ' + Rows());
            Observer.ObserveError(Name + ' error');
        end;
    end;

    local procedure AttrDoc(RefText: Text): Text
    begin
        exit('<Root><Row Id="1" Ref="' + RefText + '" /></Root>');
    end;

    local procedure ElemDoc(RefText: Text): Text
    begin
        exit('<Root><Row Id="1"><Ref2>' + RefText + '</Ref2></Row></Root>');
    end;

    [Test]
    procedure LGI_Xml_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP LGI Xml", TextEncoding::UTF16);
        Observer.Finish();
    end;

    [Test]
    procedure LGI_VarText_RoundTrip()
    begin
        RoundTrip(Xmlport::"XP LGI VarText", TextEncoding::Windows);
        Observer.Finish();
    end;

    [Test]
    procedure LGI_Xml_Attribute_Forms()
    var
        Xp: Integer;
    begin
        Xp := Xmlport::"XP LGI Xml";
        ImportText(Xp, AttrDoc('{6F9619FF-8B86-D011-B42D-00C04FC964FF}'), 'export form');
        ImportText(Xp, AttrDoc('{00000000-0000-0000-0000-000000000000}'), 'null in braces');
        ImportText(Xp, AttrDoc('{6f9619ff-8b86-d011-b42d-00c04fc964ff}'), 'lower in braces');
        ImportText(Xp, AttrDoc('6F9619FF-8B86-D011-B42D-00C04FC964FF'), 'upper no braces');
        ImportText(Xp, AttrDoc('6f9619ff-8b86-d011-b42d-00c04fc964ff'), 'lower no braces');
        ImportText(Xp, AttrDoc('(6F9619FF-8B86-D011-B42D-00C04FC964FF)'), 'parentheses');
        ImportText(Xp, AttrDoc('6F9619FF8B86D011B42D00C04FC964FF'), '32 digits');
        ImportText(Xp, AttrDoc(' {6F9619FF-8B86-D011-B42D-00C04FC964FF} '), 'spaces around');
        ImportText(Xp, AttrDoc(''), 'empty');
        ImportText(Xp, '<Root><Row Id="1" /></Root>', 'missing');
        ImportText(Xp, AttrDoc('not-a-guid'), 'not a guid');
        ImportText(Xp, AttrDoc('{6F9619FF-8B86-D011-B42D-00C04FC964F}'), 'one digit short');
        Observer.Finish();
    end;

    [Test]
    procedure LGI_Xml_Element_Forms()
    var
        Xp: Integer;
    begin
        Xp := Xmlport::"XP LGI Xml";
        ImportText(Xp, ElemDoc('{0A1B2C3D-4E5F-6789-ABCD-EF0123456789}'), 'export form');
        ImportText(Xp, ElemDoc('{0a1b2c3d-4e5f-6789-abcd-ef0123456789}'), 'lower in braces');
        ImportText(Xp, ElemDoc('0A1B2C3D-4E5F-6789-ABCD-EF0123456789'), 'upper no braces');
        ImportText(Xp, ElemDoc(''), 'empty');
        ImportText(Xp, ElemDoc('not-a-guid'), 'not a guid');
        Observer.Finish();
    end;

    [Test]
    procedure LGI_VarText_Forms()
    var
        Xp: Integer;
    begin
        Xp := Xmlport::"XP LGI VarText";
        ImportText(Xp, '"1","{6F9619FF-8B86-D011-B42D-00C04FC964FF}"', 'export form');
        ImportText(Xp, '"1","{6f9619ff-8b86-d011-b42d-00c04fc964ff}"', 'lower in braces');
        ImportText(Xp, '"1","6F9619FF-8B86-D011-B42D-00C04FC964FF"', 'upper no braces');
        ImportText(Xp, '"1",""', 'empty');
        ImportText(Xp, '"1","not-a-guid"', 'not a guid');
        Observer.Finish();
    end;
}
