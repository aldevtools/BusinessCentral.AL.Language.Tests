// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-method-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Base Application tables Sales Invoice Line and Sales Shipment Line (temporary only),
//   self-contained codeunits 82355 (overloads) and 82358 (test)
// Corpus issue #664 item 80: overloads that differ only by the Record type of a var parameter. The compiler accepts the pair;
// the question is whether the app publishes (records share one run-time type, which could give C# CS0111) and which one runs.
// Result (BC 29.0): the app publishes (no CS0111) and each record type runs its own overload.

codeunit 82355 "LT BO Record Overload Host"
{
    procedure F(var R: Record "Sales Invoice Line"): Text
    begin
        exit('invoice line ' + R."Document No.");
    end;

    procedure F(var R: Record "Sales Shipment Line"): Text
    begin
        exit('shipment line ' + R."Document No.");
    end;
}

codeunit 82358 "LT BO Record Overloads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecordTypeOverloads_WhichRuns()
    var
        Host: Codeunit "LT BO Record Overload Host";
        Observer: Codeunit "Probe Observer";
        InvoiceLine: Record "Sales Invoice Line" temporary;
        ShipmentLine: Record "Sales Shipment Line" temporary;
    begin
        InvoiceLine."Document No." := 'INV1';
        ShipmentLine."Document No." := 'SHP1';
        Observer.Observe('sales invoice line', Host.F(InvoiceLine));
        Observer.Observe('sales shipment line', Host.F(ShipmentLine));
        Observer.Expect('sales invoice line', 'invoice line INV1');
        Observer.Expect('sales shipment line', 'shipment line SHP1');
        Observer.Verify();
    end;
}
