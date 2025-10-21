import gleam/result
import gleam/list
import gleam/dynamic/decode
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
import sqlight
import parrot/dev as parrot
import deno_lustre_sc/sql
import deno_lustre_sc/monad
import deno_lustre_sc/db
import deno_lustre_sc/lustre/mvu

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
  let init = mvu.make_init(
    init:,
    to_ctx:,
    to_err_msg: GotErr(err: _),
  )

  let update = mvu.make_update(
    update:,
    to_ctx:,
    to_err_msg: GotErr(err: _),
  )

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
    conn: sqlight.Connection,
    users: List(sql.ListAllUsers),
  )
}

fn to_ctx(
  model model: Model,
) -> monad.Context {
  let Model(conn:, ..) = model

  monad.Context(
    nil: Nil,
    conn:,
  )
}

fn fetch_users(
  model model: Model,
) -> Update {
  use users <- monad.do(
    db.many(sql.list_all_users(name: "Foo"))
  )
  mvu.pure(Model(..model, users:))
}

fn init(
  flags flags: Flags,
) -> #(Model, Update) {
  let db_path = "db.sqlite3"
  let assert Ok(conn) = sqlight.open(db_path)

  let model =
    Model(
      timezone: flags.timezone,
      count: 0,
      conn:,
      users: [],
    )

  let update =
    {
      use model <- mvu.do(fetch_users(model:))
      mvu.pure(model)
    }

  #(model, update)
}

pub type View {
  Home
  History
  TagTemplates
  FaceLibrary
}

pub type Msg {
  NoOp
  GotErr(err: monad.Err)
  Inc
}

type Update =
  mvu.Update(Model, Msg)

fn update(model: Model, msg: Msg) -> Update {
  case msg {
    NoOp -> {
      model
      |> mvu.pure
    }

    GotErr(err:) -> {
      // TODO
      model
      |> mvu.pure
    }

    Inc -> {
      Model(..model, count: model.count + 1)
      |> mvu.pure
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.p([], [html.text("HI FROM LUSTRE SC")]),
    html.p([], [html.text(model.timezone)]),
    html.p([], [html.text(model.count |> int.to_string)]),
    html.button([event.on_click(Inc)], [html.text("+")]),
    html.ul([], [
      html.text(""),
      ..list.map(model.users, fn(user) {
        html.li([], [html.text(user.name)])
      })
    ]),
  ])
}
