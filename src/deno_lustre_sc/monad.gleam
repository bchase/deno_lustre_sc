import sqlight

pub type App(t) = Monad(t, Context, Err)

pub type Context {
  Context(
    nil: Nil,
    conn: sqlight.Connection,
  )
}

pub type Err {
  SqlightErr(err: sqlight.Error)
  Err(err: String)
  // DbNotFound
}

pub opaque type Monad(t, ctx, err) {
  Monad(run: fn(ctx) -> Result(t, err))
}

pub fn pure(x x: t) -> Monad(t, ctx, err) {
  Monad(run: fn(_) { Ok(x) })
}

pub fn ctx() -> Monad(ctx, ctx, err) {
  Monad(run: fn(ctx) { Ok(ctx) })
}

pub fn fail(err err: err) -> Monad(t, ctx, err) {
  Monad(run: fn(_) { Error(err) })
}

pub fn do(
  app app: Monad(a, ctx, err),
  cont cont: fn(a) -> Monad(b, ctx, err),
) -> Monad(b, ctx, err) {
  Monad(run: fn(ctx) {
    case app.run(ctx) {
      Error(err) -> Error(err)
      Ok(x) -> cont(x).run(ctx)
    }
  })
}

pub fn map(
  app app: Monad(a, ctx, err),
  apply f: fn(a) -> b,
) -> Monad(b, ctx, err) {
  Monad(run: fn(ctx) {
    case app.run(ctx) {
      Error(err) -> Error(err)
      Ok(x) -> Ok(f(x))
    }
  })
}

pub fn replace(
  app app: Monad(a, ctx, err),
  val x: b,
) -> Monad(b, ctx, err) {
  map(app, fn(_) { x })
}

pub fn run(
  app app: Monad(t, ctx, err),
  ctx ctx: ctx
) -> Result(t, err) {
  app.run(ctx)
}
