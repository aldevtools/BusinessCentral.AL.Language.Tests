// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-preservewhitespace-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 93410-93412, xmlports 93413-93417, test codeunit 93418
// Writer NP4 (NP lane, 2026-10-30). Probe: (1) XmlPort export with PreserveWhiteSpace true and false, with DefaultNamespace + UseDefaultNamespace and without: the exported
//   text of a text element and a field element holding spaces and a line end (lines joined by |, plus the stream length). (2) A table element nested in a
//   table element without LinkTable, MinOccurs = Once and MaxOccurs = Once, with 0, 1 and 2 rows in the filter set by OnPreXmlItem.
// Writer Y9 (NP lane 1030e, 2026-10-30): own tables 91450-91451, xmlports 91452-91458 (tests Y9_* in codeunit 93418). Probe: (3) a nested table element LINKED to its
//   parent (LinkTable, LinkFields) with a SourceTableView, MinOccurs = Once and MaxOccurs = Once, with 0, 1 and 2 linked rows. (4) XmlPort IMPORT with
//   PreserveWhiteSpace and DefaultNamespace + UseDefaultNamespace (and without either): white space inside values and between elements. (5) Export of a
//   text value with line ends without PreserveWhiteSpace or a namespace, and with Encoding = UTF16 (bytes shown). (6) Once/Once unlinked with three rows.
// BC versions: 27, 28, 29

table 93410 "LT NP4 XP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93411 "LT NP4 XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93412 "LT NP4 XP Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 93413 "LT NP4 XP Ws NsPreserve"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:np4';
    UseDefaultNamespace = true;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note)
            {
                trigger OnBeforePassVariable()
                begin
                    Note := NoteText;
                end;
            }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    var
        NoteText: Text;

    procedure Seed(NewNote: Text; NewTxt: Text)
    begin
        NoteText := NewNote;
        Row.Id := 1;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;
}

xmlport 93414 "LT NP4 XP Ws NsDefault"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:np4';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note)
            {
                trigger OnBeforePassVariable()
                begin
                    Note := NoteText;
                end;
            }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    var
        NoteText: Text;

    procedure Seed(NewNote: Text; NewTxt: Text)
    begin
        NoteText := NewNote;
        Row.Id := 1;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;
}

xmlport 93415 "LT NP4 XP Ws NoNsPreserve"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note)
            {
                trigger OnBeforePassVariable()
                begin
                    Note := NoteText;
                end;
            }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    var
        NoteText: Text;

    procedure Seed(NewNote: Text; NewTxt: Text)
    begin
        NoteText := NewNote;
        Row.Id := 1;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;
}

xmlport 93416 "LT NP4 XP Once Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT NP4 XP Head")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(id; Head.Id) { }
                tableelement(Child; "LT NP4 XP Row")
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                    fieldattribute(cid; Child.Id) { }
                    fieldelement(Txt; Child.Txt) { }

                    trigger OnPreXmlItem()
                    begin
                        Child.SetRange(Id, Head.Id * 10, Head.Id * 10 + 9);
                    end;
                }
            }
        }
    }
}

xmlport 93417 "LT NP4 XP Zero Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT NP4 XP Head")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(id; Head.Id) { }
                tableelement(Child; "LT NP4 XP Row")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    fieldattribute(cid; Child.Id) { }
                    fieldelement(Txt; Child.Txt) { }

                    trigger OnPreXmlItem()
                    begin
                        Child.SetRange(Id, Head.Id * 10, Head.Id * 10 + 9);
                    end;
                }
            }
        }
    }
}

