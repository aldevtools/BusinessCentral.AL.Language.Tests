// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93230-93233, xmlports 93230-93234, codeunits 93230-93232.
// Probe (gap cycle 6, G6-11): a text element with content inside a table element. Import: a temporary table element below a text
// element below a temporary table element (MaxOccurs = Once), whose field elements include a field of the OUTER table element; a text
// element with a text attribute and leaf text elements (one with its own text attribute) inside a table element. Export: a table element
// below a text element below a table element, with a nested table element (MinOccurs = Once, MaxOccurs = Once) and a linked one below it;
// a temporary table element with leaf text elements and a text element holding field elements with text attributes and a text element
// that holds a temporary table element. Shapes already pinned (not repeated): xmlport/lt-qr-xmlport-container-occurs (TO_*, TP_*, TT_*,
// TS_*, TQ_*, TR_*). Line breaks of the exported text are shown as |.
// Facts: on import the inner temporary records are inserted before the outer one, and a field element bound to the outer record
// assigns it on every inner record (the last value stays). A missing text attribute with the default Occurrence fails the import with
// XmlPortInvalidXml. On export a table element without LinkTable lists all its rows under every parent row; a table element with
// MinOccurs = Once and no row is written as an empty record. Values are the same on 27.5, 28.5, 29.0 and BC 29 SaaS.
// BC versions: 27-29

table 93230 "LT Y60 TT Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 93231 "LT Y60 TT Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Hdr No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Item; Text[30]) { }
        field(4; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Hdr No.", "Line No.") { Clustered = true; }
    }
}

table 93232 "LT Y60 TT Det"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Hdr No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Det No."; Integer) { }
        field(4; Info; Text[30]) { }
    }

    keys
    {
        key(PK; "Hdr No.", "Line No.", "Det No.") { Clustered = true; }
    }
}

table 93233 "LT Y60 TT Job"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93230 "LT Y60 TT Log"
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

