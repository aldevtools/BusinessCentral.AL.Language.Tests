// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 77721 77722 77723, table extension 77724, pages 77725 77726, page extension
//   77727, counter codeunit 77728, test codeunit 77729
// Probe (al-runner 7850): a TestPage control over a Decimal field with AutoFormatType = 11 and AutoFormatExpression =
//   Setup.GetFormat(Setup.FieldNo(Decimals)), where GetFormat is a procedure of another table's record variable (a global of the table)
//   that returns a format text and counts its calls. Steps: OpenView + GoToRecord, Value(), AsDecimal(), then OpenEdit + GoToRecord,
//   SetValue, Value(), AssertEquals(Decimal) and AssertEquals(Text) (each inside asserterror; 'NO_ERROR' when it did not raise), Close.
//   Observed per step: the value read and the GetFormat calls since the last step. Cells: the format '<precision, 2:2><standard
//   format, 0>' on a base table field; the same field declared by a table extension and shown by a page extension (the reporter's
//   shape); the procedure returning ''; returning '<precision, 0:0><standard format, 0>' with SetValue(7.5).
// local object: the field, its AutoFormatExpression and the counter are what the test checks
// BC versions: 27, 28, 29

table 77721 "PG6 AF Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Decimals; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    procedure GetFormat(FieldNo: Integer): Text
    var
        Counter: Codeunit "PG6 AF Counter";
    begin
        exit(Counter.Next(FieldNo));
    end;
}

table 77722 "PG6 AF Thing"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Amount; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 11;
            AutoFormatExpression = AFSetup.GetFormat(AFSetup.FieldNo(Decimals));
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    var
        AFSetup: Record "PG6 AF Setup";
}

table 77723 "PG6 AF Thing Ext Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

tableextension 77724 "PG6 AF Thing Ext" extends "PG6 AF Thing Ext Base"
{
    fields
    {
        field(77724; ExtAmount; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 11;
            AutoFormatExpression = AFSetup.GetFormat(AFSetup.FieldNo(Decimals));
        }
    }

    var
        AFSetup: Record "PG6 AF Setup";
}

page 77725 "PG6 AF Card"
{
    PageType = Card;
    SourceTable = "PG6 AF Thing";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 77726 "PG6 AF Ext Card"
{
    PageType = Card;
    SourceTable = "PG6 AF Thing Ext Base";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }
}

pageextension 77727 "PG6 AF Ext Card Ext" extends "PG6 AF Ext Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtAmount; Rec.ExtAmount) { ApplicationArea = All; }
        }
    }
}

codeunit 77728 "PG6 AF Counter"
{
    SingleInstance = true;

    var
        Calls: Integer;
        FormatText: Text;

    procedure Reset(NewFormat: Text)
    begin
        Calls := 0;
        FormatText := NewFormat;
    end;

    procedure Next(FieldNo: Integer): Text
    begin
        Calls += 1;
        exit(FormatText);
    end;

    procedure Take() Result: Integer
    begin
        Result := Calls;
        Calls := 0;
    end;
}

codeunit 77729 "PG6 AF Procedure Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Counter: Codeunit "PG6 AF Counter";

    local procedure Initialize(NewFormat: Text)
    var
        Thing: Record "PG6 AF Thing";
        ExtThing: Record "PG6 AF Thing Ext Base";
    begin
        Observer.Discard();
        Thing.DeleteAll();
        ExtThing.DeleteAll();
        Thing.Init();
        Thing."Code" := 'T1';
        Thing.Amount := 3.25;
        Thing.Insert();
        ExtThing.Init();
        ExtThing."Code" := 'T1';
        ExtThing.ExtAmount := 3.25;
        ExtThing.Insert();
        // asserterror rolls back the uncommitted writes of the test
        Commit();
        Counter.Reset(NewFormat);
    end;

    local procedure Say(Name: Text; Value: Text)
    begin
        Observer.Observe(Name, Value + ' calls=' + Format(Counter.Take()));
    end;

    local procedure SayError(Name: Text)
    begin
        Observer.Observe(Name, GetLastErrorText() + ' calls=' + Format(Counter.Take()));
        ClearLastError();
    end;

    local procedure StoredAmount(): Text
    var
        Thing: Record "PG6 AF Thing";
    begin
        Thing.Get('T1');
        exit(Format(Thing.Amount, 0, 9));
    end;

    local procedure RunBase(NewFormat: Text; NewValue: Decimal; DecimalText: Text)
    var
        Thing: Record "PG6 AF Thing";
        P: TestPage "PG6 AF Card";
    begin
        Initialize(NewFormat);
        Thing.Get('T1');
        Say('setup', '');
        P.OpenView();
        Say('openview', '');
        P.GoToRecord(Thing);
        Say('gotorecord', '');
        Say('value', P.Amount.Value());
        Say('asdecimal', Format(P.Amount.AsDecimal(), 0, 9));
        P.Close();
        Say('close-view', '');
        P.OpenEdit();
        P.GoToRecord(Thing);
        Say('openedit', '');
        P.Amount.SetValue(NewValue);
        Say('setvalue', '');
        Say('value-after', P.Amount.Value());
        asserterror begin
            P.Amount.AssertEquals(NewValue);
            Error('NO_ERROR');
        end;
        SayError('assert-decimal');
        asserterror begin
            P.Amount.AssertEquals(DecimalText);
            Error('NO_ERROR');
        end;
        SayError('assert-text');
        P.Close();
        Say('close-edit', StoredAmount());
    end;

    [Test]
    procedure Base_TwoDecimals_ReadSetAssert()
    begin
        RunBase('<precision, 2:2><standard format, 0>', 7, '7.00');
        Observer.Finish();
    end;

    [Test]
    procedure Base_EmptyFormat_ReadSetAssert()
    begin
        RunBase('', 7, '7.00');
        Observer.Finish();
    end;

    [Test]
    procedure Base_ZeroDecimals_ReadSetAssert()
    begin
        RunBase('<precision, 0:0><standard format, 0>', 7.5, '7.5');
        Observer.Finish();
    end;

    [Test]
    procedure Extension_TwoDecimals_ReadSetAssert()
    var
        ExtThing: Record "PG6 AF Thing Ext Base";
        P: TestPage "PG6 AF Ext Card";
    begin
        Initialize('<precision, 2:2><standard format, 0>');
        ExtThing.Get('T1');
        Say('setup', '');
        P.OpenView();
        Say('openview', '');
        P.GoToRecord(ExtThing);
        Say('gotorecord', '');
        Say('value', P.ExtAmount.Value());
        Say('asdecimal', Format(P.ExtAmount.AsDecimal(), 0, 9));
        P.Close();
        Say('close-view', '');
        P.OpenEdit();
        P.GoToRecord(ExtThing);
        Say('openedit', '');
        P.ExtAmount.SetValue(7);
        Say('setvalue', '');
        Say('value-after', P.ExtAmount.Value());
        asserterror begin
            P.ExtAmount.AssertEquals(7);
            Error('NO_ERROR');
        end;
        SayError('assert-decimal');
        asserterror begin
            P.ExtAmount.AssertEquals('7.00');
            Error('NO_ERROR');
        end;
        SayError('assert-text');
        P.Close();
        ExtThing.Get('T1');
        Say('close-edit', Format(ExtThing.ExtAmount, 0, 9));
        Observer.Finish();
    end;
}
