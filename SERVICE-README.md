# mirofish-service

Deployment mirror of the [MiroFish](https://github.com/666ghj/MiroFish) simulation platform as
it runs on the katsironni.com VPS.

This repo is the **service instance**: it carries the production customizations applied to the
live deployment. For the upstream platform and its full documentation, see
[666ghj/MiroFish](https://github.com/666ghj/MiroFish).

- Upstream: `666ghj/MiroFish`
- User fork (independent development): [jonathanngiroux-star/MiroFish](https://github.com/jonathanngiroux-star/MiroFish)
- This repo: service mirror for VPS deployment

## Contents

| Path | Purpose |
|---|---|
| `backend/app/` | FastAPI backend — graph building, simulation, report generation |
| `backend/app/services/report_agent.py` | Report generator (ReportAgent) |
| `backend/app/services/simulation_config_generator.py` | Simulation config generation |
| `backend/scripts/simulation_monitor.py` | Operational monitor for running simulations |
| `backend/scripts/simulation_monitor.sh` | Shell wrapper for the monitor |
| `frontend/` | Vue frontend (graph view, persona view, report view) |
| `examples/simulation_config.example.json` | Sanitized example simulation config |
| `docker-compose.yml` / `Dockerfile` | Container deployment |

## Production customizations

### GLM-5.x reasoning-effort support
`backend/app/config.py` adds `LLM_REASONING_EFFORT` (`low` / `high` / `max`), forwarded to
OpenAI-compatible gateways that support forced reasoning.

> `max` pushes large-prompt inference past 10 minutes and trips a gateway 504. Use `low` or
> `high` for long-context persona generation; remove the variable for models that reject it.

Plumbing: `backend/app/utils/llm_client.py`, `backend/app/utils/openai_chat_compat.py`,
`backend/app/services/simulation_config_generator.py`.

### Extended frontend API timeout
`frontend/src/api/index.js` raises the Axios timeout from 300 s to 600 s — persona generation
under forced-reasoning models routinely outlasts the original 5-minute client timeout.

### Simulation monitor
`backend/scripts/simulation_monitor.py` and `.sh` watch a running simulation on the VPS:
progress, agent activity, and stuck-run detection.

## Deployment

```bash
cp .env.example .env
# fill in LLM_API_KEY, LLM_BASE_URL, LLM_MODEL_NAME, ZEP_API_KEY
# optional: LLM_REASONING_EFFORT=low

npm run setup:all
npm run dev
```

Or with Docker:

```bash
docker compose up -d
```

- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:5001`

Runtime artifacts (generated reports, simulation state, uploads) are gitignored and live under
`backend/uploads/`.

## License

Same as upstream — see `LICENSE`.
