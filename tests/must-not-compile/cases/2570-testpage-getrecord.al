// @expect AL0132 | 'TestPage MNC Y54 List' does not contain a definition for 'GetRecord'
// TestPage has no GetRecord method (Page.GetRecord exists; a TestPage reads its row only through its controls). Pinned for
// al-runner 6519 (writer Y54), beside tests/al-language/pages/lt-y15/Y15LookupThreeFieldLink.al.
table 50570 "MNC Y54 Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

page 50570 "MNC Y54 List"
{
    PageType = List;
    SourceTable = "MNC Y54 Row";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}

codeunit 50570 "MNC Y54 0570"
{
    procedure Probe()
    var
        Pg: TestPage "MNC Y54 List";
        Row: Record "MNC Y54 Row";
    begin
        Pg.GetRecord(Row);
    end;
}
