// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93440, pages 93441-93445, test codeunit 93446
// Writer NP4 (NP lane, 2026-10-30). Probe: Error('') raised from a page CONTROL's own OnValidate (the table field has no trigger) during TestPage SetValue, on a Card,
//   a List, a Worksheet and a card with a part page: whether the test goes on, GetLastErrorText / GetLastErrorCode, the value the control shows and the stored
//   row. The table-trigger shapes are pinned in pages/lt-qi-empty-error/QzTableValidateEmptyError.al.
// Writer Y9 (NP lane 1030e, 2026-10-30): own tables 91465-91466, pages 91467-91470 (tests Y9_* in codeunit 93446). Probe: the same on a ListPart (repeater) inside
//   a Card, a ListPlus page, a Document page header field and a ListPart of lines inside the Document page.
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
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
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
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
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
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
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
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
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
        Observer.Expect('setvalue|text', 'no error');
        Observer.Expect('setvalue|code', 'Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Verify();
    end;

    // ---- Writer Y9 (NP lane 1030e, 2026-10-30): Error('') in a control OnValidate on a ListPart inside a card, a ListPlus and a Document page ----

    local procedure Y9Seed(var Head: Record "LT Y9 EE Head"; var Line: Record "LT Y9 EE Line")
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head.Id := 1;
        Head.Desc := 'seed';
        Head.Insert();
        Line.HeadId := 1;
        Line.LineNo := 10000;
        Line.Name := 'seed';
        Line.Insert();
        Commit();
    end;

    local procedure Y9Stored(): Text
    var
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
    begin
        exit('head=' + Format(Head.Get(1)) + '|' + Head.Desc + ' line=' + Format(Line.Get(1, 10000)) + '|' + Line.Name);
    end;

    [Test]
    procedure Y9_EE_ControlValidate_ListPartInCard()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
        Host: TestPage "LT Y9 EE Card Host";
    begin
        Y9Seed(Head, Line);
        Host.OpenEdit();
        Host.GoToRecord(Head);
        Host.Lines.First();
        Host.Lines.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Host.Lines.Name.Value());
        Host.Close();
        Observer.Observe('stored-after-close', Y9Stored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'head=Yes|seed line=Yes|seed');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_EE_ControlValidate_ListPlus()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
        Plus: TestPage "LT Y9 EE ListPlus";
    begin
        Y9Seed(Head, Line);
        Plus.OpenEdit();
        Plus.GoToRecord(Line);
        Plus.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Plus.Name.Value());
        Plus.Close();
        Observer.Observe('stored-after-close', Y9Stored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'head=Yes|seed line=Yes|seed');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_EE_ControlValidate_DocumentHeader()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
        Doc: TestPage "LT Y9 EE Document";
    begin
        Y9Seed(Head, Line);
        Doc.OpenEdit();
        Doc.GoToRecord(Head);
        Doc.Desc.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Doc.Desc.Value());
        Doc.Close();
        Observer.Observe('stored-after-close', Y9Stored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'head=Yes|seed line=Yes|seed');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_EE_ControlValidate_DocumentLinePart()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
        Doc: TestPage "LT Y9 EE Document";
    begin
        Y9Seed(Head, Line);
        Doc.OpenEdit();
        Doc.GoToRecord(Head);
        Doc.Lines.First();
        Doc.Lines.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Doc.Lines.Name.Value());
        Doc.Close();
        Observer.Observe('stored-after-close', Y9Stored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'head=Yes|seed line=Yes|seed');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_EE_ControlValidate_DocumentHeader_ThenValidValue()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT Y9 EE Head";
        Line: Record "LT Y9 EE Line";
        Doc: TestPage "LT Y9 EE Document";
    begin
        // after the quiet error a valid value can still be set and is stored
        Y9Seed(Head, Line);
        Doc.OpenEdit();
        Doc.GoToRecord(Head);
        Doc.Desc.SetValue('empty');
        ClearLastError();
        Doc.Desc.SetValue('fine');
        Observer.Observe('value-after', Doc.Desc.Value());
        Doc.Close();
        Observer.Observe('stored-after-close', Y9Stored());
        Observer.Expect('value-after', 'fine');
        Observer.Expect('stored-after-close', 'head=Yes|fine line=Yes|seed');
        Observer.Verify();
    end;
}

table 91465 "LT Y9 EE Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Desc; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 91466 "LT Y9 EE Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; HeadId, LineNo) { Clustered = true; } }
}

page 91467 "LT Y9 EE Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y9 EE Line";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
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

page 91468 "LT Y9 EE Card Host"
{
    PageType = Card;
    SourceTable = "LT Y9 EE Head";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT Y9 EE Lines")
            {
                ApplicationArea = All;
                SubPageLink = HeadId = field(Id);
            }
        }
    }
}

page 91469 "LT Y9 EE ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT Y9 EE Line";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
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

page 91470 "LT Y9 EE Document"
{
    PageType = Document;
    SourceTable = "LT Y9 EE Head";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Desc; Rec.Desc)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if Rec.Desc = 'empty' then
                            Error('');
                    end;
                }
            }
            part(Lines; "LT Y9 EE Lines")
            {
                ApplicationArea = All;
                SubPageLink = HeadId = field(Id);
            }
        }
    }
}
