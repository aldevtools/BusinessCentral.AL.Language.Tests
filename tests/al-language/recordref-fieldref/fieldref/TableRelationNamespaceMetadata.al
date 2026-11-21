// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope. Validate of fields whose TableRelation names an own table of another namespace (imported by using, and fully qualified) and the system table Table Metadata, on a database and a temporary record: an existing value, a missing value, a blank value.
// Fixtures used: Probe Observer (codeunit 69160); own objects 77808-77810 (FC Rel Group in FcRelTarget.al, FC Rel Holder, TableRelation Namespace Metadata)
// Probe: from al-runner issues 8191 (relation target imported by using) and 8181 (TableRelation to Table Metadata). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

namespace ALLanguage.Coverage.FcRelHolder;

using ALLanguage.Coverage.FcRelTarget;
using System.Reflection;

table 77809 "FC Rel Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Group; Code[20])
        {
            TableRelation = "FC Rel Group";
        }
        field(3; "Group Full"; Code[20])
        {
            TableRelation = ALLanguage.Coverage.FcRelTarget."FC Rel Group";
        }
        field(4; "Table ID"; Integer)
        {
            TableRelation = "Table Metadata".ID;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 77810 "TableRelation Namespace Meta"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValidate(var Holder: Record "FC Rel Holder"; FieldNo: Integer; Value: Text)
    var
        TableId: Integer;
    begin
        case FieldNo of
            2:
                Holder.Validate(Group, Value);
            3:
                Holder.Validate("Group Full", Value);
            4:
                begin
                    Evaluate(TableId, Value);
                    Holder.Validate("Table ID", TableId);
                end;
        end;
    end;

    local procedure Probe(var Holder: Record "FC Rel Holder"; FieldNo: Integer; Value: Text): Text
    begin
        Holder.Init();
        Holder."No." := 1;
        if TryValidate(Holder, FieldNo, Value) then
            exit('ok');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure SeedGroups()
    var
        Group: Record "FC Rel Group";
    begin
        Group.DeleteAll();
        Group."Code" := 'G1';
        Group.Insert();
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; var Holder: Record "FC Rel Holder")
    begin
        Observer.Observe('usingExisting', Probe(Holder, 2, 'G1'));
        Observer.Observe('usingMissing', Probe(Holder, 2, 'NOPE'));
        Observer.Observe('usingBlank', Probe(Holder, 2, ''));
        Observer.Observe('fullExisting', Probe(Holder, 3, 'G1'));
        Observer.Observe('fullMissing', Probe(Holder, 3, 'NOPE'));
        Observer.Observe('metaOwnTable', Probe(Holder, 4, Format(Database::"FC Rel Holder")));
        Observer.Observe('metaPlatformTable', Probe(Holder, 4, '2000000001'));
        Observer.Observe('metaMissing', Probe(Holder, 4, '1999999999'));
        Observer.Observe('metaZero', Probe(Holder, 4, '0'));
        Observer.Observe('metaCodeunitIdOnly', Probe(Holder, 4, Format(Codeunit::"TableRelation Namespace Meta")));
    end;

    [Test]
    procedure Validate_Database_NamespaceAndMetadata()
    var
        Holder: Record "FC Rel Holder";
        Observer: Codeunit "Probe Observer";
    begin
        SeedGroups();
        Holder.DeleteAll();
        ObserveAll(Observer, Holder);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Temporary_NamespaceAndMetadata()
    var
        Holder: Record "FC Rel Holder" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        SeedGroups();
        ObserveAll(Observer, Holder);
        Observer.Finish();
    end;

    [Test]
    procedure Relation_FieldRef_Targets()
    var
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"FC Rel Holder");
        Observer.Observe('usingRelation', Format(RecRef.Field(2).Relation() = Database::"FC Rel Group"));
        Observer.Observe('fullRelation', Format(RecRef.Field(3).Relation() = Database::"FC Rel Group"));
        Observer.Observe('metaRelation', Format(RecRef.Field(4).Relation() = Database::"Table Metadata"));
        Observer.Finish();
    end;
}
