// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71162, codeunit 71163
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): text builtins with an Option argument
// Facts: the text an Option contributes to StrSubstNo, Format, concatenation, Evaluate, SelectStr(text arg), an Option field and a global Option with spaces, empty member, and a caption
// BC versions: 29 (27 and 28 by CI)

table 71162 "LT P69 Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Status; Option)
        {
            OptionMembers = Open,"In Progress",Done;
            OptionCaption = 'Open,In Progress,Done';
        }
        field(3; Plain; Option) { OptionMembers = Alpha,Beta,Gamma; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71163 "LT P69 Option In Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Choice: Option Zero,"Some Two",,Four;

    [TryFunction]
    local procedure TrySubst(Pattern: Text; O: Option Zero,"Some Two",,Four; var R: Text)
    begin
        R := StrSubstNo(Pattern, O);
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Option_StrSubstNo()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
        i: Integer;
    begin
        for i := 0 to 3 do begin
            Choice := i;
            Ok := TrySubst('[%1]', Choice, R);
            Observer.Observe('subst_' + Format(i), Res(Ok, R));
        end;
        Choice := Choice::"Some Two";
        Observer.Observe('subst_two_args', StrSubstNo('%1/%2', Choice, Choice::Four));
        Observer.Observe('subst_member_literal', StrSubstNo('%1', Choice::Four));
        Observer.Observe('subst_len', Format(StrLen(StrSubstNo('%1', Choice))));
        Observer.Expect('subst_0', '[Zero]');
        Observer.Expect('subst_1', '[Some Two]');
        Observer.Expect('subst_2', '[2]');
        Observer.Expect('subst_3', '[Four]');
        Observer.Expect('subst_two_args', 'Some Two/Four');
        Observer.Expect('subst_member_literal', 'Four');
        Observer.Expect('subst_len', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Option_FormatAndConcat()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 3 do begin
            Choice := i;
            Observer.Observe('format_' + Format(i), Format(Choice));
            Observer.Observe('format_ord_' + Format(i), Format(Choice, 0, 2));
            Observer.Observe('format_xml_' + Format(i), Format(Choice, 0, 9));
        end;
        Choice := Choice::"Some Two";
        Observer.Observe('concat', 'v=' + Format(Choice));
        Observer.Observe('format_width', Format(Choice, 20));
        Observer.Observe('format_pattern', Format(Choice, 0, '<Text,5>'));
        Observer.Expect('format_0', 'Zero');
        Observer.Expect('format_ord_0', '0');
        Observer.Expect('format_xml_0', '0');
        Observer.Expect('format_1', 'Some Two');
        Observer.Expect('format_ord_1', '1');
        Observer.Expect('format_xml_1', '1');
        Observer.Expect('format_2', '2');
        Observer.Expect('format_ord_2', '2');
        Observer.Expect('format_xml_2', '2');
        Observer.Expect('format_3', 'Four');
        Observer.Expect('format_ord_3', '3');
        Observer.Expect('format_xml_3', '3');
        Observer.Expect('concat', 'v=Some Two');
        Observer.Expect('format_width', 'Some Two            ');
        Observer.Expect('format_pattern', 'Some ');
        Observer.Verify();
    end;

    [Test]
    procedure Option_SelectStrAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Opt Row";
        O: Option Zero,"Some Two",,Four;
        Ok: Boolean;
    begin
        Choice := Choice::Four;
        Observer.Observe('selectstr_text_of_option', SelectStr(2, Format(Choice) + ',b,c'));
        Observer.Observe('selectstr_second', SelectStr(2, 'a,' + Format(Choice::"Some Two") + ',c'));
        Ok := Evaluate(O, 'Some Two');
        Observer.Observe('eval_name', Format(Ok) + '|' + Format(O, 0, 2));
        Ok := Evaluate(O, '3');
        Observer.Observe('eval_ordinal_text', Format(Ok) + '|' + Format(O, 0, 2));
        Ok := Evaluate(O, 'four');
        Observer.Observe('eval_lowercase', Format(Ok) + '|' + Format(O, 0, 2));
        Ok := Evaluate(O, 'Nope');
        Observer.Observe('eval_unknown', Format(Ok));
        Ok := Evaluate(O, '9');
        Observer.Observe('eval_out_of_range', Format(Ok));
        Row.DeleteAll();
        Row.Id := 1;
        Row.Status := Row.Status::"In Progress";
        Row.Plain := Row.Plain::Gamma;
        Row.Insert();
        Observer.Observe('field_status', StrSubstNo('%1', Row.Status));
        Observer.Observe('field_plain', StrSubstNo('%1', Row.Plain));
        Observer.Observe('field_format_status', Format(Row.Status));
        Observer.Observe('field_status_ordinal', Format(Row.Status, 0, 2));
        Observer.Expect('selectstr_text_of_option', 'b');
        Observer.Expect('selectstr_second', 'Some Two');
        Observer.Expect('eval_name', 'Yes|1');
        Observer.Expect('eval_ordinal_text', 'Yes|3');
        Observer.Expect('eval_lowercase', 'Yes|3');
        Observer.Expect('eval_unknown', 'No');
        Observer.Expect('eval_out_of_range', 'Yes');
        Observer.Expect('field_status', 'In Progress');
        Observer.Expect('field_plain', 'Gamma');
        Observer.Expect('field_format_status', 'In Progress');
        Observer.Expect('field_status_ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Option_OtherTextBuiltins()
    var
        Observer: Codeunit "Probe Observer";
        Builder: TextBuilder;
        L: List of [Text];
        Row: Record "LT P69 Opt Row";
    begin
        Choice := Choice::"Some Two";
        Observer.Observe('uppercase', UpperCase(Format(Choice)));
        Observer.Observe('strpos', Format(StrPos(Format(Choice), 'Two')));
        Observer.Observe('copystr', CopyStr(Format(Choice), 1, 4));
        Observer.Observe('padstr', PadStr(Format(Choice), 10, '.'));
        Observer.Observe('incstr_int', Format(StrLen(Format(Choice::Four))));
        Builder.Append(Format(Choice));
        Observer.Observe('textbuilder', Builder.ToText());
        L.Add(Format(Choice::Four));
        Observer.Observe('list', L.Get(1));
        Observer.Observe('tablecaption_fieldcaption', Row.FieldCaption(Status));
        Observer.Observe('optionstring', Row.FieldName(Plain));
        Observer.Observe('error_text', Format(StrSubstNo('%1 of %2', Choice, Format(Choice::Four))));
        Observer.Expect('uppercase', 'SOME TWO');
        Observer.Expect('strpos', '6');
        Observer.Expect('copystr', 'Some');
        Observer.Expect('padstr', 'Some Two..');
        Observer.Expect('incstr_int', '4');
        Observer.Expect('textbuilder', 'Some Two');
        Observer.Expect('list', 'Four');
        Observer.Expect('tablecaption_fieldcaption', 'Status');
        Observer.Expect('optionstring', 'Plain');
        Observer.Expect('error_text', 'Some Two of Four');
        Observer.Verify();
    end;
}
