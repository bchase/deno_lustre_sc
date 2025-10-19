import gleam/dynamic/decode
import sqlight

// pub fn migrate_db(
//   conn conn: sqlight.Connection,
// ) -> Result(List(String), sqlight.Error) {
//   let sql = "
//     CREATE TABLE users (
//       name TEXT NOT NULL
//     );

//     INSERT INTO users
//       ( name )
//     VALUES
//       ( 'Foo' ),
//       ( 'Bar' );
//   "
//   let assert Ok(Nil) = sqlight.exec(sql, conn)
//   echo "INIT"

//   let user_decoder = {
//     use name <- decode.field(0, decode.string)
//     decode.success(name)
//   }

//   "SELECT * FROM users WHERE name = ?;"
//   |> sqlight.query(on: conn, with: [sqlight.text("Foo")], expecting: user_decoder)
// }
