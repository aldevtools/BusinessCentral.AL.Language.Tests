// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 66330 and 66331, test codeunit 66333
// local object: the TableRelation definitions are what the tests measure.
// Probe (al-runner issue 7459: `TableRelation = "My Master" where("Valid To" = filter('='''''))`, "Valid To" a Date field): observation form,
//   the values are read from the corpus CI matrix.
// Area: a TableRelation where() whose filter text compares with two single quotes (an empty value), on a field of the related table of
//   every type that takes it: Date, Time, DateTime, Integer, Decimal, Code, Text, Guid, Duration, DateFormula and Option. Forms:
//   filter('=''''') (equal to empty), filter('<>''''') (not empty) and filter('''''') (two quotes alone); on the Date field also filter(''),
//   filter(0D), filter(<> 0D), const(0D) and two conditions. The related table holds the row EMPTY (every field at its default) and the
//   row SET (every field with a value). Per field: Validate with EMPTY, SET and a code no row has, through Record.Validate (the Date
//   fields) and FieldRef.Validate: ok, or the error text and code.
// Existing pins: TableRelationQuotes.al TRX_* pins filter('<>''''') and filter('''''') on Code fields; RelationWhereEmptyTerm.al pins
//   filter('') and const('') on a Code field; testpage/CdConst0D.al pins filter('') on a Date field in a SourceTableView.
// BC versions: 27, 28, 29 by CI

