// Fixture host card for TestPageSubpagePartConstFilter.al. Six parts, five over the SAME
// lines page and one over the keyed variant, each with a different SubPageLink shape:
//   ConstLines       field(...) + const(<option member>)
//   FilterLines      field(...) + filter(<expression>)
//   ConstTableLines  field(...) + const(Database::<table>)
//   ConstCodeLines   field(...) + const(<quoted text literal>) on a Code field
//   ConstOnlyLines   const(...) alone, no field(...) link to the host row at all
//   ConstKeyLines    field(...) + const(<option member>) over "TSPL Keyed Lines", whose
//                    PRIMARY KEY contains the const-ed field -- the half of the New()
//                    stamping rule that "TSPL Lines" cannot show
page 60323 "TSPL Card"
{
    PageType = Card;
    SourceTable = "TSPL Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(ConstLines; "TSPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), Kind = const(Attachment);
            }
            part(FilterLines; "TSPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), Status = filter(Open | Released);
            }
            part(ConstTableLines; "TSPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), "Table ID" = const(Database::"TSPL Header");
            }
            part(ConstCodeLines; "TSPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), Category = const('SPECIAL');
            }
            part(ConstOnlyLines; "TSPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = Kind = const(Comment);
            }
            part(ConstKeyLines; "TSPL Keyed Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No."), Kind = const(Attachment);
            }
        }
    }
}
