export function ConfirmDialog({
  open,
  title = "Confirm",
  message,
  confirmText = "Delete",
  cancelText = "Cancel",
  onConfirm,
  onCancel,
}: {
  open: boolean;
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  if (!open) return null;
  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-title"
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.3)",
        display: "grid",
        placeItems: "center",
        zIndex: 9999,
      }}
      onKeyDown={(e) => {
        if (e.key === "Escape") onCancel();
      }}
    >
      <div
        style={{
          background: "white",
          padding: 16,
          borderRadius: 12,
          width: "min(480px, 92vw)",
          boxShadow: "0 10px 30px rgba(0,0,0,0.2)",
          color: "#000",
          border: "1px solid #e0e0e0",
        }}
      >
        <h3 id="confirm-title" style={{ marginTop: 0, color: "#000" }}>{title}</h3>
        <p style={{ marginTop: 0, color: "#333", whiteSpace: "pre-wrap" }}>{message}</p>
        <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 16 }}>
          <button
            onClick={onCancel}
            style={{
              background: "#f5f5f5",
              color: "#333",
              border: "1px solid #ccc",
              padding: "6px 12px",
              borderRadius: 6,
              cursor: "pointer"
            }}
          >
            {cancelText}
          </button>
          <button
            onClick={onConfirm}
            style={{
              background: "#d32f2f",
              color: "white",
              border: "none",
              padding: "6px 12px",
              borderRadius: 6,
              cursor: "pointer"
            }}
            autoFocus
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}