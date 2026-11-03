// Fixtures of the event leads of corpus issue 669 items 16 to 30 (writer CL). Used only by the test codeunit "LT CL Event Leads" (84790) in this folder.
// Every subscriber codeunit is Manual and logs into "LT CL Log" (SingleInstance), including
// "LT CL GT Subs" (bound before the first write of its tables, because the Global Triggers setup is asked once per table).

table 84760 "LT CL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 84761 "LT CL GT Reg"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 84762 "LT CL GT Mask"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 84763 "LT CL GT None"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// Items 29 and 30: CurrFieldNo in table, table extension and subscriber code.
table 84764 "LT CL CFN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[20]) { }
        field(2; B; Integer)
        {
            trigger OnValidate()
            var
                L: Codeunit "LT CL Log";
            begin
                L.Add('B.validate cur=' + Format(CurrFieldNo) + ' xB=' + Format(xRec.B));
            end;
        }
        field(3; Qty; Integer)
        {
            trigger OnValidate()
            var
                L: Codeunit "LT CL Log";
            begin
                L.Add('Qty.validate cur=' + Format(CurrFieldNo));
            end;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('table.OnInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnModify()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('table.OnModify cur=' + Format(CurrFieldNo));
    end;
}

tableextension 84765 "LT CL CFN Ext" extends "LT CL CFN Row"
{
    fields
    {
        field(84760; E; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                L: Codeunit "LT CL Log";
            begin
                L.Add('E.validate cur=' + Format(CurrFieldNo) + ' xE=' + Format(xRec.E));
            end;
        }
    }

    trigger OnInsert()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ext.OnInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnAfterInsert()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ext.OnAfterInsert cur=' + Format(CurrFieldNo));
    end;

    trigger OnModify()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ext.OnModify cur=' + Format(CurrFieldNo));
    end;

    trigger OnAfterModify()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ext.OnAfterModify cur=' + Format(CurrFieldNo));
    end;
}

// Item 22: assignments to Rec in OnAfterInsert / OnAfterModify (subscribers and table extension triggers) without a Modify.
table 84766 "LT CL AI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 84767 "LT CL AI Ext" extends "LT CL AI Row"
{
    fields
    {
        field(84760; Note; Text[50]) { DataClassification = SystemMetadata; }
    }

    trigger OnAfterInsert()
    var
        L: Codeunit "LT CL Log";
    begin
        if L.Mode() = 'ext' then
            Rec.Note := 'extAfterInsert';
    end;

    trigger OnAfterModify()
    var
        L: Codeunit "LT CL Log";
    begin
        if L.Mode() = 'ext' then
            Rec.Note := 'extAfterModify';
    end;
}

// Item 24: trigger order of a page, two page extensions and page event subscribers.
page 84768 "LT CL Ord Card"
{
    PageType = Card;
    SourceTable = "LT CL Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('page.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('page.OnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('page.OnAfterGetCurrRecord');
    end;
}

pageextension 84769 "LT CL Ord Ext A" extends "LT CL Ord Card"
{
    trigger OnOpenPage()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extA.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extA.OnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extA.OnAfterGetCurrRecord');
    end;
}

pageextension 84770 "LT CL Ord Ext B" extends "LT CL Ord Card"
{
    trigger OnOpenPage()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extB.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extB.OnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('extB.OnAfterGetCurrRecord');
    end;
}

// Items 29 and 30.
page 84771 "LT CL CFN Card"
{
    PageType = Card;
    SourceTable = "LT CL CFN Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(B; Rec.B) { ApplicationArea = All; }
            field(Qty; Rec.Qty) { ApplicationArea = All; }
            field(E; Rec.E) { ApplicationArea = All; }
        }
    }
}

// Item 17: a page event subscriber that takes Rec, or a var Boolean, without var.
page 84772 "LT CL PE Card"
{
    PageType = Card;
    SourceTable = "LT CL Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    procedure RaiseHandled(): Text
    var
        Handled: Boolean;
    begin
        OnCheckHandled(Handled);
        exit(Format(Handled));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckHandled(var Handled: Boolean)
    begin
    end;
}

// Item 25: an action subscriber that names the action in another letter case.
page 84773 "LT CL Act Card"
{
    PageType = Card;
    SourceTable = "LT CL Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostShipment)
            {
                ApplicationArea = All;
                Caption = 'P&ost Shipment';

                trigger OnAction()
                var
                    L: Codeunit "LT CL Log";
                begin
                    L.Add('OnAction');
                end;
            }
        }
    }
}

codeunit 84774 "LT CL Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetMode(NewMode: Text)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(CurrentMode);
    end;
}

