// import gleam/bytes_tree
// import gleam/erlang/process
// import gleam/http/request.{type Request}
// import gleam/http/response.{type Response}
// import lustre/element
// import lustre/element/html.{html}
// import mist.{type Connection, type ResponseData}

// pub fn main() {
//   let empty_body = mist.Bytes(bytes_tree.new())
//   let not_found = response.set_body(response.new(404), empty_body)

//   let assert Ok(_) =
//     fn(req: Request(Connection)) -> Response(ResponseData) {
//       case request.path_segments(req) {
//         // ["greet", name] -> greet(name)
//         _ -> not_found
//       }
//     }
//     |> mist.new
//     |> mist.port(3000)
//     |> mist.start

//   process.sleep_forever()
// }
