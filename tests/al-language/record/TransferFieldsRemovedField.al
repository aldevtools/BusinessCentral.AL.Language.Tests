// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects tables 79860-79870, table extensions 79871-79872, codeunit 79880
// Probe: written against Business Central 27.5, 28.5 and 29.0 (Windows containers, W1); the values were identical on the three builds.
// Facts: Record.TransferFields where a field is declared ObsoleteState = Removed (no AL code can name such a field, so only the other fields
//   and the call result are observed). Source and target tables of one app, and table extension fields of one app.
//   - A removed TARGET field never raises and never blocks the other fields: no type check against the source field, whatever the types
//     (Boolean source into a removed Code[5], Text into a removed Integer), no length check (a 10 character Code value into a removed Code[5]).
//     The primary key is copied with default arguments and kept with InitPrimaryKeyFields false; live fields are copied.
//     The same holds with SkipFieldsNotMatchingType true, with two removed target fields, and for table extension fields.
//   - A removed SOURCE field is not copied: a live target field of the same number keeps its value, for another type (Boolean into Integer)
//     and for the same type (Integer into Integer), with default arguments and with SkipFieldsNotMatchingType true. A removed field on both
//     sides raises nothing.
//   - Control: a live Boolean source field into a live Code[5] target field raises DB:TypeMisMatch with default arguments (the other
//     fields before it are not copied: Keep stays 3) and is skipped with SkipFieldsNotMatchingType true (the target field stays blank).
// Not measured: removed fields of two different apps (cross-app), RecordRef.Copy and FieldRef based transfers.
// BC versions: 27, 28, 29 (identical)

