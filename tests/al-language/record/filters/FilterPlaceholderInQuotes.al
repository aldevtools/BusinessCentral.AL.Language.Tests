// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70380, codeunit 70381
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "filter-placeholder-in-quotes" (Assumptions in force)
// Facts: SetFilter with a %n inside a quoted part of the filter text ('%1'|'%2') and blank, non-blank, Integer and Code arguments; GetFilter, Count and the rows found
// BC versions: 29 (27 and 28 by CI)

table 70380 "LT FPQ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[10]) { }
        field(4; Num; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70381 "LT FPQ Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT FPQ Row";

    begin
        R.DeleteAll();
        Add(1, '', '', 0);
        Add(2, 'A', 'A', 1);
        Add(3, 'B', 'B', 2);
        Add(4, '|', 'X', 3);
        Add(5, '%1', 'Y', 1);
    end;

    local procedure Add(Id: Integer; Txt: Text[30]; Cd: Code[10]; Num: Integer)
    var
        R: Record "LT FPQ Row";
    begin
        R.Id := Id;
        R.Txt := Txt;
        R.Cd := Cd;
        R.Num := Num;
        R.Insert();
    end;

    local procedure Ids(var R: Record "LT FPQ Row"): Text
    var
        S: Text;
    begin
        if R.FindSet() then
            repeat
                S += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(S);
    end;

    [Test]
    procedure P169_QuotedPlaceholders_BlankAndA()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''%1''|''%2''', '', 'A');
        Observer.Observe('filter', R.GetFilter(Txt));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('ids', Ids(R));
        Observer.Expect('filter', '''''|A');
        Observer.Expect('count', '2');
        Observer.Expect('ids', '1,2,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholders_TwoNonBlank()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''%1''|''%2''', 'A', 'B');
        Observer.Observe('filter', R.GetFilter(Txt));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('ids', Ids(R));
        Observer.Expect('filter', 'A|B');
        Observer.Expect('count', '2');
        Observer.Expect('ids', '2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholder_Single()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''%1''', 'A');
        Observer.Observe('single_A_filter', R.GetFilter(Txt));
        Observer.Observe('single_A_ids', Ids(R));
        R.Reset();
        R.SetFilter(Txt, '''%1''', '');
        Observer.Observe('single_blank_filter', R.GetFilter(Txt));
        Observer.Observe('single_blank_ids', Ids(R));
        Observer.Expect('single_A_filter', 'A');
        Observer.Expect('single_A_ids', '2,');
        Observer.Expect('single_blank_filter', '''''');
        Observer.Expect('single_blank_ids', '1,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholder_ArgumentWithSpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''%1''', '|');
        Observer.Observe('pipe_filter', R.GetFilter(Txt));
        Observer.Observe('pipe_ids', Ids(R));
        R.Reset();
        R.SetFilter(Txt, '''%1''', '%1');
        Observer.Observe('pct_filter', R.GetFilter(Txt));
        Observer.Observe('pct_ids', Ids(R));
        Observer.Expect('pipe_filter', '''|''');
        Observer.Expect('pipe_ids', '4,');
        Observer.Expect('pct_filter', '%1');
        Observer.Expect('pct_ids', '5,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholder_IntegerArgument()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''%1''|''%2''', Format(1), Format(2));
        Observer.Observe('int_text_filter', R.GetFilter(Txt));
        Observer.Observe('int_text_ids', Ids(R));
        R.Reset();
        R.SetFilter(Num, '''%1''|''%2''', 1, 2);
        Observer.Observe('int_field_quoted', 'no error');
        R.Reset();
        R.SetFilter(Num, '%1|%2', 1, 2);
        Observer.Observe('int_field_plain_filter', R.GetFilter(Num));
        Observer.Observe('int_field_plain_ids', Ids(R));
        Observer.Expect('int_text_filter', '1|2');
        Observer.Expect('int_text_ids', '');
        Observer.Expect('int_field_quoted', 'no error');
        Observer.Expect('int_field_plain_filter', '1|2');
        Observer.Expect('int_field_plain_ids', '2,3,5,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholder_CodeArgument()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
        C1: Code[10];
        C2: Code[10];
    begin
        Seed();
        C1 := 'a';
        C2 := '';
        R.SetFilter(Cd, '''%1''|''%2''', C1, C2);
        Observer.Observe('code_filter', R.GetFilter(Cd));
        Observer.Observe('code_count', Format(R.Count()));
        Observer.Observe('code_ids', Ids(R));
        R.Reset();
        R.SetFilter(Cd, '%1|%2', C1, C2);
        Observer.Observe('code_plain_filter', R.GetFilter(Cd));
        Observer.Observe('code_plain_ids', Ids(R));
        Observer.Expect('code_filter', 'A|''''');
        Observer.Expect('code_count', '2');
        Observer.Expect('code_ids', '1,2,');
        Observer.Expect('code_plain_filter', 'A|''''');
        Observer.Expect('code_plain_ids', '1,2,');
        Observer.Verify();
    end;

    [Test]
    procedure P169_QuotedPlaceholder_InsideLongerQuotedText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT FPQ Row";
    begin
        Seed();
        R.SetFilter(Txt, '''x%1y''', 'A');
        Observer.Observe('embedded_filter', R.GetFilter(Txt));
        Observer.Observe('embedded_count', Format(R.Count()));
        R.Reset();
        R.SetFilter(Txt, '''%1%2''', 'A', 'B');
        Observer.Observe('adjacent_filter', R.GetFilter(Txt));
        Observer.Observe('adjacent_count', Format(R.Count()));
        R.Reset();
        R.SetFilter(Txt, '''%1''|%2', '', 'B');
        Observer.Observe('mixed_filter', R.GetFilter(Txt));
        Observer.Observe('mixed_ids', Ids(R));
        Observer.Expect('embedded_filter', 'x%1y');
        Observer.Expect('embedded_count', '0');
        Observer.Expect('adjacent_filter', '%1%2');
        Observer.Expect('adjacent_count', '0');
        Observer.Expect('mixed_filter', '''''|B');
        Observer.Expect('mixed_ids', '1,3,');
        Observer.Verify();
    end;
}
