// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: assigning a record that has a Blob field (:=) copies the Blob's bytes; renaming a temporary record that has a Blob field (also Record: Rename of a temporary record with a Blob)
// Facts: Record := Record copies Blob content; Rename of a temporary record with a Blob in four write sequences
// BC versions: 29 (27 and 28 by CI)

codeunit 70092 "LT PnA Blob AssignRename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SetBlob(var Rec: Record "LT PnA Blob"; Txt: Text)
    var
        OutS: OutStream;
    begin
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText(Txt);
    end;

    local procedure GetBlob(var Rec: Record "LT PnA Blob"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not Rec.Data.HasValue() then
            exit('<no value>');
        Rec.Data.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    [Test]
    procedure Assign_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT PnA Blob" temporary;
        R2: Record "LT PnA Blob" temporary;
    begin
        R1.Code := 'A';
        SetBlob(R1, 'abc');
        R1.Insert();
        R2 := R1;
        Observer.Observe('copy-has-value', Format(R2.Data.HasValue()));
        Observer.Observe('copy-content', GetBlob(R2));
        SetBlob(R1, 'xyz');
        Observer.Observe('copy-after-source-change', GetBlob(R2));
        Observer.Observe('source-after-change', GetBlob(R1));
        SetBlob(R2, 'qqq');
        Observer.Observe('source-after-copy-change', GetBlob(R1));
        Observer.Observe('copy-after-copy-change', GetBlob(R2));
        R1.Modify();
        Observer.Observe('stored-source-after-modify', GetBlob(R1));
        R1.Get('A');
        Observer.Observe('regot-source', GetBlob(R1));
        Observer.Expect('copy-has-value', 'Yes');
        Observer.Expect('copy-content', 'abc');
        Observer.Expect('copy-after-source-change', 'abc');
        Observer.Expect('source-after-change', 'xyz');
        Observer.Expect('source-after-copy-change', 'xyz');
        Observer.Expect('copy-after-copy-change', 'qqq');
        Observer.Expect('stored-source-after-modify', 'xyz');
        Observer.Expect('regot-source', '');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_Stored()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT PnA Blob";
        R2: Record "LT PnA Blob";
    begin
        R1.DeleteAll();
        R1.Code := 'A';
        SetBlob(R1, 'abc');
        R1.Insert();
        R1.Get('A');
        R1.CalcFields(Data);
        R2 := R1;
        Observer.Observe('copy-content-loaded', GetBlob(R2));
        SetBlob(R1, 'xyz');
        Observer.Observe('copy-after-source-change', GetBlob(R2));
        R1.Get('A');
        R2 := R1;
        Observer.Observe('copy-content-notloaded', GetBlob(R2));
        R2.CalcFields(Data);
        Observer.Observe('copy-content-notloaded-calcfields', GetBlob(R2));
        R1.DeleteAll();
        Observer.Expect('copy-content-loaded', 'abc');
        Observer.Expect('copy-after-source-change', 'abc');
        Observer.Expect('copy-content-notloaded', '');
        Observer.Expect('copy-content-notloaded-calcfields', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure RenameTemporary_BlobSetBeforeInsert_AndNotPersisted()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA Blob" temporary;
        G: Record "LT PnA Blob" temporary;
    begin
        G.Copy(R, true);
        R.Code := 'A1';
        SetBlob(R, 'a1');
        R.Insert();
        R.Rename('A2');
        Observer.Observe('A-rec-content', GetBlob(R));
        Observer.Observe('A-old-key-exists', Format(G.Get('A1')));
        Observer.Observe('A-new-key-exists', Format(G.Get('A2')));
        Observer.Observe('A-new-key-content', GetBlob(G));

        R.Reset();
        R.DeleteAll();
        R.Code := 'B1';
        R.Insert();
        SetBlob(R, 'b1');
        R.Rename('B2');
        Observer.Observe('B-rec-content', GetBlob(R));
        Observer.Observe('B-new-key-exists', Format(G.Get('B2')));
        Observer.Observe('B-new-key-content', GetBlob(G));
        Observer.Expect('A-rec-content', '<no value>');
        Observer.Expect('A-old-key-exists', 'No');
        Observer.Expect('A-new-key-exists', 'Yes');
        Observer.Expect('A-new-key-content', '<no value>');
        Observer.Expect('B-rec-content', '<no value>');
        Observer.Expect('B-new-key-exists', 'Yes');
        Observer.Expect('B-new-key-content', '');
        Observer.Verify();
    end;

    [Test]
    procedure RenameTemporary_PersistedBeforeRename()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnA Blob" temporary;
        G: Record "LT PnA Blob" temporary;
    begin
        G.Copy(R, true);
        R.Code := 'C1';
        R.Insert();
        SetBlob(R, 'c1');
        R.Modify();
        R.Rename('C2');
        Observer.Observe('C-rec-content', GetBlob(R));
        Observer.Observe('C-new-key-exists', Format(G.Get('C2')));
        Observer.Observe('C-new-key-content', GetBlob(G));

        R.Reset();
        R.DeleteAll();
        R.Code := 'D1';
        SetBlob(R, 'd1');
        R.Insert();
        SetBlob(R, 'd2');
        R.Rename('D2');
        Observer.Observe('D-rec-content', GetBlob(R));
        Observer.Observe('D-new-key-exists', Format(G.Get('D2')));
        Observer.Observe('D-new-key-content', GetBlob(G));

        R.Reset();
        R.DeleteAll();
        R.Code := 'E1';
        SetBlob(R, 'e1');
        R.Insert();
        SetBlob(R, 'e2');
        R.Modify();
        SetBlob(R, 'e3');
        R.Rename('E2');
        Observer.Observe('E-rec-content', GetBlob(R));
        Observer.Observe('E-new-key-content', Format(G.Get('E2')) + '|' + GetBlob(G));
        Observer.Expect('C-rec-content', '<no value>');
        Observer.Expect('C-new-key-exists', 'Yes');
        Observer.Expect('C-new-key-content', '<no value>');
        Observer.Expect('D-rec-content', '<no value>');
        Observer.Expect('D-new-key-exists', 'Yes');
        Observer.Expect('D-new-key-content', '');
        Observer.Expect('E-rec-content', '<no value>');
        Observer.Expect('E-new-key-content', 'Yes|');
        Observer.Verify();
    end;
}
