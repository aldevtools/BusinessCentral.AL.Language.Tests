// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Assert
// Probe: every row of the "Time Zone" virtual table (2000000164): No., ID and Display Name (corpus #813, runner issue 6218).
// Asserted with the answer of the corpus CI (BC 27.5, 28.5 and 29.0 on Linux give the same 144 rows; BC 28.5 and 29.0 compared in full,
// BC 27.5 compared on the rows its test log showed in full, and this file runs on all three).
// THE TABLE DEPENDS ON THE HOST WINDOWS VERSION. Measured on the owner's BC SaaS sandbox (Windows, BC 29.0, 2026-10-29): 141 rows,
// 'W. Europe Standard Time' = No. 52. The three zones missing there are 'British Columbia Standard Time' (CI No. 8),
// 'Alberta Standard Time' (CI No. 12) and 'Manitoba Standard Time' (CI No. 17); every other row has the same ID and Display Name
// and only shifts in number. The Windows containers measured earlier (corpus #683) and the Linux CI give 144 rows with
// 'W. Europe Standard Time' = No. 55. So this file pins the Linux CI answer and fails on a host with an older Windows time zone list.
// BC versions: 27, 28, 29

codeunit 90530 "LT UV Time Zone Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TimeZone_RowCount()
    var
        TimeZone: Record "Time Zone";
    begin
        Assert.AreEqual(144, TimeZone.Count(), 'Time Zone row count.');
    end;

    local procedure CheckRow(No: Integer; ExpectedId: Text; ExpectedName: Text)
    var
        TimeZone: Record "Time Zone";
    begin
        Assert.IsTrue(TimeZone.Get(No), 'Time Zone No. ' + Format(No) + ' must exist.');
        Assert.AreEqual(ExpectedId, TimeZone.ID, 'ID of Time Zone No. ' + Format(No));
        Assert.AreEqual(ExpectedName, TimeZone."Display Name", 'Display Name of Time Zone No. ' + Format(No));
    end;

    [Test]
    procedure TimeZone_Rows001To012()
    begin
        CheckRow(1, 'Dateline Standard Time', '(UTC-12:00) International Date Line West');
        CheckRow(2, 'UTC-11', '(UTC-11:00) Coordinated Universal Time-11');
        CheckRow(3, 'Aleutian Standard Time', '(UTC-10:00) Aleutian Islands');
        CheckRow(4, 'Hawaiian Standard Time', '(UTC-10:00) Hawaii');
        CheckRow(5, 'Marquesas Standard Time', '(UTC-09:30) Marquesas Islands');
        CheckRow(6, 'Alaskan Standard Time', '(UTC-09:00) Alaska');
        CheckRow(7, 'UTC-09', '(UTC-09:00) Coordinated Universal Time-09');
        CheckRow(8, 'British Columbia Standard Time', '(UTC-07:00) Pacific Time (British Columbia)');
        CheckRow(9, 'Pacific Standard Time (Mexico)', '(UTC-08:00) Baja California');
        CheckRow(10, 'UTC-08', '(UTC-08:00) Coordinated Universal Time-08');
        CheckRow(11, 'Pacific Standard Time', '(UTC-08:00) Pacific Time (US & Canada)');
        CheckRow(12, 'Alberta Standard Time', '(UTC-06:00) Mountain Time (Alberta)');
    end;

    [Test]
    procedure TimeZone_Rows013To024()
    begin
        CheckRow(13, 'US Mountain Standard Time', '(UTC-07:00) Arizona');
        CheckRow(14, 'Mountain Standard Time (Mexico)', '(UTC-07:00) La Paz, Mazatlan');
        CheckRow(15, 'Mountain Standard Time', '(UTC-07:00) Mountain Time (US & Canada)');
        CheckRow(16, 'Yukon Standard Time', '(UTC-07:00) Yukon');
        CheckRow(17, 'Manitoba Standard Time', '(UTC-05:00) Manitoba');
        CheckRow(18, 'Central America Standard Time', '(UTC-06:00) Central America');
        CheckRow(19, 'Central Standard Time', '(UTC-06:00) Central Time (US & Canada)');
        CheckRow(20, 'Easter Island Standard Time', '(UTC-06:00) Easter Island');
        CheckRow(21, 'Central Standard Time (Mexico)', '(UTC-06:00) Guadalajara, Mexico City, Monterrey');
        CheckRow(22, 'Canada Central Standard Time', '(UTC-06:00) Saskatchewan');
        CheckRow(23, 'SA Pacific Standard Time', '(UTC-05:00) Bogota, Lima, Quito, Rio Branco');
        CheckRow(24, 'Eastern Standard Time (Mexico)', '(UTC-05:00) Chetumal');
    end;

    [Test]
    procedure TimeZone_Rows025To036()
    begin
        CheckRow(25, 'Eastern Standard Time', '(UTC-05:00) Eastern Time (US & Canada)');
        CheckRow(26, 'Haiti Standard Time', '(UTC-05:00) Haiti');
        CheckRow(27, 'Cuba Standard Time', '(UTC-05:00) Havana');
        CheckRow(28, 'US Eastern Standard Time', '(UTC-05:00) Indiana (East)');
        CheckRow(29, 'Turks And Caicos Standard Time', '(UTC-05:00) Turks and Caicos');
        CheckRow(30, 'Atlantic Standard Time', '(UTC-04:00) Atlantic Time (Canada)');
        CheckRow(31, 'Venezuela Standard Time', '(UTC-04:00) Caracas');
        CheckRow(32, 'Central Brazilian Standard Time', '(UTC-04:00) Cuiaba');
        CheckRow(33, 'SA Western Standard Time', '(UTC-04:00) Georgetown, La Paz, Manaus, San Juan');
        CheckRow(34, 'Pacific SA Standard Time', '(UTC-04:00) Santiago');
        CheckRow(35, 'Newfoundland Standard Time', '(UTC-03:30) Newfoundland');
        CheckRow(36, 'Tocantins Standard Time', '(UTC-03:00) Araguaina');
    end;

    [Test]
    procedure TimeZone_Rows037To048()
    begin
        CheckRow(37, 'Paraguay Standard Time', '(UTC-03:00) Asuncion');
        CheckRow(38, 'E. South America Standard Time', '(UTC-03:00) Brasilia');
        CheckRow(39, 'SA Eastern Standard Time', '(UTC-03:00) Cayenne, Fortaleza');
        CheckRow(40, 'Argentina Standard Time', '(UTC-03:00) City of Buenos Aires');
        CheckRow(41, 'Montevideo Standard Time', '(UTC-03:00) Montevideo');
        CheckRow(42, 'Magallanes Standard Time', '(UTC-03:00) Punta Arenas');
        CheckRow(43, 'Saint Pierre Standard Time', '(UTC-03:00) Saint Pierre and Miquelon');
        CheckRow(44, 'Bahia Standard Time', '(UTC-03:00) Salvador');
        CheckRow(45, 'UTC-02', '(UTC-02:00) Coordinated Universal Time-02');
        CheckRow(46, 'Greenland Standard Time', '(UTC-02:00) Greenland');
        CheckRow(47, 'Mid-Atlantic Standard Time', '(UTC-02:00) Mid-Atlantic - Old');
        CheckRow(48, 'Azores Standard Time', '(UTC-01:00) Azores');
    end;

    [Test]
    procedure TimeZone_Rows049To060()
    begin
        CheckRow(49, 'Cape Verde Standard Time', '(UTC-01:00) Cabo Verde Is.');
        CheckRow(50, 'UTC', '(UTC) Coordinated Universal Time');
        CheckRow(51, 'Morocco Standard Time', '(UTC+00:00) Casablanca');
        CheckRow(52, 'GMT Standard Time', '(UTC+00:00) Dublin, Edinburgh, Lisbon, London');
        CheckRow(53, 'Greenwich Standard Time', '(UTC+00:00) Monrovia, Reykjavik');
        CheckRow(54, 'Sao Tome Standard Time', '(UTC+00:00) Sao Tome');
        CheckRow(55, 'W. Europe Standard Time', '(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna');
        CheckRow(56, 'Central Europe Standard Time', '(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague');
        CheckRow(57, 'Romance Standard Time', '(UTC+01:00) Brussels, Copenhagen, Madrid, Paris');
        CheckRow(58, 'Central European Standard Time', '(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb');
        CheckRow(59, 'W. Central Africa Standard Time', '(UTC+01:00) West Central Africa');
        CheckRow(60, 'GTB Standard Time', '(UTC+02:00) Athens, Bucharest');
    end;

    [Test]
    procedure TimeZone_Rows061To072()
    begin
        CheckRow(61, 'Middle East Standard Time', '(UTC+02:00) Beirut');
        CheckRow(62, 'Egypt Standard Time', '(UTC+02:00) Cairo');
        CheckRow(63, 'E. Europe Standard Time', '(UTC+02:00) Chisinau');
        CheckRow(64, 'West Bank Standard Time', '(UTC+02:00) Gaza, Hebron');
        CheckRow(65, 'South Africa Standard Time', '(UTC+02:00) Harare, Pretoria');
        CheckRow(66, 'FLE Standard Time', '(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius');
        CheckRow(67, 'Israel Standard Time', '(UTC+02:00) Jerusalem');
        CheckRow(68, 'South Sudan Standard Time', '(UTC+02:00) Juba');
        CheckRow(69, 'Kaliningrad Standard Time', '(UTC+02:00) Kaliningrad');
        CheckRow(70, 'Sudan Standard Time', '(UTC+02:00) Khartoum');
        CheckRow(71, 'Libya Standard Time', '(UTC+02:00) Tripoli');
        CheckRow(72, 'Namibia Standard Time', '(UTC+02:00) Windhoek');
    end;

    [Test]
    procedure TimeZone_Rows073To084()
    begin
        CheckRow(73, 'Jordan Standard Time', '(UTC+03:00) Amman');
        CheckRow(74, 'Arabic Standard Time', '(UTC+03:00) Baghdad');
        CheckRow(75, 'Syria Standard Time', '(UTC+03:00) Damascus');
        CheckRow(76, 'Turkey Standard Time', '(UTC+03:00) Istanbul');
        CheckRow(77, 'Arab Standard Time', '(UTC+03:00) Kuwait, Riyadh');
        CheckRow(78, 'Belarus Standard Time', '(UTC+03:00) Minsk');
        CheckRow(79, 'Russian Standard Time', '(UTC+03:00) Moscow, St. Petersburg');
        CheckRow(80, 'E. Africa Standard Time', '(UTC+03:00) Nairobi');
        CheckRow(81, 'Volgograd Standard Time', '(UTC+03:00) Volgograd');
        CheckRow(82, 'Iran Standard Time', '(UTC+03:30) Tehran');
        CheckRow(83, 'Arabian Standard Time', '(UTC+04:00) Abu Dhabi, Muscat');
        CheckRow(84, 'Astrakhan Standard Time', '(UTC+04:00) Astrakhan, Ulyanovsk');
    end;

    [Test]
    procedure TimeZone_Rows085To096()
    begin
        CheckRow(85, 'Azerbaijan Standard Time', '(UTC+04:00) Baku');
        CheckRow(86, 'Russia Time Zone 3', '(UTC+04:00) Izhevsk, Samara');
        CheckRow(87, 'Mauritius Standard Time', '(UTC+04:00) Port Louis');
        CheckRow(88, 'Saratov Standard Time', '(UTC+04:00) Saratov');
        CheckRow(89, 'Georgian Standard Time', '(UTC+04:00) Tbilisi');
        CheckRow(90, 'Caucasus Standard Time', '(UTC+04:00) Yerevan');
        CheckRow(91, 'Afghanistan Standard Time', '(UTC+04:30) Kabul');
        CheckRow(92, 'West Asia Standard Time', '(UTC+05:00) Ashgabat, Tashkent');
        CheckRow(93, 'Qyzylorda Standard Time', '(UTC+05:00) Astana');
        CheckRow(94, 'Ekaterinburg Standard Time', '(UTC+05:00) Ekaterinburg');
        CheckRow(95, 'Pakistan Standard Time', '(UTC+05:00) Islamabad, Karachi');
        CheckRow(96, 'India Standard Time', '(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi');
    end;

    [Test]
    procedure TimeZone_Rows097To108()
    begin
        CheckRow(97, 'Sri Lanka Standard Time', '(UTC+05:30) Sri Jayawardenepura');
        CheckRow(98, 'Nepal Standard Time', '(UTC+05:45) Kathmandu');
        CheckRow(99, 'Central Asia Standard Time', '(UTC+06:00) Bishkek');
        CheckRow(100, 'Bangladesh Standard Time', '(UTC+06:00) Dhaka');
        CheckRow(101, 'Omsk Standard Time', '(UTC+06:00) Omsk');
        CheckRow(102, 'Myanmar Standard Time', '(UTC+06:30) Yangon (Rangoon)');
        CheckRow(103, 'SE Asia Standard Time', '(UTC+07:00) Bangkok, Hanoi, Jakarta');
        CheckRow(104, 'Altai Standard Time', '(UTC+07:00) Barnaul, Gorno-Altaysk');
        CheckRow(105, 'W. Mongolia Standard Time', '(UTC+07:00) Hovd');
        CheckRow(106, 'North Asia Standard Time', '(UTC+07:00) Krasnoyarsk');
        CheckRow(107, 'N. Central Asia Standard Time', '(UTC+07:00) Novosibirsk');
        CheckRow(108, 'Tomsk Standard Time', '(UTC+07:00) Tomsk');
    end;

    [Test]
    procedure TimeZone_Rows109To120()
    begin
        CheckRow(109, 'China Standard Time', '(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi');
        CheckRow(110, 'North Asia East Standard Time', '(UTC+08:00) Irkutsk');
        CheckRow(111, 'Singapore Standard Time', '(UTC+08:00) Kuala Lumpur, Singapore');
        CheckRow(112, 'W. Australia Standard Time', '(UTC+08:00) Perth');
        CheckRow(113, 'Taipei Standard Time', '(UTC+08:00) Taipei');
        CheckRow(114, 'Ulaanbaatar Standard Time', '(UTC+08:00) Ulaanbaatar');
        CheckRow(115, 'Aus Central W. Standard Time', '(UTC+08:45) Eucla');
        CheckRow(116, 'Transbaikal Standard Time', '(UTC+09:00) Chita');
        CheckRow(117, 'Tokyo Standard Time', '(UTC+09:00) Osaka, Sapporo, Tokyo');
        CheckRow(118, 'North Korea Standard Time', '(UTC+09:00) Pyongyang');
        CheckRow(119, 'Korea Standard Time', '(UTC+09:00) Seoul');
        CheckRow(120, 'Yakutsk Standard Time', '(UTC+09:00) Yakutsk');
    end;

    [Test]
    procedure TimeZone_Rows121To132()
    begin
        CheckRow(121, 'Cen. Australia Standard Time', '(UTC+09:30) Adelaide');
        CheckRow(122, 'AUS Central Standard Time', '(UTC+09:30) Darwin');
        CheckRow(123, 'E. Australia Standard Time', '(UTC+10:00) Brisbane');
        CheckRow(124, 'AUS Eastern Standard Time', '(UTC+10:00) Canberra, Melbourne, Sydney');
        CheckRow(125, 'West Pacific Standard Time', '(UTC+10:00) Guam, Port Moresby');
        CheckRow(126, 'Tasmania Standard Time', '(UTC+10:00) Hobart');
        CheckRow(127, 'Vladivostok Standard Time', '(UTC+10:00) Vladivostok');
        CheckRow(128, 'Lord Howe Standard Time', '(UTC+10:30) Lord Howe Island');
        CheckRow(129, 'Bougainville Standard Time', '(UTC+11:00) Bougainville Island');
        CheckRow(130, 'Russia Time Zone 10', '(UTC+11:00) Chokurdakh');
        CheckRow(131, 'Magadan Standard Time', '(UTC+11:00) Magadan');
        CheckRow(132, 'Norfolk Standard Time', '(UTC+11:00) Norfolk Island');
    end;

    [Test]
    procedure TimeZone_Rows133To144()
    begin
        CheckRow(133, 'Sakhalin Standard Time', '(UTC+11:00) Sakhalin');
        CheckRow(134, 'Central Pacific Standard Time', '(UTC+11:00) Solomon Is., New Caledonia');
        CheckRow(135, 'Russia Time Zone 11', '(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky');
        CheckRow(136, 'New Zealand Standard Time', '(UTC+12:00) Auckland, Wellington');
        CheckRow(137, 'UTC+12', '(UTC+12:00) Coordinated Universal Time+12');
        CheckRow(138, 'Fiji Standard Time', '(UTC+12:00) Fiji');
        CheckRow(139, 'Kamchatka Standard Time', '(UTC+12:00) Petropavlovsk-Kamchatsky - Old');
        CheckRow(140, 'Chatham Islands Standard Time', '(UTC+12:45) Chatham Islands');
        CheckRow(141, 'UTC+13', '(UTC+13:00) Coordinated Universal Time+13');
        CheckRow(142, 'Tonga Standard Time', '(UTC+13:00) Nuku''alofa');
        CheckRow(143, 'Samoa Standard Time', '(UTC+13:00) Samoa');
        CheckRow(144, 'Line Islands Standard Time', '(UTC+14:00) Kiritimati Island');
    end;
}
