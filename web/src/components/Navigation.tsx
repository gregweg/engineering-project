interface NavigationProps {
  currentTab: "txns" | "import" | "rules" | "add";
  onTabChange: (tab: "txns" | "import" | "rules" | "add") => void;
}

export function Navigation({ currentTab, onTabChange }: NavigationProps) {
  return (
    <header style={{ marginBottom: 16 }}>
      <h1 style={{ margin: 0 }}>Bookkeeping Dashboard</h1>
      <nav style={{ display: "flex", gap: 8, marginTop: 8 }}>
        <button onClick={() => onTabChange("txns")}>Transactions</button>
        <button onClick={() => onTabChange("add")}>Add Transaction</button>
        <button onClick={() => onTabChange("import")}>Import CSV</button>
        <button onClick={() => onTabChange("rules")}>Rules</button>
      </nav>
    </header>
  );
}