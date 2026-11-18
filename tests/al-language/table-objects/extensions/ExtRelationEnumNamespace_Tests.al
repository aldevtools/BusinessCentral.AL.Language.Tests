// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the enums, tables and table extension of
//   ExtRelationEnumNamespace_Enums.al, _Targets.al, _Table.al and _Ext.al (ids 97044-97049)
// Probe: written against al-runner issue 8297; measured on a local BC 29.1 OnPrem w1 container.
// BC versions: 27.0+
//
// CLAIM: a TableRelation that a table extension sets, by modify() of a field of the table or on a
// field of its own, applies its `if (Field = const(Member))` arms when the extension's file cannot
// name the enum of the condition field: its namespace (ErnMfg) has no `using` of the enums'
// namespace (ErnEnums). The member is one of the field's own enum, a member an enumextension adds
// included, and where(Status = const(Released)) on an Enum field of the related table filters as
// written. Validate accepts a value the applying arm's table holds, raises "... cannot be found in
// the related table (...)" for one it does not (code DB:RecordNotFound when the related field is
// not the whole key, DB:PrimRecordNotFound when it is), and accepts any value when no arm applies;
// the table's own arms (Item, Resource) keep working beside the extension's. A rename of a related
// row rewrites the referencing rows whose arm applies, and only those.
// Shaped like Base Application's "Mfg. Item Journal Line" (Item Journal Line."Order No.") and
// "Mfg. Standard Cost Worksheet" (Standard Cost Worksheet."No.", a Machine Center rename).
// local object: the test codeunit; the objects it reads live in four namespaces on purpose.

namespace ALLanguage.Coverage.ErnTests;

using ALLanguage.Coverage.ErnEnums;
using ALLanguage.Coverage.ErnJournal;
using ALLanguage.Coverage.ErnTargets;

