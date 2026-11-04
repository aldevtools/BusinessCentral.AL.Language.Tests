// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); the objects of ChReportFixtures.al and ChReportPart.al (84530 to 84544); test codeunit 84549
// Probe: written against BC on the corpus test loop and CI; every literal asserted below is what the tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts (corpus issue 667, by procedure prefix):
//   Part (item 117): RequestOptionsPage.<Part>.Page.<Procedure>() from the request page OnOpenPage and from OnPreReport.
//   CloseError (item 118): an Error in the request page OnClosePage of a ProcessingOnly report run with Run and RunModal: whether the caller gets it, and which report triggers ran.
//   SaveValues (item 119): SaveValues = true on the base request page; the fields a report extension adds, on the second run of the request page.
//   FilterFields (item 120): RequestFilterFields that a report extension sets on a base data item: which fields a TestRequestPage can filter, and the filters the run gets.
//   Enabled (item 122): Enabled of request page fields bound to report globals set in OnInitReport and in OnOpenPage, as a TestRequestPage sees it.
//   Order (item 123): report, data item and OnPreRendering triggers of a report and its extension under SaveAs Xml; CurrReport.Quit in OnPreReport and OnPreDataItem.
//   Params (items 124 and 125): which request page triggers and OnValidate run for Run (visible), RunRequestPage and Execute with parameters (head-less), and whether
//     an OnOpenPage (base and extension) that assigns the option globals overwrites the values of the parameters.
//   Lost (item 126): SaveValues = true and an OnOpenPage that sets a Boolean option: the value OnPreReport and OnPreDataItem see, and the value the next run shows.
// BC versions: 27, 28, 29 by CI

