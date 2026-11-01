// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91710 - 91716 (writer Y15), 92220 - 92224 (writer Y26)
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
// Y26 (al-runner 6519, follow-up to 6466): objects 92220 - 92224 add a ListPart that logs OnAfterGetRecord, OnAfterGetCurrRecord and
//   a function control, and four hosts (two- or three-field link, with or without OnAfterGetCurrRecord) with expression controls: a
//   global CurrentNo (set in OnAfterGetCurrRecord, or in OnAfterGetRecord without it) and a function call GetHostNo(), both showing No. + '/' + the stored resource. The Y26 tests
//   read every control one at a time after TestField.Lookup and log which triggers each read runs.
// Result Y26 (SaaS BC 29, the same for all four hosts): Lookup runs OnLookup, the host function control, OnValidate, the host function
//   control again; no OnAfterGetRecord or OnAfterGetCurrRecord on the host or the part. Reading controls runs nothing. After it the host
//   function control shows the picked value ('R1/R2'); the globals (CurrentNo, HeaderCurrent) and the part's controls keep the values of
//   before ('R1/'). The refresh of CurrPage.Update(false) runs at the start of the next Lookup (host rows and OnAfterGetCurrRecord, not
//   the part); Next refreshes host and part.
// Y54 (al-runner 6519): the Y54 tests call TestPart Next, First, Previous or Last after TestField.Lookup, while the refresh of
//   CurrPage.Update(false) is still pending, on the Y26 hosts and on the Y15 host. TestPage and TestPart have no GetRecord method
//   (must-not-compile cases 2570 and 2571).
// Result Y54 (BC 28.5 on Linux and on Windows; the CI legs check 27.5, 28.5 and 29.0): the first TestPart call after the lookup runs
//   the pending refresh, with the same triggers as opening the page: the host rows (OnAfterGetRecord, function controls,
//   OnAfterGetCurrRecord), then the part (OnAfterGetRecord, OnAfterGetCurrRecord, function control), then the host's current row
//   again. After it every control shows the picked value: globals, function controls and the part's controls ('R1/R2'). The part
//   holds one row (R1): Next false, First true, Previous false, Last true. A second part call runs no trigger. The refresh is used up:
//   a later Lookup starts with no refresh. A cancelled lookup leaves nothing pending: the part's Next runs no trigger and the values
//   stay as before. The same with a two-field link; without host OnAfterGetCurrRecord the refresh has no h-agcr entries.

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

    // Y26 (al-runner 6519): three-field link, OnAfterGetCurrRecord on the host sets the expression control CurrentNo.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y26_ThreeLinkCurr_LookupRefresh()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Y26: the same with a two-field link.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y26_TwoLinkCurr_LookupRefresh()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 2Link Curr Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Y26: three-field link, no OnAfterGetCurrRecord on the host (CurrentNo set in OnAfterGetRecord).
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y26_ThreeLinkPlain_LookupRefresh()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 3Link Plain Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-agr R2;h-fn R2');
        Observer.Expect('after next', 'R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Y26: two-field link, no OnAfterGetCurrRecord on the host.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y26_TwoLinkPlain_LookupRefresh()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 2Link Plain Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-agr R2;h-fn R2');
        Observer.Expect('after next', 'R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Y26: three-field link with region codes set on every row.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y26_ThreeLinkCurr_RegionsSet()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(true);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    // Y26: two lookups in a row (R2, then R3).
    [Test]
    [HandlerFunctions('PickSecondThenThird')]
    procedure Y26_ThreeLinkCurr_LookupTwice()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('second lookup log', Log.Take());
        Observer.Observe('second', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('second log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Schedule.ResourceNo.Value() + '/' + Schedule.HeaderCurrent.Value() + '/' + Schedule."No.".Value() + '/' + Schedule.CurrentNo.Value() + '/' + Schedule.HostFn.Value() + '/' + Schedule.Resources."No.".Value() + '/' + Schedule.Resources.PartCurrent.Value() + '/' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('before', '/R1//R1/R1//R1//R1/R1//R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('header current', 'R1/');
        Observer.Expect('header current log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('current no log', '');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host fn log', '');
        Observer.Expect('part no', 'R1');
        Observer.Expect('part no log', '');
        Observer.Expect('part current', 'R1/');
        Observer.Expect('part current log', '');
        Observer.Expect('part fn', 'R1/');
        Observer.Expect('part fn log', '');
        Observer.Expect('second lookup log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;lookup;h-fn R1;validate R3;h-fn R1');
        Observer.Expect('second', 'R3/R1/R2/R1/R1/R2/R1/R3/R1/R1//R1/');
        Observer.Expect('second log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R2;h-agr R1;h-fn R1;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R3/R2/R3/R2/R2/R3/R2/R3/R2/R2/R3/R2/R3');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R3');
        Observer.Verify();
    end;

    // Y54 (al-runner 6519): what TestPart.Next, First, Previous and Last do after TestField.Lookup on the three-field host with
    // OnAfterGetCurrRecord, while the refresh of CurrPage.Update(false) is still pending: the triggers each call runs and the values after.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkCurr_PartNextAfterLookup()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Snap3C(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('part next again', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next again log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Snap3C(Schedule));
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part next', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part next log', '');
        Observer.Expect('part next again', 'false');
        Observer.Expect('part next again log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R2|G1|R2/R2|R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkCurr_PartFirstAfterLookup()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part first', Format(Schedule.Resources.First(), 0, 9));
        Observer.Observe('part first log', Log.Take());
        Observer.Observe('after part first', Snap3C(Schedule));
        Observer.Observe('after part first log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Snap3C(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part first', 'true');
        Observer.Expect('part first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part first', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part first log', '');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', '');
        Observer.Expect('after part next', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part next log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkCurr_PartPreviousAfterLookup()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part previous', Format(Schedule.Resources.Previous(), 0, 9));
        Observer.Observe('part previous log', Log.Take());
        Observer.Observe('after part previous', Snap3C(Schedule));
        Observer.Observe('after part previous log', Log.Take());
        Observer.Observe('part last', Format(Schedule.Resources.Last(), 0, 9));
        Observer.Observe('part last log', Log.Take());
        Observer.Observe('after part last', Snap3C(Schedule));
        Observer.Observe('after part last log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part previous', 'false');
        Observer.Expect('part previous log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part previous', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part previous log', '');
        Observer.Expect('part last', 'true');
        Observer.Expect('part last log', '');
        Observer.Expect('after part last', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part last log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkCurr_PartLastAfterLookup()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part last', Format(Schedule.Resources.Last(), 0, 9));
        Observer.Observe('part last log', Log.Take());
        Observer.Observe('after part last', Snap3C(Schedule));
        Observer.Observe('after part last log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part last', 'true');
        Observer.Expect('part last log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part last', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part last log', '');
        Observer.Verify();
    end;

    // Y54: region codes set on every row (the part shows the same row through all three fields).
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkCurr_PartNextRegionsSet()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(true);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Snap3C(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', Snap3C(Schedule));
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part next', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part next log', '');
        Observer.Expect('next', 'true');
        Observer.Expect('next log', 'h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;p-agr R2;p-fn R2;p-agr R2;p-fn R2;p-agcr R2;p-fn R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R2|G1|R2/R2|R2/R2');
        Observer.Verify();
    end;

    // Y54: the lookup is cancelled (no OnValidate, no CurrPage.Update): the part's Next.
    [Test]
    [HandlerFunctions('CancelLookup')]
    procedure Y54_ThreeLinkCurr_PartNextAfterCancel()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Snap3C(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', '');
        Observer.Expect('after part next', '|R1/|R1|R1/|R1/|R1|G1|R1/|R1/');
        Observer.Expect('after part next log', '');
        Observer.Verify();
    end;

    // Y54: the part's Next between two lookups: does it run the pending refresh?
    [Test]
    [HandlerFunctions('PickSecondThenThird')]
    procedure Y54_ThreeLinkCurr_PartNextThenLookup()
    var
        Schedule: TestPage "LT Y26 3Link Curr Schedule";
    begin
        Setup(false);
        PickCount := 0;
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('second lookup log', Log.Take());
        Observer.Observe('after second', Snap3C(Schedule));
        Observer.Observe('after second log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('second lookup log', 'lookup;h-fn R1;validate R3;h-fn R1');
        Observer.Expect('after second', 'R3|R1/R2|R1|R1/R2|R1/R3|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after second log', '');
        Observer.Verify();
    end;

    // Y54: the part's Next on the other Y26 hosts (two-field link with OnAfterGetCurrRecord, three-field link without it).
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_TwoLinkCurr_PartNextAfterLookup()
    var
        Schedule: TestPage "LT Y26 2Link Curr Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('part first', Format(Schedule.Resources.First(), 0, 9));
        Observer.Observe('part first log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1');
        Observer.Expect('after part next', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part next log', '');
        Observer.Expect('part first', 'true');
        Observer.Expect('part first log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_ThreeLinkPlain_PartNextAfterLookup()
    var
        Schedule: TestPage "LT Y26 3Link Plain Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('part first', Format(Schedule.Resources.First(), 0, 9));
        Observer.Observe('part first log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('part next', 'false');
        Observer.Expect('part next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1');
        Observer.Expect('after part next', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|G1|R1/R2|R1/R2');
        Observer.Expect('after part next log', '');
        Observer.Expect('part first', 'true');
        Observer.Expect('part first log', '');
        Observer.Verify();
    end;

    // Y54: the Y15 host (OnAfterGetCurrRecord logs only, part without triggers): the part's whole walk after the lookup.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y54_Y15Host_PartWalkAfterLookup()
    var
        Schedule: TestPage "LT Y15 Three Link Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value());
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('part first', Format(Schedule.Resources.First(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('part previous', Format(Schedule.Resources.Previous(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('part last', Format(Schedule.Resources.Last(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('part walk log', Log.Take());
        Observer.Observe('host', Schedule.ResourceNo.Value() + '|' + Schedule."No.".Value());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.ResourceNo.Value());
        Observer.Observe('next log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;validate R2');
        Observer.Expect('part next', 'false|R1|G1');
        Observer.Expect('part next log', 'agcr R1');
        Observer.Expect('part first', 'true|R1');
        Observer.Expect('part previous', 'false|R1');
        Observer.Expect('part last', 'true|R1');
        Observer.Expect('part walk log', '');
        Observer.Expect('host', 'R2|R1');
        Observer.Expect('next', 'true|R2|R2|R2');
        Observer.Expect('next log', 'agcr R2');
        Observer.Verify();
    end;

    // Y63 (al-runner 6639, follow-up to 6519): the Y26 three-field host with a second, unlinked ListPart (OtherResources,
    // placed before the linked part, as in the reporter's page). Every control is read one at a time after the lookup.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_TwoPart_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapTP(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('part', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('other part', Schedule.OtherResources."No.".Value() + '|' + Schedule.OtherResources.OtherCurrent.Value() + '|' + Schedule.OtherResources.OtherFn.Value());
        Observer.Observe('read log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Finish();
    end;

    // Y63: the linked part moves first after the lookup, then the other part, then the host.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_TwoPart_LinkedPartNextFirst()
    var
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', SnapTP(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('other next', Format(Schedule.OtherResources.Next(), 0, 9) + '|' + Schedule.OtherResources."No.".Value());
        Observer.Observe('other next log', Log.Take());
        Observer.Observe('after other next', SnapTP(Schedule));
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', SnapTP(Schedule));
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    // Y63: the other (unlinked) part moves first after the lookup, then the linked part.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_TwoPart_OtherPartNextFirst()
    var
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('other next', Format(Schedule.OtherResources.Next(), 0, 9) + '|' + Schedule.OtherResources."No.".Value());
        Observer.Observe('other next log', Log.Take());
        Observer.Observe('after other next', SnapTP(Schedule));
        Observer.Observe('after other next log', Log.Take());
        Observer.Observe('other next again', Format(Schedule.OtherResources.Next(), 0, 9) + '|' + Schedule.OtherResources."No.".Value());
        Observer.Observe('other next again log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', SnapTP(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    // Y63: a cancelled lookup, then both parts move.
    [Test]
    [HandlerFunctions('CancelLookup')]
    procedure Y63_TwoPart_PartsNextAfterCancel()
    var
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('other next', Format(Schedule.OtherResources.Next(), 0, 9) + '|' + Schedule.OtherResources."No.".Value());
        Observer.Observe('other next log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after', SnapTP(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: the second ListPart placed after the linked part.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_PartThenOther_LinkedPartNextFirst()
    var
        Schedule: TestPage "LT Y63 Part Then Other Sched";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('after lookup', SnapPO(Schedule));
        Observer.Observe('after lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', SnapPO(Schedule));
        Observer.Observe('other next', Format(Schedule.OtherResources.Next(), 0, 9) + '|' + Schedule.OtherResources."No.".Value());
        Observer.Observe('other next log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: the second ListPart placed after the linked part; every control is read one at a time after the lookup.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_PartThenOther_LookupReadEachControl()
    var
        Schedule: TestPage "LT Y63 Part Then Other Sched";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('header current', Schedule.HeaderCurrent.Value());
        Observer.Observe('header current log', Log.Take());
        Observer.Observe('row', Schedule."No.".Value());
        Observer.Observe('row log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('current no log', Log.Take());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host fn log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('part current', Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part current log', Log.Take());
        Observer.Observe('part fn', Schedule.Resources.PartFn.Value());
        Observer.Observe('part fn log', Log.Take());
        Observer.Observe('other no', Schedule.OtherResources."No.".Value());
        Observer.Observe('other no log', Log.Take());
        Observer.Observe('other current', Schedule.OtherResources.OtherCurrent.Value());
        Observer.Observe('other fn', Schedule.OtherResources.OtherFn.Value());
        Observer.Observe('other log', Log.Take());
        Observer.Observe('after', SnapPO(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: the Y26 three-field host with a CardPart in the FactBox area linked on No. Every control is read after the lookup.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_CardPart_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y63 Card Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapCP(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('part', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('card part', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
        Observer.Observe('read log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Finish();
    end;

    // Y63: the linked ListPart moves first after the lookup, then the host.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_CardPart_LinkedPartNextFirst()
    var
        Schedule: TestPage "LT Y63 Card Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', SnapCP(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Observer.Observe('next', Format(Schedule.Next(), 0, 9));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('after next', SnapCP(Schedule));
        Observer.Observe('after next log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    // Y63: the FactBox CardPart moves first after the lookup, then the linked ListPart.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_CardPart_CardNextFirst()
    var
        Schedule: TestPage "LT Y63 Card Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('card next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('card next log', Log.Take());
        Observer.Observe('after card next', SnapCP(Schedule));
        Observer.Observe('after card next log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after part next', SnapCP(Schedule));
        Observer.Observe('after part next log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: a cancelled lookup on the FactBox host, then the linked part moves.
    [Test]
    [HandlerFunctions('CancelLookup')]
    procedure Y63_CardPart_PartNextAfterCancel()
    var
        Schedule: TestPage "LT Y63 Card Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after', SnapCP(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: no part is touched before the lookup; the first access to a part after it is a read of the other part's control.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_TwoPart_FirstPartReadAfterLookup()
    var
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('other no', Schedule.OtherResources."No.".Value());
        Observer.Observe('other no log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('after', SnapTP(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: both parts are read before the lookup; after it the linked part moves.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_TwoPart_PartsReadBeforeThenNext()
    var
        Schedule: TestPage "LT Y63 Two Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('before', Schedule.Resources."No.".Value() + '|' + Schedule.OtherResources."No.".Value());
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part next', Format(Schedule.Resources.Next(), 0, 9));
        Observer.Observe('part next log', Log.Take());
        Observer.Observe('after', SnapTP(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: the linked part (placed first) is read before the lookup; after it the other part's control is read.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_PartThenOther_PartReadBeforeLookup()
    var
        Schedule: TestPage "LT Y63 Part Then Other Sched";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Observer.Observe('before', Schedule.Resources."No.".Value());
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('other no', Schedule.OtherResources."No.".Value() + '|' + Schedule.OtherResources.OtherCurrent.Value());
        Observer.Observe('other no log', Log.Take());
        Observer.Observe('after', SnapPO(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    // Y63: no part is touched before the lookup; the first access after it is a read of the FactBox CardPart's control.
    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y63_CardPart_CardReadAfterLookup()
    var
        Schedule: TestPage "LT Y63 Card Part Schedule";
    begin
        Setup(false);
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('card no', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value());
        Observer.Observe('card no log', Log.Take());
        Observer.Observe('part no', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('part no log', Log.Take());
        Observer.Observe('after', SnapCP(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Finish();
    end;

    local procedure SnapTP(var Schedule: TestPage "LT Y63 Two Part Schedule"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherResources."No.".Value() + '|' + Schedule.OtherResources.OtherCurrent.Value() + '|' + Schedule.OtherResources.OtherFn.Value());
    end;

    local procedure SnapPO(var Schedule: TestPage "LT Y63 Part Then Other Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherResources."No.".Value() + '|' + Schedule.OtherResources.OtherCurrent.Value() + '|' + Schedule.OtherResources.OtherFn.Value());
    end;

    local procedure SnapCP(var Schedule: TestPage "LT Y63 Card Part Schedule"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
    end;

    local procedure Snap3C(var Schedule: TestPage "LT Y26 3Link Curr Schedule"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
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

page 92220 "LT Y26 Logging Resource Part"
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
                field(PartCurrent; PartCurrent) { ApplicationArea = All; Caption = 'Part Current'; }
                field(PartFn; GetPartNo()) { ApplicationArea = All; Caption = 'Part Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('p-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('p-agcr ' + Rec."No.");
        PartCurrent := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetPartNo(): Code[20]
    begin
        Log.Add('p-fn ' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        PartCurrent: Code[20];
        Log: Codeunit "LT Y15 Lookup Log";
}

page 92221 "LT Y26 3Link Curr Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 92222 "LT Y26 2Link Curr Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 92223 "LT Y26 3Link Plain Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 92224 "LT Y26 2Link Plain Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 93280 "LT Y63 Logging Other Part"
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
                field(OtherCurrent; OtherCurrent) { ApplicationArea = All; Caption = 'Other Current'; }
                field(OtherFn; GetOtherNo()) { ApplicationArea = All; Caption = 'Other Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('o-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('o-agcr ' + Rec."No.");
        OtherCurrent := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetOtherNo(): Code[20]
    begin
        Log.Add('o-fn ' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        OtherCurrent: Code[20];
        Log: Codeunit "LT Y15 Lookup Log";
}

page 93281 "LT Y63 Logging Card Part"
{
    PageType = CardPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(CardCurrent; CardCurrent) { ApplicationArea = All; Caption = 'Card Current'; }
            field(CardFn; GetCardNo()) { ApplicationArea = All; Caption = 'Card Fn'; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('c-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c-agcr ' + Rec."No.");
        CardCurrent := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetCardNo(): Code[20]
    begin
        Log.Add('c-fn ' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        CardCurrent: Code[20];
        Log: Codeunit "LT Y15 Lookup Log";
}

page 93282 "LT Y63 Two Part Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherResources; "LT Y63 Logging Other Part")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y26 Logging Resource Part")
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

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 93283 "LT Y63 Card Part Schedule"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT Y63 Logging Card Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}

page 93284 "LT Y63 Part Then Other Sched"
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
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y26 Logging Resource Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
            part(OtherResources; "LT Y63 Logging Other Part")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y15 Lookup Log";
}
