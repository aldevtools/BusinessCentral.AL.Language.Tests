// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69110, codeunits 69111 (log), 69112 (subscriber), 69114 (tests), page
//                69113, page extension 69115, report 69116, report extension 69117
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced.
//
// Pins SessionInformation.Callstack read from (see TestSessionInformationCallstackContracts.al for the form): a table event subscriber, a page
// trigger and a page action, the same in a page extension, a report trigger and a data item trigger, a report extension trigger, and a
// procedure with a quoted name. Object kinds read Table, Page, PageExtension, Report, ReportExtension, CodeUnit; an action is
// "<name> - OnAction"(Trigger) and a data item trigger "<item> - OnAfterGetRecord"(Trigger). A database event subscriber (OnAfterInsertEvent) shows
// its own frame and then the caller directly: there is NO frame for the event itself (a publisher codeunit's event does show one).
// A quoted procedure name is written quoted and without extra characters.
// BC versions: 27.5

table 69110 "Probe CSS Table"
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

codeunit 69111 "Probe CSS Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure CutRunner(Stack: Text): Text
    var
        Position: Integer;
    begin
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;

    procedure "Quoted Name Procedure"(): Text
    begin
        exit(CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 69112 "Probe CSS Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"Probe CSS Table", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "Probe CSS Table")
    var
        CssLog: Codeunit "Probe CSS Log";
    begin
        CssLog.Add('table event: ' + CssLog.CutRunner(SessionInformation.Callstack));
    end;
}

page 69113 "Probe CSS Page"
{
    PageType = Card;
    SourceTable = "Probe CSS Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PageAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    CssLog: Codeunit "Probe CSS Log";
                begin
                    CssLog.Add('page action: ' + CssLog.CutRunner(SessionInformation.Callstack));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        CssLog: Codeunit "Probe CSS Log";
    begin
        CssLog.Add('page OnOpenPage: ' + CssLog.CutRunner(SessionInformation.Callstack));
    end;
}

pageextension 69115 "Probe CSS Page Ext" extends "Probe CSS Page"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    CssLog: Codeunit "Probe CSS Log";
                begin
                    CssLog.Add('pageext action: ' + CssLog.CutRunner(SessionInformation.Callstack));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        CssLog: Codeunit "Probe CSS Log";
    begin
        CssLog.Add('pageext OnOpenPage: ' + CssLog.CutRunner(SessionInformation.Callstack));
    end;
}

report 69116 "Probe CSS Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe CSS Table")
        {
            column(Id; Id) { }

            trigger OnAfterGetRecord()
            var
                CssLog: Codeunit "Probe CSS Log";
            begin
                CssLog.Add('report row: ' + CssLog.CutRunner(SessionInformation.Callstack));
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeCssLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    trigger OnPreReport()
    var
        CssLog: Codeunit "Probe CSS Log";
    begin
        CssLog.Add('report OnPreReport: ' + CssLog.CutRunner(SessionInformation.Callstack));
    end;
}

reportextension 69117 "Probe CSS Report Ext" extends "Probe CSS Report"
{
    trigger OnPreReport()
    var
        CssLog: Codeunit "Probe CSS Log";
    begin
        CssLog.Add('reportext OnPreReport: ' + CssLog.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 69114 "Probe Callstack Sources"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Callstack_FromTablePageReportAndExtensionCode()
    var
        CssRec: Record "Probe CSS Table";
        CssLog: Codeunit "Probe CSS Log";
        CssPage: TestPage "Probe CSS Page";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Info: ModuleInfo;
        Suffix: Text;
        Test: Text;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Suffix := ' - ' + Info.Name + ' by ' + Info.Publisher + ' version ' + Format(Info.AppVersion) + '\';
        Test := '"Probe Callstack Sources"(CodeUnit 69114).Callstack_FromTablePageReportAndExtensionCode line ';
        CssRec.DeleteAll();
        Commit();
        CssLog.Take();

        CssRec.Id := 1;
        CssRec.Insert(true);
        CssPage.OpenView();
        CssPage.PageAction.Invoke();
        CssPage.ExtAction.Invoke();
        CssPage.Close();
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Probe CSS Report", '', ReportFormat::Xml, OutStr);
        CssLog.Add('quoted name: ' + CssLog."Quoted Name Procedure"());

        Assert.AreEqual(
            'table event: "Probe CSS Subscriber"(CodeUnit 69112).AfterInsert line 4' + Suffix + Test + '19' + Suffix + '|' +
            'page OnOpenPage: "Probe CSS Page"(Page 69113).OnOpenPage(Trigger) line 4' + Suffix + Test + '20' + Suffix + '|' +
            'pageext OnOpenPage: "Probe CSS Page Ext"(PageExtension 69115).OnOpenPage(Trigger) line 4' + Suffix + Test + '20' + Suffix + '|' +
            'page action: "Probe CSS Page"(Page 69113)."PageAction - OnAction"(Trigger) line 4' + Suffix + Test + '21' + Suffix + '|' +
            'pageext action: "Probe CSS Page Ext"(PageExtension 69115)."ExtAction - OnAction"(Trigger) line 4' + Suffix + Test + '22' + Suffix + '|' +
            'report OnPreReport: "Probe CSS Report"(Report 69116).OnPreReport(Trigger) line 4' + Suffix + Test + '25' + Suffix + '|' +
            'reportext OnPreReport: "Probe CSS Report Ext"(ReportExtension 69117).OnPreReport(Trigger) line 4' + Suffix + Test + '25' + Suffix + '|' +
            'report row: "Probe CSS Report"(Report 69116)."Row - OnAfterGetRecord"(Trigger) line 4' + Suffix + Test + '25' + Suffix + '|' +
            'quoted name: "Probe CSS Log"(CodeUnit 69111)."Quoted Name Procedure" line 2' + Suffix + Test + '26' + Suffix + '|',
            CssLog.Take(), 'log');
    end;
}
