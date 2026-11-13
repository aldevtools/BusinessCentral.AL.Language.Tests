// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 76630, tables 76631 to 76634, test codeunit 76635
// local object: the TableRelation of each field, its where() filters and its arm conditions are what is under test.
// Probe (al-runtime-rs assumption table-relation-quotes): the quoted-member forms of a TableRelation filter() that
//   record/table-relation/TableRelationQuotes.al leaves open. That file pins, on an Enum and an Option field with the one spaced member
//   "B C": members joined by |, one quoted member, <> one quoted member, ranges with one quoted bound, .."B C", "B C".."B C", "B C"..,
//   two and three <> terms joined by &, "B C" | D.., a quoted blank member " " in where() (Option), and arm conditions on an Option field.
//   Area of this file:
//   - where() on an Enum and an Option field with two spaced members "B C" and "E F": a range of two different quoted bounds, | of two
//     quoted members, <> of both joined by &, four & terms, a quoted member that has no space ("A", "D"), a quoted range written with spaces
//     around .., and two conditions of one where() that both hold a quoted member, a const() next to a quoted filter(), a field() next to it;
//   - arm conditions on an Enum field (all arms of the other file test an Option field): const("B C"), filter("B C" | A), filter(<> "B C"),
//     filter(.."B C"), filter("B C".."E F"), filter(<> A & <> "B C" & <> D), three arms in a row, and an arm whose condition has two
//     conditions joined by a comma.
//   Each cell validates the field with the code of every row of the related table (one row per member), an empty code and a missing code,
//   and records 'ok' or the error code, plus the error text of the missing code.
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

enum 76630 "REC TRQ Kind"
{
    Extensible = false;

    value(0; A) { }
    value(1; "B C") { }
    value(2; D) { }
    value(3; "E F") { }
}

