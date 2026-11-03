// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: Record.TestField(Field, Value) for Guid, Integer, Label, Text and TextConst values (plain, ErrorInfo, collected)
// BC versions: 27 and later (values by CI matrix)

codeunit 67905 "LT R RTF B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Guid_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Guid;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Evaluate(Val, '{11111111-2222-3333-4444-555555555555}');
        Rec.TestField(Gd, Val);
        Observer.Observe('equal', 'no error');
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
        asserterror Rec.TestField(Gd, Val);
        Observer.ObserveError('different');
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
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Guid;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Evaluate(Val, '{11111111-2222-3333-4444-555555555555}');
        Rec.TestField(Gd, Val, Info);
        Observer.Observe('equal', 'no error');
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
        asserterror Rec.TestField(Gd, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Gd, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Gd, Val, Info);
        Observer.ObserveError('different_empty_info');
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
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Guid;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Evaluate(Val, '{11111111-2222-3333-4444-555555555556}');
        Rec.TestField(Gd, Val, Info);
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
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Integer;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := 5;
        Rec.TestField(Num, Val);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Rec.TestField(Num, Val);
        Observer.ObserveError('different');
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in R Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Integer;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5;
        Rec.TestField(Num, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Rec.TestField(Num, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Num, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Num, Val, Info);
        Observer.ObserveError('different_empty_info');
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
    procedure Integer_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Integer;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 6;
        Rec.TestField(Num, Val, Info);
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
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Label_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        LblEq: Label 'Hello';
        LblDf: Label 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Rec.TestField(Txt, LblEq);
        Observer.Observe('equal', 'no error');
        asserterror Rec.TestField(Txt, LblDf);
        Observer.ObserveError('different');
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Label_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        LblEq: Label 'Hello';
        LblDf: Label 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Rec.TestField(Txt, LblEq, Info);
        Observer.Observe('equal', 'no error');
        asserterror Rec.TestField(Txt, LblDf, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Txt, LblDf, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Txt, LblDf, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Label_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        LblEq: Label 'Hello';
        LblDf: Label 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Rec.TestField(Txt, LblDf, Info);
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
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Text;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := 'Hello';
        Rec.TestField(Txt, Val);
        Observer.Observe('equal', 'no error');
        Val := 'Hellp';
        asserterror Rec.TestField(Txt, Val);
        Observer.ObserveError('different');
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Text_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Text;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 'Hello';
        Rec.TestField(Txt, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 'Hellp';
        asserterror Rec.TestField(Txt, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Txt, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Txt, Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Text_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Text;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 'Hellp';
        Rec.TestField(Txt, Val, Info);
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
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        TcEq: TextConst ENU = 'Hello';
        TcDf: TextConst ENU = 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Rec.TestField(Txt, TcEq);
        Observer.Observe('equal', 'no error');
        asserterror Rec.TestField(Txt, TcDf);
        Observer.ObserveError('different');
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TextConst_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        TcEq: TextConst ENU = 'Hello';
        TcDf: TextConst ENU = 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Rec.TestField(Txt, TcEq, Info);
        Observer.Observe('equal', 'no error');
        asserterror Rec.TestField(Txt, TcDf, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Txt, TcDf, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Txt, TcDf, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_collectible_outside|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_collectible_outside|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Txt Cap must be equal to ''Hellp''  in R Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TextConst_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        TcEq: TextConst ENU = 'Hello';
        TcDf: TextConst ENU = 'Hellp';
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Rec.TestField(Txt, TcDf, Info);
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
        Observer.Expect('after_call', 'reached');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '1');
        Observer.Expect('collected_message', 'info message');
        Observer.Expect('collected_title', 'info title');
        Observer.Expect('collected_collectible', 'Yes');
        Observer.Verify();
    end;
}
