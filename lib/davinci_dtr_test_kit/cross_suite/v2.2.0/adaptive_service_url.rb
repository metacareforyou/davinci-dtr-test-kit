module DaVinciDTRTestKit
  # DTR 2.2.0 dtr-questionnaire-adapt allows only valueUrl on the SDC questionnaireAdaptive
  # extension: the url of the service the client calls $next-question on. The kit's adaptive
  # templates mark a Questionnaire as adaptive with valueBoolean true, because a template cannot
  # know the host Inferno runs on. Before a package goes to the client, replace that marker with
  # the simulated payer's FHIR base url, so the client receives a conformant Questionnaire.
  module AdaptiveServiceUrl
    QUESTIONNAIRE_ADAPTIVE_EXTENSION_URL =
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'.freeze

    def use_adaptive_service_url(parameters, service_url)
      return parameters unless parameters.is_a?(FHIR::Parameters) && service_url.present?

      parameters.parameter.each do |param|
        next unless param.resource.is_a?(FHIR::Bundle)

        param.resource.entry.each do |entry|
          use_service_url_on_questionnaire(entry.resource, service_url) if entry.resource.is_a?(FHIR::Questionnaire)
        end
      end
      parameters
    end

    def use_service_url_on_questionnaire(questionnaire, service_url)
      questionnaire.extension.each do |extension|
        next unless extension.url == QUESTIONNAIRE_ADAPTIVE_EXTENSION_URL && extension.valueBoolean == true

        extension.valueBoolean = nil
        extension.valueUrl = service_url
      end
      questionnaire
    end
  end
end
