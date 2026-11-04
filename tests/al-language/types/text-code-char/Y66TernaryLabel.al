// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93500, test codeunit 93504
// Probe (al-runner issue 6659, writer Y66): a conditional expression with a Label branch against a table field (Text[100], Code[10], Guid),
// a Text[3], Code[3], Code[250] or Text variable or another Label, in both orders, with a Label that has MaxLength = 100 and one
// without. Each pair is read true and false into a Text, a Text[100], a Text[5] and a Code[20], with StrLen, Format and the kind of a
// Variant; an error is [E text|code]. A Guid pair is read into a Text and a Text[100] only (a shorter target is AL0777).
// Char : Label does not compile (AL0122, compile-matrix.csv). Also the reporter's table procedure (field empty and filled).
// Pinned elsewhere: Text/Text10/Code10/Guid/Char variables against a Label (types/lt-y31-conversion-matrix/Y31ConvCd.al), Code20/Text10/
// Label/literal pairs (types/TestTernaryContracts.al TI_*), Locked/MaxLength/TextConst (TestTernaryContracts.al QW_*); which type pairs
// compile: scripts/conversion-matrix/compile-matrix.csv row cond_branches,Label (a Label against a Variant is AL0122).
// BC versions: 27, 28, 29

table 93500 "LT Y66 TL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "My Text Field"; Text[100]) { }
        field(3; "My Code"; Code[10]) { }
        field(4; "My Guid"; Guid) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    procedure MyProc() Result: Text[100]
    var
        DefaultLbl: Label 'Default text', MaxLength = 100;
        BaseText: Text[100];
    begin
        BaseText := (Rec."My Text Field" <> '') ? Rec."My Text Field" : DefaultLbl;
        exit(BaseText);
    end;
}

