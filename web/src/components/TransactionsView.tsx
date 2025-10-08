import { useEffect, useMemo, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { formatAmount, formatDateISO } from "../utils/utils";
import {
  bulkCategorize,
  bulkFlag,
  bulkUnflag,
  flagOne,
  unflagOne,
  flagsFor,
  unflagType,
  unflagTypeOne,
  updateFlagMessageOne,
  deleteOne,
  bulkDelete,
} from "../api/transactions";
import type { UiFlag } from "../api/transactions";
import { BulkBar } from "./BulkBar";
import { FlagChips } from "./FlagChips";
import { ConfirmDialog } from "./ConfirmDialog";

type Transaction = {
  id: number;
  date: string;
  description: string;
  amount: string | number;
  needs_review: boolean;
  category?: { id: number; name: string } | null;
};

async function fetchTransactions(limit = 100): Promise<Transaction[]> {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/transactions?limit=${limit}`);
  if (!res.ok) throw new Error("Failed to fetch transactions");
  return res.json();
}

function useTransactions() {
  return useQuery({ queryKey: ["transactions"], queryFn: () => fetchTransactions(100) });
}

export function TransactionsView() {
  const qc = useQueryClient();
  const { data = [], isLoading, error } = useTransactions();
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [flagMap, setFlagMap] = useState<Record<number, UiFlag[]>>({});
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmMsg, setConfirmMsg] = useState("");
  const confirmRef = useRef<null | (() => void)>(null);

  const idsKey = useMemo(() => (data.length ? data.map(d => d.id).join(",") : ""), [data]);

  // load flags for visible transactions
  useEffect(() => {
    let alive = true;
    if (!idsKey) { setFlagMap({}); return; }

    (async () => {
      const rows = await flagsFor(data.map(d => d.id));
      const next: Record<number, UiFlag[]> = {};
      rows.forEach(r => { next[r.id] = r.flags; });

      if (!alive) return;

      // shallow-ish equality check to avoid redundant setState
      setFlagMap(prev => (JSON.stringify(prev) === JSON.stringify(next) ? prev : next));
    })();

    return () => { alive = false; };
  }, [idsKey]);

  const allIds = useMemo(() => data.map((t) => t.id), [data]);
  const allSelected = selected.size > 0 && selected.size === data.length;

  const toggleOne = (id: number, checked: boolean) => {
    setSelected((prev) => {
      const s = new Set(prev);
      checked ? s.add(id) : s.delete(id);
      return s;
    });
  };
  const toggleAll = (checked: boolean) => setSelected(checked ? new Set(allIds) : new Set());

  const categorizeMut = useMutation({
    mutationFn: ({ ids, categoryName }: { ids: number[]; categoryName: string }) =>
      bulkCategorize(ids, categoryName),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const bulkFlagMut = useMutation({
    mutationFn: (ids: number[]) => bulkFlag(ids),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const bulkUnflagMut = useMutation({
    mutationFn: (ids: number[]) => bulkUnflag(ids),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const bulkUnflagTypeMut = useMutation({
    mutationFn: ({ ids, type }: { ids: number[]; type: string }) => unflagType(ids, type),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const flagOneMut = useMutation({
    mutationFn: (id: number) => flagOne(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const unflagOneMut = useMutation({
    mutationFn: (id: number) => unflagOne(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const clearTypeOneMut = useMutation({
    mutationFn: ({ id, type }: { id: number; type: string }) => unflagTypeOne(id, type),
    // Optimistic update so the chip disappears immediately
    onMutate: async ({ id, type }) => {
      // cancel any inflight refetches
      await qc.cancelQueries({ queryKey: ["transactions"] });

      // snapshot previous flags
      const prevFlags = flagMap[id];

      // optimistically remove the chip
      setFlagMap((prev) => {
        const next = { ...prev };
        next[id] = (next[id] ?? []).filter((f) => f.type !== type);
        return next;
      });

      return { id, prevFlags };
    },
    onError: (_err, ctx) => {
      // rollback if server failed
      if (!ctx) return;
      setFlagMap((prev) => ({ ...prev, [ctx.id]: ctx.prevFlags ?? [] }));
    },
    onSuccess: () => {
      // refresh from server so needs_review syncs with backend
      qc.invalidateQueries({ queryKey: ["transactions"] });
    },
  });
  const updateFlagMsgMut = useMutation({
    mutationFn: ({ id, type, message }: { id: number; type: string; message: string }) =>
      updateFlagMessageOne(id, type, message),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const deleteOneMut = useMutation({
    mutationFn: (id: number) => deleteOne(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });
  const bulkDeleteMut = useMutation({
    mutationFn: (ids: number[]) => bulkDelete(ids),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["transactions"] }),
  });

  const busy =
    categorizeMut.isPending ||
    bulkFlagMut.isPending ||
    bulkUnflagMut.isPending ||
    bulkUnflagTypeMut.isPending ||
    bulkDeleteMut.isPending;

  function askConfirm(message: string, onYes: () => void) {
    setConfirmMsg(message);
    confirmRef.current = () => {
      setConfirmOpen(false);
      onYes();
    };
    setConfirmOpen(true);
  }

  if (isLoading) return <p>Loading…</p>;
  if (error instanceof Error) return <p style={{ color: "crimson" }}>Error: {error.message}</p>;

  return (
    <div>
      {selected.size > 0 && (
        <BulkBar
          count={selected.size}
          busy={busy}
          onApply={async (name) => {
            await categorizeMut.mutateAsync({ ids: Array.from(selected), categoryName: name });
            setSelected(new Set());
          }}
          onFlag={async () => {
            await bulkFlagMut.mutateAsync(Array.from(selected));
            setSelected(new Set());
          }}
          onUnflag={async () => {
            await bulkUnflagMut.mutateAsync(Array.from(selected));
            setSelected(new Set());
          }}
          onUnflagType={async (type) => {
            await bulkUnflagTypeMut.mutateAsync({ ids: Array.from(selected), type });
            setSelected(new Set());
          }}
          onDelete={async () => {
            const ids = Array.from(selected);
            if (ids.length === 0) return;
            askConfirm(`Delete ${ids.length} selected transaction(s)? This cannot be undone.`, () => {
              bulkDeleteMut.mutate(ids);
              setSelected(new Set());
            });
          }}
          onClear={() => setSelected(new Set())}
        />
      )}

      <table style={{ borderCollapse: "collapse", width: "100%" }}>
        <thead>
          <tr>
            <th style={{ padding: 6 }}>
              <input type="checkbox" checked={allSelected} onChange={(e) => toggleAll(e.target.checked)} />
            </th>
            <th style={{ textAlign: "left", padding: 6 }}>Date</th>
            <th style={{ textAlign: "left", padding: 6 }}>Description</th>
            <th style={{ textAlign: "right", padding: 6 }}>Amount</th>
            <th style={{ textAlign: "left", padding: 6 }}>Category</th>
            <th style={{ textAlign: "left", padding: 6 }}>Flags</th>
            <th style={{ textAlign: "center", padding: 6 }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {data.map((t) => (
            <tr
              key={t.id}
              style={{
                borderTop: "1px solid #eee",
                background: t.needs_review ? "#ef4444" : "white",
                borderLeft: t.needs_review ? "4px solid #f59e0b" : "4px solid transparent",
                color: "#111827",
              }}>
              <td style={{ padding: 6 }}>
                <input type="checkbox" checked={selected.has(t.id)} onChange={(e) => toggleOne(t.id, e.target.checked)} />
              </td>
              <td style={{ padding: 6, color: "#111827" }}>{formatDateISO(t.date)}</td>
              <td style={{ padding: 6, color: "#111827" }}>{t.description}</td>
              <td style={{ padding: 6, color: "#1f2937", textAlign: "right" }}>
              {formatAmount(t.amount)}
              </td>
              <td style={{ padding: 6, color: "#374151" }}>{t.category ? t.category.name : "-"}</td>
              <td style={{ padding: 6 }}>
                <FlagChips
                  txnId={t.id}
                  flags={flagMap[t.id] ?? []}
                  onClear={(type) => clearTypeOneMut.mutate({ id: t.id, type })}
                  onUpdateMessage={(type, message) =>
                    updateFlagMsgMut.mutate({ id: t.id, type, message })
                  }
                />
              </td>
              <td style={{ padding: 6, textAlign: "center" }}>
                {t.needs_review ? (
                  <button onClick={() => unflagOneMut.mutate(t.id)}>Unflag</button>
                ) : (
                  <button onClick={() => flagOneMut.mutate(t.id)}>Flag</button>
                )}
                <button
                  onClick={() =>
                    askConfirm(
                      `Delete this transaction?\n\n"${t.description}" on ${t.date} for ${typeof t.amount === "string" ? t.amount : t.amount.toFixed(2)}`,
                      () => deleteOneMut.mutate(t.id)
                    )
                  }
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <ConfirmDialog
        open={confirmOpen}
        title="Delete confirmation"
        message={confirmMsg}
        confirmText="Delete"
        cancelText="Cancel"
        onConfirm={() => confirmRef.current?.()}
        onCancel={() => setConfirmOpen(false)}
      />
    </div>
  );
}