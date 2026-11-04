// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Format of an Option field with an OptionCaption (length 5, format 0, 1, 2, 9, read directly from the field, English and German);
//   Option fields whose first member is " " or empty (OptionMembers = ,A) through Format, FieldRef.OptionMembers and FieldRef.OptionCaption;
//   Format of IsolationLevel members with format 0, 1, 2 and 9.
// BC versions: 27.5+

table 80400 "LT AX Option Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; OptCap; Option)
        {
            OptionMembers = Alpha,Beta,"Gamma Long";
            OptionCaption = 'First Caption,Second,Third One';
        }
        field(3; OptDash; Option)
        {
            OptionMembers = "A-B",C;
            OptionCaption = 'First,Second';
        }
        field(4; OptSpace; Option)
        {
            OptionMembers = " ",A;
        }
        field(5; OptEmpty; Option)
        {
            OptionMembers = ,A;
        }
        field(6; OptEmptyCap; Option)
        {
            OptionMembers = ,A;
            OptionCaption = 'Blank,Ay';
        }
        field(7; OptSpaceCapBlank; Option)
        {
            OptionMembers = " ",A;
            OptionCaption = ',Ay';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

codeunit 80420 "LT AX Format Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CapAll(var R: Record "LT AX Option Rec"): Text
    begin
        exit('[' + Format(R.OptCap, 5, 0) + ']' + Format(R.OptCap, 0, 9) + '|' + Format(R.OptCap) + '|[' + Format(R.OptCap, -12, 0) + ']|' + Format(R.OptCap, 0, 2));
    end;

    [Test]
    procedure OptionCaption_Length5_Format9()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Option Rec";
    begin
        R.OptCap := R.OptCap::Alpha;
        Observer.Observe('alpha', CapAll(R));
        R.OptCap := R.OptCap::Beta;
        Observer.Observe('beta', CapAll(R));
        R.OptCap := R.OptCap::"Gamma Long";
        Observer.Observe('gamma', CapAll(R));
        Observer.Observe('literal5', '[' + Format(R.OptCap::"Gamma Long", 5, 0) + ']');
        Observer.Observe('literal', Format(R.OptCap::"Gamma Long"));
        Observer.Expect('alpha', '[First]0|First Caption|[First Captio]|0');
        Observer.Expect('beta', '[Secon]1|Second|[Second]|1');
        Observer.Expect('gamma', '[Third]2|Third One|[Third One]|2');
        Observer.Expect('literal5', '[Third]');
        Observer.Expect('literal', 'Third One');
        Observer.Verify();
    end;

    local procedure DashAll(var R: Record "LT AX Option Rec"): Text
    begin
        exit(Format(R.OptDash) + '|' + Format(R.OptDash, 0, 0) + '|' + Format(R.OptDash, 0, 1) + '|' + Format(R.OptDash, 0, 2) + '|' + Format(R.OptDash, 0, 9));
    end;

    [Test]
    procedure OptionDashMember_DirectField_English()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Option Rec";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        R.OptDash := R.OptDash::"A-B";
        Observer.Observe('A-B', DashAll(R));
        R.OptDash := R.OptDash::C;
        Observer.Observe('C', DashAll(R));
        GlobalLanguage(Saved);
        Observer.Expect('A-B', 'First|First|First|0|0');
        Observer.Expect('C', 'Second|Second|Second|1|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionDashMember_DirectField_German()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Option Rec";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        R.OptDash := R.OptDash::"A-B";
        Observer.Observe('A-B', DashAll(R));
        R.OptDash := R.OptDash::C;
        Observer.Observe('C', DashAll(R));
        GlobalLanguage(Saved);
        Observer.Expect('A-B', 'First|First|First|0|0');
        Observer.Expect('C', 'Second|Second|Second|1|1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFirstMember_Format()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Option Rec";
    begin
        R.OptSpace := 0;
        R.OptEmpty := 0;
        R.OptEmptyCap := 0;
        R.OptSpaceCapBlank := 0;
        Observer.Observe('space0', '[' + Format(R.OptSpace) + '][' + Format(R.OptSpace, 0, 2) + '][' + Format(R.OptSpace, 0, 9) + ']');
        Observer.Observe('empty0', '[' + Format(R.OptEmpty) + '][' + Format(R.OptEmpty, 0, 2) + '][' + Format(R.OptEmpty, 0, 9) + ']');
        Observer.Observe('emptyCap0', '[' + Format(R.OptEmptyCap) + '][' + Format(R.OptEmptyCap, 0, 2) + '][' + Format(R.OptEmptyCap, 0, 9) + ']');
        Observer.Observe('spaceCapBlank0', '[' + Format(R.OptSpaceCapBlank) + '][' + Format(R.OptSpaceCapBlank, 0, 9) + ']');
        R.OptSpace := 1;
        R.OptEmpty := 1;
        R.OptEmptyCap := 1;
        R.OptSpaceCapBlank := 1;
        Observer.Observe('space1', '[' + Format(R.OptSpace) + '][' + Format(R.OptSpace, 0, 9) + ']');
        Observer.Observe('empty1', '[' + Format(R.OptEmpty) + '][' + Format(R.OptEmpty, 0, 9) + ']');
        Observer.Observe('emptyCap1', '[' + Format(R.OptEmptyCap) + '][' + Format(R.OptEmptyCap, 0, 9) + ']');
        Observer.Observe('spaceCapBlank1', '[' + Format(R.OptSpaceCapBlank) + ']');
        Observer.Observe('literalSpace', '[' + Format(R.OptSpace::" ") + '][' + Format(R.OptSpace::" ", 0, 9) + ']');
        Observer.Expect('space0', '[ ][0][0]');
        Observer.Expect('empty0', '[0][0][0]');
        Observer.Expect('emptyCap0', '[Blank][0][0]');
        Observer.Expect('spaceCapBlank0', '[ ][0]');
        Observer.Expect('space1', '[A][1]');
        Observer.Expect('empty1', '[A][1]');
        Observer.Expect('emptyCap1', '[Ay][1]');
        Observer.Expect('spaceCapBlank1', '[Ay]');
        Observer.Expect('literalSpace', '[ ][0]');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFirstMember_FieldRefOptionLists()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        i: Integer;
    begin
        RR.Open(Database::"LT AX Option Rec");
        for i := 4 to 7 do
            Observer.Observe(Format(i), '[' + RR.Field(i).OptionMembers() + '][' + RR.Field(i).OptionCaption() + ']');
        RR.Field(5).Value := 0;
        Observer.Observe('fr5value0', '[' + Format(RR.Field(5).Value) + '][' + Format(RR.Field(5).Value, 0, 9) + ']');
        RR.Field(6).Value := 0;
        Observer.Observe('fr6value0', '[' + Format(RR.Field(6).Value) + '][' + Format(RR.Field(6).Value, 0, 9) + ']');
        RR.Close();
        Observer.Expect('4', '[ ,A][ ,A]');
        Observer.Expect('5', '[,A][,A]');
        Observer.Expect('6', '[,A][Blank,Ay]');
        Observer.Expect('7', '[ ,A][ ,Ay]');
        Observer.Expect('fr5value0', '[0][0]');
        Observer.Expect('fr6value0', '[Blank][0]');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFirstMember_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Option Rec";
        Ok: Boolean;
    begin
        R.OptEmpty := 1;
        Ok := Evaluate(R.OptEmpty, '');
        Observer.Observe('empty<-blank', Format(Ok) + '|' + Format(R.OptEmpty, 0, 9));
        R.OptEmpty := 1;
        Ok := Evaluate(R.OptEmpty, ' ');
        Observer.Observe('empty<-space', Format(Ok) + '|' + Format(R.OptEmpty, 0, 9));
        R.OptSpace := 1;
        Ok := Evaluate(R.OptSpace, '');
        Observer.Observe('space<-blank', Format(Ok) + '|' + Format(R.OptSpace, 0, 9));
        R.OptSpace := 1;
        Ok := Evaluate(R.OptSpace, ' ');
        Observer.Observe('space<-space', Format(Ok) + '|' + Format(R.OptSpace, 0, 9));
        R.OptEmptyCap := 1;
        Ok := Evaluate(R.OptEmptyCap, 'Blank');
        Observer.Observe('emptyCap<-Blank', Format(Ok) + '|' + Format(R.OptEmptyCap, 0, 9));
        Observer.Expect('empty<-blank', 'No|1');
        Observer.Expect('empty<-space', 'No|1');
        Observer.Expect('space<-blank', 'Yes|0');
        Observer.Expect('space<-space', 'Yes|0');
        Observer.Expect('emptyCap<-Blank', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure IsolationLevel_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ReadUncommitted', Format(IsolationLevel::ReadUncommitted) + '|' + Format(IsolationLevel::ReadUncommitted, 0, 1) + '|' + Format(IsolationLevel::ReadUncommitted, 0, 2) + '|' + Format(IsolationLevel::ReadUncommitted, 0, 9));
        Observer.Observe('Default', Format(IsolationLevel::Default, 0, 2) + '|' + Format(IsolationLevel::Default, 0, 9));
        Observer.Observe('ReadCommitted', Format(IsolationLevel::ReadCommitted, 0, 2));
        Observer.Observe('RepeatableRead', Format(IsolationLevel::RepeatableRead, 0, 2));
        Observer.Observe('UpdLock', Format(IsolationLevel::UpdLock, 0, 2));
        Observer.Expect('ReadUncommitted', 'ReadUncommitted|ReadUncommitted|ReadUncommitted|ReadUncommitted');
        Observer.Expect('Default', 'Default|Default');
        Observer.Expect('ReadCommitted', 'ReadCommitted');
        Observer.Expect('RepeatableRead', 'RepeatableRead');
        Observer.Expect('UpdLock', 'UpdLock');
        Observer.Verify();
    end;
}
