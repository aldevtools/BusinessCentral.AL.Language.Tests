// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-currfieldno-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70908, codeunit 70909
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a callee that assigns its var parameter when CurrFieldNo was passed: is CurrFieldNo changed afterwards; with the default 0 and with an assigned CurrFieldNo; through two levels; inside a Validate trigger
// BC versions: 29 (27 and 28 by CI)

table 70908 "LT P170 Curr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal)
        {
            trigger OnValidate()
            begin
                SeenInValidate := CurrFieldNo;
                SetN(CurrFieldNo);
                SeenAfterInValidate := CurrFieldNo;
            end;
        }
        field(3; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        SeenInValidate: Integer;
        SeenAfterInValidate: Integer;

    local procedure SetN(var N: Integer)
    begin
        N := 99;
    end;

    local procedure SetNAndPassOn(var N: Integer)
    begin
        SetN(N);
    end;

    procedure PassAndAssign(): Text
    var
        Before: Integer;
        After: Integer;
    begin
        Before := CurrFieldNo;
        SetN(CurrFieldNo);
        After := CurrFieldNo;
        exit(Format(Before) + '>' + Format(After));
    end;

    procedure AssignFieldNoThenPassAndAssign(): Text
    var
        After: Integer;
    begin
        CurrFieldNo := FieldNo(Note);
        SetN(CurrFieldNo);
        After := CurrFieldNo;
        exit(Format(After));
    end;

    procedure PassTwoLevels(): Text
    begin
        SetNAndPassOn(CurrFieldNo);
        exit(Format(CurrFieldNo));
    end;

    procedure ValidateAmountSeen(): Text
    begin
        CurrFieldNo := 0;
        Validate(Amount, 5);
        exit(Format(SeenInValidate) + '/' + Format(SeenAfterInValidate) + '/' + Format(CurrFieldNo));
    end;

    procedure CopyThenAssign(): Text
    var
        CopyVar: Integer;
    begin
        CopyVar := CurrFieldNo;
        SetN(CopyVar);
        exit(Format(CopyVar) + '/' + Format(CurrFieldNo));
    end;
}

codeunit 70909 "LT P170 Curr Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P170_CurrFieldNo_PassedToVarParameter_CalleeAssigns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Curr Row";
    begin
        Observer.Observe('default', Row.PassAndAssign());
        Observer.Observe('assigned_first', Row.AssignFieldNoThenPassAndAssign());
        Observer.Observe('after_assigned_first', Row.PassAndAssign());
        Observer.Observe('two_levels', Row.PassTwoLevels());
        Observer.Expect('default', '0>99');
        Observer.Expect('assigned_first', '99');
        Observer.Expect('after_assigned_first', '99>99');
        Observer.Expect('two_levels', '99');
        Observer.Verify();
    end;

    [Test]
    procedure P170_CurrFieldNo_PassedToVarParameter_InValidate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Curr Row";
    begin
        Observer.Observe('validate', Row.ValidateAmountSeen());
        Observer.Expect('validate', '0/99/99');
        Observer.Verify();
    end;

    [Test]
    procedure P170_CurrFieldNo_CopyIsNotTheProperty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Curr Row";
    begin
        Observer.Observe('copy', Row.CopyThenAssign());
        Observer.Expect('copy', '99/0');
        Observer.Verify();
    end;
}
