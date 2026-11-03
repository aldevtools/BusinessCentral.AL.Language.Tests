// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; helper codeunit 70689 and xmlport 70681 of this file (not test codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: XmlPort | A refused guarded static import (a write is pending) returns false and its last error cannot be read (whether it is set, and to what,
// is not pinned); a successful guarded import commits its own transaction (nothing is pending afterwards); under AutoRollback a guarded import with a pending write
// and a successful one.
// BC versions: 29 (27 and 28 by CI)

xmlport 70681 "LT PnH XpImport"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT PnH XItem")
            {
                fieldelement(Id; Item.Id) { }
                fieldelement(Name; Item.Name) { }
            }
        }
    }
}

codeunit 70689 "LT PnH XpHelper"
{
    // Two items FirstId and FirstId + 1; with Failing the second Id is not a number.
    procedure Open(var BlobRec: Record "LT PnH Blob" temporary; var InStr: InStream; FirstId: Integer; Failing: Boolean)
    var
        OutStr: OutStream;
        SecondId: Text;
    begin
        BlobRec.Reset();
        BlobRec.DeleteAll();
        BlobRec.Init();
        BlobRec.Id := 1;
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
        SecondId := Format(FirstId + 1);
        if Failing then
            SecondId := 'abc';
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?><Root>' +
            '<Item><Id>' + Format(FirstId) + '</Id><Name>first</Name></Item>' +
            '<Item><Id>' + SecondId + '</Id><Name>second</Name></Item></Root>');
        BlobRec.Data.CreateInStream(InStr);
    end;

    procedure Pending(RowId: Integer)
    var
        XItem: Record "LT PnH XItem";
    begin
        XItem.Init();
        XItem.Id := RowId;
        XItem.Name := 'pending';
        XItem.Insert();
    end;

    procedure CountFrom(FromId: Integer; ToId: Integer): Integer
    var
        XItem: Record "LT PnH XItem";
    begin
        XItem.SetRange(Id, FromId, ToId);
        exit(XItem.Count());
    end;

    procedure PendingExists(RowId: Integer): Boolean
    var
        XItem: Record "LT PnH XItem";
    begin
        exit(XItem.Get(RowId));
    end;

    [TryFunction]
    procedure FailOnPurpose()
    begin
        Error('prior error');
    end;
}

codeunit 70690 "LT PnH XpGuard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT PnH XpHelper";
        Cleaner: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Cleaner.Wipe();
        Commit();
        ClearLastError();
    end;

    [Test]
    procedure Static_Guarded_PendingWrite_ReturnsFalse_LastError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Helper.Pending(1);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('result', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Observe('pending row survives', Format(Helper.PendingExists(1)));
        Observer.Expect('result', 'No');
        Observer.Expect('last error|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('last error|code', 'DB:Ok');
        Observer.Expect('imported', '0');
        Observer.Expect('pending row survives', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_PendingWrite_KeepsOrReplacesAnEarlierError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Helper.Pending(1);
        Observer.Observe('try', Format(Helper.FailOnPurpose()));
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('result', Format(Ok));
        Observer.ObserveError('last error after refused import');
        Observer.Expect('try', 'No');
        Observer.Expect('result', 'No');
        Observer.Expect('last error after refused import|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('last error after refused import|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_Success_KeepsOrClearsAnEarlierError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Observer.Observe('try', Format(Helper.FailOnPurpose()));
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('result', Format(Ok));
        Observer.ObserveError('last error after successful import');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Expect('try', 'No');
        Observer.Expect('result', 'Yes');
        Observer.Expect('last error after successful import|text', 'prior error');
        Observer.Expect('last error after successful import|code', 'Dialog');
        Observer.Expect('imported', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_Refused_ThenCommit_ThenRetry()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Helper.Pending(1);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('first', Format(Ok));
        Commit();
        Helper.Open(BlobRec, InStr, 101, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('retry', Format(Ok));
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Observe('pending row', Format(Helper.PendingExists(1)));
        Observer.Expect('first', 'No');
        Observer.Expect('retry', 'Yes');
        Observer.Expect('imported', '2');
        Observer.Expect('pending row', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_Success_LeavesNothingPending()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        asserterror Error('after the import');
        Observer.ObserveError('after');
        Observer.Observe('imported after the error', Format(Helper.CountFrom(101, 102)));
        Observer.Expect('result', 'Yes');
        Observer.Expect('imported', '2');
        Observer.Expect('after|text', 'after the import');
        Observer.Expect('after|code', 'Dialog');
        Observer.Expect('imported after the error', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_Success_ThenCallerWrite_ThenError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Helper.Pending(1);
        asserterror Error('after the write');
        Observer.ObserveError('after write');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Observe('caller write', Format(Helper.PendingExists(1)));
        Observer.Expect('after write|text', 'after the write');
        Observer.Expect('after write|code', 'Dialog');
        Observer.Expect('imported', '2');
        Observer.Expect('caller write', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Instance_Guarded_PendingWrite_Raises_LastError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        Xp: XmlPort "LT PnH XpImport";
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Helper.Pending(1);
        Xp.SetSource(InStr);
        asserterror Ok := Xp.Import();
        Observer.ObserveError('instance');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Expect('instance|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('instance|code', 'DB:Ok');
        Observer.Expect('imported', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_FailingPayload_LastError_AndRows()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Pending(1);
        Commit();
        Helper.Open(BlobRec, InStr, 101, true);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('result', Format(Ok));
        Observer.ObserveError('failing payload');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Observe('committed row', Format(Helper.PendingExists(1)));
        Observer.Expect('result', 'No');
        Observer.Expect('failing payload|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('failing payload|code', 'Evaluate');
        Observer.Expect('imported', '0');
        Observer.Expect('committed row', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Guarded_TwoSuccessfulImports_ThenPending()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('first', Format(Ok));
        Helper.Open(BlobRec, InStr, 201, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('second', Format(Ok));
        Helper.Pending(1);
        Helper.Open(BlobRec, InStr, 301, false);
        Ok := XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.Observe('third with pending', Format(Ok));
        Observer.ObserveError('third');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)) + '|' + Format(Helper.CountFrom(201, 202)) + '|' + Format(Helper.CountFrom(301, 302)));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'Yes');
        Observer.Expect('third with pending', 'No');
        Observer.Expect('third|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('third|code', 'DB:Ok');
        Observer.Expect('imported', '2|2|0');
        Observer.Verify();
    end;

    [Test]
    procedure Static_Statement_PendingWrite_LastError()
    var
        Observer: Codeunit "Probe Observer";
        BlobRec: Record "LT PnH Blob" temporary;
        InStr: InStream;
    begin
        Start();
        Helper.Open(BlobRec, InStr, 101, false);
        Helper.Pending(1);
        XmlPort.Import(XmlPort::"LT PnH XpImport", InStr);
        Observer.ObserveError('statement form');
        Observer.Observe('imported', Format(Helper.CountFrom(101, 102)));
        Observer.Expect('statement form|text', '');
        Observer.Expect('statement form|code', '');
        Observer.Expect('imported', '2');
        Observer.Verify();
    end;
}
