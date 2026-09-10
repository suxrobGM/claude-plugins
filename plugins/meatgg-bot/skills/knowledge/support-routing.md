# Where each request is handled

- **Bans and mutes go to the complaints page, not to tickets.** Categories: «Несправедливый
  бан» and «Несправедливый мут». A ticket about a punishment gets an answer, then a pointer to
  the right page.
- **A mute under the 14+ rule** is lifted only after a moderator checks the player's age over a
  social network, VK or Telegram, so the complaint has to carry a way to reach them.
- **A cheater on a server right now:** `!report` in game chat. After the fact it is a
  complaint, with a demo or a video attached. A head admin also takes proof in a direct
  message, together with a link to the Steam profile.
- **Payments.** A payment shown as «в обработке» is still with the payment provider and lands
  on its own once it clears. Money already paid is not refunded.
- **Приписка (clan tag)** is available to VIP only, and VIP is bought at `https://meat.gg/shop`.
- **VIP keys from the old site** are CSGO keys and cannot be used on the CS2 project.
- **Skins in game** are picked on the site, see [skinchanger.md](skinchanger.md).
- **Becoming an administrator** starts with the admin code at
  `https://meat.gg/rules/admin-code`. Everything else, the terms and the questions, is settled
  on the voice call with a senior administrator.
- **Frozen admin rights** are restored after linking a VK account to the profile.
- Tickets are for the site itself: payments, subscriptions, drops, an account or a page that
  misbehaves.

## The prefilled complaint link

`https://meat.gg/complaints?new=<category>&target=<steam64>` opens the complaints page with the
new complaint form already filled in. `target` is optional: leave it off when the Steam id of
the person complained about is unknown, and the player picks it themselves.

| `new=` | Used for |
| --- | --- |
| `cheating` | A cheater, after the fact. Target: the cheater. |
| `unfair_ban` | A ban an administrator has to review. Target: the administrator who banned. |
| `unfair_mute` | A mute, the 14+ age rule included. Target: the administrator who muted. |
| `abuse` | An administrator who insults or punishes without a check. Target: that administrator. |
| `harassment`, `spam`, `inappropriate`, `other` | Player behaviour outside the four above. |

A complaint against your own account is rejected by the site, so the target is always the other
side: the cheater, or the administrator who issued the punishment.
