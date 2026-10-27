# MiroFish — jonathanngiroux-star fork

This is **my own fork** of [666ghj/MiroFish](https://github.com/666ghj/MiroFish), maintained
independently for the katsironni.com deployment. Upstream is a swarm-intelligence prediction
engine; this fork carries the production customizations for the VPS deployment.

- Fork of: `666ghj/MiroFish` (upstream)
- Base branch: `main`
- Upstream remote: `git remote add upstream https://github.com/666ghj/MiroFish.git`

## What this fork changes

### 1. GLM-5.x reasoning-effort support
`backend/app/config.py` adds `LLM_REASONING_EFFORT` (`low` / `high` / `max`), which is passed
through to OpenAI-compatible gateways that support forced reasoning (GLM-5.x, NIM-hosted models).

> `max` can push large-prompt inference past 10 minutes and trip a gateway 504. Use `low` or `high`
> for long-context persona generation, and delete the variable entirely for models that do not
> accept the parameter.

Related plumbing lives in:
- `backend/app/utils/llm_client.py`
- `backend/app/utils/openai_chat_compat.py`
- `backend/app/services/simulation_config_generator.py`

### 2. Extended frontend API timeout
`frontend/src/api/index.js` raises the Axios timeout from 300 s to 600 s. Persona generation under
forced-reasoning models routinely takes several minutes and was tripping the 5-minute client
timeout before the request finished.

### 3. Simulation monitor scripts
- `backend/scripts/simulation_monitor.py`
- `backend/scripts/simulation_monitor.sh`

Operational tooling for watching a running simulation on the VPS (progress, agent activity,
stuck-run detection).

## Environment

```bash
cp .env.example .env
```

New variable:

```env
LLM_REASONING_EFFORT=low
```

Leave it unset for models that do not support it.

## Syncing with upstream

```bash
git fetch upstream
git rebase upstream/main
git push origin main
```

## License

Same as upstream — see `LICENSE`.
