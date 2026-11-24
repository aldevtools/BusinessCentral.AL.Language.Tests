// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 88076, pages 88129-88142, test codeunit 88093
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: a list filtered to Processed = false in OnOpenPage; an action marks the rows processed (ModifyAll) and calls
//   CurrPage.Update(false), Update(true) or nothing (runner issue 8343: the reporter measured on a Worksheet with OnAfterGetRecord that First() then answers
//   false). Worksheet, List and Card, each with no row trigger, OnAfterGetRecord, OnAfterGetCurrRecord or both. After the action: the current control
//   value, First(), Last(), Next(). Neighbors: the second row of two moved out, an action that only renames (the row stays in the view), the filter from
//   SourceTableView or from the test's Filter.SetFilter, an action that also removes the filter.
// BC versions: all (CI)

table 88076 "TPL Filter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Processed; Boolean) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(ByProcessed; Processed) { }
    }
}

page 88129 "TPL Filter Worksheet None"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;
}

page 88130 "TPL Filter Worksheet AGR"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;
}

page 88131 "TPL Filter Worksheet AGCR"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88132 "TPL Filter Worksheet Both"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88133 "TPL Filter List None"
{
    PageType = List;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;
}

page 88134 "TPL Filter List AGR"
{
    PageType = List;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;
}

page 88135 "TPL Filter List AGCR"
{
    PageType = List;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88136 "TPL Filter List Both"
{
    PageType = List;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88137 "TPL Filter Card None"
{
    PageType = Card;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;
}

page 88138 "TPL Filter Card AGR"
{
    PageType = Card;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;
}

page 88139 "TPL Filter Card AGCR"
{
    PageType = Card;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88140 "TPL Filter Card Both"
{
    PageType = Card;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Processed, false);
    end;

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 88141 "TPL Filter Ws AGR View"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Processed = const(false));

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;
}

page 88142 "TPL Filter Ws AGR NoFilter"
{
    PageType = Worksheet;
    SourceTable = "TPL Filter Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(false);
                end;
            }
            action(MarkUpdateTrue)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    CurrPage.Update(true);
                end;
            }
            action(MarkNoUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                end;
            }
            action(MarkCurrentUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    Rec.Processed := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(RenameUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Name, 'Renamed');
                    CurrPage.Update(false);
                end;
            }
            action(MarkClearFilterUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    AllLines: Record "TPL Filter Row";
                begin
                    AllLines.ModifyAll(Processed, true);
                    Rec.SetRange(Processed);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;
}

codeunit 88093 "TPL Filter After Action"
{
    Subtype = Test;

    [Test]
    procedure Worksheet_None_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_None_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_None_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Both_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Both_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Both_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_None_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_None_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_None_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_Both_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_Both_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_Both_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_None_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_None_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_None_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card None";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGCR_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGCR_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGCR_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_Both_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_Both_MarkUpdateTrue()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkUpdateTrue.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_Both_MarkNoUpdate()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card Both";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        Observer.Observe('firstBefore', Format(P.First()));
        P.MarkNoUpdate.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_SecondRowMarkCurrentUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        Row."Line No." := 20000;
        Row.Name := 'Line 20000';
        Row.Insert();
        P.OpenEdit();
        P.GoToKey(20000);
        P.MarkCurrentUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_SecondRowMarkCurrentUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        Row."Line No." := 20000;
        Row.Name := 'Line 20000';
        Row.Insert();
        P.OpenEdit();
        P.GoToKey(20000);
        P.MarkCurrentUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGR_SecondRowMarkCurrentUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Card AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        Row."Line No." := 20000;
        Row.Name := 'Line 20000';
        Row.Insert();
        P.OpenEdit();
        P.GoToKey(20000);
        P.MarkCurrentUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_RenameUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        P.RenameUpdateFalse.Invoke();
        Observer.Observe('name', P.NameF.Value());
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_SourceTableView_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Ws AGR View";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_TestFilter_MarkUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Ws AGR NoFilter";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        P.Filter.SetFilter(Processed, Format(false));
        P.MarkUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_MarkClearFilterUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        P.MarkClearFilterUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_MarkClearFilterUpdateFalse()
    var
        Row: Record "TPL Filter Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Filter List AGCR";
    begin
        Row.DeleteAll();
        Row."Line No." := 10000;
        Row.Name := 'Line 10000';
        Row.Insert();
        P.OpenEdit();
        P.MarkClearFilterUpdateFalse.Invoke();
        Observer.Observe('current', P.LineNo.Value());
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('afterFirst', P.LineNo.Value());
        Observer.Observe('last', Format(P.Last()));
        Observer.Observe('next', Format(P.Next()));
        P.Close();
        Observer.Finish();
    end;
}
