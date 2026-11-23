// Cross-app fixture B (al-runner issue 8696, login without a dependency): a SingleInstance codeunit whose own subscriber of
// an integration event of the AL Internals Test Fixture changes its globals. XApp E's OnAfterLogin subscriber
// (tests/al-language-xapp-e/SirNdLoginSubs.al) raises the event; XApp E does not depend on this app. The globals are read by
// one test codeunit only: tests/al-language/codeunits/SirLoginNoDep.al.
codeunit 98501 "SIR ND XB Event State"
{
    SingleInstance = true;

    var
        Cnt: Integer;
        Txt: Text;
        Names: List of [Text];
        Calls: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SIR ND Login Events", 'OnLoginRaised', '', false, false)]
    local procedure OnLoginRaised()
    begin
        Cnt := 10;
        Txt += 'E';
        Names.Add('e');
        Calls += 1;
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

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;
}