table 66330 "REC WhEmpty Master"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[15]) { }
        field(10; FDate; Date) { }
        field(11; FTime; Time) { }
        field(12; FDateTime; DateTime) { }
        field(13; FInt; Integer) { }
        field(14; FDec; Decimal) { }
        field(15; FCode; Code[10]) { }
        field(16; FText; Text[10]) { }
        field(17; FGuid; Guid) { }
        field(18; FDur; Duration) { }
        field(19; FDf; DateFormula) { }
        field(20; FOpt; Option) { OptionMembers = A,B,C; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 66331 "REC WhEmpty Response"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(100; DateEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter('=''''')); }
        field(101; DateNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter('<>''''')); }
        field(102; DateQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter('''''')); }
        field(110; TimeEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FTime = filter('=''''')); }
        field(111; TimeNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FTime = filter('<>''''')); }
        field(112; TimeQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FTime = filter('''''')); }
        field(120; DateTimeEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDateTime = filter('=''''')); }
        field(121; DateTimeNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDateTime = filter('<>''''')); }
        field(122; DateTimeQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDateTime = filter('''''')); }
        field(130; IntEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FInt = filter('=''''')); }
        field(131; IntNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FInt = filter('<>''''')); }
        field(132; IntQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FInt = filter('''''')); }
        field(140; DecEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDec = filter('=''''')); }
        field(141; DecNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDec = filter('<>''''')); }
        field(142; DecQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDec = filter('''''')); }
        field(150; CodeEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FCode = filter('=''''')); }
        field(151; CodeNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FCode = filter('<>''''')); }
        field(152; CodeQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FCode = filter('''''')); }
        field(160; TextEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FText = filter('=''''')); }
        field(161; TextNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FText = filter('<>''''')); }
        field(162; TextQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FText = filter('''''')); }
        field(170; GuidEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FGuid = filter('=''''')); }
        field(171; GuidNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FGuid = filter('<>''''')); }
        field(172; GuidQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FGuid = filter('''''')); }
        field(180; DurEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDur = filter('=''''')); }
        field(181; DurNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDur = filter('<>''''')); }
        field(182; DurQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDur = filter('''''')); }
        field(190; DfEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDf = filter('=''''')); }
        field(191; DfNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDf = filter('<>''''')); }
        field(192; DfQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDf = filter('''''')); }
        field(200; OptEq; Code[15]) { TableRelation = "REC WhEmpty Master" where(FOpt = filter('=''''')); }
        field(201; OptNe; Code[15]) { TableRelation = "REC WhEmpty Master" where(FOpt = filter('<>''''')); }
        field(202; OptQ; Code[15]) { TableRelation = "REC WhEmpty Master" where(FOpt = filter('''''')); }
        field(300; DateBlank; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter('')); }
        field(301; DateZero; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter(0D)); }
        field(302; DateNotZero; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter(<> 0D)); }
        field(303; DateConst; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = const(0D)); }
        field(304; DateEqAndCode; Code[15]) { TableRelation = "REC WhEmpty Master" where(FDate = filter('='''''), FCode = filter('<>''''')); }
        field(305; DateEqField; Code[15]) { TableRelation = "REC WhEmpty Master"."Code" where(FDate = filter('=''''')); }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66333 "REC WhEmpty Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        M: Record "REC WhEmpty Master";
        R: Record "REC WhEmpty Response";
    begin
        M.DeleteAll();
        R.DeleteAll();
        M.Init();
        M."Code" := 'EMPTY';
        M.Insert();
        M.Init();
        M."Code" := 'SET';
        M.FDate := 20260115D;
        M.FTime := 101500T;
        M.FDateTime := CreateDateTime(20260115D, 101500T);
        M.FInt := 5;
        M.FDec := 2.5;
        M.FCode := 'X';
        M.FText := 'x';
        M.FGuid := '{11F319D9-C18B-449D-A6BC-6E725A266949}';
        M.FDur := 60000;
        Evaluate(M.FDf, '<1D>');
        M.FOpt := M.FOpt::B;
        M.Insert();
    end;

    [TryFunction]
    local procedure TryValidateRef(FieldNo: Integer; Value: Code[15])
    var
        R: Record "REC WhEmpty Response";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        R.Init();
        Ref.GetTable(R);
        Fld := Ref.Field(FieldNo);
        Fld.Validate(Value);
    end;

    [TryFunction]
    local procedure TryValidateDate(FieldNo: Integer; Value: Code[15])
    var
        R: Record "REC WhEmpty Response";
    begin
        R.Init();
        case FieldNo of
            R.FieldNo(DateEq):
                R.Validate(DateEq, Value);
            R.FieldNo(DateNe):
                R.Validate(DateNe, Value);
            R.FieldNo(DateQ):
                R.Validate(DateQ, Value);
            R.FieldNo(DateBlank):
                R.Validate(DateBlank, Value);
            R.FieldNo(DateZero):
                R.Validate(DateZero, Value);
            R.FieldNo(DateNotZero):
                R.Validate(DateNotZero, Value);
            R.FieldNo(DateConst):
                R.Validate(DateConst, Value);
            R.FieldNo(DateEqAndCode):
                R.Validate(DateEqAndCode, Value);
            R.FieldNo(DateEqField):
                R.Validate(DateEqField, Value);
            else
                Error('no Record.Validate case for field %1', FieldNo);
        end;
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe(Name, GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    local procedure RefCells(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer)
    begin
        Show(Observer, Name + ' EMPTY', TryValidateRef(FieldNo, 'EMPTY'));
        Show(Observer, Name + ' SET', TryValidateRef(FieldNo, 'SET'));
    end;

    local procedure DateCells(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer)
    begin
        Show(Observer, Name + ' EMPTY', TryValidateDate(FieldNo, 'EMPTY'));
        Show(Observer, Name + ' SET', TryValidateDate(FieldNo, 'SET'));
        Show(Observer, Name + ' NOPE', TryValidateDate(FieldNo, 'NOPE'));
        Show(Observer, Name + ' blank', TryValidateDate(FieldNo, ''));
    end;

    [Test]
    procedure WhereDate_EmptyQuotesFilter_RecordValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        DateCells(Observer, 'eq', R.FieldNo(DateEq));
        DateCells(Observer, 'ne', R.FieldNo(DateNe));
        DateCells(Observer, 'quotes', R.FieldNo(DateQ));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field DateEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field DateEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq blank', 'ok');
        Observer.Expect('ne EMPTY', 'The field DateNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('ne NOPE', 'The field DateNe of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne blank', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field DateQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('quotes NOPE', 'The field DateQ of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('quotes blank', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDate_OtherEmptyForms_RecordValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        DateCells(Observer, 'blank text', R.FieldNo(DateBlank));
        DateCells(Observer, 'filter 0D', R.FieldNo(DateZero));
        DateCells(Observer, 'filter ne 0D', R.FieldNo(DateNotZero));
        Observer.Expect('blank text EMPTY', 'ok');
        Observer.Expect('blank text SET', 'The field DateBlank of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('blank text NOPE', 'The field DateBlank of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('blank text blank', 'ok');
        Observer.Expect('filter 0D EMPTY', 'ok');
        Observer.Expect('filter 0D SET', 'The field DateZero of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('filter 0D NOPE', 'The field DateZero of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('filter 0D blank', 'ok');
        Observer.Expect('filter ne 0D EMPTY', 'The field DateNotZero of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('filter ne 0D SET', 'ok');
        Observer.Expect('filter ne 0D NOPE', 'The field DateNotZero of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('filter ne 0D blank', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDate_ConstAndTwoConditions_RecordValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        DateCells(Observer, 'const 0D', R.FieldNo(DateConst));
        DateCells(Observer, 'eq and code not empty', R.FieldNo(DateEqAndCode));
        DateCells(Observer, 'eq, table.field form', R.FieldNo(DateEqField));
        Observer.Expect('const 0D EMPTY', 'The format of the Date ''0001-01-01T00:00:00.0000000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. [Evaluate]');
        Observer.Expect('const 0D SET', 'The format of the Date ''0001-01-01T00:00:00.0000000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. [Evaluate]');
        Observer.Expect('const 0D NOPE', 'The format of the Date ''0001-01-01T00:00:00.0000000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. [Evaluate]');
        Observer.Expect('const 0D blank', 'ok');
        Observer.Expect('eq and code not empty EMPTY', 'The field DateEqAndCode of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq and code not empty SET', 'The field DateEqAndCode of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq and code not empty NOPE', 'The field DateEqAndCode of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq and code not empty blank', 'ok');
        Observer.Expect('eq, table.field form EMPTY', 'ok');
        Observer.Expect('eq, table.field form SET', 'The field DateEqField of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq, table.field form NOPE', 'The field DateEqField of table REC WhEm');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDate_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(DateEq));
        RefCells(Observer, 'ne', R.FieldNo(DateNe));
        RefCells(Observer, 'quotes', R.FieldNo(DateQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(DateEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field DateEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field DateNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field DateQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field DateEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereTime_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(TimeEq));
        RefCells(Observer, 'ne', R.FieldNo(TimeNe));
        RefCells(Observer, 'quotes', R.FieldNo(TimeQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(TimeEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field TimeEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field TimeNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field TimeQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field TimeEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDateTime_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(DateTimeEq));
        RefCells(Observer, 'ne', R.FieldNo(DateTimeNe));
        RefCells(Observer, 'quotes', R.FieldNo(DateTimeQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(DateTimeEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field DateTimeEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field DateTimeNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field DateTimeQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field DateTimeEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereInt_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(IntEq));
        RefCells(Observer, 'ne', R.FieldNo(IntNe));
        RefCells(Observer, 'quotes', R.FieldNo(IntQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(IntEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('eq SET', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('ne EMPTY', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('ne SET', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('quotes EMPTY', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('quotes SET', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('eq NOPE', 'The value "" can''t be evaluated into type Integer. [InvalidFilterExpression:Evaluate]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDec_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(DecEq));
        RefCells(Observer, 'ne', R.FieldNo(DecNe));
        RefCells(Observer, 'quotes', R.FieldNo(DecQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(DecEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('eq SET', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('ne EMPTY', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('ne SET', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('quotes EMPTY', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('quotes SET', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Expect('eq NOPE', 'The value "" can''t be evaluated into type Decimal. [InvalidFilterExpression:Evaluate]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereCode_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(CodeEq));
        RefCells(Observer, 'ne', R.FieldNo(CodeNe));
        RefCells(Observer, 'quotes', R.FieldNo(CodeQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(CodeEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field CodeEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field CodeNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field CodeQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field CodeEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereText_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(TextEq));
        RefCells(Observer, 'ne', R.FieldNo(TextNe));
        RefCells(Observer, 'quotes', R.FieldNo(TextQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(TextEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field TextEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field TextNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field TextQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field TextEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereGuid_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(GuidEq));
        RefCells(Observer, 'ne', R.FieldNo(GuidNe));
        RefCells(Observer, 'quotes', R.FieldNo(GuidQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(GuidEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('eq SET', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('ne EMPTY', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('ne SET', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('quotes EMPTY', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('quotes SET', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Expect('eq NOPE', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits. [InvalidFilterExpression:InvalidGuidFormat]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDur_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(DurEq));
        RefCells(Observer, 'ne', R.FieldNo(DurNe));
        RefCells(Observer, 'quotes', R.FieldNo(DurQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(DurEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field DurEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field DurNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field DurQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field DurEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereDf_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(DfEq));
        RefCells(Observer, 'ne', R.FieldNo(DfNe));
        RefCells(Observer, 'quotes', R.FieldNo(DfQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(DfEq), 'NOPE'));
        Observer.Expect('eq EMPTY', 'ok');
        Observer.Expect('eq SET', 'The field DfEq of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne EMPTY', 'The field DfNe of table REC WhEmpty Response contains a value (EMPTY) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('ne SET', 'ok');
        Observer.Expect('quotes EMPTY', 'ok');
        Observer.Expect('quotes SET', 'The field DfQ of table REC WhEmpty Response contains a value (SET) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Expect('eq NOPE', 'The field DfEq of table REC WhEmpty Response contains a value (NOPE) that cannot be found in the related table (REC WhEmpty Master). [DB:NothingInsideFilter]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereOpt_EmptyQuotesFilter_FieldRefValidate()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC WhEmpty Response";
    begin
        Initialize();
        RefCells(Observer, 'eq', R.FieldNo(OptEq));
        RefCells(Observer, 'ne', R.FieldNo(OptNe));
        RefCells(Observer, 'quotes', R.FieldNo(OptQ));
        Show(Observer, 'eq NOPE', TryValidateRef(R.FieldNo(OptEq), 'NOPE'));
        Observer.Expect('eq EMPTY', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('eq SET', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('ne EMPTY', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('ne SET', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('quotes EMPTY', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('quotes SET', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Expect('eq NOPE', ''''' is not an option. The existing options are: A,B,C [InvalidFilterExpression:InvalidOptionString]');
        Observer.Verify();
    end;
}
