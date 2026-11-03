// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-schema
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosave-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoupdate-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoreplace-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usetemporary-xmlport-property
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005), ALT Universal (60000), ALT Blob (60008), XmlPort fixtures 60024..60029

codeunit 60207 "Test XmlPort Advanced"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure XmlPort_NestedTableElements_ExportIncludesChildRecordsAndAttribute()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        XmlText: Text;
        ParentChildXmlPort: XmlPort "ALT Parent Child XmlPort";
        Ok: Boolean;
    begin
        Initialize();
        InsertParent(1, 'P1');
        InsertChild(10, 1, 'C10', 15);
        InsertChild(11, 1, 'C11', 25);

        PrepareBlobOutStream('XPA1', BlobRec, OutStr);
        ParentChildXmlPort.SetDestination(OutStr);
        Ok := ParentChildXmlPort.Export();
        BlobRec.Modify();
        XmlText := ReadBlobText('XPA1');

        Assert.IsTrue(Ok, 'Nested XmlPort export must report success');
        Assert.IsTrue(XmlText.Contains('<ParentEntryNo>1</ParentEntryNo>'), 'Nested XmlPort export must include the parent row');
        Assert.IsTrue(XmlText.Contains('<ChildEntryNo>10</ChildEntryNo>'), 'Nested XmlPort export must include the first child row');
        // Amount is a Decimal; BC's XML serialization formats it with 2 decimal places
        // regardless of the AL literal used to seed it (15, not 15.00).
        Assert.IsTrue(XmlText.Contains('Amount="15.00"'), 'Nested XmlPort export must include fieldattribute values on child elements');
    end;

    [Test]
    procedure XmlPort_NestedTableElements_ImportCreatesParentAndChildren()
    var
        BlobRec: Record "ALT Blob" temporary;
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        StageParentChildImportBlobText(BlobRec);
        DeleteParentChildRows();
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportParentChildXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('Nested XmlPort import must report success. LastError=%1', ErrorText));
        Assert.AreEqual(1, Parent.Count(), 'Nested XmlPort import must insert the parent row');
        Assert.AreEqual(2, Child.Count(), 'Nested XmlPort import must insert both child rows');
        Child.Get(10);
        Assert.AreEqual(1, Child."Parent Entry No.", 'Nested XmlPort import must preserve parent-child links');
        Assert.AreEqual(15, Child.Amount, 'Nested XmlPort import must assign fieldattribute values');
    end;

    [Test]
    procedure XmlPort_TextVariableTriggers_ExportManipulatesTextAndAttributes()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        XmlText: Text;
        VariableXmlPort: XmlPort "ALT Variable XmlPort";
        Ok: Boolean;
    begin
        Initialize();
        InsertUniversalRow(1, 2, 'First', '');

        PrepareBlobOutStream('XPA3', BlobRec, OutStr);
        VariableXmlPort.SetDestination(OutStr);
        Ok := VariableXmlPort.Export();
        BlobRec.Modify();
        XmlText := ReadBlobText('XPA3');

        Assert.IsTrue(Ok, 'Variable XmlPort export must report success');
        Assert.IsTrue(XmlText.Contains('NoteAttr="FIRST"'), 'OnBeforePassVariable on textattribute must shape exported attribute values');
        Assert.IsTrue(XmlText.Contains('<DisplayText>TXT:First</DisplayText>'), 'OnBeforePassVariable on textelement must shape exported text values');
    end;

    [Test]
    procedure XmlPort_TextVariableTriggers_ImportMutatesAssignedValues()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        StageVariableImportBlobText(BlobRec);
        DeleteUniversalRows();
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportVariableXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('Variable XmlPort import must report success. LastError=%1', ErrorText));
        Universal.Get(1);
        Assert.AreEqual(30, Universal."Integer Field", 'OnAfterAssignField must be able to mutate imported field values before insert');
        Assert.AreEqual('alpha', Universal."Text Field", 'OnAfterAssignVariable on textelement must be able to rewrite imported text values');
        Assert.AreEqual('ALPHA', Universal."Description Field", 'OnAfterAssignVariable on textattribute must be able to map unbound values onto the record');
    end;

    [Test]
    procedure XmlPort_AutoUpdate_UpdatesSpecifiedFieldsAndPreservesOthers()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'Keep', 'KeepDesc');
        StagePartialUniversalImportBlob(BlobRec, 1, 99, 'Keep');
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportUpdateXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('AutoUpdate XmlPort import must report success. LastError=%1', ErrorText));
        Universal.Get(1);
        Assert.AreEqual(99, Universal."Integer Field", 'AutoUpdate must update fields that are present in the imported XmlPort');
        Assert.AreEqual('Keep', Universal."Text Field", 'AutoUpdate must preserve fields that are not present in the imported XmlPort');
        Assert.AreEqual('KeepDesc', Universal."Description Field", 'AutoUpdate must preserve other omitted fields');
    end;

    [Test]
    procedure XmlPort_AutoReplace_ReinitializesOmittedFields()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'Keep', 'KeepDesc');
        StagePartialUniversalImportBlob(BlobRec, 1, 99, 'Keep');
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportReplaceXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('AutoReplace XmlPort import must report success. LastError=%1', ErrorText));
        Universal.Get(1);
        Assert.AreEqual(99, Universal."Integer Field", 'AutoReplace must populate fields that are present in the imported XmlPort');
        Assert.AreEqual('', Universal."Text Field", 'AutoReplace must reinitialize fields that are omitted from the imported XmlPort');
        Assert.AreEqual('', Universal."Description Field", 'AutoReplace must reset omitted fields to their initial values');
    end;

    [Test]
    procedure XmlPort_AutoSaveFalse_OnBeforeAndAfterInsertControlPersistence()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        StageFullUniversalImportBlob(BlobRec, 1, 10, 'First');
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportManualXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('Manual XmlPort import must report success. LastError=%1', ErrorText));
        Universal.Get(1);
        Assert.AreEqual('manual-insert-First-after', Universal."Description Field", 'AutoSave=false must allow OnBeforeInsertRecord and OnAfterInsertRecord to control persistence');
    end;

    [Test]
    procedure XmlPort_AutoSaveFalse_OnBeforeAndAfterModifyControlPersistence()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        InsertUniversalRow(1, 10, 'Before', 'Existing');
        StageFullUniversalImportBlob(BlobRec, 1, 42, 'After');
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportManualXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('Manual XmlPort modify path must report success. LastError=%1', ErrorText));
        Universal.Get(1);
        Assert.AreEqual(42, Universal."Integer Field", 'AutoSave=false with AutoUpdate=true must allow OnBeforeModifyRecord to apply field updates manually');
        Assert.AreEqual('After', Universal."Text Field", 'AutoSave=false modify path must be able to persist imported text values manually');
        Assert.AreEqual('manual-modify-after', Universal."Description Field", 'AutoSave=false modify path must allow OnAfterModifyRecord to observe and adjust the stored record');
    end;

    [Test]
    procedure XmlPort_UseTemporary_RequiresManualPersistence()
    var
        BlobRec: Record "ALT Blob" temporary;
        Universal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
        ErrorText: Text;
    begin
        Initialize();
        StageFullUniversalImportBlob(BlobRec, 1, 10, 'Temp');
        OpenTempBlobInStream(BlobRec, InStr);

        ClearLastError();
        Ok := TryImportTemporaryXmlPort(InStr);
        ErrorText := GetLastErrorText();

        Assert.IsTrue(Ok, StrSubstNo('UseTemporary XmlPort import must report success. LastError=%1', ErrorText));
        Assert.IsFalse(Universal.Get(1), 'UseTemporary tableelements must not automatically persist the imported key to the real table');
        Universal.Get(1001);
        Assert.AreEqual(10, Universal."Integer Field", 'UseTemporary trigger code must be able to copy imported values into real records manually');
        Assert.AreEqual('Temp', Universal."Text Field", 'UseTemporary manual copy must preserve imported text values');
        Assert.AreEqual('temp-copy', Universal."Description Field", 'UseTemporary manual copy must be able to stamp persisted records');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertParent(EntryNo: Integer; ParentCode: Code[20])
    var
        Parent: Record "ALT Parent";
    begin
        Parent.Init();
        Parent."Entry No." := EntryNo;
        Parent.Code := ParentCode;
        Parent.Insert();
    end;

    local procedure InsertChild(EntryNo: Integer; ParentEntryNo: Integer; ChildCode: Code[20]; Amount: Decimal)
    var
        Child: Record "ALT Child";
    begin
        Child.Init();
        Child."Entry No." := EntryNo;
        Child."Parent Entry No." := ParentEntryNo;
        Child.Code := ChildCode;
        Child.Amount := Amount;
        Child.Insert();
    end;

    local procedure InsertUniversalRow(EntryNo: Integer; IntegerValue: Integer; TextValue: Text; DescriptionValue: Text)
    var
        Universal: Record "ALT Universal";
    begin
        Universal.Init();
        Universal."Entry No." := EntryNo;
        Universal."Integer Field" := IntegerValue;
        Universal."Text Field" := TextValue;
        Universal."Description Field" := DescriptionValue;
        Universal.Insert();
    end;

    local procedure PrepareBlobOutStream(BlobCode: Code[20]; var BlobRec: Record "ALT Blob"; var OutStr: OutStream)
    begin
        BlobRec.Init();
        BlobRec.Code := BlobCode;
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
    end;

    local procedure ReadBlobText(BlobCode: Code[20]): Text
    var
        BlobRec: Record "ALT Blob";
        InStr: InStream;
        Segment: Text;
        AllText: Text;
    begin
        BlobRec.Get(BlobCode);
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);

        while not InStr.EOS() do begin
            InStr.ReadText(Segment);
            AllText += Segment;
        end;

        exit(AllText);
    end;

    local procedure StageParentChildImportBlobText(var BlobRec: Record "ALT Blob" temporary)
    var
        OutStr: OutStream;
        ParentChildXmlPort: XmlPort "ALT Parent Child XmlPort";
        Ok: Boolean;
    begin
        InsertParent(1, 'P1');
        InsertChild(10, 1, 'C10', 15);
        InsertChild(11, 1, 'C11', 25);

        PrepareTempBlobOutStream(BlobRec, OutStr);
        ParentChildXmlPort.SetDestination(OutStr);
        Ok := ParentChildXmlPort.Export();
        Assert.IsTrue(Ok, 'Parent/child XmlPort export must succeed before import roundtrip assertions');
    end;

    local procedure StageVariableImportBlobText(var BlobRec: Record "ALT Blob" temporary)
    var
        OutStr: OutStream;
        VariableXmlPort: XmlPort "ALT Variable XmlPort";
        Ok: Boolean;
    begin
        InsertUniversalRow(1, 3, 'alpha', '');

        PrepareTempBlobOutStream(BlobRec, OutStr);
        VariableXmlPort.SetDestination(OutStr);
        Ok := VariableXmlPort.Export();
        Assert.IsTrue(Ok, 'Variable XmlPort export must succeed before import roundtrip assertions');
    end;

    local procedure StagePartialUniversalImportBlob(var BlobRec: Record "ALT Blob" temporary; EntryNo: Integer; IntegerValue: Integer; ExistingTextValue: Text)
    var
        OutStr: OutStream;
    begin
        PrepareTempBlobOutStream(BlobRec, OutStr);
        WritePartialUniversalXml(OutStr, EntryNo, IntegerValue);
    end;

    local procedure StageFullUniversalImportBlob(var BlobRec: Record "ALT Blob" temporary; EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    var
        OutStr: OutStream;
    begin
        PrepareTempBlobOutStream(BlobRec, OutStr);
        WriteFullUniversalXml(OutStr, EntryNo, IntegerValue, TextValue);
    end;

    local procedure PrepareTempBlobOutStream(var BlobRec: Record "ALT Blob" temporary; var OutStr: OutStream)
    begin
        BlobRec.Reset();
        if BlobRec.FindFirst() then
            BlobRec.DeleteAll();
        BlobRec.Init();
        BlobRec.Code := 'TMP';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
    end;

    local procedure OpenTempBlobInStream(var BlobRec: Record "ALT Blob" temporary; var InStr: InStream)
    begin
        BlobRec.Data.CreateInStream(InStr);
    end;

    local procedure DeleteUniversalRows()
    var
        Universal: Record "ALT Universal";
    begin
        Universal.DeleteAll(false);
    end;

    local procedure DeleteParentChildRows()
    var
        Parent: Record "ALT Parent";
        Child: Record "ALT Child";
    begin
        Child.DeleteAll(false);
        Parent.DeleteAll(false);
    end;

    [TryFunction]
    local procedure TryImportParentChildXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60024, InStr);
    end;

    [TryFunction]
    local procedure TryImportVariableXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60025, InStr);
    end;

    [TryFunction]
    local procedure TryImportUpdateXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60026, InStr);
    end;

    [TryFunction]
    local procedure TryImportReplaceXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60027, InStr);
    end;

    [TryFunction]
    local procedure TryImportManualXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60028, InStr);
    end;

    [TryFunction]
    local procedure TryImportTemporaryXmlPort(var InStr: InStream)
    begin
        XmlPort.Import(60029, InStr);
    end;

    local procedure WritePartialUniversalXml(var OutStr: OutStream; EntryNo: Integer; IntegerValue: Integer)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<Universals>');
        OutStr.WriteText(StrSubstNo('<Universal><EntryNo>%1</EntryNo><IntegerValue>%2</IntegerValue></Universal>', EntryNo, IntegerValue));
        OutStr.WriteText('</Universals>');
    end;

    local procedure WriteFullUniversalXml(var OutStr: OutStream; EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    begin
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<Universals>');
        OutStr.WriteText(StrSubstNo('<Universal><EntryNo>%1</EntryNo><IntegerValue>%2</IntegerValue><TextValue>%3</TextValue></Universal>', EntryNo, IntegerValue, TextValue));
        OutStr.WriteText('</Universals>');
    end;
}
