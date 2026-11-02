// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-requestoptionspage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own reports 94580-94581, test codeunit 94582
// Probe (writer Y86, al-runtime-rs assumption request-page-caption-set): RequestOptionsPage.Caption := Text in the request page's own code,
// in OnInit, OnOpenPage, a control's OnValidate, an action's OnAction, OnAfterGetRecord and a procedure of the request page: what does a
// request page handler read from TestRequestPage.Caption (when it opens, after SetValue, after the action), and what does the code read back.
// BC versions: 27, 28, 29

report 94580 "LT Y86 Caption Report"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Int; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Mode; Mode)
                {
                    ApplicationArea = All;
                    Caption = 'Mode';

                    trigger OnValidate()
                    begin
                        if Mode = 1 then
                            CurrReport.RequestOptionsPage.Caption := 'set in OnValidate';
                        if Mode = 2 then
                            SetByProcedure('set by procedure from OnValidate');
                        ReadBack := CurrReport.RequestOptionsPage.Caption;
                    end;
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(SetCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Set caption';

                    trigger OnAction()
                    begin
                        CurrReport.RequestOptionsPage.Caption := 'set in OnAction';
                        ReadBack := CurrReport.RequestOptionsPage.Caption;
                    end;
                }
            }
        }

        trigger OnInit()
        begin
            InitReadBack := CurrReport.RequestOptionsPage.Caption;
            CurrReport.RequestOptionsPage.Caption := 'set in OnInit';
        end;

        trigger OnOpenPage()
        begin
            OpenReadBack := CurrReport.RequestOptionsPage.Caption;
            if OnOpenCaption <> '' then
                CurrReport.RequestOptionsPage.Caption := OnOpenCaption;
        end;

        local procedure SetByProcedure(NewCaption: Text)
        begin
            CurrReport.RequestOptionsPage.Caption := NewCaption;
        end;
    }

    var
        Mode: Integer;
        ReadBack: Text;
        InitReadBack: Text;
        OpenReadBack: Text;
        OnOpenCaption: Text;

    procedure SetOnOpenCaption(NewCaption: Text)
    begin
        OnOpenCaption := NewCaption;
    end;

    procedure GetReadBack(): Text
    begin
        exit(ReadBack);
    end;

    procedure GetInitReadBack(): Text
    begin
        exit(InitReadBack);
    end;

    procedure GetOpenReadBack(): Text
    begin
        exit(OpenReadBack);
    end;
}

codeunit 94582 "LT Y86 Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Phase: Integer;
        Seen: Text;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_OnInitAndOnOpenPage()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Caption Report";
    begin
        Phase := 0;
        Seen := '';
        Rep.RunModal();
        Obs.Observe('handler_log', Seen);
        Obs.Observe('init_readback', Rep.GetInitReadBack());
        Obs.Observe('open_readback', Rep.GetOpenReadBack());
        Obs.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_OnOpenPageWins()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Caption Report";
    begin
        Phase := 0;
        Seen := '';
        Rep.SetOnOpenCaption('set in OnOpenPage');
        Rep.RunModal();
        Obs.Observe('handler_log', Seen);
        Obs.Observe('open_readback', Rep.GetOpenReadBack());
        Obs.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_OnValidateSets()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Caption Report";
    begin
        Phase := 1;
        Seen := '';
        Rep.RunModal();
        Obs.Observe('handler_log', Seen);
        Obs.Observe('readback', Rep.GetReadBack());
        Obs.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_ProcedureFromOnValidateSets()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Caption Report";
    begin
        Phase := 2;
        Seen := '';
        Rep.RunModal();
        Obs.Observe('handler_log', Seen);
        Obs.Observe('readback', Rep.GetReadBack());
        Obs.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_OnActionSets()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Caption Report";
    begin
        Phase := 3;
        Seen := '';
        Rep.RunModal();
        Obs.Observe('handler_log', Seen);
        Obs.Observe('readback', Rep.GetReadBack());
        Obs.Finish();
    end;

    [Test]
    [HandlerFunctions('CaptionHandler')]
    procedure Y86_Caption_RunRequestPageForm()
    var
        Obs: Codeunit "Probe Observer";
        Params: Text;
    begin
        Phase := 1;
        Seen := '';
        Params := Report.RunRequestPage(Report::"LT Y86 Caption Report");
        Obs.Observe('handler_log', Seen);
        Obs.Observe('params_has_mode', Format(StrPos(Params, 'Mode') > 0));
        Obs.Finish();
    end;

    [RequestPageHandler]
    procedure CaptionHandler(var RP: TestRequestPage "LT Y86 Caption Report")
    begin
        Seen := 'open=' + RP.Caption();
        case Phase of
            1:
                begin
                    RP.Mode.SetValue(1);
                    Seen += ';after_mode1=' + RP.Caption();
                end;
            2:
                begin
                    RP.Mode.SetValue(2);
                    Seen += ';after_mode2=' + RP.Caption();
                end;
            3:
                begin
                    RP.SetCaption.Invoke();
                    Seen += ';after_action=' + RP.Caption();
                end;
        end;
        RP.Cancel().Invoke();
    end;
}
