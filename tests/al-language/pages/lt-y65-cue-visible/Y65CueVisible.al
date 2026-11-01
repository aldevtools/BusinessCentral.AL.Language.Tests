// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); table 93347, page 93366 (CardPart), test codeunit 93347; Base Application pages
//   "Sales & Relationship Mgr. Act.", "SO Processor Activities", "O365 Activities"
// Probe (al-runner issue 6675; a cuegroup with Visible = true/false/a page variable on a Card is pages/lt-ab-group-properties/ABCueProps.al,
//   a field in a hidden group is handlers/TestPageFieldVisibleGroup_Tests.al): a role-center activity page (CardPart over a cue table that
//   OnOpenPage creates) whose cuegroups and cue fields take Visible from a page variable set in OnOpenPage (true and false), in OnInit, in
//   OnAfterGetRecord, from `not` a variable, from a Boolean field of Rec, from an expression over Rec (`Rec.X <> 0`) and from an expression
//   mixing both, a procedure call (IsShown()), an array element and a method call (not Rec.IsEmpty()) on a cuegroup. Compile: a group or cuegroup
//   Visible takes any Boolean expression; a field Visible is a client expression (procedure calls, method calls and array elements:
//   AL0322, must-not-compile 2631 (array) and 2632 (method call); a procedure call is 2000); an Integer is AL0208 (must-not-compile 2630). Read through TestPage: Visible() and Value of each cue field. And the reporter's three Microsoft activity pages open and close.
// BC versions: 27, 28, 29

table 93347 "LT Y65 Cue"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; CueA; Integer) { }
        field(3; CueB; Integer) { }
        field(4; CueC; Integer) { }
        field(5; CueD; Integer) { }
        field(6; CueE; Integer) { }
        field(7; CueF; Integer) { }
        field(8; CueG; Integer) { }
        field(9; CueH; Integer) { }
        field(10; CueI; Integer) { }
        field(11; Flag; Boolean) { }
        field(12; CueJ; Integer) { }
        field(13; CueK; Integer) { }
        field(14; CueL; Integer) { }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

