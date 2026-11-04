// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copy-recordref-boolean-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79902, 79904, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 6).
// Facts: RecordRef.Copy(Rec) with a Record source (the same table is pinned in misc/lt-probes-needed-6/PnF27RecordRefCopy.al): target open on
//   another table than the source (number, filters, key, current row or the error text); target never opened.
// BC versions: 27-29

codeunit 79924 "LT AS RecRef Copy Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure Source(var Row: Record "LT AS Row")
    begin
        Helper.SeedRows();
        Row.SetCurrentKey("No.");
        Row.Ascending(false);
        Row.SetFilter(Name, '<>beta');
        Row.FindFirst();
    end;

    [Test]
    procedure TargetOnOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Other: Record "LT AS Other";
        Ref: RecordRef;
    begin
        Source(Row);
        Other.DeleteAll();
        Other."Key" := 'K';
        Other.Insert();
        Ref.Open(Database::"LT AS Other");
        Ref.FindFirst();
        ClearLastError();
        if TryCopy(Ref, Row) then
            Observer.Observe('copy', 'ok')
        else
            Observer.Observe('copy', Helper.LastError());
        Observer.Observe('number', Format(Ref.Number));
        Observer.Observe('filters', Ref.GetFilters());
        Observer.Observe('row', Format(Ref.Field(1).Value));
        Observer.Observe('ascending', Format(Ref.Ascending()));
        Observer.Expect('copy', 'Both target and source tables must refer to the same table.|Argument');
        Observer.Expect('number', '79904');
        Observer.Expect('filters', '');
        Observer.Expect('row', 'K');
        Observer.Expect('ascending', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TargetNeverOpened()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Ref: RecordRef;
    begin
        Source(Row);
        ClearLastError();
        if TryCopy(Ref, Row) then
            Observer.Observe('copy', 'ok')
        else
            Observer.Observe('copy', Helper.LastError());
        Observer.Observe('number', Format(Ref.Number));
        Observer.Expect('copy', 'The record is not open.|RecordNotOpened');
        Observer.Expect('number', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCopy(var Ref: RecordRef; var Row: Record "LT AS Row")
    begin
        Ref.Copy(Row);
    end;
}
