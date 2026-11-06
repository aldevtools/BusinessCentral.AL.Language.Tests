// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// Probe: CalcFields(Blob) on a record variable whose Blob buffer is stale because
// another variable changed the same row and called Modify().

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
        Error(Obs);
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
        Error(Obs);
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
        Error(Obs);
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
        Error(Obs);
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
        Error(Obs);
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
