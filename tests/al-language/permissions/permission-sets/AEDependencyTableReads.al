// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); shared table 50001 "ALT Shape 01"; Permissions Mock (131006) from the dependency;
//   self-contained permission sets 65501 65502, test codeunit 65503
// Probe: observe-only. Reads of tables of the Base Application (a dependency app) under a permission set that does not grant them, one table that has rows in the
//   test database (Customer, Item) and one that is empty there (Standard Cost Worksheet). The own-app cases (empty table and table with rows) are in Y24PermReads.al and
//   CpPermLeads.al, the denial of Customer.FindFirst in Y69SystemGrants.al.
// Facts: per table and per set (no grant of the table; the table granted by tabledata R): Get of an existing and of a missing key, Find('-'), Find('+'), Find('='), FindFirst,
//   FindLast, FindSet, IsEmpty, Count, CountApprox, CalcSums, Next on a fresh record, GetBySystemId (existing and missing), a filter that matches no row on a table that has
//   rows, RecordRef.FindFirst, RecordRef.Get with a RecordId, CalcFields of a FlowField over another table. Each shape is one try: result, error text and error code.
// local object: the two permission sets are what is under test (a set that grants no Base Application table, a set that grants Customer only).
// BC versions: 27, 28, 29

permissionset 65501 "LT AE Own Only"
{
    Assignable = true;
    Permissions = tabledata "ALT Shape 01" = R;
}

permissionset 65502 "LT AE Customer R"
{
    Assignable = true;
    Permissions = tabledata Customer = R;
}

