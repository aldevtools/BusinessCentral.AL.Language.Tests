// Fixture for "Test Isolated Event Sub Error" (67103).
// Two subscribers to the isolated event: one writes row 1 and then raises, one writes
// row 2 and returns. One subscriber to the non-isolated event writes row 3 and raises.
codeunit 67102 "ISO Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ISO Event Publisher", 'OnIsolatedWork', '', false, false)]
    local procedure WriteThenFailOnIsolatedWork()
    var
        Row: Record "ISO Event Row";
    begin
        Row."Entry No." := 1;
        Row.Source := 'isolated-failing';
        Row.Insert();
        Error('ISO-SUBSCRIBER-FAILED');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ISO Event Publisher", 'OnIsolatedWork', '', false, false)]
    local procedure WriteOnIsolatedWork()
    var
        Row: Record "ISO Event Row";
    begin
        Row."Entry No." := 2;
        Row.Source := 'isolated-ok';
        Row.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ISO Event Publisher", 'OnSharedWork', '', false, false)]
    local procedure WriteThenFailOnSharedWork()
    var
        Row: Record "ISO Event Row";
    begin
        Row."Entry No." := 3;
        Row.Source := 'shared-failing';
        Row.Insert();
        Error('SHARED-SUBSCRIBER-FAILED');
    end;
}
