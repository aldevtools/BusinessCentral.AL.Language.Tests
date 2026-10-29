// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
// Scope: in-scope
// Fixtures used: own tables 90020, 90021, xmlports 90022, 90023, runner codeunit 90024 (writer TP); the temporary blob table 87279
//   (QrXpContainerOccurs.al); tests TP_* in codeunit 87280 (QrXpContainerOccurs.al)
// Probe: observed on a BC 29.0 service tier; every literal asserted in the TP_* tests is what that tier produced. Other versions: corpus CI matrix.
// Facts (BC 29): 90022 export writes `<entry no=".." status=".." kind="..">` with `<admission option_value="1">A1</admission>` inside; the
//   log per row is `get R1;pass entry;pass status;pass admission;pass admcode;` (the element's OnBeforePassVariable before its attribute's).
//   An empty optional attribute (kind) is left out, an empty required one is written as `status=""`; an empty element text gives
//   `<admission option_value="2" />`. Import per row: init, the field attribute, status, then `admission=A1 admcode=1` (the attribute is
//   assigned before the element's OnAfterAssignVariable), then entry's OnAfterAssignVariable (its text is the element's own text), then
//   OnBeforeInsertRecord. A missing element or required attribute fails the schema check (XmlPortInvalidXml).
//   90023 export: the unlinked inner table element writes ALL its records under EVERY outer row; with no records it writes `<attributes />`.
//   Import: the inner records are inserted (OnBeforeInsertRecord sees the outer row's field attribute) before the outer row's
//   OnBeforeInsertRecord; they stay in the temporary table across rows. An absent or empty `attributes` element inserts nothing; a
//   second one, or one after `status`, fails the schema check; a duplicate inner key fails with DB:RecordExists.
// Objects:
//   90022: table element > text element `entry` (a field attribute, a text attribute with triggers, a text attribute without triggers)
//     > text element `admission` whose only child is one required text attribute. The inner element and
//     its attribute have OnBeforePassVariable (set from the row), the element also OnAfterAssignVariable; every trigger logs (log = order).
//   90023: table element > text element `attributes` (MinOccurs = Zero, MaxOccurs = Once) > temporary table element `attribute` with no
//     LinkTable (field attributes, OnBeforeInsertRecord sets the parent key from the outer row). Every trigger logs.
// BC versions: 27, 28, 29

table 90020 "LT TP XP Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Status; Text[30]) { }
        field(3; Kind; Text[30]) { }
        field(4; Adm; Text[30]) { }
        field(5; AdmCode; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 90021 "LT TP XP Attr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Parent; Code[10]) { }
        field(2; "Code"; Code[20]) { }
        field(3; Value; Text[30]) { }
    }

    keys
    {
        key(PK; Parent, "Code") { Clustered = true; }
    }
}

