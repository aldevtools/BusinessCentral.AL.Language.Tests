// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74147, test codeunit 74148
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 3 (NP Retail blockers): Record.AreFieldsLoaded on a record that was filled by assignment or Init and never fetched,
// after Insert, after SetLoadFields followed by Find, FindFirst, FindSet and Get, after a plain copy of a fetched record, and on a temporary record
// (assigned, inserted, fetched with and without SetLoadFields). A fresh record that was never touched and the field list after Get are pinned in
// record/lt-record-read/RcAMisc.al and record/TestRecordPartialLoad.al.
// BC versions: 27, 28, 29

table 74147 "LT AFL Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74148 "LT AFL Are Fields Loaded"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AFL Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Qty := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Qty := 20;
        Row.Insert();
    end;

    [Test]
    procedure AreFieldsLoaded_AssignedNeverFetched()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AFL Row";
    begin
        Observer.Observe('fresh_id', Format(Row.AreFieldsLoaded(Id)));
        Row.Id := 5;
        Row.Name := 'x';
        Observer.Observe('assigned_id', Format(Row.AreFieldsLoaded(Id)));
        Observer.Observe('assigned_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('assigned_qty', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Observe('assigned_all', Format(Row.AreFieldsLoaded(Id, Name, Qty)));
        Observer.Observe('assigned_name_value', Row.Name);
        Observer.Expect('fresh_id', 'No');
        Observer.Expect('assigned_id', 'Yes');
        Observer.Expect('assigned_name', 'Yes');
        Observer.Expect('assigned_qty', 'Yes');
        Observer.Expect('assigned_all', 'Yes');
        Observer.Expect('assigned_name_value', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_InitNeverFetched()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AFL Row";
    begin
        Row.Init();
        Observer.Observe('init_id', Format(Row.AreFieldsLoaded(Id)));
        Observer.Observe('init_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('init_all', Format(Row.AreFieldsLoaded(Id, Name, Qty)));
        Row.Validate(Qty, 3);
        Observer.Observe('validated_qty', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Observe('validated_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Expect('init_id', 'No');
        Observer.Expect('init_name', 'No');
        Observer.Expect('init_all', 'No');
        Observer.Expect('validated_qty', 'Yes');
        Observer.Expect('validated_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AFL Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 7;
        Row.Name := 'seven';
        Observer.Observe('before_insert_name', Format(Row.AreFieldsLoaded(Name)));
        Row.Insert();
        Observer.Observe('after_insert_id', Format(Row.AreFieldsLoaded(Id)));
        Observer.Observe('after_insert_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('after_insert_all', Format(Row.AreFieldsLoaded(Id, Name, Qty)));
        Row.Qty := 1;
        Row.Modify();
        Observer.Observe('after_modify_all', Format(Row.AreFieldsLoaded(Id, Name, Qty)));
        Observer.Expect('before_insert_name', 'Yes');
        Observer.Expect('after_insert_id', 'Yes');
        Observer.Expect('after_insert_name', 'Yes');
        Observer.Expect('after_insert_all', 'Yes');
        Observer.Expect('after_modify_all', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_SetLoadFieldsThenFetch()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AFL Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Observer.Observe('findfirst_id', Format(Row.AreFieldsLoaded(Id)));
        Observer.Observe('findfirst_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('findfirst_qty', Format(Row.AreFieldsLoaded(Qty)));
        Clear(Row);
        Row.SetLoadFields(Name);
        Row.Find('-');
        Observer.Observe('find_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('find_qty', Format(Row.AreFieldsLoaded(Qty)));
        Clear(Row);
        Row.SetLoadFields(Qty);
        Row.FindSet();
        Observer.Observe('findset_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('findset_qty', Format(Row.AreFieldsLoaded(Qty)));
        Row.Next();
        Observer.Observe('next_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('next_qty', Format(Row.AreFieldsLoaded(Qty)));
        Clear(Row);
        Row.SetLoadFields(Name);
        Row.Get(2);
        Observer.Observe('get_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('get_qty', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Expect('findfirst_id', 'Yes');
        Observer.Expect('findfirst_name', 'Yes');
        Observer.Expect('findfirst_qty', 'No');
        Observer.Expect('find_name', 'Yes');
        Observer.Expect('find_qty', 'No');
        Observer.Expect('findset_name', 'No');
        Observer.Expect('findset_qty', 'Yes');
        Observer.Expect('next_name', 'No');
        Observer.Expect('next_qty', 'Yes');
        Observer.Expect('get_name', 'Yes');
        Observer.Expect('get_qty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_CopyOfPartialRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AFL Row";
        Dup: Record "LT AFL Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get(1);
        Dup := Row;
        Observer.Observe('copy_name', Format(Dup.AreFieldsLoaded(Name)));
        Observer.Observe('copy_qty', Format(Dup.AreFieldsLoaded(Qty)));
        Dup.Copy(Row);
        Observer.Observe('copycall_name', Format(Dup.AreFieldsLoaded(Name)));
        Observer.Observe('copycall_qty', Format(Dup.AreFieldsLoaded(Qty)));
        Observer.Expect('copy_name', 'Yes');
        Observer.Expect('copy_qty', 'No');
        Observer.Expect('copycall_name', 'Yes');
        Observer.Expect('copycall_qty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT AFL Row" temporary;
    begin
        Observer.Observe('fresh_name', Format(Temp.AreFieldsLoaded(Name)));
        Temp.Id := 1;
        Temp.Name := 'one';
        Observer.Observe('assigned_name', Format(Temp.AreFieldsLoaded(Name)));
        Temp.Insert();
        Observer.Observe('inserted_name', Format(Temp.AreFieldsLoaded(Name)));
        Observer.Observe('inserted_qty', Format(Temp.AreFieldsLoaded(Qty)));
        Clear(Temp);
        Temp.FindFirst();
        Observer.Observe('found_name', Format(Temp.AreFieldsLoaded(Name)));
        Observer.Observe('found_qty', Format(Temp.AreFieldsLoaded(Qty)));
        Clear(Temp);
        Temp.SetLoadFields(Name);
        Temp.FindFirst();
        Observer.Observe('partial_name', Format(Temp.AreFieldsLoaded(Name)));
        Observer.Observe('partial_qty', Format(Temp.AreFieldsLoaded(Qty)));
        Clear(Temp);
        Temp.SetLoadFields(Name);
        Temp.Get(1);
        Observer.Observe('partial_get_name', Format(Temp.AreFieldsLoaded(Name)));
        Observer.Observe('partial_get_qty', Format(Temp.AreFieldsLoaded(Qty)));
        Observer.Expect('fresh_name', 'No');
        Observer.Expect('assigned_name', 'Yes');
        Observer.Expect('inserted_name', 'Yes');
        Observer.Expect('inserted_qty', 'Yes');
        Observer.Expect('found_name', 'Yes');
        Observer.Expect('found_qty', 'Yes');
        Observer.Expect('partial_name', 'Yes');
        Observer.Expect('partial_qty', 'Yes');
        Observer.Expect('partial_get_name', 'Yes');
        Observer.Expect('partial_get_qty', 'Yes');
        Observer.Verify();
    end;
}
