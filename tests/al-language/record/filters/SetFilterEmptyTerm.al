// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. SetFilter on a Text, a Code and an Integer field with an empty term next to an '|' (al-runner issue 7764, item 2):
//   '%1|' and '|%1' with a substituted value, 'A|', '|A' and 'A||B' written out, '%1|%2' with '' as the second or the first value, '%1'
//   with '', and '|' alone. RcAFilters.al already pins the Integer literals '|10' and '10|' and the Text literal '||'.
// Fixtures used: Probe Observer (69160); self-contained table 71907 and codeunit 71908.
// Probe: written for al-runner issue 7764, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <case> is 'filter=<GetFilter> ids=<Id of each row FindSet returns>' when SetFilter did not fail, or <case>|text and
//   <case>|code (GetLastErrorText and GetLastErrorCode) when the [TryFunction] around SetFilter returned false.
//   Rows: 1 Name 'A' Code 'A' Num 1; 2 'B' 'B' 2; 3 '' '' 0; 4 'AB' 'AB' 5.
// BC versions: 27, 28, 29

table 71907 "LT SfE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Cd; Code[20]) { }
        field(4; Num; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71908 "LT SfE Empty Term"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT SfE Row";
    begin
        Row.DeleteAll();
        Add(1, 'A', 1);
        Add(2, 'B', 2);
        Add(3, '', 0);
        Add(4, 'AB', 5);
    end;

    local procedure Add(Id: Integer; Value: Text; Num: Integer)
    var
        Row: Record "LT SfE Row";
    begin
        Row.Id := Id;
        Row.Name := CopyStr(Value, 1, 50);
        Row.Cd := CopyStr(Value, 1, 20);
        Row.Num := Num;
        Row.Insert();
    end;

    // Field 2 = Name (Text), 3 = Cd (Code), 4 = Num (Integer). ArgCount 0: no substitution value, 1: A1, 2: A1 and A2.
    [TryFunction]
    local procedure TrySetFilter(var Row: Record "LT SfE Row"; FieldNo: Integer; Expr: Text; ArgCount: Integer; A1: Variant; A2: Variant)
    begin
        case FieldNo of
            2:
                case ArgCount of
                    0:
                        Row.SetFilter(Name, Expr);
                    1:
                        Row.SetFilter(Name, Expr, A1);
                    2:
                        Row.SetFilter(Name, Expr, A1, A2);
                end;
            3:
                case ArgCount of
                    0:
                        Row.SetFilter(Cd, Expr);
                    1:
                        Row.SetFilter(Cd, Expr, A1);
                    2:
                        Row.SetFilter(Cd, Expr, A1, A2);
                end;
            4:
                case ArgCount of
                    0:
                        Row.SetFilter(Num, Expr);
                    1:
                        Row.SetFilter(Num, Expr, A1);
                    2:
                        Row.SetFilter(Num, Expr, A1, A2);
                end;
        end;
    end;

    local procedure Check(CaseName: Text; FieldNo: Integer; Expr: Text; ArgCount: Integer; A1: Variant; A2: Variant)
    var
        Row: Record "LT SfE Row";
        Ids: Text;
    begin
        ClearLastError();
        if not TrySetFilter(Row, FieldNo, Expr, ArgCount, A1, A2) then begin
            Observer.ObserveError(CaseName);
            exit;
        end;
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ',';
            until Row.Next() = 0;
        case FieldNo of
            2:
                Observer.Observe(CaseName, 'filter=' + Row.GetFilter(Name) + ' ids=' + Ids);
            3:
                Observer.Observe(CaseName, 'filter=' + Row.GetFilter(Cd) + ' ids=' + Ids);
            4:
                Observer.Observe(CaseName, 'filter=' + Row.GetFilter(Num) + ' ids=' + Ids);
        end;
    end;

    [Test]
    procedure Text_SubstitutedEmptyTerm()
    begin
        Seed();
        Check('sub_trailing_pipe', 2, '%1|', 1, 'A', '');
        Check('sub_leading_pipe', 2, '|%1', 1, 'A', '');
        Check('sub_second_empty', 2, '%1|%2', 2, 'A', '');
        Check('sub_first_empty', 2, '%1|%2', 2, '', 'A');
        Check('sub_only_empty', 2, '%1', 1, '', '');
        Observer.Finish();
    end;

    [Test]
    procedure Text_LiteralEmptyTerm()
    begin
        Seed();
        Check('lit_trailing_pipe', 2, 'A|', 0, '', '');
        Check('lit_leading_pipe', 2, '|A', 0, '', '');
        Check('lit_double_pipe', 2, 'A||B', 0, '', '');
        Check('lit_pipe_only', 2, '|', 0, '', '');
        Observer.Finish();
    end;

    [Test]
    procedure Code_SubstitutedEmptyTerm()
    begin
        Seed();
        Check('sub_trailing_pipe', 3, '%1|', 1, 'A', '');
        Check('sub_second_empty', 3, '%1|%2', 2, 'A', '');
        Check('sub_first_empty', 3, '%1|%2', 2, '', 'A');
        Check('sub_only_empty', 3, '%1', 1, '', '');
        Observer.Finish();
    end;

    [Test]
    procedure Code_LiteralEmptyTerm()
    begin
        Seed();
        Check('lit_trailing_pipe', 3, 'A|', 0, '', '');
        Check('lit_leading_pipe', 3, '|A', 0, '', '');
        Check('lit_double_pipe', 3, 'A||B', 0, '', '');
        Observer.Finish();
    end;

    [Test]
    procedure Integer_SubstitutedEmptyTerm()
    begin
        Seed();
        Check('sub_trailing_pipe', 4, '%1|', 1, 1, '');
        Check('sub_leading_pipe', 4, '|%1', 1, 1, '');
        Check('sub_second_zero', 4, '%1|%2', 2, 1, 0);
        Check('lit_double_pipe', 4, '1||2', 0, '', '');
        Observer.Finish();
    end;
    [TryFunction]
    local procedure TryIssueShape(var Row: Record "LT SfE Row"; Form: Integer)
    begin
        case Form of
            1:
                Row.SetFilter(Name, '%1|', 'A');
            2:
                Row.SetFilter(Name, '%1|%2', 'A', '');
        end;
    end;

    // The shape of the issue, with Text literals as substitution values (no Variant in between).
    [Test]
    procedure Text_IssueShape_LiteralArguments()
    var
        Row: Record "LT SfE Row";
        Ids: Text;
        Form: Integer;
    begin
        Seed();
        for Form := 1 to 2 do begin
            Row.Reset();
            Ids := '';
            ClearLastError();
            if TryIssueShape(Row, Form) then begin
                if Row.FindSet() then
                    repeat
                        Ids += Format(Row.Id) + ',';
                    until Row.Next() = 0;
                Observer.Observe('form' + Format(Form), 'filter=' + Row.GetFilter(Name) + ' ids=' + Ids);
            end else
                Observer.ObserveError('form' + Format(Form));
        end;
        Observer.Finish();
    end;
}
