// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 78105, 78106
// Probe: a TableRelation whose condition is `Kind = const(" ")` on an Option field whose blank member is NOT the first member
// (OptionMembers = First, " ", Third): that it compiles, and which targets Validate accepts and rejects (result or error text and code),
// with a blank member at index 1 and at index 0 for comparison. Object ids 78105 - 78107.

table 78105 "LT AD Rel Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Kind; Option) { OptionMembers = First," ",Third; }
        field(3; Kind0; Option) { OptionMembers = " ",One,Two; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 78106 "LT AD Rel Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ToBlank; Code[10]) { TableRelation = "LT AD Rel Target"."Code" where(Kind = const(" ")); }
        field(3; ToBlank0; Code[10]) { TableRelation = "LT AD Rel Target"."Code" where(Kind0 = const(" ")); }
        field(4; ToThird; Code[10]) { TableRelation = "LT AD Rel Target"."Code" where(Kind = const(Third)); }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 78107 "LT AD Relation Blank Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        T: Record "LT AD Rel Target";
    begin
        T.DeleteAll();
        Add('A1', T.Kind::First, T.Kind0::" ");
        Add('A2', T.Kind::" ", T.Kind0::One);
        Add('A3', T.Kind::Third, T.Kind0::Two);
        Add('A4', T.Kind::" ", T.Kind0::" ");
    end;

    local procedure Add(NewCode: Code[10]; NewKind: Option First," ",Third; NewKind0: Option " ",One,Two)
    var
        T: Record "LT AD Rel Target";
    begin
        T.Code := NewCode;
        T.Kind := NewKind;
        T.Kind0 := NewKind0;
        T.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(FieldNo: Integer; Value: Code[10])
    var
        S: Record "LT AD Rel Source";
    begin
        case FieldNo of
            2: S.Validate(ToBlank, Value);
            3: S.Validate(ToBlank0, Value);
            4: S.Validate(ToThird, Value);
        end;
    end;

    local procedure Check(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; Name: Text)
    var
        Codes: List of [Text];
        C: Text;
    begin
        Codes.Add('A1');
        Codes.Add('A2');
        Codes.Add('A3');
        Codes.Add('A4');
        Codes.Add('');
        foreach C in Codes do begin
            ClearLastError();
            if TryValidate(FieldNo, CopyStr(C, 1, 10)) then
                Observer.Observe(Name + ' ' + C, 'ok')
            else
                Observer.Observe(Name + ' ' + C, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
    end;

    [Test]
    procedure Validate_BlankNotFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Check(Observer, 2, 'blank_idx1');
        Observer.Expect('blank_idx1 A1', 'error:The field ToBlank of table LT AD Rel Source contains a value (A1) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('blank_idx1 A2', 'ok');
        Observer.Expect('blank_idx1 A3', 'error:The field ToBlank of table LT AD Rel Source contains a value (A3) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('blank_idx1 A4', 'ok');
        Observer.Expect('blank_idx1 ', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_BlankFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Check(Observer, 3, 'blank_idx0');
        Observer.Expect('blank_idx0 A1', 'ok');
        Observer.Expect('blank_idx0 A2', 'error:The field ToBlank0 of table LT AD Rel Source contains a value (A2) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('blank_idx0 A3', 'error:The field ToBlank0 of table LT AD Rel Source contains a value (A3) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('blank_idx0 A4', 'ok');
        Observer.Expect('blank_idx0 ', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Third()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Check(Observer, 4, 'third');
        Observer.Expect('third A1', 'error:The field ToThird of table LT AD Rel Source contains a value (A1) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('third A2', 'error:The field ToThird of table LT AD Rel Source contains a value (A2) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('third A3', 'ok');
        Observer.Expect('third A4', 'error:The field ToThird of table LT AD Rel Source contains a value (A4) that cannot be found in the related table (LT AD Rel Target).|DB:NothingInsideFilter');
        Observer.Expect('third ', 'ok');
        Observer.Verify();
    end;
}
