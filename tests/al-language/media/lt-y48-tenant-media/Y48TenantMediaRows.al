// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (Tenant Media and Tenant Media Set are Scope = Cloud)
// Fixtures used: Probe Observer (69160); Base App table "Document Attachment" (1173) and its ImportAttachment (the four-argument
//        Media.ImportStream with a file name compiles only inside Microsoft's apps, as in Y44MediaExportStream.al); self-contained objects 92926 - 92928
// Probe: gap cycle 5, spec G5-04 (writer Y48). The Tenant Media row of a media imported with a file name; Delete, Modify (Content cleared,
//        Description changed) and Insert of Tenant Media rows from AL code, and what the Media field that holds the id then shows;
//        the Tenant Media Set rows of a MediaSet import and a Delete of the Tenant Media row of a set item.
//        Every write runs in a codeunit of its own (Codeunit.Run): an error BC raises is observed and the test goes on (the containers
//        refuse writes inside a TryFunction). Media ids are GUIDs and are never printed: relations only.
//        Asserted values: the CI containers BC 27.5, 28.5 and 29.0, all the same. A SaaS sandbox BC 29 gave the same rows but its license refuses
//        every write to Tenant Media and Tenant Media Set (ClientInsertDenied and so on), so the write values come from the containers only.
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
            // Writer Y57: Arg = '<description>|<mime type>' for the three-argument import, or '<description>' for the two-argument one
            'own import args':
                begin
                    OwnRow(Row);
                    TextStream(TempBlob, InS);
                    if StrPos(Arg, '|') > 0 then
                        Row.Pic.ImportStream(InS, CopyStr(Arg, 1, StrPos(Arg, '|') - 1), CopyStr(Arg, StrPos(Arg, '|') + 1))
                    else
                        Row.Pic.ImportStream(InS, Arg);
                    Row.Modify();
                    MediaGuid := Row.Pic.MediaId();
                    Result := 'imported';
                end;
            // Writer Y57: the Tenant Media row of a MediaSet item, Arg = description
            'own import set item':
                begin
                    OwnRow(Row);
                    TextStream(TempBlob, InS);
                    Row.Pics.ImportStream(InS, Arg);
                    Row.Modify();
                    MediaGuid := Row.Pics.Item(Row.Pics.Count());
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

    // Error texts can carry a media id or a session id: both change per run.
    local procedure ScrubIds(Value: Text): Text
    begin
        Value := Between(Value, 'ID=''', '''');
        Value := Between(Value, 'session ID: ''', '''');
        exit(Value);
    end;

    local procedure Between(Value: Text; StartText: Text; EndText: Text): Text
    var
        StartPos: Integer;
        Rest: Text;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, StartText);
        if StartPos = 0 then
            exit(Value);
        Rest := CopyStr(Value, StartPos + StrLen(StartText));
        EndPos := StrPos(Rest, EndText);
        if EndPos = 0 then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos + StrLen(StartText) - 1) + 'x' + CopyStr(Rest, EndPos));
    end;

    local procedure Run(Name: Text; Step: Text; Arg: Text; RowId: Integer; MediaGuid: Guid)
    var
        StepCu: Codeunit "LT Y48 TM Step";
    begin
        StepCu.SetStep(Step, Arg, RowId, MediaGuid);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + ScrubIds(GetLastErrorText()) + '|' + GetLastErrorCode());
        LastGuid := StepCu.GetMediaGuid();
    end;

    // The Tenant Media Set row of one item (Media Index is a time-based number and the key order follows the media ids: neither is printed).
    local procedure SetItem(SetId: Guid; ItemId: Guid): Text
    var
        TMS: Record "Tenant Media Set";
    begin
        TMS.SetRange(ID, SetId);
        if TMS.FindSet() then
            repeat
                if TMS."Media ID".MediaId() = ItemId then
                    exit('row: company=' + Format(TMS."Company Name" = CompanyName()) + ' hasvalue=' + Format(TMS."Media ID".HasValue()) + ' index>0=' + Format(TMS."Media Index" > 0) + ';');
            until TMS.Next() = 0;
        exit('no row;');
    end;

    local procedure IndexOf(SetId: Guid; ItemId: Guid): BigInteger
    var
        TMS: Record "Tenant Media Set";
    begin
        TMS.SetRange(ID, SetId);
        if TMS.FindSet() then
            repeat
                if TMS."Media ID".MediaId() = ItemId then
                    exit(TMS."Media Index");
            until TMS.Next() = 0;
        exit(-1);
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
        Observer.Expect('attach A', 'ok:attached');
        Observer.Expect('TestFile_A.txt', 'Description=|Mime Type=text/plain|File Name=TestFile_A.txt|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Expect('attach B', 'ok:attached');
        Observer.Expect('TestFile_B', 'Description=|Mime Type=application/octet-stream|File Name=TestFile_B|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Expect('attach C', 'ok:attached');
        Observer.Expect('TestFile_C.PDF', 'Description=|Mime Type=application/pdf|File Name=TestFile_C.PDF|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Verify();
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
        Observer.Expect('attach', 'ok:attached');
        Observer.Expect('tm delete', 'ok:Yes');
        Observer.Expect('tm row after delete', 'no row');
        Observer.Expect('attachment: hasvalue', 'No');
        Observer.Expect('attachment: mediaid = id', 'Yes');
        Observer.Expect('attachment: export', 'ok len=0 text=');
        Observer.Expect('own import', 'ok:imported');
        Observer.Expect('own tm delete', 'ok:Yes');
        Observer.Expect('own tm row after delete', 'no row');
        Observer.Expect('own: hasvalue', 'No');
        Observer.Expect('own: mediaid = id', 'Yes');
        Observer.Expect('own: export', 'ok len=0 text=');
        Observer.Verify();
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
        Observer.Expect('own import', 'ok:imported');
        Observer.Expect('tm row before', 'Description=test.txt|Mime Type=text/plain|File Name=|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Expect('clear content', 'ok:Yes');
        Observer.Expect('tm row after clear', 'Description=test.txt|Mime Type=text/plain|File Name=|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=0');
        Observer.Expect('after clear: hasvalue', 'Yes');
        Observer.Expect('after clear: mediaid = id', 'Yes');
        Observer.Expect('after clear: export', 'ok len=0 text=');
        Observer.Expect('own import 2', 'ok:imported');
        Observer.Expect('change description', 'ok:Yes');
        Observer.Expect('tm row after description', 'Description=changed|Mime Type=text/plain|File Name=|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Expect('after description: hasvalue', 'Yes');
        Observer.Expect('after description: export', 'ok len=38 text=Test content for attachment ABC123xyz0');
        Observer.Verify();
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
        Observer.Expect('insert', 'ok:Yes');
        Observer.Expect('tm row', 'Description=|Mime Type=|File Name=|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=1');
        Observer.Expect('set pic by recref', 'ok:Yes');
        Observer.Expect('pic: hasvalue', 'Yes');
        Observer.Expect('pic: mediaid = new id', 'Yes');
        Observer.Expect('pic: export', 'ok len=1 text=1');
        Observer.Expect('insert without company', 'ok:Yes');
        Observer.Expect('tm row without company', 'Description=|Mime Type=|File Name=|Height=0|Width=0|Company Name=[]|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=1');
        Observer.Expect('set pic by recref without company', 'ok:Yes');
        Observer.Expect('pic without company: hasvalue', 'Yes');
        Observer.Expect('pic without company: export', 'ok len=1 text=1');
        Observer.Expect('insert same id again', 'ok:No');
        Observer.Verify();
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
        Rows := SetItem(SetId, Row.Pics.Item(1)) + SetItem(SetId, Row.Pics.Item(2)) + 'index 1 < index 2=' + Format(IndexOf(SetId, Row.Pics.Item(1)) < IndexOf(SetId, Row.Pics.Item(2))) + ';';
        Observer.Observe('tms rows', Rows);
        Observer.Observe('item 1 tm row', TmRow(Row.Pics.Item(1)));
        TMS.Reset();
        Observer.Observe('tms isempty', Format(TMS.IsEmpty()));
        Observer.Observe('tm isempty', Format(TM.IsEmpty()));
        Observer.Expect('fresh guid: isempty', 'Yes');
        Observer.Expect('import set', 'ok:imported');
        Observer.Expect('pics count', '2');
        Observer.Expect('tms count', '2');
        Observer.Expect('tms rows', 'row: company=Yes hasvalue=Yes index>0=Yes;row: company=Yes hasvalue=Yes index>0=Yes;index 1 < index 2=Yes;');
        Observer.Expect('item 1 tm row', 'Description=a|Mime Type=application/octet-stream|File Name=|Height=0|Width=0|Company Name=<CompanyName()>|Prohibit Cache=No|Creating User empty=Yes|Expiration empty=Yes|Security Token empty=Yes|len=38');
        Observer.Expect('tms isempty', 'No');
        Observer.Expect('tm isempty', 'No');
        Observer.Verify();
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
        if Row.Pics.Count() >= 1 then
            Observer.Observe('pics item 1 = deleted id', Format(Row.Pics.Item(1) = Item1));
        TMS.SetRange(ID, SetId);
        Observer.Observe('tms count', Format(TMS.Count()));
        Rows := SetItem(SetId, Item1);
        if Row.Pics.Count() >= 2 then
            Rows += SetItem(SetId, Row.Pics.Item(2));
        Observer.Observe('tms rows', Rows);
        Observer.Expect('import set', 'ok:imported');
        Observer.Expect('tm delete item 1', 'ok:Yes');
        Observer.Expect('pics count', '2');
        Observer.Expect('pics item 1 = deleted id', 'Yes');
        Observer.Expect('tms count', '2');
        Observer.Expect('tms rows', 'row: company=Yes hasvalue=No index>0=Yes;row: company=Yes hasvalue=Yes index>0=Yes;');
        Observer.Verify();
    end;

    // Writer Y57: the Tenant Media row of the media AL code imports itself (two- and three-argument ImportStream, a MediaSet item), and
    // more file names through Document Attachment's four-argument import.
    [Test]
    procedure TM_RowOfOwnImports()
    var
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('two args', 'own import args', 'my description', 61, NullGuid);
        Observer.Observe('two args row', TmRow(LastGuid));
        Run('two args file-like', 'own import args', 'report.pdf', 62, NullGuid);
        Observer.Observe('two args file-like row', TmRow(LastGuid));
        Run('three args', 'own import args', 'test.txt|text/plain', 63, NullGuid);
        Observer.Observe('three args row', TmRow(LastGuid));
        Run('three args other mime', 'own import args', 'pic|image/png', 64, NullGuid);
        Observer.Observe('three args other mime row', TmRow(LastGuid));
        Run('three args empty mime', 'own import args', 'x.json|', 65, NullGuid);
        Observer.Observe('three args empty mime row', TmRow(LastGuid));
        Run('set item', 'own import set item', 'set item description', 66, NullGuid);
        Observer.Observe('set item row', TmRow(LastGuid));
        Observer.Finish();
    end;

    [Test]
    procedure TM_RowOfFourArgImport_MoreNames()
    var
        NullGuid: Guid;
    begin
        Clear(Observer);
        Run('attach D', 'attach', 'TestFile_D.xlsx', 71, NullGuid);
        Observer.Observe('TestFile_D.xlsx', TmRow(LastGuid));
        Run('attach E', 'attach', 'TestFile_E.json', 72, NullGuid);
        Observer.Observe('TestFile_E.json', TmRow(LastGuid));
        Run('attach F', 'attach', 'Test.File.F.TXT', 73, NullGuid);
        Observer.Observe('Test.File.F.TXT', TmRow(LastGuid));
        Run('attach G', 'attach', 'TestFile_G.csv', 74, NullGuid);
        Observer.Observe('TestFile_G.csv', TmRow(LastGuid));
        Run('attach H', 'attach', 'TestFile_H.docx', 75, NullGuid);
        Observer.Observe('TestFile_H.docx', TmRow(LastGuid));
        Run('attach I', 'attach', 'TestFile_I.xml', 76, NullGuid);
        Observer.Observe('TestFile_I.xml', TmRow(LastGuid));
        Observer.Finish();
    end;
}
