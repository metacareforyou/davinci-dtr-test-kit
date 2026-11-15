RSpec.describe 'DTR Full EHR v2.2.0 SMART token request verification' do # rubocop:disable RSpec/DescribeClass
  let(:tests) { Inferno::Repositories::Tests.new }
  let(:v220_test) do
    tests.find('dtr_full_ehr_v220-dtr_client_payer_auth_smart-smart_client_token_request_bsca_verification')
  end
  let(:v201_test) do
    tests.find('dtr_full_ehr-dtr_client_payer_auth_smart-smart_client_token_request_bsca_verification')
  end

  it 'checks the client assertion aud against the v2.2.0 suite token endpoint' do
    expect(v220_test).to be_present
    expect(v220_test.config.options[:endpoint_suite_id]).to eq(:dtr_full_ehr_v220)
    expect(v220_test.new.client_token_url).to end_with('/custom/dtr_full_ehr_v220/auth/token')
  end

  it 'expects the same token endpoint the v2.2.0 suite advertises' do
    metadata = SMARTAppLaunch::MockSMARTServer.smart_server_metadata(:dtr_full_ehr_v220)
    body = JSON.parse(metadata[2].first)
    expect(body['token_endpoint']).to eq(v220_test.new.client_token_url)
  end

  it 'leaves the v2.0.1 suite checking its own token endpoint' do
    expect(v201_test.new.client_token_url).to end_with('/custom/dtr_full_ehr/auth/token')
  end
end
