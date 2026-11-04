// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-drilldownpageid-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 81660 and 81661, pages 81662 and 81663, report 81664, log codeunit 81665, test codeunit 81666
// Probe: corpus issue 601 item 8. DrillDownPageID on a request page field: which page a TestRequestPage drill-down opens for a FlowField control
//   with DrillDownPageId (page property) and without it (the DrillDownPageID of the FlowField's source table), the rows that page shows,
//   and a drill-down on a request page control over a plain variable that has DrillDownPageId.
// Facts (CI, 28.5 and 29.0): TestRequestPage Drilldown on a control with DrillDownPageId returns without an error and opens no page (no page
//   handler is listed, so an opened page would fail the test); on a FlowField control without it, Drilldown raises
//   'The NavDrilldownAction method is not supported.' (MethodNotSupported). The page handlers below are kept unlisted, as probe source.
// BC versions: 27, 28, 29

table 81660 "LT BJ Dd Line"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "LT BJ Dd Lines B";
    LookupPageId = "LT BJ Dd Lines B";

    fields
    {
        field(1; "Head Code"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Integer) { }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

table 81661 "LT BJ Dd Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BJ Dd Line" where("Head Code" = field(Code)));
            Editable = false;
        }
        field(3; "Line Sum"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT BJ Dd Line".Amount where("Head Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 81662 "LT BJ Dd Lines A"
{
    PageType = List;
    SourceTable = "LT BJ Dd Line";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCode; Rec."Head Code") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 81663 "LT BJ Dd Lines B"
{
    PageType = List;
    SourceTable = "LT BJ Dd Line";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCode; Rec."Head Code") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

report 81664 "LT BJ Dd Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(HeadItem; "LT BJ Dd Head")
        {
            trigger OnAfterGetRecord()
            begin
                DdLog.Add('report ran ' + HeadItem.Code);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(DdOverride; Head."Line Count")
                {
                    ApplicationArea = All;
                    Caption = 'Count with DrillDownPageId';
                    DrillDownPageId = "LT BJ Dd Lines A";
                }
                field(DdDefault; Head."Line Sum")
                {
                    ApplicationArea = All;
                    Caption = 'Sum without DrillDownPageId';
                }
                field(DdVar; PlainValue)
                {
                    ApplicationArea = All;
                    Caption = 'Plain variable with DrillDownPageId';
                    DrillDownPageId = "LT BJ Dd Lines A";
                }
            }
        }

        trigger OnOpenPage()
        begin
            Head.Get('H1');
            Head.CalcFields("Line Count", "Line Sum");
            PlainValue := 7;
        end;
    }

    var
        Head: Record "LT BJ Dd Head";
        DdLog: Codeunit "LT BJ Dd Log";
        PlainValue: Integer;
}

