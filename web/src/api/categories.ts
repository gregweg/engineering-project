export type Category = { id: number; name: string; color?: string | null };
const BASE = import.meta.env.VITE_API_URL;

export async function listCategories(): Promise<Category[]> {
  const res = await fetch(`${BASE}/categories`);
  if (!res.ok) throw new Error("Failed to load categories");
  return res.json();
}

// web/src/api/transactions.ts (add)
export async function createTransaction(payload: {
  date: string; // YYYY-MM-DD
  description: string;
  amount: string | number; // "12.34" or 12.34
  category_id?: number | null;
  metadata?: Record<string, unknown>;
}) {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/transactions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ transaction: payload }),
  });
  if (!res.ok) {
    const msg = await res.text().catch(() => "");
    throw new Error(msg || "Failed to create transaction");
  }
  return res.json();
}