// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 77460..77473 (XNV InExt Line, XNV OutExt Line, XNV OutSub Line,
//   XNV InSub Line, XNV InSubRd Line, XNV Same Line, XNV Other Line, XNV Two Line, XNV Proc Line, XNV InExt Ext, XNV OutExt Ext,
//   XNV Cfg, XNV Subscribers, XNV Tests)
// local object: the field triggers, table extension triggers, event subscribers and table procedures that read or assign xRec are
//   what is under test; each shape has a table of its own so its code is the only code that runs between the two Validates.
// Probe (al-runner issue 9331, follow-up of XRecTableProcThroughSubscriber.al): which xRec each code point sees when a field
//   OnValidate validates another field of the same record, beyond the two-procedure cell pinned there. Every cell inserts the row
//   as 0/OLD/I1 (Mode ordinal/Series/"Item No."), sets Series := 'NEW' and runs Validate("Item No.", 'I2'). The outer trigger
//   ("Item No.") logs 'I', sets Series := 'MID', nests Validate(Mode, Production) and logs 'I after'; the inner trigger (Mode) logs
//   'T'. A log entry is 'tag x=<xRec> r=<Rec>'. Tags: 'EB'/'EA' table extension OnBeforeValidate/OnAfterValidate, 'SB'/'SA'
//   OnBeforeValidateEvent/OnAfterValidateEvent subscriber, 'G' the third level (Grade), 'O' the other record variable,
//   'I1'/'I2' the outer and the nested run of the same field.
// Cells:
//   - a table extension OnAfterValidate of the inner field reading, then assigning xRec (HOOK);
//   - table extension OnBeforeValidate and OnAfterValidate of the outer field: reading, OnBeforeValidate assigning (HOOK), and
//     OnAfterValidate after the inner trigger assigned xRec (INN);
//   - OnBeforeValidateEvent and OnAfterValidateEvent subscribers of the outer field: the same three;
//   - an OnAfterValidateEvent subscriber of the inner field reading, then assigning (SUB), the outer trigger reading after;
//   - an OnBeforeValidateEvent subscriber of the inner field reading, after the outer trigger assigned Rec.Series and xRec (OUT),
//     and assigning (SUB) before the inner trigger reads;
//   - the same field nested ("Item No." validates "Item No."): plain, outer assigns, inner assigns;
//   - Validate on another record variable of the same table in the outer trigger: a copy of Rec, a Get, a fresh Init; with the
//     outer trigger assigning xRec before the copy and the inner trigger assigning xRec;
//   - two-level nesting "Item No." -> Mode -> Grade: plain, outer, middle and innermost trigger assigning xRec;
//   - zero, one and three table procedures between the triggers with the writers of issue 9331: outer assigns, inner assigns,
//     inner xRec.SetRange, inner xRec.MarkedOnly(true), inner calls a [TryFunction] table procedure that assigns xRec then raises
//     (also with two procedures); the outer trigger's own xRec.SetRange / MarkedOnly(true) without nesting;
//   - the outer Validate run from a [TryFunction] and from a MessageHandler of the test codeunit (two procedures between).
// Facts (measured on 27.5, 28.5 and 29.0, the same on all three):
//   - on the same record variable the nested Validates share ONE xRec: the inner trigger sees the outer Validate's before-image
//     (0/NEW/I1, not the record at the inner call 1/MID/I2), at every depth (two levels, the same field nested) and with zero to
//     three procedures between; whatever any code point assigns to it is what every later reader sees: the table extension
//     triggers and the validate event subscribers of either field, the outer, middle and inner triggers, a [TryFunction] table
//     procedure whose error is caught (0/TRY/I1 stays), also when the outer Validate runs from a test TryFunction or a handler;
//   - the outer field's OnBeforeValidate extension trigger and OnBeforeValidateEvent subscriber run before the outer trigger and
//     their assignment reaches both triggers; the outer field's OnAfterValidate extension trigger and OnAfterValidateEvent
//     subscriber run after the outer trigger and see what the inner trigger assigned (0/INN/I1);
//   - Validate on another record variable gets that variable's own xRec, the variable as it is at its Validate call (copy:
//     0/MID/I2, Get: 0/OLD/I1, fresh: 0/FRE/); its trigger's assignment does not reach the outer xRec, and what the outer trigger
//     assigned before the copy does not reach it;
//   - xRec.SetRange and xRec.MarkedOnly(true) in a trigger show on Rec and on the caller's record too (GetFilters 'Series: F',
//     MarkedOnly Yes), nested or not: xRec's filters and marked-only state are Rec's.
// BC versions: 27.5, 28.5, 29.0

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
    procedure Validate_InnerExtAfterValidateReads_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;EA x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerExtAfterValidateAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;EA x=0/NEW/I1 r=1/MID/I2;I after x=0/HOOK/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterExtTriggersRead_OneXRec()
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
        Observer.Expect('log', 'EB x=0/NEW/I1 r=0/NEW/I2;I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;EA x=0/NEW/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterExtBeforeValidateAssigns_OneXRec()
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
        Observer.Expect('log', 'EB x=0/NEW/I1 r=0/NEW/I2;I x=0/HOOK/I1 r=0/NEW/I2;T x=0/HOOK/I1 r=1/MID/I2;I after x=0/HOOK/I1 r=1/MID/I2;EA x=0/HOOK/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterExtAfterValidateInnerAssigned_OneXRec()
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
        Observer.Expect('log', 'EB x=0/NEW/I1 r=0/NEW/I2;I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;EA x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterSubscribersRead_OneXRec()
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
        Observer.Expect('log', 'SB x=0/NEW/I1 r=0/NEW/I2;I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;SA x=0/NEW/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterBeforeSubscriberAssigns_OneXRec()
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
        Observer.Expect('log', 'SB x=0/NEW/I1 r=0/NEW/I2;I x=0/SUB/I1 r=0/NEW/I2;T x=0/SUB/I1 r=1/MID/I2;I after x=0/SUB/I1 r=1/MID/I2;SA x=0/SUB/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterAfterSubscriberInnerAssigned_OneXRec()
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
        Observer.Expect('log', 'SB x=0/NEW/I1 r=0/NEW/I2;I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;SA x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerAfterSubscriberReads_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;SA x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerAfterSubscriberAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;SA x=0/NEW/I1 r=1/MID/I2;I after x=0/SUB/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberReads_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;SB x=0/NEW/I1 r=1/MID/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberOuterAssigned_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;SB x=0/OUT/I1 r=1/MID/I2;T x=0/OUT/I1 r=1/MID/I2;I after x=0/OUT/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_InnerBeforeSubscriberAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;SB x=0/NEW/I1 r=1/MID/I2;T x=0/SUB/I1 r=1/MID/I2;I after x=0/SUB/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_SameFieldNested_OneXRec()
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
        Observer.Expect('log', 'I1 x=0/NEW/I1 r=0/NEW/I2;I2 x=0/NEW/I1 r=0/MID/I3;I2 after x=0/NEW/I1 r=0/MID/I3;I1 after x=0/NEW/I1 r=0/MID/I3;');
        Observer.Expect('record', '0/MID/I3');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_SameFieldNestedOuterAssigns_OneXRec()
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
        Observer.Expect('log', 'I1 x=0/NEW/I1 r=0/NEW/I2;I2 x=0/OUT/I1 r=0/MID/I3;I2 after x=0/OUT/I1 r=0/MID/I3;I1 after x=0/OUT/I1 r=0/MID/I3;');
        Observer.Expect('record', '0/MID/I3');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_SameFieldNestedInnerAssigns_OneXRec()
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
        Observer.Expect('log', 'I1 x=0/NEW/I1 r=0/NEW/I2;I2 x=0/NEW/I1 r=0/MID/I3;I2 after x=0/INN/I1 r=0/MID/I3;I1 after x=0/INN/I1 r=0/MID/I3;');
        Observer.Expect('record', '0/MID/I3');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarCopy_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/MID/I2 r=1/MID/I2;I after x=0/NEW/I1 r=0/MID/I2;O x=- r=1/MID/I2;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarGet_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OLD/I1 r=1/OLD/I1;I after x=0/NEW/I1 r=0/MID/I2;O x=- r=1/OLD/I1;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarFresh_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/FRE/ r=1/FRE/;I after x=0/NEW/I1 r=0/MID/I2;O x=- r=1/FRE/;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarCopyOuterAssigns_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/MID/I2 r=1/MID/I2;I after x=0/OUT/I1 r=0/MID/I2;O x=- r=1/MID/I2;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarCopyInnerAssigns_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/MID/I2 r=1/MID/I2;I after x=0/NEW/I1 r=0/MID/I2;O x=- r=1/MID/I2;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OtherVarGetInnerAssigns_OwnXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OLD/I1 r=1/OLD/I1;I after x=0/NEW/I1 r=0/MID/I2;O x=- r=1/OLD/I1;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TwoLevel_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1/0 r=0/NEW/I2/0;T x=0/NEW/I1/0 r=1/MID/I2/0;G x=0/NEW/I1/0 r=1/MD2/I2/1;T after x=0/NEW/I1/0 r=1/MD2/I2/1;I after x=0/NEW/I1/0 r=1/MD2/I2/1;');
        Observer.Expect('record', '1/MD2/I2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TwoLevelOuterAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1/0 r=0/NEW/I2/0;T x=0/OUT/I1/0 r=1/MID/I2/0;G x=0/OUT/I1/0 r=1/MD2/I2/1;T after x=0/OUT/I1/0 r=1/MD2/I2/1;I after x=0/OUT/I1/0 r=1/MD2/I2/1;');
        Observer.Expect('record', '1/MD2/I2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TwoLevelMiddleAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1/0 r=0/NEW/I2/0;T x=0/NEW/I1/0 r=1/MID/I2/0;G x=0/MDL/I1/0 r=1/MD2/I2/1;T after x=0/MDL/I1/0 r=1/MD2/I2/1;I after x=0/MDL/I1/0 r=1/MD2/I2/1;');
        Observer.Expect('record', '1/MD2/I2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TwoLevelInnerAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1/0 r=0/NEW/I2/0;T x=0/NEW/I1/0 r=1/MID/I2/0;G x=0/NEW/I1/0 r=1/MD2/I2/1;T after x=0/INN/I1/0 r=1/MD2/I2/1;I after x=0/INN/I1/0 r=1/MD2/I2/1;');
        Observer.Expect('record', '1/MD2/I2/1');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_NoProcOuterAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OUT/I1 r=1/MID/I2;I after x=0/OUT/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_NoProcInnerAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_NoProcInnerFilters_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I filters x=Series: F r=Series: F;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller filters', 'Series: F');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_NoProcInnerMarkedOnly_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I marked x=Yes r=Yes;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller marked', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_NoProcInnerTryAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;caught x=XNV try failed r=-;I after x=0/TRY/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OneProcOuterAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OUT/I1 r=1/MID/I2;I after x=0/OUT/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OneProcInnerAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OneProcInnerFilters_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I filters x=Series: F r=Series: F;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller filters', 'Series: F');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OneProcInnerMarkedOnly_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I marked x=Yes r=Yes;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller marked', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OneProcInnerTryAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;caught x=XNV try failed r=-;I after x=0/TRY/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ThreeProcsOuterAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OUT/I1 r=1/MID/I2;I after x=0/OUT/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerFilters_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I filters x=Series: F r=Series: F;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller filters', 'Series: F');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerMarkedOnly_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/NEW/I1 r=1/MID/I2;I marked x=Yes r=Yes;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Expect('caller marked', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_ThreeProcsInnerTryAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;caught x=XNV try failed r=-;I after x=0/TRY/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterOwnXRecFilter_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;I after x=0/NEW/I1 r=0/MID/I2;I filters x=Series: F r=Series: F;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Expect('caller filters', 'Series: F');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_OuterOwnXRecMarkedOnly_ReachesRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;I after x=0/NEW/I1 r=0/MID/I2;I marked x=Yes r=Yes;');
        Observer.Expect('record', '0/MID/I2');
        Observer.Expect('caller marked', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_TwoProcsInnerTryAssigns_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;caught x=XNV try failed r=-;I after x=0/TRY/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_FromTestTryFunction_OneXRec()
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
        Observer.Expect('try', 'Yes');
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/NEW/I1 r=1/MID/I2;I after x=0/INN/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ValidateItemMessageHandler')]
    procedure Validate_FromMessageHandler_OneXRec()
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
        Observer.Expect('log', 'I x=0/NEW/I1 r=0/NEW/I2;T x=0/OUT/I1 r=1/MID/I2;I after x=0/OUT/I1 r=1/MID/I2;');
        Observer.Expect('record', '1/MID/I2');
        Observer.Verify();
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
