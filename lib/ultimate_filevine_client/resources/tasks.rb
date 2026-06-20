# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Tasks resource. Note the lowercase path (/fv-app/v2/tasks) — Filevine
    # paths are case-sensitive and this family differs from /Projects etc.
    #
    # Filevine models a task as a Note, so every read and write returns the full
    # task record (its id lives under NoteId, which {Entities::Task} unwraps).
    # The spec's path templates are inconsistently cased (capital {taskID} on
    # complete/uncomplete, {assigneeID} on assign), but only the literal segments
    # matter once the id is interpolated, so no special casing is needed here.
    class Tasks < Base
      PATH = "/fv-app/v2/tasks"

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Task, limit:, **params)
      def get(task_id) = fetch_entity("#{PATH}/#{task_id}", Entities::Task)

      # Create a task. `Body` and `ProjectId` (an Identifier) are required; an
      # assignee comes from `AssigneeId` or an `@username` mention in the body.
      def create(attributes) = create_entity(PATH, Entities::Task, attributes)

      # Update the task body (only the `Body` field is honored by this endpoint).
      def update(task_id, attributes) = update_entity("#{PATH}/#{task_id}", Entities::Task, attributes)

      # Unassign a task. This is the spec's DELETE on the task, and it returns the
      # updated (now-unassigned) task rather than no content.
      def unassign(task_id) = delete_entity("#{PATH}/#{task_id}", Entities::Task)

      # Assign a task to a user (body-less PATCH); returns the updated task.
      def assign(task_id, assignee_id) = update_entity("#{PATH}/#{task_id}/assign/#{assignee_id}", Entities::Task)

      # Complete a task, optionally recording a time entry (every field is
      # optional; omit `time_entry` entirely to complete without one).
      def complete(task_id, time_entry = nil)
        post_entity("#{PATH}/#{task_id}/complete", Entities::Task, time_entry)
      end

      def uncomplete(task_id) = post_entity("#{PATH}/#{task_id}/uncomplete", Entities::Task)

      # Change a task's due date. The body carries the single `SnoozeDate` field
      # (PascalCase, despite the docs' camelCase prose); PUT, not POST.
      def snooze(task_id, snooze_date)
        put_entity("#{PATH}/#{task_id}/snooze", Entities::Task, { SnoozeDate: snooze_date })
      end

      def pin(task_id) = post_entity("#{PATH}/#{task_id}/pin", Entities::Task)
      def unpin(task_id) = post_entity("#{PATH}/#{task_id}/unpin", Entities::Task)
    end
  end
end
