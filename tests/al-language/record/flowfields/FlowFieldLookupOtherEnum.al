// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A Lookup FlowField that is an Enum of another enum type than the looked-up field: a member present in both enums, a member only in the looked-up enum (ordinal beyond the FlowField's enum), no row found (assumption flowfield-lookup-other-enum). Risky: may not compile (type mismatch of enums).
// BC versions: 29 (27 and 28 by CI)

enum 70829 "LT FLEnum Source"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(5; Five) { }
}

enum 70830 "LT FLEnum Target"
{
    Extensible = true;
    value(0; Nil) { }
    value(1; Uno) { }
    value(2; Dos) { }
}

table 70660 "LT FLEnum Line"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Status; Enum "LT FLEnum Source") { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 70661 "LT FLEnum Header"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Line No."; Code[10]) { }
        field(3; "Line Status"; Enum "LT FLEnum Target")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT FLEnum Line".Status where("No." = field("Line No.")));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70662 "LT FLEnum Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Line: Record "LT FLEnum Line";
        Header: Record "LT FLEnum Header";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Line."No." := 'L0';
        Line.Status := Line.Status::Zero;
        Line.Insert();
        Line."No." := 'L1';
        Line.Status := Line.Status::One;
        Line.Insert();
        Line."No." := 'L2';
        Line.Status := Line.Status::Two;
        Line.Insert();
        Line."No." := 'L5';
        Line.Status := Line.Status::Five;
        Line.Insert();
    end;

    local procedure Read(var Observer: Codeunit "Probe Observer"; Name: Text; LineNo: Code[10])
    var
        Header: Record "LT FLEnum Header";
    begin
        Header.DeleteAll();
        Header."No." := 'H';
        Header."Line No." := LineNo;
        Header.Insert();
        Header.CalcFields("Line Status");
        Observer.Observe(Name + '_format', Format(Header."Line Status"));
        Observer.Observe(Name + '_ordinal', Format(Header."Line Status".AsInteger()));
    end;

    [Test]
    procedure Lookup_MembersPresentInBoth_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Read(Observer, 'zero', 'L0');
        Read(Observer, 'one', 'L1');
        Read(Observer, 'two', 'L2');
        Observer.Expect('zero_format', 'Zero');
        Observer.Expect('zero_ordinal', '0');
        Observer.Expect('one_format', 'One');
        Observer.Expect('one_ordinal', '1');
        Observer.Expect('two_format', 'Two');
        Observer.Expect('two_ordinal', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_MemberOnlyInSource_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Read(Observer, 'five', 'L5');
        Observer.Expect('five_format', 'Five');
        Observer.Expect('five_ordinal', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Lookup_NoRowFound_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Read(Observer, 'no_row', 'NONE');
        Read(Observer, 'blank_key', '');
        Observer.Expect('no_row_format', 'Nil');
        Observer.Expect('no_row_ordinal', '0');
        Observer.Expect('blank_key_format', 'Nil');
        Observer.Expect('blank_key_ordinal', '0');
        Observer.Verify();
    end;
}