codeunit 93418 "LT NP4 XmlPort Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ToText(var Buffer: Record "LT NP4 XP Blob" temporary): Text
    var
        InS: InStream;
        Line: Text;
        Xml: Text;
    begin
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        exit(Xml + 'len=' + Format(Buffer.Data.Length));
    end;

    local procedure Sample(var Note: Text; var Txt: Text)
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        Note := '  lead' + '  inner  gap ' + 'trail  ';
        Txt := ' a' + Lf + '  b  ' + Lf;
    end;

    local procedure Dest(var Buffer: Record "LT NP4 XP Blob" temporary; var OutS: OutStream)
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
    end;

    [Test]
    procedure NP4_XmlPort_PreserveWhiteSpace_WithNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Ws NsPreserve";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Sample(Note, Txt);
        Port.Seed(Note, Txt);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns="urn:np4">|  <Note>  lead  inner  gap trail  </Note>|  <Row>|    <Txt> a|  b  |</Txt>|  </Row>|</Root>|len=177');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_XmlPort_DefaultWhiteSpace_WithNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Ws NsDefault";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Sample(Note, Txt);
        Port.Seed(Note, Txt);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root xmlns="urn:np4">|  <Note>  lead  inner  gap trail  </Note>|  <Row>|    <Txt> a|  b  |</Txt>|  </Row>|</Root>|len=177');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_XmlPort_PreserveWhiteSpace_NoNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Ws NoNsPreserve";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Sample(Note, Txt);
        Port.Seed(Note, Txt);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Note>  lead  inner  gap trail  </Note>|  <Row>|    <Txt> a|  b  |</Txt>|  </Row>|</Root>|len=161');
        Observer.Verify();
    end;

    local procedure SeedHeadsAndChildren(ChildrenOfHead1: Integer; ChildrenOfHead2: Integer)
    var
        Head: Record "LT NP4 XP Head";
        Child: Record "LT NP4 XP Row";
        i: Integer;
    begin
        Head.DeleteAll();
        Child.DeleteAll();
        Head.Id := 1;
        Head.Insert();
        Head.Id := 2;
        Head.Insert();
        for i := 1 to ChildrenOfHead1 do begin
            Child.Id := 10 + i;
            Child.Txt := 'c' + Format(Child.Id);
            Child.Insert();
        end;
        for i := 1 to ChildrenOfHead2 do begin
            Child.Id := 20 + i;
            Child.Txt := 'c' + Format(Child.Id);
            Child.Insert();
        end;
    end;

    [Test]
    procedure NP4_XmlPort_OnceOnce_ZeroAndOneRows()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Once Once";
        OutS: OutStream;
    begin
        SeedHeadsAndChildren(0, 1);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Child cid="0">|      <Txt />|    </Child>|  </Head>|  <Head id="2">|    <Child cid="21">|      <Txt>c21</Txt>|    </Child>|  </Head>|</Root>|len=235');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_XmlPort_OnceOnce_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Once Once";
        OutS: OutStream;
    begin
        SeedHeadsAndChildren(2, 0);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Child cid="11">|      <Txt>c11</Txt>|    </Child>|  </Head>|  <Head id="2">|    <Child cid="12">|      <Txt>c12</Txt>|    </Child>|  </Head>|</Root>|len=243');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_XmlPort_ZeroOnce_ZeroOneAndTwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Zero Once";
        OutS: OutStream;
    begin
        SeedHeadsAndChildren(2, 1);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Child cid="11">|      <Txt>c11</Txt>|    </Child>|  </Head>|  <Head id="2">|    <Child cid="21">|      <Txt>c21</Txt>|    </Child>|  </Head>|</Root>|len=243');
        Observer.Verify();
    end;

    // ---- Writer Y9 (NP lane 1030e, 2026-10-30) ----

    local procedure Y9DestRaw(var Buffer: Record "LT NP4 XP Blob" temporary; var OutS: OutStream)
    begin
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
    end;

    // The exported bytes: a byte order mark is named, UTF-16 is decoded by pairs, other bytes are shown as characters (line ends as \r and \n).
    local procedure Y9Bytes(var Buffer: Record "LT NP4 XP Blob" temporary): Text
    var
        InS: InStream;
        B: Byte;
        Codes: List of [Integer];
        Shown: Text;
        Ch: Text[1];
        i: Integer;
        Start: Integer;
        Mode: Text;
    begin
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Codes.Add(B);
        end;
        Start := 1;
        Mode := 'none';
        if Codes.Count() >= 2 then
            if (Codes.Get(1) = 255) and (Codes.Get(2) = 254) then begin
                Mode := 'FFFE';
                Start := 3;
            end else
                if (Codes.Get(1) = 254) and (Codes.Get(2) = 255) then begin
                    Mode := 'FEFF';
                    Start := 3;
                end;
        if Codes.Count() >= 3 then
            if (Codes.Get(1) = 239) and (Codes.Get(2) = 187) and (Codes.Get(3) = 191) then begin
                Mode := 'EFBBBF';
                Start := 4;
            end;
        i := Start;
        while i <= Codes.Count() do begin
            case Mode of
                'FFFE':
                    begin
                        Ch[1] := Codes.Get(i) + 256 * Codes.Get(i + 1);
                        i += 2;
                    end;
                'FEFF':
                    begin
                        Ch[1] := 256 * Codes.Get(i) + Codes.Get(i + 1);
                        i += 2;
                    end;
                else begin
                    Ch[1] := Codes.Get(i);
                    i += 1;
                end;
            end;
            Shown += Ch;
        end;
        exit('bom=' + Mode + '|bytes=' + Format(Codes.Count()) + '|' + Shown);
    end;

    local procedure Y9SeedLinked(Counts: List of [Integer]; WithOtherKind: List of [Boolean])
    var
        Head: Record "LT Y9 XP Head";
        Line: Record "LT Y9 XP Line";
        h: Integer;
        i: Integer;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        for h := 1 to Counts.Count() do begin
            Head.Id := h;
            Head.Insert();
            for i := 1 to Counts.Get(h) do begin
                Line.HeadId := h;
                Line.LineNo := 10 * i;
                Line.Kind := 'A';
                Line.Txt := 'h' + Format(h) + 'l' + Format(Line.LineNo);
                Line.Insert();
            end;
            if WithOtherKind.Get(h) then begin
                Line.HeadId := h;
                Line.LineNo := 90;
                Line.Kind := 'B';
                Line.Txt := 'h' + Format(h) + 'other';
                Line.Insert();
            end;
        end;
    end;

    [Test]
    procedure Y9_XmlPort_LinkedOnceOnce_ZeroOneTwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Linked Once";
        OutS: OutStream;
    begin
        // head 1: no row of kind A, head 2: one, head 3: two; each head also has a linked row of kind B that the view filters out
        Y9SeedLinked(Y9Ints(0, 1, 2), Y9Bools(true, true, true));
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Observe('held', Port.HeldLine());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Line head="0" no="0">|      <Txt />|    </Line>|  </Head>|  <Head id="2">|    <Line head="2" no="10">|      <Txt>h2l10</Txt>|    </Line>|  </Head>|  <Head id="3">|    <Line head="3" no="20">|      <Txt>h3l20</Txt>|    </Line>|  </Head>|</Root>|len=343');
        Observer.Expect('held', '3/10/A/h3l10|filters=');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_LinkedOnceOnce_TwoRowsThenNone()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Linked Once";
        OutS: OutStream;
    begin
        // head 1: two rows of kind A, head 2: only a row of kind B, head 3: no linked row at all
        Y9SeedLinked(Y9Ints(2, 0, 0), Y9Bools(true, true, false));
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Observe('held', Port.HeldLine());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Line head="1" no="20">|      <Txt>h1l20</Txt>|    </Line>|  </Head>|  <Head id="2">|    <Line head="1" no="10">|      <Txt>h1l10</Txt>|    </Line>|  </Head>|  <Head id="3">|    <Line head="1" no="10">|      <Txt>h1l10</Txt>|    </Line>|  </Head>|</Root>|len=353');
        Observer.Expect('held', '1/10/A/h1l10|filters=');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_LinkedOnceOnce_OneRowThenNone()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Linked Once";
        OutS: OutStream;
    begin
        Y9SeedLinked(Y9Ints(1, 0, 0), Y9Bools(false, false, false));
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Observe('held', Port.HeldLine());
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Line head="1" no="10">|      <Txt>h1l10</Txt>|    </Line>|  </Head>|  <Head id="2">|    <Line head="1" no="10">|      <Txt>h1l10</Txt>|    </Line>|  </Head>|  <Head id="3">|    <Line head="1" no="10">|      <Txt>h1l10</Txt>|    </Line>|  </Head>|</Root>|len=353');
        Observer.Expect('held', '1/10/A/h1l10|filters=');
        Observer.Verify();
    end;

    local procedure Y9Ints(A: Integer; B: Integer; C: Integer) Result: List of [Integer]
    begin
        Result.Add(A);
        Result.Add(B);
        Result.Add(C);
    end;

    local procedure Y9Bools(A: Boolean; B: Boolean; C: Boolean) Result: List of [Boolean]
    begin
        Result.Add(A);
        Result.Add(B);
        Result.Add(C);
    end;

    // The import input: white space inside the values (spaces, a line feed, a TAB, a value of spaces only) and between the elements.
    local procedure Y9ImportXml(WithNamespace: Boolean): Text
    var
        Lf: Text[1];
        Tab: Text[1];
        Ns: Text;
    begin
        Lf[1] := 10;
        Tab[1] := 9;
        if WithNamespace then
            Ns := ' xmlns="urn:y9"';
        exit('<?xml version="1.0" encoding="UTF-8"?>' + Lf +
            '<Root' + Ns + '>' + Lf +
            '  <Note>  lead  inner' + Lf + ' gap' + Tab + ' </Note>' + Lf +
            '  <Row>' + Lf + '    <Txt> a' + Lf + '  b  </Txt>' + Lf + '  </Row>' + Lf +
            '  <Row>' + Lf + '    <Txt>   </Txt>' + Lf + '  </Row>' + Lf +
            '  <Row><Txt>x</Txt></Row>' + Lf +
            '</Root>' + Lf);
    end;

    local procedure Y9Source(var Buffer: Record "LT NP4 XP Blob" temporary; Xml: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Buffer.DeleteAll();
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
    end;

    [Test]
    procedure Y9_XmlPort_Import_PreserveWhiteSpace_WithNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Imp NsPreserve";
        InS: InStream;
    begin
        Y9Source(Buffer, Y9ImportXml(true), InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('import', Port.Result());
        Observer.Expect('import', 'note=[  lead  inner\n gap\t ] rows=3 [ a\n  b  ] [] [x]');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_Import_DefaultWhiteSpace_WithNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Imp NsDefault";
        InS: InStream;
    begin
        Y9Source(Buffer, Y9ImportXml(true), InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('import', Port.Result());
        Observer.Expect('import', 'note=[lead inner gap] rows=3 [a b] [] [x]');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_Import_PreserveWhiteSpace_NoNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Imp NoNsPreserve";
        InS: InStream;
    begin
        Y9Source(Buffer, Y9ImportXml(false), InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('import', Port.Result());
        Observer.Expect('import', 'note=[  lead  inner\n gap\t ] rows=3 [ a\n  b  ] [] [x]');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_Import_DefaultWhiteSpace_NoNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Imp Plain";
        InS: InStream;
    begin
        Y9Source(Buffer, Y9ImportXml(false), InS);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe('import', Port.Result());
        Observer.Expect('import', 'note=[lead inner gap] rows=3 [a b] [] [x]');
        Observer.Verify();
    end;

    local procedure Y9LfValues(var Note: Text; var Txt: Text)
    var
        Lf: Text[1];
        Cr: Text[1];
    begin
        Lf[1] := 10;
        Cr[1] := 13;
        Note := 'n1' + Lf + 'n2' + Cr + Lf + 'n3' + Cr + 'n4';
        Txt := ' a' + Lf + '  b  ' + Lf;
    end;

    [Test]
    procedure Y9_XmlPort_Export_LineFeed_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Lf Plain";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Y9LfValues(Note, Txt);
        Port.Seed(Note, Txt);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', Y9Bytes(Buffer));
        Observer.Expect('export', 'bom=none|bytes=149|<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Root>\r\n  <Note>n1\r\nn2\r\nn3\r\nn4</Note>\r\n  <Row>\r\n    <Txt> a\r\n  b  \r\n</Txt>\r\n  </Row>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_Export_LineFeed_Utf16_RawStream()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Lf Utf16";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Y9LfValues(Note, Txt);
        Port.Seed(Note, Txt);
        Y9DestRaw(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', Y9Bytes(Buffer));
        Observer.Expect('export', 'bom=FFFE|bytes=302|<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Note>n1\r\nn2\r\nn3\r\nn4</Note>\r\n  <Row>\r\n    <Txt> a\r\n  b  \r\n</Txt>\r\n  </Row>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_Export_LineFeed_Utf16_Utf16Stream()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT Y9 XP Lf Utf16";
        OutS: OutStream;
        Note: Text;
        Txt: Text;
    begin
        Y9LfValues(Note, Txt);
        Port.Seed(Note, Txt);
        Buffer.Id := 1;
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF16);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', Y9Bytes(Buffer));
        Observer.Expect('export', 'bom=FFFE|bytes=302|<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Note>n1\r\nn2\r\nn3\r\nn4</Note>\r\n  <Row>\r\n    <Txt> a\r\n  b  \r\n</Txt>\r\n  </Row>\r\n</Root>');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_XmlPort_OnceOnce_ThreeRowsThenNone()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT NP4 XP Blob" temporary;
        Port: XmlPort "LT NP4 XP Once Once";
        OutS: OutStream;
    begin
        // head 1 has rows 11, 12, 13 in its filter, head 2 none: the Child element of head 2 shows the row the record holds after head 1
        SeedHeadsAndChildren(3, 0);
        Dest(Buffer, OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('export', ToText(Buffer));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Head id="1">|    <Child cid="11">|      <Txt>c11</Txt>|    </Child>|  </Head>|  <Head id="2">|    <Child cid="12">|      <Txt>c12</Txt>|    </Child>|  </Head>|</Root>|len=243');
        Observer.Verify();
    end;
}

table 91450 "LT Y9 XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 91451 "LT Y9 XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Kind; Code[10]) { }
        field(4; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; HeadId, LineNo) { Clustered = true; }
    }
}

// Nested table element linked to its parent (LinkTable + LinkFields) with a SourceTableView (descending, Kind = A), MinOccurs = Once, MaxOccurs = Once.
xmlport 91452 "LT Y9 XP Linked Once"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT Y9 XP Head")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(id; Head.Id) { }
                tableelement(Line; "LT Y9 XP Line")
                {
                    LinkTable = Head;
                    LinkFields = HeadId = field(Id);
                    SourceTableView = sorting(HeadId, LineNo) order(descending) where(Kind = const('A'));
                    MinOccurs = Once;
                    MaxOccurs = Once;
                    fieldattribute(head; Line.HeadId) { }
                    fieldattribute(no; Line.LineNo) { }
                    fieldelement(Txt; Line.Txt) { }
                }
            }
        }
    }

    procedure HeldLine(): Text
    begin
        exit(Format(Line.HeadId) + '/' + Format(Line.LineNo) + '/' + Line.Kind + '/' + Line.Txt + '|filters=' + Line.GetFilters());
    end;
}

