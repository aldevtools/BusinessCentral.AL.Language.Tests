// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: LT AI Row / LT AI Log Mgt (AiFixtures.al); pages 87158, 87159 here; tests QP_* in AiListOrderTests.al (codeunit 78860)
// Probe: writer QP (al-runtime-rs ask). A list whose OnOpenPage filters every row out (cursor on no row) gets an action that changes the
//        filter so rows exist and calls CurrPage.Update(false): which row is current after, and which triggers run. Page 87158 has
//        OnFindRecord and OnNextRecord (Nav), page 87159 only OnAfterGetRecord (Plain); both have OnAfterGetCurrRecord.
// Log format as AiFixtures.al: O = OnOpenPage, F:<Which>=<found>, N:<Steps>=<moved>, R:<no>, C:<no>, A:<name> = an action step.
// BC versions: 27.0+

page 87158 "LT QP AI Empty Nav"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetRange(Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(ShowFromThree)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>=%1', 3);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('O');
        Rec.SetFilter(Qty, '>%1', 1000);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AI Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

page 87159 "LT QP AI Empty Plain"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetRange(Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(ShowFromThree)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>=%1', 3);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('O');
        Rec.SetFilter(Qty, '>%1', 1000);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}
