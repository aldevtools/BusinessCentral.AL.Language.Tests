// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the enums, tables and table extensions of
//   ExtRelationEnumNamespace_Enums.al, _Targets.al, _Table.al, _Ext.al, _XaExt.al and _XaTwin.al (ids 97044-97049),
//   and of tests/al-language-xapp-a/table-objects/ExtRelationEnumNamespaceXaEnum.al and _XaTable.al (LT ERN XA Kind 97996,
//   LT ERN XA Line 97996)
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
// The same arms answer FieldRef.Relation (the table of the arm that applies, 0 when none does), the
// rows of Table Relations Metadata (one per arm, the member's ordinal as Condition Value, the
// table's arms before the extension's) and the Field row (RelationTableNo and RelationFieldNo 0, as
// for every conditional relation).
// The member may be qualified with the condition field ("Order Type"::Production). The extension
// may be in another app than the table (the table and its enum in XApp A). When the extension's own
// namespace declares an enum of the same name as the field's (ErnXaTwin, another app than the
// field's enum), the member is still the field's enum's: Production of LT ERN XA Kind (ordinal 1),
// not of the twin (ordinal 2).
// Shaped like Base Application's "Mfg. Item Journal Line" (Item Journal Line."Order No." and
// "Operation No.") and "Mfg. Standard Cost Worksheet" (Standard Cost Worksheet."No.", a Machine
// Center rename).
// local object: the test codeunit; the objects it reads live in several namespaces and two apps on purpose.

namespace ALLanguage.Coverage.ErnTests;

