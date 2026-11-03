// @expect AL0204 | Field type Duration is not convertible to field type Integer
// A page whose SourceTableView is where(<Duration field> = const(1000)): the const value of a Duration field does not compile.
table 50000 "MNC TD Table"
{
    fields { field(1; Id; Integer) { } field(2; Dur; Duration) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50000 "MNC TD Page"
{
    PageType = List;
    SourceTable = "MNC TD Table";
    SourceTableView = where(Dur = const(1000));

    layout { area(Content) { repeater(Rows) { field(IdCtl; Rec.Id) { } } } }
}
