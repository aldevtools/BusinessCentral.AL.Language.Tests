// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-enabled-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); CcVqMemberEnumProbeNs.al (enum 97290, page 97298); this file (enum 97291, tables
//   97292-97293, pages 97294-97297, page extension 97301, codeunit 97300)
// Probe (observation form, al-runner 6924, extends writer VQ in CcPageLeads.al VisibleExpr_V1 to V6): page control expressions
//   (Visible, Editable, Enabled) that name a qualified value through a member of a variable.
//   V7: an Option field of a global Record (Opt = E.OptField::B).
//   V8: <> and compound expressions with or, and, not around E.Mode::X.
//   V9: a page extension's own global Record (ExtDir = ExtE.Mode::Beta) on a field and an action it adds and on a base
//       control it modifies.
//   V10: a List: a repeater field's Editable, an action's Visible and an action group's Visible, with OnAfterGetRecord
//        setting the global per row.
//   V11: an enum named through a one-segment namespace (Dir = LTVQProbe."LT VQP Ns Kind"::Beta), on a page of that namespace
//        (CcVqMemberEnumProbeNs.al). On a page of the global namespace the same text does not compile with the AL 18.1 compiler
//        (AL0118 "The name 'LTVQProbe' does not exist in the current context.", one per property).
// Each test records whether the page opens and every value; Finish() raises them.
// BC versions: 27.5, 28.5, 29.0 (CI).

enum 97291 "LT VQP Kind"
{
    Extensible = false;

    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; Gamma) { }
}