using ALLanguage.Coverage.ErnEnums;
using ALLanguage.Coverage.ErnJournal;
using ALLanguage.Coverage.ErnTargets;
using ALLanguage.Coverage.ErnXa;
using ALLanguage.Coverage.ErnXaEnums;
using System.Reflection;

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

    [Test]
    procedure FieldRefRelation_ModifyRelation_TableOfTheArmThatApplies()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        Observer.Observe('order_no_production', TableName(RelationOf(Line, Line.FieldNo("Order No."))));
        Observer.Observe('order_ref_production', TableName(RelationOf(Line, Line.FieldNo("Order Ref"))));
        Line."Order Type" := Line."Order Type"::Transfer;
        Observer.Observe('order_no_transfer', TableName(RelationOf(Line, Line.FieldNo("Order No."))));
        Observer.Observe('order_ref_transfer', TableName(RelationOf(Line, Line.FieldNo("Order Ref"))));
        Line."Order Type" := Line."Order Type"::" ";
        Observer.Observe('order_no_blank', TableName(RelationOf(Line, Line.FieldNo("Order No."))));
        Line.Type := Line.Type::"Machine Center";
        Observer.Observe('no_machine_center', TableName(RelationOf(Line, Line.FieldNo("No."))));
        Line.Type := Line.Type::"Work Center";
        Observer.Observe('no_work_center', TableName(RelationOf(Line, Line.FieldNo("No."))));
        Line.Type := Line.Type::Item;
        Observer.Observe('no_item', TableName(RelationOf(Line, Line.FieldNo("No."))));
        Line.Type := Line.Type::Resource;
        Observer.Observe('no_resource', TableName(RelationOf(Line, Line.FieldNo("No."))));
        Observer.Expect('order_no_production', 'Order');
        Observer.Expect('order_ref_production', 'Order');
        Observer.Expect('order_no_transfer', '0');
        Observer.Expect('order_ref_transfer', '0');
        Observer.Expect('order_no_blank', '0');
        Observer.Expect('no_machine_center', 'Machine Center');
        Observer.Expect('no_work_center', 'Work Center');
        Observer.Expect('no_item', 'Item');
        Observer.Expect('no_resource', 'Resource');
        Observer.Verify();
    end;

    [Test]
    procedure TableRelationsMetadata_ModifyRelation_OrderNo_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        ObserveRelationRows(Observer, 'order_no', Line.FieldNo("Order No."));
        ObserveRelationRows(Observer, 'order_ref', Line.FieldNo("Order Ref"));
        Observer.Expect('order_no_rows', '1');
        Observer.Expect('order_no_1_rel_cond', '1.1');
        Observer.Expect('order_no_1_cond_field', '2');
        Observer.Expect('order_no_1_cond_type', 'CONST');
        Observer.Expect('order_no_1_cond_value', '1');
        Observer.Expect('order_no_1_related', 'Order.2');
        Observer.Expect('order_ref_rows', '1');
        Observer.Expect('order_ref_1_rel_cond', '1.1');
        Observer.Expect('order_ref_1_cond_field', '2');
        Observer.Expect('order_ref_1_cond_type', 'CONST');
        Observer.Expect('order_ref_1_cond_value', '1');
        Observer.Expect('order_ref_1_related', 'Order.2');
        Observer.Verify();
    end;

    [Test]
    procedure TableRelationsMetadata_ModifyRelation_No_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        ObserveRelationRows(Observer, 'no', Line.FieldNo("No."));
        Observer.Expect('no_rows', '4');
        Observer.Expect('no_1_rel_cond', '1.1');
        Observer.Expect('no_1_cond_field', '4');
        Observer.Expect('no_1_cond_type', 'CONST');
        Observer.Expect('no_1_cond_value', '0');
        Observer.Expect('no_1_related', 'Item.1');
        Observer.Expect('no_2_rel_cond', '2.1');
        Observer.Expect('no_2_cond_field', '4');
        Observer.Expect('no_2_cond_type', 'CONST');
        Observer.Expect('no_2_cond_value', '3');
        Observer.Expect('no_2_related', 'Resource.1');
        Observer.Expect('no_3_rel_cond', '3.1');
        Observer.Expect('no_3_cond_field', '4');
        Observer.Expect('no_3_cond_type', 'CONST');
        Observer.Expect('no_3_cond_value', '2');
        Observer.Expect('no_3_related', 'Machine Center.1');
        Observer.Expect('no_4_rel_cond', '4.1');
        Observer.Expect('no_4_cond_field', '4');
        Observer.Expect('no_4_cond_type', 'CONST');
        Observer.Expect('no_4_cond_value', '1');
        Observer.Expect('no_4_related', 'Work Center.1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_ModifyRelation_RelationTableNo()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        ObserveFieldRelation(Observer, 'order_no', Line.FieldNo("Order No."));
        ObserveFieldRelation(Observer, 'order_ref', Line.FieldNo("Order Ref"));
        ObserveFieldRelation(Observer, 'no', Line.FieldNo("No."));
        Observer.Expect('order_no_relation', '0.0');
        Observer.Expect('order_ref_relation', '0.0');
        Observer.Expect('no_relation', '0.0');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionField_FieldQualifiedMember_Validate()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        Line: Record "LT ERN Line";
    begin
        Initialize();
        ClearLastError();
        InsertOrder(ProdOrder.Status::Released, 'ERN-O1');
        Line.Init();
        Line."Order Type" := Line."Order Type"::Production;
        Observer.Observe('released', Format(TryValidateOrderRefQ(Line, 'ERN-O1')));
        Observer.ObserveError('released');
        Observer.Observe('missing', Format(TryValidateOrderRefQ(Line, 'ERN-NONE')));
        Observer.ObserveError('missing');
        Line."Order Type" := Line."Order Type"::Transfer;
        Observer.Observe('transfer', Format(TryValidateOrderRefQ(Line, 'ERN-NONE')));
        Observer.ObserveError('transfer');
        Observer.Expect('released', 'Yes');
        Observer.Expect('released|text', '');
        Observer.Expect('released|code', '');
        Observer.Expect('missing', 'No');
        Observer.Expect('missing|text', 'The field Order Ref Q of table LT ERN Line contains a value (ERN-NONE) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Expect('transfer', 'Yes');
        Observer.Expect('transfer|text', '');
        Observer.Expect('transfer|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionField_SameNamedEnumInExtensionNamespace_Validate()
    var
        Observer: Codeunit "Probe Observer";
        XaLine: Record "LT ERN XA Line";
    begin
        Initialize();
        ClearLastError();
        XaLine.Init();
        XaLine.Kind := XaLine.Kind::Production;
        Observer.Observe('production', Format(TryValidateTwinRef(XaLine, 'ERN-NONE')));
        Observer.ObserveError('production');
        XaLine.Kind := XaLine.Kind::Transfer;
        Observer.Observe('transfer', Format(TryValidateTwinRef(XaLine, 'ERN-NONE')));
        Observer.ObserveError('transfer');
        Observer.Expect('production', 'No');
        Observer.Expect('production|text', 'The field Twin Ref of table LT ERN XA Line contains a value (ERN-NONE) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('production|code', 'DB:RecordNotFound');
        Observer.Expect('transfer', 'Yes');
        Observer.Expect('transfer|text', '');
        Observer.Expect('transfer|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRelation_ExtensionInDependentApp_Validate()
    var
        Observer: Codeunit "Probe Observer";
        ProdOrder: Record "LT ERN Order";
        XaLine: Record "LT ERN XA Line";
    begin
        Initialize();
        ClearLastError();
        InsertOrder(ProdOrder.Status::Released, 'ERN-O1');
        InsertOrder(ProdOrder.Status::Planned, 'ERN-O2');
        XaLine.Init();
        XaLine.Kind := XaLine.Kind::Production;
        Observer.Observe('released', Format(TryValidateXaOrderNo(XaLine, 'ERN-O1')));
        Observer.ObserveError('released');
        Observer.Observe('planned', Format(TryValidateXaOrderNo(XaLine, 'ERN-O2')));
        Observer.ObserveError('planned');
        Observer.Observe('missing', Format(TryValidateXaOrderNo(XaLine, 'ERN-NONE')));
        Observer.ObserveError('missing');
        XaLine.Kind := XaLine.Kind::Transfer;
        Observer.Observe('transfer', Format(TryValidateXaOrderNo(XaLine, 'ERN-NONE')));
        Observer.ObserveError('transfer');
        XaLine.Kind := XaLine.Kind::Production;
        Observer.Observe('fieldref_production', TableName(XaRelation(XaLine)));
        Observer.Expect('released', 'Yes');
        Observer.Expect('released|text', '');
        Observer.Expect('released|code', '');
        Observer.Expect('planned', 'No');
        Observer.Expect('planned|text', 'The field Order No. of table LT ERN XA Line contains a value (ERN-O2) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('planned|code', 'DB:RecordNotFound');
        Observer.Expect('missing', 'No');
        Observer.Expect('missing|text', 'The field Order No. of table LT ERN XA Line contains a value (ERN-NONE) that cannot be found in the related table (LT ERN Order).');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Expect('transfer', 'Yes');
        Observer.Expect('transfer|text', '');
        Observer.Expect('transfer|code', '');
        Observer.Expect('fieldref_production', 'Order');
        Observer.Verify();
    end;

    local procedure XaRelation(XaLine: Record "LT ERN XA Line"): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(XaLine);
        exit(RecRef.Field(XaLine.FieldNo("Order No.")).Relation());
    end;

    [TryFunction]
    local procedure TryValidateOrderRefQ(var Line: Record "LT ERN Line"; Value: Code[20])
    begin
        Line.Validate("Order Ref Q", Value);
    end;

    [TryFunction]
    local procedure TryValidateTwinRef(var XaLine: Record "LT ERN XA Line"; Value: Code[20])
    begin
        XaLine.Validate("Twin Ref", Value);
    end;

    [TryFunction]
    local procedure TryValidateXaOrderNo(var XaLine: Record "LT ERN XA Line"; Value: Code[20])
    begin
        XaLine.Validate("Order No.", Value);
    end;

    local procedure RelationOf(Line: Record "LT ERN Line"; FieldNo: Integer): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Line);
        exit(RecRef.Field(FieldNo).Relation());
    end;

    // The related table by its name in this probe, so the expected texts do not depend on object ids.
    local procedure TableName(TableId: Integer): Text
    begin
        case TableId of
            0:
                exit('0');
            Database::"LT ERN Order":
                exit('Order');
            Database::"LT ERN Item":
                exit('Item');
            Database::"LT ERN Resource":
                exit('Resource');
            Database::"LT ERN Work Center":
                exit('Work Center');
            Database::"LT ERN Machine Center":
                exit('Machine Center');
        end;
        exit('other');
    end;

    local procedure ObserveRelationRows(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer)
    var
        Relations: Record "Table Relations Metadata";
        Row: Integer;
        Prefix: Text;
    begin
        Relations.SetRange("Table ID", Database::"LT ERN Line");
        Relations.SetRange("Field No.", FieldNo);
        Observer.Observe(Name + '_rows', Format(Relations.Count()));
        if Relations.FindSet() then
            repeat
                Row += 1;
                Prefix := Name + '_' + Format(Row) + '_';
                Observer.Observe(Prefix + 'rel_cond', Format(Relations."Relation No.") + '.' + Format(Relations."Condition No."));
                Observer.Observe(Prefix + 'cond_field', Format(Relations."Condition Field No."));
                Observer.Observe(Prefix + 'cond_type', Format(Relations."Condition Type"));
                Observer.Observe(Prefix + 'cond_value', Relations."Condition Value");
                Observer.Observe(Prefix + 'related', TableName(Relations."Related Table ID") + '.' + Format(Relations."Related Field No."));
            until Relations.Next() = 0;
    end;

    local procedure ObserveFieldRelation(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer)
    var
        Fld: Record Field;
    begin
        Fld.Get(Database::"LT ERN Line", FieldNo);
        Observer.Observe(Name + '_relation', TableName(Fld.RelationTableNo) + '.' + Format(Fld.RelationFieldNo));
    end;

    local procedure Initialize()
    var
        ProdOrder: Record "LT ERN Order";
        Item: Record "LT ERN Item";
        Resource: Record "LT ERN Resource";
        WorkCenter: Record "LT ERN Work Center";
        MachineCenter: Record "LT ERN Machine Center";
        Line: Record "LT ERN Line";
        XaLine: Record "LT ERN XA Line";
    begin
        XaLine.DeleteAll();
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
