import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState } from "react";
import UploadCsv from "./components/UploadCsv";
import RulesPage from "./pages/RulesPage";
import NewTransactionForm from "./components/NewTransactionForm";
import { Navigation } from "./components/Navigation";
import { TransactionsView } from "./components/TransactionsView";

const queryClient = new QueryClient();

function App() {
  const [tab, setTab] = useState<"txns" | "import" | "rules" | "add">("txns");
  return (
    <QueryClientProvider client={queryClient}>
      <div style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
        <Navigation currentTab={tab} onTabChange={setTab} />

        {tab === "add" && <NewTransactionForm />}
        {tab === "import" && <UploadCsv />}
        {tab === "txns" && <TransactionsView />}
        {tab === "rules" && <RulesPage />}
      </div>
    </QueryClientProvider>
  );
}

export default App;