codeunit 97044 "LT ERN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ModifyRelation_EnumOfUnusedNamespace_ReleasedOrder_Accepted()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertOrder(ProdOrder.Status::Released, 'ERN-O1');
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        Line.Validate("Order No.", 'ERN-O1');
        Observer.Observe('order_no', Line."Order No.");
        Observer.Expect('order_no', 'ERN-O1');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_EnumOfUnusedNamespace_MissingOrder_Error()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        asserterror Line.Validate("Order No.", 'ERN-NONE');
        Observer.ObserveError('missing');
        Observer.Observe('order_no', Line."Order No.");
        Observer.Expect('missing|text', 'The field Order No. of table LT ERN Line contains a value (ERN-NONE) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Expect('order_no', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_EnumOfUnusedNamespace_PlannedOrder_Error()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertOrder(ProdOrder.Status::Planned, 'ERN-O2');
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        asserterror Line.Validate("Order No.", 'ERN-O2');
        Observer.ObserveError('planned');
        Observer.Expect('planned|text', 'The field Order No. of table LT ERN Line contains a value (ERN-O2) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('planned|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_EnumOfUnusedNamespace_OtherOrderType_Accepted()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        Line.Init();
        Line."Order Type" := Line."Order Type"::Transfer;
        Line.Validate("Order No.", 'ERN-NONE');
        Observer.Observe('transfer_order_no', Line."Order No.");
        Line."Order Type" := Line."Order Type"::" ";
        Line.Validate("Order No.", 'ERN-NONE2');
        Observer.Observe('blank_order_no', Line."Order No.");
        Observer.Expect('transfer_order_no', 'ERN-NONE');
        Observer.Expect('blank_order_no', 'ERN-NONE2');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_EnumExtensionMember_MachineAndItem_Accepted()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertMachineCenter('ERN-M1');
        InsertItem('ERN-I1');
        Line.Init();
        Line.Type := Line.Type::"Machine Center";
        Line.Validate("No.", 'ERN-M1');
        Observer.Observe('machine_no', Line."No.");
        Line.Type := Line.Type::Item;
        Line.Validate("No.", 'ERN-I1');
        Observer.Observe('item_no', Line."No.");
        Observer.Expect('machine_no', 'ERN-M1');
        Observer.Expect('item_no', 'ERN-I1');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_EnumExtensionMember_MissingMachine_Error()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertItem('ERN-I1');
        Line.Init();
        Line.Type := Line.Type::"Machine Center";
        asserterror Line.Validate("No.", 'ERN-I1');
        Observer.ObserveError('machine');
        Observer.Expect('machine|text', 'The field No. of table LT ERN Line contains a value (ERN-I1) that cannot be found in the related table (LT ERN Machine Center).');
        Observer.Expect('machine|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_BaseArm_MachineNumberAsItem_Error()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertMachineCenter('ERN-M1');
        Line.Init();
        Line.Type := Line.Type::Item;
        asserterror Line.Validate("No.", 'ERN-M1');
        Observer.ObserveError('item');
        Observer.Expect('item|text', 'The field No. of table LT ERN Line contains a value (ERN-M1) that cannot be found in the related table (LT ERN Item).');
        Observer.Expect('item|code', 'DB:PrimRecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_Rename_MachineCenter_FollowsExtensionArm()
    var
        Observer: Codeunit "Probe Observer";
        MachineCenter: Record "LT ERN Machine Center";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertMachineCenter('ERN-M1');
        InsertLine(1, Line.Type::"Machine Center", 'ERN-M1');
        InsertLine(2, Line.Type::"Work Center", 'ERN-M1');
        InsertLine(3, Line.Type::Item, 'ERN-M1');
        MachineCenter.Get('ERN-M1');
        MachineCenter.Rename('ERN-M2');
        Line.Get(1);
        Observer.Observe('machine_line', Line."No.");
        Line.Get(2);
        Observer.Observe('work_line', Line."No.");
        Line.Get(3);
        Observer.Observe('item_line', Line."No.");
        Observer.Expect('machine_line', 'ERN-M2');
        Observer.Expect('work_line', 'ERN-M1');
        Observer.Expect('item_line', 'ERN-M1');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_Rename_ReleasedOrder_FollowsExtensionArm()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertOrder(ProdOrder.Status::Released, 'ERN-O1');
        InsertOrderLine(1, Line."Order Type"::Production, 'ERN-O1');
        InsertOrderLine(2, Line."Order Type"::Transfer, 'ERN-O1');
        ProdOrder.Get(ProdOrder.Status::Released, 'ERN-O1');
        ProdOrder.Rename(ProdOrder.Status::Released, 'ERN-O3');
        Line.Get(1);
        Observer.Observe('production_line', Line."Order No.");
        Line.Get(2);
        Observer.Observe('transfer_line', Line."Order No.");
        Observer.Expect('production_line', 'ERN-O3');
        Observer.Expect('transfer_line', 'ERN-O1');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionField_EnumOfUnusedNamespace_ReleasedOrder_Accepted()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        InsertOrder(ProdOrder.Status::Released, 'ERN-O1');
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        Line.Validate("Order Ref", 'ERN-O1');
        Observer.Observe('order_ref', Line."Order Ref");
        Line."Order Type" := Line."Order Type"::Transfer;
        Line.Validate("Order Ref", 'ERN-NONE');
        Observer.Observe('transfer_order_ref', Line."Order Ref");
        Observer.Expect('order_ref', 'ERN-O1');
        Observer.Expect('transfer_order_ref', 'ERN-NONE');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionField_EnumOfUnusedNamespace_MissingOrder_Error()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        asserterror Line.Validate("Order Ref", 'ERN-NONE');
        Observer.ObserveError('missing');
        Observer.Expect('missing|text', 'The field Order Ref of table LT ERN Line contains a value (ERN-NONE) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        ProdOrder: Record "LT ERN Order";
        Item: Record "LT ERN Item";
        Resource: Record "LT ERN Resource";
        WorkCenter: Record "LT ERN Work Center";
        MachineCenter: Record "LT ERN Machine Center";
        Line: Record "LT ERN Line";
    begin
        ProdOrder.DeleteAll();
        Item.DeleteAll();
        Resource.DeleteAll();
        WorkCenter.DeleteAll();
        MachineCenter.DeleteAll();
        Line.DeleteAll();
    end;

    local procedure InsertOrder(Status: Enum "LT ERN Order Status"; No: Code[20])
    var
        ProdOrder: Record "LT ERN Order";
    begin
        ProdOrder.Status := Status;
        ProdOrder."No." := No;
        ProdOrder.Insert();
    end;

    local procedure InsertItem(No: Code[20])
    var
        Item: Record "LT ERN Item";
    begin
        Item."No." := No;
        Item.Insert();
    end;

    local procedure InsertMachineCenter(No: Code[20])
    var
        MachineCenter: Record "LT ERN Machine Center";
    begin
        MachineCenter."No." := No;
        MachineCenter.Insert();
    end;

    local procedure InsertLine(Id: Integer; Type: Enum "LT ERN Source Type"; No: Code[20])
    var
        Line: Record "LT ERN Line";
    begin
        Line.Id := Id;
        Line.Type := Type;
        Line."No." := No;
        Line.Insert();
    end;

    local procedure InsertOrderLine(Id: Integer; OrderType: Enum "LT ERN Order Type"; No: Code[20])
    var
        Line: Record "LT ERN Line";
    begin
        Line.Id := Id;
        Line."Order Type" := OrderType;
        Line."Order No." := No;
        Line.Insert();
    end;
}
