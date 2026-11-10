// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-textencoding-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 50000 "ALT Shape 00" (root table element, temporary and real), table 60008
//   "ALT Blob" (temporary, the source stream); own tables 75120-75121, xmlports 75122-75124, test codeunit 75125.
// Probe: Xml import of a port whose ROOT is a table element (MinOccurs = Once, MaxOccurs = Once, no fields of its own) that holds a
//   nested table element (MaxOccurs = Unbounded, temporary, OnAfterInitRecord and OnAfterInsertRecord) with leaf text elements, field
//   elements (some MinOccurs = Zero) and a text element that holds only another table element (temporary, OnBeforeInsertRecord).
//   Format = Xml, FormatEvaluate = Xml, Direction not set (Both). The source is an InStream over a Blob, the port's TextEncoding is set
//   to Windows and the document declares encoding='ISO-8859-1', is indented with CR LF and tabs, and has empty elements for two
//   MinOccurs = Zero Code fields. The call is `if not Port.Import() then`. (al-runner issue 6924, generic tables and names.)
//   Cells: the full shape with a temporary root and with a real root; a minimal root table element that holds a nested table element
//   of field elements only; two header elements (text element values seen by the next header's OnAfterInitRecord, MinOccurs = Zero
//   elements missing); a character beyond ASCII under Windows; UTF-8 without a declaration and without TextEncoding; Decimal values
//   under FormatEvaluate = Xml, valid and with a comma; a header without lines; a header without a required field; the unguarded call;
//   GetLastErrorText after a successful import with and without ClearLastError in OnPreXmlPort.
// Facts (BC 29.0 on the corpus CI, run 42911094711; then checked on 27.5 and 28.5): BC imports this shape. The root table element
//   inserts one row with its key blank (Id 0, temporary or real). Each header: OnAfterInitRecord runs first, before any of its child
//   elements is read; then its line rows are inserted (OnBeforeInsertRecord sees the header's text elements and fields already set from
//   the document); then the header row is inserted and OnAfterInsertRecord runs. Text element variables are not cleared between
//   headers: the second header's OnAfterInitRecord sees the first header's values, and a MinOccurs = Zero text element the second header
//   lacks keeps the first header's value. The text element that wraps the lines reads as empty. An empty element and a missing one
//   both leave a Code field blank; a Code value is upper-cased. The ISO-8859-1 document written with TextEncoding::Windows imports with
//   or without the port's TextEncoding set, and `Größe ü` arrives unchanged. FormatEvaluate = Xml: `1234.5678`, `-0.001`, `0050.50`,
//   `.5` import; `1,5` fails with `The value "1,5" can't be evaluated into type Decimal.` (code Evaluate). A failed import returns false
//   and leaves every temporary table of the port empty, the root's too. Schema errors (code XmlPortInvalidXml) come after the header's
//   OnAfterInitRecord. After a successful `if not Import()` the last error is what was set before, unless a trigger clears it.
// BC versions: 27, 28, 29 (corpus CI)

