// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73769
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73769 "LT P165 Array Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
                Counter += 10;
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Counter: Integer;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

codeunit 73768 "LT P165 Array Globals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Slots: array[2] of Record "LT P165 Array Row";

    [Test]
    procedure LocalArray_EveryElementHasItsOwnGlobals()
    var
        Observer: Codeunit "Probe Observer";
        Rows: array[3] of Record "LT P165 Array Row";
    begin
        Rows[1].Bump();
        Rows[1].Bump();
        Rows[2].Bump();
        Observer.Observe('counters', Format(Rows[1].GetCounter()) + ';' + Format(Rows[2].GetCounter()) + ';' + Format(Rows[3].GetCounter()));
        Rows[3].Validate(Val, 4);
        Observer.Observe('after Validate of 3', Format(Rows[1].GetCounter()) + ';' + Format(Rows[2].GetCounter()) + ';' + Format(Rows[3].GetCounter()));
        Observer.Expect('counters', '2;1;0');
        Observer.Expect('after Validate of 3', '2;1;10');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalArray_KeepsGlobalsAcrossCalls()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Slots[1].Bump();
        Slots[2].Bump();
        Slots[2].Bump();
        Observer.Observe('counters', Format(Slots[1].GetCounter()) + ';' + Format(Slots[2].GetCounter()));
        Clear(Slots[2]);
        Observer.Observe('after Clear of 2', Format(Slots[1].GetCounter()) + ';' + Format(Slots[2].GetCounter()));
        Clear(Slots);
        Observer.Observe('after Clear of the array', Format(Slots[1].GetCounter()) + ';' + Format(Slots[2].GetCounter()));
        Observer.Expect('counters', '1;2');
        Observer.Expect('after Clear of 2', '1;0');
        Observer.Expect('after Clear of the array', '0;0');
        Observer.Verify();
    end;

    [Test]
    procedure Array_AssignmentAndCopyBetweenElements()
    var
        Observer: Codeunit "Probe Observer";
        Rows: array[3] of Record "LT P165 Array Row";
    begin
        Rows[1].Bump();
        Rows[1].Bump();
        Rows[2].Bump();
        Rows[2].Bump();
        Rows[2].Bump();
        Rows[3] := Rows[1];
        Observer.Observe('after assignment 3 := 1', Format(Rows[1].GetCounter()) + ';' + Format(Rows[3].GetCounter()));
        Rows[3].Copy(Rows[2]);
        Observer.Observe('after Copy 3 from 2', Format(Rows[2].GetCounter()) + ';' + Format(Rows[3].GetCounter()));
        Rows[3].TransferFields(Rows[1]);
        Observer.Observe('after TransferFields 3 from 1', Format(Rows[1].GetCounter()) + ';' + Format(Rows[3].GetCounter()));
        Observer.Expect('after assignment 3 := 1', '2;0');
        Observer.Expect('after Copy 3 from 2', '3;0');
        Observer.Expect('after TransferFields 3 from 1', '2;0');
        Observer.Verify();
    end;

    [Test]
    procedure Array_GetTableAndSetTableIntoAnElement()
    var
        Observer: Codeunit "Probe Observer";
        Rows: array[2] of Record "LT P165 Array Row";
        Source: Record "LT P165 Array Row";
        RecRef: RecordRef;
    begin
        Source.DeleteAll();
        Source.Id := 'S';
        Source.Val := 5;
        Source.Insert();
        Source.Bump();
        Source.Bump();
        RecRef.GetTable(Source);
        RecRef.SetTable(Rows[2]);
        Observer.Observe('target id', Rows[2].Id);
        Observer.Observe('target counter after SetTable', Format(Rows[2].GetCounter()));
        Observer.Observe('other element counter', Format(Rows[1].GetCounter()));
        Rows[1].GetBySystemId(Source.SystemId);
        Observer.Observe('GetBySystemId into an element', Rows[1].Id + ';' + Format(Rows[1].GetCounter()));
        Observer.Expect('target id', 'S');
        Observer.Expect('target counter after SetTable', '0');
        Observer.Expect('other element counter', '0');
        Observer.Expect('GetBySystemId into an element', 'S;0');
        Observer.Verify();
    end;
}
