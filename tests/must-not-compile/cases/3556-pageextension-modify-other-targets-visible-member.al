// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// @expect AL0107 | Syntax error, identifier expected
// A keyword member, unquoted after `.`, in the Visible of a page extension's `modify` of eight other targets, one word each (al-runner PR 8655 review): a systempart (If), a repeater (Exit), a cuegroup (End), a grid (Then), a fixed (Do), an actionref (Case), a group in a page's actions area (Mod) and a control the page does not have (Not). Each gives AL0107 at the name: the parser rejects it before the target is bound.
// Quoted, each compiles (the unknown control still gives AL0270).
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
table 53556 "MNC KP3556"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Cnt; Integer)
        {
        }
        field(3; "If"; Integer)
        {
        }
        field(4; "Exit"; Integer)
        {
        }
        field(5; "End"; Integer)
        {
        }
        field(6; "Then"; Integer)
        {
        }
        field(7; "Do"; Integer)
        {
        }
        field(8; "Case"; Integer)
        {
        }
        field(9; "Mod"; Integer)
        {
        }
        field(10; "Not"; Integer)
        {
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

page 58560 "MNC KP3556 P0"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { group(G) { field("No."; Rec."No.") { } } } area(FactBoxes) { systempart(Notes; Notes) { } }
    }
}

pageextension 58570 "MNC KP3556 X0" extends "MNC KP3556 P0"
{
    layout
    {
        modify(Notes)
        {
            Visible = Rec.If > 0;
        }
    }
}

page 58561 "MNC KP3556 P1"
{
    PageType = List;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { repeater(Rows) { field("No."; Rec."No.") { } } }
    }
}

pageextension 58571 "MNC KP3556 X1" extends "MNC KP3556 P1"
{
    layout
    {
        modify(Rows)
        {
            Visible = Rec.Exit > 0;
        }
    }
}

page 58562 "MNC KP3556 P2"
{
    PageType = CardPart;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { cuegroup(Cues) { field(Cnt; Rec.Cnt) { } } }
    }
}

pageextension 58572 "MNC KP3556 X2" extends "MNC KP3556 P2"
{
    layout
    {
        modify(Cues)
        {
            Visible = Rec.End > 0;
        }
    }
}

page 58563 "MNC KP3556 P3"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { grid(Gr) { field("No."; Rec."No.") { } } }
    }
}

pageextension 58573 "MNC KP3556 X3" extends "MNC KP3556 P3"
{
    layout
    {
        modify(Gr)
        {
            Visible = Rec.Then > 0;
        }
    }
}

page 58564 "MNC KP3556 P4"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { fixed(Fx) { group(FG) { field("No."; Rec."No.") { } } } }
    }
}

pageextension 58574 "MNC KP3556 X4" extends "MNC KP3556 P4"
{
    layout
    {
        modify(Fx)
        {
            Visible = Rec.Do > 0;
        }
    }
}

page 58565 "MNC KP3556 P5"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    actions
    {
        area(Processing) { action(Act) { trigger OnAction() begin end; } } area(Promoted) { actionref(ActRef; Act) { } }
    }
}

pageextension 58575 "MNC KP3556 X5" extends "MNC KP3556 P5"
{
    actions
    {
        modify(ActRef)
        {
            Visible = Rec.Case > 0;
        }
    }
}

page 58566 "MNC KP3556 P6"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    actions
    {
        area(Processing) { group(AG) { action(Act) { trigger OnAction() begin end; } } }
    }
}

pageextension 58576 "MNC KP3556 X6" extends "MNC KP3556 P6"
{
    actions
    {
        modify(AG)
        {
            Visible = Rec.Mod > 0;
        }
    }
}

page 58567 "MNC KP3556 P7"
{
    PageType = Card;
    SourceTable = "MNC KP3556";

    layout
    {
        area(Content) { group(G) { field("No."; Rec."No.") { } } }
    }
}

pageextension 58577 "MNC KP3556 X7" extends "MNC KP3556 P7"
{
    layout
    {
        modify(NoSuch)
        {
            Visible = Rec.Not > 0;
        }
    }
}
