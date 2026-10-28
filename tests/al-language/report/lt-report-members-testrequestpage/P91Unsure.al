// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against BC 29 (observation only; the literals are measured later). Tag P91 (GitHub issue 91).
// BC versions: 29
// Fixtures used: tables and helper of P91Fix.al; self-contained reports 71601, 71602 and codeunit 71613; writer SQ: SqSubstituteObjects.al (reports 89587, 89588, codeunit 89586)
// Facts: members whose exact signature is unsure (the lead drops what does not compile): Report.GetSubstituteReportId, Report.ValidateAndPrepareLayout,
// CurrReport.NewPagePerRecord, CurrReport.PaperSource, and the RequestPage members of a report variable (Activate, Close, Editable, LookupMode, ObjectId, SaveRecord, SetSelectionFilter) outside a run

report 71601 "LT P91 Props"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
        }
    }

    procedure Probe(): Text
    begin
        exit(Format(CurrReport.NewPagePerRecord));
    end;
}

report 71602 "LT P91 ReqMembers"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        TextVal: Text[20];
}

codeunit 71613 "LT P91 Unsure Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TrySubstitute(Id: Integer; var R: Text)
    begin
        R := Format(Report.GetSubstituteReportId(Id));
    end;

    local procedure SubstituteOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TrySubstitute(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetSubstituteReportId_Values()
    begin
        Observer.Observe('own', Format(SubstituteOf(Report::"LT P91 Props") = Format(Report::"LT P91 Props")));
        Observer.Observe('zero', SubstituteOf(0));
        Observer.Observe('unknown', SubstituteOf(71999));
        Observer.Expect('own', 'Yes');
        Observer.Expect('zero', '0');
        Observer.Expect('unknown', '71999');
        Observer.Verify();
    end;

    [Test]
    procedure CurrReport_NewPagePerRecord_PaperSource()
    var
        Rpt: Report "LT P91 Props";
    begin
        Observer.Observe('probe', Rpt.Probe());
        Observer.Expect('probe', 'No');
        Observer.Verify();
    end;

    // Writer SQ (NP lane 2026-10-28): GetSubstituteReportId with a bound manual subscriber of SubstituteReport and of OnAfterSubstituteReport (SqSubstituteObjects.al).
    local procedure SqSubstitute(Change: Text; Bind: Boolean; var Subs: Codeunit "LT SQ Subst Subscribers"): Text
    begin
        Subs.SetChange(Change);
        if Bind then
            BindSubscription(Subs);
        ClearLastError();
        exit(SubstituteOf(Report::"LT SQ Subst Source"));
    end;

    [Test]
    procedure Sq_GetSubstituteReportId_LoggingSubscriber()
    var
        Obs: Codeunit "Probe Observer";
        Subs: Codeunit "LT SQ Subst Subscribers";
    begin
        Obs.Observe('result', SqSubstitute('', true, Subs));
        Obs.Observe('platform log', Subs.Platform());
        Obs.Observe('after log', Subs.After());
        Obs.Finish();
    end;

    [Test]
    procedure Sq_GetSubstituteReportId_PlatformSubscriberChanges()
    var
        Obs: Codeunit "Probe Observer";
        Subs: Codeunit "LT SQ Subst Subscribers";
    begin
        Obs.Observe('result', SqSubstitute('platform', true, Subs));
        Obs.Observe('platform log', Subs.Platform());
        Obs.Observe('after log', Subs.After());
        Obs.Finish();
    end;

    [Test]
    procedure Sq_GetSubstituteReportId_OnAfterSubscriberChanges()
    var
        Obs: Codeunit "Probe Observer";
        Subs: Codeunit "LT SQ Subst Subscribers";
    begin
        Obs.Observe('result', SqSubstitute('after', true, Subs));
        Obs.Observe('platform log', Subs.Platform());
        Obs.Observe('after log', Subs.After());
        Obs.Finish();
    end;

    [Test]
    procedure Sq_GetSubstituteReportId_Unbound()
    var
        Obs: Codeunit "Probe Observer";
        Subs: Codeunit "LT SQ Subst Subscribers";
    begin
        Obs.Observe('result', SqSubstitute('platform', false, Subs));
        Obs.Observe('platform log', Subs.Platform());
        Obs.Finish();
    end;
}