page 93366 "LT Y65 Cue Activities"
{
    PageType = CardPart;
    SourceTable = "LT Y65 Cue";
    ApplicationArea = All;
    UsageCategory = None;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(GrpOpenTrue)
            {
                Caption = 'Open true';
                Visible = ShowOpenTrue;
                field(CueA; Rec.CueA) { ApplicationArea = All; }
            }
            cuegroup(GrpOpenFalse)
            {
                Caption = 'Open false';
                Visible = ShowOpenFalse;
                field(CueB; Rec.CueB) { ApplicationArea = All; }
            }
            cuegroup(GrpNot)
            {
                Caption = 'Not';
                Visible = not ShowOpenFalse;
                field(CueC; Rec.CueC) { ApplicationArea = All; }
            }
            cuegroup(GrpInit)
            {
                Caption = 'Init';
                Visible = ShowInit;
                field(CueD; Rec.CueD) { ApplicationArea = All; }
            }
            cuegroup(GrpLate)
            {
                Caption = 'Late';
                Visible = ShowLate;
                field(CueE; Rec.CueE) { ApplicationArea = All; }
            }
            cuegroup(GrpFields)
            {
                Caption = 'Fields';
                field(CueF; Rec.CueF)
                {
                    ApplicationArea = All;
                    Visible = Rec.CueF <> 0;
                }
                field(CueG; Rec.CueG)
                {
                    ApplicationArea = All;
                    Visible = Rec.Flag;
                }
                field(CueH; Rec.CueH)
                {
                    ApplicationArea = All;
                    Visible = ShowOpenTrue and (Rec.CueH = 0);
                }
                field(CueI; Rec.CueI)
                {
                    ApplicationArea = All;
                    Visible = ShowOpenFalse;
                }
            }
            cuegroup(GrpCall)
            {
                Caption = 'Call';
                Visible = IsShown();
                field(CueJ; Rec.CueJ) { ApplicationArea = All; }
            }
            cuegroup(GrpArr)
            {
                Caption = 'Array';
                Visible = ShowArr[2];
                field(CueK; Rec.CueK) { ApplicationArea = All; }
            }
            cuegroup(GrpEmpty)
            {
                Caption = 'Empty';
                Visible = not Rec.IsEmpty();
                field(CueL; Rec.CueL) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInit()
    begin
        ShowInit := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.CueF := 3;
            Rec.Insert();
        end;
        ShowOpenTrue := true;
        ShowOpenFalse := false;
        ShowArr[2] := true;
    end;

    trigger OnAfterGetRecord()
    begin
        ShowLate := true;
    end;

    var
        ShowOpenTrue: Boolean;
        ShowOpenFalse: Boolean;
        ShowInit: Boolean;
        ShowLate: Boolean;
        ShowArr: array[2] of Boolean;

    local procedure IsShown(): Boolean
    begin
        exit(ShowOpenTrue);
    end;
}

codeunit 93347 "LT Y65 Cue Visible Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Shown: Text;

    [TryFunction]
    local procedure TryRead(var P: TestPage "LT Y65 Cue Activities"; Ctl: Text)
    begin
        case Ctl of
            'A':
                Shown := Format(P.CueA.Visible()) + ' ' + P.CueA.Value();
            'B':
                Shown := Format(P.CueB.Visible()) + ' ' + P.CueB.Value();
            'C':
                Shown := Format(P.CueC.Visible()) + ' ' + P.CueC.Value();
            'D':
                Shown := Format(P.CueD.Visible()) + ' ' + P.CueD.Value();
            'E':
                Shown := Format(P.CueE.Visible()) + ' ' + P.CueE.Value();
            'F':
                Shown := Format(P.CueF.Visible()) + ' ' + P.CueF.Value();
            'G':
                Shown := Format(P.CueG.Visible()) + ' ' + P.CueG.Value();
            'H':
                Shown := Format(P.CueH.Visible()) + ' ' + P.CueH.Value();
            'I':
                Shown := Format(P.CueI.Visible()) + ' ' + P.CueI.Value();
            'J':
                Shown := Format(P.CueJ.Visible()) + ' ' + P.CueJ.Value();
            'K':
                Shown := Format(P.CueK.Visible()) + ' ' + P.CueK.Value();
            'L':
                Shown := Format(P.CueL.Visible()) + ' ' + P.CueL.Value();
        end;
    end;

    local procedure Read(var P: TestPage "LT Y65 Cue Activities"; Ctl: Text): Text
    begin
        ClearLastError();
        Shown := '';
        if TryRead(P, Ctl) then
            exit(Shown);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadAll(var P: TestPage "LT Y65 Cue Activities")
    begin
        Observer.Observe('open true (A)', Read(P, 'A'));
        Observer.Observe('open false (B)', Read(P, 'B'));
        Observer.Observe('not open false (C)', Read(P, 'C'));
        Observer.Observe('init (D)', Read(P, 'D'));
        Observer.Observe('after get record (E)', Read(P, 'E'));
        Observer.Observe('Rec.CueF <> 0 (F)', Read(P, 'F'));
        Observer.Observe('Rec.Flag (G)', Read(P, 'G'));
        Observer.Observe('var and Rec expr (H)', Read(P, 'H'));
        Observer.Observe('field var false (I)', Read(P, 'I'));
        Observer.Observe('cuegroup IsShown() (J)', Read(P, 'J'));
        Observer.Observe('cuegroup array element (K)', Read(P, 'K'));
        Observer.Observe('cuegroup not Rec.IsEmpty() (L)', Read(P, 'L'));
    end;

    [Test]
    procedure Y65_CueVisible_NoRowYet()
    var
        Cue: Record "LT Y65 Cue";
        P: TestPage "LT Y65 Cue Activities";
    begin
        Cue.DeleteAll();
        P.OpenEdit();
        ReadAll(P);
        P.Close();
        Observer.Observe('rows', Format(Cue.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y65_CueVisible_RowWithFlag()
    var
        Cue: Record "LT Y65 Cue";
        P: TestPage "LT Y65 Cue Activities";
    begin
        Cue.DeleteAll();
        Cue.Init();
        Cue.Flag := true;
        Cue.CueH := 4;
        Cue.Insert();
        P.OpenView();
        ReadAll(P);
        P.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenSalesRel()
    var
        Activities: TestPage "Sales & Relationship Mgr. Act.";
    begin
        Activities.OpenEdit();
        Activities.Close();
    end;

    [TryFunction]
    local procedure TryOpenSOProcessor()
    var
        Activities: TestPage "SO Processor Activities";
    begin
        Activities.OpenEdit();
        Activities.Close();
    end;

    [TryFunction]
    local procedure TryOpenO365()
    var
        Activities: TestPage "O365 Activities";
    begin
        Activities.OpenEdit();
        Activities.Close();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y65_CueVisible_Reporter_MicrosoftActivities()
    begin
        // al-runner issue 6675, the reporter's three pages.
        Observer.Observe('Sales & Relationship Mgr. Act.', Outcome(TryOpenSalesRel()));
        Observer.Observe('SO Processor Activities', Outcome(TryOpenSOProcessor()));
        Observer.Observe('O365 Activities', Outcome(TryOpenO365()));
        Observer.Finish();
    end;
}
