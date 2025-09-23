export type ImportSummary = {
  total_rows: number;
  inserted: number;
  flagged: number;
  errors: string[];
};

const BASE = import.meta.env.VITE_API_URL;

/**
 * Upload a CSV of transactions.
 * Expects Rails endpoint: POST /v1/transactions/import_csv
 * Body: multipart/form-data with "file".
 */
export async function uploadTransactionsCsv(file: File): Promise<ImportSummary> {
  const fd = new FormData();
  fd.append("file", file, file.name);

  const res = await fetch(`${BASE}/transactions/import_csv`, {
    method: "POST",
    body: fd, // DO NOT set Content-Type; browser sets boundary for multipart
  });

  if (!res.ok) {
    // try to extract server error message
    const text = await res.text().catch(() => "");
    throw new Error(text || `Import failed with status ${res.status}`);
  }

  return (await res.json()) as ImportSummary;
}

/**
 * Same as above, but with an onProgress callback (0–100).
 * Uses XHR because fetch doesn’t report upload progress.
 */
export function uploadTransactionsCsvWithProgress(
  file: File,
  onProgress: (percent: number) => void
): Promise<ImportSummary> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const fd = new FormData();
    fd.append("file", file, file.name);

    xhr.open("POST", `${BASE}/transactions/import_csv`);

    xhr.upload.onprogress = (evt) => {
      if (!evt.lengthComputable) return;
      const pct = Math.round((evt.loaded / evt.total) * 100);
      onProgress(pct);
    };

    xhr.onerror = () => reject(new Error("Network error during import"));
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          const json = JSON.parse(xhr.responseText) as ImportSummary;
          resolve(json);
        } catch {
          reject(new Error("Invalid JSON response from server"));
        }
      } else {
        reject(new Error(xhr.responseText || `Import failed with status ${xhr.status}`));
      }
    };

    xhr.send(fd);
  });
}

/**
 * Create a downloadable CSV template: date,description,amount,category
 * Returns an object URL you can use in an <a href> or revoke after use.
 */
export function makeImportTemplateUrl(): string {
  const header = "date,description,amount,category\n";
  // include a few example rows (ISO date preferred)
  const sample =
    "2025-09-01,Amazon order 1234,49.99,Shopping\n" +
    "2025-09-02,Starbucks 567,3.75,Dining\n" +
    "2025-09-03,,19.99,\n"; // missing description/category edge case
  const blob = new Blob([header + sample], { type: "text/csv;charset=utf-8" });
  return URL.createObjectURL(blob);
}

/**
 * Convenience helper to download the template immediately.
 */
export function downloadImportTemplate(filename = "transactions_template.csv") {
  const url = makeImportTemplateUrl();
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}