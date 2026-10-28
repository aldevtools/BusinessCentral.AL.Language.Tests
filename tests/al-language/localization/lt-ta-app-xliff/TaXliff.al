// Scope: in-scope
// Corpus issue (al-runner 5772, writer TA): the app ships Translations/AL Language Coverage Tests.nl-NL.xlf (feature TranslationFile).
// Each test sets GlobalLanguage and observes how the app's own translation applies to an enum caption (Format / Evaluate), a Label,
// a field caption, a table caption and an option caption; a language without a file (de-DE, 1031) shows the base text.

enum 89730 "LT TA Status"
{
    Extensible = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Rel)
    {
        Caption = 'Released';
    }
    value(2; Done)
    {
        Caption = 'Finished';
    }
}

table 89731 "LT TA Item"
{
    Caption = 'LT TA Item';
    TableType = Temporary;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Item number';
        }
        field(2; Kind; Option)
        {
            Caption = 'Kind';
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'Alpha,Beta,Gamma';
        }
        field(3; Status; Enum "LT TA Status")
        {
            Caption = 'Status';
        }
    }
    keys
    {
        key(PK; "No.") { }
    }
}

codeunit 89732 "LT TA Labels"
{
    var
        HelloLbl: Label 'Hello world';
        CountLbl: Label '%1 items found';
        LockedLbl: Label 'Hello world', Locked = true;
        UntranslatedLbl: Label 'No translation here';

    procedure Hello(): Text
    begin
        exit(HelloLbl);
    end;

    procedure Count(N: Integer): Text
    begin
        exit(StrSubstNo(CountLbl, N));
    end;

    procedure LockedHello(): Text
    begin
        exit(LockedLbl);
    end;

    procedure Untranslated(): Text
    begin
        exit(UntranslatedLbl);
    end;
}

codeunit 89733 "LT TA Xliff Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BoolText(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;

    [Test]
    procedure TA_Enum_Format_And_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        Status: Enum "LT TA Status";
        Ok: Boolean;
    begin
        Status := Status::Rel;
        GlobalLanguage(1033);
        Observer.Observe('en_format_rel', Format(Status));
        GlobalLanguage(1043);
        Observer.Observe('nl_format_rel', Format(Status));
        Status := Status::Open;
        Observer.Observe('nl_format_open', Format(Status));
        Status := Status::Done;
        Observer.Observe('nl_format_done_untranslated_unit', Format(Status));
        Clear(Status);
        Ok := Evaluate(Status, 'Vrijgegeven');
        Observer.Observe('nl_eval_dutch', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        Clear(Status);
        Ok := Evaluate(Status, 'Released');
        Observer.Observe('nl_eval_base', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        Clear(Status);
        Ok := Evaluate(Status, 'Rel');
        Observer.Observe('nl_eval_name', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        Clear(Status);
        Ok := Evaluate(Status, 'Finished');
        Observer.Observe('nl_eval_done_base', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        GlobalLanguage(1033);
        Clear(Status);
        Ok := Evaluate(Status, 'Vrijgegeven');
        Observer.Observe('en_eval_dutch', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        GlobalLanguage(1031);
        Status := Status::Rel;
        Observer.Observe('de_format_rel', Format(Status));
        Clear(Status);
        Ok := Evaluate(Status, 'Vrijgegeven');
        Observer.Observe('de_eval_dutch', BoolText(Ok) + '|' + Format(Status.AsInteger()));
        GlobalLanguage(2067);
        Status := Status::Rel;
        Observer.Observe('nlbe_format_rel', Format(Status));
        GlobalLanguage(1033);
        Observer.Finish();
    end;

    [Test]
    procedure TA_Label_Text()
    var
        Observer: Codeunit "Probe Observer";
        Labels: Codeunit "LT TA Labels";
    begin
        GlobalLanguage(1033);
        Observer.Observe('en_hello', Labels.Hello());
        GlobalLanguage(1043);
        Observer.Observe('nl_hello', Labels.Hello());
        Observer.Observe('nl_count', Labels.Count(3));
        Observer.Observe('nl_locked', Labels.LockedHello());
        Observer.Observe('nl_untranslated', Labels.Untranslated());
        GlobalLanguage(1031);
        Observer.Observe('de_hello', Labels.Hello());
        Observer.Observe('de_count', Labels.Count(3));
        GlobalLanguage(2067);
        Observer.Observe('nlbe_hello', Labels.Hello());
        GlobalLanguage(1033);
        Observer.Finish();
    end;

    [Test]
    procedure TA_Captions_And_Options()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT TA Item" temporary;
        RecRef: RecordRef;
        Ok: Boolean;
    begin
        GlobalLanguage(1033);
        Observer.Observe('en_field_caption', Item.FieldCaption("No."));
        Observer.Observe('en_table_caption', Item.TableCaption());
        GlobalLanguage(1043);
        Observer.Observe('nl_field_caption', Item.FieldCaption("No."));
        Observer.Observe('nl_field_caption_kind', Item.FieldCaption(Kind));
        Observer.Observe('nl_table_caption', Item.TableCaption());
        Item.Kind := Item.Kind::Beta;
        Observer.Observe('nl_format_option', Format(Item.Kind));
        Item.Kind := Item.Kind::Gamma;
        Observer.Observe('nl_format_option_gamma', Format(Item.Kind));
        Ok := Evaluate(Item.Kind, 'Tweede');
        Observer.Observe('nl_eval_option_dutch', BoolText(Ok) + '|' + Format(Item.Kind + 0));
        Ok := Evaluate(Item.Kind, 'Alpha');
        Observer.Observe('nl_eval_option_base', BoolText(Ok) + '|' + Format(Item.Kind + 0));
        RecRef.GetTable(Item);
        Observer.Observe('nl_fieldref_caption', RecRef.Field(1).Caption());
        Observer.Observe('nl_fieldref_optioncaption', RecRef.Field(2).OptionCaption());
        Observer.Observe('nl_recref_caption', RecRef.Caption());
        Item.Status := Item.Status::Rel;
        RecRef.GetTable(Item);
        Observer.Observe('nl_fieldref_enum_format', Format(RecRef.Field(3).Value()));
        Observer.Observe('nl_enum_field_format', Format(Item.Status));
        GlobalLanguage(1031);
        Observer.Observe('de_field_caption', Item.FieldCaption("No."));
        Observer.Observe('de_table_caption', Item.TableCaption());
        Item.Kind := Item.Kind::Beta;
        Observer.Observe('de_format_option', Format(Item.Kind));
        GlobalLanguage(1033);
        Observer.Finish();
    end;
}
