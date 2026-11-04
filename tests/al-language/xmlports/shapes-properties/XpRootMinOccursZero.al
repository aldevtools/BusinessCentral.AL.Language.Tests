// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 50002 "ALT Shape 02" (as temporary table elements), System Application codeunit
//   "Temp Blob"; own xmlports 95494-95497 (their MinOccurs properties are under test) and the runner codeunit 95484
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: MinOccurs = Zero on the root text element of an xmlport, with Format = Xml and Format = VariableText, Direction = Both, and
//   MinOccurs on the elements below it (container text element, leaf text elements, table element, field elements with Once and Zero).
//   Export with no rows and with rows (the text, lines joined by |), import of a document with the root, of the root alone, of an empty
//   document, of another root and of a document that starts at a child element (the rows and the trigger log the import made, or the
//   error text and code; the import runs inside Codeunit.Run so a failed import does not end the test).
//   (AL Runner issue 6963: a dependency app's configuration port has MinOccurs = Zero on its root.)
// Facts (29.0): MinOccurs = Zero on the root changes nothing that is seen here: export writes the root (and every container) also without
//   rows; import takes the root with or without content, and an empty file, a document without a root element, another root, a document that
//   starts at a child element or two roots fail as for a root with the default occurs (texts and codes below). Below the root, MinOccurs = Once
//   on a leaf text element or a field element makes import fail the schema when the element is missing; MinOccurs = Zero lets it be missing.
//   Export writes an empty element for a blank value either way; a table element with the default occurs and no rows is written once, blank.
//   95494 "XP Root Min Zero Issue": the port of the issue: root Cfg (MaxOccurs = Once, MinOccurs = Zero) > Namespaces (the same) > table
//     element Item (MinOccurs = Zero) > field elements Code and Url (MinOccurs = Zero).
//   95495 "XP Root Min Zero Table": root Cfg (MinOccurs = Zero) > table element Item with the default occurs > two field elements.
//   95496 "XP Root Min Zero Children": root Cfg (MinOccurs = Zero, MaxOccurs = Once) > leaf text element Head (MinOccurs = Once) > leaf
//     text element Opt (MinOccurs = Zero) > table element Item (MinOccurs = Zero) > field element Code (MinOccurs = Once) and Url (Zero).
//   95497 "XP Root Min Zero VarText": VariableText, root Cfg (MinOccurs = Zero) > table element Item (MinOccurs = Zero) > two fields.
// BC versions: 27.5, 28.5, 29.0

xmlport 95494 "XP Root Min Zero Issue"
{
    // local object: its MinOccurs properties are under test
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Cfg)
        {
            MaxOccurs = Once;
            MinOccurs = Zero;
            textelement(Namespaces)
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                tableelement(Item; "ALT Shape 02")
                {
                    MinOccurs = Zero;
                    UseTemporary = true;
                    fieldelement(Code; Item."No.") { MinOccurs = Zero; }
                    fieldelement(Url; Item.Descr) { MinOccurs = Zero; }

                    trigger OnBeforeInsertRecord()
                    begin
                        Log += 'insert ' + Item."No." + ';';
                    end;
                }
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(NewNo: Code[20]; NewDescr: Text)
    begin
        Item."No." := NewNo;
        Item.Descr := NewDescr;
        Item.Insert();
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Item."No." + '=[' + Item.Descr + '];';
            until Item.Next() = 0;
        exit(Result + ' log=' + Log);
    end;
}

