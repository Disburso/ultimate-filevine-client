# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Invoice templates (Billing). Reached via client.billing.invoice_templates.
      # Org-level ops live under /billing/invoice-templates; the project-default
      # ops live under singular /billing/project/{id}/invoice-templates (verbatim).
      class InvoiceTemplates < Base
        PATH = "/fv-app/v2/billing/invoice-templates"

        # All invoice templates in the org (a bare array of
        # {Entities::InvoiceTemplate}).
        def list
          Array(connection.get(PATH).body).map { |item| Entities::InvoiceTemplate.new(item) }
        end

        def get(template_id) = fetch_entity("#{PATH}/#{template_id}", Entities::InvoiceTemplate)

        # Add an invoice template (freeform body). Returns true on success.
        def create(attributes) = perform_action(:post, PATH, body: attributes)

        # Edit an invoice template (freeform body). Returns true on success.
        def update(template_id, attributes) = perform_action(:put, "#{PATH}/#{template_id}", body: attributes)

        # Delete an invoice template from the org. Returns true on success.
        def delete(template_id) = delete_path("#{PATH}/#{template_id}")

        # Set a template as the org default. Returns true on success.
        # rubocop:disable Naming/AccessorMethodName -- a write action, not an attribute writer
        def set_org_default(template_id) = perform_action(:post, "#{PATH}/org-default/#{template_id}")
        # rubocop:enable Naming/AccessorMethodName

        # Unset the org default template. Returns true on success.
        def unset_org_default = perform_action(:put, "#{PATH}/unset-org-default")

        # The project's default invoice template ({Entities::InvoiceTemplate}).
        def project_default(project_id)
          fetch_entity("/fv-app/v2/billing/project/#{project_id}/invoice-templates", Entities::InvoiceTemplate)
        end

        # Set a template as the project default. Returns true on success.
        def set_project_default(project_id, template_id)
          perform_action(:put, "/fv-app/v2/billing/project/#{project_id}/invoice-templates/#{template_id}")
        end

        # Unset the project default template. Returns true on success.
        def unset_project_default(project_id)
          delete_path("/fv-app/v2/billing/project/#{project_id}/invoice-templates")
        end
      end
    end
  end
end
