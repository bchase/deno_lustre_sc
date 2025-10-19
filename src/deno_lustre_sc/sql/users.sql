-- name: ListAllUsers :many
SELECT *
FROM users
WHERE name = ?;

-- name: InsertUser :one
INSERT
INTO users
  (
    name
  )
VALUES
  (
    ?
  )
RETURNING
  name;