codeunit 84549 "LT CH Report Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT CH R Log";
        HandlerMode: Integer;

    local procedure Init(NewMode: Integer)
    var
        R: Record "LT CH R Row";
    begin
        R.DeleteAll();
        R.Id := 1; R.Name := 'a'; R.Grp := 'X'; R.Insert();
        R.Id := 2; R.Name := 'b'; R.Grp := 'Y'; R.Insert();
        R.Id := 3; R.Name := 'c'; R.Grp := 'X'; R.Insert();
        Commit();
        Log.Take();
        Log.SetMode(NewMode);
        HandlerMode := 0;
    end;

    local procedure Outcome(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, GetLastErrorText());
            Obs.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    // ---------------------------------------------------------------- Part (item 117)

    [Test]
    [HandlerFunctions('PartHandler')]
    procedure Part_ProcedureOfThePartPage()
    begin
        Init(0);
        Report.Run(Report::"LT CH RP Part Host");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnOpenPage part ping count=3;handler;');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure PartHandler(var RP: TestRequestPage "LT CH RP Part Host")
    begin
        Log.Add('handler');
        RP.OK().Invoke();
    end;

    // ---------------------------------------------------------------- CloseError (item 118)

    [Test]
    [HandlerFunctions('CloseErrorHandler')]
    procedure CloseError_RunModal_Ok()
    begin
        Init(0);
        asserterror Report.RunModal(Report::"LT CH RP CloseError");
        Obs.ObserveError('runmodal');
        Obs.Observe('log', Log.Take());
        Obs.Expect('runmodal|text', 'One or more errors occurred while closing the page.\n\nLT CH close error');
        Obs.Expect('runmodal|code', 'TestWrapped');
        Obs.Expect('log', 'OnInitReport;handler;OnClosePage;');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseErrorHandler')]
    procedure CloseError_Run_Ok()
    begin
        Init(0);
        asserterror Report.Run(Report::"LT CH RP CloseError");
        Obs.ObserveError('run');
        Obs.Observe('log', Log.Take());
        Obs.Expect('run|text', 'One or more errors occurred while closing the page.\n\nLT CH close error');
        Obs.Expect('run|code', 'TestWrapped');
        Obs.Expect('log', 'OnInitReport;handler;OnClosePage;');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseErrorHandler')]
    procedure CloseError_RunModal_Cancel()
    begin
        Init(0);
        HandlerMode := 1;
        asserterror Report.RunModal(Report::"LT CH RP CloseError");
        Obs.ObserveError('runmodal');
        Obs.Observe('log', Log.Take());
        Obs.Expect('runmodal|text', 'One or more errors occurred while closing the page.\n\nLT CH close error');
        Obs.Expect('runmodal|code', 'TestWrapped');
        Obs.Expect('log', 'OnInitReport;handler;OnClosePage;');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure CloseErrorHandler(var RP: TestRequestPage "LT CH RP CloseError")
    begin
        Log.Add('handler');
        if HandlerMode = 1 then
            RP.Cancel().Invoke()
        else
            RP.OK().Invoke();
        Log.Add('handler after close');
    end;

    // ---------------------------------------------------------------- SaveValues (item 119)

    [Test]
    [HandlerFunctions('SaveValuesHandler')]
    procedure SaveValues_ExtensionFields_SecondRun()
    begin
        Init(0);
        // A first run stores known values, so the observed runs do not depend on what earlier runs stored.
        HandlerMode := 3;
        Report.RunModal(Report::"LT CH SaveValues");
        Log.Take();
        HandlerMode := 1;
        Report.RunModal(Report::"LT CH SaveValues");
        HandlerMode := 2;
        Report.RunModal(Report::"LT CH SaveValues");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'shown int=0 bool=No text=;base OnPreReport int=5;ext OnPreReport bool=Yes text=hello;shown int=5 bool=Yes text=hello;base OnPreReport int=5;ext OnPreReport bool=Yes text=hello;');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure SaveValuesHandler(var RP: TestRequestPage "LT CH SaveValues")
    begin
        if HandlerMode = 3 then begin
            RP.BaseInt.SetValue(0);
            RP.ExtBool.SetValue(false);
            RP.ExtText.SetValue('');
            RP.OK().Invoke();
            exit;
        end;
        Log.Add('shown int=' + RP.BaseInt.Value() + ' bool=' + RP.ExtBool.Value() + ' text=' + RP.ExtText.Value());
        if HandlerMode = 1 then begin
            RP.BaseInt.SetValue(5);
            RP.ExtBool.SetValue(true);
            RP.ExtText.SetValue('hello');
        end;
        RP.OK().Invoke();
    end;

    // ---------------------------------------------------------------- FilterFields (item 120)

    [TryFunction]
    local procedure TryFilterId(var RP: TestRequestPage "LT CH Filter Fields")
    begin
        RP.Items.SetFilter(Id, '1..2');
    end;

    [TryFunction]
    local procedure TryFilterName(var RP: TestRequestPage "LT CH Filter Fields")
    begin
        RP.Items.SetFilter(Name, 'b');
    end;

    [TryFunction]
    local procedure TryFilterGrp(var RP: TestRequestPage "LT CH Filter Fields")
    begin
        RP.Items.SetFilter(Grp, 'Y');
    end;

    local procedure FilterStep(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Log.Add(Name + ' ok')
        else begin
            Log.Add(Name + ' error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    [HandlerFunctions('FilterFieldsHandler')]
    procedure FilterFields_ExtensionSetsRequestFilterFields()
    begin
        Init(0);
        Report.RunModal(Report::"LT CH Filter Fields");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'filter Id ok;filter Name ok;filter Grp ok;filters=[Id: 1..2, Name: b, Grp: Y];');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure FilterFieldsHandler(var RP: TestRequestPage "LT CH Filter Fields")
    begin
        FilterStep('filter Id', TryFilterId(RP));
        FilterStep('filter Name', TryFilterName(RP));
        FilterStep('filter Grp', TryFilterGrp(RP));
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FilterFieldsParamsHandler')]
    procedure FilterFields_RunRequestPageParameters()
    var
        Params: Text;
    begin
        Init(0);
        Params := Report.RunRequestPage(Report::"LT CH Filter Fields");
        Obs.Observe('dataitems', Between(Params, '<DataItems>', '</DataItems>'));
        Obs.Observe('log', Log.Take());
        Obs.Expect('dataitems', '<DataItem name="Items">VERSION(1) SORTING(Field1)</DataItem>');
        Obs.Expect('log', '');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure FilterFieldsParamsHandler(var RP: TestRequestPage "LT CH Filter Fields")
    begin
        RP.OK().Invoke();
    end;

    local procedure Between(Value: Text; StartTag: Text; EndTag: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := Value.IndexOf(StartTag);
        EndPos := Value.IndexOf(EndTag);
        if (StartPos = 0) or (EndPos = 0) then
            exit('<not found> length=' + Format(StrLen(Value)));
        exit(CopyStr(Value, StartPos + StrLen(StartTag), EndPos - StartPos - StrLen(StartTag)));
    end;

    // ---------------------------------------------------------------- Enabled (item 122)

    [Test]
    [HandlerFunctions('EnabledHandler')]
    procedure Enabled_BoundToGlobals_False()
    begin
        Init(0);
        Report.RunModal(Report::"LT CH RP Enabled");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnOpenPage openEnabled=No initEnabled=No;open enabled=No visible=Yes editable=Yes;init enabled=No visible=Yes editable=Yes;plain enabled=Yes;');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('EnabledHandler')]
    procedure Enabled_BoundToGlobals_True()
    begin
        Init(1);
        Report.RunModal(Report::"LT CH RP Enabled");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnOpenPage openEnabled=Yes initEnabled=Yes;open enabled=Yes visible=Yes editable=Yes;init enabled=Yes visible=Yes editable=Yes;plain enabled=Yes;');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure EnabledHandler(var RP: TestRequestPage "LT CH RP Enabled")
    begin
        Log.Add('open enabled=' + Format(RP.OpenBound.Enabled()) + ' visible=' + Format(RP.OpenBound.Visible()) + ' editable=' + Format(RP.OpenBound.Editable()));
        Log.Add('init enabled=' + Format(RP.InitBound.Enabled()) + ' visible=' + Format(RP.InitBound.Visible()) + ' editable=' + Format(RP.InitBound.Editable()));
        Log.Add('plain enabled=' + Format(RP.Plain.Enabled()));
        RP.OK().Invoke();
    end;

    // ---------------------------------------------------------------- Order (item 123)

    [TryFunction]
    local procedure TrySaveXml(var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT CH Order", '', ReportFormat::Xml, OutS);
    end;

    local procedure OrderRun(NewMode: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        Init(NewMode);
        Outcome('saveas', TrySaveXml(TempBlob));
        Obs.Observe('has output', Format(TempBlob.Length() > 0));
        Obs.Observe('log', Log.Take());
    end;

    [Test]
    procedure Order_SaveAsXml_BaseAndExtension()
    begin
        OrderRun(0);
        Obs.Expect('saveas', 'ok');
        Obs.Expect('has output', 'Yes');
        Obs.Expect('log', 'base OnInitReport;base OnPreReport;ext OnPreReport;ext OnBeforePreDataItem;base OnPreDataItem;ext OnAfterPreDataItem;ext OnBeforeAfterGetRecord 1;base OnAfterGetRecord 1;ext OnAfterAfterGetRecord 1;ext OnBeforeAfterGetRecord 2;base OnAfterGetRecord 2;ext OnAfterAfterGetRecord 2;ext OnBeforePostDataItem;base OnPostDataItem;ext OnAfterPostDataItem;base OnPreRendering;ext OnPreRendering;base OnPostReport;ext OnPostReport;');
        Obs.Verify();
    end;

    [Test]
    procedure Order_SaveAsXml_QuitInOnPreReport()
    begin
        OrderRun(1);
        Obs.Expect('saveas', 'ok');
        Obs.Expect('has output', 'No');
        Obs.Expect('log', 'base OnInitReport;base OnPreReport;');
        Obs.Verify();
    end;

    [Test]
    procedure Order_SaveAsXml_QuitInOnPreDataItem()
    begin
        OrderRun(2);
        Obs.Expect('saveas', 'ok');
        Obs.Expect('has output', 'No');
        Obs.Expect('log', 'base OnInitReport;base OnPreReport;ext OnPreReport;ext OnBeforePreDataItem;base OnPreDataItem;');
        Obs.Verify();
    end;

    // ---------------------------------------------------------------- Params (items 124 and 125)

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Params_Run_Visible()
    begin
        Init(0);
        HandlerMode := 1;
        Report.RunModal(Report::"LT CH Params");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=0;ext OnOpenPage ext=0;handler shows opt=0 ext=0;Opt OnValidate 5;ExtOpt OnValidate 6;handler set;RP OnQueryClosePage OK;RP OnClosePage opt=5;handler after OK;OnPreReport opt=5;ext OnPreReport ext=6;OnPreDataItem opt=5;');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Params_Run_Visible_OnOpenPageAssigns()
    begin
        Init(1);
        HandlerMode := 2;
        Report.RunModal(Report::"LT CH Params");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=0;ext OnOpenPage ext=0;handler shows opt=99 ext=77;Opt OnValidate 5;ExtOpt OnValidate 6;handler set;RP OnQueryClosePage OK;RP OnClosePage opt=5;handler after OK;OnPreReport opt=5;ext OnPreReport ext=6;OnPreDataItem opt=5;');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Params_RunRequestPage_ThenExecute()
    var
        Params: Text;
    begin
        Init(0);
        HandlerMode := 1;
        Params := Report.RunRequestPage(Report::"LT CH Params");
        Obs.Observe('page log', Log.Take());
        Obs.Observe('options', Between(Params, '<Options>', '</Options>'));
        Outcome('execute', TryExecute(Params));
        Obs.Observe('execute log', Log.Take());
        Log.SetMode(1);
        Outcome('execute assigning', TryExecute(Params));
        Obs.Observe('execute assigning log', Log.Take());
        Obs.Expect('page log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=0;ext OnOpenPage ext=0;handler shows opt=0 ext=0;Opt OnValidate 5;ExtOpt OnValidate 6;handler set;RP OnQueryClosePage OK;RP OnClosePage opt=5;handler after OK;');
        Obs.Expect('options', '<Field name="OptVal">5</Field><Field name="ExtOptVal">6</Field>');
        Obs.Expect('execute', 'ok');
        Obs.Expect('execute log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=5;ext OnOpenPage ext=6;RP OnClosePage opt=5;OnPreReport opt=5;ext OnPreReport ext=6;OnPreDataItem opt=5;');
        Obs.Expect('execute assigning', 'ok');
        Obs.Expect('execute assigning log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=5;ext OnOpenPage ext=6;RP OnClosePage opt=99;OnPreReport opt=99;ext OnPreReport ext=77;OnPreDataItem opt=99;');
        Obs.Verify();
    end;

    [Test]
    procedure Params_Execute_Handwritten()
    var
        Params: Text;
    begin
        Init(0);
        Params := '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT CH Params" id="' + Format(Report::"LT CH Params") +
            '"><Options><Field name="OptVal">5</Field><Field name="ExtOptVal">6</Field></Options><DataItems><DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
        Outcome('execute', TryExecute(Params));
        Obs.Observe('execute log', Log.Take());
        Log.SetMode(1);
        Outcome('execute assigning', TryExecute(Params));
        Obs.Observe('execute assigning log', Log.Take());
        Outcome('execute empty assigning', TryExecute(''));
        Obs.Observe('execute empty assigning log', Log.Take());
        Obs.Expect('execute', 'ok');
        Obs.Expect('execute log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=5;ext OnOpenPage ext=6;RP OnClosePage opt=5;OnPreReport opt=5;ext OnPreReport ext=6;OnPreDataItem opt=5;');
        Obs.Expect('execute assigning', 'ok');
        Obs.Expect('execute assigning log', 'OnInitReport;RP OnInit opt=0;RP OnOpenPage opt=5;ext OnOpenPage ext=6;RP OnClosePage opt=99;OnPreReport opt=99;ext OnPreReport ext=77;OnPreDataItem opt=99;');
        Obs.Expect('execute empty assigning', 'ok');
        Obs.Expect('execute empty assigning log', 'OnInitReport;RP OnInit opt=0;OnPreReport opt=0;ext OnPreReport ext=0;OnPreDataItem opt=0;');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryExecute(Params: Text)
    begin
        Report.Execute(Report::"LT CH Params", Params);
    end;

    [RequestPageHandler]
    procedure ParamsHandler(var RP: TestRequestPage "LT CH Params")
    begin
        Log.Add('handler shows opt=' + RP.Opt.Value() + ' ext=' + RP.ExtOpt.Value());
        RP.Opt.SetValue(5);
        RP.ExtOpt.SetValue(6);
        Log.Add('handler set');
        RP.OK().Invoke();
        Log.Add('handler after OK');
    end;

    // ---------------------------------------------------------------- Lost (item 126)

    [Test]
    [HandlerFunctions('LostHandler')]
    procedure Lost_SaveValues_OnOpenPageSetsTheOption()
    begin
        Init(0);
        // A first run stores false, so the observed runs do not depend on what earlier runs stored.
        HandlerMode := 1;
        Report.RunModal(Report::"LT CH Lost Value");
        Log.Take();
        Report.RunModal(Report::"LT CH Lost Value");
        HandlerMode := 2;
        Report.RunModal(Report::"LT CH Lost Value");
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'OnOpenPage show=No;handler shows Yes;OnPreReport show=No;OnPreDataItem show=No;OnOpenPage show=No;handler shows Yes;OnPreReport show=Yes;OnPreDataItem show=Yes;');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure LostHandler(var RP: TestRequestPage "LT CH Lost Value")
    begin
        Log.Add('handler shows ' + RP.Show.Value());
        if HandlerMode = 1 then
            RP.Show.SetValue(false);
        RP.OK().Invoke();
    end;
}
