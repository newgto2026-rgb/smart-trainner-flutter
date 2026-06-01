# Agent Indexing Guide

## Purpose
- Keep agent context small while making required rules discoverable.
- The root `AGENTS.md` must be enough to start any code change safely.

## When To Load
- Always read root `AGENTS.md` first.
- Load this file when deciding which extra agent documents are needed.

## Procedure
1. Read root `AGENTS.md`.
2. Confirm the checkout is Smart Trainner.
3. Identify affected Melos modules.
4. Read only the affected module `AGENTS.md` files.
5. Load playbooks only when implementation details need extra guidance.
6. Before PR updates, re-check the root verification commands and PR template.

## Minimal Context Rules
- Keep root plus affected module guides in active context.
- Do not load unrelated feature/module guides.
- Reuse your working notes instead of repeatedly reopening long reference files.

## Branching
- Branch/PR/dependency rules: root `AGENTS.md` and `docs/agent/policies/global-rules.md`.
- Test and CI details: `docs/agent/quality-gates.md`.
- Implementation details: `docs/agent/playbooks/*.md`.
