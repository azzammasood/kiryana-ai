# Kiryana AI — AISeekho 2026 Hackathon Submission

**Challenge:** 1 — Autonomous Content-to-Action Agent  
**Team:** Kiryana AI (Ahmad integration, Esha `ai_voice`, Abdul `ai_insights`, Usman Flutter UI)

---

## Live demo

| Component | URL |
| :--- | :--- |
| **Web app (Flutter)** | https://kiryana-ai.netlify.app |
| **API (FastAPI)** | https://kiryana-ai-api.onrender.com |
| **API docs** | https://kiryana-ai-api.onrender.com/docs |
| **Health** | https://kiryana-ai-api.onrender.com/health |

---

## Demo videos

| Video | Purpose | Link |
| :--- | :--- | :--- |
| **Video 1 — Product E2E (~3 min)** | Voice logging, home, insights, agent trace, learning | _Add YouTube/Drive URL after upload_ |
| **Video 2 — Antigravity workflow (~2:30)** | Workplan, 7-step orchestrator, tool calls, failure recovery | _Add YouTube/Drive URL after upload_ |

---

## Submission checklist

- [x] Autonomous agent with traced steps (`backend/services/antigravity_agent.py`, `agent_traces` table)
- [x] Voice → structured transactions (`POST /voice/process`, `ai_voice/prompts.py`)
- [x] Weekly insights + fallbacks (`POST /insights/generate/{user_id}`, `_fallback_insight`)
- [x] Roman Urdu / Urdu UX (Flutter + Gemini prompts)
- [x] Production deploy (Netlify + Render + Supabase)
- [x] Antigravity trace pack ([`antigravity/`](./antigravity/README.md))
- [x] Architecture diagram ([`antigravity/kiryana_architecture_diagram.png`](./antigravity/kiryana_architecture_diagram.png))
- [x] Learning loop (voice Q&A, recommendation feedback, KPIs)
- [ ] Upload both demo videos and paste URLs above
- [ ] Confirm Render cold-start tested before judging

---

## Antigravity documentation index

| Document | Description |
| :--- | :--- |
| [antigravity/workplan.md](./antigravity/workplan.md) | Goals, risks, success metrics |
| [antigravity/task-plan.md](./antigravity/task-plan.md) | Phases and team ownership |
| [antigravity/agent-observations.md](./antigravity/agent-observations.md) | Runtime step observations |
| [antigravity/reasoning-decisions.md](./antigravity/reasoning-decisions.md) | Technical decisions |
| [antigravity/tool-calls.md](./antigravity/tool-calls.md) | API / DB / cache trace table |
| [antigravity/execution-log.md](./antigravity/execution-log.md) | Failure injection & recovery |
| [antigravity/final-outcomes.md](./antigravity/final-outcomes.md) | KPIs and limitations |

---

## Repository

https://github.com/azzammasood/kiryana-ai