table 79860 "TFR Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Boolean) { }
        field(3; F3; Code[20]) { }
        field(4; F4; Text[30]) { }
        field(5; F5; Integer) { }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79861 "TFR T BoolToCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Code[5]) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79862 "TFR T SameType"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(5; F5; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79863 "TFR T IntFromText"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(4; F4; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79864 "TFR T LongCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(3; F3; Code[5]) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79865 "TFR S Removed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Boolean) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(5; F5; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79866 "TFR T LiveInt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Integer) { }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79867 "TFR T LiveSame"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(5; F5; Integer) { }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79868 "TFR T LiveCode"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Code[5]) { }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79869 "TFR T TwoRemoved"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F2; Code[5]) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(4; F4; Integer) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 79870 "TFR T Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }

        field(9; Keep; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 79871 "TFR Src Ext" extends "TFR Src"
{
    fields
    {
        field(79890; ExtBool; Boolean) { }
    }
}

tableextension 79872 "TFR T Plain Ext" extends "TFR T Plain"
{
    fields
    {
        field(79890; ExtCode; Code[5]) { ObsoleteState = Removed; ObsoleteReason = 'Probe: removed field'; ObsoleteTag = '1.0'; }
    }
}

codeunit 79880 "TFR TransferFields Removed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryBoolToCode(var Src: Record "TFR Src"; var Tgt: Record "TFR T BoolToCode"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TrySameType(var Src: Record "TFR Src"; var Tgt: Record "TFR T SameType"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryIntFromText(var Src: Record "TFR Src"; var Tgt: Record "TFR T IntFromText"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryLongCode(var Src: Record "TFR Src"; var Tgt: Record "TFR T LongCode"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryTwoRemoved(var Src: Record "TFR Src"; var Tgt: Record "TFR T TwoRemoved"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryBoth(var Src: Record "TFR S Removed"; var Tgt: Record "TFR T BoolToCode"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryLiveInt(var Src: Record "TFR S Removed"; var Tgt: Record "TFR T LiveInt"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryLiveSame(var Src: Record "TFR S Removed"; var Tgt: Record "TFR T LiveSame"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryLiveCode(var Src: Record "TFR Src"; var Tgt: Record "TFR T LiveCode"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    [TryFunction]
    local procedure TryPlain(var Src: Record "TFR Src"; var Tgt: Record "TFR T Plain"; Mode: Integer)
    begin
        case Mode of
            0:
                Tgt.TransferFields(Src);
            1:
                Tgt.TransferFields(Src, true);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
            4:
                Tgt.TransferFields(Src, false, true);
        end;
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe('result', 'no error')
        else
            Observer.ObserveError('result');
    end;

    local procedure SeedSrc(var Src: Record "TFR Src")
    begin
        Src."No." := 'A';
        Src.F2 := true;
        Src.F3 := 'ABC';
        Src.F4 := 'abc';
        Src.F5 := 7;
        Src.Keep := 5;
    end;

    local procedure SeedRemovedSrc(var Src: Record "TFR S Removed")
    begin
        Src."No." := 'A';
        Src.Keep := 5;
    end;

    // the reporter shape: a live Boolean source field, a removed Code[5] target field, default arguments.
    [Test]
    procedure TransferFields_RemovedTarget_BoolToCode_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoolToCode(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // same shape, InitPrimaryKeyFields false.
    [Test]
    procedure TransferFields_RemovedTarget_BoolToCode_InitPkFalse()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoolToCode(Src, Tgt, 2));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'T');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // same shape, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedTarget_BoolToCode_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoolToCode(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // same shape, InitPrimaryKeyFields false and SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedTarget_BoolToCode_InitPkFalseSkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoolToCode(Src, Tgt, 4));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'T');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Integer target field, live Integer source field.
    [Test]
    procedure TransferFields_RemovedTarget_SameType_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T SameType";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TrySameType(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Integer target field, live Integer source field, InitPrimaryKeyFields false.
    [Test]
    procedure TransferFields_RemovedTarget_SameType_InitPkFalse()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T SameType";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TrySameType(Src, Tgt, 2));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'T');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Integer target field, live Text source field.
    [Test]
    procedure TransferFields_RemovedTarget_IntFromText_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T IntFromText";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryIntFromText(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Integer target field, live Text source field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedTarget_IntFromText_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T IntFromText";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryIntFromText(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Code[5] target field, live Code[20] source value that fits (ABC).
    [Test]
    procedure TransferFields_RemovedTarget_CodeFits_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T LongCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryLongCode(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Code[5] target field, live Code[20] source value of 10 characters.
    [Test]
    procedure TransferFields_RemovedTarget_CodeTooLong_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T LongCode";
    begin
        SeedSrc(Src);
        Src.F3 := 'ABCDEFGHIJ';
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryLongCode(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Code[5] target field, 10 character value, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedTarget_CodeTooLong_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T LongCode";
    begin
        SeedSrc(Src);
        Src.F3 := 'ABCDEFGHIJ';
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryLongCode(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // two removed target fields (Code[5] from Boolean, Integer from Text).
    [Test]
    procedure TransferFields_RemovedTarget_TwoRemoved_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T TwoRemoved";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryTwoRemoved(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Boolean source field into a removed Code[5] target field, default arguments.
    [Test]
    procedure TransferFields_RemovedBoth_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoth(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Boolean source field into a removed Code[5] target field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedBoth_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T BoolToCode";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryBoth(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // removed Boolean source field into a live Integer target field, default arguments.
    [Test]
    procedure TransferFields_RemovedSource_LiveInt_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T LiveInt";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Tgt.F2 := 7;
        Report(Observer, TryLiveInt(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f2', Format(Tgt.F2));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Expect('f2', '7');
        Observer.Verify();
    end;

    // removed Boolean source field into a live Integer target field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedSource_LiveInt_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T LiveInt";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Tgt.F2 := 7;
        Report(Observer, TryLiveInt(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f2', Format(Tgt.F2));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Expect('f2', '7');
        Observer.Verify();
    end;

    // removed Boolean source field into a live Integer target field, InitPrimaryKeyFields false and SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedSource_LiveInt_InitPkFalseSkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T LiveInt";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Tgt.F2 := 7;
        Report(Observer, TryLiveInt(Src, Tgt, 4));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f2', Format(Tgt.F2));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'T');
        Observer.Expect('keep', '5');
        Observer.Expect('f2', '7');
        Observer.Verify();
    end;

    // removed Integer source field into a live Integer target field, default arguments.
    [Test]
    procedure TransferFields_RemovedSource_SameType_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T LiveSame";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Tgt.F5 := 7;
        Report(Observer, TryLiveSame(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f5', Format(Tgt.F5));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Expect('f5', '7');
        Observer.Verify();
    end;

    // removed Integer source field into a live Integer target field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_RemovedSource_SameType_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR S Removed";
        Tgt: Record "TFR T LiveSame";
    begin
        SeedRemovedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Tgt.F5 := 7;
        Report(Observer, TryLiveSame(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f5', Format(Tgt.F5));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Expect('f5', '7');
        Observer.Verify();
    end;

    // control: live Boolean source field, live Code[5] target field, default arguments.
    [Test]
    procedure TransferFields_LiveControl_BoolToCode_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T LiveCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryLiveCode(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f2', Tgt.F2);
        Observer.Expect('result|text', 'The following fields must have the same type:\\Field: F2 <-- F2\Table: TFR T LiveCode <-- TFR Src\Type: Code <-- Boolean');
        Observer.Expect('result|code', 'DB:TypeMisMatch');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '3');
        Observer.Expect('f2', '');
        Observer.Verify();
    end;

    // control: live Boolean source field, live Code[5] target field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_LiveControl_BoolToCode_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T LiveCode";
    begin
        SeedSrc(Src);
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryLiveCode(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Observe('f2', Tgt.F2);
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Expect('f2', '');
        Observer.Verify();
    end;

    // table extension fields of one app: live Boolean source field, removed Code[5] target field (same field number), default arguments.
    [Test]
    procedure TransferFields_Extension_RemovedTarget_Default()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T Plain";
    begin
        SeedSrc(Src);
        Src.ExtBool := true;
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryPlain(Src, Tgt, 0));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;

    // table extension fields of one app: live Boolean source field, removed Code[5] target field, SkipFieldsNotMatchingType true.
    [Test]
    procedure TransferFields_Extension_RemovedTarget_SkipMismatch()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "TFR Src";
        Tgt: Record "TFR T Plain";
    begin
        SeedSrc(Src);
        Src.ExtBool := true;
        Tgt."No." := 'T';
        Tgt.Keep := 3;
        Report(Observer, TryPlain(Src, Tgt, 3));
        Observer.Observe('no', Tgt."No.");
        Observer.Observe('keep', Format(Tgt.Keep));
        Observer.Expect('result', 'no error');
        Observer.Expect('no', 'A');
        Observer.Expect('keep', '5');
        Observer.Verify();
    end;
}
