// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85365
// Facts: corpus issue 670 (odd AL behavior leads, part E): an enum value whose Caption contains a comma ('Diamond Level, with bonus'):
//   Format, Evaluate from the caption and from the name, FieldRef.OptionCaption and OptionMembers of a field of that enum, and
//   TestPage SetValue by caption (Learn warns that a comma in a caption can select the wrong value).
//   The compiler gives warning AL0649 for the comma. Format and Evaluate use the whole caption; TestPage SetValue splits the caption list at
//   every comma, so the whole caption is refused and its halves select other values.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
enum 85365 "LT CV Tier"
{
    Extensible = true;

    value(0; Plain) { Caption = 'Plain'; }
    value(1; Diamond) { Caption = 'Diamond Level, with bonus'; }
    value(2; Gold) { Caption = 'with bonus'; }
    value(3; Silver) { Caption = 'Silver'; }
}

table 85365 "LT CV Tier Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tier; Enum "LT CV Tier") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 85365 "LT CV Tier Card"
{
    PageType = Card;
    SourceTable = "LT CV Tier Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Tier; Rec.Tier) { ApplicationArea = All; }
        }
    }
}

codeunit 85365 "LT CV Enum Caption Comma Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TryEvaluate(Txt: Text): Text
    var
        E: Enum "LT CV Tier";
        Ok: Boolean;
    begin
        E := E::Silver;
        Ok := Evaluate(E, Txt);
        exit(Format(Ok) + '|' + Format(E.AsInteger()));
    end;

    [Test]
    procedure FormatAndEvaluate()
    var
        E: Enum "LT CV Tier";
        Observer: Codeunit "Probe Observer";
    begin
        E := E::Diamond;
        Observer.Observe('format', Format(E));
        Observer.Observe('format_9', Format(E, 0, 9));
        Observer.Observe('format_2', Format(E, 0, 2));
        Observer.Observe('names', Enum::"LT CV Tier".Names().Get(2));
        Observer.Observe('eval|caption', TryEvaluate('Diamond Level, with bonus'));
        Observer.Observe('eval|name', TryEvaluate('Diamond'));
        Observer.Observe('eval|second_half', TryEvaluate('with bonus'));
        Observer.Observe('eval|first_half', TryEvaluate('Diamond Level'));
        Observer.Expect('format', 'Diamond Level, with bonus');
        Observer.Expect('format_9', '1');
        Observer.Expect('format_2', '1');
        Observer.Expect('names', 'Diamond');
        Observer.Expect('eval|caption', 'Yes|1');
        Observer.Expect('eval|name', 'Yes|1');
        Observer.Expect('eval|second_half', 'Yes|2');
        Observer.Expect('eval|first_half', 'No|3');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefOptionStrings()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT CV Tier Row");
        FldRef := RecRef.Field(2);
        Observer.Observe('optioncaption', FldRef.OptionCaption());
        Observer.Observe('optionmembers', FldRef.OptionMembers());
        FldRef.Value := Enum::"LT CV Tier"::Diamond;
        Observer.Observe('fieldref_format', Format(FldRef.Value));
        Observer.Expect('optioncaption', 'Plain,Diamond Level, with bonus,with bonus,Silver');
        Observer.Expect('optionmembers', 'Plain,Diamond,Gold,Silver');
        Observer.Expect('fieldref_format', 'Diamond Level, with bonus');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetValue(var Card: TestPage "LT CV Tier Card"; NewValue: Text)
    begin
        Card.Tier.SetValue(NewValue);
    end;

    local procedure SetOnFreshPage(var Observer: Codeunit "Probe Observer"; Name: Text; NewValue: Text)
    var
        Row: Record "LT CV Tier Row";
        Card: TestPage "LT CV Tier Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tier := Row.Tier::Silver;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        Observer.Observe(Name + '|ok', Format(TrySetValue(Card, NewValue)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Card.Tier.Value());
        Card.Close();
        Row.Get(1);
        Observer.Observe(Name + '|stored', Format(Row.Tier.AsInteger()));
    end;

    // Corpus #670 item 60: TestPage field GetValidationError() with no validation error pending returns an empty text. Windows BC 27.5,
    // 28.5 and 29.0 (Windows BC 29.0 check 2026-10-20). Was held on Linux for bc-linux #160 (the Linux image, BC 29.0, ended the test with an
    // uncatchable System.ArgumentOutOfRangeException (Parameter 'index') in NavTestField.ALGetValidationError); the bc-linux maintainer
    // cannot reproduce it on the current image.
    [Test]
    procedure GetValidationError_NonePending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CV Tier Row";
        Card: TestPage "LT CV Tier Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tier := Row.Tier::Silver;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('setvalue ok', Format(TrySetValue(Card, 'Plain')));
        Observer.Observe('getvalidationerror', Card.Tier.GetValidationError());
        Observer.Expect('setvalue ok', 'Yes');
        Observer.Expect('getvalidationerror', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPageSetValueByCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetOnFreshPage(Observer, 'caption_with_comma', 'Diamond Level, with bonus');
        SetOnFreshPage(Observer, 'second_half', 'with bonus');
        SetOnFreshPage(Observer, 'first_half', 'Diamond Level');
        SetOnFreshPage(Observer, 'name', 'Diamond');
        SetOnFreshPage(Observer, 'plain_caption', 'Plain');
        Observer.Expect('caption_with_comma|ok', 'No');
        Observer.Expect('caption_with_comma|text', 'Validation error for Field: Tier,  Message = ''Your entry of ''Diamond ...th bonus'' is not an acceptable value for ''Tier''. (Select Refresh to discard errors)''');
        Observer.Expect('caption_with_comma|code', 'TestValidation');
        Observer.Expect('caption_with_comma|value', '3');
        Observer.Expect('caption_with_comma|stored', '3');
        Observer.Expect('second_half|ok', 'Yes');
        Observer.Expect('second_half|text', '');
        Observer.Expect('second_half|code', '');
        Observer.Expect('second_half|value', ' with bonus');
        Observer.Expect('second_half|stored', '2');
        Observer.Expect('first_half|ok', 'Yes');
        Observer.Expect('first_half|text', '');
        Observer.Expect('first_half|code', '');
        Observer.Expect('first_half|value', 'Diamond Level');
        Observer.Expect('first_half|stored', '1');
        Observer.Expect('name|ok', 'No');
        Observer.Expect('name|text', 'Validation error for Field: Tier,  Message = ''Your entry of ''Diamond'' is not an acceptable value for ''Tier''. (Select Refresh to discard errors)''');
        Observer.Expect('name|code', 'TestValidation');
        Observer.Expect('name|value', '3');
        Observer.Expect('name|stored', '3');
        Observer.Expect('plain_caption|ok', 'Yes');
        Observer.Expect('plain_caption|text', '');
        Observer.Expect('plain_caption|code', '');
        Observer.Expect('plain_caption|value', 'Plain');
        Observer.Expect('plain_caption|stored', '0');
        Observer.Verify();
    end;
}
