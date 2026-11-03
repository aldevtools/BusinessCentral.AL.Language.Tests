// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtableview-property
// Scope: in-scope
// Fixtures used: none — Base Application report 302 "Get Demand To Reserve"
//
// A Base Application report whose DataItemTableView is written over several lines in its AL
// source still opens its request page and hands it to the [RequestPageHandler].
//
// Report 302's data items declare their views across line breaks, e.g. FilterItem:
//     DataItemTableView = sorting("No.")
//                         where(Type = const(Inventory));
// and SalesOrderLine puts each where(...) entry on its own line. The request page applies
// those views to the data items before the handler runs, so a view the platform cannot read
// stops the report before its request page opens.
//
// Two claims:
//   1. Run hands the handler the request page exactly once, and Cancel closes it with no error.
//   2. An error the handler raises reaches the test unchanged — the handler is on the call path.
codeunit 67569 "Rpt Multi-Line DataItem View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerCalls: Integer;
        HandlerErr: Label 'Raised from the request page handler of report 302', Locked = true;

    [Test]
    [HandlerFunctions('CancelGetDemandToReserve')]
    procedure GetDemandToReserve_Run_HandsTheHandlerItsRequestPage()
    var
        GetDemandToReserve: Report "Get Demand To Reserve";
    begin
        HandlerCalls := 0;

        GetDemandToReserve.SetParameters(false, "Reservation Demand Type"::All, "Reservation From Stock"::" ", false);
        GetDemandToReserve.Run();

        Assert.AreEqual(1, HandlerCalls, 'the request page handler runs once for report 302');
    end;

    [Test]
    [HandlerFunctions('ErrorGetDemandToReserve')]
    procedure GetDemandToReserve_HandlerError_ReachesTheTest()
    var
        GetDemandToReserve: Report "Get Demand To Reserve";
    begin
        HandlerCalls := 0;

        asserterror GetDemandToReserve.Run();

        Assert.ExpectedError(HandlerErr);
        Assert.AreEqual(1, HandlerCalls, 'the error came from the request page handler');
    end;

    [RequestPageHandler]
    procedure CancelGetDemandToReserve(var RequestPage: TestRequestPage "Get Demand To Reserve")
    begin
        HandlerCalls += 1;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ErrorGetDemandToReserve(var RequestPage: TestRequestPage "Get Demand To Reserve")
    begin
        HandlerCalls += 1;
        Error(HandlerErr);
    end;
}
