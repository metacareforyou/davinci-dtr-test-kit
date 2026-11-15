RSpec.describe 'DTR Full EHR v2.2.0 UDAP registration and token verification' do # rubocop:disable RSpec/DescribeClass
  let(:tests) { Inferno::Repositories::Tests.new }

  def v220(id)
    tests.find("dtr_full_ehr_v220-#{id}")
  end

  it 'checks the UDAP registration aud against the v2.2.0 suite registration endpoint' do
    test = v220('dtr_client_payer_registration-udap_client_registration_cc_verification')
    expect(test.config.options[:endpoint_suite_id]).to eq(:dtr_full_ehr_v220)
    expect(test.new.client_registration_url).to end_with('/custom/dtr_full_ehr_v220/auth/register')
  end

  it 'waits for UDAP registration on the v2.2.0 suite' do
    test = v220('dtr_client_payer_registration-udap_client_registration_interaction')
    expect(test.config.options[:endpoint_suite_id]).to eq(:dtr_full_ehr_v220)
  end

  it 'checks the UDAP token request aud against the v2.2.0 suite token endpoint' do
    test = v220('dtr_client_payer_auth_udap-udap_client_token_request_cc_verification')
    expect(test.config.options[:endpoint_suite_id]).to eq(:dtr_full_ehr_v220)
    expect(test.new.client_token_url).to end_with('/custom/dtr_full_ehr_v220/auth/token')
  end

  it 'expects the same endpoints the v2.2.0 suite advertises in its UDAP metadata' do
    metadata = UDAPSecurityTestKit::MockUDAPServer.udap_server_metadata(:dtr_full_ehr_v220)
    body = JSON.parse(metadata[2].first)
    expect(body['token_endpoint']).to end_with('/custom/dtr_full_ehr_v220/auth/token')
    expect(body['registration_endpoint']).to end_with('/custom/dtr_full_ehr_v220/auth/register')
  end

  it 'leaves the v2.0.1 suite on its own endpoints' do
    test = tests.find('dtr_full_ehr-dtr_client_payer_auth_udap-udap_client_token_request_cc_verification')
    expect(test.new.client_token_url).to end_with('/custom/dtr_full_ehr/auth/token')
  end
end