// Custom publishers of items 19, 20 and 21.
codeunit 84775 "LT CL Pub"
{
    procedure RaiseUmlaut(Start: Integer): Integer
    var
        V: Integer;
    begin
        V := Start;
        OnUmlaut(V);
        exit(V);
    end;

    procedure RaiseFinalize(Finalize: Boolean): Integer
    var
        Hit: Integer;
    begin
        OnFinalize(Finalize, Hit);
        exit(Hit);
    end;

    procedure RaiseCuByValue(H: Codeunit "LT CL Holder")
    begin
        OnCuByValue(H);
    end;

    procedure RaiseCuByVar(var H: Codeunit "LT CL Holder")
    begin
        OnCuByVar(H);
    end;

    procedure RaiseSiByValue(H: Codeunit "LT CL Holder SI")
    begin
        OnSiByValue(H);
    end;

    procedure RaiseTempParam(var R: Record "LT CL Row")
    begin
        OnTempParam(R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTempParam(var R: Record "LT CL Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUmlaut(var ParamWithäöü: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalize(Finalize: Boolean; var Hit: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCuByValue(H: Codeunit "LT CL Holder")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCuByVar(var H: Codeunit "LT CL Holder")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSiByValue(H: Codeunit "LT CL Holder SI")
    begin
    end;
}

// Item 16 (table events of a temporary record) and items 19, 20, 21 (custom publishers).
codeunit 84776 "LT CL Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT CL Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure InsByValue(Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ins.byValue temp=' + Format(Rec.IsTemporary()) + ' count=' + Format(Rec.Count()) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure InsTemporary(Rec: Record "LT CL Row" temporary)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ins.temporary temp=' + Format(Rec.IsTemporary()) + ' count=' + Format(Rec.Count()) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure InsVar(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('ins.var temp=' + Format(Rec.IsTemporary()) + ' count=' + Format(Rec.Count()) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DelByValue(Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('del.byValue temp=' + Format(Rec.IsTemporary()) + ' count=' + Format(Rec.Count()) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DelVar(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('del.var temp=' + Format(Rec.IsTemporary()) + ' count=' + Format(Rec.Count()) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnTempParam', '', false, false)]
    local procedure TempParam(var R: Record "LT CL Row" temporary)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('tempParam temp=' + Format(R.IsTemporary()) + ' count=' + Format(R.Count()) + ' id=' + Format(R.Id));
        R.Name := 'fromSub';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnUmlaut', '', false, false)]
    local procedure Umlaut(var ParamWithäöü: Integer)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('umlaut in=' + Format(ParamWithäöü));
        ParamWithäöü += 5;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnFinalize', '', false, false)]
    local procedure Fin(Finalize: Boolean; var Hit: Integer)
    begin
        if Finalize then
            Hit := 11
        else
            Hit := 10;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnCuByValue', '', false, false)]
    local procedure CuByValue(H: Codeunit "LT CL Holder")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('cuByValue in=' + Format(H.Get()));
        if L.Mode() = 'clear' then
            Clear(H);
        H.SetValue(7);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnCuByVar', '', false, false)]
    local procedure CuByVar(var H: Codeunit "LT CL Holder")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('cuByVar in=' + Format(H.Get()));
        if L.Mode() = 'clear' then
            Clear(H);
        H.SetValue(8);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CL Pub", 'OnSiByValue', '', false, false)]
    local procedure SiByValue(H: Codeunit "LT CL Holder SI")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('siByValue in=' + Format(H.Get()));
        if L.Mode() = 'clear' then
            Clear(H);
        H.SetValue(9);
    end;
}

// Item 21: a codeunit passed through an event; not SingleInstance.
codeunit 84777 "LT CL Holder"
{
    var
        Value: Integer;

    procedure SetValue(NewValue: Integer)
    begin
        Value := NewValue;
    end;

    procedure Get(): Integer
    begin
        exit(Value);
    end;
}

codeunit 84778 "LT CL Holder SI"
{
    SingleInstance = true;

    var
        Value: Integer;

    procedure SetValue(NewValue: Integer)
    begin
        Value := NewValue;
    end;

    procedure Get(): Integer
    begin
        exit(Value);
    end;
}

// Item 23: the Base Application codeunit GlobalTriggerManagement (49) and its OnAfter* events, for three own tables:
// "LT CL GT Reg" is registered for OnDatabaseInsert/Modify only through OnAfterGetDatabaseTableTriggerSetup, "LT CL GT Mask" only through
// OnAfterGetGlobalTableTriggerMask (mask 3 = insert and modify), "LT CL GT None" not at all. The subscribers log only while the mode is 'gt'.
// Manual: the test binds it before the first write of these tables in the session.
codeunit 84779 "LT CL GT Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId = Database::"LT CL GT Reg" then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetGlobalTableTriggerMask', '', false, false)]
    local procedure Mask(TableID: Integer; var TableTriggerMask: Integer)
    begin
        if TableID = Database::"LT CL GT Mask" then
            TableTriggerMask := 3;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure DbInsert(RecRef: RecordRef)
    begin
        LogFor('dbInsert', RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure DbModify(RecRef: RecordRef)
    begin
        LogFor('dbModify', RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalInsert', '', false, false)]
    local procedure GlInsert(RecRef: RecordRef)
    begin
        LogFor('globalInsert', RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalModify', '', false, false)]
    local procedure GlModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        LogFor('globalModify', RecRef);
    end;

    local procedure LogFor(What: Text; RecRef: RecordRef)
    var
        L: Codeunit "LT CL Log";
        Name: Text;
    begin
        if L.Mode() <> 'gt' then
            exit;
        case RecRef.Number() of
            Database::"LT CL GT Reg":
                Name := 'Reg';
            Database::"LT CL GT Mask":
                Name := 'Mask';
            Database::"LT CL GT None":
                Name := 'None';
            else
                exit;
        end;
        L.Add(What + ' ' + Name + ' ' + Format(RecRef.Field(1).Value()));
    end;
}

// Item 24.
codeunit 84780 "LT CL Ord Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"LT CL Ord Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OpenPage(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT CL Ord Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure AfterGetRecord(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT CL Ord Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure AfterGetCurrRecord(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.OnAfterGetCurrRecordEvent');
    end;
}

// Item 30 (c): a subscriber to the validate events of the base field B.
codeunit 84781 "LT CL CFN Subs"
{
    EventSubscriberInstance = Manual;



    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnBeforeValidateEvent', 'Qty', false, false)]
    local procedure BeforeValidateQty(var Rec: Record "LT CL CFN Row"; var xRec: Record "LT CL CFN Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.beforeQty param=' + Format(CurrFieldNo));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnAfterValidateEvent', 'Qty', false, false)]
    local procedure AfterValidateQty(var Rec: Record "LT CL CFN Row"; var xRec: Record "LT CL CFN Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.afterQty param=' + Format(CurrFieldNo));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "LT CL CFN Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.AfterInsert');
    end;
}

// Item 22.
codeunit 84782 "LT CL AI Subs"
{
    EventSubscriberInstance = Manual;

    var
        Depth: Integer;

    [EventSubscriber(ObjectType::Table, Database::"LT CL AI Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "LT CL AI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT CL Log";
    begin
        if L.Mode() = 'sub' then
            Rec.Name := 'subAfterInsert';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL AI Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "LT CL AI Row"; var xRec: Record "LT CL AI Row"; RunTrigger: Boolean)
    var
        L: Codeunit "LT CL Log";
    begin
        case L.Mode() of
            'sub':
                Rec.Name := 'subAfterModify';
            'recurse':
                begin
                    Depth += 1;
                    L.Add('afterModify depth=' + Format(Depth) + ' run=' + Format(RunTrigger));
                    if Depth < 3 then begin
                        Rec.Name := 'depth' + Format(Depth);
                        Rec.Modify();
                    end;
                end;
        end;
    end;
}

// Item 17: the by-value subscriber of the page event and of the page's var Boolean event.
codeunit 84783 "LT CL PE Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"LT CL PE Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure AfterGetCurrRecordByValue(Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('byValue in=' + Rec.Name);
        Rec.Name := 'fromByValue';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT CL PE Card", 'OnCheckHandled', '', false, false)]
    local procedure CheckHandledByValue(Handled: Boolean)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('handled in=' + Format(Handled));
        Handled := true;
    end;
}

// Item 17 contrast: the same page event taken with var Rec.
codeunit 84784 "LT CL PE Subs Var"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"LT CL PE Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure AfterGetCurrRecordVar(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('var in=' + Rec.Name);
        Rec.Name := 'fromVar';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT CL PE Card", 'OnCheckHandled', '', false, false)]
    local procedure CheckHandledVar(var Handled: Boolean)
    begin
        Handled := true;
    end;
}

// Item 25: action subscribers that name the action in lower case.
codeunit 84785 "LT CL Act Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"LT CL Act Card", 'OnBeforeActionEvent', 'postshipment', false, false)]
    local procedure BeforeLower(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('before(lower case name)');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT CL Act Card", 'OnAfterActionEvent', 'PostShipment', false, false)]
    local procedure AfterExact(var Rec: Record "LT CL Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('after(exact name)');
    end;
}

// Not bound by any test: validate subscribers on the one-letter field B. On the Linux BC container their Event Subscription rows show
// "OnAfterValidateEvent - 66" / "OnBeforeValidateEvent - 66" (66 is the character code of B), Active = No, Error Information = ErrorFieldNotFound,
// and they never run. Queued for the Windows check (windows-queue.md, writer CL) before it is pinned.
codeunit 84786 "LT CL One Letter Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnAfterValidateEvent', 'B', false, false)]
    local procedure AfterValidateB(var Rec: Record "LT CL CFN Row"; var xRec: Record "LT CL CFN Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.B param=' + Format(CurrFieldNo));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnAfterValidateEvent', 'B', false, false)]
    local procedure AfterValidateBNoCurrFieldNo(var Rec: Record "LT CL CFN Row"; var xRec: Record "LT CL CFN Row")
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.B(no CurrFieldNo)');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CL CFN Row", 'OnBeforeValidateEvent', 'B', false, false)]
    local procedure BeforeValidateB(var Rec: Record "LT CL CFN Row"; var xRec: Record "LT CL CFN Row"; CurrFieldNo: Integer)
    var
        L: Codeunit "LT CL Log";
    begin
        L.Add('sub.beforeB param=' + Format(CurrFieldNo));
    end;
}
