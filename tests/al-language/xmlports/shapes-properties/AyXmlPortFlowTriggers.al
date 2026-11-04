// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-break-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 80515, xmlports 80516-80517, codeunit 80518
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: currXMLport.Break, BreakUnbound and Quit called from a procedure that a trigger calls, with a statement after the call in the procedure and in
// the trigger: in the import triggers OnPreXmlPort, OnAfterAssignVariable, OnAfterInitRecord, OnAfterAssignField, OnBeforeInsertRecord and
// OnAfterInsertRecord, and in the export triggers OnPreXmlPort, OnBeforePassVariable, OnPreXmlItem and OnBeforePassField: the log of the statements
// that ran, the result of Import / Export, the rows stored and the text exported. XmlPortFlowFromTrigger.al pins OnAfterGetRecord.
// BC versions: 27, 28, 29 (corpus CI)

table 80515 "LT AY Flow Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 80516 "LT AY Flow Import"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Head)
            {
                trigger OnAfterAssignVariable()
                begin
                    if Fire('head') then begin
                        CallAction();
                        LogText += 'after-head;';
                    end;
                end;
            }
            tableelement(Rw; "LT AY Flow Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name)
                {
                    trigger OnAfterAssignField()
                    begin
                        if Fire('assign') then begin
                            CallAction();
                            LogText += 'after-assign;';
                        end;
                    end;
                }

                trigger OnAfterInitRecord()
                begin
                    if Fire('init') then begin
                        CallAction();
                        LogText += 'after-init;';
                    end;
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if Fire('beforeinsert') then begin
                        CallAction();
                        LogText += 'after-beforeinsert;';
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                    if Fire('afterinsert') then begin
                        CallAction();
                        LogText += 'after-afterinsert;';
                    end;
                end;
            }
        }
    }

    var
        Trig: Text;
        Action: Integer;
        LogText: Text;
        Hits: Dictionary of [Text, Integer];

    // the trigger Tag fires the action on its second run (on its first run for triggers that run once)
    local procedure Fire(Tag: Text): Boolean
    var
        N: Integer;
    begin
        if Hits.Get(Tag, N) then;
        N += 1;
        Hits.Set(Tag, N);
        LogText += Tag + Format(N) + ';';
        if Tag <> Trig then
            exit(false);
        if Tag in ['pre', 'head'] then
            exit(N = 1);
        exit(N = 2);
    end;

    local procedure CallAction()
    begin
        case Action of
            1:
                begin
                    currXMLport.Break();
                    LogText += 'proc-after-break;';
                end;
            2:
                begin
                    currXMLport.BreakUnbound();
                    LogText += 'proc-after-breakunbound;';
                end;
            3:
                begin
                    currXMLport.Quit();
                    LogText += 'proc-after-quit;';
                end;
        end;
    end;

    procedure SetMode(NewTrig: Text; NewAction: Integer)
    begin
        Trig := NewTrig;
        Action := NewAction;
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;

    trigger OnPreXmlPort()
    begin
        if Fire('pre') then begin
            CallAction();
            LogText += 'after-pre;';
        end;
    end;

    trigger OnPostXmlPort()
    begin
        LogText += 'post;';
    end;
}

xmlport 80517 "LT AY Flow Export"
{
    Format = Xml;
    Encoding = UTF8;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Head)
            {
                trigger OnBeforePassVariable()
                begin
                    Head := 'h';
                    if Fire('head') then begin
                        CallAction();
                        LogText += 'after-head;';
                    end;
                end;
            }
            tableelement(Rw; "LT AY Flow Row")
            {
                XmlName = 'Row';
                fieldelement(Id; Rw.Id) { }
                fieldelement(Name; Rw.Name)
                {
                    trigger OnBeforePassField()
                    begin
                        if Fire('passfield') then begin
                            CallAction();
                            LogText += 'after-passfield;';
                        end;
                    end;
                }

                trigger OnPreXmlItem()
                begin
                    if Fire('preitem') then begin
                        CallAction();
                        LogText += 'after-preitem;';
                    end;
                end;
            }
        }
    }

    var
        Trig: Text;
        Action: Integer;
        LogText: Text;
        Hits: Dictionary of [Text, Integer];

    // the trigger Tag fires the action on its second run (on its first run for triggers that run once)
    local procedure Fire(Tag: Text): Boolean
    var
        N: Integer;
    begin
        if Hits.Get(Tag, N) then;
        N += 1;
        Hits.Set(Tag, N);
        LogText += Tag + Format(N) + ';';
        if Tag <> Trig then
            exit(false);
        if Tag in ['pre', 'head'] then
            exit(N = 1);
        exit(N = 2);
    end;

    local procedure CallAction()
    begin
        case Action of
            1:
                begin
                    currXMLport.Break();
                    LogText += 'proc-after-break;';
                end;
            2:
                begin
                    currXMLport.BreakUnbound();
                    LogText += 'proc-after-breakunbound;';
                end;
            3:
                begin
                    currXMLport.Quit();
                    LogText += 'proc-after-quit;';
                end;
        end;
    end;

    procedure SetMode(NewTrig: Text; NewAction: Integer)
    begin
        Trig := NewTrig;
        Action := NewAction;
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;

    trigger OnPreXmlPort()
    begin
        if Fire('pre') then begin
            CallAction();
            LogText += 'after-pre;';
        end;
    end;

    trigger OnPostXmlPort()
    begin
        LogText += 'post;';
    end;
}

