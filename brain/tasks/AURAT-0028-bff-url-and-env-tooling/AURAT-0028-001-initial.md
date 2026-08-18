# AURAT-0028-001 — Initial

Date: 2026-08-18
Context: raised from **manor** while answering "what do I need for a real
payment test". Execution slave is **slave-1**,
`feature/AURAT-0028-bff-url-and-env-tooling`, off aura-app `develop` @ `6a9138b`.

## What the user asked

> «что мне нужно для теста реального? залить бекенд и чатвут куда-то и потом
> создать билд для заливки в аккаунт разработчика? package name я же уже тебе
> предоставил»

…then, to the finding below: «да, заводи».

## Why this exists

The owner's plan — host the backend, build, upload to Play — is right, and it
still cannot work, for a reason not visible from the Play Console side:

```ts
export const BFF_HTTP_URL = __DEV__ ? `http://${DEV_HOST}:3000` : 'https://bff.invalid';
```

A build uploaded to Play is a **release** build, so `__DEV__` is `false` and the
app talks to a deliberately unresolvable placeholder. No amount of hosting fixes
that: the address is compiled in. There is no env-file tooling in the project —
`env.ts` says so itself ("No env-file tooling is wired yet").

So the first item on the critical path to a real Google Play purchase is a code
task, not an ops one.

## Next

`002-check.md`.
