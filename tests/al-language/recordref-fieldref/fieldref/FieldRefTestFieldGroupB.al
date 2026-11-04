// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: FieldRef.TestField for Date, DateTime, Decimal, Enum and Guid variables (plain, ErrorInfo, collected)
// BC versions: 27 and later (values by CI matrix)

codeunit 67903 "LT R FRTF B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Date_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Date;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(5);
        Val := 20240131D;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 20240201D;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Dt Cap must be equal to ''02/01/24''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Date_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Date;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(5);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 20240131D;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 20240201D;
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
        Observer.Expect('different|text', 'Dt Cap must be equal to ''02/01/24''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Dt Cap must be equal to ''02/01/24''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Dt Cap must be equal to ''02/01/24''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Date_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Date;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(5);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 20240201D;
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
    procedure DateTime_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: DateTime;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(6);
        Val := CreateDateTime(20240131D, 123456T);
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := CreateDateTime(20240131D, 123457T);
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Dtm Cap must be equal to ''01/31/24 12:34 PM''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24 12:34 PM''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: DateTime;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(6);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := CreateDateTime(20240131D, 123456T);
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := CreateDateTime(20240131D, 123457T);
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
        Observer.Expect('different|text', 'Dtm Cap must be equal to ''01/31/24 12:34 PM''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24 12:34 PM''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Dtm Cap must be equal to ''01/31/24 12:34 PM''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24 12:34 PM''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Dtm Cap must be equal to ''01/31/24 12:34 PM''  in R Row Caption: Code Cap=K1. Current value is ''01/31/24 12:34 PM''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure DateTime_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: DateTime;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(6);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := CreateDateTime(20240131D, 123457T);
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
    procedure Decimal_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Decimal;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(4);
        Val := 12.5;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 12.6;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Dec Cap must be equal to ''12.6''  in R Row Caption: Code Cap=K1. Current value is ''12.5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Decimal;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(4);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 12.5;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 12.6;
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
        Observer.Expect('different|text', 'Dec Cap must be equal to ''12.6''  in R Row Caption: Code Cap=K1. Current value is ''12.5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Dec Cap must be equal to ''12.6''  in R Row Caption: Code Cap=K1. Current value is ''12.5''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Dec Cap must be equal to ''12.6''  in R Row Caption: Code Cap=K1. Current value is ''12.5''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Decimal_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Decimal;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(4);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 12.6;
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
    procedure Enum_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(8);
        Val := Val::Green;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := Val::Blue;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'En Cap must be equal to ''Blue Cap''  in R Row Caption: Code Cap=K1. Current value is ''Green Cap''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(8);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := Val::Green;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := Val::Blue;
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
        Observer.Expect('different|text', 'En Cap must be equal to ''Blue Cap''  in R Row Caption: Code Cap=K1. Current value is ''Green Cap''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'En Cap must be equal to ''Blue Cap''  in R Row Caption: Code Cap=K1. Current value is ''Green Cap''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'En Cap must be equal to ''Blue Cap''  in R Row Caption: Code Cap=K1. Current value is ''Green Cap''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Enum_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(8);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := Val::Blue;
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
    procedure Guid_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Val: Guid;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(7);
        Evaluate(Val, '{11111111-2222-3333-4444-555555555555}');
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
#if BC28PLUS
        Observer.Expect('different|text', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different|text', 'Gd Cap must be equal to ''11111111-2222-3333-4444-555555555556''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Guid;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(7);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Evaluate(Val, '{11111111-2222-3333-4444-555555555555}');
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
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
        Observer.Expect('different|text', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different|text', 'Gd Cap must be equal to ''11111111-2222-3333-4444-555555555556''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different|code', 'TestField');
#if BC28PLUS
        Observer.Expect('different_collectible_outside|text', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different_collectible_outside|text', 'Gd Cap must be equal to ''11111111-2222-3333-4444-555555555556''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different_collectible_outside|code', 'TestField');
#if BC28PLUS
        Observer.Expect('different_empty_info|text', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different_empty_info|text', 'Gd Cap must be equal to ''11111111-2222-3333-4444-555555555556''  in R Row Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Guid_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Guid;
    begin
        Helper.Seed();
        RecRef.Open(67900);
        RecRef.FindFirst();
        Fld := RecRef.Field(7);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
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