codeunit 80518 "LT AY Flow Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Lf(): Text
    var
        C: Char;
    begin
        C := 10;
        exit(Format(C));
    end;

    local procedure Rows(): Text
    var
        R: Record "LT AY Flow Row";
        Out: Text;
    begin
        if R.FindSet() then
            repeat
                Out += Format(R.Id) + '=' + R.Name + ',';
            until R.Next() = 0;
        exit(Out);
    end;

    // runs the import; ends with an error so that the rows are rolled back (the caller uses asserterror and observes GetLastErrorText)
    local procedure DoImport(var Observer: Codeunit "Probe Observer"; Trig: Text; Action: Integer)
    var
        R: Record "LT AY Flow Row";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Flow Import";
        OutS: OutStream;
        InS: InStream;
    begin
        R.DeleteAll();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Head>h</Head><Row><Id>1</Id><Name>a</Name></Row><Row><Id>2</Id><Name>b</Name></Row><Row><Id>3</Id><Name>c</Name></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetMode(Trig, Action);
        Xp.SetSource(InS);
        // statement form: the value-consuming form is refused while the setup rows are uncommitted (TestXmlPortImportWriteTx.al)
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('rows', Rows());
        Error('FINISHED');
    end;

    local procedure DoExport(var Observer: Codeunit "Probe Observer"; Trig: Text; Action: Integer)
    var
        R: Record "LT AY Flow Row";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Flow Export";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        All: Text;
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Id := i;
            R.Name := 'n' + Format(i);
            R.Insert();
        end;
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetMode(Trig, Action);
        Xp.SetDestination(OutS);
        Observer.Observe('ok', Format(Xp.Export()));
        Observer.Observe('log', Xp.GetLog());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line.Trim();
        end;
        Observer.Observe('xml', All.Replace('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', '<?decl?>'));
        Error('FINISHED');
    end;

    [Test]
    procedure Import_pre_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'pre', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;');
        Observer.Expect('rows', '');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_pre_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'pre', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;');
        Observer.Expect('rows', '');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_pre_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'pre', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;');
        Observer.Expect('rows', '');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_head_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'head', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;post;');
        Observer.Expect('rows', '');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_head_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'head', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;init3;assign3;beforeinsert3;afterinsert3;post;');
        Observer.Expect('rows', '1=a,2=b,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_head_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'head', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;');
        Observer.Expect('rows', '');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_init_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'init', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;post;');
        Observer.Expect('rows', '1=a,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_init_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'init', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;init3;assign3;beforeinsert3;afterinsert3;post;');
        Observer.Expect('rows', '1=a,2=b,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_init_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'init', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;');
        Observer.Expect('rows', '1=a,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_assign_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'assign', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;init3;assign3;beforeinsert3;afterinsert3;post;');
        Observer.Expect('rows', '1=a,2=b,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_assign_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'assign', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;init3;assign3;beforeinsert3;afterinsert3;post;');
        Observer.Expect('rows', '1=a,2=b,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_assign_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'assign', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;');
        Observer.Expect('rows', '1=a,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_beforeinsert_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'beforeinsert', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;post;');
        Observer.Expect('rows', '1=a,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_beforeinsert_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'beforeinsert', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;init3;assign3;beforeinsert3;afterinsert2;post;');
        Observer.Expect('rows', '1=a,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_beforeinsert_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'beforeinsert', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;');
        Observer.Expect('rows', '1=a,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_afterinsert_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'afterinsert', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;post;');
        Observer.Expect('rows', '1=a,2=b,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_afterinsert_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'afterinsert', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;init3;assign3;beforeinsert3;afterinsert3;post;');
        Observer.Expect('rows', '1=a,2=b,3=c,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Import_afterinsert_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoImport(Observer, 'afterinsert', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('log', 'pre1;head1;init1;assign1;beforeinsert1;afterinsert1;init2;assign2;beforeinsert2;afterinsert2;');
        Observer.Expect('rows', '1=a,2=b,');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_pre_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'pre', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('xml', '<?decl?>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_pre_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'pre', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('xml', '<?decl?>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_pre_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'pre', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('xml', '<?decl?>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_head_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'head', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;post;');
        Observer.Expect('xml', '<?decl?><Root />');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_head_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'head', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id><Name>n2</Name></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_head_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'head', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;');
        Observer.Expect('xml', '<?decl?><Root />');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_preitem_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'preitem', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id><Name>n2</Name></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_preitem_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'preitem', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id><Name>n2</Name></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_preitem_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'preitem', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id><Name>n2</Name></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_passfield_Break()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'passfield', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_passfield_BreakUnbound()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'passfield', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id><Name>n2</Name></Row><Row><Id>3</Id><Name>n3</Name></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_passfield_Quit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExport(Observer, 'passfield', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;');
        Observer.Expect('xml', '<?decl?><Root><Head>h</Head><Row><Id>1</Id><Name>n1</Name></Row><Row><Id>2</Id></Row></Root>');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): the Export_* tests above trim each line; these read the exported bytes: the blob length and every byte in hex,
    // so the line ends (or their absence) after the declaration are visible.
    local procedure DoExportBytes(var Observer: Codeunit "Probe Observer"; Trig: Text; Action: Integer)
    var
        R: Record "LT AY Flow Row";
        TempBlob: Codeunit "Temp Blob";
        Xp: XmlPort "LT AY Flow Export";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Hex: Text;
        Digits: Text;
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Id := i;
            R.Name := 'n' + Format(i);
            R.Insert();
        end;
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetMode(Trig, Action);
        Xp.SetDestination(OutS);
        Observer.Observe('ok', Format(Xp.Export()));
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('length', Format(TempBlob.Length()));
        Digits := '0123456789ABCDEF';
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Hex += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1);
        end;
        Observer.Observe('hex', Hex);
        Error('FINISHED');
    end;

    [Test]
    procedure Export_pre_Break_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExportBytes(Observer, 'pre', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('length', '54');
        Observer.Expect('hex', '3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D3822207374616E64616C6F6E653D226E6F223F3E');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_pre_BreakUnbound_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExportBytes(Observer, 'pre', 2);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('length', '54');
        Observer.Expect('hex', '3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D3822207374616E64616C6F6E653D226E6F223F3E');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_pre_Quit_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExportBytes(Observer, 'pre', 3);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;');
        Observer.Expect('length', '54');
        Observer.Expect('hex', '3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D3822207374616E64616C6F6E653D226E6F223F3E');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_head_Break_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExportBytes(Observer, 'head', 1);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;post;');
        Observer.Expect('length', '64');
        Observer.Expect('hex', '3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D3822207374616E64616C6F6E653D226E6F223F3E0D0A3C526F6F74202F3E');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;

    [Test]
    procedure Export_NoAction_Bytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror DoExportBytes(Observer, '', 0);
        Observer.Observe('end', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'pre1;head1;preitem1;passfield1;passfield2;passfield3;post;');
        Observer.Expect('length', '257');
        Observer.Expect('hex', '3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554462D3822207374616E64616C6F6E653D226E6F223F3E0D0A3C526F6F743E0D0A20203C486561643E683C2F486561643E0D0A20203C526F773E0D0A202020203C49643E313C2F49643E0D0A202020203C4E616D653E6E313C2F4E616D653E0D0A20203C2F526F773E0D0A20203C526F773E0D0A202020203C49643E323C2F49643E0D0A202020203C4E616D653E6E323C2F4E616D653E0D0A20203C2F526F773E0D0A20203C526F773E0D0A202020203C49643E333C2F49643E0D0A202020203C4E616D653E6E333C2F4E616D653E0D0A20203C2F526F773E0D0A3C2F526F6F743E');
        Observer.Expect('end', 'FINISHED');
        Observer.Verify();
    end;
}