table 97292 "LT VQP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT VQP Kind") { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97293 "LT VQP Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mode; Enum "LT VQP Kind") { }
        field(3; OptField; Option) { OptionMembers = A,B,C; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 97294 "LT VQP Page V7"
{
    PageType = Card;
    SourceTable = "LT VQP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(VisCtl; Rec.Name)
            {
                ApplicationArea = All;
                Visible = Opt = E.OptField::B;
            }
            field(EdtCtl; Rec.Name)
            {
                ApplicationArea = All;
                Editable = Opt = E.OptField::B;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActCtl)
            {
                ApplicationArea = All;
                Enabled = Opt = E.OptField::B;

                trigger OnAction()
                begin
                end;
            }
            action(FlipCtl)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Opt := Opt::A;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Opt := Opt::B;
    end;

    var
        E: Record "LT VQP Other";
        Opt: Option A,B,C;
}

page 97295 "LT VQP Page V8"
{
    PageType = Card;
    SourceTable = "LT VQP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(VisCtl; Rec.Name)
            {
                ApplicationArea = All;
                Visible = Dir <> E.Mode::Alpha;
            }
            field(EdtCtl; Rec.Name)
            {
                ApplicationArea = All;
                Editable = (Rec.Kind = E.Mode::Alpha) or (Rec.Kind = E.Mode::Gamma);
            }
            field(EdtCtl2; Rec.Name)
            {
                ApplicationArea = All;
                Editable = not (Dir = E.Mode::Beta) and (Rec.Kind <> E.Mode::Gamma);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActCtl)
            {
                ApplicationArea = All;
                Enabled = (Dir = E.Mode::Alpha) or (Dir = E.Mode::Beta);

                trigger OnAction()
                begin
                end;
            }
            action(FlipCtl)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Dir := Dir::Gamma;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Dir := Dir::Beta;
    end;

    var
        E: Record "LT VQP Other";
        Dir: Enum "LT VQP Kind";
}

page 97296 "LT VQP Page V9"
{
    PageType = Card;
    SourceTable = "LT VQP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(BaseCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

pageextension 97301 "LT VQP Page V9 Ext" extends "LT VQP Page V9"
{
    layout
    {
        addlast(Content)
        {
            field(ExtVis; Rec.Name)
            {
                ApplicationArea = All;
                Visible = ExtDir = ExtE.Mode::Beta;
            }
            field(ExtEdt; Rec.Name)
            {
                ApplicationArea = All;
                Editable = Rec.Kind = ExtE.Mode::Beta;
            }
        }
        modify(BaseCtl)
        {
            Editable = ExtDir = ExtE.Mode::Beta;
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;
                Enabled = ExtDir = ExtE.Mode::Beta;

                trigger OnAction()
                begin
                end;
            }
            action(ExtFlip)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExtDir := ExtDir::Alpha;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExtDir := ExtDir::Beta;
    end;

    var
        ExtE: Record "LT VQP Other";
        ExtDir: Enum "LT VQP Kind";
}

page 97297 "LT VQP Page V10"
{
    PageType = List;
    SourceTable = "LT VQP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RepEdt; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = Rec.Kind = E.Mode::Beta;
                }
                field(RepEdtDir; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = Dir = E.Mode::Beta;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActVis)
            {
                ApplicationArea = All;
                Visible = Dir = E.Mode::Beta;

                trigger OnAction()
                begin
                end;
            }
            group(ActGrp)
            {
                Visible = Dir = E.Mode::Beta;

                action(ActIn)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Dir := Dir::Beta;
    end;

    trigger OnAfterGetRecord()
    begin
        Dir := Rec.Kind;
    end;

    var
        E: Record "LT VQP Other";
        Dir: Enum "LT VQP Kind";
}

codeunit 97300 "LT VQP Probe"
{
    Subtype = Test;

    var
        OkTxt: Label 'LT VQP step ok', Locked = true;

    // Rows 1, 2, 3 with Kind Alpha, Beta, Gamma.
    local procedure Prepare()
    var
        Row: Record "LT VQP Row";
        Idx: Integer;
    begin
        Row.DeleteAll();
        for Idx := 1 to 3 do begin
            Row.Init();
            Row.Id := Idx;
            Row.Kind := Enum::"LT VQP Kind".FromInteger(Idx - 1);
            Row.Name := 'row' + Format(Idx);
            Row.Insert();
        end;
    end;

    local procedure Outcome(): Text
    var
        Result: Text;
    begin
        if GetLastErrorText() = OkTxt then
            Result := 'ok'
        else
            Result := 'error: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    local procedure OpenV7(var P: TestPage "LT VQP Page V7")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure VqProbe_V7()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT VQP Page V7";
        Res: Text;
        Idx: Integer;
    begin
        Prepare();
        asserterror OpenV7(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            P.OpenEdit();
            for Idx := 1 to 3 do begin
                P.GoToKey(Idx);
                Observer.Observe('visible_' + Format(Idx), Format(P.VisCtl.Visible()));
                Observer.Observe('editable_' + Format(Idx), Format(P.EdtCtl.Editable()));
                Observer.Observe('enabled_' + Format(Idx), Format(P.ActCtl.Enabled()));
            end;
            P.GoToKey(2);
            P.FlipCtl.Invoke();
            Observer.Observe('visible_flipped', Format(P.VisCtl.Visible()));
            Observer.Observe('editable_flipped', Format(P.EdtCtl.Editable()));
            Observer.Observe('enabled_flipped', Format(P.ActCtl.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenV8(var P: TestPage "LT VQP Page V8")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure VqProbe_V8()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT VQP Page V8";
        Res: Text;
        Idx: Integer;
    begin
        Prepare();
        asserterror OpenV8(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            P.OpenEdit();
            for Idx := 1 to 3 do begin
                P.GoToKey(Idx);
                Observer.Observe('visible_' + Format(Idx), Format(P.VisCtl.Visible()));
                Observer.Observe('editable_' + Format(Idx), Format(P.EdtCtl.Editable()));
                Observer.Observe('editable2_' + Format(Idx), Format(P.EdtCtl2.Editable()));
                Observer.Observe('enabled_' + Format(Idx), Format(P.ActCtl.Enabled()));
            end;
            P.GoToKey(2);
            P.FlipCtl.Invoke();
            Observer.Observe('visible_flipped', Format(P.VisCtl.Visible()));
            Observer.Observe('editable_flipped', Format(P.EdtCtl.Editable()));
            Observer.Observe('editable2_flipped', Format(P.EdtCtl2.Editable()));
            Observer.Observe('enabled_flipped', Format(P.ActCtl.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenV9(var P: TestPage "LT VQP Page V9")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure VqProbe_V9()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT VQP Page V9";
        Res: Text;
        Idx: Integer;
    begin
        Prepare();
        asserterror OpenV9(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            P.OpenEdit();
            for Idx := 1 to 3 do begin
                P.GoToKey(Idx);
                Observer.Observe('ext_visible_' + Format(Idx), Format(P.ExtVis.Visible()));
                Observer.Observe('ext_editable_' + Format(Idx), Format(P.ExtEdt.Editable()));
                Observer.Observe('base_editable_' + Format(Idx), Format(P.BaseCtl.Editable()));
                Observer.Observe('ext_enabled_' + Format(Idx), Format(P.ExtAct.Enabled()));
            end;
            P.GoToKey(2);
            P.ExtFlip.Invoke();
            Observer.Observe('ext_visible_flipped', Format(P.ExtVis.Visible()));
            Observer.Observe('ext_editable_flipped', Format(P.ExtEdt.Editable()));
            Observer.Observe('base_editable_flipped', Format(P.BaseCtl.Editable()));
            Observer.Observe('ext_enabled_flipped', Format(P.ExtAct.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenV10(var P: TestPage "LT VQP Page V10")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure VqProbe_V10()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT VQP Page V10";
        Res: Text;
        Idx: Integer;
    begin
        Prepare();
        asserterror OpenV10(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            P.OpenEdit();
            Observer.Observe('first_rep_editable', Format(P.RepEdt.Editable()));
            Observer.Observe('first_rep_editable_dir', Format(P.RepEdtDir.Editable()));
            Observer.Observe('first_act_visible', Format(P.ActVis.Visible()));
            Observer.Observe('first_actin_visible', Format(P.ActIn.Visible()));
            for Idx := 1 to 3 do begin
                P.GoToKey(Idx);
                Observer.Observe('rep_editable_' + Format(Idx), Format(P.RepEdt.Editable()));
                Observer.Observe('rep_editable_dir_' + Format(Idx), Format(P.RepEdtDir.Editable()));
                Observer.Observe('act_visible_' + Format(Idx), Format(P.ActVis.Visible()));
                Observer.Observe('actin_visible_' + Format(Idx), Format(P.ActIn.Visible()));
            end;
            P.Close();
        end;
        Observer.Finish();
    end;

    local procedure OpenV11(var P: TestPage LTVQProbe."LT VQP Page V11")
    begin
        P.OpenEdit();
        Error(OkTxt);
    end;

    [Test]
    procedure VqProbe_V11()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage LTVQProbe."LT VQP Page V11";
        Res: Text;
        Idx: Integer;
    begin
        Prepare();
        asserterror OpenV11(P);
        Res := Outcome();
        Observer.Observe('open', Res);
        if Res = 'ok' then begin
            P.Close();
            P.OpenEdit();
            for Idx := 1 to 3 do begin
                P.GoToKey(Idx);
                Observer.Observe('visible_' + Format(Idx), Format(P.VisCtl.Visible()));
                Observer.Observe('editable_' + Format(Idx), Format(P.EdtCtl.Editable()));
                Observer.Observe('enabled_' + Format(Idx), Format(P.ActCtl.Enabled()));
            end;
            P.GoToKey(2);
            P.FlipCtl.Invoke();
            Observer.Observe('visible_flipped', Format(P.VisCtl.Visible()));
            Observer.Observe('editable_flipped', Format(P.EdtCtl.Editable()));
            Observer.Observe('enabled_flipped', Format(P.ActCtl.Enabled()));
            P.Close();
        end;
        Observer.Finish();
    end;
}
