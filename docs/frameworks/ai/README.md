# AI Agent Frameworks & Platforms

## Overview
Consult this guide before building an AI agent, RAG pipeline, or multi-agent system. The landscape changes rapidly — always verify current versions via Context7 before starting. Key dimensions: stateful vs stateless execution, graph-based vs declarative, Python-only vs multi-language, production observability, and LLM provider flexibility.

**Decision heuristic:**
- Complex stateful workflows + fine-grained control → LangGraph
- Rapid RAG prototyping + broad ecosystem → LangChain
- Type-safe Python agents + Pydantic validation → PydanticAI
- Role-based multi-agent teams, low code → CrewAI
- Conversational multi-agent + research/Microsoft ecosystem → AutoGen
- .NET / C# + enterprise Microsoft stack → Semantic Kernel
- Production RAG + modular pipelines → Haystack

**Important:** Prefer minimal dependencies. Do not pull in LangChain just for a single LLM call — use the provider SDK directly.

## Frameworks

### LangGraph
**Type:** Stateful graph-based agent orchestration  
**Language:** Python (JS/TS port available)  
**Best For:** Complex multi-step agentic workflows with loops, branching, and human-in-the-loop checkpoints  
**Official Docs:** https://langchain-ai.github.io/langgraph/  
**GitHub:** https://github.com/langchain-ai/langgraph  
**Key Strengths:**
- First-class stateful execution via persistent graph state and checkpointing
- Explicit control flow: nodes and edges make execution paths auditable and debuggable
- Built-in support for human-in-the-loop interrupts and approval steps
- Streaming at node, token, and event level out of the box
- LangSmith integration for tracing and observability
- Subgraph composition for modular multi-agent architectures
**Watch Out For:**
- Steeper learning curve than declarative frameworks; graph mental model takes time
- Tight coupling to LangChain ecosystem (though usable standalone)
- Boilerplate-heavy for simple single-turn agents — overkill if you don't need state

---

### LangChain
**Type:** LLM application framework with chains, tools, and retrievers  
**Language:** Python, JavaScript/TypeScript  
**Best For:** Rapid prototyping of RAG pipelines, tool-using agents, and LLM-powered apps with broad integrations  
**Official Docs:** https://python.langchain.com/  
**GitHub:** https://github.com/langchain-ai/langchain  
**Key Strengths:**
- Largest ecosystem of integrations: 100+ LLM providers, vector stores, document loaders
- LCEL (LangChain Expression Language) enables composable, declarative pipelines
- Strong RAG primitives: text splitters, embeddings, retrievers, rerankers
- Active community and extensive tutorials lower onboarding time
- LangSmith for evaluation, tracing, and dataset management
**Watch Out For:**
- Abstraction layers can obscure what is actually happening — hard to debug edge cases
- Frequent breaking changes between minor versions; pin dependencies carefully
- Heavy dependency footprint; avoid importing the full package for simple tasks
- Not designed for complex stateful workflows — use LangGraph instead

---

### PydanticAI
**Type:** Type-safe Python agent framework  
**Language:** Python  
**Best For:** Production Python agents where correctness, validation, and testability are priorities  
**Official Docs:** https://ai.pydantic.dev/  
**GitHub:** https://github.com/pydantic/pydantic-ai  
**Key Strengths:**
- Structured outputs enforced via Pydantic models — LLM responses are validated at runtime
- Dependency injection system makes agents easy to unit test without hitting real LLMs
- Provider-agnostic: OpenAI, Anthropic, Gemini, Ollama, Groq supported via a uniform API
- Minimal, Pythonic API — low boilerplate compared to LangChain
- First-class async support; integrates cleanly with FastAPI and async Python services
- Logfire integration for structured observability
**Watch Out For:**
- Young project (launched late 2024) — API surface may still evolve
- No built-in graph/stateful execution; pair with LangGraph for complex stateful flows
- Smaller community and fewer integrations than LangChain

---

### CrewAI
**Type:** Role-based multi-agent orchestration framework  
**Language:** Python  
**Best For:** Multi-agent pipelines where each agent has a distinct role, goal, and toolset; low-code team assembly  
**Official Docs:** https://docs.crewai.com/  
**GitHub:** https://github.com/crewAIInc/crewAI  
**Key Strengths:**
- Intuitive role/goal/backstory model maps naturally to real-world team structures
- Sequential and hierarchical process modes cover most multi-agent patterns
- Built-in task delegation between agents
- Integrates with LangChain tools, giving access to a wide tool ecosystem
- CrewAI Studio (cloud UI) for non-engineer crew building and monitoring
**Watch Out For:**
- Execution flow is relatively opaque — less control than LangGraph for non-standard workflows
- Performance overhead from agent-to-agent communication at scale
- Production observability tooling is still maturing
- Hierarchical mode with a manager LLM adds latency and cost