xmlport 91453 "LT Y9 XP Imp NsPreserve"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y9';
    UseDefaultNamespace = true;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note) { }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }

                trigger OnBeforeInsertRecord()
                begin
                    NextId += 1;
                    Row.Id := NextId;
                end;
            }
        }
    }

    var
        NextId: Integer;

    procedure Result(): Text
    var
        Shown: Text;
    begin
        Shown := 'note=[' + Note + '] rows=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Shown += ' [' + Row.Txt + ']';
            until Row.Next() = 0;
        exit(Shown);
    end;
}

xmlport 91454 "LT Y9 XP Imp NsDefault"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    DefaultNamespace = 'urn:y9';
    UseDefaultNamespace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note) { }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }

                trigger OnBeforeInsertRecord()
                begin
                    NextId += 1;
                    Row.Id := NextId;
                end;
            }
        }
    }

    var
        NextId: Integer;

    procedure Result(): Text
    var
        Shown: Text;
    begin
        Shown := 'note=[' + Note + '] rows=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Shown += ' [' + Row.Txt + ']';
            until Row.Next() = 0;
        exit(Shown);
    end;
}

xmlport 91455 "LT Y9 XP Imp NoNsPreserve"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    PreserveWhiteSpace = true;

    schema
    {
        textelement(Root)
        {
            textelement(Note) { }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }

                trigger OnBeforeInsertRecord()
                begin
                    NextId += 1;
                    Row.Id := NextId;
                end;
            }
        }
    }

    var
        NextId: Integer;

    procedure Result(): Text
    var
        Shown: Text;
    begin
        Shown := 'note=[' + Note + '] rows=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Shown += ' [' + Row.Txt + ']';
            until Row.Next() = 0;
        exit(Shown);
    end;
}

