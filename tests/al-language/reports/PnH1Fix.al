// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: self-contained (tables 70572-70575, helper codeunit 70576); not a test codeunit
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed rows: shared fixtures of the PnH probes (Report, XmlPort).
// BC versions: 29 (27 and 28 by CI)

table 70572 "LT PnH Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; ChildCnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnH Child" where(ParentId = field(Id)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

table 70573 "LT PnH Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Grp; Integer) { }
        field(4; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByParent; ParentId, Id) { }
    }
}

table 70574 "LT PnH XItem"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70575 "LT PnH Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70576 "LT PnH Helper"
{
    procedure Wipe()
    var
        Row: Record "LT PnH Row";
        Child: Record "LT PnH Child";
        XItem: Record "LT PnH XItem";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        XItem.DeleteAll();
    end;

    // Rows 1,2 (Grp 1) and 3 (Grp 2); children 10,11 of 1, 12 of 2, 13 of 3.
    procedure Seed()
    var
        Row: Record "LT PnH Row";
        Child: Record "LT PnH Child";
    begin
        Wipe();
        AddRow(1, 1, 'one');
        AddRow(2, 1, 'two');
        AddRow(3, 2, 'three');
        AddChild(10, 1, 1);
        AddChild(11, 1, 2);
        AddChild(12, 2, 1);
        AddChild(13, 3, 2);
    end;

    local procedure AddRow(Id: Integer; Grp: Integer; Name: Text)
    var
        Row: Record "LT PnH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Grp := Grp;
        Row.Name := CopyStr(Name, 1, MaxStrLen(Row.Name));
        Row.Insert();
    end;

    local procedure AddChild(Id: Integer; ParentId: Integer; Grp: Integer)
    var
        Child: Record "LT PnH Child";
    begin
        Child.Init();
        Child.Id := Id;
        Child.ParentId := ParentId;
        Child.Grp := Grp;
        Child.Name := 'c' + Format(Id);
        Child.Insert();
    end;
}
