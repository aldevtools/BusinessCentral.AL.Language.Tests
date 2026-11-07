// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-linktable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: tables 95350-95351, codeunit 95352 (log), xmlport 95353, test codeunit 95354.
// Probe: al-runner issue 6924 (a partner app's XmlPort whose line table element names, in LinkTable, a header table element that is
//   its preceding sibling, not an element above it). An Xml port Root > TransportHeader, TransportLine with
//   LinkTable = TransportHeader and LinkFields "Doc No." = field("No."). Questions: does it compile; which lines an export writes
//   (all, those of the last header, none); which "Doc No." an import gives the lines, with all headers first and with headers and
//   lines interleaved. Log: agr <element> <key> = OnAfterGetRecord, ins <element> <key> = OnBeforeInsertRecord with the header
//   element's current "No." after the bar.
// Facts (BC 29.0 on the corpus CI, then checked on the matrix): it compiles. Export: the header rows are written first; the line element
//   then writes only the lines linked to the header element's record as the header loop left it (the last header, H2); with no header
//   row no line is read (no OnAfterGetRecord) and the root is written empty. Import (headers first): the link does not fill the line's
//   "Doc No." (it stays blank) and the header element's "No." reads blank in the line's OnBeforeInsertRecord; a line whose own "Doc No."
//   is not blank raises "The data conflicts with the LinkTable and LinkFields setup of Table TransportLine."; a header after a line is
//   rejected by the schema check (the sequence is Header*, Line*).
// Neighbours: xmlports/import/XmlPortLinkTableNoLinkFields.al (LinkTable without LinkFields), streams/Y14XmlPortLink.al (a nested link).
// BC versions: all (CI)

table 95350 "LT R6924e Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95351 "LT R6924e Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Item; Text[30]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 95352 "LT R6924e Link Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

