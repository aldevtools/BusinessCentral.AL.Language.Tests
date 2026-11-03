// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: tables and helper of RptFixtures.al; SingleInstance log 73840 is used only by test codeunit 73850
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// TestRequestPage members (fields: Value, SetValue, AssertEquals, Visible, Editable, Enabled, Caption; data item filters SetFilter / GetFilter;
// actions OK, Cancel, Preview, Print, Schedule and a custom action), request page default values and triggers,
// Report.Run / RunRequestPage / Execute / SaveAs with a [RequestPageHandler], a missing handler, a handler of another report,
// the return value of RunRequestPage, UseRequestPage(false).
// BC versions: 29 (27 and 28 by CI)

codeunit 73840 "LT RpT Request Log"
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

report 73841 "LT RpT Request"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('row pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    field(TextCtl; TextVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Text Control';

                        trigger OnValidate()
                        begin
                            L.Add('validate text=[' + TextVal + ']');
                        end;
                    }
                    field(IntCtl; IntVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Integer Control';

                        trigger OnValidate()
                        begin
                            L.Add('validate int=' + Format(IntVal));
                        end;
                    }
                    field(DecCtl; DecVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Decimal Control';
                    }
                    field(BoolCtl; BoolVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Boolean Control';
                    }
                    field(DateCtl; DateVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Date Control';
                    }
                    field(OptCtl; OptVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Option Control';
                    }
                    field(FixedCtl; FixedVal)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Fixed Control';
                    }
                    field(HiddenCtl; HiddenVal)
                    {
                        ApplicationArea = All;
                        Visible = false;
                        Caption = 'Hidden Control';
                    }
                    field(DisabledCtl; DisabledVal)
                    {
                        ApplicationArea = All;
                        Enabled = false;
                        Caption = 'Disabled Control';
                    }
                    field(DynCtl; DynVal)
                    {
                        ApplicationArea = All;
                        Editable = DynEditable;
                        Visible = DynVisible;
                        Caption = 'Dynamic Control';
                    }
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(CustomAction)
                {
                    ApplicationArea = All;
                    Caption = 'Custom Action';

                    trigger OnAction()
                    begin
                        L.Add('custom action text=[' + TextVal + ']');
                    end;
                }
            }
        }

        trigger OnInit()
        begin
            L.Add('RP OnInit text=[' + TextVal + '] int=' + Format(IntVal));
            DynEditable := false;
            DynVisible := true;
        end;

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage text=[' + TextVal + '] int=' + Format(IntVal));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction) + ' text=[' + TextVal + ']');
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage text=[' + TextVal + ']');
        end;
    }

    var
        TextVal: Text[30];
        IntVal: Integer;
        DecVal: Decimal;
        BoolVal: Boolean;
        DateVal: Date;
        OptVal: Option A,B,C;
        FixedVal: Integer;
        HiddenVal: Integer;
        DisabledVal: Integer;
        DynVal: Integer;
        DynEditable: Boolean;
        DynVisible: Boolean;
        L: Codeunit "LT RpT Request Log";

    trigger OnInitReport()
    begin
        TextVal := 'init';
        IntVal := 7;
        DecVal := 1.5;
        BoolVal := true;
        DateVal := DMY2Date(2, 3, 2020);
        OptVal := OptVal::B;
        FixedVal := 99;
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport text=[' + TextVal + '] int=' + Format(IntVal) + ' dec=' + Format(DecVal) + ' bool=' + Format(BoolVal) + ' date=' + Format(DateVal, 0, 9) + ' opt=' + Format(OptVal) + ' fixed=' + Format(FixedVal));
    end;

    trigger OnPostReport()
    begin
        L.Add('OnPostReport');
    end;
}

report 73842 "LT RpT Request Other"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OtherCtl; OtherVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        OtherVal: Integer;
        L: Codeunit "LT RpT Request Log";

    trigger OnPreReport()
    begin
        L.Add('Other OnPreReport other=' + Format(OtherVal));
    end;
}

