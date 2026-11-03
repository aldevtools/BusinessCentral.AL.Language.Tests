// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: P112Fix.al (table 71831, helper 71834), SingleInstance log 71850 (used only by test codeunit 71852), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: OnAssistEdit and OnDrillDown triggers of fields on a report's request page, driven by TestRequestPage field AssistEdit() and DrillDown() in a RequestPageHandler: what the triggers see and change, the value after OK and Cancel, and the values the report sees
// BC versions: 29 (27 and 28 by CI)

codeunit 71850 "LT P112 Rp Log"
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

report 71851 "LT P112 Rp"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(ItemRow; "LT P112 Item")
        {
            RequestFilterFields = Id;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(ItemRow.Id));
            end;
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
                    field(NameCtl; NameVal)
                    {
                        ApplicationArea = All;

                        trigger OnAssistEdit()
                        begin
                            L.Add('assist before=[' + NameVal + ']');
                            NameVal := 'assisted';
                        end;
                    }
                    field(CountCtl; CountVal)
                    {
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        begin
                            L.Add('drill count=' + Format(CountVal));
                            CountVal += 1;
                        end;
                    }
                    field(PlainCtl; PlainVal)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    var
        NameVal: Text[30];
        CountVal: Integer;
        PlainVal: Text[30];
        L: Codeunit "LT P112 Rp Log";

    trigger OnInitReport()
    begin
        NameVal := 'init';
        CountVal := 7;
    end;

    trigger OnPreReport()
    begin
        L.Add('pre name=[' + NameVal + '] count=' + Format(CountVal) + ' plain=[' + PlainVal + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;
}

codeunit 71852 "LT P112 Rp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P112 Rp Log";
        Helper: Codeunit "LT P112 Helper";

    local procedure Seed()
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Helper.AddItem(2, 'Beta', 20);
        Commit();
        L.Take();
    end;

    [RequestPageHandler]
    procedure AssistHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        L.Add('h value before=[' + RP.NameCtl.Value() + ']');
        RP.NameCtl.AssistEdit();
        L.Add('h value after=[' + RP.NameCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure DrillHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        L.Add('h value before=[' + RP.CountCtl.Value() + ']');
        RP.CountCtl.DrillDown();
        L.Add('h value after one=[' + RP.CountCtl.Value() + ']');
        RP.CountCtl.DrillDown();
        L.Add('h value after two=[' + RP.CountCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure BothHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        RP.NameCtl.SetValue('typed');
        RP.NameCtl.AssistEdit();
        RP.CountCtl.SetValue(40);
        RP.CountCtl.DrillDown();
        RP.PlainCtl.SetValue('plain');
        L.Add('h name=[' + RP.NameCtl.Value() + '] count=[' + RP.CountCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        RP.NameCtl.AssistEdit();
        RP.CountCtl.DrillDown();
        RP.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryPlainAssist(var RP: TestRequestPage "LT P112 Rp")
    begin
        RP.PlainCtl.AssistEdit();
    end;

    [TryFunction]
    local procedure TryPlainDrill(var RP: TestRequestPage "LT P112 Rp")
    begin
        RP.PlainCtl.DrillDown();
    end;

    [RequestPageHandler]
    procedure PlainAssistHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        L.Add('h plain assist ok=' + Format(TryPlainAssist(RP)) + ' error=[' + GetLastErrorText() + ']');
        L.Add('h plain drill ok=' + Format(TryPlainDrill(RP)) + ' error=[' + GetLastErrorText() + ']');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ParamsHandler(var RP: TestRequestPage "LT P112 Rp")
    begin
        RP.NameCtl.AssistEdit();
        RP.CountCtl.DrillDown();
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('AssistHandler')]
    procedure P112_Run_AssistEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT P112 Rp", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'h value before=[init];assist before=[init];h value after=[assisted];pre name=[assisted] count=7 plain=[];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DrillHandler')]
    procedure P112_Run_DrillDown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT P112 Rp", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'h value before=[7];drill count=7;h value after one=[8];drill count=8;h value after two=[9];pre name=[init] count=9 plain=[];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BothHandler')]
    procedure P112_Run_SetValueThenTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT P112 Rp", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'assist before=[typed];drill count=40;h name=[assisted] count=[41];pre name=[assisted] count=41 plain=[plain];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P112_Run_Cancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT P112 Rp", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'assist before=[init];drill count=7;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainAssistHandler')]
    procedure P112_Run_FieldsWithoutTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT P112 Rp", true, false);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'h plain assist ok=No error=[The NavAssistEditAction method is not supported.];h plain drill ok=No error=[The NavDrilldownAction method is not supported.];pre name=[init] count=7 plain=[];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure P112_RunRequestPage_Then_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT P112 Rp");
        Observer.Observe('log after request page', L.Take());
        Observer.Observe('params non empty', Format(Params <> ''));
        Report.Execute(Report::"LT P112 Rp", Params);
        Observer.Observe('log after execute', L.Take());
        Observer.Expect('log after request page', 'assist before=[init];drill count=7;');
        Observer.Expect('params non empty', 'Yes');
        Observer.Expect('log after execute', 'pre name=[assisted] count=8 plain=[];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AssistHandler')]
    procedure P112_Run_Instance_AssistEdit()
    var
        Observer: Codeunit "Probe Observer";
        Rp: Report "LT P112 Rp";
    begin
        Seed();
        Rp.UseRequestPage(true);
        Rp.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'h value before=[init];assist before=[init];h value after=[assisted];pre name=[assisted] count=7 plain=[];row 1;row 2;post;');
        Observer.Verify();
    end;
}
