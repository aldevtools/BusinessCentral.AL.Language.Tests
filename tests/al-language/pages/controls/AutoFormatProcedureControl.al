// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75321 75322 75323, table extension 75324, pages 75325 75326, page extension
//   75327, counter codeunit 75328, test codeunit 75329
// Probe (al-runner 7850): a TestPage control over a Decimal field with AutoFormatType = 11 and AutoFormatExpression =
//   Setup.GetFormat(Setup.FieldNo(Decimals)), where GetFormat is a procedure of another table's record variable (a global of the table)
//   that returns a format text and counts its calls. Steps: OpenView + GoToRecord, Value(), AsDecimal(), then OpenEdit + GoToRecord,
//   SetValue, Value(), AssertEquals(Decimal) and AssertEquals(Text) (each inside asserterror; 'NO_ERROR' when it did not raise), Close.
//   Observed per step: the value read and the GetFormat calls since the last step. Cells: the format '<precision, 2:2><standard
//   format, 0>' on a base table field; the same field declared by a table extension and shown by a page extension (the reporter's
//   shape); the procedure returning ''; returning '<precision, 0:0><standard format, 0>' with SetValue(7.5).
// local object: the field, its AutoFormatExpression and the counter are what the test checks
// Facts: the procedure runs 2 times on OpenView, 1 on GoToRecord, 3 on OpenEdit + GoToRecord and 2 on Close after the edit; never on
//   Value(), AsDecimal(), SetValue or AssertEquals. Value() follows the format ('3.25', '7.00'; with 0:0 '3' and '8' after SetValue(7.5));
//   AssertEquals(Decimal) passes; AssertEquals('7.00') passes with 2:2 and with '' ; AssertEquals('7.5') fails with 0:0.
// BC versions: 27, 28, 29

table 75321 "PG6 AF Setup"
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

table 75322 "PG6 AF Thing"
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

table 75323 "PG6 AF Thing Ext Base"
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

tableextension 75324 "PG6 AF Thing Ext" extends "PG6 AF Thing Ext Base"
{
    fields
    {
        field(75324; ExtAmount; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 11;
            AutoFormatExpression = AFSetup.GetFormat(AFSetup.FieldNo(Decimals));
        }
    }

    var
        AFSetup: Record "PG6 AF Setup";
}

page 75325 "PG6 AF Card"
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

page 75326 "PG6 AF Ext Card"
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

pageextension 75327 "PG6 AF Ext Card Ext" extends "PG6 AF Ext Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtAmount; Rec.ExtAmount) { ApplicationArea = All; }
        }
    }
}

codeunit 75328 "PG6 AF Counter"
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

codeunit 75329 "PG6 AF Procedure Control"
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
        Observer.Expect('setup', ' calls=0');
        Observer.Expect('openview', ' calls=2');
        Observer.Expect('gotorecord', ' calls=1');
        Observer.Expect('value', '3.25 calls=0');
        Observer.Expect('asdecimal', '3.25 calls=0');
        Observer.Expect('close-view', ' calls=0');
        Observer.Expect('openedit', ' calls=3');
        Observer.Expect('setvalue', ' calls=0');
        Observer.Expect('value-after', '7.00 calls=0');
        Observer.Expect('assert-decimal', 'NO_ERROR calls=0');
        Observer.Expect('assert-text', 'NO_ERROR calls=0');
        Observer.Expect('close-edit', '7.00 calls=2');
        Observer.Verify();
    end;

    [Test]
    procedure Base_EmptyFormat_ReadSetAssert()
    begin
        RunBase('', 7, '7.00');
        Observer.Expect('setup', ' calls=0');
        Observer.Expect('openview', ' calls=2');
        Observer.Expect('gotorecord', ' calls=1');
        Observer.Expect('value', '3.25 calls=0');
        Observer.Expect('asdecimal', '3.25 calls=0');
        Observer.Expect('close-view', ' calls=0');
        Observer.Expect('openedit', ' calls=3');
        Observer.Expect('setvalue', ' calls=0');
        Observer.Expect('value-after', '7.00 calls=0');
        Observer.Expect('assert-decimal', 'NO_ERROR calls=0');
        Observer.Expect('assert-text', 'NO_ERROR calls=0');
        Observer.Expect('close-edit', '7 calls=2');
        Observer.Verify();
    end;

    [Test]
    procedure Base_ZeroDecimals_ReadSetAssert()
    begin
        RunBase('<precision, 0:0><standard format, 0>', 7.5, '7.5');
        Observer.Expect('setup', ' calls=0');
        Observer.Expect('openview', ' calls=2');
        Observer.Expect('gotorecord', ' calls=1');
        Observer.Expect('value', '3 calls=0');
        Observer.Expect('asdecimal', '3.25 calls=0');
        Observer.Expect('close-view', ' calls=0');
        Observer.Expect('openedit', ' calls=3');
        Observer.Expect('setvalue', ' calls=0');
        Observer.Expect('value-after', '8 calls=0');
        Observer.Expect('assert-decimal', 'NO_ERROR calls=0');
        Observer.Expect('assert-text', 'AssertEquals for Field: Amount Expected = ''7.5'', Actual = ''8'' calls=0');
        Observer.Expect('close-edit', '8 calls=2');
        Observer.Verify();
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
        Observer.Expect('setup', ' calls=0');
        Observer.Expect('openview', ' calls=2');
        Observer.Expect('gotorecord', ' calls=1');
        Observer.Expect('value', '3.25 calls=0');
        Observer.Expect('asdecimal', '3.25 calls=0');
        Observer.Expect('close-view', ' calls=0');
        Observer.Expect('openedit', ' calls=3');
        Observer.Expect('setvalue', ' calls=0');
        Observer.Expect('value-after', '7.00 calls=0');
        Observer.Expect('assert-decimal', 'NO_ERROR calls=0');
        Observer.Expect('assert-text', 'NO_ERROR calls=0');
        Observer.Expect('close-edit', '7.00 calls=2');
        Observer.Verify();
    end;
}
