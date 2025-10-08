import { useState } from "react";

export function BulkBar({
  count, onApply, onClear, onFlag, onUnflag, onUnflagType, onDelete, busy,
}: {
  count: number;
  onApply: (name: string) => Promise<void> | void;
  onClear: () => void;
  onFlag: () => Promise<void> | void;
  onUnflag: () => Promise<void> | void;
  onUnflagType: (flagType: string) => Promise<void> | void;
  onDelete: () => Promise<void> | void;
  busy: boolean;
}) {
  const [name, setName] = useState("");
  const [flagType, setFlagType] = useState<string>("duplicate");

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8, padding: 8, border: "1px solid #ddd", borderRadius: 8, marginBottom: 12 }}>
      <strong>{count}</strong> selected
      <input placeholder="Category (e.g. Shopping)" value={name} onChange={(e)=>setName(e.target.value)}
             style={{ padding: 6, borderRadius: 6, border: "1px solid #ccc", minWidth: 220 }} />
      <button disabled={!name || busy} onClick={() => onApply(name)}>Apply</button>
      <button disabled={busy} onClick={onFlag}  title="Mark selected as flagged">Mark flagged</button>
      <button disabled={busy} onClick={onUnflag} title="Clear all flags for selected">Clear all flags</button>
      <button disabled={busy} onClick={onDelete} title="Delete selected">Delete</button>

      <span style={{ marginLeft: 8 }}>Clear by type:</span>
      <select value={flagType} onChange={(e)=>setFlagType(e.target.value)}>
        <option value="duplicate">Duplicate</option>
        <option value="unusual_amount">Unusual Amount</option>
        <option value="missing_metadata">Missing Metadata</option>
      </select>
      <button disabled={busy} onClick={() => onUnflagType(flagType)}>Clear type</button>

      <button disabled={busy} onClick={onClear} style={{ marginLeft: "auto" }}>Clear selection</button>
    </div>
  );
}