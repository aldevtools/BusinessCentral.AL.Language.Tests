// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-relations-metadata
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72571, tables 72572-72575
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: "Probe round 6, platform tables - Table Relations Metadata (a `filter(...)` condition)" and "Tenant License State (Delete of one row)";
// (Probe fixes) "ClientType members (NAS)", "JsonValue default", "Table Relations Metadata, Condition Value", "Record and Variant"
// Facts: Condition Type/Value of filter relations on Integer, Code and Enum fields, Tenant License State Delete, ClientType::NAS ordinal, never-touched JsonValue, a Variant parameter written by the callee
// BC versions: 29 (27 and 28 by CI)

enum 72573 "LT PnE Rel Enum"
{
    Extensible = true;

    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; Gamma) { }
}

table 72572 "LT PnE Rel Target"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Num; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 72574 "LT PnE Rel Source"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT PnE Rel Enum") { }
        field(3; IntKind; Integer) { }
        field(4; CodeKind; Code[10]) { }
        field(5; Ref; Code[10])
        {
            TableRelation = if (Kind = filter(Alpha | Beta)) "LT PnE Rel Target".Code
            else if (IntKind = filter(1 | 2)) "LT PnE Rel Target".Code
            else if (CodeKind = filter('A' | 'B')) "LT PnE Rel Target".Code;
        }
        field(6; Ref2; Code[10])
        {
            TableRelation = if (IntKind = filter(5 | 7)) "LT PnE Rel Target".Code;
        }
        field(7; Ref3; Code[10])
        {
            TableRelation = if (CodeKind = filter('X*')) "LT PnE Rel Target".Code;
        }
        field(8; Ref4; Code[10])
        {
            TableRelation = if (Kind = const(Beta)) "LT PnE Rel Target".Code;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72575 "LT PnE Var Rec"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72571 "LT PnE Platform Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpRow(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        R: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            R += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(R);
    end;

    local procedure Relations(FieldNo: Integer): Text
    var
        M: Record "Table Relations Metadata";
        RR: RecordRef;
        R: Text;
        n: Integer;
    begin
        M.SetRange("Table ID", Database::"LT PnE Rel Source");
        M.SetRange("Field No.", FieldNo);
        if M.FindSet() then
            repeat
                n += 1;
                RR.GetTable(M);
                R += '[' + DumpRow(RR) + ']';
            until M.Next() = 0;
        exit(Format(n) + ':' + R);
    end;

    [Test]
    procedure TableRelations_FilterConditions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('enumAndIntAndCodeFilters', Relations(5));
        Observer.Observe('intFilter', Relations(6));
        Observer.Observe('codeFilterWildcard', Relations(7));
        Observer.Observe('enumConst', Relations(8));
        Observer.Expect('enumAndIntAndCodeFilters', '3:[Table ID=72574;Field No.=5;Relation No.=1;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=FILTER;Condition Field No.=2;Condition Value=0|1;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref;Related Table Name=LT PnE Rel Target;Related Field Name=Code;][Table ID=72574;Field No.=5;Relation No.=2;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=FILTER;Condition Field No.=3;Condition Value=1|2;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref;Related Table Name=LT PnE Rel Target;Related Field Name=Code;][Table ID=72574;Field No.=5;Relation No.=3;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=FILTER;Condition Field No.=4;Condition Value=A|B;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref;Related Table Name=LT PnE Rel Target;Related Field Name=Code;]');
        Observer.Expect('intFilter', '1:[Table ID=72574;Field No.=6;Relation No.=1;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=FILTER;Condition Field No.=3;Condition Value=5|7;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref2;Related Table Name=LT PnE Rel Target;Related Field Name=Code;]');
        Observer.Expect('codeFilterWildcard', '1:[Table ID=72574;Field No.=7;Relation No.=1;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=FILTER;Condition Field No.=4;Condition Value=X*;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref3;Related Table Name=LT PnE Rel Target;Related Field Name=Code;]');
        Observer.Expect('enumConst', '1:[Table ID=72574;Field No.=8;Relation No.=1;Condition No.=1;Related Table ID=72572;Related Field No.=1;Condition Type=CONST;Condition Field No.=2;Condition Value=1;Test Table Relation=No;Validate Table Relation=Yes;Table Name=LT PnE Rel Source;Field Name=Ref4;Related Table Name=LT PnE Rel Target;Related Field Name=Code;]');
        Observer.Verify();
    end;





    [Test]
    procedure ClientType_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('NAS', Format(ClientType::NAS, 0, 2));
        Observer.Observe('NASname', Format(ClientType::NAS));
        Observer.Observe('Default', Format(ClientType::Default, 0, 2));
        Observer.Observe('Background', Format(ClientType::Background, 0, 2));
        Observer.Observe('Management', Format(ClientType::Management, 0, 2));
        Observer.Expect('NAS', '6');
        Observer.Expect('NASname', 'NAS');
        Observer.Expect('Default', '1');
        Observer.Expect('Background', '7');
        Observer.Expect('Management', '8');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_NeverTouched()
    var
        Observer: Codeunit "Probe Observer";
        V: JsonValue;
        T: JsonToken;
        O: JsonObject;
        A: JsonArray;
    begin
        Observer.Observe('jsonValue', Format(V));
        Observer.Observe('jsonToken', Format(T));
        Observer.Observe('jsonObject', Format(O));
        Observer.Observe('jsonArray', Format(A));
        Observer.Observe('valueIsNull', Format(V.IsNull()));
        asserterror Observer.Observe('valueAsText', Format(V.AsText()));
        Observer.ObserveError('af152');
        Observer.Observe('tokenIsValue', Format(T.IsValue()));
        Observer.Observe('tokenIsObject', Format(T.IsObject()));
        Observer.Expect('jsonValue', 'null');
        Observer.Expect('jsonToken', 'null');
        Observer.Expect('jsonObject', '{}');
        Observer.Expect('jsonArray', '[]');
        Observer.Expect('valueIsNull', 'Yes');
        Observer.Expect('af152|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('af152|code', 'Conversion');
        Observer.Expect('tokenIsValue', 'Yes');
        Observer.Expect('tokenIsObject', 'No');
        Observer.Verify();
    end;

    local procedure InsertIntoVariantRecord(V: Variant)
    var
        RR: RecordRef;
    begin
        RR.GetTable(V);
        RR.Init();
        RR.Field(1).Value := 50;
        RR.Insert();
    end;

    local procedure CountOf(V: Variant): Integer
    var
        RR: RecordRef;
    begin
        RR.GetTable(V);
        exit(RR.Count());
    end;

    [Test]
    procedure RecordAndVariant_ParameterWrites()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT PnE Var Rec" temporary;
        Real: Record "LT PnE Var Rec";
        V: Variant;
    begin
        Real.DeleteAll();
        Temp.Init();
        Temp.Id := 1;
        Temp.Insert();
        Observer.Observe('tempCountByVariant', Format(CountOf(Temp)));
        InsertIntoVariantRecord(Temp);
        Observer.Observe('tempAfterCalleeInsert', Format(Temp.Count()));
        Real.Id := 1;
        Real.Insert();
        InsertIntoVariantRecord(Real);
        Observer.Observe('realAfterCalleeInsert', Format(Real.Count()));
        V := Real;
        Real.Id := 2;
        Real.Insert();
        Observer.Observe('variantIsCopy', Format(CountOf(V)));
        Observer.Observe('realCount', Format(Real.Count()));
        Real.DeleteAll();
        Observer.Expect('tempCountByVariant', '1');
        Observer.Expect('tempAfterCalleeInsert', '2');
        Observer.Expect('realAfterCalleeInsert', '2');
        Observer.Expect('variantIsCopy', '3');
        Observer.Expect('realCount', '3');
        Observer.Verify();
    end;
}
