// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67293
// The empty statement (a lone semicolon): it compiles and does nothing as a whole body, in the branches of if, in case branches and in loop bodies, and several in a row.
// BC versions: 27, 28, 29
codeunit 67293 "LT P Empty Statement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OnlyEmptyBody()
    begin
        ;
    end;

    local procedure ManyEmpty(): Integer
    begin
        ;;;
        exit(7);
        ;
    end;

    [Test]
    procedure PEmpty_Bodies()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        OnlyEmptyBody();
        Observer.Observe('procedure_with_only_empty', 'ran');
        Observer.Observe('many_empty_then_exit', Format(ManyEmpty()));
        N := 1;
        ;
        Observer.Observe('after_lone_semicolon', Format(N));
        begin
            ;
        end;
        Observer.Expect('procedure_with_only_empty', 'ran');
        Observer.Expect('many_empty_then_exit', '7');
        Observer.Expect('after_lone_semicolon', '1');
        Observer.Verify();
    end;

    [Test]
    procedure PEmpty_InIf()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        N := 1;
        if true then
            ;
        Observer.Observe('if_true_empty_then', Format(N));
        if false then
            N := 2
        else
            ;
        Observer.Observe('if_false_empty_else', Format(N));
        if true then
            ;
        N += 1;
        Observer.Observe('statement_after_empty_if', Format(N));
        if N = 2 then begin
            ;
        end;
        Observer.Observe('empty_in_begin_end', Format(N));
        Observer.Expect('if_true_empty_then', '1');
        Observer.Expect('if_false_empty_else', '1');
        Observer.Expect('statement_after_empty_if', '2');
        Observer.Expect('empty_in_begin_end', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PEmpty_InCase()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
        Hits: Text;
    begin
        for N := 1 to 4 do
            case N of
                1:
                    ;
                2:
                    Hits += 'two;';
                3:
                    begin
                        ;
                    end;
                else
                    ;
            end;
        Observer.Observe('case_hits', Hits);
        N := 9;
        case N of
            9:
                ;
        end;
        Observer.Observe('case_single_empty_branch', Format(N));
        Observer.Expect('case_hits', 'two;');
        Observer.Expect('case_single_empty_branch', '9');
        Observer.Verify();
    end;

    [Test]
    procedure PEmpty_InLoops()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        N: Integer;
    begin
        for I := 1 to 3 do
            ;
        Observer.Observe('for_empty_body_index', Format(I));
        for I := 3 downto 1 do
            ;
        Observer.Observe('for_downto_empty_body_index', Format(I));
        N := 0;
        while N < 3 do
            N += 1;
        Observer.Observe('while_counter', Format(N));
        while false do
            ;
        Observer.Observe('while_false_empty', Format(N));
        N := 0;
        repeat
            ;
            N += 1;
        until N = 2;
        Observer.Observe('repeat_empty_then_count', Format(N));
        repeat
            ;
        until true;
        Observer.Observe('repeat_only_empty', Format(N));
        Observer.Expect('for_empty_body_index', '3');
        Observer.Expect('for_downto_empty_body_index', '1');
        Observer.Expect('while_counter', '3');
        Observer.Expect('while_false_empty', '3');
        Observer.Expect('repeat_empty_then_count', '2');
        Observer.Expect('repeat_only_empty', '2');
        Observer.Verify();
    end;
}