codeunit 65503 "LT AE Dependency Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        StartedHere: Boolean;
        CustomerKey: Code[20];
        CustomerSystemId: Guid;
        CustomerRecordId: RecordId;
        ItemKey: Code[20];
        ItemSystemId: Guid;

    local procedure StartSet(SetName: Code[20])
    begin
        StartedHere := not Mock.IsStarted();
        if StartedHere then
            Mock.Start();
        Mock.ClearAssignments();
        Mock.Set(SetName);
    end;

    local procedure StopSet()
    begin
        Mock.ClearAssignments();
        if StartedHere then
            Mock.Stop();
    end;

    local procedure Remember()
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        Observer.Observe('customer_rows', Format(Customer.Count() > 0));
        Observer.Observe('item_rows', Format(Item.Count() > 0));
        if Customer.FindFirst() then begin
            CustomerKey := Customer."No.";
            CustomerSystemId := Customer.SystemId;
            CustomerRecordId := Customer.RecordId();
        end;
        if Item.FindFirst() then begin
            ItemKey := Item."No.";
            ItemSystemId := Item.SystemId;
        end;
    end;

    local procedure Report(Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'denied: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
        ClearLastError();
    end;

    [TryFunction]
    local procedure Try_Customer_find_dash()
    var
        Rec: Record Customer;
    begin
        if Rec.Find('-') then;
    end;

    [TryFunction]
    local procedure Try_Customer_find_plus()
    var
        Rec: Record Customer;
    begin
        if Rec.Find('+') then;
    end;

    [TryFunction]
    local procedure Try_Customer_find_eq()
    var
        Rec: Record Customer;
    begin
        if Rec.Find('=') then;
    end;

    [TryFunction]
    local procedure Try_Customer_findfirst()
    var
        Rec: Record Customer;
    begin
        if Rec.FindFirst() then;
    end;

    [TryFunction]
    local procedure Try_Customer_findlast()
    var
        Rec: Record Customer;
    begin
        if Rec.FindLast() then;
    end;

    [TryFunction]
    local procedure Try_Customer_findset()
    var
        Rec: Record Customer;
    begin
        if Rec.FindSet() then;
    end;

    [TryFunction]
    local procedure Try_Customer_isempty()
    var
        Rec: Record Customer;
    begin
        if Rec.IsEmpty() then;
    end;

    [TryFunction]
    local procedure Try_Customer_count()
    var
        Rec: Record Customer;
    begin
        if Rec.Count() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Customer_countapprox()
    var
        Rec: Record Customer;
    begin
        if Rec.CountApprox() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Customer_next()
    var
        Rec: Record Customer;
    begin
        if Rec.Next() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Customer_recref_findfirst()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Customer);
        RecRef.FindFirst();
    end;

    [TryFunction]
    local procedure Try_Customer_getbysystemid_missing()
    var
        Rec: Record Customer;
    begin
        if Rec.GetBySystemId(CreateGuid()) then;
    end;

    [TryFunction]
    local procedure Try_Customer_get_existing()
    var
        Rec: Record Customer;
    begin
        if Rec.Get(CustomerKey) then;
    end;

    [TryFunction]
    local procedure Try_Customer_get_missing()
    var
        Rec: Record Customer;
    begin
        if Rec.Get('LT-MISSING') then;
    end;

    [TryFunction]
    local procedure Try_Customer_getbysystemid_existing()
    var
        Rec: Record Customer;
    begin
        if Rec.GetBySystemId(CustomerSystemId) then;
    end;

    [TryFunction]
    local procedure Try_Customer_filter_no_match()
    var
        Rec: Record Customer;
    begin
        Rec.SetRange("No.", 'LT-MISSING');
        if Rec.FindFirst() then;
    end;

    [TryFunction]
    local procedure Try_Customer_calcsums()
    var
        Rec: Record Customer;
    begin
        Rec.CalcSums("Credit Limit (LCY)");
    end;

    [TryFunction]
    local procedure Try_Customer_calcfields_flowfield()
    var
        Rec: Record Customer;
    begin
        Rec.CalcFields(Balance);
    end;

    [TryFunction]
    local procedure Try_Customer_recref_get_recordid()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Customer);
        RecRef.Get(CustomerRecordId);
    end;

    [Test]
    procedure Read_Customer_SetOwnOnly_Part1()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Customer_find_dash', Try_Customer_find_dash());
        Report('Customer_find_plus', Try_Customer_find_plus());
        Report('Customer_find_eq', Try_Customer_find_eq());
        Report('Customer_findfirst', Try_Customer_findfirst());
        Report('Customer_findlast', Try_Customer_findlast());
        Report('Customer_findset', Try_Customer_findset());
        Report('Customer_isempty', Try_Customer_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_find_dash', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_find_plus', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_find_eq', 'ok');
        Observer.Expect('Customer_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_findlast', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_findset', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_isempty', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Customer_SetOwnOnly_Part2()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Customer_count', Try_Customer_count());
        Report('Customer_countapprox', Try_Customer_countapprox());
        Report('Customer_next', Try_Customer_next());
        Report('Customer_recref_findfirst', Try_Customer_recref_findfirst());
        Report('Customer_getbysystemid_missing', Try_Customer_getbysystemid_missing());
        Report('Customer_get_existing', Try_Customer_get_existing());
        Report('Customer_get_missing', Try_Customer_get_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_count', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_countapprox', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_next', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_recref_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_getbysystemid_missing', 'ok');
        Observer.Expect('Customer_get_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_get_missing', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Customer_SetOwnOnly_Part3()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Customer_getbysystemid_existing', Try_Customer_getbysystemid_existing());
        Report('Customer_filter_no_match', Try_Customer_filter_no_match());
        Report('Customer_calcsums', Try_Customer_calcsums());
        Report('Customer_calcfields_flowfield', Try_Customer_calcfields_flowfield());
        Report('Customer_recref_get_recordid', Try_Customer_recref_get_recordid());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_getbysystemid_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_filter_no_match', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_calcsums', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_calcfields_flowfield', 'denied: Sorry, the current permissions prevented the action. (TableData 379 Detailed Cust. Ledg. Entry IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_recref_get_recordid', 'denied: Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Customer_SetCustomerR_Part1()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Customer_find_dash', Try_Customer_find_dash());
        Report('Customer_find_plus', Try_Customer_find_plus());
        Report('Customer_find_eq', Try_Customer_find_eq());
        Report('Customer_findfirst', Try_Customer_findfirst());
        Report('Customer_findlast', Try_Customer_findlast());
        Report('Customer_findset', Try_Customer_findset());
        Report('Customer_isempty', Try_Customer_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_find_dash', 'ok');
        Observer.Expect('Customer_find_plus', 'ok');
        Observer.Expect('Customer_find_eq', 'ok');
        Observer.Expect('Customer_findfirst', 'ok');
        Observer.Expect('Customer_findlast', 'ok');
        Observer.Expect('Customer_findset', 'ok');
        Observer.Expect('Customer_isempty', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Customer_SetCustomerR_Part2()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Customer_count', Try_Customer_count());
        Report('Customer_countapprox', Try_Customer_countapprox());
        Report('Customer_next', Try_Customer_next());
        Report('Customer_recref_findfirst', Try_Customer_recref_findfirst());
        Report('Customer_getbysystemid_missing', Try_Customer_getbysystemid_missing());
        Report('Customer_get_existing', Try_Customer_get_existing());
        Report('Customer_get_missing', Try_Customer_get_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_count', 'ok');
        Observer.Expect('Customer_countapprox', 'ok');
        Observer.Expect('Customer_next', 'ok');
        Observer.Expect('Customer_recref_findfirst', 'ok');
        Observer.Expect('Customer_getbysystemid_missing', 'ok');
        Observer.Expect('Customer_get_existing', 'ok');
        Observer.Expect('Customer_get_missing', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Customer_SetCustomerR_Part3()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Customer_getbysystemid_existing', Try_Customer_getbysystemid_existing());
        Report('Customer_filter_no_match', Try_Customer_filter_no_match());
        Report('Customer_calcsums', Try_Customer_calcsums());
        Report('Customer_calcfields_flowfield', Try_Customer_calcfields_flowfield());
        Report('Customer_recref_get_recordid', Try_Customer_recref_get_recordid());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Customer_getbysystemid_existing', 'ok');
        Observer.Expect('Customer_filter_no_match', 'ok');
        Observer.Expect('Customer_calcsums', 'ok');
        Observer.Expect('Customer_calcfields_flowfield', 'denied: Sorry, the current permissions prevented the action. (TableData 379 Detailed Cust. Ledg. Entry IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Customer_recref_get_recordid', 'ok');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Item_find_dash()
    var
        Rec: Record Item;
    begin
        if Rec.Find('-') then;
    end;

    [TryFunction]
    local procedure Try_Item_find_plus()
    var
        Rec: Record Item;
    begin
        if Rec.Find('+') then;
    end;

    [TryFunction]
    local procedure Try_Item_find_eq()
    var
        Rec: Record Item;
    begin
        if Rec.Find('=') then;
    end;

    [TryFunction]
    local procedure Try_Item_findfirst()
    var
        Rec: Record Item;
    begin
        if Rec.FindFirst() then;
    end;

    [TryFunction]
    local procedure Try_Item_findlast()
    var
        Rec: Record Item;
    begin
        if Rec.FindLast() then;
    end;

    [TryFunction]
    local procedure Try_Item_findset()
    var
        Rec: Record Item;
    begin
        if Rec.FindSet() then;
    end;

    [TryFunction]
    local procedure Try_Item_isempty()
    var
        Rec: Record Item;
    begin
        if Rec.IsEmpty() then;
    end;

    [TryFunction]
    local procedure Try_Item_count()
    var
        Rec: Record Item;
    begin
        if Rec.Count() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Item_countapprox()
    var
        Rec: Record Item;
    begin
        if Rec.CountApprox() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Item_next()
    var
        Rec: Record Item;
    begin
        if Rec.Next() = 0 then;
    end;

    [TryFunction]
    local procedure Try_Item_recref_findfirst()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Item);
        RecRef.FindFirst();
    end;

    [TryFunction]
    local procedure Try_Item_getbysystemid_missing()
    var
        Rec: Record Item;
    begin
        if Rec.GetBySystemId(CreateGuid()) then;
    end;

    [TryFunction]
    local procedure Try_Item_get_existing()
    var
        Rec: Record Item;
    begin
        if Rec.Get(ItemKey) then;
    end;

    [TryFunction]
    local procedure Try_Item_get_missing()
    var
        Rec: Record Item;
    begin
        if Rec.Get('LT-MISSING') then;
    end;

    [TryFunction]
    local procedure Try_Item_getbysystemid_existing()
    var
        Rec: Record Item;
    begin
        if Rec.GetBySystemId(ItemSystemId) then;
    end;

    [TryFunction]
    local procedure Try_Item_filter_no_match()
    var
        Rec: Record Item;
    begin
        Rec.SetRange("No.", 'LT-MISSING');
        if Rec.FindFirst() then;
    end;

    [TryFunction]
    local procedure Try_Item_calcsums()
    var
        Rec: Record Item;
    begin
        Rec.CalcSums("Unit Price");
    end;

    [TryFunction]
    local procedure Try_Item_calcfields_flowfield()
    var
        Rec: Record Item;
    begin
        Rec.CalcFields(Inventory);
    end;

    [Test]
    procedure Read_Item_SetOwnOnly_Part1()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Item_find_dash', Try_Item_find_dash());
        Report('Item_find_plus', Try_Item_find_plus());
        Report('Item_find_eq', Try_Item_find_eq());
        Report('Item_findfirst', Try_Item_findfirst());
        Report('Item_findlast', Try_Item_findlast());
        Report('Item_findset', Try_Item_findset());
        Report('Item_isempty', Try_Item_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_find_dash', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_find_plus', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_find_eq', 'ok');
        Observer.Expect('Item_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_findlast', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_findset', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_isempty', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Item_SetOwnOnly_Part2()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Item_count', Try_Item_count());
        Report('Item_countapprox', Try_Item_countapprox());
        Report('Item_next', Try_Item_next());
        Report('Item_recref_findfirst', Try_Item_recref_findfirst());
        Report('Item_getbysystemid_missing', Try_Item_getbysystemid_missing());
        Report('Item_get_existing', Try_Item_get_existing());
        Report('Item_get_missing', Try_Item_get_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_count', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_countapprox', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_next', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_recref_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_getbysystemid_missing', 'ok');
        Observer.Expect('Item_get_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_get_missing', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Item_SetOwnOnly_Part3()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('Item_getbysystemid_existing', Try_Item_getbysystemid_existing());
        Report('Item_filter_no_match', Try_Item_filter_no_match());
        Report('Item_calcsums', Try_Item_calcsums());
        Report('Item_calcfields_flowfield', Try_Item_calcfields_flowfield());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_getbysystemid_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_filter_no_match', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_calcsums', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_calcfields_flowfield', 'denied: Sorry, the current permissions prevented the action. (TableData 32 Item Ledger Entry IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Item_SetCustomerR_Part1()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Item_find_dash', Try_Item_find_dash());
        Report('Item_find_plus', Try_Item_find_plus());
        Report('Item_find_eq', Try_Item_find_eq());
        Report('Item_findfirst', Try_Item_findfirst());
        Report('Item_findlast', Try_Item_findlast());
        Report('Item_findset', Try_Item_findset());
        Report('Item_isempty', Try_Item_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_find_dash', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_find_plus', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_find_eq', 'ok');
        Observer.Expect('Item_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_findlast', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_findset', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_isempty', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Item_SetCustomerR_Part2()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Item_count', Try_Item_count());
        Report('Item_countapprox', Try_Item_countapprox());
        Report('Item_next', Try_Item_next());
        Report('Item_recref_findfirst', Try_Item_recref_findfirst());
        Report('Item_getbysystemid_missing', Try_Item_getbysystemid_missing());
        Report('Item_get_existing', Try_Item_get_existing());
        Report('Item_get_missing', Try_Item_get_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_count', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_countapprox', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_next', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_recref_findfirst', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_getbysystemid_missing', 'ok');
        Observer.Expect('Item_get_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_get_missing', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Item_SetCustomerR_Part3()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('Item_getbysystemid_existing', Try_Item_getbysystemid_existing());
        Report('Item_filter_no_match', Try_Item_filter_no_match());
        Report('Item_calcsums', Try_Item_calcsums());
        Report('Item_calcfields_flowfield', Try_Item_calcfields_flowfield());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('Item_getbysystemid_existing', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_filter_no_match', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item Read: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_calcsums', 'denied: Sorry, the current permissions prevented the action. (TableData 27 Item IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Expect('Item_calcfields_flowfield', 'denied: Sorry, the current permissions prevented the action. (TableData 32 Item Ledger Entry IndirectRead: AL Language Coverage Tests) [DB:ClientReadDenied]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_StdCost_find_dash()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.Find('-') then;
    end;

    [TryFunction]
    local procedure Try_StdCost_find_plus()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.Find('+') then;
    end;

    [TryFunction]
    local procedure Try_StdCost_find_eq()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.Find('=') then;
    end;

    [TryFunction]
    local procedure Try_StdCost_findfirst()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.FindFirst() then;
    end;

    [TryFunction]
    local procedure Try_StdCost_findlast()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.FindLast() then;
    end;

    [TryFunction]
    local procedure Try_StdCost_findset()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.FindSet() then;
    end;

    [TryFunction]
    local procedure Try_StdCost_isempty()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.IsEmpty() then;
    end;

    [TryFunction]
    local procedure Try_StdCost_count()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.Count() = 0 then;
    end;

    [TryFunction]
    local procedure Try_StdCost_countapprox()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.CountApprox() = 0 then;
    end;

    [TryFunction]
    local procedure Try_StdCost_next()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.Next() = 0 then;
    end;

    [TryFunction]
    local procedure Try_StdCost_recref_findfirst()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Standard Cost Worksheet");
        RecRef.FindFirst();
    end;

    [TryFunction]
    local procedure Try_StdCost_getbysystemid_missing()
    var
        Rec: Record "Standard Cost Worksheet";
    begin
        if Rec.GetBySystemId(CreateGuid()) then;
    end;

    [Test]
    procedure Read_StdCost_SetOwnOnly_Part1()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('StdCost_find_dash', Try_StdCost_find_dash());
        Report('StdCost_find_plus', Try_StdCost_find_plus());
        Report('StdCost_find_eq', Try_StdCost_find_eq());
        Report('StdCost_findfirst', Try_StdCost_findfirst());
        Report('StdCost_findlast', Try_StdCost_findlast());
        Report('StdCost_findset', Try_StdCost_findset());
        Report('StdCost_isempty', Try_StdCost_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('StdCost_find_dash', 'ok');
        Observer.Expect('StdCost_find_plus', 'ok');
        Observer.Expect('StdCost_find_eq', 'ok');
        Observer.Expect('StdCost_findfirst', 'ok');
        Observer.Expect('StdCost_findlast', 'ok');
        Observer.Expect('StdCost_findset', 'ok');
        Observer.Expect('StdCost_isempty', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_StdCost_SetOwnOnly_Part2()
    begin
        Remember();
        StartSet('LT AE Own Only');
        Report('StdCost_count', Try_StdCost_count());
        Report('StdCost_countapprox', Try_StdCost_countapprox());
        Report('StdCost_next', Try_StdCost_next());
        Report('StdCost_recref_findfirst', Try_StdCost_recref_findfirst());
        Report('StdCost_getbysystemid_missing', Try_StdCost_getbysystemid_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('StdCost_count', 'ok');
        Observer.Expect('StdCost_countapprox', 'ok');
        Observer.Expect('StdCost_next', 'ok');
        Observer.Expect('StdCost_recref_findfirst', 'denied: The Standard Cost Worksheet table is empty. [DB:TableIsEmpty]');
        Observer.Expect('StdCost_getbysystemid_missing', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_StdCost_SetCustomerR_Part1()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('StdCost_find_dash', Try_StdCost_find_dash());
        Report('StdCost_find_plus', Try_StdCost_find_plus());
        Report('StdCost_find_eq', Try_StdCost_find_eq());
        Report('StdCost_findfirst', Try_StdCost_findfirst());
        Report('StdCost_findlast', Try_StdCost_findlast());
        Report('StdCost_findset', Try_StdCost_findset());
        Report('StdCost_isempty', Try_StdCost_isempty());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('StdCost_find_dash', 'ok');
        Observer.Expect('StdCost_find_plus', 'ok');
        Observer.Expect('StdCost_find_eq', 'ok');
        Observer.Expect('StdCost_findfirst', 'ok');
        Observer.Expect('StdCost_findlast', 'ok');
        Observer.Expect('StdCost_findset', 'ok');
        Observer.Expect('StdCost_isempty', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Read_StdCost_SetCustomerR_Part2()
    begin
        Remember();
        StartSet('LT AE Customer R');
        Report('StdCost_count', Try_StdCost_count());
        Report('StdCost_countapprox', Try_StdCost_countapprox());
        Report('StdCost_next', Try_StdCost_next());
        Report('StdCost_recref_findfirst', Try_StdCost_recref_findfirst());
        Report('StdCost_getbysystemid_missing', Try_StdCost_getbysystemid_missing());
        StopSet();
        Observer.Expect('customer_rows', 'Yes');
        Observer.Expect('item_rows', 'Yes');
        Observer.Expect('StdCost_count', 'ok');
        Observer.Expect('StdCost_countapprox', 'ok');
        Observer.Expect('StdCost_next', 'ok');
        Observer.Expect('StdCost_recref_findfirst', 'denied: The Standard Cost Worksheet table is empty. [DB:TableIsEmpty]');
        Observer.Expect('StdCost_getbysystemid_missing', 'ok');
        Observer.Verify();
    end;
}
