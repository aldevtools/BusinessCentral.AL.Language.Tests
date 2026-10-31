// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-addcertificate-string-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (writer Y20, al-runner issue 6484): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix. Empty, non-Base64 and
//   cut-DER values are pinned in P108Cert1.al (Text) and P108Cert2.al (SecretText).
// Facts: HttpClient.AddCertificate with well-formed values: a complete DER SEQUENCE that is no certificate ('MAIFAA=='), a PKCS#12
//   (.pfx) with its password, with a wrong password, with an empty password and without one, a PKCS#12 without a password, and an
//   X.509 certificate in DER without a private key. No request is sent.
// The certificate and EC key below were generated for this probe only (self-signed, CN "LT Y20 Test Certificate", valid until 2126);
//   they protect nothing.
// BC versions: 27, 28, 29

codeunit 92110 "LT Y20 Http Add Certificate"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [TryFunction]
    local procedure TryAdd(Cert: Text; Pwd: Text; WithPassword: Boolean)
    var
        Client: HttpClient;
    begin
        if WithPassword then
            Client.AddCertificate(Cert, Pwd)
        else
            Client.AddCertificate(Cert);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Cert: Text; Pwd: Text; WithPassword: Boolean)
    begin
        ClearLastError();
        if TryAdd(Cert, Pwd, WithPassword) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Y20_AddCertificate_DerSequenceNoCertificate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'der_seq_pw', 'MAIFAA==', 'pw', true);
        Probe(Observer, 'der_seq_no_pw', 'MAIFAA==', '', false);
        Observer.Finish();
    end;

    [Test]
    procedure Y20_AddCertificate_PfxPasswords()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'pfx_right_pw', PfxPw(), 'pw', true);
        Probe(Observer, 'pfx_wrong_pw', PfxPw(), 'wrong', true);
        Probe(Observer, 'pfx_empty_pw', PfxPw(), '', true);
        Probe(Observer, 'pfx_no_pw', PfxPw(), '', false);
        Probe(Observer, 'pfx_nopw_no_pw', PfxNoPw(), '', false);
        Probe(Observer, 'pfx_nopw_empty_pw', PfxNoPw(), '', true);
        Probe(Observer, 'pfx_nopw_some_pw', PfxNoPw(), 'pw', true);
        Observer.Finish();
    end;

    [Test]
    procedure Y20_AddCertificate_SecretText_PfxRightPassword()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Cert: SecretText;
        Pwd: SecretText;
    begin
        Cert := PfxPw();
        Pwd := SecretStrSubstNo('pw');
        Client.AddCertificate(Cert, Pwd);
        Observer.Observe('secret_pfx_right_pw', 'ok');
        Observer.Finish();
    end;

    [Test]
    procedure Y20_AddCertificate_CerWithoutKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'cer_no_pw', CerDer(), '', false);
        Probe(Observer, 'cer_pw', CerDer(), 'pw', true);
        Observer.Finish();
    end;

    local procedure PfxPw() Result: Text
    begin
        Result += 'MIIERAIBAzCCA/IGCSqGSIb3DQEHAaCCA+MEggPfMIID2zCCAooGCSqGSIb3DQEHBqCCAnswggJ3AgEAMIICcAYJKoZIhvcNAQcB';
        Result += 'MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBAQo3liJqnasne+E8sBg3JFAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFl';
        Result += 'AwQBKgQQJwCmLFyEdrsDTlpW6oL1lYCCAgCMoxIyiB0O1RfotIkrW2jMId07wZ39MfA1dbJZC7v8kpYVoHSR+WDmYaOVQWXI1fqx';
        Result += '5v9RwyxVCrAnCY0MlQQWk2Y6l7jB4ggq83jlzOdRX9OTC+WuY/UuZgrqq8/Y+G2dnAhMHKGihd+lyd0gI8F1QDqw88gSjK3v+3bH';
        Result += '4BCgo7KvMd+FANovsKejsWy9bePNHb669DHB9GeF2uXBspHZ98Wazg9Yrmw20fyjpnQdO5cHahQD0ALwQUa77edt2toCTlAC7ujg';
        Result += 'DvXPItsbhc2q1H6wZLZZXOw62NASx+sV7nmFBsi/cf1NVAPiPs2T7U5+1MYdsdNkJXmxIVF7tNtBQIIprScVNvSot2Kk+we+E/Qm';
        Result += 'ISy7rU8Je5YvzzIipzbdKpFpECYITDfM4OU+HULOujdYlFH7Wt7erWWcr6VprPotXkzFCARzIPaxFpy7v89HXZM+ePlBh+h81e9I';
        Result += 'Qt80yaXQum9BZErEHqP4KvHwFZEetiYZQqSA+0C3LyH6nB5arpNyofXDnrSQOasXjo4GfAFLt319Bit9wSRXUiKrN/7Qjw2ztOre';
        Result += 'RFaJnD+xNNvNsMjdQMKudjXV1vKFEwLFmhnmNbzRYPWPEgd4svxxU3129aH+LCOxSQBedkGIsN/+Amv//0f2pEFGybLuwcJ5wvjY';
        Result += 'd7TTH8A2ryi0BxEF9DCCAUkGCSqGSIb3DQEHAaCCAToEggE2MIIBMjCCAS4GCyqGSIb3DQEMCgECoIH3MIH0MF8GCSqGSIb3DQEF';
        Result += 'DTBSMDEGCSqGSIb3DQEFDDAkBBBqlm2m0OdCOnmExgsia2PTAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQppR9+T+Q';
        Result += 'oWX9hbqCH7onUASBkILkjt3jeBD2FJ+b1qIp8Moa722+EApuJd431m0rTVOAput6pWvMTYXCHmI2XUaXyaUyVw00b6Bf/EFxl9Ta';
        Result += 'v/oxhtTxOPAn0kkawpzuPAHZTPzLQ2o/bIQeLcnVcjfgffrduMOTSTB0Y1GrCzv3Zn7olu/HaCBbeGmNIf59hyAnZzciyZgL94pF';
        Result += 'PWzbUmBqJTElMCMGCSqGSIb3DQEJFTEWBBQ9ytIgOdvYI1jbrHycIlXVg4vmEDBJMDEwDQYJYIZIAWUDBAIBBQAEIBPSKHgov9Dy';
        Result += 'eoSE2Y8D21sF6sx9IF+SXpBWKvUQOuN0BBDqU04b3lG0286zcyqjZtQvAgIIAA==';
    end;

    local procedure PfxNoPw() Result: Text
    begin
        Result += 'MIIERAIBAzCCA/IGCSqGSIb3DQEHAaCCA+MEggPfMIID2zCCAooGCSqGSIb3DQEHBqCCAnswggJ3AgEAMIICcAYJKoZIhvcNAQcB';
        Result += 'MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBC7BrJrE7DH8GKll6m5LQluAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFl';
        Result += 'AwQBKgQQD1Al6CAlf450j97syzPw0YCCAgA2tah+hyNtyomk544N3vsFXnBuhbBUbB50b3T+MnS7tRlf9RfFDLYlsEUOsMoWqrMa';
        Result += '+QlfNcXwZJy41QnSzqnAgFAdvSPEbTlWYBUXmE8dGLrrfzCA+bTEAOAehqDq1tX1Qkx9ibcMfq1/kAapk4WiYekGVJqCDGGg5PN3';
        Result += '4+zLEBbEupQzGMbVZCgs/kFTdVOmYuLuw9REXzn8mZv2m0dZ9OJJVF2DKrRRLzW0cpxiZzK7uObXBoUBuhLI7QdXMNcrVd2ZG7C7';
        Result += 'km7+D+IOF/dXypa81KCKmFmtlMPwO4baVxvr8pSXiBZ6egvlaKmzTyddbgh/l7rxblxZh1OhJrrsa8u87yB/x80quGCPk6qN34UF';
        Result += 'shoGRgyYe8ZNgi1X4mdIVO5//0Lt3/3L8Kntzcy6smvjGaJWrnWGvfe0Iko6rw6xNHrHvOo6zQ/hXLhyhkvKLjSEztUC0TnOT7ho';
        Result += 'BDBgL9uOq1/rsvgI6iMoIJpT1bNao0gh3DqFbIMSiklqhtb4UZKCUriFwKM0k8wm0Ov6n9/MDZD7lDjAkEN3ImIiczDHrJGgOIyb';
        Result += 'Hp/DDM4SPFrgA0/dKeiElrxKbo51cN320KHAFqNZEC1uytJQiRhqG0HLNmAz+ORdd0et6yE2s17OaYDK7mrBeScc+CBgO1IT06Sh';
        Result += 'Lc8I2LHF7J6VfgG0uTCCAUkGCSqGSIb3DQEHAaCCAToEggE2MIIBMjCCAS4GCyqGSIb3DQEMCgECoIH3MIH0MF8GCSqGSIb3DQEF';
        Result += 'DTBSMDEGCSqGSIb3DQEFDDAkBBDKV2ZWpxRmt53Lx4vufcUxAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQ11pzystG';
        Result += '4+5qcAUyd7O+FwSBkKMN9C3v4RMIVW2zGeC233jYQOwWRb0k9J3/K05fqi2Fmz5zp8g9XhLfKc2LhgjmJzE4svZZmIS1zT7StpJZ';
        Result += 'AGC1p4v9+kh791/ckNoMkS9Ksj6NC6G9j6Tr2wEzoprvYDu7NDRP/tjN/0AXgiJhGgRsTomFPhh+VJdTuKce5yMXZKNseogKJoOo';
        Result += 'faFKX/a0nTElMCMGCSqGSIb3DQEJFTEWBBQ9ytIgOdvYI1jbrHycIlXVg4vmEDBJMDEwDQYJYIZIAWUDBAIBBQAEIBTWfJU8rlwo';
        Result += '+G6flHKLQfuJrCWfecIW0k3gX7iO9zH8BBCrDHJ309MoiFSXxVl9QeR5AgIIAA==';
    end;

    local procedure CerDer() Result: Text
    begin
        Result += 'MIIBmzCCAUGgAwIBAgIURSKBkXDAznosRbAyyROyAM/DsH4wCgYIKoZIzj0EAwIwIjEgMB4GA1UEAwwXTFQgWTIwIFRlc3QgQ2Vy';
        Result += 'dGlmaWNhdGUwIBcNMjYxMDMxMDk0NDU4WhgPMjEyNjEwMDcwOTQ0NThaMCIxIDAeBgNVBAMMF0xUIFkyMCBUZXN0IENlcnRpZmlj';
        Result += 'YXRlMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtHbMADTIURVZvVtKXkBAw6Iunt1p/io8nNcfxkIQReYpvvUth2qxtLttSFWa';
        Result += 'yjszjUYaFsirafFHOO5s/cy966NTMFEwHQYDVR0OBBYEFLHBKrhaJBnejCNc5ZksUVHP3hyBMB8GA1UdIwQYMBaAFLHBKrhaJBne';
        Result += 'jCNc5ZksUVHP3hyBMA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSAAwRQIhALwumEwM6Nd8hBOgfTDj1Y7v0S4e7Bb1440I';
        Result += '7jBr6G9jAiBkTVnKr/NTsHRf0xI1a9A2hXnc3ayG7OrsFjwZZ+x4lQ==';
    end;
}
