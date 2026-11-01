// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-valuesallowed-property
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// Fixtures used: Probe Observer (codeunit 69160); enum 93345, table 93345, pages 93356 (NavigatePage, temporary source), 93357 (Card),
//   93358 (List), test codeunit 93345
// Probe (al-runner issue 6672; ValuesAllowed on the PAGE control is pages/lt-y37-values-allowed/Y37ValuesAllowedSetValue.al and
//   pageext/lt-page-ext-properties/PageFieldValuesAllowed.al, Validate in code of a table field with ValuesAllowed is
//   pageext/lt-page-ext-properties/TableFieldValuesAllowed.al): TestPage SetValue on controls over TABLE fields that declare ValuesAllowed:
//   an Enum with gaps in its ordinals (0, 2, 3, 4), an Option, an Integer and a Decimal, plus an Enum field whose page control declares a
//   different ValuesAllowed of its own. SetValue with an Enum value, the member name as text, an Integer and a value outside the list, on a
//   NavigatePage over a temporary table (the reporter's wizard), a Card over a stored row (stored values read back after Close) and a List.
// BC versions: 27, 28, 29

enum 93345 "LT Y65 VA Mode"
{
    Extensible = true;

    value(0; All) { }
    value(2; "Mapped Only") { }
    value(3; None) { }
    value(4; "Published Only") { }
}

table 93345 "LT Y65 VA Settings"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Push Mode"; Enum "LT Y65 VA Mode")
        {
            ValuesAllowed = "Mapped Only", None;
        }
        field(3; Opt; Option)
        {
            OptionMembers = A,B,C,D;
            ValuesAllowed = B, D;
        }
        field(4; Int; Integer)
        {
            ValuesAllowed = 1, 5;
        }
        field(5; Dec; Decimal)
        {
            ValuesAllowed = 1.5, 2;
        }
        field(6; "Pull Mode"; Enum "LT Y65 VA Mode")
        {
            ValuesAllowed = "Mapped Only", None;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 93356 "LT Y65 VA Wizard"
{
    PageType = NavigatePage;
    SourceTable = "LT Y65 VA Settings";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Push Mode"; Rec."Push Mode") { ApplicationArea = All; }
            field(Opt; Rec.Opt) { ApplicationArea = All; }
            field(Int; Rec.Int) { ApplicationArea = All; }
            field(Dec; Rec.Dec) { ApplicationArea = All; }
            field("Pull Mode"; Rec."Pull Mode") { ApplicationArea = All; ValuesAllowed = All, None; }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."Code" := 'A';
        Rec."Push Mode" := Rec."Push Mode"::"Mapped Only";
        Rec.Insert();
    end;
}

page 93357 "LT Y65 VA Card"
{
    PageType = Card;
    SourceTable = "LT Y65 VA Settings";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field("Push Mode"; Rec."Push Mode") { ApplicationArea = All; }
            field(Opt; Rec.Opt) { ApplicationArea = All; }
            field(Int; Rec.Int) { ApplicationArea = All; }
            field(Dec; Rec.Dec) { ApplicationArea = All; }
            field("Pull Mode"; Rec."Pull Mode") { ApplicationArea = All; ValuesAllowed = All, None; }
        }
    }
}

page 93358 "LT Y65 VA List"
{
    PageType = List;
    SourceTable = "LT Y65 VA Settings";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("Push Mode"; Rec."Push Mode") { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
                field(Int; Rec.Int) { ApplicationArea = All; }
                field(Dec; Rec.Dec) { ApplicationArea = All; }
                field("Pull Mode"; Rec."Pull Mode") { ApplicationArea = All; ValuesAllowed = All, None; }
            }
        }
    }
}