xmlport 93230 "LT Y60 TT Wrap Temp Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Outer; "LT Y60 TT Hdr")
            {
                MaxOccurs = Once;
                UseTemporary = true;
                fieldelement(No; Outer."No.") { }
                textelement(Wrap)
                {
                    MinOccurs = Zero;
                    tableelement(Inner; "LT Y60 TT Line")
                    {
                        UseTemporary = true;
                        fieldelement(LineNo; Inner."Line No.") { }
                        fieldelement(Item; Inner.Item) { }
                        fieldelement(Name; Outer.Name) { }

                        trigger OnAfterInitRecord()
                        begin
                            Log.Add('inner init');
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            Log.Add('inner ins ' + Format(Inner."Line No.") + ' outer.name=' + Outer.Name);
                            Inner."Hdr No." := Outer."No.";
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    Log.Add('outer init');
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('outer ins ' + Outer."No." + ' name=' + Outer.Name);
                end;

                trigger OnBeforeModifyRecord()
                begin
                    Log.Add('outer mod ' + Outer."No." + ' name=' + Outer.Name);
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post outer=' + OuterRows() + ' inner=' + InnerRows());
    end;

    local procedure OuterRows() Result: Text
    begin
        Outer.Reset();
        if Outer.FindSet() then
            repeat
                Result += '[' + Outer."No." + '|' + Outer.Name + ']';
            until Outer.Next() = 0;
    end;

    local procedure InnerRows() Result: Text
    begin
        Inner.Reset();
        if Inner.FindSet() then
            repeat
                Result += '[' + Inner."Hdr No." + '|' + Format(Inner."Line No.") + '|' + Inner.Item + ']';
            until Inner.Next() = 0;
    end;

    var
        Log: Codeunit "LT Y60 TT Log";
}

xmlport 93234 "LT Y60 TT Wrap Once Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Outer; "LT Y60 TT Hdr")
            {
                MaxOccurs = Once;
                UseTemporary = true;
                fieldelement(No; Outer."No.") { }
                textelement(Wrap)
                {
                    MinOccurs = Once;
                    tableelement(Inner; "LT Y60 TT Line")
                    {
                        UseTemporary = true;
                        fieldelement(LineNo; Inner."Line No.") { }
                        fieldelement(Item; Inner.Item) { }
                        fieldelement(Name; Outer.Name) { }

                        trigger OnBeforeInsertRecord()
                        begin
                            Log.Add('inner ins ' + Format(Inner."Line No.") + ' outer.name=' + Outer.Name);
                            Inner."Hdr No." := Outer."No.";
                        end;
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('outer ins ' + Outer."No." + ' name=' + Outer.Name);
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Outer.Reset();
        Inner.Reset();
        Log.Add('post outer=' + Format(Outer.Count()) + ' inner=' + Format(Inner.Count()));
    end;

    var
        Log: Codeunit "LT Y60 TT Log";
}

xmlport 93231 "LT Y60 TT Ticket Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y60 TT Hdr")
            {
                textelement(Ticket)
                {
                    textattribute(kind)
                    {
                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('kind=' + kind);
                            Row.Name := CopyStr(kind, 1, MaxStrLen(Row.Name));
                        end;
                    }
                    textelement(Code)
                    {
                        MinOccurs = Zero;

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('code=' + Code);
                            Row."No." := CopyStr(Code, 1, MaxStrLen(Row."No."));
                        end;
                    }
                    textelement(Title)
                    {
                        MinOccurs = Zero;
                        textattribute(lang)
                        {
                            trigger OnAfterAssignVariable()
                            begin
                                Log.Add('lang=' + lang);
                            end;
                        }

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('title=' + Title);
                            Row.Note := CopyStr(Title, 1, MaxStrLen(Row.Note));
                        end;
                    }

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('ticket=[' + Ticket + ']');
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Log.Add('ins ' + Row."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y60 TT Log";
}

xmlport 93232 "LT Y60 TT Wrap Export"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y60 TT Hdr")
            {
                fieldattribute(No; Row."No.") { }
                textelement(Wrap)
                {
                    MinOccurs = Zero;
                    tableelement(Mid; "LT Y60 TT Line")
                    {
                        MinOccurs = Zero;
                        fieldattribute(Hdr; Mid."Hdr No.") { }
                        fieldattribute(LineNo; Mid."Line No.") { }
                        tableelement(Leaf; "LT Y60 TT Det")
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                            fieldattribute(DetNo; Leaf."Det No.") { }
                            tableelement(Sub; "LT Y60 TT Det")
                            {
                                LinkTable = Leaf;
                                LinkFields = "Hdr No." = field("Hdr No.");
                                MinOccurs = Zero;
                                fieldattribute(SubNo; Sub."Det No.") { }
                                fieldattribute(Info; Sub.Info) { }

                                trigger OnAfterGetRecord()
                                begin
                                    Log.Add('sub ' + Sub."Hdr No." + '/' + Format(Sub."Det No."));
                                end;
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Log.Add('leaf ' + Leaf."Hdr No." + '/' + Format(Leaf."Det No."));
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('mid ' + Mid."Hdr No." + '/' + Format(Mid."Line No."));
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('row ' + Row."No.");
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y60 TT Log";
}

xmlport 93233 "LT Y60 TT Info Export"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y60 TT Hdr")
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                UseTemporary = true;
                textelement(A)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('a');
                        A := 'a-' + Row."No.";
                    end;
                }
                textelement(B)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('b');
                        B := GlobalB;
                    end;
                }
                textelement(Info)
                {
                    MinOccurs = Zero;
                    fieldelement(Name; Row.Name)
                    {
                        textattribute(unit)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('unit');
                                unit := 'pcs';
                            end;
                        }
                    }
                    fieldelement(Note; Row.Note) { }
                    textelement(Sub)
                    {
                        tableelement(Child; "LT Y60 TT Line")
                        {
                            UseTemporary = true;
                            fieldelement(LineNo; Child."Line No.") { }
                            fieldelement(Item; Child.Item) { }

                            trigger OnAfterGetRecord()
                            begin
                                Log.Add('child ' + Format(Child."Line No."));
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('sub');
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('info');
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('row ' + Row."No.");
                end;
            }
        }
    }

    procedure SetData(var TempHdr: Record "LT Y60 TT Hdr" temporary; var TempLine: Record "LT Y60 TT Line" temporary; NewB: Text)
    begin
        if TempHdr.FindSet() then
            repeat
                Row := TempHdr;
                Row.Insert();
            until TempHdr.Next() = 0;
        if TempLine.FindSet() then
            repeat
                Child := TempLine;
                Child.Insert();
            until TempLine.Next() = 0;
        GlobalB := NewB;
    end;

    var
        Log: Codeunit "LT Y60 TT Log";
        GlobalB: Text;
}

codeunit 93231 "LT Y60 TT Import Runner"
{
    TableNo = "LT Y60 TT Job";

    trigger OnRun()
    var
        InS: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Rec.Id, InS);
    end;
}

codeunit 93232 "LT Y60 TT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y60 TT Log";

    local procedure RunImport(XmlportId: Integer; Content: Text): Boolean
    var
        Job: Record "LT Y60 TT Job" temporary;
        OutS: OutStream;
    begin
        Job.Id := XmlportId;
        Job.Insert();
        Job.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        Job.Modify();
        Commit();
        exit(Codeunit.Run(Codeunit::"LT Y60 TT Import Runner", Job));
    end;

    local procedure HdrRows() Result: Text
    var
        Hdr: Record "LT Y60 TT Hdr";
    begin
        if Hdr.FindSet() then
            repeat
                Result += '[' + Hdr."No." + '|' + Hdr.Name + '|' + Hdr.Note + ']';
            until Hdr.Next() = 0;
    end;

    local procedure Clean()
    var
        Hdr: Record "LT Y60 TT Hdr";
        Line: Record "LT Y60 TT Line";
        Det: Record "LT Y60 TT Det";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        Det.DeleteAll();
        Log.Take();
        Commit();
    end;

    local procedure ObserveImport(var Observer: Codeunit "Probe Observer"; Name: Text; XmlportId: Integer; Content: Text)
    begin
        Clean();
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(RunImport(XmlportId, Content)));
        if GetLastErrorText() <> '' then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' hdr rows', HdrRows());
    end;

    local procedure ExportText(XmlportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure AddHdr(No: Code[20]; Name: Text[30])
    var
        Hdr: Record "LT Y60 TT Hdr";
    begin
        Hdr."No." := No;
        Hdr.Name := Name;
        Hdr.Insert();
    end;

    local procedure AddLine(HdrNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT Y60 TT Line";
    begin
        Line."Hdr No." := HdrNo;
        Line."Line No." := LineNo;
        Line.Item := 'item' + Format(LineNo);
        Line.Insert();
    end;

    local procedure AddDet(HdrNo: Code[20]; LineNo: Integer; DetNo: Integer)
    var
        Det: Record "LT Y60 TT Det";
    begin
        Det."Hdr No." := HdrNo;
        Det."Line No." := LineNo;
        Det."Det No." := DetNo;
        Det.Info := 'info' + Format(DetNo);
        Det.Insert();
    end;

    [Test]
    procedure TextWrap_TempTable_Inner_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'two inner', Xmlport::"LT Y60 TT Wrap Temp Import",
            '<Root><Outer><No>H1</No><Wrap><Inner><LineNo>1</LineNo><Item>a</Item><Name>n1</Name></Inner>' +
            '<Inner><LineNo>2</LineNo><Item>b</Item><Name>n2</Name></Inner></Wrap></Outer></Root>');
        ObserveImport(Observer, 'no wrap', Xmlport::"LT Y60 TT Wrap Temp Import", '<Root><Outer><No>H1</No></Outer></Root>');
        ObserveImport(Observer, 'wrap once two inner', Xmlport::"LT Y60 TT Wrap Once Import",
            '<Root><Outer><No>H1</No><Wrap><Inner><LineNo>1</LineNo><Item>a</Item><Name>n1</Name></Inner>' +
            '<Inner><LineNo>2</LineNo><Item>b</Item><Name>n2</Name></Inner></Wrap></Outer></Root>');
        ObserveImport(Observer, 'wrap once missing', Xmlport::"LT Y60 TT Wrap Once Import", '<Root><Outer><No>H1</No></Outer></Root>');
        Observer.Expect('two inner ok', 'Yes');
        Observer.Expect('two inner log', 'outer init;inner init;inner ins 1 outer.name=n1;inner init;inner ins 2 outer.name=n2;outer ins H1 name=n2;post outer=[H1|n2] inner=[H1|1|a][H1|2|b];');
        Observer.Expect('two inner hdr rows', '');
        Observer.Expect('no wrap ok', 'Yes');
        Observer.Expect('no wrap log', 'outer init;outer ins H1 name=;post outer=[H1|] inner=;');
        Observer.Expect('no wrap hdr rows', '');
        Observer.Expect('wrap once two inner ok', 'Yes');
        Observer.Expect('wrap once two inner log', 'inner ins 1 outer.name=n1;inner ins 2 outer.name=n2;outer ins H1 name=n2;post outer=1 inner=2;');
        Observer.Expect('wrap once two inner hdr rows', '');
        Observer.Expect('wrap once missing ok', 'No');
        Observer.Expect('wrap once missing error', 'Imported XML cannot validate with the schema: The element ''Outer'' has incomplete content. List of possible elements expected: ''Wrap''.');
        Observer.Expect('wrap once missing code', 'XmlPortInvalidXml');
        Observer.Expect('wrap once missing log', '');
        Observer.Expect('wrap once missing hdr rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure TextWrap_Attr_Leaves_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveImport(Observer, 'full', Xmlport::"LT Y60 TT Ticket Import",
            '<Root><Row><Ticket kind="k"><Code>c</Code><Title lang="en">t</Title></Ticket></Row></Root>');
        ObserveImport(Observer, 'title missing', Xmlport::"LT Y60 TT Ticket Import",
            '<Root><Row><Ticket kind="k"><Code>c</Code></Ticket></Row></Root>');
        ObserveImport(Observer, 'no lang', Xmlport::"LT Y60 TT Ticket Import",
            '<Root><Row><Ticket kind="k"><Code>c</Code><Title>t</Title></Ticket></Row></Root>');
        ObserveImport(Observer, 'two rows', Xmlport::"LT Y60 TT Ticket Import",
            '<Root><Row><Ticket kind="k1"><Code>c1</Code></Ticket></Row><Row><Ticket kind="k2"><Code>c2</Code><Title lang="de">t2</Title></Ticket></Row></Root>');
        Observer.Expect('full ok', 'Yes');
        Observer.Expect('full log', 'kind=k;code=c;lang=en;title=t;ticket=[];ins C;');
        Observer.Expect('full hdr rows', '[C|k|t]');
        Observer.Expect('title missing ok', 'Yes');
        Observer.Expect('title missing log', 'kind=k;code=c;ticket=[];ins C;');
        Observer.Expect('title missing hdr rows', '[C|k|]');
        Observer.Expect('no lang ok', 'No');
        Observer.Expect('no lang error', 'Imported XML cannot validate with the schema: The required attribute ''lang'' is missing.');
        Observer.Expect('no lang code', 'XmlPortInvalidXml');
        Observer.Expect('no lang log', 'kind=k;code=c;');
        Observer.Expect('no lang hdr rows', '');
        Observer.Expect('two rows ok', 'Yes');
        Observer.Expect('two rows log', 'kind=k1;code=c1;ticket=[];ins C1;kind=k2;code=c2;lang=de;title=t2;ticket=[];ins C2;');
        Observer.Expect('two rows hdr rows', '[C1|k1|][C2|k2|t2]');
        Observer.Verify();
    end;

    [Test]
    procedure TextWrap_Table_Nested_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        AddHdr('H1', 'one');
        AddHdr('H2', 'two');
        AddLine('H1', 10);
        AddLine('H1', 20);
        AddDet('H1', 10, 1);
        AddDet('H1', 10, 2);
        Observer.Observe('xml', ExportText(Xmlport::"LT Y60 TT Wrap Export"));
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row No="H1">|    <Wrap>|      <Mid Hdr="H1" LineNo="10">|        <Leaf DetNo="1">|          <Sub SubNo="1" Info="info1" />|          <Sub SubNo="2" Info="info2" />|        </Leaf>|      </Mid>|      <Mid Hdr="H1" LineNo="20">|        <Leaf DetNo="1">|          <Sub SubNo="1" Info="info1" />|          <Sub SubNo="2" Info="info2" />|        </Leaf>|      </Mid>|    </Wrap>|  </Row>|  <Row No="H2">|    <Wrap>|      <Mid Hdr="H1" LineNo="10">|        <Leaf DetNo="1">|          <Sub SubNo="1" Info="info1" />|          <Sub SubNo="2" Info="info2" />|        </Leaf>|      </Mid>|      <Mid Hdr="H1" LineNo="20">|        <Leaf DetNo="1">|          <Sub SubNo="1" Info="info1" />|          <Sub SubNo="2" Info="info2" />|        </Leaf>|      </Mid>|    </Wrap>|  </Row>|</Root>|');
        Observer.Expect('log', 'row H1;mid H1/10;leaf H1/1;sub H1/1;sub H1/2;mid H1/20;leaf H1/1;sub H1/1;sub H1/2;row H2;mid H1/10;leaf H1/1;sub H1/1;sub H1/2;mid H1/20;leaf H1/1;sub H1/1;sub H1/2;');
        Observer.Verify();
    end;

    [Test]
    procedure TextWrap_Q3_NoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        AddHdr('H1', 'one');
        Observer.Observe('no lines xml', ExportText(Xmlport::"LT Y60 TT Wrap Export"));
        Observer.Observe('no lines log', Log.Take());
        AddLine('H1', 10);
        Observer.Observe('no det xml', ExportText(Xmlport::"LT Y60 TT Wrap Export"));
        Observer.Observe('no det log', Log.Take());
        Observer.Expect('no lines xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row No="H1">|    <Wrap />|  </Row>|</Root>|');
        Observer.Expect('no lines log', 'row H1;');
        Observer.Expect('no det xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row No="H1">|    <Wrap>|      <Mid Hdr="H1" LineNo="10">|        <Leaf DetNo="0" />|      </Mid>|    </Wrap>|  </Row>|</Root>|');
        Observer.Expect('no det log', 'row H1;mid H1/10;');
        Observer.Verify();
    end;

    [Test]
    procedure TextWrap_Info_Fields_Sub_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempHdr: Record "LT Y60 TT Hdr" temporary;
        TempLine: Record "LT Y60 TT Line" temporary;
        XP: XmlPort "LT Y60 TT Info Export";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Clean();
        TempHdr."No." := 'H1';
        TempHdr.Name := 'one';
        TempHdr.Note := 'n1';
        TempHdr.Insert();
        TempHdr."No." := 'H2';
        TempHdr.Name := 'two';
        TempHdr.Note := '';
        TempHdr.Insert();
        TempLine."Hdr No." := 'H1';
        TempLine."Line No." := 1;
        TempLine.Item := 'x';
        TempLine.Insert();
        TempLine."Hdr No." := 'H2';
        TempLine."Line No." := 2;
        TempLine.Item := 'y';
        TempLine.Insert();
        XP.SetData(TempHdr, TempLine, 'gb');
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        Observer.Observe('xml', Result);
        Observer.Observe('log', Log.Take());
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row>|    <A>a-H1</A>|    <B>gb</B>|    <Info>|      <Name unit="pcs">one</Name>|      <Note>n1</Note>|      <Sub>|        <Child>|          <LineNo>1</LineNo>|          <Item>x</Item>|        </Child>|        <Child>|          <LineNo>2</LineNo>|          <Item>y</Item>|        </Child>|      </Sub>|    </Info>|  </Row>|  <Row>|    <A>a-H2</A>|    <B>gb</B>|    <Info>|      <Name unit="pcs">two</Name>|      <Note />|      <Sub>|        <Child>|          <LineNo>1</LineNo>|          <Item>x</Item>|        </Child>|        <Child>|          <LineNo>2</LineNo>|          <Item>y</Item>|        </Child>|      </Sub>|    </Info>|  </Row>|</Root>|');
        Observer.Expect('log', 'row H1;a;b;info;unit;sub;child 1;child 2;row H2;a;b;info;unit;sub;child 1;child 2;');
        Observer.Verify();
    end;
}
