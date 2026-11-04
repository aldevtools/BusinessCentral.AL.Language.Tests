// Observe-only probes (writer A). Rows: Events (DeleteAll events, validate events, CurrFieldNo, rename RunTrigger,
// failing writes with subscribers, shared xRec, static subscriber instance, order, BindSubscription), table extension
// triggers, record errors, SystemId before OnInsert, Rename to same key, Find('=>').
table 69803 "PA Ev Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Val; Integer)
        {
            trigger OnValidate()
            var
                L: Codeunit "PA Ev Log";
            begin
                L.Add('trigger OnValidate Val: rec=' + Format(Rec.Val) + ' xrec=' + Format(xRec.Val) + ' CurrFieldNo=' + Format(CurrFieldNo));
            end;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Name) { }
    }

    trigger OnInsert()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('trigger OnInsert: sysid_null=' + Format(IsNullGuid(Rec.SystemId)) + ' xrec_sysid_null=' + Format(IsNullGuid(xRec.SystemId)));
    end;

    trigger OnModify()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('trigger OnModify: xrec.Name=' + xRec.Name);
    end;

    trigger OnDelete()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('trigger OnDelete id=' + Format(Rec.Id));
    end;

    trigger OnRename()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('trigger OnRename: old=' + Format(xRec.Id) + ' new=' + Format(Rec.Id));
    end;
}

tableextension 69800 "PA Ev Row Ext A" extends "PA Ev Row"
{
    trigger OnInsert()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('extA OnInsert');
    end;

    trigger OnModify()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('extA OnModify: xrec.Name=' + xRec.Name);
    end;

    trigger OnDelete()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('extA OnDelete');
    end;

    trigger OnRename()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('extA OnRename');
    end;
}

tableextension 69801 "PA Ev Row Ext B" extends "PA Ev Row"
{
    trigger OnInsert()
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('extB OnInsert');
    end;
}

codeunit 69805 "PA Ev Log"
{
    SingleInstance = true;
    var
        Lines: List of [Text];

    procedure Add(T: Text)
    begin
        Lines.Add(T);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Text(): Text
    var
        L: Text;
        R: Text;
    begin
        foreach L in Lines do
            R += L + ' ; ';
        exit(R);
    end;
}

codeunit 69806 "PA Ev Subs"
{
    var
        L: Codeunit "PA Ev Log";

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub BeforeInsert runtrigger=' + Format(RunTrigger) + ' sysid_null=' + Format(IsNullGuid(Rec.SystemId)));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub AfterInsert runtrigger=' + Format(RunTrigger) + ' sysid_null=' + Format(IsNullGuid(Rec.SystemId)));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub BeforeModify runtrigger=' + Format(RunTrigger) + ' xrec.Name=' + xRec.Name);
        if xRec.Name = 'mutate' then
            xRec.Name := 'SUB';
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub AfterModify runtrigger=' + Format(RunTrigger) + ' xrec.Name=' + xRec.Name);
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub BeforeDelete runtrigger=' + Format(RunTrigger) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDelete(var Rec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub AfterDelete runtrigger=' + Format(RunTrigger) + ' id=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRename(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub BeforeRename runtrigger=' + Format(RunTrigger) + ' old=' + Format(xRec.Id) + ' new=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRename(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; RunTrigger: Boolean)
    begin
        L.Add('sub AfterRename runtrigger=' + Format(RunTrigger) + ' old=' + Format(xRec.Id) + ' new=' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeValidateEvent', 'Val', false, false)]
    local procedure BeforeValidateVal(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; CurrFieldNo: Integer)
    begin
        L.Add('sub BeforeValidate Val: rec=' + Format(Rec.Val) + ' xrec=' + Format(xRec.Val) + ' CurrFieldNo=' + Format(CurrFieldNo));
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure AfterValidateVal(var Rec: Record "PA Ev Row"; var xRec: Record "PA Ev Row"; CurrFieldNo: Integer)
    begin
        L.Add('sub AfterValidate Val: rec=' + Format(Rec.Val) + ' xrec=' + Format(xRec.Val) + ' CurrFieldNo=' + Format(CurrFieldNo));
    end;

    // three subscribers of one event in non-alphabetical order of names
    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure Zeta_Order(var Rec: Record "PA Ev Row")
    begin
        L.Add('order Zeta (codeunit 69806, declared 1st of 3)');
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure Alpha_Order(var Rec: Record "PA Ev Row")
    begin
        L.Add('order Alpha (codeunit 69806, declared 2nd of 3)');
    end;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure Mid_Order(var Rec: Record "PA Ev Row")
    begin
        L.Add('order Mid (codeunit 69806, declared 3rd of 3)');
    end;
}

