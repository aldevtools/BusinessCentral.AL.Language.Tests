// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-close-method
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: a card with and without OnQueryClosePage and a table whose Url field validates are what is under test; the log is a SingleInstance codeunit that outlives a test
// Fixtures used: Probe Observer (codeunit 69160); own objects 99740-99744, test codeunit 99744
// Probe (al-runner issue 7345): a card TestPage is left open at the end of a [Test] procedure after a value was set on it. The next [Test]
//   procedures of the same codeunit read the row (the test runner rolls back at the end of the codeunit, not between tests). Cases: OpenEdit,
//   OpenNew on a new key, OpenNew then GoToRecord of an existing row; a valid value, an invalid value (the field's OnValidate raises
//   an error), a valid then an invalid value; with and without OnQueryClosePage; and an explicit Close() as the control. The writer tests
//   record what they saw in the log, the reader tests Observe the rows and the log.
// BC versions: 27, 28, 29

table 99740 "LT SC Setting"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Url; Text[100])
        {
            trigger OnValidate()
            begin
                if Url.StartsWith('bad') then
                    Error('Url must not start with bad.');
            end;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 99741 "LT SC Card"
{
    PageType = Card;
    SourceTable = "LT SC Setting";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Url; Rec.Url) { ApplicationArea = All; }
        }
    }
}

page 99742 "LT SC Card Q"
{
    PageType = Card;
    SourceTable = "LT SC Setting";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Url; Rec.Url) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT SC Log";
    begin
        Log.Add('Q:' + Rec."Code" + ':' + Format(CloseAction) + ':' + Rec.Url);
        exit(true);
    end;
}

codeunit 99743 "LT SC Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 99744 "LT SC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SC Log";

    local procedure Seed(Code: Code[20])
    var
        Setting: Record "LT SC Setting";
    begin
        Setting."Code" := Code;
        Setting.Url := 'old';
        Setting.Insert();
    end;

    local procedure ReadRow(Code: Code[20]): Text
    var
        Setting: Record "LT SC Setting";
    begin
        if not Setting.Get(Code) then
            exit('missing');
        exit(Setting.Url);
    end;

    [TryFunction]
    local procedure TrySetUrl(var P: TestPage "LT SC Card"; Value: Text)
    begin
        P.Url.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetUrlQ(var P: TestPage "LT SC Card Q"; Value: Text)
    begin
        P.Url.SetValue(Value);
    end;

    local procedure Note(Name: Text; Done: Boolean)
    begin
        if Done then
            Log.Add(Name + ':ok')
        else
            Log.Add(Name + ':' + GetLastErrorText());
        ClearLastError();
    end;

    // The card stays open when these tests end.

    [Test]
    procedure Y7345_Write1_EditValid_NoQuery()
    var
        P: TestPage "LT SC Card";
    begin
        Seed('E1');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E1'));
        Note('E1', TrySetUrl(P, 'new1'));
    end;

    [Test]
    procedure Y7345_Read1_NextTestSeesEdit()
    begin
        Observer.Observe('E1 after the test that left the card open', ReadRow('E1'));
        Observer.Finish();
    end;

    [Test]
    procedure Y7345_Write2_EditValid_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        Seed('E2');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E2'));
        Note('E2', TrySetUrlQ(P, 'new2'));
    end;

    [Test]
    procedure Y7345_Write3_EditInvalid_NoQuery()
    var
        P: TestPage "LT SC Card";
    begin
        Seed('E3');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E3'));
        Note('E3', TrySetUrl(P, 'bad3'));
    end;

    [Test]
    procedure Y7345_Write4_EditInvalid_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        Seed('E4');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E4'));
        Note('E4', TrySetUrlQ(P, 'bad4'));
    end;

    [Test]
    procedure Y7345_Write5_EditValidThenInvalid_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        Seed('E5');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E5'));
        Note('E5a', TrySetUrlQ(P, 'new5'));
        Note('E5b', TrySetUrlQ(P, 'bad5'));
    end;

    [Test]
    procedure Y7345_Write6_OpenNewNewKey_NoQuery()
    var
        P: TestPage "LT SC Card";
    begin
        P.OpenNew();
        P."Code".SetValue('N6');
        Note('N6', TrySetUrl(P, 'new6'));
    end;

    [Test]
    procedure Y7345_Write7_OpenNewNewKey_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        P.OpenNew();
        P."Code".SetValue('N7');
        Note('N7', TrySetUrlQ(P, 'new7'));
    end;

    [Test]
    procedure Y7345_Write8_OpenNewGoToExisting_NoQuery()
    var
        P: TestPage "LT SC Card";
    begin
        Seed('E8');
        P.OpenNew();
        P.GoToRecord(GetSetting('E8'));
        Note('E8', TrySetUrl(P, 'new8'));
    end;

    [Test]
    procedure Y7345_Write9_OpenNewGoToExisting_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        Seed('E9');
        P.OpenNew();
        P.GoToRecord(GetSetting('E9'));
        Note('E9', TrySetUrlQ(P, 'new9'));
    end;

    [Test]
    procedure Y7345_Write10_EditValid_ExplicitClose()
    var
        P: TestPage "LT SC Card";
    begin
        Seed('E10');
        P.OpenEdit();
        P.GoToRecord(GetSetting('E10'));
        Note('E10', TrySetUrl(P, 'new10'));
        P.Close();
    end;

    [Test]
    procedure Y7345_Write11_OpenNewNewKeyInvalid_NoQuery()
    var
        P: TestPage "LT SC Card";
    begin
        P.OpenNew();
        P."Code".SetValue('N11');
        Note('N11', TrySetUrl(P, 'bad11'));
    end;

    [Test]
    procedure Y7345_Write12_OpenNewNewKeyInvalid_Query()
    var
        P: TestPage "LT SC Card Q";
    begin
        P.OpenNew();
        P."Code".SetValue('N12');
        Note('N12', TrySetUrlQ(P, 'bad12'));
    end;

    [Test]
    procedure Y7345_Read2_RowsAfterAllCards()
    var
        Name: Text;
    begin
        foreach Name in 'E1,E2,E3,E4,E5,N6,N7,E8,E9,E10,N11,N12'.Split(',') do
            Observer.Observe('row ' + Name, ReadRow(CopyStr(Name, 1, 20)));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    local procedure GetSetting(Code: Code[20]) Setting: Record "LT SC Setting"
    begin
        Setting.Get(Code);
    end;
}
