// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Blob (table 60008)
// Probe: measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43072734044); the values are the same on all three.
// Facts: what the methods of an InStream and an OutStream that were never created do (EOS, Length, Position, ReadText, Read,
//   CopyStream from it, WriteText, Write, CopyStream into it): a value or an error (text and code). And InStream.Read of a Text with
//   a BigInteger length against the same read with an Integer length. Repros of aldevtools/BusinessCentral.AL.Runner#7760 (item 4)
//   and #7775 (Part A, item 8).
// BC versions: 27.5, 28.5, 29.0

codeunit 77130 "STR Uncreated Use Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryIn(var InS: InStream; Step: Text; var Result: Text)
    var
        Row: Record "ALT Blob";
        OutS: OutStream;
        T: Text;
        I: Integer;
    begin
        case Step of
            'eos':
                Result := Format(InS.EOS());
            'length':
                Result := Format(InS.Length());
            'position':
                Result := Format(InS.Position());
            'readtext':
                begin
                    I := InS.ReadText(T);
                    Result := Format(I) + '|[' + T + ']';
                end;
            'read':
                begin
                    I := InS.Read(T);
                    Result := Format(I) + '|[' + T + ']';
                end;
            'copystream':
                begin
                    Row.Data.CreateOutStream(OutS);
                    Result := Format(CopyStream(OutS, InS));
                end;
        end;
    end;

    [TryFunction]
    local procedure TryOut(var OutS: OutStream; Step: Text; var Result: Text)
    var
        Row: Record "ALT Blob";
        InS: InStream;
        OutS2: OutStream;
    begin
        case Step of
            'writetext':
                Result := Format(OutS.WriteText('x'));
            'write':
                Result := Format(OutS.Write(5));
            'copystream':
                begin
                    Row.Data.CreateOutStream(OutS2);
                    OutS2.WriteText('abc');
                    Row.Data.CreateInStream(InS);
                    Result := Format(CopyStream(OutS, InS));
                end;
        end;
    end;

    local procedure ObserveIn(var Observer: Codeunit "Probe Observer"; Step: Text)
    var
        InS: InStream;
        Result: Text;
    begin
        ClearLastError();
        if TryIn(InS, Step, Result) then
            Observer.Observe('in_' + Step, 'ok:' + Result)
        else
            Observer.Observe('in_' + Step, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveOut(var Observer: Codeunit "Probe Observer"; Step: Text)
    var
        OutS: OutStream;
        Result: Text;
    begin
        ClearLastError();
        if TryOut(OutS, Step, Result) then
            Observer.Observe('out_' + Step, 'ok:' + Result)
        else
            Observer.Observe('out_' + Step, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure UncreatedInStream_EveryMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveIn(Observer, 'eos');
        ObserveIn(Observer, 'length');
        ObserveIn(Observer, 'position');
        ObserveIn(Observer, 'readtext');
        ObserveIn(Observer, 'read');
        ObserveIn(Observer, 'copystream');
        Observer.Expect('in_eos', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('in_length', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('in_position', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('in_readtext', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('in_read', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('in_copystream', 'ok:No');
        Observer.Verify();
    end;

    [Test]
    procedure UncreatedOutStream_EveryMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOut(Observer, 'writetext');
        ObserveOut(Observer, 'write');
        ObserveOut(Observer, 'copystream');
        Observer.Expect('out_writetext', 'ok:0');
        Observer.Expect('out_write', 'ok:0');
        Observer.Expect('out_copystream', 'ok:No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadWithLength(Big: Boolean; Len: BigInteger; var Result: Text)
    var
        Row: Record "ALT Blob";
        OutS: OutStream;
        InS: InStream;
        T: Text;
        N: Integer;
        IntLen: Integer;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('abcdef');
        Row.Data.CreateInStream(InS);
        if Big then
            N := InS.Read(T, Len)
        else begin
            IntLen := Len;
            N := InS.Read(T, IntLen);
        end;
        Result := Format(N) + '|[' + T + ']|eos=' + Format(InS.EOS());
    end;

    local procedure ReadWithLength(var Observer: Codeunit "Probe Observer"; Name: Text; Big: Boolean; Len: BigInteger)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryReadWithLength(Big, Len, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure InStreamRead_TextWithBigIntegerLength()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadWithLength(Observer, 'big3', true, 3);
        ReadWithLength(Observer, 'int3', false, 3);
        ReadWithLength(Observer, 'big0', true, 0);
        ReadWithLength(Observer, 'int0', false, 0);
        ReadWithLength(Observer, 'big10', true, 10);
        ReadWithLength(Observer, 'int10', false, 10);
        Observer.Expect('big3', 'ok:3|[abc]|eos=No');
        Observer.Expect('int3', 'ok:3|[abc]|eos=No');
        Observer.Expect('big0', 'ok:0|[]|eos=No');
        Observer.Expect('int0', 'ok:0|[]|eos=No');
        Observer.Expect('big10', 'ok:6|[abcdef]|eos=Yes');
        Observer.Expect('int10', 'ok:6|[abcdef]|eos=Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryStatement(Step: Text)
    var
        Row: Record "ALT Blob";
        UncreatedIn: InStream;
        UncreatedOut: OutStream;
        InS: InStream;
        OutS: OutStream;
    begin
        case Step of
            'copy_from_uncreated':
                begin
                    Row.Data.CreateOutStream(OutS);
                    CopyStream(OutS, UncreatedIn);
                end;
            'copy_into_uncreated':
                begin
                    Row.Data.CreateOutStream(OutS);
                    OutS.WriteText('abc');
                    Row.Data.CreateInStream(InS);
                    CopyStream(UncreatedOut, InS);
                end;
            'writetext':
                UncreatedOut.WriteText('x');
            'write':
                UncreatedOut.Write(5);
        end;
    end;

    local procedure ObserveStatement(var Observer: Codeunit "Probe Observer"; Step: Text)
    begin
        ClearLastError();
        if TryStatement(Step) then
            Observer.Observe(Step, 'no error')
        else
            Observer.Observe(Step, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure UncreatedStreams_StatementForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStatement(Observer, 'copy_from_uncreated');
        ObserveStatement(Observer, 'copy_into_uncreated');
        ObserveStatement(Observer, 'writetext');
        ObserveStatement(Observer, 'write');
        Observer.Finish();
    end;
}
