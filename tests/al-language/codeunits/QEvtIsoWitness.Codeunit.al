// Fixture for "Test Event Quoted Name" (67046): counts how often the isolated subscriber in
// "QEvt Iso Subscriber" (67045) ran. SingleInstance, so the count lives outside the database
// and survives the rollback of the subscriber's failed transaction.
codeunit 67047 "QEvt Iso Witness"
{
    SingleInstance = true;

    var
        Calls: Integer;

    procedure Note()
    begin
        Calls += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Calls);
    end;
}
