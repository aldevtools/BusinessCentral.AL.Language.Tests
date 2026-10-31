// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe (writer Y20, al-runner issue 6481): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: an Option FlowField whose CalcFormula looks up an Enum field (the shape of extensions whose Option FlowFields look up
//   Base Application fields that became enums): members whose ordinal the Option has, a member whose ordinal the Option lacks,
//   no row found; max of the Enum field into an Option FlowField; a filter on the Option FlowField. An Enum FlowField that looks up
//   an Option field does not compile (must-not-compile 2350).
// BC versions: 27, 28, 29

enum 92100 "LT Y20 FLOpt Source"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(5; Five) { }
}

table 92101 "LT Y20 FLOpt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Status; Enum "LT Y20 FLOpt Source") { }
        field(3; Grp; Code[10]) { }
        field(4; Opt; Option) { OptionMembers = Zero,One,Two,Three,Four,Five; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92102 "LT Y20 FLOpt Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Line No."; Code[10]) { }
        field(3; "Line Status"; Option)
        {
            OptionMembers = Nil,Uno,Dos;
            FieldClass = FlowField;
            CalcFormula = lookup("LT Y20 FLOpt Line".Status where("No." = field("Line No.")));
            Editable = false;
        }
        field(4; "Grp"; Code[10]) { }
        field(5; "Max Status"; Option)
        {
            OptionMembers = Nil,Uno,Dos;
            FieldClass = FlowField;
            CalcFormula = max("LT Y20 FLOpt Line".Status where(Grp = field(Grp)));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 92103 "LT Y20 FLOpt Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Line: Record "LT Y20 FLOpt Line";
        Header: Record "LT Y20 FLOpt Header";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        AddLine('L0', Line.Status::Zero, 'G1', 0);
        AddLine('L1', Line.Status::One, 'G1', 1);
        AddLine('L2', Line.Status::Two, 'G2', 2);
        AddLine('L5', Line.Status::Five, 'G2', 5);
        AddLine('L3', Line.Status::One, 'G3', 3);
    end;

    local procedure AddLine(No: Code[10]; Status: Enum "LT Y20 FLOpt Source"; Grp: Code[10]; Opt: Integer)
    var
        Line: Record "LT Y20 FLOpt Line";
    begin
        Line."No." := No;
        Line.Status := Status;
        Line.Grp := Grp;
        Line.Opt := Opt;
        Line.Insert();
    end;

    local procedure Read(var Observer: Codeunit "Probe Observer"; Name: Text; LineNo: Code[10])
    var
        Header: Record "LT Y20 FLOpt Header";
        Ordinal: Integer;
    begin
        Header.DeleteAll();
        Header."No." := 'H';
        Header."Line No." := LineNo;
        Header.Insert();
        Header.CalcFields("Line Status");
        Ordinal := Header."Line Status";
        Observer.Observe(Name + '_format', Format(Header."Line Status"));
        Observer.Observe(Name + '_ordinal', Format(Ordinal));
        Observer.Observe(Name + '_format9', Format(Header."Line Status", 0, 9));
    end;

    // The reporter's shape: members whose ordinal the Option has.
    [Test]
    procedure Y20_Lookup_EnumIntoOption_Ordinal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Read(Observer, 'zero', 'L0');
        Read(Observer, 'one', 'L1');
        Read(Observer, 'two', 'L2');
        Observer.Expect('zero_format', 'Zero');
        Observer.Expect('zero_ordinal', '0');
        Observer.Expect('zero_format9', '0');
        Observer.Expect('one_format', 'One');
        Observer.Expect('one_ordinal', '1');
        Observer.Expect('one_format9', '1');
        Observer.Expect('two_format', 'Two');
        Observer.Expect('two_ordinal', '2');
        Observer.Expect('two_format9', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_Lookup_OrdinalTheOptionLacks_Result()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT Y20 FLOpt Header";
    begin
        Seed();
        Read(Observer, 'five', 'L5');
        Header.Get('H');
        Header.CalcFields("Line Status");
        Observer.Observe('five_eq_dos', Format(Header."Line Status" = Header."Line Status"::Dos));
        Observer.Expect('five_format', 'Five');
        Observer.Expect('five_ordinal', '5');
        Observer.Expect('five_format9', '5');
        Observer.Expect('five_eq_dos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_Lookup_NoRowFound_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Read(Observer, 'no_row', 'NONE');
        Observer.Expect('no_row_format', 'Nil');
        Observer.Expect('no_row_ordinal', '0');
        Observer.Expect('no_row_format9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_Max_EnumIntoOption_Result()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT Y20 FLOpt Header";
        Ordinal: Integer;
    begin
        Seed();
        Header."No." := 'H';
        Header.Grp := 'G1';
        Header.Insert();
        Header.CalcFields("Max Status");
        Ordinal := Header."Max Status";
        Observer.Observe('max_g1', Format(Header."Max Status") + '/' + Format(Ordinal));
        Header.Grp := 'G2';
        Header.CalcFields("Max Status");
        Ordinal := Header."Max Status";
        Observer.Observe('max_g2', Format(Header."Max Status") + '/' + Format(Ordinal));
        Header.Grp := 'G9';
        Header.CalcFields("Max Status");
        Ordinal := Header."Max Status";
        Observer.Observe('max_none', Format(Header."Max Status") + '/' + Format(Ordinal));
        Observer.Expect('max_g1', 'Uno/1');
        Observer.Expect('max_g2', '5/5');
        Observer.Expect('max_none', 'Nil/0');
        Observer.Verify();
    end;

    [Test]
    procedure Y20_Filter_OptionFlowFieldFromEnum_Count()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT Y20 FLOpt Header";
    begin
        Seed();
        AddHeader('H0', 'L0');
        AddHeader('H1', 'L1');
        AddHeader('H2', 'L2');
        AddHeader('H3', 'L3');
        AddHeader('H5', 'L5');
        Header.SetRange("Line Status", Header."Line Status"::Uno);
        Observer.Observe('uno_count', Format(Header.Count()));
        Header.SetRange("Line Status", Header."Line Status"::Dos);
        Observer.Observe('dos_count', Format(Header.Count()));
        Header.SetFilter("Line Status", '%1', 5);
        Observer.Observe('five_count', Format(Header.Count()));
        Observer.Expect('uno_count', '2');
        Observer.Expect('dos_count', '1');
        Observer.Expect('five_count', '1');
        Observer.Verify();
    end;

    local procedure AddHeader(No: Code[10]; LineNo: Code[10])
    var
        Header: Record "LT Y20 FLOpt Header";
    begin
        Header."No." := No;
        Header."Line No." := LineNo;
        Header.Insert();
    end;
}
