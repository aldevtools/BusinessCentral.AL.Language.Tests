// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-break-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 70950-70951, xmlport 70952, codeunit 70953
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: currXMLport.Break / BreakUnbound / Quit called in OnAfterGetRecord itself with a statement after it, and via a procedure the trigger calls with a statement after the call; the log shows which statements ran
// BC versions: 29 (27 and 28 by CI)

table 70950 "LT P170 Flow Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70951 "LT P170 Flow Blob"
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

xmlport 70952 "LT P170 Flow Port"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ItemRow; "LT P170 Flow Item")
            {
                XmlName = 'Item';
                fieldelement(Id; ItemRow.Id) { }
                fieldelement(Name; ItemRow.Name) { }

                trigger OnAfterGetRecord()
                begin
                    Hits += 1;
                    LogText += 'row' + Format(Hits) + ';';
                    if Hits = 2 then
                        case Mode of
                            1:
                                begin
                                    currXMLport.Break();
                                    LogText += 'direct-after-break;';
                                end;
                            2:
                                begin
                                    currXMLport.BreakUnbound();
                                    LogText += 'direct-after-breakunbound;';
                                end;
                            3:
                                begin
                                    currXMLport.Quit();
                                    LogText += 'direct-after-quit;';
                                end;
                            4:
                                begin
                                    CallBreak();
                                    LogText += 'trigger-after-break-proc;';
                                end;
                            5:
                                begin
                                    CallBreakUnbound();
                                    LogText += 'trigger-after-breakunbound-proc;';
                                end;
                            6:
                                begin
                                    CallQuit();
                                    LogText += 'trigger-after-quit-proc;';
                                end;
                        end;
                    LogText += 'end' + Format(Hits) + ';';
                end;
            }
        }
    }

    var
        Mode: Integer;
        Hits: Integer;
        LogText: Text;

    trigger OnPreXmlPort()
    begin
        LogText += 'pre;';
    end;

    trigger OnPostXmlPort()
    begin
        LogText += 'post;';
    end;

    local procedure CallBreak()
    begin
        currXMLport.Break();
        LogText += 'proc-after-break;';
    end;

    local procedure CallBreakUnbound()
    begin
        currXMLport.BreakUnbound();
        LogText += 'proc-after-breakunbound;';
    end;

    local procedure CallQuit()
    begin
        currXMLport.Quit();
        LogText += 'proc-after-quit;';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

codeunit 70953 "LT P170 Flow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(Mode: Integer; var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Item: Record "LT P170 Flow Item";
        Row: Record "LT P170 Flow Blob";
        Xp: XmlPort "LT P170 Flow Port";
        OutS: OutStream;
        InS: InStream;
        Big: BigText;
        Xml: Text;
        i: Integer;
        Ok: Boolean;
    begin
        Item.DeleteAll();
        for i := 1 to 3 do begin
            Item.Id := i;
            Item.Name := 'n' + Format(i);
            Item.Insert();
        end;
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        Xp.SetMode(Mode);
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        Xp.SetDestination(OutS);
        Ok := Xp.Export();
        Observer.Observe(Prefix + '_ok', Format(Ok));
        Observer.Observe(Prefix + '_log', Xp.GetLog());
        Row.Modify();
        Row.Get(1);
        Row.CalcFields(Data);
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
        Big.Read(InS);
        if Big.Length() > 0 then
            Big.GetSubText(Xml, 1, Big.Length());
        Observer.Observe(Prefix + '_xml', Xml);
    end;

    [Test]
    procedure P170_Flow_NoCallBaseline()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(0, Observer, 'none');
        Observer.ObserveError('af191');
        Observer.Expect('none_ok', 'Yes');
        Observer.Expect('none_log', 'pre;row1;end1;row2;end2;row3;end3;post;');
        Observer.Expect('af191|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af191|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_BreakInTriggerItself()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(1, Observer, 'break');
        Observer.ObserveError('af201');
        Observer.Expect('break_ok', 'Yes');
        Observer.Expect('break_log', 'pre;row1;end1;row2;post;');
        Observer.Expect('af201|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af201|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_BreakUnboundInTriggerItself()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(2, Observer, 'breakunbound');
        Observer.ObserveError('af211');
        Observer.Expect('breakunbound_ok', 'Yes');
        Observer.Expect('breakunbound_log', 'pre;row1;end1;row2;row3;end3;post;');
        Observer.Expect('af211|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af211|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_QuitInTriggerItself()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(3, Observer, 'quit');
        Observer.ObserveError('af221');
        Observer.Expect('quit_ok', 'Yes');
        Observer.Expect('quit_log', 'pre;row1;end1;row2;');
        Observer.Expect('af221|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af221|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_BreakViaProcedure()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(4, Observer, 'proc_break');
        Observer.ObserveError('af231');
        Observer.Expect('proc_break_ok', 'Yes');
        Observer.Expect('proc_break_log', 'pre;row1;end1;row2;post;');
        Observer.Expect('af231|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af231|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_BreakUnboundViaProcedure()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(5, Observer, 'proc_breakunbound');
        Observer.ObserveError('af241');
        Observer.Expect('proc_breakunbound_ok', 'Yes');
        Observer.Expect('proc_breakunbound_log', 'pre;row1;end1;row2;row3;end3;post;');
        Observer.Expect('af241|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af241|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P170_Flow_QuitViaProcedure()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(6, Observer, 'proc_quit');
        Observer.ObserveError('af251');
        Observer.Expect('proc_quit_ok', 'Yes');
        Observer.Expect('proc_quit_log', 'pre;row1;end1;row2;');
        Observer.Expect('af251|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af251|code', 'InvalidStreamData');
        Observer.Verify();
    end;
}
