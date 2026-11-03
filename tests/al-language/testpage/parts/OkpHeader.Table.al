// Fixture for "OKP Ok Part Row Tests" (60760): the header a card shows, keyed on one field.
// OnModify records how many "OKP Line" (60761) rows exist for this header at the moment the
// header is modified, which is what lets the suite observe whether the part rows or the
// header record are saved first when the card closes.
table 60760 "OKP Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[30]) { }
        field(3; "Seen Lines"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Line: Record "OKP Line";
    begin
        Line.SetRange("Header Code", "Code");
        "Seen Lines" := Line.Count();
    end;
}
