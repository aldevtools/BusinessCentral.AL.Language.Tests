// Cross-app fixtures of the xRec probes of al-runner issues 8986 and 7408 (tests in the AL Language Coverage Tests app:
// table-objects/extensions/xrec-insert-delete/XRecInsDelTests.al and record/events/XRecModifyLoadFieldsDepSub.al).
// - "XA XRE Base Line": the base table of issue 8986. Its own OnInsert stores xRec."Serial No."; a table extension in the
//   dependent app reads xRec in its insert and delete triggers.
// - "XA XRE Load Row" and "XA XRE Get Sub": the table of issue 7408 and a second OnBeforeModifyEvent subscriber in a dependency
//   app. When switched on, it re-reads the var xRec with Get before the subscriber of the dependent app runs.

table 76390 "XA XRE Base Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Serial No."; Integer) { }
        field(3; "xRec Serial In Table OnInsert"; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        "xRec Serial In Table OnInsert" := xRec."Serial No.";
    end;
}

table 76391 "XA XRE Load Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Company No."; Code[20]) { }
        field(3; "Member No."; Code[20]) { }
        field(4; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByCompany; "Company No.", "No.") { }
    }
}

codeunit 76392 "XA XRE Get Sub"
{
    SingleInstance = true;

    var
        Enabled: Boolean;
        Log: Text;

    procedure SetEnabled(NewEnabled: Boolean)
    begin
        Enabled := NewEnabled;
    end;

    procedure HasRun(): Boolean
    begin
        exit(Log <> '');
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"XA XRE Load Row", OnBeforeModifyEvent, '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "XA XRE Load Row"; var xRec: Record "XA XRE Load Row"; RunTrigger: Boolean)
    var
        Found: Boolean;
    begin
        if not Enabled then
            exit;
        Log += 'B before get: xmember=[' + xRec."Member No." + '] xname=[' + xRec.Name + '] xloaded member=' + Format(xRec.AreFieldsLoaded(xRec."Member No.")) +
            ' xfilters=[' + xRec.GetFilters() + ']; ';
        Found := xRec.Get(xRec."No.");
        Log += 'B after get: found=' + Format(Found) + ' xmember=[' + xRec."Member No." + '] xcompany=[' + xRec."Company No." + '] xname=[' + xRec.Name +
            '] xloaded member=' + Format(xRec.AreFieldsLoaded(xRec."Member No.")) + ' xfilters=[' + xRec.GetFilters() + ']; ';
    end;
}
