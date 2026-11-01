// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained objects 92920, 92921
// Probe: gap cycle 5, spec G5-02 (writer Y48), the Feature Key part. Microsoft's Web Service Management tests run
//        `if not FeatureKey.Get('DisableSOAPwebservicesonMicrosoftUIpages') then begin Init; ...; Insert(); end` with an ID cased
//        differently from the listed row DisableSoapWebServicesOnMicrosoftUIPages (PFFeatureKeyColumns.al: listed on 27.x, 28.x and 29.0).
//        Observed: Get, SetRange and SetFilter with other casing; Insert of an unknown ID (with and without triggers) and of the listed ID;
//        Delete of a listed row; and, in the last test, whether an inserted row is still there in a later test.
//        Each write runs in a codeunit of its own (Codeunit.Run), so an error BC raises is observed and the test goes on.
// BC versions: 27, 28, 29

codeunit 92921 "LT Y48 FK Step"
{
    var
        Step: Text;
        KeyId: Text[50];
        Result: Text;

    procedure SetStep(NewStep: Text; NewKeyId: Text[50])
    begin
        Step := NewStep;
        KeyId := NewKeyId;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    var
        FeatureKey: Record "Feature Key";
    begin
        case Step of
            'insert', 'insert true':
                begin
                    FeatureKey.Init();
                    FeatureKey.ID := KeyId;
                    FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                    FeatureKey."Data Update Required" := false;
                    Result := Format(FeatureKey.Insert(Step = 'insert true'));
                end;
            'delete':
                begin
                    FeatureKey.Get(KeyId);
                    Result := Format(FeatureKey.Delete());
                end;
        end;
    end;
}

codeunit 92920 "LT Y48 Feature Key Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ListedTok: Label 'DisableSoapWebServicesOnMicrosoftUIPages', Locked = true;
        TestCasingTok: Label 'DisableSOAPwebservicesonMicrosoftUIpages', Locked = true;
        UnknownTok: Label 'LTProbeUnknownKey', Locked = true;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Step: Text; KeyId: Text[50])
    var
        StepCu: Codeunit "LT Y48 FK Step";
    begin
        StepCu.SetStep(Step, KeyId);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure GetText(KeyId: Text[50]): Text
    var
        FeatureKey: Record "Feature Key";
    begin
        if not FeatureKey.Get(KeyId) then
            exit('No');
        exit('Yes id=' + FeatureKey.ID + ' enabled=' + Format(FeatureKey.Enabled) + ' description empty=' + Format(FeatureKey.Description = ''));
    end;

    local procedure CountAll(): Integer
    var
        FeatureKey: Record "Feature Key";
    begin
        exit(FeatureKey.Count());
    end;

    local procedure CountOf(KeyId: Text): Text
    var
        FeatureKey: Record "Feature Key";
    begin
        FeatureKey.SetRange(ID, KeyId);
        exit(Format(FeatureKey.Count()) + ' isempty=' + Format(FeatureKey.IsEmpty()));
    end;

    [Test]
    procedure FK_Get_OtherCasing()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get listed', GetText(ListedTok));
        Observer.Observe('get test casing', GetText(TestCasingTok));
        Observer.Observe('get lower case', GetText('disablesoapwebservicesonmicrosoftuipages'));
        Observer.Observe('setrange test casing', CountOf(TestCasingTok));
        FeatureKey.SetFilter(ID, '@disablesoap*');
        Observer.Observe('setfilter @disablesoap*', Format(FeatureKey.Count()));
        FeatureKey.SetFilter(ID, 'disablesoap*');
        Observer.Observe('setfilter disablesoap*', Format(FeatureKey.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure FK_Insert_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        Before: Integer;
    begin
        Before := CountAll();
        Run(Observer, 'insert', 'insert', UnknownTok);
        Observer.Observe('count after - before', Format(CountAll() - Before));
        Observer.Observe('get', GetText(UnknownTok));
        Observer.Observe('setrange', CountOf(UnknownTok));
        Run(Observer, 'insert again', 'insert', UnknownTok);
        Run(Observer, 'delete', 'delete', UnknownTok);
        Observer.Observe('get after delete', GetText(UnknownTok));
        Observer.Finish();
    end;

    [Test]
    procedure FK_Insert_UnknownId_RunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Before: Integer;
    begin
        Before := CountAll();
        Run(Observer, 'insert(true)', 'insert true', 'LTProbeUnknownKey2');
        Observer.Observe('count after - before', Format(CountAll() - Before));
        Observer.Observe('get', GetText('LTProbeUnknownKey2'));
        Observer.Finish();
    end;

    [Test]
    procedure FK_Insert_ListedId()
    var
        Observer: Codeunit "Probe Observer";
        Before: Integer;
    begin
        Before := CountAll();
        Run(Observer, 'insert listed casing', 'insert', ListedTok);
        Observer.Observe('count after listed - before', Format(CountAll() - Before));
        Run(Observer, 'insert test casing', 'insert', TestCasingTok);
        Observer.Observe('count after test casing - before', Format(CountAll() - Before));
        Observer.Observe('get test casing', GetText(TestCasingTok));
        Observer.Finish();
    end;

    [Test]
    procedure FK_Delete_ListedRow()
    var
        Observer: Codeunit "Probe Observer";
        Before: Integer;
    begin
        Before := CountAll();
        Run(Observer, 'delete listed', 'delete', ListedTok);
        Observer.Observe('count after - before', Format(CountAll() - Before));
        Observer.Observe('get listed', GetText(ListedTok));
        Observer.Finish();
    end;

    // Runs after the tests above (declaration order): is a row an earlier test inserted still there?
    [Test]
    procedure FK_Zz_InsertedRowsInALaterTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get LTProbeUnknownKey', GetText(UnknownTok));
        Observer.Observe('get LTProbeUnknownKey2', GetText('LTProbeUnknownKey2'));
        Observer.Observe('get listed', GetText(ListedTok));
        Observer.Finish();
    end;
}
