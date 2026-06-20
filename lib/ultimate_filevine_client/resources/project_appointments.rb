# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's appointments / calendar events.
    #
    # Casing trap (verbatim from the spec): list/create are project-scoped under
    # /Projects/{id}/Appointments, but get/update/delete address an appointment
    # by its (globally unique) id on the flat /fv-app/v2/Appointments/{id}.
    class ProjectAppointments < ProjectScoped
      FLAT_PATH = "/fv-app/v2/Appointments"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(scoped_path, Entities::Appointment, limit:, **params)
      end

      def create(attributes) = create_entity(scoped_path, Entities::Appointment, attributes)
      def get(appointment_id) = fetch_entity("#{FLAT_PATH}/#{appointment_id}", Entities::Appointment)

      def update(appointment_id, attributes)
        update_entity("#{FLAT_PATH}/#{appointment_id}", Entities::Appointment, attributes)
      end

      def delete(appointment_id) = delete_path("#{FLAT_PATH}/#{appointment_id}")

      private

      def scoped_path = "/fv-app/v2/Projects/#{project_id}/Appointments"
    end
  end
end
