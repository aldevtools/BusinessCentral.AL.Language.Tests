// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope. An InStream created over a Temp Blob that was a local of another procedure (the owner is out of scope when the stream is
//   used): HttpContent.WriteFrom, CopyStream into a kept OutStream, Clear, Read, ReadText, Position, ResetPosition, a var parameter, an
//   assignment to another InStream and CopyStream into a Blob field. Controls: the same with a Temp Blob that stays in scope.
// Fixtures used: Probe Observer (69160); "Temp Blob" (System Application); self-contained table 93265 (temporary only), codeunits 93265, 93266
// Probe: gap cycle 6, spec G6-24a (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
//   Already pinned (streams/lt-dc-stream-leads/DcInStreamScope.al): such a stream reads as empty with Length, EOS and ReadText.
// Facts: each value is the result of the call or error:<text>|<code>. Not covered: CopyStream into a DotNet MemoryStream (OnPrem only).
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): the gone stream behaves as an empty stream everywhere: WriteFrom, CopyStream, Read,
//   ReadText, a var parameter, an assignment and CopyStream into a Blob field give nothing and raise nothing; Position is 1, Position(1) raises
//   OutsidePermittedRange (1 to 0); after Clear(InS) any use raises NotInitialized.
// BC versions: 27, 28, 29

table 93265 "LT Y62 GS Blob"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93266 "LT Y62 GS Source"
{
    procedure FilledInStream(Content: Text; var InS: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS);
    end;
}

