# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project appointment / calendar event
    # (GET /fv-app/v2/Projects/{id}/Appointments). The underlying spec type is
    # CalendarEvent; `id` unwraps AppointmentId.
    class Appointment < Base
      def id = native_id("AppointmentId")
      def project_id = native_id("ProjectId")
      def title = self["Title"]
      def start_utc = self["StartUtc"]
      def end_utc = self["EndUtc"]
      def location = self["Location"]
      def all_day? = self["AllDay"] == true
      def event_type = self["CalendarEventType"]
    end
  end
end
