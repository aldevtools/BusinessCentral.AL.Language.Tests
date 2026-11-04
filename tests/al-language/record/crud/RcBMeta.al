// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: self-contained tables 72016 to 72018, test codeunit 72009
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.RecordId, TableCaption, TableName, FieldCaption, FieldName, FieldNo, IsTemporary, ChangeCompany (type only), LockTable, ReadIsolation, Consistent, Relation, system fields
// (SystemId, SystemCreatedAt, SystemCreatedBy, SystemModifiedAt, SystemModifiedBy exist; no values), CurrentKey, GetPosition/SetPosition, Fields count,
// and the errors for unknown field numbers.
// BC versions: 29 (27 and 28 by CI)

table 72016 "LT RcB Meta"
{
    DataClassification = SystemMetadata;
    Caption = 'RcB Meta Caption';

    fields
    {
        field(1; Id; Integer) { Caption = 'Identifier'; }
        field(5; "Long Name"; Text[30]) { Caption = 'Long Name Caption'; }
        field(10; NoCaption; Code[10]) { }
        field(20; Parent; Code[10]) { TableRelation = "LT RcB Meta Parent"; }
        field(30; Dec; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; "Long Name", Id) { }
    }
}

table 72017 "LT RcB Meta Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 72018 "LT RcB Meta Tmp"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72009 "LT RcB Meta Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Captions_And_Names()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('TableCaption', Rec.TableCaption());
        Observer.Observe('TableName', Rec.TableName());
        Observer.Observe('FieldCaption Id', Rec.FieldCaption(Id));
        Observer.Observe('FieldName Id', Rec.FieldName(Id));
        Observer.Observe('FieldCaption long', Rec.FieldCaption("Long Name"));
        Observer.Observe('FieldName long', Rec.FieldName("Long Name"));
        Observer.Observe('FieldCaption nocaption', Rec.FieldCaption(NoCaption));
        Observer.Observe('FieldName nocaption', Rec.FieldName(NoCaption));
        Observer.Observe('FieldCaption parent', Rec.FieldCaption(Parent));
        Observer.Expect('TableCaption', 'RcB Meta Caption');
        Observer.Expect('TableName', 'LT RcB Meta');
        Observer.Expect('FieldCaption Id', 'Identifier');
        Observer.Expect('FieldName Id', 'Id');
        Observer.Expect('FieldCaption long', 'Long Name Caption');
        Observer.Expect('FieldName long', 'Long Name');
        Observer.Expect('FieldCaption nocaption', 'NoCaption');
        Observer.Expect('FieldName nocaption', 'NoCaption');
        Observer.Expect('FieldCaption parent', 'Parent');
        Observer.Verify();
    end;

    [Test]
    procedure FieldNo_Lookup()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Id', Format(Rec.FieldNo(Id)));
        Observer.Observe('Long Name', Format(Rec.FieldNo("Long Name")));
        Observer.Observe('NoCaption', Format(Rec.FieldNo(NoCaption)));
        Observer.Observe('Parent', Format(Rec.FieldNo(Parent)));
        Observer.Observe('Dec', Format(Rec.FieldNo(Dec)));
        Observer.Observe('SystemId', Format(Rec.FieldNo(SystemId)));
        Observer.Observe('SystemCreatedAt', Format(Rec.FieldNo(SystemCreatedAt)));
        Observer.Observe('SystemCreatedBy', Format(Rec.FieldNo(SystemCreatedBy)));
        Observer.Observe('SystemModifiedAt', Format(Rec.FieldNo(SystemModifiedAt)));
        Observer.Observe('SystemModifiedBy', Format(Rec.FieldNo(SystemModifiedBy)));
        Observer.Expect('Id', '1');
        Observer.Expect('Long Name', '5');
        Observer.Expect('NoCaption', '10');
        Observer.Expect('Parent', '20');
        Observer.Expect('Dec', '30');
        Observer.Expect('SystemId', '2000000000');
        Observer.Expect('SystemCreatedAt', '2000000001');
        Observer.Expect('SystemCreatedBy', '2000000002');
        Observer.Expect('SystemModifiedAt', '2000000003');
        Observer.Expect('SystemModifiedBy', '2000000004');
        Observer.Verify();
    end;

    [Test]
    procedure SystemFields_Exist()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Observer.Observe('SystemId null before insert', Format(IsNullGuid(Rec.SystemId)));
        Observer.Observe('SystemCreatedAt before insert', Format(Rec.SystemCreatedAt = 0DT));
        Rec.Id := 1;
        Rec.Insert();
        Rec.Get(1);
        Observer.Observe('SystemId set', Format(not IsNullGuid(Rec.SystemId)));
        Observer.Observe('SystemCreatedAt set', Format(Rec.SystemCreatedAt <> 0DT));
        Observer.Observe('SystemModifiedAt set', Format(Rec.SystemModifiedAt <> 0DT));
        Observer.Observe('SystemCreatedBy set', Format(not IsNullGuid(Rec.SystemCreatedBy)));
        Observer.Observe('SystemModifiedBy set', Format(not IsNullGuid(Rec.SystemModifiedBy)));
        Observer.Expect('SystemId null before insert', 'Yes');
        Observer.Expect('SystemCreatedAt before insert', 'Yes');
        Observer.Expect('SystemId set', 'Yes');
        Observer.Expect('SystemCreatedAt set', 'Yes');
        Observer.Expect('SystemModifiedAt set', 'Yes');
        Observer.Expect('SystemCreatedBy set', 'Yes');
        Observer.Expect('SystemModifiedBy set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SystemId_GetBySystemId_Unique()
    var
        Rec: Record "LT RcB Meta";
        Other: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Id := 2;
        Rec.Insert();
        Rec.Get(1);
        Other.Get(2);
        Observer.Observe('different ids', Format(Rec.SystemId <> Other.SystemId));
        Other.GetBySystemId(Rec.SystemId);
        Observer.Observe('GetBySystemId', Format(Other.Id));
        Observer.Observe('GetBySystemId null', Format(Other.GetBySystemId(CreateGuid())));
        Observer.Expect('different ids', 'Yes');
        Observer.Expect('GetBySystemId', '1');
        Observer.Expect('GetBySystemId null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SystemId_Rename_Keeps()
    var
        Rec: Record "LT RcB Meta";
        Before: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Get(1);
        Before := Rec.SystemId;
        Rec.Rename(2);
        Observer.Observe('same after rename', Format(Rec.SystemId = Before));
        Rec.Get(2);
        Observer.Observe('same after get', Format(Rec.SystemId = Before));
        Observer.Expect('same after rename', 'Yes');
        Observer.Expect('same after get', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordId_Basics()
    var
        Rec: Record "LT RcB Meta";
        RecId: RecordId;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 7;
        Rec.Insert();
        RecId := Rec.RecordId();
        Observer.Observe('format', Format(RecId));
        Observer.Observe('table no matches', Format(RecId.TableNo = Database::"LT RcB Meta"));
        Rec.Id := 8;
        Observer.Observe('follows pk', Format(Rec.RecordId()));
        Observer.Observe('differs', Format(Rec.RecordId() = RecId));
        Rec.Id := 7;
        Observer.Observe('equal', Format(Rec.RecordId() = RecId));
        Observer.Observe('Get by RecordId', Format(Rec.Get(RecId)));
        Observer.Expect('format', 'LT RcB Meta: 7');
        Observer.Expect('table no matches', 'Yes');
        Observer.Expect('follows pk', 'LT RcB Meta: 8');
        Observer.Expect('differs', 'No');
        Observer.Expect('equal', 'Yes');
        Observer.Expect('Get by RecordId', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordId_Empty_And_Composite()
    var
        Rec: Record "LT RcB Meta";
        Rec2: Record "LT RcB Meta Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty record', Format(Rec.RecordId()));
        Rec2.Code := 'C1';
        Observer.Observe('code pk', Format(Rec2.RecordId()));
        Observer.Observe('tableno', Format(Rec2.RecordId().TableNo = Database::"LT RcB Meta Parent"));
        Observer.Expect('empty record', 'LT RcB Meta: 0');
        Observer.Expect('code pk', 'LT RcB Meta Parent: C1');
        Observer.Expect('tableno', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetPosition_SetPosition()
    var
        Rec: Record "LT RcB Meta";
        Rec2: Record "LT RcB Meta";
        Pos: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 3;
        Rec."Long Name" := 'abc';
        Rec.Insert();
        Pos := Rec.GetPosition();
        Observer.Observe('position', Pos);
        Observer.Observe('position no fields', Rec.GetPosition(false));
        Rec2.SetPosition(Pos);
        Observer.Observe('set position id', Format(Rec2.Id));
        Observer.Observe('found by position', Format(Rec2.Find('=')));
        Observer.Observe('name after find', Rec2."Long Name");
        Rec2.SetPosition(Rec.GetPosition(true));
        Observer.Expect('position', 'Identifier=CONST(3)');
        Observer.Expect('position no fields', 'Field1=0(3)');
        Observer.Expect('set position id', '3');
        Observer.Expect('found by position', 'Yes');
        Observer.Expect('name after find', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentKey_Default_And_Set()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Rec.CurrentKey());
        Rec.SetCurrentKey("Long Name");
        Observer.Observe('after set', Rec.CurrentKey());
        Rec.SetCurrentKey("Long Name", Id);
        Observer.Observe('after set two', Rec.CurrentKey());
        Rec.SetCurrentKey(Id);
        Observer.Observe('back to pk', Rec.CurrentKey());
        Rec.SetCurrentKey(Dec);
        Observer.Observe('adhoc', Rec.CurrentKey());
        Rec.Reset();
        Observer.Observe('after reset', Rec.CurrentKey());
        Observer.Expect('default', 'Identifier');
        Observer.Expect('after set', 'Long Name Caption,Identifier');
        Observer.Expect('after set two', 'Long Name Caption,Identifier');
        Observer.Expect('back to pk', 'Identifier');
        Observer.Expect('adhoc', 'Dec');
        Observer.Expect('after reset', 'Identifier');
        Observer.Verify();
    end;

    [Test]
    procedure IsTemporary_Variants()
    var
        Normal: Record "LT RcB Meta";
        Tmp: Record "LT RcB Meta" temporary;
        TableTmp: Record "LT RcB Meta Tmp";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('normal', Format(Normal.IsTemporary()));
        Observer.Observe('temporary var', Format(Tmp.IsTemporary()));
        Observer.Observe('TableType temporary', Format(TableTmp.IsTemporary()));
        Observer.Expect('normal', 'No');
        Observer.Expect('temporary var', 'Yes');
        Observer.Expect('TableType temporary', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_Behaviour()
    var
        Tmp: Record "LT RcB Meta" temporary;
        Normal: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Normal.DeleteAll();
        Tmp.Id := 1;
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Insert();
        Observer.Observe('temp count', Format(Tmp.Count()));
        Observer.Observe('normal count', Format(Normal.Count()));
        Tmp.DeleteAll();
        Observer.Observe('temp after deleteall', Format(Tmp.Count()));
        Tmp.Id := 1;
        Tmp.Insert();
        asserterror Tmp.Insert();
        Observer.ObserveError('temp duplicate');
        Observer.Expect('temp count', '2');
        Observer.Expect('normal count', '0');
        Observer.Expect('temp after deleteall', '0');
        Observer.Expect('temp duplicate|text', 'The record in table RcB Meta Caption already exists. Identification fields and values: Identifier=''1''');
        Observer.Expect('temp duplicate|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_Errors()
    var
        Tmp: Record "LT RcB Meta" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Tmp.Id := 99;
        asserterror Tmp.Modify();
        Observer.ObserveError('temp modify missing');
        asserterror Tmp.Delete();
        Observer.ObserveError('temp delete missing');
        asserterror Tmp.Get(5);
        Observer.ObserveError('temp get missing');
        Observer.Observe('find', Format(Tmp.Find()));
        Observer.Expect('temp modify missing|text', 'The RcB Meta Caption does not exist. Identification fields and values: Identifier=''99''');
        Observer.Expect('temp modify missing|code', 'DB:RecordNotFound');
        Observer.Expect('temp delete missing|text', 'The RcB Meta Caption does not exist. Identification fields and values: Identifier=''99''');
        Observer.Expect('temp delete missing|code', 'DB:RecordNotFound');
        Observer.Expect('temp get missing|text', 'The RcB Meta Caption does not exist. Identification fields and values: Identifier=''5''');
        Observer.Expect('temp get missing|code', 'DB:RecordNotFound');
        Observer.Expect('find', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TableType_Temporary_Table()
    var
        Rec: Record "LT RcB Meta Tmp";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.Id := 1;
        Rec.Txt := 'a';
        Rec.Insert();
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Observe('is temporary', Format(Rec.IsTemporary()));
        Rec.DeleteAll();
        Observer.Observe('empty', Format(Rec.IsEmpty()));
        Observer.Expect('count', '1');
        Observer.Expect('is temporary', 'Yes');
        Observer.Expect('empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeCompany_TypeOnly()
    var
        Rec: Record "LT RcB Meta";
        Other: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Other.ChangeCompany(CompanyName());
        Observer.Observe('same company count', Format(Other.Count()));
        Observer.Observe('same company get', Format(Other.Get(1)));
        Other.ChangeCompany(CompanyName());
        Observer.Observe('changed twice', Format(Other.Count()));
        Observer.Expect('same company count', '1');
        Observer.Expect('same company get', 'Yes');
        Observer.Expect('changed twice', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LockTable_Variants()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.LockTable();
        Observer.Observe('locked', 'ok');
        Rec.LockTable(true);
        asserterror Rec.LockTable(false);
        Observer.ObserveError('af356');
        Observer.Expect('locked', 'ok');
        Observer.Expect('af356|text', 'The request to lock the LT RcB Meta table with a Wait parameter of FALSE is not supported.');
        Observer.Expect('af356|code', 'AL:LockTableBadParm');
        Observer.Verify();
    end;

    [Test]
    procedure ReadIsolation_Assign()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        Observer.Observe('ReadCommitted', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::RepeatableRead;
        Observer.Observe('RepeatableRead', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        Observer.Observe('UpdLock', Format(Rec.ReadIsolation));
        Rec.ReadIsolation := IsolationLevel::Default;
        Observer.Observe('Default', Format(Rec.ReadIsolation));
        Observer.Expect('default', 'Default');
        Observer.Expect('ReadCommitted', 'ReadCommitted');
        Observer.Expect('RepeatableRead', 'RepeatableRead');
        Observer.Expect('UpdLock', 'UpdLock');
        Observer.Expect('Default', 'Default');
        Observer.Verify();
    end;

    [Test]
    procedure Consistent_Flag()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Consistent(true);
        Rec.Consistent(false);
        Rec.Consistent(true);
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Fields_Metadata_Misc()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Observer.Observe('IsEmpty', Format(Rec.IsEmpty()));
        Rec.Id := 1;
        Rec.Insert();
        Observer.Observe('IsEmpty after', Format(Rec.IsEmpty()));
        Observer.Observe('Count', Format(Rec.Count()));
        Observer.Observe('CountApprox positive', Format(Rec.CountApprox() > 0));
        Observer.Observe('HasFilter', Format(Rec.HasFilter()));
        Rec.SetRange(Id, 5);
        Observer.Observe('HasFilter after', Format(Rec.HasFilter()));
        Observer.Observe('Rec.GetView', Rec.GetView());
        Observer.Observe('Rec.GetFilters', Rec.GetFilters());
        Observer.Expect('IsEmpty', 'Yes');
        Observer.Expect('IsEmpty after', 'No');
        Observer.Expect('Count', '1');
        Observer.Expect('CountApprox positive', 'Yes');
        Observer.Expect('HasFilter', 'No');
        Observer.Expect('HasFilter after', 'Yes');
        Observer.Expect('Rec.GetView', 'VERSION(1) SORTING(Identifier) WHERE(Identifier=FILTER(5))');
        Observer.Expect('Rec.GetFilters', 'Identifier: 5');
        Observer.Verify();
    end;

    [Test]
    procedure TableRelation_Validate()
    var
        Rec: Record "LT RcB Meta";
        Parent: Record "LT RcB Meta Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Rec.Id := 1;
        asserterror Rec.Validate(Parent, 'NOPE');
        Observer.ObserveError('missing parent');
        Parent.Code := 'P1';
        Parent.Insert();
        Rec.Validate(Parent, 'P1');
        Observer.Observe('valid parent', Rec.Parent);
        Rec.Validate(Parent, '');
        Observer.Observe('blank parent', '[' + Rec.Parent + ']');
        Rec.Parent := 'UNKNOWN';
        Observer.Observe('assigned unknown', Rec.Parent);
        Observer.Expect('missing parent|text', 'The field Parent of table RcB Meta Caption contains a value (NOPE) that cannot be found in the related table (LT RcB Meta Parent).');
        Observer.Expect('missing parent|code', 'DB:PrimRecordNotFound');
        Observer.Expect('valid parent', 'P1');
        Observer.Expect('blank parent', '[]');
        Observer.Expect('assigned unknown', 'UNKNOWN');
        Observer.Verify();
    end;

    [Test]
    procedure Setters_Roundtrip_Types()
    var
        Rec: Record "LT RcB Meta";
        Observer: Codeunit "Probe Observer";
    begin
        Rec."Long Name" := 'x';
        Observer.Observe('Fields assigned', Rec."Long Name");
        Rec.Dec := 1 / 3;
        Observer.Observe('decimal third', Format(Rec.Dec, 0, 9));
        Rec."Long Name" := CopyStr('this text is far longer than the thirty chars it fits', 1, 30);
        Observer.Observe('truncated copystr', Rec."Long Name");
        asserterror Rec."Long Name" := 'this text is far longer than the thirty chars it fits';
        Observer.ObserveError('overflow assign');
        Observer.Expect('Fields assigned', 'x');
        Observer.Expect('decimal third', '0.333333333333333333');
        Observer.Expect('truncated copystr', 'this text is far longer than t');
        Observer.Expect('overflow assign|text', 'The length of the string is 53, but it must be less than or equal to 30 characters. Value: this text is far longer than the thirty chars it fits');
        Observer.Expect('overflow assign|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    // Corpus issue 672 items 28 and 31 (AL issue 6449, Learn page of Record.RecordId): Format of the RecordId of a table whose Caption
    // ('RcB Meta Caption') differs from its name, with no format number and formats 0, 1, 2 and 9, in the session language and after
    // GlobalLanguage(1031); Evaluate of the format 1 text back into a RecordId.
    [Test]
    procedure BT_RecordId_Format_CaptionedTable()
    var
        Rec: Record "LT RcB Meta";
        RecId: RecordId;
        Back: RecordId;
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
        Ok: Boolean;
    begin
        Rec.Id := 7;
        RecId := Rec.RecordId();
        Observer.Observe('none', Format(RecId));
        Observer.Observe('0', Format(RecId, 0, 0));
        Observer.Observe('1', Format(RecId, 0, 1));
        Observer.Observe('2', Format(RecId, 0, 2));
        Observer.Observe('9', Format(RecId, 0, 9));
        Observer.Observe('tablecaption', Rec.TableCaption());
        Ok := Evaluate(Back, Format(RecId, 0, 1));
        Observer.Observe('evaluate 1', Format(Ok) + '|' + Format(Back = RecId));
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('1031 none', Format(RecId));
        Observer.Observe('1031 1', Format(RecId, 0, 1));
        Observer.Observe('1031 9', Format(RecId, 0, 9));
        GlobalLanguage(Saved);
        Observer.Expect('none', 'LT RcB Meta: 7');
        Observer.Expect('0', 'LT RcB Meta: 7');
        Observer.Expect('1', 'RcB Meta Caption: 7');
        Observer.Expect('2', 'LT RcB Meta: 7');
        Observer.Expect('9', 'LT RcB Meta: 7');
        Observer.Expect('tablecaption', 'RcB Meta Caption');
        Observer.Expect('evaluate 1', 'No|No');
        Observer.Expect('1031 none', 'LT RcB Meta: 7');
        Observer.Expect('1031 1', 'RcB Meta Caption: 7');
        Observer.Expect('1031 9', 'LT RcB Meta: 7');
        Observer.Verify();
    end;
}
