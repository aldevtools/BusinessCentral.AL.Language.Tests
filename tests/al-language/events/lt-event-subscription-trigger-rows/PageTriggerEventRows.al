// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/eventsubscription/eventsubscription-table
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91510, pages 91511 and 91512, page extension 91513, subscriber codeunit 91514,
//   test codeunit 91515
// Probe: observe probe (writer Y11, 2026-10-30, al-runner issue 6411); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: every column of the Event Subscription rows for subscribers to PAGE TRIGGER events: OnBeforeValidateEvent and OnAfterValidateEvent of a
//   page field (plain name, quoted name inside a group, a control whose name differs from the field, a field added by a page extension, the same
//   field on a second page), OnAfterGetCurrRecordEvent, OnOpenPageEvent, OnClosePageEvent, OnAfterGetRecordEvent, OnNewRecordEvent,
//   OnInsertRecordEvent, OnModifyRecordEvent, OnDeleteRecordEvent and OnQueryClosePageEvent; the row count; and how "Number of Calls" moves when a
//   TestPage opens the card, validates a field and closes. The subscribers declare no parameters (a subscriber may omit them).
//   Already pinned elsewhere: page field OnAfterValidateEvent and OnOpenPageEvent in misc/lt-probes-needed-5/PnE11EventSub.al; page action events
//   in ActionEventPublishedFunction.al.
// BC versions: 27, 28, 29

table 91510 "LT Y11 PTE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; "Unit Price"; Decimal) { }
        field(4; Extra; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 91511 "LT Y11 PTE Card"
{
    PageType = Card;
    SourceTable = "LT Y11 PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code")
            {
                ApplicationArea = All;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
            group(Prices)
            {
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 91512 "LT Y11 PTE List"
{
    PageType = List;
    SourceTable = "LT Y11 PTE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(ListName; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

pageextension 91513 "LT Y11 PTE Card Ext" extends "LT Y11 PTE Card"
{
    layout
    {
        addlast(Content)
        {
            field(Extra; Rec.Extra)
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 91514 "LT Y11 PTE Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnBeforeValidateEvent, 'Name', false, false)]
    local procedure P01_CardNameBeforeValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnAfterValidateEvent, 'Name', false, false)]
    local procedure P02_CardNameAfterValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnAfterValidateEvent, 'Unit Price', false, false)]
    local procedure P03_CardUnitPriceAfterValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnAfterValidateEvent, 'Extra', false, false)]
    local procedure P04_CardExtAfterValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE List", OnAfterValidateEvent, 'Name', false, false)]
    local procedure P05_ListNameAfterValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE List", OnAfterValidateEvent, 'ListName', false, false)]
    local procedure P06_ListOtherCtlAfterValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnAfterGetCurrRecordEvent, '', false, false)]
    local procedure P07_CardAfterGetCurrRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnOpenPageEvent, '', false, false)]
    local procedure P08_CardOpenPage()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnClosePageEvent, '', false, false)]
    local procedure P09_CardClosePage()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnAfterGetRecordEvent, '', false, false)]
    local procedure P10_CardAfterGetRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnNewRecordEvent, '', false, false)]
    local procedure P11_CardNewRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnInsertRecordEvent, '', false, false)]
    local procedure P12_CardInsertRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnModifyRecordEvent, '', false, false)]
    local procedure P13_CardModifyRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnDeleteRecordEvent, '', false, false)]
    local procedure P14_CardDeleteRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnQueryClosePageEvent, '', false, false)]
    local procedure P15_CardQueryClosePage()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE List", OnAfterGetCurrRecordEvent, '', false, false)]
    local procedure P16_ListAfterGetCurrRecord()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y11 PTE Card", OnBeforeValidateEvent, 'Code', false, false)]
    local procedure P17_CardCodeBeforeValidate()
    begin
    end;
}

