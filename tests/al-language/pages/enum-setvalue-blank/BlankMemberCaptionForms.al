// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope (Cloud). TestPage only.
// local object: the Caption of the enum member " " (none, a space, empty) is what is under test
// Fixtures used: Probe Observer (codeunit 69160); own enums 63470 to 63472, table 63470, page 63473, test codeunit 63479
// Probe (al-runner issue 7439): a TestPage control over an Enum field whose value 0 is the member " ", declared without a Caption, with
//   Caption = ' ' and with Caption = ''. The control holds the member Letter first; then it gets, one input at a time, Value := Format(member),
//   SetValue(' '), SetValue(''), SetValue(the member) and SetValue(0). The reading is Format of the member, and per input whether it is
//   accepted (or the error text and code) and the value and the ordinal the control shows afterwards.
//   Already pinned: BeEnumSetValueBlank.al (Caption = ' ' only: SetValue of Integer, Text and the member on a card and a list),
//   QzNotBlankEnumList.al (NotBlank).
// BC versions: 27, 28, 29

enum 63470 "PNL BE No Caption"
{
    Extensible = false;

    value(0; " ") { }
    value(1; Letter) { Caption = 'Letter'; }
    value(2; Email) { Caption = 'Email'; }
}

enum 63471 "PNL BE Space Caption"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Letter) { Caption = 'Letter'; }
    value(2; Email) { Caption = 'Email'; }
}

enum 63472 "PNL BE Empty Caption"
{
    Extensible = false;

    value(0; " ") { Caption = ''; }
    value(1; Letter) { Caption = 'Letter'; }
    value(2; Email) { Caption = 'Email'; }
}

