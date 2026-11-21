---
name: new-chat
description: "Start a fresh Codex conversation in the current project. Triggers on 新对话, 新建对话, 开新对话, 开启新对话, new chat, $new-chat, /new-chat. Do not use for clearing the current chat, switching projects, or continuing an existing conversation."
metadata:
  short-description: Start a fresh chat in the current project
---

# New Chat

Create and open a fresh Codex conversation in the current project. The new
conversation must not carry over the current conversation history.

## Workflow

1. Resolve the current project and workspace. Use the current conversation's
   project when available; otherwise use the current workspace root as a
   projectless local workspace.
2. If the user supplied text after the trigger, use that text as the new
   conversation's first prompt. Otherwise use `在当前项目开始新对话`.
3. Call `create_thread` once with `environment.type = "local"` and a short
   title derived from the prompt or workspace.
4. After it succeeds, call `navigate_to_codex_page` once with the returned
   `threadId` to open the new conversation.
5. In the final response, state that the new conversation was opened, that it
   does not carry the current conversation history, and that the current
   conversation remains available.
6. Emit `::created-thread{threadId="..."}` on its own line. For queued worktree
   setup, emit `::created-thread{clientThreadId="..."}` instead.

## Constraints

- Do not clear, archive, or modify the current conversation.
- Do not invent a project ID or switch the workspace.
- Use `create_thread` only because the user explicitly requested a new
  conversation.
- If `create_thread` or `navigate_to_codex_page` fails, report the actual error
  and do not claim a new conversation was opened.
