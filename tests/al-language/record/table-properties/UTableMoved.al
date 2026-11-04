// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-movedfrom-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 599): MovedFrom on a table, MovedTo on a table (needs ObsoleteState = PendingMove),
// and MovedFrom / MovedTo on fields of a table extension that extends a Base Application table. Each table and field is usable at run time.
// Object ids 69582, 69583, 69781 and 69780.

table 69582 "LT U Moved From"
{
    DataClassification = SystemMetadata;
    MovedFrom = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5f6';

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69583 "LT U Moved To"
{
    DataClassification = SystemMetadata;
    ObsoleteState = PendingMove;
    ObsoleteReason = 'Moved to another app.';
    ObsoleteTag = '1.0';
    MovedTo = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5f7';

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 69781 "LT U Customer Moved Ext" extends Customer
{
    fields
    {
        field(69583; "LT U Moved In"; Text[20])
        {
            DataClassification = SystemMetadata;
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(69584; "LT U Moved Out"; Text[20])
        {
            DataClassification = SystemMetadata;
            ObsoleteState = PendingMove;
            ObsoleteReason = 'Moved to another app.';
            ObsoleteTag = '1.0';
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
    }
}

codeunit 69780 "LT U Moved Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MovedFromMovedTo_Tables_AreUsable()
    var
        Observer: Codeunit "Probe Observer";
        FromTable: Record "LT U Moved From";
        ToTable: Record "LT U Moved To";
    begin
        FromTable.DeleteAll();
        ToTable.DeleteAll();
        FromTable.Id := 1;
        FromTable.Name := 'from';
        Observer.Observe('moved_from_insert', Format(FromTable.Insert()));
        ToTable.Id := 1;
        ToTable.Name := 'to';
        Observer.Observe('moved_to_insert', Format(ToTable.Insert()));
        Clear(FromTable);
        FromTable.Get(1);
        Observer.Observe('moved_from_name', FromTable.Name);
        Clear(ToTable);
        ToTable.Get(1);
        Observer.Observe('moved_to_name', ToTable.Name);
        Observer.Observe('moved_from_table_name', FromTable.TableName());
        Observer.Observe('moved_to_table_name', ToTable.TableName());
        Observer.Expect('moved_from_insert', 'Yes');
        Observer.Expect('moved_to_insert', 'Yes');
        Observer.Expect('moved_from_name', 'from');
        Observer.Expect('moved_to_name', 'to');
        Observer.Expect('moved_from_table_name', 'LT U Moved From');
        Observer.Expect('moved_to_table_name', 'LT U Moved To');
        Observer.Verify();
    end;

    [Test]
    procedure MovedFromMovedTo_TableExtensionFields_AreUsable()
    var
        Observer: Codeunit "Probe Observer";
        Cust: Record Customer;
        RecRef: RecordRef;
    begin
        Cust.Init();
        Cust."No." := 'LTU-MOVED';
        Cust."LT U Moved In" := 'in';
        Cust."LT U Moved Out" := 'out';
        Observer.Observe('ext_insert', Format(Cust.Insert()));
        Clear(Cust);
        Cust.Get('LTU-MOVED');
        Observer.Observe('moved_in_field', Cust."LT U Moved In");
        Observer.Observe('moved_out_field', Cust."LT U Moved Out");
        Observer.Observe('moved_in_field_caption', Cust.FieldCaption("LT U Moved In"));
        Observer.Observe('moved_in_field_no', Format(Cust.FieldNo("LT U Moved In")));
        Observer.Observe('moved_out_field_no', Format(Cust.FieldNo("LT U Moved Out")));
        RecRef.GetTable(Cust);
        Observer.Observe('moved_in_field_name', RecRef.Field(69583).Name());
        Observer.Observe('moved_out_field_name', RecRef.Field(69584).Name());
        Cust.Delete();
        Observer.Expect('ext_insert', 'Yes');
        Observer.Expect('moved_in_field', 'in');
        Observer.Expect('moved_out_field', 'out');
        Observer.Expect('moved_in_field_caption', 'LT U Moved In');
        Observer.Expect('moved_in_field_no', '69583');
        Observer.Expect('moved_out_field_no', '69584');
        Observer.Expect('moved_in_field_name', 'LT U Moved In');
        Observer.Expect('moved_out_field_name', 'LT U Moved Out');
        Observer.Verify();
    end;
}
