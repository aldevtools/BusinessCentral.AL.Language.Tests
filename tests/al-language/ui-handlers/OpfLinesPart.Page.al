// Fixture for "Opf Ok Part Flush Tests" (60663). A temporary-sourced ListPart whose rows only
// the host page can read, through GetRows -- the shape a document page uses when it materialises
// what the user entered at the moment they press OK.
page 60639 "Opf Lines Part"
{
    PageType = ListPart;
    SourceTable = "Opf Line";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Value"; Rec."Value") { ApplicationArea = All; }
            }
        }
    }

    internal procedure GetRows(var Temp: Record "Opf Line" temporary)
    var
        Line: Record "Opf Line" temporary;
    begin
        Temp.Reset();
        Temp.DeleteAll();
        Line.Copy(Rec, true);
        if Line.FindSet() then
            repeat
                Temp := Line;
                Temp.Insert();
            until Line.Next() = 0;
    end;
}