xmlport 90022 "LT TP XP Nested Text"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            tableelement(row; "LT TP XP Entry")
            {
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                textelement(entry)
                {
                    fieldattribute(no; row."No.")
                    {
                        trigger OnAfterAssignField()
                        begin
                            Log += 'no=' + row."No." + ';';
                        end;
                    }
                    textattribute(status)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass status;';
                            status := row.Status;
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'status=' + status + ';';
                        end;
                    }
                    textattribute(kind)
                    {
                        Occurrence = Optional;
                    }
                    textelement(admission)
                    {
                        textattribute(admcode)
                        {
                            XmlName = 'option_value';
                            Occurrence = Required;

                            trigger OnBeforePassVariable()
                            begin
                                Log += 'pass admcode;';
                                admcode := row.AdmCode;
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log += 'pass admission;';
                            admission := row.Adm;
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            Log += 'admission=' + admission + ' admcode=' + admcode + ';';
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log += 'pass entry;';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        Log += 'entry=' + entry + ' kind=' + kind + ';';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ' + row."No." + ';';
                    kind := row.Kind;
                end;

                trigger OnAfterInitRecord()
                begin
                    Log += 'init;';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + row."No." + ';';
                    row.Status := status;
                    row.Kind := kind;
                    row.Adm := admission;
                    row.AdmCode := admcode;
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after insert;';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(No: Code[10]; NewStatus: Text[30]; NewKind: Text[30]; NewAdm: Text[30]; NewAdmCode: Text[30])
    begin
        row.Init();
        row."No." := No;
        row.Status := NewStatus;
        row.Kind := NewKind;
        row.Adm := NewAdm;
        row.AdmCode := NewAdmCode;
        row.Insert();
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Status + '/' + row.Kind + '/' + row.Adm + '/' + row.AdmCode + ';';
            until row.Next() = 0;
    end;

    procedure Values(): Text
    begin
        exit('entry=' + entry + ' status=' + status + ' kind=' + kind + ' admission=' + admission + ' admcode=' + admcode);
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 90023 "LT TP XP Unlinked Temp"
{
    Direction = Both;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(root)
        {
            tableelement(row; "LT TP XP Entry")
            {
                UseTemporary = true;
                MinOccurs = Zero;
                MaxOccurs = Unbounded;
                fieldattribute(no; row."No.")
                {
                    trigger OnAfterAssignField()
                    begin
                        Log += 'no=' + row."No." + ';';
                    end;
                }
                textelement(attributes)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                    tableelement(attr; "LT TP XP Attr")
                    {
                        MinOccurs = Zero;
                        XmlName = 'attribute';
                        UseTemporary = true;
                        fieldattribute(code; attr."Code") { }
                        fieldattribute(value; attr.Value) { }

                        trigger OnAfterGetRecord()
                        begin
                            Log += 'get attr ' + attr.Parent + '/' + attr."Code" + ';';
                        end;

                        trigger OnAfterInitRecord()
                        begin
                            Log += 'init attr;';
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            Log += 'before insert attr ' + attr."Code" + '=' + attr.Value + ' row=' + row."No." + ';';
                            attr.Parent := row."No.";
                        end;

                        trigger OnAfterInsertRecord()
                        begin
                            Log += 'after insert attr;';
                        end;
                    }
                }
                fieldelement(status; row.Status)
                {
                    MinOccurs = Zero;
                }

                trigger OnAfterGetRecord()
                begin
                    Log += 'get ' + row."No." + ';';
                end;

                trigger OnAfterInitRecord()
                begin
                    Log += 'init;';
                end;

                trigger OnBeforeInsertRecord()
                begin
                    Log += 'before insert ' + row."No." + ' status=' + row.Status + ';';
                end;

                trigger OnAfterInsertRecord()
                begin
                    Log += 'after insert;';
                end;
            }
        }
    }

    var
        Log: Text;

    procedure AddRow(No: Code[10]; NewStatus: Text[30])
    begin
        row.Init();
        row."No." := No;
        row.Status := NewStatus;
        row.Insert();
    end;

    procedure AddAttr(NewParent: Code[10]; NewCode: Code[20]; NewValue: Text[30])
    begin
        attr.Init();
        attr.Parent := NewParent;
        attr."Code" := NewCode;
        attr.Value := NewValue;
        attr.Insert();
    end;

    procedure Rows() Result: Text
    begin
        if row.FindSet() then
            repeat
                Result += row."No." + ':' + row.Status + ';';
            until row.Next() = 0;
        Result += ' attrs=';
        if attr.FindSet() then
            repeat
                Result += attr.Parent + '/' + attr."Code" + '=' + attr.Value + ';';
            until attr.Next() = 0;
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 90024 "LT TP XP Runner"
{
    // Imports Input into xmlport Mode (90022 or 90023) inside Codeunit.Run, so a failed import does not end the test.
    var
        Input: Text;
        Mode: Integer;
        Outcome: Text;

    trigger OnRun()
    var
        Buffer: Record "LT QR XP Blob" temporary;
        Nested: XmlPort "LT TP XP Nested Text";
        Unlinked: XmlPort "LT TP XP Unlinked Temp";
        OutS: OutStream;
        InS: InStream;
    begin
        Buffer.Id := 1;
        Buffer.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Input);
        Buffer.Insert();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        case Mode of
            90022:
                begin
                    Nested.SetSource(InS);
                    Nested.Import();
                    Outcome := 'log=' + Nested.GetLog() + ' values: ' + Nested.Values() + ' rows=' + Nested.Rows();
                end;
            90023:
                begin
                    Unlinked.SetSource(InS);
                    Unlinked.Import();
                    Outcome := 'log=' + Unlinked.GetLog() + ' rows=' + Unlinked.Rows();
                end;
        end;
    end;

    procedure SetInput(NewMode: Integer; NewInput: Text)
    begin
        Mode := NewMode;
        Input := NewInput;
        Outcome := '';
    end;

    procedure Result(): Text
    begin
        exit(Outcome);
    end;
}
