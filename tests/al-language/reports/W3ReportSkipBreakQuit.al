//sub:report
// CurrReport.Skip, Break and Quit outside the places the runtime implements (md:200): in OnPreDataItem, OnPostDataItem, OnPreReport, OnPostReport and in a
// procedure called from OnAfterGetRecord. The mode is set through a single instance codeunit.

codeunit 67720 "W3 Flow State"
{
    SingleInstance = true;

    var
        Entries: Text;
        ModeValue: Text;

    procedure SetMode(NewMode: Text)
    begin
        ModeValue := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(ModeValue);
    end;

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

report 67721 "W3 Flow Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            trigger OnPreDataItem()
            begin
                State.Add('pre');
                case State.Mode() of
                    'skip-pre':
                        CurrReport.Skip();
                    'break-pre':
                        CurrReport.Break();
                    'quit-pre':
                        CurrReport.Quit();
                end;
            end;

            trigger OnAfterGetRecord()
            begin
                State.Add('row ' + Format(Row.Id));
                if Row.Id = 2 then
                    case State.Mode() of
                        'skip-row-proc':
                            DoSkip();
                        'break-row-proc':
                            DoBreak();
                        'quit-row-proc':
                            DoQuit();
                    end;
            end;

            trigger OnPostDataItem()
            begin
                State.Add('post');
                case State.Mode() of
                    'skip-post':
                        CurrReport.Skip();
                    'break-post':
                        CurrReport.Break();
                    'quit-post':
                        CurrReport.Quit();
                end;
            end;
        }
        dataitem(Later; "W3 Marker")
        {
            trigger OnPreDataItem()
            begin
                State.Add('later pre');
            end;
        }
    }

    var
        State: Codeunit "W3 Flow State";

    local procedure DoSkip()
    begin
        CurrReport.Skip();
    end;

    local procedure DoBreak()
    begin
        CurrReport.Break();
    end;

    local procedure DoQuit()
    begin
        CurrReport.Quit();
    end;

    trigger OnPreReport()
    begin
        State.Add('prereport');
        case State.Mode() of
            'skip-prereport':
                CurrReport.Skip();
            'break-prereport':
                CurrReport.Break();
            'quit-prereport':
                CurrReport.Quit();
        end;
    end;

    trigger OnPostReport()
    begin
        State.Add('postreport');
        case State.Mode() of
            'skip-postreport':
                CurrReport.Skip();
            'break-postreport':
                CurrReport.Break();
            'quit-postreport':
                CurrReport.Quit();
        end;
    end;
}

codeunit 67722 "W3 Flow Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        State: Codeunit "W3 Flow State";
        Runner: Codeunit "W3 Runner";

    local procedure Probe(Mode: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "W3 Row";
        Marker: Record "W3 Marker";
        Result: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Marker.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Marker.Id := 1;
        Marker.Insert();
        Commit();
        State.SetMode(Mode);
        State.Take();
        Ok := Runner.Exec(Report::"W3 Flow Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', State.Take());
        State.SetMode('');
    end;

    [Test]
    procedure Control_NoMode_FullRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InOnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('skip-pre', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InOnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('break-pre', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InOnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('quit-pre', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InOnPostDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('skip-post', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InOnPostDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('break-post', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InOnPostDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('quit-post', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InProcedureCalledFromOnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('skip-row-proc', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InProcedureCalledFromOnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('break-row-proc', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InProcedureCalledFromOnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('quit-row-proc', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('skip-prereport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('break-prereport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('quit-prereport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;');
        Observer.Verify();
    end;

    [Test]
    procedure Skip_InOnPostReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('skip-postreport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Break_InOnPostReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('break-postreport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;

    [Test]
    procedure Quit_InOnPostReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe('quit-postreport', Observer);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'prereport;pre;row 1;row 2;row 3;post;later pre;postreport;');
        Observer.Verify();
    end;
}
