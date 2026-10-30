// @expect AL0122 | Cannot implicitly convert type 'Interface "MNC UP Preview"' to 'Codeunit "MNC UP Default"'
// A conditional expression with a codeunit true branch and an interface false branch: the interface does not convert to the codeunit (al-runner issue 6215;
// the other order, an interface true branch and an implementing codeunit false branch, compiles).
interface "MNC UP Preview"
{
    procedure GetPreview(): Text;
}

codeunit 50001 "MNC UP Default" implements "MNC UP Preview"
{
    procedure GetPreview(): Text
    begin
        exit('default');
    end;
}

codeunit 50002 "MNC UP Factory"
{
    procedure Get(UseDefault: Boolean; Other: Interface "MNC UP Preview"): Interface "MNC UP Preview"
    var
        Default: Codeunit "MNC UP Default";
    begin
        exit(UseDefault ? Default : Other);
    end;
}
