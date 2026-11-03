// Fixture pages, one per PageType, for the Page Metadata probes.

page 69480 "Probe Pg Card"
{
    PageType = Card;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69481 "Probe Pg List"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69482 "Probe Pg Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69483 "Probe Pg ListPlus"
{
    PageType = ListPlus;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69484 "Probe Pg CardPart"
{
    PageType = CardPart;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69485 "Probe Pg ListPart"
{
    PageType = ListPart;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69486 "Probe Pg Document"
{
    PageType = Document;
    SourceTable = "Probe Pf Row";
    layout
    {
        area(Content)
        {
            
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69487 "Probe Pg ConfirmationDialog"
{
    PageType = ConfirmationDialog;
}

page 69488 "Probe Pg NavigatePage"
{
    PageType = NavigatePage;
}

page 69489 "Probe Pg RoleCenter"
{
    PageType = RoleCenter;
}

page 69490 "Probe Pg StandardDialog"
{
    PageType = StandardDialog;
}

page 69491 "Probe Pg API"
{
    PageType = API;
    SourceTable = "Probe Pf Row";
    APIPublisher = 'probe'; APIGroup = 'probe'; APIVersion = 'v1.0'; EntityName = 'probeRow'; EntitySetName = 'probeRows'; ODataKeyFields = SystemId;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            field(id; Rec.SystemId) { }
            field(Txt; Rec.Txt) { }
        }
    }
}

page 69492 "Probe Pg HeadlinePart"
{
    PageType = HeadlinePart;
}

page 69493 "Probe Pg PromptDialog"
{
    PageType = PromptDialog;
    Extensible = false;
}

page 69494 "Probe Pg ViewNone"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69495 "Probe Pg ViewWhereOne"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = where(Id = const(2));
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69496 "Probe Pg ViewSortingOnly"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = sorting(Txt);
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69497 "Probe Pg ViewOrderDesc"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = order(descending);
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69498 "Probe Pg ViewSortingWhere"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = sorting(Txt) where(Id = filter(1..5));
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69499 "Probe Pg ViewTwoConditions"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = where(Id = filter(1..5), Txt = const('x'));
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69500 "Probe Pg ViewSortingOrder"
{
    PageType = List;
    SourceTable = "Probe Pf Row";
    SourceTableView = sorting(Txt) order(descending);
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69501 "Probe Pg Controls"
{
    PageType = Card;
    SourceTable = "Probe Pf Row";

    layout
    {
        area(Content)
        {
            group(G1)
            {
                Caption = 'Group One';

                field(F1; Rec.Id) { }
                field(F2; Rec.Txt) { Visible = false; }
            }
            field(F3; Rec.Txt) { Enabled = false; }
            field(F4; Rec.Txt) { Editable = false; }
            field(F5; Rec.Txt) { Visible = true; Enabled = true; Editable = true; }
            field(F6; Rec.Txt) { Visible = VisFlag; Enabled = VisFlag; Editable = VisFlag; }
            field(F7; Rec.Txt) { ShowCaption = false; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(A1)
            {
                trigger OnAction()
                begin
                end;
            }
            group(AG)
            {
                action(A2)
                {
                    trigger OnAction()
                    begin
                    end;
                }
                action(A3)
                {
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(A4)
            {
                RunObject = page "Probe Pg List";
            }
        }
        area(Promoted)
        {
            actionref(A1Ref; A1) { }
        }
    }

    var
        VisFlag: Boolean;
}

page 69502 "Probe Pg Actions Only"
{
    PageType = List;
    SourceTable = "Probe Pf Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Txt; Rec.Txt) { }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(C1)
            {
                trigger OnAction()
                begin
                end;
            }
        }
        area(Processing)
        {
            action(P1)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}
