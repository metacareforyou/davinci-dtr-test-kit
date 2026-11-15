require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220QuestionnairePackageEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:client_id) { 'adaptive_service_url_client_id' }
  let(:server_endpoint) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:adaptive_extension_url) do
    'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'
  end
  let(:valid_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
  end

  # The adaptive workflow group serves this fixture as its $questionnaire-package response.
  let(:adaptive_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_adaptive_service_url_spec_test
      config options: {
        qp_response_template_fixture: File.join('dinner_adaptive', 'parameters_questionnaire_dinner_order_adaptive.json'),
        dtr_workflow_tag: nil
      }
    end
  end

  def run(runnable, inputs = {}, scratch = {})
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name:, value:,
                             type: runnable.available_inputs[name.to_sym]&.type)
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable, scratch)
  end

  before do
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
    # Answer any {{fhirpath}} token in the template, so this spec does not depend on whether the
    # fixture uses tokens.
    stub_request(:post, %r{/fhirpath/evaluate})
      .to_return(status: 200, body: [{ type: 'string', element: 'synthetic' }].to_json)
    DaVinciDTRTestKit::FixtureLoader.instance.instance_variable_set(:@cache, {})
  end

  def packaged_adaptive_extensions
    body = JSON.parse(last_response.body)
    bundle = body['parameter'].find { |p| p['name'] == 'packagebundle' }['resource']
    questionnaire = bundle['entry'].map { |e| e['resource'] }.find { |r| r['resourceType'] == 'Questionnaire' }
    questionnaire['extension'].select { |e| e['url'] == adaptive_extension_url }
  end

  it 'sends the adaptive Questionnaire with questionnaireAdaptive as valueUrl, as dtr-questionnaire-adapt requires' do
    run(adaptive_fixture_test, client_id:)
    header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
    post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

    expect(last_response.status).to eq(200)
    extensions = packaged_adaptive_extensions
    expect(extensions.length).to eq(1)
    expect(extensions.first).not_to have_key('valueBoolean')
    expect(extensions.first['valueUrl']).to eq("http://example.org/custom/#{suite_id}/fhir")
  end

  it 'leaves a Questionnaire that already gives a valueUrl unchanged' do
    helper = Class.new { include DaVinciDTRTestKit::AdaptiveServiceUrl }.new
    questionnaire = FHIR::Questionnaire.new(
      status: 'active',
      extension: [FHIR::Extension.new(url: adaptive_extension_url, valueUrl: 'https://payer.example.org/fhir')]
    )
    helper.use_service_url_on_questionnaire(questionnaire, 'https://inferno.example.org/fhir')
    expect(questionnaire.extension.first.valueUrl).to eq('https://payer.example.org/fhir')
  end
end
