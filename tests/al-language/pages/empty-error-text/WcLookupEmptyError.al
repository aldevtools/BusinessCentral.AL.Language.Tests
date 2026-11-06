// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96210 (row), 96211 (lookup values), 96216 (marks), list page 96212, card page 96213,
//   helper codeunit 96215, test codeunit 96214.
// Probe: writer rwcap (al-runner issue 6924, waldo): Error('') raised in an OnLookup that TestPage.<control>.Lookup() starts, after the
//   OnLookup ran a lookup page with LookupMode := true and RunModal and the ModalPageHandler pressed Cancel
//   (`if Page.RunModal() <> Action::LookupOK then Error('')`). The table field's OnLookup and the page control's OnLookup; an OnLookup that
//   raises Error('') without a page; Error('<text>') in the same place under asserterror. Per step: whether the test goes on after
//   Lookup(), GetLastErrorText / GetLastErrorCode, the value the control shows, whether the row the OnLookup wrote before the error stays,
//   and whether a SetValue after the Lookup is saved.
// BC versions: 27, 28, 29

table 96210 "LT WC LkEE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Tab Val"; Code[20])
        {
            trigger OnLookup()
            var
                Helper: Codeunit "LT WC LkEE Helper";
            begin
                "Tab Val" := Helper.LookupFixed(1, false);
            end;
        }
        field(4; "Ctl Val"; Code[20]) { }
        field(5; "Direct Val"; Code[20]) { }
        field(6; "Text Val"; Code[20])
        {
            trigger OnLookup()
            var
                Helper: Codeunit "LT WC LkEE Helper";
            begin
                "Text Val" := Helper.LookupFixed(4, true);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 96211 "LT WC LkEE Value"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 96216 "LT WC LkEE Mark"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 96212 "LT WC LkEE Values"
{
    PageType = List;
    SourceTable = "LT WC LkEE Value";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            }
        }
    }
}

page 96213 "LT WC LkEE Card"
{
    PageType = Card;
    SourceTable = "LT WC LkEE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(TabVal; Rec."Tab Val") { ApplicationArea = All; }
                field(CtlVal; Rec."Ctl Val")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Helper: Codeunit "LT WC LkEE Helper";
                    begin
                        Text := Helper.LookupFixed(2, false);
                        exit(true);
                    end;
                }
                field(DirectVal; Rec."Direct Val")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Helper: Codeunit "LT WC LkEE Helper";
                    begin
                        Helper.Mark(3, 'direct before error');
                        Error('');
                    end;
                }
                field(TextVal; Rec."Text Val") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 96215 "LT WC LkEE Helper"
{
    procedure LookupFixed(MarkId: Integer; WithText: Boolean): Code[20]
    var
        Value: Record "LT WC LkEE Value";
        ValueList: Page "LT WC LkEE Values";
    begin
        Mark(MarkId, 'before runmodal');
        ValueList.LookupMode := true;
        if ValueList.RunModal() <> Action::LookupOK then begin
            if WithText then
                Error('LT WC lookup cancelled');
            Error('');
        end;
        ValueList.GetRecord(Value);
        exit(Value."Code");
    end;

    procedure Mark(MarkId: Integer; MarkName: Text)
    var
        M: Record "LT WC LkEE Mark";
    begin
        M.Init();
        M.Id := MarkId;
        M.Name := CopyStr(MarkName, 1, MaxStrLen(M.Name));
        M.Insert();
    end;
}

codeunit 96214 "LT WC Lookup Empty Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT WC LkEE Row";
        Value: Record "LT WC LkEE Value";
        M: Record "LT WC LkEE Mark";
    begin
        Row.DeleteAll();
        Value.DeleteAll();
        M.DeleteAll();
        Value."Code" := 'A';
        Value.Insert();
        Value."Code" := 'B';
        Value.Insert();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'seed';
        Row.Insert();
    end;

    local procedure Marks(): Text
    var
        M: Record "LT WC LkEE Mark";
        Result: Text;
    begin
        if M.FindSet() then
            repeat
                Result += Format(M.Id) + '=' + M.Name + ';';
            until M.Next() = 0;
        exit(Result);
    end;

    local procedure StoredName(): Text
    var
        Row: Record "LT WC LkEE Row";
    begin
        if not Row.Get(1) then
            exit('missing');
        exit(Row.Name);
    end;

    [ModalPageHandler]
    procedure CancelValues(var Values: TestPage "LT WC LkEE Values")
    begin
        Values.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CancelValues')]
    procedure WcTableFieldLookup_CancelEmptyError_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT WC LkEE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.TabVal.Lookup();
        Observer.Observe('went-on', 'yes');
        Observer.Observe('after-lookup|text', GetLastErrorText());
        Observer.Observe('after-lookup|code', GetLastErrorCode());
        Observer.Observe('value-after', Card.TabVal.Value());
        Observer.Observe('marks', Marks());
        Card.NameCtl.SetValue('after lookup');
        Card.Close();
        Observer.Observe('stored-name-after-close', StoredName());
        Observer.Observe('marks-after-close', Marks());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelValues')]
    procedure WcControlLookup_CancelEmptyError_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT WC LkEE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.CtlVal.Lookup();
        Observer.Observe('went-on', 'yes');
        Observer.Observe('after-lookup|text', GetLastErrorText());
        Observer.Observe('after-lookup|code', GetLastErrorCode());
        Observer.Observe('value-after', Card.CtlVal.Value());
        Observer.Observe('marks', Marks());
        Card.NameCtl.SetValue('after lookup');
        Card.Close();
        Observer.Observe('stored-name-after-close', StoredName());
        Observer.Observe('marks-after-close', Marks());
        Observer.Finish();
    end;

    [Test]
    procedure WcControlLookup_DirectEmptyError_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT WC LkEE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.DirectVal.Lookup();
        Observer.Observe('went-on', 'yes');
        Observer.Observe('after-lookup|text', GetLastErrorText());
        Observer.Observe('after-lookup|code', GetLastErrorCode());
        Observer.Observe('value-after', Card.DirectVal.Value());
        Observer.Observe('marks', Marks());
        Card.Close();
        Observer.Observe('marks-after-close', Marks());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelValues')]
    procedure WcTableFieldLookup_CancelTextError_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT WC LkEE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.TextVal.Lookup();
        Observer.ObserveError('lookup');
        Observer.Observe('marks', Marks());
        Observer.Observe('value-after', Card.TextVal.Value());
        Card.Close();
        Observer.Finish();
    end;
}
