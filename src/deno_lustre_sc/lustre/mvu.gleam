import lustre/effect.{type Effect}
import deno_lustre_sc/monad

pub type Update(model, msg) =
  monad.App(#(model, Effect(msg)))

pub type Init(model, msg, flags) =
  fn(flags) -> #(model, Update(model, msg))

pub fn do(
  update update: Update(model, msg),
  cont cont: fn(model) -> Update(model, msg),
) -> Update(model, msg) {
  monad.do(update, fn(t) {
    let #(model, eff1) = t
    use #(model, eff2) <- monad.do(cont(model))
    monad.pure(#(model, effect.batch([ eff1, eff2 ])))
  })
}

pub fn pure(
  model model: model,
) -> Update(model, msg) {
  monad.pure(#(model, effect.none()))
}

pub fn effs(
  model model: model,
  effects effects: List(Effect(msg)),
) -> Update(model, msg) {
  monad.pure(#(model, effect.batch(effects)))
}

pub fn make_update(
  update update: fn(model, msg) -> Update(model, msg),
  to_err_msg to_err_msg: fn(monad.Err) -> msg,
  to_ctx to_ctx: fn(model) -> monad.Context,
) -> fn(model, msg) -> #(model, Effect(msg)) {
  fn(model, msg) {
    model
    |> update(msg)
    |> run(to_err_msg:, to_ctx:, model:)
  }
}

pub fn make_init(
  init init: fn(flags) -> #(model, Update(model, msg)),
  to_err_msg to_err_msg: fn(monad.Err) -> msg,
  to_ctx to_ctx: fn(model) -> monad.Context,
) -> fn(flags) -> #(model, Effect(msg)) {
  fn(flags) {
    let #(model, update) = init(flags)

    update
    |> run(to_err_msg:, to_ctx:, model:)
  }
}

fn run(
  update update: Update(model, msg),
  to_err_msg to_err_msg: fn(monad.Err) -> msg,
  to_ctx to_ctx: fn(model) -> monad.Context,
  model model: model,
) -> #(model, Effect(msg)) {
  update
  |> monad.run(ctx: model |> to_ctx)
  |> fn(result) {
    case result {
      Ok(update) -> update
      Error(err) ->
        #(model, effect.from(fn(dispatch) {
          dispatch(to_err_msg(err))
          Nil
        }))
    }
  }
}
