// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-conditional-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 85442, test codeunit 85443
// Probe: corpus #670 items 73 and 75 (writer CW). Facts:
//   - array[50] of Variant: elements set to 10 and 20 stay independent; elements holding a Record, a Text and a Date; Clear of one element;
//   - array[3] of FieldRef set from three fields of one RecordRef: each element keeps its own field;
//   - case Field.Type of Field.Type::Text, Field.Type::Code: over the Field virtual table (TableNo 85442): which branch each field type takes.
// Results: array elements of Variant and FieldRef are independent; the CASE comma list matches Text and Code fields.
// BC versions: 27, 28, 29

table 85442 "LT CW Var Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "No."; Code[20]) { }
        field(4; Amount; Decimal) { }
        field(5; Posted; Boolean) { }
        field(6; "Due Date"; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85443 "LT CW Variant Arrays"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CW_ArrayOfVariant_Independent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CW Var Row";
        Back: Record "LT CW Var Row";
        V: array[50] of Variant;
    begin
        V[1] := 10;
        V[2] := 20;
        Observer.Observe('v1', Format(V[1]));
        Observer.Observe('v2', Format(V[2]));
        Observer.Observe('v3 empty', Format(V[3].IsInteger()) + '|' + '[' + Format(V[3]) + ']');
        Row.Id := 7;
        Row.Name := 'seven';
        V[3] := Row;
        Row.Id := 8;
        Row.Name := 'eight';
        V[4] := Row;
        V[5] := 'text five';
        V[6] := 20250102D;
        Back := V[3];
        Observer.Observe('v3 record', Format(V[3].IsRecord()) + '|' + Format(Back.Id) + '|' + Back.Name);
        Back := V[4];
        Observer.Observe('v4 record', Format(Back.Id) + '|' + Back.Name);
        Observer.Observe('v5 text', Format(V[5].IsText()) + '|' + Format(V[5]));
        Observer.Observe('v6 date', Format(V[6].IsDate()) + '|' + Format(V[6], 0, 9));
        V[1] := V[2];
        V[2] := 30;
        Observer.Observe('copy then change', Format(V[1]) + '|' + Format(V[2]));
        Clear(V[2]);
        Observer.Observe('clear one', Format(V[1]) + '|[' + Format(V[2]) + ']|' + Format(V[5]));
        Observer.Expect('v1', '10');
        Observer.Expect('v2', '20');
        Observer.Expect('v3 empty', 'No|[]');
        Observer.Expect('v3 record', 'Yes|7|seven');
        Observer.Expect('v4 record', '8|eight');
        Observer.Expect('v5 text', 'Yes|text five');
        Observer.Expect('v6 date', 'Yes|2025-01-02');
        Observer.Expect('copy then change', '20|30');
        Observer.Expect('clear one', '20|[]|text five');
        Observer.Verify();
    end;

    [Test]
    procedure CW_ArrayOfFieldRef_Independent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CW Var Row";
        RecRef: RecordRef;
        F: array[3] of FieldRef;
    begin
        Row.Id := 1;
        Row.Name := 'n1';
        Row."No." := 'C1';
        Row.Amount := 2.5;
        RecRef.GetTable(Row);
        F[1] := RecRef.Field(2);
        F[2] := RecRef.Field(3);
        F[3] := RecRef.Field(4);
        Observer.Observe('names', F[1].Name + '|' + F[2].Name + '|' + F[3].Name);
        Observer.Observe('values', Format(F[1].Value) + '|' + Format(F[2].Value) + '|' + Format(F[3].Value));
        F[1].Value := 'changed';
        Observer.Observe('after set', Format(F[1].Value) + '|' + Format(F[2].Value) + '|' + Format(RecRef.Field(2).Value));
        Observer.Expect('names', 'Name|No.|Amount');
        Observer.Expect('values', 'n1|C1|2.5');
        Observer.Expect('after set', 'changed|C1|changed');
        Observer.Verify();
    end;

    [Test]
    procedure CW_CaseOnFieldTypeCommaList()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
        R: Text;
    begin
        Fld.SetRange(TableNo, Database::"LT CW Var Row");
        Fld.SetRange(Class, Fld.Class::Normal);
        Fld.SetFilter("No.", '<%1', 2000000000);
        if Fld.FindSet() then
            repeat
                case Fld.Type of
                    Fld.Type::Text, Fld.Type::Code:
                        R += Fld.FieldName + '=textcode,';
                    Fld.Type::Integer, Fld.Type::Decimal:
                        R += Fld.FieldName + '=number,';
                    else
                        R += Fld.FieldName + '=else,';
                end;
            until Fld.Next() = 0;
        Observer.Observe('branches', R);
        Observer.Expect('branches', 'Id=number,Name=textcode,No.=textcode,Amount=number,Posted=else,Due Date=else,');
        Observer.Verify();
    end;
}
