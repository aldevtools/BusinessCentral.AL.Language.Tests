// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-xmlport-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-encoding-xmlport-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); AhPageObjects.al (table 78610); own tables 78630-78633, xmlports 78633-78638, codeunits 78630, 78631
// Probe (corpus issue 636): item 11 XmlPort table elements below a parent where only some name a LinkTable (LinkFields without LinkTable does not
// compile: must-not-compile case 1063); item 9 XmlPort import of UTF-16 documents without a byte order mark (big endian and little endian), against
// the same documents with a byte order mark and a UTF-8 control.
// BC versions: 27+

table 78630 "LT AH Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 78631 "LT AH Child A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 78632 "LT AH Child B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 78633 "LT AH Grand"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// One linked child, one child without any link below the same parent.
xmlport 78633 "LT AH Link Mixed"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT AH Parent")
            {
                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { }

                tableelement(ChA; "LT AH Child A")
                {
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;
                    fieldelement(Id; ChA.Id) { }
                    fieldelement(ParentId; ChA.ParentId) { }
                    fieldelement(Name; ChA.Name) { }
                }

                tableelement(ChB; "LT AH Child B")
                {
                    MinOccurs = Zero;
                    fieldelement(Id; ChB.Id) { }
                    fieldelement(ParentId; ChB.ParentId) { }
                    fieldelement(Name; ChB.Name) { }
                }
            }
        }
    }
}

// A linked child, and a grand child below it that names no LinkTable.
xmlport 78637 "LT AH Link Grand"
{
    Direction = Both;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Par; "LT AH Parent")
            {
                fieldelement(Id; Par.Id) { }
                fieldelement(Name; Par.Name) { }

                tableelement(ChA; "LT AH Child A")
                {
                    LinkTable = Par;
                    LinkFields = ParentId = field(Id);
                    MinOccurs = Zero;
                    fieldelement(Id; ChA.Id) { }
                    fieldelement(ParentId; ChA.ParentId) { }
                    fieldelement(Name; ChA.Name) { }

                    tableelement(Gr; "LT AH Grand")
                    {
                        MinOccurs = Zero;
                        fieldelement(Id; Gr.Id) { }
                        fieldelement(ParentId; Gr.ParentId) { }
                        fieldelement(Name; Gr.Name) { }
                    }
                }
            }
        }
    }
}

xmlport 78634 "LT AH Utf8 Import"
{
    Direction = Import;
    UseRequestPage = false;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AH Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }
}

xmlport 78638 "LT AH Utf16 Import"
{
    Direction = Import;
    UseRequestPage = false;
    Encoding = UTF16;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT AH Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }
}

