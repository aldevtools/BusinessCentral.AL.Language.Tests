// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 78301, xmlports 78302 to 78304, test codeunit 78305
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: an XmlPort fieldelement that carries a fieldattribute and a textattribute (export text, import values); a fieldelement with a child textelement and a
// fieldelement with a child fieldelement (does it compile, what does export write, does import accept the text).
// BC versions: 27, 28, 29

table 78301 "LT AF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Lang; Text[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

xmlport 78302 "LT AF XP Attr"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AF Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name)
                {
                    fieldattribute(Lang; Row.Lang) { }
                    textattribute(Kind) { }
                }
            }
        }
    }

    procedure GetKind(): Text
    begin
        exit(Kind);
    end;

    procedure SetKind(NewKind: Text)
    begin
        Kind := NewKind;
    end;
}

xmlport 78303 "LT AF XP Child Text"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AF Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name)
                {
                    textelement(Child)
                    {
                    }
                }
            }
        }
    }

    procedure SetChild(NewChild: Text)
    begin
        Child := NewChild;
    end;

    procedure GetChild(): Text
    begin
        exit(Child);
    end;
}

xmlport 78304 "LT AF XP Child Field"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AF Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name)
                {
                    fieldelement(Lang; Row.Lang) { }
                }
            }
        }
    }
}

codeunit 78305 "LT AF XmlPort Attr Children"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AF Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Alpha';
        Row.Lang := 'en';
        Row.Insert();
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

    local procedure PutText(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
    end;

    [TryFunction]
    local procedure TryExportAttr(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Attr";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetKind('K1');
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryImportAttr(var TempBlob: Codeunit "Temp Blob"; var Kind: Text)
    var
        Xp: XmlPort "LT AF XP Attr";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Kind := Xp.GetKind();
    end;

    [TryFunction]
    local procedure TryExportChildText(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Child Text";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetChild('c1');
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryImportChildText(var TempBlob: Codeunit "Temp Blob"; var Child: Text)
    var
        Xp: XmlPort "LT AF XP Child Text";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Child := Xp.GetChild();
    end;

    [TryFunction]
    local procedure TryExportChildField(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Child Field";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Xp.Export();
    end;

    [TryFunction]
    local procedure TryImportChildField(var TempBlob: Codeunit "Temp Blob")
    var
        Xp: XmlPort "LT AF XP Child Field";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
    end;

    local procedure RowState(Id: Integer): Text
    var
        Row: Record "LT AF Row";
    begin
        if not Row.Get(Id) then
            exit('absent');
        exit(Row.Name + '|' + Row.Lang);
    end;

    [Test]
    procedure AF_Attributes_In_FieldElement()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Kind: Text;
    begin
        Seed();
        ClearLastError();
        if TryExportAttr(TempBlob) then
            Observer.Observe('attr export', ReadAll(TempBlob))
        else
            Observer.ObserveError('attr export');

        Clear(TempBlob);
        PutText(TempBlob, '<?xml version="1.0" encoding="utf-8"?><Root><Row><Id>2</Id><Name Lang="de" Kind="K9">Beta</Name></Row></Root>');
        ClearLastError();
        if TryImportAttr(TempBlob, Kind) then begin
            Observer.Observe('attr import', 'ok');
            Observer.Observe('attr import row 2', RowState(2));
            Observer.Observe('attr import kind', Kind);
        end else
            Observer.ObserveError('attr import');
        Observer.Expect('attr export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Row>    <Id>1</Id>    <Name Lang="en" Kind="K1">Alpha</Name>  </Row></Root>');
        Observer.Expect('attr import', 'ok');
        Observer.Expect('attr import row 2', 'Beta|de');
        Observer.Expect('attr import kind', 'K9');
        Observer.Verify();
    end;

    [Test]
    procedure AF_FieldElement_With_TextElement_Child()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Child: Text;
    begin
        Seed();
        ClearLastError();
        if TryExportChildText(TempBlob) then
            Observer.Observe('child text export', ReadAll(TempBlob))
        else
            Observer.ObserveError('child text export');

        Clear(TempBlob);
        PutText(TempBlob, '<?xml version="1.0" encoding="utf-8"?><Root><Row><Id>3</Id><Name>Gamma<Child>cc</Child></Name></Row></Root>');
        ClearLastError();
        if TryImportChildText(TempBlob, Child) then begin
            Observer.Observe('child text import', 'ok');
            Observer.Observe('child text import row 3', RowState(3));
            Observer.Observe('child text import child', Child);
        end else
            Observer.ObserveError('child text import');
        Observer.Expect('child text export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Row>    <Id>1</Id>    <Name>Alpha<Child>c1</Child></Name>  </Row></Root>');
        Observer.Expect('child text import', 'ok');
        Observer.Expect('child text import row 3', 'Gamma|');
        Observer.Expect('child text import child', 'cc');
        Observer.Verify();
    end;

    [Test]
    procedure AF_FieldElement_With_FieldElement_Child()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Seed();
        ClearLastError();
        if TryExportChildField(TempBlob) then
            Observer.Observe('child field export', ReadAll(TempBlob))
        else
            Observer.ObserveError('child field export');

        Clear(TempBlob);
        PutText(TempBlob, '<?xml version="1.0" encoding="utf-8"?><Root><Row><Id>4</Id><Name>Delta<Lang>fr</Lang></Name></Row></Root>');
        ClearLastError();
        if TryImportChildField(TempBlob) then begin
            Observer.Observe('child field import', 'ok');
            Observer.Observe('child field import row 4', RowState(4));
        end else
            Observer.ObserveError('child field import');
        Observer.Expect('child field export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root>  <Row>    <Id>1</Id>    <Name>Alpha<Lang>en</Lang></Name>  </Row></Root>');
        Observer.Expect('child field import', 'ok');
        Observer.Expect('child field import row 4', 'Delta|fr');
        Observer.Verify();
    end;
}
