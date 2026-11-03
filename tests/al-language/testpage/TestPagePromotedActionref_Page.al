// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-actionref-type
// Scope: in-scope
// Fixtures used: TPR Row (60764), TPR List (60765), TPR List Ext (60766)
//
// A list page whose trigger-carrying actions all live in area(Processing) and whose
// area(Promoted) contains nothing but actionrefs pointing at them — the standard promotion
// pattern. An actionref delegates: on BC, invoking the promoted ref and invoking the action it
// names are the same command, and the ref itself carries no OnAction of its own (the AL
// grammar gives it nowhere to put one).
//
// Each target stamps its OWN tag, so a test can tell "an action ran" apart from "the action
// this ref points at ran".

page 60765 "TPR List"
{
    PageType = List;
    SourceTable = "TPR Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StampFlat)
            {
                ApplicationArea = All;
                Caption = 'Stamp Flat';

                trigger OnAction()
                var
                    Stamp: Record "TPR Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'FLAT';
                    Stamp.Descr := Rec."No.";
                    Stamp.Insert();
                end;
            }

            group(Grouped)
            {
                Caption = 'Grouped';

                action(StampGrouped)
                {
                    ApplicationArea = All;
                    Caption = 'Stamp Grouped';

                    trigger OnAction()
                    var
                        Stamp: Record "TPR Row";
                    begin
                        Stamp.Init();
                        Stamp."No." := 'GROUPED';
                        Stamp.Insert();
                    end;
                }
            }

            action(StampForExtRef)
            {
                ApplicationArea = All;
                Caption = 'Stamp For Ext Ref';

                trigger OnAction()
                var
                    Stamp: Record "TPR Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'BASE-VIA-EXT';
                    Stamp.Insert();
                end;
            }

            action(AlwaysFails)
            {
                ApplicationArea = All;
                Caption = 'Always Fails';

                trigger OnAction()
                begin
                    Error('TPR promoted target refused deliberately');
                end;
            }
        }

        area(Promoted)
        {
            actionref(StampFlat_Promoted; StampFlat)
            {
            }

            group(Category_Process)
            {
                Caption = 'Process';

                actionref(StampGrouped_Promoted; StampGrouped)
                {
                }
            }

            actionref(AlwaysFails_Promoted; AlwaysFails)
            {
            }
        }
    }
}

// A pageextension's promoted actionref can point either at an action the EXTENSION declares
// or at one the BASE PAGE declares. Both are the same delegation.
pageextension 60766 "TPR List Ext" extends "TPR List"
{
    actions
    {
        addlast(Processing)
        {
            action(StampExt)
            {
                ApplicationArea = All;
                Caption = 'Stamp Ext';

                trigger OnAction()
                var
                    Stamp: Record "TPR Row";
                begin
                    Stamp.Init();
                    Stamp."No." := 'EXT';
                    Stamp.Insert();
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(StampExt_Promoted; StampExt)
            {
            }

            actionref(StampBase_Promoted; StampForExtRef)
            {
            }
        }
    }
}
