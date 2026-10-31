// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91710 - 91716 (writer Y15)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6466, follow-up to 6290 (two-field link: pages/lt-wb-6290/WbLookupListPartTests.al). A List page over
//   resources (No., Group Code, Region Code) has a header field ResourceNo bound to a global setting record. Its OnLookup runs the
//   resource list modally and returns the picked No. through Text; its OnValidate modifies the setting and calls CurrPage.Update(false).
//   A ListPart over the same table is linked with SubPageLink on No., Group Code and Region Code. The test calls
//   TestField.Lookup with a handler that picks R2 (or cancels) and reads the header field, the list row and the part.
//   The page logs OnValidate of ResourceNo and OnAfterGetCurrRecord.
// Result (SaaS BC 29): as with two link fields, Lookup shows the picked R2 in ResourceNo, OnValidate runs once with R2 and stores it;
//   the list row stays R1 and the part shows R1 only. Cancel runs only OnLookup and leaves the value blank.
// Source: al-runner issue 6466 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 91710 "LT Y15 Lookup Setting"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Resource No."; Code[20]) { }
    }
    keys
    {
        key(PK; "Primary Key") { }
    }
}

table 91711 "LT Y15 Lookup Resource"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y15 Lookup Resource List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Group Code"; Code[20]) { }
        field(3; "Region Code"; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { }
    }
}

page 91712 "LT Y15 Lookup Resource List"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
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

page 91713 "LT Y15 Lookup Resource Part"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
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

page 91714 "LT Y15 Three Link Schedule"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
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
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
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
            part(Resources; "LT Y15 Lookup Resource Part")
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
    end;

    var
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

codeunit 91715 "LT Y15 Lookup Log"
{
    SingleInstance = true;

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

    var
        Entries: Text;
}

codeunit 91716 "LT Y15 Lookup Three Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y15 Lookup Log";
        PickCount: Integer;

    // The reporter's test, with the neighbours read after the lookup.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y15_ThreeLink_LookupShowsPickedResource()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y15 Three Link Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.Resources."No.".Value());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('row', Schedule."No.".Value());
        Observer.Observe('part', Schedule.Resources."No.".Value() + '/' + Schedule.Resources."Group Code".Value());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Schedule.Close();
        Observer.Expect('open log', 'agcr R1');
        Observer.Expect('before', '/R1/R1');
        Observer.Expect('lookup log', 'lookup;validate R2');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('row', 'R1');
        Observer.Expect('part', 'R1/G1');
        Observer.Expect('part next', 'false');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Region codes set on every row: the part follows the current list row on all three fields.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y15_ThreeLink_RegionsSetPartFollowsRow()
    var
        Schedule: TestPage "LT Y15 Three Link Schedule";
    begin
        Setup(true);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('part', Schedule.Resources."No.".Value());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9) + '/' + Schedule."No.".Value() + '/' + Schedule.Resources."No.".Value());
        Observer.Observe('resource no after next', Schedule.ResourceNo.Value());
        Observer.Observe('last', Format(Schedule.Last(), 0, 9) + '/' + Schedule."No.".Value() + '/' + Schedule.Resources."No.".Value() + '/' + Format(Schedule.Resources.Next(), 0, 9));
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;validate R2');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('part', 'R1');
        Observer.Expect('next', 'true/R2/R2');
        Observer.Expect('resource no after next', 'R2');
        Observer.Expect('last', 'true/R3/R3/false');
        Observer.Verify();
    end;

    // The lookup page is cancelled: OnLookup returns false, nothing is validated.
    [Test]
    [HandlerFunctions('CancelLookup')]
    procedure Y15_ThreeLink_LookupCancelled()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y15 Three Link Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('part', Schedule.Resources."No.".Value());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup');
        Observer.Expect('resource no', '');
        Observer.Expect('part', 'R1');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    // Two lookups in a row: the second pick (R3) replaces the first.
    [Test]
    [HandlerFunctions('PickSecondThenThird')]
    procedure Y15_ThreeLink_LookupTwice()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y15 Three Link Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('first', Schedule.ResourceNo.Value());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('second', Schedule.ResourceNo.Value());
        Observer.Observe('log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Schedule.Close();
        Observer.Expect('first', 'R2');
        Observer.Expect('second', 'R3');
        Observer.Expect('log', 'lookup;validate R2;agcr R1;lookup;validate R3');
        Observer.Expect('stored', 'R3');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelLookup(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PickSecondThenThird(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        PickCount += 1;
        if PickCount = 1 then
            ResourceList.GoToKey('R2')
        else
            ResourceList.GoToKey('R3');
        ResourceList.OK().Invoke();
    end;

    local procedure Setup(WithRegions: Boolean)
    var
        Setting: Record "LT Y15 Lookup Setting";
        Resource: Record "LT Y15 Lookup Resource";
    begin
        Log.Take();
        Setting.DeleteAll();
        Resource.DeleteAll();
        InsertResource(Resource, 'R1', 'G1', WithRegions, 'E1');
        InsertResource(Resource, 'R2', 'G1', WithRegions, 'E1');
        InsertResource(Resource, 'R3', 'G2', WithRegions, 'E2');
    end;

    local procedure InsertResource(var Resource: Record "LT Y15 Lookup Resource"; ResourceNo: Code[20]; GroupCode: Code[20]; WithRegion: Boolean; RegionCode: Code[20])
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource."Group Code" := GroupCode;
        if WithRegion then
            Resource."Region Code" := RegionCode;
        Resource.Insert();
    end;
}
