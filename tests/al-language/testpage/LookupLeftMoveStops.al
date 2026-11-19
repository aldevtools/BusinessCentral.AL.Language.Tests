// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75650 75651, pages 75652 75653 75654, log codeunit 75655, test codeunit 75656
// local object: a copy of the testpage/Y15LookupThreeFieldLink.al host (91714) whose OnAfterGetCurrRecord can be told to raise once
// Probe (al-runner 8503): testpage/Y15LookupThreeFieldLink.al Y80_Y15_Host_* pins the host's move as the first call after
//   TestField.Lookup: the move runs OnAfterGetCurrRecord for the new row, then the refresh of the OnValidate's CurrPage.Update(false)
//   runs it again (Next: 'agcr R2;agcr R2'). Here the move stops in between: the host's OnAfterGetCurrRecord raises on its first call
//   after the Lookup (the move's own read) or on its second (the refresh's read). The move runs inside asserterror; the Lookup's write
//   is committed first so the rollback keeps it. Then the next call: a second host Next, a TestPart Next, Close, or a second Lookup.
// Observed: the error, the trigger log of each step (lookup, validate X, agcr X), the values after it (ResourceNo | host row | part row |
//   part group) and the stored setting.
// Facts: (filled from the observation)
// BC versions: 27, 28, 29

table 75650 "LLM Setting"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Resource No."; Code[20]) { DataClassification = SystemMetadata; }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 75651 "LLM Resource"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LLM Resource List";

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = SystemMetadata; }
        field(2; "Group Code"; Code[20]) { DataClassification = SystemMetadata; }
        field(3; "Region Code"; Code[20]) { DataClassification = SystemMetadata; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 75652 "LLM Resource List"
{
    PageType = List;
    SourceTable = "LLM Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }
}

page 75653 "LLM Resource Part"
{
    PageType = ListPart;
    SourceTable = "LLM Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }
}

page 75654 "LLM Three Link Schedule"
{
    PageType = List;
    SourceTable = "LLM Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LLM Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LLM Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Resources; "LLM Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr ' + Rec."No.");
        Log.MaybeFail(Rec."No.");
    end;

    var
        Setting: Record "LLM Setting";
        Log: Codeunit "LLM Log";
}

codeunit 75655 "LLM Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        FailAt: Integer;
        Calls: Integer;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    // The Nth OnAfterGetCurrRecord from now raises once; 0 disarms.
    procedure Arm(N: Integer)
    begin
        FailAt := N;
        Calls := 0;
    end;

    procedure MaybeFail(No: Code[20])
    begin
        if FailAt = 0 then
            exit;
        Calls += 1;
        if Calls = FailAt then begin
            FailAt := 0;
            Error('LLM agcr failed on %1', No);
        end;
    end;
}

codeunit 75656 "LLM Lookup Move Stops"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LLM Log";
        PickCount: Integer;

    local procedure Setup()
    var
        Setting: Record "LLM Setting";
        Resource: Record "LLM Resource";
    begin
        Log.Arm(0);
        Log.Take();
        Setting.DeleteAll();
        Resource.DeleteAll();
        InsertResource(Resource, 'R1', 'G1');
        InsertResource(Resource, 'R2', 'G1');
        InsertResource(Resource, 'R3', 'G2');
        Commit();
        PickCount := 0;
        ClearLastError();
    end;

    local procedure InsertResource(var Resource: Record "LLM Resource"; ResourceNo: Code[20]; GroupCode: Code[20])
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource."Group Code" := GroupCode;
        Resource.Insert();
    end;

    local procedure Snap(var Schedule: TestPage "LLM Three Link Schedule"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value());
    end;

    local procedure StoredSetting(): Text
    var
        Setting: Record "LLM Setting";
    begin
        if not Setting.Get() then
            exit('<none>');
        exit(Setting."Resource No.");
    end;

    // Opens the host, runs the Lookup that picks R2, commits its write and arms the failure.
    local procedure OpenAndLookup(var Schedule: TestPage "LLM Three Link Schedule"; FailAt: Integer; MoveLast: Boolean)
    begin
        Schedule.OpenEdit();
        if MoveLast then
            Schedule.Last();
        Observer.Observe('open log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Commit();
        Log.Arm(FailAt);
    end;

    local procedure SayError(Name: Text)
    var
        Txt: Text;
    begin
        Txt := GetLastErrorText();
        if Txt = 'NO_ERROR' then
            Txt := 'ok';
        ClearLastError();
        Observer.Observe(Name, Txt);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure FailingNext(var Schedule: TestPage "LLM Three Link Schedule")
    begin
        asserterror begin
            Schedule.Next();
            Error('NO_ERROR');
        end;
        SayError('move');
    end;

    local procedure AfterMove(var Schedule: TestPage "LLM Three Link Schedule")
    begin
        Observer.Observe('after move', Snap(Schedule));
        Observer.Observe('read log', Log.Take());
        Observer.Observe('second move', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('second move log', Log.Take());
        Observer.Observe('after second move', Snap(Schedule));
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredSetting());
    end;

    // The move's own OnAfterGetCurrRecord (R2) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_MoveReadFails_ThenNext()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false);
        FailingNext(Schedule);
        AfterMove(Schedule);
        Observer.Finish();
    end;

    // The second OnAfterGetCurrRecord after the Lookup (the refresh's read in Y80) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_RefreshReadFails_ThenNext()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 2, false);
        FailingNext(Schedule);
        AfterMove(Schedule);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_MoveReadFails_ThenPartNext()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false);
        FailingNext(Schedule);
        Observer.Observe('part move', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part move log', Log.Take());
        Observer.Observe('after part move', Snap(Schedule));
        Observer.Observe('read log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_MoveReadFails_ThenClose()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false);
        FailingNext(Schedule);
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredSetting());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PickSecondThenThird')]
    procedure Next_MoveReadFails_ThenLookup()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false);
        FailingNext(Schedule);
        Schedule.ResourceNo.Lookup();
        Observer.Observe('second lookup log', Log.Take());
        Observer.Observe('after second lookup', Snap(Schedule));
        Observer.Observe('read log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    // From the last row: First's own read (R1) raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure First_MoveReadFails_ThenNext()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, true);
        asserterror begin
            Schedule.First();
            Error('NO_ERROR');
        end;
        SayError('move');
        AfterMove(Schedule);
        Observer.Finish();
    end;

    // Last reads the new-row line first in Y80 ('agcr ;agcr R3;agcr R3'): that first read raises.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Last_FirstReadFails_ThenFirst()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        OpenAndLookup(Schedule, 1, false);
        asserterror begin
            Schedule.Last();
            Error('NO_ERROR');
        end;
        SayError('move');
        Observer.Observe('after move', Snap(Schedule));
        Observer.Observe('read log', Log.Take());
        Observer.Observe('second move', Format(Schedule.First(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('second move log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LLM Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickSecondThenThird(var ResourceList: TestPage "LLM Resource List")
    begin
        PickCount += 1;
        if PickCount = 1 then
            ResourceList.GoToKey('R2')
        else
            ResourceList.GoToKey('R3');
        ResourceList.OK().Invoke();
    end;
}
