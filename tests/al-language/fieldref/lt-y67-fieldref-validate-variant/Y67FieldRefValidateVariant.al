// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93630, enum 93632, codeunit 93631 (writer Y67, gap cycle 6 follow-up)
// Probe: FieldRef.Validate(Variant) and FieldRef.Value := Variant with a Variant that holds an Integer, a Decimal, a BigInteger, a Boolean, a
//   Date, a Time, a DateTime, a Text (a number, other text, empty), a Code, an Option, an Enum, a Guid or a Duration, into a field of each type
//   (Text, Code, Integer, Decimal, BigInteger, Boolean, Date, Time, DateTime, Option, Enum, Guid, Duration). Per cell: the value of the field
//   (Format(.., 0, 9)) and how many times its OnValidate ran after Validate, and the value after FieldRef.Value :=; or the error text and code.
// BC versions: 27, 28, 29

enum 93632 "LT Y67 FV Kind"
{
    Extensible = false;

    value(0; One) { }
    value(1; Two) { }
    value(5; Five) { }
}

table 93630 "LT Y67 FV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30])
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(3; Cod; Code[20])
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(4; Int; Integer)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(5; Dec; Decimal)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(6; Big; BigInteger)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(7; Bool; Boolean)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(8; D; Date)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(9; T; Time)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(10; DT; DateTime)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(11; Opt; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;

            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(12; En; Enum "LT Y67 FV Kind")
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(13; G; Guid)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(14; Dur; Duration)
        {
            trigger OnValidate()
            begin
                Hits += 1;
            end;
        }
        field(15; Hits; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93631 "LT Y67 FV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var FRef: FieldRef; V: Variant)
    begin
        FRef.Validate(V);
    end;

    [TryFunction]
    local procedure TryAssign(var FRef: FieldRef; V: Variant)
    begin
        FRef.Value := V;
    end;

    local procedure Source(Index: Integer; var V: Variant; var Name: Text)
    var
        Big: BigInteger;
        Cd: Code[10];
        Op: Option Alpha,Beta,Gamma;
        Kind: Enum "LT Y67 FV Kind";
        Gd: Guid;
        Du: Duration;
    begin
        case Index of
            1:
                begin
                V := 42;
                Name := 'integer 42';
                end;
            2:
                begin
                V := -3;
                Name := 'integer -3';
                end;
            3:
                begin
                V := 2.5;
                Name := 'decimal 2.5';
                end;
            4:
                begin
                Evaluate(Big, '5000000000');
                V := Big;
                Name := 'biginteger';
                end;
            5:
                begin
                V := true;
                Name := 'boolean true';
                end;
            6:
                begin
                V := 20260115D;
                Name := 'date 20260115D';
                end;
            7:
                begin
                V := 120000T;
                Name := 'time 120000T';
                end;
            8:
                begin
                V := CreateDateTime(20260115D, 120000T);
                Name := 'datetime';
                end;
            9:
                begin
                V := '42';
                Name := 'text 42';
                end;
            10:
                begin
                V := 'abc';
                Name := 'text abc';
                end;
            11:
                begin
                Cd := 'C1';
                V := Cd;
                Name := 'code C1';
                end;
            12:
                begin
                Op := Op::Beta;
                V := Op;
                Name := 'option 1';
                end;
            13:
                begin
                V := Kind::Two;
                Name := 'enum Two';
                end;
            14:
                begin
                Gd := '{12345678-1234-1234-1234-123456789012}';
                V := Gd;
                Name := 'guid';
                end;
            15:
                begin
                Du := 1500;
                V := Du;
                Name := 'duration 1500';
                end;
            16:
                begin
                V := '';
                Name := 'text empty';
                end;
        end;
    end;

    // The long fixed tails and namespace prefixes of the texts are written as tags so that an observation stays short.
    local procedure Short(ErrText: Text): Text
    begin
        ErrText := ErrText.Replace('Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.', '<datehelp>');
        ErrText := ErrText.Replace('Microsoft.Dynamics.Nav.Runtime.', '<ns>');
        exit(ErrText);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Index: Integer)
    var
        Row: Record "LT Y67 FV Row";
        RecRef: RecordRef;
        FRef: FieldRef;
        V: Variant;
        Name: Text;
        Result: Text;
    begin
        Source(Index, V, Name);
        RecRef.GetTable(Row);
        FRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TryValidate(FRef, V) then
            Result := 'validate=' + Format(FRef.Value, 0, 9) + ' hits=' + Format(RecRef.Field(15).Value, 0, 9)
        else
            Result := 'validate error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Clear(Row);
        RecRef.GetTable(Row);
        FRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TryAssign(FRef, V) then
            Result += ' ; assign=' + Format(FRef.Value, 0, 9) + ' hits=' + Format(RecRef.Field(15).Value, 0, 9)
        else
            Result += ' ; assign error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Observer.Observe(Name, Result);
    end;

    local procedure Into(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; First: Integer; Last: Integer)
    var
        i: Integer;
    begin
        for i := First to Last do
            Cell(Observer, FieldNo, i);
    end;

    [Test]
    procedure Validate_Into_Txt_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Txt_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Cod_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Cod_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Int_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Int_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Dec_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Dec_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Big_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Big_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Bool_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Bool_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_D_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_D_B1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_D_B2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_T_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_T_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_DT_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_DT_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Opt_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Opt_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_En_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 12, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_En_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 12, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_G_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_G_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 9, 16);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Dur_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 1, 8);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Into_Dur_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 9, 16);
        Observer.Finish();
    end;

}
