// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73296, SingleInstance log 73297 (used only by test codeunit 73300), page 73298, subscriber codeunit 73299
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from event subscribers of a table (OnBeforeInsertEvent, OnAfterInsertEvent, OnBeforeModifyEvent, OnAfterModifyEvent, OnBeforeDeleteEvent, OnBeforeValidateEvent,
// OnAfterValidateEvent, OnAfterRenameEvent), of a page (OnOpenPageEvent, OnAfterGetRecordEvent, OnClosePageEvent) and of an IntegrationEvent published by a table procedure and by a page procedure:
// the frames of the subscriber, of the event itself (if any) and of the caller, innermost first.
// BC versions: 29 (27 and 28 by CI)

table 73296 "LT P129 CS Ev Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    [IntegrationEvent(false, false)]
    procedure OnTableProcedureEvent()
    begin
    end;

    procedure RaiseTableEvent()
    begin
        OnTableProcedureEvent();
    end;
}

codeunit 73297 "LT P129 CS Log6"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Frames(): Text
    var
        Stack: Text;
        Position: Integer;
    begin
        Stack := SessionInformation.Callstack;
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;
}

page 73298 "LT P129 CS Ev Page"
{
    PageType = List;
    SourceTable = "LT P129 CS Ev Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RaiseEvent)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    OnPageProcedureEvent();
                end;
            }
        }
    }

    [IntegrationEvent(false, false)]
    procedure OnPageProcedureEvent()
    begin
    end;
}

codeunit 73299 "LT P129 CS Subscribers"
{
    var
        L: Codeunit "LT P129 CS Log6";

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure TBeforeInsert(var Rec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnBeforeInsertEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure TAfterInsert(var Rec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnAfterInsertEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure TBeforeModify(var Rec: Record "LT P129 CS Ev Row"; var xRec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnBeforeModifyEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure TAfterModify(var Rec: Record "LT P129 CS Ev Row"; var xRec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnAfterModifyEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure TBeforeDelete(var Rec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnBeforeDeleteEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure TAfterRename(var Rec: Record "LT P129 CS Ev Row"; var xRec: Record "LT P129 CS Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('table OnAfterRenameEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure TBeforeValidate(var Rec: Record "LT P129 CS Ev Row"; var xRec: Record "LT P129 CS Ev Row"; CurrFieldNo: Integer)
    begin
        L.Add('table OnBeforeValidateEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure TAfterValidate(var Rec: Record "LT P129 CS Ev Row"; var xRec: Record "LT P129 CS Ev Row"; CurrFieldNo: Integer)
    begin
        L.Add('table OnAfterValidateEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P129 CS Ev Row", 'OnTableProcedureEvent', '', false, false)]
    local procedure TProcedureEvent()
    begin
        L.Add('table IntegrationEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P129 CS Ev Page", 'OnOpenPageEvent', '', false, false)]
    local procedure POpen()
    begin
        L.Add('page OnOpenPageEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P129 CS Ev Page", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure PAfterGetRecord(var Rec: Record "LT P129 CS Ev Row")
    begin
        L.Add('page OnAfterGetRecordEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P129 CS Ev Page", 'OnClosePageEvent', '', false, false)]
    local procedure PClose()
    begin
        L.Add('page OnClosePageEvent: ' + L.Frames());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P129 CS Ev Page", 'OnPageProcedureEvent', '', false, false)]
    local procedure PProcedureEvent()
    begin
        L.Add('page IntegrationEvent: ' + L.Frames());
    end;
}

codeunit 73300 "LT P129 CS Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 CS Log6";

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Entries: List of [Text];
        Entry: Text;
        I: Integer;
    begin
        Entries := L.Take().Split('|');
        foreach Entry in Entries do begin
            I += 1;
            if Entry <> '' then
                Observer.Observe(Name + ' ' + Format(I), Entry);
        end;
    end;

    [Test]
    procedure P129_Callstack_TableEventSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS Ev Row";
    begin
        Row.DeleteAll();
        L.Take();
        Row.Id := 1;
        Row.Insert(true);
        Show(Observer, 'insert');
        Row.Name := 'a';
        Row.Modify(true);
        Show(Observer, 'modify');
        Row.Validate(Name, 'b');
        Show(Observer, 'validate');
        Row.Rename(2);
        Show(Observer, 'rename');
        Row.Delete(true);
        Show(Observer, 'delete');
        Observer.Expect('insert 1', 'table OnBeforeInsertEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TBeforeInsert line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('insert 2', 'table OnAfterInsertEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TAfterInsert line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('modify 1', 'table OnBeforeModifyEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TBeforeModify line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 11 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('modify 2', 'table OnAfterModifyEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TAfterModify line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 11 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('validate 1', 'table OnBeforeValidateEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TBeforeValidate line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('validate 2', 'table OnAfterValidateEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TAfterValidate line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('rename 1', 'table OnAfterRenameEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TAfterRename line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('delete 1', 'table OnBeforeDeleteEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TBeforeDelete line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_TableEventSubscribers line 17 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;





    [Test]
    procedure P129_Callstack_IntegrationEventOfATableAndOfAPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS Ev Row";
        Pg: TestPage "LT P129 CS Ev Page";
    begin
        Row.DeleteAll();
        L.Take();
        Row.RaiseTableEvent();
        Show(Observer, 'table procedure event');
        Row.Id := 1;
        Row.DeleteAll();
        Row.Insert();
        L.Take();
        Pg.OpenView();
        Pg.RaiseEvent.Invoke();
        Pg.Close();
        Show(Observer, 'page');
        Observer.Expect('table procedure event 1', 'table IntegrationEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).TProcedureEvent line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Ev Row"(Table 73296).OnTableProcedureEvent(Event) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Ev Row"(Table 73296).RaiseTableEvent line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 8 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 1', 'page OnOpenPageEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).POpen line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 14 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 2', 'page OnAfterGetRecordEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PAfterGetRecord line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 14 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 3', 'page OnAfterGetRecordEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PAfterGetRecord line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 4', 'page IntegrationEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PProcedureEvent line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Ev Page"(Page 73298).OnPageProcedureEvent(Event) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Ev Page"(Page 73298)."RaiseEvent - OnAction"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 5', 'page OnAfterGetRecordEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PAfterGetRecord line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 6', 'page OnAfterGetRecordEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PAfterGetRecord line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('page 7', 'page OnClosePageEvent: "LT P129 CS Log6"(CodeUnit 73297).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Subscribers"(CodeUnit 73299).PClose line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Events"(CodeUnit 73300).P129_Callstack_IntegrationEventOfATableAndOfAPage line 16 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;




}
