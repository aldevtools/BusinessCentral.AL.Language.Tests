// @expect AL0133 | Argument 1: cannot convert from 'Record "MNC This Table"' to 'Codeunit'
// BindSubscription(this) inside a table: this is the record, not a codeunit.
table 50000 "MNC This Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure P()
    begin
        BindSubscription(this);
    end;
}
