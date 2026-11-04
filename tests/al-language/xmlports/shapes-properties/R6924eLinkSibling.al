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
