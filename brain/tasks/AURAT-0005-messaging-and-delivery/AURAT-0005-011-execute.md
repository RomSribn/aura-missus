# AURAT-0005-011 — Execute: OpenAPI schemas fix

Date: 2026-07-11

## Changed

- New `src/contracts/openapi.ts` — hand-written OpenAPI fragments mirroring
  the Zod contracts (message, send-request, history-response, register-device,
  ensure-conversation). Not re-exported from the contracts barrel — these are
  transport-doc artifacts, not device-facing DTOs.
- `ChatController` — `@ApiBody` (send), `@ApiCreatedResponse` (MessageDto),
  `@ApiBadGatewayResponse`, `@ApiQuery` before/after/limit, `@ApiOkResponse`
  (history).
- `DevicesController` — `@ApiBody` ({platform?}), `@ApiNoContentResponse` ×2.
- `ConversationsController` — `@ApiOkResponse` ({id, advisorId}) (gap
  inherited from AURAT-0004).

## Verification

- Scratch drive booting real AppModule (fakes) and asserting `/docs-json`:
  7/7 — send requestBody requires `content`, 201 = MessageDto, 502 documented,
  history query params + response schema, device body, ensure-conversation
  response. Driver deleted.
- Gates: typecheck ✓ lint ✓ 97/97 tests ✓ build ✓.

Committed to feature branch after user approve; then re-merge (gate).
