import { useState } from "react";
import type { Rule } from "../api/rules";

type Props = {
  onSubmit: (payload: Omit<Rule, "id">) => Promise<void> | void;
  busy?: boolean;
};

const FIELDS: Rule["field"][] = ["description", "amount"];
const OPS_BY_FIELD: Record<Rule["field"], Rule["operator"][]> = {
  description: ["contains", "equals"],
  amount: ["greater_than", "less_than", "equals"],
};
const ACTIONS: Rule["action_type"][] = ["set_category", "flag"];

export default function RuleForm({ onSubmit, busy = false }: Props) {
  const [field, setField] = useState<Rule["field"]>("description");
  const [operator, setOperator] = useState<Rule["operator"]>("contains");
  const [value, setValue] = useState("");
  const [actionType, setActionType] = useState<Rule["action_type"]>("set_category");
  const [actionValue, setActionValue] = useState("Shopping");
  const [priority, setPriority] = useState(0);
  const [enabled, setEnabled] = useState(true);

  const ops = OPS_BY_FIELD[field];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    await onSubmit({
      field,
      operator,
      value,
      action_type: actionType,
      action_value: actionType === "set_category" ? actionValue : "",
      priority,
      enabled,
    });
    // reset minimal bits
    setValue("");
  }

  return (
    <form onSubmit={handleSubmit} style={{ display: "grid", gap: 8, gridTemplateColumns: "repeat(6, minmax(0, 1fr))", alignItems: "center" }}>
      <select value={field} onChange={(e) => { setField(e.target.value as any); setOperator(OPS_BY_FIELD[e.target.value as Rule["field"]][0]); }}>
        {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
      </select>

      <select value={operator} onChange={(e) => setOperator(e.target.value as any)}>
        {ops.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>

      <input
        placeholder={field === "description" ? "e.g. Amazon" : "e.g. 1000"}
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />

      <select value={actionType} onChange={(e) => setActionType(e.target.value as any)}>
        {ACTIONS.map((a) => <option key={a} value={a}>{a}</option>)}
      </select>

      <input
        placeholder="Category (if set_category)"
        value={actionValue}
        disabled={actionType !== "set_category"}
        onChange={(e) => setActionValue(e.target.value)}
      />

      <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
        <input placeholder="Priority" type="number" value={priority} onChange={(e) => setPriority(parseInt(e.target.value || "0", 10))} style={{ width: 80 }} />
        <label style={{ display: "flex", alignItems: "center", gap: 4 }}>
          <input type="checkbox" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} /> enabled
        </label>
        <button disabled={busy || !value} type="submit">Add</button>
      </div>
    </form>
  );
}