// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-request-pages
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (System Application); SingleInstance log 92727 is used only by test codeunit 92731
// Writer Y40 (2026-10-31): an xmlport whose request page has content (a field bound to a global of the xmlport, OnOpenPage and
// OnQueryClosePage triggers), the shape of the e-document xmlports Microsoft's tests export from code. Export and Import from code
// (static and instance, does the page open, what the global holds), Xmlport.Run with and without the request window and the
// instance Run (no handler can take an xmlport request page: TestRequestPage takes a report only, must-not-compile case 2513).
// Empty request page sections are xmlport/lt-ra-xmlport/RaXmlPortExport.al and platform/lt-ag-contoso/AgXmlPortImport.al.
// BC (CI 27.5/28.5/29.0, same values): Export and Import from code (instance and static) never open the request page and run with
//   the globals as code set them. Xmlport.Run(Id, false, false) runs without the page. Xmlport.Run(Id, true, false) and the instance
//   Run() open the page: OnInitXmlPort runs, then 'Unhandled UI: RequestPage 92728' (MissingUIHandler), also outside a TryFunction.
// BC versions: 27 - 29
table 92726 "LT Y40 XRP Row"
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

codeunit 92727 "LT Y40 XRP Log"
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

xmlport 92728 "LT Y40 XRP Export"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y40 XRP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }

                trigger OnPreXmlItem()
                begin
                    if OnlyId <> 0 then
                        Row.SetRange(Id, OnlyId);
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('row ' + Format(Row.Id));
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    ShowCaption = false;
                    field(OnlyIdCtl; OnlyId)
                    {
                        Caption = 'Only Id';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Log.Add('rp-open only=' + Format(OnlyId));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('rp-close ' + Format(CloseAction) + ' only=' + Format(OnlyId));
            exit(true);
        end;
    }

    trigger OnInitXmlPort()
    begin
        Log.Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        Log.Add('pre only=' + Format(OnlyId));
    end;

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y40 XRP Log";
        OnlyId: Integer;

    procedure SetOnlyId(NewOnlyId: Integer)
    begin
        OnlyId := NewOnlyId;
    end;

    procedure GetOnlyId(): Integer
    begin
        exit(OnlyId);
    end;
}

xmlport 92729 "LT Y40 XRP Import"
{
    Direction = Import;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y40 XRP Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { MinOccurs = Zero; }

                trigger OnBeforeInsertRecord()
                begin
                    if Row.Name = '' then
                        Row.Name := DefaultName;
                    Log.Add('insert ' + Format(Row.Id) + ' ' + Row.Name);
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(DefaultNameCtl; DefaultName)
                {
                    Caption = 'Default Name';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;
    }

    trigger OnPreXmlPort()
    begin
        Log.Add('pre default=' + DefaultName);
    end;

    var
        Log: Codeunit "LT Y40 XRP Log";
        DefaultName: Text[30];

    procedure SetDefaultName(NewName: Text[30])
    begin
        DefaultName := NewName;
    end;
}

