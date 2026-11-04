// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 95633 (document types with FlowFields), 95634 (documents), test codeunit 95635
// Probe (al-runner issue 6986): a FlowField of type BigInteger with CalcFormula = count(...), next to the Integer count (a Decimal one
//   does not compile: AL0202, must-not-compile case 2970). Does it publish, what does CalcFields give (value, and the type a Variant reports), with a const filter, a FlowFilter, no rows,
//   SetAutoCalcFields, a filter on the BigInteger FlowField itself, and through FieldRef.CalcField. Each CalcFields runs in a TryFunction.
// BC versions: 27, 28, 29

table 95633 "LT R6986 Doc Type"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CreatedFilter; Boolean) { FieldClass = FlowFilter; }
        field(10; ToArchive; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6986 Doc" where("Doc Type No." = field("No."), Created = const(false)));
            Editable = false;
        }
        field(11; AllBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6986 Doc" where("Doc Type No." = field("No.")));
            Editable = false;
        }
        field(12; AllInt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6986 Doc" where("Doc Type No." = field("No.")));
            Editable = false;
        }
        field(14; ByFilterBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6986 Doc" where("Doc Type No." = field("No."), Created = field(CreatedFilter)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95634 "LT R6986 Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Doc Type No."; Code[20]) { }
        field(3; Created; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 95635 "LT R6986 BigInteger Count"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Type T1 has three documents (one created), T2 none, T3 two (both not created).
    local procedure Seed()
    var
        DocType: Record "LT R6986 Doc Type";
        Doc: Record "LT R6986 Doc";
    begin
        DocType.DeleteAll();
        Doc.DeleteAll();
        AddType('T1');
        AddType('T2');
        AddType('T3');
        AddDoc('D1', 'T1', false);
        AddDoc('D2', 'T1', true);
        AddDoc('D3', 'T1', false);
        AddDoc('D4', 'T3', false);
        AddDoc('D5', 'T3', false);
    end;

    local procedure AddType(No: Code[20])
    var
        DocType: Record "LT R6986 Doc Type";
    begin
        DocType.Init();
        DocType."No." := No;
        DocType.Insert();
    end;

    local procedure AddDoc(No: Code[20]; TypeNo: Code[20]; Created: Boolean)
    var
        Doc: Record "LT R6986 Doc";
    begin
        Doc.Init();
        Doc."No." := No;
        Doc."Doc Type No." := TypeNo;
        Doc.Created := Created;
        Doc.Insert();
    end;

    local procedure TypeOf(V: Variant): Text
    begin
        if V.IsBigInteger() then
            exit('BigInteger');
        if V.IsInteger() then
            exit('Integer');
        if V.IsDecimal() then
            exit('Decimal');
        exit('other');
    end;

    [TryFunction]
    local procedure TryCalcAll(var DocType: Record "LT R6986 Doc Type")
    begin
        DocType.CalcFields(ToArchive, AllBig, AllInt);
    end;

    [TryFunction]
    local procedure TryCalcByFilter(var DocType: Record "LT R6986 Doc Type")
    begin
        DocType.CalcFields(ByFilterBig);
    end;

    local procedure Calc(No: Code[20]): Text
    var
        DocType: Record "LT R6986 Doc Type";
        Result: Text;
    begin
        DocType.Get(No);
        ClearLastError();
        if not TryCalcAll(DocType) then begin
            Result := 'error=' + GetLastErrorText() + ' code=' + GetLastErrorCode();
            ClearLastError();
            exit(Result);
        end;
        exit('ToArchive=' + Format(DocType.ToArchive) + ' AllBig=' + Format(DocType.AllBig) + ' AllInt=' + Format(DocType.AllInt));
    end;

    [Test]
    procedure CountIntoBigInteger_CalcFields_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('T1', Calc('T1'));
        Observer.Observe('T2', Calc('T2'));
        Observer.Observe('T3', Calc('T3'));
        Observer.Finish();
    end;

    [Test]
    procedure CountIntoBigInteger_VariantTypes()
    var
        Observer: Codeunit "Probe Observer";
        DocType: Record "LT R6986 Doc Type";
    begin
        Seed();
        DocType.Get('T1');
        if TryCalcAll(DocType) then;
        Observer.Observe('ToArchive', TypeOf(DocType.ToArchive));
        Observer.Observe('AllBig', TypeOf(DocType.AllBig));
        Observer.Observe('AllInt', TypeOf(DocType.AllInt));
        Observer.Finish();
    end;

    [Test]
    procedure CountIntoBigInteger_FlowFilter()
    var
        Observer: Codeunit "Probe Observer";
        DocType: Record "LT R6986 Doc Type";
    begin
        Seed();
        DocType.Get('T1');
        DocType.SetRange(CreatedFilter, true);
        Observer.Observe('created', Format(TryCalcByFilter(DocType)) + ' ' + Format(DocType.ByFilterBig));
        DocType.SetRange(CreatedFilter, false);
        Observer.Observe('not created', Format(TryCalcByFilter(DocType)) + ' ' + Format(DocType.ByFilterBig));
        DocType.SetRange(CreatedFilter);
        Observer.Observe('no filter', Format(TryCalcByFilter(DocType)) + ' ' + Format(DocType.ByFilterBig));
        ClearLastError();
        Observer.Finish();
    end;

    [Test]
    procedure CountIntoBigInteger_SetAutoCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        DocType: Record "LT R6986 Doc Type";
        Result: Text;
    begin
        Seed();
        DocType.SetAutoCalcFields(ToArchive, AllBig);
        if DocType.FindSet() then
            repeat
                Result += DocType."No." + '=' + Format(DocType.ToArchive) + '/' + Format(DocType.AllBig) + ';';
            until DocType.Next() = 0;
        Observer.Observe('rows', Result);
        Observer.Finish();
    end;

    [Test]
    procedure CountIntoBigInteger_FilterOnTheFlowField()
    var
        Observer: Codeunit "Probe Observer";
        DocType: Record "LT R6986 Doc Type";
        Result: Text;
    begin
        Seed();
        DocType.SetFilter(ToArchive, '>=%1', 2);
        Observer.Observe('count', Format(DocType.Count()));
        if DocType.FindSet() then
            repeat
                Result += DocType."No." + ';';
            until DocType.Next() = 0;
        Observer.Observe('rows', Result);
        DocType.SetRange(ToArchive, 0);
        Observer.Observe('zero count', Format(DocType.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure CountIntoBigInteger_FieldRef()
    var
        Observer: Codeunit "Probe Observer";
        DocType: Record "LT R6986 Doc Type";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Seed();
        DocType.Get('T3');
        RecRef.GetTable(DocType);
        FldRef := RecRef.Field(10);
        FldRef.CalcField();
        Observer.Observe('type', Format(FldRef.Type));
        Observer.Observe('class', Format(FldRef.Class));
        Observer.Observe('value', Format(FldRef.Value));
        Observer.Finish();
    end;
}
