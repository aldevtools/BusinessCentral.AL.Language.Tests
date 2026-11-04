// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74063 (BC 29 only), test codeunit 74064
// Facts: a BigInteger assigned to an Option variable (Opt := Big): in range, an ordinal the Option lacks, negative, beyond the Integer range.
//   Whether the assignment raises, and what the variable holds afterwards. An Enum variable gets the same values on BC 29 only (E := Big does not compile on AL 16 and 17: must-not-compile/cases/0451).
// Writer QO (al-runtime-rs assumption enum-option-integer-ordinal): an Integer and a BigInteger held in a Variant, assigned to an Option
//   variable, assigned to and validated into an Option field, and set through FieldRef.Value and FieldRef.Validate of an Option and an Enum field:
//   a member ordinal, an ordinal the Option or Enum lacks, a negative one and one beyond Integer. Own enum 87080 and table 87081 (its
//   OnValidate triggers note the ordinal they saw in Seen). QO_ tests in codeunit 74064.
// BC versions: 27, 28, 29 by CI

#if BC29PLUS
enum 74063 "LT BE Enum"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(7; Seven) { }
}
#endif

enum 87080 "LT QO Ord Enum"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(7; Seven) { }
}

table 87081 "LT QO Ord Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,One,Two;

            trigger OnValidate()
            begin
                Seen := 'opt ' + Format(Opt, 0, 2);
            end;
        }
        field(3; E; Enum "LT QO Ord Enum")
        {
            trigger OnValidate()
            begin
                Seen := 'enum ' + Format(E.AsInteger());
            end;
        }
        field(4; Seen; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74064 "LT BigInt To Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two;
#if BC29PLUS
        E: Enum "LT BE Enum";
#endif
        Shown: Text;

    [TryFunction]
    local procedure SetOpt(Big: BigInteger)
    begin
        Opt := Big;
    end;

#if BC29PLUS
    [TryFunction]
    local procedure SetEnum(Big: BigInteger)
    begin
        E := Big;
    end;

    [TryFunction]
    local procedure ShowEnum()
    begin
        Shown := Format(E) + '|' + Format(E.AsInteger());
    end;

    local procedure ProbeEnum(Name: Text; Value: Text)
    var
        Big: BigInteger;
    begin
        Evaluate(Big, Value);
        Clear(E);
        if SetEnum(Big) then begin
            Obs.Observe(Name + '.set', 'ok');
            if ShowEnum() then
                Obs.Observe(Name + '.val', Shown)
            else
                Obs.ObserveError(Name + '.showerr');
        end else
            Obs.ObserveError(Name + '.err');
    end;

#endif
    [TryFunction]
    local procedure ShowOpt()
    var
        Int: Integer;
    begin
        Int := Opt;
        Shown := Format(Opt) + '|' + Format(Int);
    end;

    local procedure ProbeOpt(Name: Text; Value: Text)
    var
        Big: BigInteger;
    begin
        Evaluate(Big, Value);
        Clear(Opt);
        if SetOpt(Big) then begin
            Obs.Observe(Name + '.set', 'ok');
            if ShowOpt() then
                Obs.Observe(Name + '.val', Shown)
            else
                Obs.ObserveError(Name + '.showerr');
        end else
            Obs.ObserveError(Name + '.err');
    end;

    [Test]
    procedure Option_FromBigInteger_InRangeAndLacking()
    begin
        ProbeOpt('o0', '0');
        ProbeOpt('o1', '1');
        ProbeOpt('o2', '2');
        ProbeOpt('o3', '3');
        ProbeOpt('o7', '7');
        ProbeOpt('o100', '100');
        ProbeOpt('om1', '-1');
        Obs.Expect('o0.set', 'ok');
        Obs.Expect('o0.val', 'Zero|0');
        Obs.Expect('o1.set', 'ok');
        Obs.Expect('o1.val', 'One|1');
        Obs.Expect('o2.set', 'ok');
        Obs.Expect('o2.val', 'Two|2');
        Obs.Expect('o3.set', 'ok');
        Obs.Expect('o3.val', '3|3');
        Obs.Expect('o7.set', 'ok');
        Obs.Expect('o7.val', '7|7');
        Obs.Expect('o100.set', 'ok');
        Obs.Expect('o100.val', '100|100');
        Obs.Expect('om1.set', 'ok');
        Obs.Expect('om1.val', '-1|-1');
        Obs.Verify();
    end;

    [Test]
    procedure Option_FromBigInteger_BeyondInteger()
    begin
        ProbeOpt('imax', '2147483647');
        ProbeOpt('imax1', '2147483648');
        ProbeOpt('u32', '4294967296');
        ProbeOpt('imin', '-2147483648');
        ProbeOpt('imin1', '-2147483649');
        ProbeOpt('lmax', '9223372036854775807');
        Obs.Expect('imax.set', 'ok');
        Obs.Expect('imax.val', '2147483647|2147483647');
        Obs.Expect('imax1.err|text', 'Overflow under conversion of System.Int64 value 2147483648 to System.Int32.');
        Obs.Expect('imax1.err|code', 'ConversionCast');
        Obs.Expect('u32.err|text', 'Overflow under conversion of System.Int64 value 4294967296 to System.Int32.');
        Obs.Expect('u32.err|code', 'ConversionCast');
        Obs.Expect('imin.set', 'ok');
        Obs.Expect('imin.val', '-2147483648|-2147483648');
        Obs.Expect('imin1.err|text', 'Overflow under conversion of System.Int64 value -2147483649 to System.Int32.');
        Obs.Expect('imin1.err|code', 'ConversionCast');
        Obs.Expect('lmax.err|text', 'Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.');
        Obs.Expect('lmax.err|code', 'ConversionCast');
        Obs.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure Enum_FromBigInteger_InRangeAndLacking()
    begin
        ProbeEnum('e0', '0');
        ProbeEnum('e1', '1');
        ProbeEnum('e2', '2');
        ProbeEnum('e3', '3');
        ProbeEnum('e7', '7');
        ProbeEnum('e100', '100');
        ProbeEnum('em1', '-1');
        Obs.Expect('e0.set', 'ok');
        Obs.Expect('e0.val', 'Zero|0');
        Obs.Expect('e1.set', 'ok');
        Obs.Expect('e1.val', 'One|1');
        Obs.Expect('e2.set', 'ok');
        Obs.Expect('e2.val', 'Two|2');
        Obs.Expect('e3.set', 'ok');
        Obs.Expect('e3.val', '3|3');
        Obs.Expect('e7.set', 'ok');
        Obs.Expect('e7.val', 'Seven|7');
        Obs.Expect('e100.set', 'ok');
        Obs.Expect('e100.val', '100|100');
        Obs.Expect('em1.set', 'ok');
        Obs.Expect('em1.val', '-1|-1');
        Obs.Verify();
    end;

    [Test]
    procedure Enum_FromBigInteger_BeyondInteger()
    begin
        ProbeEnum('imax', '2147483647');
        ProbeEnum('imax1', '2147483648');
        ProbeEnum('u32', '4294967296');
        ProbeEnum('imin', '-2147483648');
        ProbeEnum('imin1', '-2147483649');
        ProbeEnum('lmax', '9223372036854775807');
        Obs.Expect('imax.set', 'ok');
        Obs.Expect('imax.val', '2147483647|2147483647');
        Obs.Expect('imax1.err|text', 'Overflow under conversion of System.Int64 value 2147483648 to System.Int32.');
        Obs.Expect('imax1.err|code', 'ConversionCast');
        Obs.Expect('u32.err|text', 'Overflow under conversion of System.Int64 value 4294967296 to System.Int32.');
        Obs.Expect('u32.err|code', 'ConversionCast');
        Obs.Expect('imin.set', 'ok');
        Obs.Expect('imin.val', '-2147483648|-2147483648');
        Obs.Expect('imin1.err|text', 'Overflow under conversion of System.Int64 value -2147483649 to System.Int32.');
        Obs.Expect('imin1.err|code', 'ConversionCast');
        Obs.Expect('lmax.err|text', 'Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.');
        Obs.Expect('lmax.err|code', 'ConversionCast');
        Obs.Verify();
    end;
#endif

    // Writer QO: Variant into Option variables and fields, and into Option and Enum fields through a FieldRef. Kind 1 Option variable,
    // 3 Option field assign, 4 Option field Validate, 7 FieldRef.Value of the Option field, 8 FieldRef.Validate of the Option field,
    // 9 FieldRef.Value of the Enum field, 10 FieldRef.Validate of the Enum field. A Variant into an Enum variable, an Enum field and
    // Validate of an Enum field do not compile (must-not-compile 0263, 1992, 1993).
    [TryFunction]
    local procedure QoTry(Kind: Integer; V: Variant; var Result: Text)
    var
        R: Record "LT QO Ord Row";
        O: Option Zero,One,Two;
        RecRef: RecordRef;
        FR: FieldRef;
    begin
        case Kind of
            1:
                begin
                    O := V;
                    Result := Format(O) + '|' + Format(O, 0, 2);
                    exit;
                end;
            3:
                R.Opt := V;
            4:
                R.Validate(Opt, V);
            7, 8, 9, 10:
                begin
                    RecRef.GetTable(R);
                    if Kind in [7, 8] then
                        FR := RecRef.Field(2)
                    else
                        FR := RecRef.Field(3);
                    if Kind in [7, 9] then
                        FR.Value := V
                    else
                        FR.Validate(V);
                    RecRef.SetTable(R);
                end;
        end;
        if Kind in [3, 4, 7, 8] then
            Result := Format(R.Opt) + '|' + Format(R.Opt, 0, 2) + '|' + R.Seen
        else
            Result := Format(R.E) + '|' + Format(R.E.AsInteger()) + '|' + R.Seen;
    end;

    local procedure QoProbe(Kind: Integer)
    var
        V: Variant;
        I: Integer;
        Big: BigInteger;
        Name: Text;
        Result: Text;
        Step: Integer;
    begin
        for Step := 1 to 8 do begin
            case Step of
                1:
                    begin
                        I := 1;
                        V := I;
                        Name := 'int1';
                    end;
                2:
                    begin
                        I := 3;
                        V := I;
                        Name := 'int3';
                    end;
                3:
                    begin
                        I := 7;
                        V := I;
                        Name := 'int7';
                    end;
                4:
                    begin
                        I := -1;
                        V := I;
                        Name := 'intm1';
                    end;
                5:
                    begin
                        Big := 2;
                        V := Big;
                        Name := 'big2';
                    end;
                6:
                    begin
                        Big := 7;
                        V := Big;
                        Name := 'big7';
                    end;
                7:
                    begin
                        Big := -1;
                        V := Big;
                        Name := 'bigm1';
                    end;
                8:
                    begin
                        Evaluate(Big, '2147483648');
                        V := Big;
                        Name := 'bigover';
                    end;
            end;
            Result := '';
            if QoTry(Kind, V, Result) then
                Obs.Observe(Name, Result)
            else
                Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure QO_Variant_ToOptionVariable()
    begin
        QoProbe(1);
        Obs.Expect('int1', 'One|1');
        Obs.Expect('int3', '3|3');
        Obs.Expect('int7', '7|7');
        Obs.Expect('intm1', '-1|-1');
        Obs.Expect('big2', 'Two|2');
        Obs.Expect('big7', '7|7');
        Obs.Expect('bigm1', '-1|-1');
        Obs.Expect('bigover|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Obs.Expect('bigover|code', 'TypeConversion:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToOptionField_Assign()
    begin
        QoProbe(3);
        Obs.Expect('int1', 'One|1|');
        Obs.Expect('int3', '3|3|');
        Obs.Expect('int7', '7|7|');
        Obs.Expect('intm1', '-1|-1|');
        Obs.Expect('big2', 'Two|2|');
        Obs.Expect('big7', '7|7|');
        Obs.Expect('bigm1', '-1|-1|');
        Obs.Expect('bigover|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Obs.Expect('bigover|code', 'TypeConversion:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToOptionField_Validate()
    begin
        QoProbe(4);
        Obs.Expect('int1', 'One|1|opt 1');
        Obs.Expect('int3', '3|3|opt 3');
        Obs.Expect('int7', '7|7|opt 7');
        Obs.Expect('intm1', '-1|-1|opt -1');
        Obs.Expect('big2', 'Two|2|opt 2');
        Obs.Expect('big7', '7|7|opt 7');
        Obs.Expect('bigm1', '-1|-1|opt -1');
        Obs.Expect('bigover|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigover|code', 'AL:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToOptionFieldRef_Value()
    begin
        QoProbe(7);
        Obs.Expect('int1', 'One|1|');
        Obs.Expect('int3', '3|3|');
        Obs.Expect('int7', '7|7|');
        Obs.Expect('intm1', '-1|-1|');
        Obs.Expect('big2', 'Two|2|');
        Obs.Expect('big7', '7|7|');
        Obs.Expect('bigm1', '-1|-1|');
        Obs.Expect('bigover|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigover|code', 'AL:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToOptionFieldRef_Validate()
    begin
        QoProbe(8);
        Obs.Expect('int1', 'One|1|opt 1');
        Obs.Expect('int3', '3|3|opt 3');
        Obs.Expect('int7', '7|7|opt 7');
        Obs.Expect('intm1', '-1|-1|opt -1');
        Obs.Expect('big2', 'Two|2|opt 2');
        Obs.Expect('big7', '7|7|opt 7');
        Obs.Expect('bigm1', '-1|-1|opt -1');
        Obs.Expect('bigover|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigover|code', 'AL:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToEnumFieldRef_Value()
    begin
        QoProbe(9);
        Obs.Expect('int1', 'One|1|');
        Obs.Expect('int3', '3|3|');
        Obs.Expect('int7', 'Seven|7|');
        Obs.Expect('intm1', '-1|-1|');
        Obs.Expect('big2', 'Two|2|');
        Obs.Expect('big7', 'Seven|7|');
        Obs.Expect('bigm1', '-1|-1|');
        Obs.Expect('bigover|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigover|code', 'AL:Overflow');
        Obs.Verify();
    end;

    [Test]
    procedure QO_Variant_ToEnumFieldRef_Validate()
    begin
        QoProbe(10);
        Obs.Expect('int1', 'One|1|enum 1');
        Obs.Expect('int3', '3|3|enum 3');
        Obs.Expect('int7', 'Seven|7|enum 7');
        Obs.Expect('intm1', '-1|-1|enum -1');
        Obs.Expect('big2', 'Two|2|enum 2');
        Obs.Expect('big7', 'Seven|7|enum 7');
        Obs.Expect('bigm1', '-1|-1|enum -1');
        Obs.Expect('bigover|text', 'Arithmetic operation resulted in an overflow.');
        Obs.Expect('bigover|code', 'AL:Overflow');
        Obs.Verify();
    end;
}
