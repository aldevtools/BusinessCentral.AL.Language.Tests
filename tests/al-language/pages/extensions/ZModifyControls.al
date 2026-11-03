// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 76000, card 76001 (pages/lt-z-page-props/ZFixtures.al); pages 76300-76329, page extensions 76330-76359, codeunits 76360-76362
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles corpus issue 619: properties of a control that a page extension sets in modify(): AssistEdit, BlankZero, CaptionClass, ClosingDates, HideValue,
//   LookupPageId, OptionCaptionML, QuickEntry, ShowCaption, ShowMandatory, Style, Width.
// Facts: what a TestPage reads from the modified control, the trigger that AssistEdit and Lookup fire, the option captions per language.
//   MaskType in modify() compiles but BC refuses to publish the app ("Modifications to property MaskType are not supported"): not pinnable in this app.
//   Properties that a page extension cannot modify (DecimalPlaces, DrillDown, Lookup, ShowFilter, UpdatePropagation) and invalid values are must-not-compile cases.
// BC versions: 29 (27 and 28 by CI)

page 76300 "LT Z Mod Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Plain; Rec.Name) { ApplicationArea = All; }
            field(Zero; Rec.Amount) { ApplicationArea = All; }
            field(ZeroPlain; Rec.Amount) { ApplicationArea = All; }
            field(ZeroOff; Rec.Amount) { ApplicationArea = All; BlankZero = true; }
            field(Cap; Rec.Name) { ApplicationArea = All; Caption = 'Base caption'; }
            field(CapRes; Rec.Name) { ApplicationArea = All; Caption = 'Base caption 2'; }
            field(Dt; Rec.Dt) { ApplicationArea = All; }
            field(DtPlain; Rec.Dt) { ApplicationArea = All; }
            field(Hid; Rec.Name) { ApplicationArea = All; }
            field(Mask; Rec.Name) { ApplicationArea = All; }
            field(Qe; Rec.Name) { ApplicationArea = All; }
            field(Sc; Rec.Name) { ApplicationArea = All; Caption = 'Show caption'; }
            field(Mand; Rec.Name) { ApplicationArea = All; }
            field(Sty1; Rec.Name) { ApplicationArea = All; }
            field(Wid; Rec.Name) { ApplicationArea = All; }
            field(Edm; Rec.Name) { ApplicationArea = All; }
            field(Opt; Rec.Opt) { ApplicationArea = All; }
            field(OptPlain; Rec.Opt) { ApplicationArea = All; }
        }
    }
}

page 76301 "LT Z Lookup Target"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 76330 "LT Z Mod Ext" extends "LT Z Mod Base"
{
    layout
    {
        modify(Name)
        {
            AssistEdit = true;

            trigger OnAssistEdit()
            var
                Log: Codeunit "LT Z Mod Log";
            begin
                Log.Add('assist');
            end;
        }
        modify(Zero) { BlankZero = true; }
        modify(ZeroOff) { BlankZero = false; }
        modify(Cap) { CaptionClass = '3,Class caption'; }
        modify(CapRes) { CaptionClass = 'LTZ,resolve me'; }
        modify(Dt) { ClosingDates = true; }
        modify(Hid) { HideValue = HideNow; }
        modify(Qe) { QuickEntry = false; }
        modify(Edm) { ODataEDMType = 'LTZ.TYPE'; }
        modify(Sc) { ShowCaption = false; }
        modify(Mand) { ShowMandatory = true; }
        modify(Sty1) { Style = Attention; StyleExpr = true; }
        modify(Wid) { Width = 10; }
        modify(Opt) { OptionCaptionML = ENU = 'One,Two,Three', DEU = 'Eins,Zwei,Drei'; }
    }

    var
        HideNow: Boolean;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Z Mod Log";
    begin
        HideNow := Log.GetHide();
    end;
}

// Writer BP (corpus issue 664, microsoft/AL issue 5261): CaptionClass set in modify() to the result of a procedure call of the page
// extension, once with area 3 (plain text) and once with the area LTZ that "LT Z Caption Resolver" resolves.
pageextension 82551 "LT BP Z Cap Ext" extends "LT Z Mod Base"
{
    layout
    {
        modify(Mask) { CaptionClass = BpCaptionClass(Rec.FieldNo(Name)); }
        modify(DtPlain) { CaptionClass = BpResolvedClass(); }
    }

    local procedure BpCaptionClass(FieldNumber: Integer): Text
    begin
        exit('3,From procedure ' + Format(FieldNumber));
    end;

    local procedure BpResolvedClass(): Text
    begin
        exit('LTZ,' + 'from procedure');
    end;
}
codeunit 76362 "LT Z Mod Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        HideNow: Boolean;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetHide(NewValue: Boolean)
    begin
        HideNow := NewValue;
    end;

    procedure GetHide(): Boolean
    begin
        exit(HideNow);
    end;
}

codeunit 76361 "LT Z Caption Resolver"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea <> 'LTZ' then
            exit;
        Caption := 'resolved:' + CaptionExpr;
        Resolved := true;
    end;
}

