namespace ALLanguage.IsolationProbe;

// Runs in the background session "LT SD Isol StartSession" (61318) starts: inserts the row SESSION.
codeunit 61319 "LT SD Isol Session Writer"
{
    trigger OnRun()
    var
        Row: Record "LT SD Isol Row";
    begin
        Row."Key" := 'SESSION';
        if Row.Insert() then;
    end;
}
