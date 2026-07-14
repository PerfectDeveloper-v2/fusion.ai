# Deploying FusionAI to Render

## Why this file exists

The FusionOS "real headless Chromium" feature (screenshot / PDF / DOM render of a URL)
needs an actual Chromium binary on the host. That's the piece that was silently broken:
the old code tried to `apt-get install chromium` *at request time*, but Render's default
native Python runtime gives the running process no root and no apt access once it's
serving traffic — so that install was always a no-op, and the feature always failed.

System packages on Render can only be added at **build time**, baked into a Docker image.
That's what the included `Dockerfile` does.

## One-time setup

1. In the Render dashboard, open this service → **Settings**.
2. Change **Runtime** from "Python 3" to **Docker**.
3. Set **Dockerfile Path** to `./Dockerfile` (repo root — already included here).
4. Redeploy. Render will build the image (installs Chromium + its shared libs during the
   build step, ~1-2 min extra build time), then run `python3 fusionai.py` inside it, same
   as before. No application code changes are needed beyond what's already in this repo —
   the app already looks for `chromium`/`chromium-browser` on `PATH`.
5. Re-add your environment variables (`GROQ_KEY`, `OPENROUTER_KEY`, `SECRET_KEY`, etc.) in
   the Render dashboard if they aren't already set — switching runtime type does not carry
   them over automatically in every case; check **Environment** after the switch.

`render.yaml` in this repo mirrors the same config if you prefer Render's Blueprint/IaC
flow instead of clicking through the dashboard.

## What does NOT change

- **SQLite / ephemeral disk**: Render's **free** plan has no persistent disk. Users, chats,
  and API keys stored in SQLite still reset on every restart/redeploy/spin-down — Docker
  doesn't fix this, it only fixes Chromium. If you need logins and history to survive:
  - upgrade to a paid plan and mount a persistent disk at `/data`, or
  - point the app at an external database instead of local SQLite (bigger change, not
    included here).
- **Auth header**: still `x-auth-token`, not `Authorization: Bearer`.
- **Everything else** (chat, image gen, MCP servers, Skills, the custom API endpoint) runs
  the same under Docker as it did under the native runtime — Docker is strictly additive
  here, it's just a normal Debian container with Chromium pre-installed.

## Verifying Chromium actually works after the switch

Once redeployed, open FusionOS → Terminal and run:

```
ver
chromium https://example.com
```

Or check `GET /api/fos/chromium/status` while logged in — it should return
`{"available": true, "path": "/usr/bin/chromium", ...}`. If `available` is still `false`
after switching to Docker, check the Render build logs for the `apt-get install` step —
it should show `chromium` being installed with no errors.

## About the "Windows" FusionOS reskin

FusionOS now looks and behaves like a Windows desktop — a bottom taskbar with a Start
button and pinned apps, a system tray with a clock, Windows-style window caption buttons
(─ □ ✕), and a PowerShell-styled terminal prompt (`PS C:\Users\FusionAI>`) with common
Windows/PowerShell command names (`dir`, `type`, `copy`, `move`, `del`, `cls`, `findstr`,
`where`) aliased to their real POSIX equivalents.

Worth being upfront about what this is and isn't: it's a themed UI over the same real
Linux container Render gives the app — not an actual Windows virtual machine. There's no
virtualization available in this environment (no KVM/nested virt, no GPU, and Render's
free tier caps CPU/RAM far below what a real Windows VM needs), so a literal Windows VM
isn't something this architecture can do, on Render's free tier or otherwise. Anything
run through the Terminal or Agent app is still a real command executing on the actual
Linux host — the alias layer just translates the common Windows spellings so muscle
memory works, it doesn't emulate `cmd.exe`/PowerShell semantics beyond that.
