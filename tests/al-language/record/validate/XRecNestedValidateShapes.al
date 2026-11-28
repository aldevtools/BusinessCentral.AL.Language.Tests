// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Facts: OBSERVE
// BC versions: OBSERVE

table 77460 "XNV InExt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                CopyFromItem();
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;
}

tableextension 77469 "XNV InExt Ext" extends "XNV InExt Line"
{
    fields
    {
        modify(Mode)
        {
            trigger OnAfterValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('EA', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get() = 'ext-assign' then
                    xRec.Series := 'HOOK';
            end;
        }
    }
}

table 77461 "XNV OutExt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get() = 'inner-assign' then
                    xRec.Series := 'INN';
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                CopyFromItem();
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;
}

tableextension 77470 "XNV OutExt Ext" extends "XNV OutExt Line"
{
    fields
    {
        modify("Item No.")
        {
            trigger OnBeforeValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('EB', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get() = 'ext-assign' then
                    xRec.Series := 'HOOK';
            end;

            trigger OnAfterValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('EA', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }
}

table 77462 "XNV OutSub Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get() = 'inner-assign' then
                    xRec.Series := 'INN';
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                CopyFromItem();
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;
}

table 77463 "XNV InSub Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                CopyFromItem();
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;
}

table 77464 "XNV InSubRd Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                CopyFromItem();
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;
}

