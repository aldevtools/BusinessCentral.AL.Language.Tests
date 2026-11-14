// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 66993
// Probe: measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43643688944); the values are the same on all three.
// Facts: InStream.ResetPosition on an InStream that was never created, OutStream.Write(Integer) on an OutStream that was never created,
//   CopyStream with both streams never created (as a statement and as a value), and Media and MediaSet ImportStream from an InStream that
//   was never created. Every cell has its own test. Neighbors of StreamUncreatedUse.al. Repros of aldevtools/BusinessCentral.AL.Runner#7760
//   and its comments.
// Result: ResetPosition and the statement form of CopyStream fail with NavInStream variable not initialized.; the value forms of OutStream.Write and
//   CopyStream return 0 and No without an error; Media and MediaSet ImportStream return an empty Guid without an error.
// BC versions: 27.5, 28.5, 29.0

table 66993 "LT UH Pic"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Icon; Media) { }
        field(3; Icons; MediaSet) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 66994 "LT UH Untouched Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try(Step: Text; var Result: Text)
    var
        Pic: Record "LT UH Pic";
        InS: InStream;
        OutS: OutStream;
        N: Integer;
    begin
        case Step of
            'inreset':
                begin
                    InS.ResetPosition();
                    Result := 'done';
                end;
            'outwrite':
                Result := Format(OutS.Write(5));
            'copy_stmt':
                begin
                    CopyStream(OutS, InS);
                    Result := 'done';
                end;
            'copy_value':
                Result := Format(CopyStream(OutS, InS));
            'media_import':
                begin
                    Pic.Code := 'A';
                    Result := Format(Pic.Icon.ImportStream(InS, 'icon'));
                end;
            'media_import2':
                begin
                    Pic.Code := 'A';
                    Result := Format(Pic.Icon.ImportStream(InS, 'icon', 'image/png'));
                end;
            'mediaset_import':
                begin
                    Pic.Code := 'A';
                    Result := Format(Pic.Icons.ImportStream(InS, 'icon'));
                end;
        end;
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Step: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if Try(Step, Result) then
            Observer.Observe('result', 'ok:' + Result)
        else
            Observer.Observe('result', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Untouched_InStream_ResetPosition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'inreset');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_OutStream_WriteInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'outwrite');
        Observer.Expect('result', 'ok:0');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_CopyStream_BothUntouched_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'copy_stmt');
        Observer.Expect('result', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_CopyStream_BothUntouched_Value()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'copy_value');
        Observer.Expect('result', 'ok:No');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_InStream_Media_ImportStream()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_import');
        Observer.Expect('result', 'ok:{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_InStream_MediaSet_ImportStream()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'mediaset_import');
        Observer.Expect('result', 'ok:{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

    [Test]
    procedure Untouched_InStream_Media_ImportStream_NoName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'media_import2');
        Observer.Expect('result', 'ok:{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