codeunit 81665 "LT BJ Dd Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 81666 "LT BJ Dd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        DdLog: Codeunit "LT BJ Dd Log";
        Which: Text;

    local procedure Seed()
    var
        Head: Record "LT BJ Dd Head";
        Line: Record "LT BJ Dd Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Code := 'H1';
        Head.Insert();
        Head.Code := 'H2';
        Head.Insert();
        Line."Head Code" := 'H1';
        Line."Line No." := 1;
        Line.Amount := 5;
        Line.Insert();
        Line."Line No." := 2;
        Line.Amount := 6;
        Line.Insert();
        Line."Head Code" := 'H2';
        Line."Line No." := 1;
        Line.Amount := 100;
        Line.Insert();
        Commit();
        DdLog.Take();
    end;

    [Test]
    [HandlerFunctions('DrillRequestHandler')]
    procedure RequestPage_DrillDownPageId()
    begin
        Seed();
        Report.Run(Report::"LT BJ Dd Report", true, false);
        Observer.Observe('log after run', DdLog.Take());
        Observer.Expect('override value', '2');
        Observer.Expect('default value', '11');
        Observer.Expect('override drilldown|text', 'NOERROR');
        Observer.Expect('override drilldown|code', 'Dialog');
        Observer.Expect('override opened', '');
        Observer.Expect('default drilldown|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('default drilldown|code', 'MethodNotSupported');
        Observer.Expect('default opened', '');
        Observer.Expect('plain variable drilldown|text', 'NOERROR');
        Observer.Expect('plain variable drilldown|code', 'Dialog');
        Observer.Expect('plain variable opened', '');
        Observer.Expect('log after run', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure DrillRequestHandler(var Req: TestRequestPage "LT BJ Dd Report")
    begin
        Observer.Observe('override value', Req.DdOverride.Value);
        Observer.Observe('default value', Req.DdDefault.Value);
        Which := '';
        asserterror begin
            Req.DdOverride.Drilldown();
            Error('NOERROR');
        end;
        Observer.ObserveError('override drilldown');
        Observer.Observe('override opened', Which);
        Which := '';
        asserterror begin
            Req.DdDefault.Drilldown();
            Error('NOERROR');
        end;
        Observer.ObserveError('default drilldown');
        Observer.Observe('default opened', Which);
        Which := '';
        asserterror begin
            Req.DdVar.Drilldown();
            Error('NOERROR');
        end;
        Observer.ObserveError('plain variable drilldown');
        Observer.Observe('plain variable opened', Which);
        Req.Cancel().Invoke();
    end;

    local procedure Rows(Kind: Text; var P: TestPage "LT BJ Dd Lines A")
    begin
        Which += Kind + ' rows=';
        if P.First() then
            repeat
                Which += P.HeadCode.Value + '/' + P.LineNo.Value + ',';
            until not P.Next();
        Which += ';';
    end;

    local procedure RowsB(Kind: Text; var P: TestPage "LT BJ Dd Lines B")
    begin
        Which += Kind + ' rows=';
        if P.First() then
            repeat
                Which += P.HeadCode.Value + '/' + P.LineNo.Value + ',';
            until not P.Next();
        Which += ';';
    end;

    [PageHandler]
    procedure ListAHandler(var P: TestPage "LT BJ Dd Lines A")
    begin
        Rows('A page', P);
    end;

    [PageHandler]
    procedure ListBHandler(var P: TestPage "LT BJ Dd Lines B")
    begin
        RowsB('B page', P);
    end;

    [ModalPageHandler]
    procedure ListAModal(var P: TestPage "LT BJ Dd Lines A")
    begin
        Rows('A modal', P);
    end;

    [ModalPageHandler]
    procedure ListBModal(var P: TestPage "LT BJ Dd Lines B")
    begin
        RowsB('B modal', P);
    end;

    // Writer PX (al-runtime-rs probes-needed "TestRequestPage.DrillDown"): DrillDown = false on request page controls (report 86223 in
    // PxRequestDrillDownOff.al): the error of Drilldown() and whether the OnDrillDown trigger runs.
    [Test]
    [HandlerFunctions('PxDdOffHandler')]
    procedure PX_RequestPage_DrillDownFalse()
    begin
        Seed();
        Report.Run(Report::"LT PX Dd Off Report", true, false);
        Observer.Observe('log after run', DdLog.Take());
        Observer.Expect('off plain|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('off plain|code', 'MethodNotSupported');
        Observer.Expect('off plain log', '');
        Observer.Expect('off trigger|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('off trigger|code', 'MethodNotSupported');
        Observer.Expect('off trigger log', '');
        Observer.Expect('on trigger|text', 'NOERROR');
        Observer.Expect('on trigger|code', 'Dialog');
        Observer.Expect('on trigger log', 'on trigger ran;');
        Observer.Expect('off flowfield|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('off flowfield|code', 'MethodNotSupported');
        Observer.Expect('off flowfield log', '');
        Observer.Expect('off pageid|text', 'The NavDrilldownAction method is not supported.');
        Observer.Expect('off pageid|code', 'MethodNotSupported');
        Observer.Expect('off pageid log', '');
        Observer.Expect('value after', '7');
        Observer.Expect('log after run', '');
        Observer.Verify();
    end;

    local procedure PxTryDrill(var Req: TestRequestPage "LT PX Dd Off Report"; Ctl: Integer; Name: Text)
    begin
        DdLog.Take();
        asserterror begin
            case Ctl of
                1:
                    Req.OffPlain.Drilldown();
                2:
                    Req.OffTrigger.Drilldown();
                3:
                    Req.OnTrigger.Drilldown();
                4:
                    Req.OffFlow.Drilldown();
                5:
                    Req.OffPageId.Drilldown();
            end;
            Error('NOERROR');
        end;
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', DdLog.Take());
    end;

    [RequestPageHandler]
    procedure PxDdOffHandler(var Req: TestRequestPage "LT PX Dd Off Report")
    begin
        PxTryDrill(Req, 1, 'off plain');
        PxTryDrill(Req, 2, 'off trigger');
        PxTryDrill(Req, 3, 'on trigger');
        PxTryDrill(Req, 4, 'off flowfield');
        PxTryDrill(Req, 5, 'off pageid');
        Observer.Observe('value after', Req.OffPlain.Value);
        Req.Cancel().Invoke();
    end;
}
