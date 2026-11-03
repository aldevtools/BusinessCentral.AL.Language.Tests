// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74633 "LT P89 Is FilterPageBuilder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsFilterPageBuilder() then
            R += 'FilterPageBuilder,';
        if V.IsRecord() then
            R += 'Record,';
        if V.IsRecordRef() then
            R += 'RecordRef,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        exit(R);
    end;

    [Test]
    procedure FilterPageBuilder_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: FilterPageBuilder;
        V: Variant;
    begin
        V := X; Observer.Observe('default', Flags(V));
        X.AddTable('LT P89 Rec', Database::"LT P89 Rec");
        V := X; Observer.Observe('with_table', Flags(V));
        Observer.Observe('count', Format(X.Count()));
        Observer.Expect('default', 'FilterPageBuilder,');
        Observer.Expect('with_table', 'FilterPageBuilder,');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;
}
