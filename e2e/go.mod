module github.com/uno-multiplayer/server/e2e

go 1.22

require (
	github.com/golang-jwt/jwt/v5 v5.2.0
	github.com/gorilla/websocket v1.5.1
	github.com/uno-multiplayer/server v0.0.0
)

replace github.com/uno-multiplayer/server => ../backend