table 75120 "XP Root Table Header"
{
    // local object: no fixture table has three Code fields next to an Integer key; the Code fields take empty and missing elements.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Customer; Code[20]) { }
        field(3; "Ship-to Code"; Code[10]) { }
        field(4; Reference; Code[20]) { }
        field(5; "Location Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 75121 "XP Root Table Line"
{
    // local object: no fixture table has three Decimal fields next to a Code and a Text field; the Decimal fields take FormatEvaluate = Xml values.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Integer) { }
        field(3; Item; Code[20]) { }
        field(4; Quantity; Decimal) { }
        field(5; Description; Text[100]) { }
        field(6; "Unit Price"; Decimal) { }
        field(7; "Discount Pct"; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 75122 "XP Root Table Full"
{
    // local object: its schema (a root table element holding a nested table element and a text element that wraps a table element) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Msg; "ALT Shape 00")
        {
            XmlName = 'Message';
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Header; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(Kind)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Customer; Header.Customer)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(ShipTo; Header."Ship-to Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(DueDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Reference; Header.Reference)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Location; Header."Location Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(Lines)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;

                        fieldelement(Item; Line.Item)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Qty; Line.Quantity)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Descr; Line.Description)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Disc; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Header."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Header."Entry No.") + '/kind=[' + Kind + ']/cust=[' + Header.Customer + ']');
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Header."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + Kind + ']/od=[' + OrderDate + ']/dd=[' + DueDate + ']/lines=[' + Lines + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Header."Entry No.") + '/kind=[' + Kind + ']/od=[' + OrderDate + ']/dd=[' + DueDate + ']/lines=[' + Lines + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Msg.Reset();
        if Msg.FindSet() then
            repeat
                Result += Format(Msg.Id) + ';';
            until Msg.Next() = 0;
        exit(Format(Msg.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Header.Reset();
        if Header.FindSet() then
            repeat
                Result += Format(Header."Entry No.") + '/' + Header.Customer + '/[' + Header."Ship-to Code" + ']/' + Header.Reference + '/[' + Header."Location Code" + '];';
            until Header.Next() = 0;
        exit(Format(Header.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75123 "XP Root Table Real"
{
    // local object: its schema (the full shape with a root table element that is not temporary) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Msg; "ALT Shape 00")
        {
            XmlName = 'Message';
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Header; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(Kind) { }
                fieldelement(Customer; Header.Customer) { }
                fieldelement(ShipTo; Header."Ship-to Code") { MinOccurs = Zero; }
                textelement(OrderDate) { MinOccurs = Zero; }
                textelement(DueDate) { MinOccurs = Zero; }
                fieldelement(Reference; Header.Reference) { }
                fieldelement(Location; Header."Location Code") { MinOccurs = Zero; }
                textelement(Lines)
                {
                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;

                        fieldelement(Item; Line.Item) { }
                        fieldelement(Qty; Line.Quantity) { }
                        fieldelement(Descr; Line.Description) { MinOccurs = Zero; }
                        fieldelement(Price; Line."Unit Price") { MinOccurs = Zero; }
                        fieldelement(Disc; Line."Discount Pct") { MinOccurs = Zero; }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Header."Entry No.";
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Header."Entry No." := HeaderNo;
                end;
            }
        }
    }

    var
        HeaderNo: Integer;
        LineNo: Integer;

    procedure Counts(): Text
    begin
        Header.Reset();
        Line.Reset();
        exit('headers=' + Format(Header.Count()) + '/lines=' + Format(Line.Count()));
    end;
}

xmlport 75124 "XP Root Table Min"
{
    // local object: its schema (a root table element whose only node is a nested table element of field elements) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Msg; "ALT Shape 00")
        {
            XmlName = 'Message';
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Header; "XP Root Table Header")
            {
                UseTemporary = true;
                MaxOccurs = Unbounded;

                fieldelement(No; Header."Entry No.") { }
                fieldelement(Customer; Header.Customer) { }
                fieldelement(ShipTo; Header."Ship-to Code") { MinOccurs = Zero; }
            }
        }
    }

    procedure Dump(): Text
    var
        Result: Text;
    begin
        Msg.Reset();
        Result := 'roots=' + Format(Msg.Count());
        if Msg.FindFirst() then
            Result += '/' + Format(Msg.Id);
        Result += ' headers=';
        Header.Reset();
        if Header.FindSet() then
            repeat
                Result += Format(Header."Entry No.") + '/' + Header.Customer + '/[' + Header."Ship-to Code" + '];';
            until Header.Next() = 0;
        exit(Result);
    end;
}

codeunit 75125 "XP Root Table Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
    begin
        Cleanup.Initialize();
        Commit();
    end;

    local procedure Nl(): Text
    var
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        exit(Format(Cr) + Format(Lf));
    end;

    local procedure Tb(Depth: Integer): Text
    var
        T: Char;
        Result: Text;
        i: Integer;
    begin
        T := 9;
        for i := 1 to Depth do
            Result += Format(T);
        exit(Result);
    end;

    // The document of the issue's shape: declaration ISO-8859-1, CR LF and tabs between the elements, empty ShipTo and Location.
    local procedure LineXml(Item: Text; Qty: Text; Descr: Text; Price: Text; Disc: Text): Text
    begin
        exit(Tb(4) + '<Line><Item>' + Item + '</Item><Qty>' + Qty + '</Qty><Descr>' + Descr + '</Descr><Price>' + Price + '</Price><Disc>' + Disc + '</Disc></Line>' + Nl());
    end;

    local procedure HeaderXml(Customer: Text; Reference: Text; LinesXml: Text): Text
    begin
        exit(Tb(1) + '<Header>' + Nl() +
          Tb(2) + '<Kind>Order</Kind>' + Nl() +
          Tb(2) + '<Customer>' + Customer + '</Customer>' + Nl() +
          Tb(2) + '<ShipTo></ShipTo>' + Nl() +
          Tb(2) + '<OrderDate>20200326</OrderDate>' + Nl() +
          Tb(2) + '<DueDate>20200327</DueDate>' + Nl() +
          Tb(2) + '<Reference>' + Reference + '</Reference>' + Nl() +
          Tb(2) + '<Location></Location>' + Nl() +
          Tb(2) + '<Lines>' + Nl() + LinesXml + Tb(2) + '</Lines>' + Nl() +
          Tb(1) + '</Header>' + Nl());
    end;

    local procedure IssueDoc(): Text
    begin
        exit('<?xml version=''1.0'' encoding=''ISO-8859-1''?>' + Nl() + '<Message>' + Nl() +
          HeaderXml('C10000', 'REF-04', LineXml('ITEM001', '2', 'first line', '6.32', '100') + LineXml('ITEM002', '10', 'second line', '1.5', '0')) +
          '</Message>' + Nl());
    end;

    local procedure WriteSource(var Src: Record "ALT Blob" temporary; Doc: Text; Enc: TextEncoding; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Src.Init();
        Src.Code := 'SRC';
        Src.Data.CreateOutStream(OutS, Enc);
        OutS.WriteText(Doc);
        Src.Insert();
        Src.Data.CreateInStream(InS);
    end;

    // The issue's call: TextEncoding (optional), SetSource over a Blob, `if not Import() then`. Every observation gets the prefix P.
    local procedure ImportFull(P: Text; Doc: Text; Enc: TextEncoding; SetWindows: Boolean)
    var
        Src: Record "ALT Blob" temporary;
        Port: XmlPort "XP Root Table Full";
        InS: InStream;
    begin
        WriteSource(Src, Doc, Enc, InS);
        if SetWindows then
            Port.TextEncoding := TextEncoding::Windows;
        Port.SetSource(InS);
        asserterror Error('an earlier error');
        if not Port.Import() then begin
            Observer.Observe(P + 'import', 'false');
            Observer.ObserveError(P + 'error');
        end else begin
            Observer.Observe(P + 'import', 'true');
            Observer.Observe(P + 'last error after', GetLastErrorText());
        end;
        Observer.Observe(P + 'log', Port.GetLog());
        Observer.Observe(P + 'roots', Port.Roots());
        Observer.Observe(P + 'headers', Port.Headers());
        Observer.Observe(P + 'lines', Port.LinesDump());
    end;

    [Test]
    procedure RT_Full_IssueDoc_WindowsBlob_Import()
    begin
        Initialize();
        ImportFull('', IssueDoc(), TextEncoding::Windows, true);
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', '');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:ITEM001/hdr=1/kind=[Order]/cust=[C10000];L.bins:ITEM002/hdr=1/kind=[Order]/cust=[C10000];H.ains:1/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];post;');
        Observer.Expect('roots', '1:0;');
        Observer.Expect('headers', '1:1/C10000/[]/REF-04/[];');
        Observer.Expect('lines', '2:1/1/ITEM001/2/first line/6.32/100;2/1/ITEM002/10/second line/1.5/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_IssueDoc_Utf8NoTextEncoding_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := IssueDoc();
        Doc := Doc.Replace('<?xml version=''1.0'' encoding=''ISO-8859-1''?>' + Nl(), '');
        ImportFull('', Doc, TextEncoding::UTF8, false);
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', '');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:ITEM001/hdr=1/kind=[Order]/cust=[C10000];L.bins:ITEM002/hdr=1/kind=[Order]/cust=[C10000];H.ains:1/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];post;');
        Observer.Expect('roots', '1:0;');
        Observer.Expect('headers', '1:1/C10000/[]/REF-04/[];');
        Observer.Expect('lines', '2:1/1/ITEM001/2/first line/6.32/100;2/1/ITEM002/10/second line/1.5/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_IssueDoc_Unguarded_Import()
    var
        Src: Record "ALT Blob" temporary;
        Port: XmlPort "XP Root Table Full";
        InS: InStream;
    begin
        Initialize();
        WriteSource(Src, IssueDoc(), TextEncoding::Windows, InS);
        Port.TextEncoding := TextEncoding::Windows;
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('headers', Port.Headers());
        Observer.Observe('lines', Port.LinesDump());
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:ITEM001/hdr=1/kind=[Order]/cust=[C10000];L.bins:ITEM002/hdr=1/kind=[Order]/cust=[C10000];H.ains:1/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];post;');
        Observer.Expect('headers', '1:1/C10000/[]/REF-04/[];');
        Observer.Expect('lines', '2:1/1/ITEM001/2/first line/6.32/100;2/1/ITEM002/10/second line/1.5/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_NonAsciiDescription_Windows_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := IssueDoc();
        Doc := Doc.Replace('first line', 'Größe ü');
        ImportFull('', Doc, TextEncoding::Windows, true);
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', '');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:ITEM001/hdr=1/kind=[Order]/cust=[C10000];L.bins:ITEM002/hdr=1/kind=[Order]/cust=[C10000];H.ains:1/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];post;');
        Observer.Expect('roots', '1:0;');
        Observer.Expect('headers', '1:1/C10000/[]/REF-04/[];');
        Observer.Expect('lines', '2:1/1/ITEM001/2/Größe ü/6.32/100;2/1/ITEM002/10/second line/1.5/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_TwoHeaders_MissingOptional_Import()
    var
        Doc: Text;
        Second: Text;
    begin
        Initialize();
        // The second header: no ShipTo, OrderDate and DueDate elements, a Location value, one line.
        Second := Tb(1) + '<Header>' + Nl() +
          Tb(2) + '<Kind>Return</Kind>' + Nl() +
          Tb(2) + '<Customer>C20000</Customer>' + Nl() +
          Tb(2) + '<Reference>REF-05</Reference>' + Nl() +
          Tb(2) + '<Location>BLUE</Location>' + Nl() +
          Tb(2) + '<Lines>' + Nl() + LineXml('ITEM003', '3', 'third line', '2', '5') + Tb(2) + '</Lines>' + Nl() +
          Tb(1) + '</Header>' + Nl();
        Doc := IssueDoc();
        Doc := Doc.Replace('</Message>', Second + '</Message>');
        ImportFull('', Doc, TextEncoding::Windows, true);
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', '');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:ITEM001/hdr=1/kind=[Order]/cust=[C10000];L.bins:ITEM002/hdr=1/kind=[Order]/cust=[C10000];H.ains:1/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];H.init:2/kind=[Order]/od=[20200326]/dd=[20200327]/lines=[];L.bins:ITEM003/hdr=2/kind=[Return]/cust=[C20000];H.ains:2/kind=[Return]/od=[20200326]/dd=[20200327]/lines=[];post;');
        Observer.Expect('roots', '1:0;');
        Observer.Expect('headers', '2:1/C10000/[]/REF-04/[];2/C20000/[]/REF-05/[BLUE];');
        Observer.Expect('lines', '3:1/1/ITEM001/2/first line/6.32/100;2/1/ITEM002/10/second line/1.5/0;3/2/ITEM003/3/third line/2/5;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_Decimals_FormatEvaluateXml_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := '<Message><Header><Kind>Order</Kind><Customer>C1</Customer><Reference>R1</Reference><Lines>' +
          '<Line><Item>A</Item><Qty>1234.5678</Qty><Price>-0.001</Price><Disc>0050.50</Disc></Line>' +
          '<Line><Item>B</Item><Qty>7</Qty><Descr></Descr><Price>.5</Price></Line>' +
          '</Lines></Header></Message>';
        ImportFull('', Doc, TextEncoding::UTF8, false);
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', '');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];L.bins:A/hdr=1/kind=[Order]/cust=[C1];L.bins:B/hdr=1/kind=[Order]/cust=[C1];H.ains:1/kind=[Order]/od=[]/dd=[]/lines=[];post;');
        Observer.Expect('roots', '1:0;');
        Observer.Expect('headers', '1:1/C1/[]/R1/[];');
        Observer.Expect('lines', '2:1/1/A/1234.5678//-0.001/50.5;2/1/B/7//0.5/0;');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_DecimalWithComma_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := '<Message><Header><Kind>Order</Kind><Customer>C1</Customer><Reference>R1</Reference><Lines>' +
          '<Line><Item>A</Item><Qty>1,5</Qty></Line></Lines></Header></Message>';
        ImportFull('', Doc, TextEncoding::UTF8, false);
        Observer.Expect('import', 'false');
        Observer.Expect('error|text', 'The value "1,5" can''t be evaluated into type Decimal.');
        Observer.Expect('error|code', 'Evaluate');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];');
        Observer.Expect('roots', '0:');
        Observer.Expect('headers', '0:');
        Observer.Expect('lines', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_HeaderWithoutLines_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := '<Message><Header><Kind>Order</Kind><Customer>C1</Customer><Reference>R1</Reference><Lines></Lines></Header></Message>';
        ImportFull('', Doc, TextEncoding::UTF8, false);
        Observer.Expect('import', 'false');
        Observer.Expect('error|text', 'Imported XML cannot validate with the schema: The element ''Lines'' has incomplete content. List of possible elements expected: ''Line''.');
        Observer.Expect('error|code', 'XmlPortInvalidXml');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];');
        Observer.Expect('roots', '0:');
        Observer.Expect('headers', '0:');
        Observer.Expect('lines', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Full_HeaderWithoutReference_Import()
    var
        Doc: Text;
    begin
        Initialize();
        Doc := '<Message><Header><Kind>Order</Kind><Customer>C1</Customer><Lines><Line><Item>A</Item><Qty>1</Qty></Line></Lines></Header></Message>';
        ImportFull('', Doc, TextEncoding::UTF8, false);
        Observer.Expect('import', 'false');
        Observer.Expect('error|text', 'Imported XML cannot validate with the schema: The element ''Header'' has invalid child element ''Lines''. List of possible elements expected: ''ShipTo, OrderDate, DueDate, Reference''.');
        Observer.Expect('error|code', 'XmlPortInvalidXml');
        Observer.Expect('log', 'init;pre;H.init:1/kind=[]/od=[]/dd=[]/lines=[];');
        Observer.Expect('roots', '0:');
        Observer.Expect('headers', '0:');
        Observer.Expect('lines', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Real_IssueDoc_Import()
    var
        Src: Record "ALT Blob" temporary;
        Shape: Record "ALT Shape 00";
        Port: XmlPort "XP Root Table Real";
        InS: InStream;
    begin
        Initialize();
        WriteSource(Src, IssueDoc(), TextEncoding::Windows, InS);
        Port.TextEncoding := TextEncoding::Windows;
        Port.SetSource(InS);
        if Port.Import() then
            Observer.Observe('import', 'true')
        else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('counts', Port.Counts());
        Observer.Observe('real root rows', Format(Shape.Count()));
        if Shape.FindFirst() then
            Observer.Observe('real root id', Format(Shape.Id));
        Observer.Expect('import', 'true');
        Observer.Expect('counts', 'headers=1/lines=2');
        Observer.Expect('real root rows', '1');
        Observer.Expect('real root id', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_Min_TwoHeaders_LastErrorKept_Import()
    var
        Src: Record "ALT Blob" temporary;
        Port: XmlPort "XP Root Table Min";
        InS: InStream;
    begin
        Initialize();
        WriteSource(Src, '<Message>' + Nl() + '  <Header><No>5</No><Customer>c5</Customer><ShipTo></ShipTo></Header>' + Nl() +
          '  <Header><No>6</No><Customer>C6</Customer></Header>' + Nl() + '</Message>', TextEncoding::UTF8, InS);
        Port.SetSource(InS);
        asserterror Error('an earlier error');
        if Port.Import() then begin
            Observer.Observe('import', 'true');
            Observer.Observe('last error after', GetLastErrorText());
        end else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('dump', Port.Dump());
        Observer.Expect('import', 'true');
        Observer.Expect('last error after', 'an earlier error');
        Observer.Expect('dump', 'roots=1/0 headers=5/C5/[];6/C6/[];');
        Observer.Verify();
    end;
}
