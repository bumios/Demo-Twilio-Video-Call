# Demo_TwilioVideoCall
---

This repository is using for demo video call with twilio service



## 1/ Setup & prepare (CLI):

### 1.1/ Install twilio.

### 1.2/ Login

- In terminal, run command below:

```shell
twilio login
```

- Inputed **Account SID** & **Auth Token** from **Account Info** in twilio console dashboard.
- Inputed identifier name (any name).

### 1.3/ Create a room

```shell
twilio api:video:v1:rooms:create 
```

After run above command, it will print **SID, Unique Name, Status** of the room created.

### 1.4/ Generate an access token from **identity** & **room-name**

```shell
twilio token:video --identity="user1" --room-name="room-name-get-from-step-3"
```

After this step, CLI will generate an access token for user with identity `user1` in room name called `room-name-get-from-step-3`





## 2/ Build and run demo:

Replace two variables below

```swift
let accessToken: String = "access-token-get-from-step-1.4"
let roomName: String = "Room-name-get-from-step-1.3"
```

Run & build the app.
