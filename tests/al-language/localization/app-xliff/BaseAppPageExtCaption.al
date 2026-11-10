// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); page extension 62440 of Base Application's "Payment Methods" (modifies two control captions, adds
//   three controls), page extension 62441 of Base Application's Territories (adds one action and touches no control); Base Application's
//   "Countries/Regions", which no corpus app extends; translation units in Translations/AL Language Coverage Tests.nl-NL.xlf; test codeunit 62449.
// local object: the page extensions are the thing under test (standing rule 2)
// Probe: al-runner issue 7327 (Business Central keeps the Base Application caption of a control of a page an app extends under another
//   language, while the app ships a translation file).
// Area: TestPage control Caption() of a Base Application page this app extends, under GlobalLanguage 1043 (the app ships an nl-NL file) and 1033.
//   Controls: a field control the extension does not touch (caption from the Base Application table field), a control whose Caption the
//   extension modifies with a unit in the file (unit kind Change), a control whose Caption it modifies without a unit, a control the extension
//   adds with a Caption and a unit (unit kind Control), one it adds with a Caption and no unit, one it adds without a Caption (caption from the
//   table field); the controls of a page whose extension adds only an action (the shape of the issue); the controls of a page no app extends.
//   The error text of a SetValue the control cannot take (it names the caption), for the untouched, the modified and the added controls.
//   A value typed into a control of the extended page (the third test of the issue).
// Neighbours (not repeated here): lt-r7144-ext-caption/R7187PageCaption.al (the app's OWN page: a control with a unit, a field control, the
//   SetValue error), lt-r7144-ext-caption/R7184BaseAppCaption.al (FieldCaption of a Base Application TABLE the app extends).
// The corpus ships only an nl-NL file, so the other language is Dutch (the issue used Danish).
// Observe form: every test ends with Finish(), which reports the observed values.
// BC versions: 27, 28, 29 (corpus CI)

pageextension 62440 "LPX Payment Methods Ext" extends "Payment Methods"
{
    layout
    {
        modify("Bal. Account Type")
        {
            Caption = 'LPX Type Modified';
        }
        modify("Bal. Account No.")
        {
            Caption = 'LPX No Modified';
        }
        addafter(Description)
        {
            field(LpxAddedWithUnit; Rec."Direct Debit")
            {
                ApplicationArea = All;
                Caption = 'LPX Added';
            }
            field(LpxAddedNoUnit; Rec."Direct Debit")
            {
                ApplicationArea = All;
                Caption = 'LPX Added No Unit';
            }
            field(LpxAddedPlain; Rec."Direct Debit")
            {
                ApplicationArea = All;
            }
        }
    }
}

// The shape of al-runner issue 7327: the extension adds one action and touches no control. The file holds a unit for the action only.
pageextension 62441 "LPX Territories Ext" extends Territories
{
    actions
    {
        addlast(processing)
        {
            action(LpxCount)
            {
                ApplicationArea = All;
                Caption = 'LPX count';
                ToolTip = 'Counts the territories.';

                trigger OnAction()
                var
                    Territory: Record Territory;
                begin
                    LpxCountKept := Territory.Count();
                end;
            }
        }
    }

    var
        LpxCountKept: Integer;
}

