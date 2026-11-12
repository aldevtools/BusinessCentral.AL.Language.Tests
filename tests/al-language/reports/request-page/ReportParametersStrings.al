// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own reports 76400-76401, codeunits 76402-76403.
// Probe: from al-runner issue 7908 (follow-up to 7590): a parameters string whose root has no name and id, written with other XML
//   declarations or by XmlDocument.WriteTo(Text) (utf-16 declaration, CRLF and two-space indentation).
// Area: the parameters string shapes, each handed to Report.SaveAs (Xml), Report.Execute and Report.RunRequestPage:
//   - one line with encoding="utf-16" standalone="yes"; with encoding="utf-8" standalone="yes"; with <?xml version="1.0"?> (no standalone);
//   - the plain declaration with CRLF and two-space indentation written by hand;
//   - the WriteTo(Text) result of a read template with self-closing Fields for both options after XmlText '2026-01-15' was added to the
//     StartDate Field (its length and whether it holds CR LF too); the same with a named root (name and id attributes).
//   Observed in OnPreReport (SaveAs, Execute) or in the request page handler (RunRequestPage): the two options, or the error.
// Facts: see the Expect lines.
// BC versions: 27 - 29

codeunit 76402 "LT RPS Log"
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

report 76400 "LT RPS Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }

            trigger OnAfterGetRecord()
            begin
                Rows += 1;
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('rows=' + Format(Rows));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(StartCtl; StartDate) { ApplicationArea = All; }
                field(NoteCtl; NoteText) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInitReport()
    begin
        NoteText := 'init';
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre start=[' + Format(StartDate, 0, 9) + '] note=[' + NoteText + ']');
    end;

    var
        StartDate: Date;
        NoteText: Text[30];
        Rows: Integer;
        Log: Codeunit "LT RPS Log";
}

report 76401 "LT RPS Exec Rpt"
{
    UsageCategory = None;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(StartCtl; StartDate) { ApplicationArea = All; }
                field(NoteCtl; NoteText) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInitReport()
    begin
        NoteText := 'init';
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre start=[' + Format(StartDate, 0, 9) + '] note=[' + NoteText + ']');
    end;

    var
        StartDate: Date;
        NoteText: Text[30];
        Log: Codeunit "LT RPS Log";
}

codeunit 76403 "LT RPS Strings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT RPS Log";
        SetStartTxt: Label '<Field name="StartDate">2026-01-15</Field>', Locked = true;
        TemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters><Options><Field name="StartDate" /><Field name="NoteText" /></Options></ReportParameters>', Locked = true;
        NamedTemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RPS Rpt" id="76400"><Options><Field name="StartDate" /><Field name="NoteText" /></Options></ReportParameters>', Locked = true;

    local procedure OneLine(Declaration: Text): Text
    begin
        exit(Declaration + '<ReportParameters><Options>' + SetStartTxt + '</Options></ReportParameters>');
    end;

    local procedure Utf16(): Text
    begin
        exit(OneLine('<?xml version="1.0" encoding="utf-16" standalone="yes"?>'));
    end;

    local procedure Utf8(): Text
    begin
        exit(OneLine('<?xml version="1.0" encoding="utf-8" standalone="yes"?>'));
    end;

    local procedure NoStandalone(): Text
    begin
        exit(OneLine('<?xml version="1.0"?>'));
    end;

    local procedure Indented(): Text
    var
        CrLf: Text[2];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        exit('<?xml version="1.0" standalone="yes"?>' + CrLf + '<ReportParameters>' + CrLf + '  <Options>' + CrLf + '    ' + SetStartTxt + CrLf +
            '  </Options>' + CrLf + '</ReportParameters>');
    end;

    local procedure WrittenFrom(Template: Text): Text
    var
        Doc: XmlDocument;
        Node: XmlNode;
        Xml: Text;
    begin
        XmlDocument.ReadFrom(Template, Doc);
        Doc.SelectSingleNode('ReportParameters/Options/Field[@name="StartDate"]', Node);
        Node.AsXmlElement().Add(XmlText.Create('2026-01-15'));
        Doc.WriteTo(Xml);
        exit(Xml);
    end;

    [TryFunction]
    local procedure TrySaveAs(Parameters: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT RPS Rpt", Parameters, ReportFormat::Xml, OutS);
    end;

    [TryFunction]
    local procedure TryExecute(Parameters: Text)
    begin
        Report.Execute(Report::"LT RPS Exec Rpt", Parameters);
    end;

    [TryFunction]
    local procedure TryRunRequestPage(Parameters: Text; var Returned: Text)
    begin
        Returned := Report.RunRequestPage(Report::"LT RPS Rpt", Parameters);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; Parameters: Text; Mode: Text)
    var
        Ok: Boolean;
        Returned: Text;
    begin
        Log.Take();
        ClearLastError();
        case Mode of
            'saveas':
                Ok := TrySaveAs(Parameters);
            'execute':
                Ok := TryExecute(Parameters);
            'runrequestpage':
                Ok := TryRunRequestPage(Parameters, Returned);
        end;
        Observer.Observe(Name + ' ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
        if Mode = 'runrequestpage' then
            Observer.Observe(Name + ' returned', Returned);
    end;

    local procedure RunOneLine(var Observer: Codeunit "Probe Observer"; Mode: Text)
    begin
        RunCase(Observer, 'utf-16 one line', Utf16(), Mode);
        RunCase(Observer, 'utf-8 one line', Utf8(), Mode);
        RunCase(Observer, 'no standalone', NoStandalone(), Mode);
    end;

    local procedure RunIndented(var Observer: Codeunit "Probe Observer"; Mode: Text)
    begin
        RunCase(Observer, 'indented by hand', Indented(), Mode);
        RunCase(Observer, 'WriteTo bare root', WrittenFrom(TemplateTxt), Mode);
        RunCase(Observer, 'WriteTo named root', WrittenFrom(NamedTemplateTxt), Mode);
    end;

    local procedure RunAll(var Observer: Codeunit "Probe Observer"; Mode: Text)
    begin
        RunOneLine(Observer, Mode);
        RunIndented(Observer, Mode);
    end;

    [Test]
    procedure RPS_XmlDocument_WriteTo_Shape()
    var
        Observer: Codeunit "Probe Observer";
        CrLf: Text[2];
        Xml: Text;
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        Xml := WrittenFrom(TemplateTxt);
        Observer.Observe('bare text', Xml);
        Observer.Observe('bare length', Format(StrLen(Xml)));
        Observer.Observe('bare has CRLF', Format(Xml.Contains(CrLf)));
        Xml := WrittenFrom(NamedTemplateTxt);
        Observer.Observe('named text', Xml);
        Observer.Observe('named length', Format(StrLen(Xml)));
        Observer.Observe('named has CRLF', Format(Xml.Contains(CrLf)));
        Observer.Finish();
    end;

    [Test]
    procedure RPS_SaveAs_DeclarationShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'saveas');
        Observer.Finish();
    end;

    [Test]
    procedure RPS_Execute_DeclarationShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAll(Observer, 'execute');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RPS_RunRequestPage_OneLineDeclarations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOneLine(Observer, 'runrequestpage');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RPS_RunRequestPage_IndentedAndWriteTo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunIndented(Observer, 'runrequestpage');
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT RPS Rpt")
    begin
        Log.Add('handler start=[' + RP.StartCtl.Value() + '] note=[' + RP.NoteCtl.Value() + ']');
        RP.OK().Invoke();
    end;
}
