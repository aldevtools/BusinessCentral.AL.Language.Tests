// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-preservewhitespace-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 93410-93412, xmlports 93413-93417, test codeunit 93418
// Writer NP4 (NP lane, 2026-10-30). Probe: (1) XmlPort export with PreserveWhiteSpace true and false, with DefaultNamespace + UseDefaultNamespace and without: the exported
//   text of a text element and a field element holding spaces and a line end (lines joined by |, plus the stream length). (2) A table element nested in a
//   table element without LinkTable, MinOccurs = Once and MaxOccurs = Once, with 0, 1 and 2 rows in the filter set by OnPreXmlItem.
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
}