xmlport 95495 "XP Root Min Zero Table"
{
    // local object: its MinOccurs properties are under test
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Cfg)
        {
            MinOccurs = Zero;
            tableelement(Item; "ALT Shape 02")
            {
                UseTemporary = true;
                fieldelement(Code; Item."No.") { }
                fieldelement(Url; Item.Descr) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ' + Item."No." + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(NewNo: Code[20]; NewDescr: Text)
    begin
        Item."No." := NewNo;
        Item.Descr := NewDescr;
        Item.Insert();
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Item."No." + '=[' + Item.Descr + '];';
            until Item.Next() = 0;
        exit(Result + ' log=' + Log);
    end;
}

xmlport 95496 "XP Root Min Zero Children"
{
    // local object: its MinOccurs properties are under test
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Cfg)
        {
            MinOccurs = Zero;
            MaxOccurs = Once;
            textelement(Head)
            {
                MinOccurs = Once;
                MaxOccurs = Once;

                trigger OnBeforePassVariable()
                begin
                    Head := 'H';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'head ' + Head + ';';
                end;
            }
            textelement(Opt)
            {
                MinOccurs = Zero;
                MaxOccurs = Once;

                trigger OnAfterAssignVariable()
                begin
                    Log += 'opt ' + Opt + ';';
                end;
            }
            tableelement(Item; "ALT Shape 02")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(Code; Item."No.") { MinOccurs = Once; }
                fieldelement(Url; Item.Descr) { MinOccurs = Zero; }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ' + Item."No." + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(NewNo: Code[20]; NewDescr: Text)
    begin
        Item."No." := NewNo;
        Item.Descr := NewDescr;
        Item.Insert();
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Item."No." + '=[' + Item.Descr + '];';
            until Item.Next() = 0;
        exit(Result + ' log=' + Log);
    end;
}

xmlport 95497 "XP Root Min Zero VarText"
{
    // local object: its MinOccurs properties are under test
    Direction = Both;
    Format = VariableText;
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Cfg)
        {
            MinOccurs = Zero;
            tableelement(Item; "ALT Shape 02")
            {
                MinOccurs = Zero;
                UseTemporary = true;
                fieldelement(Code; Item."No.") { }
                fieldelement(Url; Item.Descr) { }

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'insert ' + Item."No." + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(NewNo: Code[20]; NewDescr: Text)
    begin
        Item."No." := NewNo;
        Item.Descr := NewDescr;
        Item.Insert();
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        if Item.FindSet() then
            repeat
                Result += Item."No." + '=[' + Item.Descr + '];';
            until Item.Next() = 0;
        exit(Result + ' log=' + Log);
    end;
}

codeunit 95484 "XP Root Min Zero Runner"
{
    // Imports Input into one of the xmlports 95494-95497 (Mode is its id) inside Codeunit.Run, so a failed import does not end the test.
    var
        Input: Text;
        Mode: Integer;
        Outcome: Text;

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        Issue: XmlPort "XP Root Min Zero Issue";
        Table: XmlPort "XP Root Min Zero Table";
        Children: XmlPort "XP Root Min Zero Children";
        VarText: XmlPort "XP Root Min Zero VarText";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        case Mode of
            95494:
                begin
                    Issue.SetSource(InS);
                    Issue.Import();
                    Outcome := Issue.Rows();
                end;
            95495:
                begin
                    Table.SetSource(InS);
                    Table.Import();
                    Outcome := Table.Rows();
                end;
            95496:
                begin
                    Children.SetSource(InS);
                    Children.Import();
                    Outcome := Children.Rows();
                end;
            95497:
                begin
                    VarText.SetSource(InS);
                    VarText.Import();
                    Outcome := VarText.Rows();
                end;
        end;
    end;

    procedure SetInput(NewMode: Integer; NewInput: Text)
    begin
        Mode := NewMode;
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}

codeunit 95483 "XP Root Min Zero"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    local procedure Import(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Body: Text)
    var
        Runner: Codeunit "XP Root Min Zero Runner";
    begin
        Runner.SetInput(Mode, Body);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe(Name, 'ok ' + Runner.Result())
        else
            Observer.ObserveError(Name);
    end;

    local procedure XmlDecl(): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?>');
    end;

    local procedure CrLf(): Text
    var
        C: Text[2];
    begin
        C[1] := 13;
        C[2] := 10;
        exit(C);
    end;

    [Test]
    procedure RootMinOccursZero_Issue_Export()
    var
        Observer: Codeunit "Probe Observer";
        Empty: XmlPort "XP Root Min Zero Issue";
        Filled: XmlPort "XP Root Min Zero Issue";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no rows', ReadLines(TempBlob));
        Clear(TempBlob);
        Filled.AddRow('A', 'urn:a');
        Filled.AddRow('B', '');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Filled.SetDestination(OutS);
        Filled.Export();
        Observer.Observe('two rows, the second with a blank Url', ReadLines(TempBlob));
        Observer.Expect('no rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Namespaces />|</Cfg>|');
        Observer.Expect('two rows, the second with a blank Url', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Namespaces>|    <Item>|      <Code>A</Code>|      <Url>urn:a</Url>|    </Item>|    <Item>|      <Code>B</Code>|      <Url />|    </Item>|  </Namespaces>|</Cfg>|');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Table_Export()
    var
        Observer: Codeunit "Probe Observer";
        Empty: XmlPort "XP Root Min Zero Table";
        Filled: XmlPort "XP Root Min Zero Table";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no rows', ReadLines(TempBlob));
        Clear(TempBlob);
        Filled.AddRow('A', 'urn:a');
        Filled.AddRow('B', '');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Filled.SetDestination(OutS);
        Filled.Export();
        Observer.Observe('two rows, the second with a blank Url', ReadLines(TempBlob));
        Observer.Expect('no rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Item>|    <Code />|    <Url />|  </Item>|</Cfg>|');
        Observer.Expect('two rows, the second with a blank Url', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Item>|    <Code>A</Code>|    <Url>urn:a</Url>|  </Item>|  <Item>|    <Code>B</Code>|    <Url />|  </Item>|</Cfg>|');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Children_Export()
    var
        Observer: Codeunit "Probe Observer";
        Empty: XmlPort "XP Root Min Zero Children";
        Filled: XmlPort "XP Root Min Zero Children";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no rows', ReadLines(TempBlob));
        Clear(TempBlob);
        Filled.AddRow('A', 'urn:a');
        Filled.AddRow('B', '');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Filled.SetDestination(OutS);
        Filled.Export();
        Observer.Observe('two rows, the second with a blank Url', ReadLines(TempBlob));
        Observer.Expect('no rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Head>H</Head>|  <Opt />|</Cfg>|');
        Observer.Expect('two rows, the second with a blank Url', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Cfg>|  <Head>H</Head>|  <Opt />|  <Item>|    <Code>A</Code>|    <Url>urn:a</Url>|  </Item>|  <Item>|    <Code>B</Code>|    <Url />|  </Item>|</Cfg>|');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_VarText_Export()
    var
        Observer: Codeunit "Probe Observer";
        Empty: XmlPort "XP Root Min Zero VarText";
        Filled: XmlPort "XP Root Min Zero VarText";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Empty.SetDestination(OutS);
        Empty.Export();
        Observer.Observe('no rows', ReadLines(TempBlob));
        Clear(TempBlob);
        Filled.AddRow('A', 'urn:a');
        Filled.AddRow('B', '');
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Filled.SetDestination(OutS);
        Filled.Export();
        Observer.Observe('two rows, the second with a blank Url', ReadLines(TempBlob));
        Observer.Expect('no rows', '|');
        Observer.Expect('two rows, the second with a blank Url', '"A","urn:a"|"B",""|');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Issue_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'issue document', 95494, XmlDecl() + '<Cfg><Namespaces><Item><Code>A</Code><Url>urn:a</Url></Item><Item><Code>B</Code></Item></Namespaces></Cfg>');
        Import(Observer, 'root alone', 95494, XmlDecl() + '<Cfg />');
        Import(Observer, 'root and empty container', 95494, XmlDecl() + '<Cfg><Namespaces /></Cfg>');
        Import(Observer, 'empty document', 95494, '');
        Import(Observer, 'declaration only', 95494, XmlDecl());
        Observer.Expect('issue document', 'ok A=[urn:a];B=[]; log=insert A;insert B;');
        Observer.Expect('root alone', 'ok  log=');
        Observer.Expect('root and empty container', 'ok  log=');
        Observer.Expect('empty document|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('empty document|code', 'XmlPortData');
        Observer.Expect('declaration only|text', 'Root element is missing.');
        Observer.Expect('declaration only|code', 'XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Issue_Import2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'other root', 95494, XmlDecl() + '<Other><Namespaces><Item><Code>A</Code></Item></Namespaces></Other>');
        Import(Observer, 'starts at the container', 95494, XmlDecl() + '<Namespaces><Item><Code>A</Code></Item></Namespaces>');
        Import(Observer, 'starts at the table element', 95494, XmlDecl() + '<Item><Code>A</Code></Item>');
        Import(Observer, 'two roots', 95494, XmlDecl() + '<Cfg /><Cfg />');
        Observer.Expect('other root|text', 'Imported XML cannot validate with the schema: The ''Other'' element is not declared.');
        Observer.Expect('other root|code', 'XmlPortInvalidXml');
        Observer.Expect('starts at the container|text', 'Imported XML cannot validate with the schema: The ''Namespaces'' element is not declared.');
        Observer.Expect('starts at the container|code', 'XmlPortInvalidXml');
        Observer.Expect('starts at the table element|text', 'Imported XML cannot validate with the schema: The ''Item'' element is not declared.');
        Observer.Expect('starts at the table element|code', 'XmlPortInvalidXml');
        Observer.Expect('two roots|text', 'There are multiple root elements. Line 1, position 47.');
        Observer.Expect('two roots|code', 'XmlPortImport:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Table_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'two rows', 95495, XmlDecl() + '<Cfg><Item><Code>A</Code><Url>urn:a</Url></Item><Item><Code>B</Code><Url /></Item></Cfg>');
        Import(Observer, 'root alone', 95495, XmlDecl() + '<Cfg />');
        Import(Observer, 'empty document', 95495, '');
        Import(Observer, 'starts at the table element', 95495, XmlDecl() + '<Item><Code>A</Code><Url>urn:a</Url></Item>');
        Observer.Expect('two rows', 'ok A=[urn:a];B=[]; log=insert A;insert B;');
        Observer.Expect('root alone|text', 'Imported XML cannot validate with the schema: The element ''Cfg'' has incomplete content. List of possible elements expected: ''Item''.');
        Observer.Expect('root alone|code', 'XmlPortInvalidXml');
        Observer.Expect('empty document|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('empty document|code', 'XmlPortData');
        Observer.Expect('starts at the table element|text', 'Imported XML cannot validate with the schema: The ''Item'' element is not declared.');
        Observer.Expect('starts at the table element|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Children_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'full', 95496, XmlDecl() + '<Cfg><Head>h</Head><Opt>o</Opt><Item><Code>A</Code><Url>urn:a</Url></Item></Cfg>');
        Import(Observer, 'no Opt', 95496, XmlDecl() + '<Cfg><Head>h</Head><Item><Code>A</Code></Item></Cfg>');
        Import(Observer, 'no Head', 95496, XmlDecl() + '<Cfg><Opt>o</Opt><Item><Code>A</Code></Item></Cfg>');
        Import(Observer, 'no Code', 95496, XmlDecl() + '<Cfg><Head>h</Head><Item><Url>urn:a</Url></Item></Cfg>');
        Import(Observer, 'root alone', 95496, XmlDecl() + '<Cfg />');
        Observer.Expect('full', 'ok A=[urn:a]; log=head h;opt o;insert A;');
        Observer.Expect('no Opt', 'ok A=[]; log=head h;insert A;');
        Observer.Expect('no Head|text', 'Imported XML cannot validate with the schema: The element ''Cfg'' has invalid child element ''Opt''. List of possible elements expected: ''Head''.');
        Observer.Expect('no Head|code', 'XmlPortInvalidXml');
        Observer.Expect('no Code|text', 'Imported XML cannot validate with the schema: The element ''Item'' has invalid child element ''Url''. List of possible elements expected: ''Code''.');
        Observer.Expect('no Code|code', 'XmlPortInvalidXml');
        Observer.Expect('root alone|text', 'Imported XML cannot validate with the schema: The element ''Cfg'' has incomplete content. List of possible elements expected: ''Head''.');
        Observer.Expect('root alone|code', 'XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_Children_Import2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'empty document', 95496, '');
        Observer.Expect('empty document|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('empty document|code', 'XmlPortData');
        Observer.Verify();
    end;

    [Test]
    procedure RootMinOccursZero_VarText_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Import(Observer, 'two lines', 95497, 'A,urn:a' + CrLf() + 'B,' + CrLf());
        Import(Observer, 'empty document', 95497, '');
        Observer.Expect('two lines', 'ok A=[urn:a];B=[]; log=insert A;insert B;');
        Observer.Expect('empty document|text', 'Cannot import the specified XML document because the file is empty.');
        Observer.Expect('empty document|code', 'XmlPortData');
        Observer.Verify();
    end;
}
