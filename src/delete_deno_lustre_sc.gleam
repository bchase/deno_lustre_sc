import lustre/event
import gleam/int
import gleam/json
import lustre/element/html
import lustre/server_component
import gleam/pair
import lustre
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}

// LUSTRE SERVER COMPONENT INIT/HANDLER

pub type Socket {
  Socket(
    id: String,
    runtime: lustre.Runtime(Msg),
  )
}

pub fn init_socket(
  id: String,
  timezone: String,
  send_to_client: fn(String) -> Nil,
) -> #(Socket, fn() -> Nil) {
  let assert Ok(runtime) =
    component()
    |> lustre.start_server_component(with: Flags(
      timezone:,
    ))

  let callback =
    fn(msg) {
      msg
      |> server_component.client_message_to_json
      |> json.to_string
      |> send_to_client
    }

  let socket = Socket(id:, runtime:)

  let message = server_component.register_callback(callback)

  lustre.send(message:, to: socket.runtime)

  let deregister =
    fn() {
      let _deregistered = server_component.deregister_callback(callback)
      Nil
    }

  #(socket, deregister)
}

pub fn handle_websocket_message(
  socket: Socket,
  msg: String,
) -> Socket {
  case json.parse(msg, server_component.runtime_message_decoder()) {
    Ok(runtime_msg) -> {
      lustre.send(socket.runtime, runtime_msg)
      socket
    }

    Error(_) -> {
      socket
    }
  }
}

// LUSTRE APP

fn component() -> lustre.App(Flags, Model, Msg) {
  lustre.component(init, update, view, [
    component.open_shadow_root(True),
  ])
}

type Flags {
  Flags (
    timezone: String,
  )
}

pub type Model {
  Model(
    timezone: String,
    count: Int,
  )
}

fn init(
  flags flags: Flags,
) -> #(Model, Effect(Msg)) {
  Model(
    timezone: flags.timezone,
    count: 0,
  )
  |> pair.new(effect.batch([
  ]))
}

pub type View {
  Home
  History
  TagTemplates
  FaceLibrary
}

pub type Msg {
  NoOp
  Inc
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NoOp -> {
      #(model, effect.none())
    }

    Inc -> {
      #(Model(..model, count: model.count + 1), effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.p([], [html.text("HI FROM LUSTRE SC")]),
    html.p([], [html.text(model.timezone)]),
    html.p([], [html.text(model.count |> int.to_string)]),
    html.button([event.on_click(Inc)], [html.text("+")]),
  ])
}
