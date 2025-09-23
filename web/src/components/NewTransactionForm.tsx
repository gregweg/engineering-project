import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { listCategories, type Category } from "../api/categories";
import { createTransaction } from "../api/transactions";

export default function NewTransactionForm() {
  const qc = useQueryClient();

  const { data: categories = [] } = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
  });

  const [date, setDate] = useState<string>(() => new Date().toISOString().slice(0,10)); // YYYY-MM-DD
  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState<string>("");
  const [categoryId, setCategoryId] = useState<number | "">( "");

  const createMut = useMutation({
    mutationFn: () => createTransaction({
      date,
      description,
      amount,
      category_id: categoryId === "" ? undefined : Number(categoryId),
    }),
    onSuccess: () => {
      // Clear form and refresh the table
      setDescription("");
      setAmount("");
      setCategoryId("");
      qc.invalidateQueries({ queryKey: ["transactions"] });
      alert("Transaction added!");
    },
    onError: (e: any) => {
      alert(e?.message || "Failed to create transaction");
    },
  });

  function canSubmit() {
    return date && description.trim() && amount.toString().trim();
  }

  // allow $ and commas in the input; we’ll send raw string to backend which already normalizes
  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!canSubmit()) return;
    createMut.mutate();
  }

  return (
    <form onSubmit={onSubmit} style={{ display: "grid", gap: 12, maxWidth: 520 }}>
      <div style={{ display: "grid", gap: 6 }}>
        <label>Date</label>
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)} required />
      </div>

      <div style={{ display: "grid", gap: 6 }}>
        <label>Description</label>
        <input
          placeholder="e.g. Amazon order 1234"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          required
        />
      </div>

      <div style={{ display: "grid", gap: 6 }}>
        <label>Amount</label>
        <input
          placeholder="e.g. $49.99"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          required
          inputMode="decimal"
        />
      </div>

      <div style={{ display: "grid", gap: 6 }}>
        <label>Category (optional)</label>
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : "")}
        >
          <option value="">— None —</option>
          {categories.map((c: Category) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <button type="submit" disabled={!canSubmit() || createMut.isPending}>
          {createMut.isPending ? "Saving…" : "Add Transaction"}
        </button>
      </div>
    </form>
  );
}