// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: self-contained (table 70738, enum 70739, codeunit 70740); used by the P96 test codeunits; Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own table with one field of each TestField value type, and try-helpers that return the outcome text of Record and FieldRef calls
// BC versions: 29 (27 and 28 by CI)

table 70738 "LT P96 Rec"
{
    DataClassification = SystemMetadata;
    Caption = 'P96 Rec Caption';

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code Cap'; }
        field(2; Txt; Text[10]) { Caption = 'Txt Cap'; }
        field(3; Cd; Code[10]) { Caption = 'Cd Cap'; }
        field(4; Num; Integer) { Caption = 'Num Cap'; }
        field(5; Big; BigInteger) { Caption = 'Big Cap'; }
        field(6; Amt; Decimal) { Caption = 'Amt Cap'; }
        field(7; Flag; Boolean) { Caption = 'Flag Cap'; }
        field(8; Dt; Date) { Caption = 'Dt Cap'; }
        field(9; Tm; Time) { Caption = 'Tm Cap'; }
        field(10; Dtm; DateTime) { Caption = 'Dtm Cap'; }
        field(11; Gd; Guid) { Caption = 'Gd Cap'; }
        field(12; Kind; Enum "LT P96 Kind") { Caption = 'Kind Cap'; }
        field(13; Opt; Option) { Caption = 'Opt Cap'; OptionMembers = Alpha,Beta,Gamma; }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

enum 70739 "LT P96 Kind"
{
    Extensible = true;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
}

codeunit 70740 "LT P96 Helper"
{
    var
        LblMatch: Label 'Hello', Locked = true;
        LblDiff: Label 'Other', Locked = true;
        LblEmpty: Label '', Locked = true;

    // Row K1: every field filled. Row E1: every field empty (the default).
    procedure Seed()
    var
        Rec: Record "LT P96 Rec";
        Big: BigInteger;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Code := 'K1';
        Rec.Txt := 'Hello';
        Rec.Cd := 'ABC';
        Rec.Num := 5;
        Big := 2147483647;
        Big := Big * 4;
        Rec.Big := Big;
        Rec.Amt := 2.5;
        Rec.Flag := true;
        Rec.Dt := DMY2Date(15, 6, 2021);
        Rec.Tm := 123000T;
        Rec.Dtm := CreateDateTime(DMY2Date(15, 6, 2021), 123000T);
        Evaluate(Rec.Gd, '{11111111-2222-3333-4444-555555555555}');
        Rec.Kind := Rec.Kind::Two;
        Rec.Opt := Rec.Opt::Beta;
        Rec.Insert();
        Rec.Init();
        Rec.Code := 'E1';
        Rec.Insert();
    end;

    procedure ObservePair(var Observer: Codeunit "Probe Observer"; Name: Text; R1: Text; R2: Text)
    begin
        Observer.Observe('rec_' + Name, R1);
        Observer.Observe('ref_' + Name, R2);
        Observer.Observe('same_' + Name, Format(R1 = R2));
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // ---------------- Record side, value overloads ----------------

    [TryFunction]
    local procedure TryRecT(var Rec: Record "LT P96 Rec"; No: Integer; V: Text)
    begin
        case No of
            1:
                Rec.TestField(Code, V);
            2:
                Rec.TestField(Txt, V);
            3:
                Rec.TestField(Cd, V);
        end;
    end;

    procedure RecT(var Rec: Record "LT P96 Rec"; No: Integer; V: Text): Text
    begin
        exit(Outcome(TryRecT(Rec, No, V)));
    end;

    [TryFunction]
    local procedure TryRecC(var Rec: Record "LT P96 Rec"; No: Integer; V: Code[20])
    begin
        case No of
            1:
                Rec.TestField(Code, V);
            2:
                Rec.TestField(Txt, V);
            3:
                Rec.TestField(Cd, V);
        end;
    end;

    procedure RecC(var Rec: Record "LT P96 Rec"; No: Integer; V: Code[20]): Text
    begin
        exit(Outcome(TryRecC(Rec, No, V)));
    end;

    [TryFunction]
    local procedure TryRecL(var Rec: Record "LT P96 Rec"; No: Integer; Which: Integer)
    begin
        case No of
            2:
                case Which of
                    1:
                        Rec.TestField(Txt, LblMatch);
                    2:
                        Rec.TestField(Txt, LblDiff);
                    3:
                        Rec.TestField(Txt, LblEmpty);
                end;
            3:
                case Which of
                    1:
                        Rec.TestField(Cd, LblMatch);
                    2:
                        Rec.TestField(Cd, LblDiff);
                    3:
                        Rec.TestField(Cd, LblEmpty);
                end;
        end;
    end;

    procedure RecL(var Rec: Record "LT P96 Rec"; No: Integer; Which: Integer): Text
    begin
        exit(Outcome(TryRecL(Rec, No, Which)));
    end;

    [TryFunction]
    local procedure TryRecI(var Rec: Record "LT P96 Rec"; No: Integer; V: Integer)
    begin
        case No of
            4:
                Rec.TestField(Num, V);
            13:
                Rec.TestField(Opt, V);
        end;
    end;

    procedure RecI(var Rec: Record "LT P96 Rec"; No: Integer; V: Integer): Text
    begin
        exit(Outcome(TryRecI(Rec, No, V)));
    end;

    [TryFunction]
    local procedure TryRecBig(var Rec: Record "LT P96 Rec"; V: BigInteger)
    begin
        Rec.TestField(Big, V);
    end;

    procedure RecBig(var Rec: Record "LT P96 Rec"; V: BigInteger): Text
    begin
        exit(Outcome(TryRecBig(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecD(var Rec: Record "LT P96 Rec"; No: Integer; V: Decimal)
    begin
        case No of
            4:
                Rec.TestField(Num, V);
            6:
                Rec.TestField(Amt, V);
        end;
    end;

    procedure RecD(var Rec: Record "LT P96 Rec"; No: Integer; V: Decimal): Text
    begin
        exit(Outcome(TryRecD(Rec, No, V)));
    end;

    [TryFunction]
    local procedure TryRecBool(var Rec: Record "LT P96 Rec"; V: Boolean)
    begin
        Rec.TestField(Flag, V);
    end;

    procedure RecBool(var Rec: Record "LT P96 Rec"; V: Boolean): Text
    begin
        exit(Outcome(TryRecBool(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecDate(var Rec: Record "LT P96 Rec"; V: Date)
    begin
        Rec.TestField(Dt, V);
    end;

    procedure RecDate(var Rec: Record "LT P96 Rec"; V: Date): Text
    begin
        exit(Outcome(TryRecDate(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecTime(var Rec: Record "LT P96 Rec"; V: Time)
    begin
        Rec.TestField(Tm, V);
    end;

    procedure RecTime(var Rec: Record "LT P96 Rec"; V: Time): Text
    begin
        exit(Outcome(TryRecTime(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecDtm(var Rec: Record "LT P96 Rec"; V: DateTime)
    begin
        Rec.TestField(Dtm, V);
    end;

    procedure RecDtm(var Rec: Record "LT P96 Rec"; V: DateTime): Text
    begin
        exit(Outcome(TryRecDtm(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecGuid(var Rec: Record "LT P96 Rec"; V: Guid)
    begin
        Rec.TestField(Gd, V);
    end;

    procedure RecGuid(var Rec: Record "LT P96 Rec"; V: Guid): Text
    begin
        exit(Outcome(TryRecGuid(Rec, V)));
    end;

    [TryFunction]
    local procedure TryRecEnum(var Rec: Record "LT P96 Rec"; V: Enum "LT P96 Kind")
    begin
        Rec.TestField(Kind, V);
    end;

    procedure RecEnum(var Rec: Record "LT P96 Rec"; V: Enum "LT P96 Kind"): Text
    begin
        exit(Outcome(TryRecEnum(Rec, V)));
    end;

    // Which: 1 Alpha, 2 Beta, 3 Gamma (the option members written as literals)
    [TryFunction]
    local procedure TryRecOptMember(var Rec: Record "LT P96 Rec"; Which: Integer)
    begin
        case Which of
            1:
                Rec.TestField(Opt, Rec.Opt::Alpha);
            2:
                Rec.TestField(Opt, Rec.Opt::Beta);
            3:
                Rec.TestField(Opt, Rec.Opt::Gamma);
        end;
    end;

    procedure RecOptMember(var Rec: Record "LT P96 Rec"; Which: Integer): Text
    begin
        exit(Outcome(TryRecOptMember(Rec, Which)));
    end;

    // ---------------- Record side, no value ----------------

    [TryFunction]
    local procedure TryRecNoValue(var Rec: Record "LT P96 Rec"; No: Integer)
    begin
        case No of
            1:
                Rec.TestField(Code);
            2:
                Rec.TestField(Txt);
            3:
                Rec.TestField(Cd);
            4:
                Rec.TestField(Num);
            5:
                Rec.TestField(Big);
            6:
                Rec.TestField(Amt);
            7:
                Rec.TestField(Flag);
            8:
                Rec.TestField(Dt);
            9:
                Rec.TestField(Tm);
            10:
                Rec.TestField(Dtm);
            11:
                Rec.TestField(Gd);
            12:
                Rec.TestField(Kind);
            13:
                Rec.TestField(Opt);
        end;
    end;

    procedure RecNoValue(var Rec: Record "LT P96 Rec"; No: Integer): Text
    begin
        exit(Outcome(TryRecNoValue(Rec, No)));
    end;

    // ---------------- Record side, ErrorInfo overloads ----------------
    // Mode: 1 Message set, 2 Message empty, 3 Title set, 4 DetailedMessage set, 5 Message + Title + DetailedMessage

    local procedure MakeInfo(Mode: Integer; var Info: ErrorInfo)
    begin
        case Mode of
            1:
                Info.Message := 'Custom message';
            3:
                Info.Title := 'Custom title';
            4:
                Info.DetailedMessage := 'Custom detail';
            5:
                begin
                    Info.Message := 'Custom message';
                    Info.Title := 'Custom title';
                    Info.DetailedMessage := 'Custom detail';
                end;
        end;
    end;

    [TryFunction]
    local procedure TryRecInfoNoValue(var Rec: Record "LT P96 Rec"; No: Integer; Mode: Integer)
    var
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        case No of
            2:
                Rec.TestField(Txt, Info);
            4:
                Rec.TestField(Num, Info);
            8:
                Rec.TestField(Dt, Info);
            12:
                Rec.TestField(Kind, Info);
            13:
                Rec.TestField(Opt, Info);
        end;
    end;

    procedure RecInfoNoValue(var Rec: Record "LT P96 Rec"; No: Integer; Mode: Integer): Text
    begin
        exit(Outcome(TryRecInfoNoValue(Rec, No, Mode)));
    end;

    [TryFunction]
    local procedure TryRecInfoT(var Rec: Record "LT P96 Rec"; No: Integer; V: Text; Mode: Integer)
    var
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        case No of
            1:
                Rec.TestField(Code, V, Info);
            2:
                Rec.TestField(Txt, V, Info);
            3:
                Rec.TestField(Cd, V, Info);
        end;
    end;

    procedure RecInfoT(var Rec: Record "LT P96 Rec"; No: Integer; V: Text; Mode: Integer): Text
    begin
        exit(Outcome(TryRecInfoT(Rec, No, V, Mode)));
    end;

    [TryFunction]
    local procedure TryRecInfoV(var Rec: Record "LT P96 Rec"; Which: Integer; Mode: Integer)
    var
        Info: ErrorInfo;
        BigVal: BigInteger;
        G: Guid;
    begin
        MakeInfo(Mode, Info);
        case Which of
            1:
                Rec.TestField(Num, 99, Info);
            2:
                begin
                    BigVal := 7;
                    Rec.TestField(Big, BigVal, Info);
                end;
            3:
                Rec.TestField(Amt, 9.5, Info);
            4:
                Rec.TestField(Flag, false, Info);
            5:
                Rec.TestField(Dt, DMY2Date(1, 1, 2000), Info);
            6:
                Rec.TestField(Tm, 010000T, Info);
            7:
                Rec.TestField(Dtm, CreateDateTime(DMY2Date(1, 1, 2000), 010000T), Info);
            8:
                begin
                    Evaluate(G, '{99999999-2222-3333-4444-555555555555}');
                    Rec.TestField(Gd, G, Info);
                end;
            9:
                Rec.TestField(Kind, Rec.Kind::Zero, Info);
            10:
                Rec.TestField(Opt, Rec.Opt::Gamma, Info);
        end;
    end;

    procedure RecInfoV(var Rec: Record "LT P96 Rec"; Which: Integer; Mode: Integer): Text
    begin
        exit(Outcome(TryRecInfoV(Rec, Which, Mode)));
    end;

    // ---------------- Record side, FieldError ----------------
    // Kind: 1 FieldError(Field), 2 FieldError(Field, Text), 3 FieldError(Field, ErrorInfo)

    [TryFunction]
    local procedure TryRecFieldError(var Rec: Record "LT P96 Rec"; No: Integer; Form: Integer; Msg: Text; Mode: Integer)
    var
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        case No of
            1:
                case Form of
                    1:
                        Rec.FieldError(Code);
                    2:
                        Rec.FieldError(Code, Msg);
                    3:
                        Rec.FieldError(Code, Info);
                end;
            2:
                case Form of
                    1:
                        Rec.FieldError(Txt);
                    2:
                        Rec.FieldError(Txt, Msg);
                    3:
                        Rec.FieldError(Txt, Info);
                end;
            4:
                case Form of
                    1:
                        Rec.FieldError(Num);
                    2:
                        Rec.FieldError(Num, Msg);
                    3:
                        Rec.FieldError(Num, Info);
                end;
            6:
                case Form of
                    1:
                        Rec.FieldError(Amt);
                    2:
                        Rec.FieldError(Amt, Msg);
                    3:
                        Rec.FieldError(Amt, Info);
                end;
            7:
                case Form of
                    1:
                        Rec.FieldError(Flag);
                    2:
                        Rec.FieldError(Flag, Msg);
                    3:
                        Rec.FieldError(Flag, Info);
                end;
            8:
                case Form of
                    1:
                        Rec.FieldError(Dt);
                    2:
                        Rec.FieldError(Dt, Msg);
                    3:
                        Rec.FieldError(Dt, Info);
                end;
            12:
                case Form of
                    1:
                        Rec.FieldError(Kind);
                    2:
                        Rec.FieldError(Kind, Msg);
                    3:
                        Rec.FieldError(Kind, Info);
                end;
            13:
                case Form of
                    1:
                        Rec.FieldError(Opt);
                    2:
                        Rec.FieldError(Opt, Msg);
                    3:
                        Rec.FieldError(Opt, Info);
                end;
        end;
    end;

    procedure RecFieldError(var Rec: Record "LT P96 Rec"; No: Integer; Form: Integer; Msg: Text; Mode: Integer): Text
    begin
        exit(Outcome(TryRecFieldError(Rec, No, Form, Msg, Mode)));
    end;

    // ---------------- FieldRef side ----------------

    [TryFunction]
    local procedure TryRefNoValue(var Rec: Record "LT P96 Rec"; No: Integer)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(No);
        Fld.TestField();
    end;

    procedure RefNoValue(var Rec: Record "LT P96 Rec"; No: Integer): Text
    begin
        exit(Outcome(TryRefNoValue(Rec, No)));
    end;

    [TryFunction]
    local procedure TryRefV(var Rec: Record "LT P96 Rec"; No: Integer; V: Variant)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(No);
        Fld.TestField(V);
    end;

    procedure RefV(var Rec: Record "LT P96 Rec"; No: Integer; V: Variant): Text
    begin
        exit(Outcome(TryRefV(Rec, No, V)));
    end;

    [TryFunction]
    local procedure TryRefInfoNoValue(var Rec: Record "LT P96 Rec"; No: Integer; Mode: Integer)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(No);
        Fld.TestField(Info);
    end;

    procedure RefInfoNoValue(var Rec: Record "LT P96 Rec"; No: Integer; Mode: Integer): Text
    begin
        exit(Outcome(TryRefInfoNoValue(Rec, No, Mode)));
    end;

    [TryFunction]
    local procedure TryRefInfoV(var Rec: Record "LT P96 Rec"; No: Integer; V: Variant; Mode: Integer)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(No);
        Fld.TestField(V, Info);
    end;

    procedure RefInfoV(var Rec: Record "LT P96 Rec"; No: Integer; V: Variant; Mode: Integer): Text
    begin
        exit(Outcome(TryRefInfoV(Rec, No, V, Mode)));
    end;

    [TryFunction]
    local procedure TryRefFieldError(var Rec: Record "LT P96 Rec"; No: Integer; Form: Integer; Msg: Text; Mode: Integer)
    var
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
    begin
        MakeInfo(Mode, Info);
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(No);
        case Form of
            1:
                Fld.FieldError();
            2:
                Fld.FieldError(Msg);
            3:
                Fld.FieldError(Info);
        end;
    end;

    procedure RefFieldError(var Rec: Record "LT P96 Rec"; No: Integer; Form: Integer; Msg: Text; Mode: Integer): Text
    begin
        exit(Outcome(TryRefFieldError(Rec, No, Form, Msg, Mode)));
    end;
}
