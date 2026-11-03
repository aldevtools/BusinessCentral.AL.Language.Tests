// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method
// Scope: in-scope. Record.AreFieldsLoaded on a record that was never fetched, after assigning a field the value it already has, and after Init.
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 67355 (table) and 67356 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: AreFieldsLoaded for the assigned field, for another field and for both, on a new record variable and after Init; a non-default assignment next to it.
//   Corpus issue 576 item 2.
// BC versions: 27, 28, 29

table 67355 "LT AFL Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Quantity; Decimal) { }
        field(3; Name; Text[30]) { }
        field(4; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67356 "LT AFL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ask(Name: Text; var Rec: Record "LT AFL Table"; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_quantity', Format(Rec.AreFieldsLoaded(Quantity)));
        Observer.Observe(Name + '_name', Format(Rec.AreFieldsLoaded(Name)));
        Observer.Observe(Name + '_flag', Format(Rec.AreFieldsLoaded(Flag)));
        Observer.Observe(Name + '_id', Format(Rec.AreFieldsLoaded(Id)));
        Observer.Observe(Name + '_quantity_and_name', Format(Rec.AreFieldsLoaded(Quantity, Name)));
    end;

    [Test]
    procedure AreFieldsLoaded_NewRecordNothingAssigned()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Ask('new', Rec, Observer);
        Observer.Expect('new_quantity', 'No');
        Observer.Expect('new_name', 'No');
        Observer.Expect('new_flag', 'No');
        Observer.Expect('new_id', 'No');
        Observer.Expect('new_quantity_and_name', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterAssigningTheDefaultValue()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Quantity := 0;
        Ask('quantity0', Rec, Observer);
        Observer.Expect('quantity0_quantity', 'Yes');
        Observer.Expect('quantity0_name', 'Yes');
        Observer.Expect('quantity0_flag', 'Yes');
        Observer.Expect('quantity0_id', 'Yes');
        Observer.Expect('quantity0_quantity_and_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterAssigningTheDefaultValueTextAndBoolean()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Name := '';
        Rec.Flag := false;
        Ask('nameflag', Rec, Observer);
        Observer.Expect('nameflag_quantity', 'Yes');
        Observer.Expect('nameflag_name', 'Yes');
        Observer.Expect('nameflag_flag', 'Yes');
        Observer.Expect('nameflag_id', 'Yes');
        Observer.Expect('nameflag_quantity_and_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterAssigningAnotherValue()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Quantity := 5;
        Ask('quantity5', Rec, Observer);
        Observer.Expect('quantity5_quantity', 'Yes');
        Observer.Expect('quantity5_name', 'Yes');
        Observer.Expect('quantity5_flag', 'Yes');
        Observer.Expect('quantity5_id', 'Yes');
        Observer.Expect('quantity5_quantity_and_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterInit()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Init();
        Ask('init', Rec, Observer);
        Observer.Expect('init_quantity', 'No');
        Observer.Expect('init_name', 'No');
        Observer.Expect('init_flag', 'No');
        Observer.Expect('init_id', 'No');
        Observer.Expect('init_quantity_and_name', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterInitAndAssigningTheDefaultValue()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Init();
        Rec.Quantity := 0;
        Ask('init_quantity0', Rec, Observer);
        Observer.Expect('init_quantity0_quantity', 'Yes');
        Observer.Expect('init_quantity0_name', 'Yes');
        Observer.Expect('init_quantity0_flag', 'Yes');
        Observer.Expect('init_quantity0_id', 'Yes');
        Observer.Expect('init_quantity0_quantity_and_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AreFieldsLoaded_AfterInitAndAssigningAnotherValue()
    var
        Rec: Record "LT AFL Table";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Init();
        Rec.Quantity := 5;
        Ask('init_quantity5', Rec, Observer);
        Observer.Expect('init_quantity5_quantity', 'Yes');
        Observer.Expect('init_quantity5_name', 'Yes');
        Observer.Expect('init_quantity5_flag', 'Yes');
        Observer.Expect('init_quantity5_id', 'Yes');
        Observer.Expect('init_quantity5_quantity_and_name', 'Yes');
        Observer.Verify();
    end;
}
