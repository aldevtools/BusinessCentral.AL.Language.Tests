/// <summary>
/// Publisher codeunit firing an IntegrationEvent whose argument is an Option.
/// Mirrors the RS pattern where a codeunit-published event carries an option
/// value that subscribers receive as an Option-typed parameter.
/// </summary>
codeunit 60213 "Opt Publisher CEO"
{
    procedure Fire(Choice: Option First,Second,Third)
    begin
        OnDoChoice(Choice);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoChoice(Choice: Option First,Second,Third)
    begin
    end;
}
