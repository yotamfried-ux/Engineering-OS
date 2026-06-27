#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp[cli]>=1.0", "openai>=1.0"]
# ///
#
# nemotron-mcp-server.py — MCP server exposing Nvidia Nemotron as Claude tools.
#
# Claude calls these tools for heavy generation/review tasks; Nemotron does the
# compute; Claude validates the result before applying it.
#
# Registered via .mcp.json at the project root.
# Governing policy: external-systems/nvidia-nemotron/orchestration.md
# API key:          Nemotron_api_key (injected by Claude Code secrets)

import os
from mcp.server.fastmcp import FastMCP
from openai import OpenAI

NVIDIA_BASE_URL = "https://integrate.api.nvidia.com/v1"
# Use Ultra for deep reasoning tasks; Super for fast summarization/explanation.
ULTRA_MODEL = "nvidia/nemotron-ultra-253b-v1"
SUPER_MODEL = "nvidia/nemotron-super-49b-v1"


def _client() -> OpenAI:
    api_key = os.environ.get("Nemotron_api_key") or os.environ.get("NEMOTRON_API_KEY")
    if not api_key:
        raise RuntimeError("Nemotron_api_key not found in environment")
    return OpenAI(base_url=NVIDIA_BASE_URL, api_key=api_key)


def _call(model: str, system: str, prompt: str, max_tokens: int = 4096, temperature: float = 0.2) -> str:
    try:
        r = _client().chat.completions.create(
            model=model,
            messages=[{"role": "system", "content": system}, {"role": "user", "content": prompt}],
            max_tokens=max_tokens,
            temperature=temperature,
        )
        return r.choices[0].message.content or ""
    except Exception as exc:
        return f"[Nemotron unavailable — handle in Claude]: {exc}"


mcp = FastMCP("nemotron")


@mcp.tool()
def nemotron_generate_code(task: str, context: str, language: str = "", output_type: str = "code") -> str:
    """Generate code, tests, or documentation using Nvidia Nemotron-Ultra.
    Claude calls this for large generation tasks (boilerplate, full modules, test suites).
    Claude reviews and applies the output with Edit after receiving it.

    Args:
        task: Clear description of what to generate.
        context: Relevant existing code, specs, and patterns to follow.
        language: Programming language or format (e.g. TypeScript, Python, markdown).
        output_type: One of: code | tests | documentation | refactoring
    """
    systems = {
        "code": "You are an expert software engineer. Generate clean, idiomatic, production-quality code. Include error handling. No unnecessary comments.",
        "tests": "You are an expert in test-driven development. Generate comprehensive unit tests using AAA pattern. Cover happy path, edge cases, and error scenarios.",
        "documentation": "You are a technical writer. Generate clear, concise documentation matching the project's existing style.",
        "refactoring": "You are an expert at code refactoring. Improve quality without changing behavior. Briefly note key changes.",
    }
    system = systems.get(output_type, systems["code"])
    prompt = f"Task: {task}\n\nContext:\n{context}"
    if language:
        prompt += f"\n\nLanguage/Format: {language}"
    return _call(ULTRA_MODEL, system, prompt, max_tokens=4096, temperature=0.2)


@mcp.tool()
def nemotron_review_code(code: str, context: str = "", focus: str = "all") -> str:
    """First-pass code review using Nvidia Nemotron-Ultra.
    Claude uses this BEFORE running the mandatory security-review gate.
    Returns structured findings; Claude validates before presenting to the user.

    Args:
        code: Code or diff to review.
        context: What the code is supposed to do (purpose, requirements).
        focus: One of: bugs | security | performance | readability | all
    """
    system = (
        "You are a senior code reviewer. Identify issues and improvements. "
        "Format each finding as: [CRITICAL/HIGH/MEDIUM/LOW] <category>: <description>. "
        "Recommendation: <fix>. Be concise. Skip praise. Focus on actionable findings only."
    )
    prompt = f"Review this code"
    if context:
        prompt += f" (Purpose: {context})"
    if focus and focus != "all":
        prompt += f"\nFocus area: {focus}"
    prompt += f":\n\n```\n{code}\n```"
    return _call(ULTRA_MODEL, system, prompt, max_tokens=2048, temperature=0.1)


@mcp.tool()
def nemotron_summarize(content: str, focus: str = "", max_length: str = "medium") -> str:
    """Summarize long content using Nvidia Nemotron-Super (fast model).
    Use for large files, PR descriptions, logs, architecture docs.
    Claude validates accuracy before using the summary.

    Args:
        content: Text to summarize.
        focus: Aspect to emphasize (e.g. "breaking changes", "security implications").
        max_length: brief (2-3 sentences) | medium (1-2 paragraphs) | detailed
    """
    lengths = {
        "brief": "2-3 sentences",
        "medium": "1-2 concise paragraphs",
        "detailed": "thorough but concise, preserving all key technical details",
    }
    length = lengths.get(max_length, lengths["medium"])
    system = "You are an expert at distilling technical information. Create accurate, concise summaries that preserve key decisions and details."
    prompt = f"Summarize the following in {length}"
    if focus:
        prompt += f", focusing on {focus}"
    prompt += f":\n\n{content}"
    return _call(SUPER_MODEL, system, prompt, max_tokens=1024, temperature=0.2)


@mcp.tool()
def nemotron_explain(content: str, level: str = "technical") -> str:
    """Explain code, error messages, or concepts using Nvidia Nemotron-Super.
    Claude uses this for unfamiliar code or to prepare explanations for the user.

    Args:
        content: Code snippet, error message, or concept to explain.
        level: technical (detailed, for developers) | simple (high-level overview)
    """
    system = "You are a patient technical educator. Explain clearly and accurately. For technical audiences, include implementation details and nuances."
    prompt = f"Explain the following at a {level} level:\n\n{content}"
    return _call(SUPER_MODEL, system, prompt, max_tokens=1024, temperature=0.3)


@mcp.tool()
def nemotron_brainstorm(topic: str, constraints: str = "", count: int = 5) -> str:
    """Generate ideas, approaches, or alternatives using Nvidia Nemotron-Ultra.
    Claude reviews the ideas and selects/refines before presenting to the user.

    Args:
        topic: Problem, feature, or architectural decision to brainstorm.
        constraints: Requirements or constraints to respect.
        count: Number of distinct ideas to generate (default: 5).
    """
    system = "You are a creative problem solver with deep technical expertise. Generate diverse, practical ideas. For each idea, briefly note the key trade-off."
    prompt = f"Generate {count} distinct ideas/approaches for: {topic}"
    if constraints:
        prompt += f"\n\nConstraints: {constraints}"
    return _call(ULTRA_MODEL, system, prompt, max_tokens=2048, temperature=0.7)


if __name__ == "__main__":
    mcp.run()