codeunit 91515 "LT Y11 PTE Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(SubscriberFunction: Text): Text
    var
        Sub: Record "Event Subscription";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        R: Text;
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT Y11 PTE Subs");
        Sub.SetRange("Subscriber Function", SubscriberFunction);
        R := Format(Sub.Count()) + ' row(s): ';
        if not Sub.FindFirst() then
            exit(R);
        RR.GetTable(Sub);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if StrPos('|Subscriber Codeunit ID|Subscriber Function|Originating Package ID|Originating App Name|', '|' + FR.Name + '|') = 0 then
                R += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(R);
    end;

    local procedure Calls(SubscriberFunction: Text): Integer
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT Y11 PTE Subs");
        Sub.SetRange("Subscriber Function", SubscriberFunction);
        if not Sub.FindFirst() then
            exit(-1);
        exit(Sub."Number of Calls");
    end;

    [Test]
    procedure PageTriggerRows_FieldValidateCard()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('P01_CardNameBeforeValidate', Row('P01_CardNameBeforeValidate'));
        Observer.Observe('P02_CardNameAfterValidate', Row('P02_CardNameAfterValidate'));
        Observer.Observe('P17_CardCodeBeforeValidate', Row('P17_CardCodeBeforeValidate'));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_FieldValidateGroupExtAndList()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('P03_CardUnitPriceAfterValidate', Row('P03_CardUnitPriceAfterValidate'));
        Observer.Observe('P04_CardExtAfterValidate', Row('P04_CardExtAfterValidate'));
        Observer.Observe('P05_ListNameAfterValidate', Row('P05_ListNameAfterValidate'));
        Observer.Observe('P06_ListOtherCtlAfterValidate', Row('P06_ListOtherCtlAfterValidate'));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_RecordTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('P07_CardAfterGetCurrRecord', Row('P07_CardAfterGetCurrRecord'));
        Observer.Observe('P10_CardAfterGetRecord', Row('P10_CardAfterGetRecord'));
        Observer.Observe('P16_ListAfterGetCurrRecord', Row('P16_ListAfterGetCurrRecord'));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_OpenClose()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('P08_CardOpenPage', Row('P08_CardOpenPage'));
        Observer.Observe('P09_CardClosePage', Row('P09_CardClosePage'));
        Observer.Observe('P15_CardQueryClosePage', Row('P15_CardQueryClosePage'));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_NewInsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('P11_CardNewRecord', Row('P11_CardNewRecord'));
        Observer.Observe('P12_CardInsertRecord', Row('P12_CardInsertRecord'));
        Observer.Observe('P13_CardModifyRecord', Row('P13_CardModifyRecord'));
        Observer.Observe('P14_CardDeleteRecord', Row('P14_CardDeleteRecord'));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_CountsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT Y11 PTE Subs");
        Observer.Observe('all rows', Format(Sub.Count()));
        Sub.SetRange("Event Type", Sub."Event Type"::"Trigger");
        Observer.Observe('trigger rows', Format(Sub.Count()));
        Sub.SetRange("Event Type");
        Sub.SetRange("Publisher Object Type", Sub."Publisher Object Type"::Page);
        Sub.SetRange("Publisher Object ID", Page::"LT Y11 PTE List");
        Observer.Observe('list page rows', Format(Sub.Count()));
        Sub.SetRange("Publisher Object ID");
        Sub.SetRange("Published Function", 'OnAfterGetCurrRecordEvent');
        Observer.Observe('OnAfterGetCurrRecordEvent rows', Format(Sub.Count()));
        Sub.SetFilter("Published Function", 'OnAfterValidateEvent*');
        Observer.Observe('OnAfterValidateEvent* rows', Format(Sub.Count()));
        Sub.SetRange("Published Function", 'OnAfterValidateEvent - Name');
        Observer.Observe('OnAfterValidateEvent - Name rows', Format(Sub.Count()));
        Sub.SetRange("Published Function");
        Sub.SetRange(Active, false);
        Observer.Observe('inactive rows', Format(Sub.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageTriggerRows_CallsAfterTestPageEdit()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y11 PTE Row";
        Card: TestPage "LT Y11 PTE Card";
        Names: List of [Text];
        Before: List of [Integer];
        N: Text;
        i: Integer;
    begin
        Rec.DeleteAll();
        Rec."Code" := 'A';
        Rec.Name := 'first';
        Rec.Insert();
        Names.Add('P01_CardNameBeforeValidate');
        Names.Add('P02_CardNameAfterValidate');
        Names.Add('P03_CardUnitPriceAfterValidate');
        Names.Add('P07_CardAfterGetCurrRecord');
        Names.Add('P08_CardOpenPage');
        Names.Add('P09_CardClosePage');
        Names.Add('P10_CardAfterGetRecord');
        Names.Add('P13_CardModifyRecord');
        Names.Add('P15_CardQueryClosePage');
        Names.Add('P17_CardCodeBeforeValidate');
        foreach N in Names do
            Before.Add(Calls(N));
        Card.OpenEdit();
        Card.GoToRecord(Rec);
        Card.Name.SetValue('second');
        Card.Close();
        for i := 1 to Names.Count() do
            Observer.Observe(Names.Get(i) + ' calls delta', Format(Calls(Names.Get(i)) - Before.Get(i)));
        Rec.Get('A');
        Observer.Observe('stored name', Rec.Name);
        Observer.Finish();
    end;
}
