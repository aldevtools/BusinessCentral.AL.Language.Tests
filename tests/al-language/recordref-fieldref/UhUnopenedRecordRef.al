// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 66990
// Probe: observed by the corpus CI matrix (BC 27.5, 28.5, 29.0); the values asserted below are what BC produced.
// Facts: what the members of a RecordRef that was never opened (and of one opened and closed) do, a value or the error text and code;
//   RecordRef.GetTable of a Variant that holds an empty Text, an Integer, a non-empty Text and nothing; the members of a KeyRef nothing
//   assigned. Every cell has its own test. Repros of aldevtools/BusinessCentral.AL.Runner#7760, #7764, #8084 and #8001.
// BC versions: 27.5, 28.5, 29.0

table 66990 "LT UH Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 66991 "LT UH Unopened RecordRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try(Step: Text; var Result: Text)
    var
        Rec: Record "LT UH Row";
        RR: RecordRef;
        RR2: RecordRef;
        Src: RecordRef;
        KR: KeyRef;
        FR: FieldRef;
        V: Variant;
        RecId: RecordId;
    begin
        Src.Open(66990);
        case Step of
            'u_copylinks':
                begin
                    RR.CopyLinks(Src); Result := 'done';
                end;
            'u_findset':
                begin
                    Result := Format(RR.FindSet());
                end;
            'u_readpermission':
                begin
                    Result := Format(RR.ReadPermission());
                end;
            'u_writepermission':
                begin
                    Result := Format(RR.WritePermission());
                end;
            'u_fieldcount':
                begin
                    Result := Format(RR.FieldCount());
                end;
            'u_findfirst':
                begin
                    Result := Format(RR.FindFirst());
                end;
            'u_findlast':
                begin
                    Result := Format(RR.FindLast());
                end;
            'u_find':
                begin
                    Result := Format(RR.Find());
                end;
            'u_setrecfilter':
                begin
                    RR.SetRecFilter(); Result := 'done';
                end;
            'u_getfilters':
                begin
                    Result := RR.GetFilters();
                end;
            'u_keyindex':
                begin
                    KR := RR.KeyIndex(1); Result := 'done';
                end;
            'u_setloadfields':
                begin
                    RR.SetLoadFields(1); Result := 'done';
                end;
            'u_name':
                begin
                    Result := RR.Name();
                end;
            'u_keycount':
                begin
                    Result := Format(RR.KeyCount());
                end;
            'u_isempty':
                begin
                    Result := Format(RR.IsEmpty());
                end;
            'u_count':
                begin
                    Result := Format(RR.Count());
                end;
            'u_istemporary':
                begin
                    Result := Format(RR.IsTemporary());
                end;
            'u_reset':
                begin
                    RR.Reset(); Result := 'done';
                end;
            'u_field':
                begin
                    FR := RR.Field(1); Result := 'done';
                end;
            'u_caption':
                begin
                    Result := RR.Caption();
                end;
            'u_init':
                begin
                    RR.Init(); Result := 'done';
                end;
            'u_number':
                begin
                    Result := Format(RR.Number());
                end;
            'u_close':
                begin
                    RR.Close(); Result := 'done';
                end;
            'u_insert':
                begin
                    Result := Format(RR.Insert());
                end;
            'u_modify':
                begin
                    Result := Format(RR.Modify());
                end;
            'u_delete':
                begin
                    Result := Format(RR.Delete());
                end;
            'u_get':
                begin
                    Result := Format(RR.Get(RecId));
                end;
            'u_next':
                begin
                    Result := Format(RR.Next());
                end;
            'u_recordid':
                begin
                    Result := Format(RR.RecordId());
                end;
            'u_currentkey':
                begin
                    Result := Format(RR.CurrentKeyIndex());
                end;
            'c_copylinks':
                begin
                    RR.Open(66990); RR.Close();
                    RR.CopyLinks(Src); Result := 'done';
                end;
            'c_findset':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.FindSet());
                end;
            'c_readpermission':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.ReadPermission());
                end;
            'c_writepermission':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.WritePermission());
                end;
            'c_fieldcount':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.FieldCount());
                end;
            'c_findfirst':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.FindFirst());
                end;
            'c_name':
                begin
                    RR.Open(66990); RR.Close();
                    Result := RR.Name();
                end;
            'c_number':
                begin
                    RR.Open(66990); RR.Close();
                    Result := Format(RR.Number());
                end;
            'c_close':
                begin
                    RR.Open(66990); RR.Close();
                    RR.Close(); Result := 'done';
                end;
            'u_copylinksrec':
                begin
                    RR.CopyLinks(Rec);
                    Result := 'done';
                end;
            'c_copylinksrec':
                begin
                    RR.Open(66990);
                    RR.Close();
                    RR.CopyLinks(Rec);
                    Result := 'done';
                end;
            'gt_empty':
                begin
                    V := '';
                    RR.GetTable(V);
                    Result := 'done';
                end;
            'gt_int':
                begin
                    V := 5;
                    RR.GetTable(V);
                    Result := 'done';
                end;
            'gt_unassigned':
                begin
                    RR.GetTable(V);
                    Result := 'done';
                end;
            'gt_text':
                begin
                    V := 'abc';
                    RR.GetTable(V);
                    Result := 'done';
                end;
            'kr_fieldcount':
                Result := Format(KR.FieldCount());
            'kr_active':
                Result := Format(KR.Active());
            'kr_fieldindex':
                begin
                    FR := KR.FieldIndex(1);
                    Result := 'done';
                end;
            'kr_record':
                begin
                    RR2 := KR.Record();
                    Result := 'done';
                end;
        end;
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Step: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if Try(Step, Result) then
            Observer.Observe('result', 'ok:' + Result)
        else
            Observer.Observe('result', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Untouched_CopyLinks()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_copylinks');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_FindSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_findset');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_ReadPermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_readpermission');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_WritePermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_writepermission');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_FieldCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_fieldcount');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_FindLast()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_findlast');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Find()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_find');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_SetRecFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_setrecfilter');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_GetFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_getfilters');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_KeyIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_keyindex');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_SetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_setloadfields');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_name');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_KeyCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_keycount');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_IsEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_isempty');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_count');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_IsTemporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_istemporary');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Reset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_reset');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Field()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_field');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Caption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_caption');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Init()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_init');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Number()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_number');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Close()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_close');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Insert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_insert');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Modify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_modify');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Delete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_delete');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_get');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_Next()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_next');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_RecordId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_recordid');
        Observer.Finish();
    end;

    [Test]
    procedure Untouched_CurrentKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_currentkey');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_CopyLinks()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_copylinks');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_FindSet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_findset');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_ReadPermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_readpermission');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_WritePermission()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_writepermission');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_FieldCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_fieldcount');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_FindFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_findfirst');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_Name()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_name');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_Number()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_number');
        Observer.Finish();
    end;

    [Test]
    procedure Closed_Close()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_close');
        Observer.Finish();
    end;

    [Test]
    procedure CopyLinks_FromRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'u_copylinksrec');
        Observer.Finish();
    end;

    [Test]
    procedure CopyLinks_Closed_FromRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'c_copylinksrec');
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_VariantEmptyText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'gt_empty');
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_VariantInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'gt_int');
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_VariantUnassigned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'gt_unassigned');
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_VariantTextNonEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'gt_text');
        Observer.Finish();
    end;

    [Test]
    procedure KeyRef_FieldCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'kr_fieldcount');
        Observer.Finish();
    end;

    [Test]
    procedure KeyRef_Active()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'kr_active');
        Observer.Finish();
    end;

    [Test]
    procedure KeyRef_FieldIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'kr_fieldindex');
        Observer.Finish();
    end;

    [Test]
    procedure KeyRef_Record()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'kr_record');
        Observer.Finish();
    end;
}
