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
        field(4; Name; Text[30]) { DataClassification = SystemMetadata; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LLM Log";
    begin
        Log.Add('T-mod ' + Rec."No." + ' ' + Rec.Name);
        if Rec.Name = 'FAILMOD' then
            Error('LLM table modify refused');
    end;
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
                field(Name; Rec.Name) { ApplicationArea = All; }
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

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M ' + Rec."No." + ' ' + Rec.Name);
        exit(Rec.Name <> 'DENY');
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

    // The host row was typed before the Lookup; the save that the Lookup runs fails in the table's OnModify.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Lookup_SaveFails()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.Name.SetValue('FAILMOD');
        Observer.Observe('open log', Log.Take());
        asserterror begin
            Schedule.ResourceNo.Lookup();
            Error('NO_ERROR');
        end;
        SayEnd('lookup');
        TrySnap(Schedule, 'read');
        TryMove(Schedule, 'Next', 'move');
        TryClose(Schedule, 'close');
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    // The host stands on the new-row line: the move after the Lookup finds no row.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Next_FindsNoRow()
    var
        Schedule: TestPage "LLM Three Link Schedule";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.Last();
        Schedule.Next();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('row', Schedule."No.".Value());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Commit();
        TryMove(Schedule, 'Next', 'move');
        TrySnap(Schedule, 'read');
        TryMove(Schedule, 'First', 'second move');
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
