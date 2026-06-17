# Templates

Project skeletons for every supported project type. Each template defines the recommended tech stack, required components, security checklist, testing checklist, deployment checklist, and starter repositories.

---

## Gap Protocol — MANDATORY

> **If you search for a template for the current project type and it does not exist in this directory, you MUST stop immediately and inform the user.**
>
> Do NOT:
> - Invent a project structure from general knowledge
> - Use the closest existing template as a silent substitute
> - Proceed with implementation before the gap is acknowledged
>
> DO:
> 1. State explicitly: `"Engineering OS has no template for [project type]. I cannot scaffold this project without one."`
> 2. Propose adding the template to the OS before continuing.
> 3. Wait for user guidance: either approve a new template, point to the closest existing one, or authorize proceeding without an OS template for this case.
>
> **Reason:** A missing template is a gap in the OS — not a license to improvise. Improvised scaffolding bypasses every decision that was baked into existing templates (stack choices, security defaults, auth approach). Surfacing the gap is the correct action.

---

## Available Templates

| Template | Use When |
|---|---|
| [`web-application/`](./web-application/) | Full-stack web app (Next.js, React, SSR/SSG, CRUD, auth) |
| [`saas-platform/`](./saas-platform/) | Multi-tenant SaaS with subscriptions, billing, admin layer |
| [`api-service/`](./api-service/) | Standalone REST or GraphQL API backend |
| [`mobile-application/`](./mobile-application/) | React Native / Expo mobile app (iOS + Android) |
| [`ai-agent/`](./ai-agent/) | Single LLM-powered agent with tools and memory |
| [`multi-agent-system/`](./multi-agent-system/) | Orchestrator + specialist agents, parallel execution |
| [`rag-system/`](./rag-system/) | Retrieval-Augmented Generation pipeline |
| [`machine-learning/`](./machine-learning/) | Model training, evaluation, and serving pipeline |
| [`computer-vision/`](./computer-vision/) | Image/video classification, detection, segmentation |
| [`data-pipeline/`](./data-pipeline/) | Scheduled or event-driven data ingestion and processing |
| [`etl-elt-system/`](./etl-elt-system/) | Extract-Transform-Load / Extract-Load-Transform system |
| [`analytics-platform/`](./analytics-platform/) | Data warehouse, BI, reporting layer |
| [`microservice/`](./microservice/) | Single bounded-context service in a distributed system |
| [`automation-system/`](./automation-system/) | Scheduled jobs, workflow automation, RPA |
| [`cli-tool/`](./cli-tool/) | Command-line tool or developer utility |
| [`browser-extension/`](./browser-extension/) | Chrome/Firefox browser extension |
| [`desktop-application/`](./desktop-application/) | Electron or native desktop app |
| [`admin-dashboard/`](./admin-dashboard/) | Internal ops dashboard with data tables and CRUD |
| [`crm-system/`](./crm-system/) | Customer relationship management system |
| [`marketplace/`](./marketplace/) | Two-sided marketplace with buyer/seller flows |
| [`booking-system/`](./booking-system/) | Scheduling, reservations, and availability management |

## Known Gaps (Not Yet Templated)

The following project types are recognized in the OS but have no template yet. **If your project falls into one of these, follow the Gap Protocol above.**

| Missing Template | Status |
|---|---|
| `library` — reusable npm/PyPI package | Not yet added |
| `mcp-server` — Model Context Protocol server | Not yet added |

---

## How to Use a Template

1. Identify the best match from the table above.
2. Read the template's `README.md` fully before writing any code.
3. Use the template's "Starter Templates" section to clone or scaffold the repo.
4. Follow the Security Checklist, Testing Checklist, and Deployment Checklist — these are not optional.
5. If no template fits, follow the Gap Protocol above.
