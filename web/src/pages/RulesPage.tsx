import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import RuleForm from "../components/RuleForm";
import { listRules, createRule, updateRule, deleteRule } from "../api/rules";
import type { Rule } from "../api/rules";

export default function RulesPage() {
  const qc = useQueryClient();

  const { data: rules = [], isLoading, error } = useQuery({
    queryKey: ["rules"],
    queryFn: listRules,
  });

  const createMut = useMutation({
    mutationFn: (p: Omit<Rule, "id">) => createRule(p),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["rules"] });
      // optional: also re-apply rules server-side via your jobs, but your controller already does this after create/update
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, patch }: { id: number; patch: Partial<Rule> }) => updateRule(id, patch),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["rules"] }),
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => deleteRule(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["rules"] }),
  });

  return (
    <div style={{ display: "grid", gap: 12 }}>
      <h2 style={{ margin: 0 }}>Rules</h2>

      <RuleForm onSubmit={(payload) => createMut.mutateAsync(payload)} busy={createMut.isPending} />

      {isLoading && <p>Loading…</p>}
      {error instanceof Error && <p style={{ color: "crimson" }}>Error: {error.message}</p>}

      <table style={{ borderCollapse: "collapse", width: "100%" }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", padding: 6 }}>Enabled</th>
            <th style={{ textAlign: "left", padding: 6 }}>Priority</th>
            <th style={{ textAlign: "left", padding: 6 }}>If (field/operator/value)</th>
            <th style={{ textAlign: "left", padding: 6 }}>Then (action/action_value)</th>
            <th style={{ textAlign: "left", padding: 6 }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {rules.map((r) => (
            <tr key={r.id} style={{ borderTop: "1px solid #eee" }}>
              <td style={{ padding: 6 }}>
                <input
                  type="checkbox"
                  checked={r.enabled}
                  onChange={(e) => updateMut.mutate({ id: r.id, patch: { enabled: e.target.checked } })}
                />
              </td>
              <td style={{ padding: 6 }}>
                <input
                  type="number"
                  defaultValue={r.priority}
                  style={{ width: 80 }}
                  onBlur={(e) => {
                    const v = parseInt(e.target.value || "0", 10);
                    if (v !== r.priority) updateMut.mutate({ id: r.id, patch: { priority: v } });
                  }}
                />
              </td>
              <td style={{ padding: 6 }}>
                <code>{r.field}</code> <code>{r.operator}</code> <code>{r.value}</code>
              </td>
              <td style={{ padding: 6 }}>
                <code>{r.action_type}</code> {r.action_type === "set_category" && <code>→ {r.action_value}</code>}
              </td>
              <td style={{ padding: 6 }}>
                <button onClick={() => deleteMut.mutate(r.id)}>Delete</button>
              </td>
            </tr>
          ))}
          {rules.length === 0 && (
            <tr><td colSpan={5} style={{ padding: 6, color: "#777" }}>No rules yet</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}