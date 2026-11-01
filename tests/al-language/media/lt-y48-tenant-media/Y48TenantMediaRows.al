// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (Tenant Media and Tenant Media Set are Scope = Cloud)
// Fixtures used: Probe Observer (69160); Base App table "Document Attachment" (1173) and its ImportAttachment (the four-argument
//        Media.ImportStream with a file name compiles only inside Microsoft's apps, as in Y44MediaExportStream.al); self-contained objects 92926 - 92928
// Probe: gap cycle 5, spec G5-04 (writer Y48). The Tenant Media row of a media imported with a file name; Delete, Modify (Content cleared,
//        Description changed) and Insert of Tenant Media rows from AL code, and what the Media field that holds the id then shows;
//        the Tenant Media Set rows of a MediaSet import and a Delete of the Tenant Media row of a set item.
//        Every write runs in a codeunit of its own (Codeunit.Run): an error BC raises is observed and the test goes on (the containers
//        refuse writes inside a TryFunction). Media ids are GUIDs and are never printed: relations only.
// BC versions: 27, 28, 29

table 92926 "LT Y48 TM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92927 "LT Y48 TM Step"
{
    var
        Step: Text;
        Arg: Text;
        RowId: Integer;
        MediaGuid: Guid;
        Result: Text;
        ContentTxt: Label 'Test content for attachment ABC123xyz0', Locked = true;

    procedure SetStep(NewStep: Text; NewArg: Text; NewRowId: Integer; NewMediaGuid: Guid)
    begin
        Step := NewStep;
        Arg := NewArg;
        RowId := NewRowId;
        MediaGuid := NewMediaGuid;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    procedure GetMediaGuid(): Guid
    begin
        exit(MediaGuid);
    end;

    local procedure TextStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(ContentTxt);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    local procedure OwnRow(var Row: Record "LT Y48 TM Row")
    begin
        if not Row.Get(RowId) then begin
            Row.Init();
            Row.Id := RowId;
            Row.Insert();
        end;
    end;

    trigger OnRun()
    var
        DA: Record "Document Attachment";
        TM: Record "Tenant Media";
        Row: Record "LT Y48 TM Row";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InS: InStream;
        OutS: OutStream;
    begin
        case Step of
            // Arg = file name; RowId = line of the attachment
            'attach':
                begin
                    TextStream(TempBlob, InS);
                    DA.Init();
                    DA."Table ID" := Database::"Document Attachment";
                    DA."No." := 'LTY48TM' + Format(RowId);
                    DA."File Name" := CopyStr(Arg, 1, MaxStrLen(DA."File Name"));
                    DA.Insert(false);
                    DA.ImportAttachment(InS, Arg);
                    DA.Modify(false);
                    MediaGuid := DA."Document Reference ID".MediaId();
                    Result := 'attached';
                end;
            // Arg = 'd' (two-argument import) or 'mime' (three-argument with text/plain)
            'own import':
                begin
                    OwnRow(Row);
                    TextStream(TempBlob, InS);
                    if Arg = 'mime' then
                        Row.Pic.ImportStream(InS, 'test.txt', 'text/plain')
                    else
                        Row.Pic.ImportStream(InS, 'd');
                    Row.Modify();
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'imported';
                end;
            'own import set':
                begin
                    OwnRow(Row);
                    TextStream(TempBlob, InS);
                    Row.Pics.ImportStream(InS, 'a');
                    TextStream(TempBlob, InS);
                    Row.Pics.ImportStream(InS, 'a');
                    Row.Modify();
                    MediaGuid := Row.Pics.MediaId();
                    Result := 'imported';
                end;
            'tm delete':
                begin
                    TM.ReadIsolation(IsolationLevel::UpdLock);
                    TM.Get(MediaGuid);
                    Result := Format(TM.Delete());
                end;
            'tm clear content':
                begin
                    TM.Get(MediaGuid);
                    Clear(TM.Content);
                    Result := Format(TM.Modify());
                end;
            'tm description':
                begin
                    TM.Get(MediaGuid);
                    TM.Description := 'changed';
                    Result := Format(TM.Modify());
                end;
            // Arg = 'company' or ''
            'tm insert':
                begin
                    TM.Init();
                    if Arg = 'company' then
                        TM."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TM."Company Name"));
                    TM.Content.CreateOutStream(OutS);
                    OutS.WriteText('1');
                    TM.ID := MediaGuid;
                    Result := Format(TM.Insert());
                end;
            'set pic by recref':
                begin
                    OwnRow(Row);
                    RecRef.GetTable(Row);
                    RecRef.Field(Row.FieldNo(Pic)).Value(MediaGuid);
                    Result := Format(RecRef.Modify());
                end;
        end;
    end;
}

