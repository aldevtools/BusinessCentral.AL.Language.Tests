// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70640 is used only by test codeunit 70645
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: Request pages | A reportextension that only adds request page controls does not change the run. A control of an extension that names a
// `protected var` of the base report binds to the base report's variable (read, write, parameters text).
// BC versions: 29 (27 and 28 by CI)

codeunit 70640 "LT PnH ExtRp Log"
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

report 70641 "LT PnH ExtRpBase"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(BaseCtl; BaseText)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('base pre text=[' + BaseText + '] var=' + Format(BaseVar));
    end;

    var
        BaseText: Text[20];
        L: Codeunit "LT PnH ExtRp Log";

    protected var
        BaseVar: Integer;
}

reportextension 70642 "LT PnH ExtRpExt" extends "LT PnH ExtRpBase"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(ExtCtl; ExtVar)
                {
                    ApplicationArea = All;
                }
                field(BaseVarCtl; BaseVar)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('ext pre ext=[' + ExtVar + '] basevar=' + Format(BaseVar));
    end;

    var
        ExtVar: Text[20];
        L: Codeunit "LT PnH ExtRp Log";
}

codeunit 70645 "LT PnH ExtRp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH ExtRp Log";
        Observer: Codeunit "Probe Observer";
        Params: Text;

    local procedure Start()
    begin
        L.Take();
        Params := '';
    end;

    [Test]
    [HandlerFunctions('DefaultsHandler')]
    procedure Controls_Defaults_SeenByHandler()
    begin
        Start();
        Report.Run(Report::"LT PnH ExtRpBase");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'default base=[] ext=[] basevar=[0];base pre text=[] var=0;ext pre ext=[] basevar=0;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure DefaultsHandler(var RP: TestRequestPage "LT PnH ExtRpBase")
    begin
        L.Add('default base=[' + RP.BaseCtl.Value() + '] ext=[' + RP.ExtCtl.Value() + '] basevar=[' + RP.BaseVarCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetHandler')]
    procedure Controls_SetValue_ReachBaseAndExtension()
    begin
        Start();
        Report.Run(Report::"LT PnH ExtRpBase");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'after set base=[b] ext=[e] basevar=[42];base pre text=[b] var=42;ext pre ext=[e] basevar=42;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetHandler(var RP: TestRequestPage "LT PnH ExtRpBase")
    begin
        RP.BaseCtl.SetValue('b');
        RP.ExtCtl.SetValue('e');
        RP.BaseVarCtl.SetValue(42);
        L.Add('after set base=[' + RP.BaseCtl.Value() + '] ext=[' + RP.ExtCtl.Value() + '] basevar=[' + RP.BaseVarCtl.Value() + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('InvalidHandler')]
    procedure Controls_BaseVarControl_InvalidValue()
    begin
        Start();
        Report.Run(Report::"LT PnH ExtRpBase");
        Observer.Observe('log', L.Take());
        Observer.Expect('invalid|text', 'Validation error for Field: BaseVarCtl,  Message = ''Your entry of ''not a number'' is not an acceptable value for ''BaseVarCtl''. The value "not a number" can''t be evaluated into type Integer.''');
        Observer.Expect('invalid|code', 'TestValidation');
        Observer.Expect('log', 'base pre text=[] var=0;ext pre ext=[] basevar=0;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure InvalidHandler(var RP: TestRequestPage "LT PnH ExtRpBase")
    begin
        asserterror RP.BaseVarCtl.SetValue('not a number');
        Observer.ObserveError('invalid');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Controls_RunRequestPage_ParametersText_ThenExecute()
    var
        Rpt: Report "LT PnH ExtRpBase";
    begin
        Start();
        Params := Rpt.RunRequestPage();
        Observer.Observe('has BaseCtl', Format(Params.Contains('BaseCtl')));
        Observer.Observe('has ExtCtl', Format(Params.Contains('ExtCtl')));
        Observer.Observe('has BaseVarCtl', Format(Params.Contains('BaseVarCtl')));
        Observer.Observe('has value e', Format(Params.Contains('>e<')));
        Observer.Observe('has value 7', Format(Params.Contains('>7<')));
        Observer.Observe('log before execute', L.Take());
        Report.Execute(Report::"LT PnH ExtRpBase", Params);
        Observer.Observe('execute', L.Take());
        Observer.Expect('has BaseCtl', 'No');
        Observer.Expect('has ExtCtl', 'No');
        Observer.Expect('has BaseVarCtl', 'No');
        Observer.Expect('has value e', 'Yes');
        Observer.Expect('has value 7', 'Yes');
        Observer.Expect('log before execute', '');
        Observer.Expect('execute', 'base pre text=[b] var=7;ext pre ext=[e] basevar=7;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ParamsHandler(var RP: TestRequestPage "LT PnH ExtRpBase")
    begin
        RP.BaseCtl.SetValue('b');
        RP.ExtCtl.SetValue('e');
        RP.BaseVarCtl.SetValue(7);
        RP.OK().Invoke();
    end;

    [Test]
    procedure Controls_NoHandler_UseRequestPageFalse_Defaults()
    var
        Rpt: Report "LT PnH ExtRpBase";
    begin
        Start();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'base pre text=[] var=0;ext pre ext=[] basevar=0;');
        Observer.Verify();
    end;
}