xmlport 91456 "LT Y9 XP Imp Plain"
{
    Direction = Import;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Note) { }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }

                trigger OnBeforeInsertRecord()
                begin
                    NextId += 1;
                    Row.Id := NextId;
                end;
            }
        }
    }

    var
        NextId: Integer;

    procedure Result(): Text
    var
        Shown: Text;
    begin
        Shown := 'note=[' + Note + '] rows=' + Format(Row.Count());
        if Row.FindSet() then
            repeat
                Shown += ' [' + Row.Txt + ']';
            until Row.Next() = 0;
        exit(Shown);
    end;
}

// Export of a text value with line ends: no PreserveWhiteSpace, no namespace, UTF8.
xmlport 91457 "LT Y9 XP Lf Plain"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Note)
            {
                trigger OnBeforePassVariable()
                begin
                    Note := NoteText;
                end;
            }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    var
        NoteText: Text;

    procedure Seed(NewNote: Text; NewTxt: Text)
    begin
        NoteText := NewNote;
        Row.Id := 1;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;
}

// The same with Encoding = UTF16.
xmlport 91458 "LT Y9 XP Lf Utf16"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF16;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Note)
            {
                trigger OnBeforePassVariable()
                begin
                    Note := NoteText;
                end;
            }
            tableelement(Row; "LT NP4 XP Row")
            {
                UseTemporary = true;
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    var
        NoteText: Text;

    procedure Seed(NewNote: Text; NewTxt: Text)
    begin
        NoteText := NewNote;
        Row.Id := 1;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;
}
