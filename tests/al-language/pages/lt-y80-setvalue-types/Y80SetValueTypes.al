// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94223, pages 94224 and 94225, test codeunit 94226
// Probe (writer Y80, from the runtime lane rt-pages-1102c): TestPage control SetValue of a value that is not a Text, on a control bound to a Text, a Code and a short
//   Text[5] field: Integer (small, negative, zero, with a thousands separator, large), BigInteger, whole and fractional Decimal, Boolean, Date,
//   Time, DateTime, Guid, Duration, an Option and an Enum value, a Char. Read back with Value() (and the stored row after Close). On a Card and on
//   a List (repeater) page. pages/lt-y37-values-allowed and misc/lt-y14-triage/Y14Small.al:237 pin SetValue(Decimal) 1.11 on a Text control only.
//   Formats are those of en-US (the corpus runs with that culture).
// BC versions: 27, 28, 29

enum 94227 "LT Y80 SV Kind"
{
    Extensible = true;

    value(0; First) { Caption = 'First Kind'; }
    value(1; Second) { Caption = 'Second Kind'; }
}

table 94223 "LT Y80 SV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[20]) { }
        field(4; Short; Text[5]) { }
        field(5; Num; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 94224 "LT Y80 SV Card"
{
    PageType = Card;
    SourceTable = "LT Y80 SV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            field(CdCtl; Rec.Cd) { ApplicationArea = All; }
            field(ShortCtl; Rec.Short) { ApplicationArea = All; }
            field(NumCtl; Rec.Num) { ApplicationArea = All; }
        }
    }
}

