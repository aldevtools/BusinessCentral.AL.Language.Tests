// @expect AL0132 | 'Decimal' does not contain a definition for 'Foo'
// A report column source with three parts after a quoted data item name that holds a dot and a space: "Dq. Row".Qty.Foo.
// The first part is the data item, the second its Decimal field; a Decimal has no member Foo (corpus issue 1648).
table 50000 "MNC Dq Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Dq Three Part"
{
    dataset
    {
        dataitem("Dq. Row"; "MNC Dq Row")
        {
            column(QtyFoo; "Dq. Row".Qty.Foo) { }
        }
    }
}
