# frozen_string_literal: true

class EventTraceFormatter < LowNode
  def initialize(event:, event_tree:)
    root_event = event_tree.root_event

    @heading = if root_event.respond_to?(:request)
      "#{root_event.request.method} #{root_event.request.path}"
    else
      "Request #{event_tree.request_id}"
    end

    @steps = event_tree.sequence.map do |step|
      elapsed_ms = (step.created_at - root_event.created_at).round
      "#{key_label(step.key)} — #{step.action} (+#{elapsed_ms}ms)"
    end
  end

  def render(event:, event_tree:)
    <article class="event-trace">
      <header>{@heading}</header>

      <ol>
        <{ for: step in: @steps }>
          <li>{step}</li>
        <{ :for }>
      </ol>
    </article>
  end

  private

  def key_label(key)
    return "Status #{key.status_code}" if key.is_a?(Low::Types::Status::StatusCode)
    return key.name if key.is_a?(Class)

    key.to_s
  end
end
