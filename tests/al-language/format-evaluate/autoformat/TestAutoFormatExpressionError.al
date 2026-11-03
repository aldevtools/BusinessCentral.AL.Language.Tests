// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page and codeunit declared below.
//
// CLAIM: a control's AutoFormatExpression is evaluated as AL when the page renders the control,
// and an error it raises reaches the test that opened the page and read the control. It is not
// replaced by the default format. The paired page's expression calls a procedure that answers a
// format, and the control reads in that format.
//
// Written by agent stma-auto2-13, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#3479.

table 67644 "AFE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67644 "AFE Card"
{
    PageType = Card;
    SourceTable = "AFE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(FailingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = FailingFormat();
            }
        }
    }

    local procedure FailingFormat(): Text
    begin
        Error('AFE format expression failed');
    end;
}

page 67645 "AFE Working Card"
{
    PageType = Card;
    SourceTable = "AFE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(WorkingCtl; Rec.Amount)
            {
                ApplicationArea = All;
                AutoFormatType = 10;
                AutoFormatExpression = WorkingFormat();
            }
        }
    }

    local procedure WorkingFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,0>');
    end;
}

codeunit 67644 "AFE Expression Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow()
    var
        Row: Record "AFE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'AFE';
        Row.Amount := 7;
        Row.Insert();
    end;

    local procedure OpenAndReadFailing(): Text
    var
        Card: TestPage "AFE Card";
    begin
        Card.OpenView();
        exit(Card.FailingCtl.Value());
    end;

    [Test]
    procedure FailingAutoFormatExpression_ErrorReachesTheTest()
    begin
        SeedRow();
        asserterror OpenAndReadFailing();
        Assert.ExpectedError('AFE format expression failed');
    end;

    [Test]
    procedure WorkingAutoFormatExpression_FormatsTheValue()
    var
        Card: TestPage "AFE Working Card";
        Shown: Text;
    begin
        SeedRow();
        Card.OpenView();
        Shown := Card.WorkingCtl.Value();
        Card.Close();
        Assert.AreEqual('7.000', Shown, 'the control must read in the format its AutoFormatExpression answers');
    end;
}
