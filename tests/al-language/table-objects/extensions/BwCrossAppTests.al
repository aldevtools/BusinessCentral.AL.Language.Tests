// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Probe (writer BW): AL across three or four apps, with the cross-app fixtures A, B and C (CONTRIBUTING.md, "Multi-app fixtures").
//   #668 item 87 (cross-app half): a table extension of app B declares a procedure with the name and signature of a procedure of app A's
//     table (compiler warning AL0523 "... already defines a method called ... This warning will become an error in a future release."),
//     and one whose name differs only in case. A call from this third app does not compile: AL0196 "The call is ambiguous between the
//     method 'BwSame()' defined in Table ... and the method 'BwSame()' defined in TableExtension ..." (must-not-compile 1581). Which body
//     runs when app A or app B calls it?
//   #668 item 95: app B's page has a protected variable whose type is a table of the AL Internals Test Fixture app; app C depends only on A
//     and B and extends the page. The publish works and the extension runs (microsoft/AL issue 6637 said the publish failed before
//     runtime 27.0). Using the variable from app C does not compile: AL0132 '__MissingTypeSymbol__' (must-not-compile 1580).
//   #668 item 96: Rename of a record of app A's table whose only extension field (app B) is a Blob, compared with a Text extension field.
//   #668 item 102: this app's page (SourceTableView) and FlowField (CalcFormula) filter on an Option field that app B's extension adds.
//   #664 item 14: this app's table extension reads and writes a field that app B's extension of the same table adds.
//   #664 item 144: app B subscribes to a local integration event of app A (compiles with no diagnostic).
// Fixtures: BwCrossAppObjects.al, tests/al-language-xapp-a|b|c. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 83951 "LT BW Cross App Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure TableExt_SameProcedureNameInAnotherApp_WhichBodyRuns()
    var
        Base: Record "LT BW XA Base";
    begin
        Initialize();
        Observer.Observe('BwSame from app A', Base.BwCallSameFromA());
        Observer.Observe('BwSame from app B', Base.BwCallSameFromB());
        Observer.Observe('BwOverload Integer', Base.BwOverload(5));
        Observer.Observe('BwOverload Text', Base.BwOverload('x'));
        Observer.Expect('BwSame from app A', 'table of app A');
        Observer.Expect('BwSame from app B', 'extension of app B');
        Observer.Expect('BwOverload Integer', 'table of app A, Integer 5');
        Observer.Expect('BwOverload Text', 'extension of app B, Text x');
        Observer.Verify();
    end;

    [Test]
    procedure Page_SourceTableViewAndFlowField_OnFieldOfAnotherAppsExtension()
    var
        Base: Record "LT BW XA Base";
        Counts: Record "LT BW XApp Counts";
        List: TestPage "LT BW XApp Second Kind List";
        Seen: Text;
    begin
        Initialize();
        AddBase('K1', Base."BW XB Kind"::First, 'n1');
        AddBase('K2', Base."BW XB Kind"::Second, 'n2');
        AddBase('K3', Base."BW XB Kind"::Second, 'n2');
        AddBase('K4', Base."BW XB Kind"::Third, 'n1');
        List.OpenView();
        if List.First() then
            repeat
                Seen += List."No.".Value() + ';';
            until not List.Next();
        List.Close();
        Observer.Observe('page rows', Seen);
        Counts."No." := 'C';
        Counts.Insert();
        Counts.CalcFields("Second Kind Count");
        Observer.Observe('flowfield count Second', Format(Counts."Second Kind Count"));
        Counts.SetRange("Note Filter", 'n1');
        Counts.CalcFields("Note Filter Count");
        Observer.Observe('flowfield count note n1', Format(Counts."Note Filter Count"));
        Base.SetRange("BW XB Kind", Base."BW XB Kind"::Second);
        Observer.Observe('SetRange count Second', Format(Base.Count()));
        Observer.Expect('page rows', 'K2;K3;');
        Observer.Expect('flowfield count Second', '2');
        Observer.Expect('flowfield count note n1', '2');
        Observer.Expect('SetRange count Second', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_BlobOnlyExtensionOfAnotherApp_BlobAndOldKey()
    var
        Row: Record "LT BW XA Rename Blob";
        Fresh: Record "LT BW XA Rename Blob";
        OutS: OutStream;
    begin
        Initialize();
        Row."No." := 'OLD';
        Row.Description := 'old row';
        Row."BW XB Blob".CreateOutStream(OutS);
        OutS.WriteText('blob of OLD');
        Row.Insert();
        Row.Rename('NEW');
        Observer.Observe('blob in variable after rename', BlobText(Row));
        Observer.Observe('get NEW', Format(Fresh.Get('NEW')));
        Fresh.CalcFields("BW XB Blob");
        Observer.Observe('NEW has value', Format(Fresh."BW XB Blob".HasValue()));
        Observer.Observe('NEW blob', BlobText(Fresh));
        Clear(Fresh);
        Observer.Observe('get OLD', Format(Fresh.Get('OLD')));
        Clear(Fresh);
        Fresh."No." := 'OLD';
        Fresh.Description := 'second old row';
        Observer.Observe('insert OLD again', Format(Fresh.Insert()));
        Clear(Fresh);
        Fresh.Get('OLD');
        Fresh.CalcFields("BW XB Blob");
        Observer.Observe('new OLD has value', Format(Fresh."BW XB Blob".HasValue()));
        Observer.Observe('new OLD blob', BlobText(Fresh));
        Observer.Observe('rows', Format(Fresh.Count()));
        Observer.Expect('blob in variable after rename', '<none>');
        Observer.Expect('get NEW', 'Yes');
        Observer.Expect('NEW has value', 'Yes');
        Observer.Expect('NEW blob', 'blob of OLD');
        Observer.Expect('get OLD', 'No');
        Observer.Expect('insert OLD again', 'Yes');
        Observer.Expect('new OLD has value', 'No');
        Observer.Expect('new OLD blob', '<none>');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_TextOnlyExtensionOfAnotherApp_FieldAndOldKey()
    var
        Row: Record "LT BW XA Rename Text";
        Fresh: Record "LT BW XA Rename Text";
    begin
        Initialize();
        Row."No." := 'OLD';
        Row."BW XB Text" := 'text of OLD';
        Row.Insert();
        Row.Rename('NEW');
        Observer.Observe('get NEW', Format(Fresh.Get('NEW')));
        Observer.Observe('NEW text', Fresh."BW XB Text");
        Clear(Fresh);
        Observer.Observe('get OLD', Format(Fresh.Get('OLD')));
        Clear(Fresh);
        Fresh."No." := 'OLD';
        Observer.Observe('insert OLD again', Format(Fresh.Insert()));
        Clear(Fresh);
        Fresh.Get('OLD');
        Observer.Observe('new OLD text', Fresh."BW XB Text");
        Observer.Observe('rows', Format(Fresh.Count()));
        Observer.Expect('get NEW', 'Yes');
        Observer.Expect('NEW text', 'text of OLD');
        Observer.Expect('get OLD', 'No');
        Observer.Expect('insert OLD again', 'Yes');
        Observer.Expect('new OLD text', '');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_ProtectedVarTypeFromUnreferencedApp_ExtensionRuns()
    var
        Master: Record "LT BW XB Master";
        Card: TestPage "LT BW XB Master Card";
    begin
        Initialize();
        Master."No." := 'M1';
        Master.Insert();
        Card.OpenView();
        Card.GoToRecord(Master);
        Observer.Observe('No.', Card."No.".Value());
        Observer.Observe('C marker', Card.BwXcMarker.Value());
        Observer.Observe('blah filter', Card.BlahFilterText.Value());
        Card.Close();
        Observer.Expect('No.', 'M1');
        Observer.Expect('C marker', 'extension of app C');
        Observer.Expect('blah filter', 'No.: BW-BLAH');
        Observer.Verify();
    end;

    [Test]
    procedure LocalEvent_SubscriberInDependentApp_Runs()
    var
        Publisher: Codeunit "LT BW XA Local Publisher";
    begin
        Initialize();
        Observer.Observe('log', Publisher.Raise());
        Observer.Expect('log', 'B local;');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_FieldOfAnotherAppsExtension_ReadAndWrite()
    var
        Base: Record "LT BW XA Base";
        Fresh: Record "LT BW XA Base";
    begin
        Initialize();
        Base."No." := 'F1';
        Base."BW XB Note" := 'note of B';
        Base.Insert();
        Observer.Observe('copy', Base.BwCopyNote());
        Base.Validate("BW M Copy", 'abc');
        Base.Modify();
        Fresh.Get('F1');
        Observer.Observe('B note after validate in M', Fresh."BW XB Note");
        Observer.Observe('M copy', Fresh."BW M Copy");
        Observer.Expect('copy', 'note of B');
        Observer.Expect('B note after validate in M', 'from M: abc');
        Observer.Expect('M copy', 'abc');
        Observer.Verify();
    end;

    // Writer QY (al-runtime-rs backlog "PROBES from multiapp-runtime", item 3): table extension 61114 of cross-app fixture B is a third table
    // extension of "LT BW XA Base" (B's 61110 and 61113 are the others) and calls BwSame() and BwCaseName() bare and through Rec. Both table 61101
    // of app A and table extension 61113 of app B declare them. It compiles in app B; the same calls from a table extension of a third app are
    // AL0196 (must-not-compile 2071). Which body runs? Observed: app B's extension 61113 (BwSame and bwcasename), bare and through Rec.
    [Test]
    procedure TableExt_ThirdExtensionInSameAppCallsSameName_WhichBodyRuns()
    var
        Base: Record "LT BW XA Base";
    begin
        Initialize();
        Observer.Observe('bare BwSame', Base.QyCallSameBare());
        Observer.Observe('Rec.BwSame', Base.QyCallSameRec());
        Observer.Observe('bare BwCaseName', Base.QyCallCaseNameBare());
        Observer.Expect('bare BwSame', 'extension of app B');
        Observer.Expect('Rec.BwSame', 'extension of app B');
        Observer.Expect('bare BwCaseName', 'extension of app B, bwcasename');
        Observer.Verify();
    end;

    // Writer QY (backlog "PROBES from multiapp-runtime", item 4): Rename of a row of cross-app fixture A's table "LT QY XA Rename Blobs", which has
    // three Blob fields: "XA Blob" of the table itself (app A), "QY XB Blob" of app B's table extension, "QY M Blob" of this app's table
    // extension. Observed: each Blob in the record variable right after Rename, after CalcFields on the variable, and in the database.
    // Result (BC 27.5, 28.5, 29.0): right after Rename every Blob of the variable has no value (own field and both extension fields alike); CalcFields reads the
    // renamed row, which holds the variable's Blob content from before Rename, also when it was written after Insert and never saved.
    [Test]
    procedure Rename_UnsavedBlobWrites_OwnFieldAndTwoExtensionFields()
    var
        Row: Record "LT QY XA Rename Blobs";
    begin
        Initialize();
        QyInitialize();
        Row."No." := 'OLD';
        Row.Description := 'old row';
        Row.Insert();
        QySetBlobs(Row, 'unsaved');
        Row.Rename('NEW');
        QyObserveAfterRename(Row);
        Observer.Expect('No. in variable', 'NEW');
        Observer.Expect('variable', '<none>;<none>;<none>;');
        Observer.Expect('variable after CalcFields', 'XA unsaved;XB unsaved;M unsaved;');
        Observer.Expect('get NEW', 'Yes');
        Observer.Expect('database', 'XA unsaved;XB unsaved;M unsaved;');
        Observer.Expect('database description', 'old row');
        Observer.Expect('get OLD', 'No');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_BlobsWrittenBeforeInsert_OwnFieldAndTwoExtensionFields()
    var
        Row: Record "LT QY XA Rename Blobs";
    begin
        Initialize();
        QyInitialize();
        Row."No." := 'OLD';
        Row.Description := 'old row';
        QySetBlobs(Row, 'inserted');
        Row.Insert();
        Row.Rename('NEW');
        QyObserveAfterRename(Row);
        Observer.Expect('No. in variable', 'NEW');
        Observer.Expect('variable', '<none>;<none>;<none>;');
        Observer.Expect('variable after CalcFields', 'XA inserted;XB inserted;M inserted;');
        Observer.Expect('get NEW', 'Yes');
        Observer.Expect('database', 'XA inserted;XB inserted;M inserted;');
        Observer.Expect('database description', 'old row');
        Observer.Expect('get OLD', 'No');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_UnsavedOverwriteOfInsertedBlobs_OwnFieldAndTwoExtensionFields()
    var
        Row: Record "LT QY XA Rename Blobs";
    begin
        Initialize();
        QyInitialize();
        Row."No." := 'OLD';
        Row.Description := 'old row';
        QySetBlobs(Row, 'inserted');
        Row.Insert();
        QySetBlobs(Row, 'overwritten');
        Row.Rename('NEW');
        QyObserveAfterRename(Row);
        Observer.Expect('No. in variable', 'NEW');
        Observer.Expect('variable', '<none>;<none>;<none>;');
        Observer.Expect('variable after CalcFields', 'XA overwritten;XB overwritten;M overwritten;');
        Observer.Expect('get NEW', 'Yes');
        Observer.Expect('database', 'XA overwritten;XB overwritten;M overwritten;');
        Observer.Expect('database description', 'old row');
        Observer.Expect('get OLD', 'No');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    // Item 4, second half: the record variable's Blob after Rename for a table of this app with its own Blob field (same app as the caller).
    // Observed: same as above, the variable's Blob has no value right after Rename; CalcFields and the database have the content.
    [Test]
    procedure Rename_BlobOfTableOfThisApp_VariableAfterRename()
    var
        Row: Record "LT QY Own Blob";
        Fresh: Record "LT QY Own Blob";
    begin
        Initialize();
        QyInitialize();
        Row."No." := 'S-OLD';
        QySetOwnBlob(Row, 'inserted');
        Row.Insert();
        Row.Rename('S-NEW');
        Observer.Observe('inserted: variable', QyOwnBlobText(Row));
        Row.CalcFields(Data);
        Observer.Observe('inserted: variable after CalcFields', QyOwnBlobText(Row));
        Fresh.Get('S-NEW');
        Fresh.CalcFields(Data);
        Observer.Observe('inserted: database', QyOwnBlobText(Fresh));

        Clear(Row);
        Row."No." := 'U-OLD';
        Row.Insert();
        QySetOwnBlob(Row, 'unsaved');
        Row.Rename('U-NEW');
        Observer.Observe('unsaved: variable', QyOwnBlobText(Row));
        Row.CalcFields(Data);
        Observer.Observe('unsaved: variable after CalcFields', QyOwnBlobText(Row));
        Clear(Fresh);
        Fresh.Get('U-NEW');
        Fresh.CalcFields(Data);
        Observer.Observe('unsaved: database', QyOwnBlobText(Fresh));
        Observer.Expect('inserted: variable', '<none>');
        Observer.Expect('inserted: variable after CalcFields', 'own inserted');
        Observer.Expect('inserted: database', 'own inserted');
        Observer.Expect('unsaved: variable', '<none>');
        Observer.Expect('unsaved: variable after CalcFields', 'own unsaved');
        Observer.Expect('unsaved: database', 'own unsaved');
        Observer.Verify();
    end;

    local procedure QyInitialize()
    var
        RenameBlobs: Record "LT QY XA Rename Blobs";
        OwnBlob: Record "LT QY Own Blob";
    begin
        RenameBlobs.DeleteAll();
        OwnBlob.DeleteAll();
    end;

    local procedure QySetBlobs(var Row: Record "LT QY XA Rename Blobs"; Tag: Text)
    var
        OutS: OutStream;
    begin
        Row."XA Blob".CreateOutStream(OutS);
        OutS.WriteText('XA ' + Tag);
        Row."QY XB Blob".CreateOutStream(OutS);
        OutS.WriteText('XB ' + Tag);
        Row."QY M Blob".CreateOutStream(OutS);
        OutS.WriteText('M ' + Tag);
    end;

    local procedure QyBlobsText(var Row: Record "LT QY XA Rename Blobs"): Text
    var
        InS: InStream;
        Part: Text;
        Result: Text;
    begin
        if Row."XA Blob".HasValue() then begin
            Row."XA Blob".CreateInStream(InS);
            InS.ReadText(Part);
            Result += Part + ';';
        end else
            Result += '<none>;';
        Clear(Part);
        if Row."QY XB Blob".HasValue() then begin
            Row."QY XB Blob".CreateInStream(InS);
            InS.ReadText(Part);
            Result += Part + ';';
        end else
            Result += '<none>;';
        Clear(Part);
        if Row."QY M Blob".HasValue() then begin
            Row."QY M Blob".CreateInStream(InS);
            InS.ReadText(Part);
            Result += Part + ';';
        end else
            Result += '<none>;';
        exit(Result);
    end;

    local procedure QyObserveAfterRename(var Row: Record "LT QY XA Rename Blobs")
    var
        Fresh: Record "LT QY XA Rename Blobs";
    begin
        Observer.Observe('No. in variable', Row."No.");
        Observer.Observe('variable', QyBlobsText(Row));
        Row.CalcFields("XA Blob", "QY XB Blob", "QY M Blob");
        Observer.Observe('variable after CalcFields', QyBlobsText(Row));
        Observer.Observe('get NEW', Format(Fresh.Get('NEW')));
        Fresh.CalcFields("XA Blob", "QY XB Blob", "QY M Blob");
        Observer.Observe('database', QyBlobsText(Fresh));
        Observer.Observe('database description', Fresh.Description);
        Clear(Fresh);
        Observer.Observe('get OLD', Format(Fresh.Get('OLD')));
        Observer.Observe('rows', Format(Fresh.Count()));
    end;

    local procedure QySetOwnBlob(var Row: Record "LT QY Own Blob"; Tag: Text)
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('own ' + Tag);
    end;

    local procedure QyOwnBlobText(var Row: Record "LT QY Own Blob"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        if not Row.Data.HasValue() then
            exit('<none>');
        Row.Data.CreateInStream(InS);
        InS.ReadText(Result);
        exit(Result);
    end;

    local procedure AddBase(No: Code[20]; Kind: Integer; Note: Text[30])
    var
        Base: Record "LT BW XA Base";
    begin
        Base."No." := No;
        Base."BW XB Kind" := Kind;
        Base."BW XB Note" := Note;
        Base.Insert();
    end;

    local procedure BlobText(var Row: Record "LT BW XA Rename Blob"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        if not Row."BW XB Blob".HasValue() then
            exit('<none>');
        Row."BW XB Blob".CreateInStream(InS);
        InS.ReadText(Result);
        exit(Result);
    end;

    local procedure Initialize()
    var
        Base: Record "LT BW XA Base";
        RenameBlob: Record "LT BW XA Rename Blob";
        RenameText: Record "LT BW XA Rename Text";
        Counts: Record "LT BW XApp Counts";
        Master: Record "LT BW XB Master";
    begin
        Base.DeleteAll();
        RenameBlob.DeleteAll();
        RenameText.DeleteAll();
        Counts.DeleteAll();
        Master.DeleteAll();
    end;
}
