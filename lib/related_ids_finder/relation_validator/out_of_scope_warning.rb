module RelatedIdsFinder
  class RelationValidator
    class OutOfScopeWarning
      MESSAGE_TEMPLATE = \
        '%{full_reflection_name} ' \
        'points to %{reflection_model} (ID: %{extra_ids}), ' \
        'but relations does not include those IDs. ' \
        'If needed, you can ignore this association via config: ' \
        '`RelatedIdsFinder.config.ignore_reflection(%{model}, :%{reflection_name})`'

      attr_reader :reflection, :extra_ids, :reflection_target

      def initialize(reflection:, extra_ids:, reflection_target: reflection.klass)
        @reflection = reflection
        @extra_ids = extra_ids
        @reflection_target = reflection_target
      end

      def message
        MESSAGE_TEMPLATE % message_attributes
      end

      def full_reflection_name
        "#{model_name}##{reflection_name}"
      end

      def message_attributes
        {
          model: model_name,
          full_reflection_name: full_reflection_name,
          reflection_model: reflection_target_name,
          reflection_name: reflection_name,
          extra_ids: extra_ids.join(', ')
        }
      end

      def model_name
        reflection.active_record.name
      end

      def reflection_name
        reflection.name
      end

      def reflection_target_name
        reflection_target
      end

      def out_of_scope?
        true
      end
    end
  end
end
