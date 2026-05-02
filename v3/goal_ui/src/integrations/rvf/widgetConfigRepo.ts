/**
 * Widget config persistence via the browser RVF backend.
 *
 * Phase 2 POC for ADR-093: prove the RVF browser backend can stand
 * in for the missing-today persistence layer with a small, low-risk
 * piece of state (widget customization options).
 *
 * Today `widgetConfig` lives in React state and resets on reload.
 * With `VITE_RVF_ENABLED=true`, this repo persists it to IndexedDB
 * (namespace `widget`, key `default`) so the customization sticks
 * across sessions.
 *
 * No vector / no embedding — config is plain JSON. The repo is
 * deliberately tiny and synchronous-feeling on the consumer side
 * (callers `await get()` once at mount, `await save(cfg)` on change).
 */

import { getRvfClient } from './client';

const NAMESPACE = 'widget';
const KEY = 'default';

/**
 * Read the persisted widget config. Returns the typed value or
 * `undefined` if no row has been written yet.
 *
 * Generic for the consumer's WidgetConfig shape — the repo is
 * agnostic to the field set, just persists whatever shape it gets.
 */
export async function getWidgetConfig<T>(): Promise<T | undefined> {
  const client = getRvfClient();
  const entry = await client.get(KEY, { namespace: NAMESPACE });
  return entry?.value as T | undefined;
}

/** Persist the widget config. Upserts the single row in `widget/default`. */
export async function saveWidgetConfig<T>(cfg: T): Promise<void> {
  const client = getRvfClient();
  await client.put(cfg, { key: KEY, namespace: NAMESPACE });
}

/** Drop the persisted widget config (returns to in-code defaults on reload). */
export async function clearWidgetConfig(): Promise<void> {
  const client = getRvfClient();
  await client.delete(KEY, { namespace: NAMESPACE });
}
