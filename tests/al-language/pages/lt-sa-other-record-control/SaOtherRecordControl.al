// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT SA OR *); System tables Currency and General Ledger Setup
// Probe (al-runner issue 5822): a page control bound to a field of a GLOBAL record variable of the page (a database record and a temporary
//   one), in a header group and in a repeater, next to the same field bound through Rec on a Card: the Value text of an Option field with
//   OptionCaption (blank first member, every member, no row), an Enum, a Boolean, a Date with ClosingDates, Decimal fields with DecimalPlaces,
//   AutoFormatType 1/2 with AutoFormatExpression = Rec."Currency Code", AutoFormatType 10, BlankZero, BlankNumbers; Caption() of such a
//   control with and without a Caption of its own; Editable() and Visible(); SetValue on the Option control.
// Object ids 88940-88946. BC versions: 27, 28, 29 (CI matrix)

table 88940 "LT SA OR Settings"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Avail. Filter"; Option)
        {
            OptionCaption = 'All,Blank,All available,Some available,None available';
            OptionMembers = " ",Blank,All,Some,"None";
        }
        field(3; Kind; Enum "LT SA OR Kind") { }
        field(4; Dec22; Decimal) { DecimalPlaces = 2 : 2; }
        field(5; Dec05; Decimal) { DecimalPlaces = 0 : 5; }
        field(6; "Currency Code"; Code[10]) { }
        field(7; Amt1; Decimal) { AutoFormatType = 1; AutoFormatExpression = Rec."Currency Code"; }
        field(8; Amt2; Decimal) { AutoFormatType = 2; AutoFormatExpression = Rec."Currency Code"; }
        field(9; Amt10; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,3:3><Standard Format,0>'; }
        field(10; BZ; Decimal) { BlankZero = true; }
        field(11; BZInt; Integer) { BlankZero = true; }
        field(12; BNeg; Decimal) { BlankNumbers = BlankNeg; }
        field(13; CDate; Date) { ClosingDates = true; }
        field(14; Flag; Boolean) { }
        field(15; Locked; Text[20]) { Editable = false; }
        field(16; Captioned; Text[20]) { Caption = 'Field Caption Of Captioned'; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

enum 88941 "LT SA OR Kind"
{
    Extensible = false;

    value(0; " ") { Caption = 'Nothing'; }
    value(1; First) { Caption = 'First Kind'; }
    value(2; Second) { }
}

table 88942 "LT SA OR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 88943 "LT SA OR Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT SA OR Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(GOpt; Settings."Avail. Filter") { Caption = 'Material Availability'; }
                field(GOptText; Format(Settings."Avail. Filter")) { }
                field(GKind; Settings.Kind) { }
                field(GDec22; Settings.Dec22) { }
                field(GDec05; Settings.Dec05) { }
                field(GAmt1; Settings.Amt1) { }
                field(GAmt2; Settings.Amt2) { }
                field(GAmt10; Settings.Amt10) { }
                field(GBZ; Settings.BZ) { }
                field(GBZInt; Settings.BZInt) { }
                field(GBNeg; Settings.BNeg) { }
                field(GCDate; Settings.CDate) { }
                field(GFlag; Settings.Flag) { }
                field(GLocked; Settings.Locked) { }
                field(GCaptioned; Settings.Captioned) { }
                field(GOwnCaption; Settings.Captioned) { Caption = 'Own Caption'; }
                field(GNotEditable; Settings.Dec22) { Editable = false; }
                field(GHidden; Settings.Flag) { Visible = false; }
                field(GVisExpr; Settings.Flag) { Visible = ShowIt; }
            }
            group(TempFilters)
            {
                field(TOpt; TempSettings."Avail. Filter") { }
                field(TKind; TempSettings.Kind) { }
                field(TDec22; TempSettings.Dec22) { }
                field(TDec05; TempSettings.Dec05) { }
                field(TAmt1; TempSettings.Amt1) { }
                field(TAmt2; TempSettings.Amt2) { }
                field(TAmt10; TempSettings.Amt10) { }
                field(TBZ; TempSettings.BZ) { }
                field(TBZInt; TempSettings.BZInt) { }
                field(TBNeg; TempSettings.BNeg) { }
                field(TCDate; TempSettings.CDate) { }
                field(TLocked; TempSettings.Locked) { }
                field(TCaptioned; TempSettings.Captioned) { }
            }
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field(ROpt; Settings."Avail. Filter") { }
                field(RDec22; Settings.Dec22) { }
                field(RAmt2; Settings.Amt2) { }
                field(RLocked; Settings.Locked) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Settings.Get('') then
            Settings.Init();
        TempSettings := Settings;
        TempSettings.Insert();
        ShowIt := Settings.Flag;
    end;

    var
        Settings: Record "LT SA OR Settings";
        TempSettings: Record "LT SA OR Settings" temporary;
        ShowIt: Boolean;
}

