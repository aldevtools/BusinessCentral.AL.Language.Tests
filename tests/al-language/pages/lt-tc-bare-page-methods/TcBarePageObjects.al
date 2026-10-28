// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Assert (60021); own tables 89770, 89771, pages 89772, 89773, test codeunit 89775 (file TcBarePageMethodsTests.al)
// Probe: al-runner issue 6021. Inside a page, an unqualified call to one of the page's own built-in methods (Update, Close,
//   SaveRecord, SetSelectionFilter, Activate) and a bare read of Editable and Caption compile, and behave like the CurrPage. form.
//   Page "LT TC Bare List" uses the bare form; page "LT TC Curr List" is the same page text with CurrPage. in front. Both write
//   the same log lines, tagged B: and C:, so the tests compare trigger order of the two forms.
// BC versions: all (CI)

table 89770 "LT TC Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; "Code") { } }
}

table 89771 "LT TC Log"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Msg; Text[100]) { }
    }
    keys { key(PK; "Entry No.") { } }
}

page 89772 "LT TC Bare List"
{
    PageType = List;
    SourceTable = "LT TC Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT TC List';
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:UpdateFalse:before');
                    Update(false);
                    Log('Act:UpdateFalse:after');
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Name := 'saved-by-update';
                    Log('Act:UpdateTrue:before');
                    Update(true);
                    Log('Act:UpdateTrue:after');
                end;
            }
            action(UpdateDefault)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:UpdateDefault:before');
                    Update();
                    Log('Act:UpdateDefault:after');
                end;
            }
            action(SaveIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Name := 'saved-by-saverecord';
                    Log('Act:Save:before');
                    SaveRecord();
                    Log('Act:Save:after');
                end;
            }
            action(SelFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT TC Row";
                begin
                    SetSelectionFilter(Sel);
                    Log('Act:Sel:' + Format(Sel.Count()) + ':' + Sel.GetFilter("Code"));
                end;
            }
            action(ActivateIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Activate:before');
                    Activate();
                    Log('Act:Activate:after');
                end;
            }
            action(CloseIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Close:before');
                    Close();
                    Log('Act:Close:after');
                end;
            }
            action(ReadProps)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Props:Editable=' + Format(Editable) + ':Caption=' + Caption);
                end;
            }
            action(SetEditableFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Editable := false;
                    Log('Act:SetEditable:Editable=' + Format(Editable));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log('OpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        AgrCount += 1;
        Log('AGR:' + Rec."Code" + ':' + Format(AgrCount));
        if (Rec."Code" = 'UPD') and (AgrCount < 4) then begin
            Log('AGR:Update');
            Update(false);
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log('AGCR:' + Rec."Code");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log('QueryClose');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log('ClosePage');
    end;

    local procedure Log(Msg: Text)
    var
        L: Record "LT TC Log";
    begin
        L.Init();
        L.Msg := CopyStr('B:' + Msg, 1, MaxStrLen(L.Msg));
        L.Insert();
    end;

    var
        AgrCount: Integer;
}

page 89773 "LT TC Curr List"
{
    PageType = List;
    SourceTable = "LT TC Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT TC List';
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:UpdateFalse:before');
                    CurrPage.Update(false);
                    Log('Act:UpdateFalse:after');
                end;
            }
            action(UpdateTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Name := 'saved-by-update';
                    Log('Act:UpdateTrue:before');
                    CurrPage.Update(true);
                    Log('Act:UpdateTrue:after');
                end;
            }
            action(UpdateDefault)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:UpdateDefault:before');
                    CurrPage.Update();
                    Log('Act:UpdateDefault:after');
                end;
            }
            action(SaveIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Name := 'saved-by-saverecord';
                    Log('Act:Save:before');
                    CurrPage.SaveRecord();
                    Log('Act:Save:after');
                end;
            }
            action(SelFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT TC Row";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log('Act:Sel:' + Format(Sel.Count()) + ':' + Sel.GetFilter("Code"));
                end;
            }
            action(ActivateIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Activate:before');
                    CurrPage.Activate();
                    Log('Act:Activate:after');
                end;
            }
            action(CloseIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Close:before');
                    CurrPage.Close();
                    Log('Act:Close:after');
                end;
            }
            action(ReadProps)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log('Act:Props:Editable=' + Format(CurrPage.Editable) + ':Caption=' + CurrPage.Caption);
                end;
            }
            action(SetEditableFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Editable := false;
                    Log('Act:SetEditable:Editable=' + Format(CurrPage.Editable));
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log('OpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        AgrCount += 1;
        Log('AGR:' + Rec."Code" + ':' + Format(AgrCount));
        if (Rec."Code" = 'UPD') and (AgrCount < 4) then begin
            Log('AGR:Update');
            CurrPage.Update(false);
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log('AGCR:' + Rec."Code");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log('QueryClose');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log('ClosePage');
    end;

    local procedure Log(Msg: Text)
    var
        L: Record "LT TC Log";
    begin
        L.Init();
        L.Msg := CopyStr('C:' + Msg, 1, MaxStrLen(L.Msg));
        L.Insert();
    end;

    var
        AgrCount: Integer;
}