report 73843 "LT RpT Request Skipped"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(SkippedCtl; SkippedVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        SkippedVal: Integer;
        L: Codeunit "LT RpT Request Log";

    trigger OnPreReport()
    begin
        L.Add('Skipped OnPreReport val=' + Format(SkippedVal));
    end;
}

codeunit 73850 "LT RpT Request Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT RpT Request Log";
        Helper: Codeunit "LT RpT Helper";
        PxMode: Text;

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        I: Integer;
    begin
        Row.DeleteAll();
        L.Take();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := 1;
            Row.Insert();
        end;
        Commit();
    end;

    [Test]
    [HandlerFunctions('DefaultsHandler')]
    procedure Defaults_SeenByHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('af299');
        Observer.Observe('log', L.Take());
        Observer.Expect('af299|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af299|code', 'TestFieldNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h text=[init];h int=[7];h dec=[1.50];h bool=[Yes];h date=[3/2/2020];h opt=[B];h fixed=[99];RP OnQueryClosePage action=Cancel text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure DefaultsHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('h text=[' + RP.TextCtl.Value() + ']');
        L.Add('h int=[' + RP.IntCtl.Value() + ']');
        L.Add('h dec=[' + RP.DecCtl.Value() + ']');
        L.Add('h bool=[' + RP.BoolCtl.Value() + ']');
        L.Add('h date=[' + RP.DateCtl.Value() + ']');
        L.Add('h opt=[' + RP.OptCtl.Value() + ']');
        L.Add('h fixed=[' + RP.FixedCtl.Value() + ']');
        L.Add('h hidden=[' + RP.HiddenCtl.Value() + ']');
        L.Add('h disabled=[' + RP.DisabledCtl.Value() + ']');
        L.Add('h dyn=[' + RP.DynCtl.Value() + ']');
        L.Add('h filter=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetValuesHandler')]
    procedure SetValue_AllTypes_ReachTheReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;validate text=[typed];validate int=42;h text=[typed] int=[42] dec=[2.25] bool=[No] date=[6/5/2021] opt=[C];RP OnQueryClosePage action=OK text=[typed];RP OnClosePage text=[typed];OnPreReport text=[typed] int=42 dec=2.25 bool=No date=2021-06-05 opt=C fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetValuesHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.TextCtl.SetValue('typed');
        RP.IntCtl.SetValue(42);
        RP.DecCtl.SetValue(2.25);
        RP.BoolCtl.SetValue(false);
        RP.DateCtl.SetValue(DMY2Date(5, 6, 2021));
        RP.OptCtl.SetValue('C');
        L.Add('h text=[' + RP.TextCtl.Value() + '] int=[' + RP.IntCtl.Value() + '] dec=[' + RP.DecCtl.Value() + '] bool=[' + RP.BoolCtl.Value() + '] date=[' + RP.DateCtl.Value() + '] opt=[' + RP.OptCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetOptionByNumberHandler')]
    procedure SetValue_OptionByNumberAndText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h opt0=[A];h optb=[B];h opt2=[C];RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=C fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetOptionByNumberHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.OptCtl.SetValue(0);
        L.Add('h opt0=[' + RP.OptCtl.Value() + ']');
        RP.OptCtl.SetValue('b');
        L.Add('h optb=[' + RP.OptCtl.Value() + ']');
        RP.OptCtl.SetValue(2);
        L.Add('h opt2=[' + RP.OptCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    local procedure LogError(Name: Text)
    begin
        L.Add(Name + ' text=[' + GetLastErrorText() + '] code=[' + GetLastErrorCode() + ']');
        ClearLastError();
    end;

    [RequestPageHandler]
    procedure InvalidValuesHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        asserterror RP.IntCtl.SetValue('abc');
        LogError('int abc');
        asserterror RP.OptCtl.SetValue('Z');
        LogError('opt Z');
        asserterror RP.DateCtl.SetValue('notadate');
        LogError('date text');
        asserterror RP.BoolCtl.SetValue('maybe');
        LogError('bool text');
        asserterror RP.DecCtl.SetValue('1,2,3');
        LogError('dec text');
        asserterror RP.TextCtl.SetValue('0123456789012345678901234567890123456789');
        LogError('text too long');
        L.Add('h after text=[' + RP.TextCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PropertiesHandler')]
    procedure Field_VisibleEditableEnabledCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('af415');
        Observer.Observe('log', L.Take());
        Observer.Expect('af415|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af415|code', 'TestFieldNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;text v=Yes e=Yes en=Yes cap=[Text Control];fixed v=Yes e=No en=Yes cap=[Fixed Control];RP OnQueryClosePage action=Cancel text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PropertiesHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('text v=' + Format(RP.TextCtl.Visible()) + ' e=' + Format(RP.TextCtl.Editable()) + ' en=' + Format(RP.TextCtl.Enabled()) + ' cap=[' + RP.TextCtl.Caption() + ']');
        L.Add('fixed v=' + Format(RP.FixedCtl.Visible()) + ' e=' + Format(RP.FixedCtl.Editable()) + ' en=' + Format(RP.FixedCtl.Enabled()) + ' cap=[' + RP.FixedCtl.Caption() + ']');
        L.Add('hidden v=' + Format(RP.HiddenCtl.Visible()) + ' e=' + Format(RP.HiddenCtl.Editable()) + ' en=' + Format(RP.HiddenCtl.Enabled()) + ' cap=[' + RP.HiddenCtl.Caption() + ']');
        L.Add('disabled v=' + Format(RP.DisabledCtl.Visible()) + ' e=' + Format(RP.DisabledCtl.Editable()) + ' en=' + Format(RP.DisabledCtl.Enabled()) + ' cap=[' + RP.DisabledCtl.Caption() + ']');
        L.Add('dyn v=' + Format(RP.DynCtl.Visible()) + ' e=' + Format(RP.DynCtl.Editable()) + ' en=' + Format(RP.DynCtl.Enabled()));
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure NonEditableSetHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        asserterror RP.FixedCtl.SetValue(5);
        LogError('fixed set');
        asserterror RP.DynCtl.SetValue(5);
        LogError('dyn set');
        asserterror RP.DisabledCtl.SetValue(5);
        LogError('disabled set');
        L.Add('h fixed=[' + RP.FixedCtl.Value() + '] dyn=[' + RP.DynCtl.Value() + '] disabled=[' + RP.DisabledCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('HiddenSetHandler')]
    procedure SetValue_HiddenField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('af464');
        Observer.Observe('log', L.Take());
        Observer.Expect('af464|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af464|code', 'TestFieldNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;hidden set text=[The field with ID = n is not found on the page.] code=[TestFieldNotFound];RP OnQueryClosePage action=Cancel text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure HiddenSetHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        asserterror RP.HiddenCtl.SetValue(5);
        LogError('hidden set');
        L.Add('h hidden=[' + RP.HiddenCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('AssertEqualsHandler')]
    procedure AssertEquals_PassAndFail()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;assert text ok;assert text text=[AssertEquals for Field: TextCtl Expected = ''other'', Actual = ''init''] code=[TestAssertEquals];assert int text=[AssertEquals for Field: IntCtl Expected = ''8'', Actual = ''7''] code=[TestAssertEquals];assert opt ok;assert bool text=[AssertEquals for Field: BoolCtl Expected = ''No'', Actual = ''Yes''] code=[TestAssertEquals];RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure AssertEqualsHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.TextCtl.AssertEquals('init');
        L.Add('assert text ok');
        asserterror RP.TextCtl.AssertEquals('other');
        LogError('assert text');
        asserterror RP.IntCtl.AssertEquals(8);
        LogError('assert int');
        RP.IntCtl.AssertEquals(7);
        RP.OptCtl.AssertEquals('B');
        L.Add('assert opt ok');
        asserterror RP.BoolCtl.AssertEquals(false);
        LogError('assert bool');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ValidateHandler')]
    procedure OnValidate_RunsOnSetValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;validate text=[a];validate text=[a];validate int=7;validate int=8;RP OnQueryClosePage action=OK text=[a];RP OnClosePage text=[a];OnPreReport text=[a] int=8 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ValidateHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.TextCtl.SetValue('a');
        RP.TextCtl.SetValue('a');
        RP.IntCtl.SetValue(7);
        RP.IntCtl.SetValue(8);
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure FilterHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Row.SetFilter(Id, '2..3');
        L.Add('h filter=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('h cleared=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '1|4');
        L.Add('h or=[' + RP.Row.GetFilter(Id) + ']');
        asserterror RP.Row.SetFilter(Id, 'abc');
        LogError('filter abc');
        asserterror RP.Row.SetFilter(Name, 'x');
        LogError('filter other field');
        L.Add('h final=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure OK_TriggersOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h start;validate text=[ok];RP OnQueryClosePage action=OK text=[ok];RP OnClosePage text=[ok];h after ok;OnPreReport text=[ok] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('h start');
        RP.TextCtl.SetValue('ok');
        RP.OK().Invoke();
        L.Add('h after ok');
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure Cancel_TriggersOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h start;validate text=[cancel];RP OnQueryClosePage action=Cancel text=[cancel];RP OnClosePage text=[cancel];h after cancel;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('h start');
        RP.TextCtl.SetValue('cancel');
        RP.Cancel().Invoke();
        L.Add('h after cancel');
    end;

    [Test]
    [HandlerFunctions('ActionsHandler')]
    procedure Actions_VisibleEnabled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;OK visible=Yes;OK enabled=Yes;Cancel visible=Yes;Cancel enabled=Yes;Preview visible error=The built-in action = Preview is not found on the page.;Preview enabled error=The built-in action = Preview is not found on the page.;Print visible error=The built-in action = Print is not found on the page.;Print enabled error=The built-in action = Print is not found on the page.;Schedule visible=Yes;Schedule enabled=Yes;Custom visible error=The action with ID = n is not found on the page.;Custom enabled error=The action with ID = n is not found on the page.;RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryVisible(var RP: TestRequestPage "LT RpT Request"; Which: Integer; var Answer: Boolean)
    begin
        case Which of
            1:
                Answer := RP.OK().Visible();
            2:
                Answer := RP.Cancel().Visible();
            3:
                Answer := RP.Preview().Visible();
            4:
                Answer := RP.Print().Visible();
            5:
                Answer := RP.Schedule().Visible();
            6:
                Answer := RP.CustomAction.Visible();
        end;
    end;

    [TryFunction]
    local procedure TryEnabled(var RP: TestRequestPage "LT RpT Request"; Which: Integer; var Answer: Boolean)
    begin
        case Which of
            1:
                Answer := RP.OK().Enabled();
            2:
                Answer := RP.Cancel().Enabled();
            3:
                Answer := RP.Preview().Enabled();
            4:
                Answer := RP.Print().Enabled();
            5:
                Answer := RP.Schedule().Enabled();
            6:
                Answer := RP.CustomAction.Enabled();
        end;
    end;

    local procedure DescribeAction(var RP: TestRequestPage "LT RpT Request"; Which: Integer; Name: Text)
    var
        Answer: Boolean;
    begin
        if TryVisible(RP, Which, Answer) then
            L.Add(Name + ' visible=' + Format(Answer))
        else
            L.Add(Name + ' visible error=' + GetLastErrorText());
        if TryEnabled(RP, Which, Answer) then
            L.Add(Name + ' enabled=' + Format(Answer))
        else
            L.Add(Name + ' enabled error=' + GetLastErrorText());
    end;

    [RequestPageHandler]
    procedure ActionsHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        DescribeAction(RP, 1, 'OK');
        DescribeAction(RP, 2, 'Cancel');
        DescribeAction(RP, 3, 'Preview');
        DescribeAction(RP, 4, 'Print');
        DescribeAction(RP, 5, 'Schedule');
        DescribeAction(RP, 6, 'Custom');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CustomActionHandler')]
    procedure CustomAction_Invoke()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('af684');
        Observer.Observe('log', L.Take());
        Observer.Expect('af684|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('af684|code', 'TestActionNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;validate text=[before];RP OnQueryClosePage action=Cancel text=[before];RP OnClosePage text=[before];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CustomActionHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.TextCtl.SetValue('before');
        RP.CustomAction.Invoke();
        L.Add('h after custom');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PreviewHandler')]
    procedure Preview_Invoke_RunsReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'The built-in action = Preview is not found on the page.');
        Observer.Expect('run|code', 'TestActionNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;RP OnQueryClosePage action=Cancel text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PreviewHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Preview().Invoke();
    end;

    [Test]
    [HandlerFunctions('PrintHandler')]
    procedure Print_Invoke_RunsReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'The built-in action = Print is not found on the page.');
        Observer.Expect('run|code', 'TestActionNotFound');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;RP OnQueryClosePage action=Cancel text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PrintHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Print().Invoke();
    end;

    [Test]
    [HandlerFunctions('ScheduleHandler')]
    procedure Schedule_Invoke()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Unhandled UI: ModalPage 682');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;RP OnQueryClosePage action=Schedule text=[init];RP OnClosePage text=[init];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ScheduleHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.Schedule().Invoke();
    end;

    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure Handler_DoesNotClosePage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;validate text=[left open];h returning;RP OnQueryClosePage action=Cancel text=[left open];RP OnClosePage text=[left open];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LeaveOpenHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        RP.TextCtl.SetValue('left open');
        L.Add('h returning');
    end;

    [Test]
    procedure NoHandler_RunError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 73841');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Verify();
    end;

    [Test]
    procedure NoHandler_RunRequestPage_Error()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        asserterror Params := Report.RunRequestPage(Report::"LT RpT Request");
        Observer.ObserveError('run request page');
        Observer.Observe('log', L.Take());
        Observer.Expect('run request page|text', 'Unhandled UI: RequestPage 73841');
        Observer.Expect('run request page|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Verify();
    end;

    [Test]
    procedure NoHandler_VariableRunModal_Error()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        asserterror Rpt.RunModal();
        Observer.ObserveError('run modal');
        Observer.Expect('run modal|text', 'Unhandled UI: RequestPage 73841');
        Observer.Expect('run modal|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OtherReportHandler')]
    procedure Handler_OfAnotherReport_Mismatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT RpT Request");
        Observer.ObserveError('mismatch');
        Observer.Observe('log after mismatch', L.Take());
        Report.Run(Report::"LT RpT Request Other");
        Observer.Observe('log after other', L.Take());
        Observer.Expect('mismatch|text', 'Unhandled UI: RequestPage 73841');
        Observer.Expect('mismatch|code', 'MissingUIHandler');
        Observer.Expect('log after mismatch', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Expect('log after other', 'Other OnPreReport other=5;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OtherReportHandler(var RP: TestRequestPage "LT RpT Request Other")
    begin
        RP.OtherCtl.SetValue(5);
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RunRequestPage_ReturnValue_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Observe('starts with xml', Format(Params.StartsWith('<?xml')));
        Observer.Observe('options', Helper.Between(Params, '<Options>', '</Options>'));
        Observer.Observe('dataitems', Helper.Between(Params, '<DataItems>', '</DataItems>'));
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h start;validate text=[ok];RP OnQueryClosePage action=OK text=[ok];RP OnClosePage text=[ok];h after ok;');
        Observer.Expect('starts with xml', 'Yes');
        Observer.Expect('options', '<Field name="TextVal">ok</Field><Field name="IntVal">7</Field><Field name="DecVal">1.5</Field><Field name="BoolVal">true</Field><Field name="DateVal">2020-03-02</Field><Field name="OptVal">1</Field><Field name="FixedVal">99</Field><Field name="HiddenVal">0</Field><Field name="DisabledVal">0</Field><Field name="DynVal">0</Field>');
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1)</DataItem>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure RunRequestPage_ReturnValue_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT Request");
        Observer.Observe('log', L.Take());
        Observer.Observe('params', '[' + Params + ']');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h start;validate text=[cancel];RP OnQueryClosePage action=Cancel text=[cancel];RP OnClosePage text=[cancel];h after cancel;');
        Observer.Expect('params', '[]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetValuesHandler')]
    procedure RunRequestPage_ThenExecute_AppliesValues()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT Request");
        Observer.Observe('page log', L.Take());
        Observer.Observe('options', Helper.Between(Params, '<Options>', '</Options>'));
        Report.Execute(Report::"LT RpT Request", Params);
        Observer.Observe('execute log', L.Take());
        Observer.Expect('page log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;validate text=[typed];validate int=42;h text=[typed] int=[42] dec=[2.25] bool=[No] date=[6/5/2021] opt=[C];RP OnQueryClosePage action=OK text=[typed];RP OnClosePage text=[typed];');
        Observer.Expect('options', '<Field name="TextVal">typed</Field><Field name="IntVal">42</Field><Field name="DecVal">2.25</Field><Field name="BoolVal">false</Field><Field name="DateVal">2021-06-05</Field><Field name="OptVal">2</Field><Field name="FixedVal">99</Field><Field name="HiddenVal">0</Field><Field name="DisabledVal">0</Field><Field name="DynVal">0</Field>');
        Observer.Expect('execute log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[typed] int=42;RP OnClosePage text=[typed];OnPreReport text=[typed] int=42 dec=2.25 bool=No date=2021-06-05 opt=C fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetValuesHandler')]
    procedure RunRequestPage_ThenSaveAs_AppliesValues()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT Request");
        L.Take();
        Ok := Helper.Save(Report::"LT RpT Request", Params, Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'No');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_WithoutParameters_UsesDefaults()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"LT RpT Request", '');
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_WithoutParameters_UsesDefaults()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT RpT Request", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'No');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPageFalse_RunDoesNotShowPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Request Skipped");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'Skipped OnPreReport val=0;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPage_GetterSetter()
    var
        Observer: Codeunit "Probe Observer";
        Shown: Report "LT RpT Request";
        Skipped: Report "LT RpT Request Skipped";
    begin
        Observer.Observe('default true', Format(Shown.UseRequestPage()));
        Observer.Observe('declared false', Format(Skipped.UseRequestPage()));
        Shown.UseRequestPage(false);
        Skipped.UseRequestPage(true);
        Observer.Observe('shown after false', Format(Shown.UseRequestPage()));
        Observer.Observe('skipped after true', Format(Skipped.UseRequestPage()));
        Observer.Expect('default true', 'Yes');
        Observer.Expect('declared false', 'No');
        Observer.Expect('shown after false', 'No');
        Observer.Expect('skipped after true', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPageFalse_VariableRun_NoHandlerNeeded()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPageFalse_RunModalAndRunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request";
        Params: Text;
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('run modal', L.Take());
        asserterror Params := Rpt.RunRequestPage();
        Observer.ObserveError('af989');
        Observer.Observe('run request page', L.Take());
        Observer.Observe('params', '[' + Params + ']');
        Observer.Expect('run modal', 'OnInitReport;RP OnInit text=[init] int=7;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Expect('af989|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('af989|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('run request page', '');
        Observer.Expect('params', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPageTrue_OverridesDeclaredFalse()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request Skipped";
    begin
        Seed();
        Rpt.UseRequestPage(true);
        asserterror Rpt.Run();
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 73843');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SkippedHandler')]
    procedure UseRequestPageTrue_DeclaredFalse_ShowsPage()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request Skipped";
    begin
        Seed();
        Rpt.UseRequestPage(true);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'Skipped OnPreReport val=3;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SkippedHandler(var RP: TestRequestPage "LT RpT Request Skipped")
    begin
        RP.SkippedCtl.SetValue(3);
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetTableViewHandler')]
    procedure SetTableView_ThenRequestPage_SeesViewAsFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Request";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Id, 2, 3);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;h filter=[2..3];RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[2..3];row 2;row 3;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetTableViewHandler(var RP: TestRequestPage "LT RpT Request")
    begin
        L.Add('h filter=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    // Writer PX (al-runtime-rs probes-needed "Request page", PR 333): a handler error it does not catch closes the request page; which
    // triggers run, in what order, and the error the caller gets, for the shapes the runtime refuses (objects in PxRequestPageClose.al).
    [Test]
    [HandlerFunctions('PxSourceErrorHandler')]
    procedure PX_HandlerError_SourceTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT PX Rp Source");
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        Observer.Expect('err|text', 'px handler raised');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'OnInitReport;RP OnOpenPage;RP OnAfterGetRecord 1;RP OnAfterGetCurrRecord 1;h id=[1];RP OnQueryClosePage action=Cancel;RP OnClosePage;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxSourceErrorHandler(var RP: TestRequestPage "LT PX Rp Source")
    begin
        L.Add('h id=[' + RP.SrcId.Value() + ']');
        Error('px handler raised');
    end;

    [Test]
    [HandlerFunctions('PxPartsErrorHandler')]
    procedure PX_HandlerError_Parts()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT RpT Child";
    begin
        Seed();
        Child.DeleteAll();
        Child.Id := 1;
        Child.Insert();
        Child.Id := 2;
        Child.Insert();
        Commit();
        L.Take();
        asserterror Report.Run(Report::"LT PX Rp Parts");
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        Observer.Expect('err|text', 'px handler raised');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'RP OnOpenPage;part OnOpenPage;part OnAfterGetCurrRecord 1;h;part OnQueryClosePage action=None;RP OnQueryClosePage action=Cancel;part OnClosePage;RP OnClosePage;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxPartsErrorHandler(var RP: TestRequestPage "LT PX Rp Parts")
    begin
        L.Add('h');
        Error('px handler raised');
    end;

    [Test]
    [HandlerFunctions('PxExtErrorHandler')]
    procedure PX_HandlerError_ExtensionCloseTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror Report.Run(Report::"LT PX Rp ExtBase");
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        Observer.Expect('err|text', 'px handler raised');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'RP OnOpenPage;ext RP OnOpenPage;h;RP OnQueryClosePage action=Cancel;ext RP OnQueryClosePage action=Cancel;RP OnClosePage;ext RP OnClosePage;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxExtErrorHandler(var RP: TestRequestPage "LT PX Rp ExtBase")
    begin
        L.Add('h');
        Error('px handler raised');
    end;

    local procedure PxRunCloseMode(Mode: Integer)
    var
        Rpt: Report "LT PX Rp CloseMode";
    begin
        Rpt.SetMode(Mode);
        Rpt.Run();
    end;

    // Not tests (writer PX, local BC 29.0): with OnQueryClosePage answering false (mode 1) or raising (mode 2), a handler error gives the
    // caller the handler's error ('px handler raised', Dialog); the log is 'RP OnOpenPage;h;RP OnQueryClosePage action=Cancel;' and
    // OnClosePage does not run, so the request page may stay open in the session: in the run with these tests a later test codeunit
    // failed at Report.Run with 'Server page is already open.'. They are left out so no other test depends on them.

    [Test]
    [HandlerFunctions('PxCloseModeErrorHandler')]
    procedure PX_HandlerError_ClosePageRaises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        asserterror PxRunCloseMode(3);
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        Observer.Expect('err|text', 'px handler raised');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'RP OnOpenPage;h;RP OnQueryClosePage action=Cancel;RP OnClosePage;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxCloseModeErrorHandler(var RP: TestRequestPage "LT PX Rp CloseMode")
    begin
        L.Add('h');
        Error('px handler raised');
    end;

    // A SaveValues request page: OK with 'base' saves it; a run whose handler sets 'changed' and raises; the next run shows which is saved.
    [Test]
    [HandlerFunctions('PxSaveValuesHandler')]
    procedure PX_HandlerError_SaveValues_NextRunShows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PxMode := 'set_ok';
        Report.Run(Report::"LT PX Rp SaveValues");
        Observer.Observe('first', L.Take());
        PxMode := 'set_err';
        asserterror Report.Run(Report::"LT PX Rp SaveValues");
        Observer.ObserveError('err');
        Observer.Observe('second', L.Take());
        PxMode := 'read';
        Report.Run(Report::"LT PX Rp SaveValues");
        Observer.Observe('third', L.Take());
        Observer.Expect('first', 'RP OnQueryClosePage action=OK text=[base];OnPreReport text=[base];');
        Observer.Expect('err|text', 'px handler raised');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('second', 'h set_err shown=[base];RP OnQueryClosePage action=Cancel text=[changed];');
        Observer.Expect('third', 'h read shown=[base];RP OnQueryClosePage action=OK text=[base];OnPreReport text=[base];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PxSaveValuesHandler(var RP: TestRequestPage "LT PX Rp SaveValues")
    begin
        // The value shown at the first run depends on earlier runs in the same database: not logged.
        if PxMode <> 'set_ok' then
            L.Add('h ' + PxMode + ' shown=[' + RP.TextCtl.Value() + ']');
        case PxMode of
            'set_ok':
                begin
                    RP.TextCtl.SetValue('base');
                    RP.OK().Invoke();
                end;
            'set_err':
                begin
                    RP.TextCtl.SetValue('changed');
                    Error('px handler raised');
                end;
            else
                RP.OK().Invoke();
        end;
    end;

    // Writer RI (al-runtime-rs issue 5691): the handler's SetValue raises and the handler does not catch it (objects in
    // RiRequestPageRefusedEntry.al). The error leaves Report.Run; the log shows which close triggers ran. A second run in the same test
    // shows whether the page was closed. The value the failed OnValidate saw (Yes) is not kept: OnQueryClosePage reads No.
    [Test]
    [HandlerFunctions('RiRefusedHandler')]
    procedure RI_HandlerSetValue_OnValidateError_ReachesRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PxMode := 'apply';
        asserterror Report.Run(Report::"LT RI Rp Refused");
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        PxMode := 'ok';
        Report.Run(Report::"LT RI Rp Refused");
        Observer.Observe('next run', L.Take());
        Observer.Expect('err|text', 'Validation error for Field: ApplyCtl,  Message = ''LT RI apply rejected''');
        Observer.Expect('err|code', 'TestValidation');
        Observer.Expect('log', 'RP OnOpenPage;h apply;validate apply=Yes;RP OnQueryClosePage action=Cancel apply=No int=0;RP OnClosePage;');
        Observer.Expect('next run', 'RP OnOpenPage;h ok;RP OnQueryClosePage action=OK apply=No int=0;RP OnClosePage;OnPreReport apply=No int=0;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RiRefusedHandler')]
    procedure RI_HandlerSetValue_NotEvaluable_ReachesRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PxMode := 'int';
        asserterror Report.Run(Report::"LT RI Rp Refused");
        Observer.ObserveError('err');
        Observer.Observe('log', L.Take());
        PxMode := 'ok';
        Report.Run(Report::"LT RI Rp Refused");
        Observer.Observe('next run', L.Take());
        Observer.Expect('err|text', 'Validation error for Field: IntCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''IntCtl''. The value "abc" can''t be evaluated into type Integer.''');
        Observer.Expect('err|code', 'TestValidation');
        Observer.Expect('log', 'RP OnOpenPage;h int;RP OnQueryClosePage action=Cancel apply=No int=0;RP OnClosePage;');
        Observer.Expect('next run', 'RP OnOpenPage;h ok;RP OnQueryClosePage action=OK apply=No int=0;RP OnClosePage;OnPreReport apply=No int=0;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RiRefusedHandler(var RP: TestRequestPage "LT RI Rp Refused")
    begin
        L.Add('h ' + PxMode);
        case PxMode of
            'apply':
                RP.ApplyCtl.SetValue(true);
            'int':
                RP.IntCtl.SetValue('abc');
        end;
        if PxMode <> 'ok' then
            L.Add('h after SetValue');
        if PxMode = 'ok' then
            RP.OK().Invoke()
        else
            RP.Cancel().Invoke();
    end;
}