codeunit 69807 "PA Ev Subs Other Id"
{
    // id 69807 is above 69806; its name sorts first
    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure Order(var Rec: Record "PA Ev Row")
    var
        L: Codeunit "PA Ev Log";
    begin
        L.Add('order codeunit 69807');
    end;
}

codeunit 69808 "PA Ev Static Stateful"
{
    // static automatic subscriber, not SingleInstance, with a global
    var
        Counter: Integer;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure Count(var Rec: Record "PA Ev Row")
    var
        L: Codeunit "PA Ev Log";
    begin
        Counter += 1;
        L.Add('stateful static subscriber counter=' + Format(Counter));
    end;
}

codeunit 69809 "PA Ev Manual"
{
    EventSubscriberInstance = Manual;
    var
        Counter: Integer;

    [EventSubscriber(ObjectType::Table, Database::"PA Ev Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure Count(var Rec: Record "PA Ev Row")
    var
        L: Codeunit "PA Ev Log";
    begin
        Counter += 1;
        L.Add('manual subscriber counter=' + Format(Counter));
    end;
}

codeunit 69811 "PA Event Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Start(var L: Codeunit "PA Ev Log")
    var
        R: Record "PA Ev Row";
    begin
        R.DeleteAll();
        L.Reset();
    end;

    local procedure Seed(Id: Integer; Name: Text[30])
    var
        R: Record "PA Ev Row";
    begin
        R.Id := Id;
        R.Name := Name;
        R.Insert(false);
    end;

    [Test]
    procedure DeleteAll_True_RaisesEventsPerRow()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        Seed(3, 'c');
        L.Reset();
        R.DeleteAll(true);
        O.Observe('deleteall_true', L.Text());
        O.Expect('deleteall_true', 'sub BeforeDelete runtrigger=Yes id=1 ; trigger OnDelete id=1 ; extA OnDelete ; sub AfterDelete runtrigger=Yes id=1 ; sub BeforeDelete runtrigger=Yes id=2 ; trigger OnDelete id=2 ; extA OnDelete ; sub AfterDelete runtrigger=Yes id=2 ; sub BeforeDelete runtrigger=Yes id=3 ; trigger OnDelete id=3 ; extA OnDelete ; sub AfterDelete runtrigger=Yes id=3 ; ');
        O.Verify();
    end;

    [Test]
    procedure DeleteAll_False_RaisesEventsPerRow()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        L.Reset();
        R.DeleteAll(false);
        O.Observe('deleteall_false', L.Text());
        O.Expect('deleteall_false', 'sub BeforeDelete runtrigger=No id=1 ; sub AfterDelete runtrigger=No id=1 ; sub BeforeDelete runtrigger=No id=2 ; sub AfterDelete runtrigger=No id=2 ; ');
        O.Verify();
    end;

    [Test]
    procedure DeleteAll_Default_Arg()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        L.Reset();
        R.DeleteAll();
        O.Observe('deleteall_default', L.Text());
        O.Expect('deleteall_default', 'sub BeforeDelete runtrigger=No id=1 ; sub AfterDelete runtrigger=No id=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure Delete_True_AndFalse_Events()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        L.Reset();
        R.Get(1);
        R.Delete(true);
        O.Observe('delete_true', L.Text());
        L.Reset();
        R.Get(2);
        R.Delete(false);
        O.Observe('delete_false', L.Text());
        O.Expect('delete_true', 'sub BeforeDelete runtrigger=Yes id=1 ; trigger OnDelete id=1 ; extA OnDelete ; sub AfterDelete runtrigger=Yes id=1 ; ');
        O.Expect('delete_false', 'sub BeforeDelete runtrigger=No id=2 ; sub AfterDelete runtrigger=No id=2 ; ');
        O.Verify();
    end;

    [Test]
    procedure Insert_Events_TriggerFalseAndTrue()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        R.Id := 1;
        R.Insert(false);
        O.Observe('insert_false', L.Text());
        L.Reset();
        R.Id := 2;
        R.Insert(true);
        O.Observe('insert_true', L.Text());
        L.Reset();
        R.Id := 3;
        R.Insert();
        O.Observe('insert_default', L.Text());
        O.Expect('insert_false', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Expect('insert_true', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=Yes sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; trigger OnInsert: sysid_null=No xrec_sysid_null=No ; extA OnInsert ; extB OnInsert ; sub AfterInsert runtrigger=Yes sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Expect('insert_default', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure Modify_Events_TriggerFalseAndTrue()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        R.Get(1);
        L.Reset();
        R.Name := 'b';
        R.Modify(false);
        O.Observe('modify_false', L.Text());
        L.Reset();
        R.Name := 'c';
        R.Modify(true);
        O.Observe('modify_true', L.Text());
        L.Reset();
        R.Name := 'd';
        R.Modify();
        O.Observe('modify_default', L.Text());
        O.Expect('modify_false', 'sub BeforeModify runtrigger=No xrec.Name=b ; sub AfterModify runtrigger=No xrec.Name=b ; ');
        O.Expect('modify_true', 'sub BeforeModify runtrigger=Yes xrec.Name=c ; trigger OnModify: xrec.Name=c ; extA OnModify: xrec.Name=c ; sub AfterModify runtrigger=Yes xrec.Name=c ; ');
        O.Expect('modify_default', 'sub BeforeModify runtrigger=No xrec.Name=d ; sub AfterModify runtrigger=No xrec.Name=d ; ');
        O.Verify();
    end;

    [Test]
    procedure Delete_Events_TriggerFalse_ExtensionTriggers()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        R.Get(1);
        L.Reset();
        R.Delete(false);
        O.Observe('delete_false_with_extension', L.Text());
        O.Expect('delete_false_with_extension', 'sub BeforeDelete runtrigger=No id=1 ; sub AfterDelete runtrigger=No id=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure Rename_Events_RunTriggerValue()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        R.Get(1);
        L.Reset();
        R.Rename(5);
        O.Observe('rename', L.Text());
        O.Expect('rename', 'sub BeforeRename runtrigger=Yes old=1 new=5 ; trigger OnRename: old=1 new=5 ; extA OnRename ; sub AfterRename runtrigger=Yes old=1 new=5 ; ');
        O.Verify();
    end;

    [TryFunction]
    local procedure TryRename(var R: Record "PA Ev Row"; NewId: Integer)
    begin
        R.Rename(NewId);
    end;

    [Test]
    procedure Validate_Events_RecXRecCurrFieldNo()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        R.Id := 1;
        R.Val := 3;
        R.Insert(false);
        L.Reset();
        R.Validate(Val, 7);
        O.Observe('validate_from_code', L.Text());
        L.Reset();
        R.Val := 9;
        O.Observe('plain_assign_no_events', L.Text() + '<end>');
        L.Reset();
        R.Validate(Val);
        O.Observe('validate_no_value', L.Text());
        L.Reset();
        R.Validate(Val, 7);
        O.Observe('validate_same_value', L.Text());
        L.Reset();
        R.Validate(Id, 1);
        O.Observe('validate_other_field_no_subscriber', L.Text() + '<end>');
        O.Expect('validate_from_code', 'sub BeforeValidate Val: rec=7 xrec=3 CurrFieldNo=0 ; trigger OnValidate Val: rec=7 xrec=3 CurrFieldNo=0 ; sub AfterValidate Val: rec=7 xrec=3 CurrFieldNo=0 ; ');
        O.Expect('plain_assign_no_events', '<end>');
        O.Expect('validate_no_value', 'sub BeforeValidate Val: rec=9 xrec=9 CurrFieldNo=0 ; trigger OnValidate Val: rec=9 xrec=9 CurrFieldNo=0 ; sub AfterValidate Val: rec=9 xrec=9 CurrFieldNo=0 ; ');
        O.Expect('validate_same_value', 'sub BeforeValidate Val: rec=7 xrec=9 CurrFieldNo=0 ; trigger OnValidate Val: rec=7 xrec=9 CurrFieldNo=0 ; sub AfterValidate Val: rec=7 xrec=9 CurrFieldNo=0 ; ');
        O.Expect('validate_other_field_no_subscriber', '<end>');
        O.Verify();
    end;

    [Test]
    procedure Validate_OnRecordWithXRecSetByCode()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
        X: Record "PA Ev Row";
    begin
        Start(L);
        R.Id := 1;
        R.Val := 3;
        R.Insert(false);
        R.Get(1);
        L.Reset();
        R.Val := 5;
        R.Modify(true);
        O.Observe('modify_after_field_assign', L.Text());
        O.Expect('modify_after_field_assign', 'sub BeforeModify runtrigger=Yes xrec.Name= ; trigger OnModify: xrec.Name= ; extA OnModify: xrec.Name= ; sub AfterModify runtrigger=Yes xrec.Name= ; ');
        O.Verify();
    end;

    [Test]
    procedure ModifyMissing_BeforeEventFires()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        L.Reset();
        R.Id := 99;
        asserterror R.Modify(true);
        O.ObserveError('modify_missing');
        O.Observe('events', L.Text());
        O.Expect('modify_missing|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''99''');
        O.Expect('modify_missing|code', 'DB:RecordNotFound');
        O.Expect('events', 'sub BeforeModify runtrigger=Yes xrec.Name= ; trigger OnModify: xrec.Name= ; extA OnModify: xrec.Name= ; ');
        O.Verify();
    end;

    [Test]
    procedure DeleteMissing_BeforeEventFires()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        L.Reset();
        R.Id := 99;
        asserterror R.Delete(true);
        O.ObserveError('delete_missing');
        O.Observe('events', L.Text());
        O.Expect('delete_missing|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''99''');
        O.Expect('delete_missing|code', 'DB:RecordNotFound');
        O.Expect('events', 'sub BeforeDelete runtrigger=Yes id=99 ; trigger OnDelete id=99 ; extA OnDelete ; ');
        O.Verify();
    end;

    [Test]
    procedure RenameMissing_And_RenameToExisting()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'a');
        Seed(2, 'b');
        L.Reset();
        R.Id := 99;
        asserterror R.Rename(100);
        O.ObserveError('rename_missing');
        O.Observe('events_missing', L.Text());
        L.Reset();
        R.DeleteAll();
        Seed(1, 'a');
        Seed(2, 'b');
        L.Reset();
        R.Get(1);
        asserterror R.Rename(2);
        O.ObserveError('rename_to_existing');
        O.Observe('events_to_existing', L.Text());
        O.Expect('rename_missing|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''99''');
        O.Expect('rename_missing|code', 'DB:RecordNotFound');
        O.Expect('events_missing', 'sub BeforeRename runtrigger=Yes old=99 new=100 ; trigger OnRename: old=99 new=100 ; extA OnRename ; ');
        O.Expect('rename_to_existing|text', 'The record in table PA Ev Row already exists. Identification fields and values: Id=''2''');
        O.Expect('rename_to_existing|code', 'DB:RecordExists');
        O.Expect('events_to_existing', 'sub BeforeRename runtrigger=Yes old=1 new=2 ; trigger OnRename: old=1 new=2 ; extA OnRename ; ');
        O.Verify();
    end;

    [Test]
    procedure RecordErrors_GetMissing_TestField_Modify()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        asserterror R.Get(77);
        O.ObserveError('get_missing');
        R.Id := 5;
        R.Name := 'x';
        asserterror R.Modify();
        O.ObserveError('modify_missing_no_trigger_arg');
        asserterror R.Delete();
        O.ObserveError('delete_missing');
        Seed(5, 'x');
        R.Id := 5;
        R.Reset();
        R.SetRange(Id, 1000);
        asserterror R.FindFirst();
        O.ObserveError('findfirst_empty');
        asserterror R.FindLast();
        O.ObserveError('findlast_empty');
        asserterror R.FindSet();
        O.ObserveError('findset_empty');
        R.Reset();
        R.DeleteAll();
        Seed(5, 'x');
        R.Get(5);
        asserterror R.TestField(Name, 'other');
        O.ObserveError('testfield_value');
        asserterror R.TestField(Val);
        O.ObserveError('testfield_zero');
        O.Expect('get_missing|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''77''');
        O.Expect('get_missing|code', 'DB:RecordNotFound');
        O.Expect('modify_missing_no_trigger_arg|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''5''');
        O.Expect('modify_missing_no_trigger_arg|code', 'DB:RecordNotFound');
        O.Expect('delete_missing|text', 'The PA Ev Row does not exist. Identification fields and values: Id=''5''');
        O.Expect('delete_missing|code', 'DB:RecordNotFound');
        O.Expect('findfirst_empty|text', 'There is no PA Ev Row within the filter.\\Filters: Id: 1000');
        O.Expect('findfirst_empty|code', 'DB:NothingInsideFilter');
        O.Expect('findlast_empty|text', 'There is no PA Ev Row within the filter.\\Filters: Id: 1000');
        O.Expect('findlast_empty|code', 'DB:NothingInsideFilter');
        O.Expect('findset_empty|text', 'There is no PA Ev Row within the filter.\\Filters: Id: 1000');
        O.Expect('findset_empty|code', 'DB:NothingInsideFilter');
        O.Expect('testfield_value|text', 'Name must be equal to ''other''  in PA Ev Row: Id=5. Current value is ''x''.');
        O.Expect('testfield_value|code', 'TestField');
        O.Expect('testfield_zero|text', 'Val must have a value in PA Ev Row: Id=5. It cannot be zero or empty.');
        O.Expect('testfield_zero|code', 'TestField');
        O.Verify();
    end;

    [Test]
    procedure XRec_SharedBetweenSubscribersTriggerAndExtension()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(1, 'mutate');
        R.Get(1);
        L.Reset();
        R.Name := 'new';
        R.Modify(true);
        O.Observe('modify', L.Text());
        O.Expect('modify', 'sub BeforeModify runtrigger=Yes xrec.Name=new ; trigger OnModify: xrec.Name=new ; extA OnModify: xrec.Name=new ; sub AfterModify runtrigger=Yes xrec.Name=new ; ');
        O.Verify();
    end;

    [Test]
    procedure ExtensionTriggers_TwoExtensionsSameTrigger_Order()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        L.Reset();
        R.Id := 1;
        R.Insert(true);
        O.Observe('insert_true', L.Text());
        L.Reset();
        R.Id := 2;
        R.Insert(false);
        O.Observe('insert_false', L.Text());
        O.Expect('insert_true', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=Yes sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; trigger OnInsert: sysid_null=No xrec_sysid_null=Yes ; extA OnInsert ; extB OnInsert ; sub AfterInsert runtrigger=Yes sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Expect('insert_false', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure Subscriber_Order_AcrossCodeunits()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        L.Reset();
        R.Id := 1;
        R.Insert(false);
        O.Observe('before_insert_order', L.Text());
        O.Expect('before_insert_order', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure StaticSubscriber_NotSingleInstance_State()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        L.Reset();
        R.Id := 1;
        R.Insert(false);
        R.Id := 2;
        R.Insert(false);
        R.Id := 3;
        R.Insert(false);
        O.Observe('log', L.Text());
        O.Expect('log', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Verify();
    end;

    [Test]
    procedure BindSubscription_Twice_Statement()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        Sub: Codeunit "PA Ev Manual";
    begin
        Start(L);
        BindSubscription(Sub);
        asserterror BindSubscription(Sub);
        O.ObserveError('bind_twice_same_instance');
        UnbindSubscription(Sub);
        O.Expect('bind_twice_same_instance|text', 'The binding of codeunit 69809 was unsuccessful. The codeunit has already been bound.');
        O.Expect('bind_twice_same_instance|code', 'EventBinding');
        O.Verify();
    end;

    [Test]
    procedure BindSubscription_ManualCountsAndUnbind()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        Sub: Codeunit "PA Ev Manual";
        R: Record "PA Ev Row";
    begin
        Start(L);
        BindSubscription(Sub);
        R.Id := 1;
        R.Insert(false);
        R.Id := 2;
        R.Insert(false);
        O.Observe('bound_log', L.Text());
        O.Observe('unbind_result', Format(UnbindSubscription(Sub)));
        L.Reset();
        R.Id := 3;
        R.Insert(false);
        O.Observe('after_unbind_log', L.Text());
        O.Observe('unbind_again_result', Format(UnbindSubscription(Sub)));
        O.Expect('bound_log', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; manual subscriber counter=1 ; order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; manual subscriber counter=2 ; ');
        O.Expect('unbind_result', 'Yes');
        O.Expect('after_unbind_log', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=No sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; sub AfterInsert runtrigger=No sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Expect('unbind_again_result', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure BindSubscription_NonManualCodeunit_Statement()
    var
        O: Codeunit "Probe Observer";
        Static: Codeunit "PA Ev Subs";
    begin
        asserterror BindSubscription(Static);
        O.ObserveError('bind_non_manual');
        O.Expect('bind_non_manual|text', 'The binding of codeunit 69806 was unsuccessful. The codeunit does not use manual binding');
        O.Expect('bind_non_manual|code', 'EventBinding');
        O.Verify();
    end;

    [Test]
    procedure UnbindSubscription_NonManualCodeunit()
    var
        O: Codeunit "Probe Observer";
        Static: Codeunit "PA Ev Subs";
    begin
        O.Observe('unbind_non_manual_result', TryUnbind(Static));
        O.Expect('unbind_non_manual_result', 'No');
        O.Verify();
    end;

    local procedure TryUnbind(var C: Codeunit "PA Ev Subs"): Text
    var
        Res: Boolean;
    begin
        if TryUnbindF(C, Res) then
            exit(Format(Res));
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryUnbindF(var C: Codeunit "PA Ev Subs"; var Res: Boolean)
    begin
        Res := UnbindSubscription(C);
    end;

    [Test]
    procedure SystemId_BeforeOnInsert_AndPresetBuffer()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
        R2: Record "PA Ev Row";
        Preset: Guid;
    begin
        Start(L);
        L.Reset();
        R.Id := 1;
        R.Insert(true);
        O.Observe('log_insert_true_empty_buffer', L.Text());
        O.Observe('sysid_assigned_after', Format(not IsNullGuid(R.SystemId)));
        Preset := CreateGuid();
        R2.Id := 2;
        R2.SystemId := Preset;
        R2.Insert(false);
        O.Observe('preset_systemid_kept_without_flag', Format(R2.SystemId = Preset));
        R2.Get(2);
        O.Observe('preset_systemid_stored_without_flag', Format(R2.SystemId = Preset));
        Clear(R2);
        R2.Id := 3;
        R2.SystemId := Preset;
        R2.Insert(false, true);
        R2.Get(3);
        O.Observe('preset_systemid_stored_with_insert_false_true', Format(R2.SystemId = Preset));
        O.Expect('log_insert_true_empty_buffer', 'order Alpha (codeunit 69806, declared 2nd of 3) ; sub BeforeInsert runtrigger=Yes sysid_null=No ; order Mid (codeunit 69806, declared 3rd of 3) ; order Zeta (codeunit 69806, declared 1st of 3) ; order codeunit 69807 ; trigger OnInsert: sysid_null=No xrec_sysid_null=Yes ; extA OnInsert ; extB OnInsert ; sub AfterInsert runtrigger=Yes sysid_null=No ; stateful static subscriber counter=1 ; ');
        O.Expect('sysid_assigned_after', 'Yes');
        O.Expect('preset_systemid_kept_without_flag', 'No');
        O.Expect('preset_systemid_stored_without_flag', 'No');
        O.Expect('preset_systemid_stored_with_insert_false_true', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure SystemId_InsertWithSystemIdProperty()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
        Preset: Guid;
    begin
        Start(L);
        Preset := CreateGuid();
        R.Id := 1;
        R.SystemId := Preset;
        R.Insert(true, true);
        R.Get(1);
        O.Observe('insert_true_true_keeps_preset', Format(R.SystemId = Preset));
        Preset := CreateGuid();
        Clear(R);
        R.Id := 2;
        R.SystemId := Preset;
        R.Insert(true);
        R.Get(2);
        O.Observe('insert_true_ignores_preset', Format(R.SystemId = Preset));
        O.Expect('insert_true_true_keeps_preset', 'Yes');
        O.Expect('insert_true_ignores_preset', 'No');
        O.Verify();
    end;

    [Test]
    procedure Find_NeighbourSearch_PrimaryKey()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(10, 'a');
        Seed(20, 'b');
        Seed(30, 'c');
        O.Observe('15_ge', FindForm(15, '=>'));
        O.Observe('15_le', FindForm(15, '=<'));
        O.Observe('15_both', FindForm(15, '=><'));
        O.Observe('20_ge', FindForm(20, '=>'));
        O.Observe('20_le', FindForm(20, '=<'));
        O.Observe('20_both', FindForm(20, '=><'));
        O.Observe('5_le', FindForm(5, '=<'));
        O.Observe('5_ge', FindForm(5, '=>'));
        O.Observe('5_both', FindForm(5, '=><'));
        O.Observe('35_ge', FindForm(35, '=>'));
        O.Observe('35_le', FindForm(35, '=<'));
        O.Observe('35_both', FindForm(35, '=><'));
        O.Observe('25_both_tie_neighbours_5_each', FindForm(25, '=><'));
        O.Observe('equal_20', FindForm(20, '='));
        O.Observe('equal_15', FindForm(15, '='));
        O.Observe('minus_first', FindForm(0, '-'));
        O.Observe('plus_last', FindForm(0, '+'));
        O.Observe('gt', FindForm(20, '>'));
        O.Observe('lt', FindForm(20, '<'));
        O.Expect('15_ge', 'found id=20');
        O.Expect('15_le', 'found id=10');
        O.Expect('15_both', 'found id=20');
        O.Expect('20_ge', 'found id=20');
        O.Expect('20_le', 'found id=20');
        O.Expect('20_both', 'found id=20');
        O.Expect('5_le', 'not found, id=5');
        O.Expect('5_ge', 'found id=10');
        O.Expect('5_both', 'found id=10');
        O.Expect('35_ge', 'not found, id=35');
        O.Expect('35_le', 'found id=30');
        O.Expect('35_both', 'found id=30');
        O.Expect('25_both_tie_neighbours_5_each', 'found id=30');
        O.Expect('equal_20', 'found id=20');
        O.Expect('equal_15', 'not found, id=15');
        O.Expect('minus_first', 'found id=10');
        O.Expect('plus_last', 'found id=30');
        O.Expect('gt', 'found id=30');
        O.Expect('lt', 'found id=10');
        O.Verify();
    end;

    local procedure FindForm(Id: Integer; Which: Text): Text
    var
        R: Record "PA Ev Row";
    begin
        R.Id := Id;
        if R.Find(Which) then
            exit('found id=' + Format(R.Id));
        exit('not found, id=' + Format(R.Id));
    end;

    [Test]
    procedure Find_NeighbourSearch_WithFilterAndOtherKey()
    var
        O: Codeunit "Probe Observer";
        L: Codeunit "PA Ev Log";
        R: Record "PA Ev Row";
    begin
        Start(L);
        Seed(10, 'c');
        Seed(20, 'b');
        Seed(30, 'a');
        R.SetRange(Id, 10, 20);
        R.Id := 25;
        O.Observe('filtered_25_le', TryFind(R, '=<'));
        R.Id := 25;
        O.Observe('filtered_25_ge', TryFind(R, '=>'));
        R.Id := 15;
        O.Observe('filtered_15_both', TryFind(R, '=><'));
        R.Reset();
        R.SetCurrentKey(Name);
        R.Name := 'bb';
        O.Observe('key_name_bb_ge', TryFind(R, '=>'));
        R.Name := 'bb';
        O.Observe('key_name_bb_le', TryFind(R, '=<'));
        R.Name := 'bb';
        O.Observe('key_name_bb_both', TryFind(R, '=><'));
        R.Reset();
        R.SetAscending(Id, false);
        R.Id := 15;
        O.Observe('descending_15_ge', TryFind(R, '=>'));
        R.Id := 15;
        O.Observe('descending_15_le', TryFind(R, '=<'));
        O.Expect('filtered_25_le', 'found id=20 name=b');
        O.Expect('filtered_25_ge', 'not found id=25');
        O.Expect('filtered_15_both', 'found id=20 name=b');
        O.Expect('key_name_bb_ge', 'found id=10 name=c');
        O.Expect('key_name_bb_le', 'found id=20 name=b');
        O.Expect('key_name_bb_both', 'found id=10 name=c');
        O.Expect('descending_15_ge', 'found id=10 name=c');
        O.Expect('descending_15_le', 'found id=20 name=b');
        O.Verify();
    end;

    local procedure TryFind(var R: Record "PA Ev Row"; Which: Text): Text
    var
        Res: Text;
    begin
        if TryFindF(R, Which, Res) then
            exit(Res);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryFindF(var R: Record "PA Ev Row"; Which: Text; var Res: Text)
    begin
        if R.Find(Which) then
            Res := 'found id=' + Format(R.Id) + ' name=' + R.Name
        else
            Res := 'not found id=' + Format(R.Id);
    end;

    // ---- BSK (al-runner issue 6924): BindSubscription on two instances of one codeunit, after UnbindSubscription, after Clear, on a copy of the
    // variable, on two variables of a SingleInstance manual codeunit, and on a codeunit with EventSubscriberInstance = StaticAutomatic written out.
    // Objects in BindSubscriptionKinds.Objects.al. Every result is ok or the error text and code. ----

    [TryFunction]
    local procedure BskTryBind(var C: Codeunit "LT BSK Manual")
    begin
        BindSubscription(C);
    end;

    [TryFunction]
    local procedure BskTryBindSI(var C: Codeunit "LT BSK Manual SI")
    begin
        BindSubscription(C);
    end;

    [TryFunction]
    local procedure BskTryBindStatic(var C: Codeunit "LT BSK Static Explicit")
    begin
        BindSubscription(C);
    end;

    local procedure BskResult(Ok: Boolean): Text
    var
        R: Text;
    begin
        if Ok then
            R := 'ok'
        else
            R := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(R);
    end;

    [Test]
    procedure BSK_Bind_TwoInstancesOfOneCodeunit()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        A: Codeunit "LT BSK Manual";
        B: Codeunit "LT BSK Manual";
    begin
        A.SetTag('1');
        B.SetTag('2');
        O.Observe('bind first', BskResult(BskTryBind(A)));
        O.Observe('bind second instance', BskResult(BskTryBind(B)));
        O.Observe('hits', Pub.Ping());
        O.Observe('unbind first', Format(UnbindSubscription(A)));
        O.Observe('hits after unbind first', Pub.Ping());
        O.Observe('unbind second', Format(UnbindSubscription(B)));
        O.Observe('hits after both', Pub.Ping());
        O.Expect('bind first', 'ok');
        O.Expect('bind second instance', 'ok');
        O.Expect('hits', 'AM1M2');
        O.Expect('unbind first', 'Yes');
        O.Expect('hits after unbind first', 'AM2');
        O.Expect('unbind second', 'Yes');
        O.Expect('hits after both', 'A');
        O.Verify();
    end;

    [Test]
    procedure BSK_Bind_AfterUnbind_SameInstance()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        A: Codeunit "LT BSK Manual";
    begin
        A.SetTag('1');
        O.Observe('bind', BskResult(BskTryBind(A)));
        O.Observe('unbind', Format(UnbindSubscription(A)));
        O.Observe('hits unbound', Pub.Ping());
        O.Observe('bind again', BskResult(BskTryBind(A)));
        O.Observe('hits rebound', Pub.Ping());
        O.Observe('bind third time', BskResult(BskTryBind(A)));
        O.Observe('unbind again', Format(UnbindSubscription(A)));
        O.Observe('hits end', Pub.Ping());
        O.Expect('bind', 'ok');
        O.Expect('unbind', 'Yes');
        O.Expect('hits unbound', 'A');
        O.Expect('bind again', 'ok');
        O.Expect('hits rebound', 'AM1');
        O.Expect('bind third time', 'The binding of codeunit 95393 was unsuccessful. The codeunit has already been bound.|EventBinding');
        O.Expect('unbind again', 'Yes');
        O.Expect('hits end', 'A');
        O.Verify();
    end;

    [Test]
    procedure BSK_Bind_AfterClear_And_OnCopy()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        A: Codeunit "LT BSK Manual";
        B: Codeunit "LT BSK Manual";
    begin
        A.SetTag('1');
        O.Observe('bind', BskResult(BskTryBind(A)));
        Clear(A);
        A.SetTag('C');
        O.Observe('hits after clear', Pub.Ping());
        O.Observe('bind after clear', BskResult(BskTryBind(A)));
        O.Observe('hits after rebind', Pub.Ping());
        O.Observe('unbind after clear', Format(UnbindSubscription(A)));
        O.Observe('hits after unbind', Pub.Ping());
        A.SetTag('3');
        O.Observe('bind original', BskResult(BskTryBind(A)));
        B := A;
        O.Observe('bind copy', BskResult(BskTryBind(B)));
        O.Observe('hits copy', Pub.Ping());
        O.Observe('unbind copy', Format(UnbindSubscription(B)));
        O.Observe('hits after unbind copy', Pub.Ping());
        O.Observe('unbind original', Format(UnbindSubscription(A)));
        O.Observe('hits end', Pub.Ping());
        O.Expect('bind', 'ok');
        O.Expect('hits after clear', 'A');
        O.Expect('bind after clear', 'ok');
        O.Expect('hits after rebind', 'AMC');
        O.Expect('unbind after clear', 'Yes');
        O.Expect('hits after unbind', 'A');
        O.Expect('bind original', 'ok');
        O.Expect('bind copy', 'The binding of codeunit 95393 was unsuccessful. The codeunit has already been bound.|EventBinding');
        O.Expect('hits copy', 'AM3');
        O.Expect('unbind copy', 'Yes');
        O.Expect('hits after unbind copy', 'A');
        O.Expect('unbind original', 'Yes');
        O.Expect('hits end', 'A');
        O.Verify();
    end;

    [Test]
    procedure BSK_Bind_SingleInstanceManual_TwoVariables()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        A: Codeunit "LT BSK Manual SI";
        B: Codeunit "LT BSK Manual SI";
    begin
        O.Observe('bind first', BskResult(BskTryBindSI(A)));
        O.Observe('bind second variable', BskResult(BskTryBindSI(B)));
        O.Observe('hits', Pub.Ping());
        O.Observe('unbind second variable', Format(UnbindSubscription(B)));
        O.Observe('hits after unbind second', Pub.Ping());
        O.Observe('unbind first', Format(UnbindSubscription(A)));
        O.Observe('hits end', Pub.Ping());
        O.Expect('bind first', 'ok');
        O.Expect('bind second variable', 'The binding of codeunit 95391 was unsuccessful. The codeunit has already been bound.|EventBinding');
        O.Expect('hits', 'SA');
        O.Expect('unbind second variable', 'Yes');
        O.Expect('hits after unbind second', 'A');
        O.Expect('unbind first', 'Yes');
        O.Expect('hits end', 'A');
        O.Verify();
    end;

    [Test]
    procedure BSK_Bind_StaticAutomaticExplicit()
    var
        O: Codeunit "Probe Observer";
        Pub: Codeunit "LT BSK Pub";
        S: Codeunit "LT BSK Static Explicit";
    begin
        O.Observe('hits unbound', Pub.Ping());
        O.Observe('bind', BskResult(BskTryBindStatic(S)));
        O.Observe('return value form', Format(BindSubscription(S)));
        O.Observe('unbind', Format(UnbindSubscription(S)));
        O.Observe('hits end', Pub.Ping());
        O.Expect('hits unbound', 'A');
        O.Expect('bind', 'The binding of codeunit 95392 was unsuccessful. The codeunit does not use manual binding|EventBinding');
        O.Expect('return value form', 'No');
        O.Expect('unbind', 'No');
        O.Expect('hits end', 'A');
        O.Verify();
    end;
}