codeunit 78630 "LT AH XmlPort Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Wipe()
    var
        Par: Record "LT AH Parent";
        A: Record "LT AH Child A";
        B: Record "LT AH Child B";
        G: Record "LT AH Grand";
    begin
        Par.DeleteAll();
        A.DeleteAll();
        B.DeleteAll();
        G.DeleteAll();
    end;

    local procedure Seed()
    var
        Par: Record "LT AH Parent";
        A: Record "LT AH Child A";
        B: Record "LT AH Child B";
        G: Record "LT AH Grand";
    begin
        Wipe();
        Par.Id := 1;
        Par.Name := 'p1';
        Par.Insert();
        Par.Id := 2;
        Par.Name := 'p2';
        Par.Insert();
        A.Id := 10;
        A.ParentId := 1;
        A.Name := 'a10';
        A.Insert();
        A.Id := 11;
        A.ParentId := 1;
        A.Name := 'a11';
        A.Insert();
        A.Id := 12;
        A.ParentId := 2;
        A.Name := 'a12';
        A.Insert();
        B.Id := 20;
        B.ParentId := 1;
        B.Name := 'b20';
        B.Insert();
        B.Id := 21;
        B.ParentId := 2;
        B.Name := 'b21';
        B.Insert();
        B.Id := 22;
        B.ParentId := 2;
        B.Name := 'b22';
        B.Insert();
        G.Id := 30;
        G.ParentId := 10;
        G.Name := 'g30';
        G.Insert();
        G.Id := 31;
        G.ParentId := 12;
        G.Name := 'g31';
        G.Insert();
    end;

    local procedure Dump(): Text
    var
        Par: Record "LT AH Parent";
        A: Record "LT AH Child A";
        B: Record "LT AH Child B";
        G: Record "LT AH Grand";
        Result: Text;
    begin
        if Par.FindSet() then
            repeat
                Result += 'P' + Format(Par.Id) + '=' + Par.Name + ' ';
            until Par.Next() = 0;
        if A.FindSet() then
            repeat
                Result += 'A' + Format(A.Id) + '/' + Format(A.ParentId) + '=' + A.Name + ' ';
            until A.Next() = 0;
        if B.FindSet() then
            repeat
                Result += 'B' + Format(B.Id) + '/' + Format(B.ParentId) + '=' + B.Name + ' ';
            until B.Next() = 0;
        if G.FindSet() then
            repeat
                Result += 'G' + Format(G.Id) + '/' + Format(G.ParentId) + '=' + G.Name + ' ';
            until G.Next() = 0;
        exit(Result);
    end;

    local procedure ExportText(PortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(PortId, OutStr);
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line;
        end;
        if Result.Contains('<?xml') then
            Result := Result.Substring(Result.IndexOf('<?xml'));
        while Result.Contains('  ') do
            Result := Result.Replace('  ', '');
        exit(Result);
    end;

    [TryFunction]
    local procedure TryImport(PortId: Integer; Document: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Document);
        TempBlob.CreateInStream(InStr);
        Xmlport.Import(PortId, InStr);
    end;

    local procedure ImportObserved(var Observer: Codeunit "Probe Observer"; Name: Text; PortId: Integer; Document: Text)
    begin
        Observer.Observe(Name + '_ok', Format(TryImport(PortId, Document)));
        if GetLastErrorText() <> '' then
            Observer.ObserveError(Name + '_error');
        Observer.Observe(Name + '_db', Dump());
    end;

    [Test]
    procedure Mixed_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('xml', ExportText(78633));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>1</ParentId><Name>a10</Name></ChA><ChA><Id>11</Id><ParentId>1</ParentId><Name>a11</Name></ChA><ChB><Id>20</Id><ParentId>1</ParentId><Name>b20</Name></ChB><ChB><Id>21</Id><ParentId>2</ParentId><Name>b21</Name></ChB><ChB><Id>22</Id><ParentId>2</ParentId><Name>b22</Name></ChB></Par><Par><Id>2</Id><Name>p2</Name><ChA><Id>12</Id><ParentId>2</ParentId><Name>a12</Name></ChA><ChB><Id>20</Id><ParentId>1</ParentId><Name>b20</Name></ChB><ChB><Id>21</Id><ParentId>2</ParentId><Name>b21</Name></ChB><ChB><Id>22</Id><ParentId>2</ParentId><Name>b22</Name></ChB></Par></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Mixed_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Wipe();
        ImportObserved(Observer, 'two_parents', 78633, '<Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>99</ParentId><Name>a10</Name></ChA><ChB><Id>20</Id><ParentId>98</ParentId><Name>b20</Name></ChB></Par><Par><Id>2</Id><Name>p2</Name><ChA><Id>12</Id><ParentId>97</ParentId><Name>a12</Name></ChA><ChB><Id>21</Id><ParentId>96</ParentId><Name>b21</Name></ChB><ChB><Id>22</Id><ParentId>95</ParentId><Name>b22</Name></ChB></Par></Root>');
        Observer.Expect('two_parents_ok', 'No');
        Observer.Expect('two_parents_error|text', 'The data conflicts with the LinkTable and LinkFields setup of Table ChA.');
        Observer.Expect('two_parents_error|code', 'XmlPortData');
        Observer.Expect('two_parents_db', 'P1=p1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Mixed_Import_MatchingLinkValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Wipe();
        ImportObserved(Observer, 'matching', 78633, '<Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>1</ParentId><Name>a10</Name></ChA><ChB><Id>20</Id><ParentId>98</ParentId><Name>b20</Name></ChB></Par><Par><Id>2</Id><Name>p2</Name><ChA><Id>12</Id><ParentId>2</ParentId><Name>a12</Name></ChA><ChB><Id>21</Id><ParentId>96</ParentId><Name>b21</Name></ChB><ChB><Id>22</Id><ParentId>95</ParentId><Name>b22</Name></ChB></Par></Root>');
        Observer.Expect('matching_ok', 'Yes');
        Observer.Expect('matching_db', 'P1=p1 P2=p2 A10/1=a10 A12/2=a12 B20/98=b20 B21/96=b21 B22/95=b22 ');
        Observer.Verify();
    end;

    [Test]
    procedure Mixed_Import_ParentOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Wipe();
        ImportObserved(Observer, 'parent_only', 78633, '<Root><Par><Id>1</Id><Name>p1</Name></Par></Root>');
        Observer.Expect('parent_only_ok', 'Yes');
        Observer.Expect('parent_only_db', 'P1=p1 ');
        Observer.Verify();
    end;

    [Test]
    procedure Grand_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('xml', ExportText(78637));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>1</ParentId><Name>a10</Name><Gr><Id>30</Id><ParentId>10</ParentId><Name>g30</Name></Gr><Gr><Id>31</Id><ParentId>12</ParentId><Name>g31</Name></Gr></ChA><ChA><Id>11</Id><ParentId>1</ParentId><Name>a11</Name><Gr><Id>30</Id><ParentId>10</ParentId><Name>g30</Name></Gr><Gr><Id>31</Id><ParentId>12</ParentId><Name>g31</Name></Gr></ChA></Par><Par><Id>2</Id><Name>p2</Name><ChA><Id>12</Id><ParentId>2</ParentId><Name>a12</Name><Gr><Id>30</Id><ParentId>10</ParentId><Name>g30</Name></Gr><Gr><Id>31</Id><ParentId>12</ParentId><Name>g31</Name></Gr></ChA></Par></Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Grand_Import_MatchingLinkValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Wipe();
        ImportObserved(Observer, 'nested_matching', 78637, '<Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>1</ParentId><Name>a10</Name><Gr><Id>30</Id><ParentId>98</ParentId><Name>g30</Name></Gr></ChA></Par></Root>');
        Observer.Expect('nested_matching_ok', 'Yes');
        Observer.Expect('nested_matching_db', 'P1=p1 A10/1=a10 G30/98=g30 ');
        Observer.Verify();
    end;

    [Test]
    procedure Grand_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Wipe();
        ImportObserved(Observer, 'nested', 78637, '<Root><Par><Id>1</Id><Name>p1</Name><ChA><Id>10</Id><ParentId>99</ParentId><Name>a10</Name><Gr><Id>30</Id><ParentId>98</ParentId><Name>g30</Name></Gr></ChA></Par></Root>');
        Observer.Expect('nested_ok', 'No');
        Observer.Expect('nested_error|text', 'The data conflicts with the LinkTable and LinkFields setup of Table ChA.');
        Observer.Expect('nested_error|code', 'XmlPortData');
        Observer.Expect('nested_db', 'P1=p1 ');
        Observer.Verify();
    end;
}

codeunit 78631 "LT AH XmlPort Utf16 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Bytes of a document: Order 0 big endian, 1 little endian, 2 UTF-8. WithBom writes the byte order mark of that encoding.
    local procedure Document(Declared: Text; Order: Integer; WithBom: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
        Xml: Text;
        Code: Integer;
        I: Integer;
    begin
        Xml := '<?xml version="1.0" encoding="' + Declared + '"?><Root><Row><Id>R1</Id><Txt>h' + EAcute() + 'llo ' + Omega() + '</Txt></Row></Root>';
        if Declared = '' then
            Xml := '<Root><Row><Id>R1</Id><Txt>h' + EAcute() + 'llo ' + Omega() + '</Txt></Row></Root>';
        TempBlob.CreateOutStream(OutStr);
        if WithBom then
            case Order of
                0:
                    begin
                        WriteByte(OutStr, 254);
                        WriteByte(OutStr, 255);
                    end;
                1:
                    begin
                        WriteByte(OutStr, 255);
                        WriteByte(OutStr, 254);
                    end;
                2:
                    begin
                        WriteByte(OutStr, 239);
                        WriteByte(OutStr, 187);
                        WriteByte(OutStr, 191);
                    end;
            end;
        for I := 1 to StrLen(Xml) do begin
            Code := CharCode(Xml, I);
            case Order of
                0:
                    begin
                        WriteByte(OutStr, Code div 256);
                        WriteByte(OutStr, Code mod 256);
                    end;
                1:
                    begin
                        WriteByte(OutStr, Code mod 256);
                        WriteByte(OutStr, Code div 256);
                    end;
                2:
                    if Code < 128 then
                        WriteByte(OutStr, Code)
                    else
                        if Code < 2048 then begin
                            WriteByte(OutStr, 192 + Code div 64);
                            WriteByte(OutStr, 128 + Code mod 64);
                        end else begin
                            WriteByte(OutStr, 224 + Code div 4096);
                            WriteByte(OutStr, 128 + (Code div 64) mod 64);
                            WriteByte(OutStr, 128 + Code mod 64);
                        end;
            end;
        end;
    end;

    local procedure WriteByte(var OutStr: OutStream; Value: Integer)
    var
        B: Byte;
    begin
        B := Value;
        OutStr.Write(B);
    end;

    local procedure CharCode(Value: Text; Index: Integer): Integer
    var
        C: Char;
    begin
        C := Value[Index];
        exit(C);
    end;

    local procedure EAcute(): Text
    var
        T: Text[1];
    begin
        T[1] := 233;
        exit(T);
    end;

    local procedure Omega(): Text
    var
        T: Text[1];
    begin
        T[1] := 937;
        exit(T);
    end;

    local procedure Codes(Value: Text): Text
    var
        Result: Text;
        I: Integer;
    begin
        for I := 1 to StrLen(Value) do
            Result += Format(CharCode(Value, I)) + ',';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryImport(PortId: Integer; var TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Xmlport.Import(PortId, InStr);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; Declared: Text; Order: Integer; WithBom: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        Row: Record "LT AH Row";
        PortId: Integer;
    begin
        foreach PortId in PortIds() do begin
            Row.DeleteAll();
            Clear(TempBlob);
            Document(Declared, Order, WithBom, TempBlob);
            Observer.Observe(Name + '_port' + Format(PortId) + '_ok', Format(TryImport(PortId, TempBlob)));
            if GetLastErrorText() <> '' then
                Observer.ObserveError(Name + '_port' + Format(PortId) + '_error');
            if Row.FindFirst() then
                Observer.Observe(Name + '_port' + Format(PortId) + '_row', Row.Id + '|' + Codes(Row.Txt))
            else
                Observer.Observe(Name + '_port' + Format(PortId) + '_row', 'no row');
        end;
    end;

    local procedure PortIds() Result: List of [Integer]
    begin
        Result.Add(78634);
        Result.Add(78638);
    end;

    [Test]
    procedure BigEndian_NoBom_DeclaredUtf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'be_nobom_utf16', 'utf-16', 0, false);
        Observer.Expect('be_nobom_utf16_port78634_ok', 'Yes');
        Observer.Expect('be_nobom_utf16_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('be_nobom_utf16_port78638_ok', 'Yes');
        Observer.Expect('be_nobom_utf16_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Verify();
    end;

    [Test]
    procedure BigEndian_NoBom_NoDeclaration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'be_nobom_nodecl', '', 0, false);
        Observer.Expect('be_nobom_nodecl_port78634_ok', 'Yes');
        Observer.Expect('be_nobom_nodecl_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('be_nobom_nodecl_port78638_ok', 'Yes');
        Observer.Expect('be_nobom_nodecl_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Verify();
    end;

    [Test]
    procedure BigEndian_NoBom_DeclaredUtf8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'be_nobom_utf8decl', 'utf-8', 0, false);
        Observer.Expect('be_nobom_utf8decl_port78634_ok', 'No');
        Observer.Expect('be_nobom_utf8decl_port78634_error|text', '''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 39.');
        Observer.Expect('be_nobom_utf8decl_port78634_error|code', 'XmlPortImport:Xml');
        Observer.Expect('be_nobom_utf8decl_port78634_row', 'no row');
        Observer.Expect('be_nobom_utf8decl_port78638_ok', 'No');
        Observer.Expect('be_nobom_utf8decl_port78638_error|text', '''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 39.');
        Observer.Expect('be_nobom_utf8decl_port78638_error|code', 'XmlPortImport:Xml');
        Observer.Expect('be_nobom_utf8decl_port78638_row', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure BigEndian_WithBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'be_bom_utf16', 'utf-16', 0, true);
        Observer.Expect('be_bom_utf16_port78634_ok', 'Yes');
        Observer.Expect('be_bom_utf16_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('be_bom_utf16_port78638_ok', 'Yes');
        Observer.Expect('be_bom_utf16_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Verify();
    end;

    [Test]
    procedure LittleEndian_NoBom_DeclaredUtf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'le_nobom_utf16', 'utf-16', 1, false);
        Observer.Expect('le_nobom_utf16_port78634_ok', 'Yes');
        Observer.Expect('le_nobom_utf16_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('le_nobom_utf16_port78638_ok', 'Yes');
        Observer.Expect('le_nobom_utf16_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Verify();
    end;

    [Test]
    procedure LittleEndian_WithBom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'le_bom_utf16', 'utf-16', 1, true);
        Observer.Expect('le_bom_utf16_port78634_ok', 'Yes');
        Observer.Expect('le_bom_utf16_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('le_bom_utf16_port78638_ok', 'Yes');
        Observer.Expect('le_bom_utf16_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'utf8_nobom_utf8decl', 'utf-8', 2, false);
        RunCase(Observer, 'utf8_bom_utf8decl', 'utf-8', 2, true);
        RunCase(Observer, 'utf8_nobom_utf16decl', 'utf-16', 2, false);
        Observer.Expect('utf8_nobom_utf8decl_port78634_ok', 'Yes');
        Observer.Expect('utf8_nobom_utf8decl_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('utf8_nobom_utf8decl_port78638_ok', 'Yes');
        Observer.Expect('utf8_nobom_utf8decl_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('utf8_bom_utf8decl_port78634_ok', 'Yes');
        Observer.Expect('utf8_bom_utf8decl_port78634_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('utf8_bom_utf8decl_port78638_ok', 'Yes');
        Observer.Expect('utf8_bom_utf8decl_port78638_row', 'R1|104,233,108,108,111,32,937,');
        Observer.Expect('utf8_nobom_utf16decl_port78634_ok', 'No');
        Observer.Expect('utf8_nobom_utf16decl_port78634_error|text', 'There is no Unicode byte order mark. Cannot switch to Unicode.');
        Observer.Expect('utf8_nobom_utf16decl_port78634_error|code', 'XmlPortImport:Xml');
        Observer.Expect('utf8_nobom_utf16decl_port78634_row', 'no row');
        Observer.Expect('utf8_nobom_utf16decl_port78638_ok', 'No');
        Observer.Expect('utf8_nobom_utf16decl_port78638_error|text', 'There is no Unicode byte order mark. Cannot switch to Unicode.');
        Observer.Expect('utf8_nobom_utf16decl_port78638_error|code', 'XmlPortImport:Xml');
        Observer.Expect('utf8_nobom_utf16decl_port78638_row', 'no row');
        Observer.Verify();
    end;
}