page 76302 "LT Z Lk Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Plain; Rec.Name) { ApplicationArea = All; }
        }
    }
}

pageextension 76331 "LT Z Lk Ext" extends "LT Z Lk Base"
{
    layout
    {
        modify(Name) { LookupPageId = "LT Z Lookup Target"; }
    }
}

codeunit 76360 "LT Z Modify Controls Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "LT Z Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Amount := 0;
        R.Opt := R.Opt::B;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryAssist(var P: TestPage "LT Z Mod Base"; Which: Integer)
    begin
        case Which of
            1:
                P.Name.AssistEdit();
            2:
                P.Plain.AssistEdit();
        end;
    end;

    [Test]
    procedure ZAssistEdit_TriggerFires()
    var
        Log: Codeunit "LT Z Mod Log";
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        Log.Take();
        P.OpenEdit();
        ClearLastError();
        Observer.Observe('assist modified ok', Format(TryAssist(P, 1)));
        Observer.ObserveError('assist modified');
        Observer.Observe('log', Log.Take());
        Observer.Observe('assist plain ok', Format(TryAssist(P, 2)));
        Observer.ObserveError('assist plain');
        Observer.Observe('log after plain', Log.Take());
        P.Close();
        Observer.Expect('assist modified ok', 'Yes');
        Observer.Expect('assist modified|text', '');
        Observer.Expect('assist modified|code', '');
        Observer.Expect('log', 'assist;');
        Observer.Expect('assist plain ok', 'No');
        Observer.Expect('assist plain|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('assist plain|code', 'MethodNotSupported');
        Observer.Expect('log after plain', '');
        Observer.Verify();
    end;

    [Test]
    procedure ZBlankZero_TestPageText()
    var
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('zero (ext true)', P.Zero.Value());
        Observer.Observe('zero plain', P.ZeroPlain.Value());
        Observer.Observe('zero off (base true, ext false)', P.ZeroOff.Value());
        P.Close();
        Observer.Expect('zero (ext true)', '');
        Observer.Expect('zero plain', '0.00');
        Observer.Expect('zero off (base true, ext false)', '0.00');
        Observer.Verify();
    end;

    [Test]
    procedure ZCaptionClass_LiteralAndResolved()
    var
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('literal', P.Cap.Caption());
        Observer.Observe('resolved', P.CapRes.Caption());
        Observer.Observe('plain caption', P.Plain.Caption());
        P.Close();
        Observer.Expect('literal', 'Class caption');
        Observer.Expect('resolved', 'resolved:resolve me');
        Observer.Expect('plain caption', 'Name');
        Observer.Verify();
    end;

    [Test]
    procedure ZClosingDates_ValueAndStored()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        R.Get(1);
        R.Dt := ClosingDate(20250101D);
        R.Modify();
        P.OpenEdit();
        Observer.Observe('closing date shown', P.Dt.Value());
        Observer.Observe('closing date plain shown', P.DtPlain.Value());
        P.Close();
        R.Get(1);
        Observer.Observe('stored', Format(R.Dt));
        Observer.Observe('stored is closing date', Format(R.Dt = ClosingDate(20250101D)));
        Observer.Observe('stored normal date', Format(NormalDate(R.Dt), 0, 9));
        Observer.Expect('closing date shown', 'C1/1/2025');
        Observer.Expect('closing date plain shown', '1/1/2025');
        Observer.Expect('stored', 'C01/01/25');
        Observer.Expect('stored is closing date', 'Yes');
        Observer.Expect('stored normal date', '2025-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure ZHideValue_TrueAndFalse()
    var
        Log: Codeunit "LT Z Mod Log";
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        Log.SetHide(false);
        P.OpenEdit();
        Observer.Observe('hide false', P.Hid.Value());
        P.Close();
        Log.SetHide(true);
        P.OpenEdit();
        Observer.Observe('hide true', P.Hid.Value());
        Observer.Observe('plain while hide true', P.Plain.Value());
        P.Close();
        Log.SetHide(false);
        Observer.Expect('hide false', 'One');
        Observer.Expect('hide true', '');
        Observer.Expect('plain while hide true', 'One');
        Observer.Verify();
    end;

    [Test]
    procedure ZOptionCaptionML_PerLanguage()
    var
        P: TestPage "LT Z Mod Base";
        Language: Integer;
        Old: Integer;
        i: Integer;
    begin
        Seed();
        Old := GlobalLanguage();
        foreach Language in LanguageList() do begin
            GlobalLanguage(Language);
            P.OpenEdit();
            Observer.Observe(Format(Language) + ' value', P.Opt.Value());
            Observer.Observe(Format(Language) + ' count', Format(P.Opt.OptionCount()));
            for i := 1 to P.Opt.OptionCount() do
                Observer.Observe(Format(Language) + ' option ' + Format(i), P.Opt.GetOption(i));
            Observer.Observe(Format(Language) + ' plain value', P.OptPlain.Value());
            P.Close();
        end;
        GlobalLanguage(Old);
        Observer.Expect('1033 value', 'Two');
        Observer.Expect('1033 count', '3');
        Observer.Expect('1033 option 1', 'One');
        Observer.Expect('1033 option 2', 'Two');
        Observer.Expect('1033 option 3', 'Three');
        Observer.Expect('1033 plain value', 'Beta');
        Observer.Expect('1031 value', 'Zwei');
        Observer.Expect('1031 count', '3');
        Observer.Expect('1031 option 1', 'Eins');
        Observer.Expect('1031 option 2', 'Zwei');
        Observer.Expect('1031 option 3', 'Drei');
        Observer.Expect('1031 plain value', 'Beta');
        Observer.Expect('1036 value', 'Two');
        Observer.Expect('1036 count', '3');
        Observer.Expect('1036 option 1', 'One');
        Observer.Expect('1036 option 2', 'Two');
        Observer.Expect('1036 option 3', 'Three');
        Observer.Expect('1036 plain value', 'Beta');
        Observer.Verify();
    end;

    local procedure LanguageList() Result: List of [Integer]
    begin
        Result.Add(1033);
        Result.Add(1031);
        Result.Add(1036);
    end;

    [Test]
    procedure ZPresentationControls_Read()
    var
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('qe value', P.Qe.Value());
        Observer.Observe('qe visible', Format(P.Qe.Visible()));
        Observer.Observe('qe editable', Format(P.Qe.Editable()));
        Observer.Observe('sc caption', P.Sc.Caption());
        Observer.Observe('sc visible', Format(P.Sc.Visible()));
        Observer.Observe('sty value', P.Sty1.Value());
        Observer.Observe('sty visible', Format(P.Sty1.Visible()));
        Observer.Observe('wid value', P.Wid.Value());
        Observer.Observe('wid visible', Format(P.Wid.Visible()));
        Observer.Observe('edm value', P.Edm.Value());
        Observer.Observe('edm visible', Format(P.Edm.Visible()));
        P.Close();
        Observer.Expect('qe value', 'One');
        Observer.Expect('qe visible', 'Yes');
        Observer.Expect('qe editable', 'Yes');
        Observer.Expect('sc caption', 'Show caption');
        Observer.Expect('sc visible', 'Yes');
        Observer.Expect('sty value', 'One');
        Observer.Expect('sty visible', 'Yes');
        Observer.Expect('wid value', 'One');
        Observer.Expect('wid visible', 'Yes');
        Observer.Expect('edm value', 'One');
        Observer.Expect('edm visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ZShowMandatory_NotEnforced()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('mand before', P.Mand.Value());
        P.Mand.SetValue('');
        Observer.Observe('mand after empty', P.Mand.Value());
        P.Close();
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('mand before', 'One');
        Observer.Expect('mand after empty', '');
        Observer.Expect('stored name', '');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664): CaptionClass in modify() whose value is a procedure call of the page extension.
    [Test]
    procedure ZBP_CaptionClass_ProcedureCallInModify()
    var
        P: TestPage "LT Z Mod Base";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('area 3', P.Mask.Caption());
        Observer.Observe('resolved', P.DtPlain.Caption());
        P.Close();
        Observer.Expect('area 3', 'From procedure 2');
        Observer.Expect('resolved', 'resolved:from procedure');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryLookup(var P: TestPage "LT Z Lk Base"; Which: Integer)
    begin
        case Which of
            1:
                P.Name.Lookup();
            2:
                P.Plain.Lookup();
        end;
    end;

    [Test]
    procedure ZLookupPageId_OpensTargetPage()
    var
        P: TestPage "LT Z Lk Base";
    begin
        Seed();
        InsertSecond();
        P.OpenEdit();
        ClearLastError();
        Observer.Observe('lookup ok', Format(TryLookup(P, 1)));
        Observer.ObserveError('lookup');
        Observer.Observe('name after lookup', P.Name.Value());
        P.Close();
        Observer.Expect('lookup ok', 'Yes');
        Observer.Expect('lookup|text', '');
        Observer.Expect('lookup|code', '');
        Observer.Expect('name after lookup', 'One');
        Observer.Verify();
    end;

    [Test]
    procedure ZLookupPageId_PlainControlHasNoLookup()
    var
        P: TestPage "LT Z Lk Base";
    begin
        Seed();
        P.OpenEdit();
        ClearLastError();
        Observer.Observe('plain lookup ok', Format(TryLookup(P, 2)));
        Observer.ObserveError('plain lookup');
        P.Close();
        Observer.Expect('plain lookup ok', 'Yes');
        Observer.Expect('plain lookup|text', '');
        Observer.Expect('plain lookup|code', '');
        Observer.Verify();
    end;

    local procedure InsertSecond()
    var
        R: Record "LT Z Row";
    begin
        R.Id := 2;
        R.Name := 'Two';
        R.Insert();
    end;
}