codeunit 92731 "LT Y40 XRP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y40 XRP Log";

    local procedure Seed()
    var
        R: Record "LT Y40 XRP Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 3 do begin
            R.Id := I;
            R.Name := 'n' + Format(I);
            R.Insert();
        end;
        Log.Take();
    end;

    local procedure Rows(): Text
    var
        R: Record "LT Y40 XRP Row";
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + '=' + R.Name + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line;
        end;
        // The export is UTF-16 with a byte order mark; read as text, the mark comes out as stray characters. Kept: whether the
        // declaration names UTF-16, and the text from <Root> on (line breaks dropped by ReadText).
        exit('decl=' + Format(StrPos(Result, '<?xml version="1.0" encoding="UTF-16" standalone="no"?>') > 0) + ' ' + CopyStr(Result, StrPos(Result, '<Root>')));
    end;

    [TryFunction]
    local procedure TryExportInstance(OnlyId: Integer; var Xml: Text)
    var
        Xp: XmlPort "LT Y40 XRP Export";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xp.SetOnlyId(OnlyId);
        Xp.SetDestination(OutS);
        Xp.Export();
        Xml := ReadAll(TempBlob);
    end;

    [TryFunction]
    local procedure TryExportStatic(var Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y40 XRP Export", OutS);
        Xml := ReadAll(TempBlob);
    end;

    local procedure Outcome(Ok: Boolean; Xml: Text): Text
    begin
        if Ok then
            exit('ok ' + Xml);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y40_Export_FromCode_Instance()
    var
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('only2', Outcome(TryExportInstance(2, Xml), Xml));
        Observer.Observe('only2_log', Log.Take());
        Xml := '';
        Observer.Observe('all', Outcome(TryExportInstance(0, Xml), Xml));
        Observer.Observe('all_log', Log.Take());
        Observer.Expect('only2', 'ok decl=Yes <Root>  <Row>    <Id>2</Id>    <Name>n2</Name>  </Row></Root>');
        Observer.Expect('only2_log', 'init;pre only=2;row 2;post;');
        Observer.Expect('all', 'ok decl=Yes <Root>  <Row>    <Id>1</Id>    <Name>n1</Name>  </Row>  <Row>    <Id>2</Id>    <Name>n2</Name>  </Row>  <Row>    <Id>3</Id>    <Name>n3</Name>  </Row></Root>');
        Observer.Expect('all_log', 'init;pre only=0;row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Export_FromCode_Static()
    var
        Xml: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('static', Outcome(TryExportStatic(Xml), Xml));
        Observer.Observe('log', Log.Take());
        Observer.Expect('static', 'ok decl=Yes <Root>  <Row>    <Id>1</Id>    <Name>n1</Name>  </Row>  <Row>    <Id>2</Id>    <Name>n2</Name>  </Row>  <Row>    <Id>3</Id>    <Name>n3</Name>  </Row></Root>');
        Observer.Expect('log', 'init;pre only=0;row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImport(Instance: Boolean; Source: Text)
    var
        Xp: XmlPort "LT Y40 XRP Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Source);
        TempBlob.CreateInStream(InS);
        if Instance then begin
            Xp.SetDefaultName('dflt');
            Xp.SetSource(InS);
            Xp.Import();
        end else
            Xmlport.Import(Xmlport::"LT Y40 XRP Import", InS);
    end;

    [Test]
    procedure Y40_Import_FromCode()
    var
        R: Record "LT Y40 XRP Row";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Log.Take();
        ClearLastError();
        Observer.Observe('instance', Outcome(TryImport(true, '<Root><Row><Id>7</Id></Row><Row><Id>8</Id><Name>given</Name></Row></Root>'), ''));
        Observer.Observe('instance_log', Log.Take());
        Observer.Observe('instance_rows', Rows());
        R.DeleteAll();
        Observer.Observe('static', Outcome(TryImport(false, '<Root><Row><Id>9</Id></Row></Root>'), ''));
        Observer.Observe('static_log', Log.Take());
        Observer.Observe('static_rows', Rows());
        Observer.Expect('instance', 'ok ');
        Observer.Expect('instance_log', 'pre default=dflt;insert 7 dflt;insert 8 given;');
        Observer.Expect('instance_rows', '7=dflt,8=given,');
        Observer.Expect('static', 'ok ');
        Observer.Expect('static_log', 'pre default=;insert 9 ;');
        Observer.Expect('static_rows', '9=,');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunStatic(RequestWindow: Boolean)
    begin
        Xmlport.Run(Xmlport::"LT Y40 XRP Export", RequestWindow, false);
    end;

    [TryFunction]
    local procedure TryRunInstance(OnlyId: Integer)
    var
        Xp: XmlPort "LT Y40 XRP Export";
    begin
        Xp.SetOnlyId(OnlyId);
        Xp.Run();
    end;

    // The runs below write nothing before they start (the rows come from Seed of the earlier tests): a run with a request page after
    // an uncommitted write may end in an error before the page opens (as for reports, Y36BareReportMember.al). A RequestPageHandler
    // cannot be typed on an xmlport (TestRequestPage takes a report only: must-not-compile case 2513), so the runs with the request
    // window have no handler to take the page.
    [Test]
    procedure Y40_Run_Static_NoRequestWindow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        Observer.Observe('run', Outcome(TryRunStatic(false), ''));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run', 'ok ');
        Observer.Expect('log', 'init;pre only=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Run_Static_RequestWindow_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        Observer.Observe('run', Outcome(TryRunStatic(true), ''));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run', 'error:Unhandled UI: RequestPage 92728|MissingUIHandler');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Run_Instance_DefaultRequestPage_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        Observer.Observe('run', Outcome(TryRunInstance(1), ''));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run', 'error:Unhandled UI: RequestPage 92728|MissingUIHandler');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Run_Static_RequestWindow_NotInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        asserterror Xmlport.Run(Xmlport::"LT Y40 XRP Export", true, false);
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('log', Log.Take());
        Observer.Expect('error', 'Unhandled UI: RequestPage 92728|MissingUIHandler');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;
}
