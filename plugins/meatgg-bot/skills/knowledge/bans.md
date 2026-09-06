# Bans and mutes

## The check procedure (rule 2.28)

- An administrator who suspects a player of cheating may call them to a check on the DC server.
- Leaving the check or ignoring the call is a 30 day ban. Prohibited software found during the
  check is a permanent ban.
- Two ban reasons come from that procedure: «Выход с проверки» (the player left the check) and
  «Не успел ввести дискорд» (the player did not join the check Discord in time).

## Check bans issued without an administrator

- Those two reasons are also written automatically when the check breaks off on its own: the
  administrator disconnected, or the server restarted mid check. Such a row carries no
  administrator, and the site shows it as "Deleted Admin".
- `get_punishments` marks exactly these rows with `bugged: true`. They are a bug, not a
  verdict, and `lift_bugged_ban` removes them.
- A ban issued by an administrator who has since left the staff also renders as "Deleted
  Admin", and it is a real ban. The `bugged` flag is the only thing that separates the two.

## Everything else

- Any other ban or mute is lifted by an administrator, through a complaint. See
  [support-routing.md](support-routing.md).
- Anticheat bans (issued by CONSOLE) are final and are not reviewed.