page 94225 "LT Y80 SV List"
{
    PageType = List;
    SourceTable = "LT Y80 SV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(CdCtl; Rec.Cd) { ApplicationArea = All; }
                field(ShortCtl; Rec.Short) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 94226 "LT Y80 SV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y80 SV Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryCardTxtCtl(var P: TestPage "LT Y80 SV Card"; V: Variant)
    begin
        P.TxtCtl.SetValue(V);
    end;

    local procedure SetCardTxtCtl(var P: TestPage "LT Y80 SV Card"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryCardTxtCtl(P, V) then
            Result := 'ok|' + P.TxtCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryCardCdCtl(var P: TestPage "LT Y80 SV Card"; V: Variant)
    begin
        P.CdCtl.SetValue(V);
    end;

    local procedure SetCardCdCtl(var P: TestPage "LT Y80 SV Card"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryCardCdCtl(P, V) then
            Result := 'ok|' + P.CdCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryCardShortCtl(var P: TestPage "LT Y80 SV Card"; V: Variant)
    begin
        P.ShortCtl.SetValue(V);
    end;

    local procedure SetCardShortCtl(var P: TestPage "LT Y80 SV Card"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryCardShortCtl(P, V) then
            Result := 'ok|' + P.ShortCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListTxtCtl(var P: TestPage "LT Y80 SV List"; V: Variant)
    begin
        P.TxtCtl.SetValue(V);
    end;

    local procedure SetListTxtCtl(var P: TestPage "LT Y80 SV List"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryListTxtCtl(P, V) then
            Result := 'ok|' + P.TxtCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListCdCtl(var P: TestPage "LT Y80 SV List"; V: Variant)
    begin
        P.CdCtl.SetValue(V);
    end;

    local procedure SetListCdCtl(var P: TestPage "LT Y80 SV List"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryListCdCtl(P, V) then
            Result := 'ok|' + P.CdCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListShortCtl(var P: TestPage "LT Y80 SV List"; V: Variant)
    begin
        P.ShortCtl.SetValue(V);
    end;

    local procedure SetListShortCtl(var P: TestPage "LT Y80 SV List"; V: Variant): Text
    var
        Result: Text;
    begin
        if TryListShortCtl(P, V) then
            Result := 'ok|' + P.ShortCtl.Value()
        else begin
            Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
            ClearLastError();
        end;
        exit(Result);
    end;

    [Test]
    procedure Y80_SV_Card_TxtCtl_Integers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetCardTxtCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetCardTxtCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetCardTxtCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetCardTxtCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetCardTxtCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetCardTxtCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetCardTxtCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetCardTxtCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_TxtCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetCardTxtCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetCardTxtCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetCardTxtCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetCardTxtCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetCardTxtCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_TxtCtl_Decimals()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetCardTxtCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetCardTxtCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetCardTxtCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetCardTxtCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetCardTxtCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetCardTxtCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetCardTxtCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetCardTxtCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_TxtCtl_Others()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetCardTxtCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetCardTxtCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetCardTxtCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetCardTxtCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetCardTxtCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetCardTxtCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetCardTxtCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetCardTxtCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetCardTxtCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetCardTxtCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_TxtCtl_Enums()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetCardTxtCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetCardTxtCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetCardTxtCtl(P, En));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_CdCtl_Integers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetCardCdCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetCardCdCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetCardCdCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetCardCdCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetCardCdCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetCardCdCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetCardCdCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetCardCdCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_CdCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetCardCdCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetCardCdCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetCardCdCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetCardCdCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetCardCdCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_CdCtl_Decimals()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetCardCdCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetCardCdCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetCardCdCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetCardCdCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetCardCdCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetCardCdCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetCardCdCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetCardCdCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_CdCtl_Others()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetCardCdCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetCardCdCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetCardCdCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetCardCdCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetCardCdCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetCardCdCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetCardCdCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetCardCdCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetCardCdCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetCardCdCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_CdCtl_Enums()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetCardCdCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetCardCdCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetCardCdCtl(P, En));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_ShortCtl_Integers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetCardShortCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetCardShortCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetCardShortCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetCardShortCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetCardShortCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetCardShortCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetCardShortCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetCardShortCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_ShortCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetCardShortCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetCardShortCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetCardShortCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetCardShortCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetCardShortCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_ShortCtl_Decimals()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetCardShortCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetCardShortCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetCardShortCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetCardShortCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetCardShortCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetCardShortCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetCardShortCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetCardShortCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_ShortCtl_Others()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetCardShortCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetCardShortCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetCardShortCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetCardShortCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetCardShortCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetCardShortCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetCardShortCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetCardShortCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetCardShortCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetCardShortCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_Card_ShortCtl_Enums()
    var
        P: TestPage "LT Y80 SV Card";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetCardShortCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetCardShortCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetCardShortCtl(P, En));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_TxtCtl_Integers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetListTxtCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetListTxtCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetListTxtCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetListTxtCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetListTxtCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetListTxtCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetListTxtCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetListTxtCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_TxtCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetListTxtCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetListTxtCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetListTxtCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetListTxtCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetListTxtCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_TxtCtl_Decimals()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetListTxtCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetListTxtCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetListTxtCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetListTxtCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetListTxtCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetListTxtCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetListTxtCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetListTxtCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_TxtCtl_Others()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetListTxtCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetListTxtCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetListTxtCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetListTxtCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetListTxtCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetListTxtCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetListTxtCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetListTxtCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetListTxtCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetListTxtCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_TxtCtl_Enums()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetListTxtCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetListTxtCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetListTxtCtl(P, En));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_CdCtl_Integers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetListCdCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetListCdCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetListCdCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetListCdCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetListCdCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetListCdCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetListCdCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetListCdCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_CdCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetListCdCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetListCdCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetListCdCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetListCdCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetListCdCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_CdCtl_Decimals()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetListCdCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetListCdCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetListCdCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetListCdCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetListCdCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetListCdCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetListCdCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetListCdCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_CdCtl_Others()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetListCdCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetListCdCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetListCdCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetListCdCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetListCdCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetListCdCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetListCdCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetListCdCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetListCdCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetListCdCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_CdCtl_Enums()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetListCdCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetListCdCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetListCdCtl(P, En));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_ShortCtl_Integers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        I := 5;
        Observer.Observe('int 5', SetListShortCtl(P, I));
        I := -7;
        Observer.Observe('int -7', SetListShortCtl(P, I));
        I := 0;
        Observer.Observe('int 0', SetListShortCtl(P, I));
        I := 999;
        Observer.Observe('int 999', SetListShortCtl(P, I));
        I := 1000;
        Observer.Observe('int 1000', SetListShortCtl(P, I));
        I := 1234;
        Observer.Observe('int 1234', SetListShortCtl(P, I));
        I := 1234567;
        Observer.Observe('int 1234567', SetListShortCtl(P, I));
        I := 2147483647;
        Observer.Observe('int max', SetListShortCtl(P, I));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_ShortCtl_BigIntegers()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        B := 5;
        Observer.Observe('big 5', SetListShortCtl(P, B));
        B := -12;
        Observer.Observe('big -12', SetListShortCtl(P, B));
        B := 1000;
        Observer.Observe('big 1000', SetListShortCtl(P, B));
        B := 5000000000;
        Observer.Observe('big 5000000000', SetListShortCtl(P, B));
        B := 0;
        Observer.Observe('big 0', SetListShortCtl(P, B));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_ShortCtl_Decimals()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        D := 3;
        Observer.Observe('dec 3', SetListShortCtl(P, D));
        D := -3;
        Observer.Observe('dec -3', SetListShortCtl(P, D));
        D := 1.5;
        Observer.Observe('dec 1.5', SetListShortCtl(P, D));
        D := 1234;
        Observer.Observe('dec 1234', SetListShortCtl(P, D));
        D := 1234.5;
        Observer.Observe('dec 1234.5', SetListShortCtl(P, D));
        D := 0.00001;
        Observer.Observe('dec 0.00001', SetListShortCtl(P, D));
        D := 0;
        Observer.Observe('dec 0', SetListShortCtl(P, D));
        D := 100000;
        Observer.Observe('dec 100000', SetListShortCtl(P, D));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_ShortCtl_Others()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Bo := true;
        Observer.Observe('bool true', SetListShortCtl(P, Bo));
        Bo := false;
        Observer.Observe('bool false', SetListShortCtl(P, Bo));
        Dt := 20250131D;
        Observer.Observe('date', SetListShortCtl(P, Dt));
        Tm := 143005T;
        Observer.Observe('time', SetListShortCtl(P, Tm));
        Dtm := CreateDateTime(20250131D, 143005T);
        Observer.Observe('datetime', SetListShortCtl(P, Dtm));
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('guid', SetListShortCtl(P, G));
        Du := 90000;
        Observer.Observe('duration', SetListShortCtl(P, Du));
        Ch := 65;
        Observer.Observe('char', SetListShortCtl(P, Ch));
        Tx := 'x1';
        Observer.Observe('text', SetListShortCtl(P, Tx));
        Co := 'ab';
        Observer.Observe('code', SetListShortCtl(P, Co));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_List_ShortCtl_Enums()
    var
        P: TestPage "LT Y80 SV List";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        Dt: Date;
        Tm: Time;
        Dtm: DateTime;
        G: Guid;
        Du: Duration;
        Ch: Char;
        Tx: Text;
        Co: Code[10];
        Op: Option A,B,C;
        En: Enum "LT Y80 SV Kind";
    begin
        Seed();
        P.OpenEdit();
        Op := Op::B;
        Observer.Observe('option', SetListShortCtl(P, Op));
        En := En::First;
        Observer.Observe('enum first', SetListShortCtl(P, En));
        En := En::Second;
        Observer.Observe('enum second', SetListShortCtl(P, En));
        P.Close();
        Observer.Finish();
    end;
}
