# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Appointments resource — addresses a single appointment by its
    # (globally unique) id on the flat /fv-app/v2/Appointments path. Listing and
    # creating are project-scoped (see client.project(id).appointments).
    class Appointments < Base
      PATH = "/fv-app/v2/Appointments"

      def get(appointment_id) = fetch_entity("#{PATH}/#{appointment_id}", Entities::Appointment)

      def update(appointment_id, attributes)
        update_entity("#{PATH}/#{appointment_id}", Entities::Appointment, attributes)
      end

      def delete(appointment_id) = delete_path("#{PATH}/#{appointment_id}")
    end
  end
end
