export function formatAmount(a: unknown): string {
  if (a === null || a === undefined || a === "") return "—";
  if (typeof a === "number" && Number.isFinite(a)) return a.toFixed(2);
  if (typeof a === "string") {
    // try to coerce common string forms; if not numeric, show as-is
    const n = Number(a.replace(/,/g, ""));
    return Number.isFinite(n) ? n.toFixed(2) : a;
  }
  return String(a);
}

export function formatDateISO(d: unknown): string {
  if (!d) return "—";
  if (typeof d === "string") return d || "—";
  // if backend ever sends a Date object, render ISO
  try { return (d as Date).toISOString().slice(0, 10); } catch { return "—"; }
}