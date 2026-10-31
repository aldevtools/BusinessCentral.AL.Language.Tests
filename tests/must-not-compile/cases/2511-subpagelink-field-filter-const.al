// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, ')' expected
// SubPageLink `= field(filter(<host field>))` with a const term inside filter(). (gap cycle 3 C3-11; writer Y37)
table 50000 "MNC Y37 Host"
{
    fields { field(1; "No."; Code[20]) { } field(2; "Line Filter"; Text[250]) { } }
}

table 50001 "MNC Y37 Line"
{
    fields { field(1; "No."; Code[20]) { } }
}

page 50002 "MNC Y37 Part"
{
    PageType = ListPart;
    SourceTable = "MNC Y37 Line";
    layout { area(Content) { repeater(R) { field(No; Rec."No.") { } } } }
}

page 50003 "MNC Y37 Card"
{
    PageType = Card;
    SourceTable = "MNC Y37 Host";
    layout
    {
        area(Content)
        {
            part(Lines; "MNC Y37 Part") { SubPageLink = "No." = field(filter(const(A))); }
        }
    }
}
