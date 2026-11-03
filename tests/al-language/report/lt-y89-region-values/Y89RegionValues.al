// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatregion-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); reports and helpers of report/lt-bd-format-region/ (BdRegionFixtures.al, BdRegionReports.al); test codeunit 94742
// Probe (writer Y89, from the runtime lane rt-reports-1103c; extends BdRegionTests.al, nothing of it is changed): (1) the BC 27 and 28 values of the property and setter
// tests whose assertions BdRegionTests.al gives for BC 29 only (BdProperty_Gb, _Dk, _Nl, _Es, _Se, _No and BdSetter_EnGB, _NlNL, _SvSE, _DaDK end in Discard() on BC 27 and 28).
// (2) CurrReport.FormatRegion := a region after CurrReport.Language := a language of its own (month names and date texts in da, nl, es, sv, nb, en-GB), the dataset part and the
// run part in separate tests as the one message would pass 1800 characters.
// BC versions: 27, 28, 29

codeunit 94742 "LT Y89 Region Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "BD Region Helper";
        Log: Codeunit "BD Region Log";

    [TryFunction]
    local procedure TrySaveAsXml(ReportId: Integer; var Xml: Text)
    begin
        Xml := Helper.SaveAsXml(ReportId);
    end;

    local procedure Dataset(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Xml: Text;
    begin
        ClearLastError();
        if TrySaveAsXml(ReportId, Xml) then begin
            Observer.Observe('header', Helper.HeaderFacts(Xml));
            Observer.Observe('columns', Helper.Columns(Xml));
        end else
            Observer.ObserveError('saveas');
        Observer.Observe('log', Log.Take());
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId, false);
    end;

    local procedure RunWay(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure SetterDataset(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        Dataset(Observer, Report::"BD Region Setter");
        Log.SetCulture('', false, 0);
    end;

    local procedure SetterRun(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region Setter Proc"));
        Log.SetCulture('', false, 0);
    end;

    [Test]
    procedure Y89_Old_Property_Gb()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region Gb");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Property_Dk()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region Dk");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Property_Nl()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region Nl");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Property_Es()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region Es");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Property_Se()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region Se");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Property_No()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        Log.Take();
        Dataset(Observer, Report::"BD Region No");
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_EnGB_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterDataset(Observer, 'en-GB', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_EnGB_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterRun(Observer, 'en-GB', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_NlNL_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterDataset(Observer, 'nl-NL', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_NlNL_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterRun(Observer, 'nl-NL', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_SvSE_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterDataset(Observer, 'sv-SE', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_SvSE_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterRun(Observer, 'sv-SE', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_DaDK_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterDataset(Observer, 'da-DK', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Old_Setter_DaDK_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if not BC29PLUS
        SetterRun(Observer, 'da-DK', true, 0);
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Y89_Lang_DaDK_1030_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'da-DK', true, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_DaDK_1030_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'da-DK', true, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_NlNL_1043_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'nl-NL', true, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_NlNL_1043_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'nl-NL', true, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_EsES_1034_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'es-ES', true, 1034);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_EsES_1034_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'es-ES', true, 1034);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_SvSE_1053_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'sv-SE', true, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_SvSE_1053_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'sv-SE', true, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_NbNO_1044_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'nb-NO', true, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_NbNO_1044_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'nb-NO', true, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_EnGB_2057_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-GB', true, 2057);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_EnGB_2057_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-GB', true, 2057);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_DeAT_3079_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'de-AT', true, 3079);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_DeAT_3079_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'de-AT', true, 3079);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_FrCH_4108_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'fr-CH', true, 4108);
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Lang_FrCH_4108_R()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'fr-CH', true, 4108);
        Observer.Finish();
    end;
}
