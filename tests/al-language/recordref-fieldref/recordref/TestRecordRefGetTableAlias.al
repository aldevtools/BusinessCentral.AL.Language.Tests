// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51885 "REC RecordRefGetTable Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    [Test]
    procedure GetTableInByValueSubscriberChangesPublisherRow()
    var
        Input: Record "Probe Ref Row";
        Ref: RecordRef;
        Observed: Variant;
        Handler: Codeunit "REC RecordRefGetTable Tests";
    begin
        Initialize();
        Input.Id := 1;
        Ref.GetTable(Input);
        BindSubscription(Handler);
        OnReplace(Ref);
        UnbindSubscription(Handler);
        Observed := Ref.Field(2).Value;
        if Format(Observed) <> '7' then
            Error('Expected the caller field to be 7 after GetTable. Got %1.', Observed);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplace(Ref: RecordRef)
    begin
    end;

    [Test]
    procedure GetTableUpdatesAnAssignedAliasOfTheSameTable()
    var
        Row: Record "Probe Ref Row";
        Original: RecordRef;
        Alias: RecordRef;
        Observed: Variant;
    begin
        Initialize();
        Row.Id := 1;
        Original.GetTable(Row);
        Alias := Original;
        Row.Category := 7;
        Alias.GetTable(Row);
        Observed := Original.Field(2).Value;
        if Format(Observed) <> '7' then
            Error('The assigned alias changed the value to %1.', Observed);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"REC RecordRefGetTable Tests", 'OnReplace', '', false, false)]
    local procedure ReplaceByValue(Ref: RecordRef)
    var
        Input: Record "Probe Ref Row";
    begin
        Input.Id := 1;
        Input.Category := 7;
        Ref.GetTable(Input);
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Probe Ref Row";
    begin
        ProbeTable1.DeleteAll();
    end;
}