table 63470 "PNL BE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "No Caption"; Enum "PNL BE No Caption") { }
        field(3; "Space Caption"; Enum "PNL BE Space Caption") { }
        field(4; "Empty Caption"; Enum "PNL BE Empty Caption") { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 63473 "PNL BE Card"
{
    PageType = Card;
    SourceTable = "PNL BE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("No Caption"; Rec."No Caption") { ApplicationArea = All; }
                field("Space Caption"; Rec."Space Caption") { ApplicationArea = All; }
                field("Empty Caption"; Rec."Empty Caption") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 63479 "PNL Blank Member Captions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Row: Record "PNL BE Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Row."Code" := 'A';
        Row."No Caption" := Row."No Caption"::Letter;
        Row."Space Caption" := Row."Space Caption"::Letter;
        Row."Empty Caption" := Row."Empty Caption"::Letter;
        Row.Insert();
    end;

    // Ctl: 1 = "No Caption", 2 = "Space Caption", 3 = "Empty Caption".
    [TryFunction]
    local procedure TryAssignValue(var P: TestPage "PNL BE Card"; Ctl: Integer; NewValue: Text)
    begin
        case Ctl of
            1:
                P."No Caption".Value := NewValue;
            2:
                P."Space Caption".Value := NewValue;
            3:
                P."Empty Caption".Value := NewValue;
        end;
    end;

    [TryFunction]
    local procedure TrySetValue(var P: TestPage "PNL BE Card"; Ctl: Integer; NewValue: Variant)
    begin
        case Ctl of
            1:
                P."No Caption".SetValue(NewValue);
            2:
                P."Space Caption".SetValue(NewValue);
            3:
                P."Empty Caption".SetValue(NewValue);
        end;
    end;

    [TryFunction]
    local procedure TryRead(var P: TestPage "PNL BE Card"; Ctl: Integer; var Shown: Text)
    begin
        case Ctl of
            1:
                Shown := '[' + P."No Caption".Value() + ']/' + Format(P."No Caption".AsInteger());
            2:
                Shown := '[' + P."Space Caption".Value() + ']/' + Format(P."Space Caption".AsInteger());
            3:
                Shown := '[' + P."Empty Caption".Value() + ']/' + Format(P."Empty Caption".AsInteger());
        end;
    end;

    local procedure Reading(var P: TestPage "PNL BE Card"; Ctl: Integer; Name: Text; Ok: Boolean)
    var
        Shown: Text;
    begin
        if Ok then
            Observer.Observe(Name, 'accepted')
        else
            Observer.ObserveError(Name);
        if TryRead(P, Ctl, Shown) then
            Observer.Observe(Name + ' shows', Shown)
        else
            Observer.ObserveError(Name + ' read');
        // Back to Letter for the next input.
        if not TrySetValue(P, Ctl, 'Letter') then
            ClearLastError();
    end;

    local procedure Inputs(var P: TestPage "PNL BE Card"; Ctl: Integer; FormattedMember: Text; Member: Variant)
    var
        Zero: Integer;
    begin
        Observer.Observe('Format of the member', '[' + FormattedMember + ']');
        Reading(P, Ctl, 'Value := Format(member)', TryAssignValue(P, Ctl, FormattedMember));
        Reading(P, Ctl, 'SetValue(space)', TrySetValue(P, Ctl, ' '));
        Reading(P, Ctl, 'SetValue(empty)', TrySetValue(P, Ctl, ''));
        Reading(P, Ctl, 'SetValue(member)', TrySetValue(P, Ctl, Member));
        Reading(P, Ctl, 'SetValue(0)', TrySetValue(P, Ctl, Zero));
    end;

    [Test]
    procedure BlankMember_NoCaption_ValueAndSetValueInputs()
    var
        P: TestPage "PNL BE Card";
        Member: Enum "PNL BE No Caption";
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        Member := Member::" ";
        Inputs(P, 1, Format(Member), Member);
        P.Close();
#if BC28PLUS
        Observer.Expect('Format of the member', '[ ]');
        Observer.Expect('Value := Format(member)', 'accepted');
        Observer.Expect('Value := Format(member) shows', '[ ]/0');
        Observer.Expect('SetValue(space)|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('SetValue(space)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(space) shows', '[ ]/0');
        Observer.Expect('SetValue(empty)|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('SetValue(empty)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(empty) shows', '[ ]/0');
        Observer.Expect('SetValue(member)', 'accepted');
        Observer.Expect('SetValue(member) shows', '[ ]/0');
        Observer.Expect('SetValue(0)', 'accepted');
        Observer.Expect('SetValue(0) shows', '[ ]/0');
        Observer.Verify();
#else
        Observer.Expect('Format of the member', '[ ]');
        Observer.Expect('Value := Format(member)', 'accepted');
        Observer.Expect('Value := Format(member) shows', '[ ]/0');
        Observer.Expect('SetValue(space)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(space)|code', 'NotSupportedType');
        Observer.Expect('SetValue(space) shows', '[ ]/0');
        Observer.Expect('SetValue(empty)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(empty)|code', 'NotSupportedType');
        Observer.Expect('SetValue(empty) shows', '[ ]/0');
        Observer.Expect('SetValue(member)', 'accepted');
        Observer.Expect('SetValue(member) shows', '[ ]/0');
        Observer.Expect('SetValue(0)', 'accepted');
        Observer.Expect('SetValue(0) shows', '[ ]/0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BlankMember_SpaceCaption_ValueAndSetValueInputs()
    var
        P: TestPage "PNL BE Card";
        Member: Enum "PNL BE Space Caption";
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        Member := Member::" ";
        Inputs(P, 2, Format(Member), Member);
        P.Close();
#if BC28PLUS
        Observer.Expect('Format of the member', '[ ]');
        Observer.Expect('Value := Format(member)', 'accepted');
        Observer.Expect('Value := Format(member) shows', '[ ]/0');
        Observer.Expect('SetValue(space)|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('SetValue(space)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(space) shows', '[ ]/0');
        Observer.Expect('SetValue(empty)|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('SetValue(empty)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(empty) shows', '[ ]/0');
        Observer.Expect('SetValue(member)', 'accepted');
        Observer.Expect('SetValue(member) shows', '[ ]/0');
        Observer.Expect('SetValue(0)', 'accepted');
        Observer.Expect('SetValue(0) shows', '[ ]/0');
        Observer.Verify();
#else
        Observer.Expect('Format of the member', '[ ]');
        Observer.Expect('Value := Format(member)', 'accepted');
        Observer.Expect('Value := Format(member) shows', '[ ]/0');
        Observer.Expect('SetValue(space)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(space)|code', 'NotSupportedType');
        Observer.Expect('SetValue(space) shows', '[ ]/0');
        Observer.Expect('SetValue(empty)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(empty)|code', 'NotSupportedType');
        Observer.Expect('SetValue(empty) shows', '[ ]/0');
        Observer.Expect('SetValue(member)', 'accepted');
        Observer.Expect('SetValue(member) shows', '[ ]/0');
        Observer.Expect('SetValue(0)', 'accepted');
        Observer.Expect('SetValue(0) shows', '[ ]/0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BlankMember_EmptyCaption_ValueAndSetValueInputs()
    var
        P: TestPage "PNL BE Card";
        Member: Enum "PNL BE Empty Caption";
    begin
        Initialize();
        P.OpenEdit();
        P.First();
        Member := Member::" ";
        Inputs(P, 3, Format(Member), Member);
        P.Close();
#if BC28PLUS
        Observer.Expect('Format of the member', '[0]');
        Observer.Expect('Value := Format(member)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''0'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('Value := Format(member)|code', 'TestValidation');
        Observer.Expect('Value := Format(member) shows', '[1]/0');
        Observer.Expect('SetValue(space)|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('SetValue(space)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(space) shows', '[1]/0');
        Observer.Expect('SetValue(empty)|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('SetValue(empty)|code', 'Evaluate:Format');
        Observer.Expect('SetValue(empty) shows', '[1]/0');
        Observer.Expect('SetValue(member)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''1'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('SetValue(member)|code', 'TestValidation');
        Observer.Expect('SetValue(member) shows', '[1]/0');
        Observer.Expect('SetValue(0)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''1'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('SetValue(0)|code', 'TestValidation');
        Observer.Expect('SetValue(0) shows', '[1]/0');
        Observer.Verify();
#else
        Observer.Expect('Format of the member', '[0]');
        Observer.Expect('Value := Format(member)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''0'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('Value := Format(member)|code', 'TestValidation');
        Observer.Expect('Value := Format(member) shows', '[1]/0');
        Observer.Expect('SetValue(space)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(space)|code', 'NotSupportedType');
        Observer.Expect('SetValue(space) shows', '[1]/0');
        Observer.Expect('SetValue(empty)|text', 'The type NavOption is unknown.');
        Observer.Expect('SetValue(empty)|code', 'NotSupportedType');
        Observer.Expect('SetValue(empty) shows', '[1]/0');
        Observer.Expect('SetValue(member)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''1'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('SetValue(member)|code', 'TestValidation');
        Observer.Expect('SetValue(member) shows', '[1]/0');
        Observer.Expect('SetValue(0)|text', 'Validation error for Field: Empty Caption,  Message = ''Your entry of ''1'' is not an acceptable value for ''Empty Caption''. (Select Refresh to discard errors)''');
        Observer.Expect('SetValue(0)|code', 'TestValidation');
        Observer.Expect('SetValue(0) shows', '[1]/0');
        Observer.Verify();
#endif
    end;
}
