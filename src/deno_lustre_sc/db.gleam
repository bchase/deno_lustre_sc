import gleam/list
import sqlight
import gleam/dynamic/decode
import parrot/dev as parrot
import deno_lustre_sc/monad.{type App, Context, SqlightErr, ctx, pure, fail, do}

pub type Parrot(t) =
  #(String, List(parrot.Param), decode.Decoder(t))

pub fn many(
  query parrot: Parrot(t),
) -> App(List(t)) {
  db_query(query: parrot, ok: pure)
}

// pub fn one(
//   query parrot: Parrot(t),
// ) -> App(t) {
//   db_query(
//     query: parrot,
//     ok: fn(xs) {
//       case xs {
//         [x, ..] -> pure(x)
//         [] -> fail(DbNotFound)
//       }
//     }
//   )
// }

pub fn one(
  query parrot: Parrot(t),
) -> App(Result(t, Nil)) {
  db_query(
    query: parrot,
    ok: fn(xs) {
      case xs {
        [x, ..] -> pure(Ok(x))
        [] -> pure(Error(Nil))
      }
    }
  )
}

fn db_query(
  query parrot: Parrot(a),
  ok ok: fn(List(a)) -> App(b),
) -> App(b) {
  use Context(conn:, ..) <- do(ctx())

  let #(sql, with, expecting) = parrot
  let with = with |> list.map(parrot_to_sqlight)

  case sqlight.query(sql, on: conn, with:, expecting:) {
    Ok(xs) -> ok(xs)
    Error(err) -> fail(SqlightErr(err:))
  }
}

// parrot

fn parrot_to_sqlight(param: parrot.Param) -> sqlight.Value {
  case param {
    parrot.ParamBool(x) -> sqlight.bool(x)
    parrot.ParamFloat(x) -> sqlight.float(x)
    parrot.ParamInt(x) -> sqlight.int(x)
    parrot.ParamString(x) -> sqlight.text(x)
    parrot.ParamBitArray(x) -> sqlight.blob(x)
    parrot.ParamNullable(x) -> sqlight.nullable(fn(a) { parrot_to_sqlight(a) }, x)
    parrot.ParamList(_) -> panic as "sqlite does not implement lists"
    parrot.ParamDate(_) -> panic as "date parameter needs to be implemented"
    parrot.ParamTimestamp(_) -> panic as "sqlite does not support timestamps"
    parrot.ParamDynamic(_) -> panic as "cannot process dynamic parameter"
  }
}