xmlport 95353 "LT R6924e Link Sibling"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(TransportHeader; "LT R6924e Hdr")
            {
                MinOccurs = Zero;
                fieldattribute(No; TransportHeader."No.") { }
                fieldattribute(Name; TransportHeader.Name) { Occurrence = Optional; }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdr ' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdr ' + TransportHeader."No.");
                end;
            }
            tableelement(TransportLine; "LT R6924e Line")
            {
                MinOccurs = Zero;
                LinkTable = TransportHeader;
                LinkFields = "Doc No." = field("No.");
                fieldattribute(Doc; TransportLine."Doc No.") { Occurrence = Optional; }
                fieldattribute(LineNo; TransportLine."Line No.") { }
                fieldattribute(Item; TransportLine.Item) { Occurrence = Optional; }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

codeunit 95354 "LT R6924e Link Sibling Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6924e Link Log";

    local procedure Start()
    var
        Hdr: Record "LT R6924e Hdr";
        Line: Record "LT R6924e Line";
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
        Hdr.DeleteAll();
        Line.DeleteAll();
    end;

    local procedure AddHdr(No: Code[20])
    var
        Hdr: Record "LT R6924e Hdr";
    begin
        Hdr."No." := No;
        Hdr.Name := 'n' + No;
        Hdr.Insert();
    end;

    local procedure AddLine(DocNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT R6924e Line";
    begin
        Line."Doc No." := DocNo;
        Line."Line No." := LineNo;
        Line.Item := 'i' + DocNo + Format(LineNo);
        Line.Insert();
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
            Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    local procedure Export(Name: Text)
    var
        XP: XmlPort "LT R6924e Link Sibling";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure Import(Name: Text; Xml: Text)
    var
        XP: XmlPort "LT R6924e Link Sibling";
        TempBlob: Codeunit "Temp Blob";
        Line: Record "LT R6924e Line";
        Hdr: Record "LT R6924e Hdr";
        OutS: OutStream;
        InS: InStream;
        Rows: Text;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        XP.SetSource(InS);
        XP.Import();
        if Hdr.FindSet() then
            repeat
                Rows += 'H ' + Hdr."No." + ';';
            until Hdr.Next() = 0;
        if Line.FindSet() then
            repeat
                Rows += 'L ' + Line."Doc No." + '-' + Format(Line."Line No.") + ' ' + Line.Item + ';';
            until Line.Next() = 0;
        Observer.Observe(Name + ' rows', Rows);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure LinkSibling_Export_TwoHeaders()
    begin
        Start();
        AddHdr('H1');
        AddHdr('H2');
        AddLine('H1', 1);
        AddLine('H1', 2);
        AddLine('H2', 1);
        AddLine('X9', 1);
        Export('two headers');
        Observer.Expect('two headers xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|<TransportHeader No="H1" Name="nH1" />|<TransportHeader No="H2" Name="nH2" />|<TransportLine Doc="H2" LineNo="1" Item="iH21" />|</Root>|');
        Observer.Expect('two headers log', 'agr hdr H1;agr hdr H2;agr line H2-1|H2;');
        Observer.Verify();
    end;

    [Test]
    procedure LinkSibling_Export_NoHeader()
    begin
        Start();
        AddLine('H1', 1);
        Export('no header');
        Observer.Expect('no header xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root />|');
        Observer.Expect('no header log', '');
        Observer.Verify();
    end;

    [Test]
    procedure LinkSibling_Import_HeadersFirst()
    begin
        Start();
        Import('headers first', '<Root><TransportHeader No="H1" /><TransportHeader No="H2" /><TransportLine LineNo="1" Item="a" /><TransportLine LineNo="2" Item="b" /></Root>');
        Observer.Expect('headers first rows', 'H H1;H H2;L -1 a;L -2 b;');
        Observer.Expect('headers first log', 'ins hdr H1;ins hdr H2;ins line -1|;ins line -2|;');
        Observer.Verify();
    end;

    [Test]
    procedure LinkSibling_Import_LineWithDoc()
    begin
        Start();
        asserterror Import('line with doc', '<Root><TransportHeader No="H1" /><TransportLine Doc="Z1" LineNo="1" Item="a" /></Root>');
        Observer.Observe('line with doc error', GetLastErrorText());
        Observer.Expect('line with doc error', 'The data conflicts with the LinkTable and LinkFields setup of Table TransportLine.');
        Observer.Verify();
    end;

    [Test]
    procedure LinkSibling_Import_Interleaved()
    begin
        Start();
        asserterror Import('interleaved', '<Root><TransportHeader No="H1" /><TransportLine LineNo="1" Item="a" /><TransportHeader No="H2" /><TransportLine LineNo="2" Item="b" /></Root>');
        Observer.Observe('interleaved error', GetLastErrorText());
        Observer.Expect('interleaved error', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''TransportHeader''. List of possible elements expected: ''TransportLine''.');
        Observer.Verify();
    end;
}

// ---- Text formats and other sibling layouts (al-runner issue 6924, waldo) ----
// Same header and line tables as above; ports in VariableText and FixedText, a header that is not the preceding sibling,
// a header and line pair nested under another table element, and two header and line pairs.

table 97060 "LT R6924e Outer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 97061 "LT R6924e Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

xmlport 95355 "LT R6924e Link VT"
{
    Direction = Both;
    Format = VariableText;
    FieldSeparator = ',';
    FieldDelimiter = '"';
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(TransportHeader; "LT R6924e Hdr")
            {
                fieldelement(No; TransportHeader."No.") { }
                fieldelement(Name; TransportHeader.Name) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdr ' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdr ' + TransportHeader."No.");
                end;
            }
            tableelement(TransportLine; "LT R6924e Line")
            {
                LinkTable = TransportHeader;
                LinkFields = "Doc No." = field("No.");
                fieldelement(Doc; TransportLine."Doc No.") { }
                fieldelement(LineNo; TransportLine."Line No.") { }
                fieldelement(Item; TransportLine.Item) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

xmlport 95356 "LT R6924e Link FT"
{
    Direction = Both;
    Format = FixedText;
    RecordSeparator = '<LF>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(TransportHeader; "LT R6924e Hdr")
            {
                fieldelement(No; TransportHeader."No.") { Width = 4; }
                fieldelement(Name; TransportHeader.Name) { Width = 5; }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdr ' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdr ' + TransportHeader."No.");
                end;
            }
            tableelement(TransportLine; "LT R6924e Line")
            {
                LinkTable = TransportHeader;
                LinkFields = "Doc No." = field("No.");
                fieldelement(Doc; TransportLine."Doc No.") { Width = 4; }
                fieldelement(LineNo; TransportLine."Line No.") { Width = 3; }
                fieldelement(Item; TransportLine.Item) { Width = 5; }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

xmlport 95357 "LT R6924e Link Gap"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(TransportHeader; "LT R6924e Hdr")
            {
                MinOccurs = Zero;
                fieldattribute(No; TransportHeader."No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdr ' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdr ' + TransportHeader."No.");
                end;
            }
            tableelement(Between; "LT R6924e Other")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Between.Code) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr other ' + Between.Code);
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins other ' + Between.Code);
                end;
            }
            tableelement(TransportLine; "LT R6924e Line")
            {
                MinOccurs = Zero;
                LinkTable = TransportHeader;
                LinkFields = "Doc No." = field("No.");
                fieldattribute(Doc; TransportLine."Doc No.") { Occurrence = Optional; }
                fieldattribute(LineNo; TransportLine."Line No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

xmlport 95358 "LT R6924e Link Nest"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Outer; "LT R6924e Outer")
            {
                MinOccurs = Zero;
                fieldattribute(Code; Outer.Code) { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr outer ' + Outer.Code);
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins outer ' + Outer.Code);
                end;

                tableelement(TransportHeader; "LT R6924e Hdr")
                {
                    MinOccurs = Zero;
                    fieldattribute(No; TransportHeader."No.") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('agr hdr ' + TransportHeader."No.");
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('ins hdr ' + TransportHeader."No.");
                    end;
                }
                tableelement(TransportLine; "LT R6924e Line")
                {
                    MinOccurs = Zero;
                    LinkTable = TransportHeader;
                    LinkFields = "Doc No." = field("No.");
                    fieldattribute(Doc; TransportLine."Doc No.") { Occurrence = Optional; }
                    fieldattribute(LineNo; TransportLine."Line No.") { }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('agr line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        Log.Add('ins line ' + TransportLine."Doc No." + '-' + Format(TransportLine."Line No.") + '|' + TransportHeader."No.");
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

xmlport 95359 "LT R6924e Link Pairs"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(HdrA; "LT R6924e Hdr")
            {
                MinOccurs = Zero;
                fieldattribute(No; HdrA."No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdrA ' + HdrA."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdrA ' + HdrA."No.");
                end;
            }
            tableelement(LineA; "LT R6924e Line")
            {
                MinOccurs = Zero;
                LinkTable = HdrA;
                LinkFields = "Doc No." = field("No.");
                fieldattribute(Doc; LineA."Doc No.") { Occurrence = Optional; }
                fieldattribute(LineNo; LineA."Line No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr lineA ' + LineA."Doc No." + '-' + Format(LineA."Line No.") + '|' + HdrA."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins lineA ' + LineA."Doc No." + '-' + Format(LineA."Line No.") + '|' + HdrA."No.");
                end;
            }
            tableelement(HdrB; "LT R6924e Hdr")
            {
                MinOccurs = Zero;
                fieldattribute(No; HdrB."No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr hdrB ' + HdrB."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins hdrB ' + HdrB."No.");
                end;
            }
            tableelement(LineB; "LT R6924e Line")
            {
                MinOccurs = Zero;
                LinkTable = HdrB;
                LinkFields = "Doc No." = field("No.");
                fieldattribute(Doc; LineB."Doc No.") { Occurrence = Optional; }
                fieldattribute(LineNo; LineB."Line No.") { }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr lineB ' + LineB."Doc No." + '-' + Format(LineB."Line No.") + '|' + HdrB."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins lineB ' + LineB."Doc No." + '-' + Format(LineB."Line No.") + '|' + HdrB."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT R6924e Link Log";
}

// Runs one import inside Codeunit.Run so an error is observed as a result, not a failed test.
codeunit 97062 "LT R6924e Link Importer"
{
    var
        PortId: Integer;
        Source: Text;

    procedure Setup(NewPortId: Integer; NewSource: Text)
    begin
        PortId := NewPortId;
        Source := NewSource;
    end;

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Source);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(PortId, InS);
    end;
}

codeunit 97063 "LT R6924e Link Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6924e Link Log";

    local procedure Start()
    var
        Hdr: Record "LT R6924e Hdr";
        Line: Record "LT R6924e Line";
        Outer: Record "LT R6924e Outer";
        Other: Record "LT R6924e Other";
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
        Hdr.DeleteAll();
        Line.DeleteAll();
        Outer.DeleteAll();
        Other.DeleteAll();
    end;

    local procedure AddHdr(No: Code[20])
    var
        Hdr: Record "LT R6924e Hdr";
    begin
        Hdr."No." := No;
        Hdr.Name := 'n' + No;
        Hdr.Insert();
    end;

    local procedure AddLine(DocNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT R6924e Line";
    begin
        Line."Doc No." := DocNo;
        Line."Line No." := LineNo;
        Line.Item := 'i' + DocNo + Format(LineNo);
        Line.Insert();
    end;

    local procedure Show(Value: Text): Text
    var
        Bom: Text[1];
    begin
        Bom[1] := 65279;
        exit(Value.Replace(Bom, '<BOM>').Replace(' ', '.'));
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
            Result += Show(Line) + '|';
        end;
        exit(Result);
    end;

    local procedure Export(Name: Text; PortId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Commit();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(PortId, OutS);
        Observer.Observe(Name + ' text', ReadAll(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure Rows(): Text
    var
        Hdr: Record "LT R6924e Hdr";
        Line: Record "LT R6924e Line";
        Outer: Record "LT R6924e Outer";
        Other: Record "LT R6924e Other";
        Result: Text;
    begin
        if Outer.FindSet() then
            repeat
                Result += 'O ' + Outer.Code + ';';
            until Outer.Next() = 0;
        if Other.FindSet() then
            repeat
                Result += 'X ' + Other.Code + ';';
            until Other.Next() = 0;
        if Hdr.FindSet() then
            repeat
                Result += 'H ' + Hdr."No." + ' ' + Hdr.Name + ';';
            until Hdr.Next() = 0;
        if Line.FindSet() then
            repeat
                Result += 'L ' + Line."Doc No." + '-' + Format(Line."Line No.") + ' ' + Line.Item + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure Import(Name: Text; PortId: Integer; Source: Text)
    var
        Importer: Codeunit "LT R6924e Link Importer";
        Ok: Boolean;
    begin
        Commit();
        Log.Take();
        Importer.Setup(PortId, Source);
        Ok := Importer.Run();
        if Ok then
            Observer.Observe(Name + ' result', 'ok')
        else
            Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' rows', Rows());
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure Lf(): Text
    var
        Result: Text[1];
    begin
        Result[1] := 10;
        exit(Result);
    end;

    local procedure Fill()
    begin
        AddHdr('H1');
        AddHdr('H2');
        AddLine('H1', 1);
        AddLine('H1', 2);
        AddLine('H2', 1);
        AddLine('X9', 1);
    end;

    // ---- VariableText ----

    [Test]
    procedure VT_Export()
    begin
        Start();
        Fill();
        Export('vt export', 95355);
        Observer.Finish();
    end;

    [Test]
    procedure VT_Export_NoHeader()
    begin
        Start();
        AddLine('H1', 1);
        Export('vt no header', 95355);
        Observer.Finish();
    end;

    [Test]
    procedure VT_Import_HeadersFirst()
    begin
        Start();
        Import('vt headers first', 95355, 'H1,nH1' + Lf() + 'H2,nH2' + Lf() + ',1,a' + Lf() + ',2,b' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure VT_Import_Interleaved()
    begin
        Start();
        Import('vt interleaved', 95355, 'H1,nH1' + Lf() + ',1,a' + Lf() + 'H2,nH2' + Lf() + ',2,b' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure VT_Import_LineWithDoc()
    begin
        Start();
        Import('vt line with doc', 95355, 'H1,nH1' + Lf() + 'Z1,1,a' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure VT_Import_HeadersOnly()
    begin
        Start();
        Import('vt headers only', 95355, 'H1,nH1' + Lf() + 'H2,nH2' + Lf());
        Observer.Finish();
    end;

    // ---- FixedText (header: No 4, Name 5; line: Doc 4, LineNo 3, Item 5) ----

    [Test]
    procedure FT_Export()
    begin
        Start();
        Fill();
        Export('ft export', 95356);
        Observer.Finish();
    end;

    [Test]
    procedure FT_Export_NoHeader()
    begin
        Start();
        AddLine('H1', 1);
        Export('ft no header', 95356);
        Observer.Finish();
    end;

    [Test]
    procedure FT_Import_HeadersFirst()
    begin
        Start();
        Import('ft headers first', 95356, 'H1  nH1  ' + Lf() + 'H2  nH2  ' + Lf() + '      1a    ' + Lf() + '      2b    ' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure FT_Import_Interleaved()
    begin
        Start();
        Import('ft interleaved', 95356, 'H1  nH1  ' + Lf() + '      1a    ' + Lf() + 'H2  nH2  ' + Lf() + '      2b    ' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure FT_Import_LineWithDoc()
    begin
        Start();
        Import('ft line with doc', 95356, 'H1  nH1  ' + Lf() + 'Z1    1a    ' + Lf());
        Observer.Finish();
    end;

    [Test]
    procedure FT_Import_HeadersOnly()
    begin
        Start();
        Import('ft headers only', 95356, 'H1  nH1  ' + Lf() + 'H2  nH2  ' + Lf());
        Observer.Finish();
    end;

    // ---- Xml: header not the preceding sibling (Header, Between, Line) ----

    [Test]
    procedure Gap_Export()
    var
        Other: Record "LT R6924e Other";
    begin
        Start();
        Fill();
        Other.Code := 'O1';
        Other.Insert();
        Other.Code := 'O2';
        Other.Insert();
        Export('gap export', 95357);
        Observer.Finish();
    end;

    [Test]
    procedure Gap_Import_InOrder()
    begin
        Start();
        Import('gap in order', 95357, '<Root><TransportHeader No="H1" /><TransportHeader No="H2" /><Between Code="O1" /><TransportLine LineNo="1" /><TransportLine LineNo="2" /></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure Gap_Import_LineWithDoc()
    begin
        Start();
        Import('gap line with doc', 95357, '<Root><TransportHeader No="H1" /><Between Code="O1" /><TransportLine Doc="Z1" LineNo="1" /></Root>');
        Observer.Finish();
    end;

    // ---- Xml: header and line nested under another table element ----

    [Test]
    procedure Nest_Export()
    var
        Outer: Record "LT R6924e Outer";
    begin
        Start();
        Fill();
        Outer.Code := 'O1';
        Outer.Insert();
        Outer.Code := 'O2';
        Outer.Insert();
        Export('nest export', 95358);
        Observer.Finish();
    end;

    [Test]
    procedure Nest_Import()
    begin
        Start();
        Import('nest import', 95358, '<Root><Outer Code="O1"><TransportHeader No="H1" /><TransportHeader No="H2" /><TransportLine LineNo="1" /></Outer><Outer Code="O2"><TransportHeader No="H3" /><TransportLine LineNo="2" /></Outer></Root>');
        Observer.Finish();
    end;

    [Test]
    procedure Nest_Import_LineWithDoc()
    begin
        Start();
        Import('nest line with doc', 95358, '<Root><Outer Code="O1"><TransportHeader No="H1" /><TransportLine Doc="Z1" LineNo="1" /></Outer></Root>');
        Observer.Finish();
    end;

    // ---- Xml: two header and line pairs ----

    [Test]
    procedure Pairs_Export()
    begin
        Start();
        Fill();
        Export('pairs export', 95359);
        Observer.Finish();
    end;

    [Test]
    procedure Pairs_Import()
    begin
        Start();
        Import('pairs import', 95359, '<Root><HdrA No="H1" /><HdrA No="H2" /><LineA LineNo="1" /><HdrB No="H3" /><LineB LineNo="2" /></Root>');
        Observer.Finish();
    end;
}
