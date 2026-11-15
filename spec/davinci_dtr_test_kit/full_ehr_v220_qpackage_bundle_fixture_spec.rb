RSpec.describe 'DTR Full EHR v2.2.0 $questionnaire-package response fixtures' do # rubocop:disable RSpec/DescribeClass
  # DTR-QPackageBundle 2.2.0: Bundle.type is collection, and the Bundle holds exactly one
  # questionnaire entry and exactly one questionnaireResponse entry (dtr-questionnaireresponse).
  # Bundle entries also need a fullUrl so the package can be referenced.
  fixtures = {
    'standard workflow' => 'dinner_static/parameters_questionnaire_dinner_order_static.json',
    'adaptive workflow' => 'dinner_adaptive/parameters_questionnaire_dinner_order_adaptive.json'
  }

  fixtures.each do |workflow, path|
    describe "the #{workflow} fixture" do
      let(:parameters) { DaVinciDTRTestKit::FixtureLoader.instance[path] }
      let(:bundle) { parameters.parameter.first.resource }
      let(:resources) { bundle.entry.map(&:resource) }
      let(:questionnaire) { resources.find { |r| r.is_a?(FHIR::Questionnaire) } }
      let(:responses) { resources.select { |r| r.is_a?(FHIR::QuestionnaireResponse) } }

      it 'is a collection Bundle' do
        expect(bundle.type).to eq('collection')
      end

      it 'gives every entry a fullUrl' do
        expect(bundle.entry.map(&:fullUrl)).to all(be_present)
      end

      it 'carries exactly one QuestionnaireResponse for the packaged Questionnaire' do
        expect(responses.length).to eq(1)
        response = responses.first
        expect(response.questionnaire).to eq(questionnaire.url)
        expect(response.meta.profile)
          .to include('http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse|2.2.0')
        expect(response.subject&.reference).to be_present
      end

      it 'gives the QuestionnaireResponse the coverage and intendedUse extensions the profile requires' do
        urls = responses.first.extension.map(&:url)
        expect(urls).to include('http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-coverage',
                                'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/intendedUse')
        intended_use = responses.first.extension.find { |e| e.url.end_with?('/intendedUse') }
        coding = intended_use.valueCodeableConcept.coding.first
        expect(coding.system).to eq('http://hl7.org/fhir/us/davinci-crd/CodeSystem/coverage-information-codes')
        expect(coding.code).to eq('withpa')
      end
    end
  end
end
