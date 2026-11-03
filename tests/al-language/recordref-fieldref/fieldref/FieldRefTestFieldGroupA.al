// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: FieldRef.TestField for BigInteger, Boolean, Byte, Char and Code variables (plain, ErrorInfo, collected)
// BC versions: 27 and later (values by CI matrix)

codeunit 67902 "LT R FRTF A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BigInteger_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: BigInteger;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(2);
        Val := 5000000000L;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 5000000001L;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Big Cap must be equal to ''5000000001''  in R Row Caption: Code Cap=K1. Current value is ''5000000000''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: BigInteger;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(2);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5000000000L;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 5000000001L;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Big Cap must be equal to ''5000000001''  in R Row Caption: Code Cap=K1. Current value is ''5000000000''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Big Cap must be equal to ''5000000001''  in R Row Caption: Code Cap=K1. Current value is ''5000000000''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Big Cap must be equal to ''5000000001''  in R Row Caption: Code Cap=K1. Current value is ''5000000000''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure BigInteger_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: BigInteger;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(2);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 5000000001L;
        Fld.TestField(Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        RecRef.Close();
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        Val := true;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := false;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Bool Cap must be equal to ''No''  in R Row Caption: Code Cap=K1. Current value is ''Yes''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := true;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := false;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Bool Cap must be equal to ''No''  in R Row Caption: Code Cap=K1. Current value is ''Yes''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Bool Cap must be equal to ''No''  in R Row Caption: Code Cap=K1. Current value is ''Yes''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Bool Cap must be equal to ''No''  in R Row Caption: Code Cap=K1. Current value is ''Yes''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Boolean_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := false;
        Fld.TestField(Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        RecRef.Close();
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Byte;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Val := 5;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
#if BC28PLUS
        Observer.Expect('different|text', 'Num Cap must be equal to ''\u0006''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#else
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Byte;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
#if BC28PLUS
        Observer.Expect('different|text', 'Num Cap must be equal to ''\u0006''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#else
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#endif
        Observer.Expect('different|code', 'TestField');
#if BC28PLUS
        Observer.Expect('different_collectible_outside|text', 'Num Cap must be equal to ''\u0006''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#else
        Observer.Expect('different_collectible_outside|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#endif
        Observer.Expect('different_collectible_outside|code', 'TestField');
#if BC28PLUS
        Observer.Expect('different_empty_info|text', 'Num Cap must be equal to ''\u0006''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#else
        Observer.Expect('different_empty_info|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
#endif
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Byte_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Byte;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 6;
        Fld.TestField(Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        RecRef.Close();
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Char;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Val := 5;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Char_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Char;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Char_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Char;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(11);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 6;
        Fld.TestField(Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        RecRef.Close();
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Code_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Code[10];
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(10);
        Val := 'ABC';
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 'ABD';
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Cd Cap must be equal to ''ABD''  in R Row Caption: Code Cap=K1. Current value is ''ABC''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Code_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Code[10];
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(10);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 'ABC';
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 'ABD';
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Cd Cap must be equal to ''ABD''  in R Row Caption: Code Cap=K1. Current value is ''ABC''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Cd Cap must be equal to ''ABD''  in R Row Caption: Code Cap=K1. Current value is ''ABC''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Cd Cap must be equal to ''ABD''  in R Row Caption: Code Cap=K1. Current value is ''ABC''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Code_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Code[10];
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(10);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 'ABD';
        Fld.TestField(Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        RecRef.Close();
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;
}
