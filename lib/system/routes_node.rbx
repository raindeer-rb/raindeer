# frozen_string_literal: true

class RoutesNode < LowNode
  observe '/system/routes'

  def initialize(event:)
    @routes = Providers['rain.router'].routes
  end

  def render(event:)
    <{ LayoutNode: }>
      <h1>{"Routes"}</h1>

      <table>
        <thead>
          <tr>
            <th scope="col">HTTP Verbs</th>
            <th scope="col">Route</th>
            <th scope="col">Observers</th>
          </tr>
        </thead>
        <tbody>
          <{ for: path, route in: @routes }>
            <tr>
              <td><{ LabelFormatter labels=route.verbs }></td>
              <td>{route.path}</td>
              <td></td>
            </tr>
          <{ :for }>
        </tbody>
      </table>
    <{ :LayoutNode }>
  end
end
