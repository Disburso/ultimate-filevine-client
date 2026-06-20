# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Rate schedules and their flat-fee templates (Billing). Reached via
      # client.billing.rate_schedules. The org list lives under capitalized
      # /Billing; CRUD lives under lowercase /rate-schedules (verbatim).
      class RateSchedules < Base
        # All rate schedules in the org (a bare array of {Entities::RateSchedule}).
        def list
          Array(connection.get("/fv-app/v2/Billing/org/rateschedules").body)
            .map { |item| Entities::RateSchedule.new(item) }
        end

        def get(rate_schedule_id)
          fetch_entity("/fv-app/v2/rate-schedules/#{rate_schedule_id}", Entities::RateSchedule)
        end

        def create(attributes) = create_entity("/fv-app/v2/rate-schedules", Entities::RateSchedule, attributes)

        def update(rate_schedule_id, attributes)
          put_entity("/fv-app/v2/rate-schedules/#{rate_schedule_id}", Entities::RateSchedule, attributes)
        end

        # Delete a rate schedule. Returns true on success.
        def delete(rate_schedule_id) = delete_path("/fv-app/v2/rate-schedules/#{rate_schedule_id}")

        # Assign a rate schedule to a project. Returns the raw { Success, Message }.
        def set_for_project(project_id, rate_schedule_id)
          connection.put("/fv-app/v2/Billing/projects/#{project_id}/rateschedule/#{rate_schedule_id}").body
        end

        # Set a timekeeper's details (rate / classification) across rate schedules.
        # Returns true on success.
        def set_timekeeper(user_id, attributes)
          perform_action(:put, "/fv-app/v2/rate-schedules/timekeepers/#{user_id}", body: attributes)
        end

        # Create a flat-fee template on a rate schedule. Returns the raw template.
        def create_flat_fee_template(rate_schedule_id, attributes)
          connection.post("/fv-app/v2/rate-schedules/#{rate_schedule_id}/flatfeetemplates",
                          body: attributes).body
        end

        # Update a flat-fee template. Returns the raw result.
        def update_flat_fee_template(rate_schedule_id, template_id, attributes)
          connection.put("/fv-app/v2/rate-schedules/#{rate_schedule_id}/flatfeetemplates/#{template_id}",
                         body: attributes).body
        end

        # Delete a flat-fee template. Returns true on success.
        def delete_flat_fee_template(rate_schedule_id, template_id)
          delete_path("/fv-app/v2/rate-schedules/#{rate_schedule_id}/flatfeetemplates/#{template_id}")
        end
      end
    end
  end
end
