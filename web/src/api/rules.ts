export type Rule = {
  id: number;
  field: "description" | "amount";
  operator: "contains" | "equals" | "greater_than" | "less_than";
  value: string;
  action_type: "set_category" | "flag";
  action_value: string; // category name for set_category; can be blank for flag
  priority: number;
  enabled: boolean;
};

const BASE = import.meta.env.VITE_API_URL;

export async function listRules(): Promise<Rule[]> {
  const res = await fetch(`${BASE}/rules`);
  if (!res.ok) throw new Error("Failed to load rules");
  return res.json();
}

export async function createRule(payload: Omit<Rule, "id">) {
  const res = await fetch(`${BASE}/rules`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rule: payload }),
  });
  if (!res.ok) throw new Error("Failed to create rule");
  return res.json() as Promise<Rule>;
}

export async function updateRule(id: number, payload: Partial<Rule>) {
  const res = await fetch(`${BASE}/rules/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rule: payload }),
  });
  if (!res.ok) throw new Error("Failed to update rule");
}

export async function deleteRule(id: number) {
  const res = await fetch(`${BASE}/rules/${id}`, { method: "DELETE" });
  if (!res.ok) throw new Error("Failed to delete rule");
}