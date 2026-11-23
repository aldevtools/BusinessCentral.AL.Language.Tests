// Fixture for al-runner issue 8696 (cross-app cell): a SingleInstance codeunit of this app, which both al-language and
// cross-app fixture E depend on. XApp E (tests/al-language-xapp-e/SirXeLoginSubs.al) sets its globals in a subscriber of
// "System Initialization".OnAfterLogin. al-language does not depend on XApp E. The state is read by one test codeunit only:
// tests/al-language/codeunits/SirCrossAppLogin.al.
codeunit 61097 "SIR XE Login State"
{
    SingleInstance = true;

    var
        Cnt: Integer;
        Txt: Text;
        Names: List of [Text];
        LoginCalls: Integer;

    procedure SetFromLogin()
    begin
        Cnt := 10;
        Txt += 'L';
        Names.Add('x');
        LoginCalls += 1;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure SetCnt(NewCnt: Integer)
    begin
        Cnt := NewCnt;
    end;

    procedure GetTxt(): Text
    begin
        exit(Txt);
    end;

    procedure SetTxt(NewTxt: Text)
    begin
        Txt := NewTxt;
    end;

    procedure GetNames(): List of [Text]
    begin
        exit(Names);
    end;

    procedure AddName(Name: Text)
    begin
        Names.Add(Name);
    end;

    procedure NameCount(): Integer
    begin
        exit(Names.Count());
    end;

    procedure GetLoginCalls(): Integer
    begin
        exit(LoginCalls);
    end;
}
