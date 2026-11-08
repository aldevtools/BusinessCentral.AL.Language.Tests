// @expect AL0118 | The name 'XbCounter' does not exist in the current context
// @depends AL Language XApp A,Base Application,System Application
// Cross-app (al-runner issue 6983): cross-app fixture B's extension 95524 of fixture A's table "TBL ProtVar XA Table" declares the
// protected variable XbCounter. An app that depends on fixture A but not on fixture B extends the same table and names it. An app that
// depends on B reads and writes it: tests/al-language/table-objects/extensions/ProtectedVarCrossApp.al.
tableextension 52952 "MNC ProtVar No Dep 2952" extends "TBL ProtVar XA Table"
{
    procedure ReadCounter(): Integer
    begin
        exit(XbCounter);
    end;
}
