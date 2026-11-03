// @expect AL0133 | Argument 1: cannot convert from 'Query "MNC This Query"' to 'Codeunit'
// BindSubscription(this) inside a query.
query 50000 "MNC This Query"
{
    elements { dataitem(I; Integer) { column(N; Number) { } } }

    trigger OnBeforeOpen()
    begin
        BindSubscription(this);
    end;
}
