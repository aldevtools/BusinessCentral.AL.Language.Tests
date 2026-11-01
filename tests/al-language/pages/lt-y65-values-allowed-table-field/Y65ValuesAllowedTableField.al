// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-valuesallowed-property
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// Fixtures used: Probe Observer (codeunit 69160); enum 93345, table 93345, pages 93356 (NavigatePage, temporary source), 93357 (Card),
//   93358 (List), test codeunit 93345
// Probe (al-runner issue 6672; ValuesAllowed on the PAGE control is pages/lt-y37-values-allowed/Y37ValuesAllowedSetValue.al and
//   pageext/lt-page-ext-properties/PageFieldValuesAllowed.al, Validate in code of a table field with ValuesAllowed is
//   pageext/lt-page-ext-properties/TableFieldValuesAllowed.al): TestPage SetValue on controls over TABLE fields that declare ValuesAllowed:
//   an Enum with gaps in its ordinals (0, 2, 3, 4), an Option, an Integer and a Decimal, plus an Enum field whose page control declares a
//   different ValuesAllowed of its own. SetValue with an Enum value, the member name as text, an Integer and a value outside the list, each on a
//   freshly opened page (a validation error leaves the control in an error state): a NavigatePage over a temporary table (the reporter's
//   wizard), a Card and a List over a stored row (Close, then the stored value).
// Results (SaaS sandbox BC 29): an allowed Enum value or ordinal Integer is accepted and stored. A value outside the list raises
//   TestValidation 'Your entry of '<n>' is not an acceptable value for '<field>'.' (Enum, Option) or 'Value '<v>' is not a valid value.
//   The following values can be used: 1;5.' (Integer, Decimal), with ' (Select Refresh to discard errors)' on the Card; <n> is the position
//   of the current value, not the value typed. A member name as text raises 'The value "<text>" can't be evaluated into type Option.'
//   (Evaluate:Format). The page control's own ValuesAllowed replaces the table field's.
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
        Mode: Enum "LT Y65 VA Mode";

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

    local procedure Stored(Ctl: Text): Text
    var
        Settings: Record "LT Y65 VA Settings";
    begin
        Settings.Get('A');
        case Ctl of
            'push':
                exit(Format(Settings."Push Mode"));
            'opt':
                exit(Format(Settings.Opt));
            'int':
                exit(Format(Settings.Int));
            'dec':
                exit(Format(Settings.Dec));
            'pull':
                exit(Format(Settings."Pull Mode"));
        end;
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

    [TryFunction]
    local procedure TryCloseWizard(var P: TestPage "LT Y65 VA Wizard")
    begin
        P.Close();
    end;

    local procedure CaseWizard(Ctl: Text; V: Variant) R: Text
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA Wizard";
    begin
        P.OpenEdit();
        ClearLastError();
        if TrySetWizard(P, Ctl, V) then
            R := 'ok:' + GetWizard(P, Ctl)
        else
            R := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetWizard(P, Ctl);
        ClearLastError();
        if not TryCloseWizard(P) then
            R += ' close=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_EnumValues()
    begin
        Observer.Observe('push enum None', CaseWizard('push', Mode::None));
        Observer.Observe('push enum All', CaseWizard('push', Mode::All));
        Observer.Observe('push enum Published Only', CaseWizard('push', Mode::"Published Only"));
        Observer.Observe('push enum Mapped Only', CaseWizard('push', Mode::"Mapped Only"));
        Observer.Expect('push enum None', 'ok:None');
        Observer.Expect('push enum All', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2');
        Observer.Expect('push enum Published Only', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2');
        Observer.Expect('push enum Mapped Only', 'ok:Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_EnumTextAndInteger()
    begin
        Observer.Observe('push text None', CaseWizard('push', 'None'));
        Observer.Observe('push text published only', CaseWizard('push', 'published only'));
        Observer.Observe('push integer 3', CaseWizard('push', 3));
        Observer.Observe('push integer 1', CaseWizard('push', 1));
        Observer.Observe('push integer 0', CaseWizard('push', 0));
        Observer.Expect('push text None', 'error:The value "None" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only');
        Observer.Expect('push text published only', 'error:The value "published only" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only');
        Observer.Expect('push integer 3', 'ok:None');
        Observer.Expect('push integer 1', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2');
        Observer.Expect('push integer 0', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_OptionAndInteger()
    begin
        Observer.Observe('opt text D', CaseWizard('opt', 'D'));
        Observer.Observe('opt text A', CaseWizard('opt', 'A'));
        Observer.Observe('opt integer 1', CaseWizard('opt', 1));
        Observer.Observe('opt integer 2', CaseWizard('opt', 2));
        Observer.Observe('int 5', CaseWizard('int', 5));
        Observer.Observe('int 3', CaseWizard('int', 3));
        Observer.Observe('int text 1', CaseWizard('int', '1'));
        Observer.Expect('opt text D', 'error:The value "D" can''t be evaluated into type Option.|Evaluate:Format|now 0');
        Observer.Expect('opt text A', 'error:The value "A" can''t be evaluated into type Option.|Evaluate:Format|now 0');
        Observer.Expect('opt integer 1', 'ok:B');
        Observer.Expect('opt integer 2', 'error:Validation error for Field: Opt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Opt''.''|TestValidation|now 0');
        Observer.Expect('int 5', 'ok:5');
        Observer.Expect('int 3', 'error:Validation error for Field: Int,  Message = ''Value ''3'' is not a valid value. The following values can be used: 1;5.''|TestValidation|now 0');
        Observer.Expect('int text 1', 'ok:1');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_DecimalAndControlList()
    begin
        Observer.Observe('dec 2', CaseWizard('dec', 2));
        Observer.Observe('dec 1.7', CaseWizard('dec', 1.7));
        Observer.Observe('pull enum All', CaseWizard('pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', CaseWizard('pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', CaseWizard('pull', Mode::None));
        Observer.Observe('pull enum Published Only', CaseWizard('pull', Mode::"Published Only"));
        Observer.Expect('dec 2', 'error:Validation error for Field: Dec,  Message = ''Value ''2.00'' is not a valid value. The following values can be used: 1.5;2.''|TestValidation|now 0.00');
        Observer.Expect('dec 1.7', 'error:Validation error for Field: Dec,  Message = ''Value ''1.70'' is not a valid value. The following values can be used: 1.5;2.''|TestValidation|now 0.00');
        Observer.Expect('pull enum All', 'ok:All');
        Observer.Expect('pull enum Mapped Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''0'' is not an acceptable value for ''Pull Mode''.''|TestValidation|now 0');
        Observer.Expect('pull enum None', 'ok:None');
        Observer.Expect('pull enum Published Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''0'' is not an acceptable value for ''Pull Mode''.''|TestValidation|now 0');
        Observer.Verify();
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

    [TryFunction]
    local procedure TryCloseCard(var P: TestPage "LT Y65 VA Card")
    begin
        P.Close();
    end;

    local procedure CaseCard(Ctl: Text; V: Variant) R: Text
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA Card";
    begin
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        ClearLastError();
        if TrySetCard(P, Ctl, V) then
            R := 'ok:' + GetCard(P, Ctl)
        else
            R := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetCard(P, Ctl);
        ClearLastError();
        if not TryCloseCard(P) then
            R += ' close=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        R += ' stored=' + Stored(Ctl);
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_EnumValues()
    begin
        Observer.Observe('push enum None', CaseCard('push', Mode::None));
        Observer.Observe('push enum All', CaseCard('push', Mode::All));
        Observer.Observe('push enum Published Only', CaseCard('push', Mode::"Published Only"));
        Observer.Observe('push enum Mapped Only', CaseCard('push', Mode::"Mapped Only"));
        Observer.Expect('push enum None', 'ok:None stored=None');
        Observer.Expect('push enum All', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push enum Published Only', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push enum Mapped Only', 'ok:Mapped Only stored=Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_EnumTextAndInteger()
    begin
        Observer.Observe('push text None', CaseCard('push', 'None'));
        Observer.Observe('push text published only', CaseCard('push', 'published only'));
        Observer.Observe('push integer 3', CaseCard('push', 3));
        Observer.Observe('push integer 1', CaseCard('push', 1));
        Observer.Observe('push integer 0', CaseCard('push', 0));
        Observer.Expect('push text None', 'error:The value "None" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only stored=Mapped Only');
        Observer.Expect('push text published only', 'error:The value "published only" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only stored=Mapped Only');
        Observer.Expect('push integer 3', 'ok:None stored=None');
        Observer.Expect('push integer 1', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push integer 0', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_OptionAndInteger()
    begin
        Observer.Observe('opt text D', CaseCard('opt', 'D'));
        Observer.Observe('opt text A', CaseCard('opt', 'A'));
        Observer.Observe('opt integer 1', CaseCard('opt', 1));
        Observer.Observe('opt integer 2', CaseCard('opt', 2));
        Observer.Observe('int 5', CaseCard('int', 5));
        Observer.Observe('int 3', CaseCard('int', 3));
        Observer.Observe('int text 1', CaseCard('int', '1'));
        Observer.Expect('opt text D', 'error:The value "D" can''t be evaluated into type Option.|Evaluate:Format|now B stored=B');
        Observer.Expect('opt text A', 'error:The value "A" can''t be evaluated into type Option.|Evaluate:Format|now B stored=B');
        Observer.Expect('opt integer 1', 'ok:B stored=B');
        Observer.Expect('opt integer 2', 'error:Validation error for Field: Opt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''|TestValidation|now 1 stored=B');
        Observer.Expect('int 5', 'ok:5 stored=5');
        Observer.Expect('int 3', 'error:Validation error for Field: Int,  Message = ''Value ''3'' is not a valid value. The following values can be used: 1;5. (Select Refresh to discard errors)''|TestValidation|now 1 stored=1');
        Observer.Expect('int text 1', 'ok:1 stored=1');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_DecimalAndControlList()
    begin
        Observer.Observe('dec 2', CaseCard('dec', 2));
        Observer.Observe('dec 1.7', CaseCard('dec', 1.7));
        Observer.Observe('pull enum All', CaseCard('pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', CaseCard('pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', CaseCard('pull', Mode::None));
        Observer.Observe('pull enum Published Only', CaseCard('pull', Mode::"Published Only"));
        Observer.Expect('dec 2', 'error:Validation error for Field: Dec,  Message = ''Value ''2.00'' is not a valid value. The following values can be used: 1.5;2. (Select Refresh to discard errors)''|TestValidation|now 1.50 stored=1.5');
        Observer.Expect('dec 1.7', 'error:Validation error for Field: Dec,  Message = ''Value ''1.70'' is not a valid value. The following values can be used: 1.5;2. (Select Refresh to discard errors)''|TestValidation|now 1.50 stored=1.5');
        Observer.Expect('pull enum All', 'ok:All stored=All');
        Observer.Expect('pull enum Mapped Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Pull Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('pull enum None', 'ok:None stored=None');
        Observer.Expect('pull enum Published Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Pull Mode''. (Select Refresh to discard errors)''|TestValidation|now 2 stored=Mapped Only');
        Observer.Verify();
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

    [TryFunction]
    local procedure TryCloseList(var P: TestPage "LT Y65 VA List")
    begin
        P.Close();
    end;

    local procedure CaseList(Ctl: Text; V: Variant) R: Text
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA List";
    begin
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        ClearLastError();
        if TrySetList(P, Ctl, V) then
            R := 'ok:' + GetList(P, Ctl)
        else
            R := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|now ' + GetList(P, Ctl);
        ClearLastError();
        if not TryCloseList(P) then
            R += ' close=error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        R += ' stored=' + Stored(Ctl);
    end;

    [Test]
    procedure Y65_ValuesAllowed_List_EnumValues()
    begin
        Observer.Observe('push enum None', CaseList('push', Mode::None));
        Observer.Observe('push enum All', CaseList('push', Mode::All));
        Observer.Observe('push enum Published Only', CaseList('push', Mode::"Published Only"));
        Observer.Observe('push enum Mapped Only', CaseList('push', Mode::"Mapped Only"));
        Observer.Expect('push enum None', 'ok:None stored=None');
        Observer.Expect('push enum All', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push enum Published Only', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push enum Mapped Only', 'ok:Mapped Only stored=Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_List_EnumTextAndInteger()
    begin
        Observer.Observe('push text None', CaseList('push', 'None'));
        Observer.Observe('push text published only', CaseList('push', 'published only'));
        Observer.Observe('push integer 3', CaseList('push', 3));
        Observer.Observe('push integer 1', CaseList('push', 1));
        Observer.Observe('push integer 0', CaseList('push', 0));
        Observer.Expect('push text None', 'error:The value "None" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only stored=Mapped Only');
        Observer.Expect('push text published only', 'error:The value "published only" can''t be evaluated into type Option.|Evaluate:Format|now Mapped Only stored=Mapped Only');
        Observer.Expect('push integer 3', 'ok:None stored=None');
        Observer.Expect('push integer 1', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('push integer 0', 'error:Validation error for Field: Push Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Push Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_List_OptionAndInteger()
    begin
        Observer.Observe('opt text D', CaseList('opt', 'D'));
        Observer.Observe('opt text A', CaseList('opt', 'A'));
        Observer.Observe('opt integer 1', CaseList('opt', 1));
        Observer.Observe('opt integer 2', CaseList('opt', 2));
        Observer.Observe('int 5', CaseList('int', 5));
        Observer.Observe('int 3', CaseList('int', 3));
        Observer.Observe('int text 1', CaseList('int', '1'));
        Observer.Expect('opt text D', 'error:The value "D" can''t be evaluated into type Option.|Evaluate:Format|now B stored=B');
        Observer.Expect('opt text A', 'error:The value "A" can''t be evaluated into type Option.|Evaluate:Format|now B stored=B');
        Observer.Expect('opt integer 1', 'ok:B stored=B');
        Observer.Expect('opt integer 2', 'error:Validation error for Field: Opt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''.''|TestValidation|now 1 stored=B');
        Observer.Expect('int 5', 'ok:5 stored=5');
        Observer.Expect('int 3', 'error:Validation error for Field: Int,  Message = ''Value ''3'' is not a valid value. The following values can be used: 1;5.''|TestValidation|now 1 stored=1');
        Observer.Expect('int text 1', 'ok:1 stored=1');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_List_DecimalAndControlList()
    begin
        Observer.Observe('dec 2', CaseList('dec', 2));
        Observer.Observe('dec 1.7', CaseList('dec', 1.7));
        Observer.Observe('pull enum All', CaseList('pull', Mode::All));
        Observer.Observe('pull enum Mapped Only', CaseList('pull', Mode::"Mapped Only"));
        Observer.Observe('pull enum None', CaseList('pull', Mode::None));
        Observer.Observe('pull enum Published Only', CaseList('pull', Mode::"Published Only"));
        Observer.Expect('dec 2', 'error:Validation error for Field: Dec,  Message = ''Value ''2.00'' is not a valid value. The following values can be used: 1.5;2.''|TestValidation|now 1.50 stored=1.5');
        Observer.Expect('dec 1.7', 'error:Validation error for Field: Dec,  Message = ''Value ''1.70'' is not a valid value. The following values can be used: 1.5;2.''|TestValidation|now 1.50 stored=1.5');
        Observer.Expect('pull enum All', 'ok:All stored=All');
        Observer.Expect('pull enum Mapped Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Pull Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Expect('pull enum None', 'ok:None stored=None');
        Observer.Expect('pull enum Published Only', 'error:Validation error for Field: Pull Mode,  Message = ''Your entry of ''2'' is not an acceptable value for ''Pull Mode''.''|TestValidation|now 2 stored=Mapped Only');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Wizard_Reporter()
    var
        P: TestPage "LT Y65 VA Wizard";
    begin
        // al-runner issue 6672, the reporter's wizard.
        P.OpenEdit();
        Observer.Observe('initial', P."Push Mode".Value());
        P."Push Mode".SetValue(Mode::None);
        Observer.Observe('reporter value', P."Push Mode".Value());
        Observer.Observe('format none', Format(Mode::None));
        P.Close();
        Observer.Expect('initial', 'Mapped Only');
        Observer.Expect('reporter value', 'None');
        Observer.Expect('format none', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure Y65_ValuesAllowed_Card_Reporter()
    var
        Settings: Record "LT Y65 VA Settings";
        P: TestPage "LT Y65 VA Card";
    begin
        // al-runner issue 6672, the reporter's card.
        Seed(Settings);
        P.OpenEdit();
        P.GoToRecord(Settings);
        P."Push Mode".SetValue(Mode::None);
        P.Close();
        Observer.Observe('stored', Stored('push'));
        Observer.Expect('stored', 'None');
        Observer.Verify();
    end;
}
