// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) with Boolean, Date, Time, DateTime and Guid values incl. undefined values; FieldRef.TestField(Variant) with the same
// BC versions: 29 (27 and 28 by CI)

codeunit 70743 "LT P96 Temporal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Temporal_Boolean_Date_1()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        D1: Date;
        D0: Date;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        D1 := DMY2Date(15, 6, 2021);
        H.ObservePair(Observer, 'bool_true_equal', H.RecBool(Full,true), H.RefV(Full,7,true));
        H.ObservePair(Observer, 'bool_false_diff', H.RecBool(Full,false), H.RefV(Full,7,false));
        H.ObservePair(Observer, 'bool_false_on_empty', H.RecBool(Empty,false), H.RefV(Empty,7,false));
        H.ObservePair(Observer, 'bool_true_on_empty', H.RecBool(Empty,true), H.RefV(Empty,7,true));
        H.ObservePair(Observer, 'date_equal', H.RecDate(Full,D1), H.RefV(Full,8,D1));
        H.ObservePair(Observer, 'date_diff', H.RecDate(Full,DMY2Date(16,6,2021)), H.RefV(Full,8,DMY2Date(16,6,2021)));
        H.ObservePair(Observer, 'date_undefined_on_full', H.RecDate(Full,D0), H.RefV(Full,8,D0));
        H.ObservePair(Observer, 'date_undefined_on_empty', H.RecDate(Empty,D0), H.RefV(Empty,8,D0));
        Observer.Expect('rec_bool_true_equal', 'ok');
        Observer.Expect('ref_bool_true_equal', 'ok');
        Observer.Expect('same_bool_true_equal', 'Yes');
        Observer.Expect('rec_bool_false_diff', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('ref_bool_false_diff', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('same_bool_false_diff', 'Yes');
        Observer.Expect('rec_bool_false_on_empty', 'ok');
        Observer.Expect('ref_bool_false_on_empty', 'ok');
        Observer.Expect('same_bool_false_on_empty', 'Yes');
        Observer.Expect('rec_bool_true_on_empty', 'Flag Cap must be equal to ''Yes''  in P96 Rec Caption: Code Cap=E1. Current value is ''No''.|TestField');
        Observer.Expect('ref_bool_true_on_empty', 'Flag Cap must be equal to ''Yes''  in P96 Rec Caption: Code Cap=E1. Current value is ''No''.|TestField');
        Observer.Expect('same_bool_true_on_empty', 'Yes');
        Observer.Expect('rec_date_equal', 'ok');
        Observer.Expect('ref_date_equal', 'ok');
        Observer.Expect('same_date_equal', 'Yes');
        Observer.Expect('rec_date_diff', 'Dt Cap must be equal to ''06/16/21''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('ref_date_diff', 'Dt Cap must be equal to ''06/16/21''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('same_date_diff', 'Yes');
        Observer.Expect('rec_date_undefined_on_full', 'Dt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('ref_date_undefined_on_full', 'Dt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('same_date_undefined_on_full', 'Yes');
        Observer.Expect('rec_date_undefined_on_empty', 'ok');
        Observer.Expect('ref_date_undefined_on_empty', 'ok');
        Observer.Expect('same_date_undefined_on_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporal_Boolean_Date_2()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        D1: Date;
        D0: Date;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        D1 := DMY2Date(15, 6, 2021);
        H.ObservePair(Observer, 'date_value_on_empty', H.RecDate(Empty,D1), H.RefV(Empty,8,D1));
        H.ObservePair(Observer, 'date_closing', H.RecDate(Full,ClosingDate(D1)), H.RefV(Full,8,ClosingDate(D1)));
        Observer.Expect('rec_date_value_on_empty', 'Dt Cap must be equal to ''06/15/21''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_date_value_on_empty', 'Dt Cap must be equal to ''06/15/21''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_date_value_on_empty', 'Yes');
        Observer.Expect('rec_date_closing', 'Dt Cap must be equal to ''C06/15/21''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('ref_date_closing', 'Dt Cap must be equal to ''C06/15/21''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('same_date_closing', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporal_Time_DateTime_1()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Dt0: DateTime;
        Tm0: Time;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'time_equal', H.RecTime(Full,123000T), H.RefV(Full,9,123000T));
        H.ObservePair(Observer, 'time_diff', H.RecTime(Full,123001T), H.RefV(Full,9,123001T));
        H.ObservePair(Observer, 'time_ms_diff', H.RecTime(Full,123000T + 1), H.RefV(Full,9,123000T + 1));
        H.ObservePair(Observer, 'time_undefined_on_full', H.RecTime(Full,Tm0), H.RefV(Full,9,Tm0));
        H.ObservePair(Observer, 'time_undefined_on_empty', H.RecTime(Empty,Tm0), H.RefV(Empty,9,Tm0));
        H.ObservePair(Observer, 'time_value_on_empty', H.RecTime(Empty,123000T), H.RefV(Empty,9,123000T));
        H.ObservePair(Observer, 'dtm_equal', H.RecDtm(Full,CreateDateTime(DMY2Date(15,6,2021),123000T)), H.RefV(Full,10,CreateDateTime(DMY2Date(15,6,2021),123000T)));
        H.ObservePair(Observer, 'dtm_time_diff', H.RecDtm(Full,CreateDateTime(DMY2Date(15,6,2021),123001T)), H.RefV(Full,10,CreateDateTime(DMY2Date(15,6,2021),123001T)));
        Observer.Expect('rec_time_equal', 'ok');
        Observer.Expect('ref_time_equal', 'ok');
        Observer.Expect('same_time_equal', 'Yes');
        Observer.Expect('rec_time_diff', 'Tm Cap must be equal to ''12:30:01 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('ref_time_diff', 'Tm Cap must be equal to ''12:30:01 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('same_time_diff', 'Yes');
        Observer.Expect('rec_time_ms_diff', 'Tm Cap must be equal to ''12:30:00 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('ref_time_ms_diff', 'Tm Cap must be equal to ''12:30:00 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('same_time_ms_diff', 'Yes');
        Observer.Expect('rec_time_undefined_on_full', 'Tm Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('ref_time_undefined_on_full', 'Tm Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('same_time_undefined_on_full', 'Yes');
        Observer.Expect('rec_time_undefined_on_empty', 'ok');
        Observer.Expect('ref_time_undefined_on_empty', 'ok');
        Observer.Expect('same_time_undefined_on_empty', 'Yes');
        Observer.Expect('rec_time_value_on_empty', 'Tm Cap must be equal to ''12:30:00 PM''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_time_value_on_empty', 'Tm Cap must be equal to ''12:30:00 PM''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_time_value_on_empty', 'Yes');
        Observer.Expect('rec_dtm_equal', 'ok');
        Observer.Expect('ref_dtm_equal', 'ok');
        Observer.Expect('same_dtm_equal', 'Yes');
        Observer.Expect('rec_dtm_time_diff', 'Dtm Cap must be equal to ''06/15/21 12:30 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('ref_dtm_time_diff', 'Dtm Cap must be equal to ''06/15/21 12:30 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('same_dtm_time_diff', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporal_Time_DateTime_2()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Dt0: DateTime;
        Tm0: Time;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'dtm_date_diff', H.RecDtm(Full,CreateDateTime(DMY2Date(16,6,2021),123000T)), H.RefV(Full,10,CreateDateTime(DMY2Date(16,6,2021),123000T)));
        H.ObservePair(Observer, 'dtm_undefined_on_full', H.RecDtm(Full,Dt0), H.RefV(Full,10,Dt0));
        H.ObservePair(Observer, 'dtm_undefined_on_empty', H.RecDtm(Empty,Dt0), H.RefV(Empty,10,Dt0));
        H.ObservePair(Observer, 'dtm_value_on_empty', H.RecDtm(Empty,CreateDateTime(DMY2Date(15,6,2021),123000T)), H.RefV(Empty,10,CreateDateTime(DMY2Date(15,6,2021),123000T)));
        Observer.Expect('rec_dtm_date_diff', 'Dtm Cap must be equal to ''06/16/21 12:30 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('ref_dtm_date_diff', 'Dtm Cap must be equal to ''06/16/21 12:30 PM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('same_dtm_date_diff', 'Yes');
        Observer.Expect('rec_dtm_undefined_on_full', 'Dtm Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('ref_dtm_undefined_on_full', 'Dtm Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('same_dtm_undefined_on_full', 'Yes');
        Observer.Expect('rec_dtm_undefined_on_empty', 'ok');
        Observer.Expect('ref_dtm_undefined_on_empty', 'ok');
        Observer.Expect('same_dtm_undefined_on_empty', 'Yes');
        Observer.Expect('rec_dtm_value_on_empty', 'Dtm Cap must be equal to ''06/15/21 12:30 PM''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_dtm_value_on_empty', 'Dtm Cap must be equal to ''06/15/21 12:30 PM''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_dtm_value_on_empty', 'Yes');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Temporal_Guid()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        G1: Guid;
        G2: Guid;
        G0: Guid;
        G3: Guid;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Evaluate(G1, '{11111111-2222-3333-4444-555555555555}');
        Evaluate(G2, '{11111111-2222-3333-4444-555555555556}');
        Evaluate(G3, '{11111111-2222-3333-4444-555555555555}');
        H.ObservePair(Observer, 'guid_equal', H.RecGuid(Full,G1), H.RefV(Full,11,G1));
        H.ObservePair(Observer, 'guid_diff', H.RecGuid(Full,G2), H.RefV(Full,11,G2));
        H.ObservePair(Observer, 'guid_null_on_full', H.RecGuid(Full,G0), H.RefV(Full,11,G0));
        H.ObservePair(Observer, 'guid_null_on_empty', H.RecGuid(Empty,G0), H.RefV(Empty,11,G0));
        H.ObservePair(Observer, 'guid_value_on_empty', H.RecGuid(Empty,G1), H.RefV(Empty,11,G1));
        H.ObservePair(Observer, 'guid_case_equal', H.RecGuid(Full,G3), H.RefV(Full,11,G3));
        Observer.Expect('rec_guid_equal', 'ok');
        Observer.Expect('ref_guid_equal', 'ok');
        Observer.Expect('same_guid_equal', 'Yes');
        Observer.Expect('rec_guid_diff', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('ref_guid_diff', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555556}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('same_guid_diff', 'Yes');
        Observer.Expect('rec_guid_null_on_full', 'Gd Cap must be equal to ''{00000000-0000-0000-0000-000000000000}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('ref_guid_null_on_full', 'Gd Cap must be equal to ''{00000000-0000-0000-0000-000000000000}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('same_guid_null_on_full', 'Yes');
        Observer.Expect('rec_guid_null_on_empty', 'ok');
        Observer.Expect('ref_guid_null_on_empty', 'ok');
        Observer.Expect('same_guid_null_on_empty', 'Yes');
        Observer.Expect('rec_guid_value_on_empty', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=E1. Current value is ''{00000000-0000-0000-0000-000000000000}''.|TestField');
        Observer.Expect('ref_guid_value_on_empty', 'Gd Cap must be equal to ''{11111111-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=E1. Current value is ''{00000000-0000-0000-0000-000000000000}''.|TestField');
        Observer.Expect('same_guid_value_on_empty', 'Yes');
        Observer.Expect('rec_guid_case_equal', 'ok');
        Observer.Expect('ref_guid_case_equal', 'ok');
        Observer.Expect('same_guid_case_equal', 'Yes');
        Observer.Verify();
    end;
#endif
}