codeunit 62449 "LPX Base Page Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ArrangeRows()
    var
        PaymentMethod: Record "Payment Method";
        Territory: Record Territory;
        CountryRegion: Record "Country/Region";
    begin
        if not PaymentMethod.Get('LPX') then begin
            PaymentMethod.Init();
            PaymentMethod.Code := 'LPX';
            PaymentMethod.Description := 'LPX method';
            PaymentMethod.Insert();
        end;
        if not Territory.Get('LPX') then begin
            Territory.Init();
            Territory.Code := 'LPX';
            Territory.Name := 'LPX territory';
            Territory.Insert();
        end;
        if not CountryRegion.Get('LX') then begin
            CountryRegion.Init();
            CountryRegion.Code := 'LX';
            CountryRegion.Name := 'LPX land';
            CountryRegion.Insert();
        end;
        ClearLastError();
    end;

    local procedure ObservePaymentMethodsCaptions(var Observer: Codeunit "Probe Observer"; LanguageId: Integer)
    var
        PaymentMethods: TestPage "Payment Methods";
        Saved: Integer;
    begin
        ArrangeRows();
        Saved := GlobalLanguage();
        GlobalLanguage(LanguageId);
        PaymentMethods.OpenView();
        Observer.Observe('Code (not touched)', PaymentMethods.Code.Caption());
        Observer.Observe('Description (not touched)', PaymentMethods.Description.Caption());
        Observer.Observe('Direct Debit (not touched)', PaymentMethods."Direct Debit".Caption());
        Observer.Observe('Bal. Account Type (modify, unit)', PaymentMethods."Bal. Account Type".Caption());
        Observer.Observe('Bal. Account No. (modify, no unit)', PaymentMethods."Bal. Account No.".Caption());
        Observer.Observe('added control with a Caption and a unit', PaymentMethods.LpxAddedWithUnit.Caption());
        Observer.Observe('added control with a Caption and no unit', PaymentMethods.LpxAddedNoUnit.Caption());
        Observer.Observe('added control without a Caption', PaymentMethods.LpxAddedPlain.Caption());
        PaymentMethods.Close();
        GlobalLanguage(Saved);
    end;

    local procedure ObserveOtherPagesCaptions(var Observer: Codeunit "Probe Observer"; LanguageId: Integer)
    var
        Territories: TestPage Territories;
        CountriesRegions: TestPage "Countries/Regions";
        Saved: Integer;
    begin
        ArrangeRows();
        Saved := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Territories.OpenView();
        Observer.Observe('Territories Code (extension adds an action only)', Territories.Code.Caption());
        Observer.Observe('Territories Name (extension adds an action only)', Territories.Name.Caption());
        Territories.Close();
        CountriesRegions.OpenView();
        Observer.Observe('Countries/Regions Code (page not extended)', CountriesRegions.Code.Caption());
        Observer.Observe('Countries/Regions Name (page not extended)', CountriesRegions.Name.Caption());
        CountriesRegions.Close();
        GlobalLanguage(Saved);
    end;

    // Which is 1 the untouched Boolean control, 2 the modified control with a unit, 3 the modified control without a unit, 4 the added
    // control with a unit, 5 the added control without a unit, 6 the added control without a Caption.
    [TryFunction]
    local procedure TrySetPaymentMethods(var PaymentMethods: TestPage "Payment Methods"; Which: Integer)
    begin
        case Which of
            1:
                PaymentMethods."Direct Debit".SetValue('abc');
            2:
                PaymentMethods."Bal. Account Type".SetValue('abc');
            3:
                PaymentMethods."Bal. Account No.".SetValue('abc');
            4:
                PaymentMethods.LpxAddedWithUnit.SetValue('abc');
            5:
                PaymentMethods.LpxAddedNoUnit.SetValue('abc');
            6:
                PaymentMethods.LpxAddedPlain.SetValue('abc');
        end;
    end;

    [TryFunction]
    local procedure TryClosePaymentMethods(var PaymentMethods: TestPage "Payment Methods")
    begin
        PaymentMethods.Close();
    end;

    local procedure SetValueError(Which: Integer; LanguageId: Integer): Text
    var
        PaymentMethodRow: Record "Payment Method";
        PaymentMethods: TestPage "Payment Methods";
        Saved: Integer;
        Got: Text;
    begin
        ArrangeRows();
        PaymentMethodRow.Get('LPX');
        Saved := GlobalLanguage();
        GlobalLanguage(LanguageId);
        PaymentMethods.OpenEdit();
        PaymentMethods.GoToRecord(PaymentMethodRow);
        if TrySetPaymentMethods(PaymentMethods, Which) then
            Got := 'no error'
        else
            Got := GetLastErrorText() + ' {' + GetLastErrorCode() + '}';
        ClearLastError();
        if not TryClosePaymentMethods(PaymentMethods) then
            Got += ' close: ' + GetLastErrorText();
        ClearLastError();
        GlobalLanguage(Saved);
        exit(Got);
    end;

    [Test]
    procedure LPX_ExtendedPage_ControlCaptions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePaymentMethodsCaptions(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ExtendedPage_ControlCaptions_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePaymentMethodsCaptions(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ActionOnlyExtensionAndPlainPage_ControlCaptions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOtherPagesCaptions(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ActionOnlyExtensionAndPlainPage_ControlCaptions_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOtherPagesCaptions(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ExtendedPage_SetValueError_UntouchedAndModified_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('untouched Boolean control', SetValueError(1, 1043));
        Observer.Observe('modified control with a unit', SetValueError(2, 1043));
        Observer.Observe('modified control without a unit', SetValueError(3, 1043));
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ExtendedPage_SetValueError_AddedControls_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('added control with a unit', SetValueError(4, 1043));
        Observer.Observe('added control without a unit', SetValueError(5, 1043));
        Observer.Observe('added control without a Caption', SetValueError(6, 1043));
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ExtendedPage_SetValueError_UntouchedAndModified_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('untouched Boolean control', SetValueError(1, 1033));
        Observer.Observe('modified control with a unit', SetValueError(2, 1033));
        Observer.Observe('modified control without a unit', SetValueError(3, 1033));
        Observer.Finish();
    end;

    [Test]
    procedure LPX_ExtendedPage_SetValueError_AddedControls_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('added control with a unit', SetValueError(4, 1033));
        Observer.Observe('added control without a unit', SetValueError(5, 1033));
        Observer.Observe('added control without a Caption', SetValueError(6, 1033));
        Observer.Finish();
    end;

    // The third test of al-runner issue 7327: a value typed into a control of the extended page in a Dutch session.
    [Test]
    procedure LPX_ActionOnlyExtension_SetValue_Dutch_TakesTheValue()
    var
        Observer: Codeunit "Probe Observer";
        Territory: Record Territory;
        Territories: TestPage Territories;
        Saved: Integer;
        Got: Text;
    begin
        ArrangeRows();
        Territory.Get('LPX');
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Territories.OpenEdit();
        Territories.GoToRecord(Territory);
        Territories.Name.SetValue('LPX gebied');
        Got := Territories.Name.Value();
        Territories.Close();
        GlobalLanguage(Saved);
        Observer.Observe('value the control took', Got);
        Territory.Get('LPX');
        Observer.Observe('stored name', Territory.Name);
        Observer.Finish();
    end;
}
