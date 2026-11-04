// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72874, enum 72875
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Rec.Option) with captions equal, shorter and longer than the member list, blank entries; Format with Length 0/3/10 and FormatNumber 0/1/2; FieldRef; Evaluate of a caption and of a member name; an Enum field for comparison
// BC versions: 29 (27 and 28 by CI)

enum 72875 "LT FmtOpt Kind"
{
    Extensible = true;
    value(0; Alpha) { Caption = 'Alfa'; }
    value(1; Beta) { Caption = 'Bravo'; }
}

table 72874 "LT FmtOpt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Option) { OptionMembers = A,B,C; }
        field(3; Cap; Option) { OptionMembers = Red,Green,Blue; OptionCaption = 'Rouge,Vert,Bleu'; }
        field(4; Short; Option) { OptionMembers = One,Two,Three; OptionCaption = 'Uno,Dos'; }
        field(5; Long; Option) { OptionMembers = One,Two; OptionCaption = 'Uno,Dos,Tres,Quatro'; }
        field(6; Blank; Option) { OptionMembers = " ",Alpha,Beta; OptionCaption = ' ,Alfa,Beta2'; }
        field(7; Kind; Enum "LT FmtOpt Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72876 "LT FmtOpt Captions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(var Row: Record "LT FmtOpt Row"; Which: Integer; Len: Integer; Num: Integer; var R: Text)
    begin
        case Which of
            1:
                R := Format(Row.Plain, Len, Num);
            2:
                R := Format(Row.Cap, Len, Num);
            3:
                R := Format(Row.Short, Len, Num);
            4:
                R := Format(Row.Long, Len, Num);
            5:
                R := Format(Row.Blank, Len, Num);
            6:
                R := Format(Row.Kind, Len, Num);
        end;
    end;

    local procedure Fmt(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT FmtOpt Row"; Which: Integer; Len: Integer; Num: Integer)
    var
        R: Text;
    begin
        if TryFmt(Row, Which, Len, Num, R) then
            Observer.Observe(Name, '<' + R + '>')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Seed(var Row: Record "LT FmtOpt Row"; Idx: Integer)
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Plain := Idx;
        Row.Cap := Idx;
        Row.Short := Idx;
        Row.Long := Idx;
        Row.Blank := Idx;
        Row.Kind := Idx;
        Row.Insert();
    end;

    [Test]
    procedure FormatOption_MiddleMember()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FmtOpt Row";
    begin
        Seed(Row, 1);
        Fmt(Observer, 'plain', Row, 1, 0, 0);
        Fmt(Observer, 'cap', Row, 2, 0, 0);
        Fmt(Observer, 'short', Row, 3, 0, 0);
        Fmt(Observer, 'long', Row, 4, 0, 0);
        Fmt(Observer, 'blank', Row, 5, 0, 0);
        Fmt(Observer, 'enum', Row, 6, 0, 0);
        Observer.Expect('plain', '<B>');
        Observer.Expect('cap', '<Vert>');
        Observer.Expect('short', '<Dos>');
        Observer.Expect('long', '<Dos>');
        Observer.Expect('blank', '<Alfa>');
        Observer.Expect('enum', '<Bravo>');
        Observer.Verify();
    end;

    [Test]
    procedure FormatOption_MemberPastShortCaptionList()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FmtOpt Row";
    begin
        Seed(Row, 2);
        Fmt(Observer, 'plainC', Row, 1, 0, 0);
        Fmt(Observer, 'capBlue', Row, 2, 0, 0);
        Fmt(Observer, 'shortThree', Row, 3, 0, 0);
        Fmt(Observer, 'longThree', Row, 4, 0, 0);
        Fmt(Observer, 'blankBeta', Row, 5, 0, 0);
        Observer.Expect('plainC', '<C>');
        Observer.Expect('capBlue', '<Bleu>');
        Observer.Expect('shortThree', '<Three>');
        Observer.Expect('longThree', '<2>');
        Observer.Expect('blankBeta', '<Beta2>');
        Observer.Verify();
    end;

    [Test]
    procedure FormatOption_FirstMemberAndBlank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FmtOpt Row";
    begin
        Seed(Row, 0);
        Fmt(Observer, 'plainA', Row, 1, 0, 0);
        Fmt(Observer, 'capRed', Row, 2, 0, 0);
        Fmt(Observer, 'shortOne', Row, 3, 0, 0);
        Fmt(Observer, 'blankBlank', Row, 5, 0, 0);
        Fmt(Observer, 'enumAlpha', Row, 6, 0, 0);
        Observer.Expect('plainA', '<A>');
        Observer.Expect('capRed', '<Rouge>');
        Observer.Expect('shortOne', '<Uno>');
        Observer.Expect('blankBlank', '< >');
        Observer.Expect('enumAlpha', '<Alfa>');
        Observer.Verify();
    end;

    [Test]
    procedure FormatOption_LengthAndFormatNumber()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FmtOpt Row";
    begin
        Seed(Row, 1);
        Fmt(Observer, 'cap_len3', Row, 2, 3, 0);
        Fmt(Observer, 'cap_len10', Row, 2, 10, 0);
        Fmt(Observer, 'cap_len0_num0', Row, 2, 0, 0);
        Fmt(Observer, 'cap_len0_num1', Row, 2, 0, 1);
        Fmt(Observer, 'cap_len0_num2', Row, 2, 0, 2);
        Fmt(Observer, 'cap_len0_num9', Row, 2, 0, 9);
        Fmt(Observer, 'cap_len6_num1', Row, 2, 6, 1);
        Fmt(Observer, 'cap_len6_num2', Row, 2, 6, 2);
        Fmt(Observer, 'plain_num1', Row, 1, 0, 1);
        Fmt(Observer, 'plain_num2', Row, 1, 0, 2);
        Fmt(Observer, 'short_num1', Row, 3, 0, 1);
        Fmt(Observer, 'long_num1', Row, 4, 0, 1);
        Fmt(Observer, 'enum_num1', Row, 6, 0, 1);
        Fmt(Observer, 'enum_num2', Row, 6, 0, 2);
        Observer.Expect('cap_len3', '<Ver>');
        Observer.Expect('cap_len10', '<Vert      >');
        Observer.Expect('cap_len0_num0', '<Vert>');
        Observer.Expect('cap_len0_num1', '<Vert>');
        Observer.Expect('cap_len0_num2', '<1>');
        Observer.Expect('cap_len0_num9', '<1>');
        Observer.Expect('cap_len6_num1', '<Vert  >');
        Observer.Expect('cap_len6_num2', '<1     >');
        Observer.Expect('plain_num1', '<B>');
        Observer.Expect('plain_num2', '<1>');
        Observer.Expect('short_num1', '<Dos>');
        Observer.Expect('long_num1', '<Dos>');
        Observer.Expect('enum_num1', '<Bravo>');
        Observer.Expect('enum_num2', '<1>');
        Observer.Verify();
    end;

    [Test]
    procedure FormatOption_FieldRefAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FmtOpt Row";
        RR: RecordRef;
        FR: FieldRef;
        Tmp: Record "LT FmtOpt Row";
    begin
        Seed(Row, 1);
        RR.GetTable(Row);
        FR := RR.Field(3);
        Observer.Observe('fr_value', Format(FR.Value));
        Observer.Observe('fr_format', Format(FR));
        Observer.Observe('fr_optionCaption', FR.OptionCaption());
        Observer.Observe('fr_optionMembers', FR.OptionMembers());
        FR := RR.Field(4);
        Observer.Observe('frShort_optionCaption', FR.OptionCaption());
        Observer.Observe('frShort_optionMembers', FR.OptionMembers());
        Observer.Observe('frShort_format', Format(FR));
        Observer.Observe('eval_caption', Format(Evaluate(Tmp.Cap, 'Vert')) + ' ' + Format(Tmp.Cap, 0, 2));
        Observer.Observe('eval_member', Format(Evaluate(Tmp.Cap, 'Blue')) + ' ' + Format(Tmp.Cap, 0, 2));
        Observer.Observe('eval_ordinal', Format(Evaluate(Tmp.Cap, '2')) + ' ' + Format(Tmp.Cap, 0, 2));
        Observer.Observe('eval_unknown', Format(Evaluate(Tmp.Cap, 'Nothing')));
        Observer.Expect('fr_value', 'Vert');
        Observer.Expect('fr_format', 'Vert');
        Observer.Expect('fr_optionCaption', 'Rouge,Vert,Bleu');
        Observer.Expect('fr_optionMembers', 'Red,Green,Blue');
        Observer.Expect('frShort_optionCaption', 'Uno,Dos,Three');
        Observer.Expect('frShort_optionMembers', 'One,Two,Three');
        Observer.Expect('frShort_format', 'Dos');
        Observer.Expect('eval_caption', 'Yes 1');
        Observer.Expect('eval_member', 'Yes 2');
        Observer.Expect('eval_ordinal', 'Yes 2');
        Observer.Expect('eval_unknown', 'No');
        Observer.Verify();
    end;
}
