// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 93630 "LT Y67 FV Row" and enum 93632 "LT Y67 FV Kind" of
//   recordref-fieldref/fieldref/Y67FieldRefValidateVariant.al (one field of each type, each OnValidate counts Hits)
// Probe: Record.Validate(Field, V) and Rec.Field := V with a Variant V that holds an Integer, a Decimal, a BigInteger, a Boolean, a Date,
//   a Time, a DateTime, a Text (a number, other text, empty), a Code, an Option, an Enum, a Guid or a Duration, into a field of each type
//   (Text, Code, Integer, Decimal, BigInteger, Boolean, Date, Time, DateTime, Option, Guid, Duration). An Enum field
//   is left out: Record.Validate(EnumField, Variant) and EnumField := Variant do not compile (AL0193, AL0122). The same matrix as the
//   FieldRef one in Y67FieldRefValidateVariant.al, through the record. Per cell: the value of the field (Format(.., 0, 9)) and how many
//   times its OnValidate ran after Validate, and the value after the assignment; or the error text and code.
//   Asked by al-runner issue 6975 (Validate of a Text field with a Variant that holds an Enum).
// BC versions: 27, 28, 29

codeunit 95786 "REC Validate Variant Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Row: Record "LT Y67 FV Row"; FieldNo: Integer; V: Variant)
    begin
        case FieldNo of
            2:
                Row.Validate(Txt, V);
            3:
                Row.Validate(Cod, V);
            4:
                Row.Validate(Int, V);
            5:
                Row.Validate(Dec, V);
            6:
                Row.Validate(Big, V);
            7:
                Row.Validate(Bool, V);
            8:
                Row.Validate(D, V);
            9:
                Row.Validate(T, V);
            10:
                Row.Validate(DT, V);
            11:
                Row.Validate(Opt, V);
            13:
                Row.Validate(G, V);
            14:
                Row.Validate(Dur, V);
        end;
    end;

    [TryFunction]
    local procedure TryAssign(var Row: Record "LT Y67 FV Row"; FieldNo: Integer; V: Variant)
    begin
        case FieldNo of
            2:
                Row.Txt := V;
            3:
                Row.Cod := V;
            4:
                Row.Int := V;
            5:
                Row.Dec := V;
            6:
                Row.Big := V;
            7:
                Row.Bool := V;
            8:
                Row.D := V;
            9:
                Row.T := V;
            10:
                Row.DT := V;
            11:
                Row.Opt := V;
            13:
                Row.G := V;
            14:
                Row.Dur := V;
        end;
    end;

    local procedure Value(var Row: Record "LT Y67 FV Row"; FieldNo: Integer): Text
    begin
        case FieldNo of
            2:
                exit(Format(Row.Txt, 0, 9));
            3:
                exit(Format(Row.Cod, 0, 9));
            4:
                exit(Format(Row.Int, 0, 9));
            5:
                exit(Format(Row.Dec, 0, 9));
            6:
                exit(Format(Row.Big, 0, 9));
            7:
                exit(Format(Row.Bool, 0, 9));
            8:
                exit(Format(Row.D, 0, 9));
            9:
                exit(Format(Row.T, 0, 9));
            10:
                exit(Format(Row.DT, 0, 9));
            11:
                exit(Format(Row.Opt, 0, 9));
            13:
                exit(Format(Row.G, 0, 9));
            14:
                exit(Format(Row.Dur, 0, 9));
        end;
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
        V: Variant;
        Name: Text;
        Result: Text;
    begin
        Source(Index, V, Name);
        ClearLastError();
        if TryValidate(Row, FieldNo, V) then
            Result := 'validate=' + Value(Row, FieldNo) + ' hits=' + Format(Row.Hits, 0, 9)
        else
            Result := 'validate error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
        Clear(Row);
        ClearLastError();
        if TryAssign(Row, FieldNo, V) then
            Result += ' ; assign=' + Value(Row, FieldNo) + ' hits=' + Format(Row.Hits, 0, 9)
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
    procedure RecordValidate_Into_Txt_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Txt_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Txt_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Txt_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 2, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Cod_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Cod_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Cod_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Cod_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 3, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Int_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Int_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Int_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Int_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 4, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dec_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dec_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dec_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dec_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 5, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Big_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Big_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Big_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Big_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 6, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Bool_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Bool_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Bool_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Bool_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 7, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_D_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_D_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_D_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_D_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 8, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_T_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_T_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_T_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_T_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 9, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_DT_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_DT_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_DT_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_DT_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 10, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Opt_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Opt_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Opt_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Opt_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 11, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_G_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_G_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_G_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_G_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 13, 13, 16);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dur_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dur_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 5, 8);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dur_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 9, 12);
        Observer.Finish();
    end;

    [Test]
    procedure RecordValidate_Into_Dur_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 14, 13, 16);
        Observer.Finish();
    end;
}
