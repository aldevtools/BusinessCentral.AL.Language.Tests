// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testfield-class
// Scope: in-scope
// Fixtures used: LT P161 Cap Enum (72723), LT P161 Cap Row (72724), LT P161 Cap Card (72725)
//
// A TestPage control bound to an Enum field: SetValue with the caption, with the member name, with the
// ordinal text, for a member that has a Caption and for one that has none (its name is its caption?),
// case variations, and the value read back. Each SetValue that may be refused is wrapped in asserterror.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 72723 "LT P161 Cap Enum"
{
    Extensible = false;

    value(0; Plain) { }
    value(1; Named)
    {
        Caption = 'Shown Caption';
    }
    value(2; "With Space") { }
}

table 72724 "LT P161 Cap Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT P161 Cap Enum") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 72725 "LT P161 Cap Card"
{
    PageType = Card;
    SourceTable = "LT P161 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; }
        }
    }
}

codeunit 72726 "LT P161 Enum Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P161 Cap Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Insert();
    end;

    local procedure SetAndRead(var TP: TestPage "LT P161 Cap Card"; Input: Text): Text
    begin
        TP.Kind.SetValue(Input);
        exit(TP.Kind.Value());
    end;

    [Test]
    procedure P161_EnumControl_SetValueSpellings_Captionless()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P161 Cap Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('plainByName', SetAndRead(TP, 'Plain'));
        Observer.Observe('spaceByName', SetAndRead(TP, 'With Space'));
        Observer.Observe('plainBack', SetAndRead(TP, 'Plain'));
        TP.Kind.SetValue('plain');
        Observer.Observe('plainLower', 'no error');
        asserterror TP.Kind.SetValue('2');
        Observer.ObserveError('spaceOrdinal');
        asserterror TP.Kind.SetValue('Nothing');
        Observer.ObserveError('unknown');
        asserterror TP.Kind.SetValue('');
        Observer.ObserveError('empty');
        Observer.Observe('final', TP.Kind.Value());
        TP.Close();
        Observer.Expect('plainByName', 'Plain');
        Observer.Expect('spaceByName', 'With Space');
        Observer.Expect('plainBack', 'Plain');
        Observer.Expect('plainLower', 'no error');
        Observer.Expect('spaceOrdinal|text', 'Validation error for Field: Kind,  Message = ''Your entry of ''2'' is not an acceptable value for ''Kind''. (Select Refresh to discard errors)''');
        Observer.Expect('spaceOrdinal|code', 'TestValidation');
        Observer.Expect('unknown|text', 'Validation error for Field: Kind,  Message = ''Your entry of ''Nothing'' is not an acceptable value for ''Kind''. (Select Refresh to discard errors)''');
        Observer.Expect('unknown|code', 'TestValidation');
        Observer.Expect('empty|text', 'Validation error for Field: Kind,  Message = ''Your entry of ''0'' is not an acceptable value for ''Kind''. (Select Refresh to discard errors)''');
        Observer.Expect('empty|code', 'TestValidation');
        Observer.Expect('final', '0');
        Observer.Verify();
    end;
}
