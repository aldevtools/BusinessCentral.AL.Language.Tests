// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 file basics
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61263 "LT P110 File Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp');
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    [TryFunction]
    local procedure TName(var F: File; var N: Text)
    begin
        N := F.Name();
    end;

    [TryFunction]
    local procedure TClose(var F: File)
    begin
        F.Close();
    end;

    [Test]
    procedure P110_CreateCloseExists()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        Observer.Observe('exists_before', Format(File.Exists(P)));
        Observer.Observe('create', Format(F.Create(P)));
        Observer.Observe('exists_open', Format(File.Exists(P)));
        Observer.Observe('len_new', Format(F.Len()));
        Observer.Observe('pos_new', Format(F.Pos()));
        Observer.Observe('name_is_path', Format(F.Name() = P));
        F.Close();
        Observer.Observe('exists_closed', Format(File.Exists(P)));
        Observer.Observe('erase', Format(File.Erase(P)));
        Observer.Observe('exists_erased', Format(File.Exists(P)));
        Observer.Observe('erase_again', Format(File.Erase(P)));
        Cleanup(P);
        Observer.Expect('exists_before', 'No');
        Observer.Expect('create', 'Yes');
        Observer.Expect('exists_open', 'Yes');
        Observer.Expect('len_new', '0');
        Observer.Expect('pos_new', '0');
        Observer.Expect('name_is_path', 'No');
        Observer.Expect('exists_closed', 'Yes');
        Observer.Expect('erase', 'Yes');
        Observer.Expect('exists_erased', 'No');
        Observer.Expect('erase_again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P110_OpenExisting()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.Write('abc');
        F.Close();
        Observer.Observe('open', Format(F.Open(P)));
        Observer.Observe('len', Format(F.Len()));
        Observer.Observe('pos', Format(F.Pos()));
        Observer.Observe('name_is_path', Format(F.Name() = P));
        F.Close();
        Observer.Observe('open_again', Format(F.Open(P)));
        F.Close();
        Cleanup(P);
        Observer.Expect('open', 'Yes');
        Observer.Expect('len', '4');
        Observer.Expect('pos', '0');
        Observer.Expect('name_is_path', 'No');
        Observer.Expect('open_again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateOverwrites()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.Write('first content');
        F.Close();
        F.Open(P);
        Observer.Observe('len_before', Format(F.Len()));
        F.Close();
        Observer.Observe('create_again', Format(F.Create(P)));
        Observer.Observe('len_after_create', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('len_before', '14');
        Observer.Expect('create_again', 'Yes');
        Observer.Expect('len_after_create', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CloseTwiceAndName()
    var
        F: File;
        N: Text;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.Close();
        if TClose(F) then
            Observer.Observe('close_twice', 'ok')
        else
            Observer.Observe('close_twice', 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        if TName(F, N) then
            Observer.Observe('name_after_close', Format(N = P))
        else
            Observer.Observe('name_after_close', 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        Cleanup(P);
        Observer.Expect('close_twice', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('name_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P110_Closed_File_Never_Opened()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
    begin
        asserterror F.Close();
        Observer.ObserveError('close_unopened');
        asserterror Observer.Observe('name_unopened', F.Name());
        Observer.ObserveError('name_unopened');
        asserterror Observer.Observe('len_unopened', Format(F.Len()));
        Observer.ObserveError('len_unopened');
        asserterror Observer.Observe('pos_unopened', Format(F.Pos()));
        Observer.ObserveError('pos_unopened');
        Observer.Expect('close_unopened|text', 'The file is not open.');
        Observer.Expect('close_unopened|code', 'FileNotOpened');
        Observer.Expect('name_unopened|text', 'The file is not open.');
        Observer.Expect('name_unopened|code', 'FileNotOpened');
        Observer.Expect('len_unopened|text', 'The file is not open.');
        Observer.Expect('len_unopened|code', 'FileNotOpened');
        Observer.Expect('pos_unopened|text', 'The file is not open.');
        Observer.Expect('pos_unopened|code', 'FileNotOpened');
        Observer.Verify();
    end;
}
