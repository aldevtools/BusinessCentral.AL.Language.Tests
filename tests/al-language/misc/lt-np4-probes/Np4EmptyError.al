// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93440, pages 93441-93445, test codeunit 93446
// Writer NP4 (NP lane, 2026-10-30). Probe: Error('') raised from a page CONTROL's own OnValidate (the table field has no trigger) during TestPage SetValue, on a Card,
//   a List, a Worksheet and a card with a part page: whether the test goes on, GetLastErrorText / GetLastErrorCode, the value the control shows and the stored
//   row. The table-trigger shapes are pinned in pages/lt-qi-empty-error/QzTableValidateEmptyError.al.
// BC versions: 27, 28, 29

table 93440 "LT NP4 EE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 93441 "LT NP4 EE Card"
{
    PageType = Card;
    SourceTable = "LT NP4 EE Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    if Rec.Name = 'empty' then
                        Error('');
                end;
            }
        }
    }
}

page 93442 "LT NP4 EE List"
{
    PageType = List;
    SourceTable = "LT NP4 EE Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if Rec.Name = 'empty' then
                            Error('');
                    end;
                }
            }
        }
    }
}

page 93443 "LT NP4 EE Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT NP4 EE Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if Rec.Name = 'empty' then
                            Error('');
                    end;
                }
            }
        }
    }
}

page 93444 "LT NP4 EE Part"
{
    PageType = CardPart;
    SourceTable = "LT NP4 EE Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    if Rec.Name = 'empty' then
                        Error('');
                end;
            }
        }
    }
}

page 93445 "LT NP4 EE Host"
{
    PageType = Card;
    SourceTable = "LT NP4 EE Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(Sub; "LT NP4 EE Part")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 93446 "LT NP4 EE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(): Record "LT NP4 EE Row"
    var
        Row: Record "LT NP4 EE Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'seed';
        Row.Insert();
        Commit();
        exit(Row);
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT NP4 EE Row";
    begin
        exit(Format(Row.Get(1)) + '|' + Row.Name);
    end;

    [Test]
    procedure NP4_EE_ControlValidate_Card()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT NP4 EE Row";
        Card: TestPage "LT NP4 EE Card";
    begin
        Row := Seed();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Card.Name.Value());
        Card.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure NP4_EE_ControlValidate_List()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT NP4 EE Row";
        List: TestPage "LT NP4 EE List";
    begin
        Row := Seed();
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', List.Name.Value());
        List.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure NP4_EE_ControlValidate_Worksheet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT NP4 EE Row";
        Sheet: TestPage "LT NP4 EE Worksheet";
    begin
        Row := Seed();
        Sheet.OpenEdit();
        Sheet.GoToRecord(Row);
        Sheet.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Sheet.Name.Value());
        Sheet.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure NP4_EE_ControlValidate_PartOfCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT NP4 EE Row";
        Host: TestPage "LT NP4 EE Host";
    begin
        Row := Seed();
        Host.OpenEdit();
        Host.GoToRecord(Row);
        Host.Sub.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Host.Sub.Name.Value());
        Host.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure NP4_EE_ControlValidate_Card_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT NP4 EE Row";
        Card: TestPage "LT NP4 EE Card";
    begin
        Row := Seed();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror begin
            Card.Name.SetValue('empty');
            Error('no error');
        end;
        Observer.ObserveError('setvalue');
        Observer.Observe('value-after', Card.Name.Value());
        Card.Close();
        Observer.Finish();
    end;
}