codeunit 93504 "LT Y66 Ternary Label"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y66 TL Row";
        T3: Text[3];
        C3: Code[3];
        C250: Code[250];
        Txt: Text;
        DefaultLbl: Label 'Default text', MaxLength = 100;
        PlainLbl: Label 'plain lbl';

    [Test]
    procedure Y66_Ternary_ReporterShape()
    var
        R: Record "LT Y66 TL Row";
    begin
        Observer.Observe('empty', '[' + R.MyProc() + '|' + Format(StrLen(R.MyProc())) + ']');
        R."My Text Field" := 'Field text';
        Observer.Observe('filled', '[' + R.MyProc() + ']');
        Observer.Expect('empty', '[Default text|12]');
        Observer.Expect('filled', '[Field text]');
        Observer.Verify();
    end;

    // FText100 : LblMax
    [Test]
    procedure Y66_Ternary_Pair_1()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('FText100 : LblMax ' + Format(I = 1), Pair1(I = 1));
        Observer.Expect('FText100 : LblMax Yes', '[Field text value|16][Field text value|16][E The length of the string is 16, but it must be less than or equal to 5 characters. Value: Field text value|StringLengthExceeded][FIELD TEXT VALUE|16][16][Field text value][Text]');
        Observer.Expect('FText100 : LblMax No', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][Text]');
        Observer.Verify();
    end;

    local procedure Pair1(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair1Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair1Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair1Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? Row."My Text Field" : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair1Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? Row."My Text Field" : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? Row."My Text Field" : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? Row."My Text Field" : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? Row."My Text Field" : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? Row."My Text Field" : DefaultLbl))) + '][' + Format(Cond ? Row."My Text Field" : DefaultLbl);
        end;
    end;

    // LblMax : FText100
    [Test]
    procedure Y66_Ternary_Pair_2()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : FText100 ' + Format(I = 1), Pair2(I = 1));
        Observer.Expect('LblMax : FText100 Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : FText100 No', '[Field text value|16][Field text value|16][E The length of the string is 16, but it must be less than or equal to 5 characters. Value: Field text value|StringLengthExceeded][FIELD TEXT VALUE|16][16][Field text value][Text]');
        Observer.Verify();
    end;

    local procedure Pair2(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair2Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair2Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair2Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : Row."My Text Field";
    end;

    [TryFunction]
    local procedure Pair2Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : Row."My Text Field";
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : Row."My Text Field";
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : Row."My Text Field";
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : Row."My Text Field";
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : Row."My Text Field"))) + '][' + Format(Cond ? DefaultLbl : Row."My Text Field");
        end;
    end;

    // FText100 : Lbl
    [Test]
    procedure Y66_Ternary_Pair_3()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('FText100 : Lbl ' + Format(I = 1), Pair3(I = 1));
        Observer.Expect('FText100 : Lbl Yes', '[Field text value|16][Field text value|16][E The length of the string is 16, but it must be less than or equal to 5 characters. Value: Field text value|StringLengthExceeded][FIELD TEXT VALUE|16][16][Field text value][Text]');
        Observer.Expect('FText100 : Lbl No', '[plain lbl|9][plain lbl|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: plain lbl|StringLengthExceeded][PLAIN LBL|9][9][plain lbl][Text]');
        Observer.Verify();
    end;

    local procedure Pair3(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair3Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair3Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair3Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? Row."My Text Field" : PlainLbl;
    end;

    [TryFunction]
    local procedure Pair3Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? Row."My Text Field" : PlainLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? Row."My Text Field" : PlainLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? Row."My Text Field" : PlainLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? Row."My Text Field" : PlainLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? Row."My Text Field" : PlainLbl))) + '][' + Format(Cond ? Row."My Text Field" : PlainLbl);
        end;
    end;

    // FCode10 : LblMax
    [Test]
    procedure Y66_Ternary_Pair_4()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('FCode10 : LblMax ' + Format(I = 1), Pair4(I = 1));
        Observer.Expect('FCode10 : LblMax Yes', '[FCODE|5][FCODE|5][FCODE|5][FCODE|5][5][FCODE][Code]');
        Observer.Expect('FCode10 : LblMax No', '[E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 10 characters. Value: Default text|StringLengthExceeded]');
        Observer.Verify();
    end;

    local procedure Pair4(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair4Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair4Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair4Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? Row."My Code" : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair4Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? Row."My Code" : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? Row."My Code" : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? Row."My Code" : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? Row."My Code" : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? Row."My Code" : DefaultLbl))) + '][' + Format(Cond ? Row."My Code" : DefaultLbl);
        end;
    end;

    // LblMax : FCode10
    [Test]
    procedure Y66_Ternary_Pair_5()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : FCode10 ' + Format(I = 1), Pair5(I = 1));
        Observer.Expect('LblMax : FCode10 Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : FCode10 No', '[FCODE|5][FCODE|5][FCODE|5][FCODE|5][5][FCODE][Code]');
        Observer.Verify();
    end;

    local procedure Pair5(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair5Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair5Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair5Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : Row."My Code";
    end;

    [TryFunction]
    local procedure Pair5Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : Row."My Code";
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : Row."My Code";
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : Row."My Code";
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : Row."My Code";
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : Row."My Code"))) + '][' + Format(Cond ? DefaultLbl : Row."My Code");
        end;
    end;

    // FGuid : Lbl
    [Test]
    procedure Y66_Ternary_Pair_6()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('FGuid : Lbl ' + Format(I = 1), Pair6(I = 1));
        Observer.Expect('FGuid : Lbl Yes', '[{55555555-5555-5555-5555-555555555555}|38][{55555555-5555-5555-5555-555555555555}|38][38][{55555555-5555-5555-5555-555555555555}][Guid]');
        Observer.Expect('FGuid : Lbl No', '[E Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat][E Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat][E Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat][E Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat]');
        Observer.Verify();
    end;

    local procedure Pair6(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 3 do begin
            ClearLastError();
            if Pair6Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair6Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair6Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? Row."My Guid" : PlainLbl;
    end;

    [TryFunction]
    local procedure Pair6Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? Row."My Guid" : PlainLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? Row."My Guid" : PlainLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                R := Format(StrLen(Format(Cond ? Row."My Guid" : PlainLbl))) + '][' + Format(Cond ? Row."My Guid" : PlainLbl);
        end;
    end;

    // Lbl : FGuid
    [Test]
    procedure Y66_Ternary_Pair_7()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Lbl : FGuid ' + Format(I = 1), Pair7(I = 1));
        Observer.Expect('Lbl : FGuid Yes', '[plain lbl|9][plain lbl|9][9][plain lbl][Text]');
        Observer.Expect('Lbl : FGuid No', '[{55555555-5555-5555-5555-555555555555}|38][{55555555-5555-5555-5555-555555555555}|38][38][{55555555-5555-5555-5555-555555555555}][Text]');
        Observer.Verify();
    end;

    local procedure Pair7(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 3 do begin
            ClearLastError();
            if Pair7Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair7Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair7Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? PlainLbl : Row."My Guid";
    end;

    [TryFunction]
    local procedure Pair7Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? PlainLbl : Row."My Guid";
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? PlainLbl : Row."My Guid";
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                R := Format(StrLen(Format(Cond ? PlainLbl : Row."My Guid"))) + '][' + Format(Cond ? PlainLbl : Row."My Guid");
        end;
    end;

    // Text3 : LblMax
    [Test]
    procedure Y66_Ternary_Pair_8()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Text3 : LblMax ' + Format(I = 1), Pair8(I = 1));
        Observer.Expect('Text3 : LblMax Yes', '[abc|3][abc|3][abc|3][ABC|3][3][abc][Text]');
        Observer.Expect('Text3 : LblMax No', '[E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded][E The length of the string is 12, but it must be less than or equal to 3 characters. Value: Default text|StringLengthExceeded]');
        Observer.Verify();
    end;

    local procedure Pair8(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair8Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair8Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair8Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? T3 : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair8Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? T3 : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? T3 : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? T3 : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? T3 : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? T3 : DefaultLbl))) + '][' + Format(Cond ? T3 : DefaultLbl);
        end;
    end;

    // LblMax : Text3
    [Test]
    procedure Y66_Ternary_Pair_9()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : Text3 ' + Format(I = 1), Pair9(I = 1));
        Observer.Expect('LblMax : Text3 Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : Text3 No', '[abc|3][abc|3][abc|3][ABC|3][3][abc][Text]');
        Observer.Verify();
    end;

    local procedure Pair9(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair9Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair9Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair9Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : T3;
    end;

    [TryFunction]
    local procedure Pair9Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : T3;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : T3;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : T3;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : T3;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : T3))) + '][' + Format(Cond ? DefaultLbl : T3);
        end;
    end;

    // Code3 : Lbl
    [Test]
    procedure Y66_Ternary_Pair_10()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Code3 : Lbl ' + Format(I = 1), Pair10(I = 1));
        Observer.Expect('Code3 : Lbl Yes', '[XY|2][XY|2][XY|2][XY|2][2][XY][Code]');
        Observer.Expect('Code3 : Lbl No', '[E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded][E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded][E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded][E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded][E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded][E The length of the string is 9, but it must be less than or equal to 3 characters. Value: plain lbl|StringLengthExceeded]');
        Observer.Verify();
    end;

    local procedure Pair10(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair10Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair10Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair10Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? C3 : PlainLbl;
    end;

    [TryFunction]
    local procedure Pair10Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? C3 : PlainLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? C3 : PlainLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? C3 : PlainLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? C3 : PlainLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? C3 : PlainLbl))) + '][' + Format(Cond ? C3 : PlainLbl);
        end;
    end;

    // Lbl : Code3
    [Test]
    procedure Y66_Ternary_Pair_11()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Lbl : Code3 ' + Format(I = 1), Pair11(I = 1));
        Observer.Expect('Lbl : Code3 Yes', '[plain lbl|9][plain lbl|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: plain lbl|StringLengthExceeded][PLAIN LBL|9][9][plain lbl][TextConstant]');
        Observer.Expect('Lbl : Code3 No', '[XY|2][XY|2][XY|2][XY|2][2][XY][Code]');
        Observer.Verify();
    end;

    local procedure Pair11(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair11Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair11Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair11Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? PlainLbl : C3;
    end;

    [TryFunction]
    local procedure Pair11Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? PlainLbl : C3;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? PlainLbl : C3;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? PlainLbl : C3;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? PlainLbl : C3;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? PlainLbl : C3))) + '][' + Format(Cond ? PlainLbl : C3);
        end;
    end;

    // Code250 : LblMax
    [Test]
    procedure Y66_Ternary_Pair_12()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Code250 : LblMax ' + Format(I = 1), Pair12(I = 1));
        Observer.Expect('Code250 : LblMax Yes', '[CODE250 VALUE|13][CODE250 VALUE|13][E The length of the string is 13, but it must be less than or equal to 5 characters. Value: CODE250 VALUE|StringLengthExceeded][CODE250 VALUE|13][13][CODE250 VALUE][Code]');
        Observer.Expect('Code250 : LblMax No', '[DEFAULT TEXT|12][DEFAULT TEXT|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: DEFAULT TEXT|StringLengthExceeded][DEFAULT TEXT|12][12][DEFAULT TEXT][Code]');
        Observer.Verify();
    end;

    local procedure Pair12(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair12Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair12Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair12Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? C250 : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair12Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? C250 : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? C250 : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? C250 : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? C250 : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? C250 : DefaultLbl))) + '][' + Format(Cond ? C250 : DefaultLbl);
        end;
    end;

    // LblMax : Code250
    [Test]
    procedure Y66_Ternary_Pair_13()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : Code250 ' + Format(I = 1), Pair13(I = 1));
        Observer.Expect('LblMax : Code250 Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : Code250 No', '[CODE250 VALUE|13][CODE250 VALUE|13][E The length of the string is 13, but it must be less than or equal to 5 characters. Value: CODE250 VALUE|StringLengthExceeded][CODE250 VALUE|13][13][CODE250 VALUE][Code]');
        Observer.Verify();
    end;

    local procedure Pair13(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair13Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair13Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair13Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : C250;
    end;

    [TryFunction]
    local procedure Pair13Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : C250;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : C250;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : C250;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : C250;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : C250))) + '][' + Format(Cond ? DefaultLbl : C250);
        end;
    end;

    // LblMax : Lbl
    [Test]
    procedure Y66_Ternary_Pair_14()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : Lbl ' + Format(I = 1), Pair14(I = 1));
        Observer.Expect('LblMax : Lbl Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : Lbl No', '[plain lbl|9][plain lbl|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: plain lbl|StringLengthExceeded][PLAIN LBL|9][9][plain lbl][TextConstant]');
        Observer.Verify();
    end;

    local procedure Pair14(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair14Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair14Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair14Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : PlainLbl;
    end;

    [TryFunction]
    local procedure Pair14Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : PlainLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : PlainLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : PlainLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : PlainLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : PlainLbl))) + '][' + Format(Cond ? DefaultLbl : PlainLbl);
        end;
    end;

    // Lbl : LblMax
    [Test]
    procedure Y66_Ternary_Pair_15()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Lbl : LblMax ' + Format(I = 1), Pair15(I = 1));
        Observer.Expect('Lbl : LblMax Yes', '[plain lbl|9][plain lbl|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: plain lbl|StringLengthExceeded][PLAIN LBL|9][9][plain lbl][TextConstant]');
        Observer.Expect('Lbl : LblMax No', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Verify();
    end;

    local procedure Pair15(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair15Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair15Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair15Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? PlainLbl : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair15Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? PlainLbl : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? PlainLbl : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? PlainLbl : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? PlainLbl : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? PlainLbl : DefaultLbl))) + '][' + Format(Cond ? PlainLbl : DefaultLbl);
        end;
    end;

    // Text : LblMax
    [Test]
    procedure Y66_Ternary_Pair_16()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('Text : LblMax ' + Format(I = 1), Pair16(I = 1));
        Observer.Expect('Text : LblMax Yes', '[free text|9][free text|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: free text|StringLengthExceeded][FREE TEXT|9][9][free text][Text]');
        Observer.Expect('Text : LblMax No', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][Text]');
        Observer.Verify();
    end;

    local procedure Pair16(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair16Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair16Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair16Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? Txt : DefaultLbl;
    end;

    [TryFunction]
    local procedure Pair16Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? Txt : DefaultLbl;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? Txt : DefaultLbl;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? Txt : DefaultLbl;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? Txt : DefaultLbl;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? Txt : DefaultLbl))) + '][' + Format(Cond ? Txt : DefaultLbl);
        end;
    end;

    // LblMax : Text
    [Test]
    procedure Y66_Ternary_Pair_17()
    var
        I: Integer;
    begin
        Seed();
        for I := 1 to 2 do
            Observer.Observe('LblMax : Text ' + Format(I = 1), Pair17(I = 1));
        Observer.Expect('LblMax : Text Yes', '[Default text|12][Default text|12][E The length of the string is 12, but it must be less than or equal to 5 characters. Value: Default text|StringLengthExceeded][DEFAULT TEXT|12][12][Default text][TextConstant]');
        Observer.Expect('LblMax : Text No', '[free text|9][free text|9][E The length of the string is 9, but it must be less than or equal to 5 characters. Value: free text|StringLengthExceeded][FREE TEXT|9][9][free text][Text]');
        Observer.Verify();
    end;

    local procedure Pair17(Cond: Boolean): Text
    var
        Kind: Integer;
        R: Text;
        S: Text;
        V: Variant;
    begin
        for Kind := 1 to 5 do begin
            ClearLastError();
            if Pair17Into(Cond, Kind, R) then
                S += '[' + R + ']'
            else
                S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        end;
        ClearLastError();
        if Pair17Variant(Cond, V) then
            S += '[' + VariantKind(V) + ']'
        else
            S += '[E ' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        exit(S);
    end;

    [TryFunction]
    local procedure Pair17Variant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? DefaultLbl : Txt;
    end;

    [TryFunction]
    local procedure Pair17Into(Cond: Boolean; Kind: Integer; var R: Text)
    var
        ToText: Text;
        ToText100: Text[100];
        ToText5: Text[5];
        ToCode20: Code[20];
    begin
        case Kind of
            1:
                begin
                    ToText := Cond ? DefaultLbl : Txt;
                    R := ToText + '|' + Format(StrLen(ToText));
                end;
            2:
                begin
                    ToText100 := Cond ? DefaultLbl : Txt;
                    R := ToText100 + '|' + Format(StrLen(ToText100));
                end;
            3:
                begin
                    ToText5 := Cond ? DefaultLbl : Txt;
                    R := ToText5 + '|' + Format(StrLen(ToText5));
                end;
            4:
                begin
                    ToCode20 := Cond ? DefaultLbl : Txt;
                    R := ToCode20 + '|' + Format(StrLen(ToCode20));
                end;
            5:
                R := Format(StrLen(Format(Cond ? DefaultLbl : Txt))) + '][' + Format(Cond ? DefaultLbl : Txt);
        end;
    end;

    local procedure Seed()
    begin
        Row.Init();
        Row."My Text Field" := 'Field text value';
        Row."My Code" := 'FCODE';
        Evaluate(Row."My Guid", '{55555555-5555-5555-5555-555555555555}');
        T3 := 'abc';
        C3 := 'XY';
        C250 := 'CODE250 VALUE';
        Txt := 'free text';
    end;

    local procedure VariantKind(V: Variant): Text
    begin
        case true of
            V.IsText:
                exit('Text');
            V.IsCode:
                exit('Code');
            V.IsTextConstant:
                exit('TextConstant');
            V.IsChar:
                exit('Char');
            V.IsGuid:
                exit('Guid');
        end;
        exit('other');
    end;
}