codeunit 92928 "LT Y48 Tenant Media Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LastGuid: Guid;

    local procedure Run(Name: Text; Step: Text; Arg: Text; RowId: Integer; MediaGuid: Guid)
    var
        StepCu: Codeunit "LT Y48 TM Step";
    begin
        StepCu.SetStep(Step, Arg, RowId, MediaGuid);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        LastGuid := StepCu.GetMediaGuid();
    end;

    local procedure TmRow(Id: Guid): Text
    var
        TM: Record "Tenant Media";
        Company: Text;
    begin
        if not TM.Get(Id) then
            exit('no row');
        TM.CalcFields(Content);
        if TM."Company Name" = CompanyName() then
            Company := '<CompanyName()>'
        else
            Company := '[' + TM."Company Name" + ']';
        exit('Description=' + TM.Description + '|Mime Type=' + TM."Mime Type" + '|File Name=' + TM."File Name" + '|Height=' + Format(TM.Height) +
            '|Width=' + Format(TM.Width) + '|Company Name=' + Company + '|Prohibit Cache=' + Format(TM."Prohibit Cache") +
            '|Creating User empty=' + Format(TM."Creating User" = '') + '|Expiration empty=' + Format(TM."Expiration Date" = 0DT) +
            '|Security Token empty=' + Format(TM."Security Token" = '') + '|len=' + Format(TM.Content.Length()));
    end;

    [TryFunction]
    local procedure TryExportRow(var Row: Record "LT Y48 TM Row"; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Row.Pic.ExportStream(OutS);
    end;

    [TryFunction]
    local procedure TryExportDA(var DA: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        DA."Document Reference ID".ExportStream(OutS);
    end;

    local procedure Exported(Ok: Boolean; var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not Ok then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(T);
        exit('ok len=' + Format(TempBlob.Length()) + ' text=' + T);
    end;

    local procedure Export(var Row: Record "LT Y48 TM Row"): Text
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        ClearLastError();
        exit(Exported(TryExportRow(Row, TempBlob), TempBlob));
    end;

    local procedure ExportDA(var DA: Record "Document Attachment"): Text
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        ClearLastError();
        exit(Exported(TryExportDA(DA, TempBlob), TempBlob));
    end;

    local procedure DAMedia(No: Code[20]; var DA: Record "Document Attachment")
    begin
        DA.SetRange("Table ID", Database::"Document Attachment");
        DA.SetRange("No.", No);
        DA.FindFirst();
    end;

    [Test]
    procedure TM_RowOfFourArgImport()
    var
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('attach A', 'attach', 'TestFile_A.txt', 1, NullGuid);
        Observer.Observe('TestFile_A.txt', TmRow(LastGuid));
        Run('attach B', 'attach', 'TestFile_B', 2, NullGuid);
        Observer.Observe('TestFile_B', TmRow(LastGuid));
        Run('attach C', 'attach', 'TestFile_C.PDF', 3, NullGuid);
        Observer.Observe('TestFile_C.PDF', TmRow(LastGuid));
        Observer.Finish();
    end;

    [Test]
    procedure TM_DeleteRowOfHeldMedia()
    var
        DA: Record "Document Attachment";
        Row: Record "LT Y48 TM Row";
        Id: Guid;
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('attach', 'attach', 'TestFile_A.txt', 11, NullGuid);
        Id := LastGuid;
        Run('tm delete', 'tm delete', '', 0, Id);
        Observer.Observe('tm row after delete', TmRow(Id));
        DAMedia('LTY48TM11', DA);
        Observer.Observe('attachment: hasvalue', Format(DA."Document Reference ID".HasValue()));
        Observer.Observe('attachment: mediaid = id', Format(DA."Document Reference ID".MediaId() = Id));
        Observer.Observe('attachment: export', ExportDA(DA));

        Run('own import', 'own import', 'd', 12, NullGuid);
        Id := LastGuid;
        Run('own tm delete', 'tm delete', '', 0, Id);
        Observer.Observe('own tm row after delete', TmRow(Id));
        Row.Get(12);
        Observer.Observe('own: hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('own: mediaid = id', Format(Row.Pic.MediaId() = Id));
        Observer.Observe('own: export', Export(Row));
        Observer.Finish();
    end;

    [Test]
    procedure TM_ModifyClearContent()
    var
        Row: Record "LT Y48 TM Row";
        Id: Guid;
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('own import', 'own import', 'mime', 21, NullGuid);
        Id := LastGuid;
        Observer.Observe('tm row before', TmRow(Id));
        Run('clear content', 'tm clear content', '', 0, Id);
        Observer.Observe('tm row after clear', TmRow(Id));
        Row.Get(21);
        Observer.Observe('after clear: hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('after clear: mediaid = id', Format(Row.Pic.MediaId() = Id));
        Observer.Observe('after clear: export', Export(Row));

        Run('own import 2', 'own import', 'mime', 22, NullGuid);
        Id := LastGuid;
        Run('change description', 'tm description', '', 0, Id);
        Observer.Observe('tm row after description', TmRow(Id));
        Row.Get(22);
        Observer.Observe('after description: hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('after description: export', Export(Row));
        Observer.Finish();
    end;

    [Test]
    procedure TM_InsertByCode_ThenUseAsMediaId()
    var
        Row: Record "LT Y48 TM Row";
        NewId: Guid;
        NewId2: Guid;
    begin
        Clear(Observer);
        NewId := CreateGuid();
        Run('insert', 'tm insert', 'company', 0, NewId);
        Observer.Observe('tm row', TmRow(NewId));
        Run('set pic by recref', 'set pic by recref', '', 31, NewId);
        Row.Get(31);
        Observer.Observe('pic: hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic: mediaid = new id', Format(Row.Pic.MediaId() = NewId));
        Observer.Observe('pic: export', Export(Row));

        NewId2 := CreateGuid();
        Run('insert without company', 'tm insert', '', 0, NewId2);
        Observer.Observe('tm row without company', TmRow(NewId2));
        Run('set pic by recref without company', 'set pic by recref', '', 32, NewId2);
        Row.Get(32);
        Observer.Observe('pic without company: hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic without company: export', Export(Row));

        Run('insert same id again', 'tm insert', 'company', 0, NewId);
        Observer.Finish();
    end;

    [Test]
    procedure TMS_RowsOfMediaSetImport()
    var
        Row: Record "LT Y48 TM Row";
        TMS: Record "Tenant Media Set";
        TM: Record "Tenant Media";
        SetId: Guid;
        Rows: Text;
        NullGuid: Guid;
    begin
        Clear(Observer);
        TMS.SetRange(ID, CreateGuid());
        Observer.Observe('fresh guid: isempty', Format(TMS.IsEmpty()));
        Run('import set', 'own import set', '', 41, NullGuid);
        SetId := LastGuid;
        Row.Get(41);
        Observer.Observe('pics count', Format(Row.Pics.Count()));
        TMS.SetRange(ID, SetId);
        Observer.Observe('tms count', Format(TMS.Count()));
        if TMS.FindSet() then
            repeat
                Rows += 'index=' + Format(TMS."Media Index") + ' company=' + Format(TMS."Company Name" = CompanyName()) + ' hasvalue=' +
                    Format(TMS."Media ID".HasValue()) + ' item1=' + Format(TMS."Media ID".MediaId() = Row.Pics.Item(1)) +
                    ' item2=' + Format(TMS."Media ID".MediaId() = Row.Pics.Item(2)) + ';';
            until TMS.Next() = 0;
        Observer.Observe('tms rows', Rows);
        Observer.Observe('item 1 tm row', TmRow(Row.Pics.Item(1)));
        TMS.Reset();
        Observer.Observe('tms isempty', Format(TMS.IsEmpty()));
        Observer.Observe('tm isempty', Format(TM.IsEmpty()));
        Observer.Finish();
    end;

    [Test]
    procedure TM_DeleteRowOfMediaInSet()
    var
        Row: Record "LT Y48 TM Row";
        TMS: Record "Tenant Media Set";
        SetId: Guid;
        Item1: Guid;
        Rows: Text;
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('import set', 'own import set', '', 51, NullGuid);
        SetId := LastGuid;
        Row.Get(51);
        Item1 := Row.Pics.Item(1);
        Run('tm delete item 1', 'tm delete', '', 0, Item1);
        Row.Get(51);
        Observer.Observe('pics count', Format(Row.Pics.Count()));
        Observer.Observe('pics item 1 = deleted id', Format(Row.Pics.Item(1) = Item1));
        TMS.SetRange(ID, SetId);
        Observer.Observe('tms count', Format(TMS.Count()));
        if TMS.FindSet() then
            repeat
                Rows += 'index=' + Format(TMS."Media Index") + ' hasvalue=' + Format(TMS."Media ID".HasValue()) + ' deleted=' + Format(TMS."Media ID".MediaId() = Item1) + ';';
            until TMS.Next() = 0;
        Observer.Observe('tms rows', Rows);
        Observer.Finish();
    end;
}
