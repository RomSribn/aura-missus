# AURAT-0005-010 — Fix: OpenAPI request/response schemas missing

Date: 2026-07-11
Trigger: user verification in manor — Swagger UI shows **no request body** for
`POST /v1/advisors/{advisorId}/messages`; "Try it out" sends `-d ''` → 400
"Required". Validation works; the OpenAPI contract does not describe
bodies/queries/responses because our DTOs are Zod schemas (not classes), which
`@nestjs/swagger` cannot introspect, and I did not hand-annotate.

## Fix

Hand-written OpenAPI fragments mirroring the Zod contracts (single source in
`src/contracts/openapi.ts`, marked keep-in-sync; nestjs-zod adoption remains
TECH-DEBT #2):

- `ChatController.sendMessage` — `@ApiBody` ({content}), `@ApiCreatedResponse`
  (MessageDto), `@ApiBadGatewayResponse`.
- `ChatController.getHistory` — `@ApiQuery` before/after/limit,
  `@ApiOkResponse` (HistoryResponse).
- `DevicesController` — `@ApiBody` ({platform?}), `@ApiNoContentResponse` ×2.
- `ConversationsController.ensureConversation` — `@ApiOkResponse`
  ({id, advisorId}) (same gap inherited from AURAT-0004).

Next: execute (011).
