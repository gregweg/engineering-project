import { useState } from "react";

const FLAG_LABELS: Record<string, string> = {
  unusual_amount: "Unusual Amount",
  duplicate: "Duplicate",
  missing_metadata: "Missing Metadata",
  manual: "Manual",
};

interface FlagChipsProps {
  txnId: number;
  flags: { type: string; message?: string }[];
  onClear: (flagType: string) => void;
  onUpdateMessage: (flagType: string, message: string) => void;
}

export function FlagChips({
  txnId,
  flags,
  onClear,
  onUpdateMessage,
}: FlagChipsProps) {
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState("");
  const [draftType, setDraftType] = useState("manual");

  return (
    <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
      {flags.map((f, idx) => {
        const key = `${f.type}-${idx}`;
        const isEditing = editing === key;
        const label = FLAG_LABELS[f.type] ?? f.type;

        return (
          <span
            key={key}
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: 6,
              padding: "2px 8px",
              borderRadius: 12,
              border: "1px solid #e5e7eb",
              background: "#f3f4f6",
              fontSize: 12,
              lineHeight: 1.6,
              color: "#111827",
            }}
          >
            {!isEditing ? (
              <>
                {f.message ? (
                  <>
                    <strong style={{ color: "#374151" }}>{FLAG_LABELS[f.type] ?? f.type}:</strong>
                    <em style={{ color: "#6b7280" }}>{f.message}</em>
                  </>
                ) : (
                  <strong style={{ color: "#374151" }}>{FLAG_LABELS[f.type] ?? f.type}</strong>
                )}
                <button title="Edit note" onClick={() => { setEditing(key); setDraft(f.message || ""); setDraftType(f.type); }}>✎</button>
                <button title="Clear this flag" onClick={() => onClear(f.type)}>✕</button>
              </>
            ) : (
              <>
                <select value={draftType} onChange={(e) => setDraftType(e.target.value)} style={{ fontSize: 12 }}>
                  <option value="duplicate">Duplicate</option>
                  <option value="unusual_amount">Unusual Amount</option>
                  <option value="missing_metadata">Missing Metadata</option>
                  <option value="manual">Manual</option>
                </select>
                <input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Flag note" style={{ fontSize: 12 }} />
                <button onClick={() => { onUpdateMessage(draftType, draft); setEditing(null); }}>Save</button>
                <button onClick={() => setEditing(null)}>Cancel</button>
              </>
            )}
          </span>
        );
      })}
    </div>
  );
}