table 76631 "REC TRQ Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Kind; Enum "REC TRQ Kind") { }
        field(3; Opt; Option) { OptionMembers = A,"B C",D,"E F"; }
        field(4; Grp; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 76632 "REC TRQ T1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 76633 "REC TRQ T2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 76634 "REC TRQ Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Kind; Enum "REC TRQ Kind") { }
        field(3; Grp; Code[10]) { }
        // where() forms
        field(10; "Kind Two Quoted Range"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter("B C" .. "E F")); }
        field(11; "Opt Two Quoted Range"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Opt = filter("B C" .. "E F")); }
        field(12; "Kind Two Quoted Or"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter("B C" | "E F")); }
        field(13; "Opt Two Quoted Or"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Opt = filter("B C" | "E F")); }
        field(14; "Kind Not Both"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter(<> "B C" & <> "E F")); }
        field(15; "Opt Four And"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Opt = filter(<> A & <> "B C" & <> D & <> "E F")); }
        field(16; "Kind Quoted Plain"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter("A" | "D")); }
        field(17; "Opt Quoted Plain Not"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Opt = filter(<> "A")); }
        field(18; "Kind Range Spaced"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter("B C" .. D)); }
        field(19; "Two Quoted Conditions"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Kind = filter("B C" | "E F"), Opt = filter(<> "B C")); }
        field(20; "Const And Quoted"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Grp = const('G1'), Kind = filter(<> "B C")); }
        field(21; "Field And Quoted"; Code[10]) { TableRelation = "REC TRQ Ref"."Code" where(Grp = field(Grp), Opt = filter("B C" | D)); }
        // arm conditions on an Enum field
        field(30; "Arm Const Quoted"; Code[10])
        {
            TableRelation = if (Kind = const("B C")) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(31; "Arm Quoted Or A"; Code[10])
        {
            TableRelation = if (Kind = filter("B C" | A)) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(32; "Arm Not Quoted"; Code[10])
        {
            TableRelation = if (Kind = filter(<> "B C")) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(33; "Arm Upto Quoted"; Code[10])
        {
            TableRelation = if (Kind = filter(.. "B C")) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(34; "Arm Two Quoted Range"; Code[10])
        {
            TableRelation = if (Kind = filter("B C" .. "E F")) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(35; "Arm Three And"; Code[10])
        {
            TableRelation = if (Kind = filter(<> A & <> "B C" & <> D)) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
        field(36; "Arm Three Arms"; Code[10])
        {
            TableRelation = if (Kind = filter("B C")) "REC TRQ T1"."Code"
            else if (Kind = filter("E F" | D)) "REC TRQ T2"."Code"
            else "REC TRQ Ref"."Code";
        }
        field(37; "Arm Two Conditions"; Code[10])
        {
            TableRelation = if (Kind = filter(<> "B C"), Grp = const('G1')) "REC TRQ T1"."Code"
            else "REC TRQ T2"."Code";
        }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 76635 "REC TRQ Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddRef(Code: Code[10]; Member: Integer; Grp: Code[10])
    var
        Ref: Record "REC TRQ Ref";
    begin
        Ref.Init();
        Ref."Code" := Code;
        Ref.Kind := Enum::"REC TRQ Kind".FromInteger(Member);
        Ref.Opt := Member;
        Ref.Grp := Grp;
        Ref.Insert();
    end;

    local procedure Seed()
    var
        Ref: Record "REC TRQ Ref";
        T1: Record "REC TRQ T1";
        T2: Record "REC TRQ T2";
    begin
        Ref.DeleteAll();
        T1.DeleteAll();
        T2.DeleteAll();
        // R0 = A, R1 = "B C", R2 = D, R3 = "E F" (group G1); S1 = "B C" in group G2
        AddRef('R0', 0, 'G1');
        AddRef('R1', 1, 'G1');
        AddRef('R2', 2, 'G1');
        AddRef('R3', 3, 'G1');
        AddRef('S1', 1, 'G2');
        T1."Code" := 'X1';
        T1.Insert();
        T2."Code" := 'Y1';
        T2.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(FieldNo: Integer; KindValue: Integer; Grp: Code[10]; Value: Code[10])
    var
        S: Record "REC TRQ Src";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        S.Kind := Enum::"REC TRQ Kind".FromInteger(KindValue);
        S.Grp := Grp;
        RecRef.GetTable(S);
        Fld := RecRef.Field(FieldNo);
        Fld.Validate(Value);
    end;

    local procedure Probe(FieldNo: Integer; KindValue: Integer; Grp: Code[10]; Codes: List of [Text])
    var
        C: Text;
        Name: Text;
    begin
        foreach C in Codes do begin
            Name := 'f' + Format(FieldNo) + 'k' + Format(KindValue) + Grp + '_' + C;
            ClearLastError();
            if TryValidate(FieldNo, KindValue, Grp, CopyStr(C, 1, 10)) then
                Observer.Observe(Name, 'ok')
            else begin
                Observer.Observe(Name, GetLastErrorCode());
                if C = 'NOPE' then
                    Observer.Observe(Name + '|text', GetLastErrorText());
            end;
        end;
        ClearLastError();
    end;

    local procedure WhereCodes(var Codes: List of [Text])
    begin
        Clear(Codes);
        Codes.Add('R0');
        Codes.Add('R1');
        Codes.Add('R2');
        Codes.Add('R3');
        Codes.Add('S1');
        Codes.Add('');
        Codes.Add('NOPE');
    end;

    local procedure ArmCodes(var Codes: List of [Text])
    begin
        Clear(Codes);
        Codes.Add('X1');
        Codes.Add('Y1');
        Codes.Add('R1');
        Codes.Add('');
        Codes.Add('NOPE');
    end;

    [Test]
    procedure Where_TwoQuotedBounds_And_TwoQuotedMembers()
    var
        Codes: List of [Text];
    begin
        Seed();
        WhereCodes(Codes);
        Probe(10, 0, '', Codes);
        Probe(11, 0, '', Codes);
        Probe(12, 0, '', Codes);
        Probe(13, 0, '', Codes);
        Observer.Finish();
    end;

    [Test]
    procedure Where_TwoQuotedBounds_And_TwoQuotedMembers_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_TwoQuotedBounds_And_TwoQuotedMembers_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_TwoQuotedBounds_And_TwoQuotedMembers_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_NotBoth_FourAnd_QuotedPlain()
    var
        Codes: List of [Text];
    begin
        Seed();
        WhereCodes(Codes);
        Probe(14, 0, '', Codes);
        Probe(15, 0, '', Codes);
        Probe(16, 0, '', Codes);
        Probe(17, 0, '', Codes);
        Probe(18, 0, '', Codes);
        Observer.Finish();
    end;

    [Test]
    procedure Where_NotBoth_FourAnd_QuotedPlain_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_NotBoth_FourAnd_QuotedPlain_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_NotBoth_FourAnd_QuotedPlain_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_QuotedNextToOtherConditions()
    var
        Codes: List of [Text];
    begin
        Seed();
        WhereCodes(Codes);
        Probe(19, 0, '', Codes);
        Probe(20, 0, '', Codes);
        Probe(21, 0, 'G1', Codes);
        Probe(21, 0, 'G2', Codes);
        Observer.Finish();
    end;

    [Test]
    procedure Where_QuotedNextToOtherConditions_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_QuotedNextToOtherConditions_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Where_QuotedNextToOtherConditions_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_SingleConditions()
    var
        Codes: List of [Text];
        K: Integer;
    begin
        Seed();
        ArmCodes(Codes);
        for K := 0 to 3 do begin
            Probe(30, K, '', Codes);
            Probe(31, K, '', Codes);
            Probe(32, K, '', Codes);
            Probe(33, K, '', Codes);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Arms_EnumField_SingleConditions_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_SingleConditions_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_SingleConditions_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_RangesAndAnd()
    var
        Codes: List of [Text];
        K: Integer;
    begin
        Seed();
        ArmCodes(Codes);
        for K := 0 to 3 do begin
            Probe(34, K, '', Codes);
            Probe(35, K, '', Codes);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Arms_EnumField_RangesAndAnd_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_RangesAndAnd_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_RangesAndAnd_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_ThreeArms_TwoConditions()
    var
        Codes: List of [Text];
        K: Integer;
    begin
        Seed();
        ArmCodes(Codes);
        for K := 0 to 3 do begin
            Probe(36, K, '', Codes);
            Probe(37, K, 'G1', Codes);
            Probe(37, K, 'G2', Codes);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Arms_EnumField_ThreeArms_TwoConditions_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_ThreeArms_TwoConditions_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Arms_EnumField_ThreeArms_TwoConditions_More3()
    begin
        Observer.More();
    end;
}
