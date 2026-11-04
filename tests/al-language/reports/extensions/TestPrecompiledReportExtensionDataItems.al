// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021), and Base Application report 302 "Get Demand To Reserve" with its
// reportextension 929 "Asm. Get Demand To Reserve" (shipped precompiled in Base Application).
//
// CLAIM: a data item that a reportextension shipped inside Base Application adds to a Base
// Application report is part of that report when it runs:
//   * the added data item iterates its table and its own DataItemTableView applies: reportextension
//     929 adds AssemblyLine over "Assembly Line", filtered to Order lines of Type Item with a
//     non-zero "Remaining Quantity (Base)";
//   * the extension's own OnPreDataItem decides whether it runs: it breaks unless the report's
//     DemandType is All or Assembly Components, and the base report's SalesOrderLine breaks unless
//     it is All or Sales Orders, so the demand types give different answers;
//   * what the added data item collects is read back through the extension's GetAssemblyLines,
//     beside the base report's GetSalesOrderLines, on the same report instance. Counts are of this
//     test's own documents: the demo company holds sales order lines the base data item returns too.
//
// The report is run with RunModal and not Run: Run frees the variable's report instance when it
// ends, so a getter called after it reads a new, unrun one. That is how Base Application's own
// Reservation Worksheet calls it. Each test Commits first because RunModal refuses to start inside
// a write transaction.
//
// Written by agent stma-auto-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4837.
codeunit 68760 "RXP Precompiled DataItems"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('OkGetDemandToReserve')]
    procedure DemandAll_ReturnsTheAssemblyLineTheExtensionsDataItemIterates()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        InsertDemand(5, 5);

        RunGetDemandToReserve("Reservation Demand Type"::All, TempAssemblyLine, TempSalesLine);

        Assert.AreEqual(1, AssemblyLinesOf(TempAssemblyLine), 'the extension data item returns the assembly line');
        Assert.AreEqual(1, SalesLinesOf(TempSalesLine), 'the base data item still returns the sales line');
    end;

    [Test]
    [HandlerFunctions('OkGetDemandToReserve')]
    procedure DemandSalesOrders_TheExtensionsOnPreDataItemBreaksTheAssemblyDataItem()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        InsertDemand(5, 5);

        RunGetDemandToReserve("Reservation Demand Type"::"Sales Orders", TempAssemblyLine, TempSalesLine);

        Assert.AreEqual(0, AssemblyLinesOf(TempAssemblyLine), 'the extension OnPreDataItem breaks for Sales Orders');
        Assert.AreEqual(1, SalesLinesOf(TempSalesLine), 'the sales line is still returned for Sales Orders');
    end;

    [Test]
    [HandlerFunctions('OkGetDemandToReserve')]
    procedure DemandAssemblyComponents_ReturnsOnlyTheAssemblyLine()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        InsertDemand(5, 5);

        RunGetDemandToReserve("Reservation Demand Type"::"Assembly Components", TempAssemblyLine, TempSalesLine);

        Assert.AreEqual(1, AssemblyLinesOf(TempAssemblyLine), 'the assembly line is returned for Assembly Components');
        Assert.AreEqual(0, SalesLinesOf(TempSalesLine), 'the base SalesOrderLine breaks for Assembly Components');
    end;

    [Test]
    [HandlerFunctions('OkGetDemandToReserve')]
    procedure ZeroRemainingQuantity_TheExtensionsDataItemTableViewExcludesTheLine()
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
    begin
        InsertDemand(0, 5);

        RunGetDemandToReserve("Reservation Demand Type"::All, TempAssemblyLine, TempSalesLine);

        Assert.AreEqual(0, AssemblyLinesOf(TempAssemblyLine), 'a line with no remaining quantity is outside the data item view');
        Assert.AreEqual(1, SalesLinesOf(TempSalesLine), 'the sales line, which has quantity, is returned');
    end;

    // The CRONUS demo data holds sales order lines the base data item returns too, so each count is
    // of this test's own document only.
    local procedure AssemblyLinesOf(var TempAssemblyLine: Record "Assembly Line" temporary): Integer
    begin
        TempAssemblyLine.SetRange("Document No.", 'RXPASM');
        exit(TempAssemblyLine.Count());
    end;

    local procedure SalesLinesOf(var TempSalesLine: Record "Sales Line" temporary): Integer
    begin
        TempSalesLine.SetRange("Document No.", 'RXPSO');
        exit(TempSalesLine.Count());
    end;

    local procedure InsertDemand(AssemblyRemainingQtyBase: Decimal; SalesOutstandingQtyBase: Decimal)
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        SalesLine: Record "Sales Line";
    begin
        Item.SetRange("No.", 'RXPITEM');
        Item.DeleteAll(false);
        AssemblyLine.SetRange("Document No.", 'RXPASM');
        AssemblyLine.DeleteAll(false);
        SalesLine.SetRange("Document No.", 'RXPSO');
        SalesLine.DeleteAll(false);

        Clear(Item);
        Item."No." := 'RXPITEM';
        Item.Type := Item.Type::Inventory;
        Item.Insert(false);

        Clear(AssemblyLine);
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
        AssemblyLine."Document No." := 'RXPASM';
        AssemblyLine."Line No." := 10000;
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine."No." := Item."No.";
        AssemblyLine."Remaining Quantity (Base)" := AssemblyRemainingQtyBase;
        AssemblyLine.Reserve := AssemblyLine.Reserve::Optional;
        AssemblyLine.Insert(false);

        Clear(SalesLine);
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'RXPSO';
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Outstanding Qty. (Base)" := SalesOutstandingQtyBase;
        SalesLine.Reserve := SalesLine.Reserve::Optional;
        SalesLine.Insert(false);

        Commit();
    end;

    local procedure RunGetDemandToReserve(DemandType: Enum "Reservation Demand Type"; var TempAssemblyLine: Record "Assembly Line" temporary; var TempSalesLine: Record "Sales Line" temporary)
    var
        GetDemandToReserve: Report "Get Demand To Reserve";
    begin
        GetDemandToReserve.SetParameters(false, DemandType, "Reservation From Stock"::" ", false);
        GetDemandToReserve.RunModal();
        GetDemandToReserve.GetAssemblyLines(TempAssemblyLine);
        GetDemandToReserve.GetSalesOrderLines(TempSalesLine);
    end;

    [RequestPageHandler]
    procedure OkGetDemandToReserve(var RequestPage: TestRequestPage "Get Demand To Reserve")
    begin
        RequestPage.OK().Invoke();
    end;
}