codeunit 93345 "LT Y65 VA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(var Settings: Record "LT Y65 VA Settings")
    begin
        Settings.DeleteAll();
        Settings.Init();
        Settings."Code" := 'A';
        Settings."Push Mode" := Settings."Push Mode"::"Mapped Only";
        Settings.Opt := Settings.Opt::B;
        Settings.Int := 1;
        Settings.Dec := 1.5;
        Settings."Pull Mode" := Settings."Pull Mode"::"Mapped Only";
        Settings.Insert();
    end;

    local procedure Stored(): Text
    var
        Settings: Record "LT Y65 VA Settings";
    begin
        Settings.Get('A');
        exit(Format(Settings."Push Mode") + '|' + Format(Settings.Opt) + '|' + Format(Settings.Int) + '|' + Format(Settings.Dec) + '|' +
            Format(Settings."Pull Mode"));
    end;

    [TryFunction]
    local procedure TrySetWizard(var P: TestPage "LT Y65 VA Wizard"; Ctl: Text; V: Variant)
    begin
        case Ctl of
            'push':
                P."Push Mode".SetValue(V);
            'opt':
                P.Opt.SetValue(V);
            'int':
                P.Int.SetValue(V);
            'dec':
                P.Dec.SetValue(V);
            'pull':
                P."Pull Mode".SetValue(V);
        end;
    end;

    local procedure GetWizard(var P: TestPage "LT Y65 VA Wizard"; Ctl: Text): Text
    begin
        case Ctl of
            'push':
                exit(P."Push Mode".Value());
            'opt':
                exit(P.Opt.Value());
            'int':
                exit(P.Int.Value());
            'dec':
                exit(P.Dec.Value());
            'pull':
                exit(P."Pull Mode".Value());
        end;
    end;

    local procedure SetWizard(var P: TestPage "LT Y65 VA Wizard"; Ctl: Text; V: Variant): Text
    begin
        ClearLastError();
        if TrySetWizard(P, Ctl, V) then
            exit('ok:' + GetWizard(P, Ctl));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetWizard(P, Ctl));
    end;

    local procedure ProbeWizard(var P: TestPage "LT Y65 VA Wizard")
    var
        Mode: Enum "LT Y65 VA Mode";
    begin
        Observer.Observe('initial push', GetWizard(P, 'push'));
        Observer.Observe('push enum None', SetWizard(P, 'push', Mode::None));
        Observer.Observe('push enum All', SetWizard(P, 'push', Mode::All));
        Observer.Observe('push enum Published Only', SetWizard(P, 'push', Mode::"Published Only"));
        Observer.Observe('push text Mapped Only', SetWizard(P, 'push', 'Mapped Only'));
        Observer.Observe('push text published only', SetWizard(P, 'push', 'published only'));
        Observer.Observe('push integer 3', SetWizard(P, 'push', 3));
        Observer.Observe('push integer 1', SetWizard(P, 'push', 1));
        Observer.Observe('push integer 0', SetWizard(P, 'push', 0));
        Observer.Observe('push enum None again', SetWizard(P, 'push', Mode::None));
        Observer.Observe('opt text D', SetWizard(P, 'opt', 'D'));
        Observer.Observe('opt text A', SetWizard(P, 'opt', 'A'));
        Observer.Observe('opt integer 1', SetWizard(P, 'opt', 1));
        Observer.Observe('opt integer 2', SetWizard(P, 'opt', 2));
        Observer.Observe('int 5', SetWizard(P, 'int', 5));
        Observer.Observe('int 3', SetWizard(P, 'int', 3));
        Observer.Observe('int text 1', SetWizard(P, 'int', '1'));
        Observer.Observe('dec 2', SetWizard(P, 'dec', 2));
        Observer.Observe('dec 1.7', SetWizard(P, 'dec', 1.7));
        Observer.Observe('pull enum All', SetWizard(P, 'pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', SetWizard(P, 'pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', SetWizard(P, 'pull', Mode::None));
        Observer.Observe('pull enum Published Only', SetWizard(P, 'pull', Mode::"Published Only"));
    end;

    [TryFunction]
    local procedure TrySetCard(var P: TestPage "LT Y65 VA Card"; Ctl: Text; V: Variant)
    begin
        case Ctl of
            'push':
                P."Push Mode".SetValue(V);
            'opt':
                P.Opt.SetValue(V);
            'int':
                P.Int.SetValue(V);
            'dec':
                P.Dec.SetValue(V);
            'pull':
                P."Pull Mode".SetValue(V);
        end;
    end;

    local procedure GetCard(var P: TestPage "LT Y65 VA Card"; Ctl: Text): Text
    begin
        case Ctl of
            'push':
                exit(P."Push Mode".Value());
            'opt':
                exit(P.Opt.Value());
            'int':
                exit(P.Int.Value());
            'dec':
                exit(P.Dec.Value());
            'pull':
                exit(P."Pull Mode".Value());
        end;
    end;

    local procedure SetCard(var P: TestPage "LT Y65 VA Card"; Ctl: Text; V: Variant): Text
    begin
        ClearLastError();
        if TrySetCard(P, Ctl, V) then
            exit('ok:' + GetCard(P, Ctl));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetCard(P, Ctl));
    end;

    local procedure ProbeCard(var P: TestPage "LT Y65 VA Card")
    var
        Mode: Enum "LT Y65 VA Mode";
    begin
        Observer.Observe('initial push', GetCard(P, 'push'));
        Observer.Observe('push enum None', SetCard(P, 'push', Mode::None));
        Observer.Observe('push enum All', SetCard(P, 'push', Mode::All));
        Observer.Observe('push enum Published Only', SetCard(P, 'push', Mode::"Published Only"));
        Observer.Observe('push text Mapped Only', SetCard(P, 'push', 'Mapped Only'));
        Observer.Observe('push text published only', SetCard(P, 'push', 'published only'));
        Observer.Observe('push integer 3', SetCard(P, 'push', 3));
        Observer.Observe('push integer 1', SetCard(P, 'push', 1));
        Observer.Observe('push integer 0', SetCard(P, 'push', 0));
        Observer.Observe('push enum None again', SetCard(P, 'push', Mode::None));
        Observer.Observe('opt text D', SetCard(P, 'opt', 'D'));
        Observer.Observe('opt text A', SetCard(P, 'opt', 'A'));
        Observer.Observe('opt integer 1', SetCard(P, 'opt', 1));
        Observer.Observe('opt integer 2', SetCard(P, 'opt', 2));
        Observer.Observe('int 5', SetCard(P, 'int', 5));
        Observer.Observe('int 3', SetCard(P, 'int', 3));
        Observer.Observe('int text 1', SetCard(P, 'int', '1'));
        Observer.Observe('dec 2', SetCard(P, 'dec', 2));
        Observer.Observe('dec 1.7', SetCard(P, 'dec', 1.7));
        Observer.Observe('pull enum All', SetCard(P, 'pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', SetCard(P, 'pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', SetCard(P, 'pull', Mode::None));
        Observer.Observe('pull enum Published Only', SetCard(P, 'pull', Mode::"Published Only"));
    end;

    [TryFunction]
    local procedure TrySetList(var P: TestPage "LT Y65 VA List"; Ctl: Text; V: Variant)
    begin
        case Ctl of
            'push':
                P."Push Mode".SetValue(V);
            'opt':
                P.Opt.SetValue(V);
            'int':
                P.Int.SetValue(V);
            'dec':
                P.Dec.SetValue(V);
            'pull':
                P."Pull Mode".SetValue(V);
        end;
    end;

    local procedure GetList(var P: TestPage "LT Y65 VA List"; Ctl: Text): Text
    begin
        case Ctl of
            'push':
                exit(P."Push Mode".Value());
            'opt':
                exit(P.Opt.Value());
            'int':
                exit(P.Int.Value());
            'dec':
                exit(P.Dec.Value());
            'pull':
                exit(P."Pull Mode".Value());
        end;
    end;

    local procedure SetList(var P: TestPage "LT Y65 VA List"; Ctl: Text; V: Variant): Text
    begin
        ClearLastError();
        if TrySetList(P, Ctl, V) then
            exit('ok:' + GetList(P, Ctl));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetList(P, Ctl));
    end;

    local procedure ProbeList(var P: TestPage "LT Y65 VA List")
    var
        Mode: Enum "LT Y65 VA Mode";
    begin
        Observer.Observe('initial push', GetList(P, 'push'));
        Observer.Observe('push enum None', SetList(P, 'push', Mode::None));
        Observer.Observe('push enum All', SetList(P, 'push', Mode::All));
        Observer.Observe('push enum Published Only', SetList(P, 'push', Mode::"Published Only"));
        Observer.Observe('push text Mapped Only', SetList(P, 'push', 'Mapped Only'));
        Observer.Observe('push text published only', SetList(P, 'push', 'published only'));
        Observer.Observe('push integer 3', SetList(P, 'push', 3));
        Observer.Observe('push integer 1', SetList(P, 'push', 1));
        Observer.Observe('push integer 0', SetList(P, 'push', 0));
        Observer.Observe('push enum None again', SetList(P, 'push', Mode::None));
        Observer.Observe('opt text D', SetList(P, 'opt', 'D'));
        Observer.Observe('opt text A', SetList(P, 'opt', 'A'));
        Observer.Observe('opt integer 1', SetList(P, 'opt', 1));
        Observer.Observe('opt integer 2', SetList(P, 'opt', 2));
        Observer.Observe('int 5', SetList(P, 'int', 5));
        Observer.Observe('int 3', SetList(P, 'int', 3));
        Observer.Observe('int text 1', SetList(P, 'int', '1'));
        Observer.Observe('dec 2', SetList(P, 'dec', 2));
        Observer.Observe('dec 1.7', SetList(P, 'dec', 1.7));
        Observer.Observe('pull enum All', SetList(P, 'pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', SetList(P, 'pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', SetList(P, 'pull', Mode::None));
        Observer.Observe('pull enum Published Only', SetList(P, 'pull', Mode::"Published Only"));
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_Reporter()
    var
        P: TestPage "LT Y65 VA Wizard";
        Mode: Enum "LT Y65 VA Mode";
    begin
        P.OpenEdit();
        P."Push Mode".SetValue(Mode::None);
        Observer.Observe('reporter value', P."Push Mode".Value());
        Observer.Observe('format none', Format(Mode::None));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_Surface()
    var
        P: TestPage "LT Y65 VA Wizard";
    begin
        P.OpenEdit();
        ProbeWizard(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_Reporter()
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA Card";
        Mode: Enum "LT Y65 VA Mode";
    begin
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        P."Push Mode".SetValue(Mode::None);
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_Surface()
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA Card";
    begin
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        ProbeCard(P);
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure Y65_ValuesAllowed_List_Surface()
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA List";
    begin
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        ProbeList(P);
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;
}
