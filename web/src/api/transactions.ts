import { api } from './client'

const BASE = import.meta.env.VITE_API_URL;

export type UiFlag = { type: string; message?: string };

export async function listTransactions(params: { limit?: number } = {}) {
  const { data } = await api.get('/transactions', { params });
  return data;
}

export async function importCsv(file: File) {
  const fd = new FormData(); fd.append('file', file);
  const { data } = await api.post('/transactions/import_csv', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
  return data;
}

export async function bulkCategorize(ids: number[], categoryName: string) {
  const res = await fetch(`${BASE}/transactions/bulk_update`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids, category_name: categoryName }),
  });
  if (!res.ok) throw new Error("Bulk update failed");
}

export async function bulkFlag(ids: number[]) {
  const res = await fetch(`${BASE}/transactions/bulk_flag`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids })
  });
  if (!res.ok) throw new Error("Bulk flag failed");
}

export async function bulkUnflag(ids: number[]) {
  const res = await fetch(`${BASE}/transactions/bulk_unflag`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids })
  });
  if (!res.ok) throw new Error("Bulk unflag failed");
}

export async function flagOne(id: number) {
  const res = await fetch(`${BASE}/transactions/${id}/flag`, { method: "PATCH" });
  if (!res.ok) throw new Error("Flag failed");
}

export async function unflagOne(id: number) {
  const res = await fetch(`${BASE}/transactions/${id}/unflag`, { method: "PATCH" });
  if (!res.ok) throw new Error("Unflag failed");
}

export async function review() {
  const { data } = await api.get('/transactions/review');
  return data;
}

export async function flagsFor(ids?: number[]) {
  const base = import.meta.env.VITE_API_URL;
  const url = new URL(`${base}/transactions/flags`);
  (ids || []).forEach((id) => url.searchParams.append("ids[]", String(id)));

  const res = await fetch(url.toString());
  if (!res.ok) throw new Error("Flags fetch failed");

  const raw = await res.json() as Array<
    | { id: number; flags: { type?: string | null; message?: string }[] }
    | { id: number; flag_types: string[] }
  >;

  // Normalize:
  return raw.map((row) => {
    if ("flags" in row) {
      return {
        id: row.id,
        flags: row.flags
          .filter((f) => f && f.type)                      // drop null types
          .map((f) => ({ type: String(f.type), message: f.message })),
      };
    }
    // legacy shape (flag_types: string[])
    return {
      id: row.id,
      flags: row.flag_types.map((type) => ({ type })),
    };
  }) as { id: number; flags: UiFlag[] }[];
}

export async function unflagType(ids: number[], flagType: string) {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/transactions/bulk_unflag_type`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids, flag_type: flagType }),
  });
  if (!res.ok) throw new Error("Bulk unflag by type failed");
}

export async function flagTypeOne(id: number, flagType: string) {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/transactions/${id}/flag_type`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ flag_type: flagType }),
  });
  if (!res.ok) throw new Error("Flag type failed");
}

export async function unflagTypeOne(id: number, flagType: string) {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/transactions/${id}/unflag_type`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ flag_type: flagType }),
  });
  if (!res.ok) throw new Error("Unflag type failed");
}

export async function updateFlagMessageOne(id: number, flagType: string, message: string) {
  const res = await fetch(`${BASE}/transactions/${id}/update_flag`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ flag_type: flagType, message }),
  });
  if (!res.ok) throw new Error("Update flag message failed");
}

export async function createTransaction(payload: {
  date: string;             // "2025-09-22"
  description: string;
  amount: string | number;  // e.g. "49.99" or 49.99
  category_id?: number | null;
  metadata?: Record<string, unknown>;
}) {
  const res = await fetch(`${BASE}/transactions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ transaction: payload }),
  });

  if (!res.ok) {
    const msg = await res.text().catch(() => "");
    throw new Error(msg || `Failed to create transaction (status ${res.status})`);
  }

  return res.json();
}

export async function deleteOne(id: number) {
  const res = await fetch(`${BASE}/transactions/${id}`, { method: "DELETE" });
  if (!res.ok) throw new Error("Delete failed");
}

export async function bulkDelete(ids: number[]) {
  const res = await fetch(`${BASE}/transactions/bulk_destroy`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids }),
  });
  if (!res.ok) throw new Error("Bulk delete failed");
}