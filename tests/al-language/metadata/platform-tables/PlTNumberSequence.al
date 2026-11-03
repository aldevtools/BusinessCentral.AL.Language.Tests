// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunits 74216 (basics), 74217 (errors), 74218 (limits and names)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: NumberSequence.Insert (Start, Increment, CycleOnLimit), Next, Current, Exists, Restart, Range, Delete.
// BC versions: 29 (27 and 28 by CI)

codeunit 74216 "LT PlT NumberSequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(SeqName: Text)
    begin
        if NumberSequence.Exists(SeqName) then
            NumberSequence.Delete(SeqName);
    end;

    [Test]
    procedure Basic_Defaults()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_A');
        Observer.Observe('exists_before', Format(NumberSequence.Exists('LTPLT_A')));
        NumberSequence.Insert('LTPLT_A');
        Observer.Observe('exists_after', Format(NumberSequence.Exists('LTPLT_A')));
        Observer.Observe('next_1', Format(NumberSequence.Next('LTPLT_A')));
        Observer.Observe('next_2', Format(NumberSequence.Next('LTPLT_A')));
        Observer.Observe('next_3', Format(NumberSequence.Next('LTPLT_A')));
        Observer.Observe('current', Format(NumberSequence.Current('LTPLT_A')));
        Observer.Observe('current_again', Format(NumberSequence.Current('LTPLT_A')));
        NumberSequence.Delete('LTPLT_A');
        Observer.Observe('exists_deleted', Format(NumberSequence.Exists('LTPLT_A')));
        Observer.Expect('exists_before', 'No');
        Observer.Expect('exists_after', 'Yes');
        Observer.Expect('next_1', '0');
        Observer.Expect('next_2', '1');
        Observer.Expect('next_3', '2');
        Observer.Expect('current', '2');
        Observer.Expect('current_again', '2');
        Observer.Expect('exists_deleted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Current_BeforeFirstNext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_B');
        NumberSequence.Insert('LTPLT_B');
        Observer.Observe('current_fresh', Format(NumberSequence.Current('LTPLT_B')));
        Observer.Observe('next', Format(NumberSequence.Next('LTPLT_B')));
        NumberSequence.Delete('LTPLT_B');
        Clean('LTPLT_B2');
        NumberSequence.Insert('LTPLT_B2', 10, 5);
        Observer.Observe('current_fresh_start10', Format(NumberSequence.Current('LTPLT_B2')));
        Observer.Observe('next_start10', Format(NumberSequence.Next('LTPLT_B2')));
        Observer.Observe('current_after_next', Format(NumberSequence.Current('LTPLT_B2')));
        NumberSequence.Delete('LTPLT_B2');
        Observer.Expect('current_fresh', '0');
        Observer.Expect('next', '0');
        Observer.Expect('current_fresh_start10', '10');
        Observer.Expect('next_start10', '10');
        Observer.Expect('current_after_next', '10');
        Observer.Verify();
    end;

    [Test]
    procedure StartAndIncrement_Positive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_C');
        NumberSequence.Insert('LTPLT_C', 10, 5);
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_C')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_C')));
        Observer.Observe('n3', Format(NumberSequence.Next('LTPLT_C')));
        Observer.Observe('current', Format(NumberSequence.Current('LTPLT_C')));
        NumberSequence.Delete('LTPLT_C');
        Clean('LTPLT_C2');
        NumberSequence.Insert('LTPLT_C2', 0, 1);
        Observer.Observe('zero_start_1', Format(NumberSequence.Next('LTPLT_C2')));
        Observer.Observe('zero_start_2', Format(NumberSequence.Next('LTPLT_C2')));
        NumberSequence.Delete('LTPLT_C2');
        Clean('LTPLT_C3');
        NumberSequence.Insert('LTPLT_C3', -5, 2);
        Observer.Observe('negative_start_1', Format(NumberSequence.Next('LTPLT_C3')));
        Observer.Observe('negative_start_2', Format(NumberSequence.Next('LTPLT_C3')));
        Observer.Observe('negative_start_3', Format(NumberSequence.Next('LTPLT_C3')));
        Observer.Observe('negative_start_4', Format(NumberSequence.Next('LTPLT_C3')));
        NumberSequence.Delete('LTPLT_C3');
        Observer.Expect('n1', '10');
        Observer.Expect('n2', '15');
        Observer.Expect('n3', '20');
        Observer.Expect('current', '20');
        Observer.Expect('zero_start_1', '0');
        Observer.Expect('zero_start_2', '1');
        Observer.Expect('negative_start_1', '-5');
        Observer.Expect('negative_start_2', '-3');
        Observer.Expect('negative_start_3', '-1');
        Observer.Expect('negative_start_4', '1');
        Observer.Verify();
    end;

    [Test]
    procedure StartAndIncrement_Descending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_D');
        NumberSequence.Insert('LTPLT_D', 100, -10);
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_D')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_D')));
        Observer.Observe('n3', Format(NumberSequence.Next('LTPLT_D')));
        Observer.Observe('current', Format(NumberSequence.Current('LTPLT_D')));
        NumberSequence.Delete('LTPLT_D');
        Clean('LTPLT_D2');
        NumberSequence.Insert('LTPLT_D2', 1, -1);
        Observer.Observe('through_zero_1', Format(NumberSequence.Next('LTPLT_D2')));
        Observer.Observe('through_zero_2', Format(NumberSequence.Next('LTPLT_D2')));
        Observer.Observe('through_zero_3', Format(NumberSequence.Next('LTPLT_D2')));
        NumberSequence.Delete('LTPLT_D2');
        Observer.Expect('n1', '100');
        Observer.Expect('n2', '90');
        Observer.Expect('n3', '80');
        Observer.Expect('current', '80');
        Observer.Expect('through_zero_1', '1');
        Observer.Expect('through_zero_2', '0');
        Observer.Expect('through_zero_3', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure Restart_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_E');
        NumberSequence.Insert('LTPLT_E', 100, 10);
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_E')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_E')));
        NumberSequence.Restart('LTPLT_E');
        Observer.Observe('after_restart_current', Format(NumberSequence.Current('LTPLT_E')));
        Observer.Observe('after_restart_next', Format(NumberSequence.Next('LTPLT_E')));
        NumberSequence.Restart('LTPLT_E', 500);
        Observer.Observe('restart_500_next', Format(NumberSequence.Next('LTPLT_E')));
        Observer.Observe('restart_500_next2', Format(NumberSequence.Next('LTPLT_E')));
        NumberSequence.Restart('LTPLT_E', -20);
        Observer.Observe('restart_negative', Format(NumberSequence.Next('LTPLT_E')));
        NumberSequence.Restart('LTPLT_E', 0);
        Observer.Observe('restart_zero', Format(NumberSequence.Next('LTPLT_E')));
        NumberSequence.Delete('LTPLT_E');
        Observer.Expect('n1', '100');
        Observer.Expect('n2', '110');
        Observer.Expect('after_restart_current', '0');
        Observer.Expect('after_restart_next', '0');
        Observer.Expect('restart_500_next', '500');
        Observer.Expect('restart_500_next2', '510');
        Observer.Expect('restart_negative', '-20');
        Observer.Expect('restart_zero', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Range_Variants()
    var
        Observer: Codeunit "Probe Observer";
        First: BigInteger;
    begin
        Clean('LTPLT_F');
        NumberSequence.Insert('LTPLT_F', 1, 2);
        Observer.Observe('r', Format(NumberSequence.Range('LTPLT_F', 5, First)));
        Observer.Observe('first_of_5', Format(First));
        Observer.Observe('next_after_range', Format(NumberSequence.Next('LTPLT_F')));
        Observer.Observe('r', Format(NumberSequence.Range('LTPLT_F', 1, First)));
        Observer.Observe('first_of_1', Format(First));
        asserterror Observer.Observe('r', Format(NumberSequence.Range('LTPLT_F', 0, First)));
        Observer.ObserveError('count_zero');
        asserterror Observer.Observe('r', Format(NumberSequence.Range('LTPLT_F', -3, First)));
        Observer.ObserveError('count_negative');
        NumberSequence.Delete('LTPLT_F');
        Observer.Expect('r', '1');
        Observer.Expect('first_of_5', '2');
        Observer.Expect('next_after_range', '11');
        Observer.Expect('r', '13');
        Observer.Expect('first_of_1', '2');
        Observer.Expect('count_zero|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('count_zero|code', 'Sql:Sql');
        Observer.Expect('count_negative|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('count_negative|code', 'Sql:Sql');
        Observer.Verify();
    end;

    [Test]
    procedure TwoSequences_AreIndependent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_G1');
        Clean('LTPLT_G2');
        NumberSequence.Insert('LTPLT_G1', 1, 1);
        NumberSequence.Insert('LTPLT_G2', 1000, 1);
        Observer.Observe('g1_1', Format(NumberSequence.Next('LTPLT_G1')));
        Observer.Observe('g2_1', Format(NumberSequence.Next('LTPLT_G2')));
        Observer.Observe('g1_2', Format(NumberSequence.Next('LTPLT_G1')));
        NumberSequence.Delete('LTPLT_G1');
        Observer.Observe('g1_exists', Format(NumberSequence.Exists('LTPLT_G1')));
        Observer.Observe('g2_exists', Format(NumberSequence.Exists('LTPLT_G2')));
        Observer.Observe('g2_2', Format(NumberSequence.Next('LTPLT_G2')));
        NumberSequence.Delete('LTPLT_G2');
        Observer.Expect('g1_1', '1');
        Observer.Expect('g2_1', '1000');
        Observer.Expect('g1_2', '2');
        Observer.Expect('g1_exists', 'No');
        Observer.Expect('g2_exists', 'Yes');
        Observer.Expect('g2_2', '1001');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAndReinsert_StartsOver()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_H');
        NumberSequence.Insert('LTPLT_H', 1, 1);
        Observer.Observe('r', Format(NumberSequence.Next('LTPLT_H')));
        Observer.Observe('r', Format(NumberSequence.Next('LTPLT_H')));
        NumberSequence.Delete('LTPLT_H');
        NumberSequence.Insert('LTPLT_H', 1, 1);
        Observer.Observe('first_after_reinsert', Format(NumberSequence.Next('LTPLT_H')));
        NumberSequence.Delete('LTPLT_H');
        Observer.Expect('r', '1');
        Observer.Expect('r', '2');
        Observer.Expect('first_after_reinsert', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Next_NotRolledBackByError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_I');
        NumberSequence.Insert('LTPLT_I', 1, 1);
        asserterror
        begin
            Observer.Observe('r', Format(NumberSequence.Next('LTPLT_I')));
            Observer.Observe('r', Format(NumberSequence.Next('LTPLT_I')));
            Error('boom');
        end;
        Observer.ObserveError('err');
        Observer.Observe('next_after_rollback', Format(NumberSequence.Next('LTPLT_I')));
        NumberSequence.Delete('LTPLT_I');
        Observer.Expect('r', '1');
        Observer.Expect('r', '2');
        Observer.Expect('err|text', 'boom');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('next_after_rollback', '3');
        Observer.Verify();
    end;
}

codeunit 74217 "LT PlT NumberSequence Err"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(SeqName: Text)
    begin
        if NumberSequence.Exists(SeqName) then
            NumberSequence.Delete(SeqName);
    end;

    [Test]
    procedure Insert_Duplicate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_X1');
        NumberSequence.Insert('LTPLT_X1');
        asserterror NumberSequence.Insert('LTPLT_X1');
        Observer.ObserveError('duplicate');
        NumberSequence.Insert('LTPLT_X1', 5, 5);
        Observer.Observe('duplicate_with_args', 'no error');
        Observer.Observe('still_exists', Format(NumberSequence.Exists('LTPLT_X1')));
        NumberSequence.Delete('LTPLT_X1');
        Observer.Expect('duplicate|text', 'The number sequence ''LTPLT_X1'' already exists.');
        Observer.Expect('duplicate|code', 'AL');
        Observer.Expect('duplicate_with_args', 'no error');
        Observer.Expect('still_exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Current_Unknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_X2');
        asserterror Observer.Observe('r', Format(NumberSequence.Next('LTPLT_X2')));
        Observer.ObserveError('next');
        asserterror Observer.Observe('r', Format(NumberSequence.Current('LTPLT_X2')));
        Observer.ObserveError('current');
        Observer.Expect('next|text', 'The number sequence ''LTPLT_X2'' does not exist.');
        Observer.Expect('next|code', 'AL');
        Observer.Expect('current|text', 'The number sequence ''LTPLT_X2'' does not exist.');
        Observer.Expect('current|code', 'AL');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_Restart_Unknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_X3');
        NumberSequence.Delete('LTPLT_X3');
        Observer.Observe('delete', 'no error');
        asserterror NumberSequence.Restart('LTPLT_X3');
        Observer.ObserveError('restart');
        asserterror NumberSequence.Restart('LTPLT_X3', 5);
        Observer.ObserveError('restart_value');
        Observer.Observe('exists', Format(NumberSequence.Exists('LTPLT_X3')));
        Observer.Expect('delete', 'no error');
        Observer.Expect('restart|text', 'The number sequence ''LTPLT_X3'' does not exist.');
        Observer.Expect('restart|code', 'AL');
        Observer.Expect('restart_value|text', 'The number sequence ''LTPLT_X3'' does not exist.');
        Observer.Expect('restart_value|code', 'AL');
        Observer.Expect('exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ZeroIncrement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_X4');
        asserterror NumberSequence.Insert('LTPLT_X4', 1, 0);
        Observer.ObserveError('zero_increment');
        Observer.Observe('exists', Format(NumberSequence.Exists('LTPLT_X4')));
        Clean('LTPLT_X4');
        Observer.Expect('zero_increment|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('zero_increment|code', 'Sql:Sql');
        Observer.Expect('exists', 'No');
        Observer.Verify();
    end;

}

codeunit 74218 "LT PlT NumberSequence Limits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(SeqName: Text)
    begin
        if NumberSequence.Exists(SeqName) then
            NumberSequence.Delete(SeqName);
    end;

    local procedure Big(Value: Text): BigInteger
    var
        Result: BigInteger;
    begin
        Evaluate(Result, Value);
        exit(Result);
    end;

    [Test]
    procedure UpperLimit_NoCycle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_L1');
        NumberSequence.Insert('LTPLT_L1', Big('9223372036854775806'), 1);
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_L1')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_L1')));
        asserterror Observer.Observe('r', Format(NumberSequence.Next('LTPLT_L1')));
        Observer.ObserveError('beyond_max');
        asserterror Observer.Observe('current_after_error', Format(NumberSequence.Current('LTPLT_L1')));
        Observer.ObserveError('af340');
        NumberSequence.Delete('LTPLT_L1');
        Observer.Expect('n1', '9223372036854775806');
        Observer.Expect('n2', '9223372036854775807');
        Observer.Expect('beyond_max|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('beyond_max|code', 'Sql:Sql');
        Observer.Expect('af340|text', 'The number sequence ''LTPLT_L1'' does not exist.');
        Observer.Expect('af340|code', 'AL');
        Observer.Verify();
    end;

    [Test]
    procedure LowerLimit_Descending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_L3');
        NumberSequence.Insert('LTPLT_L3', Big('-9223372036854775807'), -1);
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_L3')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_L3')));
        asserterror Observer.Observe('r', Format(NumberSequence.Next('LTPLT_L3')));
        Observer.ObserveError('beyond_min');
        NumberSequence.Delete('LTPLT_L3');
        Observer.Expect('n1', '-9223372036854775807');
        Observer.Expect('n2', '-9223372036854775808');
        Observer.Expect('beyond_min|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('beyond_min|code', 'Sql:Sql');
        Observer.Verify();
    end;

    [Test]
    procedure LargeIncrement_NoCycle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_L4');
        NumberSequence.Insert('LTPLT_L4', 1, Big('4611686018427387904'));
        Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_L4')));
        Observer.Observe('n2', Format(NumberSequence.Next('LTPLT_L4')));
        asserterror Observer.Observe('r', Format(NumberSequence.Next('LTPLT_L4')));
        Observer.ObserveError('overflow');
        NumberSequence.Delete('LTPLT_L4');
        Observer.Expect('n1', '1');
        Observer.Expect('n2', '4611686018427387905');
        Observer.Expect('overflow|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('overflow|code', 'Sql:Sql');
        Observer.Verify();
    end;

    [Test]
    procedure CycleFlag_FalseExplicit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_L5');
        NumberSequence.Insert('LTPLT_L5', Big('9223372036854775807'), 1, false);
        asserterror Observer.Observe('n1', Format(NumberSequence.Next('LTPLT_L5')));
        Observer.ObserveError('af399');
        asserterror Observer.Observe('r', Format(NumberSequence.Next('LTPLT_L5')));
        Observer.ObserveError('beyond_max');
        NumberSequence.Delete('LTPLT_L5');
        Observer.Expect('af399|text', 'The number sequence ''LTPLT_L5'' does not exist.');
        Observer.Expect('af399|code', 'AL');
        Observer.Expect('beyond_max|text', 'The number sequence ''LTPLT_L5'' does not exist.');
        Observer.Expect('beyond_max|code', 'AL');
        Observer.Verify();
    end;

    [Test]
    procedure Names_CaseSpacesUnicode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean('LTPLT_n');
        Clean('LTPLT_N');
        NumberSequence.Insert('LTPLT_n');
        Observer.Observe('exists_lower', Format(NumberSequence.Exists('LTPLT_n')));
        Observer.Observe('exists_upper', Format(NumberSequence.Exists('LTPLT_N')));
        NumberSequence.Insert('LTPLT_N');
        Observer.Observe('both', Format(NumberSequence.Exists('LTPLT_n')) + '|' + Format(NumberSequence.Exists('LTPLT_N')));
        Observer.Observe('r', Format(NumberSequence.Next('LTPLT_n')));
        Observer.Observe('upper_independent', Format(NumberSequence.Next('LTPLT_N')));
        NumberSequence.Delete('LTPLT_n');
        Observer.Observe('upper_after_lower_deleted', Format(NumberSequence.Exists('LTPLT_N')));
        NumberSequence.Delete('LTPLT_N');
        Clean('LTPLT with spaces');
        NumberSequence.Insert('LTPLT with spaces');
        Observer.Observe('spaces', Format(NumberSequence.Next('LTPLT with spaces')));
        NumberSequence.Delete('LTPLT with spaces');
        Observer.Expect('exists_lower', 'Yes');
        Observer.Expect('exists_upper', 'No');
        Observer.Expect('both', 'Yes|Yes');
        Observer.Expect('r', '0');
        Observer.Expect('upper_independent', '0');
        Observer.Expect('upper_after_lower_deleted', 'Yes');
        Observer.Expect('spaces', '0');
        Observer.Verify();
    end;
}