codeunit 93265 "LT Y62 Gone InStream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Source: Codeunit "LT Y62 GS Source";
        KeptBlob: Codeunit "Temp Blob";
        SinkBlob: Codeunit "Temp Blob";

    local procedure Gone(var InS: InStream)
    begin
        Source.FilledInStream('Dummy test file content', InS);
    end;

    local procedure Kept(var InS: InStream)
    var
        OutS: OutStream;
    begin
        Clear(KeptBlob);
        KeptBlob.CreateOutStream(OutS);
        OutS.WriteText('Dummy test file content');
        KeptBlob.CreateInStream(InS);
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryWriteFrom(var Content: HttpContent; var InS: InStream)
    begin
        Content.WriteFrom(InS);
    end;

    [TryFunction]
    local procedure TryReadAs(var Content: HttpContent; var Txt: Text; var Ok: Boolean)
    begin
        Ok := Content.ReadAs(Txt);
    end;

    [TryFunction]
    local procedure TryLengthEos(var InS: InStream; var Txt: Text)
    begin
        Txt := 'len=' + Format(InS.Length()) + '|eos=' + Format(InS.EOS());
    end;

    local procedure LengthEos(var InS: InStream): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryLengthEos(InS, Txt) then
            exit(Txt);
        exit(Err());
    end;

    local procedure ObserveWriteFrom(var Observer: Codeunit "Probe Observer"; Prefix: Text; var InS: InStream)
    var
        Content: HttpContent;
        H: HttpHeaders;
        Values: List of [Text];
        Txt: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        if TryWriteFrom(Content, InS) then
            Observer.Observe(Prefix + 'writefrom', 'ok')
        else
            Observer.Observe(Prefix + 'writefrom', Err());
        ClearLastError();
        if TryReadAs(Content, Txt, Ok) then
            Observer.Observe(Prefix + 'readas', Format(Ok) + '|len=' + Format(StrLen(Txt)) + '|[' + Txt + ']')
        else
            Observer.Observe(Prefix + 'readas', Err());
        Content.GetHeaders(H);
        if H.GetValues('Content-Length', Values) then
            Observer.Observe(Prefix + 'content-length', Values.Get(1))
        else
            Observer.Observe(Prefix + 'content-length', 'none');
        Observer.Observe(Prefix + 'stream after', LengthEos(InS));
    end;

    [Test]
    procedure GoneStream_HttpContentWriteFrom()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        KeptS: InStream;
    begin
        Gone(InS);
        ObserveWriteFrom(Observer, 'gone ', InS);
        Kept(KeptS);
        ObserveWriteFrom(Observer, 'kept ', KeptS);
        Observer.Expect('gone writefrom', 'ok');
        Observer.Expect('gone readas', 'Yes|len=0|[]');
        Observer.Expect('gone content-length', '0');
        Observer.Expect('gone stream after', 'len=0|eos=Yes');
        Observer.Expect('kept writefrom', 'ok');
        Observer.Expect('kept readas', 'Yes|len=23|[Dummy test file content]');
        Observer.Expect('kept content-length', '23');
        Observer.Expect('kept stream after', 'len=23|eos=No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCopy(var OutS: OutStream; var InS: InStream)
    begin
        CopyStream(OutS, InS);
    end;

    local procedure SinkText(): Text
    var
        InS: InStream;
        Txt: Text;
    begin
        SinkBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        exit('len=' + Format(SinkBlob.Length()) + '|[' + Txt + ']');
    end;

    local procedure ObserveCopy(var Observer: Codeunit "Probe Observer"; Prefix: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Clear(SinkBlob);
        SinkBlob.CreateOutStream(OutS);
        ClearLastError();
        if TryCopy(OutS, InS) then
            Observer.Observe(Prefix + 'copystream', 'ok')
        else
            Observer.Observe(Prefix + 'copystream', Err());
        Observer.Observe(Prefix + 'sink', SinkText());
        Observer.Observe(Prefix + 'stream after', LengthEos(InS));
    end;

    [Test]
    procedure GoneStream_CopyStream_ToOutStream()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        KeptS: InStream;
    begin
        Gone(InS);
        ObserveCopy(Observer, 'gone ', InS);
        Kept(KeptS);
        ObserveCopy(Observer, 'kept ', KeptS);
        Observer.Expect('gone copystream', 'ok');
        Observer.Expect('gone sink', 'len=0|[]');
        Observer.Expect('gone stream after', 'len=0|eos=Yes');
        Observer.Expect('kept copystream', 'ok');
        Observer.Expect('kept sink', 'len=23|[Dummy test file content]');
        Observer.Expect('kept stream after', 'len=23|eos=Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadText(var InS: InStream; var Txt: Text)
    begin
        InS.ReadText(Txt);
    end;

    [Test]
    procedure GoneStream_Clear()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        Txt: Text;
    begin
        Gone(InS);
        Clear(InS);
        Observer.Observe('after clear', LengthEos(InS));
        ClearLastError();
        Txt := 'preset';
        if TryReadText(InS, Txt) then
            Observer.Observe('readtext after clear', '[' + Txt + ']')
        else
            Observer.Observe('readtext after clear', Err());
        Observer.Expect('after clear', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('readtext after clear', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryStep(Step: Integer; var InS: InStream; var Txt: Text)
    var
        T: Text;
        N: Integer;
    begin
        T := 'preset';
        case Step of
            1:
                begin
                    InS.Read(T);
                    Txt := '[' + T + ']';
                end;
            2:
                begin
                    N := InS.Read(T, 5);
                    Txt := Format(N) + '|[' + T + ']';
                end;
            3:
                Txt := Format(InS.Position());
            4:
                begin
                    InS.ResetPosition();
                    Txt := 'ok';
                end;
            5:
                begin
                    N := InS.ReadText(T, 3);
                    Txt := Format(N) + '|[' + T + ']';
                end;
            6:
                begin
                    InS.Position(1);
                    Txt := 'ok|' + Format(InS.Position());
                end;
        end;
    end;

    [Test]
    procedure GoneStream_ReadAndPosition()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        Txt: Text;
        Step: Integer;
    begin
        for Step := 1 to 6 do begin
            Clear(InS);
            Gone(InS);
            ClearLastError();
            Txt := '';
            if TryStep(Step, InS, Txt) then
                Observer.Observe('step' + Format(Step), Txt)
            else
                Observer.Observe('step' + Format(Step), Err());
        end;
        Observer.Expect('step1', '[]');
        Observer.Expect('step2', '0|[]');
        Observer.Expect('step3', '1');
        Observer.Expect('step4', 'ok');
        Observer.Expect('step5', '0|[]');
        Observer.Expect('step6', 'error:The value of Position parameter 1 is outside of the permitted range. The current value is: 1. The permitted range is: from 1 to 0.|OutsidePermittedRange');
        Observer.Verify();
    end;

    local procedure ReadThroughVar(var InS: InStream): Text
    var
        Txt: Text;
    begin
        Txt := 'preset';
        InS.ReadText(Txt);
        exit('len=' + Format(InS.Length()) + '|[' + Txt + ']');
    end;

    [TryFunction]
    local procedure TryVarParam(var InS: InStream; var Txt: Text)
    begin
        Txt := ReadThroughVar(InS);
    end;

    [TryFunction]
    local procedure TryAssign(var InS: InStream; var Txt: Text)
    var
        InS2: InStream;
        T: Text;
    begin
        InS2 := InS;
        T := 'preset';
        InS2.ReadText(T);
        Txt := 'len=' + Format(InS2.Length()) + '|[' + T + ']';
    end;

    [TryFunction]
    local procedure TryIntoBlobField(var InS: InStream; var Txt: Text)
    var
        Rec: Record "LT Y62 GS Blob";
        OutS: OutStream;
        BlobIn: InStream;
        T: Text;
    begin
        Rec.Data.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        Rec.Data.CreateInStream(BlobIn);
        BlobIn.ReadText(T);
        Txt := 'hasvalue=' + Format(Rec.Data.HasValue()) + '|[' + T + ']';
    end;

    [Test]
    procedure GoneStream_PassedOn()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        Txt: Text;
        Step: Integer;
        Ok: Boolean;
    begin
        for Step := 1 to 3 do begin
            Clear(InS);
            Gone(InS);
            ClearLastError();
            Txt := '';
            case Step of
                1:
                    Ok := TryVarParam(InS, Txt);
                2:
                    Ok := TryAssign(InS, Txt);
                3:
                    Ok := TryIntoBlobField(InS, Txt);
            end;
            if not Ok then
                Txt := Err();
            Observer.Observe('step' + Format(Step), Txt);
        end;
        Observer.Expect('step1', 'len=0|[]');
        Observer.Expect('step2', 'len=0|[]');
        Observer.Expect('step3', 'hasvalue=No|[]');
        Observer.Verify();
    end;
}
