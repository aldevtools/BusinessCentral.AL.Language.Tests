// Observe probe (writer Y39, temporary): dumps every row of Windows Language.
codeunit 92700 "LT Y39 WinLang Observe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RowText(var WindowsLanguage: Record "Windows Language"): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        I: Integer;
        Result: Text;
    begin
        RecRef.GetTable(WindowsLanguage);
        for I := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(I);
            if I > 1 then
                Result += '|';
            Result += Format(FldRef.Value());
        end;
        exit(Result);
    end;

    local procedure Chunk(FromIndex: Integer; ToIndex: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
        Index: Integer;
        Result: Text;
    begin
        WindowsLanguage.SetCurrentKey("Language ID");
        if WindowsLanguage.FindSet() then
            repeat
                Index += 1;
                if (Index >= FromIndex) and (Index <= ToIndex) then
                    Result += RowText(WindowsLanguage) + '~';
            until WindowsLanguage.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Y39Obs_Fields()
    var
        WindowsLanguage: Record "Windows Language";
        RecRef: RecordRef;
        FldRef: FieldRef;
        I: Integer;
        Result: Text;
    begin
        RecRef.GetTable(WindowsLanguage);
        Result := Format(RecRef.FieldCount()) + '#' + Format(WindowsLanguage.Count()) + '#';
        for I := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(I);
            Result += Format(FldRef.Number()) + ':' + FldRef.Name() + ':' + Format(FldRef.Type()) + ':' + Format(FldRef.Length()) + ':' + Format(FldRef.Class()) + '|';
        end;
        Result += '#' + RecRef.KeyIndex(1).ToString();
        Error('Y39OBS:%1', Result);
    end;

    [Test]
    procedure Y39Obs_Chunk01()
    begin
        Error('Y39OBS:%1', Chunk(1, 20));
    end;

    [Test]
    procedure Y39Obs_Chunk02()
    begin
        Error('Y39OBS:%1', Chunk(21, 40));
    end;

    [Test]
    procedure Y39Obs_Chunk03()
    begin
        Error('Y39OBS:%1', Chunk(41, 60));
    end;

    [Test]
    procedure Y39Obs_Chunk04()
    begin
        Error('Y39OBS:%1', Chunk(61, 80));
    end;

    [Test]
    procedure Y39Obs_Chunk05()
    begin
        Error('Y39OBS:%1', Chunk(81, 100));
    end;

    [Test]
    procedure Y39Obs_Chunk06()
    begin
        Error('Y39OBS:%1', Chunk(101, 120));
    end;

    [Test]
    procedure Y39Obs_Chunk07()
    begin
        Error('Y39OBS:%1', Chunk(121, 140));
    end;

    [Test]
    procedure Y39Obs_Chunk08()
    begin
        Error('Y39OBS:%1', Chunk(141, 160));
    end;

    [Test]
    procedure Y39Obs_Chunk09()
    begin
        Error('Y39OBS:%1', Chunk(161, 180));
    end;

    [Test]
    procedure Y39Obs_Chunk10()
    begin
        Error('Y39OBS:%1', Chunk(181, 200));
    end;

    [Test]
    procedure Y39Obs_Chunk11()
    begin
        Error('Y39OBS:%1', Chunk(201, 220));
    end;
}
