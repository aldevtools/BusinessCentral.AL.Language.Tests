// Probe: Report Data Items, Report Metadata, Query Metadata, Event Subscription and Table Relations Metadata,
// dumped column by column from small fixtures.
report 69510 "Probe Obj Report Items"
{
    ProcessingOnly = false;
    UseRequestPage = true;

    dataset
    {
        dataitem(ItemPlain; "Probe Pf Row")
        {
            column(Txt1; Txt) { }

            dataitem(ItemChild; "Probe Pf Row")
            {
                DataItemLink = Id = field(Id);
                DataItemTableView = sorting(Txt) order(descending) where(Id = const(1));
                column(Txt2; Txt) { }
            }
        }
        dataitem(ItemSorted; "Probe Pf Row")
        {
            DataItemTableView = sorting(Txt);
            column(Txt3; Txt) { }
        }
        dataitem(ItemDescendingOnly; "Probe Pf Row")
        {
            DataItemTableView = order(descending);
            column(Txt4; Txt) { }
        }
        dataitem(ItemTwoConditions; "Probe Pf Row")
        {
            DataItemTableView = where(Id = filter(1..5), Txt = const('x'));
            column(Txt5; Txt) { }
        }
        dataitem(ItemSortingTwoFields; "Probe Pf Row")
        {
            DataItemTableView = sorting(Txt, Id);
            column(Txt6; Txt) { }
        }
    }
}

report 69511 "Probe Obj Report Defaults"
{
    dataset
    {
        dataitem(Only; "Probe Pf Row")
        {
            column(Id; Id) { }
        }
    }
}

report 69512 "Probe Obj Report Proc Only"
{
    ProcessingOnly = true;
    UseRequestPage = false;
}

query 69513 "Probe Obj Query Plain"
{
    elements
    {
        dataitem(Row; "Probe Pf Row")
        {
            column(Id; Id) { }
        }
    }
}

query 69514 "Probe Obj Query Api"
{
    QueryType = API;
    APIPublisher = 'probe';
    APIGroup = 'probeGroup';
    APIVersion = 'v2.0';
    EntityName = 'probeEntity';
    EntitySetName = 'probeEntities';

    elements
    {
        dataitem(Row; "Probe Pf Row")
        {
            column(Id; Id) { }
        }
    }
}

table 69515 "Probe Obj Rel Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 69516 "Probe Obj Rel Enum"
{
    Extensible = true;

    value(0; Zero) { }
    value(1; One) { }
}

table 69517 "Probe Obj Rel Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Cond; Enum "Probe Obj Rel Enum") { }
        field(4; ConditionalRef; Integer)
        {
            TableRelation = if (Kind = const(A)) "Probe Obj Rel Target".Id where(Kind = const(A))
            else if (Kind = const(B)) "Probe Pf Row".Id;
        }
        field(5; EnumConditionRef; Integer)
        {
            TableRelation = if (Cond = const(One)) "Probe Obj Rel Target".Id;
        }
        field(6; FilterConditionRef; Integer)
        {
            TableRelation = "Probe Obj Rel Target".Id where(Kind = filter(<> C), Id = field(Id));
        }
        field(7; NoValidateRef; Integer)
        {
            TableRelation = "Probe Obj Rel Target".Id;
            ValidateTableRelation = false;
        }
        field(8; NoTestRef; Integer)
        {
            TableRelation = "Probe Obj Rel Target".Id;
            TestTableRelation = false;
        }
        field(9; FilterFirstArmRef; Integer)
        {
            TableRelation = if (Kind = filter(<> A)) "Probe Obj Rel Target".Id
            else "Probe Pf Row".Id;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69518 "Probe Obj Event Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Probe Pf Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsertRow(var Rec: Record "Probe Pf Row")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Pf Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModifyRow(var Rec: Record "Probe Pf Row"; var xRec: Record "Probe Pf Row")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Pf Row", 'OnAfterValidateEvent', 'Txt', false, false)]
    local procedure AfterValidateTxt(var Rec: Record "Probe Pf Row"; var xRec: Record "Probe Pf Row")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Pf Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteRow(var Rec: Record "Probe Pf Row")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbeSub(var Log: Text)
    begin
    end;
}

codeunit 69519 "Probe Object Metadata Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;








    [Test]
    procedure EventSubscription_TableTriggerEvents_AllRows()
    var
        EventSub: Record "Event Subscription";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
    begin
        EventSub.SetRange("Subscriber Codeunit ID", 69518);
        Observer.Observe('rowCount', Format(EventSub.Count()));
        if EventSub.FindSet() then
            repeat
                RecRef.GetTable(EventSub);
                Observer.Observe('row', Dumper.Dump(RecRef));
            until EventSub.Next() = 0;
        Observer.Expect('rowCount', '5');
        Observer.Ignore('row'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;










    [Test]
    procedure FieldTable_RelationTableNo_OfConditionalRelations()
    var
        FieldRec: Record Field;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"Probe Obj Rel Source");
        FieldRec.SetFilter(RelationTableNo, '<>0');
        FieldRec.FindSet();
        repeat
            Observer.Observe(FieldRec.FieldName, Format(FieldRec.RelationTableNo) + '/' + Format(FieldRec.RelationFieldNo));
        until FieldRec.Next() = 0;
        Observer.Expect('FilterConditionRef', '69515/1');
        Observer.Expect('NoValidateRef', '69515/1');
        Observer.Expect('NoTestRef', '69515/1');
        Observer.Expect('SystemCreatedBy', '2000000120/0');
        Observer.Expect('SystemModifiedBy', '2000000120/0');
        Observer.Verify();
    end;
}
