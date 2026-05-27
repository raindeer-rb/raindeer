# frozen_string_literal: true

class LabelFormatter < LowNode
  def render(event:, labels:)
    <ul class="labels">
      <{ for: label in: labels }>
        <li class={label}>{label}</li>
      <{ :for }>
    </ul>
  end
end
