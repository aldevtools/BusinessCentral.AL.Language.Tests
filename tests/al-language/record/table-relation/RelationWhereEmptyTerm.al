// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 70874 and 70875, codeunit 70876
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Validate of a value against a relation whose where() has an empty term: ok or the error text and code; the FlowField result when the where() term is empty (const(''), filter(''), field(Empty), filter(<>'')).
// BC versions: 29 (27 and 28 by CI)

table 70874 "LT RWE Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Zone; Code[10]) { }
        field(3; Qty; Integer) { }
        field(4; Name; Text[30]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 70875 "LT RWE Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ZoneSrc; Code[10]) { }
        field(3; RelBlankFilter; Code[20])
        {
            TableRelation = "LT RWE Item".Code where(Zone = filter(''));
        }
        field(4; RelBlankConst; Code[20])
        {
            TableRelation = "LT RWE Item".Code where(Zone = const(''));
        }
        field(5; RelFieldSrc; Code[20])
        {
            TableRelation = "LT RWE Item".Code where(Zone = field(ZoneSrc));
        }
        field(6; RelNotBlank; Code[20])
        {
            TableRelation = "LT RWE Item".Code where(Zone = filter(<> ''));
        }
        field(10; CntBlankConst; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RWE Item" where(Zone = const('')));
        }
        field(11; CntBlankFilter; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RWE Item" where(Zone = filter('')));
        }
        field(12; CntFieldSrc; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RWE Item" where(Zone = field(ZoneSrc)));
        }
        field(13; CntNotBlank; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RWE Item" where(Zone = filter(<> '')));
        }
        field(14; SumFieldSrc; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT RWE Item".Qty where(Zone = field(ZoneSrc)));
        }
        field(15; ExistFieldSrc; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT RWE Item" where(Zone = field(ZoneSrc)));
        }
        field(16; LookupByCode; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT RWE Item".Name where(Code = field(ZoneSrc)));
        }
        field(17; CntCodeFieldSrc; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT RWE Item" where(Code = field(ZoneSrc)));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70876 "LT Relation Where Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT RWE Item";
        Line: Record "LT RWE Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        AddItem('A1', '', 1, 'first');
        AddItem('B1', 'Z1', 2, 'second');
        AddItem('C1', '', 4, 'third');
        AddItem('D1', 'Z2', 8, 'fourth');
        AddItem('E1', 'Z1', 16, 'fifth');
    end;

    local procedure AddItem(Code: Code[20]; Zone: Code[10]; Qty: Integer; Name: Text[30])
    var
        Item: Record "LT RWE Item";
    begin
        Item.Code := Code;
        Item.Zone := Zone;
        Item.Qty := Qty;
        Item.Name := Name;
        Item.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var Line: Record "LT RWE Line"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            3:
                Line.Validate(RelBlankFilter, Value);
            4:
                Line.Validate(RelBlankConst, Value);
            5:
                Line.Validate(RelFieldSrc, Value);
            6:
                Line.Validate(RelNotBlank, Value);
        end;
    end;

    local procedure Probe(Name: Text; ZoneSrc: Code[10]; FieldNo: Integer; var Observer: Codeunit "Probe Observer")
    var
        Line: Record "LT RWE Line";
        Names: List of [Text];
        ItemName: Text;
        ItemCode: Code[20];
        Ok: Boolean;
    begin
        Line.Id := 1;
        Line.ZoneSrc := ZoneSrc;
        Names.Add('A1');
        Names.Add('B1');
        Names.Add('C1');
        Names.Add('D1');
        Names.Add('E1');
        Names.Add('NOPE');
        foreach ItemName in Names do begin
            ItemCode := CopyStr(ItemName, 1, MaxStrLen(ItemCode));
            ClearLastError();
            Ok := TryValidate(Line, FieldNo, ItemCode);
            Observer.Observe(Name + '_' + ItemName, Format(Ok) + '|' + GetLastErrorCode());
        end;
        ClearLastError();
        Ok := TryValidate(Line, FieldNo, '');
        Observer.Observe(Name + '_empty', Format(Ok));
    end;

    [Test]
    procedure Relation_WhereBlankFilterAndConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('filter', '', 3, Observer);
        Probe('const', '', 4, Observer);
        Observer.Expect('filter_A1', 'Yes|');
        Observer.Expect('filter_B1', 'No|DB:NothingInsideFilter');
        Observer.Expect('filter_C1', 'Yes|');
        Observer.Expect('filter_D1', 'No|DB:NothingInsideFilter');
        Observer.Expect('filter_E1', 'No|DB:NothingInsideFilter');
        Observer.Expect('filter_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('filter_empty', 'Yes');
        Observer.Expect('const_A1', 'Yes|');
        Observer.Expect('const_B1', 'No|DB:NothingInsideFilter');
        Observer.Expect('const_C1', 'Yes|');
        Observer.Expect('const_D1', 'No|DB:NothingInsideFilter');
        Observer.Expect('const_E1', 'No|DB:NothingInsideFilter');
        Observer.Expect('const_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('const_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_WhereFieldSourceEmptyAndFilled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('src_empty', '', 5, Observer);
        Probe('src_z1', 'Z1', 5, Observer);
        Observer.Expect('src_empty_A1', 'Yes|');
        Observer.Expect('src_empty_B1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_empty_C1', 'Yes|');
        Observer.Expect('src_empty_D1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_empty_E1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_empty_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_empty_empty', 'Yes');
        Observer.Expect('src_z1_A1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_z1_B1', 'Yes|');
        Observer.Expect('src_z1_C1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_z1_D1', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_z1_E1', 'Yes|');
        Observer.Expect('src_z1_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('src_z1_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_WhereNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe('notblank', '', 6, Observer);
        Probe('notblank_z1', 'Z1', 6, Observer);
        Observer.Expect('notblank_A1', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_B1', 'Yes|');
        Observer.Expect('notblank_C1', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_D1', 'Yes|');
        Observer.Expect('notblank_E1', 'Yes|');
        Observer.Expect('notblank_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_empty', 'Yes');
        Observer.Expect('notblank_z1_A1', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_z1_B1', 'Yes|');
        Observer.Expect('notblank_z1_C1', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_z1_D1', 'Yes|');
        Observer.Expect('notblank_z1_E1', 'Yes|');
        Observer.Expect('notblank_z1_NOPE', 'No|DB:NothingInsideFilter');
        Observer.Expect('notblank_z1_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Relation_ErrorTextOfFailedValidate()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT RWE Line";
    begin
        Seed();
        Line.Id := 1;
        asserterror Line.Validate(RelBlankFilter, 'B1');
        Observer.ObserveError('filter_b1');
        asserterror Line.Validate(RelFieldSrc, 'B1');
        Observer.ObserveError('src_empty_b1');
        Line.ZoneSrc := 'Z1';
        asserterror Line.Validate(RelFieldSrc, 'A1');
        Observer.ObserveError('src_z1_a1');
        Observer.Expect('filter_b1|text', 'The field RelBlankFilter of table LT RWE Line contains a value (B1) that cannot be found in the related table (LT RWE Item).');
        Observer.Expect('filter_b1|code', 'DB:NothingInsideFilter');
        Observer.Expect('src_empty_b1|text', 'The field RelFieldSrc of table LT RWE Line contains a value (B1) that cannot be found in the related table (LT RWE Item).');
        Observer.Expect('src_empty_b1|code', 'DB:NothingInsideFilter');
        Observer.Expect('src_z1_a1|text', 'The field RelFieldSrc of table LT RWE Line contains a value (A1) that cannot be found in the related table (LT RWE Item).');
        Observer.Expect('src_z1_a1|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFormula_CountWhereEmptyTerms()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT RWE Line";
    begin
        Seed();
        Line.Id := 1;
        Line.Insert();
        Line.CalcFields(CntBlankConst, CntBlankFilter, CntFieldSrc, CntNotBlank);
        Observer.Observe('empty_const', Format(Line.CntBlankConst));
        Observer.Observe('empty_filter', Format(Line.CntBlankFilter));
        Observer.Observe('empty_field', Format(Line.CntFieldSrc));
        Observer.Observe('empty_notblank', Format(Line.CntNotBlank));
        Line.ZoneSrc := 'Z1';
        Line.CalcFields(CntFieldSrc);
        Observer.Observe('z1_field', Format(Line.CntFieldSrc));
        Line.ZoneSrc := 'NOPE';
        Line.CalcFields(CntFieldSrc);
        Observer.Observe('nope_field', Format(Line.CntFieldSrc));
        Line.Delete();
        Observer.Expect('empty_const', '2');
        Observer.Expect('empty_filter', '2');
        Observer.Expect('empty_field', '2');
        Observer.Expect('empty_notblank', '3');
        Observer.Expect('z1_field', '2');
        Observer.Expect('nope_field', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFormula_SumExistLookupWithEmptySource()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT RWE Line";
    begin
        Seed();
        Line.Id := 1;
        Line.Insert();
        Line.CalcFields(SumFieldSrc, ExistFieldSrc, LookupByCode, CntCodeFieldSrc);
        Observer.Observe('empty_sum', Format(Line.SumFieldSrc));
        Observer.Observe('empty_exist', Format(Line.ExistFieldSrc));
        Observer.Observe('empty_lookup', Line.LookupByCode);
        Observer.Observe('empty_codecount', Format(Line.CntCodeFieldSrc));
        Line.ZoneSrc := 'Z1';
        Line.CalcFields(SumFieldSrc, ExistFieldSrc);
        Observer.Observe('z1_sum', Format(Line.SumFieldSrc));
        Observer.Observe('z1_exist', Format(Line.ExistFieldSrc));
        Line.ZoneSrc := 'A1';
        Line.CalcFields(LookupByCode, CntCodeFieldSrc);
        Observer.Observe('a1_lookup', Line.LookupByCode);
        Observer.Observe('a1_codecount', Format(Line.CntCodeFieldSrc));
        Line.Delete();
        Observer.Expect('empty_sum', '5');
        Observer.Expect('empty_exist', 'Yes');
        Observer.Expect('empty_lookup', '');
        Observer.Expect('empty_codecount', '0');
        Observer.Expect('z1_sum', '18');
        Observer.Expect('z1_exist', 'Yes');
        Observer.Expect('a1_lookup', 'first');
        Observer.Expect('a1_codecount', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFormula_SetAutoCalcFieldsAndFilterOnFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT RWE Line";
    begin
        Seed();
        Line.Id := 1;
        Line.Insert();
        Line.Id := 2;
        Line.ZoneSrc := 'Z2';
        Line.Insert();
        Line.SetAutoCalcFields(CntFieldSrc);
        Line.FindSet();
        Observer.Observe('row1', Format(Line.Id) + ':' + Format(Line.CntFieldSrc));
        Line.Next();
        Observer.Observe('row2', Format(Line.Id) + ':' + Format(Line.CntFieldSrc));
        Line.SetRange(CntFieldSrc, 2);
        Observer.Observe('filter_count_2', Format(Line.Count()));
        Line.SetRange(CntFieldSrc, 1);
        Observer.Observe('filter_count_1', Format(Line.Count()));
        Line.Reset();
        Line.DeleteAll();
        Observer.Expect('row1', '1:2');
        Observer.Expect('row2', '2:1');
        Observer.Expect('filter_count_2', '1');
        Observer.Expect('filter_count_1', '1');
        Observer.Verify();
    end;
}