page 88944 "LT SA OR Settings Card"
{
    PageType = Card;
    SourceTable = "LT SA OR Settings";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(COpt; Rec."Avail. Filter") { }
            field(CKind; Rec.Kind) { }
            field(CDec22; Rec.Dec22) { }
            field(CDec05; Rec.Dec05) { }
            field(CAmt1; Rec.Amt1) { }
            field(CAmt2; Rec.Amt2) { }
            field(CAmt10; Rec.Amt10) { }
            field(CBZ; Rec.BZ) { }
            field(CBZInt; Rec.BZInt) { }
            field(CBNeg; Rec.BNeg) { }
            field(CCDate; Rec.CDate) { }
            field(CLocked; Rec.Locked) { }
            field(CCaptioned; Rec.Captioned) { }
        }
    }
}

codeunit 88945 "LT SA OR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SavedAmountPlaces: Text;
        SavedUnitPlaces: Text;
        SavedShowCurrency: Enum "Show Currency";

    local procedure SetSetup()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        SavedAmountPlaces := GLSetup."Amount Decimal Places";
        SavedUnitPlaces := GLSetup."Unit-Amount Decimal Places";
        SavedShowCurrency := GLSetup."Show Currency";
        GLSetup."Amount Decimal Places" := '1:3';
        GLSetup."Unit-Amount Decimal Places" := '2:5';
        GLSetup."Show Currency" := "Show Currency"::Never;
        GLSetup.Modify();
        if Currency.Get('SAC') then
            Currency.Delete();
        Currency.Init();
        Currency.Code := 'SAC';
        Currency."Amount Decimal Places" := '3:3';
        Currency."Unit-Amount Decimal Places" := '4:4';
        Currency.Insert();
        if Currency.Get('SANONE') then
            Currency.Delete();
    end;

    // The BC 27.5 test runner commits what a test leaves (autoformat/PWAutoFormatTypes.al RestoreSetup), so every test puts the setup back.
    local procedure RestoreSetup()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if Currency.Get('SAC') then
            Currency.Delete();
        if not GLSetup.Get() then
            exit;
        GLSetup."Amount Decimal Places" := CopyStr(SavedAmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(SavedUnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := SavedShowCurrency;
        GLSetup.Modify();
    end;

    local procedure Seed(var Settings: Record "LT SA OR Settings")
    var
        Line: Record "LT SA OR Line";
    begin
        Settings.DeleteAll();
        Line.DeleteAll();
        Line."Entry No." := 1;
        Line.Insert();
        Line."Entry No." := 2;
        Line.Insert();
        Settings.Init();
        Settings.Code := '';
    end;

    local procedure ObserveOption(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
        Card: TestPage "LT SA OR Settings Card";
    begin
        Worksheet.OpenView();
        Observer.Observe(Tag + '-G', Worksheet.GOpt.Value());
        Observer.Observe(Tag + '-GText', Worksheet.GOptText.Value());
        Observer.Observe(Tag + '-T', Worksheet.TOpt.Value());
        Worksheet.First();
        Observer.Observe(Tag + '-R1', Worksheet.ROpt.Value());
        Worksheet.Next();
        Observer.Observe(Tag + '-R2', Worksheet.ROpt.Value());
        Worksheet.Close();
        if Settings.Get('') then begin
            Card.OpenView();
            Card.GoToRecord(Settings);
            Observer.Observe(Tag + '-C', Card.COpt.Value());
            Card.Close();
        end;
    end;

    // The reporter's shapes: no row (Init in OnOpenPage) and a row holding each member in turn.
    [Test]
    procedure SA_Option_EveryMember()
    var
        Observer: Codeunit "Probe Observer";
        Settings: Record "LT SA OR Settings";
        Member: Integer;
    begin
        Seed(Settings);
        ObserveOption(Observer, 'norow');
        for Member := 0 to 4 do begin
            Seed(Settings);
            Settings."Avail. Filter" := Member;
            Settings.Insert();
            ObserveOption(Observer, Format(Member));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure SA_Enum_Bool_Date_Text()
    var
        Observer: Codeunit "Probe Observer";
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
        Card: TestPage "LT SA OR Settings Card";
        Pass: Integer;
    begin
        for Pass := 0 to 2 do begin
            Seed(Settings);
            Settings.Kind := "LT SA OR Kind".FromInteger(Pass);
            Settings.Flag := Pass = 1;
            case Pass of
                0:
                    Settings.CDate := 0D;
                1:
                    Settings.CDate := 20260131D;
                2:
                    Settings.CDate := ClosingDate(20260131D);
            end;
            Settings.Locked := 'L' + Format(Pass);
            Settings.Captioned := 'C' + Format(Pass);
            Settings.Insert();
            Worksheet.OpenView();
            Observer.Observe(Format(Pass) + '-GKind', Worksheet.GKind.Value());
            Observer.Observe(Format(Pass) + '-TKind', Worksheet.TKind.Value());
            Observer.Observe(Format(Pass) + '-GFlag', Worksheet.GFlag.Value());
            Observer.Observe(Format(Pass) + '-GCDate', Worksheet.GCDate.Value());
            Observer.Observe(Format(Pass) + '-TCDate', Worksheet.TCDate.Value());
            Observer.Observe(Format(Pass) + '-GLocked', Worksheet.GLocked.Value());
            Observer.Observe(Format(Pass) + '-TCaptioned', Worksheet.TCaptioned.Value());
            Worksheet.First();
            Observer.Observe(Format(Pass) + '-RLocked', Worksheet.RLocked.Value());
            Worksheet.Close();
            Card.OpenView();
            Card.GoToRecord(Settings);
            Observer.Observe(Format(Pass) + '-CKind', Card.CKind.Value());
            Observer.Observe(Format(Pass) + '-CCDate', Card.CCDate.Value());
            Card.Close();
        end;
        Observer.Finish();
    end;

    local procedure ObserveDecimals(var Observer: Codeunit "Probe Observer"; Tag: Text; CurrencyCode: Code[10]; Value: Decimal)
    var
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
        Card: TestPage "LT SA OR Settings Card";
    begin
        Seed(Settings);
        Settings."Currency Code" := CurrencyCode;
        Settings.Dec22 := Value;
        Settings.Dec05 := Value;
        Settings.Amt1 := Value;
        Settings.Amt2 := Value;
        Settings.Amt10 := Value;
        Settings.BZ := Value;
        Settings.BZInt := Round(Value, 1);
        Settings.BNeg := Value;
        Settings.Insert();
        Worksheet.OpenView();
        Observer.Observe(Tag + 'G22', Worksheet.GDec22.Value());
        Observer.Observe(Tag + 'G05', Worksheet.GDec05.Value());
        Observer.Observe(Tag + 'GA1', Worksheet.GAmt1.Value());
        Observer.Observe(Tag + 'GA2', Worksheet.GAmt2.Value());
        Observer.Observe(Tag + 'GA10', Worksheet.GAmt10.Value());
        Observer.Observe(Tag + 'GBZ', Worksheet.GBZ.Value());
        Observer.Observe(Tag + 'GBZI', Worksheet.GBZInt.Value());
        Observer.Observe(Tag + 'GBN', Worksheet.GBNeg.Value());
        Observer.Observe(Tag + 'T22', Worksheet.TDec22.Value());
        Observer.Observe(Tag + 'T05', Worksheet.TDec05.Value());
        Observer.Observe(Tag + 'TA1', Worksheet.TAmt1.Value());
        Observer.Observe(Tag + 'TA2', Worksheet.TAmt2.Value());
        Observer.Observe(Tag + 'TA10', Worksheet.TAmt10.Value());
        Observer.Observe(Tag + 'TBZ', Worksheet.TBZ.Value());
        Observer.Observe(Tag + 'TBZI', Worksheet.TBZInt.Value());
        Observer.Observe(Tag + 'TBN', Worksheet.TBNeg.Value());
        Worksheet.First();
        Observer.Observe(Tag + 'R22', Worksheet.RDec22.Value());
        Observer.Observe(Tag + 'RA2', Worksheet.RAmt2.Value());
        Worksheet.Close();
        Card.OpenView();
        Card.GoToRecord(Settings);
        Observer.Observe(Tag + 'C22', Card.CDec22.Value());
        Observer.Observe(Tag + 'C05', Card.CDec05.Value());
        Observer.Observe(Tag + 'CA1', Card.CAmt1.Value());
        Observer.Observe(Tag + 'CA2', Card.CAmt2.Value());
        Observer.Observe(Tag + 'CA10', Card.CAmt10.Value());
        Observer.Observe(Tag + 'CBZ', Card.CBZ.Value());
        Observer.Observe(Tag + 'CBZI', Card.CBZInt.Value());
        Observer.Observe(Tag + 'CBN', Card.CBNeg.Value());
        Card.Close();
    end;

    // G/L Setup places 1:3 (amount) and 2:5 (unit amount); currency SAC 3:3 and 4:4; SANONE is no currency.
    [Test]
    procedure SA_Decimal_BlankCurrency()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup();
        ObserveDecimals(Observer, 'a', '', 1234.5);
        ObserveDecimals(Observer, 'b', '', -3.14159);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_Decimal_Currency()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup();
        ObserveDecimals(Observer, 'a', 'SAC', 1234.5);
        ObserveDecimals(Observer, 'b', 'SAC', -3.14159);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_Decimal_NoCurrencyRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup();
        ObserveDecimals(Observer, 'a', 'SANONE', 1234.5);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_Decimal_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup();
        ObserveDecimals(Observer, 'z', 'SAC', 0);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_Caption()
    var
        Observer: Codeunit "Probe Observer";
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
        Card: TestPage "LT SA OR Settings Card";
    begin
        Seed(Settings);
        Settings.Insert();
        Worksheet.OpenView();
        Observer.Observe('GOpt', Worksheet.GOpt.Caption());
        Observer.Observe('GOptText', Worksheet.GOptText.Caption());
        Observer.Observe('GKind', Worksheet.GKind.Caption());
        Observer.Observe('GDec22', Worksheet.GDec22.Caption());
        Observer.Observe('GCaptioned', Worksheet.GCaptioned.Caption());
        Observer.Observe('GOwnCaption', Worksheet.GOwnCaption.Caption());
        Observer.Observe('TOpt', Worksheet.TOpt.Caption());
        Observer.Observe('TCaptioned', Worksheet.TCaptioned.Caption());
        Observer.Observe('ROpt', Worksheet.ROpt.Caption());
        Worksheet.Close();
        Card.OpenView();
        Observer.Observe('COpt', Card.COpt.Caption());
        Observer.Observe('CCaptioned', Card.CCaptioned.Caption());
        Card.Close();
        Observer.Finish();
    end;

    local procedure ObserveEditable(var Observer: Codeunit "Probe Observer"; Tag: Text; var Worksheet: TestPage "LT SA OR Worksheet")
    begin
        Observer.Observe(Tag + '-GOpt', Format(Worksheet.GOpt.Editable()));
        Observer.Observe(Tag + '-GOptText', Format(Worksheet.GOptText.Editable()));
        Observer.Observe(Tag + '-GDec22', Format(Worksheet.GDec22.Editable()));
        Observer.Observe(Tag + '-GLocked', Format(Worksheet.GLocked.Editable()));
        Observer.Observe(Tag + '-GNotEditable', Format(Worksheet.GNotEditable.Editable()));
        Observer.Observe(Tag + '-TOpt', Format(Worksheet.TOpt.Editable()));
        Observer.Observe(Tag + '-TLocked', Format(Worksheet.TLocked.Editable()));
        Worksheet.First();
        Observer.Observe(Tag + '-ROpt', Format(Worksheet.ROpt.Editable()));
        Observer.Observe(Tag + '-RLocked', Format(Worksheet.RLocked.Editable()));
    end;

    // Commit after seeding: an asserterror rolls back to the last commit, and the row must survive it.
    [Test]
    procedure SA_Editable_Visible()
    var
        Observer: Codeunit "Probe Observer";
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
        Card: TestPage "LT SA OR Settings Card";
    begin
        Seed(Settings);
        Settings.Insert();
        Commit();
        Worksheet.OpenEdit();
        ObserveEditable(Observer, 'edit', Worksheet);
        Observer.Observe('flagoff-GVisExpr', Format(Worksheet.GVisExpr.Visible()));
        Observer.Observe('flagoff-GFlag', Format(Worksheet.GFlag.Visible()));
        Worksheet.Close();
        Worksheet.OpenView();
        ObserveEditable(Observer, 'view', Worksheet);
        Worksheet.Close();
        Settings.Flag := true;
        Settings.Modify();
        Commit();
        Worksheet.OpenEdit();
        Observer.Observe('flagon-GVisExpr', Format(Worksheet.GVisExpr.Visible()));
        Worksheet.Close();
        Card.OpenEdit();
        Card.GoToRecord(Settings);
        Observer.Observe('edit-CLocked', Format(Card.CLocked.Editable()));
        Observer.Observe('edit-COpt', Format(Card.COpt.Editable()));
        Card.Close();
        // A control with Visible = false (pages/W1Controls.al pins the Rec-bound case).
        Worksheet.OpenEdit();
        asserterror begin
            Observer.Observe('GHidden-visible', Format(Worksheet.GHidden.Visible()));
            Error('LT-NOERROR');
        end;
        Observer.ObserveError('GHidden');
        Worksheet.Close();
        Observer.Finish();
    end;

    local procedure TrySetOption(var Observer: Codeunit "Probe Observer"; var Worksheet: TestPage "LT SA OR Worksheet"; Tag: Text; NewValue: Text)
    begin
        ClearLastError();
        asserterror begin
            Worksheet.GOpt.SetValue(NewValue);
            Error('LT-NOERROR');
        end;
        Observer.ObserveError(Tag + '-err');
        Observer.Observe(Tag + '-G', Worksheet.GOpt.Value());
        Observer.Observe(Tag + '-GText', Worksheet.GOptText.Value());
    end;

    // SetValue on the control bound to the global record: a caption, a member name that is no caption, a member name that is also a
    // caption of another member, an empty text and a text that is neither; then whether the database row changed.
    [Test]
    procedure SA_Option_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Settings: Record "LT SA OR Settings";
        Worksheet: TestPage "LT SA OR Worksheet";
    begin
        Seed(Settings);
        Settings.Insert();
        Commit();
        Worksheet.OpenEdit();
        TrySetOption(Observer, Worksheet, 'caption', 'None available');
        TrySetOption(Observer, Worksheet, 'member', 'Some');
        TrySetOption(Observer, Worksheet, 'both', 'All');
        TrySetOption(Observer, Worksheet, 'empty', '');
        TrySetOption(Observer, Worksheet, 'other', 'Nonsense');
        Worksheet.Close();
        Settings.Get('');
        Observer.Observe('row-after', Format(Settings."Avail. Filter", 0, 2));
        Observer.Finish();
    end;
}
