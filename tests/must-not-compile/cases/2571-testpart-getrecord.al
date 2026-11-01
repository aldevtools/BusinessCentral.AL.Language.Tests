// @expect AL0132 | 'Lines' does not contain a definition for 'GetRecord'
// TestPart has no GetRecord method either (the part's row is read only through its controls). Pinned for al-runner 6519
// (writer Y54), beside tests/al-language/pages/lt-y15/Y15LookupThreeFieldLink.al.
table 50571 "MNC Y54 Part Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

page 50571 "MNC Y54 Sub List"
{
    PageType = ListPart;
    SourceTable = "MNC Y54 Part Row";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}

page 50572 "MNC Y54 Host"
{
    PageType = Card;
    layout { area(Content) { part(Lines; "MNC Y54 Sub List") { } } }
}

codeunit 50571 "MNC Y54 0571"
{
    procedure Probe()
    var
        Pg: TestPage "MNC Y54 Host";
        Row: Record "MNC Y54 Part Row";
    begin
        Pg.Lines.GetRecord(Row);
    end;
}
