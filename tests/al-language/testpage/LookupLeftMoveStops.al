// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75650 75651, pages 75652 75653 75654, log codeunit 75655, test codeunit 75656 "LLM Lookup Move Stops"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LLM Log";
        Got: Text;

    local procedure Setup()
    var
        Setting: Record "LLM Setting";
        Resource: Record "LLM Resource";
    begin
        Observer.Discard();
        Log.Arm(0);
        Log.Take();
        Setting.DeleteAll();
        Resource.DeleteAll();
        InsertResource(Resource, 'R1', 'G1');
        InsertResource(Resource, 'R2', 'G1');
        InsertResource(Resource, 'R3', 'G2');
        Commit();
        ClearLastError();
    end;

    local procedure InsertResource(var Resource: Record "LLM Resource"; ResourceNo: Code[20]; GroupCode: Code[20])
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource."Group Code" := GroupCode;
        Resource.Name := LowerCase(ResourceNo);
        Resource.Insert();
    end;

    local procedure Snap(var Schedule: TestPage "LLM Three Link Schedule"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.Name.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value());
    end;

    local procedure Stored(): Text
    var
        Setting: Record "LLM Setting";
        Resource: Record "LLM Resource";
        Result: Text;
    begin
        if Setting.Get() then
            Result := 'setting=' + Setting."Resource No."
        else
            Result := 'setting=<none>';
        if Resource.FindSet() then
            repeat
                Result += ' ' + Resource."No." + '=' + Resource.Name;
            until Resource.Next() = 0;
        exit(Result);
    end;

    // Opens the host (on the last row when MoveLast), types Name on the row when TypedName is set, runs the Lookup that picks R2,
    // commits its write and arms the failure of the FailAt-th OnAfterGetCurrRecord from now.
    local procedure OpenAndLookup(var Schedule: TestPage "LLM Three Link Schedule"; FailAt: Integer; MoveLast: Boolean; TypedName: Text)
    begin
        Schedule.OpenEdit();
        if MoveLast then
            Schedule.Last();
        if TypedName <> '' then
            Schedule.Name.SetValue(TypedName);
        Observer.Observe('open log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Commit();
        Log.Arm(FailAt);
    end;

    // 'ok' and what the block put in Got, or the error text; then the log.
    local procedure SayEnd(Name: Text)
    var
        Txt: Text;
    begin
        Txt := GetLastErrorText();
        if Txt = 'NO_ERROR' then
            Txt := 'ok ' + Got;
        ClearLastError();
        Got := '';
        Observer.Observe(Name, Txt);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure TryMove(var Schedule: TestPage "LLM Three Link Schedule"; Which: Text; Name: Text)
    begin
        Got := '';
        asserterror begin
            case Which of
                'Next':
                    Got := Format(Schedule.Next(), 0, 9);
                'First':
                    Got := Format(Schedule.First(), 0, 9);
                'Last':
                    Got := Format(Schedule.Last(), 0, 9);
                'PartNext':
                    Got := Format(Schedule.Resources.Next(), 0, 9);
            end;
            Error('NO_ERROR');
        end;
        SayEnd(Name);
    end;

    local procedure TrySnap(var Schedule: TestPage "LLM Three Link Schedule"; Name: Text)
    begin
        Got := '';
        asserterror begin
            Got := Snap(Schedule);
            Error('NO_ERROR');
        end;
        SayEnd(Name);
    end;

    local procedure TryClose(var Schedule: TestPage "LLM Three Link Schedule"; Name: Text)
    begin
        asserterror begin
            Schedule.Close();
            Error('NO_ERROR');
        end;
        SayEnd(Name);
    end;

    // After the stopped move: the page is read and closed, then the same variable opens again and moves.
    local procedure AfterStop(var Schedule: TestPage "LLM Three Link Schedule")
    begin
        TrySnap(Schedule, 'read');
        TryClose(Schedule, 'close');
        Schedule.OpenEdit();
        Observer.Observe('reopen log', Log.Take());
        TrySnap(Schedule, 'reopened read');
        TryMove(Schedule, 'Next', 'reopened next');
        TryClose(Schedule, 'reopened close');
        Observer.Observe('stored', Stored());
    end;

    // The move's own OnAfterGetCurrRecord (R2) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_MoveReadFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false, '');
        TryMove(Schedule, 'Next', 'move');
        AfterStop(Schedule);
        Observer.Finish();
    end;

    // The second OnAfterGetCurrRecord after the Lookup (the refresh's read in Y80) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_RefreshReadFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 2, false, '');
        TryMove(Schedule, 'Next', 'move');
        AfterStop(Schedule);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_MoveReadFails_ThenPartNext()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false, '');
        TryMove(Schedule, 'Next', 'move');
        TryMove(Schedule, 'PartNext', 'part move');
        TryClose(Schedule, 'close');
        Observer.Finish();
    end;

    // From the last row: First's own read (R1) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure First_MoveReadFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, true, '');
        TryMove(Schedule, 'First', 'move');
        AfterStop(Schedule);
        Observer.Finish();
    end;

    // Last reads the new-row line first in Y80 ('agcr ;agcr R3;agcr R3'): that first read raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Last_FirstReadFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false, '');
        TryMove(Schedule, 'Last', 'move');
        AfterStop(Schedule);
        Observer.Finish();
    end;

    // The host row was typed before the Lookup; the move's save fails in the table's OnModify.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_SaveFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 0, false, 'FAILMOD');
        TryMove(Schedule, 'Next', 'move');
        TrySnap(Schedule, 'read');
        TryMove(Schedule, 'Next', 'second move');
        TrySnap(Schedule, 'second read');
        TryClose(Schedule, 'close');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    // The host row was typed before the Lookup; OnModifyRecord returns false on the move's save.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_SaveDenied()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 0, false, 'DENY');
        TryMove(Schedule, 'Next', 'move');
        TrySnap(Schedule, 'read');
        TryMove(Schedule, 'Next', 'second move');
        TrySnap(Schedule, 'second read');
        TryClose(Schedule, 'close');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    // The contrast: the row typed with a value that saves.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_SaveWorks()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 0, false, 'typed');
        TryMove(Schedule, 'Next', 'move');
        TrySnap(Schedule, 'read');
        TryMove(Schedule, 'Next', 'second move');
        TryClose(Schedule, 'close');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LLM Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;
}