table 77465 "XNV Same Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
                D: Integer;
            begin
                if Cfg.Get() = '' then
                    exit;
                D := Cfg.Enter();
                Cfg.Add('I' + Format(D), Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if D = 1 then begin
                    Series := 'MID';
                    if Cfg.Get() = 'outer-assign' then
                        xRec.Series := 'OUT';
                    Validate("Item No.", 'I3');
                end else
                    if Cfg.Get() = 'inner-assign' then
                        xRec.Series := 'INN';
                Cfg.Add('I' + Format(D) + ' after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Cfg.Leave();
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

table 77466 "XNV Other Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get().EndsWith('inner-assign') then
                    xRec.Series := 'INN';
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
                Other: Record "XNV Other Line";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get().EndsWith('outer-assign') then
                    xRec.Series := 'OUT';
                if Cfg.Get().StartsWith('copy') then
                    Other := Rec;
                if Cfg.Get().StartsWith('get') then
                    Other.Get("Line No.");
                if Cfg.Get() = 'fresh' then begin
                    Other.Init();
                    Other."Line No." := 2;
                    Other.Series := 'FRE';
                end;
                Other.Validate(Mode, Other.Mode::Production);
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Cfg.Add('O', '-', Format(Other.Mode, 0, 2) + '/' + Other.Series + '/' + Other."Item No.");
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

table 77467 "XNV Two Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No." + '/' + Format(xRec.Grade, 0, 2), Format(Mode, 0, 2) + '/' + Series + '/' + "Item No." + '/' + Format(Grade, 0, 2));
                Series := 'MD2';
                if Cfg.Get() = 'mid-assign' then
                    xRec.Series := 'MDL';
                Validate(Grade, Grade::High);
                Cfg.Add('T after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No." + '/' + Format(xRec.Grade, 0, 2), Format(Mode, 0, 2) + '/' + Series + '/' + "Item No." + '/' + Format(Grade, 0, 2));
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No." + '/' + Format(xRec.Grade, 0, 2), Format(Mode, 0, 2) + '/' + Series + '/' + "Item No." + '/' + Format(Grade, 0, 2));
                Series := 'MID';
                if Cfg.Get() = 'outer-assign' then
                    xRec.Series := 'OUT';
                Validate(Mode, Mode::Production);
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No." + '/' + Format(xRec.Grade, 0, 2), Format(Mode, 0, 2) + '/' + Series + '/' + "Item No." + '/' + Format(Grade, 0, 2));
            end;
        }
        field(5; Grade; Option)
        {
            OptionMembers = Low,High;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('G', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No." + '/' + Format(xRec.Grade, 0, 2), Format(Mode, 0, 2) + '/' + Series + '/' + "Item No." + '/' + Format(Grade, 0, 2));
                if Cfg.Get() = 'inner-assign' then
                    xRec.Series := 'INN';
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

table 77468 "XNV Proc Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Mode; Option)
        {
            OptionMembers = Purchase,Production;

            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('T', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get().EndsWith('inner-assign') then
                    xRec.Series := 'INN';
                if Cfg.Get().EndsWith('filter') then
                    xRec.SetRange(Series, 'F');
                if Cfg.Get().EndsWith('marked') then
                    xRec.MarkedOnly(true);
                if Cfg.Get().EndsWith('try') then begin
                    if not TryAssignXRec() then
                        Cfg.Add('caught', GetLastErrorText(), '-');
                    ClearLastError();
                end;
            end;
        }
        field(3; Series; Code[20]) { }
        field(4; "Item No."; Code[20])
        {
            trigger OnValidate()
            var
                Cfg: Codeunit "XNV Cfg";
            begin
                if Cfg.Get() = '' then
                    exit;
                Cfg.Add('I', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                Series := 'MID';
                if Cfg.Get().EndsWith('outer-assign') then
                    xRec.Series := 'OUT';
                if Cfg.Get() = 'self-filter' then
                    xRec.SetRange(Series, 'F');
                if Cfg.Get() = 'self-marked' then
                    xRec.MarkedOnly(true);
                case true of
                    Cfg.Get().StartsWith('direct'):
                        Validate(Mode, Mode::Production);
                    Cfg.Get().StartsWith('one'):
                        UpdateMode();
                    Cfg.Get().StartsWith('two'):
                        CopyFromItem();
                    Cfg.Get().StartsWith('three'):
                        StepOne();
                end;
                Cfg.Add('I after', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Mode, 0, 2) + '/' + Series + '/' + "Item No.");
                if Cfg.Get().EndsWith('filter') then
                    Cfg.Add('I filters', xRec.GetFilters(), GetFilters());
                if Cfg.Get().EndsWith('marked') then
                    Cfg.Add('I marked', Format(xRec.MarkedOnly()), Format(MarkedOnly()));
            end;
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }

    local procedure CopyFromItem()
    begin
        UpdateMode();
    end;

    local procedure UpdateMode()
    begin
        Validate(Mode, Mode::Production);
    end;

    local procedure StepOne()
    begin
        StepTwo();
    end;

    local procedure StepTwo()
    begin
        UpdateMode();
    end;

    [TryFunction]
    local procedure TryAssignXRec()
    begin
        xRec.Series := 'TRY';
        Error('XNV try failed');
    end;
}

codeunit 77471 "XNV Cfg"
{
    SingleInstance = true;

    var
        CfgMode: Text;
        Log: Text;
        Depth: Integer;

    procedure Set(NewMode: Text)
    begin
        CfgMode := NewMode;
        Log := '';
        Depth := 0;
    end;

    procedure Get(): Text
    begin
        exit(CfgMode);
    end;

    procedure Add(Tag: Text; XRecText: Text; RecText: Text)
    begin
        Log += Tag + ' x=' + XRecText + ' r=' + RecText + ';';
    end;

    procedure Enter(): Integer
    begin
        Depth += 1;
        exit(Depth);
    end;

    procedure Leave()
    begin
        Depth -= 1;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 77472 "XNV Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"XNV OutSub Line", 'OnBeforeValidateEvent', 'Item No.', false, false)]
    local procedure OutSubBeforeItem(var Rec: Record "XNV OutSub Line"; var xRec: Record "XNV OutSub Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XNV Cfg";
    begin
        if Cfg.Get() = '' then
            exit;
        Cfg.Add('SB', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Rec.Mode, 0, 2) + '/' + Rec.Series + '/' + Rec."Item No.");
        if Cfg.Get() = 'sub-assign' then
            xRec.Series := 'SUB';
    end;

    [EventSubscriber(ObjectType::Table, Database::"XNV OutSub Line", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure OutSubAfterItem(var Rec: Record "XNV OutSub Line"; var xRec: Record "XNV OutSub Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XNV Cfg";
    begin
        if Cfg.Get() = '' then
            exit;
        Cfg.Add('SA', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Rec.Mode, 0, 2) + '/' + Rec.Series + '/' + Rec."Item No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"XNV InSub Line", 'OnAfterValidateEvent', 'Mode', false, false)]
    local procedure InSubAfterMode(var Rec: Record "XNV InSub Line"; var xRec: Record "XNV InSub Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XNV Cfg";
    begin
        if Cfg.Get() = '' then
            exit;
        Cfg.Add('SA', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Rec.Mode, 0, 2) + '/' + Rec.Series + '/' + Rec."Item No.");
        if Cfg.Get() = 'sub-assign' then
            xRec.Series := 'SUB';
    end;

    [EventSubscriber(ObjectType::Table, Database::"XNV InSubRd Line", 'OnBeforeValidateEvent', 'Mode', false, false)]
    local procedure InSubRdBeforeMode(var Rec: Record "XNV InSubRd Line"; var xRec: Record "XNV InSubRd Line"; CurrFieldNo: Integer)
    var
        Cfg: Codeunit "XNV Cfg";
    begin
        if Cfg.Get() = '' then
            exit;
        Cfg.Add('SB', Format(xRec.Mode, 0, 2) + '/' + xRec.Series + '/' + xRec."Item No.", Format(Rec.Mode, 0, 2) + '/' + Rec.Series + '/' + Rec."Item No.");
        if Cfg.Get() = 'sub-assign' then
            xRec.Series := 'SUB';
    end;
}

codeunit 77473 "XNV Tests"
{
    Subtype = Test;

    var
        Cfg: Codeunit "XNV Cfg";
        HandlerLine: Record "XNV Proc Line";

    [Test]
    procedure Validate_InnerExtAfterValidateReads_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InExt Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('read');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerExtAfterValidateAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InExt Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('ext-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterExtTriggersRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutExt Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('read');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterExtBeforeValidateAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutExt Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('ext-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterExtAfterValidateInnerAssigned_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutExt Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterSubscribersRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutSub Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('read');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterBeforeSubscriberAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutSub Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('sub-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterAfterSubscriberInnerAssigned_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV OutSub Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerAfterSubscriberReads_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InSub Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('read');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerAfterSubscriberAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InSub Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('sub-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberReads_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InSubRd Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('read');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberOuterAssigned_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InSubRd Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV InSubRd Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('sub-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_SameFieldNested_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Same Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('plain');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_SameFieldNestedOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Same Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_SameFieldNestedInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Same Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarCopy_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('copy');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarGet_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('get');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarFresh_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('fresh');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarCopyOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('copy-outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarCopyInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('copy-inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OtherVarGetInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Other Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('get-inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_TwoLevel_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Two Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('plain');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No." + '/' + Format(Line.Grade, 0, 2));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_TwoLevelOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Two Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No." + '/' + Format(Line.Grade, 0, 2));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_TwoLevelMiddleAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Two Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('mid-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No." + '/' + Format(Line.Grade, 0, 2));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_TwoLevelInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Two Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No." + '/' + Format(Line.Grade, 0, 2));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoProcOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('direct-outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoProcInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('direct-inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoProcInnerFilters_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('direct-filter');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller filters', Line.GetFilters());
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoProcInnerMarkedOnly_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('direct-marked');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller marked', Format(Line.MarkedOnly()));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoProcInnerTryAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('direct-try');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OneProcOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('one-outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OneProcInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('one-inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OneProcInnerFilters_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('one-filter');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller filters', Line.GetFilters());
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OneProcInnerMarkedOnly_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('one-marked');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller marked', Format(Line.MarkedOnly()));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OneProcInnerTryAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('one-try');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_ThreeProcsOuterAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('three-outer-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('three-inner-assign');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerFilters_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('three-filter');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller filters', Line.GetFilters());
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerMarkedOnly_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('three-marked');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller marked', Format(Line.MarkedOnly()));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerTryAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('three-try');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterOwnXRecFilter_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('self-filter');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller filters', Line.GetFilters());
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_OuterOwnXRecMarkedOnly_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('self-marked');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Observer.Observe('caller marked', Format(Line.MarkedOnly()));
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_TwoProcsInnerTryAssigns_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('two-try');
        Line.Validate("Item No.", 'I2');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_FromTestTryFunction_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('two-inner-assign');
        Observer.Observe('try', Format(TryValidateItem(Line)));
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ValidateItemMessageHandler')]
    procedure Validate_FromMessageHandler_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "XNV Proc Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."Line No." := 1;
        Line.Mode := Line.Mode::Purchase;
        Line.Series := 'OLD';
        Line."Item No." := 'I1';
        Line.Insert(false);
        Line.Series := 'NEW';
        Cfg.Set('two-outer-assign');
        HandlerLine := Line;
        Message('XNV validate');
        Line := HandlerLine;
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('record', Format(Line.Mode, 0, 2) + '/' + Line.Series + '/' + Line."Item No.");
        Cfg.Set('');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryValidateItem(var Line: Record "XNV Proc Line")
    begin
        Line.Validate("Item No.", 'I2');
    end;

    [MessageHandler]
    procedure ValidateItemMessageHandler(Msg: Text[1024])
    begin
        HandlerLine.Validate("Item No.", 'I2');
    end;
}
