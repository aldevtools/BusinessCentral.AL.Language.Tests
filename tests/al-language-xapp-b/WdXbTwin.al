// Page extension of cross-app fixture B (writer WD) for al-runner issue 6294. See al-language-xapp-a/WdXaTwin.al.

pageextension 61148 "LT WD XB Apply Ext" extends "LT WD XA Apply"
{
    // Same names and parameter types as the base page's public and protected procedures, but internal.
    internal procedure CheckRounding()
    var
        Log: Codeunit "LT WD XA Log";
    begin
        Log.Add('ext internal public-twin');
    end;

    internal procedure CheckProtected()
    var
        Log: Codeunit "LT WD XA Log";
    begin
        Log.Add('ext internal protected-twin');
    end;

    procedure CallFromExt()
    begin
        CheckRounding();
        CheckProtected();
    end;
}
