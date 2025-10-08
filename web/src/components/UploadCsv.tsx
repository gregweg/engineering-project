import { useState } from "react";
import { uploadTransactionsCsv, uploadTransactionsCsvWithProgress, downloadImportTemplate } from "../api/import";

export default function UploadCsv() {
  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [result, setResult] = useState<string>("");

  async function handleUpload() {
    if (!file) return;
    setResult("");
    setProgress(0);
    try {
      // with progress:
      const summary = await uploadTransactionsCsvWithProgress(file, setProgress);
      // or without progress:
      // const summary = await uploadTransactionsCsv(file);
      setResult(`Imported ${summary.inserted}/${summary.total_rows}. Flagged: ${summary.flagged}.`);
      if (summary.errors?.length) {
        setResult((r) => r + ` First errors: ${summary.errors.slice(0, 3).join(" | ")}`);
      }
    } catch (e: any) {
      setResult(e?.message || "Import failed");
    } finally {
      setProgress(null);
    }
  }

  return (
    <div style={{ display: "grid", gap: 8 }}>
      <div>
        <input type="file" accept=".csv,text/csv" onChange={(e) => setFile(e.target.files?.[0] || null)} />
        <button onClick={handleUpload} disabled={!file}>Upload CSV</button>
        <button onClick={() => downloadImportTemplate()}>Download Template</button>
      </div>
      {progress !== null && <div>Uploading… {progress}%</div>}
      {result && <div>{result}</div>}
    </div>
  );
}