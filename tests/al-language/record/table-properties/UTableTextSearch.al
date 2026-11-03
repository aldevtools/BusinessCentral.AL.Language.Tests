// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optimizefortextsearch-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 599): the MaxLength option of Caption on a table and a field. OptimizeForTextSearch is not probed: a table with it cannot be published to the OnPrem containers (no SQL Server Full-Text Search). Object ids 69580 and 69584.

table 69580 "LT U Text Search"
{
    DataClassification = SystemMetadata;
    Caption = 'Text search caption', MaxLength = 5;

    fields
    {
        field(1; Id; Integer) { }
        field(3; Txt; Text[30])
        {
            Caption = 'Text field caption', MaxLength = 4;
        }
        field(4; Plain; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69584 "LT U Text Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MaxLength_CaptionLongerThanLimit()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Text Search";
    begin
        Observer.Observe('table_caption', Rec.TableCaption());
        Observer.Observe('table_caption_length', Format(StrLen(Rec.TableCaption())));
        Observer.Observe('field_caption', Rec.FieldCaption(Txt));
        Observer.Observe('field_caption_length', Format(StrLen(Rec.FieldCaption(Txt))));
        Observer.Expect('table_caption', 'Text ');
        Observer.Expect('table_caption_length', '5');
        Observer.Expect('field_caption', 'Text');
        Observer.Expect('field_caption_length', '4');
        Observer.Verify();
    end;

    // Writer PX (runtime probes-needed "MaxLength on text properties"): an OptionCaption and a ToolTip longer than their MaxLength
    // (table 86239, page 86240 below), read by Format, FieldRef.OptionCaption, Evaluate and on a TestPage.
    [Test]
    procedure PX_MaxLength_OptionCaptionAndToolTip()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PX MaxLen";
        RecRef: RecordRef;
        Card: TestPage "LT PX MaxLen Card";
        Ok: Boolean;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Opt := R.Opt::B;
        R.Insert();
        Observer.Observe('format', Format(R.Opt));
        Observer.Observe('format_member', Format(R.Opt::A));
        RecRef.GetTable(R);
        Observer.Observe('optioncaption', RecRef.Field(R.FieldNo(Opt)).OptionCaption);
        Observer.Observe('fieldcaption', R.FieldCaption(Opt));
        Ok := Evaluate(R.Opt, 'Alphabet');
        Observer.Observe('evaluate_full', Format(Ok) + '/' + Format(R.Opt, 0, 9));
        Ok := Evaluate(R.Opt, 'Bet');
        Observer.Observe('evaluate_prefix', Format(Ok) + '/' + Format(R.Opt, 0, 9));
        R.Opt := R.Opt::B;
        Ok := Evaluate(R.Opt, 'Alph');
        Observer.Observe('evaluate_cut', Format(Ok) + '/' + Format(R.Opt, 0, 9));
        R.Opt := R.Opt::A;
        Ok := Evaluate(R.Opt, 'Betamax');
        Observer.Observe('evaluate_full_second', Format(Ok) + '/' + Format(R.Opt, 0, 9));
        R.Opt := R.Opt::B;
        Card.OpenView();
        Card.First();
        Observer.Observe('page_value', Card.Opt.Value);
        Observer.Observe('page_caption', Card.Opt.Caption);
        Observer.Observe('page_text_caption', Card.Txt.Caption);
        Card.Close();
        Observer.Expect('format', 'B');
        Observer.Expect('format_member', 'Alph');
        Observer.Expect('optioncaption', 'Alph,B');
        Observer.Expect('fieldcaption', 'Opt');
        Observer.Expect('evaluate_full', 'No/1');
        Observer.Expect('evaluate_prefix', 'No/1');
        Observer.Expect('evaluate_cut', 'Yes/0');
        Observer.Expect('evaluate_full_second', 'No/0');
        Observer.Expect('page_value', '1');
        Observer.Expect('page_caption', 'Opt');
        Observer.Expect('page_text_caption', 'Txt');
        Observer.Verify();
    end;

}


table 86239 "LT PX MaxLen"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = A,B;
            OptionCaption = 'Alphabet,Betamax', MaxLength = 4;
            ToolTip = 'A tool tip that is longer than its limit', MaxLength = 6;
        }
        field(3; Txt; Text[30])
        {
            ToolTip = 'Another long tool tip text', MaxLength = 3;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 86240 "LT PX MaxLen Card"
{
    PageType = Card;
    SourceTable = "LT PX MaxLen";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Opt; Rec.Opt) { ApplicationArea = All; }
            field(Txt; Rec.Txt)
            {
                ApplicationArea = All;
                ToolTip = 'Control tool tip text that is long', MaxLength = 7;
            }
        }
    }
}
