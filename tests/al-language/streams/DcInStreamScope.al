// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 74200 "LT StT Rec" (temporary only), self-contained codeunit 85782
// Probe: corpus issue 671 item 60 (microsoft/AL issues 1201, 7172, 7329, 7575, 7990): an InStream returned or passed back from a procedure whose
//   local Temp Blob, local temporary record with a Blob field or local temporary Tenant Media record goes out of scope.
// Facts: the stream reads as empty (Length 0, EOS true, no error) once its owner is out of scope; a stream of a Temp Blob that stays in scope reads the text.
// BC versions: 27, 28, 29

codeunit 85782 "LT DC InStream Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        KeptBlob: Codeunit "Temp Blob";

    local procedure FromTempBlob(Content: Text) Result: InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(Result);
    end;

    local procedure InScope(Content: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS);
        exit(ReadAll(InS));
    end;

    local procedure FromKeptBlob(Content: Text) Result: InStream
    var
        OutS: OutStream;
    begin
        KeptBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        KeptBlob.CreateInStream(Result);
    end;

    local procedure FromTempBlobVar(Content: Text; var InS: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS);
    end;

    local procedure FromTempRecord(Content: Text) Result: InStream
    var
        TempRec: Record "LT StT Rec" temporary;
        OutS: OutStream;
    begin
        TempRec.Id := 1;
        TempRec.Data.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempRec.Insert();
        TempRec.Data.CreateInStream(Result);
    end;

    local procedure FromTenantMedia(Content: Text) Result: InStream
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        OutS: OutStream;
    begin
        TempTenantMedia.Content.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempTenantMedia.Content.CreateInStream(Result);
    end;

    local procedure ReadAll(var InS: InStream): Text
    var
        Txt: Text;
    begin
        InS.ReadText(Txt);
        exit(Txt);
    end;

    [Test]
    procedure Item60_InStreamFromLocalTempBlob()
    var
        InS: InStream;
        InS2: InStream;
    begin
        Observer.Observe('control_in_scope', InScope('hello in scope'));
        InS := FromKeptBlob('hello kept blob');
        Observer.Observe('kept_blob_text', ReadAll(InS));
        InS := FromTempBlob('hello temp blob');
        Observer.Observe('return_length', Format(InS.Length()));
        Observer.Observe('return_text', ReadAll(InS));
        Observer.Observe('return_eos', Format(InS.EOS()));
        FromTempBlobVar('hello var', InS2);
        Observer.Observe('var_text', ReadAll(InS2));
        InS := FromTempBlob('first');
        InS2 := FromTempBlob('second');
        Observer.Observe('two_first', ReadAll(InS));
        Observer.Observe('two_second', ReadAll(InS2));
        Observer.Expect('control_in_scope', 'hello in scope');
        Observer.Expect('kept_blob_text', 'hello kept blob');
        Observer.Expect('return_length', '0');
        Observer.Expect('return_text', '');
        Observer.Expect('return_eos', 'Yes');
        Observer.Expect('var_text', '');
        Observer.Expect('two_first', '');
        Observer.Expect('two_second', '');
        Observer.Verify();
    end;

    [Test]
    procedure Item60_InStreamFromLocalTempRecord()
    var
        InS: InStream;
    begin
        InS := FromTempRecord('hello record');
        Observer.Observe('record_text', ReadAll(InS));
        InS := FromTenantMedia('hello media');
        Observer.Observe('media_text', ReadAll(InS));
        Observer.Expect('record_text', '');
        Observer.Expect('media_text', '');
        Observer.Verify();
    end;

    // al-runner issue 5688: a var InStream filled by a procedure of another codeunit (named CreateInstream, as Http Web Request Mgt. has) that creates it on its
    // own local Temp Blob, reached through a local codeunit variable of a procedure of this codeunit (two levels) and directly; empty and with text.
    local procedure ViaLocalSource(Content: Text; var InS: InStream)
    var
        Source: Codeunit "LT RH Stream Source";
    begin
        if Content = '' then
            Source.CreateInstream(InS)
        else
            Source.FilledInstream(Content, InS);
    end;

    [Test]
    procedure RH_VarInStreamFromOtherCodeunitLocalTempBlob()
    var
        Source: Codeunit "LT RH Stream Source";
        InS: InStream;
        InS2: InStream;
        InS3: InStream;
        InS4: InStream;
    begin
        ViaLocalSource('', InS);
        Observer.Observe('two levels empty', Format(InS.Length()) + '|' + Format(InS.EOS()) + '|' + ReadAll(InS) + '|' + Format(InS.EOS()));
        ViaLocalSource('hello two levels', InS2);
        Observer.Observe('two levels text', Format(InS2.Length()) + '|' + Format(InS2.EOS()) + '|' + ReadAll(InS2) + '|' + Format(InS2.EOS()));
        Source.CreateInstream(InS3);
        Observer.Observe('direct empty', Format(InS3.Length()) + '|' + Format(InS3.EOS()) + '|' + ReadAll(InS3) + '|' + Format(InS3.EOS()));
        Source.FilledInstream('hello direct', InS4);
        Observer.Observe('direct text', Format(InS4.Length()) + '|' + Format(InS4.EOS()) + '|' + ReadAll(InS4) + '|' + Format(InS4.EOS()));
        Observer.Expect('two levels empty', '0|Yes||Yes');
        Observer.Expect('two levels text', '0|Yes||Yes');
        Observer.Expect('direct empty', '0|Yes||Yes');
        Observer.Expect('direct text', '0|Yes||Yes');
        Observer.Verify();
    end;
}

// al-runner issue 5688: the stream source of RH_VarInStreamFromOtherCodeunitLocalTempBlob (object id 88002). Not a test codeunit.
codeunit 88002 "LT RH Stream Source"
{
    procedure CreateInstream(var InStr: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateInStream(InStr);
    end;

    procedure FilledInstream(Content: Text; var InStr: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InStr);
    end;
}
