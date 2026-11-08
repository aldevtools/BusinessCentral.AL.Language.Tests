// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
// singleinstance-shared-on-purpose: probe P7 (ADR-066 of al-runtime-rs) is what "CU P7 A Setter" (96122) leaves in this fixture for "CU P7 B Reader" (96123), the next test codeunit.
//
// local object: the table must be committed to and the SingleInstance codeunit is itself the
// thing under test (state handed from one test codeunit to the next); only 96120..96123 use them.

table 96120 "CU P7 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

codeunit 96121 "CU P7 State"
{
    SingleInstance = true;

    procedure NoteRan(What: Text)
    begin
        if Ran <> '' then
            Ran += ';';
        Ran += What;
    end;

    procedure GetRan(): Text
    begin
        exit(Ran);
    end;

    procedure SetValue(NewValue: Integer)
    begin
        Value := NewValue;
    end;

    procedure GetValue(): Integer
    begin
        exit(Value);
    end;

    var
        Ran: Text;
        Value: Integer;
}
