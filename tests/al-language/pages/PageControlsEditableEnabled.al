// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72471 "LT P194 Ctl Sub"
{
    PageType = ListPart;
    SourceTable = "LT P194 Gen";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                Editable = false;
                Enabled = false;

                field(SubCode; Rec."Code") { ApplicationArea = All; }
                field(SubName; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 72470 "LT P194 Ctl Card"
{
    PageType = Card;
    SourceTable = "LT P194 Gen";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Free)
            {
                field(CodeFld; Rec."Code") { ApplicationArea = All; }
                field(NameFld; Rec.Name) { ApplicationArea = All; }
            }
            group(LockedGrp)
            {
                Editable = false;

                field(LockedNote; Rec.Note) { ApplicationArea = All; }
            }
            group(DisabledGrp)
            {
                Enabled = false;

                field(DisabledAmount; Rec.Amount) { ApplicationArea = All; }
            }
            group(ExprGrp)
            {
                Editable = ExprEdit;
                Enabled = ExprEdit;

                field(ExprName; Rec.Name) { ApplicationArea = All; }
            }
            group(ModGrp)
            {
                Editable = false;

                field(ModNote; Rec.Note) { ApplicationArea = All; }
            }
            part(SubPart; "LT P194 Ctl Sub")
            {
                ApplicationArea = All;
            }
            part(ModPart; "LT P194 Ctl Sub")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DisabledAct)
            {
                ApplicationArea = All;
                Enabled = false;

                trigger OnAction()
                var
                    Log: Codeunit "LT P194 Log";
                begin
                    Log.Add('DisabledAct');
                end;
            }
            action(ModAct)
            {
                ApplicationArea = All;
                Enabled = false;

                trigger OnAction()
                var
                    Log: Codeunit "LT P194 Log";
                begin
                    Log.Add('ModAct');
                end;
            }
            action(ExprAct)
            {
                ApplicationArea = All;
                Enabled = ExprEdit;

                trigger OnAction()
                var
                    Log: Codeunit "LT P194 Log";
                begin
                    Log.Add('ExprAct');
                end;
            }
            action(ToggleAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExprEdit := not ExprEdit;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ExprEdit: Boolean;
}

