// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// Probe: written against real BC 27.5, 28.5 and 29.0 (identical results).
// CalcFields(Blob) picks up a Blob value another variable stored for the same
// row, even when the variable already holds a Blob buffer (empty, loaded
// earlier, or an unsaved write):
//  - Variable A holds an empty Blob, variable B changes the row and calls
//    Modify(). Before CalcFields, A.Data.HasValue() is false and A reads empty.
//    After A.CalcFields(Data), A reads B's text. Same when A called Modify()
//    first, and when B was copied from A by assignment (B := A).
//  - A has an unsaved write (no Modify) and B modifies the row: A keeps its own
//    text until CalcFields, then CalcFields replaces it with B's text (the
//    unsaved write is lost). A.Modify() afterwards stores B's text.
//  - A loaded FIRST with CalcFields, B stores SECOND: A still reads FIRST until
//    the next CalcFields, then reads SECOND.
// Contrast: when no other variable changed the row, CalcFields keeps an unsaved
// write (TestBlobCalcFieldsUncommittedWrite.al).

codeunit 96340 "LT Blob CalcFields Stale"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Stale_EmptyBuffer_OtherModifies_CalcFields()
    var
        A: Record "ALT Blob";
        B: Record "ALT Blob";
        Obs: Text;
    begin
        Cleanup.Initialize();
        A.Init();
        A.Code := 'S1';
        A.Insert();
        B.Get('S1');
        WriteBlob(B, 'B-TEXT');
        B.Modify();
        Obs := 'beforeHasValue=' + Format(A.Data.HasValue()) + ';beforeRead=' + ReadBlob(A);
        A.CalcFields(Data);
        Obs += ';afterHasValue=' + Format(A.Data.HasValue()) + ';afterRead=' + ReadBlob(A);
        Assert.AreEqual('beforeHasValue=No;beforeRead=;afterHasValue=Yes;afterRead=B-TEXT', Obs, 'Observed on real BC');
    end;

    [Test]
    procedure Stale_EmptyBuffer_AModifiedFirst_OtherModifies_CalcFields()
    var
        A: Record "ALT Blob";
        B: Record "ALT Blob";
        Obs: Text;
    begin
        Cleanup.Initialize();
        A.Init();
        A.Code := 'S2';
        A.Insert();
        A.Description := 'touched';
        A.Modify();
        B.Get('S2');
        WriteBlob(B, 'B-TEXT');
        B.Modify();
        Obs := 'beforeHasValue=' + Format(A.Data.HasValue()) + ';beforeRead=' + ReadBlob(A);
        A.CalcFields(Data);
        Obs += ';afterHasValue=' + Format(A.Data.HasValue()) + ';afterRead=' + ReadBlob(A);
        Assert.AreEqual('beforeHasValue=No;beforeRead=;afterHasValue=Yes;afterRead=B-TEXT', Obs, 'Observed on real BC');
    end;

    [Test]
    procedure Stale_UnsavedWriteInA_OtherModifies_CalcFields()
    var
        A: Record "ALT Blob";
        B: Record "ALT Blob";
        C: Record "ALT Blob";
        Obs: Text;
    begin
        Cleanup.Initialize();
        A.Init();
        A.Code := 'S3';
        A.Insert();
        WriteBlob(A, 'A-UNSAVED');
        B.Get('S3');
        WriteBlob(B, 'B-TEXT');
        B.Modify();
        Obs := 'beforeRead=' + ReadBlob(A);
        A.CalcFields(Data);
        Obs += ';afterRead=' + ReadBlob(A);
        A.Modify();
        C.Get('S3');
        C.CalcFields(Data);
        Obs += ';afterAModifyStored=' + ReadBlob(C);
        Assert.AreEqual('beforeRead=A-UNSAVED;afterRead=B-TEXT;afterAModifyStored=B-TEXT', Obs, 'Observed on real BC');
    end;

    [Test]
    procedure Stale_CopiedByAssignment_OtherModifies_CalcFields()
    var
        A: Record "ALT Blob";
        B: Record "ALT Blob";
        Obs: Text;
    begin
        Cleanup.Initialize();
        A.Init();
        A.Code := 'S4';
        A.Insert();
        B := A;
        WriteBlob(B, 'B-TEXT');
        B.Modify();
        Obs := 'beforeHasValue=' + Format(A.Data.HasValue()) + ';beforeRead=' + ReadBlob(A);
        A.CalcFields(Data);
        Obs += ';afterHasValue=' + Format(A.Data.HasValue()) + ';afterRead=' + ReadBlob(A);
        Assert.AreEqual('beforeHasValue=No;beforeRead=;afterHasValue=Yes;afterRead=B-TEXT', Obs, 'Observed on real BC');
    end;

    [Test]
    procedure Stale_LoadedValue_OtherChanges_CalcFieldsAgain()
    var
        A: Record "ALT Blob";
        B: Record "ALT Blob";
        Obs: Text;
    begin
        Cleanup.Initialize();
        A.Init();
        A.Code := 'S5';
        WriteBlob(A, 'FIRST');
        A.Insert();
        A.Get('S5');
        A.CalcFields(Data);
        Obs := 'loaded=' + ReadBlob(A);
        B.Get('S5');
        WriteBlob(B, 'SECOND');
        B.Modify();
        Obs += ';beforeSecondCalc=' + ReadBlob(A);
        A.CalcFields(Data);
        Obs += ';afterSecondCalc=' + ReadBlob(A);
        Assert.AreEqual('loaded=FIRST;beforeSecondCalc=FIRST;afterSecondCalc=SECOND', Obs, 'Observed on real BC');
    end;

    local procedure WriteBlob(var Rec: Record "ALT Blob"; Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec.Data);
        Rec.Data.CreateOutStream(OutStr);
        OutStr.WriteText(Value);
    end;

    local procedure ReadBlob(var Rec: Record "ALT Blob"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.Data.CreateInStream(InStr);
        InStr.ReadText(Result);
        exit(Result);
    end;
}
