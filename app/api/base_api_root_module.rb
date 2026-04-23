# frozen_string_literal: true

module BaseApiRootModule
  def self.included(base)
    base.class_eval do
      prefix "api"
      format :json
      content_type :csv, "text/csv"
      formatter :json, Grape::Formatter::ActiveModelSerializers

      rescue_from ActiveRecord::RecordNotFound do |e|
        class_name = e.message.match(/^Couldn't find (.*) with?/).try(:[], 1)
        class_name ||= "Record"
        error!(
          {
            error: "record not found",
            class_name: class_name
          },
          :not_found
        )
      end

      rescue_from :all do |e|
        error!({ error: e.message }, 500)
      end

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({ error: e.message }, 400)
      end
    end
  end
end