---

### AutoGen
**Type:** Conversational multi-agent framework  
**Language:** Python (core); experimental .NET support  
**Best For:** Research-oriented multi-agent systems, code-writing agents, conversational agent pairs, and Microsoft ecosystem integrations  
**Official Docs:** https://microsoft.github.io/autogen/  
**GitHub:** https://github.com/microsoft/autogen  
**Key Strengths:**
- Conversational agent model is flexible and intuitive for iterative, dialogue-based tasks
- Strong code-execution capabilities: agents can write, run, and iterate on Python code
- GroupChat orchestration supports dynamic multi-agent conversations
- Active research community; many published multi-agent patterns originate here
- Integrates with Azure OpenAI and Microsoft tooling out of the box
**Watch Out For:**
- AutoGen 0.4 introduced a breaking architectural rewrite (AgentChat API) — verify which version you target
- Non-deterministic conversation flows can be hard to test and reproduce
- Less opinionated about state persistence — you own checkpointing
- Not designed for production RAG pipelines; pair with a dedicated retrieval layer

---

### Semantic Kernel
**Type:** Enterprise AI orchestration SDK  
**Language:** C# / .NET (primary), Python, Java  
**Best For:** Enterprise .NET / C# applications integrating LLMs into existing Microsoft stack services  
**Official Docs:** https://learn.microsoft.com/en-us/semantic-kernel/overview/  
**GitHub:** https://github.com/microsoft/semantic-kernel  
**Key Strengths:**
- Native C# / .NET SDK with full type safety — first-class citizen in enterprise .NET stacks
- Deep Azure integration: Azure OpenAI, Azure AI Search, Azure Cosmos DB
- Plugin system maps naturally to existing enterprise service boundaries
- Planner component for automatic function orchestration from natural language goals
- Strong memory and RAG abstractions built in
- Stable, production-hardened with Microsoft enterprise support
**Watch Out For:**
- Python SDK lags behind C# in features and documentation
- Heavier abstraction layer than lightweight Python SDKs; more ceremony for simple tasks
- Planner reliability depends heavily on model quality — test thoroughly before production
- Community is smaller than Python-centric alternatives

---

### Haystack
**Type:** Production RAG and modular LLM pipeline framework  
**Language:** Python  
**Best For:** Production-grade RAG pipelines, document search, and modular LLM workflows requiring flexibility and observability  
**Official Docs:** https://docs.haystack.deepset.ai/  
**GitHub:** https://github.com/deepset-ai/haystack  
**Key Strengths:**
- Pipeline abstraction is composable and serializable (YAML/JSON) — easy to version and deploy
- Best-in-class document indexing and retrieval: dense, sparse, and hybrid search
- Wide vector store support: Weaviate, Qdrant, Pinecone, OpenSearch, pgvector, and more
- Evaluation framework built in for retrieval and generation quality
- Active open-source community with deepset commercial backing
- Haystack 2.x is a clean, component-based redesign — well-suited for production use
**Watch Out For:**
- Not designed for stateful multi-agent execution — use LangGraph for agentic loops
- Pipeline serialization adds indirection that can slow down debugging
- 2.x broke compatibility with 1.x; many tutorials online still target the old API

---

## Framework Selection Matrix

| Criterion | LangGraph | LangChain | PydanticAI | CrewAI | AutoGen | Semantic Kernel | Haystack |
|---|---|---|---|---|---|---|---|
| Stateful graph execution | ✓ | partial | ✗ | ✗ | partial | partial | ✗ |
| Multi-agent | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Type safety | partial | ✗ | ✓ | ✗ | ✗ | ✓ (.NET) | ✗ |
| Production-ready | ✓ | partial | ✓ | partial | partial | ✓ | ✓ |
| Multi-language | ✗ | ✗ | ✗ | ✗ | partial | ✓ | ✗ |
| RAG built-in | partial | ✓ | ✗ | ✗ | ✗ | ✓ | ✓ |
